-- Fix: non-batch path now reads pre-rounded quantities from meal_ingredient
-- instead of recomputing recipe_ingredient * servings (which was unrounded).
CREATE OR REPLACE FUNCTION generate_shopping_list(p_meal_plan_id uuid)
RETURNS TABLE (
  shopping_list_id  uuid,
  id                uuid,
  ingredient_id     uuid,
  ingredient_name   text,
  total_quantity    numeric,
  unit              text,
  category          text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_list_id uuid;
BEGIN
  SELECT mp.user_id INTO v_user_id
  FROM meal_plan mp WHERE mp.id = p_meal_plan_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM shopping_list WHERE meal_plan_id = p_meal_plan_id;

  INSERT INTO shopping_list (user_id, meal_plan_id)
  VALUES (v_user_id, p_meal_plan_id)
  RETURNING shopping_list.id INTO v_list_id;

  WITH aggregated_ingredients AS (
    -- Non-batch entries: use pre-rounded quantities from meal_ingredient
    SELECT
      mi.ingredient_id,
      COALESCE(SUM(mi.quantity), 0) AS quantity,
      mi.unit
    FROM meal_plan_entry mpe
    JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    JOIN meal_ingredient mi ON mi.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.cooking_session_id IS NULL
    GROUP BY mi.ingredient_id, mi.unit

    UNION ALL

    -- Batch entries: use pre-rounded quantities from cooking_session_ingredient
    SELECT
      csi.ingredient_id,
      COALESCE(SUM(csi.quantity_needed), 0) AS quantity,
      csi.unit
    FROM cooking_session_ingredient csi
    JOIN cooking_session cs ON cs.id = csi.cooking_session_id
    WHERE cs.meal_plan_id = p_meal_plan_id
    GROUP BY csi.ingredient_id, csi.unit
  )
  INSERT INTO shopping_list_item (shopping_list_id, ingredient_id, quantity, unit)
  SELECT
    v_list_id,
    ai.ingredient_id,
    COALESCE(SUM(ai.quantity), 0),
    ai.unit
  FROM aggregated_ingredients ai
  GROUP BY ai.ingredient_id, ai.unit;

  RETURN QUERY
  SELECT
    sli.shopping_list_id,
    sli.id,
    sli.ingredient_id,
    COALESCE(i.name_fr, i.name) AS ingredient_name,
    sli.quantity,
    sli.unit,
    i.category
  FROM shopping_list_item sli
  JOIN ingredient i ON sli.ingredient_id = i.id
  WHERE sli.shopping_list_id = v_list_id
  ORDER BY i.category, i.name;
END;
$$;
