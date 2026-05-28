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

### Per-Meal Calorie Targets Drive Serving Size

Each meal type (breakfast, lunch, dinner, snack) has its own calorie target, set during onboarding and stored in `user_goal`. The generator uses the target for each specific meal type — not a flat `total / meals_per_day` division. If a recipe yields 300 kcal per standard portion and the lunch target is 400 kcal, the serving is scaled to 1.33. This scaling propagates to:
- **Displayed macros** (calories, protein, carbs, fat reflect the scaled serving)
- **Shopping list** (ingredient quantities multiplied by the scale factor)
- **Batch cooking** (total ingredients for all portions scaled accordingly)

Macro computation stays in the backend — stored in a `meal_ingredient` table after generation. The Flutter app reads pre-computed values; it never calculates macros from raw recipe data at display time.

### Variety Is a First-Class Constraint

A meal plan that serves the same recipe every day fails the user. The generator enforces variety through a hard cap: **no recipe may appear more than 3 times per plan**. A `v_recipe_use_count` map tracks how many times each recipe has been selected. When the cap is reached, the recipe is excluded from further selection.

### Fan Subscription Shapes the Recipe Pool

When a user has an active fan subscription, **90% of the generated plan's recipes must come from that creator**. The remaining 10% can come from the general catalogue. This is enforced during selection, not as a post-process filter.

### A Plan Is All-or-Nothing

It is better to return no plan at all than to return a partial plan with missing meal slots. If any slot cannot be filled (no eligible recipe found after exhausting the top-20 candidates), the entire generation fails and an error is returned to the user. A partial plan would result in broken shopping lists and missing batch sessions.

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

meal_ingredient (pre-computed, stored after generation)
  └─ one row per ingredient per entry, with quantity already scaled by servings
     used by meal_detail and batch_detail for display

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

**Edge functions** are the orchestration layer. They handle multi-step flows that involve several DB operations, external calls, or business logic that must run as a coordinated batch. Examples: generate plan, swap entry (which must update the entry AND recalculate shopping list AND recalculate batch sessions).

**RPCs** are the atomic DB layer. They perform a single well-defined database operation: fetch top-20 candidates, insert an entry, update a component, generate a shopping list. They are called by edge functions, never chained by the Flutter app directly for complex flows.

**Flutter app** calls edge functions for user-initiated actions. It calls RPCs directly only for simple reads or single-row mutations where no orchestration is needed.

---

## 4. Generation Algorithm

### Step 1 — User Vector Lookup
The user's 50-dimensional preference vector is loaded from `user_vector`. If absent, the fallback is most-liked recipes (popularity ranking).

### Step 2 — Calorie Goal Lookup
The user's active calorie goals are fetched from `user_goal` — one target per meal type (breakfast, lunch, dinner, snack), gathered during onboarding. If a meal type has no goal, servings default to 1.0 (base portion).

### Step 3 — Recipe Pool Fetch
All eligible published recipes are fetched once, ranked by cosine similarity to the user vector. The **top 10–20 best-fitting recipes per meal type** form the pool that serves the entire plan. This avoids per-slot DB round trips and ensures the plan draws from a consistent, pre-ranked set.

When a fan subscription is active, the pool is composed such that 90% of selections come from the subscribed creator's recipes, with a 1.5x similarity score boost applied.

### Step 4 — Slot Assignment (per day × per meal type)
For each slot, the algorithm:
1. Picks the highest-ranked recipe in the pool that has not hit the 3-entry cap
2. Calculates `servings = meal_type_calorie_target / recipe.calories` (rounded to 1 decimal, min 0.1, max 4.0)
3. Inserts `meal_plan_entry` + `meal_plan_entry_component`
4. Increments the recipe's use count

If no eligible recipe exists for a slot, generation aborts entirely — no partial plan is created.

### User Entry Actions

