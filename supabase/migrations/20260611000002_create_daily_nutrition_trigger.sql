-- The trigger function update_daily_nutrition_on_consumption already exists.
-- This migration attaches it to meal_consumption so every INSERT
-- automatically rolls up macros into daily_nutrition_log.
CREATE TRIGGER trg_update_daily_nutrition_on_consumption
AFTER INSERT ON meal_consumption
FOR EACH ROW
EXECUTE FUNCTION update_daily_nutrition_on_consumption();

-- Backfill daily_nutrition_log from all pre-existing meal_consumption rows
-- (records inserted before the trigger was created were never rolled up).
INSERT INTO daily_nutrition_log (user_id, log_date, calories, protein_g, carbs_g, fat_g, fiber_g, meals_count)
SELECT
  mc.user_id,
  DATE(mc.consumed_at)                                                        AS log_date,
  SUM(COALESCE(rm.calories,  0) * mc.servings * mc.consumption_value),
  SUM(COALESCE(rm.protein_g, 0) * mc.servings * mc.consumption_value),
  SUM(COALESCE(rm.carbs_g,   0) * mc.servings * mc.consumption_value),
  SUM(COALESCE(rm.fat_g,     0) * mc.servings * mc.consumption_value),
  SUM(COALESCE(rm.fiber_g,   0) * mc.servings * mc.consumption_value),
  SUM(mc.consumption_value)
FROM meal_consumption mc
LEFT JOIN recipe_macro rm ON rm.recipe_id = mc.recipe_id
GROUP BY mc.user_id, DATE(mc.consumed_at)
ON CONFLICT (user_id, log_date) DO UPDATE SET
  calories    = EXCLUDED.calories,
  protein_g   = EXCLUDED.protein_g,
  carbs_g     = EXCLUDED.carbs_g,
  fat_g       = EXCLUDED.fat_g,
  fiber_g     = EXCLUDED.fiber_g,
  meals_count = EXCLUDED.meals_count,
  updated_at  = now();
