# Meal Generator Stress Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix six correctness issues in the meal plan generator and validate the result with six live test scenarios.

**Architecture:** Three DB migrations (meal_ingredient table + computed macro columns + RPC rewrite), edge function error handling update, Dart model reads pre-computed macros, provider includes meal_ingredient in query. The `meal_distribution` / `nutrition_plan` tables already handle per-meal calorie targets — no new columns on `user_goal` needed. Note: the spec describes a "one-time pool fetch" (top-20 pre-fetched per meal type); the RPC rewrite here uses per-slot queries with equivalent constraints instead — this is functionally identical and simpler in PL/pgSQL. The pool prefetch can be revisited as a performance optimisation post-launch if needed.

**Tech Stack:** PostgreSQL/pgvector, Deno edge functions, Flutter/Dart, Riverpod, Supabase

---

## File Map

| File | Type | Change |
|------|------|--------|
| `supabase/migrations/20260529000001_add_meal_ingredient_table.sql` | New | `meal_ingredient` table + index |
| `supabase/migrations/20260529000002_add_computed_macros_to_entry.sql` | New | Add `calories_computed` etc. to `meal_plan_entry` |
| `supabase/migrations/20260529000003_rewrite_generate_meal_plan.sql` | New | Full RPC rewrite (all-or-nothing, cap, fan rule, scale bounds, pre-computed macros, meal_ingredient population) |
| `supabase/functions/generate-meal-plan/index.ts` | Modify | Structured error handling for `insufficient_recipes`; fix response/provider shape mismatch |
| `lib/shared/models/meal_plan.dart` | Modify | New `MealIngredient` model; `MealPlanEntry` reads `calories_computed` etc.; add `ingredients` field |
| `lib/providers/meal_plan_provider.dart` | Modify | Include `meal_ingredient(*)` in active plan query; fix response parsing in generator notifier |

---

### Task 1: Migration — `meal_ingredient` table

**Files:**
- Create: `supabase/migrations/20260529000001_add_meal_ingredient_table.sql`

- [ ] **Step 1: Write the migration**

```sql
-- =============================================================================
-- Migration: 20260529000001_add_meal_ingredient_table.sql
-- Description: Per-entry ingredient list scaled to user portion size
-- =============================================================================

CREATE TABLE public.meal_ingredient (
  id                  uuid    NOT NULL DEFAULT gen_random_uuid(),
  meal_plan_entry_id  uuid    NOT NULL REFERENCES public.meal_plan_entry(id) ON DELETE CASCADE,
  ingredient_id       uuid    REFERENCES public.ingredient(id),
  ingredient_name     text    NOT NULL,
  quantity            numeric NOT NULL,
  unit                text    NOT NULL,
  CONSTRAINT meal_ingredient_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_meal_ingredient_entry ON public.meal_ingredient(meal_plan_entry_id);

ALTER TABLE public.meal_ingredient ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own meal ingredients"
ON public.meal_ingredient FOR SELECT
USING (
  auth.uid() = (
    SELECT mp.user_id
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mpe.id = meal_plan_entry_id
  )
);

COMMENT ON TABLE public.meal_ingredient IS
  'Pre-computed ingredient quantities scaled to the user portion size (recipe_ingredient.quantity × entry.servings). Populated at plan generation time.';
```

- [ ] **Step 2: Apply migration locally**

```bash
supabase db push
```
Expected: migration applied, no errors.

- [ ] **Step 3: Verify table exists**

```bash
supabase db diff --linked
```
Expected: `meal_ingredient` table present in diff output.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260529000001_add_meal_ingredient_table.sql
git commit -m "feat(db): add meal_ingredient table for pre-scaled ingredient quantities"
```

---

### Task 2: Migration — computed macro columns on `meal_plan_entry`

**Files:**
- Create: `supabase/migrations/20260529000002_add_computed_macros_to_entry.sql`

- [ ] **Step 1: Write the migration**

```sql
-- =============================================================================
-- Migration: 20260529000002_add_computed_macros_to_entry.sql
-- Description: Pre-computed macros stored at generation time (calories × servings)
-- =============================================================================

