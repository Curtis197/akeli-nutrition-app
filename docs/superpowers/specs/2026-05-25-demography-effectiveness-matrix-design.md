# Akeli — Demographic Effectiveness Matrix Design

**Date:** 2026-05-25  
**Status:** Approved — implementation deferred (not required for V1 launch)  
**Branch:** `demography-matrix` (to be created when implementation begins)

---

## Overview

A hidden recommendation layer that tracks, per recipe, how well each recipe performs for each demographic signal over time. It runs as a weekly batch, produces two scalar scores per (recipe, axis_bucket) pair — **retention** and **effectiveness** — and injects those into the recommendation pipeline via pgvector dot products.

The system is invisible to users. Creators can see their own recipe scores. The goal is to surface recipes that genuinely work for the user's demographic profile, not just recipes with high overall consumption — preventing popular recipes from permanently crowding out newer, better-targeted ones.

---

## Core Design Principle

A user's demographic profile is **not** a single composite bucket. It is a set of independent axis signals. A 28F halal weight_loss moderate-activity user occupies five independent positions in a 200D vector — one per axis. Each position accumulates its own score independently.

This avoids combinatorial explosion:
- Single composite bucket approach: 30 × 25 × 12 × 5 × 13 = **585,000 combinations** (~3M users needed for meaningful data everywhere)
- Multi-axis approach: 30 + 25 + 12 + 5 + 13 = **85 axis buckets** (~425 users needed for full coverage)

A recipe accumulates at most **85 independent scores**. Each score grows at its own pace. Low sample sizes produce low-trust scores, not zero scores — preventing popular recipes from dominating through sheer data volume.

---

## 200D Vector Layout

```
Dims   0– 49  │ Age × gender        │ 30 active, 20 reserved
Dims  50– 74  │ Goal × activity     │ 25 active (complete grid)
Dims  75– 94  │ BMI range × gender  │ 12 active, 8 reserved
Dims  95–109  │ Dietary type        │  5 active, 10 reserved
Dims 110–124  │ Cuisine origin      │ 13 active, 2 reserved
Dims 125–199  │ Reserved            │ future axes
```

---

## Axis Bucket Table

### Table: `demography_bucket`

Shared between nutrition and beauty modes. `axis` identifies which segment the bucket belongs to. `vector_idx` is the position in the 200D vectors — assigned once, never changed.

```sql
CREATE TABLE demography_bucket (
  id          serial PRIMARY KEY,
  axis        text NOT NULL CHECK (axis IN (
                'age_gender', 'goal_activity', 'bmi_gender',
                'dietary', 'cuisine_origin'
              )),
  label       text NOT NULL UNIQUE,   -- e.g. 'female_26_35', 'weight_loss_moderate'
  vector_idx  int  NOT NULL UNIQUE,   -- 0-based index into 200D vectors
  -- axis-specific columns (nullable depending on axis type)
  age_min     int,
  age_max     int,
  gender      text CHECK (gender IN ('male', 'female', 'other', 'any')),
  goal        text CHECK (goal IN ('weight_loss','muscle_gain','maintenance','health','performance')),
  activity    text CHECK (activity IN ('sedentary','light','moderate','active','very_active')),
  bmi_min     float,
  bmi_max     float,
  dietary     text,
  cuisine     text
);
```

### V1 Seed Rows

**Axis 1 — Age × gender (dims 0–49)**

| label | vector_idx | age_min | age_max | gender |
|---|---|---|---|---|
| female_18_25 | 0 | 18 | 25 | female |
| male_18_25 | 1 | 18 | 25 | male |
| other_18_25 | 2 | 18 | 25 | other |
| female_26_35 | 3 | 26 | 35 | female |
| male_26_35 | 4 | 26 | 35 | male |
| other_26_35 | 5 | 26 | 35 | other |
| female_36_45 | 6 | 36 | 45 | female |
| male_36_45 | 7 | 36 | 45 | male |
| other_36_45 | 8 | 36 | 45 | other |
| female_46_60 | 9 | 46 | 60 | female |
| male_46_60 | 10 | 46 | 60 | male |
| other_46_60 | 11 | 46 | 60 | other |
| female_61_99 | 12 | 61 | 99 | female |
| male_61_99 | 13 | 61 | 99 | male |
| other_61_99 | 14 | 61 | 99 | other |
| *(dims 15–49 reserved for finer splits e.g. 18–21, 22–25)* | | | | |

**Axis 2 — Goal × activity (dims 50–74, complete grid)**

