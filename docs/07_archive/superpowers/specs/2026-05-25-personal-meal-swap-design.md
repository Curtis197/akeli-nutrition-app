# Personal Meal Swap — Implementation Spec

**Date:** 2026-05-25
**Branch:** fix-compliance-and-router-issues-814be

---

## Problem

Users cannot log a meal they actually ate if it differs from their plan. The only existing swap flow (`swap_meal_plan_entry`) requires picking a recipe from the catalog. There is no way to record a custom meal (e.g. "poulet yassa maison + riz") and have its calories and macros tracked.

---

## Goals

- Let users replace any `meal_plan_entry` with a personal meal they describe in text or photograph
- AI (Gemini 1.5 Flash) analyzes the input and returns `meal_name`, `calories`, `protein_g`, `carbs_g`, `fat_g`
- Results are editable before saving (manual correction)
- The entry's shopping list ingredients are regenerated (old recipe ingredients removed)
- Display of the entry in `MealDetailPage` adapts to show the custom meal info

---

## Decisions Made

| Topic | Decision |
|-------|----------|
| AI provider for photos | Gemini 1.5 Flash Vision (`GEMINI_API_KEY` already provisioned) |
| Photo persistence | Base64 only — sent to AI, never stored in Supabase Storage |
| Entry points | `MealDetailPage` only |
| Shopping list | Regenerate after swap (removes old recipe ingredients) |

---

## Data Model

### `meal_plan_entry` — add 6 columns

```sql
ALTER TABLE meal_plan_entry
  ADD COLUMN custom_meal_name  text,
  ADD COLUMN custom_calories   numeric(7,1),
  ADD COLUMN custom_protein_g  numeric(6,1),
  ADD COLUMN custom_carbs_g    numeric(6,1),
  ADD COLUMN custom_fat_g      numeric(6,1),
  ADD COLUMN is_custom_meal    boolean NOT NULL DEFAULT false;
```

No new table. Custom macro data lives directly on the entry row.

When `is_custom_meal = true`:
- `meal_plan_entry_component` rows are **deleted** (entry has no recipe link)
- `custom_*` columns hold the AI-determined nutritional values
- `custom_meal_name` is the display title

When `is_custom_meal = false` (default):
- Existing macro derivation path is unchanged (`components → recipe_macro`)
- All `custom_*` columns are `NULL`

No RLS change needed — the entry inherits the existing policy (`meal_plan_id IN (SELECT id FROM meal_plan WHERE user_id = auth.uid())`).

---

## Migration File

**`supabase/migrations/20260525000008_personal_meal_entry.sql`**

```sql
-- =============================================================================
-- Migration: 20260525000008_personal_meal_entry.sql
-- Description: Add custom meal override columns + swap_meal_plan_entry_custom RPC
-- =============================================================================

-- 1. Add custom meal columns to meal_plan_entry
ALTER TABLE meal_plan_entry
  ADD COLUMN IF NOT EXISTS custom_meal_name  text,
  ADD COLUMN IF NOT EXISTS custom_calories   numeric(7,1),
  ADD COLUMN IF NOT EXISTS custom_protein_g  numeric(6,1),
  ADD COLUMN IF NOT EXISTS custom_carbs_g    numeric(6,1),
  ADD COLUMN IF NOT EXISTS custom_fat_g      numeric(6,1),
  ADD COLUMN IF NOT EXISTS is_custom_meal    boolean NOT NULL DEFAULT false;

-- 2. RPC: swap a meal plan entry for a custom (non-recipe) meal
CREATE OR REPLACE FUNCTION swap_meal_plan_entry_custom(
  p_entry_id    uuid,
  p_meal_name   text,
  p_calories    numeric,
  p_protein_g   numeric DEFAULT NULL,
  p_carbs_g     numeric DEFAULT NULL,
  p_fat_g       numeric DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id  uuid;
  v_plan_id  uuid;
BEGIN
  -- 1. Ownership check
  SELECT mp.user_id, mp.id
    INTO v_user_id, v_plan_id
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mpe.id = p_entry_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized or entry not found';
  END IF;

  -- 2. Remove existing recipe-backed components
  DELETE FROM meal_plan_entry_component
  WHERE meal_plan_entry_id = p_entry_id;

  -- 3. Write custom macro overrides onto the entry
  UPDATE meal_plan_entry SET
    is_custom_meal   = true,
    custom_meal_name = p_meal_name,
    custom_calories  = p_calories,
    custom_protein_g = p_protein_g,
    custom_carbs_g   = p_carbs_g,
    custom_fat_g     = p_fat_g
  WHERE id = p_entry_id;

  -- 4. Regenerate shopping list (removes old recipe ingredients)
  PERFORM generate_shopping_list(v_plan_id);
END;
$$;
```

---

## Edge Function `analyze-meal-photo`

**File:** `supabase/functions/analyze-meal-photo/index.ts`

### Input

```json
{
  "description": "poulet yassa + riz blanc",
  "image_base64": "<base64 string>",
  "image_mime_type": "image/jpeg"
}
```

