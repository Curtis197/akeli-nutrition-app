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
