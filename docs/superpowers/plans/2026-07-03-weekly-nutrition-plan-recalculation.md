# Weekly Nutrition Plan Recalculation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a weekly cron job that recalculates each user's `nutrition_plan` calorie/macro targets from their most recently logged weight, keeping `user_goal` and `user_health_profile.weight_kg` in sync, so the Monday meal-plan generation batch reads up-to-date targets.

**Architecture:** A single set-based Postgres function (`recalculate_nutrition_plans_from_weight()`) recomputes BMR/TDEE/calorie-goal/macros for every eligible user in one SQL statement and writes to `nutrition_plan`, `user_goal`, and `user_health_profile`. A thin Deno edge function invokes that one RPC and is registered as a `pg_cron` job firing Sunday 23:00 UTC — two hours before the existing Monday 01:00 UTC `batch-generate-meal-plans-weekly` job.

**Tech Stack:** PostgreSQL (plpgsql, pg_cron, pgTAP), Supabase Edge Functions (Deno/TypeScript).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-03-weekly-nutrition-plan-recalculation-design.md` — read this first; this plan implements it exactly.
- The Deno edge function MUST follow the project's mandatory logging standard (`CLAUDE.md`): `createLogger`, ENTRY/EXIT logs, `[STEP N]` labels, `logRLSCheck`/`logQueryResult`, catch-all error handler. SQL functions are not covered by this mandate (no Dart/Deno file).
- No l10n changes — this feature has no Dart/UI surface.
- Formula must be an exact port of `lib/core/nutrition_calculator.dart` + the DB-value activity mapping in `lib/providers/health_profile_provider.dart:14-29` (verbatim values given in Task 1).
- Migration filenames use this repo's `YYYYMMDDHHMMSS_description.sql` convention; the next available timestamps as of 2026-07-03 are `20260703000000` and `20260703000001`.
- Project ref for the remote Supabase project (used in cron `net.http_post` URLs, matching existing cron migrations): `njzqcftjzskwcpforwzf`.

---

### Task 1: SQL recalculation function + pgTAP tests

**Files:**
- Create: `supabase/migrations/20260703000000_add_recalculate_nutrition_plans_function.sql`
- Create: `supabase/tests/recalculate_nutrition_plans_from_weight_test.sql`

**Interfaces:**
- Produces: `public.recalculate_nutrition_plans_from_weight()` — no params, `RETURNS integer` (count of users updated). Callable only by `service_role` (matches `generate_meal_plan_internal` convention: `REVOKE ALL ... FROM PUBLIC/anon/authenticated`). Task 3's edge function calls this via `supabase.rpc("recalculate_nutrition_plans_from_weight")`.

- [ ] **Step 1: Write the pgTAP test file (fails — function doesn't exist yet)**

Create `supabase/tests/recalculate_nutrition_plans_from_weight_test.sql`:

```sql
-- supabase/tests/recalculate_nutrition_plans_from_weight_test.sql
BEGIN;
SELECT plan(32);

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

-- T9: meal_distribution cascade — add a 3-slot distribution to U1's plan.
INSERT INTO meal_distribution (nutrition_plan_id, meal_type, sort_order, calorie_pct, calorie_target)
SELECT id, 'breakfast', 0, 30, 30.0 * 9999 / 100 FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true
UNION ALL
SELECT id, 'lunch', 1, 35, 35.0 * 9999 / 100 FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true
UNION ALL
SELECT id, 'dinner', 2, 35, 35.0 * 9999 / 100 FROM nutrition_plan WHERE user_id = 'a0000000-0000-4000-8000-000000000001'::uuid AND is_active = true;

