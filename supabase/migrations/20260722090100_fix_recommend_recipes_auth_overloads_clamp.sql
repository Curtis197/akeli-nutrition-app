-- Migration: Restore missing auth.uid() check in recommend_recipes, drop the 2
-- stale overloads left behind by prior CREATE OR REPLACE drift, and clamp the
-- fan-mode similarity boost to <= 1.0.
-- File: supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Findings #2 (Critical),
-- #3 (High), #8 (Medium).
--
-- 20260721000006_hybrid_virtue_masking_recommendations.sql and
-- 20260721000021_recommend_recipes_fan_mode.sql both declare the identical
-- argument type list recommend_recipes(uuid, int, text, text, text, text), so
-- 20260721000021's CREATE OR REPLACE replaced 20260721000006's function in
-- place rather than creating a 4th distinct overload. There are therefore only
-- 3 distinct overloads live today: the 7-arg int/text mix from 20260720000002,
-- the 9-arg version from 20260720000008, and the 6-arg uuid/int/text version
-- whose current body comes from 20260721000021. This migration drops the first
-- two stale overloads and patches the third in place.

DROP FUNCTION IF EXISTS recommend_recipes(uuid, int, int, text, text, int, text);
DROP FUNCTION IF EXISTS recommend_recipes(uuid, int, int, text, text, int, text, text, text);

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
    IF auth.uid() IS DISTINCT FROM p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

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
            LEAST(
              (CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1.5 ELSE 1.0 END)::DOUBLE PRECISION,
              1.0::DOUBLE PRECISION
            ) AS similarity
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
        LEAST(
          ((1.0 - (rv.vector <=> v_user_vector)) *
           (CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1.5 ELSE 1.0 END)
          )::DOUBLE PRECISION,
          1.0::DOUBLE PRECISION
        ) AS similarity
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
