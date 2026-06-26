-- Migration: 20260626000004_fix_swap_meal_plan_entry_custom
-- Fixes three issues in swap_meal_plan_entry_custom:
--   1. Add SET search_path (security hardening, matches other RPCs)
--   2. Delete orphaned meal_ingredient rows after component removal
--   3. Trigger nutrition re-sync when a consumed entry is swapped to custom

CREATE OR REPLACE FUNCTION public.swap_meal_plan_entry_custom(
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
SET search_path TO 'public', 'pg_temp'
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

  -- 2. Remove existing recipe-backed components and their ingredient rows
  DELETE FROM meal_plan_entry_component
  WHERE meal_plan_entry_id = p_entry_id;

  DELETE FROM meal_ingredient
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

  -- 4. Re-sync nutrition log if this entry was already consumed.
  --    sync_daily_nutrition_for_date fires on meal_consumption UPDATE and
  --    re-reads custom_calories/macros via COALESCE. The no-op value
  --    assignment is intentional — it triggers the trigger without changing data.
  UPDATE meal_consumption
  SET consumption_value = consumption_value
  WHERE meal_plan_entry_id = p_entry_id;

  -- 5. Regenerate shopping list (custom meals have no ingredients to include)
  PERFORM generate_shopping_list(v_plan_id);
END;
$$;
