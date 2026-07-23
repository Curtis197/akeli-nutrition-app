-- Migration: 20260722110300_register_compute_monthly_beauty_revenue_cron.sql
-- Finding #4 (Area C, High): registers the compute-monthly-beauty-revenue
-- cron job, mirroring the pattern used by
-- 20260703000001_register_recalculate_nutrition_plans_cron.sql. Scheduled
-- one hour after compute-monthly-revenue's own documented (but, per grep,
-- never actually registered by any tracked migration) 01:00 UTC slot, to
-- avoid resource contention.
--
-- Cron registration — skipped silently on local where pg_cron is not installed.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
    -- Idempotent: unschedule first so re-runs don't error or duplicate
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'compute-monthly-beauty-revenue';

    PERFORM cron.schedule(
      'compute-monthly-beauty-revenue',
      '0 2 1 * *',
      $cmd$
      SELECT net.http_post(
        url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/compute-monthly-beauty-revenue',
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
