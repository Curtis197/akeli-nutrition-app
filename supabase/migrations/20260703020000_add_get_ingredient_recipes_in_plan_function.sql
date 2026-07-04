-- Reconstructs "which recipes in this meal plan use this ingredient" on
-- demand for the shopping list item detail sheet. shopping_list_item does
-- not retain per-recipe origin (discarded by generate_shopping_list's
-- GROUP BY), so this is computed live from the two ways a recipe can be
-- part of a plan: a meal plan entry's component, or a batch-cooked session.
CREATE OR REPLACE FUNCTION get_ingredient_recipes_in_plan(
  p_meal_plan_id uuid,
  p_ingredient_id uuid
)
RETURNS TABLE (
  recipe_id uuid,
  title text,
  cover_image_url text,
  prep_time_min int,
  cook_time_min int
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  WITH plan_recipes AS (
    SELECT mpec.recipe_id FROM meal_plan_entry_component mpec
      JOIN meal_plan_entry mpe ON mpe.id = mpec.meal_plan_entry_id
    WHERE mpe.meal_plan_id = p_meal_plan_id AND mpec.recipe_id IS NOT NULL
    UNION
    SELECT recipe_id FROM cooking_session
    WHERE meal_plan_id = p_meal_plan_id AND recipe_id IS NOT NULL
  )
  SELECT DISTINCT r.id, r.title, r.cover_image_url, r.prep_time_min, r.cook_time_min
  FROM recipe r
  JOIN recipe_ingredient ri ON ri.recipe_id = r.id
  WHERE r.id IN (SELECT recipe_id FROM plan_recipes)
    AND ri.ingredient_id = p_ingredient_id;
$$;
