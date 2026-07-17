-- supabase/tests/generate_meal_plan_custom_schedule_test.sql
BEGIN;
SELECT plan(15);

-- ── Shared seed helpers ──────────────────────────────────────────────────────

-- We test with a fixed test user uuid that must exist in auth.users.
-- In the local Supabase environment, use the seeded test user.
DO $$
BEGIN
  -- Ensure test user exists in auth.users (idempotent)
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES ('00000000-0000-0000-0000-000000000001', 'test@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES ('00000000-0000-0000-0000-000000000001', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  -- Test calorie goal
  INSERT INTO user_goal (user_id, calorie_goal, protein_goal, fat_goal, is_active, created_at)
  VALUES ('00000000-0000-0000-0000-000000000001', 2000, 125, 55, true, now())
  ON CONFLICT DO NOTHING;
END $$;

-- Helper: upsert a nutrition_plan + distributions for the test user
CREATE OR REPLACE FUNCTION _test_setup_plan(p_distributions JSONB[])
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_plan_id uuid;
  v_dist JSONB;
  v_idx int := 0;
BEGIN
  -- Deactivate existing
  UPDATE nutrition_plan SET is_active = false
  WHERE user_id = '00000000-0000-0000-0000-000000000001';

  INSERT INTO nutrition_plan (user_id, calorie_goal, protein_goal_g, carb_goal_g, fat_goal_g, is_active)
  VALUES ('00000000-0000-0000-0000-000000000001', 2000, 125, 225, 55, true)
  RETURNING id INTO v_plan_id;

  FOREACH v_dist IN ARRAY p_distributions LOOP
    INSERT INTO meal_distribution (nutrition_plan_id, meal_type, sort_order, calorie_pct,
      calorie_target, nickname, protein_pct, fat_pct, carbs_pct)
    VALUES (
      v_plan_id,
      v_dist->>'meal_type',
      v_idx,
      (v_dist->>'calorie_pct')::double precision,
      (v_dist->>'calorie_target')::double precision,
      v_dist->>'nickname',
      (v_dist->>'protein_pct')::double precision,
      (v_dist->>'fat_pct')::double precision,
      (v_dist->>'carbs_pct')::double precision
    );
    v_idx := v_idx + 1;
  END LOOP;

  RETURN v_plan_id;
END $$;

-- Helper: count entries per day for a generated plan
CREATE OR REPLACE FUNCTION _test_entries_per_day(p_user_id uuid, p_date date)
RETURNS int LANGUAGE sql AS $$
  SELECT count(*)::int FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = p_user_id AND mpe.scheduled_date = p_date;
$$;

-- Helper: get meal_types for a day, sorted
CREATE OR REPLACE FUNCTION _test_meal_types_for_day(p_user_id uuid, p_date date)
RETURNS text[] LANGUAGE sql AS $$
  SELECT array_agg(mpe.meal_type ORDER BY mpe.sort_order)
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = p_user_id AND mpe.scheduled_date = p_date;
$$;

-- Seed: measurement unit (FK required by recipe_ingredient.unit)
INSERT INTO public.measurement_unit (code, name_fr, name_en)
VALUES ('g', 'g', 'g') ON CONFLICT (code) DO NOTHING;

-- Seed: ingredients used in recipe_ingredient rows
INSERT INTO public.ingredient (id, name, name_fr) VALUES
  ('f0000000-0000-0000-0000-000000000001'::uuid, 'Millet',  'Millet'),
  ('f0000000-0000-0000-0000-000000000002'::uuid, 'Peanut',  'Arachide'),
  ('f0000000-0000-0000-0000-000000000003'::uuid, 'Yam',     'Igname')
ON CONFLICT (id) DO NOTHING;

-- Seed: 3 recipes covering every meal type (breakfast/lunch/dinner/snack).
-- 3 recipes × max_repeat=3 = 9 available slots — covers the 5-slot T4 test.
INSERT INTO public.recipe (id, title, is_published, meal_types, allergen_tags) VALUES
  ('e0000000-1000-0000-0000-000000000001'::uuid, 'Test Recipe A', true, ARRAY['breakfast','lunch','dinner','snack'], ARRAY[]::text[]),
  ('e0000000-1000-0000-0000-000000000002'::uuid, 'Test Recipe B', true, ARRAY['breakfast','lunch','dinner','snack'], ARRAY[]::text[]),
  ('e0000000-1000-0000-0000-000000000003'::uuid, 'Test Recipe C', true, ARRAY['breakfast','lunch','dinner','snack'], ARRAY[]::text[])
ON CONFLICT (id) DO NOTHING;

-- Seed: recipe_macro with total_weight_g so GENERATED kcal_per_100g > 0
-- (generator filters rm.kcal_per_100g > 0; requires total_weight_g IS NOT NULL and > 0)
INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g) VALUES
  ('e0000000-1000-0000-0000-000000000001'::uuid, 500, 25, 60, 15, 300),
  ('e0000000-1000-0000-0000-000000000002'::uuid, 600, 30, 70, 18, 350),
  ('e0000000-1000-0000-0000-000000000003'::uuid, 450, 20, 55, 12, 270)
