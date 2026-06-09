-- =============================================================================
-- pgTAP Test: swap_meal_plan_entry
-- Verifies the two bugs fixed in 20260602000001:
--   1. Computed macro columns are updated after a swap
--   2. meal_ingredient rows are replaced after a swap
-- =============================================================================

BEGIN;

SELECT plan(8);

-- ─── Seed: minimal reference data ───────────────────────────────────────────

-- Ingredient
INSERT INTO public.ingredient (id, name, name_fr)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, 'Water', 'Eau'),
  ('00000000-0000-0000-0000-000000000002'::uuid, 'Yam',   'Igname');

-- Old recipe
INSERT INTO public.recipe (id, title, is_published, servings, meal_types)
VALUES ('aaaaaaaa-0000-0000-0000-000000000001'::uuid, 'Old Recipe', true, 1, ARRAY['dinner']);

INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g)
VALUES ('aaaaaaaa-0000-0000-0000-000000000001'::uuid, 500, 20, 60, 15);

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
VALUES ('aaaaaaaa-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid, 300, 'ml', false);

-- New recipe
INSERT INTO public.recipe (id, title, is_published, servings, meal_types)
VALUES ('bbbbbbbb-0000-0000-0000-000000000001'::uuid, 'New Recipe', true, 1, ARRAY['dinner']);

INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g)
VALUES ('bbbbbbbb-0000-0000-0000-000000000001'::uuid, 800, 40, 90, 25);

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
VALUES ('bbbbbbbb-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000002'::uuid, 200, 'g', false);

-- User
INSERT INTO public.user_profile (id, display_name)
VALUES ('cccccccc-0000-0000-0000-000000000001'::uuid, 'Test User');

-- Calorie goal (no active goal → servings defaults to 1.0)
-- (intentionally omitted so v_new_servings stays 1.0 and math is trivial)

-- Meal plan
INSERT INTO public.meal_plan (id, user_id, start_date, end_date, is_active)
VALUES ('dddddddd-0000-0000-0000-000000000001'::uuid,
        'cccccccc-0000-0000-0000-000000000001'::uuid,
        CURRENT_DATE, CURRENT_DATE + 2, true);

-- Meal plan entry (pre-populated with old recipe's macros)
INSERT INTO public.meal_plan_entry
  (id, meal_plan_id, scheduled_date, meal_type, servings,
   calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed)
VALUES
  ('eeeeeeee-0000-0000-0000-000000000001'::uuid,
   'dddddddd-0000-0000-0000-000000000001'::uuid,
   CURRENT_DATE, 'dinner', 1.0,
   500, 20, 60, 15);   -- ← old recipe values

-- Component binding (old recipe)
INSERT INTO public.meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
VALUES ('eeeeeeee-0000-0000-0000-000000000001'::uuid,
        'aaaaaaaa-0000-0000-0000-000000000001'::uuid, 'base', 1.0);

-- meal_ingredient rows (old recipe)
INSERT INTO public.meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
VALUES ('eeeeeeee-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid, 'Eau', 300, 'ml');

-- ─── Act: impersonate test user and call the RPC ─────────────────────────────

-- Bypass auth.uid() for the test by temporarily setting the local role claim
SET LOCAL request.jwt.claims = '{"sub":"cccccccc-0000-0000-0000-000000000001"}';
SET LOCAL ROLE authenticated;

SELECT public.swap_meal_plan_entry(
  'eeeeeeee-0000-0000-0000-000000000001'::uuid,
  'bbbbbbbb-0000-0000-0000-000000000001'::uuid
);

RESET ROLE;

-- ─── Assert: computed macro columns updated ───────────────────────────────────

SELECT is(
  (SELECT calories_computed FROM public.meal_plan_entry
   WHERE id = 'eeeeeeee-0000-0000-0000-000000000001'::uuid),
  800.0::numeric,
  'calories_computed reflects the new recipe'
);

SELECT is(
  (SELECT protein_g_computed FROM public.meal_plan_entry
   WHERE id = 'eeeeeeee-0000-0000-0000-000000000001'::uuid),
  40.0::numeric,
  'protein_g_computed reflects the new recipe'
);

SELECT is(
  (SELECT carbs_g_computed FROM public.meal_plan_entry
   WHERE id = 'eeeeeeee-0000-0000-0000-000000000001'::uuid),
  90.0::numeric,
  'carbs_g_computed reflects the new recipe'
);

SELECT is(
  (SELECT fat_g_computed FROM public.meal_plan_entry
   WHERE id = 'eeeeeeee-0000-0000-0000-000000000001'::uuid),
  25.0::numeric,
  'fat_g_computed reflects the new recipe'
);

-- ─── Assert: component binding updated ───────────────────────────────────────

SELECT is(
  (SELECT recipe_id FROM public.meal_plan_entry_component
   WHERE meal_plan_entry_id = 'eeeeeeee-0000-0000-0000-000000000001'::uuid
     AND role = 'base'),
  'bbbbbbbb-0000-0000-0000-000000000001'::uuid,
  'meal_plan_entry_component points to the new recipe'
);

-- ─── Assert: meal_ingredient rows replaced ────────────────────────────────────

SELECT is(
  (SELECT COUNT(*)::int FROM public.meal_ingredient
   WHERE meal_plan_entry_id = 'eeeeeeee-0000-0000-0000-000000000001'::uuid),
  1,
  'exactly one meal_ingredient row exists after swap'
);

SELECT is(
  (SELECT ingredient_id FROM public.meal_ingredient
   WHERE meal_plan_entry_id = 'eeeeeeee-0000-0000-0000-000000000001'::uuid),
  '00000000-0000-0000-0000-000000000002'::uuid,
  'meal_ingredient row belongs to the new recipe (Yam, not Water)'
);

SELECT is(
  (SELECT quantity FROM public.meal_ingredient
   WHERE meal_plan_entry_id = 'eeeeeeee-0000-0000-0000-000000000001'::uuid),
  200.000::numeric,
  'meal_ingredient quantity is scaled to new servings (200g × 1.0)'
);

SELECT * FROM finish();

ROLLBACK;
