-- Switch create_batch_sessions (and its internal variant) from per-serving to
-- per-100g portion model, keeping it consistent with generate_meal_plan.
--
-- Previously: mpe.servings held a fractional multiplier (e.g. 0.3).
--             SUM(mpe.servings) / recipe.servings = scale_factor
--             ingredient qty = ri.quantity * scale_factor
--
-- Now:        mpe.servings holds grams (e.g. 600).
--             SUM(mpe.servings) = total_grams across all appearances.
--             scale_factor = total_grams / recipe_macro.total_weight_g
--             ingredient qty = ri.quantity * scale_factor   (same formula)
--
-- The cooking_session.scale_factor column is reused: it now represents the
-- ratio of total planned grams to the full recipe weight, which is semantically
-- equivalent to the old "fractional servings / recipe servings" ratio.

CREATE OR REPLACE FUNCTION public.create_batch_sessions(
  p_meal_plan_id uuid,
  p_user_id      uuid,
  p_max_portions integer DEFAULT 7
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_rec            RECORD;
  v_total_weight_g numeric;
  v_scale_factor   numeric(8,4);
  v_session_id     uuid;
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

  DELETE FROM public.cooking_session
  WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;

  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)              AS appearance_count,
      SUM(mpe.servings)     AS total_grams,
      MIN(mpe.scheduled_date) AS first_date
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2 AND COUNT(*) <= p_max_portions
  LOOP
    SELECT rm.total_weight_g INTO v_total_weight_g
    FROM public.recipe_macro rm WHERE rm.recipe_id = v_rec.recipe_id;

    v_scale_factor := ROUND(
      (v_rec.total_grams / GREATEST(COALESCE(v_total_weight_g, 1), 1))::numeric,
      4
    );

    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used, scale_factor
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, v_rec.appearance_count::int, 0, v_scale_factor
    )
    RETURNING id INTO v_session_id;

    INSERT INTO public.cooking_session_ingredient
      (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
    SELECT
      v_session_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_scale_factor,
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM public.recipe_ingredient ri
    JOIN public.ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_rec.recipe_id
      AND ri.is_optional = false;

    UPDATE public.meal_plan_entry_component mpec
    SET cooking_session_id = v_session_id
    FROM public.meal_plan_entry mpe
    WHERE mpec.meal_plan_entry_id = mpe.id
      AND mpe.meal_plan_id = p_meal_plan_id
      AND mpec.recipe_id = v_rec.recipe_id;

  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_batch_sessions_internal(
  p_meal_plan_id uuid,
  p_user_id      uuid,
  p_max_portions integer DEFAULT 7
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_rec            RECORD;
  v_total_weight_g numeric;
  v_scale_factor   numeric(8,4);
  v_session_id     uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.meal_plan
    WHERE id = p_meal_plan_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'create_batch_sessions_internal: plan % not owned by user %',
      p_meal_plan_id, p_user_id;
  END IF;

  DELETE FROM public.cooking_session
  WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;

  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)              AS appearance_count,
      SUM(mpe.servings)     AS total_grams,
      MIN(mpe.scheduled_date) AS first_date
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2 AND COUNT(*) <= p_max_portions
  LOOP
    SELECT rm.total_weight_g INTO v_total_weight_g
    FROM public.recipe_macro rm WHERE rm.recipe_id = v_rec.recipe_id;

    v_scale_factor := ROUND(
      (v_rec.total_grams / GREATEST(COALESCE(v_total_weight_g, 1), 1))::numeric,
      4
    );

    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used, scale_factor
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, v_rec.appearance_count::int, 0, v_scale_factor
    )
    RETURNING id INTO v_session_id;

    INSERT INTO public.cooking_session_ingredient
      (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
    SELECT
      v_session_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_scale_factor,
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM public.recipe_ingredient ri
    JOIN public.ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_rec.recipe_id
      AND ri.is_optional = false;

    UPDATE public.meal_plan_entry_component mpec
    SET cooking_session_id = v_session_id
    FROM public.meal_plan_entry mpe
    WHERE mpec.meal_plan_entry_id = mpe.id
      AND mpe.meal_plan_id = p_meal_plan_id
      AND mpec.recipe_id = v_rec.recipe_id;

  END LOOP;
END;
$function$;
