# Meal Plan Generator — Philosophy & Challenges

**Last updated:** 2026-05-28
**Status:** Living document — updated as design decisions evolve

---

## 1. Core Philosophy

### The Recipe Is the Atomic Unit

Every recipe on Akeli is a **complete, ready-to-eat dish** created and published by a creator. There are no modular components (base + starch + side). The creator is responsible for the full composition of the dish — the platform does not decompose or recombine recipes.

### Portions Drive the Plan, Not the Other Way Around

A recipe has a natural **portion count** (how many servings it yields when cooked). When a recipe is selected for a meal plan, it appears as **one entry per portion consumed during the week**. A recipe with 3 portions = 3 meal plan entries, each representing one consumption moment.

This means:
- Batch cooking is a natural consequence: if a recipe appears 3 times, the user cooks it once and uses 3 portions.
- The meal plan is a schedule of **consumption moments**, not a cooking schedule.

### Calorie Targets Drive Serving Size

The user's daily calorie goal determines how much of a recipe they consume per entry. If a recipe yields 300 kcal per standard portion and the user needs 400 kcal per meal, the serving is scaled to 1.33 — meaning the user eats 1.33x the base portion. This scaling propagates to:
- **Displayed macros** (calories, protein, carbs, fat must reflect the scaled serving)
- **Shopping list** (ingredient quantities multiplied by the scale factor)
- **Batch cooking** (total ingredients for all portions scaled accordingly)

### Variety Is a First-Class Constraint

A meal plan that serves the same recipe every day fails the user. The generator enforces variety through deduplication: a recipe is not selected again once it has been used. When the recipe pool is exhausted for a given meal type, deduplication resets and repeats become allowed — but this is a last resort, not an intended state.

---

## 2. Data Model

```
meal_plan
  └─ meal_plan_entry (one per consumption moment)
       ├─ meal_type: breakfast | lunch | dinner | snack
       ├─ scheduled_date
       ├─ servings: numeric (scaling factor relative to recipe base portion)
       └─ meal_plan_entry_component (always exactly ONE — the complete recipe)
            └─ recipe_id, role='base'

cooking_session (one per repeated recipe, auto-created after generation)
  ├─ recipe_id
  ├─ total_portions (sum of servings across all entries for this recipe)
  ├─ scale_factor (total_portions / recipe.servings)
  └─ cooking_session_ingredient (ingredient × scale_factor)

shopping_list
  └─ shopping_list_item
       └─ quantity = ingredient.quantity × mpe.servings (regular)
                   = csi.quantity_needed (batch)
```

---

## 3. Architecture Principle — Edge Functions vs. RPCs

