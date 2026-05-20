# Language Selection Feature — Implementation Plan

**Date:** March 2026  
**Branch:** language-selection  
**Related:** [LANGUAGE_SELECTION_AUDIT.md](./LANGUAGE_SELECTION_AUDIT.md)  
**Status:** Ready for implementation

---

## Overview

This document details the implementation of a comprehensive language selection system for Akeli V1. The system will:

1. Store all static UI text in a database-backed translation table
2. Render recipes in the user's selected language (with AI-assisted translation)
3. Support feed and meal planner content in multiple languages
4. Enable seamless language switching across Flutter, SQL, and Edge Functions

**Supported Languages (Phase 1):** French (fr), English (en), Spanish (es), Portuguese (pt)  
**Supported Languages (Phase 2):** Wolof (wo), Bambara (bm), Lingala (ln)

---

## Phase 1: Database Schema & Infrastructure

### 1.1 Migration: i18n Schema

**File:** `supabase/migrations/20260301000003_i18n_schema.sql`

```sql
-- =============================================================================
-- AKELI V1 — Internationalization (i18n) Schema
-- Migration: 20260301000003_i18n_schema.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. supported_language — Master language reference table
-- ---------------------------------------------------------------------------

CREATE TABLE supported_language (
  code          text PRIMARY KEY,           -- ISO 639-1: 'fr', 'en', 'wo', etc.
  name_native   text NOT NULL,              -- Native name: 'Français', 'English'
  name_en       text NOT NULL,              -- English name for admin UI
  direction     text DEFAULT 'ltr',         -- 'ltr' or 'rtl'
  is_active     boolean DEFAULT true,       -- Enable/disable without deletion
  is_default    boolean DEFAULT false,      -- One language should be default
  sort_order    int DEFAULT 0,              -- Display order in selector
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE supported_language ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads active languages" ON supported_language
  FOR SELECT USING (is_active = true);

-- Insert initial languages
INSERT INTO supported_language (code, name_native, name_en, is_default, sort_order) VALUES
  ('fr', 'Français', 'French', true, 1),
  ('en', 'English', 'English', false, 2),
  ('es', 'Español', 'Spanish', false, 3),
  ('pt', 'Português', 'Portuguese', false, 4),
  ('wo', 'Wolof', 'Wolof', false, 5),
  ('bm', 'Bamanankan', 'Bambara', false, 6),
  ('ln', 'Lingála', 'Lingala', false, 7)
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. app_translation_key — Centralized translation keys
-- ---------------------------------------------------------------------------

CREATE TABLE app_translation_key (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key_name      text NOT NULL UNIQUE,       -- e.g., 'nav.home', 'btn.submit'
  namespace     text DEFAULT 'common',      -- Grouping: 'common', 'errors', 'recipe', etc.
  description   text,                       -- Context for translators
  is_active     boolean DEFAULT true,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

CREATE INDEX idx_app_translation_key_namespace ON app_translation_key(namespace);

ALTER TABLE app_translation_key ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads translations" ON app_translation_key
  FOR SELECT USING (is_active = true);

-- Trigger for updated_at
CREATE TRIGGER trg_app_translation_key_updated_at
  BEFORE UPDATE ON app_translation_key
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- 3. app_translation — Translations by language
-- ---------------------------------------------------------------------------

CREATE TABLE app_translation (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  translation_key_id uuid REFERENCES app_translation_key(id) ON DELETE CASCADE,
  language_code   text REFERENCES supported_language(code),
  value           text NOT NULL,            -- Translated text
  is_machine_translated boolean DEFAULT false,
  reviewed_by     uuid REFERENCES user_profile(id),
  reviewed_at     timestamptz,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (translation_key_id, language_code)
);

CREATE INDEX idx_app_translation_language ON app_translation(language_code);
CREATE INDEX idx_app_translation_key ON app_translation(translation_key_id);

ALTER TABLE app_translation ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads translations" ON app_translation
  FOR SELECT USING (true);

-- Only admins/creators can update translations (RLS policy to be refined)
CREATE POLICY "authenticated manages translations" ON app_translation
  FOR ALL USING (auth.role() = 'authenticated');

CREATE TRIGGER trg_app_translation_updated_at
  BEFORE UPDATE ON app_translation
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- 4. recipe_translation — Recipe content translations (1:N)
-- ---------------------------------------------------------------------------

CREATE TABLE recipe_translation (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id       uuid REFERENCES recipe(id) ON DELETE CASCADE,
  language_code   text REFERENCES supported_language(code),
  title           text NOT NULL,
  description     text,
  instructions    text NOT NULL,
  is_original     boolean DEFAULT false,    -- True if this is the source language
  is_machine_translated boolean DEFAULT false,
  translated_by   uuid REFERENCES user_profile(id),
  translated_at   timestamptz,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (recipe_id, language_code)
);

CREATE INDEX idx_recipe_translation_recipe ON recipe_translation(recipe_id);
CREATE INDEX idx_recipe_translation_language ON recipe_translation(language_code);

ALTER TABLE recipe_translation ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe translations" ON recipe_translation
  FOR SELECT USING (true);

-- Creators can manage translations for their own recipes
CREATE POLICY "creator manages recipe translations" ON recipe_translation
  USING (
    recipe_id IN (
      SELECT r.id FROM recipe r
      JOIN creator c ON r.creator_id = c.id
      WHERE c.user_id = auth.uid()
    )
  );

CREATE TRIGGER trg_recipe_translation_updated_at
  BEFORE UPDATE ON recipe_translation
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- 5. Update existing tables for better i18n support
-- ---------------------------------------------------------------------------

-- Add fallback chain to user_profile
ALTER TABLE user_profile 
  ADD COLUMN locale_fallback text DEFAULT 'fr' 
  REFERENCES supported_language(code);

-- Set fallback for existing users
UPDATE user_profile SET locale_fallback = 'fr' WHERE locale_fallback IS NULL;

-- ---------------------------------------------------------------------------
-- 6. Helper Functions
-- ---------------------------------------------------------------------------

-- Get translation with fallback
CREATE OR REPLACE FUNCTION get_app_translation(
  p_key_name text,
  p_language_code text DEFAULT 'fr'
)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_value text;
  v_fallback text := 'fr';  -- Default fallback
BEGIN
  -- Try requested language
  SELECT at.value INTO v_value
  FROM app_translation at
  JOIN app_translation_key atk ON at.translation_key_id = atk.id
  WHERE atk.key_name = p_key_name
    AND at.language_code = p_language_code
    AND atk.is_active = true;
  
  -- Fallback to French if not found
  IF v_value IS NULL THEN
    SELECT at.value INTO v_value
    FROM app_translation at
    JOIN app_translation_key atk ON at.translation_key_id = atk.id
    WHERE atk.key_name = p_key_name
      AND at.language_code = v_fallback
      AND atk.is_active = true;
  END IF;
  
  -- Return key name as last resort (for debugging)
  RETURN COALESCE(v_value, p_key_name);
END;
$$;

-- Get recipe content in preferred language with fallback
CREATE OR REPLACE FUNCTION get_recipe_content(
  p_recipe_id uuid,
  p_language_code text DEFAULT 'fr'
)
RETURNS TABLE (
  title text,
  description text,
  instructions text,
  language_code text,
  is_translated boolean
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_recipe_lang text;
BEGIN
  -- Get original recipe language
  SELECT r.language INTO v_recipe_lang
  FROM recipe r WHERE r.id = p_recipe_id;
  
  -- Try to get translation
  RETURN QUERY
  SELECT 
    COALESCE(rt.title, r.title) AS title,
    COALESCE(rt.description, r.description) AS description,
    COALESCE(rt.instructions, r.instructions) AS instructions,
    COALESCE(rt.language_code, r.language) AS language_code,
    (rt.id IS NOT NULL) AS is_translated
  FROM recipe r
  LEFT JOIN recipe_translation rt 
    ON rt.recipe_id = r.id 
    AND rt.language_code = p_language_code
  WHERE r.id = p_recipe_id;
END;
$$;

-- Bulk fetch translations for app initialization
CREATE OR REPLACE FUNCTION get_all_app_translations(
  p_language_code text DEFAULT 'fr'
)
RETURNS TABLE (
  key_name text,
  namespace text,
  value text
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    atk.key_name,
    atk.namespace,
    COALESCE(
      at_primary.value,
      at_fallback.value,
      atk.key_name
    ) AS value
  FROM app_translation_key atk
  LEFT JOIN app_translation at_primary 
    ON at_primary.translation_key_id = atk.id 
    AND at_primary.language_code = p_language_code
  LEFT JOIN app_translation at_fallback 
    ON at_fallback.translation_key_id = atk.id 
    AND at_fallback.language_code = 'fr'
  WHERE atk.is_active = true;
END;
$$;

```

