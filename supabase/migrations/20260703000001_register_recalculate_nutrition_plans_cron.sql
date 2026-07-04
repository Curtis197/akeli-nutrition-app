-- Register weekly nutrition plan recalculation cron job.
-- Fires every Sunday at 23:00 UTC — two hours before
-- batch-generate-meal-plans-weekly (Monday 01:00 UTC) — so that week's meal
-- plan generation reads the freshly recalculated calorie_goal.
--
-- The INTERNAL_SECRET must be in Vault before this migration is applied
-- (it already is, reused from the existing batch-generate-meal-plans and
-- send-meal-reminders cron jobs).

-- Cron registration — skipped silently on local where pg_cron is not installed.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
    -- Idempotent: unschedule first so re-runs don't error or duplicate
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'recalculate-nutrition-plans-weekly';

    PERFORM cron.schedule(
      'recalculate-nutrition-plans-weekly',
      '0 23 * * 0',
      $cmd$
      SELECT net.http_post(
        url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/recalculate-nutrition-plans',
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
