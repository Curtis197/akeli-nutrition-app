-- supabase/migrations/20260529000005_add_rating_dimensions_to_consumption.sql
-- Add optional sub-dimension rating columns to meal_consumption.
-- The existing `rating` column (overall, feeds recipe.average_rating via trigger)
-- is unchanged. These three are nullable and never aggregated publicly.

ALTER TABLE public.meal_consumption
  ADD COLUMN IF NOT EXISTS rating_taste   integer CHECK (rating_taste   BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS rating_ease    integer CHECK (rating_ease    BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS rating_satiety integer CHECK (rating_satiety BETWEEN 1 AND 5);
