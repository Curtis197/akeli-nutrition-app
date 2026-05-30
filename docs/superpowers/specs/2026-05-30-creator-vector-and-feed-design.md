# Creator Vector & Creator Feed Generator — Design Spec

**Date:** 2026-05-30
**Scope:** Python batch function to compute creator vectors + 3 SQL RPCs to generate a personalized creator feed

---

## Goal

Enable personalized creator discovery by embedding creators into the existing 50D shared vector space (same space as users and recipes), then generating a 70/20/10 creator feed using cosine similarity against the user vector.

---

## Context

The existing system has:
- `user_vector(50D)` — encodes user preferences/goals
- `recipe_vector(50D)` — encodes recipe nutritional + cultural profile
- 3 feed RPCs: `generate_feed_personalized`, `generate_feed_exploration`, `generate_feed_fresh`
- Python nightly batch: `compute_user_vectors()`, `compute_recipe_vectors()` in `python/engine/vectorization.py`

**Creators currently have no vector.** The Créateurs tab (added in the previous sprint) shows creators ordered by `recipe_count DESC` — static, not personalized.

---

## Approach

**Option A chosen:** Extend the Python batch job to compute and store `creator_vector` nightly. Three new SQL RPCs (one per feed segment) query the vector using the existing pgvector HNSW infrastructure.

Creator vector = simple unweighted average of all published recipe vectors for that creator, L2-normalized. Same 50D space — no new dimensions — so cosine similarity with `user_vector` is meaningful with zero additional calibration.

---

## 1. Schema — Migration

One new table and HNSW index:

```sql
CREATE TABLE IF NOT EXISTS creator_vector (
  creator_id          UUID PRIMARY KEY REFERENCES creator(id) ON DELETE CASCADE,
  vector              vector(50) NOT NULL,
  last_computed       timestamptz NOT NULL DEFAULT now(),
  recipe_count_sampled int NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_creator_vector_hnsw
  ON creator_vector USING hnsw (vector vector_cosine_ops);
```

`recipe_count_sampled` — number of published recipe vectors averaged. Preserved for future confidence-weighting (algorithm_improvements.md Priority 2: Bayesian cold-start).

No `creator_performance_metrics` table in V1. Quality gates reuse existing `creator.recipe_count` and `creator.average_rating`.

---

## 2. Python Batch Function

**File:** `python/engine/vectorization.py`
**New function:** `compute_creator_vectors(conn)`

### Algorithm

```
for each creator where recipe_count >= 1:
  vectors = SELECT rv.vector
            FROM recipe_vector rv
            JOIN recipe r ON r.id = rv.recipe_id
            WHERE r.creator_id = :creator_id
              AND r.is_published = true

  if len(vectors) == 0:
    log warning "no recipe vectors yet for creator_id"
    continue

  centroid = np.mean(vectors, axis=0)   # shape (50,)
  norm = np.linalg.norm(centroid)

  if norm == 0:
    log error "zero-norm centroid for creator_id — skipping"
    continue

  normalized = centroid / norm

  UPSERT INTO creator_vector
    (creator_id, vector, last_computed, recipe_count_sampled)
    VALUES (:creator_id, :normalized, now(), len(vectors))
    ON CONFLICT (creator_id) DO UPDATE SET
      vector = EXCLUDED.vector,
      last_computed = EXCLUDED.last_computed,
      recipe_count_sampled = EXCLUDED.recipe_count_sampled
```

### Integration

Called from the existing nightly batch entry point after `compute_recipe_vectors()` (recipe vectors must exist before creator vectors can be derived from them).

```python
def run_nightly_batch(conn):
    compute_user_vectors(conn)
    compute_recipe_vectors(conn)
    compute_creator_vectors(conn)   # new — depends on recipe vectors
```

### Edge Cases

| Case | Handling |
|---|---|
| Creator has no published recipes | Skip, log warning |
| Creator's recipes exist but none in `recipe_vector` yet | Skip, log warning (will pick up next night after recipe vectorization) |
| Single recipe | Average of 1 = that recipe's vector, valid |
| All-zero centroid | Skip, log error |
| Creator deleted | `ON DELETE CASCADE` cleans up `creator_vector` row |

---

## 3. Feed Generator RPCs

Three SQL functions added in one migration, mirroring the recipe feed pattern.

### `generate_creators_personalized(p_user_id UUID, p_limit INT DEFAULT 14)`

**Purpose:** Top creators by cosine similarity to user vector (70% of creator feed).

