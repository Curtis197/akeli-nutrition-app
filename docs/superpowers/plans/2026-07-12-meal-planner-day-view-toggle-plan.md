# Meal Planner — Day View Toggle — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Semaine/Jour toggle to `MealPlannerPage` that reveals a day-tab layout (day-chip selector + per-day calorie recap + that day's meals) as an alternative to the existing continuous week scroll — pure Flutter UI, no backend/data-model changes.

**Architecture:** Four new presentational widgets (`MealPlannerViewToggle`, `MealPlannerDaySelector`, `MealPlannerDayRecapCard`, `MealPlannerDayTabView`) composed under a new `PlannerViewMode` enum + `plannerViewModeProvider` (Riverpod `StateProvider.autoDispose`). `MealPlannerPage`'s body branches on that provider. Consumed-toggle and add-snack logic — currently inlined twice's worth of near-identical code once the day view exists — is extracted once into a shared `meal_planner_actions.dart` so both views call the exact same code path (avoids the two views silently diverging, e.g. on the calorie-consistency risk the design doc itself flags).

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), `intl` (`^0.20.2`, already a dependency), existing `akeli` package conventions (`AkeliColors`/`AkeliRadius` design tokens, `appLogger`, ARB-based l10n).

**Source spec:** `docs/superpowers/specs/2026-07-10-meal-planner-day-view-toggle-design.md`

## Global Constraints

- Every Dart file created or modified MUST have full structured logging per `CLAUDE.md` (import `package:akeli/core/logger.dart`; file-level `final _logger = appLogger;` constant, matching the existing convention in `lib/shared/widgets/meal_card.dart:14` — **not** a class-level field, this codebase uses a top-level file constant).
- Every user-visible string MUST go through `AppLocalizations` — add to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` before referencing a key in Dart. Run `flutter gen-l10n` after every ARB edit, before the next compile/test.
- Key naming: `<screen>_<key>` camelCase (e.g. `plannerViewToggleWeek`).
- No backend changes: no new tables, columns, RPCs, or edge functions. `MealPlan.entriesByDay` (`lib/shared/models/meal_plan.dart:49-63`) already provides everything this feature needs.
- Providers/notifiers never resolve l10n strings — widget layer only.
- `intl: ^0.20.2` is already in `pubspec.yaml` — no dependency changes.

## Design Decisions (deviations from the source spec, made explicit here)

1. **Calorie formula for the day recap.** The spec's §2 implementation note assumed the Home screen's "consumed/target kcal" formula could be reused directly. It cannot: Home's calorie ring (`lib/features/home/home_page.dart:296-324`) computes consumed from `todayNutritionProvider` — a nutrition-log aggregate scoped to *today only* — which has no way to answer "consumed kcal for an arbitrary selected day." Since `Jour` view lets the user pick any day in the plan, this plan instead computes consumed kcal by summing `entry.calories` for entries where `overrides[entry.id] ?? entry.isConsumed` is true, over the selected day's `entriesByDay[date]` list — the same overlay-merge pattern `MealPlannerPage` already uses at `meal_planner_page.dart:181-182` for the toggle-effective state. Target kcal is `activeNutritionPlanProvider`'s `calorieGoal` (same source Home uses for target, matching Home's target side exactly).
2. **`AkeliMealCard` does not branch on `isCustomMeal`.** The spec's §9 edge case claims it does; it doesn't (`lib/shared/widgets/meal_card.dart` has no `isCustomMeal` parameter at all). The custom/computed branching already happens one layer up, in `MealPlanEntry.calories` (`lib/shared/models/meal_plan.dart:169-173`), before the resolved `double` ever reaches the card. Net effect is the same (no special-casing needed in the new widgets) — corrected here so the "why" is accurate.
3. **`AkeliMealCard` planner variant is a fixed 300×300 box** (`lib/shared/widgets/meal_card.dart:82-83`), not width-flexible. Rather than adding a new parameter/variant to a shared widget for this one caller (YAGNI), Task 7 stacks the existing fixed-size cards vertically, each centered in the available width. This reuses `AkeliMealCard` completely unmodified.
4. **Extracted shared actions.** The spec's minimal `MealPlannerDayTabView({ required MealPlan plan })` constructor implies the widget handles consumed-toggle and add-snack internally (mirroring what `MealPlannerPage` already does inline). Duplicating that logic verbatim in two places would risk exactly the kind of week/day divergence the spec itself warns about for calories — so both call sites (`MealPlannerPage` for week view, `MealPlannerDayTabView` for day view) call two new shared functions in `lib/features/meal_planner/meal_planner_actions.dart` (Task 3).
5. **`mealPlannerTitle` already exists** in both ARB files (`"Your Meals"` / `"Vos repas"`, `lib/l10n/app_en.arb:535-536`, `lib/l10n/app_fr.arb:186`) but is currently unreferenced in `lib/`. This plan starts using the existing key/copy rather than adding a new one.
6. **Empty-state edge case.** The spec's §9 says the toggle stays "visible/selectable" with no active plan, while §4.1 says `Jour` "is not selectable/rendered differently" in that case — these are reconcilable (toggle tappable, but renders the identical empty state either way), but making the toggle appear on the empty-state screen would require lifting the header out of `NestedScrollView.headerSliverBuilder` (which only builds when `plan != null`) into an always-visible scaffold region — a disproportionate structural change for a control that would be a no-op either way. Task 8 keeps `_buildEmptyState` exactly as it is today (no toggle shown when there's no active plan); functionally identical outcome, smaller diff.

---

### Task 1: `PlannerViewMode` enum + `plannerViewModeProvider`

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart:88-90` (insert new block between the end of `activeMealPlanProvider` and the `MealPlanGeneratorNotifier` banner comment)
- Test: `test/providers/planner_view_mode_provider_test.dart` (new)

