# Recommendation & Feed Engine Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the 4 missing tables and 5 RPC functions that move recommendation and feed generation fully into pgvector RPCs, with no Python on the runtime path.

**Architecture:** Single migration file `20260517000003_recommendation_feed_engine.sql`. Tables come first (dependencies), then RPCs. Python's only remaining role is nightly vectorization via `job_vectorizer.py` (Railway) — it writes to `user_vector`, `recipe_vector`, and the new `combination_vector`; it reads nothing at runtime. Existing `recommend_recipes()` already uses pgvector and is left untouched. New functions are additive only.

**Tech Stack:** PostgreSQL 15+, pgvector (already enabled), Supabase RLS, `SECURITY DEFINER` RPCs

---

## What already exists — do NOT recreate

| Object | Exists in migration |
|---|---|
| `user_vector` table | `20260301000001_initial_schema.sql` |
| `recipe_vector` table | `20260301000001_initial_schema.sql` |
| `recommend_recipes()` RPC | `20260301000002_rpc_functions.sql` |
| `cooking_session` table | `20260516000001_modular_meal_batch_cooking.sql` |
| `meal_plan_entry_component` table | `20260516000001_modular_meal_batch_cooking.sql` |
| `recipe.is_private` column | `20260516000001_modular_meal_batch_cooking.sql` |

## File Map

| File | Responsibility |
|---|---|
| `supabase/migrations/20260517000003_recommendation_feed_engine.sql` | All 4 tables + 5 RPCs in one atomic migration |

---

## Task 1: `recipe_combination` table

The join table that drives `recommend_combinations()`. Stores validated pairings between a base sauce and a starch/side, with three sources: creator-defined, cross-creator (Akeli-validated), user-defined.

**Files:**
- Create: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Create the file and write the `recipe_combination` table**

```sql
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
  CONSTRAINT unique_combination UNIQUE (base_recipe_id, paired_recipe_id, source, owner_user_id),
  -- Les combinaisons utilisateur doivent avoir un owner
  CONSTRAINT user_source_requires_owner CHECK (
    source != 'user' OR owner_user_id IS NOT NULL
  )
);

CREATE INDEX idx_recipe_combination_base   ON recipe_combination(base_recipe_id);
CREATE INDEX idx_recipe_combination_paired ON recipe_combination(paired_recipe_id);
CREATE INDEX idx_recipe_combination_source ON recipe_combination(source, is_validated);

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
```

---

## Task 2: `combination_vector` table

Stores the 50D embedding for each recipe combination — weighted average of base vector (60%) and paired vector (40%), computed nightly by `job_vectorizer.py`.

**Files:**
- Modify: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Append `combination_vector` to the migration file**

```sql
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
CREATE POLICY "public reads combination_vector" ON combination_vector
  FOR SELECT USING (true);
```

---

## Task 3: `recipe_performance_metrics` table

Computed metrics used by feed filtering: drop-off rate (quality gate for personalized feed) and adherence rate (quality gate for exploration feed). Updated by Python or a Supabase cron.

**Files:**
- Modify: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Append `recipe_performance_metrics` to the migration file**

```sql
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
  drop_off_rate       numeric(5,4) NOT NULL DEFAULT 0,
  adherence_rate      numeric(5,4) NOT NULL DEFAULT 0,
  consumption_rate_7d numeric(8,2) NOT NULL DEFAULT 0,
  computed_at         timestamptz DEFAULT now()
);

ALTER TABLE recipe_performance_metrics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_performance_metrics" ON recipe_performance_metrics
  FOR SELECT USING (true);
```

---

## Task 4: `user_feed` table

Cache of the assembled feed for a user. Regenerated by the `get-feed` Edge Function when stale (> 24h) or on pull-to-refresh. Each row is one recipe slot with its segment (personalized / exploration / fresh) and score.

**Files:**
- Modify: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Append `user_feed` to the migration file**

```sql
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
CREATE POLICY "owner only user_feed" ON user_feed
  USING (auth.uid() = user_id);
```

- [ ] **Step 2: Commit the tables**

```
git add supabase/migrations/20260517000003_recommendation_feed_engine.sql
git commit -m "feat(db): add recipe_combination, combination_vector, recipe_performance_metrics, user_feed tables"
```

---

## Task 5: `recommend_combinations()` RPC

Recommends validated (base + starch/side) pairings ranked by cosine similarity to the user vector. Active only when `modular_meal_enabled = true`. Source priority is encoded directly in the distance: user-defined combinations get a 10% boost, creator-defined get 5%, cross-creator are neutral.

