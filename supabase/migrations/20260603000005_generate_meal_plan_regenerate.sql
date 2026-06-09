-- supabase/migrations/20260603000005_generate_meal_plan_regenerate.sql
--
-- Fix: regenerate (replace) an existing meal plan for the same start_date.
--
-- Root cause: generate_meal_plan had an idempotency guard that returned ZERO
-- rows (not an exception) when an active plan already existed for p_start_date:
--
--     IF EXISTS (... active plan for p_start_date ...) THEN RETURN; END IF;
--
-- The generate-meal-plan edge function treats a zero-row result as "insufficient
-- recipes" and returns 422 "Pas assez de recettes disponibles pour générer un
-- plan" — a misleading error shown to users who simply already had a plan for
-- that day. The function already deactivates all active plans
-- (UPDATE meal_plan SET is_active = false ...) immediately before inserting the
-- new one, so removing the guard makes an explicit regenerate REPLACE the
-- existing same-date plan. Everything else (ingredient rounding, scoring,
-- p_max_recipe_repeat) is preserved verbatim from 20260603000004.

CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id            uuid,
  p_days               integer,
  p_meals_per_day      integer,
  p_start_date         date,
  p_max_recipe_repeat  integer DEFAULT 3
)
RETURNS TABLE (
  meal_plan_id      uuid,
  entry_id          uuid,
  component_id      uuid,
  scheduled_date    date,
  meal_type         text,
  recipe_id         uuid,
  recipe_title      text,
  cover_image_url   text,
  calories          numeric,
  protein_g         numeric,
  score             double precision
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector            vector(50);
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_meal_types             text[] := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_protein_goal           numeric;
  v_fat_goal               numeric;
  v_target_meal_cal        numeric;
  v_target_protein_density numeric;
  v_target_fat_density     numeric;
  v_servings               numeric(4,1);
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  v_total_slots     := p_days * p_meals_per_day;
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), ARRAY[]::text[]) INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND p_meals_per_day > 0 THEN
    v_target_protein_density :=
      COALESCE(v_protein_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
    v_target_fat_density :=
      COALESCE(v_fat_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
  ELSE
    v_target_protein_density := 7.5;
    v_target_fat_density     := 3.3;
  END IF;

  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      v_target_meal_cal := NULL;
      SELECT md.calorie_target INTO v_target_meal_cal
      FROM meal_distribution md
      JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
      WHERE np.user_id = p_user_id
        AND np.is_active = true
        AND md.meal_type = v_meal_type
      LIMIT 1;

      IF v_target_meal_cal IS NULL AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / p_meals_per_day;
      END IF;

      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (
                 0.50 * (1 - (rv.vector <=> v_user_vector))
                        * CASE WHEN v_fan_creator_id IS NOT NULL
                                    AND r.creator_id = v_fan_creator_id
                               THEN 1.5 ELSE 1.0 END
                 + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                         - v_target_protein_density)
                     / NULLIF(v_target_protein_density, 0.001),
                     1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001),
                     1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
          AND NOT (r.allergen_tags && v_user_allergens)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
          AND NOT (r.allergen_tags && v_user_allergens)
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.calories > 0 THEN
        v_servings := GREATEST(0.1, LEAST(4.0,
          ROUND((v_target_meal_cal / v_recipe.calories)::numeric, 1)));
      ELSE
        v_servings := 1.0;
      END IF;

      INSERT INTO meal_plan_entry (
        meal_plan_id, scheduled_date, meal_type, servings,
        calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed
      )
      VALUES (
        v_plan_id, v_current_date, v_meal_type, v_servings,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        ROUND((v_recipe.carbs_g   * v_servings)::numeric, 1),
        ROUND((v_recipe.fat_g     * v_servings)::numeric, 1)
      )
      RETURNING id INTO v_entry_id;

      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
      SELECT
        v_entry_id,
        ri.ingredient_id,
        COALESCE(i.name_fr, i.name),
        round_to_step(
          ri.quantity * v_servings,
          COALESCE(
            (SELECT rounding_step FROM ingredient_rounding_rule
             WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
            (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
          )
        ),
        ri.unit
      FROM recipe_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = v_recipe.id
        AND ri.is_optional = false;

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

      RETURN QUERY SELECT
        v_plan_id, v_entry_id, v_component_id,
        v_current_date, v_meal_type,
        v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        v_recipe.score::double precision;

    END LOOP;
  END LOOP;
END;
$$;