**Interfaces:**
- Produces: `enum PlannerViewMode { week, day }`, `final plannerViewModeProvider = StateProvider.autoDispose<PlannerViewMode>(...)` — consumed by Tasks 4 (widget uses the enum type) and 8 (page wires it up).

- [ ] **Step 1: Write the failing test**

Create `test/providers/planner_view_mode_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/providers/meal_plan_provider.dart';

void main() {
  group('plannerViewModeProvider', () {
    test('defaults to PlannerViewMode.week', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(plannerViewModeProvider), PlannerViewMode.week);
    });

    test('can be set to PlannerViewMode.day', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(plannerViewModeProvider.notifier).state = PlannerViewMode.day;
      expect(container.read(plannerViewModeProvider), PlannerViewMode.day);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/planner_view_mode_provider_test.dart`
Expected: FAIL — `Undefined name 'PlannerViewMode'` / `Undefined name 'plannerViewModeProvider'` (compile error, since neither exists yet).

- [ ] **Step 3: Implement**

In `lib/providers/meal_plan_provider.dart`, insert immediately after line 88 (the closing `});` of `activeMealPlanProvider`) and before the `// --- Generate meal plan — Edge Function ---` banner comment (currently line 90):

```dart

// ---------------------------------------------------------------------------
// Planner view mode — Semaine (week) vs Jour (day) toggle on MealPlannerPage
// ---------------------------------------------------------------------------

enum PlannerViewMode { week, day }

final plannerViewModeProvider =
    StateProvider.autoDispose<PlannerViewMode>((ref) => PlannerViewMode.week);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/planner_view_mode_provider_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/providers/meal_plan_provider.dart test/providers/planner_view_mode_provider_test.dart
git commit -m "feat(meal-planner): add PlannerViewMode enum and plannerViewModeProvider"
```

---

### Task 2: New l10n keys (`plannerViewToggleWeek`, `plannerViewToggleDay`)

**Files:**
- Modify: `lib/l10n/app_en.arb:535-537`
- Modify: `lib/l10n/app_fr.arb:186-187`

**Interfaces:**
- Produces: `AppLocalizations.plannerViewToggleWeek`, `AppLocalizations.plannerViewToggleDay` getters (generated) — consumed by Task 4 (`MealPlannerViewToggle`).

- [ ] **Step 1: Add keys to `lib/l10n/app_en.arb`**

Current (lines 535-539):
```json
  "mealPlannerTitle": "Your Meals",
  "@mealPlannerTitle": {},

  "mealPlannerWeekTitle": "Your meals this week",
  "@mealPlannerWeekTitle": {},
```

Replace with:
```json
  "mealPlannerTitle": "Your Meals",
  "@mealPlannerTitle": {},

  "plannerViewToggleWeek": "Week",
  "@plannerViewToggleWeek": {},

  "plannerViewToggleDay": "Day",
  "@plannerViewToggleDay": {},

  "mealPlannerWeekTitle": "Your meals this week",
  "@mealPlannerWeekTitle": {},
```

- [ ] **Step 2: Add keys to `lib/l10n/app_fr.arb`**

Current (lines 186-188):
```json
  "mealPlannerTitle": "Vos repas",
  "mealPlannerWeekTitle": "Vos repas de la semaine",
  "mealPlannerDaysTitle": "Vos repas des prochains jours",
```

Replace with:
```json
  "mealPlannerTitle": "Vos repas",
  "plannerViewToggleWeek": "Semaine",
  "plannerViewToggleDay": "Jour",
  "mealPlannerWeekTitle": "Vos repas de la semaine",
  "mealPlannerDaysTitle": "Vos repas des prochains jours",
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: exits 0, regenerates `lib/l10n/app_localizations*.dart` including new `plannerViewToggleWeek`/`plannerViewToggleDay` getters.

- [ ] **Step 4: Verify the getters exist**

Run: `grep -n "plannerViewToggleWeek\|plannerViewToggleDay" lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart`
Expected: 2 matches per file (getter + implementation, or similar — non-empty output in both files).

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart
git commit -m "feat(meal-planner): add plannerViewToggleWeek/Day l10n keys"
```

---

### Task 3: Shared meal-planner actions (`toggleMealConsumption`, `addSnackToDay`)

**Files:**
- Create: `lib/features/meal_planner/meal_planner_actions.dart`

**Interfaces:**
- Consumes: `mealConsumptionProvider` (`AsyncNotifierProvider.autoDispose<MealConsumptionNotifier, String?>`, `lib/providers/meal_plan_provider.dart:435-437`), `MealConsumptionNotifier.toggleConsumption(String mealPlanEntryId, {required bool isCurrentlyConsumed})` (`lib/providers/meal_plan_provider.dart:369`), `snackEntryProvider` (`AsyncNotifierProvider<SnackEntryNotifier, void>`, `lib/providers/meal_plan_provider.dart:934-936`) with `addSnack({required mealPlanId, required recipeId, required scheduledDate, double weightG})` and `addCustomSnack({required mealPlanId, required scheduledDate, required name, required calories, required proteinG, required carbsG, required fatG})`, `SnackSelection`/`RecipeSnackSelection`/`CustomSnackSelection` (`lib/features/meal_planner/widgets/snack_picker_sheet.dart`).
- Produces: `Future<void> toggleMealConsumption(BuildContext context, WidgetRef ref, {required String entryId, required bool isCurrentlyConsumed, required String screen})` and `Future<void> addSnackToDay(BuildContext context, WidgetRef ref, String mealPlanId, DateTime date, {required String screen})` — consumed by Task 7 (`MealPlannerDayTabView`) and Task 8 (`MealPlannerPage` refactor).