Once a plan is generated, an entry is **permanent** — it cannot be deleted. The user has two actions:
1. **Swap for a recipe** — replace with a different recipe from the catalogue
2. **Swap for a personal meal** — replace with a custom meal analyzed via AI photo

In both cases the shopping list and batch sessions recalculate automatically (full recalculation, not delta).

### Step 5 — Batch Session Creation
After all entries are created, `create_batch_sessions` groups entries by recipe, sums their servings, and creates a `cooking_session` with scaled ingredient quantities for recipes appearing 2+ times.

### Step 6 — Shopping List Generation
`generate_shopping_list` aggregates ingredients from:
- Non-batch entries: `ingredient.quantity × entry.servings`
- Batch entries: pre-computed `cooking_session_ingredient.quantity_needed`

---

## 5. Multi-Meal-Type Recipes

A recipe tagged with both lunch and dinner is eligible for both slots. When selected for two different meal types, it generates two separate entries with different calorie targets and therefore different serving sizes. Example:
- Lunch entry: 400 kcal target → servings = 400/500 = 0.8
- Dinner entry: 300 kcal target → servings = 300/500 = 0.6
- Total servings consumed: 1.4 → batch cooking and shopping list scale ingredients by 1.4 / recipe.servings

---

## 6. Known Challenges

### Macro Display Bug

`MealPlanEntry.calories` (and protein, carbs, fat) in the Dart model sums raw component macros without multiplying by `servings`. A recipe with 300 kcal and servings=1.33 displays 300 kcal instead of 400 kcal.

Macro computation must move entirely to the backend: values are pre-computed and stored in `meal_ingredient` after generation. The Dart model reads stored values and never calculates macros at runtime.

---

### Silent Slot Failures

When no recipe is found for a slot, the current RPC issues a `CONTINUE` — the entry is silently skipped. The user receives a partial plan with no error.

Since a partial plan is unacceptable, generation must be all-or-nothing: if any slot cannot be filled, the entire operation rolls back and a clear error is returned.

---

### Recipe Pool Exhaustion

If the recipe catalogue has fewer than 10 unique recipes for a meal type, the pool is too shallow for a full week. This must be detected before generation starts (pre-flight check) and surfaced to the user as: "Not enough recipes available for [meal type]. Please check back later."

---

### Data Gaps

| Gap | Current behaviour | Required fix |
|-----|------------------|--------------|
| No `user_vector` | Falls back to most-liked recipes | Surface warning; proceed with fallback |
| No calorie goal for meal type | `servings = 1.0` | Use 1.0, note in plan summary |
| Recipe with no `recipe_macro` | `servings = 1.0`, macros = 0 kcal | Exclude from generation pool |
| Recipe with no `meal_types` | Never selected | Exclude; flag to creator dashboard |

---

### Serving Scale Bounds

`v_servings` is capped at **4.0** (max) and **0.1** (min). When a recipe's natural scale would exceed 4.0 (e.g., a 50 kcal recipe against a 600 kcal target), the algorithm skips it and picks the next candidate from the pool.

---

## 7. Design Constraints for Launch

| Constraint | Value | Rationale |
|-----------|-------|-----------|
| Max entries per recipe per plan | 3 | Prevents one recipe dominating the week |
| Max serving scale factor | 4.0 | Prevents unrealistic portion sizes |
| Min serving scale factor | 0.1 | Prevents near-zero portions |
| Fan creator recipe share | 90% | Respects fan subscription intent |
| Meals per day options | 2, 3, or 4 | 2=lunch+dinner, 3=standard, 4=+snack |
| Plan duration | 7 days (default) | One week |
| Batch session threshold | 2+ appearances | Only batch-cook repeated recipes |
| Plan completeness | All-or-nothing | No partial plans returned to user |

---

## 8. Open Questions (Post-Launch)

- Should users be able to set a custom max-portions-per-recipe cap?
- Should the generator respect user-defined cooking days, or does the user decide independently?
- Should users be able to tune the recipe variance (tight preference match vs. more discovery)?
