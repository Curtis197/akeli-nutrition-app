-- =============================================================================
-- AKELI V1 — Recommendation & Feed Engine (pgvector)
-- Migration: 20260517000003_recommendation_feed_engine.sql
-- Specs: V1_RECOMMENDATION_MULTI_ENGINE.md · FEED_GENERATION_V2.md
--
-- What this adds:
--   Tables : recipe_combination, combination_vector,
--             recipe_performance_metrics, user_feed
--   RPCs   : recommend_combinations, optimize_batch,
--             generate_feed_personalized, generate_feed_exploration,
--             generate_feed_fresh
--
-- What stays untouched:
--   user_vector, recipe_vector, recommend_recipes() — already in pgvector,
--   no Python on the runtime path.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. Colonnes manquantes sur recipe
-- is_private     : recette privée (visible uniquement par son propriétaire)
-- owner_user_id  : utilisateur propriétaire des recettes privées
-- Ces colonnes sont référencées par les RPCs de ce fichier.
-- ---------------------------------------------------------------------------

ALTER TABLE recipe
  ADD COLUMN IF NOT EXISTS is_private    boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS owner_user_id uuid    REFERENCES user_profile(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_recipe_private ON recipe(owner_user_id)
  WHERE is_private = true;

-- ---------------------------------------------------------------------------
-- 1. recipe_combination
-- Paires validées (base ↔ starch/side). Trois sources :
--   creator       — définie par le créateur de la recette base
--   cross_creator — pré-validée par Akeli entre deux créateurs différents
--   user          — définie par l'utilisateur (privée)
-- is_validated = true avant d'être éligible à recommend_combinations().
-- ---------------------------------------------------------------------------

CREATE TABLE recipe_combination (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  base_recipe_id   uuid NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  paired_recipe_id uuid NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  paired_role      text NOT NULL CHECK (paired_role IN ('starch', 'side')),
  source           text NOT NULL CHECK (source IN ('creator', 'cross_creator', 'user')),
  is_validated     boolean NOT NULL DEFAULT false,
  owner_user_id    uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  created_at       timestamptz DEFAULT now(),
  -- Les combinaisons utilisateur doivent avoir un owner
  CONSTRAINT user_source_requires_owner CHECK (
    source != 'user' OR owner_user_id IS NOT NULL
  )
);

CREATE INDEX idx_recipe_combination_base   ON recipe_combination(base_recipe_id);
CREATE INDEX idx_recipe_combination_paired ON recipe_combination(paired_recipe_id);
CREATE INDEX idx_recipe_combination_source ON recipe_combination(source, is_validated);

-- Partial unique indexes to handle NULL owner_user_id correctly
CREATE UNIQUE INDEX unique_combination_system
  ON recipe_combination (base_recipe_id, paired_recipe_id, source)
  WHERE source IN ('creator', 'cross_creator');

CREATE UNIQUE INDEX unique_combination_user
  ON recipe_combination (base_recipe_id, paired_recipe_id, owner_user_id)
  WHERE source = 'user';

ALTER TABLE recipe_combination ENABLE ROW LEVEL SECURITY;

-- Les combinaisons validées creator/cross_creator sont publiques
CREATE POLICY "public reads validated combinations" ON recipe_combination
  FOR SELECT USING (
    is_validated = true AND source IN ('creator', 'cross_creator')
  );

-- Les combinaisons utilisateur ne sont lisibles que par leur propriétaire
CREATE POLICY "owner reads own combinations" ON recipe_combination
  FOR SELECT USING (
    source = 'user' AND owner_user_id = auth.uid()
  );

-- Un utilisateur peut créer ses propres combinaisons
CREATE POLICY "owner inserts own combinations" ON recipe_combination
  FOR INSERT WITH CHECK (
    source = 'user' AND owner_user_id = auth.uid()
  );

-- Un utilisateur peut supprimer ses propres combinaisons
CREATE POLICY "owner deletes own combinations" ON recipe_combination
  FOR DELETE USING (
    source = 'user' AND owner_user_id = auth.uid()
  );

-- ---------------------------------------------------------------------------
-- 2. combination_vector
-- Vecteur 50D pour chaque paire (moyenne pondérée : base 60% + paired 40%).
-- Écrit par job_vectorizer.py (Python Railway, nightly).
-- Jamais lu directement par l'app — uniquement par recommend_combinations().
-- ---------------------------------------------------------------------------

CREATE TABLE combination_vector (
  combination_id uuid PRIMARY KEY REFERENCES recipe_combination(id) ON DELETE CASCADE,
  vector         vector(50) NOT NULL,
  last_computed  timestamptz DEFAULT now()
);

CREATE INDEX idx_combination_vector_hnsw ON combination_vector
  USING hnsw (vector vector_cosine_ops) WITH (m = 16, ef_construction = 64);

ALTER TABLE combination_vector ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reads combination_vector" ON combination_vector
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipe_combination rc
      WHERE rc.id = combination_id
        AND (
          (rc.is_validated = true AND rc.source IN ('creator', 'cross_creator'))
          OR (rc.source = 'user' AND rc.owner_user_id = auth.uid())
        )
    )
  );

