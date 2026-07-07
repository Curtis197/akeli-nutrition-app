# Nutrition Targets Calculation Redesign — Design Spec

**Date:** 2026-07-07
**Status:** Approved (pending spec review)

## Problem

The calorie/macro computation (`lib/core/nutrition_calculator.dart`) produces
near-identical outputs regardless of the user's objective:

- The deficit/surplus is a flat −500/+300 kcal for every body and every pace.
  Weight-loss and maintenance results differ by a constant, and macro splits
  barely move (25–30% protein across all three goals).
- `target_weight_kg` and the onboarding timeline stepper (`timelineMonths`)
  are collected but never used in the math — they only feed the cosmetic
  Intense/Modéré/Durable badge. `target_time_weeks` exists as a DB column but
  onboarding never fills it.
- No safety bounds: a flat −500 can push a small user below their BMR.
- The exact same formula is duplicated in Dart and in the Postgres function
  `recalculate_nutrition_plans_from_weight()`
  (migration `20260703000000`), with a comment warning both must be kept in
  sync by hand — a standing drift risk on the app's most important number.

This is a core function of the product; wrong calories/macros directly cause
user dissatisfaction and churn.

## Goals

- One backend source of truth for the whole computation; zero Dart/SQL
  duplication.
- Calorie adjustment derived from the user's actual desired pace
  (target weight + timeline), not a flat constant.
- Hard safety bounds: BMR floor on deficits, %-of-TDEE cap on surpluses,
  clinical max pace clamps.
- Protein anchored to bodyweight (g/kg, sports-nutrition guidance), carbs/fat
  filling the remaining calories — so macros genuinely differ by objective.
- `timelineMonths` wired end-to-end: onboarding → computation → persisted as
  `user_health_profile.target_time_weeks` for Settings and the weekly cron.

## Non-Goals

- Changing BMR (Mifflin-St Jeor) or TDEE activity multipliers — both stay.
- Changing meal-slot distribution (`getDefaultMealSplits`) or the manual
  macro-slider override UX in Settings.
- Body-fat/lean-mass-based formulas (Katch-McArdle) — we don't collect body
  fat %.
- Push notifications or UI redesign of the nutrition plan page.

---

## 1. The Formula

### 1.1 BMR — Mifflin-St Jeor (unchanged)

```
bmr = 10*weight_kg + 6.25*height_cm − 5*age + (CASE sex WHEN 'male' THEN 5 ELSE −161 END)
```

`sex = 'other'` uses the −161 branch (matches current behavior).

### 1.2 TDEE (unchanged, DB activity codes mapped directly)

| `activity_level` (DB value) | multiplier |
|---|---|
| `sedentary` | 1.2 |
| `light` | 1.375 |
| `moderate` | 1.55 |
| `active` | 1.725 |
| `very_active` | 1.9 |
| NULL / other | 1.2 |

The Dart-side `activityLevelForCalculator` translation layer becomes
unnecessary for this path — the SQL function accepts DB codes natively.

### 1.3 Calorie adjustment — pace-based

Energy density constant: **7700 kcal per kg** of body mass change.
Daily adjustment for a pace `p` (kg/week): `p × 7700 / 7 = p × 1100`.

```
delta_kg = target_weight_kg − weight_kg        (signed)
raw_pace = |delta_kg| / target_time_weeks      (kg/week)
```

**weight_loss:**
- Effective pace = `min(raw_pace, 1.0)` kg/week (clinical max). No lower
  clamp — a small remaining delta naturally produces a small deficit.
- If `delta_kg >= 0` (target reached or crossed, or contradictory input):
  adjustment = 0 (maintenance calories). See §1.5.
- `calorie_goal = round(max(tdee − pace × 1100, bmr))` ← **BMR floor**, the
  goal can never drop below resting metabolic needs.

**muscle_gain:**
- Effective pace = `min(raw_pace, 0.5)` kg/week.
- If `delta_kg <= 0`: adjustment = 0 (maintenance calories).
- `calorie_goal = round(tdee + min(pace × 1100, 0.20 × tdee))` ← **surplus
  cap at +20% of TDEE** (beyond which gains are mostly fat).

**maintenance:** `calorie_goal = round(tdee)`; target weight ignored.

### 1.4 Defaults when target/timeline are NULL

When `target_weight_kg` or `target_time_weeks` is NULL, assume a moderate
default pace instead of the timeline math:

| Goal | Default pace | ≈ adjustment |
|---|---|---|
| weight_loss | 0.5 kg/week | −550 kcal/day (then BMR floor) |
| muscle_gain | 0.25 kg/week | +275 kcal/day (then 20% TDEE cap) |

### 1.5 Contradictory targets → maintenance (supersedes "default pace")

During brainstorming, section 2 initially proposed the default pace for
contradictory input (goal = loss but target above current weight); section 3's
adaptive-easing refinement supersedes it: **crossed or contradictory targets
yield zero adjustment (maintenance)**. Rationale:

- It is the mechanism that lets the weekly cron ease the deficit toward
  maintenance as the user approaches their target, and stop it entirely once
  reached — no stale "−550 forever".
- It is the safe direction: never impose a deficit on someone already at or
  below their target.
- At onboarding, the result card shows the computed number before saving, so
  a user who mistyped their target sees maintenance calories and can correct
  it. (Optional future UI nicety, out of scope: inline warning when target
  direction contradicts the selected objective.)

### 1.6 Macros — protein per kg bodyweight, fat %, carbs remainder

| Goal | Protein | Fat | Carbs |
|---|---|---|---|
| weight_loss | 2.0 g/kg | 25% of calorie_goal | remainder |
| muscle_gain | 1.8 g/kg | 25% of calorie_goal | remainder |
| maintenance | 1.4 g/kg | 25% of calorie_goal | remainder |

Guards:

- **Protein reference weight** for weight_loss =
  `LEAST(weight_kg, COALESCE(target_weight_kg, weight_kg))` — avoids inflated
  protein targets for heavier users (standard practice: dose protein against
  goal weight). Other goals use current weight.
- **Protein cap:** protein calories ≤ 35% of `calorie_goal`; grams reduced to
  the cap if exceeded (keeps carbs from going negative on low-calorie goals).

Gram conversions: protein/carbs 4 kcal/g, fat 9 kcal/g.

```
protein_g = min(ref_weight × g_per_kg, 0.35 × calorie_goal / 4)
fat_g     = 0.25 × calorie_goal / 9
carb_g    = (calorie_goal − protein_g × 4 − fat_g × 9) / 4
```

### 1.7 Worked examples (70 kg, 170 cm, 30 y, female, moderate → BMR 1452, TDEE 2250)

| Scenario | calorie_goal | protein | Notes |
|---|---|---|---|
| Lose 10 kg in 6 months (26 wk) | 1827 | 120 g | pace 0.38 kg/wk → −423; protein vs 60 kg ref |
| Lose 10 kg in 2 months (9 wk) | 1452 | 120 g | pace clamped to 1.0 → −1100 → **BMR floor** |
| Lose, no target set | 1700 | 140 g | default 0.5 kg/wk → −550; no target, so ref weight = current 70 kg |
| Maintain | 2250 | 98 g | plain TDEE, 1.4 g/kg |
| Gain, no target set | 2525 | 126 g | default 0.25 kg/wk → +275 (cap 450 not hit) |

Old behavior for the same profile: 1750 / 2250 / 2550 kcal with protein
128–141 g in every case.

---

## 2. Backend — `calculate_nutrition_targets()`

New Postgres function, **pure computation, no table access**:

```sql
CREATE FUNCTION public.calculate_nutrition_targets(
  p_weight_kg         numeric,
  p_height_cm         numeric,
  p_age               integer,
  p_sex               text,              -- 'male' | 'female' | 'other'
  p_activity_level    text,              -- DB codes (sedentary|light|moderate|active|very_active)
  p_primary_goal      text,              -- weight_loss | maintenance | muscle_gain
  p_target_weight_kg  numeric DEFAULT NULL,
  p_target_time_weeks integer DEFAULT NULL
) RETURNS TABLE (
  bmr numeric, tdee numeric, calorie_goal integer,
  protein_g numeric, carb_g numeric, fat_g numeric
)
LANGUAGE sql IMMUTABLE SECURITY INVOKER;
```

- `IMMUTABLE` + `SECURITY INVOKER`; `GRANT EXECUTE TO authenticated,
  service_role`. It's arithmetic — no RLS concern.
- Unknown `p_primary_goal` values (`health`, `performance`, NULL) fall through
  to maintenance, matching current behavior.
- Header comment marks it as the **single source of truth**; the old warning
  about keeping Dart and SQL in sync becomes obsolete.

### 2.1 Weekly cron rewrite

`recalculate_nutrition_plans_from_weight()` (migration `20260703000000`)
drops its inline formula and calls `calculate_nutrition_targets()` via a
`LATERAL` join — still one set-based statement, no per-user loop. Candidate
selection additionally pulls `target_weight_kg` and `target_time_weeks` from
`user_health_profile` and passes the **latest logged weight** as
`p_weight_kg`.

Emergent behavior (intended): as logged weight approaches the target, the
deficit shrinks automatically; once reached/crossed, the user gets
maintenance calories.

---

## 3. Call Sites & Wiring

### 3.1 Onboarding (Flutter)

- `NutritionPlanPage._calculateResults()` becomes async: calls
  `supabase.rpc('calculate_nutrition_targets', ...)` instead of local Dart
  math. In onboarding mode it reads from `onboardingProvider`:
  - `primary_goal` via `primaryGoalFromOnboardingSelections(weightGoal,
    muscleGoal)` (already implemented + tested).
  - `p_target_weight_kg` = `obData.targetWeight`.
  - `p_target_time_weeks` = `round(obData.timelineMonths × 4.33)` —
    **timelineMonths finally counts in the computation.**
