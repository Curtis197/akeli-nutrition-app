# Personal Snack — AI-Assisted Creation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users add a personal (custom, AI-analyzed) snack directly from the snack picker sheet instead of only picking from existing recipes.

**Architecture:** `PersonalMealBottomSheet` gains a create mode (nullable `entryId`) that pops with a new `PersonalMealCreatedResult` data class instead of calling the save RPC. `SnackPickerSheet` adds a sealed `SnackSelection` return type, a "Collation personnelle" button that opens the sheet in create mode, and converts the result into `CustomSnackSelection` before popping. `SnackEntryNotifier` gets an `addCustomSnack()` method for the direct-insert path. `meal_planner_page.dart`'s `_addSnack()` switches on the sealed type to choose which notifier method to call.

**Tech Stack:** Flutter 3, Riverpod AsyncNotifier, Supabase Dart client, Dart sealed classes (exhaustive switch)

---

## File Map

| File | Change |
|------|--------|
| `lib/features/meal_planner/personal_meal_bottom_sheet.dart` | Add `PersonalMealCreatedResult`; make `entryId` nullable; fork `_save()`; update title + button label |
| `lib/features/meal_planner/widgets/snack_picker_sheet.dart` | Add sealed `SnackSelection` classes; change return type; add "Collation personnelle" button + `_openPersonalSnack()`; update recipe tile pop |
| `lib/providers/meal_plan_provider.dart` | Add `addCustomSnack()` to `SnackEntryNotifier` |
| `lib/features/meal_planner/meal_planner_page.dart` | Update `_addSnack()` to `showModalBottomSheet<SnackSelection>` + exhaustive switch |

> **Why `PersonalMealCreatedResult` instead of `CustomSnackSelection` in `personal_meal_bottom_sheet.dart`?**
> `snack_picker_sheet.dart` imports `personal_meal_bottom_sheet.dart` (to show it). If `personal_meal_bottom_sheet.dart` also imported `snack_picker_sheet.dart` (to use `CustomSnackSelection`), that would be a circular import. `PersonalMealCreatedResult` is defined in `personal_meal_bottom_sheet.dart`; `SnackPickerSheet` reads it and wraps it into `CustomSnackSelection` before popping.

---

### Task 1: `PersonalMealBottomSheet` — create mode

**Files:**
- Modify: `lib/features/meal_planner/personal_meal_bottom_sheet.dart:9-16` (class declaration + `_save()`)

- [ ] **Step 1: Add `PersonalMealCreatedResult` data class above the widget class**

  Open `lib/features/meal_planner/personal_meal_bottom_sheet.dart`.

  Add this class directly above the `class PersonalMealBottomSheet` declaration (after the imports, before line 9):

  ```dart
  class PersonalMealCreatedResult {
    final String name;
    final double calories;
    final double proteinG;
    final double carbsG;
    final double fatG;
    const PersonalMealCreatedResult({
      required this.name,
      required this.calories,
      required this.proteinG,
      required this.carbsG,
      required this.fatG,
    });
  }
  ```

- [ ] **Step 2: Make `entryId` nullable in the widget declaration**

  Replace lines 9–16:
  ```dart
  class PersonalMealBottomSheet extends ConsumerStatefulWidget {
    final String entryId;
  
    const PersonalMealBottomSheet({super.key, required this.entryId});
  ```
  With:
  ```dart
  class PersonalMealBottomSheet extends ConsumerStatefulWidget {
    final String? entryId; // null = create mode
  
    const PersonalMealBottomSheet({super.key, this.entryId});
  ```

