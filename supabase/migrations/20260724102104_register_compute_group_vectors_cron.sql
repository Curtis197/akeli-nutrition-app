-- Migration: register the compute-group-vectors-weekly cron job.
--
-- This job (jobid 5 on production, schedule '0 2 * * 1') was registered
-- directly on remote out-of-band and had no corresponding migration file —
-- discovered while investigating why local's cron.job table was empty
-- despite 5 other cron-registration migrations existing in git. Captured
-- here so it's finally reproducible from migrations alone, matching the
-- pattern used by every other *_cron.sql migration in this project.
--
-- Cron registration — skipped silently where pg_cron is not installed.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
    -- Idempotent: unschedule first so re-runs don't error or duplicate
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'compute-group-vectors-weekly';

    PERFORM cron.schedule(
      'compute-group-vectors-weekly',
      '0 2 * * 1',
      $cmd$
      SELECT net.http_post(
        url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/compute-group-vectors',
        headers := jsonb_build_object(
          'Content-Type',      'application/json',
          'x-internal-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET' ORDER BY created_at DESC LIMIT 1)
        ),
        body    := '{}'::jsonb
      ) AS request_id;
      $cmd$
    );
  END IF;
END;
$$;
