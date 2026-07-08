-- Migration: calculate_nutrition_targets_muscle_goal_macros
--
-- Decouples macro composition from calorie direction. Previously protein
-- g/kg and fat % were both derived from goal_c (the collapsed weight_goal/
-- muscle_goal priority result also used for calorie direction), so a
-- recomposition selection (weightGoal=loss + muscleGoal=gain) got weight-
-- loss macros with no reflection of the muscle objective at all, and fat
-- was pinned at a flat 25% for every goal with no differentiation.
--
-- New model: p_primary_goal keeps driving calorie_goal exactly as before
-- (unchanged — weight direction). New p_muscle_goal independently drives
-- protein g/kg and fat %:
--   gain                  -> 2.2 g/kg protein, 20% fat
--   loss                  -> 1.2 g/kg protein, 30% fat
--   maintenance/NULL/other -> 1.6 g/kg protein, 25% fat (safe default,
--   consistent with how unrecognized p_primary_goal/p_activity_level
--   values fall back to a conservative default elsewhere in this function)
-- The weight-loss protein reference-weight rule (dose against
-- LEAST(current, target) to avoid inflated targets for heavier users)
-- stays tied to goal_c = 'weight_loss', independent of muscle_goal.
-- 35% protein cap unchanged; max fat 30% + max protein cap 35% still
-- leaves >=35% for carbs, so carbs can never go negative.
--
-- Adding a parameter changes the argument-type signature, so this is a
-- DROP + CREATE rather than a plain CREATE OR REPLACE (which would leave
-- the old 8-arg overload behind instead of replacing it).

DROP FUNCTION IF EXISTS public.calculate_nutrition_targets(
  numeric, numeric, integer, text, text, text, numeric, integer
);

CREATE FUNCTION public.calculate_nutrition_targets(
  p_weight_kg         numeric,
  p_height_cm         numeric,
  p_age               integer,
  p_sex               text,
  p_activity_level    text,
  p_primary_goal      text,
  p_target_weight_kg  numeric DEFAULT NULL,
  p_remaining_weeks   integer DEFAULT NULL,
  p_muscle_goal       text DEFAULT NULL
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
  -- Protein g/kg + fat % driven by p_muscle_goal, independent of goal_c
  -- (calorie direction). Reference weight for the g/kg dose still follows
  -- weight direction: dose against LEAST(current, target) only when
  -- goal_c = 'weight_loss' (standard practice — avoids inflated protein
  -- targets for heavier users cutting toward a lower goal weight).
  SELECT *,
         LEAST(
           (CASE WHEN goal_c = 'weight_loss'
                 THEN LEAST(p_weight_kg, COALESCE(p_target_weight_kg, p_weight_kg))
                 ELSE p_weight_kg
            END)
           * (CASE p_muscle_goal
                WHEN 'gain' THEN 2.2
                WHEN 'loss' THEN 1.2
                ELSE 1.6
              END),
           0.35 * cal_c / 4.0
         ) AS protein_c,
         (CASE p_muscle_goal
            WHEN 'gain' THEN 0.20
            WHEN 'loss' THEN 0.30
            ELSE 0.25
          END) * cal_c / 9.0 AS fat_c
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
    WHEN goal_c = 'maintenance' OR p_target_weight_kg IS NULL OR pace_c = 0 OR eff_c <= 0 THEN NULL
    ELSE ROUND(ABS(delta_c) / eff_c, 1)
  END
FROM with_macros
$$;

GRANT EXECUTE ON FUNCTION public.calculate_nutrition_targets(
  numeric, numeric, integer, text, text, text, numeric, integer, text
) TO authenticated, service_role;
