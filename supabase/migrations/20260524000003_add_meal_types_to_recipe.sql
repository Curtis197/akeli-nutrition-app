-- =============================================================================
-- Migration: 20260524000003_add_meal_types_to_recipe.sql
-- Description: Add meal_types to recipe and enforce filtering in generate_meal_plan
-- =============================================================================

-- 1. Add meal_types column to recipe table.
-- Default it to all meal types so existing recipes remain eligible for any meal.
ALTER TABLE recipe
  ADD COLUMN meal_types text[] DEFAULT '{breakfast,lunch,dinner,snack}';

-- 2. Update generate_meal_plan to filter by meal_types
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
BEGIN
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  -- Désactiver les plans actifs précédents
  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

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

      -- Créer l'entrée du plan (sans recipe_id)
      INSERT INTO meal_plan_entry (meal_plan_id, scheduled_date, meal_type)
      VALUES (v_plan_id, v_current_date, v_meal_type)
      RETURNING id INTO v_entry_id;

      -- Créer le composant base
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
