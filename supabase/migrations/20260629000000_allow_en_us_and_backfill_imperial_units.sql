-- Migration: Allow 'en-US' in recipe_ingredient_translation and backfill US conversions
-- Date: 2026-06-29

-- 1. Alter locale check constraint to support 'en-US'
ALTER TABLE public.recipe_ingredient_translation 
  DROP CONSTRAINT IF EXISTS recipe_ingredient_translation_locale_check;

ALTER TABLE public.recipe_ingredient_translation 
  ADD CONSTRAINT recipe_ingredient_translation_locale_check 
  CHECK (locale = ANY (ARRAY['fr'::text, 'en'::text, 'es'::text, 'pt'::text, 'wo'::text, 'bm'::text, 'ln'::text, 'ar'::text, 'en-US'::text]));

-- 2. Ensure unique constraint exists on (recipe_ingredient_id, locale)
ALTER TABLE public.recipe_ingredient_translation
  DROP CONSTRAINT IF EXISTS recipe_ingredient_translation_recipe_ingredient_id_locale_key;
ALTER TABLE public.recipe_ingredient_translation
  ADD CONSTRAINT recipe_ingredient_translation_recipe_ingredient_id_locale_key
  UNIQUE (recipe_ingredient_id, locale);

-- 3. Backfill existing recipe ingredients with US conversions
INSERT INTO public.recipe_ingredient_translation (
  recipe_ingredient_id, 
  locale, 
  title, 
  quantity, 
  unit, 
  is_auto, 
  generated_at, 
  updated_at
)
SELECT
  ri.id as recipe_ingredient_id,
  'en-US' as locale,
  NULL as title,
  CASE
    WHEN ri.quantity IS NULL THEN NULL
    WHEN lower(trim(ri.unit)) = 'g' THEN
      CASE
        WHEN ri.quantity < 500 THEN round((ri.quantity / 28.3495) / 0.25) * 0.25
        ELSE round((ri.quantity / 453.592) / 0.25) * 0.25
      END
    WHEN lower(trim(ri.unit)) = 'kg' THEN round((ri.quantity * 2.20462) / 0.25) * 0.25
    WHEN lower(trim(ri.unit)) = 'ml' THEN
      CASE
        WHEN ri.quantity < 15 THEN round((ri.quantity / 5.0) / 0.25) * 0.25
        WHEN ri.quantity < 60 THEN round((ri.quantity / 15.0) / 0.5) * 0.5
        ELSE round((ri.quantity / 29.5735) / 0.5) * 0.5
      END
    WHEN lower(trim(ri.unit)) = 'l' THEN
      CASE
        WHEN ri.quantity > 0.5 THEN round((ri.quantity * 4.227) / 0.25) * 0.25
        ELSE round((ri.quantity * 33.814) / 0.5) * 0.5
      END
    ELSE ri.quantity
  END as quantity,
  CASE
    WHEN ri.quantity IS NULL THEN ri.unit
    WHEN lower(trim(ri.unit)) = 'g' THEN
      CASE
        WHEN ri.quantity < 500 THEN 'oz'
        ELSE 'lb'
      END
    WHEN lower(trim(ri.unit)) = 'kg' THEN 'lb'
    WHEN lower(trim(ri.unit)) = 'ml' THEN
      CASE
        WHEN ri.quantity < 15 THEN 'tsp'
        WHEN ri.quantity < 60 THEN 'tbsp'
        ELSE 'fl_oz'
      END
    WHEN lower(trim(ri.unit)) = 'l' THEN
      CASE
        WHEN ri.quantity > 0.5 THEN 'cup'
        ELSE 'fl_oz'
      END
    ELSE ri.unit
  END as unit,
  true as is_auto,
  now() as generated_at,
  now() as updated_at
FROM public.recipe_ingredient ri
WHERE NOT EXISTS (
  SELECT 1 
  FROM public.recipe_ingredient_translation rit 
  WHERE rit.recipe_ingredient_id = ri.id AND rit.locale = 'en-US'
)
ON CONFLICT (recipe_ingredient_id, locale) DO NOTHING;
