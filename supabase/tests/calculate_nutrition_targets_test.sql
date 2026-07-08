-- supabase/tests/calculate_nutrition_targets_test.sql
-- Asserts the single-source-of-truth formula, spec §1 + §6.1:
-- docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md
BEGIN;
SELECT plan(28);

-- ── Baseline BMR/TDEE (profile M, maintenance) ─────────────────────────────
SELECT results_eq(
  $$SELECT bmr, tdee, calorie_goal FROM calculate_nutrition_targets(64, 180, 30, 'male', 'sedentary', 'maintenance')$$,
  $$VALUES (1620::numeric, 1944::numeric, 1944)$$,
  'M maintenance: BMR 1620, TDEE 1944, goal = TDEE');

-- Macros now driven by p_muscle_goal, independent of calorie direction
-- (spec addendum 2026-07-08). NULL muscle_goal -> safe default tier:
-- protein 1.6 g/kg, fat 25% kcal, carbs remainder.
SELECT results_eq(
  $$SELECT protein_g, fat_g, carb_g FROM calculate_nutrition_targets(64, 180, 30, 'male', 'sedentary', 'maintenance')$$,
  $$VALUES (102.4::numeric, 54.0::numeric, 262.1::numeric)$$,
  'M maintenance macros, no muscle_goal: 102.4 P / 54.0 F / 262.1 C (default tier)');

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
-- ref weight, default (no muscle_goal) tier 1.6 g/kg: 60*1.6 = 96.0
SELECT results_eq(
  $$SELECT calorie_goal, protein_g, effective_pace_kg_week, estimated_weeks_to_target
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 60, 26)$$,
  $$VALUES (1827, 96.0::numeric, 0.38::numeric, 26.0::numeric)$$,
  'F loss 10kg/26wk, no muscle_goal: 1827 kcal, P96 (default tier), pace .38, est 26wk');

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

-- Row 5: loss, no target -> default 0.5 kg/wk; protein vs current 70 kg,
-- default (no muscle_goal) tier 1.6 g/kg: 70*1.6 = 112.0
SELECT results_eq(
  $$SELECT calorie_goal, protein_g, estimated_weeks_to_target
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss')$$,
  $$VALUES (1700, 112.0::numeric, NULL::numeric)$$,
  'F loss no target, no muscle_goal: 1700 kcal, P112 (default tier), est NULL');

-- Row 7: gain, no target -> default 0.25 kg/wk; default tier 70*1.6=112.0
SELECT results_eq(
  $$SELECT calorie_goal, protein_g FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'muscle_gain')$$,
  $$VALUES (2525, 112.0::numeric)$$, 'F gain no target, no muscle_goal: 2525 kcal, P112 (default tier)');

-- ── muscle_goal independently drives protein g/kg + fat % (2026-07-08) ─────
-- Recomposition: weight_loss calorie direction (unchanged, 1827) but
-- muscle_gain-tier macros (2.2 g/kg vs 60kg ref, 20% fat) — this combo was
-- impossible to express before muscle_goal decoupling.
SELECT results_eq(
  $$SELECT calorie_goal, protein_g, fat_g
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 60, 26, 'gain')$$,
  $$VALUES (1827, 132.0::numeric, 40.6::numeric)$$,
  'Recomposition (loss calories + gain macros): 1827 kcal, P132, F40.6');
-- Same calorie direction, muscle_goal=loss tier (1.2 g/kg, 30% fat) instead.
SELECT results_eq(
  $$SELECT calorie_goal, protein_g, fat_g
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 60, 26, 'loss')$$,
  $$VALUES (1827, 72.0::numeric, 60.9::numeric)$$,
  'weight_loss + muscle_goal=loss: 1827 kcal, P72, F60.9');
-- Explicit muscle_goal='maintenance' must equal the NULL default exactly.
SELECT results_eq(
  $$SELECT protein_g, fat_g, carb_g
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 60, 26, 'maintenance')$$,
  $$SELECT protein_g, fat_g, carb_g
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'weight_loss', 60, 26)$$,
  'muscle_goal=maintenance produces the same macros as omitting muscle_goal');

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
-- Regression: cal_c's integer ROUND() vs unrounded tdee_c can leave eff_c a
-- tiny nonzero residue instead of an exact zero; estimated_weeks_to_target
-- must still come back NULL via the pace_c = 0 guard, not a bogus huge value.
SELECT results_eq(
  $$SELECT calorie_goal, estimated_weeks_to_target
    FROM calculate_nutrition_targets(70, 170, 30, 'female', 'moderate', 'muscle_gain', 65, 26)$$,
  $$VALUES (2250, NULL::numeric)$$, 'gain with target below current -> maintenance, NULL ETA not a rounding-residue bug');

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
