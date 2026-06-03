CREATE TABLE IF NOT EXISTS group_vector (
  group_id             uuid PRIMARY KEY REFERENCES community_group(id) ON DELETE CASCADE,
  vector               vector(50) NOT NULL,
  last_computed        timestamptz NOT NULL DEFAULT now(),
  member_count_sampled int NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_group_vector_hnsw
  ON group_vector USING hnsw (vector vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

ALTER TABLE group_vector ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "service manages group_vector" ON group_vector;
CREATE POLICY "service manages group_vector" ON group_vector
  FOR ALL USING (true);

CREATE OR REPLACE FUNCTION get_group_vector_avg(
  p_group_id uuid
)
RETURNS TABLE (avg_vector vector(50), sampled bigint)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT AVG(uv.vector)::vector(50) as avg_vector, COUNT(*) as sampled
  FROM user_vector uv
  JOIN group_member gm ON gm.user_id = uv.user_id
  WHERE gm.group_id = p_group_id;
END;
$$;

CREATE OR REPLACE FUNCTION generate_groups_personalized(
  p_user_id  uuid,
  p_limit    int     DEFAULT 20,
  p_exclude  uuid[]  DEFAULT '{}'
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
  ORDER BY (gv.vector <=> v_user_vector) ASC
  LIMIT LEAST(p_limit, 100);
END;
$$;