---

### 1.2 Seed Data: Initial Translations

**File:** `supabase/seed/02_app_translations.sql`

```sql
-- =============================================================================
-- AKELI V1 — Seed: Initial App Translations
-- File: 02_app_translations.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Translation Keys & Values
-- ---------------------------------------------------------------------------

-- Navigation
INSERT INTO app_translation_key (key_name, namespace, description) VALUES
  ('nav.home', 'navigation', 'Home tab label'),
  ('nav.meal_planner', 'navigation', 'Meal Planner tab label'),
  ('nav.discover', 'navigation', 'Recipe Discovery tab label'),
  ('nav.community', 'navigation', 'Community tab label'),
  ('nav.settings', 'navigation', 'Settings tab label'),
  ('nav.profile', 'navigation', 'Profile tab label')
ON CONFLICT (key_name) DO NOTHING;

-- Common UI
INSERT INTO app_translation_key (key_name, namespace, description) VALUES
  ('btn.save', 'common', 'Save button'),
  ('btn.cancel', 'common', 'Cancel button'),
  ('btn.delete', 'common', 'Delete button'),
  ('btn.edit', 'common', 'Edit button'),
  ('btn.submit', 'common', 'Submit button'),
  ('btn.search', 'common', 'Search button'),
  ('btn.filter', 'common', 'Filter button'),
  ('lbl.loading', 'common', 'Loading label'),
  ('lbl.error', 'common', 'Error label'),
  ('lbl.success', 'common', 'Success label')
ON CONFLICT (key_name) DO NOTHING;

-- Recipe related
INSERT INTO app_translation_key (key_name, namespace, description) VALUES
  ('recipe.ingredients', 'recipe', 'Ingredients section title'),
  ('recipe.instructions', 'recipe', 'Instructions section title'),
  ('recipe.prep_time', 'recipe', 'Preparation time label'),
  ('recipe.cook_time', 'recipe', 'Cooking time label'),
  ('recipe.servings', 'recipe', 'Servings label'),
  ('recipe.difficulty', 'recipe', 'Difficulty label'),
  ('recipe.calories', 'recipe', 'Calories label'),
  ('recipe.protein', 'recipe', 'Protein label'),
  ('recipe.add_to_plan', 'recipe', 'Add to meal plan button'),
  ('recipe.like', 'recipe', 'Like recipe button'),
  ('recipe.share', 'recipe', 'Share recipe button')
ON CONFLICT (key_name) DO NOTHING;

-- Meal Planner
INSERT INTO app_translation_key (key_name, namespace, description) VALUES
  ('meal.breakfast', 'meal_types', 'Breakfast'),
  ('meal.lunch', 'meal_types', 'Lunch'),
  ('meal.dinner', 'meal_types', 'Dinner'),
  ('meal.snack', 'meal_types', 'Snack'),
  ('meal_plan.generate', 'meal_planner', 'Generate meal plan button'),
  ('meal_plan.shopping_list', 'meal_planner', 'Shopping list button'),
  ('meal_plan.week', 'meal_planner', 'Week label')
ON CONFLICT (key_name) DO NOTHING;

-- Errors
INSERT INTO app_translation_key (key_name, namespace, description) VALUES
  ('error.network', 'errors', 'Network error message'),
  ('error.unauthorized', 'errors', 'Unauthorized error'),
  ('error.not_found', 'errors', 'Resource not found'),
  ('error.server', 'errors', 'Server error'),
  ('error.validation', 'errors', 'Validation error')
ON CONFLICT (key_name) DO NOTHING;

-- Now insert French translations (default language)
INSERT INTO app_translation (translation_key_id, language_code, value)
SELECT ak.id, 'fr', CASE ak.key_name
  -- Navigation
  WHEN 'nav.home' THEN 'Accueil'
  WHEN 'nav.meal_planner' THEN 'Meal Planner'
  WHEN 'nav.discover' THEN 'Découvrir'
  WHEN 'nav.community' THEN 'Communauté'
  WHEN 'nav.settings' THEN 'Paramètres'
  WHEN 'nav.profile' THEN 'Profil'
  -- Common
  WHEN 'btn.save' THEN 'Enregistrer'
  WHEN 'btn.cancel' THEN 'Annuler'
  WHEN 'btn.delete' THEN 'Supprimer'
  WHEN 'btn.edit' THEN 'Modifier'
  WHEN 'btn.submit' THEN 'Valider'
  WHEN 'btn.search' THEN 'Rechercher'
  WHEN 'btn.filter' THEN 'Filtrer'
  WHEN 'lbl.loading' THEN 'Chargement...'
  WHEN 'lbl.error' THEN 'Erreur'
  WHEN 'lbl.success' THEN 'Succès'
  -- Recipe
  WHEN 'recipe.ingredients' THEN 'Ingrédients'
  WHEN 'recipe.instructions' THEN 'Instructions'
  WHEN 'recipe.prep_time' THEN 'Préparation'
  WHEN 'recipe.cook_time' THEN 'Cuisson'
  WHEN 'recipe.servings' THEN 'Portions'
  WHEN 'recipe.difficulty' THEN 'Difficulté'
  WHEN 'recipe.calories' THEN 'Calories'
  WHEN 'recipe.protein' THEN 'Protéines'
  WHEN 'recipe.add_to_plan' THEN 'Ajouter au planning'
  WHEN 'recipe.like' THEN 'J''aime'
  WHEN 'recipe.share' THEN 'Partager'
  -- Meal types
  WHEN 'meal.breakfast' THEN 'Petit-déjeuner'
  WHEN 'meal.lunch' THEN 'Déjeuner'
  WHEN 'meal.dinner' THEN 'Dîner'
  WHEN 'meal.snack' THEN 'Collation'
  WHEN 'meal_plan.generate' THEN 'Générer un planning'
  WHEN 'meal_plan.shopping_list' THEN 'Liste de courses'
  WHEN 'meal_plan.week' THEN 'Semaine'
  -- Errors
  WHEN 'error.network' THEN 'Erreur de connexion'
  WHEN 'error.unauthorized' THEN 'Non autorisé'
  WHEN 'error.not_found' THEN 'Non trouvé'
  WHEN 'error.server' THEN 'Erreur serveur'
  WHEN 'error.validation' THEN 'Erreur de validation'
  ELSE ak.key_name
END
FROM app_translation_key ak
ON CONFLICT (translation_key_id, language_code) DO NOTHING;

-- English translations
INSERT INTO app_translation (translation_key_id, language_code, value)
SELECT ak.id, 'en', CASE ak.key_name
  WHEN 'nav.home' THEN 'Home'
  WHEN 'nav.meal_planner' THEN 'Meal Planner'
  WHEN 'nav.discover' THEN 'Discover'
  WHEN 'nav.community' THEN 'Community'
  WHEN 'nav.settings' THEN 'Settings'
  WHEN 'nav.profile' THEN 'Profile'
  WHEN 'btn.save' THEN 'Save'
  WHEN 'btn.cancel' THEN 'Cancel'
  WHEN 'btn.delete' THEN 'Delete'
  WHEN 'btn.edit' THEN 'Edit'
  WHEN 'btn.submit' THEN 'Submit'
  WHEN 'btn.search' THEN 'Search'
  WHEN 'btn.filter' THEN 'Filter'
  WHEN 'lbl.loading' THEN 'Loading...'
  WHEN 'lbl.error' THEN 'Error'
  WHEN 'lbl.success' THEN 'Success'
  WHEN 'recipe.ingredients' THEN 'Ingredients'
  WHEN 'recipe.instructions' THEN 'Instructions'
  WHEN 'recipe.prep_time' THEN 'Prep Time'
  WHEN 'recipe.cook_time' THEN 'Cook Time'
  WHEN 'recipe.servings' THEN 'Servings'
  WHEN 'recipe.difficulty' THEN 'Difficulty'
  WHEN 'recipe.calories' THEN 'Calories'
  WHEN 'recipe.protein' THEN 'Protein'
  WHEN 'recipe.add_to_plan' THEN 'Add to Plan'
  WHEN 'recipe.like' THEN 'Like'
  WHEN 'recipe.share' THEN 'Share'
  WHEN 'meal.breakfast' THEN 'Breakfast'
  WHEN 'meal.lunch' THEN 'Lunch'
  WHEN 'meal.dinner' THEN 'Dinner'
  WHEN 'meal.snack' THEN 'Snack'
  WHEN 'meal_plan.generate' THEN 'Generate Plan'
  WHEN 'meal_plan.shopping_list' THEN 'Shopping List'
  WHEN 'meal_plan.week' THEN 'Week'
  WHEN 'error.network' THEN 'Network error'
  WHEN 'error.unauthorized' THEN 'Unauthorized'
  WHEN 'error.not_found' THEN 'Not found'
  WHEN 'error.server' THEN 'Server error'
  WHEN 'error.validation' THEN 'Validation error'
  ELSE ak.key_name
END
FROM app_translation_key ak
ON CONFLICT (translation_key_id, language_code) DO NOTHING;

-- Spanish translations
INSERT INTO app_translation (translation_key_id, language_code, value)
SELECT ak.id, 'es', CASE ak.key_name
  WHEN 'nav.home' THEN 'Inicio'
  WHEN 'nav.meal_planner' THEN 'Planificador'
  WHEN 'nav.discover' THEN 'Descubrir'
  WHEN 'nav.community' THEN 'Comunidad'
  WHEN 'nav.settings' THEN 'Configuración'
  WHEN 'nav.profile' THEN 'Perfil'
  WHEN 'btn.save' THEN 'Guardar'
  WHEN 'btn.cancel' THEN 'Cancelar'
  WHEN 'btn.delete' THEN 'Eliminar'
  WHEN 'btn.edit' THEN 'Editar'
  WHEN 'btn.submit' THEN 'Enviar'
  WHEN 'btn.search' THEN 'Buscar'
  WHEN 'btn.filter' THEN 'Filtrar'
  WHEN 'lbl.loading' THEN 'Cargando...'
  WHEN 'lbl.error' THEN 'Error'
  WHEN 'lbl.success' THEN 'Éxito'
  WHEN 'recipe.ingredients' THEN 'Ingredientes'
  WHEN 'recipe.instructions' THEN 'Instrucciones'
  WHEN 'recipe.prep_time' THEN 'Tiempo de preparación'
  WHEN 'recipe.cook_time' THEN 'Tiempo de cocción'
  WHEN 'recipe.servings' THEN 'Porciones'
  WHEN 'recipe.difficulty' THEN 'Dificultad'
  WHEN 'recipe.calories' THEN 'Calorías'
  WHEN 'recipe.protein' THEN 'Proteínas'
  WHEN 'recipe.add_to_plan' THEN 'Añadir al plan'
  WHEN 'recipe.like' THEN 'Me gusta'
  WHEN 'recipe.share' THEN 'Compartir'
  WHEN 'meal.breakfast' THEN 'Desayuno'
  WHEN 'meal.lunch' THEN 'Almuerzo'
  WHEN 'meal.dinner' THEN 'Cena'
  WHEN 'meal.snack' THEN 'Merienda'
  WHEN 'meal_plan.generate' THEN 'Generar plan'
  WHEN 'meal_plan.shopping_list' THEN 'Lista de compras'
  WHEN 'meal_plan.week' THEN 'Semana'
  WHEN 'error.network' THEN 'Error de red'
  WHEN 'error.unauthorized' THEN 'No autorizado'
  WHEN 'error.not_found' THEN 'No encontrado'
  WHEN 'error.server' THEN 'Error del servidor'
  WHEN 'error.validation' THEN 'Error de validación'
  ELSE ak.key_name
END
FROM app_translation_key ak
ON CONFLICT (translation_key_id, language_code) DO NOTHING;

-- Portuguese translations
INSERT INTO app_translation (translation_key_id, language_code, value)
SELECT ak.id, 'pt', CASE ak.key_name
  WHEN 'nav.home' THEN 'Início'
  WHEN 'nav.meal_planner' THEN 'Planejador'
  WHEN 'nav.discover' THEN 'Descobrir'
  WHEN 'nav.community' THEN 'Comunidade'
  WHEN 'nav.settings' THEN 'Configurações'
  WHEN 'nav.profile' THEN 'Perfil'
  WHEN 'btn.save' THEN 'Salvar'
  WHEN 'btn.cancel' THEN 'Cancelar'
  WHEN 'btn.delete' THEN 'Excluir'
  WHEN 'btn.edit' THEN 'Editar'
  WHEN 'btn.submit' THEN 'Enviar'
  WHEN 'btn.search' THEN 'Buscar'
  WHEN 'btn.filter' THEN 'Filtrar'
  WHEN 'lbl.loading' THEN 'Carregando...'
  WHEN 'lbl.error' THEN 'Erro'
  WHEN 'lbl.success' THEN 'Sucesso'
  WHEN 'recipe.ingredients' THEN 'Ingredientes'
  WHEN 'recipe.instructions' THEN 'Instruções'
  WHEN 'recipe.prep_time' THEN 'Tempo de preparo'
  WHEN 'recipe.cook_time' THEN 'Tempo de cozimento'
  WHEN 'recipe.servings' THEN 'Porções'
  WHEN 'recipe.difficulty' THEN 'Dificuldade'
  WHEN 'recipe.calories' THEN 'Calorias'
  WHEN 'recipe.protein' THEN 'Proteínas'
  WHEN 'recipe.add_to_plan' THEN 'Adicionar ao plano'
  WHEN 'recipe.like' THEN 'Curtir'
  WHEN 'recipe.share' THEN 'Compartilhar'
  WHEN 'meal.breakfast' THEN 'Café da manhã'
  WHEN 'meal.lunch' THEN 'Almoço'
  WHEN 'meal.dinner' THEN 'Jantar'
  WHEN 'meal.snack' THEN 'Lanche'
  WHEN 'meal_plan.generate' THEN 'Gerar plano'
  WHEN 'meal_plan.shopping_list' THEN 'Lista de compras'
  WHEN 'meal_plan.week' THEN 'Semana'
  WHEN 'error.network' THEN 'Erro de rede'
  WHEN 'error.unauthorized' THEN 'Não autorizado'
  WHEN 'error.not_found' THEN 'Não encontrado'
  WHEN 'error.server' THEN 'Erro do servidor'
  WHEN 'error.validation' THEN 'Erro de validação'
  ELSE ak.key_name
END
FROM app_translation_key ak
ON CONFLICT (translation_key_id, language_code) DO NOTHING;

```

