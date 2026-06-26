# Future Meal Consumption Guard

**Date:** 2026-06-10  
**Status:** Approved

## Problem

Users can tap the consumption toggle on meal cards and the detail page for meals scheduled in the future, marking them as consumed before eating. This creates invalid data.

## Solution

Hide the consumption UI entirely when `scheduled_date > today` (date-only comparison). Past and today's meals are unaffected.

## Date Comparison

Use a date-only comparison so a meal scheduled for today is always actionable regardless of the current hour:

```dart
bool _isFutureMeal(DateTime scheduledDate) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final mealDate = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
  return mealDate.isAfter(todayDate);
}
```

This function is a top-level helper, defined once in each file that needs it.

## Changes

### 1. `lib/shared/widgets/meal_card.dart`

Wrap the circular toggle in `if (onConsumedToggle != null)`. No new parameters — null already conventionally means "unavailable" in Flutter. The meal type badge stays right-aligned; no layout shift.

```dart
if (onConsumedToggle != null)
  GestureDetector(
    onTap: onConsumedToggle,
    child: Container(/* circle toggle */),
  ),
```

### 2. `lib/features/meal_planner/widgets/meal_planner_day_row.dart`

Compute `isFuture` from the existing `date` prop before building each card:

```dart
final isFuture = _isFutureMeal(date);
// ...
onConsumedToggle: isFuture ? null : () {
  appLogger.userAction('Meal card consumed toggle', ...);
  onConsumedToggle?.call(entry.id);
},
```

### 3. `lib/features/meal_planner/meal_detail_page.dart`

Wrap the entire "Consumed check" block (SizedBox + GestureDetector) in a guard:

```dart
if (!_isFutureMeal(entry.scheduledDate)) ...[
  const SizedBox(height: 20),
  GestureDetector(/* consume row */),
],
```

## Scope

- 3 files modified
- ~10 lines changed
- No new parameters on public APIs
- No model, provider, or database changes
- No behaviour change for today's or past meals

## Out of Scope

- Home page meal cards (already no consume toggle passed)
- Time-of-day gating (e.g. hide until after breakfast hour)
- Disabling vs. hiding distinction (always hidden)
