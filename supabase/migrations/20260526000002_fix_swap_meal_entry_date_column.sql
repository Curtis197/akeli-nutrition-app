-- =============================================================================
-- Migration: 20260526000002_fix_swap_meal_entry_date_column.sql
-- Description: Fix swap_meal_plan_entry RPC — use scheduled_date column
--              (the previous migration mistakenly referenced 'date')
-- =============================================================================

CREATE OR REPLACE FUNCTION swap_meal_plan_entry(
  p_entry_id uuid,
  p_new_recipe_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_plan_id uuid;
  v_meals_per_day int;
  v_calorie_goal numeric;
  v_target_meal_calories numeric;
  v_recipe_calories numeric;
  v_new_servings numeric(4,1) := 1.0;
  v_entry_date date;
BEGIN
  -- 1. Verify entry exists and get plan details
  SELECT mp.user_id, mp.id, mpe.scheduled_date INTO v_user_id, v_plan_id, v_entry_date
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mpe.id = p_entry_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized or entry not found';
  END IF;

  -- 2. Calculate meals per day for the target date to split calories
  SELECT COUNT(*) INTO v_meals_per_day
  FROM meal_plan_entry
  WHERE meal_plan_id = v_plan_id AND scheduled_date = v_entry_date;

  IF v_meals_per_day = 0 THEN
    v_meals_per_day := 3; -- fallback
  END IF;

  -- 3. Fetch user's calorie goal
  SELECT calorie_goal INTO v_calorie_goal
  FROM user_goal
  WHERE user_id = v_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  -- 4. Get the new recipe's calories
  SELECT calories INTO v_recipe_calories
  FROM recipe_macro
  WHERE recipe_id = p_new_recipe_id;

  -- 5. Calculate new servings
  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND v_recipe_calories IS NOT NULL AND v_recipe_calories > 0 THEN
    v_target_meal_calories := v_calorie_goal / v_meals_per_day;
    v_new_servings := ROUND((v_target_meal_calories / v_recipe_calories)::numeric, 1);

    IF v_new_servings < 0.1 THEN
      v_new_servings := 0.1;
    END IF;
  END IF;

  -- 6. Update the entry's servings
  UPDATE meal_plan_entry
  SET servings = v_new_servings
  WHERE id = p_entry_id;

  -- 7. Delete existing components for this entry
  DELETE FROM meal_plan_entry_component
  WHERE meal_plan_entry_id = p_entry_id;

  -- 8. Insert the new component
  INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
  VALUES (p_entry_id, p_new_recipe_id, 'base', 1.0);

  -- 9. Regenerate the shopping list
  PERFORM generate_shopping_list(v_plan_id);

END;
$$;
