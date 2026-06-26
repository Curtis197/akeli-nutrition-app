# Akeli V1 — Moteurs de Recommandation Multi-Engine (pgvector)

> Architecture de recommandation basée sur des fonctions RPC PostgreSQL + pgvector.
> Pas de service Python supplémentaire pour la recommandation — tout reste dans Supabase.
> Python (Railway) est utilisé uniquement pour le calcul nightly des vecteurs.

**Statut** : Prêt pour implémentation V1  
**Date** : Avril 2026  
**Auteur** : Curtis — Fondateur Akeli  
**Dépendances** : `V1_MODULAR_MEAL_BATCH_CONCILIATION.md`, `V1_USER_RECIPES_COMBINATIONS.md`

---

## 1. Architecture globale

### 1.1 Principe

Les moteurs de recommandation sont des **fonctions RPC PostgreSQL** appelées directement
depuis les Edge Functions via `supabase.rpc()`. pgvector HNSW assure les similarités
cosine en ~3ms.

Python (Railway) intervient uniquement en amont, la nuit, pour calculer et stocker les
vecteurs. Il ne répond à aucune requête en temps réel.

```
┌─────────────────────────────────────────────┐
│ Nightly — Python (Railway)                  │
│                                             │
│ job_vectorizer.py                           │
│  ├── Calcule user_vector (50D)              │
│  ├── Calcule recipe_vector (50D)            │
│  └── Calcule combination_vector (50D)       │
│              ↓ stocke dans Supabase         │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Runtime — Edge Function (Supabase)          │
│                                             │
│ generate-meal-plan                          │
│  ├── supabase.rpc('recommend_recipes')      │
│  ├── supabase.rpc('recommend_combinations') │
│  └── supabase.rpc('optimize_batch')         │
│              ↓ pgvector HNSW (~3ms)         │
└─────────────────────────────────────────────┘
```

### 1.2 Matrice des cas d'usage

| Préférences utilisateur | Fonctions RPC appelées |
|---|---|
| `batch = false`, `modular = false` | `recommend_recipes()` |
| `batch = true`, `modular = false` | `recommend_recipes()` + `optimize_batch()` |
| `batch = false`, `modular = true` | `recommend_recipes()` + `recommend_combinations()` |
| `batch = true`, `modular = true` | Les trois fonctions |

---

## 2. Tables pgvector

### 2.1 Tables existantes (inchangées)

```sql
-- Vecteurs recettes (existant)
CREATE TABLE recipe_vector (
  recipe_id     uuid PRIMARY KEY REFERENCES recipe(id) ON DELETE CASCADE,
  vector        vector(50) NOT NULL,
  last_computed timestamptz DEFAULT now()
);
CREATE INDEX idx_recipe_vector_hnsw ON recipe_vector
  USING hnsw (vector vector_cosine_ops);

-- Vecteurs utilisateurs (existant)
CREATE TABLE user_vector (
  user_id       uuid PRIMARY KEY REFERENCES user_profile(id) ON DELETE CASCADE,
  vector        vector(50) NOT NULL,
  last_computed timestamptz DEFAULT now()
);
```

### 2.2 Nouvelle table : `combination_vector`

```sql
CREATE TABLE combination_vector (
  combination_id uuid PRIMARY KEY REFERENCES recipe_combination(id) ON DELETE CASCADE,
  vector         vector(50) NOT NULL,
  last_computed  timestamptz DEFAULT now()
);

CREATE INDEX idx_combination_vector_hnsw ON combination_vector
  USING hnsw (vector vector_cosine_ops);

ALTER TABLE combination_vector ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads" ON combination_vector FOR SELECT USING (true);
```

---

## 3. Fonction RPC 1 — `recommend_recipes`

Recommande des recettes individuelles par similarité cosine avec le profil utilisateur.
Supporte le filtrage par rôle pour le modular meal.

```sql
CREATE OR REPLACE FUNCTION recommend_recipes(
  p_user_id   uuid,
  p_role      text    DEFAULT NULL,   -- 'base' | 'starch' | 'side' | NULL (tous)
  p_limit     int     DEFAULT 10,
  p_exclude   uuid[]  DEFAULT '{}'    -- recipe_ids déjà planifiés
)
RETURNS TABLE (
  recipe_id   uuid,
  title       text,
  region      text,
  servings    int,
  distance    numeric
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    r.id          AS recipe_id,
    r.title,
    r.region,
    r.servings,
    (rv.vector <=> uv.vector)::numeric AS distance
  FROM recipe r
  JOIN recipe_vector rv ON rv.recipe_id = r.id
  JOIN user_vector uv   ON uv.user_id   = p_user_id
  WHERE
    r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND (
      p_role IS NULL
      OR (p_role = 'starch' AND r.id IN (
            SELECT paired_recipe_id FROM recipe_combination
            WHERE paired_role = 'starch' AND is_validated = true
          ))
      OR (p_role = 'base' AND r.id IN (
            SELECT base_recipe_id FROM recipe_combination
            WHERE is_validated = true
          ))
      OR p_role = 'side'
    )
  ORDER BY distance
  LIMIT p_limit;
$$;
```

