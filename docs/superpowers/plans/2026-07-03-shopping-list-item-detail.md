# Shopping List Item Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user tap a shopping list item to see which recipe(s) in their current meal plan use that ingredient, plus nutrition/price info, by extending the existing `IngredientDetailSheet`.

**Architecture:** A new read-only Postgres function (`get_ingredient_recipes_in_plan`) reconstructs "which recipes in this plan contain this ingredient" on demand, since that link is discarded during shopping-list aggregation. A new `ingredientRecipesInPlanProvider` calls it. `IngredientDetailSheet` gains an optional `mealPlanId` param that, when present, renders a new "Used in" section of tappable recipe cards — its existing nutrition/price rendering is untouched. `AkeliShoppingRow` gains a small info-icon affordance that opens the sheet.

**Tech Stack:** Flutter/Dart 3.3+, Riverpod 2.5 (`FutureProvider.family`), Supabase Postgres, pgTAP, go_router.

## Global Constraints

- Every Dart file created or modified MUST have full structured logging per `CLAUDE.md` (`package:akeli/core/logger.dart`).
- No hardcoded user-visible strings — every string goes through `AppLocalizations`, added to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` before being referenced in Dart, followed by `flutter gen-l10n`.
- Never run the local Supabase stack — verify migrations and query shapes against the remote project (`njzqcftjzskwcpforwzf`) via the Supabase MCP `execute_sql` tool, per `.agent/skills/akeli-local-testing-protocol/SKILL.md`.
- All work happens on the `price-scraper-feature` git branch (same as the sort/filter plan).
- Applying the migration to the shared remote project requires explicit user confirmation before running `supabase db push`.

## Dependency note on `shopping_list_page.dart`

This plan's Task 6 edits the same file as Task 7 of
`docs/superpowers/plans/2026-07-03-shopping-list-filters.md` (not yet
executed as of this writing). The specific `AkeliShoppingRow(...)`
construction this plan modifies is unaffected by that other plan's changes
(which touch sort/filter state and the surrounding sliver structure, not the
`AkeliShoppingRow` call's own parameters) — but if that plan runs first, the
construction will be found inside its new `_buildSectionSlivers` helper
method instead of directly in a top-level `SliverList`. Locate the
`AkeliShoppingRow(` call by content, not by assumed line number, and apply
the same parameter addition wherever it now lives.

---

### Task 1: Add `get_ingredient_recipes_in_plan` RPC

**Files:**
- Create: `supabase/migrations/20260703020000_add_get_ingredient_recipes_in_plan_function.sql`
- Create: `supabase/tests/get_ingredient_recipes_in_plan_test.sql`

**Interfaces:**
- Produces: Postgres function `get_ingredient_recipes_in_plan(p_meal_plan_id uuid, p_ingredient_id uuid) RETURNS TABLE(recipe_id uuid, title text, cover_image_url text, prep_time_min int, cook_time_min int)`. Task 3's provider calls this by name.

- [ ] **Step 1: Write the migration**

```sql
-- supabase/migrations/20260703020000_add_get_ingredient_recipes_in_plan_function.sql
-- Reconstructs "which recipes in this meal plan use this ingredient" on
-- demand for the shopping list item detail sheet. shopping_list_item does
-- not retain per-recipe origin (discarded by generate_shopping_list's
-- GROUP BY), so this is computed live from the three ways a recipe can be
-- part of a plan: a simple (non-modular) entry, a modular entry's
-- component, or a batch-cooked session.
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

- [ ] **Step 2: Write the pgTAP test**

```sql
-- supabase/tests/get_ingredient_recipes_in_plan_test.sql
BEGIN;
SELECT plan(6);

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('b0000000-0000-4000-8000-000000000001'::uuid, 'girip-test@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, role, locale)
VALUES ('b0000000-0000-4000-8000-000000000001'::uuid, true, false, now(), 'user', 'fr')
ON CONFLICT (id) DO NOTHING;

INSERT INTO meal_plan (id, user_id, start_date, end_date, is_active)
VALUES ('b0000000-0000-4000-8000-000000000010'::uuid, 'b0000000-0000-4000-8000-000000000001'::uuid, CURRENT_DATE, CURRENT_DATE + 6, true);

INSERT INTO ingredient (id, name)
VALUES ('b0000000-0000-4000-8000-000000000020'::uuid, 'Test Rice');

-- Recipe A: legacy meal_plan_entry.recipe_id path, contains the ingredient
INSERT INTO recipe (id, title, instructions, is_published)
VALUES ('b0000000-0000-4000-8000-000000000030'::uuid, 'Recipe A', 'cook it', true);
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit)
VALUES ('b0000000-0000-4000-8000-000000000030'::uuid, 'b0000000-0000-4000-8000-000000000020'::uuid, 100, 'g');

-- Recipe B: modular meal_plan_entry_component.recipe_id path, contains the ingredient
INSERT INTO recipe (id, title, instructions, is_published)
VALUES ('b0000000-0000-4000-8000-000000000031'::uuid, 'Recipe B', 'cook it', true);
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit)
VALUES ('b0000000-0000-4000-8000-000000000031'::uuid, 'b0000000-0000-4000-8000-000000000020'::uuid, 200, 'g');

-- Recipe C: batch cooking_session.recipe_id path, contains the ingredient
INSERT INTO recipe (id, title, instructions, is_published)
VALUES ('b0000000-0000-4000-8000-000000000032'::uuid, 'Recipe C', 'cook it', true);
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit)
VALUES ('b0000000-0000-4000-8000-000000000032'::uuid, 'b0000000-0000-4000-8000-000000000020'::uuid, 300, 'g');

-- Recipe D: in the plan (legacy path) but does NOT contain the ingredient
INSERT INTO recipe (id, title, instructions, is_published)
VALUES ('b0000000-0000-4000-8000-000000000033'::uuid, 'Recipe D', 'cook it', true);

-- Recipe E: contains the ingredient but is NOT in this plan at all
INSERT INTO recipe (id, title, instructions, is_published)
VALUES ('b0000000-0000-4000-8000-000000000034'::uuid, 'Recipe E', 'cook it', true);
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit)
VALUES ('b0000000-0000-4000-8000-000000000034'::uuid, 'b0000000-0000-4000-8000-000000000020'::uuid, 400, 'g');

-- Wire up plan linkage
INSERT INTO meal_plan_entry (id, meal_plan_id, recipe_id, scheduled_date, meal_type)
VALUES ('b0000000-0000-4000-8000-000000000040'::uuid, 'b0000000-0000-4000-8000-000000000010'::uuid, 'b0000000-0000-4000-8000-000000000030'::uuid, CURRENT_DATE, 'lunch');

INSERT INTO meal_plan_entry (id, meal_plan_id, recipe_id, scheduled_date, meal_type)
VALUES ('b0000000-0000-4000-8000-000000000041'::uuid, 'b0000000-0000-4000-8000-000000000010'::uuid, NULL, CURRENT_DATE, 'dinner');

INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role)
VALUES ('b0000000-0000-4000-8000-000000000041'::uuid, 'b0000000-0000-4000-8000-000000000031'::uuid, 'base');

INSERT INTO cooking_session (id, user_id, meal_plan_id, recipe_id, planned_date, total_portions)
VALUES ('b0000000-0000-4000-8000-000000000050'::uuid, 'b0000000-0000-4000-8000-000000000001'::uuid, 'b0000000-0000-4000-8000-000000000010'::uuid, 'b0000000-0000-4000-8000-000000000032'::uuid, CURRENT_DATE, 4);

INSERT INTO meal_plan_entry (id, meal_plan_id, recipe_id, scheduled_date, meal_type)
VALUES ('b0000000-0000-4000-8000-000000000042'::uuid, 'b0000000-0000-4000-8000-000000000010'::uuid, 'b0000000-0000-4000-8000-000000000033'::uuid, CURRENT_DATE, 'breakfast');

SELECT is(
  (SELECT count(*)::int FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  )),
  3,
  'T1: returns exactly 3 recipes (A, B, C) -- not D (no ingredient) or E (not in plan)'
);

SELECT ok(
  EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000030'::uuid),
  'T2: Recipe A (legacy meal_plan_entry.recipe_id path) is included'
);

SELECT ok(
  EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000031'::uuid),
  'T3: Recipe B (modular meal_plan_entry_component.recipe_id path) is included'
);

SELECT ok(
  EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000032'::uuid),
  'T4: Recipe C (batch cooking_session.recipe_id path) is included'
);

SELECT ok(
  NOT EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000033'::uuid),
  'T5: Recipe D (in plan, but recipe_ingredient has no row for this ingredient) is excluded'
);

SELECT ok(
  NOT EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000034'::uuid),
  'T6: Recipe E (contains ingredient, but not in this plan) is excluded'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 3: Apply the migration to the remote project (requires explicit user confirmation first)**

Ask the user to confirm before running this against the shared remote project. Once confirmed:

```bash
supabase db push
```

Expected: migration `20260703020000_add_get_ingredient_recipes_in_plan_function` applied with no errors.

- [ ] **Step 4: Verify via Supabase MCP `execute_sql` (project_id: `njzqcftjzskwcpforwzf`)**

```sql
SELECT proname, pronargs FROM pg_proc WHERE proname = 'get_ingredient_recipes_in_plan';
```

Expected: one row, `pronargs = 2`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260703020000_add_get_ingredient_recipes_in_plan_function.sql supabase/tests/get_ingredient_recipes_in_plan_test.sql
git commit -m "feat(db): add get_ingredient_recipes_in_plan RPC for shopping list item detail"
```

---

### Task 2: Add the `RecipeUsage` model

**Files:**
- Create: `lib/shared/models/recipe_usage.dart`
- Create: `test/shared/models/recipe_usage_test.dart`

**Interfaces:**
- Produces: `RecipeUsage(id, title, thumbnailUrl, prepTimeMin, cookTimeMin)` with `RecipeUsage.fromJson(Map<String, dynamic>)` parsing the RPC's row shape (`recipe_id, title, cover_image_url, prep_time_min, cook_time_min`). Consumed by Task 3 (provider) and Task 5 (sheet's recipe cards).

