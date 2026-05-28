-- =============================================================================
-- Migration: 20260529000003_rewrite_generate_meal_plan.sql
-- Description: All-or-nothing generation, 3-entry cap, fan 90% rule,
--              scale bounds, pre-computed macros, meal_ingredient population
-- =============================================================================

DROP FUNCTION IF EXISTS generate_meal_plan(uuid, int, int, date);
CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id       uuid,
  p_days          int     DEFAULT 7,
  p_meals_per_day int     DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  meal_plan_id    uuid,
  entry_id        uuid,
  component_id    uuid,
  scheduled_date  date,
  meal_type       text,
  recipe_id       uuid,
  recipe_title    text,
  cover_image_url text,
  calories        numeric,
  protein_g       numeric,
  similarity      float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector       vector(50);
  v_fan_creator_id    uuid;
  v_plan_id           uuid;
  v_meal_types        text[] := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day               int;
  v_meal_type         text;
  v_current_date      date;
  v_recipe            record;
  v_entry_id          uuid;
  v_component_id      uuid;
  v_used_recipe_ids   uuid[] := ARRAY[]::uuid[];
  v_calorie_goal      numeric;
  v_target_meal_cal   numeric;
  v_servings          numeric(4,1);
  v_fan_count         int := 0;
  v_other_count       int := 0;
  v_total_slots       int;
  v_max_other_slots   int;
BEGIN
  -- Compute fan quota
  v_total_slots     := p_days * p_meals_per_day;
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  -- Determine meal types
  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  -- Get user vector
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Get fan creator
  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  -- Get fallback calorie goal
  SELECT calorie_goal INTO v_calorie_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  -- Disable previous active plans
  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  -- Create new plan (rolled back automatically if RAISE EXCEPTION is hit)
  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      -- Per-meal calorie target from meal_distribution
      v_target_meal_cal := NULL;
      SELECT md.calorie_target INTO v_target_meal_cal
      FROM meal_distribution md
      JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
      WHERE np.user_id = p_user_id
        AND np.is_active = true
        AND md.meal_type = v_meal_type
      LIMIT 1;

      -- Fallback to flat split
      IF v_target_meal_cal IS NULL AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / p_meals_per_day;
      END IF;

      -- Select best recipe with all constraints applied
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (1 - (rv.vector <=> v_user_vector)) *
               CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
                 THEN 1.5 ELSE 1.0 END AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          -- 3-entry cap
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          -- Fan 90% rule
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          -- Scale cap: skip if would exceed 4.0x
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               0.5::float AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
        GROUP BY r.id, rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g, r.creator_id
        ORDER BY COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      -- All-or-nothing: abort entire plan if no recipe found
      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
      END IF;

      -- Calculate servings with bounds
      IF v_target_meal_cal IS NOT NULL AND v_recipe.calories > 0 THEN
        v_servings := GREATEST(0.1, LEAST(4.0, ROUND((v_target_meal_cal / v_recipe.calories)::numeric, 1)));
      ELSE
        v_servings := 1.0;
      END IF;

      -- Insert entry with pre-computed macros
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

      -- Add base recipe component
      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      -- Populate meal_ingredient (scaled by servings)
      INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
      SELECT
        v_entry_id,
        ri.ingredient_id,
        COALESCE(i.name_fr, i.name),
        ROUND((ri.quantity * v_servings)::numeric, 3),
        ri.unit
      FROM recipe_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = v_recipe.id
        AND ri.is_optional = false;

      -- Track usage
      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

      RETURN QUERY SELECT
        v_plan_id,
        v_entry_id,
        v_component_id,
        v_current_date,
        v_meal_type,
        v_recipe.id,
        v_recipe.title,
        v_recipe.cover_image_url,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        v_recipe.score::float;

    END LOOP;
  END LOOP;
END;
$$;
