-- =============================================================================
-- Migration: 20260525000006_create_batch_sessions_rpc.sql
-- Description: RPC to automatically create batch cooking sessions for repeated recipes
-- =============================================================================

CREATE OR REPLACE FUNCTION create_batch_sessions(
  p_meal_plan_id uuid,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_recipe RECORD;
  v_recipe_servings numeric;
  v_scale_factor numeric(6,3);
  v_session_id uuid;
BEGIN
  -- 1. Verify ownership
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 2. Delete existing sessions for this plan (cascades to ingredients, sets components to null)
  DELETE FROM cooking_session
  WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;

  -- 3. Find repeated recipes (2+ appearances) and loop through them
  FOR v_recipe IN (
    SELECT mpec.recipe_id,
           COUNT(*) AS appearance_count,
           SUM(mpe.servings) AS total_portions_needed
    FROM meal_plan_entry mpe
    JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2
  ) LOOP
    
    -- 4. Fetch base recipe servings
    SELECT servings INTO v_recipe_servings 
    FROM recipe 
    WHERE id = v_recipe.recipe_id;

    -- Calculate scale factor
    v_scale_factor := ROUND((v_recipe.total_portions_needed / GREATEST(v_recipe_servings, 1))::numeric, 3);

    -- 5. Create cooking session
    INSERT INTO cooking_session (user_id, meal_plan_id, recipe_id, total_portions, scale_factor, planned_date)
    VALUES (
      p_user_id, 
      p_meal_plan_id, 
      v_recipe.recipe_id, 
      CEIL(v_recipe.total_portions_needed), -- Round up portions for visual display
      v_scale_factor, 
      CURRENT_DATE
    )
    RETURNING id INTO v_session_id;

    -- 6. Create scaled ingredient rows
    INSERT INTO cooking_session_ingredient
      (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
    SELECT
      v_session_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      ROUND((ri.quantity * v_scale_factor)::numeric, 3),
      ri.unit
    FROM recipe_ingredient ri
    JOIN ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_recipe.recipe_id
      AND ri.is_optional = false;

    -- 7. Link components back to the new session
    UPDATE meal_plan_entry_component mpec
    SET cooking_session_id = v_session_id
    FROM meal_plan_entry mpe
    WHERE mpec.meal_plan_entry_id = mpe.id
      AND mpe.meal_plan_id = p_meal_plan_id
      AND mpec.recipe_id = v_recipe.recipe_id;

  END LOOP;
END;
$$;
