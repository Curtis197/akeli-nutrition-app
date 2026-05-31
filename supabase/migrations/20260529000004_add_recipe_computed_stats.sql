-- =============================================================================
-- Add computed stats columns to recipe table
--
-- Fixes: average_rating and rating_count were read by the Dart model but did
--        not exist as columns. like_count existed in RPC paths only.
--
-- Strategy (Option A): store denormalized counters on recipe, maintained by
-- AFTER triggers on meal_consumption and recipe_like. Backfill from existing rows.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.recipe
  ADD COLUMN IF NOT EXISTS average_rating numeric        NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS rating_count   integer        NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS like_count     integer        NOT NULL DEFAULT 0;

-- ---------------------------------------------------------------------------
-- 2. Backfill like_count from existing recipe_like rows
-- ---------------------------------------------------------------------------
UPDATE public.recipe r
SET like_count = (
  SELECT COUNT(*)::integer
  FROM public.recipe_like rl
  WHERE rl.recipe_id = r.id
);

-- ---------------------------------------------------------------------------
-- 3. Backfill rating stats from existing meal_consumption rows
-- ---------------------------------------------------------------------------
UPDATE public.recipe r
SET
  average_rating = COALESCE(
    (SELECT ROUND(AVG(mc.rating)::numeric, 2)
     FROM public.meal_consumption mc
     WHERE mc.recipe_id = r.id
       AND mc.rating IS NOT NULL),
    0
  ),
  rating_count = COALESCE(
    (SELECT COUNT(*)::integer
     FROM public.meal_consumption mc
     WHERE mc.recipe_id = r.id
       AND mc.rating IS NOT NULL),
    0
  );

-- ---------------------------------------------------------------------------
-- 4. Trigger: maintain like_count on recipe_like INSERT / DELETE
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_fn_recipe_like_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.recipe
    SET like_count = like_count + 1
    WHERE id = NEW.recipe_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.recipe
    SET like_count = GREATEST(like_count - 1, 0)
    WHERE id = OLD.recipe_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_recipe_like_count ON public.recipe_like;
CREATE TRIGGER trg_recipe_like_count
  AFTER INSERT OR DELETE ON public.recipe_like
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_recipe_like_count();

-- ---------------------------------------------------------------------------
-- 5. Trigger: maintain average_rating + rating_count on meal_consumption
--    Fires on INSERT, UPDATE OF rating, and DELETE.
--    Re-aggregates from source of truth to keep averages exact.
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
    )
  WHERE id = v_recipe_id;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_recipe_rating_stats ON public.meal_consumption;
CREATE TRIGGER trg_recipe_rating_stats
  AFTER INSERT OR UPDATE OF rating OR DELETE ON public.meal_consumption
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_recipe_rating_stats();