---

### 1.3 Update RPC Functions for Language Support

**File:** `supabase/migrations/20260301000004_update_rpc_for_i18n.sql`

```sql
-- =============================================================================
-- AKELI V1 — Update RPC Functions for i18n Support
-- Migration: 20260301000004_update_rpc_for_i18n.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Update recommend_recipes to accept language parameter
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION recommend_recipes(
  p_user_id       uuid,
  p_limit         int     DEFAULT 20,
  p_offset        int     DEFAULT 0,
  p_region        text    DEFAULT NULL,
  p_difficulty    text    DEFAULT NULL,
  p_max_time      int     DEFAULT NULL,
  p_language_code text    DEFAULT 'fr'  -- NEW PARAMETER
)
RETURNS TABLE (
  id              uuid,
  title           text,      -- Will be translated
  description     text,      -- Will be translated
  cover_image_url text,
  region          text,
  difficulty      text,
  prep_time_min   int,
  cook_time_min   int,
  servings        int,
  creator_id      uuid,
  creator_name    text,
  creator_avatar  text,
  calories        numeric,
  protein_g       numeric,
  like_count      bigint,
  similarity      float,
  language_code   text       -- NEW: actual language returned
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
  v_fan_creator_id uuid;
BEGIN
  -- Get user vector
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv
  WHERE uv.user_id = p_user_id;

  -- Get active Fan creator
  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  -- Cold start fallback
  IF v_user_vector IS NULL THEN
    RETURN QUERY
    SELECT
      r.id,
      COALESCE(rt.title, r.title),
      COALESCE(rt.description, r.description),
      r.cover_image_url,
      r.region,
      r.difficulty,
      r.prep_time_min,
      r.cook_time_min,
      r.servings,
      r.creator_id,
      c.display_name,
      c.avatar_url,
      rm.calories,
      rm.protein_g,
      COUNT(rl.recipe_id)::bigint AS like_count,
      0.5::float AS similarity,
      COALESCE(rt.language_code, r.language)
    FROM recipe r
    LEFT JOIN creator c ON r.creator_id = c.id
    LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
    LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
    LEFT JOIN recipe_translation rt 
      ON rt.recipe_id = r.id AND rt.language_code = p_language_code
    WHERE r.is_published = true
      AND (p_region IS NULL OR r.region = p_region)
      AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
      AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, rt.title, rt.description, rt.language_code
    ORDER BY like_count DESC
    LIMIT p_limit
    OFFSET p_offset;
    RETURN;
  END IF;

  -- Vectorized feed with Fan boost
  RETURN QUERY
  SELECT
    r.id,
    COALESCE(rt.title, r.title),
    COALESCE(rt.description, r.description),
    r.cover_image_url,
    r.region,
    r.difficulty,
    r.prep_time_min,
    r.cook_time_min,
    r.servings,
    r.creator_id,
    c.display_name,
    c.avatar_url,
    rm.calories,
    rm.protein_g,
    COUNT(rl.recipe_id)::bigint AS like_count,
    (1 - (rv.vector <=> v_user_vector)) *
      CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
        THEN 1.5 ELSE 1.0 END AS similarity,
    COALESCE(rt.language_code, r.language)
  FROM recipe r
  JOIN recipe_vector rv ON r.id = rv.recipe_id
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  LEFT JOIN recipe_translation rt 
    ON rt.recipe_id = r.id AND rt.language_code = p_language_code
  WHERE r.is_published = true
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, rv.vector, v_fan_creator_id, rt.title, rt.description, rt.language_code
  ORDER BY similarity DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. Update search_recipes to accept language parameter
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION search_recipes(
  p_query         text    DEFAULT NULL,
  p_region        text    DEFAULT NULL,
  p_difficulty    text    DEFAULT NULL,
  p_tag_ids       uuid[]  DEFAULT NULL,
  p_max_time      int     DEFAULT NULL,
  p_order_by      text    DEFAULT 'recent',
  p_limit         int     DEFAULT 20,
  p_offset        int     DEFAULT 0,
  p_language_code text    DEFAULT 'fr'  -- NEW PARAMETER
)
RETURNS TABLE (
  id              uuid,
  title           text,
  description     text,
  cover_image_url text,
  region          text,
  difficulty      text,
  prep_time_min   int,
  cook_time_min   int,
  servings        int,
  creator_id      uuid,
  creator_name    text,
  creator_avatar  text,
  calories        numeric,
  like_count      bigint,
  created_at      timestamptz,
  language_code   text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    COALESCE(rt.title, r.title),
    COALESCE(rt.description, r.description),
    r.cover_image_url,
    r.region,
    r.difficulty,
    r.prep_time_min,
    r.cook_time_min,
    r.servings,
    r.creator_id,
    c.display_name,
    c.avatar_url,
    rm.calories,
    COUNT(rl.recipe_id)::bigint AS like_count,
    r.created_at,
    COALESCE(rt.language_code, r.language)
  FROM recipe r
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  LEFT JOIN recipe_translation rt 
    ON rt.recipe_id = r.id AND rt.language_code = p_language_code
  WHERE r.is_published = true
    AND (p_query IS NULL OR (
      COALESCE(rt.title, r.title) ILIKE '%' || p_query || '%' OR
      COALESCE(rt.description, r.description) ILIKE '%' || p_query || '%'
    ))
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    AND (p_tag_ids IS NULL OR (
      SELECT COUNT(*) FROM recipe_tag rt
      WHERE rt.recipe_id = r.id AND rt.tag_id = ANY(p_tag_ids)
    ) = array_length(p_tag_ids, 1))
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rt.title, rt.description, rt.language_code
  ORDER BY
    CASE WHEN p_order_by = 'popular' THEN COUNT(rl.recipe_id) END DESC,
    CASE WHEN p_order_by = 'quick'   THEN COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0) END ASC,
    CASE WHEN p_order_by = 'recent' OR p_order_by IS NULL THEN r.created_at END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. Update generate_meal_plan to accept language parameter
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id       uuid,
  p_days          int     DEFAULT 7,
  p_meals_per_day int     DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE,
  p_language_code text    DEFAULT 'fr'  -- NEW PARAMETER
)
RETURNS TABLE (
  meal_plan_id    uuid,
  entry_id        uuid,
  scheduled_date  date,
  meal_type       text,
  recipe_id       uuid,
  recipe_title    text,      -- Translated
  cover_image_url text,
  calories        numeric,
  protein_g       numeric,
  similarity      float,
  language_code   text       -- NEW
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
-- [Implementation similar to above - omitted for brevity]
-- Key change: JOIN recipe_translation and use COALESCE(rt.title, r.title)
$$;

```

