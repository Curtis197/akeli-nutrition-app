-- =============================================================================
-- Add detailed ratings to recipe table
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.recipe
  ADD COLUMN IF NOT EXISTS average_rating_taste numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS average_rating_ease numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS average_rating_satiety numeric NOT NULL DEFAULT 0;

-- ---------------------------------------------------------------------------
-- 2. Backfill detailed rating stats from existing meal_consumption rows
-- ---------------------------------------------------------------------------
UPDATE public.recipe r
SET
  average_rating_taste = COALESCE(
    (SELECT ROUND(AVG(mc.rating_taste)::numeric, 2)
     FROM public.meal_consumption mc
     WHERE mc.recipe_id = r.id
       AND mc.rating_taste IS NOT NULL),
    0
  ),
  average_rating_ease = COALESCE(
    (SELECT ROUND(AVG(mc.rating_ease)::numeric, 2)
     FROM public.meal_consumption mc
     WHERE mc.recipe_id = r.id
       AND mc.rating_ease IS NOT NULL),
    0
  ),
  average_rating_satiety = COALESCE(
    (SELECT ROUND(AVG(mc.rating_satiety)::numeric, 2)
     FROM public.meal_consumption mc
     WHERE mc.recipe_id = r.id
       AND mc.rating_satiety IS NOT NULL),
    0
  );

-- ---------------------------------------------------------------------------
-- 3. Update Trigger function: maintain detailed average_rating stats
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_fn_recipe_rating_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_recipe_id uuid;
BEGIN
  -- Resolve which recipe is affected
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
      (SELECT ROUND(AVG(mc.rating)::numeric, 2)
       FROM public.meal_consumption mc
       WHERE mc.recipe_id = v_recipe_id
         AND mc.rating IS NOT NULL),
      0
    ),
    rating_count = COALESCE(
      (SELECT COUNT(*)::integer
       FROM public.meal_consumption mc
       WHERE mc.recipe_id = v_recipe_id
         AND mc.rating IS NOT NULL),
      0
    ),
    average_rating_taste = COALESCE(
      (SELECT ROUND(AVG(mc.rating_taste)::numeric, 2)
       FROM public.meal_consumption mc
       WHERE mc.recipe_id = v_recipe_id
         AND mc.rating_taste IS NOT NULL),
      0
    ),
    average_rating_ease = COALESCE(
      (SELECT ROUND(AVG(mc.rating_ease)::numeric, 2)
       FROM public.meal_consumption mc
       WHERE mc.recipe_id = v_recipe_id
         AND mc.rating_ease IS NOT NULL),
      0
    ),
    average_rating_satiety = COALESCE(
      (SELECT ROUND(AVG(mc.rating_satiety)::numeric, 2)
       FROM public.meal_consumption mc
       WHERE mc.recipe_id = v_recipe_id
         AND mc.rating_satiety IS NOT NULL),
      0
    )
  WHERE id = v_recipe_id;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_recipe_rating_stats ON public.meal_consumption;
CREATE TRIGGER trg_recipe_rating_stats
  AFTER INSERT OR UPDATE OF rating, rating_taste, rating_ease, rating_satiety OR DELETE ON public.meal_consumption
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_recipe_rating_stats();
