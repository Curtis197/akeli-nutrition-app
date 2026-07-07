# Nutrition Targets Calculation Redesign — Design Spec (v2)

**Date:** 2026-07-07
**Status:** Approved — all alignment questions resolved
**Supersedes:** v1 of this spec (same date)

## Decision log (resolved during spec review)

| # | Decision | Resolution |
|---|---|---|
| D1 | Timeline model | **Constant pace, date-anchored** (`target_date`), not static-weeks easing |
| D2 | Result card / badge | Derived from **post-clamp effective pace**, never from requested inputs |
| D3 | Contradictory-target warning | **In V1 scope** (onboarding + Settings inline validation) |
| D4 | `target_time_weeks` column | **Dropped** (never populated by V0 onboarding; replaced by `target_date`) |
| D5 | Overdue-date floor | Remaining weeks floored at **4** |
| D6 | Onboarding UI | `timelineMonths` stepper kept; converted to `target_date` — no date picker in V1 |
| D7 | Cron weight input | **7-day smoothed weight** (avg of logs in last 7 days, fallback latest). Hysteresis on crossing: noted as future hardening, not V1 |
| D8 | Deficit floor | **Pure BMR** — no absolute 1,200 kcal floor |
| D9 | Regain after target reached | Automatic deficit resumption via the 4-week floor is **intended behavior**, stated and tested |
| D10 | Input contract | Invalid required inputs → **empty row** (caller shows error; cron skips user) |
| D11 | Client input guards | UI blocks out-of-bounds weight/height/age/target at the field level (§1.12); backend zero-rows becomes a defense-in-depth layer, not the primary UX |

## Problem

The calorie/macro computation (`lib/core/nutrition_calculator.dart`) produces
near-identical outputs regardless of the user's objective:

- The deficit/surplus is a flat −500/+300 kcal for every body and every pace.
  Weight-loss and maintenance results differ by a constant, and macro splits
  barely move (25–30% protein across all three goals).
- `target_weight_kg` and the onboarding timeline stepper (`timelineMonths`)
  are collected but never used in the math — they only feed the cosmetic
  Intense/Modéré/Durable badge.
- No safety bounds: a flat −500 can push a small user below their BMR.
- The exact same formula is duplicated in Dart and in the Postgres function
  `recalculate_nutrition_plans_from_weight()` (migration `20260703000000`),
  with a comment warning both must be kept in sync by hand — a standing drift
  risk on the app's most important number.

This is a core function of the product; wrong calories/macros directly cause
user dissatisfaction and churn.

## Goals

- One backend source of truth for the whole computation; zero Dart/SQL
  duplication.
- Calorie adjustment derived from the user's actual desired pace
  (target weight + target date), **constant over the journey** — the
  timeline shown at onboarding is the timeline the math honors.
- Hard safety bounds: BMR floor on deficits, %-of-TDEE cap on surpluses,
  clinical max pace clamps, 4-week floor on remaining time.
- Protein anchored to bodyweight (g/kg), carbs/fat filling the remaining
  calories — macros genuinely differ by objective.
- Honest UI: displayed pace, estimated date, and badge all derive from the
  **effective** (post-clamp) output.
- Weekly cron resilient to weigh-in noise (7-day smoothing).

## Non-Goals

- Changing BMR (Mifflin-St Jeor) or TDEE activity multipliers — both stay.
- Changing meal-slot distribution (`getDefaultMealSplits`) or the manual
  macro-slider override UX in Settings.
- Body-fat/lean-mass-based formulas (Katch-McArdle) — body fat % not collected.
- Crossing hysteresis (see §1.8) — future hardening, one-line note only.
- Push notifications or UI redesign of the nutrition plan page.

---

## 1. The Formula

### 1.1 BMR — Mifflin-St Jeor (unchanged)

```
bmr = 10*weight_kg + 6.25*height_cm − 5*age + (CASE sex WHEN 'male' THEN 5 ELSE −161 END)
```

`sex = 'other'` uses the −161 branch (matches current behavior).

