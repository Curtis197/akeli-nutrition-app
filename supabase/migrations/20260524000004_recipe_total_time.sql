-- supabase/migrations/20260524000003_recipe_total_time.sql
ALTER TABLE recipe
  ADD COLUMN IF NOT EXISTS total_time_min INTEGER
  GENERATED ALWAYS AS (prep_time_min + cook_time_min) STORED;

COMMENT ON COLUMN recipe.total_time_min IS 'prep_time_min + cook_time_min — used by PostgREST time filters';