---

## Phase 2: Flutter Implementation

### 2.1 Dependencies

**File:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  supabase_flutter: ^2.3.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### 2.2 Directory Structure

```
lib/
├── core/
│   ├── localization/
│   │   ├── app_locale.dart           # Locale model
│   │   ├── translation_service.dart  # Supabase integration
│   │   ├── locale_provider.dart      # Provider/Notifier
│   │   └── locale_selector.dart      # UI widget
│   │
├── generated/
│   └── l10n/                         # Optional: if using ARB files
│
├── main.dart                         # Updated with localization
```

### 2.3 Core Files

**File:** `lib/core/localization/app_locale.dart`

```dart
import 'package:flutter/material.dart';

class AppLocale {
  final String code;
  final String nameNative;
  final String nameEn;
  final TextDirection direction;

  const AppLocale({
    required this.code,
    required this.nameNative,
    required this.nameEn,
    this.direction = TextDirection.ltr,
  });

  Locale get locale => Locale(code);

  static const fr = AppLocale(
    code: 'fr',
    nameNative: 'Français',
    nameEn: 'French',
  );

  static const en = AppLocale(
    code: 'en',
    nameNative: 'English',
    nameEn: 'English',
  );

  static const es = AppLocale(
    code: 'es',
    nameNative: 'Español',
    nameEn: 'Spanish',
  );

  static const pt = AppLocale(
    code: 'pt',
    nameNative: 'Português',
    nameEn: 'Portuguese',
  );

  static const wo = AppLocale(
    code: 'wo',
    nameNative: 'Wolof',
    nameEn: 'Wolof',
  );

  static const bm = AppLocale(
    code: 'bm',
    nameNative: 'Bamanankan',
    nameEn: 'Bambara',
  );

  static const ln = AppLocale(
    code: 'ln',
    nameNative: 'Lingála',
    nameEn: 'Lingala',
  );

  static const List<AppLocale> supported = [
    fr,
    en,
    es,
    pt,
    // wo, bm, ln - Phase 2
  ];

  static AppLocale fromCode(String code) {
    return supported.firstWhere(
      (locale) => locale.code == code,
      orElse: () => fr,
    );
  }
}
```