**Assumptions (stated, no code impact):**
- Mifflin-St Jeor is an adult equation; the computation assumes age ≥ 18,
  aligned with Akeli's terms of use.
- Callers derive `p_age` from a stored **birthdate at call time** — never
  from a stored age integer, which would silently drift as users age. If any
  V1 profile path stores an integer age, it migrates to birthdate.

### 1.2 TDEE (unchanged, DB activity codes mapped directly)

| `activity_level` (DB value) | multiplier |
|---|---|
| `sedentary` | 1.2 |
| `light` | 1.375 |
| `moderate` | 1.55 |
| `active` | 1.725 |
| `very_active` | 1.9 |
| NULL / other | 1.2 |

The Dart-side `activityLevelForCalculator` translation layer is removed —
the SQL function accepts DB codes natively.

### 1.3 Timeline — date-anchored, constant pace

`user_health_profile` stores **`target_date date`** (new column;
`target_time_weeks` is dropped). Onboarding computes
`target_date = today + timelineMonths` (month arithmetic, then cast to date).

The function stays IMMUTABLE, so it cannot read `current_date`: it accepts
**`p_remaining_weeks`**, computed by each caller:

```
remaining_weeks = GREATEST(4, CEIL((target_date − today) / 7.0))
```

- **Dart (onboarding/Settings):** computed at call time from
  `target_date` (at onboarding, directly from `timelineMonths × 4.33`,
  since target_date is "today + timeline").
- **Cron (SQL):** same expression inside candidate selection.

Because the denominator shrinks in step with the remaining delta, the
prescribed pace stays constant across the journey: a 10 kg / 26-week user
sits at ~0.38 kg/week whether 10 kg and 26 weeks remain or 5 kg and 13 weeks
remain. The stated timeline is honored.

**Overdue protection (the 4-week floor):** when `target_date` has passed
with weight remaining, remaining weeks pins at 4 → pace =
`remaining_delta / 4`, then bounded by the existing clamps (§1.4) and the
BMR floor. An overdue plan pushes at a firm but safe pace until crossing
(§1.6) stops it at maintenance. No unbounded deficit is possible.

### 1.4 Calorie adjustment — pace-based

Energy density constant: **7700 kcal per kg** of body mass change.
Daily adjustment for a pace `p` (kg/week): `p × 7700 / 7 = p × 1100`.

```
delta_kg = target_weight_kg − weight_kg        (signed)
raw_pace = |delta_kg| / remaining_weeks        (kg/week)
```

**weight_loss:**
- Effective pace = `min(raw_pace, 1.0)` kg/week (clinical max). No lower
  clamp — a small remaining delta naturally produces a small deficit.
- If `delta_kg >= 0` (target reached/crossed, or contradictory input):
  adjustment = 0 (maintenance calories). See §1.6.
- `calorie_goal = round(max(tdee − pace × 1100, bmr))` ← **BMR floor**
  (pure BMR — no absolute kcal floor; BMR is the physiological bound, D8).

**muscle_gain:**
- Effective pace = `min(raw_pace, 0.5)` kg/week.
- If `delta_kg <= 0`: adjustment = 0 (maintenance calories).
- `calorie_goal = round(tdee + min(pace × 1100, 0.20 × tdee))` ← **surplus
  cap at +20% of TDEE**.

**maintenance:** `calorie_goal = round(tdee)`; target weight ignored.

### 1.5 Defaults when target or date are NULL

When `target_weight_kg` or `target_date` is NULL, assume a moderate default
pace instead of the timeline math:

| Goal | Default pace | ≈ adjustment |
|---|---|---|
| weight_loss | 0.5 kg/week | −550 kcal/day (then BMR floor) |
| muscle_gain | 0.25 kg/week | +275 kcal/day (then 20% TDEE cap) |

Known V1 limitation (accepted): a no-target weight_loss user keeps −550
indefinitely — crossing detection (§1.6) needs a target. Future nudge:
"set a target so your plan can adapt."

### 1.6 Crossed / contradictory targets → maintenance

