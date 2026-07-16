-- supabase/migrations/20260716200000_deferred_unpublish.sql
-- Deferred unpublish: creators' unpublish requests are held until Monday 00:30 UTC
-- (30 min before batch-generate-meal-plans-weekly at 01:00) so existing meal plans
-- keep working through the week. See docs/superpowers/specs/2026-07-16-deferred-unpublish-design.md

ALTER TABLE recipe ADD COLUMN IF NOT EXISTS unpublish_requested_at timestamptz NULL;

COMMENT ON COLUMN recipe.unpublish_requested_at IS
  'Non-null = pending unpublish. Recipe stays is_published=true (readable) until the Monday finalizer cron flips it. Cleared on re-publish.';

CREATE OR REPLACE FUNCTION public.finalize_pending_unpublish()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  UPDATE recipe
  SET is_published = false,
      unpublish_requested_at = NULL
  WHERE unpublish_requested_at IS NOT NULL;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Only cron (runs as postgres) may call this — it mass-unpublishes flagged recipes.
REVOKE EXECUTE ON FUNCTION public.finalize_pending_unpublish() FROM PUBLIC, anon, authenticated;

-- Cron registration — skipped silently on local where pg_cron is not installed.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'finalize-pending-unpublish-weekly';

    PERFORM cron.schedule(
      'finalize-pending-unpublish-weekly',
      '30 0 * * 1',
      $cmd$ SELECT public.finalize_pending_unpublish(); $cmd$
    );
  END IF;
END;
$$;
