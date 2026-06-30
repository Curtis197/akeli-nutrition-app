-- Search recipes by ingredients RPC
-- Returns recipe_ids sorted by match count (descending) and match percentage (descending)

CREATE OR REPLACE FUNCTION public.get_recipes_by_ingredients(p_ingredient_ids UUID[])
RETURNS TABLE (recipe_id UUID)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    WITH recipe_counts AS (
        SELECT 
            ri.recipe_id, 
            COUNT(ri.ingredient_id) as total_cnt
        FROM public.recipe_ingredient ri
        GROUP BY ri.recipe_id
    ),
    matched_counts AS (
        SELECT 
            ri.recipe_id, 
            COUNT(ri.ingredient_id) as match_cnt
        FROM public.recipe_ingredient ri
        WHERE ri.ingredient_id = ANY(p_ingredient_ids)
        GROUP BY ri.recipe_id
    )
    SELECT 
        mc.recipe_id
    FROM matched_counts mc
    JOIN recipe_counts rc ON mc.recipe_id = rc.recipe_id
    ORDER BY mc.match_cnt DESC, (mc.match_cnt::numeric / rc.total_cnt::numeric) DESC;
$$;