This is pure extraction of existing logic (currently inlined at `meal_planner_page.dart:177-198` and `:235-288`) into a shared, parameterized location — no automated test is added for it in isolation (it needs a live `BuildContext`/`WidgetRef`/Supabase client, exactly like the inline code it replaces, which itself has never had a dedicated unit test in this repo). Correctness is verified by Task 8's full-suite run once both call sites use it.

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';
import 'widgets/snack_picker_sheet.dart';

final _logger = appLogger;

/// Toggles a meal plan entry's consumed state, with optimistic UI update
/// and error snackbar on failure. Shared by MealPlannerPage's week view
/// and MealPlannerDayTabView's day view so both stay behaviorally identical.
Future<void> toggleMealConsumption(
  BuildContext context,
  WidgetRef ref, {
  required String entryId,
  required bool isCurrentlyConsumed,
  required String screen,
}) async {
  try {
    await ref.read(mealConsumptionProvider.notifier).toggleConsumption(
          entryId,
          isCurrentlyConsumed: isCurrentlyConsumed,
        );
  } catch (e) {
    _logger.userAction('toggleConsumption ERROR | $e',
        screen: screen, metadata: {'error': e.toString()});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).mealPlannerConsumptionError),
        ),
      );
    }
  }
}

/// Opens the snack picker sheet and adds the selection to [mealPlanId] on
/// [date]. Shared by MealPlannerPage's week view and MealPlannerDayTabView's
/// day view so both stay behaviorally identical.
Future<void> addSnackToDay(
  BuildContext context,
  WidgetRef ref,
  String mealPlanId,
  DateTime date, {
  required String screen,
}) async {
  _logger.userAction('Add snack tapped', screen: screen,
      metadata: {'date': date.toIso8601String()});
  final l10n = AppLocalizations.of(context);

  final selection = await showModalBottomSheet<SnackSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SnackPickerSheet(),
  );
  if (selection == null || !context.mounted) return;

  try {
    switch (selection) {
      case RecipeSnackSelection(:final recipeId, :final weightG):
        await ref.read(snackEntryProvider.notifier).addSnack(
              mealPlanId: mealPlanId,
              recipeId: recipeId,
              scheduledDate: date,
              weightG: weightG,
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
        SnackBar(
          content: Text(l10n.feedAddedToMealPlan),
          backgroundColor: AkeliColors.primary,
        ),
      );
    }
  } catch (e) {
    _logger.edge('add-snack', 'ERROR | $e', error: e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mealPlannerError(e.toString())),
          backgroundColor: AkeliColors.error,
        ),
      );
    }
  }
}
```

- [ ] **Step 2: Verify it compiles in isolation**

Run: `flutter analyze lib/features/meal_planner/meal_planner_actions.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/meal_planner/meal_planner_actions.dart
git commit -m "refactor(meal-planner): extract shared consumed-toggle and add-snack actions"
```

---

### Task 4: `MealPlannerViewToggle` widget

**Files:**
- Create: `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart`
- Test: `test/features/meal_planner/meal_planner_view_toggle_test.dart` (new)

**Interfaces:**
- Consumes: `PlannerViewMode` (Task 1), `l10n.plannerViewToggleWeek`/`plannerViewToggleDay` (Task 2).
- Produces: `class MealPlannerViewToggle extends StatelessWidget` with `MealPlannerViewToggle({required PlannerViewMode value, required ValueChanged<PlannerViewMode> onChanged})` — consumed by Task 8 (`MealPlannerPage` header).
- Widget keys for testing: `Key('planner-view-toggle-week')`, `Key('planner-view-toggle-day')`.

- [ ] **Step 1: Write the failing test**

Create `test/features/meal_planner/meal_planner_view_toggle_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_view_toggle.dart';
import 'package:akeli/providers/meal_plan_provider.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    );