- [ ] **Step 3: Fork `_save()` for create vs swap mode**

  Replace the entire `_save()` method (currently lines 74–96):
  ```dart
  Future<void> _save() async {
    _logger.userAction('Confirmer ce repas tapped', screen: 'PersonalMealBottomSheet', metadata: {'entryId': widget.entryId});
    if (widget.entryId == null) {
      // create mode — return data to caller, no DB write
      Navigator.of(context).pop(PersonalMealCreatedResult(
        name: _nameController.text.trim(),
        calories: double.tryParse(_calController.text.trim()) ?? 0,
        proteinG: double.tryParse(_protController.text.trim()) ?? 0,
        carbsG: double.tryParse(_carbsController.text.trim()) ?? 0,
        fatG: double.tryParse(_fatController.text.trim()) ?? 0,
      ));
      return;
    }
    // swap mode — save via RPC then dismiss
    setState(() => _isSaving = true);
    try {
      await ref.read(personalMealSwapProvider.notifier).save(
        entryId: widget.entryId!,
        mealName: _nameController.text.trim(),
        calories: double.tryParse(_calController.text.trim()) ?? 0,
        proteinG: double.tryParse(_protController.text.trim()) ?? 0,
        carbsG: double.tryParse(_carbsController.text.trim()) ?? 0,
        fatG: double.tryParse(_fatController.text.trim()) ?? 0,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  ```

- [ ] **Step 4: Update title and confirm button label to be mode-dependent**

  In the `build()` method, find:
  ```dart
  Text(
    'Saisir un repas personnel',
    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  ),
  ```
  Replace with:
  ```dart
  Text(
    widget.entryId == null ? 'Ajouter une collation personnelle' : 'Saisir un repas personnel',
    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  ),
  ```

  Find the confirm button label:
  ```dart
  : const Text('Confirmer ce repas'),
  ```
  Replace with:
  ```dart
  : Text(widget.entryId == null ? 'Ajouter la collation' : 'Confirmer ce repas'),
  ```

  Also update the logger line in `build()`:
  ```dart
  _logger.provider('PersonalMealBottomSheet build() | entryId: ${widget.entryId}');
  ```
  This already handles null correctly — leave it as-is.