ALTER TABLE public.meal_plan_entry
  ADD COLUMN calories_computed  numeric,
  ADD COLUMN protein_g_computed numeric,
  ADD COLUMN carbs_g_computed   numeric,
  ADD COLUMN fat_g_computed     numeric;

COMMENT ON COLUMN public.meal_plan_entry.calories_computed IS
  'recipe_macro.calories × entry.servings — computed at generation time, read directly by the app';
COMMENT ON COLUMN public.meal_plan_entry.protein_g_computed IS
  'recipe_macro.protein_g × entry.servings — computed at generation time';
COMMENT ON COLUMN public.meal_plan_entry.carbs_g_computed IS
  'recipe_macro.carbs_g × entry.servings — computed at generation time';
COMMENT ON COLUMN public.meal_plan_entry.fat_g_computed IS
  'recipe_macro.fat_g × entry.servings — computed at generation time';
```

- [ ] **Step 2: Apply migration**

```bash
supabase db push
```
Expected: four nullable columns added to `meal_plan_entry`, no errors.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260529000002_add_computed_macros_to_entry.sql
git commit -m "feat(db): add computed macro columns to meal_plan_entry"
```

---

### Task 3: Migration — rewrite `generate_meal_plan` RPC

**Files:**
- Create: `supabase/migrations/20260529000003_rewrite_generate_meal_plan.sql`

This is the core fix. Changes from the current patch (`20260525000004`):
1. **All-or-nothing**: `RAISE EXCEPTION 'insufficient_recipes'` instead of `CONTINUE` when no recipe found
2. **3-entry cap**: `unnest(v_used_recipe_ids)` count check replaces boolean exclusion
3. **Fan 90% rule**: `v_other_count < v_max_other_slots` gate added
4. **Serving scale upper bound**: `LEAST(4.0, ...)` added to clamp
5. **Pre-computed macros**: `calories_computed` etc. populated on insert
6. **`meal_ingredient` population**: INSERT after each entry
7. **RETURN QUERY**: now returns scaled `calories` and `protein_g`
8. Per-meal targets already handled via existing `meal_distribution` join — kept as-is

- [ ] **Step 1: Write the migration**