void main() {
  group('MealPlannerViewToggle', () {
    testWidgets('tapping Jour calls onChanged with day', (tester) async {
      PlannerViewMode? changedTo;
      await tester.pumpWidget(_wrap(MealPlannerViewToggle(
        value: PlannerViewMode.week,
        onChanged: (mode) => changedTo = mode,
      )));

      await tester.tap(find.byKey(const Key('planner-view-toggle-day')));
      await tester.pump();

      expect(changedTo, PlannerViewMode.day);
    });

    testWidgets('tapping the already-active segment does not call onChanged', (tester) async {
      var callCount = 0;
      await tester.pumpWidget(_wrap(MealPlannerViewToggle(
        value: PlannerViewMode.week,
        onChanged: (_) => callCount++,
      )));

      await tester.tap(find.byKey(const Key('planner-view-toggle-week')));
      await tester.pump();

      expect(callCount, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/meal_planner/meal_planner_view_toggle_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:akeli/features/meal_planner/widgets/meal_planner_view_toggle.dart'`.

- [ ] **Step 3: Implement**

Create `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/meal_plan_provider.dart';

final _logger = appLogger;

class MealPlannerViewToggle extends StatelessWidget {
  final PlannerViewMode value;
  final ValueChanged<PlannerViewMode> onChanged;

  const MealPlannerViewToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _select(PlannerViewMode mode) {
    if (mode == value) return;
    HapticFeedback.selectionClick();
    _logger.userAction('Planner view toggle changed', screen: 'MealPlannerPage',
        metadata: {'mode': mode.name});
    onChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(l10n.plannerViewToggleWeek, PlannerViewMode.week,
              const Key('planner-view-toggle-week')),
          _segment(l10n.plannerViewToggleDay, PlannerViewMode.day,
              const Key('planner-view-toggle-day')),
        ],
      ),
    );
  }

  Widget _segment(String label, PlannerViewMode mode, Key key) {
    final isActive = value == mode;
    return GestureDetector(
      key: key,
      onTap: () => _select(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AkeliColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? AkeliColors.onPrimary : AkeliColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/meal_planner/meal_planner_view_toggle_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/widgets/meal_planner_view_toggle.dart test/features/meal_planner/meal_planner_view_toggle_test.dart
git commit -m "feat(meal-planner): add MealPlannerViewToggle widget"
```

---

### Task 5: `MealPlannerDaySelector` widget (+ `_DayChip`)

**Files:**
- Create: `lib/features/meal_planner/widgets/meal_planner_day_selector.dart`
- Test: `test/features/meal_planner/meal_planner_day_selector_test.dart` (new)

**Interfaces:**
- Produces: `class MealPlannerDaySelector extends StatelessWidget` with `MealPlannerDaySelector({required List<DateTime> days, required DateTime selected, required ValueChanged<DateTime> onSelect})` — consumed by Task 7 (`MealPlannerDayTabView`).
- Widget keys: `Key('day-chip-${date.toIso8601String()}')` per chip.

- [ ] **Step 1: Write the failing test**

Create `test/features/meal_planner/meal_planner_day_selector_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_day_selector.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    );

void main() {
  group('MealPlannerDaySelector', () {
    testWidgets('renders exactly one chip per day, not a fixed 7', (tester) async {
      final days = [
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 14),
        DateTime(2026, 7, 15),
      ];
      await tester.pumpWidget(_wrap(MealPlannerDaySelector(
        days: days,
        selected: days.first,
        onSelect: (_) {},
      )));

      expect(find.byKey(Key('day-chip-${days[0].toIso8601String()}')), findsOneWidget);
      expect(find.byKey(Key('day-chip-${days[1].toIso8601String()}')), findsOneWidget);
      expect(find.byKey(Key('day-chip-${days[2].toIso8601String()}')), findsOneWidget);
      expect(find.byKey(Key('day-chip-${DateTime(2026, 7, 16).toIso8601String()}')), findsNothing);
    });

    testWidgets('renders a single chip when only one day is present', (tester) async {
      final day = DateTime(2026, 7, 13);
      await tester.pumpWidget(_wrap(MealPlannerDaySelector(
        days: [day],
        selected: day,
        onSelect: (_) {},
      )));

      expect(find.byKey(Key('day-chip-${day.toIso8601String()}')), findsOneWidget);
    });

    testWidgets('tapping a chip calls onSelect with that date', (tester) async {
      final days = [DateTime(2026, 7, 13), DateTime(2026, 7, 14)];
      DateTime? selected;
      await tester.pumpWidget(_wrap(MealPlannerDaySelector(
        days: days,
        selected: days.first,
        onSelect: (date) => selected = date,
      )));

      await tester.tap(find.byKey(Key('day-chip-${days[1].toIso8601String()}')));
      await tester.pump();

      expect(selected, days[1]);
    });

    testWidgets('tapping the already-selected chip does not call onSelect', (tester) async {
      final days = [DateTime(2026, 7, 13), DateTime(2026, 7, 14)];
      var callCount = 0;
      await tester.pumpWidget(_wrap(MealPlannerDaySelector(
        days: days,
        selected: days.first,
        onSelect: (_) => callCount++,
      )));

      await tester.tap(find.byKey(Key('day-chip-${days[0].toIso8601String()}')));
      await tester.pump();

      expect(callCount, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/meal_planner/meal_planner_day_selector_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:akeli/features/meal_planner/widgets/meal_planner_day_selector.dart'`.

- [ ] **Step 3: Implement**

Create `lib/features/meal_planner/widgets/meal_planner_day_selector.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';

final _logger = appLogger;

class MealPlannerDaySelector extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const MealPlannerDaySelector({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final isActive = _isSameDay(date, selected);
          return _DayChip(
            date: date,
            label: DateFormat.E(locale).format(date),
            isActive: isActive,
            onTap: () {
              if (isActive) return;
              HapticFeedback.selectionClick();
              _logger.userAction('Planner day chip selected', screen: 'MealPlannerPage',
                  metadata: {'date': date.toIso8601String()});
              onSelect(date);
            },
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime date;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DayChip({
    required this.date,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('day-chip-${date.toIso8601String()}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AkeliColors.primary : AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
          border: Border.all(
            color: isActive ? AkeliColors.primary : AkeliColors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? AkeliColors.onPrimary : AkeliColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/meal_planner/meal_planner_day_selector_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/widgets/meal_planner_day_selector.dart test/features/meal_planner/meal_planner_day_selector_test.dart
git commit -m "feat(meal-planner): add MealPlannerDaySelector widget"
```

---

### Task 6: `MealPlannerDayRecapCard` widget

**Files:**
- Create: `lib/features/meal_planner/widgets/meal_planner_day_recap_card.dart`
- Test: `test/features/meal_planner/meal_planner_day_recap_card_test.dart` (new)

**Interfaces:**
- Produces: `class MealPlannerDayRecapCard extends StatelessWidget` with `MealPlannerDayRecapCard({required DateTime date, required double consumedKcal, required double targetKcal})` — consumed by Task 7 (`MealPlannerDayTabView`).
- Widget key: `Key('day-recap-progress')` on the `LinearProgressIndicator`.

- [ ] **Step 1: Write the failing test**

Create `test/features/meal_planner/meal_planner_day_recap_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_day_recap_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    );

void main() {
  group('MealPlannerDayRecapCard', () {
    testWidgets('shows consumed / target kcal text uncapped', (tester) async {
      await tester.pumpWidget(_wrap(MealPlannerDayRecapCard(
        date: DateTime(2026, 7, 13),
        consumedKcal: 1500,
        targetKcal: 1200,
      )));

      expect(find.text('1500 / 1200 kcal'), findsOneWidget);
    });

    testWidgets('progress bar clamps at 100% when consumed exceeds target', (tester) async {
      await tester.pumpWidget(_wrap(MealPlannerDayRecapCard(
        date: DateTime(2026, 7, 13),
        consumedKcal: 1500,
        targetKcal: 1200,
      )));

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('day-recap-progress')),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('progress bar reflects partial progress under target', (tester) async {
      await tester.pumpWidget(_wrap(MealPlannerDayRecapCard(
        date: DateTime(2026, 7, 13),
        consumedKcal: 600,
        targetKcal: 1200,
      )));

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('day-recap-progress')),
      );
      expect(indicator.value, 0.5);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/meal_planner/meal_planner_day_recap_card_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:akeli/features/meal_planner/widgets/meal_planner_day_recap_card.dart'`.

- [ ] **Step 3: Implement**

Create `lib/features/meal_planner/widgets/meal_planner_day_recap_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';

final _logger = appLogger;

class MealPlannerDayRecapCard extends StatelessWidget {
  final DateTime date;
  final double consumedKcal;
  final double targetKcal;

  const MealPlannerDayRecapCard({
    super.key,
    required this.date,
    required this.consumedKcal,
    required this.targetKcal,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat('EEEE d MMMM', locale).format(date);
    final rawProgress = targetKcal > 0 ? consumedKcal / targetKcal : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);

    _logger.provider('MealPlannerDayRecapCard build() | date: $formattedDate | '
        'consumed: ${consumedKcal.toInt()} | target: ${targetKcal.toInt()}');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AkeliRadius.card),
        border: Border.all(color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${consumedKcal.toInt()} / ${targetKcal.toInt()} kcal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AkeliColors.accentAmber,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AkeliRadius.sm),
            child: LinearProgressIndicator(
              key: const Key('day-recap-progress'),
              value: progress,
              minHeight: 8,
              backgroundColor: AkeliColors.surfaceContainerLowest,
              valueColor: const AlwaysStoppedAnimation(AkeliColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/meal_planner/meal_planner_day_recap_card_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/widgets/meal_planner_day_recap_card.dart test/features/meal_planner/meal_planner_day_recap_card_test.dart
git commit -m "feat(meal-planner): add MealPlannerDayRecapCard widget"
```

---

### Task 7: `MealPlannerDayTabView` widget

**Files:**
- Create: `lib/features/meal_planner/widgets/meal_planner_day_tab_view.dart`
- Test: `test/features/meal_planner/meal_planner_day_tab_view_test.dart` (new — matches the file the source spec's §10.1 names)

**Interfaces:**
- Consumes: `MealPlannerDaySelector` (Task 5), `MealPlannerDayRecapCard` (Task 6), `toggleMealConsumption`/`addSnackToDay` (Task 3), `optimisticConsumptionProvider` (`StateProvider<Map<String, bool>>`, `lib/providers/meal_plan_provider.dart:440-441`), `activeNutritionPlanProvider` (`FutureProvider<NutritionPlan?>`, `lib/providers/nutrition_plan_provider.dart:10`), `NutritionPlan.calorieGoal` (`int`, `lib/shared/models/nutrition_plan.dart:101`), `MealPlan.entriesByDay`, `MealPlanEntry.calories`/`isConsumed`/`scheduledDate`/`mealType` (`lib/shared/models/meal_plan.dart`), `isFutureMeal(DateTime)` (`lib/core/date_utils.dart`), `AkeliMealCard` (`lib/shared/widgets/meal_card.dart`).
- Produces: `class MealPlannerDayTabView extends ConsumerStatefulWidget` with `MealPlannerDayTabView({required MealPlan plan, Function(String entryId)? onRecipeTap})` — consumed by Task 8 (`MealPlannerPage`).
- Widget key: `Key('day-tab-add-snack')` on the add-snack button.

- [ ] **Step 1: Write the failing test**

Create `test/features/meal_planner/meal_planner_day_tab_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_day_tab_view.dart';
import 'package:akeli/features/meal_planner/widgets/snack_picker_sheet.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/shared/models/meal_plan.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

MealPlanEntry _entry({
  required String id,
  required DateTime date,
  bool isConsumed = false,
  double? caloriesComputed,
  String mealType = 'lunch',
}) =>
    MealPlanEntry(
      id: id,
      mealPlanId: 'plan-1',
      mealType: mealType,
      scheduledDate: date,
      servings: 1.0,
      isConsumed: isConsumed,
      isRated: false,
      isCustomMeal: false,
      caloriesComputed: caloriesComputed,
      ingredients: const [],
      components: const [],
    );

Widget _wrap(Widget child, {required List<Override> overrides}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  final day1 = DateTime(2026, 7, 13);
  final day2 = DateTime(2026, 7, 14);

  MealPlan plan() => MealPlan(
        id: 'plan-1',
        userId: 'u-1',
        startDate: day1,
        endDate: day2,
        isActive: true,
        entries: [
          _entry(id: 'e1', date: day1, isConsumed: true, caloriesComputed: 600),
          _entry(id: 'e2', date: day1, isConsumed: false, caloriesComputed: 700),
          _entry(id: 'e3', date: day2, isConsumed: false, caloriesComputed: 500),
        ],
      );

  List<Override> baseOverrides() => [
        activeNutritionPlanProvider.overrideWith((ref) async => NutritionPlan(
              userId: 'u-1',
              calorieGoal: 1200,
              proteinGoalG: 90,
              carbGoalG: 120,
              fatGoalG: 40,
            )),
      ];

  group('MealPlannerDayTabView', () {
    testWidgets('defaults to the first day and recaps only that day', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: baseOverrides(),
      ));
      await tester.pump();

      expect(find.byKey(Key('day-chip-${day1.toIso8601String()}')), findsOneWidget);
      expect(find.byKey(Key('day-chip-${day2.toIso8601String()}')), findsOneWidget);
      expect(find.text('600 / 1200 kcal'), findsOneWidget);
    });

    testWidgets('selecting a day chip updates recap to that day', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: baseOverrides(),
      ));
      await tester.pump();

      await tester.tap(find.byKey(Key('day-chip-${day2.toIso8601String()}')));
      await tester.pump();

      expect(find.text('0 / 1200 kcal'), findsOneWidget);
    });

    testWidgets('recap respects the optimisticConsumptionProvider overlay', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: [
          ...baseOverrides(),
          optimisticConsumptionProvider.overrideWith((ref) => {'e2': true}),
        ],
      ));
      await tester.pump();

      expect(find.text('1300 / 1200 kcal'), findsOneWidget);
    });

    testWidgets('progress bar clamps at 100% when consumed exceeds target', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: [
          ...baseOverrides(),
          optimisticConsumptionProvider.overrideWith((ref) => {'e2': true}),
        ],
      ));
      await tester.pump();

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('day-recap-progress')),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('add-snack button opens the snack picker sheet', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: baseOverrides(),
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('day-tab-add-snack')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackPickerSheet), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/meal_planner/meal_planner_day_tab_view_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:akeli/features/meal_planner/widgets/meal_planner_day_tab_view.dart'`.

- [ ] **Step 3: Implement**

Create `lib/features/meal_planner/widgets/meal_planner_day_tab_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/date_utils.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../providers/nutrition_plan_provider.dart';
import '../../../shared/models/meal_plan.dart';
import '../../../shared/widgets/meal_card.dart';
import '../meal_planner_actions.dart';
import 'meal_planner_day_recap_card.dart';
import 'meal_planner_day_selector.dart';

final _logger = appLogger;

class MealPlannerDayTabView extends ConsumerStatefulWidget {
  final MealPlan plan;
  final Function(String entryId)? onRecipeTap;

  const MealPlannerDayTabView({
    super.key,
    required this.plan,
    this.onRecipeTap,
  });

  @override
  ConsumerState<MealPlannerDayTabView> createState() => _MealPlannerDayTabViewState();
}

class _MealPlannerDayTabViewState extends ConsumerState<MealPlannerDayTabView> {
  DateTime? _selectedDate;

  List<DateTime> get _dayKeys => widget.plan.entriesByDay.keys.toList()..sort();

  @override
  Widget build(BuildContext context) {
    final dayKeys = _dayKeys;
    final selected = (_selectedDate != null && dayKeys.contains(_selectedDate))
        ? _selectedDate!
        : dayKeys.first;
    final entries = widget.plan.entriesByDay[selected] ?? [];
    final overrides = ref.watch(optimisticConsumptionProvider);
    final consumedKcal = entries.fold<double>(0.0, (sum, e) {
      final isConsumed = overrides[e.id] ?? e.isConsumed;
      return isConsumed ? sum + e.calories : sum;
    });
    final targetKcal =
        (ref.watch(activeNutritionPlanProvider).valueOrNull?.calorieGoal ?? 2000).toDouble();
    final locale = Localizations.localeOf(context).languageCode;

    _logger.provider('MealPlannerDayTabView build() | selected: ${selected.toIso8601String()} | '
        'entries: ${entries.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MealPlannerDaySelector(
          days: dayKeys,
          selected: selected,
          onSelect: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 16),
        MealPlannerDayRecapCard(
          date: selected,
          consumedKcal: consumedKcal,
          targetKcal: targetKcal,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              for (final entry in entries) ...[
                Center(
                  child: AkeliMealCard(
                    title: entry.localizedTitle(locale) ??
                        entry.displayLabel(AppLocalizations.of(context)),
                    mealType: entry.mealType,
                    calories: entry.calories,
                    duration: entry.totalTimeMin,
                    imageUrl: entry.recipeThumbnail,
                    isPlanner: true,
                    isConsumed: overrides[entry.id] ?? entry.isConsumed,
                    onTap: () {
                      _logger.userAction('Meal plan entry tapped', screen: 'MealPlannerDayTabView',
                          metadata: {'entryId': entry.id});
                      widget.onRecipeTap?.call(entry.id);
                    },
                    onConsumedToggle: isFutureMeal(entry.scheduledDate)
                        ? null
                        : () {
                            final effectiveIsConsumed = overrides[entry.id] ?? entry.isConsumed;
                            _logger.userAction('Meal card consumed toggle',
                                screen: 'MealPlannerDayTabView',
                                metadata: {'entryId': entry.id, 'wasConsumed': effectiveIsConsumed});
                            toggleMealConsumption(
                              context,
                              ref,
                              entryId: entry.id,
                              isCurrentlyConsumed: effectiveIsConsumed,
                              screen: 'MealPlannerDayTabView',
                            );
                          },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildAddSnackButton(context, selected, entries),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAddSnackButton(BuildContext context, DateTime date, List<MealPlanEntry> entries) {
    final l10n = AppLocalizations.of(context);
    final hasSnack = entries.any((e) => e.mealType == 'snack');
    return OutlinedButton.icon(
      key: const Key('day-tab-add-snack'),
      onPressed: () => addSnackToDay(context, ref, widget.plan.id, date,
          screen: 'MealPlannerDayTabView'),
      icon: const Icon(Icons.add, size: 16),
      label: Text(hasSnack ? l10n.mealPlannerAddAnotherSnack : l10n.mealPlannerAddSnack),
      style: OutlinedButton.styleFrom(
        foregroundColor: AkeliColors.primary,
        side: BorderSide(color: AkeliColors.primary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.md)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/meal_planner/meal_planner_day_tab_view_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/widgets/meal_planner_day_tab_view.dart test/features/meal_planner/meal_planner_day_tab_view_test.dart
git commit -m "feat(meal-planner): add MealPlannerDayTabView widget"
```

---

### Task 8: Wire into `MealPlannerPage`

**Files:**
- Modify: `lib/features/meal_planner/meal_planner_page.dart` (full `build()` method rewrite, `_addSnack` removed, imports updated)
- Modify: `lib/l10n/app_en.arb:538-542` (remove `mealPlannerWeekTitle`/`mealPlannerDaysTitle`)
- Modify: `lib/l10n/app_fr.arb:187-188` (remove `mealPlannerWeekTitle`/`mealPlannerDaysTitle`)

**Interfaces:**
- Consumes: everything from Tasks 1-7.

- [ ] **Step 1: Update imports in `meal_planner_page.dart`**

Current (lines 1-16):
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/providers/user_profile_provider.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';
import 'rating_bottom_sheet.dart';
import 'widgets/meal_planner_day_row.dart';
import 'widgets/snack_picker_sheet.dart';
```

Replace with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/providers/user_profile_provider.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';
import 'meal_planner_actions.dart';
import 'rating_bottom_sheet.dart';
import 'widgets/meal_planner_day_row.dart';
import 'widgets/meal_planner_day_tab_view.dart';
import 'widgets/meal_planner_view_toggle.dart';
```

(Note `widgets/snack_picker_sheet.dart` is removed — `SnackSelection`/`RecipeSnackSelection`/`CustomSnackSelection` are no longer referenced directly in this file now that `_addSnack` has moved into `meal_planner_actions.dart`.)

- [ ] **Step 2: Replace the `build()` method**

Current `build()` spans lines 21-233 (from `@override\n  Widget build(...)` through its closing `}`). Replace the entire method body with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    ref.listen(mealConsumptionProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: AkeliColors.error,
        ));
      } else if (next.valueOrNull != null) {
        final entryId = next.valueOrNull!;
        final plan = ref.read(activeMealPlanProvider).valueOrNull;
        final entry = plan?.entries.where((e) => e.id == entryId).firstOrNull;
        if (entry != null && !entry.isRated) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => RatingBottomSheet(mealPlanEntryId: entryId),
          );
        }
      }
    });

    final planAsync = ref.watch(activeMealPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.mealPlannerError(error.toString()), style: const TextStyle(color: AkeliColors.error))),
        data: (plan) {
          if (plan == null) {
            return _buildEmptyState(context, ref);
          }
          final viewMode = ref.watch(plannerViewModeProvider);
          final entriesByDay = plan.entriesByDay;
          final dayKeys = entriesByDay.keys.toList()..sort();

          appLogger.provider('MealPlannerPage build() | days: ${dayKeys.length} | viewMode: ${viewMode.name}');

          return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── HEADER ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.mealPlannerTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        tooltip: l10n.mealScheduleCustomizeButton,
                        color: AkeliColors.primary,
                        onPressed: () {
                          appLogger.userAction('Customize meal structure tapped', screen: 'MealPlannerPage');
                          _showCustomizeSheet(context, ref);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MealPlannerViewToggle(
                    value: viewMode,
                    onChanged: (mode) {
                      appLogger.provider('plannerViewModeProvider → ${mode.name}');
                      ref.read(plannerViewModeProvider.notifier).state = mode;
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── QUICK ACTIONS ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildNavigationCard(
                    context,
                    icon: Icons.restaurant_menu,
                    title: l10n.mealPlannerViewDietPlan,
                    onTap: () {
                      appLogger.userAction('Diet plan card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.dietPlan);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    context,
                    icon: Icons.shopping_basket,
                    title: l10n.mealPlannerViewShoppingList,
                    onTap: () {
                      appLogger.userAction('Shopping list card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.shoppingList);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    context,
                    icon: Icons.soup_kitchen_outlined,
                    title: l10n.mealPlannerViewBatchCooking,
                    onTap: () {
                      appLogger.userAction('Batch cooking card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.batchCooking);
                    },
                  ),
                ],
              ),
            ),
          ),

        ],
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              // ── HINT BANNER ─────────────────────────────────────────────
              Consumer(builder: (context, ref, _) {
                final profileAsync = ref.watch(userProfileProvider);
                final profile = profileAsync.valueOrNull;
                if (profile == null || profile.hasDismissedMealScheduleHint) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: MaterialBanner(
                    content: Text(l10n.mealScheduleHintBanner),
                    actions: [
                      TextButton(
                        onPressed: () {
                          appLogger.userAction('Meal schedule hint dismissed', screen: 'MealPlannerPage');
                          ref.read(dismissMealScheduleHintProvider(profile.id));
                        },
                        child: Text(l10n.mealScheduleHintDismiss),
                      ),
                    ],
                  ),
                );
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              if (viewMode == PlannerViewMode.day) ...[
                // ── DAY TAB VIEW ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: MealPlannerDayTabView(
                    plan: plan,
                    onRecipeTap: (entryId) {
                      appLogger.userAction('Meal plan entry tapped', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
                      context.push(AkeliRoutes.mealDetailPath(entryId));
                    },
                  ),
                ),
              ] else ...[
                // ── DAILY MEAL LIST (week view) ──────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = dayKeys[index];
                      final entries = entriesByDay[date]!;

                      return MealPlannerDayRow(
                        date: date,
                        entries: entries,
                        onRecipeTap: (entryId) {
                          appLogger.userAction('Meal plan entry tapped', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
                          context.push(AkeliRoutes.mealDetailPath(entryId));
                        },
                        onConsumedToggle: (entryId) async {
                          appLogger.userAction('Meal consumed toggle', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
                          final currentPlan = ref.read(activeMealPlanProvider).valueOrNull;
                          final dbIsConsumed = currentPlan?.entries.where((e) => e.id == entryId).firstOrNull?.isConsumed ?? false;
                          final overrides = ref.read(optimisticConsumptionProvider);
                          final effectiveIsConsumed = overrides[entryId] ?? dbIsConsumed;
                          await toggleMealConsumption(
                            context,
                            ref,
                            entryId: entryId,
                            isCurrentlyConsumed: effectiveIsConsumed,
                            screen: 'MealPlannerPage',
                          );
                        },
                        onAddSnack: () =>
                            addSnackToDay(context, ref, plan.id, date, screen: 'MealPlannerPage'),
                      );
                    },
                    childCount: dayKeys.length,
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      appLogger.userAction('Generate plan button tapped', screen: 'MealPlannerPage');
                      _generatePlan(context, ref);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.mealPlannerGenerate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AkeliColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AkeliRadius.lg)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
          );
        },
      ),
    );
  }
