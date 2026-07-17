-- supabase/tests/database/saved_recipe_eligibility.test.sql
-- Tests: saved-recipe pool-size precheck in generate_meal_plan_from_saved,
-- and the meal_variety_days-coupled eligibility threshold + its triggers.

BEGIN;

SELECT plan(11);

-- ─── Seed: shared ingredient/unit ──────────────────────────────────────────

INSERT INTO public.measurement_unit (code, name_fr, name_en)
VALUES ('g', 'g', 'g') ON CONFLICT (code) DO NOTHING;

INSERT INTO public.ingredient (id, name, name_fr)
VALUES ('00000000-0000-0000-0000-000000000098'::uuid,
        'Eligibility Ingredient', 'Ingrédient Éligibilité')
ON CONFLICT (id) DO NOTHING;

-- ─── Seed: small-pool user (3 universal recipes, saved) ────────────────────

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('a1111111-0000-4000-8000-000000000001'::uuid,
        'smallpool@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, meal_variety_days)
VALUES ('a1111111-0000-4000-8000-000000000001'::uuid, 'SmallPool', 7)
ON CONFLICT (id) DO UPDATE SET meal_variety_days = 7;

INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
VALUES
  ('b1111111-0000-4000-8000-000000000001'::uuid, 'Small Pool Recipe 1', true,
   ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]),
  ('b1111111-0000-4000-8000-000000000002'::uuid, 'Small Pool Recipe 2', true,
   ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]),
  ('b1111111-0000-4000-8000-000000000003'::uuid, 'Small Pool Recipe 3', true,
   ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]);

-- trg_recipe_create_macro auto-creates an empty recipe_macro row on recipe
-- INSERT above, so this must be an upsert, not a plain INSERT.
INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
VALUES
  ('b1111111-0000-4000-8000-000000000001'::uuid, 400, 20, 50, 10, 300),
  ('b1111111-0000-4000-8000-000000000002'::uuid, 500, 25, 55, 12, 350),
  ('b1111111-0000-4000-8000-000000000003'::uuid, 600, 30, 60, 15, 400)