---

## 4. Fonction RPC 2 — `recommend_combinations`

Recommande des paires validées (base + starch) adaptées au profil utilisateur.
Activée uniquement si `modular_meal_enabled = true`.

```sql
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
AS $$
  SELECT
    rc.id              AS combination_id,
    rc.base_recipe_id,
    rc.paired_recipe_id,
    rc.paired_role,
    rc.source,
    -- Priorité source intégrée dans le score de distance
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

## 5. Fonction RPC 3 — `optimize_batch`

Fonction contextuelle : opère sur un meal plan actif pour maximiser la réutilisation
des sessions batch. Pas de vecteur — logique SQL pure.

```sql
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
AS $$
  WITH available_sessions AS (
    SELECT
      cs.id       AS session_id,
      cs.recipe_id,
      r.title     AS recipe_title,
      cs.total_portions - cs.portions_used AS available_portions,
      cs.planned_date
    FROM cooking_session cs
    JOIN recipe r ON r.id = cs.recipe_id
    WHERE
      cs.meal_plan_id = p_meal_plan_id
      AND cs.total_portions > cs.portions_used
  ),
  free_slots AS (
    SELECT
      mpe.id             AS entry_id,
      mpe.scheduled_date,
      mpe.meal_type
    FROM meal_plan_entry mpe
    WHERE
      mpe.meal_plan_id = p_meal_plan_id
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

---

## 6. Appel depuis l'Edge Function

```typescript
// Edge Function : generate-meal-plan (extrait)

const { data: userPrefs } = await supabaseV1
  .from('user_profile')
  .select('batch_cooking_enabled, modular_meal_enabled')
  .eq('id', userId)
  .single();

// Moteur 1 — toujours actif
const { data: recipeRecs } = await supabaseV1.rpc('recommend_recipes', {
  p_user_id: userId,
  p_limit:   20,
});

// Moteur 2 — si modular meal activé
let combinationRecs = null;
if (userPrefs.modular_meal_enabled) {
  const { data } = await supabaseV1.rpc('recommend_combinations', {
    p_user_id: userId,
    p_limit:   10,
  });
  combinationRecs = data;
}

// Moteur 3 — si batch cooking activé
let batchSuggestions = null;
if (userPrefs.batch_cooking_enabled) {
  const { data } = await supabaseV1.rpc('optimize_batch', {
    p_user_id:      userId,
    p_meal_plan_id: mealPlanId,
  });
  batchSuggestions = data;
}

const mealPlan = assembleMealPlan({
  recipeRecs,
  combinationRecs,
  batchSuggestions,
  userPrefs,
});
```

---

## 7. Python Railway — Vectorisation uniquement

Un seul job couvre les trois types de vecteurs. Aucune logique de recommandation
en Python — uniquement du calcul et du stockage.

**Job** : `job_vectorizer.py`  
**Fréquence** : Nightly 01:00

```python
async def run():
    # 1. Vecteurs recettes (nouvelles + modifiées depuis hier)
    await compute_recipe_vectors()

    # 2. Vecteurs combinaisons (moyenne pondérée base 60% + starch 40%)
    await compute_combination_vectors()

    # 3. Vecteurs utilisateurs (basés sur historique de consommation)
    await compute_user_vectors()

def compute_combination_vector(base_vector, starch_vector):
    """
    La sauce (base) est le composant culturellement central — poids supérieur.
    """
    return base_vector * 0.6 + starch_vector * 0.4
```

---

## 8. Résumé

| Composant | Technologie | Latence |
|-----------|------------|---------|
| `recommend_recipes()` | RPC pgvector HNSW | ~3ms |
| `recommend_combinations()` | RPC pgvector HNSW | ~3ms |
| `optimize_batch()` | RPC SQL pur | ~5ms |
| Calcul des vecteurs | Python Railway nightly | batch |

---

*Document créé : Avril 2026*  
*Auteur : Curtis — Fondateur Akeli*  
*Version : 2.0 — Architecture pgvector RPC (remplace version jobs Python)*  
*Documents liés : V1_MODULAR_MEAL_BATCH_CONCILIATION.md · V1_USER_RECIPES_COMBINATIONS.md · PYTHON_RECOMMENDATION_ENGINE.md*
