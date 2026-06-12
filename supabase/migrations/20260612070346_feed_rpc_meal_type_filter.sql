-- =============================================================================
-- AKELI — Feed RPC: add p_meal_type filter
-- Migration: 20260612070346_feed_rpc_meal_type_filter.sql
--
-- Adds an optional p_meal_type text param that filters results to recipes
-- where the given meal type is in the recipe.meal_types array.
-- NULL (default) = no filter, preserving all existing callers.
-- =============================================================================

DROP FUNCTION IF EXISTS generate_feed_personalized(uuid, int, uuid[], text, text, int, numeric, numeric, text);

CREATE OR REPLACE FUNCTION generate_feed_personalized(
  p_user_id      uuid,
  p_limit        int     DEFAULT 140,
  p_exclude      uuid[]  DEFAULT '{}',
  p_region_id    text    DEFAULT NULL,
  p_difficulty   text    DEFAULT NULL,
  p_max_time_min int     DEFAULT NULL,
  p_min_cal      numeric DEFAULT NULL,
  p_max_cal      numeric DEFAULT NULL,
  p_order_by     text    DEFAULT NULL,
  p_meal_type    text    DEFAULT NULL
)
RETURNS TABLE (
  recipe_id uuid,
  score     numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  -- Auth guard
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_order_by IS NOT NULL AND p_order_by NOT IN ('rating', 'likes', 'created_at') THEN
    RAISE EXCEPTION 'Invalid p_order_by value: %. Valid values: rating, likes, created_at', p_order_by;
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Cold start: no user vector -> rank by like_count DESC
  IF v_user_vector IS NULL THEN
    RETURN QUERY
    WITH user_allergens AS (
      SELECT COALESCE(array_agg(a.slug), '{}') AS tags
      FROM user_allergy ua
      JOIN allergen a ON a.id = ua.allergen_id
      WHERE ua.user_id = p_user_id
    )
    SELECT
      r.id AS recipe_id,
      CASE p_order_by
        WHEN 'rating'     THEN COALESCE(r.average_rating, 0)::numeric
        WHEN 'likes'      THEN COALESCE(r.like_count, 0)::numeric
        WHEN 'created_at' THEN (EXTRACT(EPOCH FROM r.created_at) / 1e9)::numeric
        ELSE              COALESCE(r.like_count, 0)::numeric
      END AS score
    FROM recipe r
    LEFT JOIN recipe_macro rm ON rm.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
      AND (p_region_id    IS NULL OR r.region         = p_region_id)
      AND (p_difficulty   IS NULL OR r.difficulty     = p_difficulty)
      AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
      AND (p_min_cal IS NULL OR rm.calories IS NULL OR rm.calories >= p_min_cal)
      AND (p_max_cal IS NULL OR rm.calories IS NULL OR rm.calories <= p_max_cal)
      AND (p_meal_type IS NULL OR p_meal_type = ANY(r.meal_types))
      AND NOT EXISTS (
        SELECT 1 FROM recipe_performance_metrics rpm
        WHERE rpm.recipe_id = r.id
          AND rpm.drop_off_rate > 0.20
      )
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
    ORDER BY score DESC
    LIMIT LEAST(p_limit, 200);
    RETURN;
  END IF;

  -- Vectorized path: cosine similarity unless p_order_by overrides
  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  )
  SELECT
    r.id AS recipe_id,
    CASE p_order_by
      WHEN 'rating'     THEN COALESCE(r.average_rating, 0)::numeric
      WHEN 'likes'      THEN COALESCE(r.like_count, 0)::numeric
      WHEN 'created_at' THEN (EXTRACT(EPOCH FROM r.created_at) / 1e9)::numeric
      ELSE              (1 - (rv.vector <=> v_user_vector))::numeric
    END AS score
  FROM recipe r
  JOIN  recipe_vector rv ON rv.recipe_id = r.id
  LEFT JOIN recipe_macro rm ON rm.recipe_id = r.id
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND (p_region_id    IS NULL OR r.region         = p_region_id)
    AND (p_difficulty   IS NULL OR r.difficulty     = p_difficulty)
    AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
    AND (p_min_cal IS NULL OR rm.calories IS NULL OR rm.calories >= p_min_cal)
    AND (p_max_cal IS NULL OR rm.calories IS NULL OR rm.calories <= p_max_cal)
    AND (p_meal_type IS NULL OR p_meal_type = ANY(r.meal_types))
    AND NOT EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
        AND rpm.drop_off_rate > 0.20
    )
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  ORDER BY score DESC
  LIMIT LEAST(p_limit, 200);
END;
$$;