| label | vector_idx | goal | activity |
|---|---|---|---|
| weight_loss_sedentary | 50 | weight_loss | sedentary |
| weight_loss_light | 51 | weight_loss | light |
| weight_loss_moderate | 52 | weight_loss | moderate |
| weight_loss_active | 53 | weight_loss | active |
| weight_loss_very_active | 54 | weight_loss | very_active |
| muscle_gain_sedentary | 55 | muscle_gain | sedentary |
| muscle_gain_light | 56 | muscle_gain | light |
| muscle_gain_moderate | 57 | muscle_gain | moderate |
| muscle_gain_active | 58 | muscle_gain | active |
| muscle_gain_very_active | 59 | muscle_gain | very_active |
| maintenance_sedentary | 60 | maintenance | sedentary |
| maintenance_light | 61 | maintenance | light |
| maintenance_moderate | 62 | maintenance | moderate |
| maintenance_active | 63 | maintenance | active |
| maintenance_very_active | 64 | maintenance | very_active |
| health_sedentary | 65 | health | sedentary |
| health_light | 66 | health | light |
| health_moderate | 67 | health | moderate |
| health_active | 68 | health | active |
| health_very_active | 69 | health | very_active |
| performance_sedentary | 70 | performance | sedentary |
| performance_light | 71 | performance | light |
| performance_moderate | 72 | performance | moderate |
| performance_active | 73 | performance | active |
| performance_very_active | 74 | performance | very_active |

**Axis 3 — BMI range × gender (dims 75–94)**

BMI tiers: underweight (<18.5), normal (18.5–24.9), overweight (25–29.9), obese (≥30).

| label | vector_idx | bmi_min | bmi_max | gender |
|---|---|---|---|---|
| underweight_female | 75 | 0 | 18.5 | female |
| underweight_male | 76 | 0 | 18.5 | male |
| underweight_other | 77 | 0 | 18.5 | other |
| normal_bmi_female | 78 | 18.5 | 24.9 | female |
| normal_bmi_male | 79 | 18.5 | 24.9 | male |
| normal_bmi_other | 80 | 18.5 | 24.9 | other |
| overweight_female | 81 | 25 | 29.9 | female |
| overweight_male | 82 | 25 | 29.9 | male |
| overweight_other | 83 | 25 | 29.9 | other |
| obese_female | 84 | 30 | 99 | female |
| obese_male | 85 | 30 | 99 | male |
| obese_other | 86 | 30 | 99 | other |
| *(dims 87–94 reserved)* | | | | |

**Axis 4 — Dietary type (dims 95–109)**

| label | vector_idx | dietary |
|---|---|---|
| omnivore | 95 | omnivore |
| vegetarian | 96 | vegetarian |
| vegan | 97 | vegan |
| halal | 98 | halal |
| other_dietary | 99 | other |
| *(dims 100–109 reserved)* | | |

**Axis 5 — Cuisine origin (dims 110–124)**

Maps to the 13 cuisine regions in the nutrition 50D space (dims 10–22).

| label | vector_idx | cuisine |
|---|---|---|
| origin_west_africa | 110 | West Africa |
| origin_central_africa | 111 | Central Africa |
| origin_east_africa | 112 | East Africa |
| origin_north_africa | 113 | North Africa |
| origin_south_africa | 114 | South Africa |
| origin_caribbean | 115 | Caribbean |
| origin_france | 116 | France |
| origin_mediterranean | 117 | Mediterranean |
| origin_middle_east | 118 | Middle East |
| origin_south_asia | 119 | South Asia |
| origin_southeast_asia | 120 | Southeast Asia |
| origin_latin_america | 121 | Latin America |
| origin_north_america | 122 | North America |
| *(dims 123–124 reserved)* | | |

### Bucket Resolution

A user resolves exactly **one bucket per axis** (5 total) from their health profile:

```sql
-- Example: resolve axis_bucket ids for a given user
SELECT db.id, db.vector_idx, db.axis
FROM demography_bucket db
JOIN user_health_profile uhp ON uhp.user_id = :user_id
WHERE
  (db.axis = 'age_gender'
    AND uhp.age BETWEEN db.age_min AND db.age_max
    AND db.gender = uhp.gender)
  OR
  (db.axis = 'goal_activity'
    AND db.goal = uhp.goal
    AND db.activity = uhp.activity_level)
  OR
  (db.axis = 'bmi_gender'
    AND (uhp.weight_kg / ((uhp.height_cm/100.0)^2)) BETWEEN db.bmi_min AND db.bmi_max
    AND db.gender = uhp.gender)
  OR
  (db.axis = 'dietary'
    AND db.dietary = COALESCE(uhp.dietary_restriction, 'omnivore'))
  OR
  (db.axis = 'cuisine_origin'
    AND db.cuisine = uhp.primary_cuisine_origin);
```

When V2 appends finer age buckets (`female_18_21`, `female_22_25`), users in those ranges start using the finer bucket automatically. Historical scores for `female_18_25` remain valid.

---

## Score Table

