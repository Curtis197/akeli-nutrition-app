-- Migration: Enforce "only one active beauty_plan per user" as a durable
-- DB-level invariant via trigger, instead of relying on every insert path to
-- remember to run the UPDATE ... SET is_active = false first.
-- File: supabase/migrations/20260724000003_beauty_plan_deactivate_others_trigger.sql
--
-- 20260722100000_beauty_plan_is_active_column.sql added the is_active column
-- with a one-time backfill UPDATE, but that only fixes historical rows at
-- migration-apply time -- it does not keep the invariant true going forward.
-- Today, only generate_beauty_plan() and both generate_beauty_plan_from_saved()
-- overloads maintain it, each by manually running the same
-- `UPDATE beauty_plan SET is_active = false WHERE user_id = ... AND
-- is_active = true` immediately before their own INSERT. Any other insert
-- path (a raw INSERT, or a future RPC that forgets this boilerplate) can
-- leave a user with more than one active plan.
--
-- supabase/tests/beauty_plan_is_active_column_test.sql (T4/T5) asserts a raw
-- INSERT of two beauty_plan rows for the same user results in only the most
-- recently created one being active -- confirmed via `pg_get_functiondef`
-- that no such trigger existed, and empirically: T5 failed with
-- "have: true, want: false" because the column's DEFAULT true alone cannot
-- express a per-user invariant. This is a real gap, not just a test bug.
CREATE OR REPLACE FUNCTION beauty_plan_deactivate_others()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.is_active THEN
    UPDATE beauty_plan
    SET is_active = false
    WHERE user_id = NEW.user_id
      AND id <> NEW.id
      AND is_active = true;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS beauty_plan_deactivate_others_trigger ON beauty_plan;
CREATE TRIGGER beauty_plan_deactivate_others_trigger
AFTER INSERT ON beauty_plan
FOR EACH ROW
EXECUTE FUNCTION beauty_plan_deactivate_others();
