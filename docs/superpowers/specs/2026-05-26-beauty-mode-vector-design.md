# Beauty Mode — Vector Space Design
**Date:** 2026-05-26
**Branch:** beauty-mode
**Author:** Curtis — Fondateur Akeli

---

## Context

Akeli is extending its recommendation engine from nutrition to beauty. The beauty mode focuses on **DIY natural beauty recipes** (homemade masks, oils, scrubs, treatments) in alignment with Akeli's African/natural identity. The vector-based recommendation system used for nutrition is replicated in a parallel beauty track — same Python engine, same pgvector infrastructure, same nightly batch, same combination routine pattern.

---

## Core Decisions

### 1. Separate vectors per domain
A single user gets up to two beauty vectors, computed independently:
- `hair_vector` (50D) — matched against hair recipe vectors
- `skin_vector` (50D) — matched against skin recipe vectors

Skin and hair are not mixed in a single vector. This keeps cosine similarity meaningful within each domain.

### 2. 50D symmetric space (same as nutrition)
Both user and recipe vectors are 50D, L2-normalised. Dimension `i` encodes the same concept in both vectors. Cosine similarity = genuine need-benefit alignment. Reuses the entire existing Python/pgvector/HNSW infrastructure without modification.

### 3. Routine combinations
Recipes pair into **beauty routines** (e.g. shampoo + deep mask + sealing oil + leave-in), modelled after the nutrition `recipe_combination` + `combination_vector` system. The routine vector is a weighted average of its component recipe vectors.

### 4. Separate beauty tables
Beauty ingredients, recipes, and vectors live in dedicated tables. No shared tables with nutrition to avoid schema confusion, while following identical architecture patterns.

---

## User Beauty Profile

### Tables

```sql
-- One row per user — collected at beauty onboarding
beauty_hair_profile (
  user_id      uuid REFERENCES user_profile(id),
  hair_type    text CHECK (hair_type IN (
    '1A','1B','1C','2A','2B','2C','3A','3B','3C','4A','4B','4C'
  )),
  porosity     text CHECK (porosity IN ('low','medium','high')),
  texture      text CHECK (texture IN ('fine','medium','coarse'))
)

beauty_skin_profile (
  user_id      uuid REFERENCES user_profile(id),
  skin_type    text CHECK (skin_type IN (
    'oily','dry','combination','normal','sensitive'
  )),
  fitzpatrick  int  CHECK (fitzpatrick BETWEEN 1 AND 6)
)

-- Multi-row, one per concern — mirrors user_dietary_restriction
beauty_hair_concern (
  user_id  uuid,
  concern  text CHECK (concern IN (
    'dryness','breakage','frizz','dandruff',
    'oily_scalp','itchy_scalp','hair_loss','slow_growth','lack_of_shine'
  ))
)

beauty_skin_concern (
  user_id  uuid,
  concern  text CHECK (concern IN (
    'hyperpigmentation','acne','aging','dullness',
    'large_pores','redness','uneven_texture','dehydration','dark_circles'
  ))
)

-- Multi-row, mirrors user_goal
beauty_goal (
  user_id    uuid,
  goal_type  text,   -- see enums below
  domain     text CHECK (domain IN ('hair','skin')),
  is_active  boolean DEFAULT true
)
-- Hair goals: moisturize, strengthen, grow, scalp_health, define_curls, anti_frizz, shine
-- Skin goals: hydrate, brighten, anti_acne, anti_aging, soothe, even_tone, exfoliate
```

### Hair type encoding (used in vector computation)

The Andre Walker 1A–4C system is mapped to a continuous curl score for symmetric vector encoding:

| Type | Curl score |
|------|-----------|
| 1A | 0.08 |
| 1B | 0.16 |
| 1C | 0.25 |
| 2A | 0.33 |
| 2B | 0.42 |
| 2C | 0.50 |
| 3A | 0.58 |
| 3B | 0.67 |
| 3C | 0.75 |
| 4A | 0.83 |
| 4B | 0.92 |
| 4C | 1.00 |

