# Batch Cooking Calorie Adaptation — Design Spec

**Date:** 2026-05-25
**Branch:** fix-compliance-and-router-issues-814be

---

## Problem

Batch cooking sessions exist in the schema but are disconnected from the user's calorie goal. `cooking_session.total_portions` is set manually with no nutritional awareness, the creation UI is disabled ("coming soon"), and the shopping list excludes batch components entirely — leaving ingredient quantities uncalculated.

---

## Goals

- Auto-generate batch cooking sessions whenever a recipe appears 2+ times in a generated meal plan
- Scale ingredient quantities to the user's actual calorie-adjusted servings: `quantity × (total_portions / recipe.servings)`
- Store scaled ingredient quantities in a `cooking_session_ingredient` table for fast reads
- Merge batch ingredient quantities into the regular shopping list
- Remove the dead "coming soon" creation button; sessions are fully plan-managed
- On plan regeneration: delete all existing sessions and recreate from scratch

---

## Data Model

### `cooking_session` — add one column

| Column | Type | Notes |
|--------|------|-------|
| `scale_factor` | NUMERIC | `total_portions_needed / recipe.servings` — stored for reference |

All other existing columns unchanged: `id`, `user_id`, `meal_plan_id`, `recipe_id`, `planned_date`, `total_portions`, `portions_used`, `notes`.

### New `cooking_session_ingredient`

One row per ingredient per session. Quantities are pre-computed at session creation time.

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `cooking_session_id` | UUID FK → `cooking_session` CASCADE | |
| `ingredient_id` | UUID FK → `ingredient` | |
| `ingredient_name` | TEXT | denormalized — avoids join on display |
| `quantity_needed` | NUMERIC | `recipe_ingredient.quantity × scale_factor` |
| `unit` | TEXT | |
| `created_at` | TIMESTAMPTZ | |

**RLS:** owner via `cooking_session.user_id`.
**Index:** `cooking_session_ingredient(cooking_session_id)`.

### `meal_plan_entry_component.cooking_session_id`

Already exists as a nullable FK. The new RPC sets it after creating sessions. Must be `ON DELETE SET NULL` so deleting sessions cleanly unlinks components.

---

## `create_batch_sessions()` RPC

```sql
create_batch_sessions(p_meal_plan_id UUID, p_user_id UUID)
RETURNS void
SECURITY DEFINER
LANGUAGE plpgsql
```

### Steps

**1. Delete existing sessions**
```sql
DELETE FROM cooking_session
WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;
-- CASCADE deletes cooking_session_ingredient rows
-- ON DELETE SET NULL unlinks meal_plan_entry_component.cooking_session_id
```

**2. Find repeated recipes (2+ appearances)**
```sql
SELECT mpec.recipe_id,
       COUNT(*)           AS appearance_count,
       SUM(mpe.servings)  AS total_portions_needed
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
WHERE mpe.meal_plan_id = p_meal_plan_id
GROUP BY mpec.recipe_id
HAVING COUNT(*) >= 2
```

**3. For each repeated recipe**
```sql
-- Fetch base recipe servings
SELECT servings INTO v_recipe_servings FROM recipe WHERE id = v_recipe_id;

v_scale_factor := v_total_portions_needed / GREATEST(v_recipe_servings, 1);

-- Create cooking session
INSERT INTO cooking_session (user_id, meal_plan_id, recipe_id, total_portions, scale_factor, planned_date)
VALUES (p_user_id, p_meal_plan_id, v_recipe_id, v_total_portions_needed, v_scale_factor, CURRENT_DATE)
RETURNING id INTO v_session_id;

-- Create scaled ingredient rows
INSERT INTO cooking_session_ingredient
  (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
SELECT
  v_session_id,
  ri.ingredient_id,
  i.name,
  ri.quantity * v_scale_factor,
  ri.unit
FROM recipe_ingredient ri
JOIN ingredient i ON i.id = ri.ingredient_id
WHERE ri.recipe_id = v_recipe_id;
```

**4. Link components back**
```sql
UPDATE meal_plan_entry_component mpec
SET cooking_session_id = v_session_id
FROM meal_plan_entry mpe
WHERE mpec.meal_plan_entry_id = mpe.id
  AND mpe.meal_plan_id = p_meal_plan_id
  AND mpec.recipe_id = v_recipe_id;
```

---

## Shopping List Update (`generate_shopping_list()`)

Replace the current `cooking_session_id IS NULL` exclusion with a UNION that pulls from `cooking_session_ingredient`:

