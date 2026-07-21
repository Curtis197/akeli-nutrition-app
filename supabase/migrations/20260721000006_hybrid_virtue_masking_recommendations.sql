-- Migration: Hybrid Selective Virtue Masking in recommend_recipes RPC
-- File: supabase/migrations/20260721000006_hybrid_virtue_masking_recommendations.sql

CREATE OR REPLACE FUNCTION recommend_recipes(
    p_user_id UUID,
    p_limit INT DEFAULT 10,
    p_mode TEXT DEFAULT 'nutrition',
    p_beauty_type TEXT DEFAULT NULL,
    p_beauty_sub_type TEXT DEFAULT NULL,
    p_frequency TEXT DEFAULT NULL
)
RETURNS TABLE (
    recipe_id UUID,
    title TEXT,
    description TEXT,
    mode TEXT,
    beauty_type TEXT,
    beauty_sub_type TEXT,
    frequency TEXT,
    similarity DOUBLE PRECISION
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_user_vector vector(50);
BEGIN
    -- 1. Fetch user vector from user_vector table
    SELECT vector INTO v_user_vector
    FROM user_vector
    WHERE user_id = p_user_id;

    IF v_user_vector IS NULL THEN
        RETURN;
    END IF;

    -- 2. Return matching recipes sorted by Cosine Distance (<=>)
    RETURN QUERY
    SELECT 
        r.id AS recipe_id,
        r.title::TEXT,
        r.description::TEXT,
        COALESCE(r.mode, 'nutrition')::TEXT AS mode,
        r.beauty_type::TEXT,
        r.beauty_sub_type::TEXT,
        r.frequency::TEXT,
        (1.0 - (rv.vector <=> v_user_vector))::DOUBLE PRECISION AS similarity
    FROM recipe r
    JOIN recipe_vector rv ON r.id = rv.recipe_id
    WHERE r.is_published = TRUE
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND (p_beauty_type IS NULL OR r.beauty_type = p_beauty_type OR r.beauty_type = 'both')
      AND (p_beauty_sub_type IS NULL OR r.beauty_sub_type = p_beauty_sub_type)
      AND (p_frequency IS NULL OR r.frequency = p_frequency)
    ORDER BY rv.vector <=> v_user_vector ASC
    LIMIT p_limit;
END;
$$;