At least one of `description` or `image_base64` is required.

### Output

```json
{
  "meal_name": "Poulet Yassa + Riz",
  "calories": 620,
  "protein_g": 42,
  "carbs_g": 68,
  "fat_g": 14,
  "confidence": "high"
}
```

### Gemini API call

- **Model:** `gemini-1.5-flash`
- **Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=GEMINI_API_KEY`
- Image sent as `inlineData` (`mimeType` + `data` = base64 string)
- Description sent as text `part`

### System prompt (embedded in function)

```
Tu es un expert en nutrition africaine et internationale.
Analyse le repas décrit ou photographié et retourne UNIQUEMENT un objet JSON valide.
Utilise des noms de repas en français.
Estime les valeurs pour UNE portion standard si la quantité n'est pas précisée.

Format attendu:
{
  "meal_name": string,
  "calories": number,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number,
  "confidence": "high" | "medium" | "low"
}

"confidence" = "high" si le repas est clairement identifiable, "medium" si tu estimes, "low" si incertain.
Retourne uniquement le JSON, sans markdown ni commentaires.
```

### Error cases

| Case | Response |
|------|----------|
| No description and no image | 400 `"description or image required"` |
| Gemini returns invalid JSON | 422 `"AI analysis failed — invalid response"` |
| Gemini API error | 500 `serverError(e)` |

---

## Flutter Model (`lib/shared/models/meal_plan.dart`)

### `MealPlanEntry` — add fields

```dart
final bool isCustomMeal;
final String? customMealName;
final double? customCalories;
final double? customProteinG;
final double? customCarbsG;
final double? customFatG;
```

### `MealPlanEntry.fromJson` — read new columns

```dart
isCustomMeal: (json['is_custom_meal'] as bool?) ?? false,
customMealName: json['custom_meal_name'] as String?,
customCalories: (json['custom_calories'] as num?)?.toDouble(),
customProteinG: (json['custom_protein_g'] as num?)?.toDouble(),
customCarbsG: (json['custom_carbs_g'] as num?)?.toDouble(),
customFatG: (json['custom_fat_g'] as num?)?.toDouble(),
```

### Updated computed getters

```dart
// Title — returns custom name if custom meal
String? get recipeTitle =>
    isCustomMeal ? customMealName : (_base?.recipeTitle);

// Macros — return custom values when custom meal, otherwise fold over components
double get calories => isCustomMeal
    ? (customCalories ?? 0.0)
    : components.fold(0.0, (s, c) => s + (c.calories ?? 0.0));

double get proteinG => isCustomMeal
    ? (customProteinG ?? 0.0)
    : components.fold(0.0, (s, c) => s + (c.proteinG ?? 0.0));

double get carbsG => isCustomMeal
    ? (customCarbsG ?? 0.0)
    : components.fold(0.0, (s, c) => s + (c.carbsG ?? 0.0));

double get fatG => isCustomMeal
    ? (customFatG ?? 0.0)
    : components.fold(0.0, (s, c) => s + (c.fatG ?? 0.0));
```

---

## Flutter Provider (`lib/providers/meal_plan_provider.dart`)

### 1. Update `activeMealPlanProvider` SELECT

```dart
// Add custom_* columns to the SELECT query:
'*, meal_plan_entry('
  '*, '
  'is_custom_meal, custom_meal_name, custom_calories, custom_protein_g, custom_carbs_g, custom_fat_g, '
  'meal_plan_entry_component(*, recipe(id, title, cover_image_url, recipe_macro(calories, protein_g, carbs_g, fat_g)))'
')'
```

> The new columns are on `meal_plan_entry` — the existing `*` wildcard already covers them. The SELECT string does not need to change if using `*`. Verify this matches the actual PostgREST response shape.

### 2. New `PersonalMealSwapNotifier`

**State shape:** `AsyncValue<MealAnalysisResult?>`

```dart
@immutable
class MealAnalysisResult {
  final String mealName;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String confidence; // 'high' | 'medium' | 'low'
}
```

**Methods:**

```dart
// Step 1 — AI analysis
Future<void> analyze({
  String? description,
  String? imageBase64,
  String? mimeType,
}) async { ... }

// Step 2 — Save to DB after user confirms
Future<void> save({
  required String entryId,
  required String mealName,
  required double calories,
  required double proteinG,
  required double carbsG,
  required double fatG,
}) async { ... }
```

**`analyze` implementation:**
```dart
state = const AsyncLoading();
final res = await client.functions.invoke('analyze-meal-photo', body: {
  if (description != null) 'description': description,
  if (imageBase64 != null) 'image_base64': imageBase64,
  if (mimeType != null) 'image_mime_type': mimeType,
});
final data = res.data as Map<String, dynamic>;
state = AsyncData(MealAnalysisResult.fromJson(data));
```

**`save` implementation:**
```dart
state = const AsyncLoading();
await client.rpc('swap_meal_plan_entry_custom', params: {
  'p_entry_id':   entryId,
  'p_meal_name':  mealName,
  'p_calories':   calories,
  'p_protein_g':  proteinG,
  'p_carbs_g':    carbsG,
  'p_fat_g':      fatG,
});
ref.invalidate(activeMealPlanProvider);
ref.invalidate(shoppingListProvider);
```

**Provider declaration:**
```dart
final personalMealSwapProvider =
    AsyncNotifierProvider.autoDispose<PersonalMealSwapNotifier, MealAnalysisResult?>(
        PersonalMealSwapNotifier.new);
