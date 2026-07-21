-- ================================================================
-- AKELI BEAUTY MODE: RECIPE FREQUENCY TAXONOMY & RECOMMENDATION RPC UPDATE
-- ================================================================

-- 1. ADD FREQUENCY COLUMN TO RECIPE TABLE
ALTER TABLE recipe 
ADD COLUMN IF NOT EXISTS frequency VARCHAR(50);

-- 2. POPULATE FREQUENCY VALUES FOR STARTER BEAUTY REMEDIES
UPDATE recipe SET frequency = '1x_week' WHERE id = 'b0000001-0000-0000-0000-000000000001';
UPDATE recipe SET frequency = '2x_month' WHERE id = 'b0000002-0000-0000-0000-000000000004';
UPDATE recipe SET frequency = 'daily' WHERE id = 'b0000003-0000-0000-0000-000000000003';
UPDATE recipe SET frequency = '2x_week' WHERE id = 'b0000004-0000-0000-0000-000000000005';
UPDATE recipe SET frequency = '2x_week' WHERE id = 'b0000005-0000-0000-0000-000000000006';
UPDATE recipe SET frequency = '2x_week' WHERE id = 'b0000006-0000-0000-0000-000000000008';
UPDATE recipe SET frequency = '1x_month' WHERE id = 'b0000007-0000-0000-0000-000000000010';
UPDATE recipe SET frequency = '1x_week' WHERE id = 'b0000008-0000-0000-0000-000000000011';
UPDATE recipe SET frequency = '2x_week' WHERE id = 'b0000009-0000-0000-0000-000000000012';
UPDATE recipe SET frequency = '2x_month' WHERE id = 'b0000010-0000-0000-0000-000000000013';
UPDATE recipe SET frequency = '1x_week' WHERE id = 'b0000011-0000-0000-0000-000000000014';
UPDATE recipe SET frequency = '2x_week' WHERE id = 'b0000012-0000-0000-0000-000000000015';

UPDATE recipe SET frequency = '1x_week' WHERE id = 'b0000002-0000-0000-0000-000000000002';
UPDATE recipe SET frequency = '2x_week' WHERE id = 'b0000007-0000-0000-0000-000000000007';
UPDATE recipe SET frequency = 'daily' WHERE id = 'b0000013-0000-0000-0000-000000000016';
UPDATE recipe SET frequency = 'daily' WHERE id = 'b0000014-0000-0000-0000-000000000017';
UPDATE recipe SET frequency = '1x_week' WHERE id = 'b0000015-0000-0000-0000-000000000018';
UPDATE recipe SET frequency = 'daily' WHERE id = 'b0000016-0000-0000-0000-000000000019';
UPDATE recipe SET frequency = '1x_week' WHERE id = 'b0000017-0000-0000-0000-000000000020';
UPDATE recipe SET frequency = 'daily' WHERE id = 'b0000018-0000-0000-0000-000000000021';
UPDATE recipe SET frequency = '2x_week' WHERE id = 'b0000019-0000-0000-0000-000000000022';
UPDATE recipe SET frequency = 'daily' WHERE id = 'b0000020-0000-0000-0000-000000000023';

-- 3. UPDATE RECOMMEND_RECIPES RPC TO SUPPORT FREQUENCY FILTERING & OUTPUT
CREATE OR REPLACE FUNCTION recommend_recipes(
    p_user_id UUID,
    p_limit INT DEFAULT 10,
    p_mode VARCHAR DEFAULT NULL,
    p_beauty_type VARCHAR DEFAULT NULL,
    p_beauty_sub_type VARCHAR DEFAULT NULL,
    p_frequency VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    recipe_id UUID,
    title VARCHAR,
    description TEXT,
    similarity DOUBLE PRECISION,
    cover_image_url TEXT,
    mode VARCHAR,
    beauty_type VARCHAR,
    beauty_sub_type VARCHAR,
    frequency VARCHAR,
    virtues TEXT[]
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_vector vector(50);
BEGIN
    -- Retrieve user's vector
    SELECT user_vector INTO v_user_vector
    FROM user_health_profile
    WHERE user_id = p_user_id;

    IF v_user_vector IS NULL THEN
        RAISE EXCEPTION 'User profile or vector not found for user_id: %', p_user_id;
    END IF;

    RETURN QUERY
    SELECT 
        r.id AS recipe_id,
        r.title,
        r.description,
        (1 - (rv.embedding <=> v_user_vector))::DOUBLE PRECISION AS similarity,
        r.cover_image_url,
        r.mode,
        r.beauty_type,
        r.beauty_sub_type,
        r.frequency,
        r.virtues
    FROM recipe r
    JOIN recipe_vector rv ON r.id = rv.recipe_id
    WHERE r.is_published = true
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND (p_beauty_type IS NULL OR r.beauty_type = p_beauty_type OR r.beauty_type = 'both')
      AND (p_beauty_sub_type IS NULL OR r.beauty_sub_type = p_beauty_sub_type)
      AND (p_frequency IS NULL OR r.frequency = p_frequency)
    ORDER BY rv.embedding <=> v_user_vector ASC
    LIMIT p_limit;
END;
$$;