**File:** `lib/core/localization/translation_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class TranslationService {
  final SupabaseClient _client;
  
  // Cache to avoid repeated calls
  final Map<String, Map<String, String>> _translationCache = {};

  TranslationService(this._client);

  /// Fetch all translations for a language
  Future<Map<String, String>> loadTranslations(String languageCode) async {
    // Check cache first
    if (_translationCache.containsKey(languageCode)) {
      return _translationCache[languageCode]!;
    }

    try {
      final response = await _client.rpc(
        'get_all_app_translations',
        params: {'p_language_code': languageCode},
      );

      final translations = <String, String>{};
      
      if (response is List) {
        for (var item in response) {
          translations[item['key_name'] as String] = item['value'] as String;
        }
      }

      _translationCache[languageCode] = translations;
      return translations;
    } catch (e) {
      // Fallback to French if error
      if (languageCode != 'fr') {
        return loadTranslations('fr');
      }
      rethrow;
    }
  }

  /// Get a single translation with fallback
  Future<String> translate(String key, String languageCode) async {
    final translations = await loadTranslations(languageCode);
    return translations[key] ?? key;
  }

  /// Clear cache (useful after language switch or update)
  void clearCache() {
    _translationCache.clear();
  }

  /// Clear cache for specific language
  void clearCacheFor(String languageCode) {
    _translationCache.remove(languageCode);
  }
}
```

