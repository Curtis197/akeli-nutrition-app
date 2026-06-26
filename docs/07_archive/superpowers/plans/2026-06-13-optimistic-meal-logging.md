# Optimistic Meal Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flip the meal consumed checkmark immediately on tap, call the edge function in the background, and revert with a snackbar on failure.

**Architecture:** A single `StateProvider<Map<String, bool>>` (`optimisticConsumptionProvider`) stores per-entry overrides. `toggleConsumption()` writes the override before the async call and reverts on error. The three callsites merge the overlay with the DB value using `overrides[entry.id] ?? entry.isConsumed`.

**Tech Stack:** Flutter, Riverpod (`StateProvider`, `AutoDisposeAsyncNotifier`), Dart async/await, mocktail

---

## File Map

| File | Change |
|------|--------|
| `lib/providers/meal_plan_provider.dart` | Add `optimisticConsumptionProvider`; rewrite `toggleConsumption()` to use try/catch + optimistic write/revert |
| `lib/features/home/home_page.dart` | Merge overlay; make callback async; add snackbar on error; remove manual `invalidate` |
| `lib/features/meal_planner/meal_planner_page.dart` | Merge overlay; make callback async; add snackbar on error |
| `lib/features/meal_planner/meal_detail_page.dart` | Merge overlay; pass effective value to toggle call |
| `test/providers/optimistic_consumption_test.dart` | New — unit tests for overlay provider and merge logic |

---

### Task 1: Add `optimisticConsumptionProvider` and rewrite `toggleConsumption()`

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart`

**Background:** The current `toggleConsumption()` uses `AsyncValue.guard()` which swallows exceptions — callers never see errors. We replace it with a plain try/catch so errors can be rethrown after reverting the optimistic state. `optimisticConsumptionProvider` is not `autoDispose` so it survives across notifier resets.

- [ ] **Step 1: Add `optimisticConsumptionProvider` after `mealConsumptionProvider`**

Open `lib/providers/meal_plan_provider.dart`. After line 418 (the `mealConsumptionProvider` declaration), add:

```dart
// Optimistic overlay — entryId → isConsumed — cleared after server confirms.
final optimisticConsumptionProvider =
    StateProvider<Map<String, bool>>((ref) => {});
