-- Fix: swap_meal_plan_entry scaled the new recipe to a FLAT split
-- (calorie_goal / meals_per_day), ignoring meal_distribution. generate_meal_plan
-- scales to the per-meal meal_distribution.calorie_target. So a swapped meal
-- drifted from the slot objective the generator built (e.g. breakfast aimed at
-- goal/3 = 1046 instead of the 30%-of-goal distribution target).
--
-- Fix: read meal_distribution.calorie_target for the entry's meal_type (same
-- source the generator uses), falling back to the flat goal/meals split only
-- when no distribution row exists. Also adopt the generator's serving bounds
-- (0.1 .. 4.0) and add SET search_path = public (advisor 0011).

CREATE OR REPLACE FUNCTION public.swap_meal_plan_entry(p_entry_id uuid, p_new_recipe_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
DECLARE
  v_user_id              uuid;
  v_plan_id              uuid;
  v_meals_per_day        int;
  v_entry_meal_type      text;
  v_calorie_goal         numeric;
  v_target_meal_calories numeric;
  v_recipe_calories      numeric;
  v_recipe_protein_g     numeric;
  v_recipe_carbs_g       numeric;
  v_recipe_fat_g         numeric;
  v_new_servings         numeric(4,1) := 1.0;
  v_entry_date           date;
BEGIN
  -- Fetch the entry's plan, date AND meal_type (meal_type is new: needed to
  -- look up the per-meal calorie target).
  SELECT mp.user_id, mp.id, mpe.scheduled_date, mpe.meal_type
  INTO   v_user_id, v_plan_id, v_entry_date, v_entry_meal_type
  FROM   meal_plan_entry mpe
  JOIN   meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE  mpe.id = p_entry_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized or entry not found';
  END IF;

  SELECT COUNT(*) INTO v_meals_per_day
  FROM   meal_plan_entry
  WHERE  meal_plan_id = v_plan_id AND scheduled_date = v_entry_date;

  IF v_meals_per_day = 0 THEN v_meals_per_day := 3; END IF;

  SELECT calorie_goal INTO v_calorie_goal
  FROM   user_goal
  WHERE  user_id = v_user_id AND is_active = true
  ORDER  BY created_at DESC LIMIT 1;

  SELECT calories, protein_g, carbs_g, fat_g
  INTO   v_recipe_calories, v_recipe_protein_g, v_recipe_carbs_g, v_recipe_fat_g
  FROM   recipe_macro
  WHERE  recipe_id = p_new_recipe_id;

  -- Per-meal calorie objective: prefer meal_distribution.calorie_target for this
  -- slot (same source generate_meal_plan uses), so a swap lands on the SAME
  -- objective the generator built — not a flat goal/meals split. Fall back to
  -- the flat split only when no distribution row exists.
  SELECT md.calorie_target INTO v_target_meal_calories
  FROM   meal_distribution md
  JOIN   nutrition_plan np ON np.id = md.nutrition_plan_id
  WHERE  np.user_id = v_user_id
    AND  np.is_active = true
    AND  md.meal_type = v_entry_meal_type
  LIMIT 1;

  IF v_target_meal_calories IS NULL
     AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
    v_target_meal_calories := v_calorie_goal / v_meals_per_day;
  END IF;

  -- Scale to the target with the same bounds as the generator (0.1 .. 4.0).
  IF v_target_meal_calories IS NOT NULL
     AND v_recipe_calories IS NOT NULL AND v_recipe_calories > 0 THEN
    v_new_servings := GREATEST(0.1, LEAST(4.0,
      ROUND((v_target_meal_calories / v_recipe_calories)::numeric, 1)));
  ELSE
    v_new_servings := 1.0;
  END IF;

  UPDATE meal_plan_entry
  SET
    servings           = v_new_servings,
    calories_computed  = ROUND((COALESCE(v_recipe_calories,  0) * v_new_servings)::numeric, 1),
    protein_g_computed = ROUND((COALESCE(v_recipe_protein_g, 0) * v_new_servings)::numeric, 1),
    carbs_g_computed   = ROUND((COALESCE(v_recipe_carbs_g,   0) * v_new_servings)::numeric, 1),
    fat_g_computed     = ROUND((COALESCE(v_recipe_fat_g,     0) * v_new_servings)::numeric, 1)
  WHERE id = p_entry_id;

  DELETE FROM meal_plan_entry_component WHERE meal_plan_entry_id = p_entry_id;

  INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
  VALUES (p_entry_id, p_new_recipe_id, 'base', 1.0);

  DELETE FROM meal_ingredient WHERE meal_plan_entry_id = p_entry_id;

  INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
  SELECT
    p_entry_id,
    ri.ingredient_id,
    COALESCE(i.name_fr, i.name),
    round_to_step(
      ri.quantity * v_new_servings,
      COALESCE(
        (SELECT rounding_step FROM ingredient_rounding_rule
         WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
        (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
      )
    ),
    ri.unit
  FROM   recipe_ingredient ri
  JOIN   ingredient i ON i.id = ri.ingredient_id
  WHERE  ri.recipe_id = p_new_recipe_id
    AND  ri.is_optional = false
    AND  ri.ingredient_id IS NOT NULL;

  PERFORM generate_shopping_list(v_plan_id);
  PERFORM create_batch_sessions(v_plan_id, v_user_id, 7);
END;
$function$;
