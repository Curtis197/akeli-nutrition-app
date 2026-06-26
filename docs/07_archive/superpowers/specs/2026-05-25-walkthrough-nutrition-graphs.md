# Nutrition Graphs Implementation Walkthrough

This document outlines the work completed to implement the new nutrition graphs design as specified in `2026-05-25-nutrition-graphs-design.md`.

## Summary of Changes

We enhanced the visual data tracking in the application, making it easier for users to understand their progress at a glance and discover the detailed nutrition page.

### 1. Home Page Navigation Update
- **File:** `lib/features/home/home_page.dart`
- **Change:** Wrapped the main metrics card (calories and weight) with an `InkWell` to make the entire card tappable, navigating directly to the Nutrition page.
- **Visual cue:** Added a subtle "Voir mes progrès →" text link at the bottom of the card to encourage users to tap and explore their detailed stats.

### 2. Weight Trend Chart
- **File:** `lib/features/nutrition/nutrition_page.dart`
- **Change:** Replaced the static current weight display with a new `_WeightTrendChart` powered by `fl_chart`.
- **Features:** 
  - Displays a line chart of the user's recent weight entries (chronological order).
  - Includes a dashed horizontal line indicating the user's `targetWeightKg` from their `healthProfileProvider`.
  - Gracefully falls back to a simple text display if the user has fewer than 2 weight logs, encouraging them to log another entry to see the trend.

### 3. Macro Target Bars
- **File:** `lib/features/nutrition/nutrition_page.dart`
- **Change:** Created a new `_MacroTargetBars` widget.
- **Features:** 
  - Adds 3 linear progress bars below the donut chart on the "Aujourd'hui" tab.
  - Displays the user's progress against target protein, carbs, and fat goals.
  - Automatically calculates progress percentage and caps it at 100% visually, ensuring a clean UI even if the user exceeds their goals.

### 4. Stacked Weekly Calories Chart
- **File:** `lib/features/nutrition/nutrition_page.dart`
- **Change:** Refactored the `_WeeklyCaloriesChart` on the "Semaine" tab to use `BarChartRodStackItem`.
- **Features:**
  - Instead of a single color bar for total calories, each day's bar is now visually segmented into its macronutrient components (Protein, Carbs, Fat).
  - Segments are calculated based on their energy equivalents (Protein: 4 kcal/g, Carbs: 4 kcal/g, Fat: 9 kcal/g).
  - Added a color-coded legend (`_Legend`) below the chart to help users quickly identify which color corresponds to which macro.

## Verification
- **Code validation:** Checked for syntax errors and ensured no build warnings are present.
- **State Integration:** Ensured all charts properly listen to their respective Riverpod providers (`weightLogProvider`, `healthProfileProvider`, `todayNutritionProvider`).
- **Responsive UI:** The charts adjust their sizing dynamically within their containers.