```

- [ ] **Step 2: Replace `toggleConsumption()` with the optimistic version**

Replace the entire `toggleConsumption` method body (lines 354–413 in `meal_plan_provider.dart`) with:

```dart
Future<void> toggleConsumption(String mealPlanEntryId, {required bool isCurrentlyConsumed}) async {
  if (state.isLoading) return;

  _logger.userAction('Toggle meal consumption | isConsumed: $isCurrentlyConsumed',
      metadata: {'mealPlanEntryId': mealPlanEntryId});

  // Phase 1: optimistic write — flip before any async work
  ref.read(optimisticConsumptionProvider.notifier)
      .update((map) => {...map, mealPlanEntryId: !isCurrentlyConsumed});

  final client = ref.read(supabaseClientProvider);
  state = const AsyncLoading();

  try {
    if (isCurrentlyConsumed) {
      _logger.edge('unconsume-meal', 'BEFORE | mealPlanEntryId: $mealPlanEntryId');
      _logger.provider('MealConsumptionNotifier → loading (unconsume)');
      await client.functions.invoke(
        'unconsume-meal',
        body: {'meal_plan_entry_id': mealPlanEntryId},
      );
      _logger.edge('unconsume-meal', 'AFTER | success');
      _logger.provider('MealConsumptionNotifier → data (unconsume $mealPlanEntryId)');
      state = const AsyncData(null);
    } else {
      _logger.edge('log-meal-consumption', 'BEFORE | mealPlanEntryId: $mealPlanEntryId');
      _logger.provider('MealConsumptionNotifier → loading (consume)');
      try {
        await client.functions.invoke(
          'log-meal-consumption',
          body: {'meal_plan_entry_id': mealPlanEntryId},
        );
      } on FunctionException catch (e, st) {
        final details = e.details;
        if (details is Map && details['error'] == 'Meal already consumed') {
          _logger.edge('log-meal-consumption', 'WARNING | Already consumed. Treating as success.');
        } else {
          _logger.edge('log-meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
          rethrow;
        }
      }
      _logger.edge('log-meal-consumption', 'AFTER | success');
      _logger.provider('MealConsumptionNotifier → data (consume $mealPlanEntryId)');
      state = AsyncData(mealPlanEntryId);
    }
    // Success: remove override, DB refetch confirms
    ref.read(optimisticConsumptionProvider.notifier)
        .update((map) => Map.from(map)..remove(mealPlanEntryId));
    ref.invalidate(activeMealPlanProvider);
  } catch (e, st) {
    // Revert optimistic override
    ref.read(optimisticConsumptionProvider.notifier)
        .update((map) => {...map, mealPlanEntryId: isCurrentlyConsumed});
    _logger.edge('meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
    _logger.provider('MealConsumptionNotifier → error | $e', error: e, stackTrace: st);
    state = AsyncError(e, st);
    rethrow;
  }
}
```

- [ ] **Step 3: Verify it compiles**

```bash
flutter analyze lib/providers/meal_plan_provider.dart
```

Expected: no errors. Warnings about unused imports are fine.

- [ ] **Step 4: Commit**

```bash
git add lib/providers/meal_plan_provider.dart
git commit -m "feat: add optimisticConsumptionProvider and rewrite toggleConsumption with optimistic write/revert"
```

---

### Task 2: Unit tests for the overlay provider and merge logic

**Files:**
- Create: `test/providers/optimistic_consumption_test.dart`

- [ ] **Step 1: Create the test file**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/providers/meal_plan_provider.dart';

void main() {
  group('optimisticConsumptionProvider', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(optimisticConsumptionProvider), isEmpty);
    });

    test('sets override for an entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, 'entry-1': true});
      expect(container.read(optimisticConsumptionProvider)['entry-1'], isTrue);
    });

    test('reverts override on simulated error', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, 'entry-1': true});
      // Simulate revert
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, 'entry-1': false});
      expect(container.read(optimisticConsumptionProvider)['entry-1'], isFalse);
    });

    test('clears override after success', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, 'entry-1': true});
      container.read(optimisticConsumptionProvider.notifier)
          .update((map) => Map.from(map)..remove('entry-1'));
      expect(container.read(optimisticConsumptionProvider).containsKey('entry-1'), isFalse);
    });
  });

  group('effective isConsumed merge', () {
    test('overlay takes precedence over db value', () {
      const dbIsConsumed = false;
      final overrides = {'entry-1': true};
      final effective = overrides['entry-1'] ?? dbIsConsumed;
      expect(effective, isTrue);
    });

    test('falls back to db value when no override exists', () {
      const dbIsConsumed = true;
      final overrides = <String, bool>{};
      final effective = overrides['entry-1'] ?? dbIsConsumed;
      expect(effective, isTrue);
    });

    test('overlay false overrides db true', () {
      const dbIsConsumed = true;
      final overrides = {'entry-1': false};
      final effective = overrides['entry-1'] ?? dbIsConsumed;
      expect(effective, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests**

```bash
flutter test test/providers/optimistic_consumption_test.dart
```

Expected: 7 tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/providers/optimistic_consumption_test.dart
git commit -m "test: optimisticConsumptionProvider overlay and merge logic"
```

---

### Task 3: Home page — overlay merge + error snackbar

**Files:**
- Modify: `lib/features/home/home_page.dart`

**Background:** The home page `itemBuilder` currently passes `entry.isConsumed` directly and doesn't await the toggle, so errors are silently lost. We add the overlay merge and a try/catch snackbar. The manual `ref.invalidate(activeMealPlanProvider)` call is removed — `toggleConsumption()` now handles it on success.

- [ ] **Step 1: Add overlay merge and update `isConsumed` + callback**

Locate this block in `lib/features/home/home_page.dart` (around line 388–419):

```dart
final entry = todayEntries[index];
return AkeliMealCard(
  key: ValueKey(entry.id),
  title: entry.recipeTitle ?? 'Repas',
  mealType: entry.mealType,
  calories: entry.calories,
  imageUrl: entry.recipeThumbnail,
  isConsumed: entry.isConsumed,
  onConsumedToggle: () {
    HapticFeedback.mediumImpact();
    _logger.userAction('Meal consumed toggled',
        screen: 'HomePage',
        metadata: {
          'mealId': entry.id,
          'wasConsumed': entry.isConsumed,
        });
    ref
        .read(mealConsumptionProvider.notifier)
        .toggleConsumption(
          entry.id,
          isCurrentlyConsumed: entry.isConsumed,
        );
    ref.invalidate(activeMealPlanProvider);
  },
```

Replace with:

```dart
final entry = todayEntries[index];
final overrides = ref.watch(optimisticConsumptionProvider);
final effectiveIsConsumed = overrides[entry.id] ?? entry.isConsumed;
return AkeliMealCard(
  key: ValueKey(entry.id),
  title: entry.recipeTitle ?? 'Repas',
  mealType: entry.mealType,
  calories: entry.calories,
  imageUrl: entry.recipeThumbnail,
  isConsumed: effectiveIsConsumed,
  onConsumedToggle: () async {
    HapticFeedback.mediumImpact();
    _logger.userAction('Meal consumed toggled',
        screen: 'HomePage',
        metadata: {
          'mealId': entry.id,
          'wasConsumed': effectiveIsConsumed,
        });
    try {
      await ref
          .read(mealConsumptionProvider.notifier)
          .toggleConsumption(
            entry.id,
            isCurrentlyConsumed: effectiveIsConsumed,
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de mettre à jour le repas. Réessayez.'),
          ),
        );
      }
    }
  },
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/home/home_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/home_page.dart
git commit -m "feat(home): optimistic consumed toggle with overlay merge and error snackbar"
```

---

### Task 4: Meal planner page — overlay merge + error snackbar

**Files:**
- Modify: `lib/features/meal_planner/meal_planner_page.dart`

- [ ] **Step 1: Update `onConsumedToggle` in the `SliverChildBuilderDelegate`**

Locate this block in `lib/features/meal_planner/meal_planner_page.dart` (around line 133–138):

```dart
onConsumedToggle: (entryId) {
  appLogger.userAction('Meal consumed toggle', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
  final plan = ref.read(activeMealPlanProvider).valueOrNull;
  final isConsumed = plan?.entries.where((e) => e.id == entryId).firstOrNull?.isConsumed ?? false;
  ref.read(mealConsumptionProvider.notifier).toggleConsumption(entryId, isCurrentlyConsumed: isConsumed);
},
```

Replace with:

```dart
onConsumedToggle: (entryId) async {
  appLogger.userAction('Meal consumed toggle', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
  final plan = ref.read(activeMealPlanProvider).valueOrNull;
  final dbIsConsumed = plan?.entries.where((e) => e.id == entryId).firstOrNull?.isConsumed ?? false;
  final overrides = ref.read(optimisticConsumptionProvider);
  final effectiveIsConsumed = overrides[entryId] ?? dbIsConsumed;
  try {
    await ref.read(mealConsumptionProvider.notifier).toggleConsumption(
      entryId,
      isCurrentlyConsumed: effectiveIsConsumed,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de mettre à jour le repas. Réessayez.'),
        ),
      );
    }
  }
},
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/meal_planner/meal_planner_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/meal_planner/meal_planner_page.dart
git commit -m "feat(planner): optimistic consumed toggle with overlay merge and error snackbar"
```

---

### Task 5: Meal detail page — overlay merge

**Files:**
- Modify: `lib/features/meal_planner/meal_detail_page.dart`

**Background:** `meal_detail_page.dart` already has a `ref.listen(mealConsumptionProvider, ...)` error handler that shows a snackbar — no new try/catch needed. We only need to: (1) read the overlay so `isConsumed` renders optimistically, and (2) pass the effective value as `isCurrentlyConsumed` to the toggle call.

- [ ] **Step 1: Read the overlay in `build()` and update the `onConsume` callback**

In `lib/features/meal_planner/meal_detail_page.dart`, the `build()` method currently reads:

```dart
final planAsync = ref.watch(activeMealPlanProvider);
final consumeState = ref.watch(mealConsumptionProvider);
```

Add the overlay read immediately after:

```dart
final planAsync = ref.watch(activeMealPlanProvider);
final consumeState = ref.watch(mealConsumptionProvider);
final consumptionOverrides = ref.watch(optimisticConsumptionProvider);
```

Then find where `entry` is used for `onConsume` (around line 82–88):

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

Replace with:

```dart
onConsume: () {
  final effectiveIsConsumed = consumptionOverrides[entry.id] ?? entry.isConsumed;
  _logger.userAction('Mark consumed tapped | isConsumed: $effectiveIsConsumed',
      screen: 'MealDetailPage', metadata: {'mealId': entry.id});
  ref.read(mealConsumptionProvider.notifier).toggleConsumption(
    entry.id,
    isCurrentlyConsumed: effectiveIsConsumed,
  );
},
```

- [ ] **Step 2: Update the existing error listener message for consistency**

Find the `ref.listen` block (around line 39–58):

```dart
ref.listen(mealConsumptionProvider, (_, next) {
  if (next.hasError) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(next.error.toString()),
      backgroundColor: AkeliColors.error,
    ));
```

Replace only the `Text(next.error.toString())` line:

```dart
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: const Text('Impossible de mettre à jour le repas. Réessayez.'),
  backgroundColor: AkeliColors.error,
));
```

- [ ] **Step 3: Verify it compiles**

```bash
flutter analyze lib/features/meal_planner/meal_detail_page.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/meal_planner/meal_detail_page.dart
git commit -m "feat(meal-detail): optimistic consumed toggle with overlay merge"
```

---

### Task 6: Full test run and smoke check

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: all existing tests pass, plus the 7 new optimistic consumption tests.

- [ ] **Step 2: Run full analyzer**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 3: Manual smoke check**

Launch the app (`flutter run`), navigate to today's meals on the home screen, tap a meal's consumed toggle. Verify:
- The checkmark flips **immediately** on tap (no delay)
- After a moment, the card state confirms from the DB refetch (no visible change if successful)
- The nutrition summary does NOT update optimistically (only the checkmark)

- [ ] **Step 4: Final commit if anything was missed**

```bash
git add -A
git commit -m "chore: optimistic meal logging — cleanup"
```