- [ ] **Step 5: Verify no analyzer errors**

  ```powershell
  flutter analyze lib/features/meal_planner/personal_meal_bottom_sheet.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 6: Commit**

  ```powershell
  git add lib/features/meal_planner/personal_meal_bottom_sheet.dart
  git commit -m "feat: PersonalMealBottomSheet create mode (nullable entryId)"
  ```

---

### Task 2: `SnackPickerSheet` — sealed return type + "Collation personnelle" button

**Files:**
- Modify: `lib/features/meal_planner/widgets/snack_picker_sheet.dart`

- [ ] **Step 1: Add sealed `SnackSelection` classes at top of file (after imports)**

  After the last `import` line and before `class SnackPickerSheet`, insert:
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

- [ ] **Step 2: Add import for `PersonalMealBottomSheet`**

  Add this import with the other imports at the top of the file:
  ```dart
  import '../personal_meal_bottom_sheet.dart';
  ```

- [ ] **Step 3: Update the recipe tile `pop` call to return `RecipeSnackSelection`**

  In `_SnackPickerSheetState.build()`, inside the `_RecipePickerTile` `onTap` callback, find:
  ```dart
  Navigator.of(context).pop(recipe.id);
  ```
  Replace with:
  ```dart
  Navigator.of(context).pop(RecipeSnackSelection(recipe.id));
  ```

- [ ] **Step 4: Add `_openPersonalSnack()` method to `_SnackPickerSheetState`**

  Add this method after `dispose()` and before `build()`:
  ```dart
  Future<void> _openPersonalSnack() async {
    _logger.userAction('Collation personnelle tapped', screen: 'SnackPickerSheet');
    final result = await showModalBottomSheet<PersonalMealCreatedResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PersonalMealBottomSheet(entryId: null),
    );
    if (result != null && mounted) {
      _logger.userAction('Personal snack created', screen: 'SnackPickerSheet',
          metadata: {'name': result.name});
      Navigator.of(context).pop(CustomSnackSelection(
        name: result.name,
        calories: result.calories,
        proteinG: result.proteinG,
        carbsG: result.carbsG,
        fatG: result.fatG,
      ));
    }
  }
  ```

- [ ] **Step 5: Add the "Collation personnelle" button between the search bar and the recipe list**

  In `build()`, find:
  ```dart
              const SizedBox(height: 12),
              Expanded(
  ```
  Replace with:
  ```dart
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _openPersonalSnack,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Collation personnelle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AkeliColors.primary,
                    side: BorderSide(color: AkeliColors.primary.withValues(alpha: 0.5)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.md)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
  ```

- [ ] **Step 6: Verify no analyzer errors**

  ```powershell
  flutter analyze lib/features/meal_planner/widgets/snack_picker_sheet.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 7: Commit**

  ```powershell
  git add lib/features/meal_planner/widgets/snack_picker_sheet.dart
  git commit -m "feat: SnackPickerSheet sealed SnackSelection + Collation personnelle button"
  ```

---

### Task 3: `addCustomSnack()` in `SnackEntryNotifier`

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart:844` (end of `SnackEntryNotifier`, before `}`  )

- [ ] **Step 1: Add `addCustomSnack()` after `addSnack()` and before the closing `}` of `SnackEntryNotifier`**

  Find the closing `}` of `SnackEntryNotifier` (currently right before `final snackEntryProvider =`). Insert this method before it:

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
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      _logger.userAction('Add custom snack entry',
          metadata: {'mealPlanId': mealPlanId, 'name': name});
      _logger.provider('SnackEntryNotifier → loading (addCustomSnack)');

      final client = ref.read(supabaseClientProvider);
      final dateStr =
          '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';

      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        try {
          _logger.db('BEFORE | table: meal_plan_entry | op: INSERT | is_custom_meal: true | date: $dateStr');
          await client.from('meal_plan_entry').insert({
            'meal_plan_id': mealPlanId,
            'meal_type': 'snack',
            'scheduled_date': dateStr,
            'is_custom_meal': true,
            'custom_meal_name': name,
            'custom_calories': calories,
            'custom_protein_g': proteinG,
            'custom_carbs_g': carbsG,
            'custom_fat_g': fatG,
            'servings': 1.0,
            'is_consumed': false,
          });
          _logger.db('AFTER | table: meal_plan_entry | op: INSERT | custom snack success');
          _logger.provider('SnackEntryNotifier → data (addCustomSnack success)');
        } on PostgrestException catch (e, st) {
          if (e.code == '42501') {
            _logger.rls('Permission denied | table: meal_plan_entry | INSERT | userId: ${user.id}',
                error: e, stackTrace: st);
          } else {
            _logger.db('ERROR | table: meal_plan_entry | INSERT custom snack | code: ${e.code}',
                error: e, stackTrace: st);
          }
          _logger.provider('SnackEntryNotifier → error | ${e.message}');
          rethrow;
        } catch (e, st) {
          _logger.db('ERROR | meal_plan_entry INSERT custom snack | unexpected: $e',
              error: e, stackTrace: st);
          _logger.provider('SnackEntryNotifier → error | $e');
          rethrow;
        }
      });

      if (state is AsyncData) {
        _logger.provider('SnackEntryNotifier → invalidating activeMealPlanProvider');
        ref.invalidate(activeMealPlanProvider);
      }
    }
  ```

- [ ] **Step 2: Verify no analyzer errors**

  ```powershell
  flutter analyze lib/providers/meal_plan_provider.dart
  ```
  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```powershell
  git add lib/providers/meal_plan_provider.dart
  git commit -m "feat: SnackEntryNotifier.addCustomSnack() for is_custom_meal entries"
  ```

---

### Task 4: `_addSnack()` — handle both `SnackSelection` types

**Files:**
- Modify: `lib/features/meal_planner/meal_planner_page.dart:177-211`

