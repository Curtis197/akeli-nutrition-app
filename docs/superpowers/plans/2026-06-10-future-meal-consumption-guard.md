# Future Meal Consumption Guard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hide the consumption toggle/checkbox on meal cards and meal detail when `scheduled_date` is in the future, preventing users from marking a meal as consumed before they have eaten it.

**Architecture:** A pure helper function `isFutureMeal(DateTime)` is extracted to `lib/core/date_utils.dart` for testability and shared between two call sites (`MealPlannerDayRow` and `MealDetailPage`). `AkeliMealCard` requires no date logic — it already uses a null `onConsumedToggle` as the "hidden" signal; a single `if (onConsumedToggle != null)` guard is added to the widget.

**Tech Stack:** Flutter, Dart, flutter_test

---

## Files

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `lib/core/date_utils.dart` | `isFutureMeal` pure helper |
| Create | `test/core/date_utils_test.dart` | Unit tests for `isFutureMeal` |
| Modify | `lib/shared/widgets/meal_card.dart` | Wrap toggle in `if (onConsumedToggle != null)` + add test key |
| Create | `test/shared/widgets/meal_card_consumed_guard_test.dart` | Widget tests for toggle visibility |
| Modify | `lib/features/meal_planner/widgets/meal_planner_day_row.dart` | Compute `isFutureMeal(date)`, pass null for future meals |
| Create | `test/features/meal_planner/meal_planner_day_row_guard_test.dart` | Widget test: no toggle for future date |
| Modify | `lib/features/meal_planner/meal_detail_page.dart` | Guard consume row with `if (!isFutureMeal(...))` + add test key |

---

## Task 1: `isFutureMeal` helper + unit tests

**Files:**
- Create: `lib/core/date_utils.dart`
- Create: `test/core/date_utils_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/date_utils_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/date_utils.dart';

void main() {
  group('isFutureMeal', () {
    test('returns true for tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(isFutureMeal(tomorrow), isTrue);
    });

    test('returns false for today', () {
      final today = DateTime.now();
      expect(isFutureMeal(today), isFalse);
    });

    test('returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(isFutureMeal(yesterday), isFalse);
    });

    test('returns false for today with a late time component', () {
      final todayLate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        23,
        59,
        59,
      );
      expect(isFutureMeal(todayLate), isFalse);
    });

    test('returns true for a date far in the future', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(isFutureMeal(future), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/core/date_utils_test.dart
```

Expected: compilation error — `date_utils.dart` does not exist yet.

- [ ] **Step 3: Implement `lib/core/date_utils.dart`**

```dart
/// Returns true when [scheduledDate] falls strictly after today's date.
/// Time-of-day is ignored — a meal scheduled for today is always actionable.
bool isFutureMeal(DateTime scheduledDate) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final mealDay = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
  return mealDay.isAfter(today);
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```
flutter test test/core/date_utils_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 5: Commit**

```
git add lib/core/date_utils.dart test/core/date_utils_test.dart
git commit -m "feat: add isFutureMeal helper with unit tests"
```

---

## Task 2: Guard toggle in `AkeliMealCard`

**Files:**
- Modify: `lib/shared/widgets/meal_card.dart:119-162`
- Create: `test/shared/widgets/meal_card_consumed_guard_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/shared/widgets/meal_card_consumed_guard_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/widgets/meal_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AkeliMealCard planner variant — consumed toggle visibility', () {
    testWidgets('toggle is visible when onConsumedToggle is provided', (tester) async {
      await tester.pumpWidget(_wrap(AkeliMealCard(
        title: 'Thiéboudiène',
        mealType: 'lunch',
        calories: 550,
        isPlanner: true,
        isConsumed: false,
        onConsumedToggle: () {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsOneWidget);
    });

    testWidgets('toggle is absent when onConsumedToggle is null', (tester) async {
      await tester.pumpWidget(_wrap(AkeliMealCard(
        title: 'Thiéboudiène',
        mealType: 'lunch',
        calories: 550,
        isPlanner: true,
        isConsumed: false,
        onConsumedToggle: null,
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsNothing);
    });

    testWidgets('toggle shows check icon when consumed', (tester) async {
      await tester.pumpWidget(_wrap(AkeliMealCard(
        title: 'Thiéboudiène',
        mealType: 'lunch',
        calories: 550,
        isPlanner: true,
        isConsumed: true,
        onConsumedToggle: () {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/shared/widgets/meal_card_consumed_guard_test.dart
```

