-- Migration: Unify generate_feed_personalized RPC with p_mode filter
-- File: supabase/migrations/20260721000010_unify_feed_personalized_with_mode.sql

-- 1. Drop existing overloaded functions
DROP FUNCTION IF EXISTS public.generate_feed_personalized(uuid, integer, uuid[], text);
DROP FUNCTION IF EXISTS public.generate_feed_personalized(uuid, integer, uuid[], text, text, integer, numeric, numeric, text, text);
DROP FUNCTION IF EXISTS public.generate_feed_personalized(uuid, integer, uuid[], text, text, integer, numeric, numeric, text, text, text);

-- 2. Create single unified generate_feed_personalized function
CREATE OR REPLACE FUNCTION public.generate_feed_personalized(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_exclude UUID[] DEFAULT '{}'::UUID[],
    p_region_id TEXT DEFAULT NULL::TEXT,
    p_difficulty TEXT DEFAULT NULL::TEXT,
    p_max_time_min INTEGER DEFAULT NULL::INTEGER,
    p_min_cal NUMERIC DEFAULT NULL::NUMERIC,
    p_max_cal NUMERIC DEFAULT NULL::NUMERIC,
    p_order_by TEXT DEFAULT NULL::TEXT,
    p_meal_type TEXT DEFAULT NULL::TEXT,
    p_mode TEXT DEFAULT NULL::TEXT
)
RETURNS TABLE (
    recipe_id UUID,
    score NUMERIC
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
AS $$
DECLARE
    v_user_vector vector(50);
BEGIN
    SELECT uv.vector INTO v_user_vector
    FROM user_vector uv WHERE uv.user_id = p_user_id;

    IF v_user_vector IS NULL THEN
        RETURN QUERY
        SELECT r.id AS recipe_id, 0.5::numeric AS score
        FROM recipe r
        WHERE r.is_published = true
          AND r.is_private = false
          AND (p_mode IS NULL OR r.mode = p_mode)
          AND (p_region_id IS NULL OR r.region = p_region_id)
          AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
          AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
          AND r.id <> ALL(p_exclude)
        ORDER BY r.created_at DESC
        LIMIT LEAST(p_limit, 200);
        RETURN;
    END IF;

    RETURN QUERY
    WITH user_allergens AS (
        SELECT COALESCE(array_agg(a.slug), '{}') AS tags
        FROM user_allergy ua
        JOIN allergen a ON a.id = ua.allergen_id
        WHERE ua.user_id = p_user_id
    )
    SELECT
        r.id AS recipe_id,
        (1 - (rv.vector <=> v_user_vector))::numeric AS score
    FROM recipe r
    JOIN recipe_vector rv ON rv.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND (p_region_id IS NULL OR r.region = p_region_id)
      AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
      AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
      AND r.id <> ALL(p_exclude)
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
    ORDER BY score DESC
    LIMIT LEAST(p_limit, 200);
END;
$$;
