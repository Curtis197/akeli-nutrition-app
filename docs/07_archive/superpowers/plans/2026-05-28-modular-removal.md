# Modular Removal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all multi-component (modular) meal rendering from the UI so every entry displays as a single complete recipe.

**Architecture:** Surgical UI-only cleanup — no DB migrations, no RPC changes. Four files touched. The `meal_plan_entry_component` table and `MealPlanEntryComponent` Dart model are kept; only the UI code that handles multiple components is removed.

**Tech Stack:** Flutter/Dart, Riverpod

---

## File Map

| File | Change |
|------|--------|
| `lib/shared/models/meal_plan.dart` | Remove `isModular` getter (line 141) |
| `lib/features/meal_planner/meal_detail_page.dart` | Remove `_ComponentRow` widget and the "Ingrédients/Components" section; remove `_ComponentRow` class |
| `lib/features/meal_planner/meal_planner_page.dart` | Remove snack addition stub (lines 296–333) |
| `lib/providers/meal_plan_provider.dart` | No `isModular` usage found — verify and skip if clean |

---

### Task 1: Remove `isModular` getter from model

**Files:**
- Modify: `lib/shared/models/meal_plan.dart:141`

- [ ] **Step 1: Remove the getter**

In `lib/shared/models/meal_plan.dart`, delete line 141:

```dart
// DELETE this line:
bool get isModular => components.length > 1;
```

The file at that location looks like:
```dart
  // Convenience accessor — recipe ID of the base component. Null for custom meals.
  String? get recipeId => isCustomMeal ? null : _base?.recipeId;

  bool get isModular => components.length > 1;   // ← DELETE THIS LINE

  String get mealTypeLabel {
```

After removal:
```dart
  // Convenience accessor — recipe ID of the base component. Null for custom meals.
  String? get recipeId => isCustomMeal ? null : _base?.recipeId;

  String get mealTypeLabel {
```

- [ ] **Step 2: Verify no references remain**

Run:
```
grep -rn "isModular" lib/
```
Expected: no output (zero matches).

- [ ] **Step 3: Commit**

```bash
git add lib/shared/models/meal_plan.dart
git commit -m "refactor: remove isModular getter from MealPlanEntry"
```

---

### Task 2: Remove component rendering from MealDetailPage

**Files:**
- Modify: `lib/features/meal_planner/meal_detail_page.dart`

Context: The "Ingrédients / Components" section (lines 331–345) iterates `entry.components` and renders `_ComponentRow` for each. Since entries always have exactly one base component, and `_ComponentRow` shows recipe titles (not actual ingredients), this section is removed entirely. The ingredient list from `meal_ingredient` will be added in the generator stress test plan.

The `_ComponentRow` class (lines 486–537) is also removed as it is no longer used.

- [ ] **Step 1: Remove the "Ingrédients / Components" section**

In `lib/features/meal_planner/meal_detail_page.dart`, delete the block:

```dart
          // ── INGREDIENTS / COMPONENTS ──────────────────
          if (entry.components.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingrédients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...entry.components.map((c) => _ComponentRow(component: c)),
                ],
              ),
            ),
```

- [ ] **Step 2: Remove the `_ComponentRow` class**

Delete the entire `_ComponentRow` class at the bottom of the file (lines 486–537):

```dart
class _ComponentRow extends StatelessWidget {
  final MealPlanEntryComponent component;

  const _ComponentRow({required this.component});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AkeliColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  component.role == 'starch' ? Icons.grain : Icons.eco,
                  color: AkeliColors.outline,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                component.recipeTitle ?? component.role,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          if (component.isBatch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AkeliColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('BATCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AkeliColors.secondary)),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify the import of `MealPlanEntryComponent` is still needed**

`MealPlanEntryComponent` is still imported via `meal_plan.dart` and is used in `MealPlanEntry.components` type. The import stays. Verify:

```
grep -n "MealPlanEntryComponent" lib/features/meal_planner/meal_detail_page.dart
```
Expected: no direct references remain (the type is used indirectly via `MealPlanEntry`).

- [ ] **Step 4: Hot reload and verify meal detail renders correctly**

Run the app (`flutter run`), navigate to any meal plan entry detail. Verify:
- Recipe title, thumbnail, macros display correctly
- No "Ingrédients" section shown
- No crash

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/meal_detail_page.dart
git commit -m "refactor: remove modular component rendering from MealDetailPage"
```

---

### Task 3: Remove snack addition stub from MealPlannerPage

**Files:**
- Modify: `lib/features/meal_planner/meal_planner_page.dart:296-333`

Context: The snack stub is a UI card with an "Ajouter" button whose `onPressed` only logs a user action with no implementation. The entire card is dead UI.

- [ ] **Step 1: Locate and remove the snack stub widget method**

Search for the method containing the stub:
```
grep -n "Add snack\|_buildSnack\|Ajouter une collation\|Personnalisez votre plan" lib/features/meal_planner/meal_planner_page.dart
```

Remove the entire method/widget that contains this block (the card with `ElevatedButton` whose `onPressed` only calls `appLogger.userAction('Add snack tapped', ...)`):

```dart
            ElevatedButton(
              onPressed: () {
                appLogger.userAction('Add snack tapped', screen: 'MealPlannerPage');
                HapticFeedback.lightImpact();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AkeliColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AkeliRadius.pill),
                ),
              ),
              child: const Text(
                'Ajouter',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
```

Remove the entire parent container/card that wraps this button, including the "Personnalisez votre plan" text and any surrounding `Padding` or `Container`.

- [ ] **Step 2: Remove any call site that renders the snack stub**

Search for the call site in the `build` method:
```
grep -n "_buildSnack\|snackSection\|Collation" lib/features/meal_planner/meal_planner_page.dart
```

Remove the call and any associated `SizedBox` spacers.

- [ ] **Step 3: Hot reload and verify meal planner renders correctly**

Navigate to the meal planner page. Verify:
- No snack addition card shown
- No layout gaps or rendering issues
- Generate plan FAB still works

- [ ] **Step 4: Commit**

```bash
git add lib/features/meal_planner/meal_planner_page.dart
git commit -m "refactor: remove unimplemented snack addition stub from MealPlannerPage"
```

---

### Task 4: Final verification

- [ ] **Step 1: Full build check**

```bash
flutter analyze
```
Expected: no new errors or warnings related to removed code.

- [ ] **Step 2: Verify no dead references**

```bash
grep -rn "isModular\|_ComponentRow\|Add snack tapped" lib/
```
Expected: no output.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "refactor: modular removal complete — UI-only, no DB changes"
```