Porosity: `low=0.25`, `medium=0.50`, `high=1.00`
Texture: `fine=0.25`, `medium=0.50`, `coarse=1.00`

---

## Beauty Recipe & Ingredient Tables

```sql
beauty_ingredient (
  id           uuid PRIMARY KEY,
  name_fr      text NOT NULL,
  name_en      text NOT NULL,
  name_es      text,
  name_pt      text,
  category     text CHECK (category IN (
    'oil','butter','clay','botanical','kitchen','essential_oil','hydrosol'
  )),
  region       text REFERENCES food_region(code)  -- reuses existing referential
)

-- Key table driving recipe vector computation
beauty_ingredient_property (
  ingredient_id  uuid REFERENCES beauty_ingredient(id),
  property       text CHECK (property IN (
    'moisturizing','humectant','occlusive','protein','strengthening',
    'scalp_stimulating','anti_fungal','astringent','brightening',
    'exfoliating','anti_inflammatory','antioxidant','anti_acne',
    'firming','curl_defining','sealing','cleansing'
  )),
  intensity      numeric(3,2) CHECK (intensity BETWEEN 0 AND 1),
  PRIMARY KEY (ingredient_id, property)
)

beauty_recipe (
  id           uuid PRIMARY KEY,
  title        text NOT NULL,
  description  text,
  domain       text CHECK (domain IN ('hair','skin')),
  recipe_type  text CHECK (recipe_type IN (
    -- hair
    'shampoo','conditioner','mask','oil','pre_poo','leave_in',
    -- skin
    'scrub','toner','cleanser','serum','face_mask','body_mask'
  )),
  region       text REFERENCES food_region(code),
  difficulty   text CHECK (difficulty IN ('easy','medium','hard')),
  prep_time_min int,
  creator_id   uuid REFERENCES creator(id),
  is_published boolean DEFAULT false,
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
)

beauty_recipe_ingredient (
  recipe_id      uuid REFERENCES beauty_recipe(id),
  ingredient_id  uuid REFERENCES beauty_ingredient(id),
  quantity       numeric,
  unit           text REFERENCES measurement_unit(code),
  PRIMARY KEY (recipe_id, ingredient_id)
)

-- Vector storage (one row per recipe, per domain)
beauty_recipe_vector (
  recipe_id      uuid PRIMARY KEY REFERENCES beauty_recipe(id),
  domain         text CHECK (domain IN ('hair','skin')),
  vector         vector(50) NOT NULL,
  last_computed  timestamptz DEFAULT now()
)

-- Routine combinations (shampoo + mask + oil + leave-in)
beauty_combination (
  id               uuid PRIMARY KEY,
  base_recipe_id   uuid REFERENCES beauty_recipe(id),
  paired_recipe_id uuid REFERENCES beauty_recipe(id),
  paired_role      text,   -- 'conditioner','treatment','finishing','styling'
  domain           text CHECK (domain IN ('hair','skin')),
  source           text CHECK (source IN ('creator','cross_creator','user')),
  is_validated     boolean DEFAULT false,
  owner_user_id    uuid REFERENCES user_profile(id)
)

beauty_combination_vector (
  combination_id  uuid PRIMARY KEY REFERENCES beauty_combination(id),
  vector          vector(50) NOT NULL,
  last_computed   timestamptz DEFAULT now()
)

-- User computed vectors
beauty_hair_vector (
  user_id       uuid PRIMARY KEY REFERENCES user_profile(id),
  vector        vector(50) NOT NULL,
  last_computed timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
)

beauty_skin_vector (
  user_id       uuid PRIMARY KEY REFERENCES user_profile(id),
  vector        vector(50) NOT NULL,
  last_computed timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
)
```

---

## Hair Vector — 50 Dimensions

**2× amplification before L2 normalisation:** dims 0–8 (moisture + protein groups).