Crossed or contradictory targets yield **zero adjustment (maintenance)**:
loss with `delta_kg >= 0`, gain with `delta_kg <= 0`.

- Safe direction: never impose a deficit on someone already at or below
  their target (and symmetrically for gain).
- Combined with the weekly cron, this is the automatic stop at goal.

**Regain protection (intended emergent behavior, D9):** after the target is
reached (maintenance) and the date has passed, a later regain re-opens a
negative delta → remaining weeks pinned at 4 → a moderate, clamped deficit
resumes automatically until the user is back at target. Example: 2 kg
regained → pace 2/4 = 0.5 kg/week → −550. This is designed behavior and is
asserted in pgTAP (§6.1, §6.2).

**V1 UI validation (D3):** the target-weight step in onboarding — and the
same fields in Settings — show an inline warning when the target direction
contradicts the selected objective (loss with target ≥ current; gain with
target ≤ current): the plan will compute at maintenance unless corrected.
Backend behavior is unchanged; this is the UI layer catching a mistype
before it becomes a wrong first number. Non-blocking (the user may genuinely
want maintenance-at-target), but explicit.

### 1.7 Macros — protein per kg bodyweight, fat %, carbs remainder

| Goal | Protein | Fat | Carbs |
|---|---|---|---|
| weight_loss | 2.0 g/kg | 25% of calorie_goal | remainder |
| muscle_gain | 1.8 g/kg | 25% of calorie_goal | remainder |
| maintenance | 1.4 g/kg | 25% of calorie_goal | remainder |

Guards:

- **Protein reference weight** for weight_loss =
  `LEAST(weight_kg, COALESCE(target_weight_kg, weight_kg))` — protein dosed
  against goal weight (standard practice). Other goals use current weight.
- **Protein cap:** protein calories ≤ 35% of `calorie_goal`; grams reduced
  to the cap if exceeded.
- Structural safety: 35% protein cap + fixed 25% fat ⇒ carbs ≥ 40% of
  calories — carbs can never go negative at any calorie level.

Gram conversions: protein/carbs 4 kcal/g, fat 9 kcal/g.

```
protein_g = min(ref_weight × g_per_kg, 0.35 × calorie_goal / 4)
fat_g     = 0.25 × calorie_goal / 9
carb_g    = (calorie_goal − protein_g × 4 − fat_g × 9) / 4
```

### 1.8 Cron weight input — 7-day smoothing (D7)

Raw day-to-day weight fluctuates ±1–2 kg (water, glycogen, meal timing).
The weekly cron therefore feeds the computation a **smoothed weight**:

```
smoothed_weight = AVG(weight_kg of logs in the last 7 days)
                  fallback: latest logged weight if none in the window
```

Used for **both** the pace math and the crossing check (§1.6) — this
prevents plan jitter and false maintenance-flips near the target.

*Future hardening (out of V1 scope):* crossing hysteresis — once maintenance
triggers, require smoothed weight to move ≥ 0.5 kg back past the target
before the deficit resumes.

Onboarding/Settings use the user-entered current weight directly (a single
deliberate input, not a noisy log).

### 1.9 Effective pace & honest display (D2)

The function returns, computed **after all clamps and floors**:

```
effective_pace_kg_week    -- loss: (tdee − calorie_goal)/1100
                          -- gain: (calorie_goal − tdee)/1100
                          -- maintenance: 0
estimated_weeks_to_target -- |delta_kg| / effective_pace
                          -- NULL if maintenance, no target, or pace = 0
```

UI contract:
- The result card (onboarding and Settings) displays **effective pace** and
  an **estimated achievement date** (`today + estimated_weeks_to_target`),
  never the requested inputs.
- The Intense/Modéré/Durable badge derives from **effective pace**.
  Proposed thresholds (adjust to existing badge copy if needed):
  loss — < 0.35 Durable, 0.35–0.70 Modéré, > 0.70 Intense;
  gain — < 0.15 Durable, 0.15–0.35 Modéré, > 0.35 Intense.
