# Meal Planner — Day View Toggle — Design
**Date:** 2026-07-10
**Status:** Proposed

## Overview

The marketing store-screenshot mockups (`akeli_landing_page/public/store-screenshots`, screen `PlannerScreen`) show a day-tab planner layout that doesn't exist in the app today: a horizontal day-of-week chip selector, a per-day calorie recap card, and that day's meals listed underneath. The app's actual `MealPlannerPage` is a single continuous vertical scroll — one `MealPlannerDayRow` per day of the active plan, each row itself a horizontally-scrolling strip of meal cards.

This spec adds the day-tab layout as a second view, reachable via a **Semaine / Jour** toggle on the existing Planner page. It is a pure Flutter UI addition: no backend changes, no data-model changes, no shopping-list changes. `MealPlan.entriesByDay` (`lib/shared/models/meal_plan.dart`) already returns exactly the `Map<DateTime, List<MealPlanEntry>>` grouping this view needs.

## Goals

- Add a `MealPlannerViewToggle` (Semaine / Jour) to `MealPlannerPage`, default `Semaine` (today's behavior, unchanged).
- `Jour` view: a day-chip selector (only for days present in the active plan — not a fixed Mon–Sun grid), a per-day calorie recap card, that day's meals, and the existing add-snack action.
- Reuse existing data (`entriesByDay`), existing widgets (`AkeliMealCard`), and existing logging/l10n conventions. No new provider queries.

## Non-Goals

- Any change to the shopping list (feature, UI, or `generate_shopping_list` RPC). The mockup shows an inline per-day shopping list, but the real RPC has no per-day scoping and this is explicitly out of scope — `Jour` view does not embed a shopping list section.
- Any change to plan generation, RPCs, or the "rest of this week" day-count logic (`8 - now.weekday` in `MealPlanGeneratorNotifier`).
- Persisting the Semaine/Jour toggle choice across sessions. Resets to `Semaine` on next page load.
- Filling in empty/future days beyond what's already generated. No per-day "generate" CTA — the day selector simply doesn't show a chip for a day that isn't in `entriesByDay`.
- `DietPlanPage` / `NutritionPlanPage` — unrelated screens, not touched.
- Batch cooking, meal swap, rating flows — unchanged, reused as-is via `AkeliMealCard`.

---

## 1. Data Model

No changes. `MealPlan.entriesByDay` already provides the day → entries grouping this view needs, pre-sorted.

**Caution for implementation:** `meal_plan_entry`'s columns have drifted from migration files before (see `supabase/migrations/20260529000014_fix_meal_plan_entry_column_names.sql` — live DB had `date` instead of `scheduled_date`, integer instead of `numeric(4,1)` servings). Verify current column names against the live schema (Supabase MCP `list_tables`) before writing any new query — though this spec introduces none, the implementer should not assume any single migration file reflects current schema.

## 2. Flutter Model Changes

None required. `MealPlanEntry.calories` (existing getter) already branches correctly on `isCustomMeal` vs computed/component-based calories — the day recap card sums this per date, no new model logic needed.

**Implementation note:** the day recap's "consumed / target kcal" must reuse whatever calculation the Home screen's calorie `ProgressRing`/`AkeliModernMetric` already uses (daily target from `activeNutritionPlanProvider`, consumed total aware of the `optimisticConsumptionProvider` overlay on top of `MealConsumptionNotifier`). Locate and reuse that exact formula rather than reimplementing it — two independently-computed totals disagreeing between Home and Planner would be a visible bug.

## 3. New Flutter UI Components

### 3.1 `MealPlannerViewToggle`
`lib/features/meal_planner/widgets/meal_planner_view_toggle.dart`

Two-option segmented control (Semaine / Jour), not a tab row — `AkeliTabBar` is an underline text-tab widget built for 2+ arbitrary tabs, not a toggle; a filled-pill 2-way switch is the right shape here.

```dart
MealPlannerViewToggle({
  required PlannerViewMode value,
  required ValueChanged<PlannerViewMode> onChanged,
})
```

Stateless/controlled. `HapticFeedback.selectionClick()` on change, matching the existing `_FilterChip` convention in `lib/features/home/home_page.dart`. Styled with `AkeliColors`/`AkeliRadius` tokens — active half filled with brand color, inactive half transparent.

### 3.2 `MealPlannerDaySelector`
`lib/features/meal_planner/widgets/meal_planner_day_selector.dart`

Horizontal scrollable row of day chips, one per `DateTime` key in `plan.entriesByDay` (already sorted ascending) — **not** a fixed 7-day grid.

```dart
MealPlannerDaySelector({
  required List<DateTime> days,
  required DateTime selected,
  required ValueChanged<DateTime> onSelect,
})
```

Each chip is a private `_DayChip` mirroring the existing `_FilterChip` pattern in `home_page.dart` (rounded pill, `isActive` bool, haptic feedback on tap) — kept local to this file rather than extracted to a shared widget, following the precedent that this visual pattern is already duplicated locally, not shared. Short weekday label via `intl`'s `DateFormat.E(locale)` (or whatever short-weekday helper `lib/core/date_utils.dart` already exposes, if any — check before adding a new formatting path).

### 3.3 `MealPlannerDayRecapCard`
`lib/features/meal_planner/widgets/meal_planner_day_recap_card.dart`

```dart
MealPlannerDayRecapCard({
  required DateTime date,
  required double consumedKcal,
  required double targetKcal,
})
```

Card-style container (existing surface/elevation tokens) showing: full date label (reuse the `EEEE d MMMM` formatting already used in `MealPlannerDayRow`'s header), "{consumed} / {target} kcal" text, and a `LinearProgressIndicator` styled with `AkeliColors`/`AkeliRadius`. Progress is visually clamped at 100% even if `consumedKcal > targetKcal` (custom/bonus meals) — the kcal text itself stays uncapped.

### 3.4 `MealPlannerDayTabView`
`lib/features/meal_planner/widgets/meal_planner_day_tab_view.dart`

```dart
MealPlannerDayTabView({ required MealPlan plan })
```

Composes 3.2 + 3.3 + a vertical `Column` of that day's `AkeliMealCard(isPlanner: true, ...)` — the same widget `MealPlannerDayRow` already uses, laid out full-width/vertically rather than the existing horizontal 270-height scroller (only one day's meals to show now, no need to horizontally scroll). Existing "Add snack" `OutlinedButton` at the bottom, wired to the same `snackEntryProvider` flow `MealPlannerDayRow` already uses.

Holds `selectedDate` as local widget state (or a small `autoDispose` `StateProvider<DateTime?>`), defaulting to the first key in `entriesByDay` — i.e. today, when present.

## 4. Modified Flutter Pages

### 4.1 `MealPlannerPage`
`lib/features/meal_planner/meal_planner_page.dart`

- Add `MealPlannerViewToggle` directly below the existing header title.
- Replace the current conditional title (`l10n.mealPlannerWeekTitle` vs `l10n.mealPlannerDaysTitle`, chosen by `dayKeys.length > 3`) with a single static title (new key `mealPlannerTitle`) — the toggle itself now communicates the view mode. Grep for `mealPlannerWeekTitle`/`mealPlannerDaysTitle` elsewhere before removing them; if unused elsewhere, delete from both ARB files.
- Introduce `PlannerViewMode { week, day }` and `plannerViewModeProvider` (`StateProvider<PlannerViewMode>`, `autoDispose`, default `.week`) in `lib/providers/meal_plan_provider.dart`, alongside the existing providers.
- Body branches on `ref.watch(plannerViewModeProvider)`:
  - `.week` → existing `NestedScrollView`/`MealPlannerDayRow` list, unchanged.
  - `.day` → new `MealPlannerDayTabView(plan: plan)`.
- The 3 existing quick-action cards (Diet plan / Shopping list / Batch cooking) and the header `tune` (customize) icon stay in both modes, unchanged.
- If `activeMealPlanProvider` has no active plan, both modes fall back to the existing "Generate plan" empty state — `Jour` is not selectable/rendered differently in this case.

## 5. Backend Changes

None. No changes to `generate_meal_plan`, `generate_shopping_list`, any edge function, or any migration.

## 6. Migrations Summary

None.

## 7. New Localization Keys

Both `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`:

```
plannerViewToggleWeek     ← "Week" / "Semaine"
plannerViewToggleDay      ← "Day" / "Jour"
mealPlannerTitle          ← "My plan" / "Mon planning"  (replaces the two conditional titles)
```

Day-chip weekday labels and the recap card's date format use `intl`'s locale-aware `DateFormat`, no new ARB keys needed there. Run `flutter gen-l10n` after ARB changes, before referencing the new keys.

## 8. Logging

Per project logging standard (mandatory, `CLAUDE.md`):

- `_logger.userAction` — toggling Semaine/Jour, selecting a day chip. (Add-snack tap is already logged via the reused `snackEntryProvider` flow — verify, don't duplicate.)
- `_logger.provider` — `plannerViewModeProvider` state transitions.
- No new `_logger.db` / `_logger.edge` calls — no new queries or edge functions introduced; this view reads from the already-logged `activeMealPlanProvider`.

## 9. Edge Cases

- **Plan has only 1 day left** (e.g. viewing on a Sunday) → day selector renders a single chip; view still functions without horizontal scroll.
- **No active plan** → `Jour` toggle still visible/selectable, but the view shows the same existing "Generate plan" CTA/empty state as `Semaine` mode today — not an empty day-tab shell.
- **Consumed kcal exceeds target** (custom/bonus meals) → progress bar visually clamps at 100%; the kcal text shows the true, uncapped numbers.
- **Custom (non-recipe) meal entry** (`isCustomMeal == true`) for the selected day → renders via the existing `AkeliMealCard`, which already branches on `isCustomMeal` for its calorie display — no special-casing needed in the new widgets.

## 10. Verification Tests

### 10.1 Flutter widget tests
`test/features/meal_planner/meal_planner_day_tab_view_test.dart` (new)

- Toggle switches the page body between week and day views.
- Day selector renders exactly one chip per date in `entriesByDay` — not a fixed 7, and none for dates outside the plan.
- Selecting a day chip updates both the recap card and the meals list to that day's data.
- Default selected day is the first key in `entriesByDay` (today, when present).
- Recap card's consumed/target kcal matches the sum of that day's consumed entries, respecting the `optimisticConsumptionProvider` overlay.
- Progress bar visually clamps at 100% when consumed > target; kcal text does not.
- Add-snack button in `Jour` view opens the same `snack_picker_sheet` flow as `Semaine` view's row.
- No active plan → `Jour` view shows the existing empty/"Generate plan" state, not an empty shell.

### 10.2 Manual / integration

- Fresh plan generation → `Jour` view's default day and chip range match the generated plan.
- Consuming a meal in `Jour` view updates the recap progress immediately (optimistic) and agrees with the Home screen's equivalent total.
- Switching Semaine → Jour → Semaine does not lose the week view's scroll position or force a data refetch.

## 11. Files Changed

**New:**
- `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart`
- `lib/features/meal_planner/widgets/meal_planner_day_selector.dart`
- `lib/features/meal_planner/widgets/meal_planner_day_recap_card.dart`
- `lib/features/meal_planner/widgets/meal_planner_day_tab_view.dart`
- `test/features/meal_planner/meal_planner_day_tab_view_test.dart`

**Modified:**
- `lib/features/meal_planner/meal_planner_page.dart`
- `lib/providers/meal_plan_provider.dart` (add `PlannerViewMode` enum + `plannerViewModeProvider`)
- `lib/l10n/app_en.arb`
- `lib/l10n/app_fr.arb`