Expected: `findsNothing` test fails because the toggle is always rendered.

- [ ] **Step 3: Modify `lib/shared/widgets/meal_card.dart`**

In `_buildPlannerCard`, find the "Consumption Toggle" block (lines ~128-142) inside the `Row` of the `Positioned` top badges. Replace:

```dart
// BEFORE
GestureDetector(
  onTap: onConsumedToggle,
  child: Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: isConsumed ? AkeliColors.success : Colors.white.withValues(alpha: 0.8),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: isConsumed
        ? const Icon(Icons.check, size: 20, color: Colors.white)
        : null,
  ),
),
```

With:

```dart
// AFTER
if (onConsumedToggle != null)
  GestureDetector(
    onTap: onConsumedToggle,
    child: Container(
      key: const Key('consumed-toggle'),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isConsumed ? AkeliColors.success : Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: isConsumed
          ? const Icon(Icons.check, size: 20, color: Colors.white)
          : null,
    ),
  ),
```

- [ ] **Step 4: Run tests to confirm they pass**

```
flutter test test/shared/widgets/meal_card_consumed_guard_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 5: Confirm no analysis errors**

```
flutter analyze lib/shared/widgets/meal_card.dart
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```
git add lib/shared/widgets/meal_card.dart test/shared/widgets/meal_card_consumed_guard_test.dart
git commit -m "feat: hide consumed toggle on AkeliMealCard when callback is null"
```

---

## Task 3: Apply guard in `MealPlannerDayRow`

**Files:**
- Modify: `lib/features/meal_planner/widgets/meal_planner_day_row.dart:1-106`
- Create: `test/features/meal_planner/meal_planner_day_row_guard_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/meal_planner/meal_planner_day_row_guard_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_day_row.dart';
import 'package:akeli/shared/models/meal_plan.dart';

MealPlanEntry _makeEntry(DateTime scheduledDate) => MealPlanEntry(
      id: 'e1',
      mealPlanId: 'p1',
      mealType: 'lunch',
      scheduledDate: scheduledDate,
      servings: 1.0,
      isConsumed: false,
      isRated: false,
      isCustomMeal: false,
      ingredients: const [],
      components: const [],
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MealPlannerDayRow — consumed toggle visibility', () {
    testWidgets('toggle is visible for today', (tester) async {
      final today = DateTime.now();
      await tester.pumpWidget(_wrap(MealPlannerDayRow(
        date: today,
        entries: [_makeEntry(today)],
        onConsumedToggle: (_) {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsOneWidget);
    });

    testWidgets('toggle is absent for tomorrow', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.pumpWidget(_wrap(MealPlannerDayRow(
        date: tomorrow,
        entries: [_makeEntry(tomorrow)],
        onConsumedToggle: (_) {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsNothing);
    });

    testWidgets('toggle is visible for yesterday', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(_wrap(MealPlannerDayRow(
        date: yesterday,
        entries: [_makeEntry(yesterday)],
        onConsumedToggle: (_) {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```