```

- [ ] **Step 3: Delete the now-unused `_addSnack` method**

Remove this entire method (was lines 235-288, now directly after the `build()` closing brace):

```dart
  Future<void> _addSnack(BuildContext context, WidgetRef ref, String mealPlanId, DateTime date) async {
    appLogger.userAction('Add snack tapped', screen: 'MealPlannerPage',
        metadata: {'date': date.toIso8601String()});
    final l10n = AppLocalizations.of(context);

    final selection = await showModalBottomSheet<SnackSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SnackPickerSheet(),
    );
    if (selection == null || !context.mounted) return;

    try {
      switch (selection) {
        case RecipeSnackSelection(:final recipeId, :final weightG):
          await ref.read(snackEntryProvider.notifier).addSnack(
            mealPlanId: mealPlanId,
            recipeId: recipeId,
            scheduledDate: date,
            weightG: weightG,
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
          SnackBar(
            content: Text(l10n.feedAddedToMealPlan),
            backgroundColor: AkeliColors.primary,
          ),
        );
      }
    } catch (e) {
      appLogger.edge('add-snack', 'ERROR | $e', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mealPlannerError(e.toString())),
            backgroundColor: AkeliColors.error,
          ),
        );
      }
    }
  }

```
(delete it entirely — no replacement, its logic now lives in `meal_planner_actions.dart`'s `addSnackToDay`)

- [ ] **Step 4: Remove the obsolete l10n keys**

In `lib/l10n/app_en.arb`, delete these 4 lines (previously 538-542, now directly after `plannerViewToggleDay`'s block from Task 2):
```json
  "mealPlannerWeekTitle": "Your meals this week",
  "@mealPlannerWeekTitle": {},

  "mealPlannerDaysTitle": "Your upcoming meals",
  "@mealPlannerDaysTitle": {},