```

---

## UI

### `PersonalMealBottomSheet` (`lib/features/meal_planner/personal_meal_bottom_sheet.dart`)

**Trigger:** called from `MealDetailPage` via `showModalBottomSheet`

**State machine:**

```
idle → analyzing → analyzed → saving → [pop + refresh]
                ↓ error
              idle (snackbar shown)
```

**Layout:**

```
DraggableScrollableSheet
└── Column
    ├── Handle bar
    ├── Header: "Saisir un repas personnel"
    ├── Input tabs: [Description] [Photo]
    │
    │   — Description tab —
    │   TextFormField (multiline)
    │   "Ex: Poulet yassa + riz, portion normale"
    │
    │   — Photo tab —
    │   Row: [📷 Caméra] [🖼️ Galerie]
    │   Image preview (if selected)
    │
    ├── ElevatedButton "Analyser avec l'IA"  ← disabled if no input, shows loading
    │
    ├── — Result card (visible after analysis) —
    │   TextFormField: meal name (editable)
    │   Row: [Calories] [Protéines] [Glucides] [Lipides]  ← each editable
    │   Confidence chip: ✓ Élevée / ~ Moyenne / ? Faible
    │
    └── ElevatedButton "Confirmer ce repas"  ← disabled until analyzed, shows loading
```

**Image handling:**
```dart
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

final picker = ImagePicker();
final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
final bytes = await file.readAsBytes();
final base64 = base64Encode(bytes);
final mimeType = 'image/jpeg';
```

**Confidence chip colors:**
- `high` → green (`AkeliColors.primary`)
- `medium` → amber (`AkeliColors.accentAmber`)
- `low` → red (`AkeliColors.error`)

### `MealDetailPage` — changes

**1. New CTA button** (between "Changer ce repas" and "Marquer comme consommé"):

```dart
if (!entry.isConsumed && !entry.isCustomMeal)
  SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PersonalMealBottomSheet(entryId: entry.id),
      ),
      child: const Text('Saisir un repas personnel'),
    ),
  ),
```

**2. Custom meal badge** (in the header `Wrap`):

```dart
if (entry.isCustomMeal)
  _Badge(
    label: 'Repas personnalisé',
    backgroundColor: AkeliColors.accentAmber.withValues(alpha: 0.15),
    textColor: AkeliColors.accentAmber,
  ),
```

**3. Hide "Voir la recette" for custom meals:**

```dart
if (entry.recipeId != null && !entry.isCustomMeal)
  // ... existing button
```

**4. Hide "Changer ce repas" for custom meals** (or keep it — the user can still swap to a recipe):

> Recommendation: keep it visible so users can revert to a recipe-backed meal. The RPC handles the transition.

---

## Files Summary

| File | Action | Notes |
|------|--------|-------|
| `supabase/migrations/20260525000008_personal_meal_entry.sql` | **Create** | 6 new columns + `swap_meal_plan_entry_custom` RPC |
| `supabase/functions/analyze-meal-photo/index.ts` | **Create** | Gemini Vision edge function |
| `lib/shared/models/meal_plan.dart` | **Modify** | 6 new fields, updated computed getters |
| `lib/providers/meal_plan_provider.dart` | **Modify** | `PersonalMealSwapNotifier` + `personalMealSwapProvider` |
| `lib/features/meal_planner/personal_meal_bottom_sheet.dart` | **Create** | Full UI flow |
| `lib/features/meal_planner/meal_detail_page.dart` | **Modify** | New CTA, custom badge, conditional buttons |

---

## Verification Checklist

- [ ] `supabase db push` applies `20260525000008` without errors
- [ ] Text-only analysis: describe "riz + haricots verts" → AI returns plausible JSON
- [ ] Photo analysis: upload a photo of food → AI identifies and returns macros
- [ ] Invalid input (no text, no photo) → 400 error shown in snackbar
- [ ] Low-confidence result → amber chip, user can manually edit macros before saving
- [ ] Save: `meal_plan_entry` row has `is_custom_meal = true` and `custom_*` values
- [ ] Save: `meal_plan_entry_component` rows deleted for the swapped entry
- [ ] Shopping list regenerated: old recipe ingredients removed
- [ ] `MealDetailPage`: custom entry shows "Repas personnalisé" badge + `customMealName` as title
- [ ] `MealDetailPage`: "Voir la recette" button hidden for custom meals
- [ ] RLS: user cannot call `swap_meal_plan_entry_custom` on another user's entry
- [ ] "Marquer comme consommé" still works after a custom swap
- [ ] Re-opening `MealDetailPage` after swap shows updated macros from the entry