- `onboarding_page.dart _submit()` adds `target_time_weeks` (same conversion,
  sent whenever `targetWeight` is provided) to the `complete-onboarding`
  body.
- `supabase/functions/complete-onboarding/index.ts` destructures
  `target_time_weeks` and includes it in the `user_health_profile` upsert
  (column already exists). Structured-logging standard applies to the touched
  step.

### 3.2 Settings (Flutter)

- `NutritionPlanPage` (settings mode) passes the stored
  `healthProfile.targetWeightKg` + `healthProfile.targetTimeWeeks`.
- `HealthProfileNotifier.save()` replaces the synchronous
  `computeNutritionTargets(updated)` call with an awaited RPC call using the
  same inputs; the rest of the save flow (meal-split rescale via `savePlan`)
  is unchanged.

### 3.3 Dart cleanup

- Removed from `nutrition_calculator.dart`: `calculateBMR`, `calculateTDEE`,
  `calculateCalorieGoal`, `getDefaultMacros`. Kept: `getDefaultMealSplits`,
  `calculateMacroGrams` (manual macro-slider UX only).
- Removed from `health_profile_provider.dart`: `computeCalorieGoal`,
  `computeNutritionTargets`, `activityLevelForCalculator` (RPC accepts DB
  codes). Their unit tests are replaced (see §5).
- `test/features/nutrition_plan/nutrition_plan_simulation_test.dart` (Dart
  simulation harness) is deleted; its 12-row matrix moves into pgTAP
  fixtures.

### 3.4 Error handling

If the RPC fails (offline, server error), show the page's existing save-error
snackbar pattern and keep prior values — **no silent local fallback**; a
visible retry beats a wrong first-time health number. Standard BEFORE/AFTER/
ERROR `_logger.db('rpc | fn: calculate_nutrition_targets …')` logging per the
project standard.

---

## 4. Migrations (in order)

| # | File | Purpose |
|---|---|---|
| 1 | `YYYYMMDD_add_calculate_nutrition_targets.sql` | Create the function + grants |
| 2 | `YYYYMMDD_recalculate_plans_use_calculator.sql` | Rewrite `recalculate_nutrition_plans_from_weight()` to LATERAL-join the new function; extend candidate selection with target columns |

Deployment note: DB is currently local-only (`supabase db push` deferred per
project memory); migrations apply locally via Docker until the push happens.
The `complete-onboarding` edge function redeploy must also be explicit.

---

## 5. Testing

### 5.1 pgTAP — `supabase/tests/calculate_nutrition_targets_test.sql`

- **Baseline:** male 30 y / 80 kg / 175 cm / active — BMR/TDEE hand-checked.
- **Pace math:** the §1.7 worked-example matrix asserted row by row.
- **Clamps:** loss pace > 1.0 clamped; gain pace > 0.5 clamped; surplus
  capped at 20% TDEE (use a high-TDEE profile where the cap binds).
- **BMR floor:** aggressive small-user scenario lands exactly on BMR.
- **Contradictory/crossed targets:** loss with target ≥ current →
  maintenance; gain with target ≤ current → maintenance.
- **NULL handling:** each of target/timeline NULL → default paces; NULL
  activity → 1.2; `sex='other'` → female constant; unknown goal →
  maintenance.
- **Macro guards:** protein ref weight = target for loss; 35% protein cap
  binding case; carbs never negative; grams × kcal re-sum ≈ calorie_goal.

### 5.2 pgTAP — cron function

Update `recalculate_nutrition_plans_from_weight_test.sql` expectations to the
new formula; add: user whose latest weight crossed the target → maintenance
calories.

### 5.3 Dart

- Keep `primaryGoalFromOnboardingSelections` tests (7 cases, passing).
- Replace deleted pure-function tests with a mocked-RPC test asserting the
  parameter mapping (incl. `timelineMonths → weeks` conversion) and the
  error-snackbar path.

### 5.4 Manual (Docker psql, test users A–D)

Run the function directly with each test user's profile; verify onboarding
end-to-end on device: pick each objective, confirm visibly different
calories/macros on the result card.

---

## 6. Files Changed

**New:**
- `supabase/migrations/YYYYMMDD_add_calculate_nutrition_targets.sql`
- `supabase/migrations/YYYYMMDD_recalculate_plans_use_calculator.sql`
- `supabase/tests/calculate_nutrition_targets_test.sql`

**Modified:**
- `lib/core/nutrition_calculator.dart` (shrink)
- `lib/providers/health_profile_provider.dart` (RPC-backed save, remove pure fns)
- `lib/features/nutrition_plan/nutrition_plan_page.dart` (async RPC calculate, target/timeline inputs)
- `lib/features/auth/onboarding_page.dart` (`target_time_weeks` in submit body)
- `supabase/functions/complete-onboarding/index.ts` (persist `target_time_weeks`)
- `supabase/tests/recalculate_nutrition_plans_from_weight_test.sql`
- `test/providers/health_profile_provider_test.dart` (replace deleted-fn tests)

**Deleted:**
- `test/features/nutrition_plan/nutrition_plan_simulation_test.dart`
