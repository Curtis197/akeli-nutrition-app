-- When the last meal_consumption row for a user+date is deleted,
-- the full-recompute SELECT returns zero rows so the ON CONFLICT never fires
-- and stale calories remain in daily_nutrition_log forever.
-- Fix: after the recompute upsert, explicitly zero out the row when no
-- meal_consumption rows remain for that user+date.

CREATE OR REPLACE FUNCTION sync_daily_nutrition_for_date()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_date   date;
  v_user   uuid;
BEGIN
  v_date := CASE WHEN TG_OP = 'DELETE' THEN OLD.scheduled_date ELSE NEW.scheduled_date END;
  v_user := CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id        ELSE NEW.user_id        END;

  -- Full recompute from all remaining meal_consumption rows for this user+date.
  INSERT INTO daily_nutrition_log (user_id, log_date, calories, protein_g, carbs_g, fat_g, fiber_g, meals_count)
  SELECT
    mc.user_id,
    v_date,
    SUM(COALESCE(mpe.custom_calories,  mpe.calories_computed,  COALESCE(rm.calories,  0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.custom_protein_g, mpe.protein_g_computed, COALESCE(rm.protein_g, 0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.custom_carbs_g,   mpe.carbs_g_computed,   COALESCE(rm.carbs_g,   0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.custom_fat_g,     mpe.fat_g_computed,     COALESCE(rm.fat_g,     0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(rm.fiber_g, 0) * mc.servings * mc.consumption_value),
    SUM(mc.consumption_value)
  FROM meal_consumption mc
  LEFT JOIN meal_plan_entry mpe ON mpe.id = mc.meal_plan_entry_id
  LEFT JOIN recipe_macro    rm  ON rm.recipe_id = mc.recipe_id
  WHERE mc.user_id       = v_user
    AND mc.scheduled_date = v_date
  GROUP BY mc.user_id
  ON CONFLICT (user_id, log_date) DO UPDATE SET
    calories    = EXCLUDED.calories,
    protein_g   = EXCLUDED.protein_g,
    carbs_g     = EXCLUDED.carbs_g,
    fat_g       = EXCLUDED.fat_g,
    fiber_g     = EXCLUDED.fiber_g,
    meals_count = EXCLUDED.meals_count,
    updated_at  = now();

  -- If no meal_consumption rows remain for this user+date (e.g. last row was
  -- deleted), the SELECT above returns nothing and the upsert never fires.
  -- Explicitly zero out the log so stale values don't persist.
  INSERT INTO daily_nutrition_log (user_id, log_date, calories, protein_g, carbs_g, fat_g, fiber_g, meals_count)
  SELECT v_user, v_date, 0, 0, 0, 0, 0, 0
  WHERE NOT EXISTS (
    SELECT 1 FROM meal_consumption
    WHERE user_id       = v_user
      AND scheduled_date = v_date
  )
  ON CONFLICT (user_id, log_date) DO UPDATE SET
    calories    = 0,
    protein_g   = 0,
    carbs_g     = 0,
    fat_g       = 0,
    fiber_g     = 0,
    meals_count = 0,
    updated_at  = now();

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;
