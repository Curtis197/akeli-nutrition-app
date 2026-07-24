-- supabase/tests/compute_monthly_beauty_revenue_cron_test.sql
-- Finding #4 (Area C, High): the entire beauty payout system has no
-- cron/edge-function invocation anywhere (confirmed: no reference to
-- calculate_creator_payouts outside its own migration file, prior to this
-- fix). This test verifies the SQL-testable half of the fix: the cron
-- registration. The edge function itself (Deno code) is verified by a
-- direct file-existence check in Step 4 below, since pgTAP cannot invoke
-- Deno functions.
BEGIN;
SELECT plan(2);

SELECT has_function(
  'public', 'calculate_creator_payouts', ARRAY['date','integer'],
  'calculate_creator_payouts(date, integer) exists for the monthly beauty revenue cron to call'
);

-- NOTE: this repository's local/CI environment does not have the
-- pg_cron extension installed (same reason every other cron-registration
-- migration in this repo, e.g. 20260703000001_register_recalculate_nutrition_plans_cron.sql,
-- guards its own PERFORM cron.schedule(...) call behind this exact
-- schema check). Where pg_cron IS available (staging/prod), this
-- assertion is a real integration check that fails before the migration
-- and passes after. Where it is not available, it SKIPs rather than
-- silently passing.
-- A top-level SQL CASE must resolve every branch's table references at parse
-- time, even ones that never execute -- so referencing cron.job directly in
-- an ELSE-guarded branch still fails to parse when pg_cron isn't installed.
-- Deferring the cron.job read into dynamic SQL (EXECUTE) inside a PL/pgSQL
-- IF block avoids this: plpgsql only parses each embedded statement lazily,
-- when its branch actually runs -- the same approach this codebase's own
-- 20260703000001_register_recalculate_nutrition_plans_cron.sql migration
-- uses to guard its own cron.job/cron.schedule references.
DO $$
DECLARE
  v_cron_available boolean := EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron');
  v_count int;
BEGIN
  PERFORM set_config('pgtap_test.cron_available', v_cron_available::text, true);
  IF v_cron_available THEN
    EXECUTE 'SELECT count(*)::int FROM cron.job WHERE jobname = ''compute-monthly-beauty-revenue''' INTO v_count;
    PERFORM set_config('pgtap_test.cron_job_count', v_count::text, true);
  END IF;
END;
$$;

SELECT CASE current_setting('pgtap_test.cron_available', true)
  WHEN 'true' THEN (
    SELECT is(
      current_setting('pgtap_test.cron_job_count', true)::int,
      1,
      'compute-monthly-beauty-revenue is registered as a monthly cron job'
    )
  )
  ELSE (
    SELECT skip('pg_cron schema not installed in this environment (expected on local/CI without the extension) — see note above')
  )
END AS result;

SELECT * FROM finish();
ROLLBACK;
