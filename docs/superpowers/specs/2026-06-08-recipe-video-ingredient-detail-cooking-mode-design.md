# Recipe Video, Ingredient Detail Sheet & Cooking Mode — Design Spec

**Date:** 2026-06-08  
**Status:** Approved  

---

## Overview

Three self-contained features are added on top of the existing `RecipeDetailPage`:

1. **Recipe Video** — a video player card embedded in `RecipeDetailPage`
2. **Ingredient Detail Sheet** — a rich bottom sheet opened by tapping any ingredient
3. **Cooking Mode** — a full-screen guided step-by-step cooking experience

All three share the existing `Recipe` data loaded by `recipeDetailProvider`. No duplicate fetches.

---

## 1. Data Model Changes

### 1.1 `recipe` table
Add one nullable column:
```sql
ALTER TABLE recipe ADD COLUMN video_url TEXT NULL;
```

**Dart model** (`lib/shared/models/recipe.dart`): add `final String? videoUrl` to `Recipe`. Parsed from `json['video_url']`.

---

### 1.2 `recipe_step` table
Add two nullable columns:
```sql
ALTER TABLE recipe_step ADD COLUMN video_url TEXT NULL;
ALTER TABLE recipe_step ADD COLUMN ingredient_ids UUID[] NULL;
```

`ingredient_ids` is a Postgres array of ingredient IDs that tags which ingredients are used in this step. When null or empty, cooking mode falls back to showing all recipe ingredients.

**Dart model** (`lib/shared/models/recipe.dart`): `RecipeStep` gains:
- `final String? videoUrl`
- `final List<String> ingredientIds` (defaults to `[]` when null)

Parsed from `json['video_url']` and `(json['ingredient_ids'] as List?)?.cast<String>() ?? []`.

---

### 1.3 `ingredient` table
Add nullable nutritional and contextual columns:
```sql
ALTER TABLE ingredient
  ADD COLUMN calories_per_100g NUMERIC NULL,
  ADD COLUMN protein_g        NUMERIC NULL,
  ADD COLUMN carbs_g          NUMERIC NULL,
  ADD COLUMN fat_g            NUMERIC NULL,
  ADD COLUMN fiber_g          NUMERIC NULL,
  ADD COLUMN substitution     TEXT NULL,
  ADD COLUMN market_notes     TEXT NULL;
```

A new `IngredientDetail` Dart model is added at `lib/shared/models/ingredient_detail.dart`:
```dart
class IngredientDetail {
  final String id;
  final String name;
  final double? caloriesPer100g;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final String? substitution;   // nullable — only shown when non-null
  final String? marketNotes;    // nullable — only shown when non-null
}
```

New provider: `ingredientDetailProvider(String ingredientId)` in `lib/providers/ingredient_provider.dart`. Fetches the `ingredient` table row by ID. Called lazily — only when the sheet is opened, not during recipe load.

---

## 2. Recipe Video

### 2.1 Packages
Add to `pubspec.yaml`:
- `video_player`
- `chewie`

### 2.2 Widget: `RecipeVideoCard`
New file: `lib/shared/widgets/recipe_video_card.dart`

- `StatefulWidget` that takes `videoUrl` and `thumbnailUrl`
- Initialises `VideoPlayerController.networkUrl(uri)` in `initState`, disposes in `dispose`
- Renders a `Chewie` player in a `16:9` aspect ratio container
- Styled to match existing cards: `surfaceContainerLowest` background, `AkeliRadius.xl` border radius, standard box shadow
- Player initialises **paused** with `thumbnailUrl` as poster frame
- Auto-play is **off**
- Logging: `_logger.userAction` on play, pause, and seek events

### 2.3 Integration into `RecipeDetailPage`
In `_RecipeContent.build()`, insert `RecipeVideoCard` between the hero `PageView` and the `Transform.translate` meta card, guarded by `recipe.videoUrl != null`:
```dart
if (recipe.videoUrl != null)
  RecipeVideoCard(
    videoUrl: recipe.videoUrl!,
    thumbnailUrl: recipe.thumbnailUrl,
  ),
```

---

## 3. Ingredient Detail Sheet

### 3.1 Widget: `IngredientDetailSheet`
New file: `lib/features/recipes/widgets/ingredient_detail_sheet.dart`

- `ConsumerWidget`, opened via `showModalBottomSheet`
- Constructor takes `RecipeIngredient ingredient`

**Layout (top to bottom):**
1. Drag handle
2. Ingredient name — `plusJakartaSans` bold, large — with optional badge (`(opt.)`) if `ingredient.isOptional`
3. Quantity/unit pill — `accentAmber` background, e.g. `"200 g"`
4. Divider
5. `AsyncValue` from `ingredientDetailProvider(ingredient.ingredientId)`:
   - Loading → `CircularProgressIndicator`
   - Error → section hidden silently
   - Data:
     - **Nutrition card** — mini 5-column macro grid (`calories/100g`, `protéines`, `glucides`, `lipides`, `fibres`) using the `_MacroBox` style from `RecipeDetailPage`
     - **Substitution section** — rendered only when `detail.substitution != null`: amber-tinted container, swap icon, substitution text
     - **Market notes section** — rendered only when `detail.marketNotes != null`: green-tinted container, location pin icon, sourcing context text