-- ── Run the function once (set-based — processes all seeded users) ─────────
-- T11: exactly 7 users are eligible (U1, U2b-e, T10a, T10b); the other 5
-- (T3-T7) are excluded by the candidate-selection conditions.
SELECT is(
  (SELECT recalculate_nutrition_plans_from_weight()),
  7,
  'T11: returns count of 7 eligible users'
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `supabase test db`
Expected: FAILS — `function recalculate_nutrition_plans_from_weight() does not exist`

- [ ] **Step 3: Write the migration with the function**

Create `supabase/migrations/20260703000000_add_recalculate_nutrition_plans_function.sql`:

```sql
-- Migration: add_recalculate_nutrition_plans_function
-- Weekly recalculation of nutrition_plan/user_goal targets from the user's
-- most recently logged weight. Formula is an exact port of
-- lib/core/nutrition_calculator.dart (Mifflin-St Jeor BMR, activity
-- multiplier, goal-based calorie offset, macro percentage splits) combined
-- with the DB-value activity_level mapping in
-- lib/providers/health_profile_provider.dart:14-29 (activityLevelForCalculator).
-- If that formula ever changes, update both places together.

CREATE OR REPLACE FUNCTION public.recalculate_nutrition_plans_from_weight()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_updated_count integer;
BEGIN
  WITH latest_weight AS (
    SELECT DISTINCT ON (wl.user_id)
      wl.user_id,
      wl.weight_kg
    FROM weight_log wl
    WHERE wl.logged_at >= CURRENT_DATE - INTERVAL '14 days'
    ORDER BY wl.user_id, wl.logged_at DESC, wl.created_at DESC
  ),
  candidates AS (
    SELECT
      np.id                                                     AS plan_id,
      ug.id                                                      AS goal_id,
      hp.user_id                                                 AS user_id,
      lw.weight_kg                                               AS weight_kg,
      hp.height_cm                                               AS height_cm,
      DATE_PART('year', AGE(CURRENT_DATE, hp.birth_date))::int   AS age,
      hp.sex                                                     AS sex,
      hp.activity_level                                          AS activity_level,
      ug.goal_type                                                AS goal_type
    FROM user_health_profile hp
    JOIN latest_weight lw  ON lw.user_id = hp.user_id
    JOIN nutrition_plan np ON np.user_id = hp.user_id AND np.is_active = true
    JOIN user_goal ug      ON ug.user_id = hp.user_id AND ug.is_active = true
    WHERE hp.height_cm IS NOT NULL
      AND hp.birth_date IS NOT NULL
      AND hp.sex IS NOT NULL
  ),
  with_bmr AS (
    -- Mifflin-St Jeor, mirrors calculateBMR (nutrition_calculator.dart:3-16).
    -- sex = 'other' falls into the ELSE (-161) branch, matching the Dart code.
    SELECT
      c.*,
      (10 * c.weight_kg + 6.25 * c.height_cm - 5 * c.age
        + CASE WHEN c.sex = 'male' THEN 5 ELSE -161 END) AS bmr_calc
    FROM candidates c
  ),
  with_tdee AS (
    -- Combines activityLevelForCalculator's DB-value mapping with
    -- calculateTDEE's multipliers in one CASE (health_profile_provider.dart:14-29).
    SELECT
      w.*,
      w.bmr_calc * (CASE w.activity_level
        WHEN 'sedentary'   THEN 1.2
        WHEN 'light'       THEN 1.375
        WHEN 'moderate'    THEN 1.55
        WHEN 'active'      THEN 1.725
        WHEN 'very_active' THEN 1.9
        ELSE 1.2
      END) AS tdee_calc
    FROM with_bmr w
  ),
  with_calorie_goal AS (
    -- Mirrors calculateCalorieGoal + getDefaultMacros (nutrition_calculator.dart:35-51).
    SELECT
      w.*,
      ROUND(CASE w.goal_type
        WHEN 'weight_loss' THEN w.tdee_calc - 500
        WHEN 'muscle_gain' THEN w.tdee_calc + 300
        ELSE w.tdee_calc
      END)::integer AS calorie_goal_calc,
      CASE w.goal_type WHEN 'weight_loss' THEN 30 WHEN 'muscle_gain' THEN 30 ELSE 25 END AS protein_pct,
      CASE w.goal_type WHEN 'weight_loss' THEN 40 WHEN 'muscle_gain' THEN 45 ELSE 50 END AS carb_pct,
      CASE w.goal_type WHEN 'weight_loss' THEN 30 WHEN 'muscle_gain' THEN 25 ELSE 25 END AS fat_pct
    FROM with_tdee w
  ),
  final AS (
    -- Mirrors calculateMacroGrams (nutrition_calculator.dart:53-60): fat / 9, protein & carbs / 4.
    SELECT
      w.plan_id,
      w.goal_id,
      w.user_id,
      w.weight_kg,
      w.bmr_calc,
      w.tdee_calc,
      w.calorie_goal_calc,
      (w.calorie_goal_calc * w.protein_pct / 100.0 / 4.0) AS protein_g_calc,
      (w.calorie_goal_calc * w.carb_pct    / 100.0 / 4.0) AS carb_g_calc,
      (w.calorie_goal_calc * w.fat_pct     / 100.0 / 9.0) AS fat_g_calc
    FROM with_calorie_goal w
  ),
  -- Chained data-modifying CTEs: each subsequent UPDATE reads the previous
  -- one's RETURNING output, guaranteeing the whole chain executes when the
  -- final SELECT references the last one.
  updated_plans AS (
    UPDATE nutrition_plan np
    SET calorie_goal   = f.calorie_goal_calc,
        bmr            = f.bmr_calc,
        tdee           = f.tdee_calc,
        protein_goal_g = f.protein_g_calc,
        carb_goal_g    = f.carb_g_calc,
        fat_goal_g     = f.fat_g_calc
    FROM final f
    WHERE np.id = f.plan_id
    RETURNING np.id AS plan_id, f.goal_id, f.user_id, f.weight_kg,
              f.calorie_goal_calc, f.protein_g_calc, f.carb_g_calc, f.fat_g_calc
  ),
  updated_goals AS (
    -- Keeps generate_meal_plan_internal's fallback and swap_meal_plan_entry
    -- (both read user_goal.calorie_goal directly) from drifting out of sync.
    UPDATE user_goal ug
    SET calorie_goal = up.calorie_goal_calc,
        protein_goal = up.protein_g_calc,
        carbs_goal   = up.carb_g_calc,
        fat_goal     = up.fat_g_calc
    FROM updated_plans up
    WHERE ug.id = up.goal_id
    RETURNING ug.id AS goal_id, up.user_id, up.weight_kg
  ),
  updated_profiles AS (
    UPDATE user_health_profile hp
    SET weight_kg = ug2.weight_kg
    FROM updated_goals ug2
    WHERE hp.user_id = ug2.user_id
    RETURNING hp.user_id
  )
  SELECT COUNT(*) INTO v_updated_count FROM updated_profiles;

  RETURN COALESCE(v_updated_count, 0);
END;
$function$;

-- Security: restrict execute to service_role/postgres only, same convention
-- as generate_meal_plan_internal — prevents any Supabase client from calling
-- this via PostgREST RPC.
REVOKE ALL ON FUNCTION public.recalculate_nutrition_plans_from_weight() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.recalculate_nutrition_plans_from_weight() FROM anon;
REVOKE ALL ON FUNCTION public.recalculate_nutrition_plans_from_weight() FROM authenticated;
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `supabase test db`
Expected: `recalculate_nutrition_plans_from_weight_test.sql ... ok` — all 32 assertions pass, total suite now `Files=5, Tests=65` (verified baseline before this task was `Files=4, Tests=33`).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260703000000_add_recalculate_nutrition_plans_function.sql supabase/tests/recalculate_nutrition_plans_from_weight_test.sql
git commit -m "feat: add recalculate_nutrition_plans_from_weight SQL function

Weekly weight-based recalculation of BMR/TDEE/calorie/macro targets,
ported from nutrition_calculator.dart. Updates nutrition_plan, user_goal,
and user_health_profile.weight_kg for every eligible user in one
set-based statement."
```

---

### Task 2: Cron registration migration

**Files:**
- Create: `supabase/migrations/20260703000001_register_recalculate_nutrition_plans_cron.sql`

**Interfaces:**
- Consumes: none (registers a pg_cron job that calls the edge function built in Task 3 — the job registration doesn't depend on the function existing yet, since `pg_cron` doesn't validate the target URL at schedule time).
- Produces: a `pg_cron` job named `recalculate-nutrition-plans-weekly` at `0 23 * * 0` (Sunday 23:00 UTC).

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/20260703000001_register_recalculate_nutrition_plans_cron.sql`:

```sql
-- Register weekly nutrition plan recalculation cron job.
-- Fires every Sunday at 23:00 UTC — two hours before
-- batch-generate-meal-plans-weekly (Monday 01:00 UTC) — so that week's meal
-- plan generation reads the freshly recalculated calorie_goal.
--
-- The INTERNAL_SECRET must be in Vault before this migration is applied
-- (it already is, reused from the existing batch-generate-meal-plans and
-- send-meal-reminders cron jobs).

-- Cron registration — skipped silently on local where pg_cron is not installed.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
    -- Idempotent: unschedule first so re-runs don't error or duplicate
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'recalculate-nutrition-plans-weekly';

    PERFORM cron.schedule(
      'recalculate-nutrition-plans-weekly',
      '0 23 * * 0',
      $cmd$
      SELECT net.http_post(
        url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/recalculate-nutrition-plans',
        headers := jsonb_build_object(
          'Content-Type',      'application/json',
          'x-internal-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET' ORDER BY created_at DESC LIMIT 1)
        ),
        body    := '{}'::jsonb
      ) AS request_id;
      $cmd$
    );
  END IF;