- [ ] **Step 1: Write the failing test**

```dart
// test/shared/models/recipe_usage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/recipe_usage.dart';

void main() {
  group('RecipeUsage.fromJson', () {
    test('maps all fields when present', () {
      final usage = RecipeUsage.fromJson(const {
        'recipe_id': 'r1',
        'title': 'Jollof Rice',
        'cover_image_url': 'https://example.com/jollof.jpg',
        'prep_time_min': 15,
        'cook_time_min': 40,
      });

      expect(usage.id, 'r1');
      expect(usage.title, 'Jollof Rice');
      expect(usage.thumbnailUrl, 'https://example.com/jollof.jpg');
      expect(usage.prepTimeMin, 15);
      expect(usage.cookTimeMin, 40);
    });

    test('defaults missing optional fields', () {
      final usage = RecipeUsage.fromJson(const {
        'recipe_id': 'r2',
        'title': 'Plain Rice',
        'cover_image_url': null,
        'prep_time_min': null,
        'cook_time_min': null,
      });

      expect(usage.thumbnailUrl, isNull);
      expect(usage.prepTimeMin, 0);
      expect(usage.cookTimeMin, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shared/models/recipe_usage_test.dart`
Expected: FAIL — `package:akeli/shared/models/recipe_usage.dart` does not exist.

