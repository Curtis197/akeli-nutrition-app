-- =============================================================================
-- Migration: 20260529000002_add_computed_macros_to_entry.sql
-- Description: Pre-computed macros stored at generation time (calories × servings)
-- =============================================================================

ALTER TABLE public.meal_plan_entry
  ADD COLUMN IF NOT EXISTS calories_computed  numeric(10,1),
  ADD COLUMN IF NOT EXISTS protein_g_computed numeric(10,1),
  ADD COLUMN IF NOT EXISTS carbs_g_computed   numeric(10,1),
  ADD COLUMN IF NOT EXISTS fat_g_computed     numeric(10,1);

COMMENT ON COLUMN public.meal_plan_entry.calories_computed IS
  'recipe_macro.calories × entry.servings — computed at generation time, read directly by the app';
COMMENT ON COLUMN public.meal_plan_entry.protein_g_computed IS
  'recipe_macro.protein_g × entry.servings — computed at generation time';
COMMENT ON COLUMN public.meal_plan_entry.carbs_g_computed IS
  'recipe_macro.carbs_g × entry.servings — computed at generation time';
COMMENT ON COLUMN public.meal_plan_entry.fat_g_computed IS
  'recipe_macro.fat_g × entry.servings — computed at generation time';
