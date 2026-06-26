# Akeli — 50D Shared Vector Space Reference

Both `user_vector` and `recipe_vector` live in the **same 50-dimensional space**.
Dimension `i` means the same thing in both vectors — cosine similarity between a user vector and a recipe vector therefore measures genuine preference-property alignment, not just structural overlap.

> **Weights applied before L2 normalisation (user vector only):**
> Goal-driven dims [0–5] are multiplied by **2×** before normalisation so they dominate over preference dims in the final dot product.

---

## Dimensions 0–9 — Nutritional & Practical Signals

| Dim | Name | User value | Recipe value | High similarity means… |
|-----|------|-----------|--------------|------------------------|
| 0 | **Protein intensity** | `1.0` if `weight_loss` or `muscle_gain` goal; `0.8` if `performance`; `0.5` if `maintenance` | `(protein_g × 4) / calories` — % of calories from protein, capped at 1.0 | User needs protein → recipe is protein-dense |
| 1 | **Low-calorie** | `1.0` if `weight_loss`; `0.5` if `maintenance` | `1 − min(calories / 800, 1)` — inverse caloric density (800 kcal = p90 cap) | User wants light meals → recipe is low-calorie |
| 2 | **High-fiber / satiety** | `0.8` if `weight_loss`; `0.7` if `health` | `min(fiber_g / 15, 1)` — currently `0` for all recipes (data pending) | User wants satiety → recipe is fiber-rich |
| 3 | **Satiety index** | `1.0` if `weight_loss`; `0.5` if `health` | `min((protein_kcal + fiber_g × 2) / calories, 1)` | User needs to stay full → recipe keeps you full per kcal |
| 4 | **Carb-rich** | `0.8` if `muscle_gain`; `0.7` if `performance` | `(carbs_g × 4) / calories` — % of calories from carbs, capped at 1.0 | User needs carbs for training → recipe is carb-heavy |
| 5 | **Caloric surplus** | `0.7` if `muscle_gain` | `min(calories / 800, 1)` — caloric density | User is bulking → recipe is calorie-dense |
| 6 | **Quick meal** | `1 − activity_level` (sedentary = 0.9, very_active = 0.0) | `1 − min((prep + cook) / 120, 1)` — 120 min = max reference time | Inactive user wants fast cooking → recipe is fast |
| 7 | **Difficulty match** | `activity_level` (sedentary = 0.1, very_active = 1.0) | `easy=0.25`, `medium=0.60`, `hard=1.0` | Active user tolerates complex recipes → recipe is challenging |
| 8 | **Recipe freshness** | `0.5` (neutral — no user preference) | `max(0, 1 − age_days / 365)` — linearly decays over 1 year | Neutral signal; biases toward recently published recipes |
| 9 | **Popularity** | `0.5` (neutral) | `log(1 + consumptions_30d) / log(1001)` — log scale, cap at 1000 | Neutral signal; biases toward frequently consumed recipes |

---

## Dimensions 10–22 — Cuisine Regions (13D one-hot)

**Identical mapping in both vectors.** User dims are set to `1.0` for each preferred region (up to 5). Recipe dim is `1.0` for the recipe's single region, `0` otherwise.

| Dim | Region |
|-----|--------|
| 10 | West Africa |
| 11 | Central Africa |
| 12 | East Africa |
| 13 | North Africa |
| 14 | South Africa |
| 15 | Caribbean |
| 16 | France |
| 17 | Mediterranean |
| 18 | Middle East |
| 19 | South Asia |
| 20 | Southeast Asia |
| 21 | Latin America |
| 22 | North America |

High similarity here means the recipe's region is one the user explicitly prefers.

---

## Dimensions 23–26 — Dietary & Creator Signals

| Dim | Name | User value | Recipe value | High similarity means… |
|-----|------|-----------|--------------|------------------------|
| 23 | **Vegetarian / vegan** | `1.0` if restriction is `vegetarian` or `vegan` | `1.0` if recipe is vegetarian/vegan-suitable | User eats plant-based → recipe fits |
| 24 | **Halal** | `1.0` if restriction is `halal` | `1.0` if recipe is halal-suitable | User eats halal → recipe is halal |
| 25 | **Creator quality** | `0.5` (neutral) | `min(creator_recipe_count / 100, 1)` — experience proxy | Neutral; biases toward established creators |
| 26 | **Fan-eligible creator** | `0.3` (slight negative lean) | `1.0` if `creator_recipe_count ≥ 30`, else `0` | Slight de-prioritisation of fan-gate recipes for casual users |

---

## Dimensions 27–49 — Reserved

All zeros in both vectors. Reserved for future signals (e.g. seasonal produce, budget tier, allergens).

---

## Activity Level Encoding

| Label | Numeric value |
|-------|--------------|
| `sedentary` | 0.10 |
| `light` | 0.30 |
| `moderate` | 0.50 |
| `active` | 0.75 |
| `very_active` | 1.00 |

---

## How the Score Is Used

```
score = cosine_similarity(user_vector, recipe_vector)
      = (user · recipe) / (‖user‖ × ‖recipe‖)
```

Both vectors are **L2-normalised** before storage, so at query time the dot product alone is sufficient. The `generate_feed_personalized` RPC computes `1 − (rv.vector <=> v_user_vector)` (pgvector cosine distance operator) and sorts descending — higher score = better match.