END;
$$;
```

- [ ] **Step 2: Verify the migration applies cleanly**

Run: `supabase db reset`
Expected: no errors during migration replay (the `IF EXISTS (... schema_name = 'cron')` guard means this is a no-op on local, matching the two existing cron migrations' behavior).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260703000001_register_recalculate_nutrition_plans_cron.sql
git commit -m "feat: register weekly nutrition plan recalculation cron job

Fires Sunday 23:00 UTC, two hours before the Monday meal-plan batch job,
so that week's plan generation reads the recalculated calorie_goal."
```

---

### Task 3: Edge function

**Files:**
- Create: `supabase/functions/recalculate-nutrition-plans/index.ts`

**Interfaces:**
- Consumes: `public.recalculate_nutrition_plans_from_weight()` (Task 1) via `admin.rpc("recalculate_nutrition_plans_from_weight")`; `serviceClient()` and `verifyInternalSecret(req)` from `supabase/functions/_shared/supabase.ts`; `ok`/`serverError` from `supabase/functions/_shared/response.ts`; `createLogger`/`logRLSCheck`/`logQueryResult` from `supabase/functions/_shared/logger.ts`.
- Produces: `POST /functions/v1/recalculate-nutrition-plans` — requires header `x-internal-secret: <INTERNAL_SECRET>`. Returns `{ data: { updated: <count> }, error: null }` on success.

