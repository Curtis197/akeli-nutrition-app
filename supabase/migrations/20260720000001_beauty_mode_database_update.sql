-- ================================================================
-- AKELI BEAUTY MODE: DATABASE SCHEMA & RPC FUNCTION UPDATE
-- ================================================================

-- 1. ADD MODE COLUMN TO RECIPE TABLE
ALTER TABLE recipe 
  ADD COLUMN IF NOT EXISTS mode VARCHAR(50) NOT NULL DEFAULT 'nutrition';

CREATE INDEX IF NOT EXISTS idx_recipe_mode ON recipe(mode);

-- 2. ADD MODE COLUMN TO INGREDIENT TABLE
ALTER TABLE ingredient 
  ADD COLUMN IF NOT EXISTS mode VARCHAR(50) NOT NULL DEFAULT 'nutrition';

CREATE INDEX IF NOT EXISTS idx_ingredient_mode ON ingredient(mode);

-- 3. ADD MODE COLUMN TO MEAL_PLAN TABLE (ROUTINE PLAN SUPPORT)
ALTER TABLE meal_plan 
  ADD COLUMN IF NOT EXISTS mode VARCHAR(50) NOT NULL DEFAULT 'nutrition';

CREATE INDEX IF NOT EXISTS idx_meal_plan_mode ON meal_plan(mode);

-- 4. UPDATE SEARCH_RECIPES RPC TO FILTER BY MODE
CREATE OR REPLACE FUNCTION search_recipes(
  p_query text DEFAULT NULL::text,
  p_region_id text DEFAULT NULL::text,
  p_difficulty text DEFAULT NULL::text,
  p_max_time_min integer DEFAULT NULL::integer,
  p_mode text DEFAULT NULL::text,
  p_limit integer DEFAULT 20,
  p_offset integer DEFAULT 0
)
RETURNS TABLE(
  id uuid,
  title text,
  description text,
  cover_image_url text,
  prep_time_min integer,
  cook_time_min integer,
  difficulty text,
  region text,
  mode text,
  creator_id uuid,
  creator_name text,
  like_count integer,
  is_liked_by_me boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.title,
    r.description,
    r.cover_image_url,
    r.prep_time_min,
    r.cook_time_min,
    r.difficulty,
    r.region,
    r.mode,
    r.creator_id,
    c.display_name AS creator_name,
    COALESCE(r.like_count, 0) AS like_count,
    EXISTS (
      SELECT 1 FROM recipe_like rl 
      WHERE rl.recipe_id = r.id AND rl.user_id = auth.uid()
    ) AS is_liked_by_me
  FROM recipe r
  LEFT JOIN creator c ON c.id = r.creator_id
  WHERE r.is_published = true
    AND (p_mode IS NULL OR r.mode = p_mode)
    AND (p_region_id IS NULL OR r.region = p_region_id)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time_min IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time_min)
    AND (
      p_query IS NULL 
      OR p_query = '' 
      OR r.title ILIKE '%' || p_query || '%'
      OR r.description ILIKE '%' || p_query || '%'
    )
  ORDER BY r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 5. GENERATE BEAUTY ROUTINE PLAN RPC
CREATE OR REPLACE FUNCTION generate_routine_plan(
  p_user_id uuid,
  p_days integer DEFAULT 7
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan_id uuid;
  v_start_date date := CURRENT_DATE;
  v_end_date date := CURRENT_DATE + (p_days - 1);
BEGIN
  -- Deactivate existing beauty plans for user
  UPDATE meal_plan 
  SET is_active = false 
  WHERE user_id = p_user_id AND mode = 'beauty' AND is_active = true;

  -- Create new beauty routine plan
  INSERT INTO meal_plan (
    user_id,
    start_date,
    end_date,
    is_active,
    mode
  ) VALUES (
    p_user_id,
    v_start_date,
    v_end_date,
    true,
    'beauty'
  )
  RETURNING id INTO v_plan_id;

  RETURN v_plan_id;
END;
$$;
