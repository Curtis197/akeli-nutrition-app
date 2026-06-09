-- =============================================================================
-- pgTAP Test: generate_meal_plan regenerate-on-existing-plan
-- Verifies the bug fixed in 20260603000005:
--   When an active plan already exists for the requested start_date, calling
--   generate_meal_plan must REPLACE it (deactivate old, build new) instead of
--   short-circuiting to zero rows (which the edge function misreported as
--   "Pas assez de recettes disponibles pour générer un plan").
-- =============================================================================

BEGIN;

SELECT plan(4);

-- ─── Seed: minimal reference data ───────────────────────────────────────────

-- Ingredient
INSERT INTO public.ingredient (id, name, name_fr)
VALUES ('00000000-0000-0000-0000-000000000010'::uuid, 'Rice', 'Riz');

-- One published recipe that covers every meal type, so each of the 3 daily
-- slots can be filled from a single recipe (p_max_recipe_repeat defaults to 3).
INSERT INTO public.recipe (id, title, is_published, servings, meal_types, allergen_tags)
VALUES ('aaaaaaaa-0000-0000-0000-000000000010'::uuid, 'Anytime Recipe', true, 1,
        ARRAY['breakfast', 'lunch', 'dinner'], ARRAY[]::text[]);

INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g)
VALUES ('aaaaaaaa-0000-0000-0000-000000000010'::uuid, 500, 20, 60, 15);

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
VALUES ('aaaaaaaa-0000-0000-0000-000000000010'::uuid,
        '00000000-0000-0000-0000-000000000010'::uuid, 100, 'g', false);

-- User
INSERT INTO public.user_profile (id, display_name)
VALUES ('cccccccc-0000-0000-0000-000000000010'::uuid, 'Regen User');

-- Pre-existing ACTIVE plan for today — this is the condition that used to make
-- the function bail out with zero rows.
INSERT INTO public.meal_plan (id, user_id, start_date, end_date, is_active)
VALUES ('dddddddd-0000-0000-0000-000000000010'::uuid,
        'cccccccc-0000-0000-0000-000000000010'::uuid,
        CURRENT_DATE, CURRENT_DATE, true);

-- ─── Act: impersonate the user and regenerate for the same start_date ────────

SET LOCAL request.jwt.claims = '{"sub":"cccccccc-0000-0000-0000-000000000010"}';

CREATE TEMP TABLE gen_result AS
SELECT * FROM public.generate_meal_plan(
  'cccccccc-0000-0000-0000-000000000010'::uuid, 1, 3, CURRENT_DATE);

-- ─── Assert: a fresh plan was actually built ─────────────────────────────────

SELECT is(
  (SELECT count(*)::int FROM gen_result),
  3,
  'regenerate builds 3 entries even though an active plan already existed for the date'
);

SELECT is(
  (SELECT is_active FROM public.meal_plan
   WHERE id = 'dddddddd-0000-0000-0000-000000000010'::uuid),
  false,
  'the previously active plan was deactivated'
);

SELECT is(
  (SELECT count(*)::int FROM public.meal_plan
   WHERE user_id = 'cccccccc-0000-0000-0000-000000000010'::uuid
     AND is_active = true),
  1,
  'exactly one active plan remains for the user'
);

SELECT isnt(
  (SELECT meal_plan_id FROM gen_result LIMIT 1),
  'dddddddd-0000-0000-0000-000000000010'::uuid,
  'a brand-new plan (different id) was created'
);

SELECT * FROM finish();

ROLLBACK;
