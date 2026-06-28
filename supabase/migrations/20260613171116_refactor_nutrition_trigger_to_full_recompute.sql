-- Replace increment/decrement triggers with a single recompute-from-source
-- trigger. On every INSERT or DELETE on meal_consumption, the affected day is
-- fully recomputed from the current rows — no running total to drift.
--
-- Macro source priority (same as before):
--   1. meal_plan_entry.{calories,protein_g,carbs_g,fat_g}_computed  (plan-scaled portion)
--   2. recipe_macro × servings  (free-form logs with no plan entry)

DROP TRIGGER IF EXISTS trg_update_daily_nutrition_on_consumption ON meal_consumption;
DROP TRIGGER IF EXISTS trg_decrement_daily_nutrition_on_unconsume ON meal_consumption;
DROP FUNCTION IF EXISTS update_daily_nutrition_on_consumption() CASCADE;
DROP FUNCTION IF EXISTS decrement_daily_nutrition_on_unconsume() CASCADE;

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
    SUM(COALESCE(mpe.calories_computed,  COALESCE(rm.calories,  0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.protein_g_computed, COALESCE(rm.protein_g, 0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.carbs_g_computed,   COALESCE(rm.carbs_g,   0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.fat_g_computed,     COALESCE(rm.fat_g,     0) * mc.servings) * mc.consumption_value),
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

CREATE TRIGGER trg_sync_daily_nutrition
AFTER INSERT OR DELETE ON meal_consumption
FOR EACH ROW
EXECUTE FUNCTION sync_daily_nutrition_for_date();
