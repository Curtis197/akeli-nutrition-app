-- supabase/migrations/20260529000007_create_batch_sessions_function.sql
-- Replacement for 20260525000006: same logic + SET search_path + plan ownership guard + REVOKE/GRANT

CREATE OR REPLACE FUNCTION public.create_batch_sessions(
  p_meal_plan_id uuid,
  p_user_id      uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_rec              RECORD;
  v_recipe_servings  numeric;
  v_scale_factor     numeric(6,3);
  v_session_id       uuid;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.meal_plan
    WHERE id = p_meal_plan_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Delete existing sessions for this plan (cascades to ingredients, nulls component FKs)
  DELETE FROM public.cooking_session
  WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;

  -- For each recipe that appears >= 2 times as a base component, create one batch session
  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)                  AS appearance_count,
      SUM(mpe.servings)         AS total_portions_needed,
      MIN(mpe.scheduled_date)   AS first_date
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2
  LOOP
    SELECT servings INTO v_recipe_servings
    FROM public.recipe
    WHERE id = v_rec.recipe_id;

    v_scale_factor := ROUND(
      (v_rec.total_portions_needed / GREATEST(COALESCE(v_recipe_servings, 1), 1))::numeric,
      3
    );

    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used, scale_factor
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, CEIL(v_rec.total_portions_needed), 0, v_scale_factor
    )
    RETURNING id INTO v_session_id;

    -- Scaled ingredients for batch cooking UI
    INSERT INTO public.cooking_session_ingredient
      (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
    SELECT
      v_session_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      ROUND((ri.quantity * v_scale_factor)::numeric, 3),
      ri.unit
    FROM public.recipe_ingredient ri
    JOIN public.ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_rec.recipe_id
      AND ri.is_optional = false;

    -- Link components to session so shopping list doesn't double-count
    UPDATE public.meal_plan_entry_component mpec
    SET cooking_session_id = v_session_id
    FROM public.meal_plan_entry mpe
    WHERE mpec.meal_plan_entry_id = mpe.id
      AND mpe.meal_plan_id = p_meal_plan_id
      AND mpec.recipe_id = v_rec.recipe_id;

  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.create_batch_sessions(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_batch_sessions(uuid, uuid) TO authenticated;