ON CONFLICT (recipe_id) DO UPDATE SET
  calories = EXCLUDED.calories, protein_g = EXCLUDED.protein_g,
  carbs_g = EXCLUDED.carbs_g, fat_g = EXCLUDED.fat_g,
  total_weight_g = EXCLUDED.total_weight_g;

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
VALUES
  ('b1111111-0000-4000-8000-000000000001'::uuid, '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false),
  ('b1111111-0000-4000-8000-000000000002'::uuid, '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false),
  ('b1111111-0000-4000-8000-000000000003'::uuid, '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false);

INSERT INTO public.recipe_save (user_id, recipe_id)
VALUES
  ('a1111111-0000-4000-8000-000000000001'::uuid, 'b1111111-0000-4000-8000-000000000001'::uuid),
  ('a1111111-0000-4000-8000-000000000001'::uuid, 'b1111111-0000-4000-8000-000000000002'::uuid),
  ('a1111111-0000-4000-8000-000000000001'::uuid, 'b1111111-0000-4000-8000-000000000003'::uuid);

-- ─── Seed: large-pool user (7 universal recipes, saved) ────────────────────

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('a1111111-0000-4000-8000-000000000002'::uuid,
        'largepool@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, meal_variety_days)
VALUES ('a1111111-0000-4000-8000-000000000002'::uuid, 'LargePool', 7)
ON CONFLICT (id) DO UPDATE SET meal_variety_days = 7;

INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
SELECT ('b2222222-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       'Large Pool Recipe ' || i, true,
       ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]
FROM generate_series(1, 7) i;

-- trg_recipe_create_macro auto-creates an empty recipe_macro row on recipe
-- INSERT above, so this must be an upsert, not a plain INSERT.
INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
SELECT ('b2222222-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       400 + (i * 10), 20, 50, 10, 300
FROM generate_series(1, 7) i
ON CONFLICT (recipe_id) DO UPDATE SET
  calories = EXCLUDED.calories, protein_g = EXCLUDED.protein_g,
  carbs_g = EXCLUDED.carbs_g, fat_g = EXCLUDED.fat_g,
  total_weight_g = EXCLUDED.total_weight_g;

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
SELECT ('b2222222-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false
FROM generate_series(1, 7) i;

INSERT INTO public.recipe_save (user_id, recipe_id)
SELECT 'a1111111-0000-4000-8000-000000000002'::uuid,
       ('b2222222-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
FROM generate_series(1, 7) i;

UPDATE public.recipe_macro
SET calories_per_100g = ROUND(calories * 100 / NULLIF(total_weight_g, 0), 2),
    protein_per_100g  = ROUND(protein_g * 100 / NULLIF(total_weight_g, 0), 2),
    carbs_per_100g    = ROUND(carbs_g * 100 / NULLIF(total_weight_g, 0), 2),
    fat_per_100g      = ROUND(fat_g * 100 / NULLIF(total_weight_g, 0), 2)
WHERE total_weight_g > 0;

-- ─── Test 1 & 2: small pool (3 < variety_days=7) never raises insufficient_saved_recipes ──

SET LOCAL request.jwt.claims = '{"sub":"a1111111-0000-4000-8000-000000000001"}';

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_from_saved(
       'a1111111-0000-4000-8000-000000000001'::uuid,
       1, 3, (CURRENT_DATE + 400)::date, 3
     ) $$,
  'small pool (3 recipes/type, variety=7): week 1 generates without error'
);

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_from_saved(
       'a1111111-0000-4000-8000-000000000001'::uuid,
       1, 3, (CURRENT_DATE + 403)::date, 3
     ) $$,
  'small pool (3 recipes/type, variety=7): week 2 (3 days later, pool fully exhausted by blacklist) still generates without error'
);

-- ─── Test 3: large pool (7 >= variety_days=7) still enforces the blacklist ──

SET LOCAL request.jwt.claims = '{"sub":"a1111111-0000-4000-8000-000000000002"}';

SELECT public.generate_meal_plan_from_saved(
  'a1111111-0000-4000-8000-000000000002'::uuid,
  1, 3, (CURRENT_DATE + 400)::date, 3
);

CREATE TEMP TABLE t_elig_w1 AS
SELECT DISTINCT mpec.recipe_id
FROM public.meal_plan mp
JOIN public.meal_plan_entry mpe ON mpe.meal_plan_id = mp.id
JOIN public.meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
WHERE mp.user_id         = 'a1111111-0000-4000-8000-000000000002'::uuid
  AND mpe.scheduled_date = (CURRENT_DATE + 400)::date
  AND mpec.role          = 'base';

SELECT public.generate_meal_plan_from_saved(
  'a1111111-0000-4000-8000-000000000002'::uuid,
  1, 3, (CURRENT_DATE + 403)::date, 3
);

SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'a1111111-0000-4000-8000-000000000002'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 403)::date
      AND mpec.role          = 'base'
      AND mpec.recipe_id IN (SELECT recipe_id FROM t_elig_w1)
  ),
  'large pool (7 recipes/type, variety=7): week 2 shares no recipe with week 1 — blacklist still enforced when pool is sufficient'
);

-- ─── Test 3b: pool smaller than variety_days skips the blacklist entirely ──
-- This is the one assertion in this file that actually distinguishes
-- pre-fix from post-fix behavior (see Step 2/Step 4 below for why Tests
-- 1-3 already pass today via the pre-existing Pass 2 fallback). It encodes
-- the accepted trade-off documented in the spec: a pool below variety_days
-- is not partially blacklist-protected — the whole meal type falls back to
-- unfiltered scoring instead of trying to salvage what little protection
-- the non-blacklisted remainder could offer.

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('a1111111-0000-4000-8000-000000000004'::uuid,
        'partialpool@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, meal_variety_days)
VALUES ('a1111111-0000-4000-8000-000000000004'::uuid, 'PartialPool', 7)
ON CONFLICT (id) DO UPDATE SET meal_variety_days = 7;

-- 5 universal recipes with distinct preferred_meal_type so scoring is
-- deterministic: A is the unambiguous top pick for the breakfast slot
-- (score 0.15), D/E are the "any" fallback (score 0.075), B/C prefer other
-- meal types (score 0 for a breakfast slot) so they never compete for it.
INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
VALUES
  ('b3333333-0000-4000-8000-000000000001'::uuid, 'Partial Pool A (breakfast)', true, ARRAY['breakfast','lunch','dinner'], 'breakfast', ARRAY[]::text[]),
  ('b3333333-0000-4000-8000-000000000002'::uuid, 'Partial Pool B (lunch)',     true, ARRAY['breakfast','lunch','dinner'], 'lunch',     ARRAY[]::text[]),
  ('b3333333-0000-4000-8000-000000000003'::uuid, 'Partial Pool C (dinner)',    true, ARRAY['breakfast','lunch','dinner'], 'dinner',    ARRAY[]::text[]),
  ('b3333333-0000-4000-8000-000000000004'::uuid, 'Partial Pool D (any)',       true, ARRAY['breakfast','lunch','dinner'], 'any',       ARRAY[]::text[]),
  ('b3333333-0000-4000-8000-000000000005'::uuid, 'Partial Pool E (any)',       true, ARRAY['breakfast','lunch','dinner'], 'any',       ARRAY[]::text[]);

-- trg_recipe_create_macro auto-creates an empty recipe_macro row on recipe
-- INSERT above, so this must be an upsert, not a plain INSERT.
INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
SELECT id, 400, 20, 50, 10, 300 FROM public.recipe WHERE id IN (
  'b3333333-0000-4000-8000-000000000001'::uuid, 'b3333333-0000-4000-8000-000000000002'::uuid,
  'b3333333-0000-4000-8000-000000000003'::uuid, 'b3333333-0000-4000-8000-000000000004'::uuid,
  'b3333333-0000-4000-8000-000000000005'::uuid
)
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
SELECT id, '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false FROM public.recipe WHERE id IN (
  'b3333333-0000-4000-8000-000000000001'::uuid, 'b3333333-0000-4000-8000-000000000002'::uuid,
  'b3333333-0000-4000-8000-000000000003'::uuid, 'b3333333-0000-4000-8000-000000000004'::uuid,
  'b3333333-0000-4000-8000-000000000005'::uuid
);

INSERT INTO public.recipe_save (user_id, recipe_id)
SELECT 'a1111111-0000-4000-8000-000000000004'::uuid, id FROM public.recipe WHERE id IN (
  'b3333333-0000-4000-8000-000000000001'::uuid, 'b3333333-0000-4000-8000-000000000002'::uuid,
  'b3333333-0000-4000-8000-000000000003'::uuid, 'b3333333-0000-4000-8000-000000000004'::uuid,
  'b3333333-0000-4000-8000-000000000005'::uuid
);

UPDATE public.recipe_macro
SET calories_per_100g = ROUND(calories * 100 / NULLIF(total_weight_g, 0), 2),
    protein_per_100g  = ROUND(protein_g * 100 / NULLIF(total_weight_g, 0), 2),
    carbs_per_100g    = ROUND(carbs_g * 100 / NULLIF(total_weight_g, 0), 2),
    fat_per_100g      = ROUND(fat_g * 100 / NULLIF(total_weight_g, 0), 2)
WHERE total_weight_g > 0;

SET LOCAL request.jwt.claims = '{"sub":"a1111111-0000-4000-8000-000000000004"}';

-- Week 1: breakfast/lunch/dinner slots deterministically pick A/B/C (each
-- strictly highest-scoring for its own slot type). D and E are unused.
SELECT public.generate_meal_plan_from_saved(
  'a1111111-0000-4000-8000-000000000004'::uuid,
  1, 3, (CURRENT_DATE + 450)::date, 3
);

-- Week 2, 3 days later (within the 7-day window): pool=5 < variety_days=7,
-- so the precheck should skip the blacklist for this meal type entirely,
-- and Pass 2's raw scoring picks A again for breakfast (A objectively
-- out-scores D/E even without the blacklist). Before this task's fix,
-- Pass 1 would still run with the blacklist active, exclude A/B/C, and
-- pick D or E instead — never A.
SELECT public.generate_meal_plan_from_saved(
  'a1111111-0000-4000-8000-000000000004'::uuid,
  1, 3, (CURRENT_DATE + 453)::date, 3
);

SELECT is(
  (
    SELECT mpec.recipe_id
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'a1111111-0000-4000-8000-000000000004'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 453)::date
      AND mpe.meal_type      = 'breakfast'
      AND mpec.role          = 'base'
  ),
  'b3333333-0000-4000-8000-000000000001'::uuid,
  'pool (5) < variety_days (7): breakfast slot reuses recipe A — precheck skips the blacklist entirely for this meal type instead of partially enforcing it (accepted trade-off, see spec Part 1 edge cases)'
);

