-- Migration: Allow 'en-US' in recipe_translation and recipe_step_translation, and backfill from 'en'
-- Date: 2026-06-29

-- 1. Alter locale check constraints to support 'en-US' (only if tables exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipe_translation') THEN
    ALTER TABLE public.recipe_translation
      DROP CONSTRAINT IF EXISTS recipe_translation_locale_check;
    ALTER TABLE public.recipe_translation
      ADD CONSTRAINT recipe_translation_locale_check
      CHECK (locale = ANY (ARRAY['fr'::text, 'en'::text, 'es'::text, 'pt'::text, 'wo'::text, 'bm'::text, 'ln'::text, 'ar'::text, 'en-US'::text]));
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipe_step_translation') THEN
    ALTER TABLE public.recipe_step_translation
      DROP CONSTRAINT IF EXISTS recipe_step_translation_locale_check;
    ALTER TABLE public.recipe_step_translation
      ADD CONSTRAINT recipe_step_translation_locale_check
      CHECK (locale = ANY (ARRAY['fr'::text, 'en'::text, 'es'::text, 'pt'::text, 'wo'::text, 'bm'::text, 'ln'::text, 'ar'::text, 'en-US'::text]));
  END IF;
END $$;

-- 2. Backfill recipe_translation for 'en-US' from 'en' (only if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipe_translation') THEN
    INSERT INTO public.recipe_translation (
      recipe_id,
      locale,
      title,
      description,
      is_auto,
      generated_at,
      updated_at
    )
    SELECT
      recipe_id,
      'en-US' as locale,
      title,
      description,
      is_auto,
      generated_at,
      updated_at
    FROM public.recipe_translation
    WHERE locale = 'en'
    AND NOT EXISTS (
      SELECT 1
      FROM public.recipe_translation rt2
      WHERE rt2.recipe_id = public.recipe_translation.recipe_id AND rt2.locale = 'en-US'
    )
    ON CONFLICT (recipe_id, locale) DO NOTHING;
  END IF;
END $$;

-- 3. Backfill recipe_step_translation for 'en-US' from 'en' (only if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipe_step_translation') THEN
    INSERT INTO public.recipe_step_translation (
      step_id,
      locale,
      content,
      title,
      is_auto,
      generated_at,
      updated_at
    )
    SELECT
      step_id,
      'en-US' as locale,
      content,
      title,
      is_auto,
      generated_at,
      updated_at
    FROM public.recipe_step_translation
    WHERE locale = 'en'
    AND NOT EXISTS (
      SELECT 1
      FROM public.recipe_step_translation rst2
      WHERE rst2.step_id = public.recipe_step_translation.step_id AND rst2.locale = 'en-US'
    )
    ON CONFLICT (step_id, locale) DO NOTHING;
  END IF;
END $$;
