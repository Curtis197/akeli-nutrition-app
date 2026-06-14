-- Prepend custom_calories/protein_g/carbs_g/fat_g to the COALESCE chain so that
-- personal meal swaps (is_custom_meal=true) are counted with the user-entered
-- macros rather than the old recipe-derived calories_computed values.

CREATE OR REPLACE FUNCTION sync_daily_nutrition_for_date()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_date   date;
  v_user   uuid;
BEGIN
  v_date := CASE WHEN TG_OP = 'DELETE' THEN OLD.scheduled_date ELSE NEW.scheduled_date END;
  v_user := CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id        ELSE NEW.user_id        END;

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
  LEFT JOIN recipe_macro rm ON rm.recipe_id = mc.recipe_id
  WHERE mc.user_id = v_user
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

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;
