-- Migration: 20260722110700_fix_beauty_shopping_list_authorization.sql
-- Finding #10 (Area C, Medium): generate_beauty_shopping_list has no
-- auth.uid() check on p_beauty_plan_id — same IDOR pattern as Finding #1.
-- The check cannot be the literal first statement (there is no p_user_id
-- parameter; ownership must be resolved from the plan row itself first),
-- so it is placed immediately after the existing "plan not found" check
-- and before any DELETE/INSERT side effects — the same placement used by
-- this codebase's own Nutrition-side equivalent,
-- generate_shopping_list_internal (confirmed in
-- supabase/migrations/20260717053537_reconcile_local_with_prod_schema.sql).
CREATE OR REPLACE FUNCTION generate_beauty_shopping_list(p_beauty_plan_id uuid)
RETURNS TABLE (
  shopping_list_id  uuid,
  shopping_item_id  uuid,
  ingredient_id     uuid,
  ingredient_name   text,
  category          text,
  total_quantity    numeric,
  unit              text,
  is_checked        boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_list_id uuid;
BEGIN
  -- Get owner of beauty plan
  SELECT user_id INTO v_user_id
  FROM beauty_plan
  WHERE id = p_beauty_plan_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Beauty plan % not found', p_beauty_plan_id;
  END IF;

  IF v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Delete existing shopping list for this beauty plan
  DELETE FROM shopping_list WHERE beauty_plan_id = p_beauty_plan_id;

  -- Create container row in shopping_list
  INSERT INTO shopping_list (user_id, beauty_plan_id, name)
  VALUES (v_user_id, p_beauty_plan_id, 'Routine Beauté — Liste de Courses')
  RETURNING id INTO v_list_id;

  -- Aggregate ingredients across all slots in the beauty plan
  WITH plan_recipes AS (
    SELECT DISTINCT bps.recipe_id
    FROM beauty_plan_slot bps
    WHERE bps.plan_id = p_beauty_plan_id
      AND bps.recipe_id IS NOT NULL
  ),
  aggregated_ingredients AS (
    SELECT
      ri.ingredient_id,
      COALESCE(ri.unit, '') AS unit,
      SUM(COALESCE(ri.quantity, 1.0)) AS total_quantity
    FROM plan_recipes pr
    JOIN recipe_ingredient ri ON ri.recipe_id = pr.recipe_id
    WHERE ri.ingredient_id IS NOT NULL
    GROUP BY ri.ingredient_id, COALESCE(ri.unit, '')
  )
  INSERT INTO shopping_list_item (shopping_list_id, ingredient_id, quantity, unit, is_checked)
  SELECT
    v_list_id,
    ai.ingredient_id,
    ai.total_quantity,
    ai.unit,
    FALSE
  FROM aggregated_ingredients ai;

  -- Return results with ingredient metadata
  RETURN QUERY
  SELECT
    v_list_id AS shopping_list_id,
    sli.id AS shopping_item_id,
    sli.ingredient_id,
    COALESCE(i.name_fr, i.name, 'Ingrédient Botanique') AS ingredient_name,
    COALESCE(i.category, 'Soins Naturels') AS category,
    sli.quantity AS total_quantity,
    sli.unit,
    sli.is_checked
  FROM shopping_list_item sli
  LEFT JOIN ingredient i ON i.id = sli.ingredient_id
  WHERE sli.shopping_list_id = v_list_id;
END;
$$;
