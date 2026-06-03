# Creator Vector & Creator Feed Generator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Embed creators into the existing 50D vector space and generate a 70/20/10 personalized creator feed using cosine similarity against user vectors.

**Architecture:** Python batch job computes `creator_vector` as the L2-normalized average of a creator's published recipe vectors (same 50D space, no new dimensions). Three SQL RPCs (`generate_creators_personalized`, `generate_creators_exploration`, `generate_creators_fresh`) mirror the existing recipe feed pattern exactly, querying the HNSW index for < 5ms latency.

**Tech Stack:** Python 3, NumPy, psycopg2, FastAPI (Railway), PostgreSQL + pgvector, Supabase migrations

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `supabase/migrations/20260530000001_creator_vector_feed.sql` | Create | `creator_vector` table + HNSW index + 3 feed RPCs |
| `python/engine/database.py` | Modify | Add `get_all_creators()`, `get_creator_recipe_vectors()`, `upsert_creator_vector()` |
| `python/engine/vectorization.py` | Modify | Add `compute_creator_vector()` |
| `python/tests/test_vectorization.py` | Modify | Add unit tests for `compute_creator_vector()` |
| `python/main.py` | Modify | Add `/compute-creator-vector` endpoint + creator step in `run_nightly_batch()` |

---

## Task 1: Database Migration — creator_vector table + 3 feed RPCs

**Files:**
- Create: `supabase/migrations/20260530000001_creator_vector_feed.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- =============================================================================
-- AKELI — Creator Vector & Creator Feed RPCs
-- Migration: 20260530000001_creator_vector_feed.sql
--
-- What this adds:
--   Table : creator_vector
--   RPCs  : generate_creators_personalized,
--            generate_creators_exploration,
--            generate_creators_fresh
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. creator_vector
-- Vecteur 50D par créateur — moyenne normalisée L2 de ses recipe_vectors.
-- Écrit par le batch Python nightly (après compute_recipe_vectors).
-- recipe_count_sampled : nombre de recettes ayant contribué à la moyenne.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS creator_vector (
  creator_id           UUID PRIMARY KEY REFERENCES creator(id) ON DELETE CASCADE,
  vector               vector(50) NOT NULL,
  last_computed        timestamptz NOT NULL DEFAULT now(),
  recipe_count_sampled int        NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_creator_vector_hnsw
  ON creator_vector USING hnsw (vector vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

ALTER TABLE creator_vector ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service manages creator_vector" ON creator_vector;
CREATE POLICY "service manages creator_vector" ON creator_vector
  FOR ALL USING (true);

-- ---------------------------------------------------------------------------
-- 2. generate_creators_personalized — 70% du creator feed
-- Top créateurs par similarité cosine avec le user_vector.
-- Filtre qualité : recipe_count >= 3.
-- Cold start (pas de user_vector) : fallback fan_count DESC.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_creators_personalized(
  p_user_id UUID,
  p_limit   INT     DEFAULT 14,
  p_exclude UUID[]  DEFAULT '{}'
)
RETURNS TABLE (creator_id UUID, score numeric)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
  v_max_fans    int;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Cold start : pas de vecteur → fallback fan_count normalisé
  IF v_user_vector IS NULL THEN
    SELECT MAX(fan_count) INTO v_max_fans FROM creator;
    RETURN QUERY
    SELECT
      c.id AS creator_id,
      CASE WHEN v_max_fans > 0
        THEN (c.fan_count::numeric / v_max_fans)
        ELSE 0::numeric
      END AS score
    FROM creator c
    WHERE c.recipe_count >= 3
      AND c.id <> ALL(p_exclude)
    ORDER BY c.fan_count DESC
    LIMIT LEAST(p_limit, 100);
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    c.id                                          AS creator_id,
    (1 - (cv.vector <=> v_user_vector))::numeric  AS score
  FROM creator c
  JOIN creator_vector cv ON cv.creator_id = c.id
  WHERE c.recipe_count >= 3
    AND c.id <> ALL(p_exclude)
  ORDER BY (cv.vector <=> v_user_vector) ASC
  LIMIT LEAST(p_limit, 100);
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. generate_creators_exploration — 20% du creator feed
-- Créateurs stylistiquement différents (similarité < 0.50) mais
-- haute qualité (average_rating >= 3.5).
-- ORDER BY random() pour la diversité de découverte.
-- Retourne vide si pas de user_vector.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_creators_exploration(
  p_user_id UUID,
  p_limit   INT    DEFAULT 4,
  p_exclude UUID[] DEFAULT '{}'
)
RETURNS TABLE (creator_id UUID, score numeric)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH candidates AS (
    SELECT
      c.id                                          AS creator_id,
      (1 - (cv.vector <=> v_user_vector))::numeric  AS score
    FROM creator c
    JOIN creator_vector cv ON cv.creator_id = c.id
    WHERE c.recipe_count >= 3
      AND c.average_rating >= 3.5
      AND c.id <> ALL(p_exclude)
  )
  SELECT cand.creator_id, cand.score
  FROM candidates cand
  WHERE cand.score < 0.50
  ORDER BY random()
  LIMIT LEAST(p_limit, 50);
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. generate_creators_fresh — 10% du creator feed
-- Nouveaux créateurs (rejoint < 60 jours ou première recette < 30 jours)
-- que l'utilisateur ne suit pas encore.
-- Score = 0 (pas de signal vectoriel — fraîcheur temporelle uniquement).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_creators_fresh(
  p_user_id UUID,
  p_limit   INT    DEFAULT 2,
  p_exclude UUID[] DEFAULT '{}'
)
RETURNS TABLE (creator_id UUID, score numeric)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    c.id      AS creator_id,
    0::numeric AS score
  FROM creator c
  WHERE
    c.id <> ALL(p_exclude)
    AND (
      c.created_at >= now() - interval '60 days'
      OR EXISTS (
        SELECT 1 FROM recipe r
        WHERE r.creator_id = c.id
          AND r.is_published = true
          AND r.created_at >= now() - interval '30 days'
      )
    )
    AND NOT EXISTS (
      SELECT 1 FROM fan_subscription fs
      WHERE fs.creator_id = c.id
        AND fs.user_id = p_user_id
        AND fs.status = 'active'
    )
  ORDER BY c.created_at DESC
  LIMIT LEAST(p_limit, 20);
END;
$$;
```

