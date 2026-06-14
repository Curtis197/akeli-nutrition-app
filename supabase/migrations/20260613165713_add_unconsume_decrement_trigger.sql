-- When a meal_consumption row is deleted (user un-consumes a meal), decrement
-- daily_nutrition_log for the meal's scheduled_date using the same macro source
-- logic as the INSERT trigger: plan-computed values when available, recipe_macro
-- fallback for free-form logs.

CREATE OR REPLACE FUNCTION decrement_daily_nutrition_on_unconsume()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
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
  IF OLD.meal_plan_entry_id IS NOT NULL THEN
    SELECT calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed
    INTO v_plan_cals, v_plan_prot, v_plan_carbs, v_plan_fat
    FROM meal_plan_entry
    WHERE id = OLD.meal_plan_entry_id;
  END IF;

  IF v_plan_cals IS NOT NULL THEN
    v_calories  := v_plan_cals  * OLD.consumption_value;
    v_protein_g := v_plan_prot  * OLD.consumption_value;
    v_carbs_g   := v_plan_carbs * OLD.consumption_value;
    v_fat_g     := v_plan_fat   * OLD.consumption_value;
  ELSE
    SELECT
      COALESCE(rm.calories,  0) * OLD.servings * OLD.consumption_value,
      COALESCE(rm.protein_g, 0) * OLD.servings * OLD.consumption_value,
      COALESCE(rm.carbs_g,   0) * OLD.servings * OLD.consumption_value,
      COALESCE(rm.fat_g,     0) * OLD.servings * OLD.consumption_value,
      COALESCE(rm.fiber_g,   0) * OLD.servings * OLD.consumption_value
    INTO v_calories, v_protein_g, v_carbs_g, v_fat_g, v_fiber_g
    FROM recipe_macro rm
    WHERE rm.recipe_id = OLD.recipe_id;
  END IF;

  UPDATE daily_nutrition_log SET
    calories    = GREATEST(0, calories    - v_calories),
    protein_g   = GREATEST(0, protein_g   - v_protein_g),
    carbs_g     = GREATEST(0, carbs_g     - v_carbs_g),
    fat_g       = GREATEST(0, fat_g       - v_fat_g),
    fiber_g     = GREATEST(0, fiber_g     - v_fiber_g),
    meals_count = GREATEST(0, meals_count - OLD.consumption_value),
    updated_at  = now()
  WHERE user_id = OLD.user_id
    AND log_date = OLD.scheduled_date;

  RETURN OLD;
END;
$$;

CREATE TRIGGER trg_decrement_daily_nutrition_on_unconsume
AFTER DELETE ON meal_consumption
FOR EACH ROW
EXECUTE FUNCTION decrement_daily_nutrition_on_unconsume();