```

In `lib/l10n/app_fr.arb`, delete these 2 lines:
```json
  "mealPlannerWeekTitle": "Vos repas de la semaine",
  "mealPlannerDaysTitle": "Vos repas des prochains jours",
```

Run: `flutter gen-l10n`
Expected: exits 0; `mealPlannerWeekTitle`/`mealPlannerDaysTitle` getters removed from generated files.

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: all tests pass, including the pre-existing `test/features/meal_planner/meal_planner_day_row_guard_test.dart` (unaffected — `MealPlannerDayRow` itself wasn't touched) and every test added in Tasks 1, 4, 5, 6, 7.

- [ ] **Step 6: Static analysis**

Run: `flutter analyze`
Expected: `No issues found!` — confirms no unused imports (`snack_picker_sheet.dart` removed from `meal_planner_page.dart`), no dangling references to the deleted `mealPlannerWeekTitle`/`mealPlannerDaysTitle` getters.

- [ ] **Step 7: Manual verification** (no existing automated coverage for `MealPlannerPage` as a whole — same gap that existed before this change; documenting here per the source spec's own §10.2 split between widget tests and manual checks)

Run the app (`flutter run`) against a user with an active meal plan and walk through:
- Toggle switches the page body between week and day views, header/quick-actions stay visible in both.
- `Jour` view's day selector shows one chip per plan day (not a fixed 7); selecting a chip updates both the recap card and the meal list.
- Consuming a meal in `Jour` view updates the recap progress immediately (optimistic) and the change is reflected if you flip back to `Semaine` view.
- Add-snack in `Jour` view opens the same picker sheet as `Semaine` view and the added snack appears in both views after refresh.
- Log out of the active plan (or use a test account with no active plan) → confirm the empty "Generate plan" state renders with no toggle and no day-tab shell, matching today's behavior.
- Generate a fresh plan while in `Jour` view → confirm the day selector re-derives from the new plan's `entriesByDay` (no stale selected day past the new range, per the `dayKeys.contains(_selectedDate)` fallback in `MealPlannerDayTabView`).

- [ ] **Step 8: Commit**

```bash
git add lib/features/meal_planner/meal_planner_page.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart
git commit -m "feat(meal-planner): wire Semaine/Jour toggle into MealPlannerPage"
```

---

## Files Changed Summary

**New:**
- `lib/features/meal_planner/meal_planner_actions.dart`
- `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart`
- `lib/features/meal_planner/widgets/meal_planner_day_selector.dart`
- `lib/features/meal_planner/widgets/meal_planner_day_recap_card.dart`
- `lib/features/meal_planner/widgets/meal_planner_day_tab_view.dart`
- `test/providers/planner_view_mode_provider_test.dart`
- `test/features/meal_planner/meal_planner_view_toggle_test.dart`
- `test/features/meal_planner/meal_planner_day_selector_test.dart`
- `test/features/meal_planner/meal_planner_day_recap_card_test.dart`
- `test/features/meal_planner/meal_planner_day_tab_view_test.dart`

**Modified:**
- `lib/providers/meal_plan_provider.dart` (add `PlannerViewMode` + `plannerViewModeProvider`)
- `lib/features/meal_planner/meal_planner_page.dart` (toggle, view branching, title, refactor to shared actions)
- `lib/l10n/app_en.arb` / `lib/l10n/app_fr.arb` (add 2 keys, remove 2 keys)
- `lib/l10n/app_localizations*.dart` (regenerated, not hand-edited)