```sql
-- =============================================================================
-- Migration: 20260529000003_rewrite_generate_meal_plan.sql
-- Description: All-or-nothing generation, 3-entry cap, fan 90% rule,
--              scale bounds, pre-computed macros, meal_ingredient population
-- =============================================================================

DROP FUNCTION IF EXISTS generate_meal_plan(uuid, int, int, date);
CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id       uuid,
  p_days          int     DEFAULT 7,
  p_meals_per_day int     DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  meal_plan_id    uuid,
  entry_id        uuid,
  component_id    uuid,
  scheduled_date  date,
  meal_type       text,
  recipe_id       uuid,
  recipe_title    text,
  cover_image_url text,
  calories        numeric,
  protein_g       numeric,
  similarity      float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector       vector(50);
  v_fan_creator_id    uuid;
  v_plan_id           uuid;
  v_meal_types        text[] := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day               int;
  v_meal_type         text;
  v_current_date      date;
  v_recipe            record;
  v_entry_id          uuid;
  v_component_id      uuid;
  v_used_recipe_ids   uuid[] := ARRAY[]::uuid[];
  v_calorie_goal      numeric;
  v_target_meal_cal   numeric;
  v_servings          numeric(4,1);
  v_fan_count         int := 0;
  v_other_count       int := 0;
  v_total_slots       int;
  v_max_other_slots   int;
BEGIN
  -- Compute fan quota
  v_total_slots     := p_days * p_meals_per_day;
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  -- Determine meal types
  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  -- Get user vector
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Get fan creator
  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  -- Get fallback calorie goal
  SELECT calorie_goal INTO v_calorie_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  -- Disable previous active plans
  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  -- Create new plan (rolled back automatically if RAISE EXCEPTION is hit)
  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      -- Per-meal calorie target from meal_distribution
      v_target_meal_cal := NULL;
      SELECT md.calorie_target INTO v_target_meal_cal
      FROM meal_distribution md
      JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
      WHERE np.user_id = p_user_id
        AND np.is_active = true
        AND md.meal_type = v_meal_type
      LIMIT 1;

      -- Fallback to flat split
      IF v_target_meal_cal IS NULL AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / p_meals_per_day;
      END IF;

      -- Select best recipe with all constraints applied
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (1 - (rv.vector <=> v_user_vector)) *
               CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
                 THEN 1.5 ELSE 1.0 END AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          -- 3-entry cap
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          -- Fan 90% rule
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          -- Scale cap: skip if would exceed 4.0x
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               0.5::float AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
        GROUP BY r.id, rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g, r.creator_id
        ORDER BY COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      -- All-or-nothing: abort entire plan if no recipe found
      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
      END IF;

      -- Calculate servings with bounds
      IF v_target_meal_cal IS NOT NULL AND v_recipe.calories > 0 THEN
        v_servings := GREATEST(0.1, LEAST(4.0, ROUND((v_target_meal_cal / v_recipe.calories)::numeric, 1)));
      ELSE
        v_servings := 1.0;
      END IF;

      -- Insert entry with pre-computed macros
      INSERT INTO meal_plan_entry (
        meal_plan_id, scheduled_date, meal_type, servings,
        calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed
      )
      VALUES (
        v_plan_id, v_current_date, v_meal_type, v_servings,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        ROUND((v_recipe.carbs_g   * v_servings)::numeric, 1),
        ROUND((v_recipe.fat_g     * v_servings)::numeric, 1)
      )
      RETURNING id INTO v_entry_id;

      -- Add base recipe component
      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      -- Populate meal_ingredient (scaled by servings)
      INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
      SELECT
        v_entry_id,
        ri.ingredient_id,
        COALESCE(i.name_fr, i.name),
        ROUND((ri.quantity * v_servings)::numeric, 3),
        ri.unit
      FROM recipe_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = v_recipe.id
        AND ri.is_optional = false;

      -- Track usage
      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

      RETURN QUERY SELECT
        v_plan_id,
        v_entry_id,
        v_component_id,
        v_current_date,
        v_meal_type,
        v_recipe.id,
        v_recipe.title,
        v_recipe.cover_image_url,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        v_recipe.score::float;

    END LOOP;
  END LOOP;
END;
$$;
```

- [ ] **Step 2: Apply migration**

```bash
supabase db push
```
Expected: no errors. The function replaces the previous version.

- [ ] **Step 3: Smoke test the RPC directly**

