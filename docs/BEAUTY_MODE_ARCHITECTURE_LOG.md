# 👑 Akeli Beauty Mode — 50D Vector Recommendation Engine & Evolution System
> **Technical Architecture, Data Models, SQL Migrations & Algorithm Specification**  
> *Last Updated: July 21, 2026*

---

## 📑 Executive Summary

This document logs the complete technical implementation of **Akeli Beauty Mode**, transitioning the platform into a 50D Goal-Driven Recommendation & Time-Series Evolution Tracking Engine.

### **Core Capabilities Implemented**:
1. **50D Shared Semantic Vector Space**: Uniform mapping between user profile vectors ($U$) and remedy/product vectors ($R$).
2. **Continuous Spectrum Physical Encodings**: Non-discrete spectrums for Hair Texture (1A–4C), Porosity (Low–High), and Skin Type (Dry–Oily).
3. **18 Standardized Beauty Virtues & Ingredient Inheritance**: Standardized continuous virtue weights ($0.0 \to 1.0$) across ingredients and recipes.
4. **Premade Commercial Product vs. DIY Remedy Vectorization**: Explicit creator virtue vectors for bottled products vs. accumulated virtue vectors for raw botanical remedies.
5. **Hybrid Selective Virtue Masking**: Preserves physical hair/skin attributes while masking un-requested virtues to eliminate dilution penalties.
6. **Extensive Beauty Log & Evolution Tracking**: Time-series tracking of 15+ quantitative & qualitative hair/skin metrics with dynamic recommendation priority feedback loops.

---

## 📐 1. 50D Shared Semantic Vector Space Architecture (`vector(50)`)

```
  Index         Attribute / Goal                                Scale & Meaning
  ─────────────────────────────────────────────────────────────────────────────────────────────
  [0 - 26]      Culinary & Dietary Subspace                    Macros, satiety, speed, 13 cuisine regions
  [27]          DIM_HAIR_TEXTURE                               Continuous Spectrum: 1A-1C=0.10 ... 4C=1.00
  [28]          DIM_POROSITY                                   Continuous Spectrum: Low=0.20, Med=0.50, High=1.00
  [29]          DIM_SCALP_TYPE                                 Continuous Spectrum: Dry=0.10 ... Flaky=1.00
  [30]          DIM_SKIN_TYPE                                  Continuous Spectrum: Dry=0.10 ... Acne=1.00

  -- Hair Care Goals & Virtues (31 - 39) --
  [31]          GOAL_HAIR_GROWTH                               Length retention & follicle stimulation
  [32]          GOAL_HAIR_ANTI_BREAKAGE                        Strengthening & anti-breakage
  [33]          GOAL_HAIR_MOISTURE                             Deep cortical hydration
  [34]          GOAL_SCALP_SOOTHING                            Anti-itch & dandruff relief
  [35]          GOAL_CURL_DEFINITION                           Anti-frizz & curl shaping
  [36]          GOAL_PROTECTIVE_STYLE                          Braids, locs & edge care
  [37]          GOAL_HAIR_VOLUME                               Density & body
  [38]          GOAL_HAIR_SHINE                                Cuticle smoothing & luster
  [39]          GOAL_SCALP_DETOX                               Clarifying & buildup removal

  -- Skin Care Goals & Virtues (40 - 48) --
  [40]          GOAL_SKIN_GLOW                                 Radiance & anti-dullness
  [41]          GOAL_SKIN_BARRIER                              Lipid repair & moisture barrier
  [42]          GOAL_SKIN_SEBUM_ACNE                           Matrifying & blemish control
  [43]          GOAL_SKIN_SOOTHING                             Calming reactive skin
  [44]          GOAL_SKIN_ANTI_DARK_SPOTS                      Hyperpigmentation & even tone
  [45]          GOAL_SKIN_ANTI_AGING                           Firming & elasticity
  [46]          GOAL_SKIN_EXFOLIATION                          Smooth texture & dead skin removal
  [47]          GOAL_BODY_NUTRITION                            Body butter deep moisture
  [48]          GOAL_SUN_PROTECTION                            Antioxidant defense
  [49]          RESERVED_BEAUTY_EXPANSION                      Reserved
```

---

## 📁 2. File Directory & Codebase References

### 🗄️ **Database Migrations (`supabase/migrations/`)**
* **[`supabase/migrations/20260721000003_recipe_virtue_weights_vector.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000003_recipe_virtue_weights_vector.sql)**
  * Adds `virtue_weights JSONB` column to the `recipe` table.
* **[`supabase/migrations/20260721000004_standardize_ingredient_virtue_vectors.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000004_standardize_ingredient_virtue_vectors.sql)**
  * Standardizes 18 continuous virtue weight maps across 45+ natural botanical ingredients.
* **[`supabase/migrations/20260721000005_premade_product_classification.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000005_premade_product_classification.sql)**
  * Adds `is_premade_product BOOLEAN` and `product_type TEXT` (`'diy'`, `'artisanal'`, `'industrial'`) columns to `recipe`.
* **[`supabase/migrations/20260721000006_hybrid_virtue_masking_recommendations.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000006_hybrid_virtue_masking_recommendations.sql)**
  * Updates `recommend_recipes(p_user_id, ...)` SQL RPC with HNSW Cosine Distance matching (`rv.vector <=> v_user_vector`).
