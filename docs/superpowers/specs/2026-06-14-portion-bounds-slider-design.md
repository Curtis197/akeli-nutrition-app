---
name: portion-bounds-slider
description: Per-meal-type portion bound sliders (min/max grams) in NutritionPlanPage — onboarding step 6 and Settings > Suivi nutritionnel
metadata:
  type: spec
---

# Portion Bounds Slider — Design Spec

**Date:** 2026-06-14
**Status:** Approved, ready for implementation
**Surfaces:** Onboarding step 6 + Settings → Suivi nutritionnel (both use `NutritionPlanPage`)

---

## Problem

`meal_distribution.min_portion_g` and `max_portion_g` are stored per meal type and read by the generator RPC at plan generation time. The DB, RPC, and Flutter model are all wired up, but the UI exposes no way to set them — every user gets the hardcoded defaults (50 g / 1500 g).

---

## Goal

Let users optionally configure portion bounds per meal type (breakfast, lunch, dinner, snack) directly inside the nutrition plan UI, without adding friction for users who are happy with the defaults.

---

## No Backend Changes Required

| Layer | Status |
|-------|--------|
| `meal_distribution.min_portion_g / max_portion_g` columns | ✅ Applied (`20260614103445`) |
| `generate_meal_plan` reads bounds per meal type | ✅ Applied (`20260614154145`) |
| `swap_meal_plan_entry` reads bounds per meal type | ✅ Applied (`20260614103445`) |
| `MealDistribution.minPortionG / maxPortionG` Dart fields | ✅ Done (`lib/shared/models/nutrition_plan.dart`) |
| `MealDistribution.toJson()` includes `min_portion_g / max_portion_g` | ✅ Done |
| `NutritionPlanNotifier.savePlan()` writes distributions | ✅ Done |

---

## UI Design

### Placement

Inside `NutritionPlanPage`, section **"3. Répartition des repas"**. Each meal distribution row gains an expand chip on the right showing the current bounds.

### Collapsed state (default)

```
[Petit-déjeuner]  [−] [33%] [+]  [314 kcal]  [⚙ 50–1500g ▾]  [🗑]
```

- Chip color: `AkeliColors.surfaceContainerHighest` (muted) when at defaults
- Chip color: `AkeliColors.primaryContainer` with `AkeliColors.primary` text when customised
- Tapping chip toggles the panel open/closed

### Expanded state

```
[Petit-déjeuner]  [−] [33%] [+]  [314 kcal]  [⚙ 200–800g ▴]  [🗑]
┌──────────────────────────────────────────────────────────────────┐
│  QUANTITÉ DE PORTION                                             │
│  ●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●                   │
│  50 g                                   1 500 g                  │
│  Min : 200 g                       Max : 800 g                   │
└──────────────────────────────────────────────────────────────────┘
```

- Uses Flutter `RangeSlider` widget
- Track: `AkeliColors.secondaryContainer` (active), `AkeliColors.surfaceContainerHighest` (inactive)
- Thumb: `AkeliColors.surfaceContainerLowest`
- Below the slider: two labels showing current min g and max g

### Slider configuration

| Property | Value |
|----------|-------|
| Min value | 50 g |
| Max value | 1500 g |
| Step | 25 g |
| Flutter `divisions` | `(1500 - 50) ~/ 25 = 58` |
| Constraint | `minG < maxG` — enforced natively by `RangeSlider` |

---

## Implementation

### New private widget: `_PortionBoundsPanel`

```dart
// Stateless — receives current values and callbacks
class _PortionBoundsPanel extends StatelessWidget {
  final int minG;
  final int maxG;
  final void Function(int minG, int maxG) onChanged;
}
```

Renders the `RangeSlider` + labels. Kept stateless — state lives in `NutritionPlanPageState._distributions`.

### Changes to `NutritionPlanPageState`

**1. New expand-state tracker**

```dart
final Set<int> _expandedBoundsIndices = {};
```

Cleared when `_calculateResults()` resets `_distributions`.
Cleaned up when `_removeMealSlot(index)` is called: remove `index`, shift down all indices above it.

**2. New update method**

```dart
void _updateSlotBounds(int index, int minG, int maxG) {
  setState(() {
    final updated = [..._distributions];
    updated[index] = updated[index].copyWith(minPortionG: minG, maxPortionG: maxG);
    _distributions = updated;
  });
}
```

**3. Updated meal row widget**

Each row builds:
- The existing `[−] pct [+] kcal [🗑]` row with the bounds chip appended
- If `_expandedBoundsIndices.contains(i)`: render `_PortionBoundsPanel` below the row

### Chip label logic

```dart
bool _isCustomBounds(MealDistribution d) =>
    d.minPortionG != 50 || d.maxPortionG != 1500;

String _boundsLabel(MealDistribution d) =>
    '${d.minPortionG}–${d.maxPortionG} g';
```

---

## Behaviour by Surface

### Onboarding (step 6, `isOnboarding: true`)

- All panels start collapsed
- Chip shows `50–1500 g` in muted colour — signals "standard, no action needed"
- User can expand any meal row and adjust before tapping "Suivant"
- Bounds are saved alongside the rest of the plan when `savePlan()` is called by `_saveNutritionPlanAndNext()`

### Settings → Suivi nutritionnel (`isOnboarding: false`)

- `_loadInitialData()` loads the active plan including distributions; stored bounds are reflected immediately in chip labels and slider positions
- User adjusts, taps "Enregistrer mon plan" — same `savePlan()` path

---

## Edge Cases

| Case | Handling |
|------|----------|
| New meal slot added (`_addMealSlot`) | `MealDistribution` constructor defaults `minPortionG: 50, maxPortionG: 1500` — no action needed |
| Meal slot removed (`_removeMealSlot(index)`) | Remove `index` from `_expandedBoundsIndices`; shift all stored indices `> index` down by 1 |
| `_calculateResults()` resets distributions | Clear `_expandedBoundsIndices` — all rows go back to collapsed defaults |
| Returning user with saved custom bounds | `_loadInitialData()` populates `_distributions` with stored values; chip shows correct label immediately |
| User resets to defaults | No explicit reset button — user drags slider back to 50 / 1500; chip reverts to muted style |

---

## Files Changed

| File | Change |
|------|--------|
| `lib/features/nutrition_plan/nutrition_plan_page.dart` | Add `_expandedBoundsIndices`, `_updateSlotBounds()`, bounds chip on each row, `_PortionBoundsPanel` widget |

No other files require changes.