| Dim | Group | Name | User value | Recipe value |
|-----|-------|------|-----------|--------------|
| 0 | Moisture | Moisturizing intensity | `1.0` if `dryness` concern or `moisturize` goal; scales with curl score (4C adds +0.3 capped at 1.0) | Weighted sum of `moisturizing` ingredient property intensities |
| 1 | Moisture | Humectant richness | High porosity + dryness → `1.0` | Sum of `humectant` properties (honey, aloe, glycerin equiv.) |
| 2 | Moisture | Occlusive/sealing | High porosity → `1.0` | `occlusive` property (shea, castor, coconut) |
| 3 | Moisture | Lightweight hydration | `1 − (curl_score × texture_score)` — fine/straight hair wants light formulas | Inverse of heavy emollient concentration |
| 4 | Moisture | Deep conditioning | `4C` + high porosity + `dryness` → `1.0` | Rich butter content (shea, mango, cocoa butter) |
| 5 | Protein | Protein treatment | `1.0` if `breakage` concern or `strengthen` goal | `protein` property (egg, rice water, yogurt, amla) |
| 6 | Protein | Strengthening | `breakage` + damage concerns | `strengthening` property intensities |
| 7 | Protein | Elasticity support | Breakage in curl types ≥ 3A | Elastin-supporting ingredients (avocado, banana, honey) |
| 8 | Protein | Damage repair | Chemical or heat damage concern | Reconstructing ingredient signal |
| 9 | Hair type | Curl/coil compatibility | `curl_score`: 1A=0.08 → 4C=1.00 | Suited for high-curl types (1.0 = optimal for 4C) |
| 10 | Hair type | Porosity match | `low=0.25` `medium=0.50` `high=1.00` | Penetrating/heavy ingredient score |
| 11 | Hair type | Fine hair suitability | `1 − texture_score` | Lightweight formula signal (inverse of heavy emollients) |
| 12 | Hair type | Coarse penetration | `texture_score` (`fine=0.25` `coarse=1.00`) | High-penetration ingredients (coconut oil, rice water) |
| 13 | Scalp | Scalp treatment | Any scalp concern → `1.0` | Scalp-active ingredient sum |
| 14 | Scalp | Anti-dandruff | `dandruff` concern → `1.0` | `anti_fungal` property (tea tree, ACV, neem) |
| 15 | Scalp | Scalp oil control | `oily_scalp` concern → `1.0` | `astringent` property (clay, ACV, green tea) |
| 16 | Scalp | Scalp soothing | `itchy_scalp` concern → `1.0` | `anti_inflammatory` scalp signal (aloe, chamomile, lavender) |
| 17 | Scalp | Scalp stimulation | `hair_loss` or `slow_growth` + `grow` goal → `1.0` | `scalp_stimulating` property (rosemary, peppermint, ginger, castor) |
| 18 | Growth | Growth stimulation | `slow_growth` + `grow` goal | Castor oil, rosemary, onion juice signal |
| 19 | Growth | Length retention | `breakage` at ends | Protective coating ingredients |
| 20 | Finish | Curl definition | `curl_score ≥ 0.58` (type ≥ 3A) | `curl_defining` property (flaxseed, aloe, hibiscus) |
| 21 | Finish | Anti-frizz | `frizz` concern → `1.0` | Anti-humidity sealing ingredients |
| 22 | Finish | Shine | `lack_of_shine` concern or `shine` goal | Shine-enhancing oils (argan, sweet almond, jojoba) |
| 23 | Finish | Cleansing intensity | `oily_scalp` or `dandruff` → `1.0`; `dryness` → `0.2` | `cleansing` property intensity |
| 24 | Origin | West Africa | `1.0` if preferred region | `1.0` if dominant ingredient region (shea, black soap, moringa) |
| 25 | Origin | North/East Africa | `1.0` if preferred region | `1.0` if dominant (argan, baobab, niger seed) |
| 26 | Origin | Caribbean | `1.0` if preferred region | `1.0` if dominant (coconut, hibiscus, soursop leaf) |
| 27 | Origin | South/SE Asia | `1.0` if preferred region | `1.0` if dominant (rice water, amla, fenugreek, neem) |
| 28 | Origin | Mediterranean | `1.0` if preferred region | `1.0` if dominant (olive oil, rosemary, sage) |
| 29 | Origin | Universal pantry | `1.0` if preferred region | `1.0` if dominant (honey, egg, yogurt, banana, avocado) |
| 30 | Origin | Reserved | `0` | `0` |
| 31 | Practical | Quick recipe | `neutral 0.5` | `1 − min(prep_time_min / 60, 1)` |
| 32 | Practical | Freshness | `neutral 0.5` | `max(0, 1 − age_days / 365)` |
| 33–49 | — | Reserved | `0` | `0` |

