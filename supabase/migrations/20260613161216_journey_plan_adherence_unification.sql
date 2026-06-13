-- Migration: journey_plan_adherence_unification
-- Unifies all Journey tab metrics onto meal-plan adherence.
-- Before: summary/streak used daily_nutrition_log (calorie logging).
-- After:  summary/streak use meal_plan_entry.is_consumed (plan tracking).
-- Goal hit rates (calorie/macro %) remain in the `goals` section unchanged.

CREATE OR REPLACE FUNCTION get_journey_stats(
  p_year  INT,
  p_month INT
) RETURNS JSON
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_user_id      UUID    := auth.uid();
  v_start_date   DATE;
  v_today        DATE    := CURRENT_DATE;
  v_month_start  DATE    := make_date(p_year, p_month, 1);
  v_month_end    DATE    := (v_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  -- Summary
  v_total_days         INT;
  v_total_planned_days INT := 0;
  v_days_logged        INT := 0;   -- days where consumed >= 1 meal
  v_meals_consumed     INT := 0;
  v_consistency_pct    INT := 0;

  -- Nutrition targets (for goal hit rates only)
  v_calorie_goal  NUMERIC;
  v_protein_goal  NUMERIC;
  v_carb_goal     NUMERIC;
  v_fat_goal      NUMERIC;
  v_days_with_log INT := 0;

  -- Goal hit rates
  v_calorie_hit_pct INT := 0;
  v_protein_hit_pct INT := 0;
  v_carbs_hit_pct   INT := 0;
  v_fat_hit_pct     INT := 0;

  -- Streak
  v_current_streak  INT := 0;
  v_best_streak     INT := 0;

  -- Weight
  v_weight_start   NUMERIC;
  v_weight_current NUMERIC;
  v_weight_target  NUMERIC;

  -- Calendar
  v_calendar JSON;
BEGIN
  -- ── 1. Start date ─────────────────────────────────────────────────────────
  SELECT created_at::DATE INTO v_start_date
  FROM user_profile WHERE id = v_user_id;
  IF v_start_date IS NULL THEN v_start_date := v_today; END IF;

  -- ── 2. Summary (plan-adherence based) ─────────────────────────────────────
  v_total_days := GREATEST(1, v_today - v_start_date + 1);

  -- Days that had at least one planned meal
  SELECT COUNT(DISTINCT mpe.scheduled_date)
  INTO v_total_planned_days
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = v_user_id
    AND mpe.scheduled_date BETWEEN v_start_date AND v_today;

  -- Days where at least one planned meal was consumed
  SELECT COUNT(DISTINCT mpe.scheduled_date)
  INTO v_days_logged
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = v_user_id
    AND mpe.is_consumed = TRUE
    AND mpe.scheduled_date BETWEEN v_start_date AND v_today;

  -- Total consumed meals
  SELECT COUNT(*)
  INTO v_meals_consumed
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = v_user_id
    AND mpe.is_consumed = TRUE;

  -- Consistency = adherence rate among planned days (not all days since joining)
  IF v_total_planned_days > 0 THEN
    v_consistency_pct := ROUND(v_days_logged::NUMERIC / v_total_planned_days * 100);
  END IF;

  -- ── 3. Active nutrition targets ───────────────────────────────────────────
  SELECT calorie_goal, protein_goal_g, carb_goal_g, fat_goal_g
  INTO v_calorie_goal, v_protein_goal, v_carb_goal, v_fat_goal
  FROM nutrition_plan
  WHERE user_id = v_user_id AND is_active = TRUE
  ORDER BY created_at DESC
  LIMIT 1;

  -- ── 4. Goal hit rates (calorie/macro, from daily_nutrition_log) ───────────
  SELECT COUNT(*) INTO v_days_with_log
  FROM daily_nutrition_log
  WHERE user_id = v_user_id
    AND log_date BETWEEN v_start_date AND v_today
    AND calories > 0;

  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND v_days_with_log > 0 THEN
    SELECT
      ROUND(100.0 * SUM(CASE WHEN ABS(calories - v_calorie_goal) / v_calorie_goal <= 0.10 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_protein_goal > 0 AND ABS(protein_g - v_protein_goal) / v_protein_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_carb_goal > 0 AND ABS(carbs_g - v_carb_goal) / v_carb_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_fat_goal > 0 AND ABS(fat_g - v_fat_goal) / v_fat_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*))
    INTO v_calorie_hit_pct, v_protein_hit_pct, v_carbs_hit_pct, v_fat_hit_pct
    FROM daily_nutrition_log
    WHERE user_id = v_user_id
      AND log_date BETWEEN v_start_date AND v_today
      AND calories > 0;
  END IF;

  -- ── 5. Streak (plan-adherence: full completion per day) ───────────────────
  -- A day is a "hit" when: planned > 0 AND consumed == planned.
  -- Days with no plan count as not-hit and break the streak.
  WITH plan_by_day AS (
    SELECT
      mpe.scheduled_date                                           AS d,
      COUNT(*)::INT                                                AS planned,
      SUM(CASE WHEN mpe.is_consumed THEN 1 ELSE 0 END)::INT       AS consumed
    FROM meal_plan_entry mpe
    JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mp.user_id = v_user_id
    GROUP BY mpe.scheduled_date
  ),
  all_days AS (
    SELECT generate_series(v_start_date, v_today, '1 day')::DATE AS d
  ),
  day_status AS (
    SELECT
      ad.d,
      COALESCE(pbd.planned > 0 AND pbd.consumed = pbd.planned, FALSE) AS is_hit
    FROM all_days ad
    LEFT JOIN plan_by_day pbd ON pbd.d = ad.d
  ),
  grp_assigned AS (
    SELECT d, is_hit,
      d - ROW_NUMBER() OVER (PARTITION BY is_hit ORDER BY d)::INT AS grp
    FROM day_status
  ),
  streak_lengths AS (
    SELECT MIN(d) AS s_start, MAX(d) AS s_end, COUNT(*) AS len
    FROM grp_assigned
    WHERE is_hit
    GROUP BY grp
  )
  SELECT
    COALESCE(MAX(len), 0),
    COALESCE(
      (SELECT len FROM streak_lengths WHERE s_end >= v_today - 1 ORDER BY s_end DESC LIMIT 1),
      0
    )
  INTO v_best_streak, v_current_streak
  FROM streak_lengths;

  -- ── 6. Weight ─────────────────────────────────────────────────────────────
  SELECT starting_weight_kg, target_weight_kg, weight_kg
  INTO v_weight_start, v_weight_target, v_weight_current
  FROM user_health_profile WHERE user_id = v_user_id;

  SELECT weight_kg INTO v_weight_current
  FROM weight_log WHERE user_id = v_user_id ORDER BY logged_at DESC LIMIT 1;

  IF v_weight_start IS NULL THEN v_weight_start := v_weight_current; END IF;

  -- ── 7. Calendar (meal-plan adherence per day) ─────────────────────────────
  SELECT json_agg(
    json_build_object(
      'date',     d.day::TEXT,
      'planned',  COALESCE(mc.planned,  0),
      'consumed', COALESCE(mc.consumed, 0)
    )
    ORDER BY d.day
  ) INTO v_calendar
  FROM generate_series(v_month_start, v_month_end, '1 day'::INTERVAL) AS d(day)
  LEFT JOIN (
    SELECT
      mpe.scheduled_date,
      COUNT(*)                                               AS planned,
      SUM(CASE WHEN mpe.is_consumed THEN 1 ELSE 0 END)::INT AS consumed
    FROM meal_plan_entry mpe
    JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mp.user_id = v_user_id
      AND mpe.scheduled_date BETWEEN v_month_start AND v_month_end
    GROUP BY mpe.scheduled_date
  ) mc ON mc.scheduled_date = d.day::DATE;

  -- ── 8. Return ─────────────────────────────────────────────────────────────
  RETURN json_build_object(
    'summary', json_build_object(
      'total_days',         v_total_days,
      'total_planned_days', v_total_planned_days,
      'days_logged',        v_days_logged,
      'meals_consumed',     v_meals_consumed,
      'consistency_pct',    v_consistency_pct
    ),
    'streak', json_build_object(
      'current', v_current_streak,
      'best',    v_best_streak
    ),
    'goals', json_build_object(
      'weight_start_kg',   v_weight_start,
      'weight_current_kg', v_weight_current,
      'weight_target_kg',  v_weight_target,
      'calorie_hit_pct',   v_calorie_hit_pct,
      'protein_hit_pct',   v_protein_hit_pct,
      'carbs_hit_pct',     v_carbs_hit_pct,
      'fat_hit_pct',       v_fat_hit_pct
    ),
    'calendar', COALESCE(v_calendar, '[]'::JSON)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_journey_stats(INT, INT) TO authenticated;