-- ─── Test 4 & 5: meal_variety_days = 0 is unaffected by the precheck ───────

UPDATE public.user_profile
SET meal_variety_days = 0
WHERE id = 'a1111111-0000-4000-8000-000000000001'::uuid;

SET LOCAL request.jwt.claims = '{"sub":"a1111111-0000-4000-8000-000000000001"}';

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_from_saved(
       'a1111111-0000-4000-8000-000000000001'::uuid,
       1, 3, (CURRENT_DATE + 500)::date, 3
     ) $$,
  'variety=0: week 3 generates without error'
);

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_from_saved(
       'a1111111-0000-4000-8000-000000000001'::uuid,
       1, 3, (CURRENT_DATE + 503)::date, 3
     ) $$,
  'variety=0: week 4 (3 days later, reuse allowed) generates without error'
);

-- ─── Seed: eligibility user (14 universal recipes) — used by Tasks 2 & 3 ───
-- Tests 6-10 are written here but will fail until Tasks 2 and 3 land; that is
-- expected for this step (see Step 2 below).

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('a1111111-0000-4000-8000-000000000003'::uuid,
        'eligibility@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, meal_variety_days, use_saved_recipes_only, is_saved_recipe_eligible)
VALUES ('a1111111-0000-4000-8000-000000000003'::uuid, 'Eligibility', 7, false, false)
ON CONFLICT (id) DO UPDATE SET meal_variety_days = 7, use_saved_recipes_only = false, is_saved_recipe_eligible = false;

INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
SELECT ('c3333333-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       'Eligibility Recipe ' || i, true,
       ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]
FROM generate_series(1, 14) i;

-- Save only the first 10 for now (Test 6 checks "not yet eligible").
INSERT INTO public.recipe_save (user_id, recipe_id)
SELECT 'a1111111-0000-4000-8000-000000000003'::uuid,
       ('c3333333-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
FROM generate_series(1, 10) i;

-- Test 6: 10 saved/type, variety_days=7 (target 14) → NOT eligible
SELECT public.evaluate_saved_recipe_eligibility('a1111111-0000-4000-8000-000000000003'::uuid);

SELECT is(
  (SELECT is_saved_recipe_eligible FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  false,
  'eligibility: 10 saved recipes/type at variety_days=7 (target 14) is NOT eligible'
);

-- Save the remaining 4 (total 14) for Test 7.
INSERT INTO public.recipe_save (user_id, recipe_id)
SELECT 'a1111111-0000-4000-8000-000000000003'::uuid,
       ('c3333333-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
FROM generate_series(11, 14) i;

SELECT public.evaluate_saved_recipe_eligibility('a1111111-0000-4000-8000-000000000003'::uuid);

-- Test 7: 14 saved/type, variety_days=7 (target 14) → eligible
SELECT is(
  (SELECT is_saved_recipe_eligible FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  true,
  'eligibility: 14 saved recipes/type at variety_days=7 (target 14) IS eligible'
);

-- Turn saved-only mode on so Test 8/9 can prove the variety-change trigger forces it back off.
UPDATE public.user_profile
SET use_saved_recipes_only = true
WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid;

-- Test 8 & 9: raising variety_days to 15 (target 30, still only 14 saved) fires
-- the trigger automatically and forces both flags off.
UPDATE public.user_profile
SET meal_variety_days = 15
WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid;

SELECT is(
  (SELECT is_saved_recipe_eligible FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  false,
  'trigger: raising meal_variety_days to 15 (target 30, still 14 saved) flips is_saved_recipe_eligible to false automatically'
);

SELECT is(
  (SELECT use_saved_recipes_only FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  false,
  'trigger: raising meal_variety_days also force-disables use_saved_recipes_only automatically'
);

-- Test 10: direct write guard — attempting to set use_saved_recipes_only=true
-- while ineligible is silently reverted.
UPDATE public.user_profile
SET use_saved_recipes_only = true
WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid;

SELECT is(
  (SELECT use_saved_recipes_only FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  false,
  'guard trigger: direct UPDATE setting use_saved_recipes_only=true while ineligible is silently reverted to false'
);

SELECT * FROM finish();

ROLLBACK;
