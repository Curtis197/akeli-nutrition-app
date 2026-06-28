-- Migration: US Imperial Recipe Units Seed & Trigger
-- Date: 2026-06-28

-- 1. Seed new imperial units
INSERT INTO public.measurement_unit (code, name_fr, name_en) VALUES
  ('oz', 'oz', 'oz'),
  ('lb', 'lb', 'lb'),
  ('fl_oz', 'fl oz', 'fl oz')
ON CONFLICT (code) DO NOTHING;

-- 2. Seed default unit rounding configurations for imperial units
INSERT INTO public.unit_rounding_config (unit, rounding_step) VALUES
  ('oz', 0.25),
  ('lb', 0.25),
  ('fl_oz', 0.5)
ON CONFLICT (unit) DO UPDATE SET rounding_step = EXCLUDED.rounding_step;

-- 3. Ensure recipe_ingredient_translation table exists with required columns
-- (table was created directly on remote; create it locally if missing)
CREATE TABLE IF NOT EXISTS public.recipe_ingredient_translation (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_ingredient_id uuid REFERENCES public.recipe_ingredient(id) ON DELETE CASCADE,
  locale               text NOT NULL,
  quantity             numeric,
  unit                 text,
  title                text,
  is_auto              boolean DEFAULT false,
  generated_at         timestamptz,
  updated_at           timestamptz DEFAULT now()
);
ALTER TABLE public.recipe_ingredient_translation
  ADD COLUMN IF NOT EXISTS quantity numeric,
  ADD COLUMN IF NOT EXISTS unit text;

-- 4. Create trigger function to call the auto-translate edge function on recipe publish
CREATE OR REPLACE FUNCTION public.trg_recipe_auto_translate()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF OLD.is_published = false AND NEW.is_published = true THEN
    PERFORM pg_net.http_post(
      url := current_setting('app.supabase_functions_url') || '/translate-recipe',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-internal-secret', current_setting('app.internal_secret')
      ),
      body := jsonb_build_object('recipe_id', NEW.id)::text
    );
  END IF;
  RETURN NEW;
END;
$$;

-- 5. Bind trigger to recipe table
DROP TRIGGER IF EXISTS trg_recipe_publish_translate ON public.recipe;
CREATE TRIGGER trg_recipe_publish_translate
  AFTER UPDATE OF is_published ON public.recipe
  FOR EACH ROW EXECUTE FUNCTION public.trg_recipe_auto_translate();