ON CONFLICT (recipe_id) DO NOTHING;

-- Seed: one recipe_ingredient each (needed for meal_ingredient population in generator)
INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional) VALUES
  ('e0000000-1000-0000-0000-000000000001'::uuid, 'f0000000-0000-0000-0000-000000000001'::uuid, 100, 'g', false),
  ('e0000000-1000-0000-0000-000000000002'::uuid, 'f0000000-0000-0000-0000-000000000002'::uuid, 120, 'g', false),
  ('e0000000-1000-0000-0000-000000000003'::uuid, 'f0000000-0000-0000-0000-000000000003'::uuid, 150, 'g', false)
ON CONFLICT DO NOTHING;

-- Set auth.uid() context for all calls
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001"}';

-- ── T1: Default fallback — no distribution ───────────────────────────────────
UPDATE nutrition_plan SET is_active = false
WHERE user_id = '00000000-0000-0000-0000-000000000001';

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 3, CURRENT_DATE, 3) $$,
  'T1: generates with default 3-meal fallback'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE),
  3,
  'T1: 3 entries generated for today'
);

-- ── T2: Standard 3-meal explicit ─────────────────────────────────────────────
SELECT _test_setup_plan(ARRAY[
  '{"meal_type":"breakfast","calorie_pct":30,"calorie_target":600}'::JSONB,
  '{"meal_type":"lunch","calorie_pct":35,"calorie_target":700}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":35,"calorie_target":700}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 3, CURRENT_DATE + 1, 3) $$,
  'T2: generates 3-meal plan'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 1),
  3,
  'T2: 3 entries for tomorrow'
);

-- ── T3: No breakfast ─────────────────────────────────────────────────────────
SELECT _test_setup_plan(ARRAY[
  '{"meal_type":"lunch","calorie_pct":40,"calorie_target":800}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":60,"calorie_target":1200}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 2, CURRENT_DATE + 2, 3) $$,
  'T3: generates no-breakfast plan'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 2),
  2,
  'T3: exactly 2 entries (no breakfast)'
);
SELECT ok(
  NOT ('breakfast' = ANY(_test_meal_types_for_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 2))),
  'T3: no breakfast entry'
);

-- ── T4: 3 collations + lunch + dinner ────────────────────────────────────────
SELECT _test_setup_plan(ARRAY[
  '{"meal_type":"lunch","calorie_pct":25,"calorie_target":500}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":35,"calorie_target":700}'::JSONB,
  '{"meal_type":"snack","calorie_pct":15,"calorie_target":300,"nickname":"Collation matin"}'::JSONB,
  '{"meal_type":"snack","calorie_pct":15,"calorie_target":300,"nickname":"Collation après-midi"}'::JSONB,
  '{"meal_type":"snack","calorie_pct":10,"calorie_target":200,"nickname":"Collation soir"}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 5, CURRENT_DATE + 3, 3) $$,
  'T4: generates 5-slot plan (lunch+dinner+3 snacks)'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 3),
  5,
  'T4: 5 entries generated'
);

-- ── T5: Heavy dinner, light lunch ────────────────────────────────────────────
SELECT _test_setup_plan(ARRAY[
  '{"meal_type":"lunch","calorie_pct":20,"calorie_target":400}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":55,"calorie_target":1100}'::JSONB,
  '{"meal_type":"snack","calorie_pct":25,"calorie_target":500}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 3, CURRENT_DATE + 4, 3) $$,
  'T5: heavy dinner plan generates'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 4),
  3,
  'T5: 3 entries'
);

-- ── T9: Nickname propagation ──────────────────────────────────────────────────
SELECT _test_setup_plan(ARRAY[
  '{"meal_type":"snack","calorie_pct":50,"calorie_target":1000,"nickname":"Collation du matin"}'::JSONB,
  '{"meal_type":"snack","calorie_pct":50,"calorie_target":1000,"nickname":"Collation du soir"}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 2, CURRENT_DATE + 5, 3) $$,
  'T9: nickname plan generates'
);
SELECT ok(
  EXISTS(
    SELECT 1 FROM meal_plan_entry mpe
    JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mp.user_id = '00000000-0000-0000-0000-000000000001'
      AND mpe.scheduled_date = CURRENT_DATE + 5
      AND mpe.nickname = 'Collation du matin'
  ),
  'T9: nickname "Collation du matin" propagated to entry'
);

-- ── T11: sort_order preserved ─────────────────────────────────────────────────
SELECT _test_setup_plan(ARRAY[
  '{"meal_type":"lunch","calorie_pct":40,"calorie_target":800}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":60,"calorie_target":1200}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 2, CURRENT_DATE + 6, 3) $$,
  'T11: generates with sort_order'
);
SELECT ok(
  (SELECT array_agg(mpe.sort_order ORDER BY mpe.sort_order)
   FROM meal_plan_entry mpe
   JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
   WHERE mp.user_id = '00000000-0000-0000-0000-000000000001'
     AND mpe.scheduled_date = CURRENT_DATE + 6) = ARRAY[0, 1],
  'T11: sort_order 0 and 1 set on entries'
);

SELECT * FROM finish();
ROLLBACK;
