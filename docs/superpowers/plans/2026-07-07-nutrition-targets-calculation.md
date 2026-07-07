# Nutrition Targets Calculation Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat ±500/+300 kcal calculator with a single Postgres source of truth that derives calories from the user's target weight + target date (pace-based, BMR-floored, surplus-capped), doses protein per kg bodyweight, and guards all user inputs at the field level.

**Architecture:** One new IMMUTABLE SQL function `calculate_nutrition_targets()` is the only place the formula lives. Flutter calls it via RPC from the onboarding/Settings "Calculate" flows; the weekly cron `recalculate_nutrition_plans_from_weight()` calls it via LATERAL join with a 7-day-smoothed weight. `user_health_profile.target_time_weeks` is replaced by a date-anchored `target_date`. The Dart copies of the formula are deleted.

**Tech Stack:** Flutter/Riverpod, Supabase (Postgres + pgTAP + Deno edge functions), local Docker DB.

**Spec:** `docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md` — read it before starting any task.

## Global Constraints

- **Logging standard (CLAUDE.md):** every touched Dart file logs via `appLogger` (`_logger.db` BEFORE/AFTER/ERROR around every RPC, `_logger.userAction` on taps, `_logger.provider` on state transitions); every touched Deno step keeps `[STEP N]` labels and `logQueryResult`.
- **L10n standard (CLAUDE.md):** zero hardcoded user-visible strings. Every new string is added to BOTH `lib/l10n/app_en.arb` AND `lib/l10n/app_fr.arb` before use, then `flutter gen-l10n`.
- **Formula bounds (spec, copy exactly):** weight 30–300 kg, height 120–230 cm, age 18–100; loss pace clamp 1.0 kg/wk; gain pace clamp 0.5 kg/wk; surplus cap 0.20 × TDEE; deficit floor = BMR; defaults 0.5 kg/wk (loss) / 0.25 kg/wk (gain); 7700 kcal/kg (1100/day per kg/wk); protein 2.0/1.8/1.4 g/kg (loss/gain/maintenance), cap 35% kcal, loss ref weight `LEAST(current, target)`; fat 25% kcal; carbs remainder; remaining weeks floor 4.
- **Commands:** SQL tests `supabase test db` (from repo root; local stack must be running — `supabase start`). Flutter: `flutter test`, `flutter analyze`, `flutter gen-l10n`.
- **Commits:** conventional commits, one per task, ending with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- The local DB is the only DB right now (`supabase db push` to remote is deferred project-wide). Never run `db push`.

---

### Task 1: Migration — `target_date` replaces `target_time_weeks`

**Files:**
- Create: `supabase/migrations/20260707000000_health_profile_target_date.sql`

**Interfaces:**
- Produces: column `user_health_profile.target_date date NULL`; column `target_time_weeks` no longer exists. Tasks 3, 6, 10, 11 rely on this.

- [ ] **Step 1: Write the migration**

```sql
-- Migration: health_profile_target_date
-- Replaces target_time_weeks (an unanchored duration) with target_date
-- (a date anchor), per spec D1/D4:
-- docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md §1.3
-- Backfill: existing durations are re-anchored to today. Approximate by
-- design — the local DB has no production users yet.

ALTER TABLE public.user_health_profile
  ADD COLUMN IF NOT EXISTS target_date date;

COMMENT ON COLUMN public.user_health_profile.target_date IS
  'ROLE: Goal deadline | PURPOSE: pace = remaining delta / remaining weeks (floor 4) in calculate_nutrition_targets callers';

UPDATE public.user_health_profile
SET target_date = CURRENT_DATE + (target_time_weeks * 7)
WHERE target_time_weeks IS NOT NULL AND target_date IS NULL;

ALTER TABLE public.user_health_profile
  DROP COLUMN IF EXISTS target_time_weeks;
```

- [ ] **Step 2: Apply and verify**

Run: `supabase migration up`
Then: `docker ps --format "{{.Names}}" | grep supabase_db` to get the container name, and:

```bash
docker exec <container> psql -U postgres -d postgres -c "\d user_health_profile" | grep -E "target_date|target_time_weeks"
```

Expected: `target_date | date` present, no `target_time_weeks` line.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260707000000_health_profile_target_date.sql
git commit -m "feat(db): replace target_time_weeks with date-anchored target_date"
```

---

### Task 2: `calculate_nutrition_targets()` — pgTAP tests + migration (TDD)

**Files:**
- Create: `supabase/tests/calculate_nutrition_targets_test.sql`
- Create: `supabase/migrations/20260707000001_add_calculate_nutrition_targets.sql`

**Interfaces:**
- Produces: `public.calculate_nutrition_targets(p_weight_kg numeric, p_height_cm numeric, p_age int, p_sex text, p_activity_level text, p_primary_goal text, p_target_weight_kg numeric DEFAULT NULL, p_remaining_weeks int DEFAULT NULL) RETURNS TABLE (bmr numeric, tdee numeric, calorie_goal int, protein_g numeric, carb_g numeric, fat_g numeric, effective_pace_kg_week numeric, estimated_weeks_to_target numeric)`. Zero rows on invalid required inputs. Tasks 3 and 5 consume this exact signature.

Reference profiles used below (hand-checked):
- **M:** male 64 kg / 180 cm / 30 y → BMR = 640+1125−150+5 = **1620**; sedentary TDEE = **1944**.
- **F:** female 70 kg / 170 cm / 30 y → BMR = 700+1062.5−150−161 = **1451.5**; moderate TDEE = **2249.825**.

- [ ] **Step 1: Write the failing pgTAP test file**

```sql
-- supabase/tests/calculate_nutrition_targets_test.sql
-- Asserts the single-source-of-truth formula, spec §1 + §6.1:
-- docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md
BEGIN;
SELECT plan(24);

-- ── Baseline BMR/TDEE (profile M, maintenance) ─────────────────────────────
SELECT results_eq(
  $$SELECT bmr, tdee, calorie_goal FROM calculate_nutrition_targets(64, 180, 30, 'male', 'sedentary', 'maintenance')$$,
  $$VALUES (1620::numeric, 1944::numeric, 1944)$$,
  'M maintenance: BMR 1620, TDEE 1944, goal = TDEE');

-- Maintenance macros: protein 1.4 g/kg, fat 25% kcal, carbs remainder
SELECT results_eq(
  $$SELECT protein_g, fat_g, carb_g FROM calculate_nutrition_targets(64, 180, 30, 'male', 'sedentary', 'maintenance')$$,
  $$VALUES (89.6::numeric, 54.0::numeric, 274.9::numeric)$$,
  'M maintenance macros: 89.6 P / 54.0 F / 274.9 C');

-- ── Activity multipliers ───────────────────────────────────────────────────
SELECT results_eq(
  $$SELECT tdee FROM calculate_nutrition_targets(64, 180, 30, 'male', 'light', 'maintenance')$$,
  $$VALUES (2227.5::numeric)$$, 'light -> 1.375');
SELECT results_eq(
  $$SELECT tdee FROM calculate_nutrition_targets(64, 180, 30, 'male', 'very_active', 'maintenance')$$,
  $$VALUES (3078::numeric)$$, 'very_active -> 1.9');
SELECT results_eq(
  $$SELECT tdee FROM calculate_nutrition_targets(64, 180, 30, 'male', NULL, 'maintenance')$$,
  $$VALUES (1944::numeric)$$, 'NULL activity -> 1.2 fallback');

-- ── Worked matrix, profile F (spec §1.12) ──────────────────────────────────
-- Row 1: lose 10 kg, 26 wks: pace .3846 -> −423.08 -> 1827; protein vs 60 kg
SELECT results_eq(
  $$SELECT calorie_goal, protein_g, effective_pace_kg_week, estimated_weeks_to_target
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 60, 26)$$,
  $$VALUES (1827, 120.0::numeric, 0.38::numeric, 26.0::numeric)$$,
  'F loss 10kg/26wk: 1827 kcal, P120, pace .38, est 26wk');

-- Row 2: lose 10 kg, 9 wks: pace clamped 1.0 -> −1100 -> BMR floor 1452
SELECT results_eq(
  $$SELECT calorie_goal, effective_pace_kg_week, estimated_weeks_to_target
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 60, 9)$$,
  $$VALUES (1452, 0.73::numeric, 13.8::numeric)$$,
  'F loss 10kg/9wk: BMR floor 1452, honest pace 0.73, est ~13.8wk');

-- Row 4 regain: 2 kg above target, weeks pinned at 4 by caller -> −550
SELECT results_eq(
  $$SELECT calorie_goal, effective_pace_kg_week
    FROM calculate_nutrition_targets(62, 170, 30, 'female', 'moderate', 'weight_loss', 60, 4)$$,
  $$VALUES (1576, 0.5::numeric)$$,
  'F regain 2kg @4wk floor: 1576 kcal, pace 0.5');

-- Row 5: loss, no target -> default 0.5 kg/wk; protein vs current 70 kg
SELECT results_eq(
  $$SELECT calorie_goal, protein_g, estimated_weeks_to_target
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss')$$,
  $$VALUES (1700, 140.0::numeric, NULL::numeric)$$,
  'F loss no target: 1700 kcal, P140, est NULL');

-- Row 7: gain, no target -> default 0.25 kg/wk
SELECT results_eq(
  $$SELECT calorie_goal, protein_g FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'muscle_gain')$$,
  $$VALUES (2525, 126.0::numeric)$$, 'F gain no target: 2525 kcal, P126');