- [ ] **Step 1: Write the edge function**

Create `supabase/functions/recalculate-nutrition-plans/index.ts`:

```typescript
// Cron-only — not callable from Flutter. Secured by x-internal-secret.
// Fires weekly at 23:00 UTC Sunday via pg_cron, two hours before
// batch-generate-meal-plans-weekly, so that week's plan generation reads
// the recalculated calorie_goal.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const logger = createLogger("recalculate-nutrition-plans");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify internal secret");
    if (!verifyInternalSecret(req)) {
      logger.warn("EARLY RETURN | reason: invalid internal secret");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();

    logger.debug("[STEP 2] Calling recalculate_nutrition_plans_from_weight RPC");
    logRLSCheck(logger, "nutrition_plan+user_goal+user_health_profile", "UPDATE", "cron");
    const { data, error } = await admin.rpc("recalculate_nutrition_plans_from_weight");
    logQueryResult(
      logger,
      "nutrition_plan+user_goal+user_health_profile",
      "UPDATE",
      typeof data === "number" ? data : 0,
      error ?? undefined,
    );

    if (error) {
      logger.error("💥 RPC failed", { message: error.message });
      return serverError(error);
    }

    const updated = typeof data === "number" ? data : 0;
    logger.info(`✅ EXIT | updated: ${updated} | duration: ${Date.now() - start}ms`);
    return ok({ updated });
  } catch (e) {
    const caught = e instanceof Error ? e : new Error(String(e));
    logger.error("💥 Unhandled error", { message: caught.message, stack: caught.stack });
    return serverError(caught);
  }
});
```