```sql
-- Regular items (non-batch components)
SELECT ri.ingredient_id, i.name, SUM(ri.quantity * mpe.servings) AS total_qty, ri.unit
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
JOIN recipe_ingredient ri ON ri.recipe_id = mpec.recipe_id
JOIN ingredient i ON i.id = ri.ingredient_id
WHERE mpe.meal_plan_id = p_meal_plan_id
  AND mpec.cooking_session_id IS NULL
GROUP BY ri.ingredient_id, i.name, ri.unit

UNION ALL

-- Batch items (pre-computed from session ingredients)
SELECT csi.ingredient_id, csi.ingredient_name, SUM(csi.quantity_needed), csi.unit
FROM cooking_session_ingredient csi
JOIN cooking_session cs ON cs.id = csi.cooking_session_id
WHERE cs.meal_plan_id = p_meal_plan_id
GROUP BY csi.ingredient_id, csi.ingredient_name, csi.unit
```

The Flutter `ShoppingListProvider` needs no changes — same result shape.

---

## Flutter Architecture

### New / modified files

| File | Change |
|------|--------|
| `lib/shared/models/meal_plan.dart` | Add `scaleFactor` to `CookingSession`; add `CookingSessionIngredient` data class; add `ingredients` list to `CookingSession` |
| `lib/providers/meal_plan_provider.dart` | `MealPlanGeneratorNotifier.generate()` calls `create_batch_sessions()` after `generate_meal_plan()` succeeds |
| `lib/providers/meal_plan_provider.dart` | `cookingSessionsProvider` SELECT includes `cooking_session_ingredient(*)` nested |
| `lib/features/meal_planner/batch_cooking_page.dart` | Remove "coming soon" creation button; session cards show scaled ingredient list |

### `MealPlanGeneratorNotifier.generate()` flow

```dart
// 1. Call generate_meal_plan()
final entries = await client.rpc('generate_meal_plan', params: {...});
final mealPlanId = entries.first['meal_plan_id'];

// 2. Immediately call create_batch_sessions()
await client.rpc('create_batch_sessions', params: {
  'p_meal_plan_id': mealPlanId,
  'p_user_id': user.id,
});

// 3. Invalidate providers
ref.invalidate(activeMealPlanProvider);
ref.invalidate(cookingSessionsProvider);
```

Both calls are inside the same try/catch — a batch session failure surfaces to the user rather than silently failing.

### `BatchCookingPage` session card

Each session card displays:
- Recipe title + planned date
- Total portions + portions used (existing progress bar)
- Expanded ingredient list: `ingredient_name — quantity_needed unit`
  - e.g. "Poulet — 560 g", "Riz — 280 g"

No creation or editing UI. Sessions are read-only and fully plan-managed.

---

## Migration Files

| File | Purpose |
|------|---------|
| `20260525000005_cooking_session_ingredient.sql` | Add `scale_factor` to `cooking_session`; create `cooking_session_ingredient` table, RLS, index; ensure `meal_plan_entry_component.cooking_session_id` is `ON DELETE SET NULL` |
| `20260525000006_create_batch_sessions_rpc.sql` | Create `create_batch_sessions()` function |
| `20260525000007_patch_shopping_list.sql` | Rewrite `generate_shopping_list()` with UNION for batch items |

---

## Ingredient Scaling Formula

```
scale_factor         = total_portions_needed / recipe.servings
total_portions_needed = SUM(meal_plan_entry.servings) for all entries using this recipe
quantity_needed      = recipe_ingredient.quantity × scale_factor
```

**Example:**
- Recipe: 4 servings × 250 kcal = written for 1000 kcal total
- User needs: 2 meal plan entries, each at 1.4 servings (350 kcal target / 250 kcal per serving)
- `total_portions_needed = 1.4 + 1.4 = 2.8`
- `scale_factor = 2.8 / 4 = 0.7`
- Ingredient "Poulet 800g" → `800 × 0.7 = 560g needed`

---

## Verification Checklist

- [ ] `supabase db push` applies all 3 migrations without errors
- [ ] Generate a 7-day plan where one recipe appears 3 times and another appears once — only the 3-time recipe gets a session
- [ ] `cooking_session.total_portions` equals sum of `meal_plan_entry.servings` for the recipe
- [ ] `cooking_session_ingredient.quantity_needed` matches `recipe_ingredient.quantity × scale_factor`
- [ ] All `meal_plan_entry_component` rows for that recipe have `cooking_session_id` set
- [ ] Shopping list includes batch ingredient quantities merged with regular items — no duplicates
- [ ] Regenerating the plan deletes old sessions and creates fresh ones
- [ ] Batch cooking page shows ingredient list per session, no creation button
- [ ] RLS: user cannot read another user's `cooking_session_ingredient` rows