---

## Skin Vector — 50 Dimensions

**2× amplification before L2 normalisation:** dims 0–11 (hydration + brightening + acne groups).

| Dim | Group | Name | User value | Recipe value |
|-----|-------|------|-----------|--------------|
| 0 | Hydration | Hydration intensity | `1.0` if `dry` type or `dehydration` concern or `hydrate` goal | Weighted sum of `moisturizing` + `humectant` property intensities |
| 1 | Hydration | Rich moisturising | Very dry type → `1.0` | `occlusive` property (shea, mango butter, avocado) |
| 2 | Hydration | Lightweight hydration | `oily` or `combination` type → `1.0` | Gel/water-based signal — aloe, cucumber dominant |
| 3 | Hydration | Oil control | `oily` type + `large_pores` or `acne` concern | `astringent` + oil-absorbing property (clay, witch hazel, ACV) |
| 4 | Brightening | Brightening intensity | `hyperpigmentation` concern or `brighten`/`even_tone` goal → `1.0` | `brightening` property (lemon, papaya, rosehip, turmeric) |
| 5 | Brightening | Tone evening | `uneven_texture` + `even_tone` goal | Melanin-modulating naturals (turmeric, kojic analog) |
| 6 | Brightening | Dark spot targeting | `hyperpigmentation` + post-acne marks | AHA-rich signal (papaya enzymes, lemon, yogurt lactic acid) |
| 7 | Brightening | Tone sensitivity | `1 − (fitzpatrick / 6)` — darker tones need gentler actives | `1 − harsh_brightening_score` (gentle recipe = high value) |
| 8 | Acne | Acne fighting | `acne` concern or `anti_acne` goal → `1.0` | `anti_acne` property (tea tree, honey, neem, turmeric) |
| 9 | Acne | Sebum control | `oily` type + `large_pores` concern | Oil-control property (kaolin, bentonite, ACV) |
| 10 | Acne | Pore minimising | `large_pores` concern → `1.0` | `astringent` property (witch hazel, ACV, green tea) |
| 11 | Acne | Deep cleansing | `acne` + congested skin | Detox/purifying signal (clay, charcoal) |
| 12 | Anti-aging | Anti-aging intensity | `aging` concern or `anti_aging` goal → `1.0` | `firming` + retinol-analog properties (rosehip, bakuchiol equiv., frankincense) |
| 13 | Anti-aging | Antioxidant richness | `dullness` concern or `anti_aging` goal | `antioxidant` property (hibiscus, green tea, moringa, baobab, pomegranate) |
| 14 | Anti-aging | Firming | `aging` + sagging/texture concern | Collagen-supporting signal (rosehip, aloe, frankincense) |
| 15 | Anti-aging | Exfoliation intensity | `dullness` + `uneven_texture` + `exfoliate` goal → `1.0` | `exfoliating` property (sugar, oatmeal, papaya enzymes) |
| 16 | Soothing | Soothing intensity | `sensitive` type or `redness` concern or `soothe` goal → `1.0` | `anti_inflammatory` property (aloe, chamomile, oatmeal, cucumber) |
| 17 | Soothing | Sensitivity safety | `sensitive` type → `1.0` | `1 − harsh_active_score` — low-irritant signal |
| 18 | Soothing | Anti-redness | `redness` concern → `1.0` | Redness-calming signal (aloe, green tea, chamomile, calendula) |
| 19 | Soothing | Barrier strengthening | `dry` + `sensitive` + `dehydration` | Ceramide-analog naturals (shea, rosehip, sea buckthorn) |
| 20 | Skin type | Oily suitability | `1.0` if `oily` | Non-comedogenic, balancing formula signal |
| 21 | Skin type | Dry suitability | `1.0` if `dry` | Rich and nourishing formula signal |
| 22 | Skin type | Combination balance | `1.0` if `combination` | Zone-balancing formula signal |
| 23 | Origin | West Africa | `1.0` if preferred region | `1.0` if dominant (shea, black soap, baobab) |
| 24 | Origin | North/East Africa | `1.0` if preferred region | `1.0` if dominant (argan, rose water, baobab) |
| 25 | Origin | Caribbean | `1.0` if preferred region | `1.0` if dominant (coconut, hibiscus, soursop) |
| 26 | Origin | South/SE Asia | `1.0` if preferred region | `1.0` if dominant (turmeric, neem, sandalwood, rice water) |
| 27 | Origin | Mediterranean | `1.0` if preferred region | `1.0` if dominant (olive oil, rose water, rosemary) |
| 28 | Origin | Universal pantry | `1.0` if preferred region | `1.0` if dominant (honey, yogurt, lemon, avocado, oatmeal) |
| 29 | Origin | Reserved | `0` | `0` |
| 30 | Practical | Quick recipe | `neutral 0.5` | `1 − min(prep_time_min / 60, 1)` |
| 31 | Practical | Freshness | `neutral 0.5` | `max(0, 1 − age_days / 365)` |
| 32–49 | — | Reserved | `0` | `0` |

