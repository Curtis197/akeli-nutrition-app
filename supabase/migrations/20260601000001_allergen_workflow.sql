-- =============================================================================
-- AKELI V1 — Allergy Workflow
-- Migration: 20260601000001_allergen_workflow.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Database Schema
-- ---------------------------------------------------------------------------

CREATE TABLE allergen (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug       text UNIQUE NOT NULL,
  label      text NOT NULL,
  is_active  boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE ingredient_allergen (
  ingredient_id uuid REFERENCES ingredient(id) ON DELETE CASCADE,
  allergen_id   uuid REFERENCES allergen(id) ON DELETE CASCADE,
  PRIMARY KEY (ingredient_id, allergen_id)
);

CREATE TABLE user_allergy (
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  allergen_id uuid REFERENCES allergen(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, allergen_id)
);

CREATE TABLE allergen_suggestion (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid REFERENCES user_profile(id),
  label      text NOT NULL,
  status     text DEFAULT 'pending', -- 'pending' | 'approved' | 'rejected'
  created_at timestamptz DEFAULT now()
);

-- recipe tags
ALTER TABLE recipe ADD COLUMN allergen_tags text[] DEFAULT '{}';
CREATE INDEX idx_recipe_allergen_tags ON recipe USING GIN (allergen_tags);

-- RLS policies
ALTER TABLE allergen ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads allergen" ON allergen FOR SELECT USING (true);

ALTER TABLE ingredient_allergen ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads ingredient_allergen" ON ingredient_allergen FOR SELECT USING (true);

ALTER TABLE user_allergy ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner manages own user_allergy" ON user_allergy
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE allergen_suggestion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated inserts suggestion" ON allergen_suggestion FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);
CREATE POLICY "owner reads own suggestion" ON allergen_suggestion FOR SELECT USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- 2. Allergen Seed List
-- ---------------------------------------------------------------------------

INSERT INTO allergen (slug, label) VALUES
  ('nuts', 'Tree Nuts'),
  ('peanuts', 'Peanuts'),
  ('dairy', 'Dairy & Lactose'),
  ('gluten', 'Gluten'),
  ('eggs', 'Eggs'),
  ('shellfish', 'Shellfish'),
  ('fish', 'Fish'),
  ('soy', 'Soy & Soya'),
  ('sesame', 'Sesame'),
  ('berries', 'Berries'),
  ('citrus', 'Citrus'),
  ('nightshades', 'Nightshades'),
  ('stone_fruits', 'Stone Fruits'),
  ('legumes', 'Legumes'),
  ('corn', 'Corn & Maize'),
  ('sulfites', 'Sulfites'),
  ('mustard', 'Mustard'),
  ('celery', 'Celery'),
  ('lupin', 'Lupin'),
  ('molluscs', 'Molluscs');

-- ---------------------------------------------------------------------------
-- 3. Trigger & Backfill
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION refresh_recipe_allergen_tags()
RETURNS TRIGGER AS $$
DECLARE
  affected_ingredient_id uuid;
BEGIN
  affected_ingredient_id := COALESCE(NEW.ingredient_id, OLD.ingredient_id);

  UPDATE recipe r
  SET allergen_tags = (
    SELECT COALESCE(array_agg(DISTINCT a.slug), '{}')
    FROM recipe_ingredient ri
    JOIN ingredient_allergen ia ON ia.ingredient_id = ri.ingredient_id
    JOIN allergen a ON a.id = ia.allergen_id
    WHERE ri.recipe_id = r.id
  )
  WHERE r.id IN (
    SELECT DISTINCT ri.recipe_id
    FROM recipe_ingredient ri
    WHERE ri.ingredient_id = affected_ingredient_id
  );

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_refresh_recipe_allergen_tags
AFTER INSERT OR DELETE ON ingredient_allergen
FOR EACH ROW EXECUTE FUNCTION refresh_recipe_allergen_tags();

UPDATE recipe r
SET allergen_tags = (
  SELECT COALESCE(array_agg(DISTINCT a.slug), '{}')
  FROM recipe_ingredient ri
  JOIN ingredient_allergen ia ON ia.ingredient_id = ri.ingredient_id
  JOIN allergen a ON a.id = ia.allergen_id
  WHERE ri.recipe_id = r.id
);

-- ---------------------------------------------------------------------------
-- 4. New RPC — search_allergens
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION search_allergens(p_query text)
RETURNS TABLE(id uuid, slug text, label text) AS $$
  SELECT id, slug, label
  FROM allergen
  WHERE is_active = true
    AND label ILIKE '%' || p_query || '%'
  ORDER BY label
  LIMIT 10;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- 5. RPC Allergen Filter Overwrites
-- ---------------------------------------------------------------------------

-- 5a. recommend_recipes
DROP FUNCTION IF EXISTS recommend_recipes(uuid, int, int, text, text, int);
CREATE OR REPLACE FUNCTION recommend_recipes(
  p_user_id   uuid,
  p_limit     int     DEFAULT 20,
  p_offset    int     DEFAULT 0,
  p_region    text    DEFAULT NULL,
  p_difficulty text   DEFAULT NULL,
  p_max_time  int     DEFAULT NULL
)
RETURNS TABLE (
  id              uuid,
  title           text,
  description     text,
  cover_image_url text,
  region          text,
  difficulty      text,
  prep_time_min   int,
  cook_time_min   int,
  servings        int,
  creator_id      uuid,
  creator_name    text,
  creator_avatar  text,
  calories        numeric,
  protein_g       numeric,
  like_count      bigint,
  similarity      float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
  v_fan_creator_id uuid;
BEGIN
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv
  WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  IF v_user_vector IS NULL THEN
    RETURN QUERY
    WITH user_allergens AS (
      SELECT COALESCE(array_agg(a.slug), '{}') AS tags
      FROM user_allergy ua
      JOIN allergen a ON a.id = ua.allergen_id
      WHERE ua.user_id = p_user_id
    )
    SELECT
      r.id, r.title, r.description, r.cover_image_url, r.region, r.difficulty, r.prep_time_min, r.cook_time_min, r.servings, r.creator_id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, COUNT(rl.recipe_id)::bigint AS like_count, 0.5::float AS similarity
    FROM recipe r
    LEFT JOIN creator c ON r.creator_id = c.id
    LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
    LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
    WHERE r.is_published = true
      AND (p_region IS NULL OR r.region = p_region)
      AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
      AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
    GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g
    ORDER BY like_count DESC
    LIMIT p_limit
    OFFSET p_offset;
    RETURN;
  END IF;

  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  )
  SELECT
    r.id, r.title, r.description, r.cover_image_url, r.region, r.difficulty, r.prep_time_min, r.cook_time_min, r.servings, r.creator_id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, COUNT(rl.recipe_id)::bigint AS like_count,
    (1 - (rv.vector <=> v_user_vector)) *
      CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
        THEN 1.5 ELSE 1.0 END AS similarity
  FROM recipe r
  JOIN recipe_vector rv ON r.id = rv.recipe_id
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  WHERE r.is_published = true
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, rv.vector, v_fan_creator_id
  ORDER BY similarity DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 5b. search_recipes
DROP FUNCTION IF EXISTS search_recipes(text, text, text, uuid[], int, text, int, int);
CREATE OR REPLACE FUNCTION search_recipes(
  p_query      text    DEFAULT NULL,
  p_region     text    DEFAULT NULL,
  p_difficulty text    DEFAULT NULL,
  p_tag_ids    uuid[]  DEFAULT NULL,
  p_max_time   int     DEFAULT NULL,
  p_order_by   text    DEFAULT 'recent',
  p_limit      int     DEFAULT 20,
  p_offset     int     DEFAULT 0
)
RETURNS TABLE (
  id              uuid,
  title           text,
  description     text,
  cover_image_url text,
  region          text,
  difficulty      text,
  prep_time_min   int,
  cook_time_min   int,
  servings        int,
  creator_id      uuid,
  creator_name    text,
  creator_avatar  text,
  calories        numeric,
  like_count      bigint,
  created_at      timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = auth.uid()
  )
  SELECT
    r.id, r.title, r.description, r.cover_image_url, r.region, r.difficulty, r.prep_time_min, r.cook_time_min, r.servings, r.creator_id, c.display_name, c.avatar_url, rm.calories, COUNT(rl.recipe_id)::bigint AS like_count, r.created_at
  FROM recipe r
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  WHERE r.is_published = true
    AND (p_query IS NULL OR (r.title ILIKE '%' || p_query || '%' OR r.description ILIKE '%' || p_query || '%'))
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    AND (p_tag_ids IS NULL OR (
      SELECT COUNT(*) FROM recipe_tag rt
      WHERE rt.recipe_id = r.id AND rt.tag_id = ANY(p_tag_ids)
    ) = array_length(p_tag_ids, 1))
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories
  ORDER BY
    CASE WHEN p_order_by = 'popular' THEN COUNT(rl.recipe_id) END DESC,
    CASE WHEN p_order_by = 'quick'   THEN COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0) END ASC,
    CASE WHEN p_order_by = 'recent' OR p_order_by IS NULL THEN r.created_at END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 5c. generate_feed_personalized