**File:** `lib/core/localization/locale_provider.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_locale.dart';
import 'translation_service.dart';

class LocaleProvider extends ChangeNotifier {
  AppLocale _currentLocale = AppLocale.fr;
  TranslationService? _translationService;
  Map<String, String> _translations = {};
  bool _isLoading = false;

  LocaleProvider() {
    _loadSavedLocale();
  }

  AppLocale get currentLocale => _currentLocale;
  Locale get locale => _currentLocale.locale;
  Map<String, String> get translations => _translations;
  bool get isLoading => _isLoading;

  String t(String key) {
    return _translations[key] ?? key;
  }

  Future<void> initialize(SupabaseClient client) async {
    _translationService = TranslationService(client);
    await _loadTranslations();
  }

  Future<void> setLocale(AppLocale newLocale) async {
    if (newLocale.code == _currentLocale.code) return;

    _currentLocale = newLocale;
    _isLoading = true;
    notifyListeners();

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.code);

    // Update backend if user logged in
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('user_profile')
          .update({'locale': newLocale.code})
          .eq('id', user.id);
    }

    // Load new translations
    await _loadTranslations();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('locale');
    
    if (savedCode != null && savedCode.isNotEmpty) {
      _currentLocale = AppLocale.fromCode(savedCode);
      notifyListeners();
    }
  }

  Future<void> _loadTranslations() async {
    if (_translationService == null) return;

    try {
      _translations = await _translationService!
          .loadTranslations(_currentLocale.code);
    } catch (e) {
      print('Error loading translations: $e');
      _translations = {};
    }
  }
}
```