-- Gain with target: 5 kg / 26 wks -> +211.5 -> 2461
SELECT results_eq(
  $$SELECT calorie_goal, effective_pace_kg_week
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'muscle_gain', 75, 26)$$,
  $$VALUES (2461, 0.19::numeric)$$, 'F gain 5kg/26wk: 2461, pace 0.19');

-- ── Crossed / contradictory -> maintenance ─────────────────────────────────
SELECT results_eq(
  $$SELECT calorie_goal, effective_pace_kg_week, estimated_weeks_to_target
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 75, 26)$$,
  $$VALUES (2250, 0::numeric, NULL::numeric)$$, 'loss with target above current -> maintenance');
SELECT results_eq(
  $$SELECT calorie_goal FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'muscle_gain', 65, 26)$$,
  $$VALUES (2250)$$, 'gain with target below current -> maintenance');

-- ── Clamps & caps ──────────────────────────────────────────────────────────
-- Deficit floor is pure BMR (D8): M sedentary loss default: 1944−550 < 1620 -> 1620
SELECT results_eq(
  $$SELECT calorie_goal FROM calculate_nutrition_targets(64, 180, 30, 'male', 'sedentary', 'weight_loss')$$,
  $$VALUES (1620)$$, 'M loss default pace hits pure BMR floor 1620');
-- Surplus cap binds: M gain 10kg/20wk raw 0.5 -> 550 > 0.2*1944=388.8 -> 2333
SELECT results_eq(
  $$SELECT calorie_goal, effective_pace_kg_week
    FROM calculate_nutrition_targets(64, 180, 30, 'male', 'sedentary', 'muscle_gain', 74, 20)$$,
  $$VALUES (2333, 0.35::numeric)$$, 'surplus capped at 20% TDEE');
-- Loss pace clamp: covered by Row 2 above (raw 1.11 -> 1.0)

-- ── Protein guards ─────────────────────────────────────────────────────────
-- Cap binds: 150kg/170cm/60y male sedentary loss to 145 in 4wk:
-- BMR 2267.5 floor -> 2268 kcal; raw protein 290g > cap 0.35*2268/4 = 198.45
-- (numeric ROUND is half-away-from-zero: 198.45 -> 198.5)
SELECT results_eq(
  $$SELECT calorie_goal, protein_g
    FROM calculate_nutrition_targets(150, 170, 60, 'male', 'sedentary', 'weight_loss', 145, 4)$$,
  $$VALUES (2268, 198.5::numeric)$$, '35% protein cap binds for heavy user');
-- Carbs never negative even at cap: same call
SELECT ok(
  (SELECT carb_g >= 0 FROM calculate_nutrition_targets(150, 170, 60, 'male', 'sedentary', 'weight_loss', 145, 4)),
  'carbs non-negative when protein cap binds');

-- ── Sex / goal fallbacks ───────────────────────────────────────────────────
SELECT results_eq(
  $$SELECT calorie_goal FROM calculate_nutrition_targets(70, 170, 30, 'other', 'sedentary', 'maintenance')$$,
  $$VALUES (1742)$$, 'sex other uses female constant: 1451.5*1.2 -> 1742');
SELECT results_eq(
  $$SELECT calorie_goal FROM calculate_nutrition_targets(64, 180, 30, 'male', 'sedentary', 'health')$$,
  $$VALUES (1944)$$, 'unknown goal_type -> maintenance');
SELECT results_eq(
  $$SELECT calorie_goal FROM calculate_nutrition_targets(64, 180, 30, 'male', 'sedentary', NULL)$$,
  $$VALUES (1944)$$, 'NULL goal_type -> maintenance');

-- ── Invalid required inputs -> zero rows (D10 / §1.10) ─────────────────────
SELECT is_empty(
  $$SELECT * FROM calculate_nutrition_targets(25, 180, 30, 'male', 'sedentary', 'maintenance')$$,
  'weight below 30 -> empty');
SELECT is_empty(
  $$SELECT * FROM calculate_nutrition_targets(64, 250, 30, 'male', 'sedentary', 'maintenance')$$,
  'height above 230 -> empty');
SELECT is_empty(
  $$SELECT * FROM calculate_nutrition_targets(64, 180, 17, 'male', 'sedentary', 'maintenance')$$,
  'age below 18 -> empty');
SELECT is_empty(
  $$SELECT * FROM calculate_nutrition_targets(64, 180, 30, NULL, 'sedentary', 'maintenance')$$,
  'NULL sex -> empty');

-- Energy identity: grams re-sum to calorie_goal (±10 kcal rounding tolerance)
SELECT ok(
  (SELECT ABS(protein_g*4 + carb_g*4 + fat_g*9 - calorie_goal) <= 10
   FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 60, 26)),
  'macros re-sum to calorie_goal within 10 kcal');

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run to verify it fails**

Run: `supabase test db`
Expected: FAIL — `function calculate_nutrition_targets(…) does not exist`.

- [ ] **Step 3: Write the migration (minimal implementation)**

```sql
-- Migration: add_calculate_nutrition_targets
-- SINGLE SOURCE OF TRUTH for BMR/TDEE/calorie-goal/macro computation.
-- Spec: docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md
-- Called by: Flutter RPC (onboarding + Settings Calculate) and
-- recalculate_nutrition_plans_from_weight() (weekly cron, LATERAL join).
-- IMMUTABLE by design: takes p_remaining_weeks instead of reading
-- current_date. Callers apply GREATEST(4, ceil((target_date - today)/7)).
-- Invalid required inputs return ZERO ROWS (never garbage, never an error).

CREATE OR REPLACE FUNCTION public.calculate_nutrition_targets(
  p_weight_kg         numeric,
  p_height_cm         numeric,
  p_age               integer,
  p_sex               text,
  p_activity_level    text,
  p_primary_goal      text,
  p_target_weight_kg  numeric DEFAULT NULL,
  p_remaining_weeks   integer DEFAULT NULL
) RETURNS TABLE (
  bmr numeric,
  tdee numeric,
  calorie_goal integer,
  protein_g numeric,
  carb_g numeric,
  fat_g numeric,
  effective_pace_kg_week numeric,
  estimated_weeks_to_target numeric
)
LANGUAGE sql IMMUTABLE SECURITY INVOKER
AS $$
WITH base AS (
  -- Input contract (§1.10): out-of-bounds required inputs -> no row.
  SELECT (10*p_weight_kg + 6.25*p_height_cm - 5*p_age
          + CASE WHEN p_sex = 'male' THEN 5 ELSE -161 END)::numeric AS bmr_c
  WHERE p_weight_kg BETWEEN 30 AND 300
    AND p_height_cm BETWEEN 120 AND 230
    AND p_age BETWEEN 18 AND 100
    AND p_sex IS NOT NULL
),
with_tdee AS (
  SELECT bmr_c,
         bmr_c * CASE p_activity_level
           WHEN 'sedentary'   THEN 1.2
           WHEN 'light'       THEN 1.375
           WHEN 'moderate'    THEN 1.55
           WHEN 'active'      THEN 1.725
           WHEN 'very_active' THEN 1.9
           ELSE 1.2
         END AS tdee_c
  FROM base
),
with_goal AS (
  SELECT *,
    CASE WHEN p_primary_goal IN ('weight_loss','muscle_gain')
         THEN p_primary_goal ELSE 'maintenance' END AS goal_c,
    (p_target_weight_kg - p_weight_kg) AS delta_c
  FROM with_tdee
),
with_pace AS (
  -- Requested pace kg/week after direction check, defaults, and clamps (§1.4/§1.5/§1.6).
  SELECT *,
    CASE
      WHEN goal_c = 'maintenance' THEN 0
      WHEN goal_c = 'weight_loss' THEN CASE
        WHEN p_target_weight_kg IS NOT NULL AND delta_c >= 0 THEN 0          -- crossed/contradictory
        WHEN p_target_weight_kg IS NULL OR p_remaining_weeks IS NULL THEN 0.5 -- default pace
        ELSE LEAST(ABS(delta_c) / GREATEST(p_remaining_weeks, 1), 1.0)
      END
      ELSE CASE                                                               -- muscle_gain
        WHEN p_target_weight_kg IS NOT NULL AND delta_c <= 0 THEN 0
        WHEN p_target_weight_kg IS NULL OR p_remaining_weeks IS NULL THEN 0.25
        ELSE LEAST(ABS(delta_c) / GREATEST(p_remaining_weeks, 1), 0.5)
      END
    END AS pace_c
  FROM with_goal
),
with_cal AS (
  SELECT *,
    CASE goal_c
      WHEN 'weight_loss' THEN ROUND(GREATEST(tdee_c - pace_c*1100, bmr_c))::int
      WHEN 'muscle_gain' THEN ROUND(tdee_c + LEAST(pace_c*1100, 0.20*tdee_c))::int
      ELSE ROUND(tdee_c)::int
    END AS cal_c
  FROM with_pace
),
with_eff AS (
  -- Effective (post-clamp/floor) pace, spec §1.9 / D2. Unrounded here;
  -- rounded only at output so estimated weeks stays precise.
  SELECT *,
    CASE goal_c
      WHEN 'weight_loss' THEN (tdee_c - cal_c) / 1100.0
      WHEN 'muscle_gain' THEN (cal_c - tdee_c) / 1100.0
      ELSE 0
    END AS eff_c
  FROM with_cal
),
with_macros AS (
  SELECT *,
    LEAST(
      CASE goal_c
        WHEN 'weight_loss' THEN LEAST(p_weight_kg, COALESCE(p_target_weight_kg, p_weight_kg)) * 2.0
        WHEN 'muscle_gain' THEN p_weight_kg * 1.8
        ELSE p_weight_kg * 1.4
      END,
      0.35 * cal_c / 4.0
    ) AS protein_c,
    0.25 * cal_c / 9.0 AS fat_c
  FROM with_eff
)
SELECT
  bmr_c,
  tdee_c,
  cal_c,
  ROUND(protein_c, 1),
  ROUND((cal_c - protein_c*4 - fat_c*9) / 4.0, 1),
  ROUND(fat_c, 1),
  ROUND(eff_c, 2),
  CASE
    WHEN goal_c = 'maintenance' OR p_target_weight_kg IS NULL OR eff_c <= 0 THEN NULL
    ELSE ROUND(ABS(delta_c) / eff_c, 1)
  END
FROM with_macros
$$;

GRANT EXECUTE ON FUNCTION public.calculate_nutrition_targets(
  numeric, numeric, integer, text, text, text, numeric, integer
) TO authenticated, service_role;
```

