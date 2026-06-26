# Consumed Toggle & Conditional Rating Sheet — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the consumed checkbox a full toggle (undo consumption), fix the always-false `isRated` flag, and make the review button state-aware.

**Architecture:** New `unconsume-meal` edge function for the undo path. `MealConsumptionNotifier.toggleConsumption` replaces `logConsumption` and routes by current state. `activeMealPlanProvider` gains a second `recipe_comment` query to build a `Set<String>` of rated recipe IDs, threaded into model parsing so `isRated` is correctly derived without a DB schema change.

**Tech Stack:** Deno/TypeScript (Supabase Edge Functions), Dart/Flutter, Riverpod, Supabase PostgREST client.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `supabase/functions/unconsume-meal/index.ts` | CREATE | Reset `is_consumed`, delete `meal_consumption` rows |
| `lib/providers/meal_plan_provider.dart` | MODIFY | Toggle logic in notifier; second query in `activeMealPlanProvider` |
| `lib/shared/models/meal_plan.dart` | MODIFY | Thread `ratedRecipeIds` through `fromJson`; fix `isRated` |
| `lib/features/meal_planner/meal_detail_page.dart` | MODIFY | Remove consume guard; adaptive review button |
| `lib/features/meal_planner/meal_planner_page.dart` | MODIFY | Update `onConsumedToggle` call to use `toggleConsumption` |
| `lib/features/meal_planner/widgets/meal_planner_day_row.dart` | MODIFY | Remove `isConsumed ? null :` gate on `MealCard.onConsumedToggle` |

---

## Task 1: `unconsume-meal` edge function

**Files:**
- Create: `supabase/functions/unconsume-meal/index.ts`

- [ ] **Step 1: Create the file**

```typescript
// supabase/functions/unconsume-meal/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("unconsume-meal");
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
    const { meal_plan_entry_id } = await req.json();
    if (!meal_plan_entry_id) {
      logger.warn("EARLY RETURN | reason: meal_plan_entry_id missing");
      return err("meal_plan_entry_id is required");
    }
    logger.debug("[STEP 1] meal_plan_entry_id: " + meal_plan_entry_id);

    logger.debug("[STEP 2] Verify entry exists and is consumed");
    logRLSCheck(logger, "meal_plan_entry", "SELECT", user.id);
    const { data: entry, error: entryError } = await client
      .from("meal_plan_entry")
      .select("id, is_consumed, meal_plan_id")
      .eq("id", meal_plan_entry_id)
      .maybeSingle();
    logQueryResult(logger, "meal_plan_entry", "SELECT", entry ? 1 : 0, entryError ?? undefined);

    if (entryError || !entry) {
      logger.warn("EARLY RETURN | reason: entry not found | id: " + meal_plan_entry_id);
      return err("Meal plan entry not found", 404);
    }
    if (!entry.is_consumed) {
      logger.warn("EARLY RETURN | reason: entry not consumed | id: " + meal_plan_entry_id);
      return err("Meal is not consumed", 400);
    }

    logger.debug("[STEP 3] Delete meal_consumption rows for this entry");
    logRLSCheck(logger, "meal_consumption", "DELETE", user.id);
    const { error: deleteError } = await client
      .from("meal_consumption")
      .delete()
      .eq("meal_plan_entry_id", meal_plan_entry_id)
      .eq("user_id", user.id);
    logQueryResult(logger, "meal_consumption", "DELETE", deleteError ? 0 : 1, deleteError ?? undefined);

    if (deleteError) throw deleteError;

    logger.debug("[STEP 4] Reset is_consumed on meal_plan_entry");
    const admin = serviceClient();
    const { error: updateError } = await admin
      .from("meal_plan_entry")
      .update({ is_consumed: false, consumed_at: null })
      .eq("id", meal_plan_entry_id)
      .eq("meal_plan_id", entry.meal_plan_id);
    logQueryResult(logger, "meal_plan_entry", "UPDATE", updateError ? 0 : 1, updateError ?? undefined);

    if (updateError) throw updateError;

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ unconsumed: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 2: Deploy the function**

```bash
npx supabase functions deploy unconsume-meal
```

Expected: `Deployed Function unconsume-meal`

- [ ] **Step 3: Smoke-test via curl (replace tokens and IDs)**

```bash
curl -X POST https://<project>.supabase.co/functions/v1/unconsume-meal \
  -H "Authorization: Bearer <user-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"meal_plan_entry_id": "<a-consumed-entry-id>"}'
