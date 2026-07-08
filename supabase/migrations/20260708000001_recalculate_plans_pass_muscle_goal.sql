-- Migration: recalculate_plans_pass_muscle_goal
-- Wires user_health_profile.muscle_goal through to calculate_nutrition_targets()
-- so the weekly cron's macro recomputation reflects the same muscle-goal-driven
-- protein g/kg + fat % as the interactive Flutter calculate flow, instead of
-- silently falling back to the NULL-muscle_goal default tier for everyone.

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
      hp.muscle_goal,
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
      c.goal_type, c.target_weight_kg, c.remaining_weeks, c.muscle_goal
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
