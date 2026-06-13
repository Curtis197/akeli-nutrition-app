-- Add scheduled_date to meal_consumption so the app can query meals by their
-- planned date rather than consumed_at (tap date). A user who forgets to log a
-- meal and taps it the next day should see it under the original scheduled day.

ALTER TABLE meal_consumption
ADD COLUMN IF NOT EXISTS scheduled_date date;

-- BEFORE INSERT trigger: resolves scheduled_date from the linked plan entry,
-- falls back to DATE(consumed_at) for free-form logs with no plan entry.
CREATE OR REPLACE FUNCTION set_meal_consumption_scheduled_date()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.meal_plan_entry_id IS NOT NULL THEN
    SELECT scheduled_date INTO NEW.scheduled_date
    FROM meal_plan_entry
    WHERE id = NEW.meal_plan_entry_id;
  END IF;

  IF NEW.scheduled_date IS NULL THEN
    NEW.scheduled_date := DATE(NEW.consumed_at);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_set_meal_consumption_scheduled_date
BEFORE INSERT ON meal_consumption
FOR EACH ROW
EXECUTE FUNCTION set_meal_consumption_scheduled_date();

-- Update daily_nutrition_log trigger to use NEW.scheduled_date (already resolved
-- by the BEFORE trigger above) instead of recomputing it.
CREATE OR REPLACE FUNCTION update_daily_nutrition_on_consumption()
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
  IF NEW.meal_plan_entry_id IS NOT NULL THEN
    SELECT calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed
    INTO v_plan_cals, v_plan_prot, v_plan_carbs, v_plan_fat
    FROM meal_plan_entry
    WHERE id = NEW.meal_plan_entry_id;
  END IF;

  IF v_plan_cals IS NOT NULL THEN
    v_calories  := v_plan_cals  * NEW.consumption_value;
    v_protein_g := v_plan_prot  * NEW.consumption_value;
    v_carbs_g   := v_plan_carbs * NEW.consumption_value;
    v_fat_g     := v_plan_fat   * NEW.consumption_value;
  ELSE
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
    NEW.scheduled_date,
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

-- Backfill existing rows
UPDATE meal_consumption mc
SET scheduled_date = COALESCE(mpe.scheduled_date, DATE(mc.consumed_at))
FROM meal_plan_entry mpe
WHERE mc.meal_plan_entry_id = mpe.id
  AND mc.scheduled_date IS NULL;

UPDATE meal_consumption
SET scheduled_date = DATE(consumed_at)
WHERE scheduled_date IS NULL;
