-- supabase/tests/database/generate_meal_plan_variety.test.sql
-- Tests: 15-day blacklist prevents recipe repetition across weekly plans.

BEGIN;

SELECT plan(5);

-- ─── Seed ──────────────────────────────────────────────────────────────────

INSERT INTO public.measurement_unit (code, name_fr, name_en)
VALUES ('g', 'g', 'g') ON CONFLICT (code) DO NOTHING;

INSERT INTO public.ingredient (id, name, name_fr)
VALUES ('00000000-0000-0000-0000-000000000099'::uuid,
        'Variety Ingredient', 'Ingrédient Variété')
ON CONFLICT (id) DO NOTHING;

-- Test user
INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('eeeeffff-0000-4000-8000-000000000099'::uuid,
        'variety@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name)
VALUES ('eeeeffff-0000-4000-8000-000000000099'::uuid, 'Variety')
ON CONFLICT (id) DO NOTHING;

-- 6 recipes: 2 per meal type.
-- A recipes get one like → score higher → deterministically picked in week 1.
-- B recipes have no likes → picked only when A is blacklisted (week 2).
INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
VALUES
  ('cccc0001-0000-4000-8000-000000000099'::uuid, 'Variety Breakfast A', true,
   ARRAY['breakfast'], 'breakfast', ARRAY[]::text[]),
  ('cccc0002-0000-4000-8000-000000000099'::uuid, 'Variety Breakfast B', true,
   ARRAY['breakfast'], 'breakfast', ARRAY[]::text[]),
  ('cccc0003-0000-4000-8000-000000000099'::uuid, 'Variety Lunch A', true,
   ARRAY['lunch'], 'lunch', ARRAY[]::text[]),
  ('cccc0004-0000-4000-8000-000000000099'::uuid, 'Variety Lunch B', true,
   ARRAY['lunch'], 'lunch', ARRAY[]::text[]),
  ('cccc0005-0000-4000-8000-000000000099'::uuid, 'Variety Dinner A', true,
   ARRAY['dinner'], 'dinner', ARRAY[]::text[]),
  ('cccc0006-0000-4000-8000-000000000099'::uuid, 'Variety Dinner B', true,
   ARRAY['dinner'], 'dinner', ARRAY[]::text[]);

-- total_weight_g required so GENERATED kcal_per_100g > 0
INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
VALUES
  ('cccc0001-0000-4000-8000-000000000099'::uuid, 400, 20, 50, 10, 300),
  ('cccc0002-0000-4000-8000-000000000099'::uuid, 400, 20, 50, 10, 300),
  ('cccc0003-0000-4000-8000-000000000099'::uuid, 600, 30, 70, 15, 400),
  ('cccc0004-0000-4000-8000-000000000099'::uuid, 600, 30, 70, 15, 400),
  ('cccc0005-0000-4000-8000-000000000099'::uuid, 700, 35, 80, 20, 450),
  ('cccc0006-0000-4000-8000-000000000099'::uuid, 700, 35, 80, 20, 450);

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
VALUES
  ('cccc0001-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 100, 'g', false),
  ('cccc0002-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 100, 'g', false),
  ('cccc0003-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 150, 'g', false),
  ('cccc0004-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 150, 'g', false),
  ('cccc0005-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 200, 'g', false),
  ('cccc0006-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 200, 'g', false);

-- Likes on A recipes to break score ties deterministically
INSERT INTO public.recipe_like (recipe_id, user_id)
VALUES
  ('cccc0001-0000-4000-8000-000000000099'::uuid,
   'eeeeffff-0000-4000-8000-000000000099'::uuid),
  ('cccc0003-0000-4000-8000-000000000099'::uuid,
   'eeeeffff-0000-4000-8000-000000000099'::uuid),
  ('cccc0005-0000-4000-8000-000000000099'::uuid,
   'eeeeffff-0000-4000-8000-000000000099'::uuid);

-- ─── Test 1: 15-day blacklist — week 2 uses different recipes than week 1 ──

SET LOCAL request.jwt.claims =
  '{"sub":"eeeeffff-0000-4000-8000-000000000099"}';

-- Week 1 (1-day plan at far future offset to avoid collision with other tests)
SELECT public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 200)::date, 3
);

CREATE TEMP TABLE t_variety_w1 AS
SELECT DISTINCT mpec.recipe_id
FROM public.meal_plan mp
JOIN public.meal_plan_entry mpe
  ON mpe.meal_plan_id = mp.id
JOIN public.meal_plan_entry_component mpec
  ON mpec.meal_plan_entry_id = mpe.id
WHERE mp.user_id         = 'eeeeffff-0000-4000-8000-000000000099'::uuid
  AND mpe.scheduled_date = (CURRENT_DATE + 200)::date
  AND mpec.role          = 'base';

-- Week 2 (1-day plan, 8 days later — within the 15-day window)
SELECT public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 208)::date, 3
);

SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe
      ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'eeeeffff-0000-4000-8000-000000000099'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 208)::date
      AND mpec.role          = 'base'
      AND mpec.recipe_id IN (SELECT recipe_id FROM t_variety_w1)
  ),
  '15-day blacklist: plan at day+208 shares no recipe with plan at day+200'
);

