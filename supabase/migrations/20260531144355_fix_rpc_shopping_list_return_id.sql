-- Fix RPC to return the shopping_list_item ID
-- And fix RLS policy for shopping_list_item to allow UPDATE

DROP FUNCTION IF EXISTS generate_shopping_list(uuid);

CREATE OR REPLACE FUNCTION generate_shopping_list(p_meal_plan_id uuid)
RETURNS TABLE (
  shopping_list_id  uuid,
  id                uuid, -- This is the shopping_list_item id
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
    SELECT 
      ri.ingredient_id, 
      SUM(ri.quantity * mpe.servings) AS quantity, 
      ri.unit
    FROM meal_plan_entry mpe
    JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    JOIN recipe_ingredient ri ON ri.recipe_id = mpec.recipe_id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND ri.is_optional = false
      AND mpec.cooking_session_id IS NULL
    GROUP BY ri.ingredient_id, ri.unit

    UNION ALL

    SELECT 
      csi.ingredient_id, 
      SUM(csi.quantity_needed) AS quantity, 
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
    SUM(ai.quantity),
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

-- Fix RLS policy for UPDATE
DROP POLICY IF EXISTS "owner via list shopping_list_item" ON shopping_list_item;

CREATE POLICY "owner via list shopping_list_item" ON shopping_list_item
  FOR ALL
  USING (
    shopping_list_id IN (SELECT id FROM shopping_list WHERE user_id = auth.uid())
  )
  WITH CHECK (
    shopping_list_id IN (SELECT id FROM shopping_list WHERE user_id = auth.uid())
  );
