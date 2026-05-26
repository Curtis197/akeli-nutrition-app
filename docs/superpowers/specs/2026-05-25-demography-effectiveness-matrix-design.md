# Akeli — Demographic Effectiveness Matrix Design

**Date:** 2026-05-25
**Status:** Approved — implementation deferred (not required for V1 launch)
**Branch:** `demography-matrix` (to be created when implementation begins)

---

## Overview

A hidden recommendation layer that tracks, per recipe, how well each recipe performs for a given demographic over time. It runs as a weekly batch, produces two scalar signals per (recipe, demographic) pair — **retention** (is this recipe re-selected?) and **effectiveness** (does it produce goal-aligned weight change?) — and injects those signals into the recipe recommendation pipeline as additional vector dimensions.

The system is invisible to users. Creators can see their own recipe scores. The goal is to improve long-term user retention by surfacing recipes that genuinely work for the user's demographic and goal, not just recipes that look good on paper.

---

## Architecture Overview

```
weekly_batch
│
├── compute_recipe_retention()
│   └── (recipe, demography_bucket) → retention score [0, 1]
│
└── compute_recipe_effectiveness()
    └── (recipe, demography_bucket, goal) → effectiveness score [0, 1]
│
└── upsert into recipe_demography_score
│
└── rebuild recipe_retention_vector(40) and recipe_effectiveness_vector(40)
```

At query time the recommendation RPC does:

```sql
retention_score   := recipe_retention_vector   <#> user_demographic_vector * -1
effectiveness_score := recipe_effectiveness_vector <#> user_demographic_vector * -1
```