**File:** `lib/core/localization/locale_selector.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_locale.dart';
import 'locale_provider.dart';

class LocaleSelector extends StatelessWidget {
  const LocaleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AppLocale>(
      value: context.watch<LocaleProvider>().currentLocale,
      underline: const SizedBox(),
      items: AppLocale.supported.map((locale) {
        return DropdownMenuItem(
          value: locale,
          child: Row(
            children: [
              Text(locale.nameNative),
              if (locale.code != locale.nameEn.toLowerCase().substring(0, 2))
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '(${locale.nameEn})',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      onChanged: (locale) {
        if (locale != null) {
          context.read<LocaleProvider>().setLocale(locale);
        }
      },
    );
  }
}
```

### 2.4 Update main.dart

**File:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/localization/app_locale.dart';
import 'core/localization/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const AkeliApp());
}

class AkeliApp extends StatelessWidget {
  const AkeliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Akeli',
            debugShowCheckedModeBanner: false,
            
            // Localization setup
            locale: localeProvider.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocale.supported
                .map((l) => Locale(l.code))
                .toList(),
            
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepOrange,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepOrange,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final t = localeProvider.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('nav.home')),
        actions: [
          // Language selector in app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: DropdownButton<AppLocale>(
                value: localeProvider.currentLocale,
                underline: const SizedBox(),
                items: AppLocale.supported.map((locale) {
                  return DropdownMenuItem(
                    value: locale,
                    child: Text(locale.code.toUpperCase()),
                  );
                }).toList(),
                onChanged: (locale) {
                  if (locale != null) {
                    localeProvider.setLocale(locale);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t('lbl.loading')),
            const SizedBox(height: 16),
            Text('Current: ${localeProvider.currentLocale.nameNative}'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: localeProvider.t('nav.home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            label: localeProvider.t('nav.meal_planner'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore),
            label: localeProvider.t('nav.discover'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: localeProvider.t('nav.community'),
          ),
        ],
      ),
    );
  }
}
```

---

## Phase 3: Edge Functions

### 3.1 get-translations Function

**File:** `supabase/functions/get-translations/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { language_code = "fr", namespaces } = await req.json();

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    // Build query
    let query = supabaseClient
      .from("app_translation")
      .select(`
        key_name:app_translation_key!inner(key_name,namespace),
        language_code,
        value
      `)
      .eq("language_code", language_code);

    if (namespaces && namespaces.length > 0) {
      query = query.in("app_translation_key.namespace", namespaces);
    }

    const { data, error } = await query;

    if (error) throw error;

    // Transform to key-value format
    const translations: Record<string, string> = {};
    for (const item of data) {
      translations[item.key_name.key_name] = item.value;
    }

    return new Response(JSON.stringify({ translations }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
```

### 3.2 translate-recipe Function (AI-Powered)

**File:** `supabase/functions/translate-recipe/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { recipe_id, target_language } = await req.json();

    if (!recipe_id || !target_language) {
      throw new Error("Missing recipe_id or target_language");
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    // Get original recipe content
    const { data: recipe, error: recipeError } = await supabaseClient
      .from("recipe")
      .select("title, description, instructions, language")
      .eq("id", recipe_id)
      .single();

    if (recipeError) throw recipeError;

    // Call AI translation API (example with OpenAI)
    const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: `You are a professional culinary translator. Translate recipe content from ${recipe.language} to ${target_language}. Maintain cooking terminology accuracy. Return JSON format.`,
          },
          {
            role: "user",
            content: JSON.stringify({
              title: recipe.title,
              description: recipe.description,
              instructions: recipe.instructions,
            }),
          },
        ],
        response_format: { type: "json_object" },
      }),
    });

    const aiData = await aiResponse.json();
    const translation = JSON.parse(aiData.choices[0].message.content);

    // Save translation to database
    const { error: insertError } = await supabaseClient
      .from("recipe_translation")
      .upsert({
        recipe_id,
        language_code: target_language,
        title: translation.title,
        description: translation.description,
        instructions: translation.instructions,
        is_machine_translated: true,
        translated_at: new Date().toISOString(),
      });

    if (insertError) throw insertError;

    return new Response(JSON.stringify({ success: true, translation }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
```

---

## Phase 4: Testing & Validation

### 4.1 Test Scenarios

| Scenario | Expected Result | Priority |
|----------|----------------|----------|
| User changes language | UI updates immediately | P0 |
| Missing translation | Falls back to French | P0 |
| Recipe without translation | Shows original language | P0 |
| Feed renders in selected language | All titles/descriptions translated | P1 |
| Meal plan generates in selected language | Recipe content translated | P1 |
| Offline mode | Last cached translations work | P2 |

### 4.2 Performance Benchmarks

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Translation load time | < 500ms | DevTools Network |
| Language switch latency | < 200ms (cached) | Dart performance overlay |
| Cache hit rate | > 90% | Analytics |
| Missing translation rate | < 5% | Error tracking |

---

## Rollout Plan

### Week 1: Database & Backend
- [ ] Deploy migration `20260301000003_i18n_schema.sql`
- [ ] Deploy seed `02_app_translations.sql`
- [ ] Update RPC functions
- [ ] Test SQL functions manually

### Week 2: Flutter Core
- [ ] Add dependencies
- [ ] Implement `TranslationService`
- [ ] Implement `LocaleProvider`
- [ ] Build `LocaleSelector` widget
- [ ] Update `main.dart`

### Week 3: Integration
- [ ] Connect Flutter to Supabase translations
- [ ] Update navigation labels
- [ ] Translate top 100 UI strings
- [ ] Test feed with language parameter

### Week 4: Polish & Launch
- [ ] Add Edge Functions
- [ ] Implement recipe translation pipeline
- [ ] QA testing
- [ ] Performance optimization
- [ ] Launch to beta users

---

## Appendix: Translation Key Naming Convention

Use dot notation with namespaces:

```
{namespace}.{element}.{purpose}

Examples:
- nav.home
- btn.submit.primary
- recipe.ingredients.title
- errors.network.unavailable
- meal.types.breakfast
```

**Namespaces:**
- `nav` — Navigation
- `btn` — Buttons
- `lbl` — Labels
- `recipe` — Recipe-related
- `meal` — Meal planner
- `errors` — Error messages
- `common` — General purpose

---

**Approval Required:** Review and approve this implementation plan before proceeding with code changes.
