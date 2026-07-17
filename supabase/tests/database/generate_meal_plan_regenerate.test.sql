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

-- Measurement units (FK required by recipe_ingredient.unit)
INSERT INTO public.measurement_unit (code, name_fr, name_en)
VALUES ('g', 'g', 'g') ON CONFLICT (code) DO NOTHING;

-- Ingredient
INSERT INTO public.ingredient (id, name, name_fr)
VALUES ('00000000-0000-0000-0000-000000000010'::uuid, 'Rice', 'Riz');

-- One published recipe that covers every meal type, so each of the 3 daily
-- slots can be filled from a single recipe (p_max_recipe_repeat defaults to 3).
INSERT INTO public.recipe (id, title, is_published, servings, meal_types, allergen_tags)
VALUES ('aaaaaaaa-0000-0000-0000-000000000010'::uuid, 'Anytime Recipe', true, 1,
        ARRAY['breakfast', 'lunch', 'dinner'], ARRAY[]::text[]);

-- total_weight_g required so calories_per_100g (backfilled below) is > 0
-- (generator filters rm.calories_per_100g > 0). trg_recipe_create_macro
-- auto-creates an empty recipe_macro row on recipe INSERT above, so this
-- must be an upsert, not a plain INSERT.
INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
VALUES ('aaaaaaaa-0000-0000-0000-000000000010'::uuid, 500, 20, 60, 15, 300)
ON CONFLICT (recipe_id) DO UPDATE SET
  calories = EXCLUDED.calories, protein_g = EXCLUDED.protein_g,
  carbs_g = EXCLUDED.carbs_g, fat_g = EXCLUDED.fat_g,
  total_weight_g = EXCLUDED.total_weight_g;

UPDATE public.recipe_macro
SET calories_per_100g = ROUND(calories * 100 / NULLIF(total_weight_g, 0), 2),
    protein_per_100g  = ROUND(protein_g * 100 / NULLIF(total_weight_g, 0), 2),
    carbs_per_100g    = ROUND(carbs_g * 100 / NULLIF(total_weight_g, 0), 2),
    fat_per_100g      = ROUND(fat_g * 100 / NULLIF(total_weight_g, 0), 2)
WHERE total_weight_g > 0 AND (calories_per_100g IS NULL OR calories_per_100g = 0);

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
VALUES ('aaaaaaaa-0000-0000-0000-000000000010'::uuid,
        '00000000-0000-0000-0000-000000000010'::uuid, 100, 'g', false);

-- User (auth.users required before user_profile FK)
INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('cccccccc-0000-0000-0000-000000000010'::uuid, 'regen@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name)
VALUES ('cccccccc-0000-0000-0000-000000000010'::uuid, 'Regen')
ON CONFLICT (id) DO NOTHING;

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

-- Migration 20260628000002 uses plan-reuse: the existing overlapping plan is
-- reused (same ID, future entries replaced) rather than deactivated.
SELECT is(
  (SELECT is_active FROM public.meal_plan
   WHERE id = 'dddddddd-0000-0000-0000-000000000010'::uuid),
  true,
  'existing plan is still active (reused, not deactivated)'
);

SELECT is(
  (SELECT count(*)::int FROM public.meal_plan
   WHERE user_id = 'cccccccc-0000-0000-0000-000000000010'::uuid
     AND is_active = true),
  1,
  'exactly one active plan remains for the user'
);

SELECT is(
  (SELECT meal_plan_id FROM gen_result LIMIT 1),
  'dddddddd-0000-0000-0000-000000000010'::uuid,
  'existing plan was reused (same id)'
);

SELECT * FROM finish();

ROLLBACK;
