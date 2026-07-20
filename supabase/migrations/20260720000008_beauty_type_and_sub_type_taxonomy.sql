-- ================================================================
-- AKELI BEAUTY MODE: BEAUTY TYPE (HAIR/SKIN) AND SUB-TYPE TAXONOMY
-- ================================================================

-- 1. ADD BEAUTY TYPE AND BEAUTY SUB-TYPE COLUMNS TO RECIPE TABLE
ALTER TABLE recipe
  ADD COLUMN IF NOT EXISTS beauty_type VARCHAR(50) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS beauty_sub_type VARCHAR(50) DEFAULT NULL;

COMMENT ON COLUMN recipe.beauty_type IS 'Beauty target category (hair, skin, both)';
COMMENT ON COLUMN recipe.beauty_sub_type IS 'Beauty remedy sub-type (mask, oil_bath, moisturizer, leave_in_mist, scalp_serum, face_mask, cleanser_scrub, face_oil_serum, toner_mist)';

-- 2. SEED BEAUTY TYPE & SUB-TYPE FOR ALL BEAUTY REMEDIES
UPDATE recipe SET beauty_type = 'hair', beauty_sub_type = 'mask' WHERE id = 'b0000001-0000-0000-0000-000000000001'::uuid;
UPDATE recipe SET beauty_type = 'skin', beauty_sub_type = 'cleanser_scrub' WHERE id = 'b0000002-0000-0000-0000-000000000002'::uuid;
UPDATE recipe SET beauty_type = 'both', beauty_sub_type = 'toner_mist' WHERE id = 'b0000003-0000-0000-0000-000000000003'::uuid;
UPDATE recipe SET beauty_type = 'hair', beauty_sub_type = 'oil_bath' WHERE id = 'b0000004-0000-0000-0000-000000000004'::uuid;
UPDATE recipe SET beauty_type = 'hair', beauty_sub_type = 'scalp_serum' WHERE id = 'b0000005-0000-0000-0000-000000000005'::uuid;
UPDATE recipe SET beauty_type = 'hair', beauty_sub_type = 'moisturizer' WHERE id = 'b0000006-0000-0000-0000-000000000006'::uuid;
UPDATE recipe SET beauty_type = 'skin', beauty_sub_type = 'face_mask' WHERE id = 'b0000007-0000-0000-0000-000000000007'::uuid;
UPDATE recipe SET beauty_type = 'hair', beauty_sub_type = 'scalp_serum' WHERE id = 'b0000008-0000-0000-0000-000000000008'::uuid;

-- 3. UPDATE RECOMMEND_RECIPES RPC WITH BEAUTY TYPE/SUB-TYPE FILTERS
CREATE OR REPLACE FUNCTION recommend_recipes(
  p_user_id        uuid,
  p_limit          int     DEFAULT 10,
  p_offset         int     DEFAULT 0,
  p_region         text    DEFAULT NULL,
  p_difficulty     text    DEFAULT NULL,
  p_max_time       int     DEFAULT NULL,
  p_mode           text    DEFAULT NULL,
  p_beauty_type    text    DEFAULT NULL,
  p_beauty_sub_type text   DEFAULT NULL
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
      AND (p_beauty_type IS NULL OR r.beauty_type = p_beauty_type OR r.beauty_type = 'both')
      AND (p_beauty_sub_type IS NULL OR r.beauty_sub_type = p_beauty_sub_type)
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
    AND (p_beauty_type IS NULL OR r.beauty_type = p_beauty_type OR r.beauty_type = 'both')
    AND (p_beauty_sub_type IS NULL OR r.beauty_sub_type = p_beauty_sub_type)
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
