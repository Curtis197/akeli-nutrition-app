# Personal Snack — AI-Assisted Creation

**Date:** 2026-06-12  
**Status:** Approved

## Problem

The "Add a snack" flow in the meal planner only lets users pick a snack from existing recipes. Users who want to log a personal/home-made snack have no path to do so from the snack picker.

## Solution

Extend `PersonalMealBottomSheet` with a **create mode** (no `entryId`) so it can be launched from the snack picker. Add a "Collation personnelle" button to `SnackPickerSheet` that opens this mode. The sheet collects description or photo, calls the existing `analyze-meal-photo` edge function, lets the user review/edit macros, then returns the result so the caller can create a new custom `meal_plan_entry`.

## Architecture

Four files changed, no new files created.

### 1. `PersonalMealBottomSheet` — create mode

**File:** `lib/features/meal_planner/personal_meal_bottom_sheet.dart`

`entryId` becomes nullable:

```dart
class PersonalMealBottomSheet extends ConsumerStatefulWidget {
  final String? entryId; // null = create mode
  const PersonalMealBottomSheet({super.key, this.entryId});
}
```

All UI up to the confirm button is identical between modes (Description/Photo tabs, AI analysis, editable result fields, confidence chip). The fork is only on confirm:

| Mode | `entryId` | Confirm action |
|------|-----------|----------------|
| swap | non-null | calls `save()` RPC → `Navigator.pop()` with no value |
| create | null | `Navigator.pop(context, CustomSnackSelection(...))` |

Visual differences in create mode:
- Title: "Ajouter une collation personnelle"
- Confirm button label: "Ajouter la collation"

No logic changes to `analyze()`. `save()` is only called in swap mode.

### 2. `SnackPickerSheet` — return type + button

**File:** `lib/features/meal_planner/widgets/snack_picker_sheet.dart`

Sealed `SnackSelection` class defined at top of file (not in a separate model file — it is the sheet's return contract):

```dart
sealed class SnackSelection {}

class RecipeSnackSelection extends SnackSelection {
  final String recipeId;
  RecipeSnackSelection(this.recipeId);
}

class CustomSnackSelection extends SnackSelection {
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  CustomSnackSelection({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}
```

Sheet return type changes: `showModalBottomSheet<SnackSelection>` (was `<String>`).

A **"Collation personnelle"** button is added below the search bar, above the recipe list. It is a full-width `OutlinedButton.icon` with `Icons.edit_note`. When tapped:

1. Opens `PersonalMealBottomSheet(entryId: null)` via `showModalBottomSheet`
2. If the result is a `CustomSnackSelection`, the picker pops with it immediately
3. If the result is null (user dismissed), the picker stays open

Recipe tile taps pop with `RecipeSnackSelection(recipeId: recipe.id)` — same behaviour as current, just wrapped in the new type.

### 3. `SnackEntryNotifier.addCustomSnack()` — new method

**File:** `lib/providers/meal_plan_provider.dart`

New method on the existing `SnackEntryNotifier`:

```dart
Future<void> addCustomSnack({
  required String mealPlanId,
  required DateTime scheduledDate,
  required String name,
  required double calories,
  required double proteinG,
  required double carbsG,
  required double fatG,
}) async {
  // Direct INSERT into meal_plan_entry with is_custom_meal: true
  // No meal_plan_entry_component row — custom snack has no recipe to link
  await supabase.from('meal_plan_entry').insert({
    'meal_plan_id': mealPlanId,
    'meal_type': 'snack',
    'scheduled_date': '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}',
    'is_custom_meal': true,
    'custom_meal_name': name,
    'custom_calories': calories,
    'custom_protein_g': proteinG,
    'custom_carbs_g': carbsG,
    'custom_fat_g': fatG,
    'servings': 1.0,
    'is_consumed': false,
  });
  ref.invalidate(activeMealPlanProvider);
}
```

### 4. `_addSnack()` — handle both selection types

**File:** `lib/features/meal_planner/meal_planner_page.dart`

```dart
final selection = await showModalBottomSheet<SnackSelection>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => const SnackPickerSheet(),
);
if (selection == null || !context.mounted) return;

switch (selection) {
  case RecipeSnackSelection(:final recipeId):
    await ref.read(snackEntryProvider.notifier).addSnack(
      mealPlanId: mealPlanId,
      recipeId: recipeId,
      scheduledDate: date,
    );
  case CustomSnackSelection(:final name, :final calories,
      :final proteinG, :final carbsG, :final fatG):
    await ref.read(snackEntryProvider.notifier).addCustomSnack(
      mealPlanId: mealPlanId,
      scheduledDate: date,
      name: name,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
}
// Same success/error snackbars as today for both paths
```

## Data Flow

```
User taps "Ajouter une collation"
  → SnackPickerSheet opens
    → User taps "Collation personnelle"
      → PersonalMealBottomSheet(entryId: null) opens
        → User enters description or photo
        → analyze-meal-photo edge function called
        → AI returns name + macros + confidence
        → User reviews/edits fields
        → User taps "Ajouter la collation"
        → Sheet pops with CustomSnackSelection
      → SnackPickerSheet receives result → pops with CustomSnackSelection
    → meal_planner_page receives CustomSnackSelection
    → snackEntryProvider.addCustomSnack() inserts meal_plan_entry (is_custom_meal: true)
    → activeMealPlanProvider invalidated → UI refreshes
```

## Constraints

- No new DB migrations needed — `is_custom_meal`, `custom_*` columns already exist
- No new edge functions — `analyze-meal-photo` is reused as-is
- No new provider — `personalMealSwapProvider` is reused; `analyze()` does not use `entryId`
- Swap mode behaviour is completely unchanged — existing `entryId` path untouched
- All logging follows the project standard (CLAUDE.md)