- [ ] **Step 3: Implement the model**

```dart
// lib/shared/models/recipe_usage.dart
import 'package:akeli/core/logger.dart';
import 'package:flutter/foundation.dart';

@immutable
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

  factory RecipeUsage.fromJson(Map<String, dynamic> json) {
    appLogger.db('RecipeUsage.fromJson | recipeId: ${json['recipe_id']}');
    return RecipeUsage(
      id: json['recipe_id'] as String,
      title: json['title'] as String? ?? '',
      thumbnailUrl: json['cover_image_url'] as String?,
      prepTimeMin: (json['prep_time_min'] as num?)?.toInt() ?? 0,
      cookTimeMin: (json['cook_time_min'] as num?)?.toInt() ?? 0,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shared/models/recipe_usage_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/recipe_usage.dart test/shared/models/recipe_usage_test.dart
git commit -m "feat(model): add RecipeUsage for shopping list item detail's recipe cards"
```

---

### Task 3: Add `ingredientRecipesInPlanProvider`

**Files:**
- Modify: `lib/providers/ingredient_provider.dart`

**Interfaces:**
- Consumes: `RecipeUsage.fromJson` (Task 2).
- Produces: `ingredientRecipesInPlanProvider` — `FutureProvider.family<List<RecipeUsage>, (String mealPlanId, String ingredientId)>`. Consumed by Task 5's `_RecipeUsageSection`.

