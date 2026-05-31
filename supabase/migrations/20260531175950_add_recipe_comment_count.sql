-- =============================================================================
-- Add comment_count to recipe table
-- =============================================================================

ALTER TABLE public.recipe
  ADD COLUMN IF NOT EXISTS comment_count integer NOT NULL DEFAULT 0;

-- Backfill from existing comments (if any)
UPDATE public.recipe r
SET comment_count = (
  SELECT COUNT(*)
  FROM public.recipe_comment rc
  WHERE rc.recipe_id = r.id
);

-- Trigger to keep comment_count updated
CREATE OR REPLACE FUNCTION public.trg_fn_recipe_comment_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_recipe_id uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_recipe_id := OLD.recipe_id;
  ELSE
    v_recipe_id := NEW.recipe_id;
  END IF;

  IF v_recipe_id IS NOT NULL THEN
    UPDATE public.recipe
    SET comment_count = (
      SELECT COUNT(*)
      FROM public.recipe_comment
      WHERE recipe_id = v_recipe_id
    )
    WHERE id = v_recipe_id;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_recipe_comment_stats ON public.recipe_comment;
CREATE TRIGGER trg_recipe_comment_stats
  AFTER INSERT OR UPDATE OR DELETE ON public.recipe_comment
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_recipe_comment_stats();