### Table: `recipe_demography_score`

One row per (recipe, axis_bucket). No goal column — goal is already captured by the `goal_activity` axis buckets.

```sql
CREATE TABLE recipe_demography_score (
  recipe_id            uuid  NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  bucket_id            int   NOT NULL REFERENCES demography_bucket(id),

  -- Effectiveness: avg(consumption_pct × goal_aligned_diff)
  -- Only meal plans where consumption_pct > 0 are included.
  effectiveness_raw    float NOT NULL DEFAULT 0,   -- [-1, 1] pre-shift
  effectiveness_sample int   NOT NULL DEFAULT 0,
  effectiveness_last_at timestamptz,

  -- Retention: proportion of users who re-added this recipe within 30 days
  retention_raw        float NOT NULL DEFAULT 0,   -- [0, 1]
  retention_sample     int   NOT NULL DEFAULT 0,
  retention_last_at    timestamptz,

  updated_at           timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (recipe_id, bucket_id)
);
```

---

## Vectors

Three new columns on existing tables. Not merged into the 50D nutrition property vectors.

```sql
-- On recipe_vector table
ALTER TABLE recipe_vector
  ADD COLUMN effectiveness_vector vector(200),
  ADD COLUMN retention_vector     vector(200);

-- On user_vector table
ALTER TABLE user_vector
  ADD COLUMN demographic_vector vector(200);
```

### `user_demographic_vector(200)`

Multi-hot: `1.0` at the user's 5 axis bucket positions, `0.0` everywhere else.

```
Example — Fatima (28F, weight_loss, moderate, normal BMI, halal, West Africa):
  dim 3   (female_26_35)         = 1.0
  dim 52  (weight_loss_moderate) = 1.0
  dim 78  (normal_bmi_female)    = 1.0
  dim 98  (halal)                = 1.0
  dim 110 (origin_west_africa)   = 1.0
  all other 195 dims             = 0.0
```

### `recipe_effectiveness_vector(200)` and `recipe_retention_vector(200)`

Each position holds the trust-weighted score for that axis bucket:

```
vector[bucket.vector_idx] = trust(n, t) × score_shifted
```

Zero for buckets with no data yet (natural cold start — recipe ranks on 50D property match until demographic data accumulates).

Not L2-normalised. The dot product at query time returns the raw sum of matched axis scores.

---

## Trust Formula

Two independent factors applied at write time. Neither blocks signal — both dampen it proportionally.

```
trust(n, t) = sample_trust(n) × recency_trust(t)

sample_trust(n)  = 1 − exp(−n / 5)
  n=1 → 0.18   n=5 → 0.63   n=10 → 0.86   n=∞ → 1.0

recency_trust(t) = exp(−0.02 × weeks_since_last_observation)
  t=0w → 1.00   t=17w → 0.71   t=35w → 0.50   t=70w → 0.25
```

Five observations from last week: `trust = 0.63 × 1.00 = 0.63`
Five observations from 8 months ago: `trust = 0.63 × 0.50 = 0.32`

This ensures recent small datasets outrank stale large ones when recency matters.

---

## Effectiveness Score Formula

```
effectiveness(R, B) = AVG( consumption_pct(R, P) × goal_aligned_diff(u, P) )
```

**Scope:** all meal plans P where:
- User u belongs to axis bucket B
- Recipe R appears in plan P
- `consumption_pct(R, P) > 0` — zero-consumption observations excluded entirely

```
consumption_pct(R, P) = consumed_entries / planned_entries  ∈ (0, 1]

goal_aligned_diff:
  weight_loss:   −(weight_end − weight_start) / plan_weeks
  muscle_gain:   +(weight_end − weight_start) / plan_weeks
  maintenance:    1 − |weight_end − weight_start| / (plan_weeks × 0.2)
  health:         same as maintenance
  performance:    same as maintenance
  clip to [−1, 1]

weight measurement tolerance: ±3 days from plan start/end date
```

**Storage shift:** `score_shifted = (effectiveness_raw + 1) / 2` → stored in `[0, 1]`

---

## Retention Score Formula

```
retention(R, B) = reuse_count(R, B) / user_count(R, B)
```

- `user_count(R, B)` = distinct users in bucket B who had recipe R in at least one plan
- `reuse_count(R, B)` = users in bucket B who added R to a second plan within 30 days of first

Already in `[0, 1]` — no shift needed.

---

## Concrete Example

**Fatima** (28F, weight_loss, moderate, normal BMI, halal, West Africa)

Recipe A — Thiéboudienne (culturally iconic, carb-heavy):

