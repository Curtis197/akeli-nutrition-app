-- Migration: 20260617085800_saved_recipes_eligibility
-- Description: Adds eligibility state boolean and progress tracking RPC.

-- 1. Add eligibility column
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS is_saved_recipe_eligible BOOLEAN NOT NULL DEFAULT false;

-- 2. Update Evaluate eligibility RPC
CREATE OR REPLACE FUNCTION public.evaluate_saved_recipe_eligibility(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_breakfast_count int;
  v_lunch_count int;
  v_dinner_count int;
  v_was_eligible boolean;
  v_now_eligible boolean;
BEGIN
  -- Get current eligibility
  SELECT is_saved_recipe_eligible INTO v_was_eligible
  FROM user_profile WHERE id = p_user_id;

  -- Calculate counts
  SELECT count(*) INTO v_breakfast_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'breakfast' = ANY(r.meal_types);

  SELECT count(*) INTO v_lunch_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'lunch' = ANY(r.meal_types);

  SELECT count(*) INTO v_dinner_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'dinner' = ANY(r.meal_types);

  -- Determine new state
  IF v_breakfast_count >= 7 AND v_lunch_count >= 7 AND v_dinner_count >= 7 THEN
    v_now_eligible := true;
  ELSE
    v_now_eligible := false;
  END IF;

  -- Apply updates
  IF v_now_eligible != COALESCE(v_was_eligible, false) THEN
    IF v_now_eligible = false THEN
      -- If they lost eligibility, also force the feature off
      UPDATE user_profile 
      SET is_saved_recipe_eligible = false, use_saved_recipes_only = false 
      WHERE id = p_user_id;
    ELSE
      -- They gained eligibility
      UPDATE user_profile 
      SET is_saved_recipe_eligible = true 
      WHERE id = p_user_id;
    END IF;
  END IF;
END;
$$;

-- 3. Create Progress tracking RPC for the frontend UI
DROP FUNCTION IF EXISTS public.get_saved_recipe_eligibility_progress(uuid);

CREATE OR REPLACE FUNCTION public.get_saved_recipe_eligibility_progress(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_breakfast_count int;
  v_lunch_count int;
  v_dinner_count int;
  v_is_eligible boolean;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT is_saved_recipe_eligible INTO v_is_eligible
  FROM user_profile WHERE id = p_user_id;

  SELECT count(*) INTO v_breakfast_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'breakfast' = ANY(r.meal_types);

  SELECT count(*) INTO v_lunch_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'lunch' = ANY(r.meal_types);

  SELECT count(*) INTO v_dinner_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'dinner' = ANY(r.meal_types);

  RETURN json_build_object(
    'is_eligible', COALESCE(v_is_eligible, false),
    'progress', json_build_array(
      json_build_object('meal_type', 'breakfast', 'saved_count', v_breakfast_count, 'target_count', 7),
      json_build_object('meal_type', 'lunch', 'saved_count', v_lunch_count, 'target_count', 7),
      json_build_object('meal_type', 'dinner', 'saved_count', v_dinner_count, 'target_count', 7)
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION get_saved_recipe_eligibility_progress(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_saved_recipe_eligibility_progress(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION get_saved_recipe_eligibility_progress(uuid) TO authenticated;