In Supabase SQL editor (or via `supabase db execute`), run with a real user ID that has recipes:
```sql
SELECT * FROM generate_meal_plan(
  p_user_id    := '<your-test-user-uuid>',
  p_days       := 7,
  p_meals_per_day := 3,
  p_start_date := CURRENT_DATE
);
```
Expected: 21 rows returned; no recipe appears more than 3 times; `calories` column shows scaled values.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260529000003_rewrite_generate_meal_plan.sql
git commit -m "feat(db): rewrite generate_meal_plan — all-or-nothing, 3-entry cap, fan 90% rule, scale bounds, pre-computed macros"
```

---

### Task 4: Edge function — error handling + response shape fix

**Files:**
- Modify: `supabase/functions/generate-meal-plan/index.ts`

Two fixes:
1. Catch `insufficient_recipes` RPC exception and return a structured error
2. Fix shape mismatch: the Flutter provider currently expects `res.data` to be a `List` but the function returns a `Map` — align them

- [ ] **Step 1: Update the edge function**

Replace the content of `supabase/functions/generate-meal-plan/index.ts` with:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("generate-meal-plan");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn("EARLY RETURN | reason: unauthorized");
      return unauthorized();
    }
    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 1] Parse body");
    const body = await req.json();
    const {
      start_date = new Date().toISOString().split("T")[0],
      days = 7,
      meals_per_day = 3,
    } = body;
    logger.debug("[STEP 1] Body parsed", { start_date, days, meals_per_day });

    if (days < 1 || days > 14) {
      logger.warn("EARLY RETURN | reason: days out of range | days: " + days);
      return err("days must be between 1 and 14");
    }

    logger.debug("[STEP 2] RPC call | fn: generate_meal_plan");
    logRLSCheck(logger, "generate_meal_plan", "RPC", user.id);
    const { data, error } = await client.rpc("generate_meal_plan", {
      p_user_id: user.id,
      p_days: days,
      p_meals_per_day: meals_per_day,
      p_start_date: start_date,
    });
    logQueryResult(logger, "generate_meal_plan", "RPC", data?.length ?? 0, error ?? undefined);

    if (error) {
      // All-or-nothing: not enough recipes for a meal type
      if (error.message === "insufficient_recipes" || error.code === "P0001") {
        const mealType = error.details ?? "unknown";
        logger.warn("EARLY RETURN | reason: insufficient_recipes | meal_type: " + mealType);
        return err("Pas assez de recettes disponibles pour : " + mealType, 422);
      }
      throw error;
    }

    const mealPlanId = data?.[0]?.meal_plan_id ?? null;
    logger.debug("[STEP 3] Plan created | meal_plan_id: " + mealPlanId + " | entries: " + (data?.length ?? 0));

    if (mealPlanId) {
      logger.debug("[STEP 4] RPC call | fn: create_batch_sessions");
      logRLSCheck(logger, "create_batch_sessions", "RPC", user.id);
      const { error: batchError } = await client.rpc("create_batch_sessions", {
        p_meal_plan_id: mealPlanId,
        p_user_id: user.id,
      });
      logQueryResult(logger, "create_batch_sessions", "RPC", 0, batchError ?? undefined);
      if (batchError) {
        logger.warn("create_batch_sessions failed (non-fatal) | " + batchError.message);
      }
    }

    logger.info("✅ EXIT | status: 200 | entries: " + (data?.length ?? 0) + " | duration: " + (Date.now() - start) + "ms");
    return ok({
      meal_plan_id: mealPlanId,
      start_date,
      days,
      meals_per_day,
    });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 2: Deploy edge function**

```bash
supabase functions deploy generate-meal-plan
```
Expected: deployment succeeds.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/generate-meal-plan/index.ts
git commit -m "fix(edge): structured error handling for insufficient_recipes + fix response shape"
```

---

### Task 5: Dart — new `MealIngredient` model + updated `MealPlanEntry`

**Files:**
- Modify: `lib/shared/models/meal_plan.dart`

Two changes:
1. Add `MealIngredient` model at the bottom of the file
2. Update `MealPlanEntry` to read `calories_computed` etc. and include `ingredients` list

- [ ] **Step 1: Add `MealIngredient` model**

At the bottom of `lib/shared/models/meal_plan.dart`, after the `ShoppingItem` class, add:

```dart
// ---------------------------------------------------------------------------
// MealIngredient
// Pre-computed ingredient quantity for a meal entry (scaled to user portion).
// ---------------------------------------------------------------------------

@immutable
class MealIngredient {
  final String id;
  final String mealPlanEntryId;
  final String? ingredientId;
  final String ingredientName;
  final double quantity;
  final String unit;

  const MealIngredient({
    required this.id,
    required this.mealPlanEntryId,
    this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) => MealIngredient(
        id: json['id'] as String,
        mealPlanEntryId: json['meal_plan_entry_id'] as String,
        ingredientId: json['ingredient_id'] as String?,
        ingredientName: json['ingredient_name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
      );

  String get quantityDisplay =>
      '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} $unit';
}
```

- [ ] **Step 2: Update `MealPlanEntry` fields**

In `lib/shared/models/meal_plan.dart`, update the `MealPlanEntry` class.

Add these fields after `customFatG`:
```dart
  final double? caloriesComputed;
  final double? proteinGComputed;
  final double? carbsGComputed;
  final double? fatGComputed;
  final List<MealIngredient> ingredients;
```

Update the constructor to include the new fields:
```dart
  const MealPlanEntry({
    required this.id,
    required this.mealPlanId,
    required this.mealType,
    required this.scheduledDate,
    required this.servings,
    required this.isConsumed,
    required this.isCustomMeal,
    this.customMealName,
    this.customCalories,
    this.customProteinG,
    this.customCarbsG,
    this.customFatG,
    this.caloriesComputed,
    this.proteinGComputed,
    this.carbsGComputed,
    this.fatGComputed,
    required this.ingredients,
    required this.components,
  });
```