- [ ] **Step 4: Apply and run tests**

Run: `supabase migration up` then `supabase test db`
Expected: the new file PASSes all 24; pre-existing test files unchanged (the old cron tests still pass — its function is untouched until Task 3).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260707000001_add_calculate_nutrition_targets.sql supabase/tests/calculate_nutrition_targets_test.sql
git commit -m "feat(db): calculate_nutrition_targets — pace-based single source of truth"
```

---

### Task 3: Rewrite the weekly cron on top of the calculator (TDD)

**Files:**
- Create: `supabase/migrations/20260707000002_recalculate_plans_use_calculator.sql`
- Modify: `supabase/tests/recalculate_nutrition_plans_from_weight_test.sql`

**Interfaces:**
- Consumes: `calculate_nutrition_targets(...)` (Task 2 signature), `user_health_profile.target_date` (Task 1).
- Produces: same external contract as before — `recalculate_nutrition_plans_from_weight() RETURNS integer`, service_role-only.

- [ ] **Step 1: Update existing test expectations to the new formula**

In `supabase/tests/recalculate_nutrition_plans_from_weight_test.sql`:

1. Extend the seed helper with target columns (add two parameters at the end and pass them through):

```sql
-- signature gains:
  p_target_weight_kg    numeric DEFAULT NULL,
  p_target_date_days    int     DEFAULT NULL   -- days from today; NULL = no target_date
-- and the user_health_profile INSERT gains:
  target_weight_kg, target_date
-- VALUES gains:
  p_target_weight_kg,
  CASE WHEN p_target_date_days IS NULL THEN NULL
       ELSE (CURRENT_DATE + p_target_date_days)::date END
-- ON CONFLICT DO UPDATE gains:
  target_weight_kg = EXCLUDED.target_weight_kg,
  target_date = EXCLUDED.target_date