- [ ] **Step 2: Apply the migration**

```bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
npx supabase db push
```

Expected: Migration applies cleanly. If `creator.created_at` column doesn't exist, add `ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now()` before the functions in the same migration.

- [ ] **Step 3: Verify table and functions exist**

```bash
npx supabase db execute --command "SELECT column_name FROM information_schema.columns WHERE table_name = 'creator_vector';"
npx supabase db execute --command "SELECT proname FROM pg_proc WHERE proname LIKE 'generate_creators%';"
```

Expected: `creator_id`, `vector`, `last_computed`, `recipe_count_sampled` columns; 3 function names returned.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260530000001_creator_vector_feed.sql
git commit -m "feat(db): add creator_vector table and generate_creators_* feed RPCs"
```

---

## Task 2: Database Helpers

**Files:**
- Modify: `python/engine/database.py`

- [ ] **Step 1: Write the failing tests**

Add to `python/tests/test_vectorization.py` (import section at top already has `pytest`, `patch`, `numpy`):

```python
# --- creator vector database helper tests (offline, no DB needed) ---

def test_upsert_creator_vector_signature():
    """upsert_creator_vector must accept (creator_id, vector, recipe_count_sampled)."""
    from engine.database import upsert_creator_vector
    import inspect
    sig = inspect.signature(upsert_creator_vector)
    params = list(sig.parameters.keys())
    assert params == ['creator_id', 'vector', 'recipe_count_sampled']
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app\python"
python -m pytest tests/test_vectorization.py::test_upsert_creator_vector_signature -v
```

Expected: `ImportError` or `AssertionError` — function not yet defined.

- [ ] **Step 3: Add the three helper functions to `database.py`**

Append after `upsert_recipe_vector` (end of file):

```python
# ---------------------------------------------------------------------------
# Creator helpers
# ---------------------------------------------------------------------------

