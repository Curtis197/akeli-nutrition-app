-- Switch the portion model from per-serving to per-100g.
--
-- Two schema changes:
-- 1. Widen meal_plan_entry.servings from numeric(4,1) to numeric(6,1) so it can
--    store gram values (50–1500) without overflow. Existing fractional values
--    (0.1–4.0) are preserved as-is; subsequent generator runs will write grams.
-- 2. Add four GENERATED STORED columns to recipe_macro that expose the per-100g
--    nutrition figures. All 123 existing recipes have total_weight_g > 0 so no
--    NULLs will appear. The generated columns auto-update whenever the source
--    columns change.

ALTER TABLE public.meal_plan_entry
  ALTER COLUMN servings TYPE numeric(6,1);

ALTER TABLE public.recipe_macro
  ADD COLUMN IF NOT EXISTS kcal_per_100g    numeric
    GENERATED ALWAYS AS (ROUND(calories    / NULLIF(total_weight_g, 0) * 100, 2)) STORED,
  ADD COLUMN IF NOT EXISTS protein_per_100g numeric
    GENERATED ALWAYS AS (ROUND(protein_g   / NULLIF(total_weight_g, 0) * 100, 2)) STORED,
  ADD COLUMN IF NOT EXISTS carbs_per_100g   numeric
    GENERATED ALWAYS AS (ROUND(carbs_g     / NULLIF(total_weight_g, 0) * 100, 2)) STORED,
  ADD COLUMN IF NOT EXISTS fat_per_100g     numeric
    GENERATED ALWAYS AS (ROUND(fat_g       / NULLIF(total_weight_g, 0) * 100, 2)) STORED;
