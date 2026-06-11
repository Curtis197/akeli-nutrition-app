-- Fix: update_daily_nutrition_on_consumption used a `record` variable for the
-- recipe_macro SELECT. When no macro row exists for a recipe, PostgreSQL leaves
-- the record untyped and any field access (v_macros.calories) throws
-- "record has no field calories", rolling back the meal_consumption INSERT → 500.
-- Fix: use individual numeric variables initialised to 0; a missing macro row
-- simply leaves them at 0 and the trigger continues normally.

CREATE OR REPLACE FUNCTION update_daily_nutrition_on_consumption()
RETURNS TRIGGER AS $$
DECLARE
  v_log_date  date;
  v_calories  numeric := 0;
  v_protein_g numeric := 0;
  v_carbs_g   numeric := 0;
  v_fat_g     numeric := 0;
  v_fiber_g   numeric := 0;
BEGIN
  v_log_date := DATE(NEW.consumed_at);

  SELECT
    COALESCE(rm.calories,  0) * NEW.servings * NEW.consumption_value,
    COALESCE(rm.protein_g, 0) * NEW.servings * NEW.consumption_value,
    COALESCE(rm.carbs_g,   0) * NEW.servings * NEW.consumption_value,
    COALESCE(rm.fat_g,     0) * NEW.servings * NEW.consumption_value,
    COALESCE(rm.fiber_g,   0) * NEW.servings * NEW.consumption_value
  INTO v_calories, v_protein_g, v_carbs_g, v_fat_g, v_fiber_g
  FROM recipe_macro rm
  WHERE rm.recipe_id = NEW.recipe_id;
  -- FOUND = false when no macro row exists → all variables remain 0, no error.

  INSERT INTO daily_nutrition_log (user_id, log_date, calories, protein_g, carbs_g, fat_g, fiber_g, meals_count)
  VALUES (
    NEW.user_id,
    v_log_date,
    v_calories,
    v_protein_g,
    v_carbs_g,
    v_fat_g,
    v_fiber_g,
    NEW.consumption_value
  )
  ON CONFLICT (user_id, log_date) DO UPDATE SET
    calories    = daily_nutrition_log.calories    + EXCLUDED.calories,
    protein_g   = daily_nutrition_log.protein_g   + EXCLUDED.protein_g,
    carbs_g     = daily_nutrition_log.carbs_g     + EXCLUDED.carbs_g,
    fat_g       = daily_nutrition_log.fat_g       + EXCLUDED.fat_g,
    fiber_g     = daily_nutrition_log.fiber_g     + EXCLUDED.fiber_g,
    meals_count = daily_nutrition_log.meals_count + EXCLUDED.meals_count,
    updated_at  = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
