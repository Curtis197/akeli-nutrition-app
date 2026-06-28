# Custom Meal Plan Schedule — Design Spec
**Date:** 2026-06-28  
**Status:** Approved

## Overview

Allow users to define their own meal schedule — which meal slots they want each day, how many, what type, optional nickname, calorie %, and per-slot macro targets. The meal plan generator respects this configuration instead of using a hardcoded 3-meal structure.

## Goals

- Skip any default meal (e.g. no breakfast)
- Add multiple snacks / collations per day
- Control how heavy each slot is (calorie % per slot)
- Set per-slot macro targets (protein/carbs/fat %)
- Two edit entry points: Nutrition Plan page (full) + Meal Planner quick-edit
- Optional onboarding step + hint banner for users who skip
- Regenerate from today or defer to next week when changing structure mid-week

## Non-Goals

- Per-day schedule variation (same structure applies every day of the week)
- Free-text recipe type tags (category stays within the existing 4: breakfast/lunch/dinner/snack)
- Retroactive change to already-consumed entries

---

## 1. Data Model

### 1.1 `meal_distribution` — 4 new columns

```sql
ALTER TABLE meal_distribution
  ADD COLUMN IF NOT EXISTS nickname      text,
  ADD COLUMN IF NOT EXISTS protein_pct   double precision,
  ADD COLUMN IF NOT EXISTS carbs_pct     double precision,
  ADD COLUMN IF NOT EXISTS fat_pct       double precision;
```

| Column | Purpose |
|---|---|
| `nickname` | Optional user-facing label. Shown instead of default type name (e.g. "Collation du matin"). |
| `protein_pct` | % of this slot's calories from protein. Used by generator to score recipes per slot. |
| `carbs_pct` | % of this slot's calories from carbs. |
| `fat_pct` | % of this slot's calories from fat. |

Existing columns retained unchanged: `meal_type` (recipe-selection category: `breakfast | lunch | dinner | snack`), `calorie_pct`, `calorie_target`, `min_portion_g`, `max_portion_g`, `sort_order`.

Multiple rows can share the same `meal_type` (e.g. 3 rows with `meal_type = 'snack'`). `sort_order` and `nickname` differentiate them for display and generation order.

### 1.2 `meal_plan_entry` — 1 new column

```sql
ALTER TABLE meal_plan_entry
  ADD COLUMN IF NOT EXISTS nickname text;
```

Populated at generation time by copying from `meal_distribution.nickname`. Denormalized so display never requires a distribution join.

### 1.3 `user_profile` — 1 new column

```sql
ALTER TABLE user_profile
  ADD COLUMN IF NOT EXISTS has_dismissed_meal_schedule_hint boolean NOT NULL DEFAULT false;
```

Tracks whether the post-generation hint banner has been dismissed.

---

## 2. Flutter Model Changes

### 2.1 `MealDistribution` (`lib/shared/models/nutrition_plan.dart`)

Add 4 optional fields:

```dart
final String?  nickname;
final double?  proteinPct;
final double?  carbsPct;
final double?  fatPct;
```

Update `fromJson`, `toJson`, and `copyWith` accordingly.

### 2.2 `MealPlanEntry` (`lib/shared/models/meal_plan.dart`)

Add:

```dart
final String? nickname;
```

Display helper:

```dart
String displayLabel(AppLocalizations l10n) =>
    nickname ?? mealTypeL10n(l10n, mealType);
```

`mealTypeL10n` is the existing localized label resolver in `core/meal_type_l10n.dart`.

---

## 3. New Flutter UI Components

### 3.1 `MealScheduleWidget` (`lib/features/nutrition_plan/widgets/meal_schedule_widget.dart`)

Reusable `StatefulWidget`. Accepts:

```dart
MealScheduleWidget({
  required List<MealDistribution> distributions,
  required int totalCalorieGoal,
  required void Function(List<MealDistribution>) onChanged,
})
```