| dim | axis bucket | effectiveness_raw | trust | stored |
|---|---|---|---|---|
| 3 | female_26_35 | 0.45 | 0.90 | 0.41 |
| 52 | weight_loss_moderate | 0.30 | 0.75 | **0.23** |
| 78 | normal_bmi_female | 0.48 | 0.88 | 0.42 |
| 98 | halal | 0.50 | 0.95 | 0.48 |
| 110 | origin_west_africa | 0.85 | 0.98 | **0.83** |

`dot product = 0.41+0.23+0.42+0.48+0.83 = 2.37 → normalised: 0.474`

Recipe B — Grilled Tilapia (lean protein, newer recipe):

| dim | axis bucket | effectiveness_raw | trust | stored |
|---|---|---|---|---|
| 3 | female_26_35 | 0.78 | 0.70 | 0.55 |
| 52 | weight_loss_moderate | 0.88 | 0.80 | **0.70** |
| 78 | normal_bmi_female | 0.72 | 0.65 | 0.47 |
| 98 | halal | 0.75 | 0.40 | **0.30** ← 3 data points |
| 110 | origin_west_africa | 0.65 | 0.60 | 0.39 |

`dot product = 0.55+0.70+0.47+0.30+0.39 = 2.41 → normalised: 0.482`

**Recipe B wins for Fatima** despite Recipe A's dominant cultural score. The `weight_loss_moderate` axis is decisive. Recipe B's halal score will grow as more halal users cook it.

---

## Recommendation RPC Integration

```sql
-- In generate_feed_personalized (post 50D cosine retrieval):
effectiveness_bonus := (rv.effectiveness_vector <#> v_demographic) * -1 / 5.0;
retention_bonus     := (rv.retention_vector     <#> v_demographic) * -1 / 5.0;

final_score := base_cosine_score
             + 0.10 * effectiveness_bonus
             + 0.05 * retention_bonus;
```

Division by 5.0 normalises the multi-hot sum back to [0, 1] regardless of how many axes are active. If a 6th axis is added later, the divisor updates to 6.0.

Weights (0.10 / 0.05) are conservative at launch to avoid overfitting sparse early data. Adjust once buckets mature.

---

## Creator Score Visibility

Creators query their recipe's scores per axis bucket. Buckets with `sample < 5` are shown as "not enough data yet".

```sql
SELECT
  db.axis,
  db.label,
  rds.effectiveness_raw,
  rds.effectiveness_sample,
  rds.retention_raw,
  rds.retention_sample
FROM recipe_demography_score rds
JOIN demography_bucket db ON db.id = rds.bucket_id
WHERE rds.recipe_id = :recipe_id
  AND rds.effectiveness_sample >= 5
ORDER BY rds.effectiveness_raw DESC;
```

---

## Weekly Batch

```
Sunday 03:00 UTC
  1. For each (recipe, bucket) pair with new activity this week:
     a. compute_recipe_effectiveness(recipe_id, bucket_id)
     b. compute_recipe_retention(recipe_id, bucket_id)
     c. upsert into recipe_demography_score
  2. Rebuild effectiveness_vector and retention_vector for updated recipes
  3. Rebuild demographic_vector for users whose profile changed
     (age boundary crossed, goal updated, weight changed BMI tier)
```

V1: recompute from full history each week.  
V2: switch to rolling EMA (α ≈ 0.3) once dataset grows.

---

## Relationship to Beauty Mode

`demography_bucket` is shared. Beauty recipes get separate `beauty_effectiveness_vector(200)` and `beauty_retention_vector(200)` columns on `beauty_recipe_vector`. Same axis buckets, same `vector_idx` mapping, same trust formula. The cuisine_origin axis is particularly relevant for beauty (natural ingredient traditions by region).

---

## Out of Scope (V1)

- Ingredient-level effectiveness attribution
- Cross-goal correlation
- Real-time score updates
- Fine-grained age splits below 18–25

---

## Implementation Order

1. Migration: `demography_bucket` table + seed all 85 V1 rows
2. Migration: `recipe_demography_score` table
3. Migration: `ALTER TABLE recipe_vector ADD COLUMN effectiveness_vector(200) / retention_vector(200)`
4. Migration: `ALTER TABLE user_vector ADD COLUMN demographic_vector(200)`
5. Python: `resolve_user_buckets(user_id)` → returns 5 (bucket_id, vector_idx) tuples
6. Python: `compute_recipe_effectiveness(recipe_id, bucket_id)`
7. Python: `compute_recipe_retention(recipe_id, bucket_id)`
8. Python: `rebuild_demographic_vectors(recipe_ids)` and `rebuild_user_demographic_vector(user_id)`
9. Python: weekly batch scheduler entry
10. Edge function: `complete-onboarding` — set `demographic_vector` on signup
11. RPC: update `generate_feed_personalized` with effectiveness + retention re-rank step
12. Creator API: recipe score endpoint (filter `sample >= 5`)