DROP FUNCTION IF EXISTS generate_feed_personalized(uuid, int, uuid[]);
CREATE OR REPLACE FUNCTION generate_feed_personalized(
  p_user_id uuid,
  p_limit   int     DEFAULT 140,
  p_exclude uuid[]  DEFAULT '{}'
)
RETURNS TABLE (
  recipe_id uuid,
  score     numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    RETURN QUERY
    WITH user_allergens AS (
      SELECT COALESCE(array_agg(a.slug), '{}') AS tags
      FROM user_allergy ua
      JOIN allergen a ON a.id = ua.allergen_id
      WHERE ua.user_id = p_user_id
    )
    SELECT
      r.id                         AS recipe_id,
      COUNT(rl.recipe_id)::numeric AS score
    FROM recipe r
    LEFT JOIN recipe_like rl ON rl.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
      AND NOT EXISTS (
        SELECT 1 FROM recipe_performance_metrics rpm
        WHERE rpm.recipe_id = r.id
          AND rpm.drop_off_rate > 0.20
      )
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
    GROUP BY r.id
    ORDER BY score DESC
    LIMIT LEAST(p_limit, 200);
    RETURN;
  END IF;

  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  )
  SELECT
    r.id                                         AS recipe_id,
    (1 - (rv.vector <=> v_user_vector))::numeric AS score
  FROM recipe r
  JOIN recipe_vector rv ON rv.recipe_id = r.id
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND NOT EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
        AND rpm.drop_off_rate > 0.20
    )
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  ORDER BY score DESC
  LIMIT LEAST(p_limit, 200);
