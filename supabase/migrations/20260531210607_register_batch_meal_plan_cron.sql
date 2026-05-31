-- Register weekly batch meal plan generation cron job.
-- Fires every Sunday at 23:00 UTC and calls the batch-generate-meal-plans edge function.
--
-- The INTERNAL_SECRET must be stored in the Supabase Vault under the name 'INTERNAL_SECRET'
-- before this migration is applied. Set it via:
--   supabase secrets set INTERNAL_SECRET=<value> --project-ref <project-ref>
-- Then insert into vault:
--   SELECT vault.create_secret('<value>', 'INTERNAL_SECRET', 'Internal secret for cron auth');
--
-- The cron job uses vault.decrypted_secrets to read the secret at runtime so the
-- plaintext value is never stored in pg_cron.job.command.

-- Fix 2: Vault pre-flight guard — fail loudly if INTERNAL_SECRET is missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET'
  ) THEN
    RAISE EXCEPTION 'INTERNAL_SECRET not found in vault. Run: SELECT vault.create_secret(''<secret>'', ''INTERNAL_SECRET'') before applying this migration.';
  END IF;
END;
$$;

-- Fix 1: Idempotency — unschedule if already registered so re-runs don't error or duplicate
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'batch-generate-meal-plans-weekly';

SELECT cron.schedule(
  'batch-generate-meal-plans-weekly',
  '0 23 * * 0',
  $$
  SELECT net.http_post(
    -- NOTE: URL is hardcoded to production project njzqcftjzskwcpforwzf — update if migrating to a different project
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/batch-generate-meal-plans',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET' ORDER BY created_at DESC LIMIT 1)
    ),
    body    := '{}'::jsonb  -- offset: 0 is intentional; edge function self-chains for subsequent batches
  ) AS request_id;
  $$
);
