# Walkthrough: Meal Plan Generation — Full System

## Overview

The meal plan system generates a personalized 7-day plan (configurable) for a user based on cultural similarity, macro alignment, and meal slot preferences. It creates batch cooking sessions for repeated recipes and builds a shopping list. Users control batch cooking behavior from onboarding and from Settings > Préférences.

---

## Architecture

```
Flutter app
  └─ invokes edge function: generate-meal-plan
        └─ calls RPC: generate_meal_plan(p_user_id, p_days, p_meals_per_day, p_start_date)
              └─ selects recipes using weighted scoring
              └─ inserts: meal_plan, meal_plan_entry, meal_plan_entry_component, meal_ingredient
        └─ fetches user_profile.batch_cooking_enabled
        └─ if enabled: calls RPC: create_batch_sessions(p_meal_plan_id, p_user_id, p_max_portions)
              └─ inserts: cooking_session, cooking_session_ingredient
              └─ updates: meal_plan_entry_component.cooking_session_id
        └─ returns: meal_plan_id
```

---

## Schema Changes (chronological)

### meal_types array on recipe (migration 20260524000005)
Added `meal_types TEXT[]` to `recipe`. Used in the candidate WHERE clause:
```sql
AND v_meal_type = ANY(r.meal_types)
```

### meal_plan_entry column fix (migration 20260529000004)
Live DB had `date` instead of `scheduled_date` and `servings integer` instead of `numeric(4,1)`. Fixed:
```sql
ALTER TABLE public.meal_plan_entry RENAME COLUMN date TO scheduled_date;
ALTER TABLE public.meal_plan_entry ALTER COLUMN servings TYPE numeric(4,1) USING servings::numeric(4,1);
```

### preferred_meal_type on recipe (migration 20260529000005)
Soft meal slot preference for scoring. Default `'any'` keeps all existing recipes valid:
```sql
ALTER TABLE public.recipe
  ADD COLUMN IF NOT EXISTS preferred_meal_type text NOT NULL DEFAULT 'any'
  CHECK (preferred_meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'any'));
```

### Recipe tagging (migration 20260529000006)
14 live recipes tagged: 2 breakfast (Fondé, Pap en Vleis), 6 lunch, 6 dinner. All others remain `'any'`.

### batch_cooking_max_portions on user_profile (migration 20260529000009)
```sql
ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS batch_cooking_max_portions int NOT NULL DEFAULT 4
  CHECK (batch_cooking_max_portions BETWEEN 2 AND 7);
```

---

## Weighted Scoring Formula (migration 20260529000008)

The `generate_meal_plan` RPC v2 replaces plain `ORDER BY similarity DESC` with a 4-component score:

```sql
0.50 × cultural similarity (fan 1.5× bonus preserved)
+ 0.25 × protein density alignment
+ 0.15 × meal slot preference (preferred_meal_type)
+ 0.10 × fat density alignment
```

**Target macro densities** are pre-computed once before the day loop from the user's `user_goal`:
```
target_protein_density = protein_goal / (calorie_goal / meals_per_day) * 100
target_fat_density     = fat_goal     / (calorie_goal / meals_per_day) * 100
```
Sensible defaults apply when no goal exists: 7.5g P / 100 kcal, 3.3g F / 100 kcal.

**Slot match values:**
- `preferred_meal_type = slot` → 1.0
- `preferred_meal_type = 'any'` → 0.5
- mismatch → 0.0

The score is a relative ranking value — not normalized to 0–1 (fan bonus can push above 1.0). The `similarity` column in the RPC response returns this composite score.

**Security:** SECURITY DEFINER + `SET search_path = public, pg_temp` + `auth.uid()` caller guard + `REVOKE ALL / GRANT TO authenticated`.

---

## create_batch_sessions (migrations 20260529000007, 20260529000010)

Creates batch cooking sessions for recipes appearing ≥ 2 times as base components, up to `p_max_portions` uses. Recipes appearing more times than the user's max are not batched (too many portions for one session).

Each session gets:
- `cooking_session` row: `scale_factor`, `total_portions`, `planned_date` (first appearance)
- `cooking_session_ingredient` rows: scaled quantities for all non-optional ingredients
- `meal_plan_entry_component.cooking_session_id` updated: links entries to session (used by shopping list to avoid double-counting)

