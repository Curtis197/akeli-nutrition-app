-- =============================================================================
-- AKELI V1 — Fonctions SQL PostgreSQL (RPC)
-- Migration: 20260301000002_rpc_functions.sql
-- Ces fonctions sont appelées via .rpc() depuis Flutter ou les Edge Functions
-- Ref: V1_ARCHITECTURE_DECISIONS.md ADR-001, ADR-002, ADR-004
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. recommend_recipes
-- Feed vectorisé — cosine similarity pgvector HNSW (~3ms)
-- ADR-001: Python remplacé par pgvector au runtime
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION recommend_recipes(
  p_user_id   uuid,
  p_limit     int     DEFAULT 20,
  p_offset    int     DEFAULT 0,
  p_region    text    DEFAULT NULL,
  p_difficulty text   DEFAULT NULL,
  p_max_time  int     DEFAULT NULL   -- prep_time_min + cook_time_min
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
      r.title,
      r.description,
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
    WHERE r.is_published = true
      AND (p_region IS NULL OR r.region = p_region)
      AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
      AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g
    ORDER BY like_count DESC
    LIMIT p_limit
    OFFSET p_offset;
    RETURN;
  END IF;

  -- Feed vectorisé avec boost Mode Fan (×1.5) et cosine similarity HNSW
  RETURN QUERY
  SELECT
    r.id,
    r.title,
    r.description,
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
  WHERE r.is_published = true
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, rv.vector, v_fan_creator_id
  ORDER BY similarity DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. search_recipes
-- Recherche recettes — texte libre + filtres + tri
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION search_recipes(
  p_query      text    DEFAULT NULL,
  p_region     text    DEFAULT NULL,
  p_difficulty text    DEFAULT NULL,
  p_tag_ids    uuid[]  DEFAULT NULL,
  p_max_time   int     DEFAULT NULL,
  p_order_by   text    DEFAULT 'recent',  -- 'recent' | 'popular' | 'quick'
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
    r.title,
    r.description,
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
  WHERE r.is_published = true
    -- Recherche texte (ilike sur titre et description)
    AND (p_query IS NULL OR (
      r.title ILIKE '%' || p_query || '%' OR
      r.description ILIKE '%' || p_query || '%'
    ))
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    -- Filtrage par tags (la recette doit avoir TOUS les tags demandés)
    AND (p_tag_ids IS NULL OR (
      SELECT COUNT(*) FROM recipe_tag rt
      WHERE rt.recipe_id = r.id AND rt.tag_id = ANY(p_tag_ids)
    ) = array_length(p_tag_ids, 1))
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories
  ORDER BY
    CASE WHEN p_order_by = 'popular' THEN COUNT(rl.recipe_id) END DESC,
    CASE WHEN p_order_by = 'quick'   THEN COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0) END ASC,
    CASE WHEN p_order_by = 'recent' OR p_order_by IS NULL THEN r.created_at END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. search_creators
-- Recherche créateurs par nom — ADR-004
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION search_creators(
  p_query  text DEFAULT NULL,
  p_limit  int  DEFAULT 20,
  p_offset int  DEFAULT 0
)
RETURNS TABLE (
  id              uuid,
  display_name    text,
  bio             text,
  avatar_url      text,
  cover_url       text,
  specialties     text[],
  is_verified     boolean,
  is_fan_eligible boolean,
  recipe_count    int,
  fan_count       int
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.display_name,
    c.bio,
    c.avatar_url,
    c.cover_url,
    c.specialties,
    c.is_verified,
    c.is_fan_eligible,
    c.recipe_count,
    c.fan_count
  FROM creator c
  WHERE
    (p_query IS NULL OR c.display_name ILIKE '%' || p_query || '%')
  ORDER BY
    -- Créateurs éligibles Fan en tête, puis par nombre de recettes
    c.is_fan_eligible DESC,
    c.recipe_count DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. get_creator_public_profile
-- Profil public complet d'un créateur — ADR-004
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_creator_public_profile(p_creator_id uuid)
RETURNS TABLE (
  id              uuid,
  user_id         uuid,
  display_name    text,
  bio             text,
  avatar_url      text,
  cover_url       text,
  specialties     text[],
  languages       text[],
  is_verified     boolean,
  is_fan_eligible boolean,
  recipe_count    int,
  fan_count       int,
  created_at      timestamptz,
  -- Fan actif de l'utilisateur connecté pour ce créateur
  is_my_fan_creator boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.user_id,
    c.display_name,
    c.bio,
    c.avatar_url,
    c.cover_url,
    c.specialties,
    c.languages,
    c.is_verified,
    c.is_fan_eligible,
    c.recipe_count,
    c.fan_count,
    c.created_at,
    EXISTS (
      SELECT 1 FROM fan_subscription fs
      WHERE fs.user_id = auth.uid()
        AND fs.creator_id = p_creator_id
        AND fs.status IN ('active', 'pending')
    ) AS is_my_fan_creator
  FROM creator c
  WHERE c.id = p_creator_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- 5. generate_meal_plan
-- Génération d'un plan alimentaire vectorisé via pgvector
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id       uuid,
  p_days          int     DEFAULT 7,
  p_meals_per_day int     DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE
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
        SELECT r.id, r.title, r.cover_image_url, rm.calories, rm.protein_g,
               (1 - (rv.vector <=> v_user_vector)) *
               CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
                 THEN 1.5 ELSE 1.0 END AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND r.id <> ALL(v_used_recipe_ids)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        -- Fallback popularité si pas de vecteur
        SELECT r.id, r.title, r.cover_image_url, rm.calories, rm.protein_g, 0.5::float AS score
        INTO v_recipe
        FROM recipe r
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND r.id <> ALL(v_used_recipe_ids)
        GROUP BY r.id, rm.calories, rm.protein_g
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

-- ---------------------------------------------------------------------------
-- 6. generate_shopping_list
-- Liste de courses agrégée depuis un meal_plan
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_shopping_list(p_meal_plan_id uuid)
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

  -- Retourner la liste
  RETURN QUERY
  SELECT
    sli.shopping_list_id,
    sli.ingredient_id,
    COALESCE(i.name_fr, i.name) AS ingredient_name,
    sli.quantity,
    sli.unit,
    i.category
  FROM shopping_list_item sli
  JOIN ingredient i ON sli.ingredient_id = i.id
  WHERE sli.shopping_list_id = v_list_id
  ORDER BY i.category, i.name;
END;
$$;

-- ---------------------------------------------------------------------------
-- 7. find_or_create_conversation
-- Trouver ou créer une conversation privée entre deux utilisateurs
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION find_or_create_conversation(
  p_other_user_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_user_id uuid := auth.uid();
  v_conversation_id uuid;
BEGIN
  -- Chercher une conversation existante entre les deux utilisateurs
  SELECT cp1.conversation_id INTO v_conversation_id
  FROM conversation_participant cp1
  JOIN conversation_participant cp2
    ON cp1.conversation_id = cp2.conversation_id
  WHERE cp1.user_id = v_current_user_id
    AND cp2.user_id = p_other_user_id;

  IF v_conversation_id IS NOT NULL THEN
    RETURN v_conversation_id;
  END IF;

  -- Vérifier qu'une demande acceptée existe (ou créer sans demande pour les créateurs)
  -- Créer une nouvelle conversation
  INSERT INTO conversation DEFAULT VALUES
  RETURNING id INTO v_conversation_id;

  INSERT INTO conversation_participant (conversation_id, user_id)
  VALUES
    (v_conversation_id, v_current_user_id),
    (v_conversation_id, p_other_user_id);

  RETURN v_conversation_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- 8. respond_conversation_request
-- Accepter ou refuser une demande de conversation
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION respond_conversation_request(
  p_request_id uuid,
  p_action     text  -- 'accepted' | 'declined'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_request        record;
  v_conversation_id uuid;
BEGIN
  IF p_action NOT IN ('accepted', 'declined') THEN
    RAISE EXCEPTION 'Invalid action: %', p_action;
  END IF;

  SELECT * INTO v_request
  FROM conversation_request
  WHERE id = p_request_id AND to_user_id = auth.uid() AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found or not authorized';
  END IF;

  -- Mettre à jour le statut de la demande
  UPDATE conversation_request SET status = p_action WHERE id = p_request_id;

  IF p_action = 'accepted' THEN
    -- Créer la conversation
    INSERT INTO conversation DEFAULT VALUES RETURNING id INTO v_conversation_id;
    INSERT INTO conversation_participant (conversation_id, user_id)
    VALUES
      (v_conversation_id, v_request.from_user_id),
      (v_conversation_id, v_request.to_user_id);

    RETURN jsonb_build_object('conversation_id', v_conversation_id);
  END IF;

  RETURN jsonb_build_object('status', p_action);
END;
$$;

-- ---------------------------------------------------------------------------
-- 9. join_group
-- Rejoindre un groupe communautaire
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION join_group(p_group_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_group record;
BEGIN
  SELECT * INTO v_group
  FROM community_group WHERE id = p_group_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Group not found';
  END IF;

  IF NOT v_group.is_public THEN
    RAISE EXCEPTION 'Cannot join a private group without invitation';
  END IF;

  INSERT INTO group_member (group_id, user_id, role)
  VALUES (p_group_id, auth.uid(), 'member')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  RETURN jsonb_build_object('group_id', p_group_id, 'status', 'joined');
END;
$$;
