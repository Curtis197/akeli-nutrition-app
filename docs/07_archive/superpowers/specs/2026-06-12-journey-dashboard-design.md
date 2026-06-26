# Journey Dashboard — "Parcours" Tab Design

**Date:** 2026-06-12
**Status:** Approved

## Overview

Add a third tab "Parcours" to the existing `NutritionPage` (alongside "Aujourd'hui" and "Semaine"). The tab gives the user a full-history view of their nutrition journey: all-time summary stats, a streak counter, goal progress bars, and a navigable monthly calendar showing day-by-day calorie target adherence.

---

## 1. Tab Placement

`NutritionPage` gains a third tab at index 2. No other page or navigation element changes.

```
[ Aujourd'hui ]  [ Semaine ]  [ Parcours ]   ← existing tabs + new
```

---

## 2. Layout (top → bottom, scrollable)

| # | Section | Description |
|---|---------|-------------|
| 1 | **Summary row** | 2×2 grid of all-time stat cards |
| 2 | **Streak pill** | Current streak + personal record |
| 3 | **Goals card** | 5 progress bars: weight + 4 macro/calorie hit rates |
| 4 | **Monthly calendar** | Month grid with ‹ › navigation |

---

## 3. Summary Row

Four stat cards in a 2×2 grid:

| Card | Value | Source |
|------|-------|--------|
| Jours de parcours | Days since onboarding date | `user_profile.created_at` |
| Jours logués | Days with at least one entry in `daily_nutrition_log` | RPC |
| Repas consommés | Total rows with `is_consumed = true` in `meal_plan_entry` | RPC |
| Taux de régularité | `days_logged / total_days * 100` % | RPC |

---

## 4. Streak Pill

- **Current streak**: consecutive days ending today where `status = 'hit'` (see §6)
- **Personal record**: longest ever consecutive hit streak
- Displays: 🔥 icon, large current streak number, small label, "Record: N" right-aligned
- Streak resets to 0 if today is not yet `'hit'` (user hasn't logged today) — does NOT break if today is still in progress

---

## 5. Goals Card

Five stacked progress bars:

| Bar | Label | Computation |
|-----|-------|-------------|
| Poids | Start kg → current kg → target kg | gradient red→yellow→green, `(start - current) / (start - target)` |
| Calories | % of logged days with calorie target hit | `hit_days / logged_days` |
| Protéines | % of logged days with protein target hit (±15%) | same |
| Glucides | % of logged days with carbs target hit (±15%) | same |
| Lipides | % of logged days with fat target hit (±15%) | same |

Macro bars use their existing color codes (protein = primary, carbs = tertiary, fat = warning).
Weight `current_kg` is taken from the most recent entry in `weight_log`.

---

## 6. Monthly Calendar

- Full 7-column month grid (Sun-start), navigable with ‹ › buttons
- Default view: current month
- Navigation: previous months only (no future months)
- Each day cell shows the day number and is colored by status:

| Status | Color | Condition |
|--------|-------|-----------|
| `hit` | Green background | Calories logged AND within ±10% of daily target |
| `partial` | Yellow background | Calories logged but outside ±10% of daily target |
| `missed` | Red background | Meal plan existed that day, nothing logged |
| `empty` | Dark grey | No log, no plan |

- Today's cell gets a blue outline
- Future days are muted, not interactive
- Tapping a day: no action in V1

---

## 7. Data Architecture

### RPC: `get_journey_stats`

```sql
get_journey_stats(
  p_user_id UUID,
  p_year    INT,
  p_month   INT
) RETURNS JSON
```

Returns a single JSON object:

```json
{
  "summary": {
    "total_days": 103,
    "days_logged": 78,
    "meals_consumed": 234,
    "consistency_pct": 76
  },
  "streak": {
    "current": 7,
    "best": 14
  },
  "goals": {
    "weight_start_kg": 82.0,
    "weight_current_kg": 76.5,
    "weight_target_kg": 73.0,
    "calorie_hit_pct": 64,
    "protein_hit_pct": 71,
    "carbs_hit_pct": 58,
    "fat_hit_pct": 69
  },
  "calendar": [
    { "date": "2026-06-01", "status": "hit" },
    { "date": "2026-06-02", "status": "partial" }
  ]
}
```

- `calendar` contains only days in the requested `p_year`/`p_month`
- Summary and streak are always all-time (not scoped to the month)
- RLS: function executes as the calling user; `p_user_id` must equal `auth.uid()`

### Flutter Provider

```dart
// family provider keyed by (year, month)
final journeyStatsProvider = FutureProvider.family<JourneyStats, ({int year, int month})>(
  (ref, params) async { ... }
);
```

- Re-fetches only when month changes
- `JourneyStats` model is a plain Dart class parsed from the RPC JSON
- `JourneyCalendarDay` model: `{ date: DateTime, status: JourneyDayStatus }`

---

## 8. New Files

```
lib/features/nutrition/widgets/journey/
  journey_tab.dart            ← root, reads provider, loading/error states
  journey_summary_row.dart    ← 2×2 stat cards
  journey_streak_pill.dart    ← flame + streak + record
  journey_goals_card.dart     ← 5 progress bars
  journey_calendar.dart       ← month grid + navigation

lib/shared/models/journey_stats.dart   ← JourneyStats, JourneyCalendarDay, JourneyDayStatus

lib/providers/journey_provider.dart    ← journeyStatsProvider family

supabase/functions/get-journey-stats/index.ts   ← edge function wrapping the RPC
```

### Modified Files

```
lib/features/nutrition/nutrition_page.dart   ← add third tab + JourneyTab widget
```

---

## 9. Error & Loading States

- Loading: skeleton shimmer on each section (summary, streak, goals, calendar)
- Error: inline error card with retry button — does not break the other two nutrition tabs
- Empty state (user has < 3 days of data): show summary row only with zeroes, calendar empty, streak 0

---

## 10. Out of Scope (V1)

- Tapping a calendar day to drill into that day's log
- Exporting journey data
- Social sharing of streak milestones
- Streak freeze / grace day mechanic