Each slot card renders:
- **Category picker** — `DropdownButton` with 4 options: Breakfast / Lunch / Dinner / Snack (maps to `meal_type`)
- **Nickname field** — optional `TextFormField`; placeholder is the category default name
- **Calorie % slider** — 0–60%, with live kcal display (`caloriePct × totalCalorieGoal / 100`)
- **Macro section** (expandable) — three sliders for protein/carbs/fat %; sum must = 100% to be valid; shows g equivalent live
- **Delete button** — removed if only 1 slot remains
- **Drag handle** — `ReorderableListView` for sort order

Bottom bar:
- Running calorie % total with green/red indicator
- "Add slot" button (adds a `snack` slot with 0%)
- Calorie total must equal 100% for the parent's save to be enabled

### 3.2 `MealSchedulePage` (`lib/features/settings/meal_schedule_page.dart`)

Full-page wrapper. Route: `AkeliRoutes.mealSchedule`.

- Loads active `NutritionPlan` + its distributions
- Embeds `MealScheduleWidget`
- Save button: writes updated `meal_distribution` rows via `nutritionPlanNotifierProvider`
- Added to `SettingsPage` list as "Meal Schedule" entry

### 3.3 `MealScheduleOnboardingStep` (`lib/features/auth/widgets/meal_schedule_onboarding_step.dart`)

Shown after `NutritionPlanPage` step during onboarding.

- Wraps `MealScheduleWidget` with pre-filled 3-meal default
- Prominent "Skip" button → proceeds with default, sets no distribution (generator falls back)
- Completing it saves the distribution before proceeding

---

## 4. Modified Flutter Pages

### 4.1 `NutritionPlanPage`

Replace the manual `_addMealSlot / _removeMealSlot / _updateSlotPct / _updateSlotBounds` methods and their inline UI with `MealScheduleWidget`. State is lifted via the `onChanged` callback. Logic for validating total % and saving distributions is unchanged.

### 4.2 `MealPlannerPage`

- Add a "Customize" `IconButton` (settings icon) to the page header area
- Tapping it opens a `showModalBottomSheet` with `MealScheduleWidget` + a save button
- On save: `showDialog` with two options:
  - **"Apply from today"** → saves distribution, calls `mealPlanGeneratorProvider.generate()`
  - **"Apply from next week"** → saves distribution only, no regeneration
- After first plan generation, if `has_dismissed_meal_schedule_hint == false`, show a dismissible `MaterialBanner`:  
  _"Customize your meal schedule anytime — tap the settings icon above"_  
  Dismissing it calls an upsert on `user_profile`.

### 4.3 `MealPlannerDayRow`

`AkeliMealCard` `title` field: use `entry.nickname ?? entry.mealTypeLabel` (localized via `displayLabel`).

Entries within a day are sorted by `sort_order` from their distribution. Since entries don't carry `sort_order` directly, entries are sorted using the `sort_order` implied by their generation sequence. This is handled by ensuring the generator inserts entries in `sort_order` order and querying with `.order('created_at')` or adding `sort_order` to `meal_plan_entry` (simpler: add `sort_order int` column, populated at generation time).

> **Note:** Add `sort_order int` to `meal_plan_entry` (same migration as `nickname`) so day rows render in the user-defined slot order.

### 4.4 `OnboardingPage`

Insert `MealScheduleOnboardingStep` after the nutrition plan step. Controlled by an index-based step list already in place.

---

## 5. Backend Changes

### 5.1 `generate_meal_plan` SQL function

Replace hardcoded `v_meal_types` assignment:

```sql
-- Read from user's active nutrition plan distributions
SELECT array_agg(md.meal_type ORDER BY md.sort_order)
INTO   v_meal_types
FROM   meal_distribution md
JOIN   nutrition_plan np ON np.id = md.nutrition_plan_id
WHERE  np.user_id = p_user_id
  AND  np.is_active = true;

-- Fallback: default 3-meal structure
IF v_meal_types IS NULL THEN
  v_meal_types := ARRAY['breakfast', 'lunch', 'dinner'];
END IF;
```

