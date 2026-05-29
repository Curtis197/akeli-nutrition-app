-- Create function to generate batch cooking sessions from meal plan
-- Recipes appearing 2+ times as 'base' components trigger session creation
CREATE OR REPLACE FUNCTION public.create_batch_sessions(
  p_meal_plan_id uuid,
  p_user_id      uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_rec RECORD;
BEGIN
  -- Caller must be acting as themselves
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- The meal plan must belong to the caller
  IF NOT EXISTS (
    SELECT 1 FROM public.meal_plan
    WHERE id = p_meal_plan_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)                AS portion_count,
      MIN(mpe.scheduled_date) AS first_date
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2
  LOOP
    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, v_rec.portion_count, 0
    )
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.create_batch_sessions(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_batch_sessions(uuid, uuid) TO authenticated;
