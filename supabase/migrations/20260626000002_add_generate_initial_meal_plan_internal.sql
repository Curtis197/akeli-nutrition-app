-- Migration: 20260626000002_add_generate_initial_meal_plan_internal
-- Description: Batch/service_role copy of generate_initial_meal_plan.
-- The original (user-facing) function is preserved unchanged — it has the
-- auth.uid() guard and is called from the Flutter app during onboarding.
-- This internal copy removes the guard so the batch edge function can invoke
-- it as service_role (e.g. to recover from a failed Monday cron).

CREATE OR REPLACE FUNCTION public.generate_initial_meal_plan_internal(
  p_user_id           uuid,
  p_meals_per_day     integer DEFAULT 3,
  p_max_recipe_repeat integer DEFAULT 2
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  v_days_until_sunday integer;
BEGIN
  -- (7 - dow) % 7 + 1 → Sun=1, Mon=7, Tue=6, Wed=5, Thu=4, Fri=3, Sat=2
  v_days_until_sunday :=
    (7 - EXTRACT(dow FROM CURRENT_DATE)::integer) % 7 + 1;

  PERFORM public.generate_meal_plan_internal(
    p_user_id,
    v_days_until_sunday,
    p_meals_per_day,
    CURRENT_DATE
  );
END;
$$;

REVOKE ALL ON FUNCTION public.generate_initial_meal_plan_internal(uuid, integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_initial_meal_plan_internal(uuid, integer, integer) FROM anon;
REVOKE ALL ON FUNCTION public.generate_initial_meal_plan_internal(uuid, integer, integer) FROM authenticated;