-- ─── Tests 2 & 3: fallback — two plans within 15 days must not crash ───────
-- JWT is already set via SET LOCAL above; generate_meal_plan honours it.

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan(
       'eeeeffff-0000-4000-8000-000000000099'::uuid,
       1, 3, (CURRENT_DATE + 300)::date, 3
     ) $$,
  'First plan at day+300 generates without error'
);

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan(
       'eeeeffff-0000-4000-8000-000000000099'::uuid,
       1, 3, (CURRENT_DATE + 305)::date, 3
     ) $$,
  'Second plan within 15-day window (day+305) generates without error — fallback if pool exhausted'
);

-- ─── Test 4: 15-day window is date-relative, not CURRENT_DATE-relative ───────
-- A plan at day+1 must NOT blacklist recipes for a plan at day+20 (gap = 19 days > 15).
-- Window for day+20 plan = [day+5, day+20) — day+1 is outside this window.

SELECT public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 1)::date, 3
);

CREATE TEMP TABLE t_variety_d1 AS
SELECT mpec.recipe_id
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
WHERE mp.user_id       = 'eeeeffff-0000-4000-8000-000000000099'::uuid
  AND mpe.scheduled_date = (CURRENT_DATE + 1)::date
  AND mpec.role         = 'base';

SELECT public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 20)::date, 3
);

-- day+20 window = [day+5, day+20): day+1 is before day+5, so NOT blacklisted.
-- A recipes (higher score) should be selected again at day+20.
SELECT ok(
  EXISTS(
    SELECT 1
    FROM meal_plan_entry mpe2
    JOIN meal_plan_entry_component mpec2 ON mpec2.meal_plan_entry_id = mpe2.id
    JOIN meal_plan mp2 ON mp2.id = mpe2.meal_plan_id
    WHERE mp2.user_id        = 'eeeeffff-0000-4000-8000-000000000099'::uuid
      AND mpe2.scheduled_date = (CURRENT_DATE + 20)::date
      AND mpec2.role          = 'base'
      AND mpec2.recipe_id IN (SELECT recipe_id FROM t_variety_d1)
  ),
  '15-day window is date-relative: plan at day+20 reuses day+1 recipes (gap=19 > 15, window=[day+5,day+20))'
);

-- ─── Test 5: fallback path — pool exhausted, Pass 2 generates without error ──
-- day+212 window = [day+197, day+212): contains day+200 (A) and day+208 (B) → all 6 recipes blacklisted.
SELECT lives_ok(
  $$ SELECT public.generate_meal_plan(
       'eeeeffff-0000-4000-8000-000000000099'::uuid,
       1, 3, (CURRENT_DATE + 212)::date, 3
     ) $$,
  'fallback: when entire pool is blacklisted (day+212, both A+B in window), Pass 2 generates plan successfully'
);

SELECT * FROM finish();

ROLLBACK;