```sql
CREATE OR REPLACE FUNCTION generate_creators_personalized(
  p_user_id UUID,
  p_limit   INT DEFAULT 14
)
RETURNS TABLE (creator_id UUID, score numeric, segment text)
LANGUAGE sql STABLE
AS $$
  -- Cold start fallback: no user vector → rank by fan_count
  SELECT
    c.id            AS creator_id,
    CASE
      WHEN uv.vector IS NOT NULL
        THEN (1 - (cv.vector <=> uv.vector))::numeric
      ELSE (c.fan_count::numeric / NULLIF((SELECT MAX(fan_count) FROM creator), 0))
    END             AS score,
    'personalized'  AS segment
  FROM creator c
  JOIN creator_vector cv ON cv.creator_id = c.id
  LEFT JOIN user_vector uv ON uv.user_id = p_user_id
  WHERE c.recipe_count >= 3
  ORDER BY
    CASE WHEN uv.vector IS NOT NULL
      THEN (cv.vector <=> uv.vector)
      ELSE -c.fan_count::float
    END ASC
  LIMIT p_limit;
$$;
```

**Filters:**
- `creator.recipe_count >= 3` — credibility gate

**Cold start:** If no `user_vector` exists for the user, falls back to `fan_count DESC`.

---

### `generate_creators_exploration(p_user_id UUID, p_limit INT DEFAULT 4)`

**Purpose:** Creators stylistically different from user's taste but high quality (20%).

```sql
CREATE OR REPLACE FUNCTION generate_creators_exploration(
  p_user_id UUID,
  p_limit   INT DEFAULT 4
)
RETURNS TABLE (creator_id UUID, score numeric, segment text)
LANGUAGE sql STABLE
AS $$
  SELECT
    c.id                                          AS creator_id,
    (1 - (cv.vector <=> uv.vector))::numeric      AS score,
    'exploration'                                 AS segment
  FROM creator c
  JOIN creator_vector cv ON cv.creator_id = c.id
  JOIN user_vector uv    ON uv.user_id = p_user_id
  WHERE c.recipe_count >= 3
    AND c.average_rating >= 3.5
    AND (1 - (cv.vector <=> uv.vector)) < 0.50
  ORDER BY random()
  LIMIT p_limit;
$$;
```

**Filters:**
- Similarity < 0.50 — genuinely different style
- `average_rating >= 3.5` — quality gate compensates for style mismatch
- `ORDER BY random()` — diversity, avoids always showing same borderline creators

**Cold start:** Returns empty (JOIN on `user_vector` excludes users with no vector).

---

### `generate_creators_fresh(p_user_id UUID, p_limit INT DEFAULT 2)`

**Purpose:** New creators the user hasn't discovered yet (10%).

```sql
CREATE OR REPLACE FUNCTION generate_creators_fresh(
  p_user_id UUID,
  p_limit   INT DEFAULT 2
)
RETURNS TABLE (creator_id UUID, score numeric, segment text)
LANGUAGE sql STABLE
AS $$
  SELECT
    c.id        AS creator_id,
    0::numeric  AS score,
    'fresh'     AS segment
  FROM creator c
  WHERE
    -- new creator (joined recently) OR just published first recipes
    (c.created_at >= now() - interval '60 days'
     OR (
       SELECT MIN(r.created_at) FROM recipe r
       WHERE r.creator_id = c.id AND r.is_published = true
     ) >= now() - interval '30 days'
    )
    -- not already a fan
    AND NOT EXISTS (
      SELECT 1 FROM fan_subscription fs
      WHERE fs.creator_id = c.id
        AND fs.user_id = p_user_id
        AND fs.status = 'active'
    )
  ORDER BY c.created_at DESC
  LIMIT p_limit;
$$;
```

**No vector join needed** — freshness is a temporal signal, not a preference signal.

---

## 4. Feed Composition

The 3 RPCs are designed to be called in parallel from a new `get-creator-feed` edge function or from the Flutter `creatorsListProvider`, then interleaved 7:2:1 per 10 slots:

| Segment | Limit | Ratio |
|---|---|---|
| Personalized | 14 | 70% |
| Exploration | 4 | 20% |
| Fresh | 2 | 10% |
| **Total** | **20** | **100%** |

---

## 5. Dimension Usage

Creator vectors inherit the full 50D semantics from recipe vectors:

| Dimensions | Meaning | Creator interpretation |
|---|---|---|
| 0–9 | Nutritional + practical | Avg nutritional profile of creator's recipes |
| 10–22 | Cuisine regions (13D one-hot) | Dominant cuisine regions in creator's catalog |
| 23–26 | Dietary + creator signals | Avg vegetarian/halal signal; creator quality proxy |
| 27–49 | **Reserved** | Free for future creator-specific signals (allergen specialty, audience tier, etc.) |

---

## 6. Out of Scope (V1)

- Quality-weighted centroid (recency decay, adherence weighting) — algorithm_improvements.md Priority 2
- `creator_performance_metrics` table
- Creator similarity search ("find creators like X")
- Interleaving creator cards into the main recipe feed
- Flutter `creatorsListProvider` update to use the new RPCs (separate Flutter task)

---

## 7. Files Created / Modified

| File | Action |
|---|---|
| `supabase/migrations/TIMESTAMP_creator_vector.sql` | New — schema + 3 RPCs |
| `python/engine/vectorization.py` | Modify — add `compute_creator_vectors()` |
