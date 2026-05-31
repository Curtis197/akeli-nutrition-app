-- =============================================================================
-- Fix recipe stats triggers to bypass RLS
-- =============================================================================

-- 1. trg_fn_recipe_comment_stats
CREATE OR REPLACE FUNCTION public.trg_fn_recipe_comment_stats()
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
$function$;

-- 2. trg_fn_recipe_like_count
CREATE OR REPLACE FUNCTION public.trg_fn_recipe_like_count()
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

  IF v_recipe_id IS NOT NULL THEN
    UPDATE public.recipe
    SET like_count = (
      SELECT COUNT(*)
      FROM public.recipe_like
      WHERE recipe_id = v_recipe_id
    )
    WHERE id = v_recipe_id;
  END IF;

  RETURN NULL;
END;
$function$;

-- 3. trg_fn_recipe_rating_stats
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
$function$;