**Edge functions** are the orchestration layer. They handle multi-step flows that involve several DB operations, external calls, or business logic that must run as a coordinated batch. Examples: generate plan, swap entry (which must update the entry AND recalculate shopping list AND recalculate batch sessions atomically from the user's perspective).

**RPCs** are the atomic DB layer. They perform a single well-defined database operation: fetch top-20 candidates, insert an entry, update a component, generate a shopping list. They are called by edge functions, never chained by the Flutter app directly for complex flows.

**Flutter app** calls edge functions for user-initiated actions. It calls RPCs directly only for simple reads or single-row mutations where no orchestration is needed.

---

## 4. Generation Algorithm

### Step 1 — User Vector Lookup
The user's 50-dimensional preference vector is loaded from `user_vector`. If absent, the fallback is most-liked recipes (popularity ranking).

### Step 2 — Calorie Goal Lookup
The user's active calorie goal is fetched from `user_goal`. Target calories per meal = `calorie_goal / meals_per_day`. If absent, servings default to 1.0 (base portion).// each meal_type has a calorie goal. gathered at the onboarding

### Step 3 — Recipe Selection (per day × per meal type)
For each slot (day + meal type), the algorithm:
1. Filters recipes to those tagged with the current meal type
2. Excludes already-used recipes (`v_used_recipe_ids`) and recipes that have hit the 3-entry cap
3. Ranks by cosine similarity to the user vector, with a 1.5x boost for the subscribed creator's recipes
4. Fetches the **top 20 candidates** and selects the best available one
5. Calculates `servings = calorie_target / recipe.calories` (rounded to 1 decimal, min 0.1)
6. Inserts `meal_plan_entry` + `meal_plan_entry_component`
//if there is a fan subscription 90% of the recipe must come from the creator 
// all recipe should be fetch once the top 10-20 best fitting recipe should serve for the meal_plan. We might evaluate the user to set the variance/recipe per meal plan
### User Entry Actions

Once a plan is generated, an entry is **permanent** — it cannot be deleted. The user has two actions:
1. **Swap for a recipe** — replace with a different recipe from the catalogue (`swap_meal_plan_entry` RPC)
2. **Swap for a personal meal** — replace with a custom meal analyzed via AI photo (`swap_meal_plan_entry_custom` RPC)

In both cases the shopping list recalculates automatically after the swap.

### Step 4 — Batch Session Creation
After all entries are created, `create_batch_sessions` groups entries by recipe, sums their servings, and creates a `cooking_session` with scaled ingredient quantities for recipes appearing 2+ times.

### Step 5 — Shopping List Generation
`generate_shopping_list` aggregates ingredients from:
- Non-batch entries: `ingredient.quantity × entry.servings`
- Batch entries: pre-computed `cooking_session_ingredient.quantity_needed`

---

## 5. Known Challenges

### 4.1 Portion Count vs. Plan Diversity (CRITICAL)

**Problem:** If the most-aligned recipe has 8 portions, it would claim 8 entries in a 7-day, 3-meal plan (21 total entries). A single recipe consuming 38% of the plan defeats variety.

**Decision:** Hard cap of **3 entries per recipe per plan**. The generator must not select a recipe more than 3 times, regardless of its portion count.

**Future consideration:** Allow the user to configure the max portion cap per recipe (e.g., "I want to batch cook max 5 times this week"). Evaluate after launch.

**Implementation:** The RPC fetches the top 20 candidates per slot (LIMIT 20 ordered by similarity score) and iterates to find the first that hasn't hit the cap. Because the catalogue is expected to have 20+ recipes per meal type, this edge case has a low probability of being reached. If all top-20 candidates are capped, the slot is skipped and a warning is surfaced.

**Tracking:** A `v_recipe_use_count` map (recipe_id → count) replaces the current boolean `v_used_recipe_ids` array. A recipe is excluded when its count reaches 3.

---

### 4.2 Macro Display Bug (CRITICAL)

**Problem:** `MealPlanEntry.calories` (and protein, carbs, fat) in the Dart model sums raw component macros without multiplying by `servings`. A recipe with 300 kcal and servings=1.33 displays 300 kcal instead of 400 kcal.

**Fix required:** All macro getters in `MealPlanEntry` must multiply the component sum by `servings`.

**Also:** The `generate_meal_plan` RETURN QUERY returns unscaled `v_recipe.calories` — must return `v_recipe.calories * v_servings` for any downstream consumers that use the RPC directly.
// the omputation must stay in the backend with sql and stired in a meal_ingredient table. the meal_detail or the batch_detail show only the meal ingredient. 
---

### 4.3 Silent Slot Failures (HIGH)

**Problem:** When no recipe is found for a meal slot (no recipes tagged with the required meal type, or all matching recipes exhausted), the RPC issues a `CONTINUE` — the entry is silently skipped. The user receives a plan with fewer entries than expected, with no error or warning.

**Fix required:**
- Count expected vs. actual entries in the edge function after generation
- If entries < `p_days × p_meals_per_day`, return a structured warning to the Flutter app
- The UI must surface this: "Your plan has gaps — not enough recipes for [meal type]"
// we must be sure each meal have a recipe it is better to have no plan at all.
---

### 4.4 Recipe Pool Exhaustion (MEDIUM)

**Problem:** If the recipe catalogue has fewer unique recipes for a meal type than the number of plan days, the deduplication list resets and repeats begin. There is no user feedback, and the repeat threshold is invisible.

**Current behaviour:** `v_used_recipe_ids` resets to `ARRAY[]` when no recipe is found (after exclusion). This can cause the same recipe to appear repeatedly if the pool is small.

**Mitigation at launch:** Ensure sufficient recipe coverage per meal type before enabling plan generation for users (recipe catalogue health check). Long-term: surface a "limited variety" warning when repeats occur.

---

### 4.5 Data Gaps (MEDIUM)

| Gap | Current behaviour | Risk |
|-----|------------------|------|
| No `user_vector` | Falls back to most-liked recipes | Silent quality degradation |
| No calorie goal | `servings = 1.0` for all entries | User doesn't hit calorie targets |
| Recipe with no `recipe_macro` | `servings = 1.0`, macros display as 0 kcal | Broken-looking cards |
| Recipe with no `meal_types` | Never selected for any slot | Creator recipes invisible to generator |

**Fix required:** All four gaps should be detected and surfaced — either at plan generation time or at recipe publish time.

---

### 4.6 Serving Scale Upper Bound (LOW)

**Problem:** If a recipe has very few calories (e.g., 50 kcal) and the user target is 600 kcal, `v_servings = 12.0`. This means 12x the base portion — unrealistic for a single meal. The current minimum bound is 0.1 but there is no maximum bound.

**Fix required:** Cap `v_servings` at a sensible maximum (e.g., 4.0) and prefer selecting a different recipe when the scale factor would exceed the cap.

---

## 6. Batch Cooking Relationship

Batch cooking is a **derived output** of the plan, not a planning input. The user does not configure batch cooking — it is auto-created when a recipe appears 2 or more times in the plan.

The `cooking_session` stores:
- `total_portions`: sum of `servings` across all entries for this recipe (accounts for calorie scaling)
- `scale_factor`: total_portions / recipe.servings (how much to multiply base ingredient quantities)
- Pre-computed ingredient quantities in `cooking_session_ingredient`

When an entry is removed, batch sessions must be recalculated. If a recipe drops from 2 entries to 1, its cooking session is deleted and that recipe's ingredients revert to the regular shopping list path.

---

## 7. Design Constraints for Launch

| Constraint | Value | Rationale |
|-----------|-------|-----------|
| Max entries per recipe per plan | 3 | Prevents one recipe dominating the week |
| Max serving scale factor | 4.0 | Prevents unrealistic portion sizes |
| Min serving scale factor | 0.1 | Already enforced |
| Meals per day options | 2, 3, or 4 | 2=lunch+dinner, 3=standard, 4=+snack |
| Plan duration | 7 days (default) | One week; configurable |
| Batch session threshold | 2+ appearances | Only batch-cook repeated recipes |

---

## 8. Open Questions (Post-Launch)

- Should users be able to set a custom max-portions-per-recipe cap? (e.g., "I want to batch cook max 5 Jollof Rice this week")
// to complex for the moment
- Should the generator respect user-defined cooking days? (e.g., "I only cook on Sunday and Wednesday")
//We'll let the user decide its cooking day no day attributed
- Should swapping a recipe entry trigger a full batch/shopping recalculation or just a delta update?
// full calculation
- How do we handle recipes that span multiple meal types? (e.g., a dish tagged both lunch and dinner)
// the recipe has 2 meal_entry one at lunch 400kcal and one at dinner 300kcal. We set the ingredient for 700kcal. if the recipe is made for 800kcal to total the ingredient are x7/8.