- Rationale: for a sedentary user, TDEE = 1.2 × BMR caps the deficit at
  0.2 × BMR (§1.12 profile as sedentary: max ≈ 290 kcal/day ≈ 0.26 kg/week).
  Ambitious requests are physically unreachable for this segment; the card
  must show the real pace and real date, not the requested fiction.

### 1.10 Input contract (D10)

Required inputs with NULL or implausible values → the function returns
**zero rows** (empty result), never garbage and never an exception:

| Input | Validity bounds |
|---|---|
| `p_weight_kg` | 30–300 |
| `p_height_cm` | 120–230 |
| `p_age` | 18–100 |
| `p_sex` | non-NULL (any value; non-'male' → female constant) |

- Dart callers: empty result → existing save-error snackbar (§4.4), prior
  values kept.
- Cron: the `CROSS JOIN LATERAL` naturally drops users yielding zero rows —
  an invalid profile is skipped, not corrupted.
- Optional inputs (`target_weight_kg`, `remaining_weeks`, `activity_level`,
  `primary_goal`) follow their documented NULL defaults (§1.5, §1.2) and are
  never a reason to return empty.

### 1.11 Client-side input guards — realistic input (D11)

The §1.10 backend bounds are the last line of defense; the field level is
where a user should learn their input is implausible. One new constants
class, `lib/core/nutrition_input_bounds.dart`, mirrors the backend bounds
(header comment cross-references `calculate_nutrition_targets()`; the values
are stable clinical constants, so this limited duplication is accepted —
the backend zero-rows contract remains authoritative if they ever drift).

