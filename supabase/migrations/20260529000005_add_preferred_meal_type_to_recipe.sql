-- supabase/migrations/20260529000005_add_preferred_meal_type_to_recipe.sql
ALTER TABLE public.recipe
  ADD COLUMN IF NOT EXISTS preferred_meal_type text NOT NULL DEFAULT 'any'
  CHECK (preferred_meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'any'));
