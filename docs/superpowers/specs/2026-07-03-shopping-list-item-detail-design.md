# Shopping List Item Detail — Design

## Goal

Let a user tap a shopping list item to see which recipe(s) in their current
meal plan use that ingredient, plus nutrition and price information —
answering "why is this on my list" without leaving the shopping list.

## Branch

Continues on `price-scraper-feature`, alongside the sort/filter work
(`docs/superpowers/plans/2026-07-03-shopping-list-filters.md`).

## Constraint: recipe linkage is not stored on `shopping_list_item`

`shopping_list_item` (`id, shopping_list_id, ingredient_id, quantity, unit,
is_checked`) has no `recipe_id` or `meal_plan_entry_id`. The
`generate_shopping_list` RPC aggregates ingredient quantities across the
whole meal plan via `GROUP BY ingredient_id, unit` before insert, discarding
per-recipe origin at that step.

The raw linkage still exists elsewhere and can be reconstructed:
- `meal_plan_entry.recipe_id` — legacy/simple (non-modular) entries.
- `meal_plan_entry_component.recipe_id` — modular meals (base/starch/side),
  joined to `meal_plan_entry` via `meal_plan_entry_id`.
- `cooking_session.recipe_id` — batch-cooked recipes, joined via
  `meal_plan_id` directly.
- `recipe_ingredient` — the authoritative per-recipe ingredient list, used to
  check which of the plan's recipes actually contain the target ingredient
  (more precise than the flattened, portion-scaled `meal_ingredient` rows,
  which don't distinguish which component of a modular entry an ingredient
  came from).

### Chosen approach: reconstruct on demand

A new read-only Postgres function computes "recipes in this plan containing
this ingredient" live, when the detail sheet opens. Rejected alternative:
denormalizing into a new `shopping_list_item_recipe` join table populated by
`generate_shopping_list` — would speed up reads, but requires a new
migration, a backfill story for already-generated shopping lists, and
touches a function that has already needed two prior bugfix migrations.
Since this data is fetched once per sheet-open (not on every list render),
the on-demand approach's cost is acceptable and carries much less risk.

## Backend

### New RPC: `get_ingredient_recipes_in_plan`

```sql
CREATE OR REPLACE FUNCTION get_ingredient_recipes_in_plan(
  p_meal_plan_id uuid,
  p_ingredient_id uuid
)
RETURNS TABLE (
  recipe_id uuid,
  title text,
  cover_image_url text,
  prep_time_min int,
  cook_time_min int
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  WITH plan_recipes AS (
    SELECT recipe_id FROM meal_plan_entry
    WHERE meal_plan_id = p_meal_plan_id AND recipe_id IS NOT NULL
    UNION
    SELECT mpec.recipe_id FROM meal_plan_entry_component mpec
      JOIN meal_plan_entry mpe ON mpe.id = mpec.meal_plan_entry_id
    WHERE mpe.meal_plan_id = p_meal_plan_id
    UNION
    SELECT recipe_id FROM cooking_session
    WHERE meal_plan_id = p_meal_plan_id AND recipe_id IS NOT NULL
  )
  SELECT DISTINCT r.id, r.title, r.cover_image_url, r.prep_time_min, r.cook_time_min
  FROM recipe r
  JOIN recipe_ingredient ri ON ri.recipe_id = r.id
  WHERE r.id IN (SELECT recipe_id FROM plan_recipes)
    AND ri.ingredient_id = p_ingredient_id;
$$;
```

`SECURITY INVOKER` (the default) is sufficient — `meal_plan_entry`,
`meal_plan_entry_component`, and `cooking_session` are already RLS-scoped to
`user_id = auth.uid()` via their owning `meal_plan`/`cooking_session` rows.
`recipe` allows public `SELECT` for `is_published = true` rows (plus
creator-owned rows for their own drafts) and `recipe_ingredient` has no
additional restriction beyond its parent recipe — matching how recipe
detail pages already read this data. No privilege escalation needed.

## Flutter

### New model: `RecipeUsage`

Lightweight — not the full `Recipe` model (25+ fields), since a usage card
only needs enough to render and navigate:

```dart
class RecipeUsage {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final int prepTimeMin;
  final int cookTimeMin;
  const RecipeUsage({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.prepTimeMin,
    required this.cookTimeMin,
  });
}
```

### New provider: `ingredientRecipesInPlanProvider`

`FutureProvider.family<List<RecipeUsage>, (String mealPlanId, String ingredientId)>`,
keyed by a Dart record (structural equality, no extra key class needed),
calling the new RPC.

### `IngredientDetailSheet` — extended, not replaced

`IngredientDetailSheet.show()` gains an optional `mealPlanId` parameter
(default `null`). Existing call sites (recipe detail, meal detail, cooking
mode, batch cooking) are unchanged — they omit it, so behavior there is
identical to today.

When `mealPlanId` is provided, the sheet additionally watches
`ingredientRecipesInPlanProvider((mealPlanId, ing.ingredientId))` and renders
a new "Used in" section — a horizontal row of small tappable recipe cards
(thumbnail, title, prep + cook time) — below the sheet's existing nutrition
(per-100g) and price content, which is **unchanged**.

Tapping a recipe card: pop the sheet, then
`context.push(AkeliRoutes.recipeDetailPath(recipe.id))`.

### Shopping list wiring

- `shopping_list_page.dart` watches `activeMealPlanProvider` to get the
  current `mealPlanId`.
- `AkeliShoppingRow` gains a small info-icon affordance, distinct from the
  existing tap-to-toggle-checked gesture on the row. Tapping it builds a
  `RecipeIngredient` from the tapped `ShoppingItem` (all needed fields —
  `id`, `ingredientId`, `name`, `quantity`, `unit` — already exist on
  `ShoppingItem`; `isOptional` defaults to `false`) and calls
  `IngredientDetailSheet.show(context, ing, mealPlanId: mealPlanId)`.

## Edge Cases

- `ShoppingItem.ingredientId == null` (custom/unlinked item) — info icon is
  hidden entirely; there is no ingredient record, price, or recipe usage to
  show.
- RPC returns an empty list, or the request errors — the "Used in" section
  is silently omitted; the rest of the sheet (nutrition, price) still
  renders normally. This mirrors the sheet's general resilience: a
  secondary/supplementary section should never block the primary content.
- An ingredient used in zero recipes in the current plan (e.g. leftover from
  a since-removed meal) — same as "empty list," section omitted.

## Testing

- SQL: verify `get_ingredient_recipes_in_plan` against the remote project
  (via Supabase MCP `execute_sql`) for a real meal plan — confirm it returns
  recipes from all three linkage paths (simple entry, modular component,
  batch-cooked session) and excludes recipes that don't actually contain the
  ingredient.
- Dart: `RecipeUsage` parsing test (fromJson-style mapping from RPC rows).
- Widget test: `IngredientDetailSheet` renders the "Used in" section when
  `mealPlanId` is provided and the provider resolves a non-empty list; omits
  it when the list is empty or `mealPlanId` is null (existing call sites'
  behavior unchanged).
- Widget test: `AkeliShoppingRow`'s info icon is absent when
  `item.ingredientId` is null, present otherwise.
