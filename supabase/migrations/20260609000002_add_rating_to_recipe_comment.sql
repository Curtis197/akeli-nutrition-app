-- supabase/migrations/20260609000002_add_rating_to_recipe_comment.sql
-- Add rating columns to recipe_comment and migrate data from meal_consumption

-- 1. Add rating columns to recipe_comment and make content nullable
ALTER TABLE public.recipe_comment
  ALTER COLUMN content DROP NOT NULL,
  ADD COLUMN IF NOT EXISTS rating integer CHECK (rating BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS rating_taste integer CHECK (rating_taste BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS rating_ease integer CHECK (rating_ease BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS rating_satiety integer CHECK (rating_satiety BETWEEN 1 AND 5);

-- 2. Migrate existing ratings from meal_consumption to recipe_comment.
-- Skipped on local reset: meal_consumption.created_at may not exist yet and
-- the table is empty anyway, so the backfill produces no rows.
DO $backfill$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'meal_consumption' AND column_name = 'created_at'
  ) THEN
    INSERT INTO public.recipe_comment (
      user_id, recipe_id, rating, rating_taste, rating_ease, rating_satiety,
      created_at, updated_at
    )
    SELECT
      mc.user_id, mc.recipe_id, mc.rating, mc.rating_taste, mc.rating_ease,
      mc.rating_satiety, mc.created_at, mc.created_at
    FROM public.meal_consumption mc
    WHERE mc.rating IS NOT NULL
    ON CONFLICT (user_id, recipe_id) DO UPDATE
    SET
      rating         = EXCLUDED.rating,
      rating_taste   = EXCLUDED.rating_taste,
      rating_ease    = EXCLUDED.rating_ease,
      rating_satiety = EXCLUDED.rating_satiety,
      updated_at     = EXCLUDED.updated_at
    WHERE EXCLUDED.created_at > public.recipe_comment.updated_at;
  END IF;
END $backfill$;

-- 3. Update the trg_fn_recipe_rating_stats function to calculate from recipe_comment
CREATE OR REPLACE FUNCTION public.trg_fn_recipe_rating_stats()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_recipe_id uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_recipe_id := OLD.recipe_id;
  ELSE
    v_recipe_id := NEW.recipe_id;
  END IF;

  IF v_recipe_id IS NULL THEN
    RETURN NULL;
  END IF;

  UPDATE public.recipe
  SET
    average_rating = COALESCE(
      (SELECT ROUND(AVG(rc.rating)::numeric, 2)
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating IS NOT NULL),
      0
    ),
    rating_count = COALESCE(
      (SELECT COUNT(*)::integer
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating IS NOT NULL),
      0
    ),
    average_rating_taste = COALESCE(
      (SELECT ROUND(AVG(rc.rating_taste)::numeric, 2)
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating_taste IS NOT NULL),
      0
    ),
    average_rating_ease = COALESCE(
      (SELECT ROUND(AVG(rc.rating_ease)::numeric, 2)
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating_ease IS NOT NULL),
      0
    ),
    average_rating_satiety = COALESCE(
      (SELECT ROUND(AVG(rc.rating_satiety)::numeric, 2)
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating_satiety IS NOT NULL),
      0
    )
  WHERE id = v_recipe_id;

  RETURN NULL;
END;
$function$;

-- 4. Move the trigger from meal_consumption to recipe_comment
DROP TRIGGER IF EXISTS trg_recipe_rating_stats ON public.meal_consumption;
DROP TRIGGER IF EXISTS trg_recipe_rating_stats ON public.recipe_comment;

CREATE TRIGGER trg_recipe_rating_stats
  AFTER INSERT OR UPDATE OF rating, rating_taste, rating_ease, rating_satiety OR DELETE ON public.recipe_comment
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_recipe_rating_stats();

-- 5. Drop rating columns from meal_consumption to enforce the new schema
ALTER TABLE public.meal_consumption
  DROP COLUMN IF EXISTS rating,
  DROP COLUMN IF EXISTS rating_taste,
  DROP COLUMN IF EXISTS rating_ease,
  DROP COLUMN IF EXISTS rating_satiety;
