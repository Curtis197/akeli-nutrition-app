# Akeli V1 — Feed Generation (pgvector)

> Le feed est généré par des fonctions RPC PostgreSQL + pgvector.
> Pas de service Python pour le feed — tout reste dans Supabase.
> Python (Railway) est utilisé uniquement pour le calcul nightly des vecteurs
> (partagé avec le moteur de recommandation — voir `V1_RECOMMENDATION_MULTI_ENGINE.md`).

**Statut** : Prêt pour implémentation V1  
**Date** : Avril 2026  
**Auteur** : Curtis — Fondateur Akeli  
**Remplace** : `FEED_GENERATION.md` v1.0 (architecture Python Railway)

---

## 1. Principe

Le feed n'est pas une liste chronologique — c'est un moteur de découverte qui équilibre
personnalisation et sérendipité.

```
70% personnalisé   — cosine similarity user_vector ↔ recipe_vector
20% exploration    — faible similarité mais haute qualité
10% fresh          — recettes publiées dans les 7 derniers jours
```

L'économie du feed est alignée sur la consommation, pas sur les vues.
Une recette bien notée mais peu consommée est moins bien rankée qu'une recette
modeste mais régulièrement cuisinée.

---

## 2. Architecture

```
Flutter App
    ↓
Edge Function : get-feed
    ↓ supabase.rpc()
    ├── generate_feed_personalized()   — pgvector HNSW (~3ms)
    ├── generate_feed_exploration()    — pgvector HNSW (~3ms)
    └── generate_feed_fresh()          — SQL pur (~2ms)
    ↓
Assemble + interleave + store in user_feed
    ↓
Infinite scroll
```

Python (Railway) calcule les vecteurs en nightly batch — même job `job_vectorizer.py`
que pour les recommandations. Aucune logique de feed en Python.

---

## 3. Tables

### 3.1 `user_feed` — cache du feed généré

```sql
CREATE TABLE user_feed (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  recipe_id   uuid REFERENCES recipe(id) ON DELETE CASCADE,
  position    int NOT NULL,
  segment     text NOT NULL CHECK (segment IN ('personalized', 'exploration', 'fresh')),
  score       numeric(6,4),
  generated_at timestamptz DEFAULT now(),
  seen_at     timestamptz,
  interacted_at timestamptz
);

CREATE INDEX idx_user_feed_user     ON user_feed(user_id, position);
CREATE INDEX idx_user_feed_recipe   ON user_feed(recipe_id);
CREATE INDEX idx_user_feed_gen      ON user_feed(user_id, generated_at DESC);

ALTER TABLE user_feed ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only" ON user_feed USING (auth.uid() = user_id);
```

---

## 4. Fonctions RPC

### 4.1 `generate_feed_personalized` — 70%

Top recettes par similarité cosine, filtrées sur la qualité et la diversité.

```sql
CREATE OR REPLACE FUNCTION generate_feed_personalized(
  p_user_id    uuid,
  p_limit      int DEFAULT 140,
  p_exclude    uuid[] DEFAULT '{}'   -- déjà consommées récemment
)
RETURNS TABLE (
  recipe_id  uuid,
  score      numeric
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    r.id                                        AS recipe_id,
    (1 - (rv.vector <=> uv.vector))::numeric    AS score
  FROM recipe r
  JOIN recipe_vector rv ON rv.recipe_id = r.id
  JOIN user_vector uv   ON uv.user_id   = p_user_id
  WHERE
    r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    -- Qualité minimale : exclure les recettes avec taux d'abandon élevé
    AND NOT EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
      AND rpm.drop_off_rate > 0.20
    )
  ORDER BY score DESC
  LIMIT p_limit;
$$;
```

### 4.2 `generate_feed_exploration` — 20%

Recettes à faible similarité mais haute adhérence — découverte culturelle.

```sql
CREATE OR REPLACE FUNCTION generate_feed_exploration(
  p_user_id    uuid,
  p_limit      int DEFAULT 40,
  p_exclude    uuid[] DEFAULT '{}'
)
RETURNS TABLE (
  recipe_id  uuid,
  score      numeric
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    r.id                                        AS recipe_id,
    (1 - (rv.vector <=> uv.vector))::numeric    AS similarity
  FROM recipe r
  JOIN recipe_vector rv ON rv.recipe_id = r.id
  JOIN user_vector uv   ON uv.user_id   = p_user_id
  WHERE
    r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    -- Faible similarité = découverte
    AND (1 - (rv.vector <=> uv.vector)) < 0.50
    -- Mais haute qualité : adhérence élevée
    AND EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
      AND rpm.adherence_rate > 0.70
    )
  ORDER BY random()   -- diversité dans l'exploration
  LIMIT p_limit;
$$;
```

### 4.3 `generate_feed_fresh` — 10%

Recettes récentes de créateurs non encore suivis. SQL pur, pas de vecteur.

