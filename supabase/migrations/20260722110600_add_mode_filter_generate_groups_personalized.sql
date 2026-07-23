-- Migration: 20260722110600_add_mode_filter_generate_groups_personalized.sql
-- Finding #7 (Area C, High): Community "Browse Groups" has no mode filter.
-- Adds p_mode TEXT DEFAULT NULL to generate_groups_personalized, filtering
-- both the cold-start fallback branch and the personalized vector-search
-- branch. Appended as the 4th parameter so existing callers that only
-- pass p_user_id/p_limit/p_exclude are unaffected. SET search_path and
-- STABLE SECURITY DEFINER preserved unchanged from the live version
-- (confirmed via supabase/migrations/20260717053537_reconcile_local_with_prod_schema.sql).
CREATE OR REPLACE FUNCTION generate_groups_personalized(
  p_user_id  uuid,
  p_limit    int     DEFAULT 20,
  p_exclude  uuid[]  DEFAULT '{}',
  p_mode     text    DEFAULT NULL
)
RETURNS TABLE (group_id uuid, score numeric)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Cold start: fallback to profile field matching
  IF v_user_vector IS NULL THEN
    RETURN QUERY
    SELECT cg.id AS group_id, 0::numeric AS score
    FROM community_group cg
    LEFT JOIN user_profile up ON up.id = p_user_id
    WHERE cg.is_public = true
      AND cg.id <> ALL(p_exclude)
      AND (p_mode IS NULL OR cg.mode = p_mode)
      AND (
        cg.language = up.locale
        OR cg.region_code IN (
          SELECT ucp.region FROM user_cuisine_preference ucp
          WHERE ucp.user_id = p_user_id
        )
      )
    ORDER BY cg.member_count DESC
    LIMIT LEAST(p_limit, 100);
    RETURN;
  END IF;

  -- Personalized path: cosine similarity
  RETURN QUERY
  SELECT
    cg.id                                           AS group_id,
    (1 - (gv.vector <=> v_user_vector))::numeric    AS score
  FROM community_group cg
  JOIN group_vector gv ON gv.group_id = cg.id
  WHERE cg.is_public = true
    AND cg.id <> ALL(p_exclude)
    AND (p_mode IS NULL OR cg.mode = p_mode)
  ORDER BY (gv.vector <=> v_user_vector) ASC
  LIMIT LEAST(p_limit, 100);
END;
$$;