- [ ] **Step 2: Verify it starts without errors locally**

Run: `supabase functions serve recalculate-nutrition-plans --env-file supabase/.env.local`
Expected: `Serving functions on http://localhost:54321/functions/v1/<function-name>` with no startup errors (Deno type-checks imports on boot, so a typo in the shared-module paths would fail here immediately). Stop the server (Ctrl+C) once confirmed.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/recalculate-nutrition-plans/index.ts
git commit -m "feat: add recalculate-nutrition-plans edge function

Thin cron-only wrapper around recalculate_nutrition_plans_from_weight();
follows the same x-internal-secret + serviceClient pattern as
send-meal-reminders."
```

---

### Task 4: Local end-to-end verification

**Files:**
- None created/modified — this task exercises Tasks 1-3 together against the local Supabase stack.

**Interfaces:**
- Consumes: `recalculate_nutrition_plans_from_weight()` (Task 1), `recalculate-nutrition-plans` edge function (Task 3), and the 4 pre-seeded test users documented in project memory (`test.standard@akeli.local` = `aa000001-0000-4000-8000-000000000001`, etc.), reseeded fresh by `supabase db reset`.

- [ ] **Step 1: Reset the local DB (applies both new migrations + reseeds test data)**

Run: `supabase db reset`
Expected: completes without error; seeds the 4 test users from project memory.

- [ ] **Step 2: Confirm the pgTAP suite passes as part of the full run**

Run: `supabase test db`
Expected: `Files=5, Tests=68, Result: PASS` against a fully fresh reset with only this feature's own tests runnable in isolation (baseline was `Files=4, Tests=33`; Task 1 added 32 assertions, later grown to 35 by the `user_goal` dedup fix's regression test). Note: as of this writing, two unrelated pre-existing bugs in older migrations (documented separately, out of this feature's scope) make a true full-suite fresh-reset run show other files failing — this feature's own test file passes cleanly in isolation via `supabase test db supabase/tests/recalculate_nutrition_plans_from_weight_test.sql` (`Files=1, Tests=35, PASS`).

- [ ] **Step 3: Insert a fresh weight_log entry for test user A (standard)**

Find the local DB container name, then insert a new weight (2kg lighter than whatever default is seeded):

```bash
docker ps | grep db
docker exec <container_name> psql -U postgres -d postgres -c "
INSERT INTO weight_log (user_id, weight_kg, logged_at)
VALUES ('aa000001-0000-4000-8000-000000000001', 68.0, CURRENT_DATE)
ON CONFLICT (user_id, logged_at) DO UPDATE SET weight_kg = EXCLUDED.weight_kg;
"
```

Also ensure user A has a complete health profile and active goal (adjust values as needed if the seed doesn't already set them):

```bash
docker exec <container_name> psql -U postgres -d postgres -c "
SELECT user_id, height_cm, birth_date, sex, activity_level FROM user_health_profile
WHERE user_id = 'aa000001-0000-4000-8000-000000000001';
"
```

Expected: a row with non-null `height_cm`, `birth_date`, `sex`. If any is NULL, set it via `UPDATE user_health_profile SET ... WHERE user_id = '...'` before continuing (the seed from `docs/superpowers/specs` local-meal-plan-testing notes should already have these populated for a 2000 kcal standard user).

- [ ] **Step 4: Start the edge function locally and invoke it**

In one terminal:

```bash
supabase functions serve recalculate-nutrition-plans --env-file supabase/.env.local
```

In another terminal, find the local `INTERNAL_SECRET` value (from `supabase/.env.local` or `supabase secrets list`) and call the function:

```bash
curl -X POST http://localhost:54321/functions/v1/recalculate-nutrition-plans \
  -H "x-internal-secret: <local INTERNAL_SECRET value>" \
  -H "Content-Type: application/json"