- [ ] **Step 1: Replace `_addSnack()` with the updated version**

  Replace the entire `_addSnack()` method (lines 177–211):

  ```dart
  Future<void> _addSnack(BuildContext context, WidgetRef ref, String mealPlanId, DateTime date) async {
    appLogger.userAction('Add snack tapped', screen: 'MealPlannerPage',
        metadata: {'date': date.toIso8601String()});

    final selection = await showModalBottomSheet<SnackSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SnackPickerSheet(),
    );
    if (selection == null || !context.mounted) return;

    try {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collation ajoutée !'),
            backgroundColor: AkeliColors.primary,
          ),
        );
      }
    } catch (e) {
      appLogger.edge('add-snack', 'ERROR | $e', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AkeliColors.error,
          ),
        );
      }
    }
  }
  ```

- [ ] **Step 2: Verify the whole project analyzes cleanly**

  ```powershell
  flutter analyze
  ```
  Expected: `No issues found!`

  If you see `The sealed class 'SnackSelection' does not cover all cases`, that means the switch is missing a case — add the missing subclass.
  If you see `The getter 'recipeId' isn't defined`, ensure you are using Dart 3 pattern matching syntax (`:final recipeId` inside `case RecipeSnackSelection(...)`).

- [ ] **Step 3: Commit**

  ```powershell
  git add lib/features/meal_planner/meal_planner_page.dart
  git commit -m "feat: _addSnack handles SnackSelection union (recipe + custom)"
  ```

---

### Task 5: Manual smoke test

No automated test runner covers full Riverpod+Supabase widget flows in this codebase. Validate manually:

- [ ] **Step 1: Launch the app on a device or emulator**

  ```powershell
  flutter run
  ```

- [ ] **Step 2: Happy path — recipe snack (existing behaviour must not regress)**

  1. Navigate to Meal Planner (Repas tab)
  2. Tap "Ajouter une collation" on any day row
  3. "Choisir une collation" sheet opens — search bar visible, recipe list visible
  4. "Collation personnelle" button is visible above the recipe list
  5. Tap any recipe tile → sheet dismisses → "Collation ajoutée !" snackbar appears → snack entry appears in the day

- [ ] **Step 3: Happy path — personal snack via description**

  1. Tap "Ajouter une collation"
  2. Tap "Collation personnelle" button
  3. "Ajouter une collation personnelle" sheet opens (title must be this, NOT "Saisir un repas personnel")
  4. Description tab is active; type "Banane et beurre de cacahuète"
  5. Tap "Analyser avec l'IA" → spinner → analysis result appears with name + macros + confidence chip
  6. Confirm button label reads "Ajouter la collation"
  7. Tap "Ajouter la collation"
  8. PersonalMealBottomSheet dismisses → SnackPickerSheet dismisses → "Collation ajoutée !" snackbar → custom snack appears in the day

- [ ] **Step 4: Happy path — personal snack via photo**

  Repeat Step 3 but on the Photo tab: pick from gallery, tap Analyser, confirm.

- [ ] **Step 5: Dismiss path**

  1. Open snack picker → tap "Collation personnelle"
  2. PersonalMealBottomSheet opens
  3. Drag to dismiss WITHOUT tapping confirm
  4. SnackPickerSheet remains open (it must not dismiss)
  5. Tap close icon on SnackPickerSheet → both sheets dismiss

- [ ] **Step 6: Existing swap mode is unaffected**

  1. Navigate to a meal detail page via a meal plan entry
  2. Open the personal meal swap feature (existing path via `PersonalMealBottomSheet(entryId: '<someId>')`)
  3. Confirm that the title reads "Saisir un repas personnel" and button reads "Confirmer ce repas"
  4. Confirm works (calls RPC, dismisses, updates entry)

- [ ] **Step 7: Commit if any last-minute fixes were needed**

  ```powershell
  git add -p
  git commit -m "fix: <describe any manual-test fixes>"
  ```
