-- Fix 1: daily_nutrition_log must roll up to the meal's scheduled_date, not the
-- consumption date. A user who forgets to log a meal and marks it consumed the
-- next day should have it counted on the day it was planned, not the tap date.
--
-- Fix 2: macros must use meal_plan_entry.{calories,protein_g,carbs_g,fat_g}_computed
-- (already scaled to the scheduled serving size) rather than the raw recipe_macro
-- values which represent a full recipe portion. Fall back to recipe_macro × servings
-- only for free-form logs that have no linked plan entry.

CREATE OR REPLACE FUNCTION update_daily_nutrition_on_consumption()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_log_date   date;
  v_calories   numeric := 0;
  v_protein_g  numeric := 0;
  v_carbs_g    numeric := 0;
  v_fat_g      numeric := 0;
  v_fiber_g    numeric := 0;
  v_plan_cals  numeric;
  v_plan_prot  numeric;
  v_plan_carbs numeric;
  v_plan_fat   numeric;
BEGIN
  -- Resolve log date and plan-computed macros from the linked plan entry
  IF NEW.meal_plan_entry_id IS NOT NULL THEN
    SELECT
      scheduled_date,
      calories_computed,
      protein_g_computed,
      carbs_g_computed,
      fat_g_computed
    INTO v_log_date, v_plan_cals, v_plan_prot, v_plan_carbs, v_plan_fat
    FROM meal_plan_entry
    WHERE id = NEW.meal_plan_entry_id;
  END IF;

  IF v_log_date IS NULL THEN
    v_log_date := DATE(NEW.consumed_at);
  END IF;

  IF v_plan_cals IS NOT NULL THEN
    -- Use plan-computed macros (already scaled to scheduled servings)
    -- multiplied by consumption_value for partial consumption
    v_calories  := v_plan_cals  * NEW.consumption_value;
    v_protein_g := v_plan_prot  * NEW.consumption_value;
    v_carbs_g   := v_plan_carbs * NEW.consumption_value;
    v_fat_g     := v_plan_fat   * NEW.consumption_value;
  ELSE
    -- Free-form log: fall back to recipe_macro × servings × consumption_value
    SELECT
      COALESCE(rm.calories,  0) * NEW.servings * NEW.consumption_value,
      COALESCE(rm.protein_g, 0) * NEW.servings * NEW.consumption_value,
      COALESCE(rm.carbs_g,   0) * NEW.servings * NEW.consumption_value,
      COALESCE(rm.fat_g,     0) * NEW.servings * NEW.consumption_value,
      COALESCE(rm.fiber_g,   0) * NEW.servings * NEW.consumption_value
    INTO v_calories, v_protein_g, v_carbs_g, v_fat_g, v_fiber_g
    FROM recipe_macro rm
    WHERE rm.recipe_id = NEW.recipe_id;
  END IF;

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
$$;