**Files:**
- Modify: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Append `recommend_combinations` to the migration file**

```sql
-- ---------------------------------------------------------------------------
-- 5. recommend_combinations
-- Recommande des paires validées par similarité cosine avec le profil user.
-- Appelée uniquement si user_profile.modular_meal_enabled = true.
-- Priorité source encodée dans le score : user 0.90, creator 0.95, cross 1.00.
-- (Distance plus faible = plus proche = meilleur rang)
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
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    rc.id              AS combination_id,
    rc.base_recipe_id,
    rc.paired_recipe_id,
    rc.paired_role,
    rc.source,
    (cv.vector <=> uv.vector)::numeric *
      CASE rc.source
        WHEN 'user'          THEN 0.90
        WHEN 'creator'       THEN 0.95
        WHEN 'cross_creator' THEN 1.00
      END AS distance
  FROM recipe_combination rc
  JOIN combination_vector cv ON cv.combination_id = rc.id
  JOIN user_vector uv        ON uv.user_id = p_user_id
  WHERE
    rc.is_validated = true
    AND (
      rc.source IN ('creator', 'cross_creator')
      OR (rc.source = 'user' AND rc.owner_user_id = p_user_id)
    )
  ORDER BY distance
  LIMIT p_limit;
$$;
```

---

## Task 6: `optimize_batch()` RPC

Operates on an existing meal plan to suggest which cooking sessions can cover free slots. No vector math — pure SQL. Active only when `batch_cooking_enabled = true`. Depends on `cooking_session` and `meal_plan_entry_component` (added in `20260516000001`).

**Files:**
- Modify: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Append `optimize_batch` to the migration file**

```sql
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
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  WITH available_sessions AS (
    SELECT
      cs.id                                     AS session_id,
      cs.recipe_id,
      r.title                                   AS recipe_title,
      cs.total_portions - cs.portions_used      AS available_portions,
      cs.planned_date
    FROM cooking_session cs
    JOIN recipe r ON r.id = cs.recipe_id
    WHERE cs.meal_plan_id = p_meal_plan_id
      AND cs.user_id = p_user_id
      AND cs.total_portions > cs.portions_used
  ),
  free_slots AS (
    -- Entrées du plan sans aucun composant lié à une session batch
    SELECT
      mpe.id             AS entry_id,
      mpe.scheduled_date,
      mpe.meal_type
    FROM meal_plan_entry mpe
    WHERE mpe.meal_plan_id = p_meal_plan_id
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
  ORDER BY fs.scheduled_date;
$$;
```

- [ ] **Step 2: Commit the recommendation RPCs**

```
git add supabase/migrations/20260517000003_recommendation_feed_engine.sql
git commit -m "feat(rpc): add recommend_combinations and optimize_batch RPCs"
```

---

## Task 7: `generate_feed_personalized()` RPC

Returns the top 140 recipes ranked by cosine similarity to the user vector. Excludes recipes with a drop-off rate above 20% (quality gate). Skips recipes the user consumed in the last 7 days (passed as `p_exclude`). Falls back to popularity-ranked recipes if the user has no vector yet (cold start).

**Files:**
- Modify: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Append `generate_feed_personalized` to the migration file**

```sql
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
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Cold start : pas encore de vecteur → tri par popularité (likes)
  IF v_user_vector IS NULL THEN
    RETURN QUERY
    SELECT
      r.id                        AS recipe_id,
      COUNT(rl.recipe_id)::numeric AS score
    FROM recipe r
    LEFT JOIN recipe_like rl ON rl.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
    GROUP BY r.id
    ORDER BY score DESC
    LIMIT p_limit;
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    r.id                                     AS recipe_id,
    (1 - (rv.vector <=> v_user_vector))::numeric AS score
  FROM recipe r
  JOIN recipe_vector rv ON rv.recipe_id = r.id
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    -- Filtre qualité : exclure les recettes avec taux d'abandon élevé
    AND NOT EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
        AND rpm.drop_off_rate > 0.20
    )
  ORDER BY score DESC
  LIMIT p_limit;
END;
$$;
```

---

## Task 8: `generate_feed_exploration()` RPC

Returns up to 40 recipes that are dissimilar to the user (similarity < 0.50) but have high adherence (≥ 0.70) — culturally adventurous picks with proven quality. Ordered randomly so the exploration slot is different each time.

