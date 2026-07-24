-- Migration: Fix beauty_plan_deactivate_others to key off created_at instead
-- of id, so multi-row INSERTs don't mutually deactivate every row.
-- File: supabase/migrations/20260724000005_fix_beauty_plan_deactivate_others_trigger_ordering.sql
--
-- 20260724000003_beauty_plan_deactivate_others_trigger.sql's trigger used
-- `id <> NEW.id AND is_active = true` to find rows to deactivate. For a
-- single-row INSERT (the only pattern generate_beauty_plan/
-- generate_beauty_plan_from_saved use) this is fine. But Postgres queues
-- row-level AFTER triggers for a multi-row INSERT and fires them only once
-- ALL rows in the statement have already been inserted -- so by the time
-- either row's trigger runs, both rows already exist with is_active=true.
-- Row A's trigger then deactivates row B (id <> A, is_active = true), and
-- row B's trigger deactivates row A right back -- both end up false.
-- Confirmed empirically via a direct 2-row INSERT reproducing exactly this:
-- both rows ended up is_active = false. supabase/tests/beauty_plan_is_active_column_test.sql
-- T4 caught this ("most recently created plan is active", have: false).
--
-- Fix: only deactivate rows strictly OLDER than the new one (created_at <
-- NEW.created_at), so the earlier row's trigger has nothing to touch yet in
-- a multi-row insert (no row is older than the first-listed one) and the
-- later row's trigger correctly deactivates only its genuinely older sibling.
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
      AND is_active = true
      AND created_at < NEW.created_at;
  END IF;
  RETURN NEW;
END;
$$;