Update `fromJson` to map the new fields (add after `customFatG` mapping):
```dart
        caloriesComputed: (json['calories_computed'] as num?)?.toDouble(),
        proteinGComputed: (json['protein_g_computed'] as num?)?.toDouble(),
        carbsGComputed: (json['carbs_g_computed'] as num?)?.toDouble(),
        fatGComputed: (json['fat_g_computed'] as num?)?.toDouble(),
        ingredients: (json['meal_ingredient'] as List<dynamic>?)
                ?.map((e) => MealIngredient.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
```

- [ ] **Step 3: Update macro getters to use pre-computed values**

Replace the existing `calories`, `proteinG`, `carbsG`, `fatG` getters:

```dart
  // Macros — read pre-computed backend values when available, fall through to
  // component sum (legacy entries before migration) or custom values.
  double get calories {
    if (isCustomMeal) return customCalories ?? 0.0;
    if (caloriesComputed != null) return caloriesComputed!;
    return components.fold(0.0, (s, c) => s + (c.calories ?? 0.0)) * servings;
  }

  double get proteinG {
    if (isCustomMeal) return customProteinG ?? 0.0;
    if (proteinGComputed != null) return proteinGComputed!;
    return components.fold(0.0, (s, c) => s + (c.proteinG ?? 0.0)) * servings;
  }

  double get carbsG {
    if (isCustomMeal) return customCarbsG ?? 0.0;
    if (carbsGComputed != null) return carbsGComputed!;
    return components.fold(0.0, (s, c) => s + (c.carbsG ?? 0.0)) * servings;
  }

  double get fatG {
    if (isCustomMeal) return customFatG ?? 0.0;
    if (fatGComputed != null) return fatGComputed!;
    return components.fold(0.0, (s, c) => s + (c.fatG ?? 0.0)) * servings;
  }
```

Note: the `* servings` fallback also fixes the display bug for legacy entries that were generated before the migration.

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/shared/models/meal_plan.dart
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/meal_plan.dart
git commit -m "feat(dart): add MealIngredient model; MealPlanEntry reads pre-computed macros"
```

---

### Task 6: Provider — include `meal_ingredient` in query + fix generator response parsing

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart`

Two fixes:
1. Include `meal_ingredient(*)` in the `activeMealPlanProvider` select query
2. Fix `MealPlanGeneratorNotifier.generate()` — it currently expects `res.data` to be a `List` but the edge function now returns a `Map`

- [ ] **Step 1: Update `activeMealPlanProvider` query**

In `lib/providers/meal_plan_provider.dart`, find the `.select(...)` call in `activeMealPlanProvider` (around line 27) and update it:

```dart
    final data = await client
        .from('meal_plan')
        .select(
          '*, meal_plan_entry(*, meal_ingredient(*), meal_plan_entry_component(*, recipe(id, title, cover_image_url, recipe_macro(calories, protein_g, carbs_g, fat_g))))',
        )
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();
```

- [ ] **Step 2: Fix `MealPlanGeneratorNotifier.generate()` response parsing**

In `lib/providers/meal_plan_provider.dart`, replace the response handling block in `generate()` (lines 89–107) with:

```dart
        final data = res.data;
        _logger.edge('generate-meal-plan', 'AFTER | success | responseType: ${data.runtimeType}');

        String? mealPlanId;
        if (data is Map<String, dynamic>) {
          mealPlanId = data['meal_plan_id'] as String?;
        } else if (data is List && data.isNotEmpty) {
          // Legacy shape fallback
          final firstEntry = data.first;
          if (firstEntry is Map && firstEntry.containsKey('meal_plan_id')) {
            mealPlanId = firstEntry['meal_plan_id'] as String?;
          }
        }

        if (mealPlanId == null) {
          _logger.edge('generate-meal-plan', 'ERROR | missing meal_plan_id in response');
          throw StateError('generate-meal-plan: missing meal_plan_id in response');
        }

        // create_batch_sessions is now called inside the edge function — removed from provider.
```

