-- =============================================================================
-- AKELI V1 — Language Selection Support
-- Migration: 20260301000003_language_support.sql
-- Purpose: Add translation tables and language-aware RPC functions
-- =============================================================================

-- ---------------------------------------------------------------------------
-- SECTION 1 — TRANSLATION TABLES
-- ---------------------------------------------------------------------------

-- app_translation_key — Keys for all translatable UI strings
CREATE TABLE app_translation_key (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key_name    text NOT NULL UNIQUE,  -- e.g., 'home.feed.title', 'recipe.details.ingredients'
  description text,                   -- Context for translators
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE app_translation_key ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads app_translation_key" ON app_translation_key FOR SELECT USING (true);

-- app_translation — Actual translations per language
CREATE TABLE app_translation (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  translation_key_id uuid REFERENCES app_translation_key(id) ON DELETE CASCADE,
  language_code   text NOT NULL CHECK (language_code IN ('fr', 'en', 'es', 'pt', 'wo', 'bm', 'ln')),
  value           text NOT NULL,
  is_machine_translated boolean DEFAULT false,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (translation_key_id, language_code)
);

ALTER TABLE app_translation ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads app_translation" ON app_translation FOR SELECT USING (true);

CREATE INDEX idx_app_translation_key ON app_translation(translation_key_id);
CREATE INDEX idx_app_translation_language ON app_translation(language_code);

CREATE TRIGGER trg_app_translation_updated_at
  BEFORE UPDATE ON app_translation
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- recipe_translation — Translations for recipe content
CREATE TABLE recipe_translation (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id       uuid REFERENCES recipe(id) ON DELETE CASCADE,
  language_code   text NOT NULL CHECK (language_code IN ('fr', 'en', 'es', 'pt', 'wo', 'bm', 'ln')),
  title           text NOT NULL,
  description     text,
  instructions    text NOT NULL,
  is_machine_translated boolean DEFAULT false,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (recipe_id, language_code)
);

ALTER TABLE recipe_translation ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_translation" ON recipe_translation FOR SELECT USING (true);

CREATE INDEX idx_recipe_translation_recipe ON recipe_translation(recipe_id);
CREATE INDEX idx_recipe_translation_language ON recipe_translation(language_code);

CREATE TRIGGER trg_recipe_translation_updated_at
  BEFORE UPDATE ON recipe_translation
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- SECTION 2 — HELPER FUNCTIONS
-- ---------------------------------------------------------------------------

-- Function to get UI translation
CREATE OR REPLACE FUNCTION get_ui_translation(
  p_key_name text,
  p_language_code text DEFAULT 'fr'
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_value text;
BEGIN
  SELECT at.value INTO v_value
  FROM app_translation_key atk
  JOIN app_translation at ON atk.id = at.translation_key_id
  WHERE atk.key_name = p_key_name
    AND at.language_code = p_language_code;
  
  -- Fallback to French if translation not found
  IF v_value IS NULL THEN
    SELECT at.value INTO v_value
    FROM app_translation_key atk
    JOIN app_translation at ON atk.id = at.translation_key_id
    WHERE atk.key_name = p_key_name
      AND at.language_code = 'fr';
  END IF;
  
  RETURN COALESCE(v_value, p_key_name);
END;
$$;

-- Function to get recipe in specific language
CREATE OR REPLACE FUNCTION get_recipe_translation(
  p_recipe_id uuid,
  p_language_code text DEFAULT 'fr'
)
RETURNS TABLE (
  title           text,
  description     text,
  instructions    text,
  is_machine_translated boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT rt.title, rt.description, rt.instructions, rt.is_machine_translated
  FROM recipe_translation rt
  WHERE rt.recipe_id = p_recipe_id
    AND rt.language_code = p_language_code;
  
  -- Fallback to original recipe if no translation
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT r.title, r.description, r.instructions, false
    FROM recipe r
    WHERE r.id = p_recipe_id;
  END IF;
END;
$$;

-- Function to get all UI translations for a language
CREATE OR REPLACE FUNCTION get_all_ui_translations(p_language_code text DEFAULT 'fr')
RETURNS TABLE (
  key_name text,
  value text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT atk.key_name, at.value
  FROM app_translation_key atk
  JOIN app_translation at ON atk.id = at.translation_key_id
  WHERE at.language_code = p_language_code
  ORDER BY atk.key_name;
  
  -- Include French fallbacks for missing translations
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT atk.key_name, at.value
    FROM app_translation_key atk
    JOIN app_translation at ON atk.id = at.translation_key_id
    WHERE at.language_code = 'fr'
    ORDER BY atk.key_name;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- SECTION 3 — UPDATED RPC FUNCTIONS WITH LANGUAGE SUPPORT
-- ---------------------------------------------------------------------------

-- Updated recommend_recipes with language parameter
CREATE OR REPLACE FUNCTION recommend_recipes(
  p_user_id   uuid,
  p_limit     int     DEFAULT 20,
  p_offset    int     DEFAULT 0,
  p_region    text    DEFAULT NULL,
  p_difficulty text   DEFAULT NULL,
  p_max_time  int     DEFAULT NULL,
  p_language  text    DEFAULT 'fr'
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
  protein_g       numeric,
  like_count      bigint,
  similarity      float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
  v_fan_creator_id uuid;
BEGIN
  -- Récupérer le vecteur utilisateur
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv
  WHERE uv.user_id = p_user_id;

  -- Récupérer le créateur Fan actif de l'utilisateur (si existe)
  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  -- Si pas de vecteur → fallback popularité (cold start)
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
      0.5::float AS similarity
    FROM recipe r
    LEFT JOIN creator c ON r.creator_id = c.id
    LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
    LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
    LEFT JOIN recipe_translation rt ON r.id = rt.recipe_id AND rt.language_code = p_language
    WHERE r.is_published = true
      AND (p_region IS NULL OR r.region = p_region)
      AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
      AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, rt.title, rt.description
    ORDER BY like_count DESC
    LIMIT p_limit
    OFFSET p_offset;
    RETURN;
  END IF;

  -- Feed vectorisé avec boost Mode Fan (×1.5) et cosine similarity HNSW
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
    -- Score final = similarité cosine × boost Fan optionnel
    (1 - (rv.vector <=> v_user_vector)) *
      CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
        THEN 1.5 ELSE 1.0 END AS similarity
  FROM recipe r
  JOIN recipe_vector rv ON r.id = rv.recipe_id
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  LEFT JOIN recipe_translation rt ON r.id = rt.recipe_id AND rt.language_code = p_language
  WHERE r.is_published = true
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, rv.vector, v_fan_creator_id, rt.title, rt.description
  ORDER BY similarity DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- Updated search_recipes with language parameter
CREATE OR REPLACE FUNCTION search_recipes(
  p_query      text    DEFAULT NULL,
  p_region     text    DEFAULT NULL,
  p_difficulty text    DEFAULT NULL,
  p_tag_ids    uuid[]  DEFAULT NULL,
  p_max_time   int     DEFAULT NULL,
  p_order_by   text    DEFAULT 'recent',
  p_language   text    DEFAULT 'fr',
  p_limit      int     DEFAULT 20,
  p_offset     int     DEFAULT 0
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
  created_at      timestamptz
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
    r.created_at
  FROM recipe r
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  LEFT JOIN recipe_translation rt ON r.id = rt.recipe_id AND rt.language_code = p_language
  WHERE r.is_published = true
    -- Recherche texte (ilike sur titre et description)
    AND (p_query IS NULL OR (
      COALESCE(rt.title, r.title) ILIKE '%' || p_query || '%' OR
      COALESCE(rt.description, r.description) ILIKE '%' || p_query || '%'
    ))
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    -- Filtrage par tags (la recette doit avoir TOUS les tags demandés)
    AND (p_tag_ids IS NULL OR (
      SELECT COUNT(*) FROM recipe_tag rt
      WHERE rt.recipe_id = r.id AND rt.tag_id = ANY(p_tag_ids)
    ) = array_length(p_tag_ids, 1))
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, r.created_at, rt.title, rt.description
  ORDER BY
    CASE WHEN p_order_by = 'popular' THEN COUNT(rl.recipe_id) END DESC,
    CASE WHEN p_order_by = 'quick'   THEN COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0) END ASC,
    CASE WHEN p_order_by = 'recent' OR p_order_by IS NULL THEN r.created_at END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- Updated generate_meal_plan with language parameter
CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id       uuid,
  p_days          int     DEFAULT 7,
  p_meals_per_day int     DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE,
  p_language      text    DEFAULT 'fr'
)
RETURNS TABLE (
  meal_plan_id    uuid,
  entry_id        uuid,
  scheduled_date  date,
  meal_type       text,
  recipe_id       uuid,
  recipe_title    text,
  cover_image_url text,
  calories        numeric,
  protein_g       numeric,
  similarity      float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector    vector(50);
  v_fan_creator_id uuid;
  v_plan_id        uuid;
  v_meal_types     text[]  := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day            int;
  v_meal_idx       int;
  v_meal_type      text;
  v_current_date   date;
  v_recipe         record;
  v_entry_id       uuid;
  v_month_key      text;
  v_used_recipe_ids uuid[] := ARRAY[]::uuid[];
BEGIN
  -- Récupérer le vecteur utilisateur
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Créateur Fan actif
  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  v_month_key := to_char(p_start_date, 'YYYY-MM');

  -- Désactiver les plans actifs précédents
  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  -- Créer le nouveau plan
  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  -- Adapter les types de repas selon p_meals_per_day
  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  -- Boucle sur les jours × repas
  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      -- Sélectionner la meilleure recette non déjà utilisée dans le plan
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, 
               COALESCE(rt.title, r.title), 
               r.cover_image_url, 
               rm.calories, 
               rm.protein_g,
               (1 - (rv.vector <=> v_user_vector)) *
               CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
                 THEN 1.5 ELSE 1.0 END AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_translation rt ON r.id = rt.recipe_id AND rt.language_code = p_language
        WHERE r.is_published = true
          AND r.id <> ALL(v_used_recipe_ids)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        -- Fallback popularité si pas de vecteur
        SELECT r.id, 
               COALESCE(rt.title, r.title), 
               r.cover_image_url, 
               rm.calories, 
               rm.protein_g, 
               0.5::float AS score
        INTO v_recipe
        FROM recipe r
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        LEFT JOIN recipe_translation rt ON r.id = rt.recipe_id AND rt.language_code = p_language
        WHERE r.is_published = true
          AND r.id <> ALL(v_used_recipe_ids)
        GROUP BY r.id, rm.calories, rm.protein_g, r.cover_image_url, rt.title
        ORDER BY COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        -- Plus de recettes disponibles : réinitialiser les exclusions
        v_used_recipe_ids := ARRAY[]::uuid[];
        CONTINUE;
      END IF;

      -- Insérer l'entrée du plan
      INSERT INTO meal_plan_entry (meal_plan_id, recipe_id, scheduled_date, meal_type)
      VALUES (v_plan_id, v_recipe.id, v_current_date, v_meal_type)
      RETURNING id INTO v_entry_id;

      -- Marquer la recette comme utilisée dans ce plan
      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;

      -- Retourner l'entrée
      RETURN QUERY SELECT
        v_plan_id,
        v_entry_id,
        v_current_date,
        v_meal_type,
        v_recipe.id,
        v_recipe.title,
        v_recipe.cover_image_url,
        v_recipe.calories,
        v_recipe.protein_g,
        v_recipe.score;
    END LOOP;
  END LOOP;
END;
$$;

-- Updated generate_shopping_list with language parameter
CREATE OR REPLACE FUNCTION generate_shopping_list(
  p_meal_plan_id uuid,
  p_language     text DEFAULT 'fr'
)
RETURNS TABLE (
  shopping_list_id  uuid,
  ingredient_id     uuid,
  ingredient_name   text,
  total_quantity    numeric,
  unit              text,
  category          text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id        uuid;
  v_list_id        uuid;
BEGIN
  -- Vérifier que le plan appartient à l'utilisateur connecté
  SELECT mp.user_id INTO v_user_id
  FROM meal_plan mp WHERE mp.id = p_meal_plan_id;

  IF v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Supprimer l'ancienne shopping list pour ce plan (si existe)
  DELETE FROM shopping_list WHERE meal_plan_id = p_meal_plan_id;

  -- Créer la nouvelle shopping list
  INSERT INTO shopping_list (user_id, meal_plan_id)
  VALUES (v_user_id, p_meal_plan_id)
  RETURNING id INTO v_list_id;

  -- Agréger les ingrédients de toutes les recettes du plan
  INSERT INTO shopping_list_item (shopping_list_id, ingredient_id, quantity, unit)
  SELECT
    v_list_id,
    ri.ingredient_id,
    SUM(ri.quantity * mpe.servings),
    ri.unit
  FROM meal_plan_entry mpe
  JOIN recipe_ingredient ri ON mpe.recipe_id = ri.recipe_id
  WHERE mpe.meal_plan_id = p_meal_plan_id
    AND ri.is_optional = false
  GROUP BY ri.ingredient_id, ri.unit;

  -- Retourner la liste avec noms traduits
  RETURN QUERY
  SELECT
    sli.shopping_list_id,
    sli.ingredient_id,
    CASE 
      WHEN p_language = 'en' THEN COALESCE(i.name_en, i.name_fr, i.name)
      WHEN p_language = 'es' THEN COALESCE(i.name_es, i.name_fr, i.name)
      WHEN p_language = 'pt' THEN COALESCE(i.name_pt, i.name_fr, i.name)
      ELSE COALESCE(i.name_fr, i.name)
    END AS ingredient_name,
    sli.quantity,
    sli.unit,
    i.category
  FROM shopping_list_item sli
  JOIN ingredient i ON sli.ingredient_id = i.id
  WHERE sli.shopping_list_id = v_list_id
  ORDER BY i.category, ingredient_name;
END;
$$;