* **[`supabase/migrations/20260721000007_beauty_log_evolution_tracking.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000007_beauty_log_evolution_tracking.sql)**
  * Creates `beauty_log` table for time-series check-ins and `get_beauty_evolution_history(p_user_id, p_limit)` RPC.

---

### 🐍 **Python Recommendation & Vector Engine (`python/engine/`)**
* **[`python/engine/vectorization.py`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/python/engine/vectorization.py)**
  * Implements `compute_user_vector(user_id, mode="beauty")` with continuous spectrum lookups, dynamic `beauty_log` priority feedback, and L2 normalization.
  * Implements `compute_recipe_vector(recipe_id, mode="beauty", active_goals=None)` with dual virtue vectorization (explicit commercial product vectors vs. DIY ingredient accumulation) and hybrid selective virtue masking.
* **[`python/engine/database.py`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/python/engine/database.py)**
  * Implements `get_recipe_data`, `get_user_health_profile`, `get_latest_beauty_log`, and `get_beauty_evolution_history`.
* **[`python/tests/test_vectorization.py`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/python/tests/test_vectorization.py)**
  * Comprehensive Pytest unit test suite (**24 passing tests**) covering spectrum lookups, dual branch vectorization, hybrid virtue masking, and dynamic check-in metric feedback.

---

### 📱 **Flutter Dart Shared Models & Tests (`lib/ & test/`)**
* **[`lib/shared/models/recipe.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/lib/shared/models/recipe.dart)**
  * Data model for beauty remedies including `virtueWeights`, `suitableHairType`, `skinTarget`, `formulation`, `isPremadeProduct`, and `productType`.
* **[`lib/shared/models/beauty_log.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/lib/shared/models/beauty_log.dart)**
  * Data model for time-series progress logs with `fromJson` and `toJson`.
* **[`test/shared/models/beauty_log_test.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/test/shared/models/beauty_log_test.dart)**
  * Widget & model unit tests (**239 passing tests** across the app).

---

## 🛠️ 3. Key Algorithmic Innovations

### **A. Continuous Spectrum Mappings**
* **Hair Texture (`[27]`)**: $1\text{A}-1\text{C} = 0.10$, $2\text{A}-2\text{C} = 0.30$, $3\text{A} = 0.50$, $3\text{B} = 0.60$, $3\text{C} = 0.70$, $4\text{A} = 0.80$, $4\text{B} = 0.90$, $4\text{C} = 1.00$.
* **Porosity (`[28]`)**: $\text{Low} = 0.20$, $\text{Medium} = 0.50$, $\text{High} = 1.00$.
* **Skin Type (`[30]`)**: $\text{Dry} = 0.10$, $\text{Combination} = 0.50$, $\text{Oily/Acne} = 0.90$.

---

### **B. Hybrid Selective Virtue Masking**
```
  50D Shared Vector Dimensions
  ┌──────────────────────────────────────────────┬──────────────────────────────────────────────┐
  │   Inherent Attributes Dims [27] - [30]       │   Virtue & Goal Dimensions Dims [31] - [48]  │
  ├──────────────────────────────────────────────┼──────────────────────────────────────────────┤
  │ ALWAYS PRESERVED & ACTIVE                    │ SELECTIVELY NULLIFIED TO 0.0                 │
  │ • Hair Texture (1A..4C)                      │ • Preserved IF requested in active_goals     │
  │ • Porosity (Low, Med, High)                  │ • Zeroed out (0.0) IF NOT in active_goals    │
  │ • Scalp Type & Skin Type                     │   (Eliminates extra-virtue dilution penalty) │
  └──────────────────────────────────────────────┴──────────────────────────────────────────────┘
```

---

### **C. Dynamic Check-in Priority Loop (`beauty_log`)**
```
                       ┌───────────────────────────────┐
                       │    User Check-in (beauty_log) │
                       └───────────────┬───────────────┘
                                       │
                                       ▼
                     ┌───────────────────────────────────┐
                     │ Check Physical Measured Metrics:  │
                     │ • hair_strength_score < 5.0       │
                     │ • hair_shedding_rate = 'high'     │
                     │ • skin_hydration_level < 5.0      │
                     └─────────────────┬─────────────────┘
                                       │
                                       ▼
                     ┌───────────────────────────────────┐
                     │ Dynamically Boost Vector Priorities│
                     │ • GOAL_HAIR_ANTI_BREAKAGE += 1.0  │
                     │ • GOAL_HAIR_GROWTH += 1.0         │
                     │ • GOAL_SKIN_BARRIER += 1.0        │
                     └─────────────────┬─────────────────┘
                                       │
                                       ▼
                     ┌───────────────────────────────────┐
                     │ Recommend Tailored Repair Remedies│
                     └───────────────────────────────────┘
```

---

## 🧪 4. Verification Summary

* **Flutter Test Suite**: `239 / 239 PASSED` (100% green)
* **Pytest Test Suite**: `24 / 24 PASSED` (100% green)
* **Git Branch**: Committed & pushed to `origin/sdui`.
