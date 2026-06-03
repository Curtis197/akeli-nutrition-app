-- Add save_count to recipe, maintained by trigger on recipe_save.
-- The toggle-recipe-like edge function is being redirected to recipe_save,
-- so this column replaces recipe.like_count as the "save" counter.

ALTER TABLE recipe ADD COLUMN IF NOT EXISTS save_count integer NOT NULL DEFAULT 0;

-- Backfill from existing recipe_save rows
UPDATE recipe r
SET save_count = (SELECT COUNT(*) FROM recipe_save rs WHERE rs.recipe_id = r.id);

-- Trigger function (SECURITY DEFINER so it bypasses RLS on recipe table)
-- Clients read recipe.save_count, never recipe_save directly — no public policy needed.
CREATE OR REPLACE FUNCTION public.trg_fn_recipe_save_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE recipe SET save_count = save_count + 1 WHERE id = NEW.recipe_id;
    RETURN NEW;
  ELSE
    UPDATE recipe SET save_count = GREATEST(save_count - 1, 0) WHERE id = OLD.recipe_id;
    RETURN OLD;
  END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_recipe_save_count ON recipe_save;
CREATE TRIGGER trg_recipe_save_count
  AFTER INSERT OR DELETE ON recipe_save
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_recipe_save_count();