```

Expected: `{"unconsumed":true}` and the entry's `is_consumed` resets to `false` in the DB.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/unconsume-meal/index.ts
git commit -m "feat: add unconsume-meal edge function"
```

---

## Task 2: `MealConsumptionNotifier` — toggle logic

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart` (class `MealConsumptionNotifier`, lines ~320–365)

- [ ] **Step 1: Replace `logConsumption` with `toggleConsumption`**

Replace the entire `logConsumption` method with `toggleConsumption`:

```dart
Future<void> toggleConsumption(String mealPlanEntryId, {required bool isCurrentlyConsumed}) async {
  if (state.isLoading) return;

  _logger.userAction('Toggle meal consumption | isConsumed: $isCurrentlyConsumed',
      metadata: {'mealPlanEntryId': mealPlanEntryId});

  final client = ref.read(supabaseClientProvider);
  state = const AsyncLoading();

  if (isCurrentlyConsumed) {
    // Undo consumption
    _logger.edge('unconsume-meal', 'BEFORE | mealPlanEntryId: $mealPlanEntryId');
    _logger.provider('MealConsumptionNotifier → loading (unconsume)');
    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'unconsume-meal',
          body: {'meal_plan_entry_id': mealPlanEntryId},
        );
        _logger.edge('unconsume-meal', 'AFTER | success');
        _logger.provider('MealConsumptionNotifier → data (unconsume $mealPlanEntryId)');
        return mealPlanEntryId;
      } catch (e, st) {
        _logger.edge('unconsume-meal', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('MealConsumptionNotifier → error | $e');
        rethrow;
      }
    });
  } else {
    // Log consumption
    _logger.edge('log-meal-consumption', 'BEFORE | mealPlanEntryId: $mealPlanEntryId');
    _logger.provider('MealConsumptionNotifier → loading (consume)');
    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'log-meal-consumption',
          body: {'meal_plan_entry_id': mealPlanEntryId},
        );
        _logger.edge('log-meal-consumption', 'AFTER | success');
        _logger.provider('MealConsumptionNotifier → data (consume $mealPlanEntryId)');
        return mealPlanEntryId;
      } on FunctionException catch (e) {
        final details = e.details;
        if (details is Map && details['error'] == 'Meal already consumed') {
          _logger.edge('log-meal-consumption', 'WARNING | Already consumed. Treating as success.');
          return mealPlanEntryId;
        }
        _logger.edge('log-meal-consumption', 'ERROR | $e');
        _logger.provider('MealConsumptionNotifier → error | $e');
        rethrow;
      } catch (e, st) {
        _logger.edge('log-meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('MealConsumptionNotifier → error | $e');
        rethrow;
      }
    });
  }

  if (state is AsyncData) ref.invalidate(activeMealPlanProvider);
}
```

- [ ] **Step 2: Update call site in `meal_planner_page.dart` (line ~132–134)**

Replace:
```dart
onConsumedToggle: (entryId) {
  appLogger.userAction('Meal consumed toggle', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
  ref.read(mealConsumptionProvider.notifier).logConsumption(entryId);
},
```

With:
```dart
onConsumedToggle: (entryId) {
  appLogger.userAction('Meal consumed toggle', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
  final plan = ref.read(activeMealPlanProvider).valueOrNull;
  final isConsumed = plan?.entries.where((e) => e.id == entryId).firstOrNull?.isConsumed ?? false;
  ref.read(mealConsumptionProvider.notifier).toggleConsumption(entryId, isCurrentlyConsumed: isConsumed);
},
```

- [ ] **Step 3: Update call site in `meal_detail_page.dart` (line ~79–82)**

Replace:
```dart
onConsume: () {
  _logger.userAction('Mark consumed tapped', screen: 'MealDetailPage',
      metadata: {'mealId': entry.id});
  ref.read(mealConsumptionProvider.notifier).logConsumption(entry.id);
},
```

With:
```dart
onConsume: () {
  _logger.userAction('Mark consumed tapped | isConsumed: ${entry.isConsumed}',
      screen: 'MealDetailPage', metadata: {'mealId': entry.id});
  ref.read(mealConsumptionProvider.notifier).toggleConsumption(
    entry.id,
    isCurrentlyConsumed: entry.isConsumed,
  );
},
```

- [ ] **Step 4: Commit**

```bash
git add lib/providers/meal_plan_provider.dart \
        lib/features/meal_planner/meal_planner_page.dart \
        lib/features/meal_planner/meal_detail_page.dart
git commit -m "feat: replace logConsumption with toggleConsumption"
```

---

## Task 3: Fix `isRated` — provider query + model parsing

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart` (`activeMealPlanProvider`, lines ~15–55)
- Modify: `lib/shared/models/meal_plan.dart` (`MealPlan.fromJson`, `MealPlanEntry.fromJson`)

- [ ] **Step 1: Add the second query to `activeMealPlanProvider`**

In `activeMealPlanProvider`, after the existing `meal_plan` SELECT and before `return MealPlan.fromJson(data)`, add:

```dart
// Fetch recipe IDs the user has already rated
appLogger.db('BEFORE | table: recipe_comment | op: SELECT | userId: ${user.id}');
final ratedRaw = await client
    .from('recipe_comment')
    .select('recipe_id')
    .eq('user_id', user.id)
    .not('rating', 'is', null);
appLogger.db('AFTER | table: recipe_comment | rows: ${(ratedRaw as List).length}');
final ratedRecipeIds = (ratedRaw as List)
    .map((r) => r['recipe_id'] as String)
    .toSet();
```

Then replace:
```dart
return MealPlan.fromJson(data);
```
With:
```dart
return MealPlan.fromJson(data, ratedRecipeIds: ratedRecipeIds);
```

- [ ] **Step 2: Update `MealPlan.fromJson` signature**

In `lib/shared/models/meal_plan.dart`, replace:

```dart
factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: (json['is_active'] as bool?) ?? true,
      entries: (json['meal_plan_entry'] as List<dynamic>?)
              ?.map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
```

With:

```dart
factory MealPlan.fromJson(Map<String, dynamic> json, {Set<String> ratedRecipeIds = const {}}) => MealPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: (json['is_active'] as bool?) ?? true,
      entries: (json['meal_plan_entry'] as List<dynamic>?)
              ?.map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>,
                  ratedRecipeIds: ratedRecipeIds))
              .toList() ??
          [],
    );
```

- [ ] **Step 3: Fix `MealPlanEntry.fromJson` — replace broken `isRated` derivation**

In `MealPlanEntry.fromJson`, the `isRated` line currently reads:

```dart
isRated: ((json['meal_consumption'] as List<dynamic>?) ?? [])
    .any((c) => (c as Map<String, dynamic>)['rating'] != null),
```

Replace with a named-parameter factory that parses components first:

```dart
factory MealPlanEntry.fromJson(Map<String, dynamic> json, {Set<String> ratedRecipeIds = const {}}) {
  final components = (json['meal_plan_entry_component'] as List<dynamic>?)
          ?.map((e) => MealPlanEntryComponent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [];
  return MealPlanEntry(
    id: json['id'] as String,
    mealPlanId: json['meal_plan_id'] as String,
    mealType: json['meal_type'] as String,
    scheduledDate: DateTime.parse(json['scheduled_date'] as String),
    servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
    isConsumed: (json['is_consumed'] as bool?) ?? false,
    isRated: components.any((c) => ratedRecipeIds.contains(c.recipeId)),
    isCustomMeal: (json['is_custom_meal'] as bool?) ?? false,
    customMealName: json['custom_meal_name'] as String?,
    customCalories: (json['custom_calories'] as num?)?.toDouble(),
    customProteinG: (json['custom_protein_g'] as num?)?.toDouble(),
    customCarbsG: (json['custom_carbs_g'] as num?)?.toDouble(),
    customFatG: (json['custom_fat_g'] as num?)?.toDouble(),
    caloriesComputed: (json['calories_computed'] as num?)?.toDouble(),
    proteinGComputed: (json['protein_g_computed'] as num?)?.toDouble(),
    carbsGComputed: (json['carbs_g_computed'] as num?)?.toDouble(),
    fatGComputed: (json['fat_g_computed'] as num?)?.toDouble(),
    ingredients: (json['meal_ingredient'] as List<dynamic>?)
            ?.map((e) => MealIngredient.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    components: components,
  );
}
```

- [ ] **Step 4: Verify the app compiles**

```bash
flutter analyze lib/shared/models/meal_plan.dart lib/providers/meal_plan_provider.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/meal_plan.dart lib/providers/meal_plan_provider.dart
git commit -m "fix: derive isRated from recipe_comment instead of dropped meal_consumption.rating"
```

---

## Task 4: UI — unlock consumed toggle, adaptive review button

**Files:**
- Modify: `lib/features/meal_planner/widgets/meal_planner_day_row.dart` (lines ~94–99)
- Modify: `lib/features/meal_planner/meal_detail_page.dart` (lines ~259, ~512–528)

- [ ] **Step 1: Remove `isConsumed ? null :` gate in `meal_planner_day_row.dart`**

Replace (lines ~94–99):
```dart
onConsumedToggle: entry.isConsumed
    ? null
    : () {
        appLogger.userAction('Meal card consumed toggle', screen: 'MealPlannerDayRow', metadata: {'entryId': entry.id});
        onConsumedToggle?.call(entry.id);
      },
```

With:
```dart
onConsumedToggle: () {
  appLogger.userAction('Meal card consumed toggle', screen: 'MealPlannerDayRow', metadata: {'entryId': entry.id});
  onConsumedToggle?.call(entry.id);
},
```

- [ ] **Step 2: Remove `entry.isConsumed ? null :` guard on the consume row in `meal_detail_page.dart`**

In `_MealDetailBody`, replace (line ~259):
```dart
onTap: isConsumeLoading || entry.isConsumed ? null : onConsume,
```
With:
```dart
onTap: isConsumeLoading ? null : onConsume,
```

- [ ] **Step 3: Make the review button 3-state in `meal_detail_page.dart`**

Replace the `_ActionButton` block for rating (lines ~511–528):
```dart
_ActionButton(
  icon: entry.isConsumed ? Icons.star_rounded : Icons.star_border_rounded,
  label: entry.isConsumed ? 'Note & commentaire' : 'Consommez d\'abord ce repas',
  color: AkeliColors.accentAmber,
  onTap: entry.isConsumed
      ? () {
          appLogger.userAction('Rating tapped', screen: 'MealDetailPage',
              metadata: {'mealId': entry.id});
          showModalBottomSheet(
            context: pageContext,
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            backgroundColor: Colors.transparent,
            builder: (_) => RatingBottomSheet(mealPlanEntryId: entry.id),
          );
        }
      : null,
),
```

With:
```dart
_ActionButton(
  icon: entry.isRated ? Icons.star_rounded : Icons.star_border_rounded,
  label: !entry.isConsumed
      ? 'Consommez d\'abord ce repas'
      : entry.isRated
          ? 'Modifier votre avis'
          : 'Laisser un avis',
  color: AkeliColors.accentAmber,
  onTap: entry.isConsumed
      ? () {
          appLogger.userAction(
            entry.isRated ? 'Update rating tapped' : 'Rate tapped',
            screen: 'MealDetailPage',
            metadata: {'mealId': entry.id, 'isRated': entry.isRated},
          );
          showModalBottomSheet(
            context: pageContext,
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            backgroundColor: Colors.transparent,
            builder: (_) => RatingBottomSheet(mealPlanEntryId: entry.id),
          );
        }
      : null,
),
```

- [ ] **Step 4: Verify the app compiles**

```bash
flutter analyze lib/features/meal_planner/
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/widgets/meal_planner_day_row.dart \
        lib/features/meal_planner/meal_detail_page.dart
git commit -m "feat: consumed checkbox toggle + adaptive review button state"
```

---

## Task 5: End-to-end verification

- [ ] **Step 1: Run the app**

```bash
flutter run
```

- [ ] **Step 2: Test first consumption — rating sheet appears**

1. Open the meal planner. Find an unconsumed meal.
2. Tap the meal card checkbox. The card turns green.
3. Confirm the `RatingBottomSheet` appears automatically.
4. Submit a rating.
5. Confirm the review button in the meal detail page shows `'Modifier votre avis'` with `Icons.star_rounded`.

- [ ] **Step 3: Test second consumption — rating sheet skipped**

1. From the meal detail page, tap the consumed row again (unconsume).
2. Confirm the card reverts to unchecked.
3. Tap the checkbox again to re-consume.
4. Confirm the rating sheet does NOT appear (because the recipe is already rated).

- [ ] **Step 4: Test unconsume from the meal detail page**

1. Open the meal detail page for a consumed meal.
2. Tap the consumed row.
3. Confirm `is_consumed` flips back to `false` (row turns grey, label reverts to "Marquer comme consommé").
4. Confirm the review button reverts to disabled ("Consommez d'abord ce repas").

- [ ] **Step 5: Final commit**

```bash
git add .
git commit -m "feat: consumed toggle and conditional rating sheet"
```
