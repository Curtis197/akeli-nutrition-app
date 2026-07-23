-- Migration: Restore missing auth.uid() authorization check in generate_routine_plan
-- File: supabase/migrations/20260722090000_fix_generate_routine_plan_auth_check.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #1 (Critical).
--
-- generate_routine_plan (20260720000001_beauty_mode_database_update.sql:90-126) is
-- SECURITY DEFINER with no auth.uid() = p_user_id check, so any authenticated user
-- can pass another user's UUID and deactivate/overwrite their beauty routine plan.
-- This restores the exact idiom already used correctly by recommend_recipes in the
-- same migration file (20260720000002_adapt_vector_rpcs_for_beauty_mode.sql:40):
--   IF auth.uid() IS DISTINCT FROM p_user_id THEN RAISE EXCEPTION 'Unauthorized'; END IF;
--
-- Signature is unchanged (uuid, integer), so CREATE OR REPLACE patches the existing
-- function in place without needing a DROP FUNCTION first.

CREATE OR REPLACE FUNCTION generate_routine_plan(
  p_user_id uuid,
  p_days integer DEFAULT 7
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan_id uuid;
  v_start_date date := CURRENT_DATE;
  v_end_date date := CURRENT_DATE + (p_days - 1);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Deactivate existing beauty plans for user
  UPDATE meal_plan
  SET is_active = false
  WHERE user_id = p_user_id AND mode = 'beauty' AND is_active = true;

  -- Create new beauty routine plan
  INSERT INTO meal_plan (
    user_id,
    start_date,
    end_date,
    is_active,
    mode
  ) VALUES (
    p_user_id,
    v_start_date,
    v_end_date,
    true,
    'beauty'
  )
  RETURNING id INTO v_plan_id;

  RETURN v_plan_id;
END;
$$;
