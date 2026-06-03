-- Sync recipe table to match remote schema (columns added without migration files)
ALTER TABLE public.recipe
  ADD COLUMN IF NOT EXISTS slug text,
  ADD COLUMN IF NOT EXISTS draft_data jsonb,
  ADD COLUMN IF NOT EXISTS is_pork_free boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS tags text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS parent_recipe_id uuid REFERENCES public.recipe(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS variant_type text,
  ADD COLUMN IF NOT EXISTS substitution_notes text;