The `<#>` pgvector operator returns negative inner product; negate to get dot product. Because only one element in `user_demographic_vector` is non-zero (the user's bucket), the result is the scalar stored at the user's bucket index.

---

## Demography Bucket System

### Table: `demography_bucket`

Shared between nutrition and beauty modes. Schema is granular from day one; V1 uses wide ranges. V2 appends finer rows (`18–21`, `22–25`) for the same age bracket without any schema change.

```sql
CREATE TABLE demography_bucket (
  id          serial PRIMARY KEY,
  age_min     int NOT NULL,
  age_max     int NOT NULL,
  gender      text NOT NULL CHECK (gender IN ('male', 'female', 'other', 'any')),
  label       text NOT NULL UNIQUE,  -- e.g. 'female_18_25'
  vector_idx  int  NOT NULL UNIQUE   -- 0-based index into 40D vectors
);
```

**V1 initial rows (40 total slots, ~12 active):**

| id | age_min | age_max | gender | label | vector_idx |
|----|---------|---------|--------|-------|-----------|
| 1 | 18 | 25 | female | female_18_25 | 0 |
| 2 | 18 | 25 | male | male_18_25 | 1 |
| 3 | 26 | 35 | female | female_26_35 | 2 |
| 4 | 26 | 35 | male | male_26_35 | 3 |
| 5 | 36 | 45 | female | female_36_45 | 4 |
| 6 | 36 | 45 | male | male_36_45 | 5 |
| 7 | 46 | 60 | female | female_46_60 | 6 |
| 8 | 46 | 60 | male | male_46_60 | 7 |
| 9 | 18 | 99 | other | other_18_99 | 8 |
| … | … | … | … | … | 9–39 (reserved) |

`vector_idx` values 9–39 are reserved for future buckets. Once `vector_idx` is assigned to a bucket, it never changes.

### Bucket Resolution

A user's bucket is resolved from their health profile at query time:

```sql
SELECT id, vector_idx
FROM demography_bucket
WHERE age_min <= user_age AND user_age <= age_max
  AND (gender = user_gender OR gender = 'any')
ORDER BY (age_max - age_min) ASC  -- prefer most specific bucket
LIMIT 1;
```

When V2 appends `female_18_21` and `female_22_25`, users in those ranges automatically start using the finer bucket. Historical scores for the old `female_18_25` bucket remain and are still valid for users that fall back to it (e.g., `gender = 'other'` with no finer bucket).

### Hierarchical Fallback

When a bucket has `sample_size < 10`, the recommendation RPC falls back to the next-widest bucket. This is implemented as a SQL function `resolve_user_bucket(user_id)` that walks from finest to widest until a bucket with sufficient samples is found.

---

## Score Tables

### Table: `recipe_demography_score`

One row per (recipe, demography_bucket). Updated weekly by the batch.

```sql
CREATE TABLE recipe_demography_score (
  recipe_id           uuid    NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  demography_id       int     NOT NULL REFERENCES demography_bucket(id),
  goal                text    NOT NULL CHECK (goal IN ('weight_loss', 'muscle_gain', 'maintenance', 'health', 'performance')),

  -- Retention: proportion of users in this demography who, having tried this recipe,
  -- added it to a subsequent meal plan within 30 days.
  retention_score     float   NOT NULL DEFAULT 0,
  retention_sample    int     NOT NULL DEFAULT 0,

  -- Effectiveness: avg(consumption_pct × goal_aligned_diff) over consumed meal plans.
  -- Only meal plans where the recipe was actually consumed (consumption_pct > 0) count.
  effectiveness_score float   NOT NULL DEFAULT 0,
  effectiveness_sample int   NOT NULL DEFAULT 0,

  -- Confidence weights applied to both scores during vector rebuild:
  -- confidence = min(sample_size / 50, 1.0)
  -- stored score = confidence × raw_score

  updated_at          timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (recipe_id, demography_id, goal)
);
```

---

## Vectors

Three new pgvector columns, **not** on the existing `recipe_vector` / `user_vector` tables. They live separately to avoid polluting the 50D nutrition property space.

### `recipe_retention_vector(40)` and `recipe_effectiveness_vector(40)`

Added to the `recipe_vector` table as separate columns:

```sql
ALTER TABLE recipe_vector
  ADD COLUMN retention_vector  vector(40),
  ADD COLUMN effectiveness_vector vector(40);
```

Each element `i` holds the confidence-weighted score for `demography_bucket.vector_idx = i`. Zero for buckets with no data.

### `user_demographic_vector(40)`

Added to the `user_vector` table:

```sql
ALTER TABLE user_vector
  ADD COLUMN demographic_vector vector(40);
```

`1.0` at the user's current bucket's `vector_idx`, `0.0` everywhere else. Rebuilt by `complete-onboarding` edge function and by a separate daily batch that re-resolves buckets when a user's age passes a boundary.

These vectors are **not L2-normalised**. The dot product `retention_vector <#> demographic_vector` returns the raw score at the user's bucket index directly.

---

## Effectiveness Score Formula

```
effectiveness(R, D, G) = AVG( consumption_pct(R, P) × goal_aligned_diff(u, P, G) )
```

**Scope:** over all meal plans P where:
- The meal plan belongs to a user u in demographic bucket D
- The meal plan has goal G
- Recipe R appears in the meal plan
- `consumption_pct(R, P) > 0` — **zero-consumption observations are excluded entirely**

**Terms:**

```
consumption_pct(R, P) = consumed_entries(R, P) / planned_entries(R, P)  ∈ (0, 1]
```

Only counts meal plans where the recipe was consumed at least once. Acts as a relevance weight — a recipe barely consumed barely influences the score.

```
goal_aligned_diff(u, P, G):
  raw_diff = (weight_end - weight_start) / plan_weeks   (kg/week)

  weight_loss:   -raw_diff          (loss = positive outcome)
  muscle_gain:   +raw_diff          (gain = positive outcome)
  maintenance:   1 - |raw_diff| / threshold   (threshold = 0.2 kg/week)
  health:        same as maintenance
  performance:   same as maintenance

  clip to [-1, 1]
```

**Weight measurement tolerance:** ±3 days from `meal_plan.start_date` and `meal_plan.end_date` for matching `weight_log` rows.

**Storage:** shift `[-1, 1]` → `[0, 1]`: `stored = (score + 1) / 2`.

**Confidence weighting:**

```
confidence = min(sample_size / 50, 1.0)
vector[bucket.vector_idx] = confidence × raw_score_shifted
```

At `sample_size < 50` the score is dampened toward zero (neutral). At 50+ observations the full score is used.

---

## Retention Score Formula

```
retention(R, D) = reuse_count(R, D) / user_count(R, D)
```

Where:
- `user_count(R, D)` = distinct users in bucket D who had recipe R in at least one meal plan
- `reuse_count(R, D)` = users in bucket D who added recipe R to a second meal plan within 30 days of the first

Same confidence weighting applied before vector storage.

---

## Python Implementation Sketch

### `compute_recipe_effectiveness(recipe_id, demography_id, goal)`

```python
sql = """
WITH observations AS (
  SELECT
    mp.id              AS plan_id,
    mp.user_id,
    mp.goal,
    mp.start_date,
    mp.end_date,
    -- consumption_pct for this recipe in this plan
    COUNT(DISTINCT mpe.id)::float                   AS planned_count,
    COUNT(DISTINCT mc.id)::float                    AS consumed_count,
    COUNT(DISTINCT mc.id)::float /
      NULLIF(COUNT(DISTINCT mpe.id)::float, 0)       AS consumption_pct,
    -- weight measurements (±3 day tolerance)
    w_start.weight_kg  AS weight_start,
    w_end.weight_kg    AS weight_end,
    EXTRACT(EPOCH FROM (mp.end_date - mp.start_date))
      / 604800.0       AS plan_weeks
  FROM meal_plan mp
  JOIN meal_plan_entry mpe ON mpe.meal_plan_id = mp.id
    AND mpe.recipe_id = :recipe_id
  LEFT JOIN meal_consumption mc ON mc.meal_plan_entry_id = mpe.id
    AND mc.consumed = true
  JOIN user_health_profile uhp ON uhp.user_id = mp.user_id
  JOIN demography_bucket db ON db.id = :demography_id
    AND uhp.age BETWEEN db.age_min AND db.age_max
    AND (db.gender = uhp.gender OR db.gender = 'any')
  LEFT JOIN weight_log w_start ON w_start.user_id = mp.user_id
    AND w_start.logged_at BETWEEN mp.start_date - INTERVAL '3 days'
                               AND mp.start_date + INTERVAL '3 days'
  LEFT JOIN weight_log w_end   ON w_end.user_id = mp.user_id
    AND w_end.logged_at BETWEEN mp.end_date - INTERVAL '3 days'
                             AND mp.end_date + INTERVAL '3 days'
  WHERE mp.goal = :goal
  GROUP BY mp.id, mp.user_id, mp.goal, mp.start_date, mp.end_date,
           w_start.weight_kg, w_end.weight_kg
  -- Only include observations where the recipe was consumed at least once
  HAVING SUM(CASE WHEN mc.id IS NOT NULL THEN 1 ELSE 0 END) > 0
    AND w_start.weight_kg IS NOT NULL
    AND w_end.weight_kg IS NOT NULL
)
SELECT
  AVG(consumption_pct * goal_aligned_diff) AS raw_score,
  COUNT(*)                                  AS sample_size
FROM (
  SELECT
    consumption_pct,
    GREATEST(-1, LEAST(1,
      CASE :goal
        WHEN 'weight_loss'  THEN -(weight_end - weight_start) / plan_weeks
        WHEN 'muscle_gain'  THEN  (weight_end - weight_start) / plan_weeks
        ELSE 1 - ABS((weight_end - weight_start) / plan_weeks) / 0.2
      END
    )) AS goal_aligned_diff
  FROM observations
) scored
"""
```

---

## Recommendation RPC Integration

In `generate_feed_personalized` (or a post-ranking step):

```sql
-- dot product: returns score at user's demographic bucket
retention_bonus     := (rv.retention_vector     <#> v_demographic) * -1;
effectiveness_bonus := (rv.effectiveness_vector <#> v_demographic) * -1;

-- Combined re-rank score (weights TBD, start with small values):
final_score := base_cosine_score
             + 0.05 * retention_bonus
             + 0.10 * effectiveness_bonus;
```

Weights are configurable. Start conservative (0.05/0.10) to avoid over-fitting to early sparse data. Adjust once sample sizes mature.

---

## Creator Score Visibility

Creators can query their own recipe's aggregate scores:

```sql
SELECT
  db.label           AS demographic,
  rds.goal,
  rds.effectiveness_score,
  rds.effectiveness_sample,
  rds.retention_score,
  rds.retention_sample
FROM recipe_demography_score rds
JOIN demography_bucket db ON db.id = rds.demography_id
WHERE rds.recipe_id = :recipe_id
ORDER BY rds.effectiveness_sample DESC;
```

Scores with `sample_size < 10` are hidden from creator dashboards (shown as "not enough data yet").

---

## Weekly Batch Schedule

```
Sunday 03:00 UTC
  1. for each (recipe, demography_bucket, goal) with new activity this week:
     a. compute_recipe_effectiveness(recipe_id, demography_id, goal)
     b. compute_recipe_retention(recipe_id, demography_id)
     c. upsert into recipe_demography_score
  2. rebuild retention_vector and effectiveness_vector for updated recipes
  3. rebuild demographic_vector for users whose age passed a bucket boundary
```

The update is **incremental** (rolling EMA optional for V2). V1: recompute from full history each week. At scale, switch to EMA with decay factor α ≈ 0.3.

---

## Relationship to Beauty Mode

`demography_bucket` is shared. When beauty mode implements its own effectiveness tracking (post-V1), it reuses the same bucket table and the same `vector_idx` mapping. Beauty recipes get separate `beauty_demography_score` and `beauty_retention_vector` / `beauty_effectiveness_vector` columns on `beauty_recipe_vector`.

---

## Out of Scope (V1)

- Ingredient-level effectiveness attribution
- Per-allergen or per-restriction breakdowns
- Cross-goal correlation (e.g., a weight_loss recipe that also improves performance)
- Real-time score updates (weekly batch only)
- Fine-grained buckets below 18–25 age ranges

---

## Implementation Order

1. Migration: `demography_bucket` table + seed V1 rows
2. Migration: `recipe_demography_score` table
3. Migration: `ALTER TABLE recipe_vector ADD COLUMN retention_vector / effectiveness_vector`
4. Migration: `ALTER TABLE user_vector ADD COLUMN demographic_vector`
5. Python: `compute_recipe_effectiveness()` + `compute_recipe_retention()`
6. Python: vector rebuild function
7. Python: weekly batch scheduler entry
8. Edge function: `complete-onboarding` — resolve and set `demographic_vector` on signup
9. RPC: update `generate_feed_personalized` to include re-rank step
10. Creator API: endpoint for recipe score visibility