```sql
CREATE OR REPLACE FUNCTION generate_feed_fresh(
  p_user_id    uuid,
  p_limit      int DEFAULT 20,
  p_exclude    uuid[] DEFAULT '{}'
)
RETURNS TABLE (
  recipe_id  uuid,
  score      numeric
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    r.id                                              AS recipe_id,
    -- Score décroissant selon l'âge (plus récent = score plus élevé)
    EXTRACT(EPOCH FROM (now() - r.created_at)) / 604800 AS score
  FROM recipe r
  WHERE
    r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    -- Publiée dans les 7 derniers jours
    AND r.created_at >= now() - interval '7 days'
    -- De créateurs non encore suivis
    AND r.creator_id NOT IN (
      SELECT creator_id FROM fan_subscription
      WHERE user_id = p_user_id AND status = 'active'
    )
  ORDER BY r.created_at DESC
  LIMIT p_limit;
$$;
```

---

## 5. Assemblage dans l'Edge Function

```typescript
// Edge Function : get-feed

Deno.serve(async (req) => {
  const userId = req.headers.get('x-user-id');

  // Recettes déjà consommées récemment (7 jours) — à exclure
  const { data: recentlyConsumed } = await supabase
    .from('meal_consumption')
    .select('recipe_id')
    .eq('user_id', userId)
    .gte('consumed_at', new Date(Date.now() - 7 * 86400000).toISOString());

  const excludeIds = recentlyConsumed?.map(r => r.recipe_id) ?? [];

  // Appel des trois fonctions RPC en parallèle
  const [personalized, exploration, fresh] = await Promise.all([
    supabase.rpc('generate_feed_personalized', {
      p_user_id: userId,
      p_limit:   140,
      p_exclude: excludeIds,
    }),
    supabase.rpc('generate_feed_exploration', {
      p_user_id: userId,
      p_limit:   40,
      p_exclude: excludeIds,
    }),
    supabase.rpc('generate_feed_fresh', {
      p_user_id: userId,
      p_limit:   20,
      p_exclude: excludeIds,
    }),
  ]);

  // Interleave les trois segments
  const feed = interleaveFeed(
    personalized.data,   // 70%
    exploration.data,    // 20%
    fresh.data,          // 10%
  );

  // Stocker dans user_feed (remplace le feed précédent)
  await supabase.from('user_feed').delete().eq('user_id', userId);
  await supabase.from('user_feed').insert(
    feed.map((r, i) => ({
      user_id:   userId,
      recipe_id: r.recipe_id,
      position:  i,
      segment:   r.segment,
      score:     r.score,
    }))
  );

  return new Response(JSON.stringify({ ok: true, count: feed.length }));
});

// Interleave : 7 personnalisé, 2 exploration, 1 fresh — répété
function interleaveFeed(personalized, exploration, fresh) {
  const result = [];
  let pi = 0, ei = 0, fi = 0, pos = 0;

  while (pi < personalized.length || ei < exploration.length || fi < fresh.length) {
    const slot = pos % 10;
    if (slot < 7 && pi < personalized.length) {
      result.push({ ...personalized[pi++], segment: 'personalized' });
    } else if (slot < 9 && ei < exploration.length) {
      result.push({ ...exploration[ei++], segment: 'exploration' });
    } else if (fi < fresh.length) {
      result.push({ ...fresh[fi++], segment: 'fresh' });
    } else if (pi < personalized.length) {
      result.push({ ...personalized[pi++], segment: 'personalized' });
    }
    pos++;
  }
  return result;
}
```

---

## 6. Feeds secondaires (SQL simple, pas de vecteur)

### Discovery Feed — Trending

```sql
SELECT r.id, r.title, rpm.consumption_rate_7d
FROM recipe r
JOIN recipe_performance_metrics rpm ON rpm.recipe_id = r.id
WHERE r.is_published = true
ORDER BY rpm.consumption_rate_7d DESC
LIMIT 100;
```

### Creator Feed — Following

```sql
SELECT r.id, r.title, r.created_at
FROM recipe r
JOIN fan_subscription fs ON fs.creator_id = r.creator_id
WHERE fs.user_id = :user_id
AND fs.status = 'active'
AND r.is_published = true
ORDER BY r.created_at DESC
LIMIT 50;
```

Ces deux feeds sont appelés directement depuis Flutter via Supabase client —
pas besoin d'Edge Function dédiée.

---

## 7. Rafraîchissement du feed

| Événement | Action |
|-----------|--------|
| Ouverture de l'app | Vérifier si `generated_at < 24h` — si oui, utiliser le cache |
| `generated_at > 24h` | Appeler `get-feed` Edge Function pour régénérer |
| Pull-to-refresh | Forcer la régénération |
| Scroll au bout | Appeler `get-feed` avec `page` pour étendre |

---

## 8. Résumé

| Composant | Technologie | Latence |
|-----------|------------|---------|
| `generate_feed_personalized()` | RPC pgvector HNSW | ~3ms |
| `generate_feed_exploration()` | RPC pgvector HNSW | ~3ms |
| `generate_feed_fresh()` | RPC SQL pur | ~2ms |
| Discovery + Creator feeds | SQL direct client | ~2ms |
| Calcul `user_vector` / `recipe_vector` | Python Railway nightly | batch |

---

*Document créé : Avril 2026*  
*Auteur : Curtis — Fondateur Akeli*  
*Version : 2.0 — Architecture pgvector RPC (remplace FEED_GENERATION.md v1.0)*  
*Documents liés : V1_RECOMMENDATION_MULTI_ENGINE.md · PYTHON_RECOMMENDATION_ENGINE.md*