- [ ] **Step 1: Add the import**

At the top of `lib/providers/ingredient_provider.dart`, add:

```dart
import '../shared/models/recipe_usage.dart';
```

- [ ] **Step 2: Add the provider**

Append to `lib/providers/ingredient_provider.dart` (after the existing `searchIngredientsProvider`):

```dart
// ---------------------------------------------------------------------------
// Recipes in the current plan that use a given ingredient
// ---------------------------------------------------------------------------

final ingredientRecipesInPlanProvider =
    FutureProvider.family<List<RecipeUsage>, (String mealPlanId, String ingredientId)>(
        (ref, args) async {
  final (mealPlanId, ingredientId) = args;
  final logger = appLogger;
  logger.provider(
      'ingredientRecipesInPlanProvider build() | mealPlanId: $mealPlanId | ingredientId: $ingredientId');
  ref.onDispose(() => logger.provider(
      'ingredientRecipesInPlanProvider disposed | mealPlanId: $mealPlanId | ingredientId: $ingredientId'));

  logger.db(
      'BEFORE rpc | fn: get_ingredient_recipes_in_plan | mealPlanId: $mealPlanId | ingredientId: $ingredientId');

  try {
    final data = await Supabase.instance.client.rpc(
      'get_ingredient_recipes_in_plan',
      params: {
        'p_meal_plan_id': mealPlanId,
        'p_ingredient_id': ingredientId,
      },
    ) as List<dynamic>;

    logger.db('AFTER rpc | fn: get_ingredient_recipes_in_plan | rows: ${data.length}');
    return data.map((e) => RecipeUsage.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e, st) {
    logger.db('ERROR | rpc: get_ingredient_recipes_in_plan | $e', error: e, stackTrace: st);
    return <RecipeUsage>[];
  }
});
```

Errors are swallowed to an empty list (not rethrown) — per the design, the "Used in" section is a secondary/supplementary part of the sheet and should never block the primary nutrition/price content.

- [ ] **Step 3: Verify against remote via Supabase MCP `execute_sql`**

Per `.agent/skills/akeli-local-testing-protocol/SKILL.md` — confirm the RPC returns the expected shape for a real meal plan + ingredient pair (project_id: `njzqcftjzskwcpforwzf`):

```sql
SELECT * FROM get_ingredient_recipes_in_plan(
  (SELECT id FROM meal_plan WHERE is_active = true LIMIT 1),
  (SELECT id FROM ingredient LIMIT 1)
);
```

Expected: no error; zero or more rows shaped `recipe_id, title, cover_image_url, prep_time_min, cook_time_min`.

- [ ] **Step 4: Commit**

```bash
git add lib/providers/ingredient_provider.dart
git commit -m "feat(provider): add ingredientRecipesInPlanProvider"
```

---

### Task 4: Add an info-icon affordance to `AkeliShoppingRow`

**Files:**
- Modify: `lib/shared/widgets/shopping_row.dart`
- Create: `test/shared/widgets/shopping_row_test.dart`

