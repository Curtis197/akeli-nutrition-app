-- Migration: Restore missing auth.uid() authorization check in
-- generate_feed_personalized.
-- File: supabase/migrations/20260722090200_fix_generate_feed_personalized_auth_check.sql
-- Fixes: bug found during Area A verification (not one of the review's 8 listed
-- findings, but the same class of bug as Finding #2). The original definition in
-- 20260720000002_adapt_vector_rpcs_for_beauty_mode.sql:104 had the
-- auth.uid() = p_user_id guard; 20260721000010_unify_feed_personalized_with_mode.sql
-- and 20260721000015_feed_beauty_filters.sql each DROP FUNCTION + CREATE OR REPLACE
-- a new version and neither carries the guard forward.
--
-- Signature is unchanged from 20260721000015, so this is a straight CREATE OR
-- REPLACE with the auth check inserted at the top of the body; every other line
-- of logic is preserved verbatim.

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
    p_mode TEXT DEFAULT NULL::TEXT,
    p_product_type TEXT DEFAULT NULL::TEXT,
    p_routine_category TEXT DEFAULT NULL::TEXT,
    p_beauty_goal TEXT DEFAULT NULL::TEXT
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
    IF auth.uid() IS DISTINCT FROM p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

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
          AND (p_product_type IS NULL OR r.product_type = p_product_type)
          AND (p_routine_category IS NULL OR r.beauty_type = p_routine_category OR r.beauty_sub_type = p_routine_category)
          AND (p_beauty_goal IS NULL OR (r.virtue_weights IS NOT NULL AND (r.virtue_weights->>p_beauty_goal)::numeric > 0))
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
      AND (p_product_type IS NULL OR r.product_type = p_product_type)
      AND (p_routine_category IS NULL OR r.beauty_type = p_routine_category OR r.beauty_sub_type = p_routine_category)
      AND (p_beauty_goal IS NULL OR (r.virtue_weights IS NOT NULL AND (r.virtue_weights->>p_beauty_goal)::numeric > 0))
      AND r.id <> ALL(p_exclude)
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
    ORDER BY score DESC
    LIMIT LEAST(p_limit, 200);
END;
$$;