Wait — since the edge function now calls `create_batch_sessions` internally, the provider no longer needs to call it. Remove the `create_batch_sessions` RPC call from `generate()`:

```dart
        final data = res.data;
        _logger.edge('generate-meal-plan', 'AFTER | success | responseType: ${data.runtimeType}');

        String? mealPlanId;
        if (data is Map<String, dynamic>) {
          mealPlanId = data['meal_plan_id'] as String?;
        } else if (data is List && data.isNotEmpty) {
          final firstEntry = data.first;
          if (firstEntry is Map && firstEntry.containsKey('meal_plan_id')) {
            mealPlanId = firstEntry['meal_plan_id'] as String?;
          }
        }

        if (mealPlanId == null) {
          _logger.edge('generate-meal-plan', 'ERROR | missing meal_plan_id in response');
          throw StateError('generate-meal-plan: missing meal_plan_id in response');
        }

        _logger.provider('MealPlanGeneratorNotifier → data (generate success) | mealPlanId: $mealPlanId');
        return null;
```

- [ ] **Step 3: Handle `insufficient_recipes` error in the provider**

In the `catch (e, st)` block of `generate()`, add recognition of the structured error:

```dart
      } catch (e, st) {
        _logger.edge('generate-meal-plan', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('MealPlanGeneratorNotifier → error | $e');
        rethrow;
      }
```

The error will propagate as-is to the UI via `AsyncValue.guard`. The edge function already returns a user-friendly French message — the UI will display it through the existing error snackbar in `MealPlannerPage`.

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/providers/meal_plan_provider.dart
```
Expected: no errors.

- [ ] **Step 5: Hot reload and generate a test plan**

Run the app, navigate to the meal planner, tap the generate FAB. Verify:
- Plan generates without crash
- Macros displayed on entry cards match the calorie target (±rounding)
- No "unexpected shape" error in logs

- [ ] **Step 6: Commit**

```bash
git add lib/providers/meal_plan_provider.dart
git commit -m "fix(provider): include meal_ingredient in query; fix generate response parsing"
```

---

### Task 7: Live Testing — T1 through T6

Run each scenario manually using the Supabase SQL editor and the Flutter app on a test device/emulator.

- [ ] **T1 — Complete Plan (Baseline)**

Setup: confirm test user has a row in `user_vector`, an active `nutrition_plan` with `meal_distribution` rows for breakfast/lunch/dinner, and 20+ published recipes per meal type with `recipe_macro`.

Generate a plan via the app FAB.

Verify in SQL:
```sql
-- No recipe appears more than 3 times
SELECT mpec.recipe_id, COUNT(*) AS appearances
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
WHERE mp.user_id = '<test-user-uuid>' AND mp.is_active = true
GROUP BY mpec.recipe_id
HAVING COUNT(*) > 3;
-- Expected: 0 rows
```

```sql
-- meal_ingredient rows exist for all entries
SELECT mpe.id, COUNT(mi.id) AS ingredient_count
FROM meal_plan_entry mpe
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
LEFT JOIN meal_ingredient mi ON mi.meal_plan_entry_id = mpe.id
WHERE mp.user_id = '<test-user-uuid>' AND mp.is_active = true
GROUP BY mpe.id
HAVING COUNT(mi.id) = 0;
-- Expected: 0 rows (every entry has at least one ingredient)
```

```sql
-- calories_computed is populated
SELECT id, calories_computed, servings FROM meal_plan_entry
WHERE meal_plan_id = (
  SELECT id FROM meal_plan WHERE user_id = '<test-user-uuid>' AND is_active = true
);
-- Expected: all rows have non-null calories_computed
```

- [ ] **T2 — All-or-Nothing on Missing Meal Type**

```sql
-- Temporarily remove breakfast meal_types from all recipes
UPDATE recipe SET meal_types = array_remove(meal_types, 'breakfast')
WHERE 'breakfast' = ANY(meal_types);
```

Attempt to generate a plan via the app FAB.

Expected:
- App shows error snackbar: "Pas assez de recettes disponibles pour : breakfast"
- In SQL: no new `meal_plan` row with `is_active = true` was created for the test user

```sql
-- Restore
UPDATE recipe SET meal_types = array_append(meal_types, 'breakfast')
WHERE id IN (<ids of recipes that had breakfast>);
```

- [ ] **T3 — Macro Accuracy**

```sql
-- Find a breakfast entry and verify computed macros match servings × base calories
SELECT
  mpe.servings,
  mpe.calories_computed,
  rm.calories AS base_calories,
  ROUND((rm.calories * mpe.servings)::numeric, 1) AS expected_computed
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
JOIN recipe_macro rm ON rm.recipe_id = mpec.recipe_id
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
WHERE mp.user_id = '<test-user-uuid>'
  AND mp.is_active = true
  AND mpe.meal_type = 'breakfast';
