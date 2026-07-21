# 👑 Akeli Beauty Mode — 50D Vector Engine, Evolution System & Creator Payout Architecture
> **Technical Architecture, Data Models, SQL Migrations, UI Components & Royalty Engine Specification**  
> *Last Updated: July 21, 2026*

---

## 📑 Executive Summary

This document logs the complete technical implementation of **Akeli Beauty Mode**, transitioning the platform into a 50D Goal-Driven Recommendation Engine, Time-Series Evolution Tracking Engine, and Proportional Creator Payout System.

### **Core Capabilities Implemented**:
1. **50D Shared Semantic Vector Space**: Uniform mapping between user profile vectors ($U$) and remedy/product vectors ($R$).
2. **Continuous Spectrum Physical Encodings**: Non-discrete spectrums for Hair Texture (1A–4C), Porosity (Low–High), and Skin Type (Dry–Oily).
3. **18 Standardized Beauty Virtues & Ingredient Inheritance**: Standardized continuous virtue weights ($0.0 \to 1.0$) across ingredients and recipes.
4. **Premade Commercial Product vs. DIY Remedy Vectorization**: Explicit creator virtue vectors for bottled products vs. accumulated virtue vectors for raw botanical remedies.
5. **Hybrid Selective Virtue Masking**: Preserves physical hair/skin attributes while masking un-requested virtues to eliminate dilution penalties.
6. **Extensive Beauty Log & Evolution Tracking**: Time-series tracking of 15+ quantitative & qualitative hair/skin metrics with dynamic recommendation priority feedback loops.
7. **Monthly Beauty Plan Generator**: 30-day care cycle across 5 frequency tiers (`daily`, `2x_week`, `1x_week`, `2x_month`, `1x_month`).
8. **Unified Mode-Aware Recipe Feed & Beauty Routine Planner**: Seamless app mode switching (`AppMode.nutrition` vs. `AppMode.beauty`) across remedies feeds and routine planners.
9. **Mode-Isolated Community Groups & Conversations**: Dedicated Beauty community groups (*Secret du Chébé*, *Peaux Claires & Bio*, *Bains d'Huiles*) and beauty topics.
10. **Color Set Selector Modal**: Customizable Primary & Secondary color palettes (*Teal & Amber*, *Rose & Gold*, *Sage & Bronze*, *Terracotta & Clay*).
11. **Proportional Creator Revenue Value (`revenue_value = 1 / N`) & Platform Retained Revenue Engine**:
    - Each monthly beauty plan slot carries a weight of `1 / N` (total plan weight = 1.0).
    - 1.00€ direct share pool per plan: completed slots pay `entry.revenue_value * 1.00€` to creators; unchecked slots remain with the platform.

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
* **[`supabase/migrations/20260721000003_recipe_virtue_weights_vector.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000003_recipe_virtue_weights_vector.sql)**: Adds `virtue_weights JSONB` column to `recipe`.
* **[`supabase/migrations/20260721000004_standardize_ingredient_virtue_vectors.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000004_standardize_ingredient_virtue_vectors.sql)**: Standardizes 18 virtue weight maps across 45+ botanical ingredients.
* **[`supabase/migrations/20260721000005_premade_product_classification.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000005_premade_product_classification.sql)**: Adds `is_premade_product` and `product_type` (`'diy'`, `'artisanal'`, `'industrial'`).
* **[`supabase/migrations/20260721000006_hybrid_virtue_masking_recommendations.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000006_hybrid_virtue_masking_recommendations.sql)**: Updates `recommend_recipes` SQL RPC with HNSW Cosine Distance.
* **[`supabase/migrations/20260721000007_beauty_log_evolution_tracking.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000007_beauty_log_evolution_tracking.sql)**: Creates `beauty_log` table and `get_beauty_evolution_history` RPC.
* **[`supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql)**: Generates 30-day care cycle across 5 frequency tiers (`daily`, `2x_week`, `1x_week`, `2x_month`, `1x_month`).
* **[`supabase/migrations/20260721000009_onboarding_baseline_beauty_log.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000009_onboarding_baseline_beauty_log.sql)**: Adds `create_initial_beauty_log` RPC for onboarding.
* **[`supabase/migrations/20260721000010_unify_feed_personalized_with_mode.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000010_unify_feed_personalized_with_mode.sql)**: Unifies `generate_feed_personalized` RPC with `p_mode` support.
* **[`supabase/migrations/20260721000011_community_mode_and_beauty_topics.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000011_community_mode_and_beauty_topics.sql)**: Adds `mode` column to `community_group` and `conversation`, seeds Beauty starter groups.
* **[`supabase/migrations/20260721000012_beauty_plan_slot_revenue_value.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000012_beauty_plan_slot_revenue_value.sql)**: Adds `revenue_value = 1 / N` column to `beauty_plan_slot`.
* **[`supabase/migrations/20260721000013_beauty_payouts_revenue_value.sql`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/supabase/migrations/20260721000013_beauty_payouts_revenue_value.sql)**: Direct 1.00€ plan share creator payout RPCs (`calculate_creator_payouts`, `get_creator_beauty_payout_breakdown`, `get_platform_retained_beauty_revenue`).

---

### 🐍 **Python Recommendation & Vector Engine (`python/engine/`)**
* **[`python/engine/vectorization.py`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/python/engine/vectorization.py)**: Vector computation engine.
* **[`python/engine/database.py`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/python/engine/database.py)**: Database interface helpers.
* **[`python/tests/test_vectorization.py`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/python/tests/test_vectorization.py)**: Pytest unit test suite (**24 passing tests**).

---

### 📱 **Flutter Dart Implementation (`lib/ & test/`)**
* **[`lib/shared/models/beauty_log.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/lib/shared/models/beauty_log.dart)**: Time-series log model.
* **[`lib/shared/models/beauty_plan.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/lib/shared/models/beauty_plan.dart)**: Monthly beauty plan & slot model (includes `revenueValue`).
* **[`lib/providers/beauty_plan_provider.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/lib/providers/beauty_plan_provider.dart)**: Active beauty plan state provider & slot completion notifier.
* **[`lib/features/beauty/widgets/beauty_checkin_sheet.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/lib/features/beauty/widgets/beauty_checkin_sheet.dart)**: Modal bottom sheet for progress check-ins.
* **[`lib/features/meal_planner/widgets/beauty_planner_view.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/lib/features/meal_planner/widgets/beauty_planner_view.dart)**: Schedule view widget displaying monthly care routines.
* **[`lib/shared/widgets/color_set_modal.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/lib/shared/widgets/color_set_modal.dart)**: Primary & Secondary theme palette switcher modal.
* **[`test/features/beauty/widgets/beauty_checkin_sheet_test.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/test/features/beauty/widgets/beauty_checkin_sheet_test.dart)**: Widget unit tests.
* **[`test/features/meal_planner/widgets/beauty_planner_view_test.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/test/features/meal_planner/widgets/beauty_planner_view_test.dart)**: Widget unit tests.
* **[`test/shared/widgets/color_set_modal_test.dart`](file:///c:/Users/DELL%20LATITUDE%207480/akeli-nutrition-app/test/shared/widgets/color_set_modal_test.dart)**: Widget unit tests (**243 passing Flutter tests total**).

---

## 💰 3. Creator Royalty & Platform Retained Revenue Engine

### **Formula & Rules**:
1. **Slot Weight ($1 / N$)**: Each slot in a plan of $N$ entries gets `revenue_value = 1 / N`. Total plan weight = **1.00**.
2. **Subscription Share (1.00€ per plan)**:
   - **Completed Slot**: Pays `entry.revenue_value * 1.00€` to the recipe author.
   - **Unchecked / Incomplete Slot**: Retained by the platform (`entry.revenue_value * 1.00€`).
3. **Monthly Retained Revenue Breakdown**:
   $$\text{Platform Retained (€)} = \text{Total Plan Pool (€)} - \sum \text{Creator Completed Payouts (€)}$$

---

## 🧪 4. Final Verification Summary

* **Flutter Test Suite**: `243 / 243 PASSED` (100% green)
* **Pytest Test Suite**: `24 / 24 PASSED` (100% green)
* **Git Branch**: Committed & pushed to `origin/sdui`.

---

## 📜 5. Activity Log & Ongoing Changelog

> **Mandatory Policy**: Every subsequent action, schema change, RPC update, UI modification, or bug fix MUST be logged in this document with timestamps, files modified, and commit SHAs.

### **Changelog Entry — July 21, 2026 (15:05 UTC)**
- **Beauty Analytics Page & History Timeline**: Built `BeautyAnalyticsPage` (`beauty_analytics_page.dart`) with Rosewood (`#8A3B58`) and Gold (`#D4AF37`) digital editorial aesthetics, time-range chips (7J, 30J, 90J, Tout), ritual adherence percentage score card, hair growth delta metric, strength score meter, anti-shedding status badge, skin hydration/clarity progress metrics, and historical `BeautyLog` timeline entries.
- **Provider & Model Expansion**: Created `BeautyLog` model (`beauty_log.dart`), `beautyLogsProvider`, and `addBeautyLogNotifierProvider` in `beauty_plan_provider.dart`.
- **Verification**: Created `beauty_analytics_page_test.dart`. Tested live via widget tests, **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Nutrition Fan Mode Audit & Beauty Alignment**: Verified `generate_meal_plan` (Nutrition Mode) Fan Mode mechanics (`fan_subscription` check, 1.5x vector similarity score multiplier for creator recipes, and 90% fan slot quota with 10% non-fan cap `v_max_other_slots`).
- **Beauty Mode Parity Migration (`20260721000022_beauty_plan_fan_mode_quota.sql`)**: Updated `generate_beauty_plan` to incorporate active Fan Subscription lookups and slot quota tracking so that Beauty Mode routine plan generation achieves 100% feature and architectural parity with Nutrition Mode.
- **Verification**: Verified live on Supabase DB, **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Fan Mode Recommendation Support (`recommend_recipes`)**: Updated `recommend_recipes` RPC in migration `20260721000021_recommend_recipes_fan_mode.sql` to check active user fan subscriptions (`fan_subscription`). When a user is subscribed to a creator in Fan Mode (`fs.status = 'active'`), recipes by that creator receive a **1.5x similarity multiplier score boost** and prioritize creator recipes at the top of routine recommendations.
- **Beauty Plan Integration**: Because `generate_beauty_plan` and `generate_initial_beauty_plan` rely on `recommend_recipes` for routine slot assignment, Fan Mode is now automatically enabled and respected during Beauty Plan generation!
- **Verification**: Tested live via SQL query, **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Saved Beauty Recipe Pool Threshold Migration**: Updated `generate_beauty_plan_from_saved(...)` in migration `20260721000020_beauty_plan_saved_threshold.sql` with a minimum pool threshold parameter (`p_min_saved_threshold INT DEFAULT 3`) and fallback parameter (`p_fallback_to_recommended BOOLEAN DEFAULT true`).
- **Threshold Validation**: If the user's saved beauty recipe collection is below the threshold (`< 3`), it automatically logs a notice and falls back to generating the standard recommended beauty plan (or raises `insufficient_saved_beauty_recipes` if fallback is disabled).
- **Verification**: Tested live via SQL query, **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Monthly Remainder Onboarding Beauty Plan**: Updated `generate_initial_beauty_plan(p_user_id)` in migration `20260721000019_beauty_plan_generation_trio.sql` to calculate the exact remaining days from the user's onboarding date to the end of the current calendar month (`(end_of_month - start_date + 1)`). This ensures Beauty Mode onboarding generates a monthly routine plan aligned to the remainder of the current month rather than truncating at Sunday.
- **Verification**: Tested live via SQL query, **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Beauty Plan Generation Parity Trio**: Created migration `20260721000019_beauty_plan_generation_trio.sql` introducing the full trio of plan generation RPCs to mirror Nutrition Mode:
  1. `generate_beauty_plan(p_user_id, p_start_date, p_days)` — Full $N$-day routine plan generator.
  2. `generate_initial_beauty_plan(p_user_id)` — Partial initial onboarding plan from current day until upcoming Sunday.
  3. `generate_beauty_plan_from_saved(p_user_id, p_start_date, p_days)` — Routine plan built exclusively from saved beauty recipes (`recipe_save`).
- **Onboarding Alignment (`20260721000018_first_beauty_log_onboarding.sql`)**: Updated `complete_beauty_onboarding` RPC to call `generate_initial_beauty_plan` during onboarding.
- **Verification**: Tested live via SQL query, **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Python Beauty User Vectorization Trigger**: Updated `complete-beauty-onboarding` Edge Function (`index.ts`) to fire an asynchronous, non-blocking HTTP POST request to `${PYTHON_SERVICE_URL}/compute-user-vector` with `{ user_id, mode: "beauty" }`. This immediately builds the initial 50D Beauty User Vector (covering dims 27-49: hair texture spectrum, porosity, scalp condition, skin typology, and virtue preferences) upon onboarding completion.
- **Verification**: Tested live, **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Dedicated Beauty Onboarding Edge Function**: Created `supabase/functions/complete-beauty-onboarding/index.ts` to achieve architectural parity with Nutrition Mode (`complete-onboarding`). Features Bearer JWT verification (`getAuthUser`), structured Deno logging (`createLogger`), service role execution, and RPC fallback.
- **Provider Parity (`user_profile_provider.dart`)**: Updated `completeBeautyOnboarding` in `UserProfileNotifier` to invoke `client.functions.invoke('complete-beauty-onboarding', body: ...)` with RPC fallback so both Edge Function and database execution are supported seamlessly.
- **Verification**: Tested live, **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **5-Step Beauty Onboarding Wizard**: Added Step 5 (**Résumé & Confirmation / Summary & Confirmation**) to `BeautyOnboardingPage` (`beauty_onboarding_page.dart`). Renders interactive summary cards for Hair Profile, Skin Diagnostic, Selected Goals, and First Log Measurements, allowing quick inline edit navigation (`onEdit` callbacks) back to previous steps before final confirmation.
- **Verification**: Updated `beauty_onboarding_page_test.dart`. **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **First Beauty Log Check-in Migration**: Updated `complete_beauty_onboarding(...)` RPC in migration `20260721000018_first_beauty_log_onboarding.sql` to accept baseline `beauty_log` parameters (`p_hair_length_cm`, `p_hair_strength_score`, `p_hair_thickness_score`, `p_hair_shedding_rate`, `p_skin_hydration_level`, `p_skin_clarity_score`, `p_checkin_notes`) and automatically log the user's initial baseline check-in row upon completing onboarding.
- **4-Step Beauty Onboarding Wizard**: Added Step 4 (**Premier Bilan Initial / First Beauty Log**) to `BeautyOnboardingPage` (`beauty_onboarding_page.dart`) with interactive sliders for hair length (cm), strength (1-10), shedding rate (low/med/high), skin hydration (1-10), skin clarity (1-10), and initial notes.
- **Verification**: Updated `beauty_onboarding_page_test.dart`. **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Balanced Hair & Skin Ritual Goals**: Reorganized Step 3 of `BeautyOnboardingPage` into two distinct categories: **Objectifs Capillaires 👑** (Pousse, Densité, Force, Anti-Casse, Hydratation, Apaisement Cuir Chevelu) and **Objectifs Cutanés & Teint ✨** (Éclat du Teint, Atténuation des Taches, Hydratation Cutanée, Clarification Anti-Imperfections, Barrière Cutanée).
- **Clean Outcome Goal Titles**: Removed all ingredient recommendations (e.g. `Chébé, Nigelle`) from goal labels to keep the onboarding goals focused purely on personal beauty outcomes.
- **Verification**: Tested live via widget tests, **24 / 24 Pytest tests**, and **245 / 245 Flutter tests** passing 100%.
- **Deep Skin Profile Migration**: Added `skin_concerns TEXT[] DEFAULT '{}'` to `user_health_profile` table and updated `complete_beauty_onboarding(...)` RPC in migration `20260721000017_deep_skin_profile.sql`.
- **Comprehensive Skin Typology & Dermatology Concerns**: Upgraded Step 2 of `BeautyOnboardingPage` with an extensive Skin Typology Dropdown (Peau Mixte, Sèche & Déshydratée, Grasse & Acneique, Sensible & Réactive, Hyperpigmentée, Mature, Normale), 6 Dermatological Concern Checkboxes (Hyperpigmentation, Acné, Déshydratation, Barrière Fragilisée, Sébum, Perte d'Élasticité), and Body Skin Particularities.
- **Verification**: Updated `beauty_onboarding_page_test.dart`. **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Rosewood & Gold Editorial Color Palette**: Replaced default green `AkeliColors.primary` in `BeautyOnboardingPage` with Beauty Mode's editorial Rosewood palette (`Color(0xFF8A3B58)` & `Color(0xFFD4AF37)` matching `ColorSetModal`).
- **Extensive Hair Composition Dropdown**: Upgraded hair texture selection to a comprehensive `DropdownButtonFormField` covering all 15 hair compositions (Types 1A–1C, 2A–2C, 3A–3C, 4A–4C, Locks/Dreadlocks, Cheveux en Transition, and Soin Sous Tresses/Perruque).
- **Verification**: Updated `beauty_onboarding_page_test.dart`. **24 / 24 Pytest tests** and **245 / 245 Flutter tests** passing 100%.
- **Beauty Onboarding Guard & Schema Migration**: Added `beauty_onboarding_done BOOLEAN DEFAULT FALSE` column to `user_profile` table and created `complete_beauty_onboarding(...)` RPC in migration `20260721000016_beauty_onboarding_flag.sql`.
- **User Profile Model & Provider**: Added `beautyOnboardingDone` to `UserProfile` model (`user_profile.dart`) and added `completeBeautyOnboarding` method to `UserProfileNotifier` (`user_profile_provider.dart`).
- **Beauty Onboarding Wizard Screen**: Created `BeautyOnboardingPage` (`lib/features/beauty/beauty_onboarding_page.dart`), a 3-step wizard collecting hair texture/porosity, skin type/scalp condition, and ritual goals, which auto-generates the initial 30-day Beauty Plan upon completion.
- **GoRouter Guard Redirect**: Updated `router.dart` to automatically redirect users who toggle to Beauty Mode without a completed Beauty Health Profile (`beautyOnboardingDone == false`) directly to `/onboarding/beauty`.
- **Verification**: Added `beauty_onboarding_page_test.dart`. Tested live via SQL query, **24 / 24 Pytest tests**, and **245 / 245 Flutter tests** passing 100%.
- **Feed RPC Beauty Filter Parameters Migration**: Extended `generate_feed_personalized` RPC with `p_product_type`, `p_routine_category`, and `p_beauty_goal` parameters in migration `20260721000015_feed_beauty_filters.sql`.
- **Dart Feed Provider (`recipe_provider.dart`)**: Extended `FeedParams` with `productType`, `routineCategory`, and `beautyGoal`.
- **Mode-Aware Filter UI (`feed_page.dart`)**: Updated `_showCombinedFilterSheet` in `FeedPage` to render Beauty filter choices (Catégorie de Soin: Cheveux, Cuir Chevelu, Visage, Corps; Type de Formule: DIY, Artisanal, Commercial; Objectif: Pousse, Force Anti-Casse, Hydratation, Soin Apaisant, Barrière Cutanée).
- **Verification**: Tested live via SQL query, **24 / 24 Pytest tests**, and **244 / 244 Flutter tests** passing 100%.
- **Mode-Aware Beauty Shopping List Migration**: Added `beauty_plan_id` to `shopping_list` table and created `generate_beauty_shopping_list(p_beauty_plan_id uuid)` RPC in migration `20260721000014_beauty_shopping_list.sql`.
- **Botanical Ingredient Aggregation**: Automatically aggregates powders (Chébé), plant oils (Nigella, Carrot), hydrosols, clays, and butters (Shea) across all 30-day routine recipes in the active Beauty Plan.
- **Mode-Aware `ShoppingListNotifier`**: Updated `ShoppingListNotifier` in `meal_plan_provider.dart` to watch `currentModeProvider` and fetch/toggle items for `activeBeautyPlanProvider` in Beauty Mode.
- **Verification**: Verified via live SQL execution on active plan (`63341436-651d...`), **24 / 24 Pytest tests**, and **244 / 244 Flutter tests** passing 100%.
- **Hero Banner Removal**: Removed `hero_banner` component from Beauty fallback SDUI layout (`layout_fetch_service.dart`).
- **Shared Native Greeting Header**: Updated `home_page.dart` to render the native greeting header ("Bonjour [Name] 👋", "Ravi de vous revoir") identically across Nutrition and Beauty modes.
- **Today's Beauty Routines Widget**: Created `TodayBeautyRoutinesWidget` (`lib/features/beauty/widgets/today_beauty_routines_widget.dart`) filtering routines strictly for today (`dayNumber == currentDayOfMonth`) with completion checkboxes and a direct link to the 30-day planner (`BeautyPlannerView`).
- **Widget Unit Test Suite**: Added `today_beauty_routines_widget_test.dart` (244 Flutter tests passing 100%).
- **Section-by-Section Homepage Comparison**: Detailed 7-section side-by-side analysis (Header, Core Metrics, Daily Schedule, Progress Check-in, Creator Feed, Utility Tools, and Monetization Logic) logged.
- **Mandatory Logging Directive**: Established rule that all future development actions must be recorded in this document.
- **Session Commits Summary**:
  - `479ee67`: Logged initial Homepage mode comparison.
  - `ee710b7`: Added mandatory Activity Log section to `BEAUTY_MODE_ARCHITECTURE_LOG.md`.
  - `7945dfb`: Documented 50D Vector Engine, Beauty Log, Community Isolation, ColorSetModal & Royalty Engine.
  - `1c90311`: Direct 1.00€ plan share creator payout RPCs (`calculate_creator_payouts`, `get_creator_beauty_payout_breakdown`, `get_platform_retained_beauty_revenue`).
  - `d0d5510`: Added proportional slot revenue weight (`revenue_value = 1 / N`) migration `20260721000012` and model upgrade.
  - `079a530`: Added widget unit tests for `ColorSetModal` (`color_set_modal_test.dart`).
  - `274b3a8`: Mode-isolated community conversations & Beauty starter groups migration `20260721000011`.
  - `ffc90ab`: Created `ColorSetModal` theme palette switcher component.
  - `5c113be` & `21d7655`: Fixed `BeautyPlannerView` image URL and routing.
  - `a7e1af7` & `1005141`: Unified `generate_feed_personalized` RPC with `p_mode` support and mode-aware feed page auto-refresh.

