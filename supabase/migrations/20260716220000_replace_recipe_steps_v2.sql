-- supabase/migrations/20260716220000_replace_recipe_steps_v2.sql
-- replace_recipe_steps v2: carry image_url + ingredient_ids (v1 silently dropped them),
-- and add an ownership check (v1 was SECURITY DEFINER with no authorization at all).

-- Drift backfill (local dev only, no-op on prod): prod's recipe_step already has
-- `sort_order` and `is_section_header` columns (added directly on prod at some point,
-- outside any migration committed to this repo -- discovered while implementing this
-- task, same class of gap as the already-documented calories_per_100g/kcal_per_100g
-- drift on recipe_macro). A local DB built via `supabase db reset` from this repo's
-- migration history is missing both columns, which would make the INSERT below fail
-- the moment `replace_recipe_steps` is actually called locally. Guarded by
-- IF NOT EXISTS with the same type/default/nullability prod already has, so on prod
-- this is a verified no-op and on local it closes the gap.
ALTER TABLE public.recipe_step ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;
ALTER TABLE public.recipe_step ADD COLUMN IF NOT EXISTS is_section_header boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.replace_recipe_steps(p_recipe_id uuid, p_steps jsonb)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_count integer;
  v_role  text := COALESCE(auth.jwt() ->> 'role', 'none'); -- 'none' = direct DB connection (psql, cron, tests)
BEGIN
  IF v_role NOT IN ('service_role', 'none') THEN
    IF NOT EXISTS (
      SELECT 1 FROM recipe r
      JOIN creator c ON c.id = r.creator_id
      WHERE r.id = p_recipe_id AND c.user_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'replace_recipe_steps: caller does not own recipe %', p_recipe_id
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  IF p_steps IS NULL OR jsonb_typeof(p_steps) <> 'array' OR jsonb_array_length(p_steps) = 0 THEN
    RAISE EXCEPTION 'replace_recipe_steps: p_steps must be a non-empty JSON array';
  END IF;

  DELETE FROM public.recipe_step WHERE recipe_id = p_recipe_id;

  INSERT INTO public.recipe_step
    (recipe_id, step_number, sort_order, title, content, image_url, timer_seconds, is_section_header, ingredient_ids)
  SELECT
    p_recipe_id,
    (s->>'step_number')::int,
    (s->>'sort_order')::int,
    NULLIF(s->>'title', ''),
    NULLIF(s->>'content', ''),
    NULLIF(s->>'image_url', ''),
    NULLIF(s->>'timer_seconds', '')::int,
    COALESCE((s->>'is_section_header')::boolean, false),
    COALESCE(
      (SELECT array_agg(x::uuid) FROM jsonb_array_elements_text(s->'ingredient_ids') AS x),
      '{}'::uuid[]
    )
  FROM jsonb_array_elements(p_steps) AS s;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$;