**Files:**
- Modify: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Append `generate_feed_exploration` to the migration file**

```sql
-- ---------------------------------------------------------------------------
-- 8. generate_feed_exploration — 20% du feed
-- Faible similarité (< 0.50) mais haute adhérence (> 0.70).
-- ORDER BY random() pour la diversité de découverte.
-- Skip si pas de user_vector (impossible de calculer la dissimilarité).
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
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Sans vecteur on ne peut pas calculer la dissimilarité → retourner vide
  IF v_user_vector IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    r.id                                     AS recipe_id,
    (1 - (rv.vector <=> v_user_vector))::numeric AS score
  FROM recipe r
  JOIN recipe_vector rv ON rv.recipe_id = r.id
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    -- Faible similarité = découverte culturelle
    AND (1 - (rv.vector <=> v_user_vector)) < 0.50
    -- Haute qualité : l'utilisateur cuisine vraiment la recette
    AND EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
        AND rpm.adherence_rate > 0.70
    )
  ORDER BY random()
  LIMIT p_limit;
END;
$$;
```

---

## Task 9: `generate_feed_fresh()` RPC

Returns up to 20 recipes published in the last 7 days from creators the user is not already a fan of. Pure SQL, no vector. Score is a freshness decay value (lower = newer), returned inverted so higher score = more recent.

**Files:**
- Modify: `supabase/migrations/20260517000003_recommendation_feed_engine.sql`

- [ ] **Step 1: Append `generate_feed_fresh` to the migration file**

```sql
-- ---------------------------------------------------------------------------
-- 9. generate_feed_fresh — 10% du feed
-- Recettes publiées dans les 7 derniers jours, de créateurs non encore suivis.
-- SQL pur — pas de vecteur nécessaire.
-- Score : fraction de semaine écoulée depuis la publication (plus bas = plus récent).
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
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    r.id                                                                  AS recipe_id,
    -- Score décroissant : 0.0 = vient d'être publiée, ~1.0 = publiée il y a 7 jours
    (EXTRACT(EPOCH FROM (now() - r.created_at)) / 604800.0)::numeric     AS score
  FROM recipe r
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND r.created_at >= now() - interval '7 days'
    -- De créateurs que l'utilisateur ne suit pas encore en Mode Fan
    AND r.creator_id NOT IN (
      SELECT creator_id FROM fan_subscription
      WHERE user_id = p_user_id AND status = 'active'
    )
  ORDER BY r.created_at DESC
  LIMIT p_limit;
$$;
```

- [ ] **Step 2: Commit the feed RPCs**

```
git add supabase/migrations/20260517000003_recommendation_feed_engine.sql
git commit -m "feat(rpc): add generate_feed_personalized, generate_feed_exploration, generate_feed_fresh RPCs"
```

---

## Verification Checklist

After all tasks are committed, verify before applying to production:

- [ ] **Dry-run locally:** `supabase db reset` applies all migrations in order — no errors
- [ ] **Tables exist:** `\dt recipe_combination combination_vector recipe_performance_metrics user_feed` — all 4 present
- [ ] **HNSW index on combination_vector:** `\di idx_combination_vector_hnsw` — present
- [ ] **RPCs callable:** in Supabase SQL editor, run each with dummy UUIDs and confirm they return 0 rows (not error):
  ```sql
  SELECT * FROM recommend_combinations('00000000-0000-0000-0000-000000000000', 5);
  SELECT * FROM optimize_batch('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000000');
  SELECT * FROM generate_feed_personalized('00000000-0000-0000-0000-000000000000', 10, '{}');
  SELECT * FROM generate_feed_exploration('00000000-0000-0000-0000-000000000000', 5, '{}');
  SELECT * FROM generate_feed_fresh('00000000-0000-0000-0000-000000000000', 5, '{}');
  ```
- [ ] **No Python on runtime path:** confirm none of the 5 new RPCs reference any external service or pg_net call
- [ ] **Deploy:** `supabase db push` (or via Supabase dashboard migration apply)

---

## Python (Railway) — what it still does after this migration

The `job_vectorizer.py` nightly job writes to three tables. It does not respond to any user request:

| Table written | When |
|---|---|
| `recipe_vector` | When a recipe is new or modified |
| `user_vector` | Based on last 30 days of `meal_consumption` |
| `combination_vector` | For each `recipe_combination` where `is_validated = true` |

No migration needed for the Python job itself — it simply needs to be updated to include `combination_vector` inserts/upserts alongside the existing recipe and user vector jobs.
