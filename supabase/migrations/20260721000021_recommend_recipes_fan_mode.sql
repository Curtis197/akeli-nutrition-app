-- Migration: 20260721000021_recommend_recipes_fan_mode.sql
-- Description: Update recommend_recipes RPC to support Fan Mode (fan_subscription creator 1.5x boost) across Nutrition & Beauty modes

CREATE OR REPLACE FUNCTION recommend_recipes(
    p_user_id          UUID,
    p_limit            INT DEFAULT 10,
    p_mode             TEXT DEFAULT NULL,
    p_beauty_type      TEXT DEFAULT NULL,
    p_beauty_sub_type  TEXT DEFAULT NULL,
    p_frequency        TEXT DEFAULT NULL
)
RETURNS TABLE (
    recipe_id          UUID,
    title              TEXT,
    description        TEXT,
    mode               TEXT,
    beauty_type        TEXT,
    beauty_sub_type    TEXT,
    frequency          TEXT,
    similarity         DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_vector vector(50);
    v_fan_creator_id UUID;
BEGIN
    SELECT vector INTO v_user_vector
    FROM user_vector
    WHERE user_id = p_user_id;

    -- Check active Fan Subscription
    SELECT fs.creator_id INTO v_fan_creator_id
    FROM fan_subscription fs
    WHERE fs.user_id = p_user_id AND fs.status = 'active'
    LIMIT 1;

    IF v_user_vector IS NULL THEN
        RETURN QUERY
        SELECT 
            r.id AS recipe_id,
            r.title::TEXT,
            r.description::TEXT,
            COALESCE(r.mode, 'nutrition')::TEXT AS mode,
            r.beauty_type::TEXT,
            r.beauty_sub_type::TEXT,
            r.frequency::TEXT,
            (CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1.5 ELSE 1.0 END)::DOUBLE PRECISION AS similarity
        FROM recipe r
        WHERE r.is_published = TRUE
          AND (p_mode IS NULL OR r.mode = p_mode)
          AND (p_beauty_type IS NULL OR r.beauty_type = p_beauty_type OR r.beauty_type = 'both')
          AND (p_beauty_sub_type IS NULL OR r.beauty_sub_type = p_beauty_sub_type)
          AND (p_frequency IS NULL OR r.frequency = p_frequency)
        ORDER BY (CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1 ELSE 2 END) ASC, r.created_at DESC
        LIMIT p_limit;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        r.id AS recipe_id,
        r.title::TEXT,
        r.description::TEXT,
        COALESCE(r.mode, 'nutrition')::TEXT AS mode,
        r.beauty_type::TEXT,
        r.beauty_sub_type::TEXT,
        r.frequency::TEXT,
        ((1.0 - (rv.vector <=> v_user_vector)) * 
         (CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1.5 ELSE 1.0 END)
        )::DOUBLE PRECISION AS similarity
    FROM recipe r
    JOIN recipe_vector rv ON r.id = rv.recipe_id
    WHERE r.is_published = TRUE
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND (p_beauty_type IS NULL OR r.beauty_type = p_beauty_type OR r.beauty_type = 'both')
      AND (p_beauty_sub_type IS NULL OR r.beauty_sub_type = p_beauty_sub_type)
      AND (p_frequency IS NULL OR r.frequency = p_frequency)
    ORDER BY similarity DESC
    LIMIT p_limit;
END;
$$;
