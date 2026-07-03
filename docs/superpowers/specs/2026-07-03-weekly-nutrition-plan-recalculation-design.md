# Weekly Nutrition Plan Recalculation — Design Spec
**Date:** 2026-07-03
**Status:** Approved

## Overview

A weekly cron job recalculates each user's calorie and macro targets from their most
recently logged weight, so `nutrition_plan` stays in step with real weight changes
instead of only updating when a user manually edits their health profile.

## Goals

- Every week, recompute `bmr` / `tdee` / `calorie_goal` / macro grams for users who
  logged a new weight recently, using the same Mifflin-St Jeor formula the app
  already uses (`lib/core/nutrition_calculator.dart`).
- Keep `user_health_profile.weight_kg` in sync with the latest `weight_log` entry
  used in the calculation.
- Keep `user_goal`'s numeric goal columns (`calorie_goal`, `protein_goal`,
  `carbs_goal`, `fat_goal`) in sync with the recalculated targets, since
  `generate_meal_plan_internal`'s fallback path and `swap_meal_plan_entry` read
  `user_goal.calorie_goal` directly rather than `nutrition_plan.calorie_goal`.
- Run early enough that the existing Monday meal-plan generation batch job picks up
  the updated `calorie_goal` for that week's plan.

## Non-Goals

- Triggering meal-plan regeneration directly (the existing
  `batch-generate-meal-plans-weekly` cron already regenerates meal plans every
  Monday and will naturally read the updated `calorie_goal`).
- Push notifications when a target changes.
- Any threshold/smoothing logic — every eligible user is recalculated every week,
  regardless of how small the change is.
- Changing `meal_distribution` directly — the existing
  `trg_sync_calorie_target_on_plan` trigger already rescales
  `meal_distribution.calorie_target` whenever `nutrition_plan.calorie_goal`
  changes.

---

## 1. Formula (ported from `lib/core/nutrition_calculator.dart`)

### 1.1 Activity level mapping

`user_health_profile.activity_level` stores one of `sedentary | light | moderate |
active | very_active` (its `CHECK` constraint), which is **not** the same set of
strings the Dart formula switches on. The app translates via
`activityLevelForCalculator` (`lib/providers/health_profile_provider.dart:14-29`)
before calling `calculateTDEE`. The SQL function must replicate the combined
mapping directly from the DB value to a multiplier:

| `activity_level` (DB value) | multiplier |
|---|---|
| `sedentary` | 1.2 |
| `light` | 1.375 |
| `moderate` | 1.55 |
| `active` | 1.725 |
| `very_active` | 1.9 |
| NULL / anything else | 1.2 (matches Dart's default-to-sedentary fallback) |

### 1.2 BMR (Mifflin-St Jeor)

```
bmr = 10*weight_kg + 6.25*height_cm - 5*age + (CASE WHEN sex = 'male' THEN 5 ELSE -161 END)
```

`sex = 'other'` falls into the `-161` branch, matching
`calculateBMR` (`lib/core/nutrition_calculator.dart:3-16`) exactly. `age` is
computed from `birth_date` as of `CURRENT_DATE` at run time (not cached), so a
birthday that falls between runs is naturally picked up.

### 1.3 TDEE

```
tdee = bmr * activity_multiplier
```

### 1.4 Calorie goal (by `user_goal.goal_type`, mirrors `calculateCalorieGoal`)

| `goal_type` | `calorie_goal` |
|---|---|
| `weight_loss` | `round(tdee - 500)` |
| `muscle_gain` | `round(tdee + 300)` |
| anything else (`maintenance`, `health`, `performance`) | `round(tdee)` |

### 1.5 Macros (by `goal_type`, mirrors `getDefaultMacros` + `calculateMacroGrams`)

| `goal_type` | protein % | carb % | fat % |
|---|---|---|---|
| `weight_loss` | 30 | 40 | 30 |
| `muscle_gain` | 30 | 45 | 25 |
| anything else | 25 | 50 | 25 |

Grams: `protein_goal_g = calorie_goal * protein_pct / 100 / 4`,
`carb_goal_g = calorie_goal * carb_pct / 100 / 4`,
`fat_goal_g = calorie_goal * fat_pct / 100 / 9`.

---

## 2. Candidate Selection

A user is recalculated only if **all** of the following hold; otherwise they are
silently excluded from the set-based update (no error, no row touched):

- Has a `nutrition_plan` row with `is_active = true`.
- Has a `user_goal` row with `is_active = true` (so `goal_type` is known — matches
  `computeNutritionTargets`'s null-check behavior in
  `lib/providers/health_profile_provider.dart:74-81`).
- Has a `user_health_profile` row with `height_cm`, `birth_date`, and `sex` all
  `NOT NULL`.
- Has a `weight_log` row with `logged_at >= CURRENT_DATE - INTERVAL '14 days'`. The
  most recent one (`logged_at` desc, `created_at` desc as tiebreak) is used as the
  current weight.

---

## 3. Backend Changes

### 3.1 New SQL function — `public.recalculate_nutrition_plans_from_weight()`

- No parameters. Returns `integer` — count of `nutrition_plan` rows updated.
- `SECURITY DEFINER`, granted to `service_role` only (same convention as
  `generate_meal_plan_internal`).
- Implemented as a single set-based statement (CTEs for candidate selection →
  computed targets → three `UPDATE`s), not a per-user loop — this is pure
  arithmetic, so one statement handles every eligible user in one pass:
  1. `UPDATE nutrition_plan SET calorie_goal = ..., bmr = ..., tdee = ...,
     protein_goal_g = ..., carb_goal_g = ..., fat_goal_g = ... FROM (candidates)
     WHERE nutrition_plan.id = candidates.id` — fires the existing
     `trg_sync_calorie_target_on_plan` trigger automatically.
  2. `UPDATE user_goal SET calorie_goal = ..., protein_goal = ..., carbs_goal =
     ..., fat_goal = ... FROM (candidates) WHERE user_goal.id = candidates.
     goal_id` — same active row, `goal_type`/`is_active` untouched. Keeps
     `generate_meal_plan_internal`'s fallback path and `swap_meal_plan_entry`
     (both of which read `user_goal.calorie_goal` directly) from drifting out of
     sync with `nutrition_plan`.
  3. `UPDATE user_health_profile SET weight_kg = candidates.latest_weight_kg FROM
     (candidates) WHERE user_health_profile.user_id = candidates.user_id`.
- Header comment cross-references `lib/core/nutrition_calculator.dart` and
  `lib/providers/health_profile_provider.dart` as the source of truth, flagging
  that both places must be updated together if the formula ever changes.

### 3.2 New edge function — `supabase/functions/recalculate-nutrition-plans/index.ts`

- Same `INTERNAL_SECRET` + `timingSafeEqual` auth pattern as
  `supabase/functions/batch-generate-meal-plans/index.ts`.
- Full structured logging per the project's mandatory logging standard: ENTRY
  log, `[STEP N]` labels, `logRLSCheck`/`logQueryResult` around the RPC call,
  catch-all error handler returning `serverError(e)`, EXIT log before the 200
  response.
- Body: a single `supabase.rpc('recalculate_nutrition_plans_from_weight')` call.
  No batching, pagination, or self-chaining — the SQL function already handles
  every eligible user in one call. Logs and returns the updated count:
  `{ updated: <count> }`.

### 3.3 Cron registration

New migration registers `recalculate-nutrition-plans-weekly` at `0 23 * * 0`
(Sunday 23:00 UTC) — two hours before `batch-generate-meal-plans-weekly` (Monday
01:00 UTC), so that week's meal-plan generation reads the freshly recalculated
`calorie_goal`. Same `vault.decrypted_secrets` for `INTERNAL_SECRET` and
idempotent `cron.unschedule`-then-`cron.schedule` pattern as the two existing
cron migrations (`20260531210607_register_batch_meal_plan_cron.sql`,
`20260602000004_register_meal_reminder_cron.sql`).

---

## 4. Migrations Summary (in order)

| # | File name pattern | What it does |
|---|---|---|
| 1 | `YYYYMMDD_add_recalculate_nutrition_plans_function.sql` | Creates `public.recalculate_nutrition_plans_from_weight()` |
| 2 | `YYYYMMDD_register_recalculate_nutrition_plans_cron.sql` | Registers the `recalculate-nutrition-plans-weekly` pg_cron job at `0 23 * * 0` |

---

## 5. Verification Tests

### 5.1 pgTAP — `supabase/tests/recalculate_nutrition_plans_from_weight_test.sql`

| # | Scenario | Setup | Expected |
|---|---|---|---|
| T1 | **Standard recalculation** | User with complete health profile, active goal/plan, weight_log dated today differing from current `nutrition_plan` values | `calorie_goal`/`bmr`/`tdee`/macros match hand-computed Mifflin-St Jeor values for each `activity_level` value |
| T2 | **Activity level mapping** | 5 users, one per `activity_level` value (`sedentary`/`light`/`moderate`/`active`/`very_active`) | Each recalculated `tdee` uses the correct multiplier (1.2/1.375/1.55/1.725/1.9) |
| T3 | **Stale weight_log (>14 days)** | weight_log dated 20 days ago | `nutrition_plan` unchanged |
| T4 | **No weight_log at all** | No weight_log rows for user | `nutrition_plan` unchanged |
| T5 | **Incomplete health profile** | `birth_date` NULL | `nutrition_plan` unchanged |
| T6 | **No active user_goal** | `user_goal.is_active = false` for all rows | `nutrition_plan` unchanged |
| T7 | **No active nutrition_plan** | `nutrition_plan.is_active = false` | Nothing updated for that user |
| T8 | **weight_kg snapshot sync** | Same setup as T1 | `user_health_profile.weight_kg` equals the `weight_log.weight_kg` used |
| T8b | **user_goal numeric sync** | Same setup as T1 | Active `user_goal` row's `calorie_goal`/`protein_goal`/`carbs_goal`/`fat_goal` match the new `nutrition_plan` values; `goal_type` and `is_active` unchanged |
| T9 | **meal_distribution cascade** | User has `meal_distribution` rows with `calorie_pct` set | `calorie_target` on each row rescales to match the new `calorie_goal` (via existing trigger, not touched directly by this function) |
| T10 | **goal_type branches** | Three users: `weight_loss`, `muscle_gain`, `maintenance` | `calorie_goal` offset (-500/+300/0) and macro % splits match section 1.4/1.5 |
| T11 | **Return value** | Batch of N eligible + M ineligible users | Function returns exactly N |

### 5.2 Manual local verification (Docker psql, existing test users A/B/C/D)

1. Insert a new `weight_log` row for test user A with a different weight, dated
   today.
2. Run `SELECT public.recalculate_nutrition_plans_from_weight();` directly.
3. Confirm the returned count and inspect `nutrition_plan` /
   `user_health_profile` / `meal_distribution` for user A match expectations.
4. Confirm test users with no recent weight_log (or intentionally incomplete
   profiles) are untouched.

### 5.3 Edge function

No automated test harness exists yet for edge functions in this repo. Verify
manually via `curl` with the `INTERNAL_SECRET` bearer token against the deployed
function, confirming the logged/returned count matches step 5.2's expectation.

### 5.4 Deployment

This requires `supabase db push` (or applying via the Supabase MCP) for both
migrations, plus deploying the new edge function — neither happens
automatically and must be done explicitly as part of implementation.

---

## 6. Files Changed

**New:**
- `supabase/migrations/YYYYMMDD_add_recalculate_nutrition_plans_function.sql`
- `supabase/migrations/YYYYMMDD_register_recalculate_nutrition_plans_cron.sql`
- `supabase/functions/recalculate-nutrition-plans/index.ts`
- `supabase/tests/recalculate_nutrition_plans_from_weight_test.sql`

**Modified:**
- None — this feature is additive; it reads existing tables and writes only to
  `nutrition_plan` and `user_health_profile.weight_kg`, both already writable by
  `service_role`.