-- ---------------------------------------------------------------------------
-- 3. recipe_performance_metrics
-- Métriques calculées par recette. Mise à jour périodique (Python ou cron).
-- drop_off_rate    : fraction d'utilisateurs qui abandonnent la recette.
--                    > 0.20 → exclue du feed personnalisé.
-- adherence_rate   : fraction d'utilisateurs qui cuisinent après avoir vu.
--                    > 0.70 → éligible au feed exploration.
-- consumption_rate_7d : consommations des 7 derniers jours (trending).
-- ---------------------------------------------------------------------------

CREATE TABLE recipe_performance_metrics (
  recipe_id           uuid PRIMARY KEY REFERENCES recipe(id) ON DELETE CASCADE,
  drop_off_rate       numeric(5,4) NOT NULL DEFAULT 0 CHECK (drop_off_rate BETWEEN 0 AND 1),
  adherence_rate      numeric(5,4) NOT NULL DEFAULT 0 CHECK (adherence_rate BETWEEN 0 AND 1),
  consumption_rate_7d numeric(8,2) NOT NULL DEFAULT 0 CHECK (consumption_rate_7d >= 0),
  computed_at         timestamptz DEFAULT now()
);

ALTER TABLE recipe_performance_metrics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_performance_metrics" ON recipe_performance_metrics
  FOR SELECT USING (true);

-- ---------------------------------------------------------------------------
-- 4. user_feed
-- Cache du feed généré. Recalculé par get-feed Edge Function.
-- Cycle : DELETE tout → INSERT les 200 nouvelles entrées → retour Flutter.
-- seen_at / interacted_at permettent l'analyse des comportements de scroll.
-- ---------------------------------------------------------------------------

CREATE TABLE user_feed (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES user_profile(id) ON DELETE CASCADE,
  recipe_id     uuid NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  position      int NOT NULL,
  segment       text NOT NULL CHECK (segment IN ('personalized', 'exploration', 'fresh')),
  score         numeric(6,4),
  generated_at  timestamptz DEFAULT now(),
  seen_at       timestamptz,
  interacted_at timestamptz
);

CREATE INDEX idx_user_feed_user   ON user_feed(user_id, position);
CREATE INDEX idx_user_feed_recipe ON user_feed(recipe_id);
CREATE INDEX idx_user_feed_gen    ON user_feed(user_id, generated_at DESC);

ALTER TABLE user_feed ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads user_feed" ON user_feed
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "owner deletes user_feed" ON user_feed
  FOR DELETE USING (auth.uid() = user_id);