```

Expected: `{"data":{"updated":<N>},"error":null}` with status 200, where `N >= 1` (at least test user A should be recalculated).

- [ ] **Step 5: Verify user A's nutrition_plan reflects the new weight**

```bash
docker exec <container_name> psql -U postgres -d postgres -c "
SELECT calorie_goal, bmr, tdee, protein_goal_g, carb_goal_g, fat_goal_g
FROM nutrition_plan WHERE user_id = 'aa000001-0000-4000-8000-000000000001' AND is_active = true;
"
docker exec <container_name> psql -U postgres -d postgres -c "
SELECT weight_kg FROM user_health_profile WHERE user_id = 'aa000001-0000-4000-8000-000000000001';
"
```

Expected: `calorie_goal`/`bmr`/`tdee` differ from their pre-insertion values (reflecting the new 68kg weight), and `user_health_profile.weight_kg` now reads `68.0`.

- [ ] **Step 6: Stop the local function server**

Ctrl+C in the terminal running `supabase functions serve`.

No commit for this task — it's a verification pass over already-committed code, not a code change.

---

### Task 5: Deploy to remote Supabase project

> **This task modifies the live, shared Supabase project used by real users. Confirm explicitly with the user immediately before running any command in this task — do not run it as part of an unattended batch.**

**Files:**
- None created/modified — deploys artifacts from Tasks 1-3.

**Interfaces:**
- Consumes: the two migrations from Tasks 1-2, the edge function from Task 3.
- Produces: the live `recalculate_nutrition_plans_from_weight()` function, the live `recalculate-nutrition-plans` edge function, and the live `recalculate-nutrition-plans-weekly` cron job on project `njzqcftjzskwcpforwzf`.

- [ ] **Step 1: Confirm with the user before proceeding**

Ask explicitly: "Ready to push these 2 migrations and deploy the edge function to the live Supabase project (`njzqcftjzskwcpforwzf`)? This will register a new cron job that starts modifying real users' `nutrition_plan`/`user_goal`/`user_health_profile` data on the next Sunday 23:00 UTC." Do not proceed without an explicit yes.

- [ ] **Step 2: Push migrations**

Run: `supabase db push --project-ref njzqcftjzskwcpforwzf`
Expected: both `20260703000000_...` and `20260703000001_...` apply cleanly with no errors; `supabase migration list --project-ref njzqcftjzskwcpforwzf` shows both as applied remotely.

- [ ] **Step 3: Deploy the edge function**

Run: `supabase functions deploy recalculate-nutrition-plans --project-ref njzqcftjzskwcpforwzf`
Expected: deployment succeeds; function appears in `supabase functions list --project-ref njzqcftjzskwcpforwzf`.

- [ ] **Step 4: Verify the cron job is registered**

Run (via `supabase db execute` or the SQL editor):

```sql
SELECT jobname, schedule, active FROM cron.job WHERE jobname = 'recalculate-nutrition-plans-weekly';
```

Expected: one row, `schedule = '0 23 * * 0'`, `active = true`.

- [ ] **Step 5: Manually invoke once to confirm end-to-end on remote (optional but recommended)**

Using the remote `INTERNAL_SECRET` value (from Supabase Vault, not committed anywhere):

```bash
curl -X POST https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/recalculate-nutrition-plans \
  -H "x-internal-secret: <remote INTERNAL_SECRET value>" \
  -H "Content-Type: application/json"
```

Expected: `{"data":{"updated":<N>},"error":null}` with status 200.

No commit for this task — it is a deployment/operational step, not a code change.