END;
$$;

-- 5d. generate_feed_exploration
DROP FUNCTION IF EXISTS generate_feed_exploration(uuid, int, uuid[]);
CREATE OR REPLACE FUNCTION generate_feed_exploration(
  p_user_id uuid,
  p_limit   int    DEFAULT 40,
  p_exclude uuid[] DEFAULT '{}'
)
RETURNS TABLE (
  recipe_id uuid,
  score     numeric
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  ),
  candidates AS (
    SELECT
      r.id                                         AS recipe_id,
      (1 - (rv.vector <=> v_user_vector))::numeric AS score
    FROM recipe r
    JOIN recipe_vector rv ON rv.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  )
  SELECT c.recipe_id, c.score
  FROM candidates c
  WHERE c.score < 0.50
    AND EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = c.recipe_id
        AND rpm.adherence_rate > 0.70
    )
  ORDER BY random()
  LIMIT LEAST(p_limit, 80);
END;
$$;

-- 5e. generate_feed_fresh
DROP FUNCTION IF EXISTS generate_feed_fresh(uuid, int, uuid[]);
CREATE OR REPLACE FUNCTION generate_feed_fresh(
  p_user_id uuid,
  p_limit   int    DEFAULT 20,
  p_exclude uuid[] DEFAULT '{}'
)
RETURNS TABLE (
  recipe_id uuid,
  score     numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  )
  SELECT
    r.id                                                                        AS recipe_id,
    (1.0 - EXTRACT(EPOCH FROM (now() - r.created_at)) / 604800.0)::numeric     AS score
  FROM recipe r
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND r.created_at >= now() - interval '7 days'
    AND NOT EXISTS (
      SELECT 1 FROM fan_subscription fs
      WHERE fs.user_id = p_user_id
        AND fs.status = 'active'
        AND fs.creator_id = r.creator_id
    )
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  ORDER BY r.created_at DESC
  LIMIT LEAST(p_limit, 40);
END;
$$;

-- 5f. generate_meal_plan
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
  v_user_vector    vector(50);
  v_fan_creator_id uuid;
  v_plan_id        uuid;
  v_meal_types     text[]  := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day            int;
  v_meal_type      text;
  v_current_date   date;
  v_recipe         record;
  v_entry_id       uuid;
  v_used_recipe_ids uuid[] := ARRAY[]::uuid[];
  v_user_allergens text[];
BEGIN
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), '{}') INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

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
          AND r.id <> ALL(v_used_recipe_ids)
          AND NOT (r.allergen_tags && v_user_allergens)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url, rm.calories, rm.protein_g, 0.5::float AS score
        INTO v_recipe
        FROM recipe r
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND r.id <> ALL(v_used_recipe_ids)
          AND NOT (r.allergen_tags && v_user_allergens)
        GROUP BY r.id, rm.calories, rm.protein_g
        ORDER BY COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        v_used_recipe_ids := ARRAY[]::uuid[];
        CONTINUE;
      END IF;

      INSERT INTO meal_plan_entry (meal_plan_id, recipe_id, scheduled_date, meal_type)
      VALUES (v_plan_id, v_recipe.id, v_current_date, v_meal_type)
      RETURNING id INTO v_entry_id;

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;

      RETURN QUERY SELECT
        v_plan_id, v_entry_id, v_current_date, v_meal_type, v_recipe.id, v_recipe.title, v_recipe.cover_image_url, v_recipe.calories, v_recipe.protein_g, v_recipe.score;
    END LOOP;
  END LOOP;
END;
$$;

-- 5g. generate_meal_plan_internal
DROP FUNCTION IF EXISTS public.generate_meal_plan_internal(uuid, integer, integer, date);
CREATE OR REPLACE FUNCTION public.generate_meal_plan_internal(
  p_user_id       uuid,
  p_days          integer DEFAULT 7,
  p_meals_per_day integer DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
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
  v_user_allergens         text[];
BEGIN
  IF EXISTS (
    SELECT 1 FROM meal_plan
    WHERE user_id = p_user_id
      AND start_date = p_start_date
      AND is_active = true
  ) THEN
    RETURN;
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

  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), '{}') INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

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
        ROUND((ri.quantity * v_servings)::numeric, 3),
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

    END LOOP;
  END LOOP;
END;
$function$;

REVOKE ALL ON FUNCTION public.generate_meal_plan_internal(uuid, integer, integer, date) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_meal_plan_internal(uuid, integer, integer, date) FROM anon;
REVOKE ALL ON FUNCTION public.generate_meal_plan_internal(uuid, integer, integer, date) FROM authenticated;
