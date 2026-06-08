-- supabase/migrations/20260608100000_recipe_video_cooking_mode.sql

-- recipe: presentation video URL
ALTER TABLE recipe ADD COLUMN IF NOT EXISTS video_url TEXT NULL;

-- recipe_step: per-step video and tagged ingredient IDs
ALTER TABLE recipe_step ADD COLUMN IF NOT EXISTS video_url       TEXT   NULL;
ALTER TABLE recipe_step ADD COLUMN IF NOT EXISTS ingredient_ids  UUID[] NULL;

-- ingredient: nutritional values and contextual notes (all nullable)
ALTER TABLE ingredient
  ADD COLUMN IF NOT EXISTS calories_per_100g NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS protein_g         NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS carbs_g           NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS fat_g             NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS fiber_g           NUMERIC NULL,
  ADD COLUMN IF NOT EXISTS substitution      TEXT    NULL,
  ADD COLUMN IF NOT EXISTS market_notes      TEXT    NULL;
