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
