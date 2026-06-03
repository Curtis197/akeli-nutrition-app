-- =============================================================================
-- Migration: 20260525000008_personal_meal_entry.sql
-- Description: Add custom meal override columns + swap_meal_plan_entry_custom RPC
-- =============================================================================

-- 1. Add custom meal columns to meal_plan_entry
ALTER TABLE meal_plan_entry
  ADD COLUMN IF NOT EXISTS custom_meal_name  text,
  ADD COLUMN IF NOT EXISTS custom_calories   numeric(7,1),
  ADD COLUMN IF NOT EXISTS custom_protein_g  numeric(6,1),
  ADD COLUMN IF NOT EXISTS custom_carbs_g    numeric(6,1),
  ADD COLUMN IF NOT EXISTS custom_fat_g      numeric(6,1),
  ADD COLUMN IF NOT EXISTS is_custom_meal    boolean NOT NULL DEFAULT false;

-- 2. RPC: swap a meal plan entry for a custom (non-recipe) meal
CREATE OR REPLACE FUNCTION swap_meal_plan_entry_custom(
  p_entry_id    uuid,
  p_meal_name   text,
  p_calories    numeric,
  p_protein_g   numeric DEFAULT NULL,
  p_carbs_g     numeric DEFAULT NULL,
  p_fat_g       numeric DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id  uuid;
  v_plan_id  uuid;
BEGIN
  -- 1. Ownership check
  SELECT mp.user_id, mp.id
    INTO v_user_id, v_plan_id
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mpe.id = p_entry_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized or entry not found';
  END IF;

  -- 2. Remove existing recipe-backed components
  DELETE FROM meal_plan_entry_component
  WHERE meal_plan_entry_id = p_entry_id;

  -- 3. Write custom macro overrides onto the entry
  UPDATE meal_plan_entry SET
    is_custom_meal   = true,
    custom_meal_name = p_meal_name,
    custom_calories  = p_calories,
    custom_protein_g = p_protein_g,
    custom_carbs_g   = p_carbs_g,
    custom_fat_g     = p_fat_g
  WHERE id = p_entry_id;

  -- 4. Regenerate shopping list (removes old recipe ingredients)
  PERFORM generate_shopping_list(v_plan_id);
END;
$$;
