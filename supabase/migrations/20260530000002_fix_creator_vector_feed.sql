-- =============================================================================
-- AKELI — Fix creator_vector feed issues
-- Migration: 20260530000002_fix_creator_vector_feed.sql
--
-- Fixes applied after code review of 20260530000001:
--   1. Add creator.average_rating column (referenced by generate_creators_exploration)
--   2. Add index on creator(created_at) for generate_creators_fresh
--   3. Recreate generate_creators_fresh with recency decay score (was 0::numeric)
-- =============================================================================

-- 1. Add average_rating to creator table
ALTER TABLE creator
  ADD COLUMN IF NOT EXISTS average_rating numeric NOT NULL DEFAULT 0;

-- 2. Index supporting generate_creators_fresh date-range filter
CREATE INDEX IF NOT EXISTS idx_creator_created_at
  ON creator (created_at DESC);

-- 3. Recreate generate_creators_fresh with 60-day decay score
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
    c.id AS creator_id,
    -- Decay score: 1.0 = just created, ~0.0 = 60 days old
    (1.0 - EXTRACT(EPOCH FROM (now() - c.created_at)) / (60.0 * 24 * 3600))::numeric AS score
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
