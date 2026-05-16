# Spec — MealDetailPage & BatchCookingPage
**Date:** 2026-05-16  
**Author:** Curtis — Fondateur Akeli  
**Approach:** A — Simple list layout, existing design tokens

---

## Scope

Two Flutter UI changes:

1. **MealDetailPage** — update the existing page to display meal components, real macros, and a working "Marquer comme consommé" button.
2. **BatchCookingPage** — new page listing cooking sessions for the active meal plan, with a FAB to create a new session.

Both pages are simple: no custom design system, use `AkeliColors` / `AkeliSpacing` / `AkeliRadius` tokens directly. No animations, no complex state.

---

## 1. MealDetailPage

### Data source
`activeMealPlanProvider` — already used. Entry is resolved by `mealId` param.  
`mealConsumptionProvider` — for the consume action.

### Layout
- `Scaffold` with standard `AppBar("Détail du repas")` and back button.
- `SingleChildScrollView` body.
- Image placeholder (emoji `🍽️`) in a coloured container — kept from current page.
- Title: `entry.recipeTitle ?? 'Repas'`
- Badges row: meal type label + "Consommé ✓" badge if `entry.isConsumed`.
- **Components section** (visible only when `entry.isModular`):
  - Section label "Composants"
  - Horizontal `Wrap` of small `Container` chips: `[icon] [title] · [role label]`
  - Role icons: base → `restaurant`, starch → `rice_bowl` (or `grain`), side → `eco`
  - "BATCH" label appended on the chip if `component.isBatch`
- **Macros section** — existing `AkeliMacroBadge` widgets, values from `entry.calories`, `entry.proteinG`, `entry.carbsG`, `entry.fatG` (now computed from components).
- **"Voir la recette" link** — only shown for the base component. Navigates to `/recipe/:recipeId` if `entry.recipeId != null`.
- **"Voir le batch cooking" link** — shown if any component `isBatch`. Navigates to `/batch-cooking`.
- **"Marquer comme consommé" button** — `ElevatedButton`, full-width, hidden if `entry.isConsumed`. Calls `mealConsumptionProvider.logConsumption(entry.id)`. Shows loading state while async. On error shows `SnackBar`.
- Remove hardcoded ingredients list and instructions string.

### Routing
No new route. `MealDetailPage` already registered at `/meal/:id`.

---

## 2. BatchCookingPage

### Data source
`cookingSessionsProvider` — fetches sessions for the active meal plan. Returns `List<CookingSession>`.  
`cookingSessionNotifierProvider` — for creating a new session.

### Layout
- `Scaffold` with `AppBar("Batch Cooking")`.
- `FutureProvider` `when()` — loading spinner, error text, data list.
- **Data: sessions list** — `ListView` of `_CookingSessionCard` (private widget in same file).
- **Empty state** — centered icon + "Aucune session cette semaine" text + subtitle "Appuyez sur + pour créer votre première session batch."
- **FAB** — `Icons.add`, `AkeliColors.primary`, opens `_CreateSessionSheet` bottom sheet.

### `_CookingSessionCard`
```
┌─────────────────────────────────────┐
│ [recipe image or emoji]  Recipe title
│                          date · N portions
│                          [progress bar] X/N utilisées
└─────────────────────────────────────┘
```
- White card, `BorderRadius.circular(AkeliRadius.card)`, light shadow.
- Left: 56×56 image from `session.recipeThumbnail` (or `🍲` emoji).
- Right: title, formatted date, `LinearProgressIndicator` for portions ratio.

### `_CreateSessionSheet` (bottom sheet)
Fields (all in a `Column` inside a `DraggableScrollableSheet` or simple `Padding`):
- Recipe name — `TextFormField` (free text for now, no autocomplete)
- Planned date — `TextButton` that opens `showDatePicker`
- Number of portions — `TextFormField` (numeric)
- Notes — `TextFormField` (optional, multiline)
- "Créer la session" `ElevatedButton` — calls `CookingSessionNotifier.create()`, closes sheet on success.

> **Note:** Recipe selection is free text in V1 since there's no recipe picker widget yet. The `recipe_id` field requires a UUID; for now the create button is disabled and shows "Bientôt disponible" until recipe picker is built. The card and empty state are fully functional.

### Route
New route `/batch-cooking` added to `AkeliRoutes` and `GoRouter`.  
Entry points:
1. `MealPlannerPage` — third navigation card "Batch Cooking" (after shopping list card).
2. `MealDetailPage` — "Voir le batch cooking" link (when any component `isBatch`).

---

## 3. Files to create / modify

| File | Action |
|---|---|
| `lib/features/meal_planner/meal_detail_page.dart` | Update |
| `lib/features/meal_planner/batch_cooking_page.dart` | Create |
| `lib/core/router.dart` | Add `/batch-cooking` route + import |
| `lib/features/meal_planner/meal_planner_page.dart` | Add third nav card |

---

## 4. Out of scope

- Recipe picker / autocomplete for session creation
- Editing or deleting existing sessions
- Linking a session to a specific meal plan entry component from UI (done via DB only for now)
- Any animation or page transition customisation