### 3.2 Entry points
- **`RecipeDetailPage`**: each ingredient row in the ingredients section is wrapped in `InkWell`. On tap: `_logger.userAction('Ingredient tapped', screen: 'RecipeDetailPage')` then `showModalBottomSheet` with `IngredientDetailSheet`.
- **`CookingModePage`**: ingredient chips in the step view are tappable → same sheet.

---

## 4. Cooking Mode Page

### 4.1 Route
Nested under `/recipe/:id`:
```dart
GoRoute(
  path: AkeliRoutes.recipeDetail,   // /recipe/:id
  builder: RecipeDetailPage,
  routes: [
    GoRoute(
      path: 'cook',                  // /recipe/:id/cook
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CookingModePage(
          recipe: extra['recipe'] as Recipe,
          initialStepIndex: extra['initialStepIndex'] as int? ?? 0,
        );
      },
    ),
  ],
)
```

`AkeliRoutes` additions:
```dart
static const recipeCook = '/recipe/:id/cook';
static String recipeCookPath(String id) => '/recipe/$id/cook';
```

### 4.2 Widget: `CookingModePage`
New file: `lib/features/cooking/cooking_mode_page.dart`

**State:**
- `_currentStepIndex` (int)
- `_timerSeconds` (int) — initialised from `step.durationMin * 60` when step changes
- `_timerRunning` (bool)
- `_checkedIngredients` (Set\<String\>) — ingredientIds marked as checked

**Layout (top to bottom):**

1. **Top bar**
   - Step counter: `"Étape ${_currentStepIndex + 1} / ${recipe.steps.length}"`
   - Linear progress bar
   - Close button → `context.pop()`

2. **Instruction zone** (~50% of screen height)
   - `step.instruction` in `plusJakartaSans`, fontSize 22, height 1.5
   - Vertically centred, horizontally padded
   - Designed for hands-free reading

3. **Step media** (below instruction)
   - If `step.videoUrl != null`: compact `Chewie` player
   - Else if `step.imageUrl != null`: `CachedNetworkImage` in a 16:9 container
   - Hidden when neither exists

4. **Timer widget**
   - Shown only when `step.durationMin != null`
   - Circular countdown display
   - Tap to start/pause
   - On reaching zero: `HapticFeedback.mediumImpact()` + `ScaffoldMessenger` snackbar "Étape terminée !"
   - Does **not** auto-advance — user taps "Suivant" to move on (avoids skipping a step the user is still working on)

5. **Ingredient strip**
   - Horizontal `SingleChildScrollView` of ingredient chips
   - Source: `step.ingredientIds.isNotEmpty ? step.ingredientIds.map(...)` filtered from `recipe.ingredients`; fallback to all `recipe.ingredients`
   - Checked ingredients: `_checkedIngredients.contains(id)` → strikethrough text, muted color
   - Each chip tappable → `IngredientDetailSheet`; long-press → toggle checked state

6. **Navigation buttons**
   - "Précédent" (disabled on step 0) and "Suivant" / "Terminer" (on last step)
   - Swipe left/right via `GestureDetector` on the instruction zone also advances steps

### 4.3 Entry points from `RecipeDetailPage`

**"Start Cooking" CTA**: a secondary gradient button added to the meta card below the existing "Ajouter au plan repas" button:
```dart
onTap: () => context.push(
  AkeliRoutes.recipeCookPath(recipe.id),
  extra: {'recipe': recipe, 'initialStepIndex': 0},
),
```

**Step rows**: each step row in the steps section becomes an `InkWell`:
```dart
onTap: () => context.push(
  AkeliRoutes.recipeCookPath(recipe.id),
  extra: {'recipe': recipe, 'initialStepIndex': step.stepNumber - 1},
),
```

---

## 5. Logging

All new files follow the CLAUDE.md logging standard:
- `import 'package:akeli/core/logger.dart'`
- `final _logger = appLogger`
- Provider lifecycle, DB queries, user actions, and state transitions all logged
- Sensitive data masked via `LogHelper`

---

## 6. File Manifest

| File | Action |
|------|--------|
| `lib/shared/models/recipe.dart` | Modify — add `videoUrl` to `Recipe`, `videoUrl` + `ingredientIds` to `RecipeStep` |
| `lib/shared/models/ingredient_detail.dart` | Create — `IngredientDetail` model |
| `lib/providers/ingredient_provider.dart` | Create — `ingredientDetailProvider` |
| `lib/shared/widgets/recipe_video_card.dart` | Create — `RecipeVideoCard` widget |
| `lib/features/recipes/widgets/ingredient_detail_sheet.dart` | Create — `IngredientDetailSheet` |
| `lib/features/cooking/cooking_mode_page.dart` | Create — `CookingModePage` |
| `lib/features/recipes/recipe_detail_page.dart` | Modify — video card, "Start Cooking" CTA, tappable steps and ingredients |
| `lib/core/router.dart` | Modify — nested `/cook` route, `AkeliRoutes` constants |
| `pubspec.yaml` | Modify — add `video_player`, `chewie` |
| `supabase/migrations/YYYYMMDD_recipe_video_cooking_mode.sql` | Create — DB migrations |
