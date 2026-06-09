-- =============================================================================
-- Migration: 20260602000002_fix_swap_batch_session_sync.sql
-- Description: Wire create_batch_sessions into swap_meal_plan_entry so that
--              cooking sessions stay in sync after every recipe swap.
--              Also drops the ambiguous 2-arg create_batch_sessions overload
--              that causes "function is not unique" errors when called without
--              explicit casts (the 3-arg version with DEFAULT 7 supersedes it).
-- =============================================================================

-- Drop the superseded 2-arg overload to eliminate ambiguity
DROP FUNCTION IF EXISTS public.create_batch_sessions(uuid, uuid);

-- Rewrite swap_meal_plan_entry to also regenerate batch sessions (step 10)
CREATE OR REPLACE FUNCTION swap_meal_plan_entry(
  p_entry_id      uuid,
  p_new_recipe_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id              uuid;
  v_plan_id              uuid;
  v_meals_per_day        int;
  v_calorie_goal         numeric;
  v_target_meal_calories numeric;
  v_recipe_calories      numeric;
  v_recipe_protein_g     numeric;
  v_recipe_carbs_g       numeric;
  v_recipe_fat_g         numeric;
  v_new_servings         numeric(4,1) := 1.0;
  v_entry_date           date;
BEGIN
  -- 1. Verify entry exists and belongs to the calling user
  SELECT mp.user_id, mp.id, mpe.scheduled_date
  INTO   v_user_id, v_plan_id, v_entry_date
  FROM   meal_plan_entry mpe
  JOIN   meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE  mpe.id = p_entry_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized or entry not found';
  END IF;

  -- 2. Count meals on the same day to split calorie budget evenly
  SELECT COUNT(*) INTO v_meals_per_day
  FROM   meal_plan_entry
  WHERE  meal_plan_id = v_plan_id AND scheduled_date = v_entry_date;

  IF v_meals_per_day = 0 THEN
    v_meals_per_day := 3;
  END IF;

  -- 3. Fetch user's active calorie goal
  SELECT calorie_goal INTO v_calorie_goal
  FROM   user_goal
  WHERE  user_id = v_user_id AND is_active = true
  ORDER  BY created_at DESC
  LIMIT  1;

  -- 4. Fetch the new recipe's full macro profile (all four values in one query)
  SELECT calories, protein_g, carbs_g, fat_g
  INTO   v_recipe_calories, v_recipe_protein_g, v_recipe_carbs_g, v_recipe_fat_g
  FROM   recipe_macro
  WHERE  recipe_id = p_new_recipe_id;

  -- 5. Calculate serving size to match calorie target
  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0
     AND v_recipe_calories IS NOT NULL AND v_recipe_calories > 0 THEN
    v_target_meal_calories := v_calorie_goal / v_meals_per_day;
    v_new_servings := ROUND((v_target_meal_calories / v_recipe_calories)::numeric, 1);

    IF v_new_servings < 0.1 THEN
      v_new_servings := 0.1;
    END IF;
  END IF;

  -- 6. Update servings AND recompute macro columns for the new recipe + servings
  UPDATE meal_plan_entry
  SET
    servings           = v_new_servings,
    calories_computed  = ROUND((COALESCE(v_recipe_calories,  0) * v_new_servings)::numeric, 1),
    protein_g_computed = ROUND((COALESCE(v_recipe_protein_g, 0) * v_new_servings)::numeric, 1),
    carbs_g_computed   = ROUND((COALESCE(v_recipe_carbs_g,   0) * v_new_servings)::numeric, 1),
    fat_g_computed     = ROUND((COALESCE(v_recipe_fat_g,     0) * v_new_servings)::numeric, 1)
  WHERE id = p_entry_id;

  -- 7. Replace the component binding (old recipe → new recipe)
  DELETE FROM meal_plan_entry_component
  WHERE  meal_plan_entry_id = p_entry_id;

  INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
  VALUES (p_entry_id, p_new_recipe_id, 'base', 1.0);

  -- 8. Sync meal_ingredient rows so the per-entry ingredient list stays current
  DELETE FROM meal_ingredient
  WHERE  meal_plan_entry_id = p_entry_id;

  INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
  SELECT
    p_entry_id,
    ri.ingredient_id,
    COALESCE(i.name_fr, i.name),
    ROUND((ri.quantity * v_new_servings)::numeric, 3),
    ri.unit
  FROM   recipe_ingredient ri
  JOIN   ingredient i ON i.id = ri.ingredient_id
  WHERE  ri.recipe_id = p_new_recipe_id
    AND  ri.is_optional = false
    AND  ri.ingredient_id IS NOT NULL;

  -- 9. Regenerate the shopping list to reflect the new recipe
  PERFORM generate_shopping_list(v_plan_id);

  -- 10. Regenerate batch cooking sessions so portions stay in sync with the swap
  PERFORM create_batch_sessions(v_plan_id, v_user_id, 7);

END;
$$;
