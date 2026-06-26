# Optimistic Meal Logging

**Date:** 2026-06-13  
**Status:** Approved

## Problem

When a user taps the consumed checkmark on a meal card, the UI waits for a full round-trip: edge function call → DB write → `activeMealPlanProvider` invalidate → DB refetch. The checkmark only flips after all of that completes, making the interaction feel slow.

## Goal

The checkmark flips immediately on tap. The edge function call happens in the background. On error, the checkmark reverts and an error message is shown. The nutrition summary (calorie ring, macro totals) is **not** updated optimistically — only the checkmark.

## Architecture

### New provider

```dart
// lib/providers/meal_plan_provider.dart
final optimisticConsumptionProvider =
    StateProvider<Map<String, bool>>((ref) => {});
```

A `Map<String, bool>` keyed by `mealPlanEntryId`. A value of `true` means optimistically consumed, `false` means optimistically un-consumed. Entries are removed once the server confirms (after the next `activeMealPlanProvider` refetch resolves).

### Updated `toggleConsumption()`

`MealConsumptionNotifier.toggleConsumption()` gains three phases:

1. **Optimistic write** — synchronously set `optimisticConsumptionProvider[entryId] = !isCurrentlyConsumed` before any async work
2. **Edge function call** — unchanged (`log-meal-consumption` / `unconsume-meal`)
3. **On success** — remove the override; the `invalidate(activeMealPlanProvider)` + refetch confirms the DB value  
   **On error** — revert the override to `isCurrentlyConsumed`, then rethrow

The `invalidate(activeMealPlanProvider)` call stays in place and is unchanged.

### Callsite merge (3 places)

Every callsite that renders a meal card adds one read of the overlay and merges it with the DB value:

```dart
final overrides = ref.watch(optimisticConsumptionProvider);
final effectiveIsConsumed = overrides[entry.id] ?? entry.isConsumed;
```

`effectiveIsConsumed` is passed to `isConsumed:` instead of `entry.isConsumed`.

Affected files:
- `lib/features/home/home_page.dart`
- `lib/features/meal_planner/meal_planner_page.dart` (via `MealPlannerDayRow`)
- `lib/features/meal_planner/meal_detail_page.dart`

### Error snackbar

When `toggleConsumption()` rethrows after reverting, the callsite catches and shows:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Impossible de mettre à jour le repas. Réessayez.')),
);
```

The `try/catch` wraps the `ref.read(mealConsumptionProvider.notifier).toggleConsumption(...)` call at each of the 3 callsites.

## What does not change

- `activeMealPlanProvider` — remains a `FutureProvider.autoDispose`, no conversion needed
- `AkeliMealCard` widget — no changes, already accepts `isConsumed` as a prop
- `MealPlanEntry` model — no `copyWith` needed
- Edge functions — unchanged
- Nutrition summary (daily macros ring, calorie totals) — not optimistically updated

## Files to create/modify

| File | Change |
|------|--------|
| `lib/providers/meal_plan_provider.dart` | Add `optimisticConsumptionProvider`; update `toggleConsumption()` |
| `lib/features/home/home_page.dart` | Merge overlay at meal card callsite; wrap toggle in try/catch |
| `lib/features/meal_planner/meal_planner_page.dart` | Merge overlay at `onConsumedToggle`; wrap in try/catch |
| `lib/features/meal_planner/meal_detail_page.dart` | Merge overlay; wrap in try/catch |