Derive `p_meals_per_day` internally from `array_length(v_meal_types, 1)` for fan-mode slot cap calculations (replaces the parameter-based value). The SQL function signature retains `p_meals_per_day` for backward compatibility but ignores it when a distribution is found.

Per-slot macro targeting: inside the generation loop, join `meal_distribution` on `(nutrition_plan_id, meal_type, sort_order)` to read `protein_pct` / `fat_pct` for the current slot. Use these to set `v_target_protein_density` and `v_target_fat_density` per iteration instead of the current single global value.

Populate `meal_plan_entry.nickname` and `meal_plan_entry.sort_order` from the distribution row during INSERT.

Apply the same changes to `generate_meal_plan_from_saved`.

### 5.2 `generate-meal-plan` edge function (`supabase/functions/generate-meal-plan/index.ts`)

Remove `meals_per_day` from the request body parsing and from the RPC call params. Flutter no longer sends it; the SQL derives slot count from the distribution.

### 5.3 Flutter `MealPlanGeneratorNotifier.generate()`

Remove the `mealsPerDay` parameter and stop sending `meals_per_day` in the edge function body.

---

## 6. Migrations Summary (in order)

| # | File name pattern | What it does |
|---|---|---|
| 1 | `YYYYMMDD_add_meal_schedule_columns.sql` | Add `nickname`, `protein_pct`, `carbs_pct`, `fat_pct` to `meal_distribution`; add `nickname`, `sort_order` to `meal_plan_entry`; add `has_dismissed_meal_schedule_hint` to `user_profile` |
| 2 | `YYYYMMDD_generate_meal_plan_read_distribution.sql` | Rewrite `generate_meal_plan` to read `v_meal_types` from `meal_distribution`; per-slot macro density; populate `nickname` + `sort_order` on entry INSERT |
| 3 | `YYYYMMDD_generate_meal_plan_from_saved_read_distribution.sql` | Same update for `generate_meal_plan_from_saved` |

---

## 7. New Localization Keys

Both `app_en.arb` and `app_fr.arb`:

```
mealScheduleTitle
mealScheduleSubtitle
mealScheduleAddSlot
mealScheduleSaveChanges
mealScheduleTotalCalories          ← "{total}% of daily calories"
mealScheduleMacroSection           ← "Macro targets"
mealScheduleCategoryBreakfast
mealScheduleCategoryLunch
mealScheduleCategoryDinner
mealScheduleCategorySnack
mealScheduleNicknamePlaceholder    ← "Custom label (optional)"
mealScheduleApplyFromToday
mealScheduleApplyFromNextWeek
mealScheduleApplyDialogTitle
mealScheduleHintBanner             ← "Customize your meal schedule anytime…"
mealScheduleHintDismiss
mealScheduleOnboardingTitle
mealScheduleOnboardingSkip
```

---

## 8. Files Changed

**New:**
- `lib/features/nutrition_plan/widgets/meal_schedule_widget.dart`
- `lib/features/settings/meal_schedule_page.dart`
- `lib/features/auth/widgets/meal_schedule_onboarding_step.dart`
- `supabase/migrations/YYYYMMDD_add_meal_schedule_columns.sql`
- `supabase/migrations/YYYYMMDD_generate_meal_plan_read_distribution.sql`
- `supabase/migrations/YYYYMMDD_generate_meal_plan_from_saved_read_distribution.sql`

**Modified:**
- `lib/shared/models/nutrition_plan.dart`
- `lib/shared/models/meal_plan.dart`
- `lib/features/nutrition_plan/nutrition_plan_page.dart`
- `lib/features/meal_planner/meal_planner_page.dart`
- `lib/features/meal_planner/widgets/meal_planner_day_row.dart`
- `lib/features/auth/onboarding_page.dart`
- `lib/features/settings/settings_page.dart`
- `lib/providers/meal_plan_provider.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_fr.arb`
- `supabase/functions/generate-meal-plan/index.ts`