-- Expected: calories_computed = expected_computed for all rows
```

Verify in the Flutter app: calories shown on meal detail matches `calories_computed` from SQL.

- [ ] **T4 — Fan Subscription 90% Rule**

Setup: ensure test user has an active `fan_subscription` to a creator with 15+ published recipes.

Generate a plan, then run:
```sql
SELECT
  r.creator_id,
  COUNT(*) AS recipe_count
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
JOIN recipe r ON r.id = mpec.recipe_id
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
WHERE mp.user_id = '<test-user-uuid>' AND mp.is_active = true
GROUP BY r.creator_id;
-- Expected: subscribed creator has ≥ 19 entries out of 21 total
```

- [ ] **T5 — Serving Scale Cap**

```sql
-- Set a recipe's calories to 50 temporarily
UPDATE recipe_macro SET calories = 50 WHERE recipe_id = '<a-recipe-uuid>';
-- Ensure this recipe is tagged for lunch
UPDATE recipe SET meal_types = array_append(meal_types, 'lunch') WHERE id = '<a-recipe-uuid>';
```

Generate a plan with a lunch calorie target of 600 kcal (scale would be 12.0).

```sql
-- Verify no entry exceeds 4.0 servings
SELECT id, servings FROM meal_plan_entry
WHERE meal_plan_id = (
  SELECT id FROM meal_plan WHERE user_id = '<test-user-uuid>' AND is_active = true
) AND servings > 4.0;
-- Expected: 0 rows
```

Restore the recipe:
```sql
UPDATE recipe_macro SET calories = <original_value> WHERE recipe_id = '<a-recipe-uuid>';
```

- [ ] **T6a — No User Vector**

```sql
-- Temporarily delete user vector
DELETE FROM user_vector WHERE user_id = '<test-user-uuid>';
```

Generate plan — expected: plan generates successfully using popularity fallback.

```sql
-- Restore
INSERT INTO user_vector (user_id, vector) VALUES ('<test-user-uuid>', '<original-vector>');
```

- [ ] **T6b — No Calorie Goal**

```sql
UPDATE nutrition_plan SET is_active = false WHERE user_id = '<test-user-uuid>';
```

Generate plan — expected: plan generates with `servings = 1.0` for all entries.

```sql
SELECT servings FROM meal_plan_entry WHERE meal_plan_id = (
  SELECT id FROM meal_plan WHERE user_id = '<test-user-uuid>' AND is_active = true
);
-- Expected: all rows have servings = 1.0
```

Restore:
```sql
UPDATE nutrition_plan SET is_active = true WHERE user_id = '<test-user-uuid>'
  AND id = (SELECT id FROM nutrition_plan WHERE user_id = '<test-user-uuid>' ORDER BY created_at DESC LIMIT 1);
```

- [ ] **T6c — Recipes Missing `recipe_macro`**

```sql
-- Temporarily delete recipe_macro for a few recipes
DELETE FROM recipe_macro WHERE recipe_id IN (
  SELECT id FROM recipe WHERE is_published = true LIMIT 3
);
```

Generate plan — expected: plan generates (those recipes excluded from pool), no crash.

Restore:
```sql
-- Re-insert with representative values or run the vectorization pipeline
```

- [ ] **Final commit**

```bash
git add -A
git commit -m "test: live testing complete — T1–T6 all passing"
```
