-- ================================================================
-- AKELI BEAUTY MODE: ADAPT VECTOR RPC FUNCTIONS FOR BEAUTY MODE
-- ================================================================

-- 1. RECOMMEND_RECIPES (WITH MODE FILTER)
CREATE OR REPLACE FUNCTION recommend_recipes(
  p_user_id   uuid,
  p_limit     int     DEFAULT 10,
  p_offset    int     DEFAULT 0,
  p_region    text    DEFAULT NULL,
  p_difficulty text   DEFAULT NULL,
  p_max_time  int     DEFAULT NULL,
  p_mode      text    DEFAULT NULL
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
  similarity      numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
  v_fan_creator_id uuid;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  IF v_user_vector IS NULL THEN
    RETURN QUERY
    SELECT
      r.id, r.title, r.description, r.cover_image_url, r.region, r.difficulty, r.prep_time_min, r.cook_time_min, r.servings, r.creator_id, c.display_name, c.profile_image_url AS creator_avatar, rm.calories, rm.protein_g, COUNT(rl.recipe_id)::bigint AS like_count,
      0.5::numeric AS similarity
    FROM recipe r
    LEFT JOIN creator c ON r.creator_id = c.id
    LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
    LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
    WHERE r.is_published = true
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND (p_region IS NULL OR r.region = p_region)
      AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
      AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    GROUP BY r.id, c.display_name, c.profile_image_url, rm.calories, rm.protein_g
    ORDER BY like_count DESC, r.created_at DESC
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
    r.id, r.title, r.description, r.cover_image_url, r.region, r.difficulty, r.prep_time_min, r.cook_time_min, r.servings, r.creator_id, c.display_name, c.profile_image_url AS creator_avatar, rm.calories, rm.protein_g, COUNT(rl.recipe_id)::bigint AS like_count,
    ((1 - (rv.vector <=> v_user_vector)) *
      CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
        THEN 1.5 ELSE 1.0 END)::numeric AS similarity
  FROM recipe r
  JOIN recipe_vector rv ON r.id = rv.recipe_id
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  WHERE r.is_published = true
    AND (p_mode IS NULL OR r.mode = p_mode)
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  GROUP BY r.id, c.display_name, c.profile_image_url, rm.calories, rm.protein_g, rv.vector, v_fan_creator_id
  ORDER BY similarity DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 2. GENERATE_FEED_PERSONALIZED (WITH MODE FILTER)
CREATE OR REPLACE FUNCTION generate_feed_personalized(
  p_user_id uuid,
  p_limit   int    DEFAULT 100,
  p_exclude uuid[] DEFAULT '{}',
  p_mode    text   DEFAULT NULL
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
    RETURN QUERY
    SELECT r.id AS recipe_id, 0.5::numeric AS score
    FROM recipe r
    WHERE r.is_published = true
      AND r.is_private = false
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND r.id <> ALL(p_exclude)
    ORDER BY r.created_at DESC
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
    AND (p_mode IS NULL OR r.mode = p_mode)
    AND r.id <> ALL(p_exclude)
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  ORDER BY score DESC
  LIMIT LEAST(p_limit, 200);
END;
$$;

-- 3. GENERATE_FEED_EXPLORATION (WITH MODE FILTER)
CREATE OR REPLACE FUNCTION generate_feed_exploration(
  p_user_id uuid,
  p_limit   int    DEFAULT 40,
  p_exclude uuid[] DEFAULT '{}',
  p_mode    text   DEFAULT NULL
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
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND r.id <> ALL(p_exclude)
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  )
  SELECT c.recipe_id, c.score
  FROM candidates c
  WHERE c.score < 0.50
  ORDER BY random()
  LIMIT LEAST(p_limit, 80);
END;
$$;
