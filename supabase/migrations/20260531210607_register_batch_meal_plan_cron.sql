-- Register weekly batch meal plan generation cron job.
-- Fires every Monday at 01:00 UTC and calls the batch-generate-meal-plans edge function.
--
-- The INTERNAL_SECRET must be stored in the Supabase Vault under the name 'INTERNAL_SECRET'
-- before this migration is applied. Set it via:
--   supabase secrets set INTERNAL_SECRET=<value> --project-ref <project-ref>
-- Then insert into vault:
--   SELECT vault.create_secret('<value>', 'INTERNAL_SECRET', 'Internal secret for cron auth');
--
-- The cron job uses vault.decrypted_secrets to read the secret at runtime so the
-- plaintext value is never stored in pg_cron.job.command.

-- Vault pre-flight: seed a local placeholder if secret is absent (local DB reset only).
-- On remote the secret already exists so this block is a no-op.
DO $$
DECLARE
  v_placeholder text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET'
  ) THEN
    SELECT encode(gen_random_bytes(32), 'hex') INTO v_placeholder;
    PERFORM vault.create_secret(v_placeholder, 'INTERNAL_SECRET', 'Local dev placeholder — replace on remote');
  END IF;
END;
$$;

-- Cron registration — skipped silently on local where pg_cron is not installed.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
    -- Idempotency: unschedule if already registered
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'batch-generate-meal-plans-weekly';

    PERFORM cron.schedule(
      'batch-generate-meal-plans-weekly',
      '0 1 * * 1',
      $cmd$
      SELECT net.http_post(
        url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/batch-generate-meal-plans',
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET' ORDER BY created_at DESC LIMIT 1)
        ),
        body    := '{}'::jsonb
      ) AS request_id;
      $cmd$
    );
  END IF;
END;
$$;