The function uses `DELETE ... WHERE meal_plan_id = ...` at the start — re-generation is idempotent.

---

## generate-meal-plan Edge Function

Step 3.5 (added in this session): before calling `create_batch_sessions`, fetch user preferences:

```typescript
const { data: profileData } = await client
  .from("user_profile")
  .select("batch_cooking_enabled, batch_cooking_max_portions")
  .eq("id", user.id)
  .single();

const batchEnabled = profileData?.batch_cooking_enabled ?? false;
const maxPortions  = profileData?.batch_cooking_max_portions ?? 4;

if (batchEnabled) {
  await client.rpc("create_batch_sessions", {
    p_meal_plan_id: mealPlanId,
    p_user_id: user.id,
    p_max_portions: maxPortions,
  });
}
```

Fetch failure is non-fatal — logged as warn, execution continues without batching.

---

## generate_shopping_list (migration patch_shopping_list_skip_null_ingredients)

Patched to filter out `recipe_ingredient` rows with null `ingredient_id` or null `quantity` (data quality issue in some recipes). Two-path aggregation:

1. **Regular path** (`cooking_session_id IS NULL`): sums `quantity * servings` per ingredient
2. **Batch path**: reads pre-scaled quantities from `cooking_session_ingredient`

The union prevents double-counting because batched components have `cooking_session_id` set.

---

## User-Controlled Batch Cooking Preferences

### Onboarding (Goals step)
After the cooking time radio, a new card appears:
- Toggle: "Préparer plusieurs repas à la fois"
- When ON: dropdown "Portions max par session" (2–7, default 4)

Submitted via `complete-onboarding` edge function → saved to `user_profile`.

### Settings > Préférences page
New page at `/preferences` consolidating:
- **Cuisson**: cooking time (quick/medium/any) + batch cooking toggle + portions dropdown
- **Région culinaire**: single-select region chips
- **Restrictions alimentaires**: no-pork / no-meat / no-gluten / no-lactose toggles + allergies chips (read-only)

Saves all at once via `UserPreferencesNotifier.save()` — sequential writes to 4 tables (`user_health_profile`, `user_profile`, `user_cuisine_preference`, `user_dietary_restriction`).

---

## Live Test Results (user c70fdca2, 2026-05-29)

**User profile:** 180cm / 100kg male, target 90kg, light activity, calorie goal 1852 kcal, protein 138.9g, fat 61.7g.

**7-day plan (3 meals/day = 21 entries):**
- ✅ 0 rows with same recipe in all 3 slots of a day (Issue 1 fixed)
- ✅ Fondé (breakfast-tagged) appears only in breakfast slots
- ✅ Protein tracking: consistently above target (over-shoot expected — catalog is protein-rich)
- ✅ 21 entries returned, all macros computed

**Batch sessions (14 sessions from 14-day test plan):**
- All sessions have `scale_factor`, ingredient rows, and component links
- `cooking_session_ingredient` populated with scaled quantities

**Shopping list:**
- 63 line items, deduplicated across batch and regular paths
- Categorized: condiment, dairy, dried_fish, fat, fish, herb, legume, liquid, nut, protein, spice, starch, vegetable

---

## Known Data Quality Issues

- **Soupe du Pêcheur — Atiéké** and **Bouillon de Pieds de Porc — Riz Blanc**: 2 `recipe_ingredient` rows each with null `ingredient_id` / null `quantity`. These are skipped by `generate_shopping_list` (`ri.ingredient_id IS NOT NULL AND ri.quantity IS NOT NULL`). Fix on the website when the recipes are edited.
- **Mixed units**: some ingredients (Oignon, Tomate, Sel) appear in multiple rows with different units (g vs piece vs unit). The shopping list correctly preserves separate rows rather than aggregating incompatible units. Fix by standardizing units in recipe data.
- **Calorie scaling**: users without numeric calorie goals get `servings = 1.0` (full recipe yield). This can produce very high per-meal calorie counts for batch-sized recipes. Resolves automatically once macro goals are set.