**Interfaces:**
- Produces: `AkeliShoppingRow` gains `onInfoTap` (`VoidCallback?`, default `null`). When `null`, no icon renders (unchanged from today). Consumed by Task 6.

- [ ] **Step 1: Write the failing tests**

```dart
// test/shared/widgets/shopping_row_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/meal_plan.dart';
import 'package:akeli/shared/widgets/shopping_row.dart';

const _item = ShoppingItem(
  id: 'i1',
  ingredientId: 'ing1',
  name: 'Riz',
  quantity: 500,
  unit: 'g',
  isChecked: false,
);

void main() {
  group('AkeliShoppingRow -- info icon', () {
    testWidgets('is absent when onInfoTap is not provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AkeliShoppingRow(item: _item, isChecked: false, onToggle: () {}),
        ),
      ));

      expect(find.byKey(const Key('shopping-row-info')), findsNothing);
    });

    testWidgets('is present and invokes onInfoTap when provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AkeliShoppingRow(
            item: _item,
            isChecked: false,
            onToggle: () {},
            onInfoTap: () => tapped = true,
          ),
        ),
      ));

      expect(find.byKey(const Key('shopping-row-info')), findsOneWidget);
      await tester.tap(find.byKey(const Key('shopping-row-info')));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('tapping the info icon does not also trigger onToggle', (tester) async {
      var toggled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AkeliShoppingRow(
            item: _item,
            isChecked: false,
            onToggle: () => toggled = true,
            onInfoTap: () {},
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('shopping-row-info')));
      await tester.pump();
      expect(toggled, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/shared/widgets/shopping_row_test.dart`
Expected: FAIL — `onInfoTap` is an undefined named parameter on `AkeliShoppingRow`.

- [ ] **Step 3: Add the field and icon**

In `lib/shared/widgets/shopping_row.dart`, replace the field/constructor block:

```dart
class AkeliShoppingRow extends StatelessWidget {
  final ShoppingItem item;
  final bool isChecked;
  final VoidCallback onToggle;
  final bool isUsLocale;
  final String locale;

  const AkeliShoppingRow({
    super.key,
    required this.item,
    required this.isChecked,
    required this.onToggle,
    this.isUsLocale = false,
    this.locale = 'fr',
  });
```

with:

```dart
class AkeliShoppingRow extends StatelessWidget {
  final ShoppingItem item;
  final bool isChecked;
  final VoidCallback onToggle;
  final bool isUsLocale;
  final String locale;
  final VoidCallback? onInfoTap;

  const AkeliShoppingRow({
    super.key,
    required this.item,
    required this.isChecked,
    required this.onToggle,
    this.isUsLocale = false,
    this.locale = 'fr',
    this.onInfoTap,
  });
```

Then replace the tail of the row's `Row` widget (the quantity pill's closing `Container` plus the `Row`'s closing):

