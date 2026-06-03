-- =============================================================================
-- Migration: 20260525000004_patch_generate_meal_plan.sql
-- Description: Patch generate_meal_plan to use per-slot calorie target
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
  v_user_vector     vector(50);
  v_fan_creator_id  uuid;
  v_plan_id         uuid;
  v_meal_types      text[] := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day             int;
  v_meal_type       text;
  v_current_date    date;
  v_recipe          record;
  v_entry_id        uuid;
  v_component_id    uuid;
  v_used_recipe_ids uuid[] := ARRAY[]::uuid[];
  v_calorie_goal    numeric;
  v_target_meal_cal numeric;
  v_servings        numeric(4,1);
BEGIN
  -- Get user vector for AI similarity
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Get fan creator id to boost their recipes
  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  -- Fetch user calorie goal (fallback)
  SELECT calorie_goal INTO v_calorie_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  -- Disable previous active plans
  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  -- Create new plan
  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      -- 1. Determine target calories for this specific meal slot
      v_target_meal_cal := NULL;
      
      SELECT md.calorie_target INTO v_target_meal_cal
      FROM meal_distribution md
      JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
      WHERE np.user_id = p_user_id
        AND np.is_active = true
        AND md.meal_type = v_meal_type
      LIMIT 1;

      -- Fallback if no specific distribution is found
      IF v_target_meal_cal IS NULL AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / p_meals_per_day;
      END IF;

      -- 2. Find recipe
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url, rm.calories, rm.protein_g,
               (1 - (rv.vector <=> v_user_vector)) *
               CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
                 THEN 1.5 ELSE 1.0 END AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND r.id <> ALL(v_used_recipe_ids)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url, rm.calories, rm.protein_g, 0.5::float AS score
        INTO v_recipe
        FROM recipe r
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND r.id <> ALL(v_used_recipe_ids)
        GROUP BY r.id, rm.calories, rm.protein_g
        ORDER BY COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        v_used_recipe_ids := ARRAY[]::uuid[];
        CONTINUE;
      END IF;

      -- 3. Calculate scaled servings based on slot's target calories
      v_servings := 1.0;
      IF v_target_meal_cal IS NOT NULL AND v_recipe.calories IS NOT NULL AND v_recipe.calories > 0 THEN
        v_servings := ROUND((v_target_meal_cal / v_recipe.calories)::numeric, 1);
        IF v_servings < 0.1 THEN
          v_servings := 0.1;
        END IF;
      END IF;

      -- 4. Create entry with calculated servings
      INSERT INTO meal_plan_entry (meal_plan_id, scheduled_date, meal_type, servings)
      VALUES (v_plan_id, v_current_date, v_meal_type, v_servings)
      RETURNING id INTO v_entry_id;

      -- 5. Add base recipe component
      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;

      RETURN QUERY SELECT
        v_plan_id,
        v_entry_id,
        v_component_id,
        v_current_date,
        v_meal_type,
        v_recipe.id,
        v_recipe.title,
        v_recipe.cover_image_url,
        v_recipe.calories,
        v_recipe.protein_g,
        v_recipe.score;
    END LOOP;
  END LOOP;
END;
$$;