-- Service role (Edge Function get-feed) insère les lignes du feed
CREATE POLICY "service inserts user_feed" ON user_feed
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- ---------------------------------------------------------------------------
-- 5. recommend_combinations
-- Recommande des paires validées par similarité cosine avec le profil user.
-- Appelée uniquement si user_profile.modular_meal_enabled = true.
-- Priorité source encodée dans le score : user 0.90, creator 0.95, cross 1.00.
-- (Distance plus faible = plus proche = meilleur rang)
-- Retourne vide (sans exception) si l'utilisateur n'a pas encore de vecteur.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION recommend_combinations(
  p_user_id uuid,
  p_limit   int DEFAULT 10
)
RETURNS TABLE (
  combination_id   uuid,
  base_recipe_id   uuid,
  paired_recipe_id uuid,
  paired_role      text,
  source           text,
  distance         numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  -- Auth guard: caller must be the user they're requesting recommendations for
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Fetch user vector; return empty set if not yet computed (cold start)
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    rc.id              AS combination_id,
    rc.base_recipe_id,
    rc.paired_recipe_id,
    rc.paired_role,
    rc.source,
    (cv.vector <=> v_user_vector)::numeric *
      CASE rc.source
        WHEN 'user'          THEN 0.90
        WHEN 'creator'       THEN 0.95
        WHEN 'cross_creator' THEN 1.00
      END AS distance
  FROM recipe_combination rc
  JOIN combination_vector cv ON cv.combination_id = rc.id
  WHERE
    rc.is_validated = true
    AND (
      rc.source IN ('creator', 'cross_creator')
      OR (rc.source = 'user' AND rc.owner_user_id = p_user_id)
    )
  ORDER BY distance
  LIMIT LEAST(p_limit, 50);
END;
$$;

-- ---------------------------------------------------------------------------
-- 6. optimize_batch
-- Opère sur un meal plan actif : trouve les sessions batch avec des portions
-- disponibles et les aligne avec les slots libres (sans cooking_session).
-- SQL pur — pas de vecteur. Appelée si batch_cooking_enabled = true.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION optimize_batch(
  p_user_id      uuid,
  p_meal_plan_id uuid
)
RETURNS TABLE (
  cooking_session_id  uuid,
  recipe_id           uuid,
  recipe_title        text,
  available_portions  int,
  suggested_slot_date date,
  suggested_meal_type text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  -- Auth guard: caller must be the user they're optimizing for
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Verify the meal plan belongs to this user
  IF NOT EXISTS (
    SELECT 1 FROM meal_plan mp
    WHERE mp.id = p_meal_plan_id AND mp.user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Meal plan not found or not owned by this user';
  END IF;

  RETURN QUERY
  WITH available_sessions AS (
    SELECT
      cs.id                                              AS session_id,
      cs.recipe_id,
      r.title                                            AS recipe_title,
      GREATEST(cs.total_portions - cs.portions_used, 0) AS available_portions,
      cs.planned_date
    FROM cooking_session cs
    JOIN recipe r ON r.id = cs.recipe_id
    WHERE cs.meal_plan_id = p_meal_plan_id
      AND cs.user_id = p_user_id
      AND cs.total_portions > cs.portions_used
  ),
  free_slots AS (
    -- Meal plan entries without any batch-linked component
    SELECT
      mpe.id             AS entry_id,
      mpe.scheduled_date,
      mpe.meal_type
    FROM meal_plan_entry mpe
    JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mp.user_id = p_user_id
      AND NOT EXISTS (
        SELECT 1 FROM meal_plan_entry_component mpec
        WHERE mpec.meal_plan_entry_id = mpe.id
          AND mpec.cooking_session_id IS NOT NULL
      )
  )
  SELECT
    av.session_id,
    av.recipe_id,
    av.recipe_title,
    av.available_portions,
    fs.scheduled_date,
    fs.meal_type
  FROM available_sessions av
  CROSS JOIN LATERAL (
    SELECT * FROM free_slots
    WHERE scheduled_date >= av.planned_date
    LIMIT av.available_portions
  ) fs
  ORDER BY fs.scheduled_date, av.planned_date, av.session_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- 7. generate_feed_personalized — 70% du feed
-- Top recettes par similarité cosine. Filtre qualité : drop_off_rate ≤ 0.20.
-- Fallback popularité si pas de user_vector (cold start).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_feed_personalized(
  p_user_id uuid,
  p_limit   int     DEFAULT 140,
  p_exclude uuid[]  DEFAULT '{}'
)
RETURNS TABLE (
  recipe_id uuid,
  score     numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  -- Auth guard
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Cold start : pas encore de vecteur → tri par popularité (likes)
  -- Même filtre qualité drop_off_rate que le chemin vectorisé.
  IF v_user_vector IS NULL THEN
    RETURN QUERY
    SELECT
      r.id                         AS recipe_id,
      COUNT(rl.recipe_id)::numeric AS score
    FROM recipe r
    LEFT JOIN recipe_like rl ON rl.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
      -- Filtre qualité identique au chemin vectorisé
      AND NOT EXISTS (
        SELECT 1 FROM recipe_performance_metrics rpm
        WHERE rpm.recipe_id = r.id
          AND rpm.drop_off_rate > 0.20
      )
    GROUP BY r.id
    ORDER BY score DESC
    LIMIT LEAST(p_limit, 200);
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    r.id                                         AS recipe_id,
    (1 - (rv.vector <=> v_user_vector))::numeric AS score
  FROM recipe r
  JOIN recipe_vector rv ON rv.recipe_id = r.id
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    -- Filtre qualité : exclure les recettes avec taux d'abandon élevé
    -- Les recettes sans métriques passent (données insuffisantes = bénéfice du doute)
    AND NOT EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
        AND rpm.drop_off_rate > 0.20
    )
  ORDER BY score DESC
  LIMIT LEAST(p_limit, 200);
END;
$$;

-- ---------------------------------------------------------------------------
-- 8. generate_feed_exploration — 20% du feed
-- Faible similarité (< 0.50) mais haute adhérence (> 0.70).
-- ORDER BY random() pour la diversité de découverte.
-- Retourne vide si pas de user_vector (dissimilarité impossible à calculer).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_feed_exploration(
  p_user_id uuid,
  p_limit   int    DEFAULT 40,
  p_exclude uuid[] DEFAULT '{}'
)
RETURNS TABLE (
  recipe_id uuid,
  score     numeric
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  -- Auth guard
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Sans vecteur on ne peut pas calculer la dissimilarité → retourner vide
  IF v_user_vector IS NULL THEN
    RETURN;
  END IF;

  -- CTE pour calculer la distance une seule fois par recette
  RETURN QUERY
  WITH candidates AS (
    SELECT
      r.id                                         AS recipe_id,
      (1 - (rv.vector <=> v_user_vector))::numeric AS score
    FROM recipe r
    JOIN recipe_vector rv ON rv.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
  )
  SELECT c.recipe_id, c.score
  FROM candidates c
  WHERE c.score < 0.50
    -- Haute qualité : l'utilisateur cuisine vraiment la recette
    AND EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = c.recipe_id
        AND rpm.adherence_rate > 0.70
    )
  ORDER BY random()
  LIMIT LEAST(p_limit, 80);
END;
$$;

-- ---------------------------------------------------------------------------
-- 9. generate_feed_fresh — 10% du feed
-- Recettes publiées dans les 7 derniers jours, de créateurs non encore suivis.
-- SQL pur — pas de vecteur nécessaire.
-- Score : 1.0 = vient d'être publiée, ~0.0 = publiée il y a 7 jours.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_feed_fresh(
  p_user_id uuid,
  p_limit   int    DEFAULT 20,
  p_exclude uuid[] DEFAULT '{}'
)
RETURNS TABLE (
  recipe_id uuid,
  score     numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  -- Auth guard
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    r.id                                                                        AS recipe_id,
    -- Score décroissant : 1.0 = publiée maintenant, ~0.0 = publiée il y a 7 jours
    (1.0 - EXTRACT(EPOCH FROM (now() - r.created_at)) / 604800.0)::numeric     AS score
  FROM recipe r
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND r.created_at >= now() - interval '7 days'
    -- De créateurs que l'utilisateur ne suit pas encore en Mode Fan
    -- NOT EXISTS est NULL-safe (contrairement à NOT IN)
    AND NOT EXISTS (
      SELECT 1 FROM fan_subscription fs
      WHERE fs.user_id = p_user_id
        AND fs.status = 'active'
        AND fs.creator_id = r.creator_id
    )
  ORDER BY r.created_at DESC
  LIMIT LEAST(p_limit, 40);
END;
$$;

-- Index pour generate_feed_fresh : filtre sur created_at dans les 7 derniers jours
CREATE INDEX IF NOT EXISTS idx_recipe_created_at_published
  ON recipe (created_at DESC)
  WHERE is_published = true AND is_private = false;
