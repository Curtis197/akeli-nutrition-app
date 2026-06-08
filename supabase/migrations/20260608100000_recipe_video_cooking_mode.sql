-- supabase/migrations/20260608100000_recipe_video_cooking_mode.sql

-- recipe: presentation video URL
ALTER TABLE recipe ADD COLUMN IF NOT EXISTS video_url TEXT NULL;

-- recipe_step: per-step video and tagged ingredient IDs
ALTER TABLE recipe_step ADD COLUMN IF NOT EXISTS video_url       TEXT   NULL;
ALTER TABLE recipe_step ADD COLUMN IF NOT EXISTS ingredient_ids  UUID[] NULL;

-- ingredient: new contextual and missing nutritional columns only
-- (calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g already exist in initial schema)
ALTER TABLE ingredient
  ADD COLUMN IF NOT EXISTS fiber_per_100g NUMERIC(5,1) NULL,
  ADD COLUMN IF NOT EXISTS substitution   TEXT         NULL,
  ADD COLUMN IF NOT EXISTS market_notes   TEXT         NULL;