def get_all_creators() -> list[str]:
    """Retourne les creator_ids ayant au moins une recette publiée."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT DISTINCT c.id
                FROM creator c
                WHERE c.recipe_count >= 1
            """)
            return [row[0] for row in cur.fetchall()]


def get_creator_recipe_vectors(creator_id: str) -> list[np.ndarray]:
    """
    Retourne les vecteurs de toutes les recettes publiées d'un créateur.
    Retourne une liste vide si aucun recipe_vector n'existe encore pour ce créateur.
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT rv.vector
                FROM recipe_vector rv
                JOIN recipe r ON r.id = rv.recipe_id
                WHERE r.creator_id = %s
                  AND r.is_published = true
            """, (creator_id,))
            rows = cur.fetchall()
            if not rows:
                return []
            # psycopg2 returns pgvector as a string like '[0.1,0.2,...]'
            # Convert each to a float32 numpy array
            result = []
            for row in rows:
                raw = row[0]
                if isinstance(raw, str):
                    nums = [float(x) for x in raw.strip('[]').split(',')]
                    result.append(np.array(nums, dtype=np.float32))
                else:
                    result.append(np.array(raw, dtype=np.float32))
            return result


def upsert_creator_vector(creator_id: str, vector: np.ndarray, recipe_count_sampled: int):
    """Stocke ou met à jour le creator_vector dans PostgreSQL."""
    vector_list = vector.tolist()
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO creator_vector
                    (creator_id, vector, last_computed, recipe_count_sampled)
                VALUES (%s, %s::vector, NOW(), %s)
                ON CONFLICT (creator_id) DO UPDATE SET
                    vector               = EXCLUDED.vector,
                    last_computed        = NOW(),
                    recipe_count_sampled = EXCLUDED.recipe_count_sampled
            """, (creator_id, str(vector_list), recipe_count_sampled))
        conn.commit()
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app\python"
python -m pytest tests/test_vectorization.py::test_upsert_creator_vector_signature -v
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add python/engine/database.py python/tests/test_vectorization.py
git commit -m "feat(python): add get_all_creators, get_creator_recipe_vectors, upsert_creator_vector"
```

---

## Task 3: compute_creator_vector Function

**Files:**
- Modify: `python/engine/vectorization.py`
- Modify: `python/tests/test_vectorization.py`

- [ ] **Step 1: Write the failing tests**

Add to `python/tests/test_vectorization.py` after the existing recipe tests:

```python
# --- compute_creator_vector ---

@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_success(mock_get_vectors):
    """Returns L2-normalized 50D centroid of recipe vectors."""
    from engine.vectorization import compute_creator_vector
    # Two recipe vectors with known values
    v1 = np.zeros(50, dtype=np.float32)
    v1[0] = 1.0
    v2 = np.zeros(50, dtype=np.float32)
    v2[0] = 0.5
    v2[1] = 0.5
    mock_get_vectors.return_value = [v1, v2]

    result = compute_creator_vector("creator_abc")

    assert result is not None
    assert isinstance(result, np.ndarray)
    assert len(result) == 50
    # Must be L2-normalized
    assert np.isclose(np.linalg.norm(result), 1.0, atol=1e-6)
    # Centroid before normalization: [0.75, 0.25, 0, ...] → check direction preserved
    assert result[0] > result[1]


@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_no_recipes(mock_get_vectors):
    """Returns None when creator has no recipe vectors."""
    from engine.vectorization import compute_creator_vector
    mock_get_vectors.return_value = []

    result = compute_creator_vector("creator_no_recipes")

    assert result is None


@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_single_recipe(mock_get_vectors):
    """Single recipe vector — centroid equals that recipe vector."""
    from engine.vectorization import compute_creator_vector
    v = np.zeros(50, dtype=np.float32)
    v[10] = 1.0  # only region dim
    mock_get_vectors.return_value = [v]

    result = compute_creator_vector("creator_one_recipe")

    assert result is not None
    # Single recipe: centroid = that vector = already normalized (norm=1)
    assert np.isclose(np.linalg.norm(result), 1.0, atol=1e-6)
    assert result[10] == pytest.approx(1.0, abs=1e-5)


@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_zero_norm(mock_get_vectors):
    """Returns None if centroid is all-zeros (degenerate case)."""
    from engine.vectorization import compute_creator_vector
    v = np.zeros(50, dtype=np.float32)
    mock_get_vectors.return_value = [v]

    result = compute_creator_vector("creator_zero")

    assert result is None
```

- [ ] **Step 2: Run to verify they fail**

```bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app\python"
python -m pytest tests/test_vectorization.py -k "creator_vector" -v
```

Expected: 4 FAILs — `ImportError: cannot import name 'compute_creator_vector'`.

- [ ] **Step 3: Add the import in `vectorization.py`**

At the top of `python/engine/vectorization.py`, add `get_creator_recipe_vectors` to the existing import block:

```python
from .database import (
    get_user_health_profile,
    get_recipe_data,
    get_recipe_consumption_stats,
    get_creator_recipe_vectors,   # new
)
```

- [ ] **Step 4: Add `compute_creator_vector` to `vectorization.py`**

Append after `compute_recipe_vector` (end of file):

```python
# ---------------------------------------------------------------------------
# CREATOR VECTOR
# ---------------------------------------------------------------------------

def compute_creator_vector(creator_id: str) -> Optional[np.ndarray]:
    """
    Compute the creator vector as the L2-normalized average of all
    published recipe vectors for this creator.

    The result lives in the same 50D semantic space as user_vector and
    recipe_vector, so cosine similarity with user_vector is directly
    interpretable as creator–user alignment.

    Returns None if:
    - no published recipe vectors exist yet for this creator
    - the centroid has zero norm (degenerate case — all recipes all-zero)
    """
    recipe_vectors = get_creator_recipe_vectors(creator_id)
    if not recipe_vectors:
        return None

    # Stack into matrix and compute unweighted mean — shape (50,)
    matrix = np.stack(recipe_vectors, axis=0)           # (N, 50)
    centroid = np.mean(matrix, axis=0).astype(np.float32)  # (50,)

    return _normalize_l2(centroid)  # returns None-equivalent via norm guard
```

Note: `_normalize_l2` already guards `norm > 1e-10` — when norm ≤ 1e-10 it returns the un-normalized vector (near-zero). The test for zero norm expects `None`, so update the function to return `None` on degenerate input:

```python
def compute_creator_vector(creator_id: str) -> Optional[np.ndarray]:
    recipe_vectors = get_creator_recipe_vectors(creator_id)
    if not recipe_vectors:
        return None

    matrix = np.stack(recipe_vectors, axis=0)
    centroid = np.mean(matrix, axis=0).astype(np.float32)

    norm = np.linalg.norm(centroid)
    if norm <= 1e-10:
        return None

    return centroid / norm
```

- [ ] **Step 5: Run tests to verify all 4 pass**

```bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app\python"
python -m pytest tests/test_vectorization.py -k "creator_vector" -v
```

Expected: 4 PASSes.

- [ ] **Step 6: Run full test suite to check for regressions**

```bash
python -m pytest tests/ -v
```

Expected: All existing tests still pass + 4 new creator tests pass.

- [ ] **Step 7: Commit**

```bash
git add python/engine/vectorization.py python/tests/test_vectorization.py
git commit -m "feat(python): add compute_creator_vector (L2-normalized centroid of recipe vectors)"
```

---

## Task 4: Batch Integration

**Files:**
- Modify: `python/main.py`

- [ ] **Step 1: Add imports to `main.py`**

In `main.py`, extend the existing import blocks:

```python
# In the engine.vectorization import line, add compute_creator_vector:
from engine.vectorization import compute_user_vector, compute_recipe_vector, compute_creator_vector

# In the engine.database import block, add the three new helpers:
from engine.database import (
    upsert_user_vector,
    upsert_recipe_vector,
    get_active_users,
    get_pending_recipes,
    get_all_creators,           # new
    upsert_creator_vector,      # new
)
```

- [ ] **Step 2: Add the `/compute-creator-vector` endpoint**

Add after the `/compute-recipe-vector` endpoint (before the `/nightly-batch` endpoint):

```python
class CreatorVectorRequest(BaseModel):
    creator_id: str


@app.post("/compute-creator-vector")
async def api_compute_creator_vector(request: CreatorVectorRequest):
    """
    Calcule et stocke le creator_vector pour un créateur.
    Appelé manuellement ou depuis le batch nightly.
    Requiert que les recipe_vectors du créateur soient déjà calculés.
    """
    try:
        vector = compute_creator_vector(request.creator_id)
        if vector is None:
            raise HTTPException(
                status_code=404,
                detail="Creator not found or no published recipe vectors available"
            )
        # get_all_creators returns IDs with recipe_count >= 1;
        # count sampled = number of vectors that went into the mean
        from engine.database import get_creator_recipe_vectors
        recipe_count = len(get_creator_recipe_vectors(request.creator_id))
        upsert_creator_vector(request.creator_id, vector, recipe_count)
        return {
            "creator_id": request.creator_id,
            "vector_computed": True,
            "dimensions": len(vector),
            "recipe_count_sampled": recipe_count,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

- [ ] **Step 3: Add creator step to `run_nightly_batch()`**

In `run_nightly_batch()`, after the recipe vectors block (after the `logger.info(f"[nightly-batch] Recipe vectors: ...")` line), add:

```python
    # --- 3. Creator vectors ---
    # Must run AFTER recipe vectors — creator vectors are derived from them.
    all_creators = get_all_creators()
    logger.info(f"[nightly-batch] Processing {len(all_creators)} creators")

    creator_success = 0
    for creator_id in all_creators:
        try:
            vector = compute_creator_vector(creator_id)
            if vector is not None:
                from engine.database import get_creator_recipe_vectors
                recipe_count = len(get_creator_recipe_vectors(creator_id))
                upsert_creator_vector(creator_id, vector, recipe_count)
                creator_success += 1
        except Exception as e:
            logger.error(f"[nightly-batch] Creator {creator_id} failed: {e}")

    logger.info(f"[nightly-batch] Creator vectors: {creator_success}/{len(all_creators)} updated")
```

- [ ] **Step 4: Verify the file parses cleanly**

```bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app\python"
python -c "import main; print('OK')"
```

Expected: `OK` with no import errors.

- [ ] **Step 5: Run full test suite**

```bash
python -m pytest tests/ -v
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add python/main.py
git commit -m "feat(python): add creator vectors to nightly batch and /compute-creator-vector endpoint"
```

---

## Task 5: Integration Smoke Test

Manual verification that the full pipeline works end-to-end.

- [ ] **Step 1: Apply migration to local Supabase**

```bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
npx supabase db push
```

Expected: Migration `20260530000001_creator_vector_feed.sql` applied.

- [ ] **Step 2: Verify `creator_vector` table is empty initially**

```bash
npx supabase db execute --command "SELECT COUNT(*) FROM creator_vector;"
```

Expected: `0`.

- [ ] **Step 3: Trigger the batch endpoint manually**

```bash
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app\python"
# Start server if not running:
# python main.py &
# Then call the nightly batch endpoint with the BATCH_SECRET from .env
curl -s -X POST http://localhost:8000/nightly-batch \
  -H "Content-Type: application/json" \
  -d '{"secret": "'"$BATCH_SECRET"'"}'
```

Expected: `{"status": "batch_started", "message": "Running in background"}`. Check logs for `[nightly-batch] Creator vectors: N/N updated`.

- [ ] **Step 4: Verify creator vectors were written**

```bash
npx supabase db execute --command "SELECT creator_id, recipe_count_sampled, last_computed FROM creator_vector LIMIT 5;"
```

Expected: Rows with non-null vectors, `recipe_count_sampled > 0`.

- [ ] **Step 5: Verify feed RPC returns results**

```bash
npx supabase db execute --command "
  SELECT generate_creators_personalized(
    (SELECT id FROM user_profile LIMIT 1),
    5
  );
"
```

Expected: Up to 5 rows with `creator_id` and `score`.

- [ ] **Step 6: Commit smoke test sign-off**

```bash
git commit --allow-empty -m "test(creators): smoke test pass — creator vectors computed, feed RPCs return results"
```
