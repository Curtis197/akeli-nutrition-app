-- supabase/tests/calculate_nutrition_targets_test.sql
-- Asserts the single-source-of-truth formula, spec §1 + §6.1:
-- docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md
BEGIN;
SELECT plan(25);

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
