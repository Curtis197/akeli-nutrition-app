-- =============================================================================
-- AKELI — Creator Vector & Creator Feed RPCs
-- Migration: 20260530000001_creator_vector_feed.sql
--
-- What this adds:
--   Table : creator_vector
--   RPCs  : generate_creators_personalized,
--            generate_creators_exploration,
--            generate_creators_fresh
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. creator_vector
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS creator_vector (
  creator_id           UUID PRIMARY KEY REFERENCES creator(id) ON DELETE CASCADE,
  vector               vector(50) NOT NULL,
  last_computed        timestamptz NOT NULL DEFAULT now(),
  recipe_count_sampled int        NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_creator_vector_hnsw
  ON creator_vector USING hnsw (vector vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

ALTER TABLE creator_vector ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service manages creator_vector" ON creator_vector;
CREATE POLICY "service manages creator_vector" ON creator_vector
  FOR ALL USING (true);

-- ---------------------------------------------------------------------------
-- 2. generate_creators_personalized — 70% du creator feed
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_creators_personalized(
  p_user_id UUID,
  p_limit   INT     DEFAULT 14,
  p_exclude UUID[]  DEFAULT '{}'
)
RETURNS TABLE (creator_id UUID, score numeric)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
  v_max_fans    int;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    SELECT MAX(fan_count) INTO v_max_fans FROM creator;
    RETURN QUERY
    SELECT
      c.id AS creator_id,
      CASE WHEN v_max_fans > 0
        THEN (c.fan_count::numeric / v_max_fans)
        ELSE 0::numeric
      END AS score
    FROM creator c
    WHERE c.recipe_count >= 3
      AND c.id <> ALL(p_exclude)
    ORDER BY c.fan_count DESC
    LIMIT LEAST(p_limit, 100);
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    c.id                                          AS creator_id,
    (1 - (cv.vector <=> v_user_vector))::numeric  AS score
  FROM creator c
  JOIN creator_vector cv ON cv.creator_id = c.id
  WHERE c.recipe_count >= 3
    AND c.id <> ALL(p_exclude)
  ORDER BY (cv.vector <=> v_user_vector) ASC
  LIMIT LEAST(p_limit, 100);
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. generate_creators_exploration — 20% du creator feed
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_creators_exploration(
  p_user_id UUID,
  p_limit   INT    DEFAULT 4,
  p_exclude UUID[] DEFAULT '{}'
)
RETURNS TABLE (creator_id UUID, score numeric)
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
    RETURN;
  END IF;

  RETURN QUERY
  WITH candidates AS (
    SELECT
      c.id                                          AS creator_id,
      (1 - (cv.vector <=> v_user_vector))::numeric  AS score
    FROM creator c
    JOIN creator_vector cv ON cv.creator_id = c.id
    WHERE c.recipe_count >= 3
      AND c.average_rating >= 3.5
      AND c.id <> ALL(p_exclude)
  )
  SELECT cand.creator_id, cand.score
  FROM candidates cand
  WHERE cand.score < 0.50
  ORDER BY random()
  LIMIT LEAST(p_limit, 50);
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. generate_creators_fresh — 10% du creator feed
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_creators_fresh(
  p_user_id UUID,
  p_limit   INT    DEFAULT 2,
  p_exclude UUID[] DEFAULT '{}'
)
RETURNS TABLE (creator_id UUID, score numeric)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    c.id      AS creator_id,
    0::numeric AS score
  FROM creator c
  WHERE
    c.id <> ALL(p_exclude)
    AND (
      c.created_at >= now() - interval '60 days'
      OR EXISTS (
        SELECT 1 FROM recipe r
        WHERE r.creator_id = c.id
          AND r.is_published = true
          AND r.created_at >= now() - interval '30 days'
      )
    )
    AND NOT EXISTS (
      SELECT 1 FROM fan_subscription fs
      WHERE fs.creator_id = c.id
        AND fs.user_id = p_user_id
        AND fs.status = 'active'
    )
  ORDER BY c.created_at DESC
  LIMIT LEAST(p_limit, 20);
END;
$$;
