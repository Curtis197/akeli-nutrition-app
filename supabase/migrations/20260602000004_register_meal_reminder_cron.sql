-- Register daily meal reminder cron job.
-- Fires every day at 07:00 UTC and calls the send-meal-reminders edge function.
--
-- The INTERNAL_SECRET must be in Vault before this migration is applied.
-- If not already present, add it:
--   SELECT vault.create_secret('<value>', 'INTERNAL_SECRET', 'Internal secret for cron auth');

-- Cron registration — skipped silently on local where pg_cron is not installed.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
    -- Idempotent: unschedule first so re-runs don't error or duplicate
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'send-meal-reminders-daily';

    PERFORM cron.schedule(
      'send-meal-reminders-daily',
      '0 7 * * *',
      $cmd$
      SELECT net.http_post(
        url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-meal-reminders',
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