> **Dim 7 note:** The only dimension where a higher user value signals a *constraint* rather than a desire. Darker Fitzpatrick scores (4–6) should not be matched with aggressive brightening. The inverse recipe encoding (`1 − harsh_brightening_score`) ensures cosine similarity naturally penalises harsh actives for these users.

---

## Python Engine — New Endpoints

Two new endpoints added to the existing FastAPI service (`python/main.py`), following the exact same pattern as `/compute-user-vector`:

```
POST /compute-beauty-hair-vector   { user_id }
POST /compute-beauty-skin-vector   { user_id }
```

Both called once after beauty onboarding (via a new `complete-beauty-onboarding` edge function), then refreshed nightly via `/nightly-batch` for active users.

The nightly batch adds:
```python
# beauty hair vectors
active_users = get_active_beauty_users(days=7)
for user_id in active_users:
    vector = compute_beauty_hair_vector(user_id)
    if vector: upsert_beauty_hair_vector(user_id, vector)

# beauty skin vectors
for user_id in active_users:
    vector = compute_beauty_skin_vector(user_id)
    if vector: upsert_beauty_skin_vector(user_id, vector)
```

---

## Recommendation RPCs

Three new Postgres RPCs, mirroring the nutrition feed engine:

- `recommend_beauty_hair(p_user_id, p_limit, p_recipe_type)` — cosine similarity on `beauty_hair_vector` vs `beauty_recipe_vector WHERE domain='hair'`. Optional `p_recipe_type` filter (e.g. `'mask'` only).
- `recommend_beauty_skin(p_user_id, p_limit, p_recipe_type)` — same for skin.
- `recommend_beauty_routine(p_user_id, p_limit)` — cosine similarity on `beauty_combination_vector` vs user's `hair_vector`, returns full routine combinations.

---

## What Is NOT in Scope for This Design

- Beauty onboarding UI (separate spec)
- Creator tools for submitting beauty recipes (separate spec)
- Ingredient property tagging workflow (editorial, separate spec)
- Feed integration with existing `user_feed` table (separate spec)