**Hard guards (blocking, inline field error, l10n'd in both ARBs):**

| Field | Bounds (metric) | US-locale display |
|---|---|---|
| Current weight | 30–300 kg | 66–661 lb |
| Target weight | 30–300 kg | 66–661 lb |
| Height | 120–230 cm | 3 ft 11 in – 7 ft 6 in |
| Age | 18–100 y | same |

- Applied in all three entry surfaces: onboarding profile + target-weight
  steps, `NutritionPlanPage` (settings mode) health-parameter fields, and
  Settings ▸ Health Profile.
- Out-of-bounds value ⇒ inline `TextFormField` error, and the step/save/
  calculate action is blocked until corrected (extends the existing
  `canAdvance` pattern in `onboarding_data.dart` for the onboarding steps).
- Bounds are validated against the metric canonical value after unit
  conversion, so lb / ft-in entry in the US locale is guarded identically.
- Age entered as an integer in onboarding validates 18–100 directly;
  birthdate pickers (Settings) constrain the selectable range to
  `today − 100y … today − 18y` instead.
- Numeric keyboards + digit-only input formatters on all four fields (minor
  hardening, prevents `-`/`e` input entirely).

**Soft guards (non-blocking warning, user may proceed):**

- **Underweight target:** target weight implying BMI < 18.5 for the entered
  height shows an inline warning (the target is medically underweight); the
  computation itself still runs — the BMR floor and crossing rules keep the
  output safe regardless.
- **Contradictory direction:** already specified in §1.6 / D3.

**Already-bounded inputs (no change):** the timeline slider is hard-limited
to 1–12 months in the widget; sex/activity/goal are dropdown/radio picks and
cannot be out of range.

### 1.12 Worked examples (70 kg, 170 cm, 30 y, female, moderate → BMR 1452, TDEE 2250)

| # | Scenario | calorie_goal | protein | effective pace | est. weeks | Notes |
|---|---|---|---|---|---|---|
| 1 | Lose 10 kg, date 26 wks out | 1827 | 120 g | 0.38 | 26 | ref weight 60 kg |
| 2 | Lose 10 kg, date 9 wks out | 1452 | 120 g | 0.73 | ~14 | pace clamped 1.0 → −1100 → **BMR floor**; honest display: ~14 wks, not 9 |
| 3 | **Cron mid-journey:** 5 kg left, 13 wks left | 1827 | 130 g | 0.38 | 13 | **constant pace proven** (ref weight 65→60... ref = min(65, 60) = 60 → 120 g) |
| 4 | **Overdue/regain:** date passed, 2 kg above target | 1700 | 120 g | 0.5 | 4 | weeks pinned at 4 → −550; regain protection |
| 5 | Lose, no target set | 1700 | 140 g | 0.5 | NULL | default pace; ref weight = current 70 kg |
| 6 | Maintain | 2250 | 98 g | 0 | NULL | plain TDEE, 1.4 g/kg |
| 7 | Gain, no target set | 2525 | 126 g | 0.25 | NULL | +275 (20% cap = 450, not hit) |

Row 3 correction detail: smoothed weight 65 kg, target 60 → ref weight =
`LEAST(65, 60)` = 60 → protein 120 g. Pace = 5/13 = 0.38 → −423 → 1827.
Identical calories to row 1: the pace never decayed.

Row 2 honest display: effective pace = (2250 − 1452)/1100 = 0.73 kg/week;
estimated weeks = 10 / 0.73 ≈ 13.8 → the card shows ~14 weeks even though
the user asked for 9. Badge shows "Intense" from effective pace 0.73.

Old behavior for this profile: 1750 / 2250 / 2550 kcal with protein
128–141 g in every case, regardless of target or timeline.

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
  p_remaining_weeks   integer DEFAULT NULL   -- caller-computed, GREATEST(4, …); see §1.3
) RETURNS TABLE (
  bmr numeric, tdee numeric, calorie_goal integer,
  protein_g numeric, carb_g numeric, fat_g numeric,
  effective_pace_kg_week numeric,
  estimated_weeks_to_target numeric
)
LANGUAGE sql IMMUTABLE SECURITY INVOKER;
```

- `IMMUTABLE` + `SECURITY INVOKER`; `GRANT EXECUTE TO authenticated,
  service_role`. Pure arithmetic — no RLS concern. Immutability is why the
  function takes `p_remaining_weeks` rather than reading `current_date`.
- Invalid required inputs → zero rows (§1.10).
- Unknown `p_primary_goal` values (`health`, `performance`, NULL) fall
  through to maintenance, matching current behavior.
- Header comment marks it as the **single source of truth**; the old warning
  about keeping Dart and SQL in sync becomes obsolete.

### 2.1 Weekly cron rewrite

`recalculate_nutrition_plans_from_weight()` (migration `20260703000000`)
drops its inline formula and calls `calculate_nutrition_targets()` via a
`CROSS JOIN LATERAL` — still one set-based statement, no per-user loop.
Candidate selection changes:

- pulls `target_weight_kg` and `target_date` from `user_health_profile`;
- computes `remaining_weeks = GREATEST(4, CEIL((target_date − CURRENT_DATE) / 7.0))`
  (NULL target_date → NULL, triggering default pace);
- computes the **7-day smoothed weight** (§1.8) as `p_weight_kg`;
- derives `p_age` from stored birthdate at execution time (§1.1).

Users whose profile yields zero rows from the function (invalid inputs) are
skipped untouched.

Behavior over the journey (designed, not emergent): constant pace to the
target date, automatic stop at maintenance on crossing, automatic clamped
resumption on regain (§1.6).

---

## 3. Schema

| Change | Detail |
|---|---|
| ADD | `user_health_profile.target_date date NULL` |
| DROP | `user_health_profile.target_time_weeks` (never populated by V0 onboarding; D4) |
| Audit | If age is stored as an integer anywhere in the profile path, migrate to birthdate (§1.1) |

DB is currently local-only (`supabase db push` deferred per project
practice); migrations apply locally via Docker until the push happens.

---

## 4. Call Sites & Wiring

### 4.1 Onboarding (Flutter)

- `NutritionPlanPage._calculateResults()` becomes async: calls
  `supabase.rpc('calculate_nutrition_targets', ...)` instead of local Dart
  math. In onboarding mode it reads from `onboardingProvider`:
  - `primary_goal` via `primaryGoalFromOnboardingSelections(weightGoal,
    muscleGoal)` (already implemented + tested);
  - `p_target_weight_kg` = `obData.targetWeight`;
  - `p_remaining_weeks` = `max(4, (obData.timelineMonths × 4.33).round())`
    (target_date is "today + timeline", so remaining = full timeline here).
- Result card renders effective pace, estimated date, and badge from the
  RPC's `effective_pace_kg_week` / `estimated_weeks_to_target` (§1.9).
- **Contradictory-target inline warning** on the target-weight step (§1.6).
- `onboarding_page.dart _submit()` adds `target_date`
  (`today + timelineMonths`, sent whenever `targetWeight` is provided) to
  the `complete-onboarding` body.
- `supabase/functions/complete-onboarding/index.ts` destructures
  `target_date` and includes it in the `user_health_profile` upsert.
  Structured-logging standard applies to the touched step.

### 4.2 Settings (Flutter)

- `NutritionPlanPage` (settings mode) passes stored
  `healthProfile.targetWeightKg` and remaining weeks computed from stored
  `healthProfile.targetDate` (`GREATEST(4, …)`; NULL date → NULL param).
- Same effective-pace display contract and contradictory-target warning as
  onboarding.
- `HealthProfileNotifier.save()` replaces the synchronous
  `computeNutritionTargets(updated)` call with an awaited RPC call using the
  same inputs; the rest of the save flow (meal-split rescale via `savePlan`)
  is unchanged.

### 4.3 Dart cleanup

- Removed from `nutrition_calculator.dart`: `calculateBMR`, `calculateTDEE`,
  `calculateCalorieGoal`, `getDefaultMacros`. Kept: `getDefaultMealSplits`,
  `calculateMacroGrams` (manual macro-slider UX only).
- Removed from `health_profile_provider.dart`: `computeCalorieGoal`,
  `computeNutritionTargets`, `activityLevelForCalculator` (RPC accepts DB
  codes). Their unit tests are replaced (§6.3).
- `test/features/nutrition_plan/nutrition_plan_simulation_test.dart` (Dart
  simulation harness) is deleted; its matrix moves into pgTAP fixtures.

### 4.4 Error handling

If the RPC fails (offline, server error) **or returns zero rows** (§1.10):
show the page's existing save-error snackbar pattern and keep prior values —
**no silent local fallback**; a visible retry beats a wrong first-time
health number. Standard BEFORE/AFTER/ERROR
`_logger.db('rpc | fn: calculate_nutrition_targets …')` logging per the
project standard.

---

## 5. Migrations (in order)

| # | File | Purpose |
|---|---|---|
| 1 | `YYYYMMDD_health_profile_target_date.sql` | ADD `target_date`, DROP `target_time_weeks` (+ birthdate audit fix if needed) |
| 2 | `YYYYMMDD_add_calculate_nutrition_targets.sql` | Create the function + grants |
| 3 | `YYYYMMDD_recalculate_plans_use_calculator.sql` | Rewrite `recalculate_nutrition_plans_from_weight()`: LATERAL join, smoothed weight, remaining-weeks from `target_date` |

The `complete-onboarding` edge function redeploy must be explicit.

---

## 6. Testing

### 6.1 pgTAP — `supabase/tests/calculate_nutrition_targets_test.sql`

- **Baseline:** male 30 y / 80 kg / 175 cm / active — BMR/TDEE hand-checked.
- **Pace math:** the §1.12 worked-example matrix asserted row by row,
  including the mid-journey constant-pace row and the overdue/regain row.
- **Clamps:** loss pace > 1.0 clamped; gain pace > 0.5 clamped; surplus
  capped at 20% TDEE (high-TDEE profile where the cap binds).
- **BMR floor:** aggressive small-user scenario lands exactly on BMR
  (pure BMR — assert no hidden 1,200 floor, D8).
- **Effective outputs:** `effective_pace_kg_week` and
  `estimated_weeks_to_target` asserted post-clamp (row 2 of §1.12:
  pace 0.73, ~13.8 weeks); NULL estimated weeks for maintenance/no-target.
- **Remaining-weeks semantics:** value 4 (floor) vs large values; NULL →
  default paces.
- **Crossed/contradictory targets:** loss with target ≥ current →
  maintenance; gain with target ≤ current → maintenance.
- **Regain protection:** crossed → maintenance, then weight above target
  with `p_remaining_weeks = 4` → clamped deficit resumes (D9).
- **NULL/invalid handling:** each of target/remaining-weeks NULL → default
  paces; NULL activity → 1.2; `sex='other'` → female constant; unknown goal
  → maintenance; **out-of-bounds weight/height/age → zero rows** (§1.10).
- **Macro guards:** protein ref weight = target for loss; 35% protein cap
  binding case; carbs never negative; grams × kcal re-sum ≈ calorie_goal
  (±10 kcal rounding tolerance).

### 6.2 pgTAP — cron function

Update `recalculate_nutrition_plans_from_weight_test.sql` to the new
formula; add:
- smoothed weight: several logs within 7 days → average used; single old
  log → fallback to latest;
- user whose **smoothed** weight crossed the target → maintenance;
- pace stability: same user simulated at two journey points (delta and
  remaining weeks shrunk proportionally) → same calorie_goal;
- overdue date → 4-week floor behavior;
- invalid-profile user skipped untouched.

### 6.3 Dart

- Keep `primaryGoalFromOnboardingSelections` tests (7 cases, passing).
- Replace deleted pure-function tests with a mocked-RPC test asserting the
  parameter mapping (incl. `timelineMonths → remaining_weeks` conversion and
  `target_date` in the submit body), the zero-row → snackbar path, and the
  effective-pace → badge derivation.
- Widget-level check: contradictory-target inline warning appears for
  loss-with-higher-target and gain-with-lower-target.
- Input-guard widget tests (§1.11): out-of-bounds weight/height/age shows
  the inline error and blocks advance/save; boundary values (30/300 kg,
  120/230 cm, 18/100 y) accepted; US-locale entry validated after lb/ft-in
  conversion; underweight-target (BMI < 18.5) soft warning shown but not
  blocking.

### 6.4 Manual (Docker psql, test users A–D)

Run the function directly with each test user's profile; verify onboarding
end-to-end on device: pick each objective, confirm visibly different
calories/macros on the result card, confirm the card shows effective pace +
estimated date (use an aggressive timeline to see the clamp reflected), and
trigger the contradictory-target warning.

---

## 7. Files Changed

**New:**
- `supabase/migrations/YYYYMMDD_health_profile_target_date.sql`
- `supabase/migrations/YYYYMMDD_add_calculate_nutrition_targets.sql`
- `supabase/migrations/YYYYMMDD_recalculate_plans_use_calculator.sql`
- `supabase/tests/calculate_nutrition_targets_test.sql`
- `lib/core/nutrition_input_bounds.dart` (client mirror of §1.10 bounds)

**Modified:**
- `lib/core/nutrition_calculator.dart` (shrink)
- `lib/providers/health_profile_provider.dart` (RPC-backed save, remove pure fns)
- `lib/features/nutrition_plan/nutrition_plan_page.dart` (async RPC calculate; target/remaining-weeks inputs; effective-pace card + badge; contradictory-target warning; §1.11 field guards)
- `lib/features/auth/onboarding_page.dart` (`target_date` in submit body; inline warning on target step; §1.11 field guards on profile + target steps)
- `lib/features/auth/onboarding_data.dart` (`canAdvance` blocks on out-of-bounds fields)
- `lib/features/settings/health_profile_page.dart` (§1.11 field guards; birthdate picker range)
- `lib/l10n/app_en.arb` + `lib/l10n/app_fr.arb` (guard error/warning strings)
- `supabase/functions/complete-onboarding/index.ts` (persist `target_date`)
- `supabase/tests/recalculate_nutrition_plans_from_weight_test.sql`
- `test/providers/health_profile_provider_test.dart` (replace deleted-fn tests)

**Deleted:**
- `test/features/nutrition_plan/nutrition_plan_simulation_test.dart`
- Column `user_health_profile.target_time_weeks`
