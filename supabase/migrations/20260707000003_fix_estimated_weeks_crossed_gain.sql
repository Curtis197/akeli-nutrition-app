-- Migration: fix_estimated_weeks_crossed_gain
--
-- Bug: for a crossed/contradictory muscle_gain target (e.g. target_weight_kg
-- below current weight), pace_c is correctly set to the exact literal 0,
-- but eff_c is derived from cal_c (already ROUND()'ed to an integer) minus
-- the unrounded tdee_c, so integer rounding leaves a tiny nonzero residue
-- (e.g. +0.00016) instead of an exact zero. That residue can land on either
-- side of zero: for weight_loss-crossed it happened to come out <= 0 (NULL
-- correctly returned), but for muscle_gain-crossed it came out > 0, so the
-- `eff_c <= 0` guard failed to catch it and estimated_weeks_to_target
-- divided by a near-zero pace, producing a nonsensical value in the tens of
-- thousands of weeks instead of NULL.
--
-- Fix: guard on pace_c = 0 as well — pace_c is an exact literal 0 in both
-- the maintenance and crossed/contradictory branches (see with_pace CTE in
-- 20260707000001_add_calculate_nutrition_targets.sql), so it is immune to
-- the rounding residue that eff_c carries.

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
  SELECT *,
         CASE
           WHEN goal_c = 'maintenance' THEN 0
           WHEN goal_c = 'weight_loss' THEN CASE
             WHEN p_target_weight_kg IS NOT NULL AND delta_c >= 0 THEN 0
             WHEN p_target_weight_kg IS NULL OR p_remaining_weeks IS NULL THEN 0.5
             ELSE LEAST(ABS(delta_c) / GREATEST(p_remaining_weeks, 1), 1.0)
           END
           ELSE CASE
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
    -- pace_c = 0 added: it is an exact literal in the maintenance and
    -- crossed/contradictory branches, immune to the rounding residue eff_c
    -- can carry when cal_c's integer ROUND() doesn't land exactly on tdee_c.
    WHEN goal_c = 'maintenance' OR p_target_weight_kg IS NULL OR pace_c = 0 OR eff_c <= 0 THEN NULL
    ELSE ROUND(ABS(delta_c) / eff_c, 1)
  END
FROM with_macros
$$;

GRANT EXECUTE ON FUNCTION public.calculate_nutrition_targets(
  numeric, numeric, integer, text, text, text, numeric, integer
) TO authenticated, service_role;
