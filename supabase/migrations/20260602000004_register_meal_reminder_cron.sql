-- Register daily meal reminder cron job.
-- Fires every day at 07:00 UTC and calls the send-meal-reminders edge function.
--
-- The INTERNAL_SECRET must be in Vault before this migration is applied.
-- If not already present, add it:
--   SELECT vault.create_secret('<value>', 'INTERNAL_SECRET', 'Internal secret for cron auth');

-- Vault pre-flight guard — skip on local dev if secret is missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET'
  ) THEN
    RAISE WARNING 'INTERNAL_SECRET not found in vault — skipping cron registration (local dev). Run: SELECT vault.create_secret(''<secret>'', ''INTERNAL_SECRET'') for production.';
    RETURN;
  END IF;
END;
$$;

-- Idempotent — unschedule first so re-runs don't error or duplicate
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'send-meal-reminders-daily';

SELECT cron.schedule(
  'send-meal-reminders-daily',
  '0 7 * * *',
  $$
  SELECT net.http_post(
    -- NOTE: URL hardcoded to production project njzqcftjzskwcpforwzf — update if migrating
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-meal-reminders',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-internal-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET' ORDER BY created_at DESC LIMIT 1)
    ),
    body    := '{}'::jsonb
  ) AS request_id;
  $$
);
