-- Migration: restore the pending-unpublish exclusion filter that
-- generate_feed_personalized lost on 2026-07-20.
--
-- Root cause: 20260716210000_exclude_pending_unpublish.sql added
-- `AND r.unpublish_requested_at IS NULL` to both selection sites of the
-- (then nutrition-only) generate_feed_personalized. Four days later,
-- 20260720000002_adapt_vector_rpcs_for_beauty_mode.sql redefined the same
-- function from an older, pre-07-16 base to add p_mode support, silently
-- dropping the filter. Every later redefinition
-- (20260721000010_unify_feed_personalized_with_mode.sql,
-- 20260721000015_feed_beauty_filters.sql,
-- 20260722090200_fix_generate_feed_personalized_auth_check.sql) built on
-- top of the already-broken version, so the filter never came back.
-- Confirmed via supabase/tests/deferred_unpublish_test.sql (tests 9-10),
-- which failed on both selection-site count and live behavior.
--
-- generate_meal_plan was fixed by the same 20260716210000 migration and
-- still has all 5 of its filters intact, confirming this is isolated to
-- generate_feed_personalized, not a general pattern loss.
CREATE OR REPLACE FUNCTION public.generate_feed_personalized(
  p_user_id uuid,
  p_limit integer DEFAULT 20,
  p_exclude uuid[] DEFAULT '{}'::uuid[],
  p_region_id text DEFAULT NULL::text,
  p_difficulty text DEFAULT NULL::text,
  p_max_time_min integer DEFAULT NULL::integer,
  p_min_cal numeric DEFAULT NULL::numeric,
  p_max_cal numeric DEFAULT NULL::numeric,
  p_order_by text DEFAULT NULL::text,
  p_meal_type text DEFAULT NULL::text,
  p_mode text DEFAULT NULL::text,
  p_product_type text DEFAULT NULL::text,
  p_routine_category text DEFAULT NULL::text,
  p_beauty_goal text DEFAULT NULL::text
)
RETURNS TABLE(recipe_id uuid, score numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
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
          AND r.unpublish_requested_at IS NULL
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
      AND r.unpublish_requested_at IS NULL
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
$function$;