```

2. Replace the T1/T2/T10 numeric expectations (base profile M: BMR 1620, sedentary TDEE 1944):
   - T1 maintenance: `calorie_goal 1944`, `protein_g 89.6`, `carb_g 274.9`, `fat_g 54.0` (was 25/50/25%).
   - T2 TDEE assertions unchanged (multipliers did not change).
   - T10a weight_loss (no target seeded → default pace, then **BMR floor**): `calorie_goal 1620`, `protein_g 128.0` (64×2.0, cap 141.75 not hit), `fat_g 45.0`, `carb_g 175.8`.
   - T10b muscle_gain (no target): `calorie_goal 2219` (1944 + 275), `protein_g 115.2`, `fat_g 61.6`, `carb_g 300.9`.
   - T12 dedup expectations: recompute with the same rules for whichever goal_type that scenario asserts.

3. Append new scenarios (new seeded users, fresh UUIDs `a0000000-…-0015` onward), and bump `plan(N)`:

```sql
-- T13: 7-day smoothing — three logs (63, 64, 65 kg) within the last 7 days
-- -> smoothed weight 64.0 used (same outputs as T1's 64 kg user).
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000015'::uuid, 63.0, 1, 180.0, 30, 'male', 'sedentary', 'maintenance', true, true, 9999);
INSERT INTO weight_log (user_id, weight_kg, logged_at) VALUES
  ('a0000000-0000-4000-8000-000000000015', 64.0, CURRENT_DATE - 3),
  ('a0000000-0000-4000-8000-000000000015', 65.0, CURRENT_DATE - 5);
-- assert after run: calorie_goal = 1944 (avg 64 -> BMR 1620 -> TDEE 1944)

-- T14: crossed target -> maintenance. weight_loss user, smoothed 64 kg,
-- target 65 kg (already below target) -> calorie_goal = TDEE = 1944.
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000016'::uuid, 64.0, 1, 180.0, 30, 'male', 'sedentary', 'weight_loss', true, true, 9999, 65.0, 60);

-- T15: overdue target_date -> 4-week floor. weight_loss, 64 kg, target 62,
-- date 10 days in the PAST -> remaining_weeks pinned 4 -> pace 0.5 ->
-- GREATEST(1944-550, 1620) = 1620 (floor still binds for this sedentary user).
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000017'::uuid, 64.0, 1, 180.0, 30, 'male', 'sedentary', 'weight_loss', true, true, 9999, 62.0, -10);

-- T16: dated target drives pace. weight_loss, 64 kg, target 60 (4 kg),
-- date 140 days out -> remaining_weeks = 20 -> pace 0.2 -> deficit 220 ->
-- GREATEST(1944-220, 1620) = 1724.
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000018'::uuid, 64.0, 1, 180.0, 30, 'male', 'sedentary', 'weight_loss', true, true, 9999, 60.0, 140);

-- T17: invalid profile skipped untouched — weight_log 320 kg (> 300 bound)
-- -> calculate_nutrition_targets returns zero rows -> sentinel 9999 remains.
SELECT _test_seed_recalc_user('a0000000-0000-4000-8000-000000000019'::uuid, 320.0, 1, 180.0, 30, 'male', 'sedentary', 'maintenance', true, true, 9999);
```

- [ ] **Step 2: Run to verify the updated tests fail**

Run: `supabase test db`
Expected: FAIL — old function still applies flat −500/percent macros (e.g. T10a asserts 1620, old code produces 1444).

- [ ] **Step 3: Write the rewrite migration**

```sql
-- Migration: recalculate_plans_use_calculator
-- Drops the inlined formula copy; delegates to calculate_nutrition_targets()
-- (the single source of truth) via LATERAL. Adds 7-day weight smoothing (D7)
-- and date-anchored remaining_weeks (D1/D5). Spec §2.1.

CREATE OR REPLACE FUNCTION public.recalculate_nutrition_plans_from_weight()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_updated_count integer;
BEGIN
  WITH smoothed_weight AS (
    -- 7-day average when available; otherwise the latest log in the 14-day
    -- eligibility window (same window as before).
    SELECT
      wl.user_id,
      COALESCE(
        AVG(wl.weight_kg) FILTER (WHERE wl.logged_at >= CURRENT_DATE - INTERVAL '7 days'),
        (ARRAY_AGG(wl.weight_kg ORDER BY wl.logged_at DESC, wl.created_at DESC))[1]
      ) AS weight_kg
    FROM weight_log wl
    WHERE wl.logged_at >= CURRENT_DATE - INTERVAL '14 days'
    GROUP BY wl.user_id
  ),
  latest_goal AS (
    SELECT DISTINCT ON (ug.user_id)
      ug.user_id, ug.id AS goal_id, ug.goal_type
    FROM user_goal ug
    WHERE ug.is_active = true
    ORDER BY ug.user_id, ug.created_at DESC
  ),
  candidates AS (
    SELECT
      np.id AS plan_id,
      lg.goal_id,
      hp.user_id,
      sw.weight_kg,
      hp.height_cm,
      DATE_PART('year', AGE(CURRENT_DATE, hp.birth_date))::int AS age,
      hp.sex,
      hp.activity_level,
      lg.goal_type,
      hp.target_weight_kg,
      CASE WHEN hp.target_date IS NULL THEN NULL
           ELSE GREATEST(4, CEIL((hp.target_date - CURRENT_DATE) / 7.0))::int
      END AS remaining_weeks
    FROM user_health_profile hp
    JOIN smoothed_weight sw ON sw.user_id = hp.user_id
    JOIN nutrition_plan np  ON np.user_id = hp.user_id AND np.is_active = true
    JOIN latest_goal lg     ON lg.user_id = hp.user_id
    WHERE hp.height_cm IS NOT NULL
      AND hp.birth_date IS NOT NULL
      AND hp.sex IS NOT NULL
  ),
  computed AS (
    -- LATERAL: zero rows from the calculator (invalid inputs) drops the user.
    SELECT c.*, t.*
    FROM candidates c
    CROSS JOIN LATERAL public.calculate_nutrition_targets(
      c.weight_kg, c.height_cm, c.age, c.sex, c.activity_level,
      c.goal_type, c.target_weight_kg, c.remaining_weeks
    ) t
  ),
  updated_plans AS (
    UPDATE nutrition_plan np
    SET calorie_goal   = f.calorie_goal,
        bmr            = f.bmr,
        tdee           = f.tdee,
        protein_goal_g = f.protein_g,
        carb_goal_g    = f.carb_g,
        fat_goal_g     = f.fat_g
    FROM computed f
    WHERE np.id = f.plan_id
    RETURNING np.id AS plan_id, f.goal_id, f.user_id, f.weight_kg,
              f.calorie_goal, f.protein_g, f.carb_g, f.fat_g
  ),
  updated_goals AS (
    UPDATE user_goal ug
    SET calorie_goal = up.calorie_goal,
        protein_goal = up.protein_g,
        carbs_goal   = up.carb_g,
        fat_goal     = up.fat_g
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

REVOKE ALL ON FUNCTION public.recalculate_nutrition_plans_from_weight() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.recalculate_nutrition_plans_from_weight() FROM anon;
REVOKE ALL ON FUNCTION public.recalculate_nutrition_plans_from_weight() FROM authenticated;
```

- [ ] **Step 4: Apply and run tests**

Run: `supabase migration up` then `supabase test db`
Expected: all files PASS, including the updated cron suite.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260707000002_recalculate_plans_use_calculator.sql supabase/tests/recalculate_nutrition_plans_from_weight_test.sql
git commit -m "feat(db): weekly recalc delegates to calculate_nutrition_targets with smoothed weight"
```

---

### Task 4: `NutritionInputBounds` — client mirror of the input contract (TDD)

**Files:**
- Create: `lib/core/nutrition_input_bounds.dart`
- Test: `test/core/nutrition_input_bounds_test.dart`

**Interfaces:**
- Produces: `NutritionInputBounds` statics — `minWeightKg/maxWeightKg (30/300)`, `minHeightCm/maxHeightCm (120/230)`, `minAge/maxAge (18/100)`, `underweightBmi (18.5)`; predicates `weightOk(double?)`, `heightOk(double?)`, `ageOk(int?)`, `targetUnderweight(double? targetKg, double? heightCm)`. `null` passes the `*Ok` predicates (required-ness is enforced by each form, not here). Tasks 9, 10 consume these.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/nutrition_input_bounds_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/nutrition_input_bounds.dart';

void main() {
  group('NutritionInputBounds', () {
    test('weight bounds inclusive', () {
      expect(NutritionInputBounds.weightOk(30), isTrue);
      expect(NutritionInputBounds.weightOk(300), isTrue);
      expect(NutritionInputBounds.weightOk(29.9), isFalse);
      expect(NutritionInputBounds.weightOk(300.1), isFalse);
      expect(NutritionInputBounds.weightOk(null), isTrue); // optional-field semantics
    });

    test('height bounds inclusive', () {
      expect(NutritionInputBounds.heightOk(120), isTrue);
      expect(NutritionInputBounds.heightOk(230), isTrue);
      expect(NutritionInputBounds.heightOk(119.9), isFalse);
      expect(NutritionInputBounds.heightOk(230.1), isFalse);
      expect(NutritionInputBounds.heightOk(null), isTrue);
    });

    test('age bounds inclusive', () {
      expect(NutritionInputBounds.ageOk(18), isTrue);
      expect(NutritionInputBounds.ageOk(100), isTrue);
      expect(NutritionInputBounds.ageOk(17), isFalse);
      expect(NutritionInputBounds.ageOk(101), isFalse);
      expect(NutritionInputBounds.ageOk(null), isTrue);
    });

    test('underweight target detection at BMI 18.5', () {
      // 170 cm -> BMI 18.5 at 53.465 kg
      expect(NutritionInputBounds.targetUnderweight(53.0, 170), isTrue);
      expect(NutritionInputBounds.targetUnderweight(54.0, 170), isFalse);
      expect(NutritionInputBounds.targetUnderweight(null, 170), isFalse);
      expect(NutritionInputBounds.targetUnderweight(53.0, null), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/core/nutrition_input_bounds_test.dart`
Expected: FAIL — file/class not found.

- [ ] **Step 3: Implement**

```dart
// lib/core/nutrition_input_bounds.dart

import 'package:akeli/core/logger.dart';

// Logger import required by CLAUDE.md logging standard.
// Pure constants/predicates — no side-effect logging calls needed at runtime.
// ignore: unused_element
final _logger = appLogger;

/// Client-side mirror of the plausibility bounds enforced by
/// public.calculate_nutrition_targets() (which returns zero rows when
/// violated). Spec §1.10/§1.11, D11:
/// docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md
/// If the SQL bounds ever change, change these together.
class NutritionInputBounds {
  static const double minWeightKg = 30;
  static const double maxWeightKg = 300;
  static const double minHeightCm = 120;
  static const double maxHeightCm = 230;
  static const int minAge = 18;
  static const int maxAge = 100;
  static const double underweightBmi = 18.5;

  /// null passes: required-ness is each form's concern, not the bounds'.
  static bool weightOk(double? kg) =>
      kg == null || (kg >= minWeightKg && kg <= maxWeightKg);

  static bool heightOk(double? cm) =>
      cm == null || (cm >= minHeightCm && cm <= maxHeightCm);

  static bool ageOk(int? years) =>
      years == null || (years >= minAge && years <= maxAge);

  /// True when a target weight implies an underweight BMI for the given
  /// height — soft warning only (§1.11), never blocks.
  static bool targetUnderweight(double? targetKg, double? heightCm) {
    if (targetKg == null || heightCm == null || heightCm <= 0) return false;
    final hM = heightCm / 100;
    return targetKg / (hM * hM) < underweightBmi;
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/core/nutrition_input_bounds_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/nutrition_input_bounds.dart test/core/nutrition_input_bounds_test.dart
git commit -m "feat: NutritionInputBounds client mirror of calculator input contract"
```

---

### Task 5: RPC wrapper — `nutrition_targets_provider.dart` (TDD on the pure parts)

**Files:**
- Create: `lib/providers/nutrition_targets_provider.dart`
- Test: `test/providers/nutrition_targets_provider_test.dart`

**Interfaces:**
- Consumes: `calculate_nutrition_targets` RPC (Task 2).
- Produces (Tasks 7, 9 consume):
  - `class NutritionTargetsResult { double bmr; double tdee; int calorieGoal; double proteinG; double carbG; double fatG; double effectivePaceKgWeek; double? estimatedWeeksToTarget; }` with `factory NutritionTargetsResult.fromRpcRow(Map<String, dynamic>)`
  - `Map<String, dynamic> buildCalculateTargetsParams({required double weightKg, required double heightCm, required int age, required String sex, required String? activityLevel, required String primaryGoal, double? targetWeightKg, int? remainingWeeks})`
  - `int remainingWeeksFromMonths(int months)` → `max(4, (months * 4.33).round())`
  - `int? remainingWeeksFromDate(DateTime? targetDate, {DateTime? now})` → null when date null, else `max(4, ceil(days/7))`
  - `Future<NutritionTargetsResult?> fetchNutritionTargets(SupabaseClient client, {…same named params as buildCalculateTargetsParams})` — returns null on zero rows; rethrows on error after logging.

- [ ] **Step 1: Write the failing test (pure functions only — no Supabase mock needed)**

```dart
// test/providers/nutrition_targets_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/nutrition_targets_provider.dart';

void main() {
  group('buildCalculateTargetsParams', () {
    test('maps every input to its p_ column name', () {
      final p = buildCalculateTargetsParams(
        weightKg: 70, heightCm: 170, age: 30, sex: 'female',
        activityLevel: 'moderate', primaryGoal: 'weight_loss',
        targetWeightKg: 60, remainingWeeks: 26,
      );
      expect(p, {
        'p_weight_kg': 70.0, 'p_height_cm': 170.0, 'p_age': 30,
        'p_sex': 'female', 'p_activity_level': 'moderate',
        'p_primary_goal': 'weight_loss',
        'p_target_weight_kg': 60.0, 'p_remaining_weeks': 26,
      });
    });

    test('optional params pass through as null', () {
      final p = buildCalculateTargetsParams(
        weightKg: 70, heightCm: 170, age: 30, sex: 'male',
        activityLevel: null, primaryGoal: 'maintenance',
      );
      expect(p['p_target_weight_kg'], isNull);
      expect(p['p_remaining_weeks'], isNull);
      expect(p['p_activity_level'], isNull);
    });
  });

  group('remainingWeeks helpers', () {
    test('from months: 6 months -> 26 weeks', () {
      expect(remainingWeeksFromMonths(6), 26);
    });
    test('from months: floors at 4 (1 month -> 4, not 4.33-rounded-below)', () {
      expect(remainingWeeksFromMonths(1), 4);
    });
    test('from date: null -> null', () {
      expect(remainingWeeksFromDate(null), isNull);
    });
    test('from date: 140 days out -> 20 weeks', () {
      final now = DateTime(2026, 7, 7);
      expect(remainingWeeksFromDate(now.add(const Duration(days: 140)), now: now), 20);
    });
    test('from date: overdue -> floor 4', () {
      final now = DateTime(2026, 7, 7);
      expect(remainingWeeksFromDate(now.subtract(const Duration(days: 10)), now: now), 4);
    });
  });

  group('NutritionTargetsResult.fromRpcRow', () {
    test('parses numeric row including null estimated weeks', () {
      final r = NutritionTargetsResult.fromRpcRow({
        'bmr': 1451.5, 'tdee': 2249.825, 'calorie_goal': 1827,
        'protein_g': 120.0, 'carb_g': 222.6, 'fat_g': 50.8,
        'effective_pace_kg_week': 0.38, 'estimated_weeks_to_target': 26.0,
      });
      expect(r.calorieGoal, 1827);
      expect(r.effectivePaceKgWeek, 0.38);
      expect(r.estimatedWeeksToTarget, 26.0);

      final m = NutritionTargetsResult.fromRpcRow({
        'bmr': 1620, 'tdee': 1944, 'calorie_goal': 1944,
        'protein_g': 89.6, 'carb_g': 274.9, 'fat_g': 54.0,
        'effective_pace_kg_week': 0, 'estimated_weeks_to_target': null,
      });
      expect(m.estimatedWeeksToTarget, isNull);
      expect(m.bmr, 1620.0);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/providers/nutrition_targets_provider_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/providers/nutrition_targets_provider.dart

import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';

final _logger = appLogger;

/// Output row of public.calculate_nutrition_targets() — the backend single
/// source of truth (spec §2). No calorie/macro math may be done in Dart.
class NutritionTargetsResult {
  final double bmr;
  final double tdee;
  final int calorieGoal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double effectivePaceKgWeek;
  final double? estimatedWeeksToTarget;

  const NutritionTargetsResult({
    required this.bmr,
    required this.tdee,
    required this.calorieGoal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.effectivePaceKgWeek,
    this.estimatedWeeksToTarget,
  });

  factory NutritionTargetsResult.fromRpcRow(Map<String, dynamic> row) =>
      NutritionTargetsResult(
        bmr: (row['bmr'] as num).toDouble(),
        tdee: (row['tdee'] as num).toDouble(),
        calorieGoal: (row['calorie_goal'] as num).toInt(),
        proteinG: (row['protein_g'] as num).toDouble(),
        carbG: (row['carb_g'] as num).toDouble(),
        fatG: (row['fat_g'] as num).toDouble(),
        effectivePaceKgWeek:
            (row['effective_pace_kg_week'] as num).toDouble(),
        estimatedWeeksToTarget:
            (row['estimated_weeks_to_target'] as num?)?.toDouble(),
      );
}

Map<String, dynamic> buildCalculateTargetsParams({
  required double weightKg,
  required double heightCm,
  required int age,
  required String sex,
  required String? activityLevel,
  required String primaryGoal,
  double? targetWeightKg,
  int? remainingWeeks,
}) =>
    {
      'p_weight_kg': weightKg,
      'p_height_cm': heightCm,
      'p_age': age,
      'p_sex': sex,
      'p_activity_level': activityLevel,
      'p_primary_goal': primaryGoal,
      'p_target_weight_kg': targetWeightKg,
      'p_remaining_weeks': remainingWeeks,
    };

/// Onboarding: target_date is "today + timelineMonths", so remaining weeks
/// is the whole timeline. Spec §1.3/§4.1: floor 4.
int remainingWeeksFromMonths(int months) =>
    math.max(4, (months * 4.33).round());

/// Settings/anywhere with a stored target_date. Spec §1.3: floor 4,
/// NULL date -> NULL (calculator applies its default pace).
int? remainingWeeksFromDate(DateTime? targetDate, {DateTime? now}) {
  if (targetDate == null) return null;
  final days = targetDate.difference(now ?? DateTime.now()).inDays;
  return math.max(4, (days / 7).ceil());
}

/// Calls the backend calculator. Returns null when the function returns zero
/// rows (invalid inputs, spec §1.10) — callers show an error and keep prior
/// values. Never falls back to local math.
Future<NutritionTargetsResult?> fetchNutritionTargets(
  SupabaseClient client, {
  required double weightKg,
  required double heightCm,
  required int age,
  required String sex,
  required String? activityLevel,
  required String primaryGoal,
  double? targetWeightKg,
  int? remainingWeeks,
}) async {
  final params = buildCalculateTargetsParams(
    weightKg: weightKg,
    heightCm: heightCm,
    age: age,
    sex: sex,
    activityLevel: activityLevel,
    primaryGoal: primaryGoal,
    targetWeightKg: targetWeightKg,
    remainingWeeks: remainingWeeks,
  );
  _logger.db('BEFORE rpc | fn: calculate_nutrition_targets | params: $params');
  try {
    final rows = await client.rpc('calculate_nutrition_targets',
        params: params) as List<dynamic>;
    _logger.db(
        'AFTER rpc | fn: calculate_nutrition_targets | rows: ${rows.length}');
    if (rows.isEmpty) return null;
    return NutritionTargetsResult.fromRpcRow(
        rows.first as Map<String, dynamic>);
  } on PostgrestException catch (e, st) {
    _logger.db(
        'ERROR rpc | fn: calculate_nutrition_targets | code: ${e.code} | ${e.message}',
        error: e, stackTrace: st);
    rethrow;
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/providers/nutrition_targets_provider_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/providers/nutrition_targets_provider.dart test/providers/nutrition_targets_provider_test.dart
git commit -m "feat: RPC wrapper for calculate_nutrition_targets with remaining-weeks helpers"
```

---

### Task 6: Model + consumer swap — `targetTimeWeeks` → `targetDate`

**Files:**
- Modify: `lib/features/settings/models/health_profile_model.dart`
- Modify: `lib/shared/models/user_profile.dart` (class `HealthProfile`, ~lines 125–190)
- Modify: `lib/providers/health_profile_provider.dart:128` (select string) and `:207-208` (upsert)
- Modify: `lib/features/settings/health_profile_page.dart:450-494` (weeks slider)
- Modify: `lib/features/diet_plan/diet_plan_page.dart:159-164`
- Modify: `test/features/settings/health_profile_model_test.dart`
- Also update the select string in whichever provider populates `HealthProfile` (grep `target_time_weeks` — Step 4 catches any stragglers).

**Interfaces:**
- Consumes: DB column `target_date` (Task 1), `remainingWeeksFromDate` (Task 5).
- Produces: `HealthProfileModel.targetDate: DateTime?` (+ `clearTargetDate` in `copyWith`, `target_date` in `fromJson`); `HealthProfile.targetDate: DateTime?`. Tasks 7, 9, 10 consume `targetDate`.

- [ ] **Step 1: Update the failing model test first**

In `test/features/settings/health_profile_model_test.dart`, replace every `targetTimeWeeks: <int>` construction with `targetDate: DateTime(2026, 12, 1)` and the JSON round-trip expectation `'target_time_weeks': 8` / `expect(model.targetTimeWeeks, 8)` with:

```dart
'target_date': '2026-12-01',
// ...
expect(model.targetDate, DateTime(2026, 12, 1));
```

Run: `flutter test test/features/settings/health_profile_model_test.dart` — Expected: FAIL (no such field).

- [ ] **Step 2: Swap the field in both models**

In `health_profile_model.dart`: replace `final int? targetTimeWeeks;` with `final DateTime? targetDate;`; constructor/copyWith/`==`/`hashCode` accordingly; add `bool clearTargetDate = false` to `copyWith` (`targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate)`); in `fromJson`:

```dart
targetDate: health?['target_date'] != null
    ? DateTime.tryParse(health!['target_date'] as String)
    : null,
```

In `user_profile.dart` (`HealthProfile`): same swap — `final DateTime? targetDate;`, `fromJson`: `targetDate: json['target_date'] != null ? DateTime.parse(json['target_date'] as String) : null,`.

- [ ] **Step 3: Update the provider select/upsert**

`health_profile_provider.dart` line 128 select string: replace `target_time_weeks` with `target_date`. Lines 207–208 upsert: replace with

```dart
if (updated.targetDate != null)
  'target_date':
      updated.targetDate!.toIso8601String().split('T').first,
```

- [ ] **Step 4: Update the two UI consumers**

`health_profile_page.dart` — the slider keeps its 4–52 weeks UX but reads/writes `targetDate` (no date picker in V1, D6):

```dart
// above the Row, inside build:
final targetWeeks = (remainingWeeksFromDate(local.targetDate) ?? 26).clamp(4, 52);
```

Replace `(local.targetTimeWeeks ?? 26)` reads with `targetWeeks`, the badge's `months:` param with `targetWeeks / 4.33`, and the slider's `onChanged` with:

```dart
onChanged: (v) {
  _logger.userAction('Target weeks changed',
      screen: 'HealthProfilePage', metadata: {'weeks': v.round()});
  setState(() => _local = local.copyWith(
      targetDate: DateTime.now().add(Duration(days: v.round() * 7))));
},
```

Import: `import '../../providers/nutrition_targets_provider.dart' show remainingWeeksFromDate;`

`diet_plan_page.dart:159-164`:

```dart
final targetDate = health?.targetDate;
double? weeklyLoss;
final remainingWeeks = remainingWeeksFromDate(targetDate);
if (startingWeight != null && targetWeight != null && remainingWeeks != null) {
  weeklyLoss = (startingWeight - targetWeight) / remainingWeeks;
}
```

(same import as above).

- [ ] **Step 5: Sweep for stragglers**

Run: `grep -rn "targetTimeWeeks\|target_time_weeks" lib/ test/`
Expected: zero hits. Fix any remaining reference the same way.

- [ ] **Step 6: Test and commit**

Run: `flutter analyze && flutter test`
Expected: analyze clean; all tests pass (the old `computeCalorieGoal` tests still pass — untouched until Task 7).

```bash
git add -A lib test
git commit -m "refactor: date-anchored targetDate replaces targetTimeWeeks across models and UI"
```

---

### Task 7: `HealthProfileNotifier.save()` uses the RPC; delete Dart formula copies

**Files:**
- Modify: `lib/providers/health_profile_provider.dart`
- Modify: `test/providers/health_profile_provider_test.dart`
- Modify: `lib/core/nutrition_calculator.dart`

**Interfaces:**
- Consumes: `fetchNutritionTargets`, `remainingWeeksFromDate`, `NutritionTargetsResult` (Task 5).
- Produces: `save()` persists RPC-computed targets. **Deletes:** `computeCalorieGoal`, `computeNutritionTargets`, `NutritionTargets`, `activityLevelForCalculator` (provider) and `calculateBMR`, `calculateTDEE`, `calculateCalorieGoal`, `getDefaultMacros` (calculator). `getDefaultMealSplits` and `calculateMacroGrams` remain.

- [ ] **Step 1: Update the provider test file first**

Delete the `activityLevelForCalculator` and `computeCalorieGoal` groups entirely from `test/providers/health_profile_provider_test.dart` (their subjects are being deleted; SQL now owns that behavior with pgTAP coverage). The file keeps only imports that still resolve — if nothing testable remains, replace the body with a single placeholder group asserting model wiring:

```dart
// test/providers/health_profile_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/settings/models/health_profile_model.dart';

void main() {
  // Formula tests moved to supabase/tests/calculate_nutrition_targets_test.sql
  // (single source of truth, spec §2). Provider save() is RPC-backed and
  // covered by integration/manual verification.
  group('HealthProfileModel goalType passthrough', () {
    test('fromJson reads goal_type from the goal row', () {
      final m = HealthProfileModel.fromJson(
          health: null, goal: {'goal_type': 'weight_loss'});
      expect(m.goalType, 'weight_loss');
    });
  });
}
```

- [ ] **Step 2: Rewrite `save()`'s recompute block**

In `health_profile_provider.dart`: delete `activityLevelForCalculator`, `computeCalorieGoal`, `NutritionTargets`, `computeNutritionTargets` (lines 13–105). Add imports:

```dart
import 'nutrition_targets_provider.dart';
```

Replace the `// 2. Recompute…` block in `save()` (currently `final targets = computeNutritionTargets(updated);`) with:

```dart
      // 2. Recompute the full target set via the backend calculator (single
      //    source of truth — spec 2026-07-07 v2). Missing required inputs ->
      //    skip recompute, same as before.
      NutritionTargetsResult? targets;
      final age = updated.age;
      if (age != null &&
          updated.weightKg != null &&
          updated.heightCm != null &&
          updated.goalType != null) {
        targets = await fetchNutritionTargets(
          client,
          weightKg: updated.weightKg!,
          heightCm: updated.heightCm!,
          age: age,
          sex: updated.sex ?? 'male',
          activityLevel: updated.activityLevel,
          primaryGoal: updated.goalType!,
          targetWeightKg: updated.targetWeightKg,
          remainingWeeks: remainingWeeksFromDate(updated.targetDate),
        );
      }
```

The existing `if (targets == null) { … skip … }` branch stays as-is. The plan construction keeps working because `NutritionTargetsResult` exposes the same `bmr/tdee/calorieGoal` names plus grams directly — replace `targets.proteinG`-from-percent lines with the direct fields:

```dart
      final plan = NutritionPlan(
        userId: user.id,
        calorieGoal: targets.calorieGoal,
        proteinGoalG: targets.proteinG,
        carbGoalG: targets.carbG,
        fatGoalG: targets.fatG,
        bmr: targets.bmr,
        tdee: targets.tdee,
        isActive: true,
      );
```

- [ ] **Step 3: Shrink `nutrition_calculator.dart`**

Delete `calculateBMR`, `calculateTDEE`, `calculateCalorieGoal`, `getDefaultMacros`. Keep `calculateMacroGrams` and `getDefaultMealSplits`. Add header comment:

```dart
/// Formula lives in public.calculate_nutrition_targets() (Postgres) — the
/// single source of truth. This class keeps only UI-side helpers that
/// operate on an already-computed calorie goal.
```

Note: `nutrition_plan_page.dart` still references the deleted functions at this point — that's Task 9's subject. To keep the build green, Task 9 must be executed before running `flutter analyze` on the whole app; run only the targeted tests here:

Run: `flutter test test/providers/health_profile_provider_test.dart test/core test/features/settings`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/providers/health_profile_provider.dart lib/core/nutrition_calculator.dart test/providers/health_profile_provider_test.dart
git commit -m "refactor: health profile save recomputes via calculate_nutrition_targets RPC"
```

---

### Task 8: `IntensityBadge` — post-clamp pace input, l10n labels

**Files:**
- Modify: `lib/features/settings/widgets/intensity_badge.dart`
- Modify: `lib/features/auth/onboarding_page.dart:1497-1501` (call site)
- Modify: `lib/features/settings/health_profile_page.dart:454-458` (call site)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`

**Interfaces:**
- Produces: `IntensityBadge({required double? paceKgWeek, required bool isGain})`. Thresholds (spec §1.9): loss `<0.35` Sustainable, `0.35–0.70` Moderate, `>0.70` Intense; gain `<0.15` / `0.15–0.35` / `>0.35`. Task 9 consumes this for the result card.

- [ ] **Step 1: Add ARB keys (both files, then gen-l10n)**

`app_en.arb`:
```json
"intensityBadgeIntense": "Intense",
"intensityBadgeModerate": "Moderate",
"intensityBadgeSustainable": "Sustainable",
```
`app_fr.arb`:
```json
"intensityBadgeIntense": "Intense",
"intensityBadgeModerate": "Modéré",
"intensityBadgeSustainable": "Durable",
```
Run: `flutter gen-l10n`

- [ ] **Step 2: Rewrite the widget**

```dart
// lib/features/settings/widgets/intensity_badge.dart

import 'package:flutter/material.dart';
import 'package:akeli/l10n/app_localizations.dart';
import '../../../core/theme.dart';

/// Pill badge classifying a pace in kg/week. Callers MUST pass the
/// post-clamp effective pace when displaying a computed plan (spec §1.9/D2);
/// pre-calculation contexts (goals step) may pass the requested pace.
///
/// Thresholds (spec §1.9): loss <0.35 Sustainable, 0.35–0.70 Moderate,
/// >0.70 Intense; gain <0.15 / 0.15–0.35 / >0.35.
class IntensityBadge extends StatelessWidget {
  final double? paceKgWeek;
  final bool isGain;

  const IntensityBadge({
    super.key,
    required this.paceKgWeek,
    required this.isGain,
  });

  @override
  Widget build(BuildContext context) {
    final pace = paceKgWeek;
    if (pace == null || pace <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    final (lower, upper) = isGain ? (0.15, 0.35) : (0.35, 0.70);
    final (label, bg, fg) = pace > upper
        ? (
            l10n.intensityBadgeIntense,
            AkeliColors.error.withValues(alpha: 0.12),
            AkeliColors.error,
          )
        : pace >= lower
            ? (
                l10n.intensityBadgeModerate,
                AkeliColors.tertiaryFixed,
                AkeliColors.onTertiaryFixed,
              )
            : (
                l10n.intensityBadgeSustainable,
                AkeliColors.secondaryContainer,
                AkeliColors.onSecondaryContainer,
              );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.08,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update the two call sites (requested pace, pre-calculation contexts)**

`onboarding_page.dart` (goals step, ~line 1497):

```dart
IntensityBadge(
  paceKgWeek: (data.targetWeight != null && data.weight != null)
      ? (data.targetWeight! - data.weight!).abs() /
          (data.timelineMonths * 4.33)
      : null,
  isGain: (data.targetWeight ?? 0) > (data.weight ?? 0),
),
```

`health_profile_page.dart` (~line 454, `targetWeeks` from Task 6 in scope):

```dart
IntensityBadge(
  paceKgWeek: (local.weightKg != null && local.targetWeightKg != null)
      ? (local.targetWeightKg! - local.weightKg!).abs() / targetWeeks
      : null,
  isGain: (local.targetWeightKg ?? 0) > (local.weightKg ?? 0),
),
```

- [ ] **Step 4: Verify and commit**

Run: `flutter analyze lib/features/settings/widgets/intensity_badge.dart lib/features/settings/health_profile_page.dart`
Expected: no issues (onboarding_page still red until Task 10 only if you removed things it uses — it shouldn't be; check with `flutter analyze lib/features/auth/onboarding_page.dart`).

```bash
git add lib/features/settings/widgets/intensity_badge.dart lib/features/auth/onboarding_page.dart lib/features/settings/health_profile_page.dart lib/l10n
git commit -m "feat: IntensityBadge classifies kg/week pace with l10n labels"
```

---

### Task 9: `NutritionPlanPage` — async RPC calculate, honest result card, field guards

**Files:**
- Modify: `lib/features/nutrition_plan/nutrition_plan_page.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`

**Interfaces:**
- Consumes: `fetchNutritionTargets` / `remainingWeeksFromMonths` / `remainingWeeksFromDate` / `NutritionTargetsResult` (Task 5), `NutritionInputBounds` (Task 4), `IntensityBadge` (Task 8), `primaryGoalFromOnboardingSelections` (already in this file), `HealthProfileModel.targetDate` (Task 6).

- [ ] **Step 1: Add ARB keys (both files, then gen-l10n)**

`app_en.arb`:
```json
"nutritionPlanCalculateError": "Could not calculate your targets. Check your inputs and connection, then try again.",
"nutritionPlanEffectivePace": "Effective pace: {pace} kg/week",
"@nutritionPlanEffectivePace": { "placeholders": { "pace": { "type": "String" } } },
"nutritionPlanEstimatedDate": "Estimated goal date: {date}",
"@nutritionPlanEstimatedDate": { "placeholders": { "date": { "type": "String" } } },
"inputGuardWeightRange": "Enter a weight between {min} and {max} {unit}",
"@inputGuardWeightRange": { "placeholders": { "min": { "type": "String" }, "max": { "type": "String" }, "unit": { "type": "String" } } },
"inputGuardHeightRange": "Enter a height between {min} and {max} {unit}",
"@inputGuardHeightRange": { "placeholders": { "min": { "type": "String" }, "max": { "type": "String" }, "unit": { "type": "String" } } },
"inputGuardAgeRange": "Age must be between 18 and 100",
```
`app_fr.arb`:
```json
"nutritionPlanCalculateError": "Impossible de calculer vos objectifs. Vérifiez vos saisies et votre connexion, puis réessayez.",
"nutritionPlanEffectivePace": "Rythme effectif : {pace} kg/semaine",
"@nutritionPlanEffectivePace": { "placeholders": { "pace": { "type": "String" } } },
"nutritionPlanEstimatedDate": "Date estimée de l'objectif : {date}",
"@nutritionPlanEstimatedDate": { "placeholders": { "date": { "type": "String" } } },
"inputGuardWeightRange": "Saisissez un poids entre {min} et {max} {unit}",
"@inputGuardWeightRange": { "placeholders": { "min": { "type": "String" }, "max": { "type": "String" }, "unit": { "type": "String" } } },
"inputGuardHeightRange": "Saisissez une taille entre {min} et {max} {unit}",
"@inputGuardHeightRange": { "placeholders": { "min": { "type": "String" }, "max": { "type": "String" }, "unit": { "type": "String" } } },
"inputGuardAgeRange": "L'âge doit être compris entre 18 et 100 ans",
```
Run: `flutter gen-l10n`

- [ ] **Step 2: New state + load path**

Imports to add: `nutrition_input_bounds.dart`, `nutrition_targets_provider.dart`, `../settings/widgets/intensity_badge.dart`. Remove the now-dead import usage of `activityLevelForCalculator`.

Add state fields after `_calorieGoal`:

```dart
  double? _targetWeightKg;
  int? _remainingWeeks;
  double? _effectivePace;
  double? _estimatedWeeks;
```

In `_loadInitialData()` onboarding branch, inside `setState`, replace the whole `targetWeight` if/else block (already `primaryGoalFromOnboardingSelections` from the earlier fix) with:

```dart
        _primaryGoal = primaryGoalFromOnboardingSelections(
          weightGoal: obData.weightGoal,
          muscleGoal: obData.muscleGoal,
        );
        _targetWeightKg = obData.targetWeight;
        _remainingWeeks = obData.targetWeight != null
            ? remainingWeeksFromMonths(obData.timelineMonths)
            : null;
```

In the settings branch (`else if (healthProfile != null)`), add:

```dart
        _targetWeightKg = healthProfile.targetWeightKg;
        _remainingWeeks = remainingWeeksFromDate(healthProfile.targetDate);
```

Also change the final `else { _calculateResults(); }` call site — `_calculateResults` becomes async; call it as `unawaited(_calculateResults());` with `import 'dart:async';`.

- [ ] **Step 3: Async `_calculateResults` via RPC**

Replace the entire `_calculateResults()` with:

```dart
  bool get _healthParamsValid =>
      NutritionInputBounds.weightOk(_weightKg) &&
      NutritionInputBounds.heightOk(_heightCm) &&
      NutritionInputBounds.ageOk(_age);

  Future<void> _calculateResults() async {
    _logger.userAction('Calculate button tapped', screen: 'NutritionPlanPage');
    if (!_healthParamsValid) return; // button is disabled; belt-and-braces
    final l10n = AppLocalizations.of(context);
    final client = ref.read(supabaseClientProvider);
    try {
      final res = await fetchNutritionTargets(
        client,
        weightKg: _weightKg,
        heightCm: _heightCm,
        age: _age,
        sex: _sex,
        activityLevel: _activityLevel,
        primaryGoal: _primaryGoal,
        targetWeightKg: _targetWeightKg,
        remainingWeeks: _remainingWeeks,
      );
      if (!mounted) return;
      if (res == null) {
        _logger.provider('NutritionPlanPage → calculate returned zero rows');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.nutritionPlanCalculateError)));
        return;
      }

      final defaultSplits = NutritionCalculatorService.getDefaultMealSplits(3);
      final newDistributions = defaultSplits.entries
          .mapIndexed((i, e) => MealDistribution(
                mealType: e.key,
                sortOrder: i,
                caloriePct: e.value,
                calorieTarget: res.calorieGoal.toDouble() * (e.value / 100),
              ))
          .toList();

      final totalMacroCal =
          (res.proteinG * 4) + (res.carbG * 4) + (res.fatG * 9);
      _logger.provider(
          'NutritionPlanPage → calculated | goal: ${res.calorieGoal} | pace: ${res.effectivePaceKgWeek}');
      setState(() {
        _bmr = res.bmr;
        _tdee = res.tdee;
        _calorieGoal = res.calorieGoal;
        if (totalMacroCal > 0) {
          _proteinPct = ((res.proteinG * 4) / totalMacroCal) * 100;
          _carbPct = ((res.carbG * 4) / totalMacroCal) * 100;
          _fatPct = ((res.fatG * 9) / totalMacroCal) * 100;
        }
        _effectivePace = res.effectivePaceKgWeek;
        _estimatedWeeks = res.estimatedWeeksToTarget;
        _distributions = newDistributions;
        _isCalculated = true;
      });
    } catch (e, st) {
      _logger.provider('NutritionPlanPage → calculate error | $e',
          error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.nutritionPlanCalculateError)));
    }
  }
```

Update the Calculate button (line ~442): `onPressed: _healthParamsValid ? _calculateResults : null,`.

- [ ] **Step 4: Field guards (settings-mode health params)**

Add `errorText:` to the three `InputDecoration`s (weight/height metric variant/age), e.g. weight:

```dart
errorText: NutritionInputBounds.weightOk(_weightKg)
    ? null
    : l10n.inputGuardWeightRange(
        isUs
            ? UnitConverter.kgToLb(NutritionInputBounds.minWeightKg).toStringAsFixed(0)
            : NutritionInputBounds.minWeightKg.toStringAsFixed(0),
        isUs
            ? UnitConverter.kgToLb(NutritionInputBounds.maxWeightKg).toStringAsFixed(0)
            : NutritionInputBounds.maxWeightKg.toStringAsFixed(0),
        isUs ? 'lb' : 'kg'),
```

Height (cm variant) uses `heightOk(_heightCm)` + `l10n.inputGuardHeightRange('120', '230', 'cm')`. For the US ft/in variant, put the errorText on the feet field with the imperial bounds baked into the min/max strings and an empty unit: `l10n.inputGuardHeightRange("3'11\"", "7'6\"", '')`. Age uses `ageOk(_age)` + `l10n.inputGuardAgeRange`.

- [ ] **Step 5: Honest result card (spec §1.9)**

In the Result Card `Column`, after the BMR/TDEE `Text`, add:

```dart
                      if (_effectivePace != null && _effectivePace! > 0) ...[
                        const SizedBox(height: 8),
                        IntensityBadge(
                          paceKgWeek: _effectivePace,
                          isGain: _primaryGoal == 'muscle_gain',
                        ),
                        const SizedBox(height: 4),
                        Text(
                            l10n.nutritionPlanEffectivePace(
                                _effectivePace!.toStringAsFixed(2)),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        if (_estimatedWeeks != null)
                          Text(
                              l10n.nutritionPlanEstimatedDate(
                                  MaterialLocalizations.of(context)
                                      .formatShortDate(DateTime.now().add(
                                          Duration(
                                              days: (_estimatedWeeks! * 7)
                                                  .round())))),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                      ],
```

- [ ] **Step 6: Verify**

Run: `flutter analyze lib/features/nutrition_plan/nutrition_plan_page.dart && flutter test test/features/nutrition_plan/nutrition_plan_page_test.dart`
Expected: analyze clean; the 7 `primaryGoalFromOnboardingSelections` tests still PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/nutrition_plan/nutrition_plan_page.dart lib/l10n
git commit -m "feat(nutrition-plan): RPC-backed calculation, effective-pace card, input guards"
```

---

### Task 10: Onboarding + Settings — guards, warnings, `target_date` in submit

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart` (`_StepProfile` fields ~896-1018, `_StepGoals` target field ~1464-1486, `_MetricField` ~1120-1190, `_submit` ~91-143)
- Modify: `lib/features/auth/onboarding_data.dart` (`canAdvance` ~240-261)
- Modify: `lib/features/settings/health_profile_page.dart` (weight/height/target-weight fields, birthdate picker, `_save`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`

**Interfaces:**
- Consumes: `NutritionInputBounds` (Task 4), ARB keys from Task 9 (`inputGuardWeightRange`, `inputGuardHeightRange`, `inputGuardAgeRange`).
- Produces: `complete-onboarding` body gains `'target_date': 'YYYY-MM-DD'` (Task 11 consumes).

- [ ] **Step 1: Add the warning ARB keys (both files, then gen-l10n)**

`app_en.arb`:
```json
"inputGuardTargetContradictsLoss": "Your target is above your current weight — your plan will use maintenance calories unless you adjust it",
"inputGuardTargetContradictsGain": "Your target is below your current weight — your plan will use maintenance calories unless you adjust it",
"inputGuardTargetUnderweight": "This target implies an underweight BMI (below 18.5)",
```
`app_fr.arb`:
```json
"inputGuardTargetContradictsLoss": "Votre objectif est supérieur à votre poids actuel — votre plan utilisera des calories de maintien si vous ne l'ajustez pas",
"inputGuardTargetContradictsGain": "Votre objectif est inférieur à votre poids actuel — votre plan utilisera des calories de maintien si vous ne l'ajustez pas",
"inputGuardTargetUnderweight": "Cet objectif implique un IMC d'insuffisance pondérale (inférieur à 18,5)",
```
Run: `flutter gen-l10n`

- [ ] **Step 2: `_MetricField` gains `errorText`**

```dart
class _MetricField extends StatefulWidget {
  final String value;
  final String suffix;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const _MetricField({
    required this.value,
    required this.suffix,
    required this.onChanged,
    this.errorText,
  });
  // ...
```

In `_MetricFieldState.build`, wrap the existing `Container` in a `Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ <existing Container>, if (widget.errorText != null) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text(widget.errorText!, style: const TextStyle(color: AkeliColors.error, fontSize: 11))) ])`.

- [ ] **Step 3: Wire guards into `_StepProfile`**

Age field (~line 896):

```dart
                          _MetricField(
                            value: data.age?.toString() ?? '',
                            suffix: l10n.onboardingProfileAgeSuffix,
                            errorText: NutritionInputBounds.ageOk(data.age)
                                ? null
                                : l10n.inputGuardAgeRange,
                            onChanged: (v) => notifier.updateProfile(
                                age: int.tryParse(v)),
                          ),
```

Weight field: add to the existing `_MetricField`:

```dart
                            errorText: NutritionInputBounds.weightOk(data.weight)
                                ? null
                                : l10n.inputGuardWeightRange(
                                    isUs ? '66' : '30',
                                    isUs ? '661' : '300',
                                    isUs ? 'lb' : 'kg'),
```

Height: metric variant gets `errorText: NutritionInputBounds.heightOk(data.height) ? null : l10n.inputGuardHeightRange('120', '230', 'cm')`; the US ft/in variant puts the same check on the feet `_MetricField` with `l10n.inputGuardHeightRange("3'11\"", "7'6\"", '')`.

Import at top of file (if absent): `import '../../core/nutrition_input_bounds.dart';`

- [ ] **Step 4: Target-weight guards + warnings in `_StepGoals`**

Add a helper method to `_StepGoalsState`:

```dart
  String? _targetWarning(AppLocalizations l10n, OnboardingData data, bool isUs) {
    final t = data.targetWeight;
    if (t == null) return null;
    if (!NutritionInputBounds.weightOk(t)) {
      return l10n.inputGuardWeightRange(
          isUs ? '66' : '30', isUs ? '661' : '300', isUs ? 'lb' : 'kg');
    }
    if (NutritionInputBounds.targetUnderweight(t, data.height)) {
      return l10n.inputGuardTargetUnderweight;
    }
    final w = data.weight;
    if (w != null && data.weightGoal == 'loss' && t >= w) {
      return l10n.inputGuardTargetContradictsLoss;
    }
    if (w != null && data.weightGoal == 'gain' && t <= w) {
      return l10n.inputGuardTargetContradictsGain;
    }
    return null;
  }
```

Below the target-weight `_MetricField` (~line 1486), add:

```dart
                Builder(builder: (context) {
                  final warning = _targetWarning(l10n, data, isUs);
                  if (warning == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AkeliSpacing.xs),
                    child: Text(warning,
                        style: const TextStyle(
                            color: AkeliColors.error, fontSize: 12)),
                  );
                }),
```

(Hard bound blocks via `canAdvance` below; the two "contradicts"/"underweight" cases are non-blocking by design — spec §1.6/§1.11.)

- [ ] **Step 5: Block advancement on out-of-bounds values**

`onboarding_data.dart` `canAdvance`:

```dart
      case 2: // Profile — name required; entered metrics must be plausible
        return state.name.trim().isNotEmpty &&
            NutritionInputBounds.weightOk(state.weight) &&
            NutritionInputBounds.heightOk(state.height) &&
            NutritionInputBounds.ageOk(state.age);
      case 3: // Goals — weight goal required; target must be plausible
        return state.weightGoal != null &&
            NutritionInputBounds.weightOk(state.targetWeight);
```

Import: `import 'package:akeli/core/nutrition_input_bounds.dart';`

- [ ] **Step 6: Send `target_date` in `_submit`**

In `_submit()` (~line 99), after `final now = DateTime.now().toUtc().toIso8601String();` add:

```dart
    // Date-anchored goal deadline (spec D1/D6): today + timelineMonths.
    final targetDate = d.targetWeight != null
        ? DateTime(DateTime.now().year, DateTime.now().month + d.timelineMonths,
            DateTime.now().day)
        : null;
```

and in the `body` map, after the `target_weight_kg` line:

```dart
      if (targetDate != null)
        'target_date': targetDate.toIso8601String().split('T').first,
```

- [ ] **Step 7: Same guards on Settings ▸ Health Profile (spec §1.11 — third entry surface)**

In `lib/features/settings/health_profile_page.dart`:

1. Import `package:akeli/core/nutrition_input_bounds.dart`.
2. Locate the current-weight, height, and target-weight input fields (grep for `weightKg`, `heightCm`, `targetWeightKg` setters inside the page). Each field's `InputDecoration` gains an `errorText` following exactly the Task 9 Step 4 pattern (`weightOk`/`heightOk` against the metric canonical value, `inputGuardWeightRange`/`inputGuardHeightRange` with lb/ft-in strings for the US locale). The target-weight field additionally shows the non-blocking warnings via a `Text` under the field using the same logic as `_targetWarning` in Step 4 (`weightGoal == 'loss'` / `'gain'` from `local.weightGoal`, underweight check via `NutritionInputBounds.targetUnderweight(local.targetWeightKg, local.heightCm)`).
3. Locate the birthdate `showDatePicker` call and constrain it to the 18–100 age window:

```dart
final now = DateTime.now();
showDatePicker(
  context: context,
  initialDate: local.birthDate ??
      DateTime(now.year - 30, now.month, now.day),
  firstDate: DateTime(now.year - NutritionInputBounds.maxAge, now.month, now.day),
  lastDate: DateTime(now.year - NutritionInputBounds.minAge, now.month, now.day),
);
```

4. In `_save`, guard before persisting (blocking — mirrors `canAdvance`):

```dart
if (!NutritionInputBounds.weightOk(local.weightKg) ||
    !NutritionInputBounds.heightOk(local.heightCm) ||
    !NutritionInputBounds.weightOk(local.targetWeightKg)) {
  _logger.userAction('Save blocked by input guards',
      screen: 'HealthProfilePage');
  return;
}
```

- [ ] **Step 8: Verify and commit**

Run: `flutter analyze lib/features/auth lib/features/settings && flutter test`
Expected: clean; full suite passes.

```bash
git add lib/features/auth lib/features/settings lib/l10n
git commit -m "feat(guards): input bounds on onboarding and settings, target warnings, target_date submit"
```

---

### Task 11: `complete-onboarding` edge function persists `target_date`

**Files:**
- Modify: `supabase/functions/complete-onboarding/index.ts` (destructure ~line 38, upsert ~line 85)

**Interfaces:**
- Consumes: `'target_date'` body field (Task 10).

- [ ] **Step 1: Destructure and persist**

Add `target_date,` after `target_weight_kg,` in the body destructuring, and in the `user_health_profile` upsert object after `target_weight_kg,`:

```typescript
        ...(target_date !== undefined && { target_date }),
```

- [ ] **Step 2: Verify locally**

Run: `supabase functions serve complete-onboarding` compiles without error (Ctrl+C after startup), or minimally `deno check supabase/functions/complete-onboarding/index.ts` if deno is on PATH.
Expected: no type errors. (Redeploy to remote stays deferred with the rest of the DB push.)

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/complete-onboarding/index.ts
git commit -m "feat(edge): persist target_date from onboarding"
```

---

### Task 12: Cleanup, full verification, manual pass

**Files:**
- Delete: `test/features/nutrition_plan/nutrition_plan_simulation_test.dart`
- Verify-only: whole repo.

- [ ] **Step 1: Delete the Dart simulation harness** (its matrix now lives in pgTAP — Task 2)

```bash
git rm test/features/nutrition_plan/nutrition_plan_simulation_test.dart
```

- [ ] **Step 2: Stale-reference sweep**

Run and expect ZERO hits in `lib/` and `test/`:

```bash
grep -rn "calculateBMR\|calculateTDEE\|calculateCalorieGoal\|getDefaultMacros\|activityLevelForCalculator\|computeNutritionTargets\|computeCalorieGoal\|targetTimeWeeks\|target_time_weeks" lib/ test/
```

Fix anything found (docs/ and supabase/migrations history hits are fine — migrations are immutable).

- [ ] **Step 3: Full verification**

Run, all must pass:

```bash
flutter gen-l10n
flutter analyze
flutter test
supabase test db
```

- [ ] **Step 4: Manual verification (Docker psql + device)**

1. `docker exec <container> psql -U postgres -d postgres -c "SELECT * FROM calculate_nutrition_targets(70,170,30,'female','moderate','weight_loss',60,26);"` → expect 1827 kcal / P 120 / pace 0.38 / est 26.
2. Run the app, complete onboarding three times (loss with aggressive timeline, maintenance, gain): result card must show clearly different calories/macros, the badge, effective pace, and — for the aggressive timeline — an estimated date later than requested.
3. Enter weight 500 on the profile step → inline error, Next blocked. Enter a loss target above current weight → non-blocking warning shown.
4. Settings ▸ Health Profile: move the duration slider, save, reopen → slider position persists (via `target_date`).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove Dart formula remnants; full-suite verification for nutrition targets redesign"
```

---

## Self-Review Notes (already applied)

- Spec coverage: §1.1–§1.12 → Tasks 2–3 (formula/cron), §1.11/D11 → Tasks 4, 9, 10 (10 Step 7 covers the Settings surface incl. birthdate picker range); §1.9/D2 → Tasks 8–9; §2 → Task 2; §2.1/D7 → Task 3; §3/D4 → Tasks 1, 6; §4.1 → Tasks 9–10; §4.2 → Tasks 6–7, 9; §4.3 → Tasks 7, 12; §4.4 → Tasks 5, 9; §5 → Tasks 1–3; §6 → embedded per task.
- Known sequencing constraint: after Task 7 the app does not fully compile until Task 9 lands (nutrition_plan_page still references deleted calculator functions). Tasks 7→9 must not be reordered, and whole-repo `flutter analyze` is deferred to Tasks 9/12 on purpose.
- The Dart-side badge thresholds and the SQL bounds are intentionally duplicated constants; both carry cross-reference comments (spec-accepted duplication).