```dart
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isChecked
                      ? AkeliColors.surfaceContainerHighest
                      : AkeliColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  qtyText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.onSurfaceVariant,
                    decoration:
                        isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

with:

```dart
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isChecked
                      ? AkeliColors.surfaceContainerHighest
                      : AkeliColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  qtyText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.onSurfaceVariant,
                    decoration:
                        isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (onInfoTap != null)
                IconButton(
                  key: const Key('shopping-row-info'),
                  icon: const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                  onPressed: onInfoTap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/shared/widgets/shopping_row_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/shopping_row.dart test/shared/widgets/shopping_row_test.dart
git commit -m "feat(shopping-list): add info icon affordance to AkeliShoppingRow"
```

---

### Task 5: Extend `IngredientDetailSheet` with a "Used in" recipes section

**Files:**
- Modify: `lib/features/recipes/widgets/ingredient_detail_sheet.dart`
- Modify: `lib/l10n/app_en.arb:1740` (insert after `ingredientDetailEnergy` block)
- Modify: `lib/l10n/app_fr.arb:609` (insert after `ingredientDetailEnergy` line)
- Create: `test/features/recipes/widgets/ingredient_detail_sheet_test.dart`

**Interfaces:**
- Consumes: `ingredientRecipesInPlanProvider` (Task 3), `RecipeUsage` (Task 2).
- Produces: `IngredientDetailSheet(ingredient, scrollController, mealPlanId)` — `mealPlanId` optional, defaults `null` (all 4 existing call sites unaffected). Consumed by Task 6.

- [ ] **Step 1: Add l10n keys**

In `lib/l10n/app_en.arb`, after line 1740 (`"@ingredientDetailEnergy": {},`), insert:

```json
  "ingredientDetailUsedInTitle": "Used in",
  "@ingredientDetailUsedInTitle": {},
```

In `lib/l10n/app_fr.arb`, after line 609 (`"ingredientDetailEnergy": "Énergie",`), insert:

```json
  "ingredientDetailUsedInTitle": "Utilisé dans",
```

Run:

```bash
flutter gen-l10n
```

Expected: no errors; `AppLocalizations` exposes `ingredientDetailUsedInTitle`.

- [ ] **Step 2: Write the failing widget tests**

```dart
// test/features/recipes/widgets/ingredient_detail_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/recipes/widgets/ingredient_detail_sheet.dart';
import 'package:akeli/providers/ingredient_provider.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:akeli/shared/models/recipe_usage.dart';

const _ingredient = RecipeIngredient(
  id: 'ri1',
  ingredientId: 'ing1',
  name: 'Rice',
  quantity: 200,
  unit: 'g',
  isOptional: false,
);

Widget _wrap(Widget child, {required List<Override> overrides}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('IngredientDetailSheet -- recipe usage section', () {
    testWidgets('renders a recipe card when mealPlanId is provided and recipes resolve', (tester) async {
      await tester.pumpWidget(_wrap(
        const IngredientDetailSheet(ingredient: _ingredient, mealPlanId: 'plan1'),
        overrides: [
          ingredientDetailProvider.overrideWith((ref, id) async => null),
          ingredientRecipesInPlanProvider.overrideWith((ref, args) async => const [
                RecipeUsage(id: 'r1', title: 'Jollof Rice', prepTimeMin: 10, cookTimeMin: 30),
              ]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Jollof Rice'), findsOneWidget);
      expect(find.byKey(const Key('recipe-usage-card')), findsOneWidget);
    });

    testWidgets('omits the section when the recipe list is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        const IngredientDetailSheet(ingredient: _ingredient, mealPlanId: 'plan1'),
        overrides: [
          ingredientDetailProvider.overrideWith((ref, id) async => null),
          ingredientRecipesInPlanProvider.overrideWith((ref, args) async => const []),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe-usage-card')), findsNothing);
    });

    testWidgets('omits the section entirely when mealPlanId is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const IngredientDetailSheet(ingredient: _ingredient),
        overrides: [
          ingredientDetailProvider.overrideWith((ref, id) async => null),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe-usage-card')), findsNothing);
    });
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/recipes/widgets/ingredient_detail_sheet_test.dart`
Expected: FAIL — `mealPlanId` is an undefined named parameter on `IngredientDetailSheet`.

- [ ] **Step 4: Add imports**

At the top of `lib/features/recipes/widgets/ingredient_detail_sheet.dart`, add:

```dart
import 'package:go_router/go_router.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/shared/models/recipe_usage.dart';
```

- [ ] **Step 5: Add `mealPlanId` to the widget and its `show()` method**

Replace:

```dart
class IngredientDetailSheet extends ConsumerWidget {
  final RecipeIngredient ingredient;
  final ScrollController? scrollController;

  const IngredientDetailSheet({
    super.key,
    required this.ingredient,
    this.scrollController,
  });

  static Future<void> show(BuildContext context, RecipeIngredient ingredient) {
    appLogger.userAction('IngredientDetailSheet opened',
        screen: 'IngredientDetailSheet',
        metadata: {'ingredientId': ingredient.ingredientId});
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => IngredientDetailSheet(
          ingredient: ingredient,
          scrollController: scrollController,
        ),
      ),
    );
  }
```

with:

```dart
class IngredientDetailSheet extends ConsumerWidget {
  final RecipeIngredient ingredient;
  final ScrollController? scrollController;
  final String? mealPlanId;

  const IngredientDetailSheet({
    super.key,
    required this.ingredient,
    this.scrollController,
    this.mealPlanId,
  });

  static Future<void> show(
    BuildContext context,
    RecipeIngredient ingredient, {
    String? mealPlanId,
  }) {
    appLogger.userAction('IngredientDetailSheet opened',
        screen: 'IngredientDetailSheet',
        metadata: {'ingredientId': ingredient.ingredientId, 'mealPlanId': mealPlanId});
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => IngredientDetailSheet(
          ingredient: ingredient,
          scrollController: scrollController,
          mealPlanId: mealPlanId,
        ),
      ),
    );
  }
```

- [ ] **Step 6: Render the "Used in" section**

In the `build()` method, replace the final `detailAsync.when(...)` block (the one rendering description + nutrition, right before the closing of the inner `Column`'s `children`):

```dart
                detailAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AkeliColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (detail) {
                    if (detail == null) return const SizedBox.shrink();
                    final locale = AppLocalizations.of(context).localeName;
                    final localizedDesc = detail.localizedDescription(locale);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (localizedDesc != null && localizedDesc.isNotEmpty)
                          _DescriptionSection(text: localizedDesc),
                        if (detail.caloriesPer100g != null ||
                            detail.proteinPer100g != null)
                          _NutritionSection(detail: detail),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

with:

```dart
                detailAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AkeliColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (detail) {
                    if (detail == null) return const SizedBox.shrink();
                    final locale = AppLocalizations.of(context).localeName;
                    final localizedDesc = detail.localizedDescription(locale);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (localizedDesc != null && localizedDesc.isNotEmpty)
                          _DescriptionSection(text: localizedDesc),
                        if (detail.caloriesPer100g != null ||
                            detail.proteinPer100g != null)
                          _NutritionSection(detail: detail),
                      ],
                    );
                  },
                ),
                if (mealPlanId != null)
                  _RecipeUsageSection(
                    mealPlanId: mealPlanId!,
                    ingredientId: ingredient.ingredientId,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Add the `_RecipeUsageSection` and `_RecipeUsageCard` widgets**

Append to the end of `lib/features/recipes/widgets/ingredient_detail_sheet.dart`:

```dart
class _RecipeUsageSection extends ConsumerWidget {
  final String mealPlanId;
  final String ingredientId;
  const _RecipeUsageSection({required this.mealPlanId, required this.ingredientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recipesAsync =
        ref.watch(ingredientRecipesInPlanProvider((mealPlanId, ingredientId)));

    return recipesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: AkeliColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (recipes) {
        if (recipes.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ingredientDetailUsedInTitle,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurface),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _RecipeUsageCard(recipe: recipes[index]),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _RecipeUsageCard extends StatelessWidget {
  final RecipeUsage recipe;
  const _RecipeUsageCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('recipe-usage-card'),
      onTap: () {
        appLogger.userAction('Recipe usage card tapped',
            screen: 'IngredientDetailSheet', metadata: {'recipeId': recipe.id});
        Navigator.of(context).pop();
        context.push(AkeliRoutes.recipeDetailPath(recipe.id));
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AkeliRadius.md),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: recipe.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: recipe.thumbnailUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(width: 48, height: 48, color: AkeliColors.surfaceContainer),
                    )
                  : Container(width: 48, height: 48, color: AkeliColors.surfaceContainer),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AkeliColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${recipe.prepTimeMin + recipe.cookTimeMin} min',
                    style: GoogleFonts.inter(fontSize: 11, color: AkeliColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `flutter test test/features/recipes/widgets/ingredient_detail_sheet_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 9: Commit**

```bash
git add lib/features/recipes/widgets/ingredient_detail_sheet.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart test/features/recipes/widgets/ingredient_detail_sheet_test.dart
git commit -m "feat(ingredient-detail): add \"Used in\" recipe usage section"
```

---

### Task 6: Wire the shopping list row to open the detail sheet

**Files:**
- Modify: `lib/features/meal_planner/shopping_list_page.dart`

**Interfaces:**
- Consumes: `AkeliShoppingRow.onInfoTap` (Task 4), `IngredientDetailSheet.show(..., mealPlanId:)` (Task 5), `RecipeIngredient` (existing), `activeMealPlanProvider` (existing, from `meal_plan_provider.dart`).
- Produces: no new public interface — this is the leaf integration point.

- [ ] **Step 1: Add imports**

At the top of `lib/features/meal_planner/shopping_list_page.dart`, add:

```dart
import '../recipes/widgets/ingredient_detail_sheet.dart';
import '../../shared/models/recipe.dart';
```

- [ ] **Step 2: Watch the active meal plan for its id**

Right after the existing `final localeName = l10n.localeName;` line near the top of `build()`, add:

```dart
    final mealPlan = ref.watch(activeMealPlanProvider).valueOrNull;
```

- [ ] **Step 3: Pass `onInfoTap` to `AkeliShoppingRow`**

Find the `AkeliShoppingRow(...)` construction (see the dependency note at the top of this plan for where it may have moved to). Replace:

```dart
                        child: AkeliShoppingRow(
                          item: item,
                          isChecked: item.isChecked,
                          isUsLocale: isUsLocale,
                          locale: localeName,
                          onToggle: () {
                            ref.read(shoppingListProvider.notifier).toggleItem(item.id, !item.isChecked);
                          },
                        ),
```

with:

```dart
                        child: AkeliShoppingRow(
                          item: item,
                          isChecked: item.isChecked,
                          isUsLocale: isUsLocale,
                          locale: localeName,
                          onToggle: () {
                            ref.read(shoppingListProvider.notifier).toggleItem(item.id, !item.isChecked);
                          },
                          onInfoTap: (item.ingredientId == null || mealPlan == null)
                              ? null
                              : () {
                                  _logger.userAction(
                                    'Open ingredient detail from shopping list',
                                    screen: 'ShoppingListPage',
                                    metadata: {'ingredientId': item.ingredientId},
                                  );
                                  IngredientDetailSheet.show(
                                    context,
                                    RecipeIngredient(
                                      id: item.id,
                                      ingredientId: item.ingredientId!,
                                      name: item.name,
                                      quantity: item.quantity,
                                      unit: item.unit,
                                      isOptional: false,
                                    ),
                                    mealPlanId: mealPlan.id,
                                  );
                                },
                        ),
```

- [ ] **Step 4: Run static analysis**

Run: `flutter analyze lib/features/meal_planner/shopping_list_page.dart`
Expected: no new errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/shopping_list_page.dart
git commit -m "feat(shopping-list): open ingredient detail sheet with recipe usage from row tap"
```

---

### Task 7: Full verification pass

**Files:** none (verification only)

- [ ] **Step 1: Run the full Dart test suite**

```bash
flutter test
```

Expected: all tests pass, including the new ones from Tasks 2, 4, 5.

- [ ] **Step 2: Run static analysis on the whole project**

```bash
flutter analyze
```

Expected: no new errors introduced by this feature.

- [ ] **Step 3: Manual verification in a running app**

Use the project's `run` skill (or a connected simulator/device) to open the shopping list, tap an item's info icon, and confirm: the sheet opens with nutrition/price content unchanged from before, a "Used in" section appears with recipe cards when the ingredient is used in the current plan, tapping a card navigates to that recipe's detail page, and the icon is absent for any item with no `ingredientId`. Also confirm existing call sites (recipe detail, meal detail, cooking mode, batch cooking) still open the sheet exactly as before, with no "Used in" section. Report this as done only after actually observing it.
