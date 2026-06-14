-- Switch swap_meal_plan_entry from per-serving to per-100g portion model,
-- keeping it consistent with generate_meal_plan (migration 20260614200100).
--
-- Previously: v_new_servings = target_kcal / kcal_per_serving  (0.1–4.0)
--             ingredients scaled by ri.quantity * v_new_servings
--
-- Now:        v_grams = target_kcal / (kcal_per_100g / 100)    (50–1500g)
--             ingredients scaled by ri.quantity * v_grams / total_weight_g
--
-- The calorie target lookup (meal_distribution.calorie_target preferred over
-- flat goal/meals fallback) and all other logic are unchanged.

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
  v_entry_date           date;
  v_calorie_goal         numeric;
  v_target_meal_calories numeric;
  v_kcal_per_100g        numeric;
  v_protein_per_100g     numeric;
  v_carbs_per_100g       numeric;
  v_fat_per_100g         numeric;
  v_total_weight_g       numeric;
  v_grams                integer := 300;
BEGIN
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

  SELECT rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
         rm.total_weight_g
  INTO   v_kcal_per_100g, v_protein_per_100g, v_carbs_per_100g, v_fat_per_100g,
         v_total_weight_g
  FROM   recipe_macro rm
  WHERE  rm.recipe_id = p_new_recipe_id;

  -- Per-meal calorie target: prefer meal_distribution (same source as the
  -- generator) so the swap lands on the same objective. Fall back to flat split.
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

  IF v_target_meal_calories IS NOT NULL AND v_kcal_per_100g > 0 THEN
    v_grams := GREATEST(50, LEAST(1500,
      ROUND(v_target_meal_calories / (v_kcal_per_100g / 100))::integer));
  END IF;

  UPDATE meal_plan_entry
  SET
    servings           = v_grams,
    calories_computed  = ROUND((COALESCE(v_kcal_per_100g,    0) * v_grams / 100)::numeric, 1),
    protein_g_computed = ROUND((COALESCE(v_protein_per_100g, 0) * v_grams / 100)::numeric, 1),
    carbs_g_computed   = ROUND((COALESCE(v_carbs_per_100g,   0) * v_grams / 100)::numeric, 1),
    fat_g_computed     = ROUND((COALESCE(v_fat_per_100g,     0) * v_grams / 100)::numeric, 1)
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
      ri.quantity * v_grams / NULLIF(v_total_weight_g, 0),
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