flutter test test/features/meal_planner/meal_planner_day_row_guard_test.dart
```

Expected: the "toggle is absent for tomorrow" test fails — the toggle is still shown.

- [ ] **Step 3: Modify `lib/features/meal_planner/widgets/meal_planner_day_row.dart`**

Add the import at the top of the file (after existing imports):

```dart
import '../../../core/date_utils.dart';
```

In the `build` method, before `ListView.builder`, compute the future guard. Then pass `null` for future rows. The full `itemBuilder` becomes:

```dart
itemBuilder: (context, index) {
  final entry = entries[index];
  final isFuture = isFutureMeal(date);
  return AkeliMealCard(
    title: entry.recipeTitle ?? '',
    mealType: entry.mealType,
    calories: entry.calories,
    duration: entry.totalTimeMin,
    imageUrl: entry.recipeThumbnail,
    isPlanner: true,
    isConsumed: entry.isConsumed,
    onTap: () {
      appLogger.userAction('Meal plan entry tapped',
          screen: 'MealPlannerDayRow',
          metadata: {'entryId': entry.id});
      onRecipeTap?.call(entry.id);
    },
    onConsumedToggle: isFuture
        ? null
        : () {
            appLogger.userAction('Meal card consumed toggle',
                screen: 'MealPlannerDayRow',
                metadata: {
                  'entryId': entry.id,
                  'wasConsumed': entry.isConsumed
                });
            onConsumedToggle?.call(entry.id);
          },
  );
},
```

- [ ] **Step 4: Run tests to confirm they pass**

```
flutter test test/features/meal_planner/meal_planner_day_row_guard_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 5: Confirm no analysis errors**

```
flutter analyze lib/features/meal_planner/widgets/meal_planner_day_row.dart
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```
git add lib/features/meal_planner/widgets/meal_planner_day_row.dart test/features/meal_planner/meal_planner_day_row_guard_test.dart
git commit -m "feat: hide consumed toggle on meal cards for future dates"
```

---

## Task 4: Guard consume row in `MealDetailPage`

**Files:**
- Modify: `lib/features/meal_planner/meal_detail_page.dart:259-307`

The `MealDetailPage` uses Riverpod providers, making a full widget test heavyweight. The `isFutureMeal` logic is already unit-tested in Task 1. This task adds the guard and is verified via `flutter analyze` + manual smoke test.

- [ ] **Step 1: Add import to `lib/features/meal_planner/meal_detail_page.dart`**

Add after existing imports at the top:

```dart
import 'package:akeli/core/date_utils.dart';
```

- [ ] **Step 2: Wrap the consume block in `_MealDetailBody.build`**

Find the `// Consumed check` comment (around line 259). The current code is:

```dart
// Consumed check
const SizedBox(height: 20),
GestureDetector(
  onTap: isConsumeLoading ? null : onConsume,
  child: Container(
    // ... rectangular consume row
  ),
),
```

Replace with:

```dart
// Consumed check — hidden for future meals
if (!isFutureMeal(entry.scheduledDate)) ...[
  const SizedBox(height: 20),
  GestureDetector(
    key: const Key('consume-row'),
    onTap: isConsumeLoading ? null : onConsume,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isConsumed
            ? AkeliColors.secondaryContainer
            : AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      child: Row(
        children: [
          isConsumeLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: entry.isConsumed ? AkeliColors.primary : Colors.transparent,
                    border: Border.all(
                      color: entry.isConsumed ? AkeliColors.primary : AkeliColors.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: entry.isConsumed
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
          const SizedBox(width: 12),
          Text(
            entry.isConsumed ? 'Repas consommé' : 'Marquer comme consommé',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: entry.isConsumed
                  ? AkeliColors.onSecondaryContainer
                  : AkeliColors.onSurface,
            ),
          ),
        ],
      ),
    ),
  ),
],
```

- [ ] **Step 3: Run analysis**

```
flutter analyze lib/features/meal_planner/meal_detail_page.dart
```

Expected: No issues found.

- [ ] **Step 4: Run full test suite**

```
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```
git add lib/features/meal_planner/meal_detail_page.dart
git commit -m "feat: hide consume row in meal detail for future meals"
```

---

## Smoke Test Checklist

After all tasks, verify manually in the app:

- [ ] Open meal planner → navigate to a future day → confirm no circular toggle on cards
- [ ] Open meal planner → navigate to today → confirm circular toggle is visible and tappable
- [ ] Open meal planner → navigate to a past day → confirm circular toggle is visible
- [ ] Tap a future meal card → open detail page → confirm "Marquer comme consommé" row is absent
- [ ] Tap a today/past meal card → open detail page → confirm consume row is present and functional
