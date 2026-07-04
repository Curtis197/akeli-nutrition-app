-- supabase/tests/recalculate_nutrition_plans_from_weight_test.sql
BEGIN;
SELECT plan(35);

-- Helper: seeds one test user with a health profile, goal, nutrition plan,
-- and (optionally) a weight_log entry. Reused across all scenarios below.
CREATE OR REPLACE FUNCTION _test_seed_recalc_user(
  p_user_id             uuid,
  p_weight_log_kg       numeric,   -- NULL = no weight_log row inserted
  p_weight_log_days_ago int,       -- ignored when p_weight_log_kg IS NULL
  p_height_cm           numeric,   -- NULL = leave height_cm NULL (incomplete profile)
  p_age_years           int,       -- NULL = leave birth_date NULL (incomplete profile)
  p_sex                 text,
  p_activity_level      text,
  p_goal_type           text,
  p_goal_active         boolean,
  p_plan_active         boolean,
  p_sentinel_calorie    int        -- pre-set on nutrition_plan + user_goal; unchanged = "not recalculated"
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES (p_user_id, p_user_id::text || '@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, role, locale)
  VALUES (p_user_id, true, false, now(), 'user', 'fr')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_health_profile (user_id, sex, birth_date, height_cm, activity_level)
  VALUES (
    p_user_id,
    p_sex,
    CASE WHEN p_age_years IS NULL THEN NULL
         ELSE (CURRENT_DATE - (p_age_years || ' years')::interval)::date END,
    p_height_cm,
    p_activity_level
  )
  ON CONFLICT (user_id) DO UPDATE SET
    sex = EXCLUDED.sex,
    birth_date = EXCLUDED.birth_date,
    height_cm = EXCLUDED.height_cm,
    activity_level = EXCLUDED.activity_level;

  INSERT INTO user_goal (user_id, goal_type, calorie_goal, protein_goal, carbs_goal, fat_goal, is_active)
  VALUES (p_user_id, p_goal_type, p_sentinel_calorie, 1, 1, 1, p_goal_active);

  INSERT INTO nutrition_plan (user_id, calorie_goal, protein_goal_g, carb_goal_g, fat_goal_g, bmr, tdee, is_active)
  VALUES (p_user_id, p_sentinel_calorie, 1, 1, 1, 1, 1, p_plan_active);

  IF p_weight_log_kg IS NOT NULL THEN
    INSERT INTO weight_log (user_id, weight_kg, logged_at)
    VALUES (p_user_id, p_weight_log_kg, CURRENT_DATE - p_weight_log_days_ago);
  END IF;
END;
$$;

-- ── Seed all scenarios ────────────────────────────────────────────────────
-- Base profile for T1/T2/T8/T8b/T9/T11: 64kg, 180cm, age 30 (birth_date is
-- relative to CURRENT_DATE so age is always exactly 30 regardless of run
-- date), male, maintenance goal.
-- bmr = 10*64 + 6.25*180 - 5*30 + 5 = 1620 (exact, no rounding ambiguity)

-- U1: sedentary — tdee = 1620*1.2 = 1944 (maintenance -> calorie_goal = 1944)
SELECT _test_seed_recalc_user(
  'a0000000-0000-4000-8000-000000000001'::uuid, 64.0, 1, 180.0, 30,
  'male', 'sedentary', 'maintenance', true, true, 9999
);

-- T2: activity level mapping — same base profile, only activity_level varies.
-- U2b light:       tdee = 1620*1.375 = 2227.5
-- U2c moderate:    tdee = 1620*1.55  = 2511
-- U2d active:      tdee = 1620*1.725 = 2794.5
-- U2e very_active: tdee = 1620*1.9   = 3078
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000002'::uuid, 64.0, 1, 180.0, 30, 'male', 'light',       'maintenance', true, true, 9999);
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000003'::uuid, 64.0, 1, 180.0, 30, 'male', 'moderate',    'maintenance', true, true, 9999);
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000004'::uuid, 64.0, 1, 180.0, 30, 'male', 'active',      'maintenance', true, true, 9999);
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000005'::uuid, 64.0, 1, 180.0, 30, 'male', 'very_active', 'maintenance', true, true, 9999);

-- T3: stale weight_log (20 days ago, > 14-day window) -> must NOT recalculate
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000007'::uuid, 64.0, 20, 180.0, 30, 'male', 'sedentary', 'maintenance', true, true, 9999);

-- T4: no weight_log at all -> must NOT recalculate
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000008'::uuid, NULL, NULL, 180.0, 30, 'male', 'sedentary', 'maintenance', true, true, 9999);

-- T5: incomplete profile (birth_date NULL) -> must NOT recalculate
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000009'::uuid, 64.0, 1, 180.0, NULL, 'male', 'sedentary', 'maintenance', true, true, 9999);

-- T6: no active user_goal -> must NOT recalculate
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000010'::uuid, 64.0, 1, 180.0, 30, 'male', 'sedentary', 'maintenance', false, true, 9999);

-- T7: no active nutrition_plan -> must NOT recalculate
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000011'::uuid, 64.0, 1, 180.0, 30, 'male', 'sedentary', 'maintenance', true, false, 9999);

-- T10a: weight_loss — same base bmr/tdee (1620/1944).
-- calorie_goal = 1944-500 = 1444; protein=30%,carb=40%,fat=30%
-- protein_g = 1444*0.30/4 = 108.3 ; carb_g = 1444*0.40/4 = 144.4
-- fat_g = 1444*0.30/9 = 48.1333... (repeating; assert rounded to 4dp)
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000012'::uuid, 64.0, 1, 180.0, 30, 'male', 'sedentary', 'weight_loss', true, true, 9999);

-- T10b: muscle_gain — calorie_goal = 1944+300 = 2244; protein=30%,carb=45%,fat=25%
-- protein_g = 2244*0.30/4 = 168.3 ; carb_g = 2244*0.45/4 = 252.45
-- fat_g = 2244*0.25/9 = 62.3333... (repeating; assert rounded to 4dp)
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000013'::uuid, 64.0, 1, 180.0, 30, 'male', 'sedentary', 'muscle_gain', true, true, 9999);

-- T12: duplicate active user_goal rows — dedup regression guard for
-- latest_goal. Same base profile as U1 (64kg/180cm/age30/male/sedentary) ->
-- bmr=1620, tdee=1944. Two active user_goal rows are seeded for the SAME
-- user at distinct created_at timestamps; the function must pick only the
-- most-recently-created active row (muscle_gain) and must not touch the
-- older one (weight_loss).
SELECT _test_seed_recalc_user(
  'a0000000-0000-4000-8000-000000000014'::uuid, 64.0, 1, 180.0, 30,
  'male', 'sedentary', 'maintenance', true, true, 9999
);

-- The helper above seeds exactly one user_goal row; replace it with two
-- active rows at explicit, distinct created_at values to reproduce the
-- "multiple active user_goal rows per user" scenario.
DELETE FROM user_goal WHERE user_id = 'a0000000-0000-4000-8000-000000000014'::uuid;

-- Older active goal (created yesterday): must be left untouched.
INSERT INTO user_goal (user_id, goal_type, calorie_goal, protein_goal, carbs_goal, fat_goal, is_active, created_at)
VALUES ('a0000000-0000-4000-8000-000000000014'::uuid, 'weight_loss', 8888, 1, 1, 1, true, now() - interval '1 day');

-- Newer active goal (created now): this is the one latest_goal must pick.
-- calorie_goal = tdee + 300 = 1944 + 300 = 2244 (muscle_gain branch)
INSERT INTO user_goal (user_id, goal_type, calorie_goal, protein_goal, carbs_goal, fat_goal, is_active, created_at)
VALUES ('a0000000-0000-4000-8000-000000000014'::uuid, 'muscle_gain', 9999, 1, 1, 1, true, now());

-- T9: meal_distribution cascade — add a 3-slot distribution to U1's plan.
INSERT INTO meal_distribution (nutrition_plan_id, meal_type, sort_order, calorie_pct, calorie_target)
SELECT id, 'breakfast', 0, 30, 30.0 * 9999 / 100 FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true
UNION ALL
SELECT id, 'lunch', 1, 35, 35.0 * 9999 / 100 FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true
UNION ALL
SELECT id, 'dinner', 2, 35, 35.0 * 9999 / 100 FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true;

-- ── Run the function once (set-based — processes all seeded users) ─────────
-- T11: exactly 8 users are eligible (U1, U2b-e, T10a, T10b, U14); the other 5
-- (T3-T7) are excluded by the candidate-selection conditions.
SELECT is(
  (SELECT recalculate_nutrition_plans_from_weight()),
  8,
  'T11: returns count of 8 eligible users'
);

-- ── T1: standard recalculation (nutrition_plan) ─────────────────────────────
SELECT is((SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 1944, 'T1: calorie_goal');
SELECT is((SELECT bmr FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 1620::numeric, 'T1: bmr');
SELECT is((SELECT tdee FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 1944::numeric, 'T1: tdee');
SELECT is((SELECT protein_goal_g FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 121.5::numeric, 'T1: protein_goal_g');
SELECT is((SELECT carb_goal_g FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 243::numeric, 'T1: carb_goal_g');
SELECT is((SELECT fat_goal_g FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 54::numeric, 'T1: fat_goal_g');

-- ── T8b: user_goal numeric sync ──────────────────────────────────────────────
SELECT is((SELECT calorie_goal FROM user_goal WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 1944::numeric, 'T8b: user_goal.calorie_goal');
SELECT is((SELECT protein_goal FROM user_goal WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 121.5::numeric, 'T8b: user_goal.protein_goal');
SELECT is((SELECT carbs_goal FROM user_goal WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 243::numeric, 'T8b: user_goal.carbs_goal');
SELECT is((SELECT fat_goal FROM user_goal WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true), 54::numeric, 'T8b: user_goal.fat_goal');

-- ── T8: weight_kg snapshot sync ──────────────────────────────────────────────
SELECT is((SELECT weight_kg FROM user_health_profile WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid), 64.0::numeric, 'T8: weight_kg synced');

-- ── T2: activity level mapping (tdee only — no rounding ambiguity) ──────────
SELECT is((SELECT tdee FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000002'::uuid AND is_active = true), 2227.5::numeric, 'T2: light -> 1.375x');
SELECT is((SELECT tdee FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000003'::uuid AND is_active = true), 2511::numeric, 'T2: moderate -> 1.55x');
SELECT is((SELECT tdee FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000004'::uuid AND is_active = true), 2794.5::numeric, 'T2: active -> 1.725x');
SELECT is((SELECT tdee FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000005'::uuid AND is_active = true), 3078::numeric, 'T2: very_active -> 1.9x');

-- ── T3-T7: skip conditions — sentinel calorie_goal untouched ────────────────
SELECT is((SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000007'::uuid AND is_active = true), 9999, 'T3: stale weight_log skipped');
SELECT is((SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000008'::uuid AND is_active = true), 9999, 'T4: no weight_log skipped');
SELECT is((SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000009'::uuid AND is_active = true), 9999, 'T5: incomplete profile skipped');
SELECT is((SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000010'::uuid AND is_active = true), 9999, 'T6: no active goal skipped');
SELECT is((SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000011'::uuid AND is_active = false), 9999, 'T7: no active plan skipped');

-- ── T10a: weight_loss branch ─────────────────────────────────────────────────
SELECT is((SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000012'::uuid AND is_active = true), 1444, 'T10a: weight_loss calorie_goal');
SELECT is((SELECT protein_goal_g FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000012'::uuid AND is_active = true), 108.3::numeric, 'T10a: weight_loss protein_g');
SELECT is((SELECT carb_goal_g FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000012'::uuid AND is_active = true), 144.4::numeric, 'T10a: weight_loss carb_g');
SELECT is((SELECT round(fat_goal_g, 4) FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000012'::uuid AND is_active = true), 48.1333::numeric, 'T10a: weight_loss fat_g (rounded)');

-- ── T10b: muscle_gain branch ─────────────────────────────────────────────────
SELECT is((SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000013'::uuid AND is_active = true), 2244, 'T10b: muscle_gain calorie_goal');
SELECT is((SELECT protein_goal_g FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000013'::uuid AND is_active = true), 168.3::numeric, 'T10b: muscle_gain protein_g');
SELECT is((SELECT carb_goal_g FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000013'::uuid AND is_active = true), 252.45::numeric, 'T10b: muscle_gain carb_g');
SELECT is((SELECT round(fat_goal_g, 4) FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000013'::uuid AND is_active = true), 62.3333::numeric, 'T10b: muscle_gain fat_g (rounded)');

-- ── T12: duplicate active user_goal rows — only the latest is updated ──────
-- Verifies the latest_goal DISTINCT ON dedup guard: nutrition_plan must
-- reflect the NEWER row's goal_type (muscle_gain), the newer row itself must
-- be updated, and the OLDER row must be left completely untouched.
SELECT is(
  (SELECT calorie_goal FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000014'::uuid AND is_active = true),
  2244,
  'T12: nutrition_plan.calorie_goal reflects newer (muscle_gain) goal_type'
);
SELECT is(
  (SELECT calorie_goal FROM user_goal WHERE user_id = 'a0000000-0000-4000-8000-000000000014'::uuid AND goal_type = 'muscle_gain'),
  2244::numeric,
  'T12: newer user_goal row (muscle_gain) updated'
);
SELECT is(
  (SELECT calorie_goal FROM user_goal WHERE user_id = 'a0000000-0000-4000-8000-000000000014'::uuid AND goal_type = 'weight_loss'),
  8888::numeric,
  'T12: older user_goal row (weight_loss) left untouched'
);

-- ── T9: meal_distribution cascade (trg_sync_calorie_target_on_plan) ─────────
SELECT is(
  (SELECT calorie_target FROM meal_distribution md JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
   WHERE np.user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND np.is_active = true AND md.meal_type = 'breakfast'),
  (1944 * 30 / 100.0)::numeric, 'T9: breakfast calorie_target cascades'
);
SELECT is(
  (SELECT calorie_target FROM meal_distribution md JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
   WHERE np.user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND np.is_active = true AND md.meal_type = 'lunch'),
  (1944 * 35 / 100.0)::numeric, 'T9: lunch calorie_target cascades'
);
SELECT is(
  (SELECT calorie_target FROM meal_distribution md JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
   WHERE np.user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND np.is_active = true AND md.meal_type = 'dinner'),
  (1944 * 35 / 100.0)::numeric, 'T9: dinner calorie_target cascades'
);

SELECT * FROM finish();
ROLLBACK;
