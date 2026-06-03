# Nutrition Page Graph Upgrades + Home Entry Point

**Date:** 2026-05-25
**Status:** Approved

## Problem

The home dashboard is a good daily snapshot but gives zero trend visibility. The NutritionPage already exists with daily and weekly tabs but is only discoverable by tapping the calories metric chip — most users never find it. Its graphs are also minimal: a flat calorie bar chart and a static weight number, with no macro-vs-target feedback.

## Scope

Two files only: `lib/features/home/home_page.dart` and `lib/features/nutrition/nutrition_page.dart`. No new routes, providers, or schema changes.

## Design

### Change 1 — Home page entry point

**File:** `lib/features/home/home_page.dart`

Wrap the entire metrics card `Container` (weight + calories row) in an `InkWell` that navigates to `/nutrition`. Add a subtle `"Voir mes progrès →"` text label at the bottom of the card. The calories metric already had an individual `onTap` routing to `/nutrition`; that is removed in favour of the card-level tap. The weight metric gains the same navigation. Net result: one tap anywhere on the card lands on NutritionPage.

### Change 2 — Today tab: weight trend line chart

**File:** `lib/features/nutrition/nutrition_page.dart` — `_WeightSection` replaced by `_WeightTrendChart`

- Uses existing `weightLogProvider` (returns `List<WeightEntry>`, ordered newest-first; reversed to chronological for the chart)
- Renders a `LineChart` (fl_chart) showing the last 7–10 entries as a smooth curve with spot dots
- Target weight from `healthProfileProvider` rendered as a horizontal dashed reference line
- The `+` dialog to log a new weight entry is preserved, anchored top-right of the card
- If fewer than 2 entries exist, falls back to the current single-value display with a prompt to log more

### Change 3 — Today tab: macro progress bars

**File:** `lib/features/nutrition/nutrition_page.dart` — new `_MacroTargetBars` widget, inserted after the existing donut chart

- Three horizontal `LinearProgressIndicator` bars: Protéines, Glucides, Lipides
- Consumed values from `todayNutritionProvider` (already on the page)
- Targets: pulled from `healthProfileProvider` if available; fallback defaults of 150g / 250g / 65g until a user target-setting feature is built
- Each bar labelled `"Xg / Yg"` inline with colour matching the donut chart legend (primary / tertiary / warning)

### Change 4 — Weekly tab: stacked macro bar chart

**File:** `lib/features/nutrition/nutrition_page.dart` — `_WeeklyCaloriesChart` upgraded in place

- Each day's single bar replaced with a stacked bar using `BarChartRodStackItem`
- Three segments per day, expressed in kcal equivalents:
  - Protein: `proteinG × 4 kcal` — AkeliColors.primary
  - Carbs: `carbsG × 4 kcal` — AkeliColors.tertiary
  - Fat: `fatG × 9 kcal` — AkeliColors.warning
- `weeklyNutritionProvider` already returns all four macros per day; no extra query needed
- A colour legend row (Protéines / Glucides / Lipides) sits below the chart

## Data sources (all existing)

| Provider | Table | Used for |
|---|---|---|
| `todayNutritionProvider` | `daily_nutrition_log` | Today's calories + macros |
| `weeklyNutritionProvider` | `daily_nutrition_log` | 7-day macro history |
| `weightLogProvider` | `weight_log` | Weight trend line chart |
| `healthProfileProvider` | `health_profile` | Target weight reference line |

## What this does NOT include

- A new bottom nav tab (intentional — navbar stays at 4 tabs)
- A 30-day view (weekly is sufficient for V1; extend later)
- Streak / meal adherence metrics (separate future feature)
- User-configurable macro targets (fallback defaults used for now)
- Fixing the hardcoded 2000 kcal target on the home page (separate task)
