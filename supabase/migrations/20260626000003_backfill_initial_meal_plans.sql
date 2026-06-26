-- Migration: 20260626000003_backfill_initial_meal_plans
-- Description: One-time backfill — generates today → coming Sunday meal plans for all
-- onboarded users who do not yet have an active plan starting today.
-- Needed because the Monday batch cron failed and left users without a current-week plan.
-- Uses generate_initial_meal_plan_internal (service_role-safe, no auth.uid() guard).
-- Each user is processed in an isolated sub-transaction so a single failure does not
-- roll back the rest of the batch.

SET statement_timeout = '0';

DO $$
DECLARE
  v_user_id   uuid;
  v_success   int := 0;
  v_skipped   int := 0;
  v_failed    int := 0;
BEGIN
  FOR v_user_id IN
    SELECT id
    FROM public.user_profile
    WHERE onboarding_done = true
    ORDER BY created_at
  LOOP
    BEGIN
      PERFORM public.generate_initial_meal_plan_internal(v_user_id);
      v_success := v_success + 1;
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLERRM ILIKE '%insufficient_recipes%' THEN
          v_skipped := v_skipped + 1;
        ELSE
          v_failed := v_failed + 1;
          RAISE NOTICE 'Failed for user %: %', v_user_id, SQLERRM;
        END IF;
    END;
  END LOOP;

  RAISE NOTICE 'Backfill complete | success: % | skipped (no recipes): % | failed: %',
    v_success, v_skipped, v_failed;
END;
$$;

RESET statement_timeout;
