# Shopping List Filter & Sort Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add category/price/store sort modes and a store-type filter to the shopping list screen, on the `price-scraper-feature` branch, reusing its existing package-based costing model.

**Architecture:** A new `ingredient.store_type` column (admin-tagged, 3-way enum) flows through the existing `ingredient` join in `ShoppingListNotifier`. A new pure function (`groupAndSortShoppingItems`) turns the flat item list into ordered, headered sections with zero Flutter/Riverpod dependency, so all grouping/sorting/filtering logic is unit-testable in isolation. The page renders those sections as pinned `SliverPersistentHeader` + `SliverList` pairs, with a new bottom-sheet widget for choosing sort mode and store filter.

**Tech Stack:** Flutter/Dart 3.3+, Riverpod (`AutoDisposeAsyncNotifier`), Supabase Postgres (PostgREST embedded joins), pgTAP.

## Global Constraints

- Every Dart file created or modified MUST have full structured logging per `CLAUDE.md` (`package:akeli/core/logger.dart`, category-specific methods: `.provider`, `.db`, `.userAction`, etc.) — logs are never removed, `kDebugMode` controls visibility only.
- No hardcoded user-visible strings in any widget — every string goes through `AppLocalizations`, added to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` before being referenced in Dart, followed by `flutter gen-l10n`.
- Providers/notifiers/pure logic files never resolve l10n strings — only the widget layer does.
- Never run the local Supabase stack (`supabase start`, `supabase test db`) — this project's schema is only trusted on the remote project (`njzqcftjzskwcpforwzf`); verify migrations and query shapes there via the Supabase MCP `execute_sql` tool, per `.agent/skills/akeli-local-testing-protocol/SKILL.md`.
- All work happens on the `price-scraper-feature` git branch, not `main`.
- Applying the migration to the shared remote project is a hard-to-reverse action — confirm with the user before running `supabase db push` or the MCP `apply_migration` tool (this is the one step in this plan that touches shared state).

---

### Task 0: Switch to the `price-scraper-feature` branch

**Files:** none (git operation only)

- [ ] **Step 1: Confirm working tree is clean enough to switch, then check out the branch**

```bash
git status --short
git checkout price-scraper-feature
```

Expected: no error. If there are uncommitted changes from unrelated work on `main` that would conflict, stop and ask the user how to proceed (e.g. stash, worktree) rather than discarding anything.

- [ ] **Step 2: Confirm the branch has the expected pre-existing costing code**

```bash
grep -n "estimatedPriceBought" lib/shared/models/meal_plan.dart
```

Expected: match found (confirms you're on the right branch with the existing costing model intact).

---

### Task 1: Add `ingredient.store_type` column

**Files:**
- Create: `supabase/migrations/20260703010000_add_ingredient_store_type.sql`
- Create: `supabase/tests/add_ingredient_store_type_test.sql`

**Interfaces:**
- Produces: DB column `public.ingredient.store_type` (`text NOT NULL DEFAULT 'other'`, `CHECK (store_type IN ('supermarket', 'epicery', 'other'))`). Task 3 selects this column by name.

- [ ] **Step 1: Write the migration**

```sql
-- supabase/migrations/20260703010000_add_ingredient_store_type.sql
-- Adds admin-tagged store classification to ingredients, powering the
-- shopping list's sort/filter by store (supermarket vs épicerie).
ALTER TABLE public.ingredient
  ADD COLUMN IF NOT EXISTS store_type text NOT NULL DEFAULT 'other'
    CHECK (store_type IN ('supermarket', 'epicery', 'other'));
```

- [ ] **Step 2: Write the pgTAP test**

```sql
-- supabase/tests/add_ingredient_store_type_test.sql
BEGIN;
SELECT plan(5);

SELECT has_column('public', 'ingredient', 'store_type', 'store_type column exists on ingredient');
SELECT col_type_is('public', 'ingredient', 'store_type', 'text', 'store_type is text');
SELECT col_not_null('public', 'ingredient', 'store_type', 'store_type is NOT NULL');
SELECT col_default_is('public', 'ingredient', 'store_type', 'other', 'store_type defaults to other');

SELECT throws_ok(
  $$INSERT INTO ingredient (name, store_type) VALUES ('__pgtap_test_ingredient__', 'invalid_value')$$,
  '23514',
  null,
  'store_type CHECK constraint rejects invalid values'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 3: Apply the migration to the remote project (requires explicit user confirmation first)**

Ask the user to confirm before running this against the shared remote project. Once confirmed:

```bash
supabase db push
```

Expected: migration `20260703010000_add_ingredient_store_type` applied with no errors.

- [ ] **Step 4: Verify the column via Supabase MCP `execute_sql` (project_id: `njzqcftjzskwcpforwzf`)**

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'ingredient' AND column_name = 'store_type';
```

Expected: one row — `store_type | text | NO | 'other'::text`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260703010000_add_ingredient_store_type.sql supabase/tests/add_ingredient_store_type_test.sql
git commit -m "feat(db): add ingredient.store_type column for shopping list store filter"
```

---

### Task 2: Extend `ShoppingItem` model with `storeType` and `categoryDisplayName`

**Files:**
- Modify: `lib/shared/models/meal_plan.dart:440-652` (the `ShoppingItem` class)
- Create: `test/models/shopping_item_test.dart`

**Interfaces:**
- Consumes: nothing new (adds fields to the existing `ShoppingItem` class).
- Produces: `ShoppingItem.storeType` (`String`, default `'other'`), `ShoppingItem.categoryDisplayName` (`String?`). Task 3 sets these from the DB join; Task 4's `groupAndSortShoppingItems` reads them.

- [ ] **Step 1: Write the failing test**

```dart
// test/models/shopping_item_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/meal_plan.dart';

ShoppingItem _baseItem({String? storeType, String? categoryDisplayName}) => ShoppingItem(
      id: 'i1',
      name: 'Riz',
      quantity: 1,
      unit: 'kg',
      isChecked: false,
      storeType: storeType ?? 'other',
      categoryDisplayName: categoryDisplayName,
    );

void main() {
  group('ShoppingItem.storeType', () {
    test('defaults to other when not provided', () {
      const item = ShoppingItem(
        id: 'i1',
        name: 'Riz',
        quantity: 1,
        unit: 'kg',
        isChecked: false,
      );
      expect(item.storeType, 'other');
    });

    test('can be explicitly set', () {
      final item = _baseItem(storeType: 'supermarket');
      expect(item.storeType, 'supermarket');
    });
  });

  group('ShoppingItem.categoryDisplayName', () {
    test('defaults to null when not provided', () {
      const item = ShoppingItem(
        id: 'i1',
        name: 'Riz',
        quantity: 1,
        unit: 'kg',
        isChecked: false,
      );
      expect(item.categoryDisplayName, isNull);
    });
  });

  group('ShoppingItem.copyWith', () {
    test('preserves storeType and categoryDisplayName when not overridden', () {
      final item = _baseItem(storeType: 'epicery', categoryDisplayName: 'Produce');
      final copy = item.copyWith(isChecked: true);
      expect(copy.storeType, 'epicery');
      expect(copy.categoryDisplayName, 'Produce');
    });

    test('overrides storeType and categoryDisplayName when provided', () {
      final item = _baseItem(storeType: 'other', categoryDisplayName: null);
      final copy = item.copyWith(storeType: 'supermarket', categoryDisplayName: 'Dairy');
      expect(copy.storeType, 'supermarket');
      expect(copy.categoryDisplayName, 'Dairy');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/shopping_item_test.dart`
Expected: FAIL — `storeType`/`categoryDisplayName` are undefined named parameters on `ShoppingItem`.

- [ ] **Step 3: Add the fields to `ShoppingItem`**

In `lib/shared/models/meal_plan.dart`, replace lines 440-467 (field declarations + constructor):

```dart
class ShoppingItem {
  final String id;
  final String? ingredientId;
  final String name;
  final double quantity;
  final String unit;
  final String? category;
  final String? categoryDisplayName;
  final bool isChecked;
  final double pricePer100g;
  final String currency;
  final double? avgWeightG;
  final double? packageSize;
  final String? packageUnit;
  final String storeType;

  const ShoppingItem({
    required this.id,
    this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.category,
    this.categoryDisplayName,
    required this.isChecked,
    this.pricePer100g = 0.0,
    this.currency = 'EUR',
    this.avgWeightG,
    this.packageSize,
    this.packageUnit,
    this.storeType = 'other',
  });
```

Replace lines 602-623 (`factory ShoppingItem.fromJson`):

```dart
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    final ingredient = json['ingredient'] as Map<String, dynamic>?;
    final pricingList = ingredient?['ingredient_market_price'] as List<dynamic>?;
    final pricing = (pricingList != null && pricingList.isNotEmpty) 
        ? pricingList.first as Map<String, dynamic> 
        : null;

    return ShoppingItem(
      id: json['id'] as String? ?? '',
      ingredientId: json['ingredient_id'] as String?,
      name: json['ingredient_name'] as String? ?? 'Unknown',
      quantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      category: json['category'] as String?,
      isChecked: (json['is_checked'] as bool?) ?? false,
      pricePer100g: (pricing?['price_per_100g'] as num?)?.toDouble() ?? 0.0,
      currency: pricing?['currency'] as String? ?? 'EUR',
      avgWeightG: (ingredient?['avg_weight_g'] as num?)?.toDouble(),
      packageSize: (pricing?['package_size'] as num?)?.toDouble(),
      packageUnit: pricing?['package_unit'] as String?,
      storeType: (ingredient?['store_type'] as String?) ?? 'other',
    );
  }
```

Replace lines 625-652 (`copyWith`):

```dart
  ShoppingItem copyWith({
    String? id,
    String? ingredientId,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    String? categoryDisplayName,
    bool? isChecked,
    double? pricePer100g,
    String? currency,
    double? avgWeightG,
    double? packageSize,
    String? packageUnit,
    String? storeType,
  }) => ShoppingItem(
        id: id ?? this.id,
        ingredientId: ingredientId ?? this.ingredientId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        category: category ?? this.category,
        categoryDisplayName: categoryDisplayName ?? this.categoryDisplayName,
        isChecked: isChecked ?? this.isChecked,
        pricePer100g: pricePer100g ?? this.pricePer100g,
        currency: currency ?? this.currency,
        avgWeightG: avgWeightG ?? this.avgWeightG,
        packageSize: packageSize ?? this.packageSize,
        packageUnit: packageUnit ?? this.packageUnit,
        storeType: storeType ?? this.storeType,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/shopping_item_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/meal_plan.dart test/models/shopping_item_test.dart
git commit -m "feat(model): add storeType and categoryDisplayName to ShoppingItem"
```

---

### Task 3: Wire `store_type` and category display name through the shopping list query

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart:254` (selectQuery), `:286-317` (item mapping), `:377-390` (aggregation)

**Interfaces:**
- Consumes: `ShoppingItem(storeType: ..., categoryDisplayName: ...)` constructor params from Task 2.
- Produces: `ShoppingListNotifier` / `shoppingListProvider` now emit items with real `storeType`/`categoryDisplayName` values from the DB. Task 4's `groupAndSortShoppingItems` consumes these.

- [ ] **Step 1: Update the select query to include `store_type` and the `ingredient_category` join**

In `lib/providers/meal_plan_provider.dart`, replace line 254:

```dart
    const selectQuery = 'id, shopping_list_item(id, ingredient_id, quantity, unit, is_checked, ingredient(name, name_fr, name_en, category, avg_weight_g, ingredient_market_price(price_per_100g, currency, country_code, package_size, package_unit)))';
```

with:

```dart
    const selectQuery = 'id, shopping_list_item(id, ingredient_id, quantity, unit, is_checked, ingredient(name, name_fr, name_en, category, avg_weight_g, store_type, ingredient_category(name_fr, name_en), ingredient_market_price(price_per_100g, currency, country_code, package_size, package_unit)))';
```

`ingredient_category` is embedded because `ingredient.category` is a foreign key to `ingredient_category(code)` — PostgREST resolves the to-one relationship automatically, returning it as a single object (like the existing `ingredient` embed), not a list.

- [ ] **Step 2: Parse `store_type` and the resolved category display name**

Replace lines 286-317 (the `.map()` closure body) with:

```dart
      final items = itemsData.map((e) {
          final ingredient = e['ingredient'] as Map<String, dynamic>?;
          final nameFr = (ingredient?['name_fr'] as String?) ?? (ingredient?['name'] as String?) ?? e['custom_name'] as String? ?? 'Unknown';
          final nameEn = ingredient?['name_en'] as String?;
          
          // Skip water (Eau) as it costs nothing and can be skipped
          final lowerFr = nameFr.toLowerCase();
          final lowerEn = (nameEn ?? '').toLowerCase();
          if (lowerFr == 'eau' || lowerFr == 'water' || lowerEn == 'water' || lowerEn == 'eau') {
            return null;
          }

          final pricingList = ingredient?['ingredient_market_price'] as List<dynamic>?;
          final pricing = (pricingList != null && pricingList.isNotEmpty)
              ? pricingList.first as Map<String, dynamic>
              : null;

          final ingredientCategory = ingredient?['ingredient_category'] as Map<String, dynamic>?;
          final categoryNameFr = ingredientCategory?['name_fr'] as String?;
          final categoryNameEn = ingredientCategory?['name_en'] as String?;
          final categoryDisplayName = (locale == 'en' && categoryNameEn != null) ? categoryNameEn : categoryNameFr;

          return ShoppingItem(
             id: e['id'] as String,
             ingredientId: e['ingredient_id'] as String?,
             name: (locale == 'en' && nameEn != null) ? nameEn : nameFr,
             quantity: (e['quantity'] as num).toDouble(),
             unit: (e['unit'] as String?) ?? '',
             category: ingredient?['category'] as String?,
             categoryDisplayName: categoryDisplayName,
             isChecked: (e['is_checked'] as bool?) ?? false,
             pricePer100g: (pricing?['price_per_100g'] as num?)?.toDouble() ?? 0.0,
             currency: pricing?['currency'] as String? ?? 'EUR',
             avgWeightG: (ingredient?['avg_weight_g'] as num?)?.toDouble(),
             packageSize: (pricing?['package_size'] as num?)?.toDouble(),
             packageUnit: pricing?['package_unit'] as String?,
             storeType: (ingredient?['store_type'] as String?) ?? 'other',
          );
       }).whereType<ShoppingItem>().toList();
```

- [ ] **Step 3: Propagate the new fields through aggregation**

Replace lines 377-390 (the combined `ShoppingItem` built in `_aggregateShoppingItems`) with:

```dart
      result.add(ShoppingItem(
        id: combinedId,
        ingredientId: first.ingredientId,
        name: first.name,
        quantity: totalQty,
        unit: targetUnit,
        category: first.category,
        categoryDisplayName: first.categoryDisplayName,
        isChecked: isChecked,
        pricePer100g: first.pricePer100g,
        currency: first.currency,
        avgWeightG: first.avgWeightG,
        packageSize: first.packageSize,
        packageUnit: first.packageUnit,
        storeType: first.storeType,
      ));
```

- [ ] **Step 4: Verify the query shape against the remote project via Supabase MCP `execute_sql`**

Per `.agent/skills/akeli-local-testing-protocol/SKILL.md` section 3 — confirm every newly-selected column/relationship actually exists (project_id: `njzqcftjzskwcpforwzf`):

```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'ingredient' AND column_name IN ('store_type', 'category');
-- Expect both rows present.

SELECT conname FROM pg_constraint
WHERE conrelid = 'ingredient'::regclass AND confrelid = 'ingredient_category'::regclass;
-- Expect one FK constraint (confirms the ingredient_category embed will resolve).
```

- [ ] **Step 5: Commit**

```bash
git add lib/providers/meal_plan_provider.dart
git commit -m "feat(provider): select store_type and category display name for shopping list"
```

---

### Task 4: Build the pure sort/filter/group logic

**Files:**
- Create: `lib/features/meal_planner/shopping_list_sort.dart`
- Create: `test/features/meal_planner/shopping_list_sort_test.dart`

**Interfaces:**
- Consumes: `ShoppingItem` (`category`, `categoryDisplayName`, `storeType`, `name`, `estimatedPriceBought`) from Task 2/3.
- Produces: `ShoppingSortMode` enum (`category`, `price`, `store`), `StoreTypeFilter` enum (`all`, `supermarket`, `epicery`, `other`), `uncategorizedKey` constant, `ShoppingListSection` class (`headerKey: String?`, `items: List<ShoppingItem>`), and `List<ShoppingListSection> groupAndSortShoppingItems(List<ShoppingItem> items, {required ShoppingSortMode sortMode, required StoreTypeFilter storeFilter})`. Consumed by Task 6 (enums) and Task 7 (the function + section type).

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/meal_planner/shopping_list_sort_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/meal_planner/shopping_list_sort.dart';
import 'package:akeli/shared/models/meal_plan.dart';

ShoppingItem _item({
  required String id,
  required String name,
  String? category,
  String? categoryDisplayName,
  String storeType = 'other',
  double pricePer100g = 0.0,
  double quantity = 100,
  String unit = 'g',
}) =>
    ShoppingItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      categoryDisplayName: categoryDisplayName,
      isChecked: false,
      pricePer100g: pricePer100g,
      storeType: storeType,
    );

void main() {
  group('groupAndSortShoppingItems — category mode', () {
    test('groups by categoryDisplayName, sections sorted alphabetically by header', () {
      final items = [
        _item(id: '1', name: 'Lait', categoryDisplayName: 'Dairy'),
        _item(id: '2', name: 'Carotte', categoryDisplayName: 'Produce'),
        _item(id: '3', name: 'Yaourt', categoryDisplayName: 'Dairy'),
      ];

      final sections = groupAndSortShoppingItems(
        items,
        sortMode: ShoppingSortMode.category,
        storeFilter: StoreTypeFilter.all,
      );

      expect(sections.map((s) => s.headerKey), ['Dairy', 'Produce']);
      expect(sections[0].items.map((i) => i.name), ['Lait', 'Yaourt']);
    });

    test('falls back to raw category when categoryDisplayName is null', () {
      final items = [_item(id: '1', name: 'Riz', category: 'grain')];

      final sections = groupAndSortShoppingItems(
        items,
        sortMode: ShoppingSortMode.category,
        storeFilter: StoreTypeFilter.all,
      );

      expect(sections.single.headerKey, 'grain');
    });

    test('groups items with no category under uncategorizedKey', () {
      final items = [_item(id: '1', name: 'Mystery item')];

      final sections = groupAndSortShoppingItems(
        items,
        sortMode: ShoppingSortMode.category,
        storeFilter: StoreTypeFilter.all,
      );

      expect(sections.single.headerKey, uncategorizedKey);
    });
  });

  group('groupAndSortShoppingItems — price mode', () {
    test('returns a single flat section (no header), sorted ascending by estimatedPriceBought', () {
      final items = [
        _item(id: '1', name: 'Expensive', pricePer100g: 10, quantity: 1000, unit: 'g'),
        _item(id: '2', name: 'Cheap', pricePer100g: 1, quantity: 100, unit: 'g'),
      ];

      final sections = groupAndSortShoppingItems(
        items,
        sortMode: ShoppingSortMode.price,
        storeFilter: StoreTypeFilter.all,
      );

      expect(sections.length, 1);
      expect(sections.single.headerKey, isNull);
      expect(sections.single.items.map((i) => i.name), ['Cheap', 'Expensive']);
    });
  });

  group('groupAndSortShoppingItems — store mode', () {
    test('orders sections supermarket -> epicery -> other', () {
      final items = [
        _item(id: '1', name: 'A', storeType: 'other'),
        _item(id: '2', name: 'B', storeType: 'epicery'),
        _item(id: '3', name: 'C', storeType: 'supermarket'),
      ];

      final sections = groupAndSortShoppingItems(
        items,
        sortMode: ShoppingSortMode.store,
        storeFilter: StoreTypeFilter.all,
      );

      expect(sections.map((s) => s.headerKey), ['supermarket', 'epicery', 'other']);
    });
  });

  group('groupAndSortShoppingItems — store filter', () {
    test('excludes items not matching the store filter', () {
      final items = [
        _item(id: '1', name: 'A', storeType: 'supermarket', categoryDisplayName: 'Dairy'),
        _item(id: '2', name: 'B', storeType: 'epicery', categoryDisplayName: 'Dairy'),
      ];

      final sections = groupAndSortShoppingItems(
        items,
        sortMode: ShoppingSortMode.category,
        storeFilter: StoreTypeFilter.supermarket,
      );

      expect(sections.single.items.map((i) => i.name), ['A']);
    });

    test('StoreTypeFilter.all keeps every item regardless of storeType', () {
      final items = [
        _item(id: '1', name: 'A', storeType: 'supermarket'),
        _item(id: '2', name: 'B', storeType: 'epicery'),
      ];

      final sections = groupAndSortShoppingItems(
        items,
        sortMode: ShoppingSortMode.price,
        storeFilter: StoreTypeFilter.all,
      );

      expect(sections.single.items.length, 2);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/meal_planner/shopping_list_sort_test.dart`
Expected: FAIL — `package:akeli/features/meal_planner/shopping_list_sort.dart` does not exist.

- [ ] **Step 3: Implement the pure logic**

```dart
// lib/features/meal_planner/shopping_list_sort.dart
import 'package:akeli/core/logger.dart';
import 'package:akeli/shared/models/meal_plan.dart';

enum ShoppingSortMode { category, price, store }

enum StoreTypeFilter { all, supermarket, epicery, other }

/// Sentinel header key for items with no category and no categoryDisplayName.
const uncategorizedKey = '__uncategorized__';

const _storeTypeOrder = ['supermarket', 'epicery', 'other'];

class ShoppingListSection {
  /// null only for the single flat section produced by ShoppingSortMode.price.
  final String? headerKey;
  final List<ShoppingItem> items;
  const ShoppingListSection({this.headerKey, required this.items});
}

String _storeTypeValueFor(StoreTypeFilter filter) {
  switch (filter) {
    case StoreTypeFilter.supermarket:
      return 'supermarket';
    case StoreTypeFilter.epicery:
      return 'epicery';
    case StoreTypeFilter.other:
      return 'other';
    case StoreTypeFilter.all:
      return '';
  }
}

List<ShoppingListSection> groupAndSortShoppingItems(
  List<ShoppingItem> items, {
  required ShoppingSortMode sortMode,
  required StoreTypeFilter storeFilter,
}) {
  appLogger.d(
      '🧮 groupAndSortShoppingItems | sortMode: $sortMode | storeFilter: $storeFilter | itemCount: ${items.length}');

  final filtered = storeFilter == StoreTypeFilter.all
      ? items
      : items.where((item) => item.storeType == _storeTypeValueFor(storeFilter)).toList();

  switch (sortMode) {
    case ShoppingSortMode.price:
      final sorted = [...filtered]
        ..sort((a, b) => a.estimatedPriceBought.compareTo(b.estimatedPriceBought));
      return [ShoppingListSection(items: sorted)];

    case ShoppingSortMode.category:
      return _groupBy(
        filtered,
        keyOf: (item) => item.categoryDisplayName ?? item.category ?? uncategorizedKey,
        priorityOrder: null,
      );

    case ShoppingSortMode.store:
      return _groupBy(
        filtered,
        keyOf: (item) => item.storeType,
        priorityOrder: _storeTypeOrder,
      );
  }
}

List<ShoppingListSection> _groupBy(
  List<ShoppingItem> items, {
  required String Function(ShoppingItem) keyOf,
  required List<String>? priorityOrder,
}) {
  final Map<String, List<ShoppingItem>> grouped = {};
  for (final item in items) {
    grouped.putIfAbsent(keyOf(item), () => []).add(item);
  }
  for (final group in grouped.values) {
    group.sort((a, b) => a.name.compareTo(b.name));
  }

  final keys = grouped.keys.toList();
  if (priorityOrder != null) {
    keys.sort((a, b) => priorityOrder.indexOf(a).compareTo(priorityOrder.indexOf(b)));
  } else {
    keys.sort();
  }

  return [
    for (final key in keys) ShoppingListSection(headerKey: key, items: grouped[key]!),
  ];
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/meal_planner/shopping_list_sort_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/shopping_list_sort.dart test/features/meal_planner/shopping_list_sort_test.dart
git commit -m "feat(shopping-list): add pure sort/filter/group logic"
```

---

### Task 5: Add l10n strings

**Files:**
- Modify: `lib/l10n/app_en.arb:783` (insert after `shoppingListRemaining` block)
- Modify: `lib/l10n/app_fr.arb:269` (insert after `shoppingListRemaining` line)

**Interfaces:**
- Produces: `AppLocalizations` getters `shoppingListSortFilterTitle`, `shoppingListSortByLabel`, `shoppingListSortCategory`, `shoppingListSortPrice`, `shoppingListSortStore`, `shoppingListFilterByStoreLabel`, `shoppingListStoreSupermarket`, `shoppingListStoreEpicery`, `shoppingListStoreOther`, `shoppingListUncategorized`, `shoppingListApply` (generated by `flutter gen-l10n`). Consumed by Task 6 and Task 7. (`shoppingListAll` already exists and is reused for the "All" store-filter chip.)

- [ ] **Step 1: Add English keys**

In `lib/l10n/app_en.arb`, after line 783 (`"@shoppingListRemaining": {},`), insert:

```json
  "shoppingListSortFilterTitle": "Sort & Filter",
  "@shoppingListSortFilterTitle": {},
  "shoppingListSortByLabel": "Sort by",
  "@shoppingListSortByLabel": {},
  "shoppingListSortCategory": "Category",
  "@shoppingListSortCategory": {},
  "shoppingListSortPrice": "Price",
  "@shoppingListSortPrice": {},
  "shoppingListSortStore": "Store",
  "@shoppingListSortStore": {},
  "shoppingListFilterByStoreLabel": "Filter by store",
  "@shoppingListFilterByStoreLabel": {},
  "shoppingListStoreSupermarket": "Supermarket",
  "@shoppingListStoreSupermarket": {},
  "shoppingListStoreEpicery": "Grocery",
  "@shoppingListStoreEpicery": {},
  "shoppingListStoreOther": "Other",
  "@shoppingListStoreOther": {},
  "shoppingListUncategorized": "Uncategorized",
  "@shoppingListUncategorized": {},
  "shoppingListApply": "Apply",
  "@shoppingListApply": {},
```

- [ ] **Step 2: Add French keys**

In `lib/l10n/app_fr.arb`, after line 269 (`"shoppingListRemaining": "Restants",`), insert:

```json
  "shoppingListSortFilterTitle": "Trier et filtrer",
  "shoppingListSortByLabel": "Trier par",
  "shoppingListSortCategory": "Catégorie",
  "shoppingListSortPrice": "Prix",
  "shoppingListSortStore": "Magasin",
  "shoppingListFilterByStoreLabel": "Filtrer par magasin",
  "shoppingListStoreSupermarket": "Supermarché",
  "shoppingListStoreEpicery": "Épicerie",
  "shoppingListStoreOther": "Autre",
  "shoppingListUncategorized": "Non catégorisé",
  "shoppingListApply": "Appliquer",
```

- [ ] **Step 3: Regenerate localizations**

```bash
flutter gen-l10n
```

Expected: no errors; `lib/l10n/app_localizations_en.dart` and `app_localizations_fr.dart` now expose the new getters.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart
git commit -m "feat(l10n): add shopping list sort/filter strings (en, fr)"
```

---

### Task 6: Build the `ShoppingSortFilterSheet` widget

**Files:**
- Create: `lib/features/meal_planner/widgets/shopping_sort_filter_sheet.dart`
- Create: `test/features/meal_planner/widgets/shopping_sort_filter_sheet_test.dart`

**Interfaces:**
- Consumes: `ShoppingSortMode`, `StoreTypeFilter` (Task 4); `AppLocalizations` getters from Task 5.
- Produces: `ShoppingSortFilterSheet` widget with constructor `({required ShoppingSortMode sortMode, required StoreTypeFilter storeFilter, required ValueChanged<ShoppingSortMode> onSortModeChanged, required ValueChanged<StoreTypeFilter> onStoreFilterChanged, required VoidCallback onApply})`. Consumed by Task 7.

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/features/meal_planner/widgets/shopping_sort_filter_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/meal_planner/shopping_list_sort.dart';
import 'package:akeli/features/meal_planner/widgets/shopping_sort_filter_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

void main() {
  group('ShoppingSortFilterSheet', () {
    testWidgets('tapping the price chip invokes onSortModeChanged(price)', (tester) async {
      ShoppingSortMode? selected;
      await tester.pumpWidget(_wrap(ShoppingSortFilterSheet(
        sortMode: ShoppingSortMode.category,
        storeFilter: StoreTypeFilter.all,
        onSortModeChanged: (mode) => selected = mode,
        onStoreFilterChanged: (_) {},
        onApply: () {},
      )));

      await tester.tap(find.byKey(const Key('sort-price')));
      await tester.pump();

      expect(selected, ShoppingSortMode.price);
    });

    testWidgets('tapping the supermarket chip invokes onStoreFilterChanged(supermarket)', (tester) async {
      StoreTypeFilter? selected;
      await tester.pumpWidget(_wrap(ShoppingSortFilterSheet(
        sortMode: ShoppingSortMode.category,
        storeFilter: StoreTypeFilter.all,
        onSortModeChanged: (_) {},
        onStoreFilterChanged: (filter) => selected = filter,
        onApply: () {},
      )));

      await tester.tap(find.byKey(const Key('store-filter-supermarket')));
      await tester.pump();

      expect(selected, StoreTypeFilter.supermarket);
    });

    testWidgets('current sortMode chip is shown as selected', (tester) async {
      await tester.pumpWidget(_wrap(ShoppingSortFilterSheet(
        sortMode: ShoppingSortMode.store,
        storeFilter: StoreTypeFilter.all,
        onSortModeChanged: (_) {},
        onStoreFilterChanged: (_) {},
        onApply: () {},
      )));

      final chip = tester.widget<ChoiceChip>(find.byKey(const Key('sort-store')));
      expect(chip.selected, isTrue);

      final otherChip = tester.widget<ChoiceChip>(find.byKey(const Key('sort-category')));
      expect(otherChip.selected, isFalse);
    });

    testWidgets('tapping apply invokes onApply', (tester) async {
      var applied = false;
      await tester.pumpWidget(_wrap(ShoppingSortFilterSheet(
        sortMode: ShoppingSortMode.category,
        storeFilter: StoreTypeFilter.all,
        onSortModeChanged: (_) {},
        onStoreFilterChanged: (_) {},
        onApply: () => applied = true,
      )));

      await tester.tap(find.byKey(const Key('sort-filter-apply')));
      await tester.pump();

      expect(applied, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/meal_planner/widgets/shopping_sort_filter_sheet_test.dart`
Expected: FAIL — `package:akeli/features/meal_planner/widgets/shopping_sort_filter_sheet.dart` does not exist.

- [ ] **Step 3: Implement the widget**

```dart
// lib/features/meal_planner/widgets/shopping_sort_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/shopping_list_sort.dart';

class ShoppingSortFilterSheet extends StatelessWidget {
  final ShoppingSortMode sortMode;
  final StoreTypeFilter storeFilter;
  final ValueChanged<ShoppingSortMode> onSortModeChanged;
  final ValueChanged<StoreTypeFilter> onStoreFilterChanged;
  final VoidCallback onApply;

  const ShoppingSortFilterSheet({
    super.key,
    required this.sortMode,
    required this.storeFilter,
    required this.onSortModeChanged,
    required this.onStoreFilterChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    appLogger.provider('ShoppingSortFilterSheet build() | sortMode: $sortMode | storeFilter: $storeFilter');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shoppingListSortFilterTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AkeliColors.onSurface),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.shoppingListSortByLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('sort-category'),
                  label: Text(l10n.shoppingListSortCategory),
                  selected: sortMode == ShoppingSortMode.category,
                  onSelected: (_) => onSortModeChanged(ShoppingSortMode.category),
                ),
                ChoiceChip(
                  key: const Key('sort-price'),
                  label: Text(l10n.shoppingListSortPrice),
                  selected: sortMode == ShoppingSortMode.price,
                  onSelected: (_) => onSortModeChanged(ShoppingSortMode.price),
                ),
                ChoiceChip(
                  key: const Key('sort-store'),
                  label: Text(l10n.shoppingListSortStore),
                  selected: sortMode == ShoppingSortMode.store,
                  onSelected: (_) => onSortModeChanged(ShoppingSortMode.store),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.shoppingListFilterByStoreLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('store-filter-all'),
                  label: Text(l10n.shoppingListAll),
                  selected: storeFilter == StoreTypeFilter.all,
                  onSelected: (_) => onStoreFilterChanged(StoreTypeFilter.all),
                ),
                ChoiceChip(
                  key: const Key('store-filter-supermarket'),
                  label: Text(l10n.shoppingListStoreSupermarket),
                  selected: storeFilter == StoreTypeFilter.supermarket,
                  onSelected: (_) => onStoreFilterChanged(StoreTypeFilter.supermarket),
                ),
                ChoiceChip(
                  key: const Key('store-filter-epicery'),
                  label: Text(l10n.shoppingListStoreEpicery),
                  selected: storeFilter == StoreTypeFilter.epicery,
                  onSelected: (_) => onStoreFilterChanged(StoreTypeFilter.epicery),
                ),
                ChoiceChip(
                  key: const Key('store-filter-other'),
                  label: Text(l10n.shoppingListStoreOther),
                  selected: storeFilter == StoreTypeFilter.other,
                  onSelected: (_) => onStoreFilterChanged(StoreTypeFilter.other),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('sort-filter-apply'),
                onPressed: onApply,
                child: Text(l10n.shoppingListApply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/meal_planner/widgets/shopping_sort_filter_sheet_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/meal_planner/widgets/shopping_sort_filter_sheet.dart test/features/meal_planner/widgets/shopping_sort_filter_sheet_test.dart
git commit -m "feat(shopping-list): add sort/filter bottom sheet widget"
```

---

### Task 7: Integrate sort/filter into `ShoppingListPage`

**Files:**
- Modify: `lib/features/meal_planner/shopping_list_page.dart` (imports, state fields, the "Filters" row, the trailing `SliverPadding`/`SliverList` block, plus two new private helpers/classes at file scope)

**Interfaces:**
- Consumes: `ShoppingSortMode`, `StoreTypeFilter`, `groupAndSortShoppingItems`, `uncategorizedKey` (Task 4); `ShoppingSortFilterSheet` (Task 6); l10n getters (Task 5).
- Produces: no new public interface — this is the leaf integration point.

- [ ] **Step 1: Add imports and state fields**

At the top of `lib/features/meal_planner/shopping_list_page.dart`, add two imports alongside the existing ones:

```dart
import 'shopping_list_sort.dart';
import 'widgets/shopping_sort_filter_sheet.dart';
```

In `_ShoppingListPageState`, add two fields next to the existing `_filter`:

```dart
class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final _logger = appLogger;
  _ShoppingFilter _filter = _ShoppingFilter.all;
  ShoppingSortMode _sortMode = ShoppingSortMode.category;
  StoreTypeFilter _storeFilter = StoreTypeFilter.all;
```

- [ ] **Step 2: Add the sheet-opening method**

Add this method to `_ShoppingListPageState` (near the `build` method):

```dart
  void _openSortFilterSheet() {
    _logger.userAction('Open sort/filter sheet', screen: 'ShoppingListPage');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AkeliColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return ShoppingSortFilterSheet(
              sortMode: _sortMode,
              storeFilter: _storeFilter,
              onSortModeChanged: (mode) {
                _logger.userAction('Sort mode selected', screen: 'ShoppingListPage', metadata: {'mode': mode.name});
                setState(() => _sortMode = mode);
                setSheetState(() {});
              },
              onStoreFilterChanged: (filter) {
                _logger.userAction('Store filter selected', screen: 'ShoppingListPage', metadata: {'filter': filter.name});
                setState(() => _storeFilter = filter);
                setSheetState(() {});
              },
              onApply: () => Navigator.of(sheetContext).pop(),
            );
          },
        );
      },
    );
  }
```

- [ ] **Step 3: Wrap the "Filters" row with the new icon button**

Replace the existing `// Filters` `Container(...)` block (the one holding the three `_FilterButton`s) with:

```dart
                      // Filters + Sort/Filter entry point
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AkeliColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _FilterButton(
                                    title: l10n.shoppingListAll,
                                    isSelected: _filter == _ShoppingFilter.all,
                                    onTap: () => setState(() {
                                      _logger.userAction('Filter selected', screen: 'ShoppingListPage', metadata: {'filter': 'all'});
                                      _filter = _ShoppingFilter.all;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterButton(
                                    title: l10n.shoppingListChecked,
                                    isSelected: _filter == _ShoppingFilter.bought,
                                    onTap: () => setState(() {
                                      _logger.userAction('Filter selected', screen: 'ShoppingListPage', metadata: {'filter': 'bought'});
                                      _filter = _ShoppingFilter.bought;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterButton(
                                    title: l10n.shoppingListRemaining,
                                    isSelected: _filter == _ShoppingFilter.remaining,
                                    onTap: () => setState(() {
                                      _logger.userAction('Filter selected', screen: 'ShoppingListPage', metadata: {'filter': 'remaining'});
                                      _filter = _ShoppingFilter.remaining;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AkeliColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              key: const Key('sort-filter-button'),
                              icon: const Icon(Icons.tune, color: AkeliColors.onSurfaceVariant),
                              tooltip: l10n.shoppingListSortFilterTitle,
                              onPressed: _openSortFilterSheet,
                            ),
                          ),
                        ],
                      ),
```

- [ ] **Step 4: Replace the flat item list with grouped, headered sections**

Right after the existing `final filteredItems = items.where(...).toList();` computation, add:

```dart
          if (filteredItems.isEmpty) {
            _logger.provider('ShoppingListPage → filtered result empty | filter: $_filter | storeFilter: $_storeFilter');
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: l10n.shoppingListTitle,
              subtitle: l10n.shoppingListEmpty,
            );
          }

          final sections = groupAndSortShoppingItems(
            filteredItems,
            sortMode: _sortMode,
            storeFilter: _storeFilter,
          );
```

This matches the spec's edge case ("If the entire filtered result is empty, reuse the existing `EmptyState` widget") — it replaces the whole scrollable body (cost banner included), the same way the pre-existing `items.isEmpty` check at the top of `data:` already does for the unfiltered case.

Replace the trailing `// Ingredient List` `SliverPadding(...)` block (the last sliver in the `slivers:` list) with a spread of the new helper's output:

```dart
              ..._buildSectionSlivers(sections, l10n, isUsLocale, localeName),
```

- [ ] **Step 5: Add the section-building helper and header delegate**

Add this method to `_ShoppingListPageState`:

```dart
  List<Widget> _buildSectionSlivers(
    List<ShoppingListSection> sections,
    AppLocalizations l10n,
    bool isUsLocale,
    String localeName,
  ) {
    final slivers = <Widget>[];
    for (final section in sections) {
      if (section.headerKey != null) {
        slivers.add(
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeaderDelegate(_headerLabel(section.headerKey!, _sortMode, l10n)),
          ),
        );
      }
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = section.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: AkeliShoppingRow(
                    item: item,
                    isChecked: item.isChecked,
                    isUsLocale: isUsLocale,
                    locale: localeName,
                    onToggle: () {
                      ref.read(shoppingListProvider.notifier).toggleItem(item.id, !item.isChecked);
                    },
                  ),
                );
              },
              childCount: section.items.length,
            ),
          ),
        ),
      );
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 120)));
    return slivers;
  }
```

Add these two file-scope declarations near the existing `_FilterButton` class at the bottom of the file:

```dart
String _headerLabel(String key, ShoppingSortMode mode, AppLocalizations l10n) {
  if (mode == ShoppingSortMode.store) {
    switch (key) {
      case 'supermarket':
        return l10n.shoppingListStoreSupermarket;
      case 'epicery':
        return l10n.shoppingListStoreEpicery;
      default:
        return l10n.shoppingListStoreOther;
    }
  }
  if (key == uncategorizedKey) {
    return l10n.shoppingListUncategorized;
  }
  return key;
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  const _SectionHeaderDelegate(this.label);

  @override
  double get minExtent => 36;

  @override
  double get maxExtent => 36;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AkeliColors.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AkeliColors.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) => oldDelegate.label != label;
}
```

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze lib/features/meal_planner/shopping_list_page.dart`
Expected: no errors (warnings about the pre-existing file are fine; there must be none introduced by this change).

- [ ] **Step 7: Commit**

```bash
git add lib/features/meal_planner/shopping_list_page.dart
git commit -m "feat(shopping-list): add sort/filter UI with grouped section headers"
```

---

### Task 8: Full verification pass

**Files:** none (verification only)

- [ ] **Step 1: Run the full Dart test suite**

```bash
flutter test
```

Expected: all tests pass, including the new ones from Tasks 2, 4, 6.

- [ ] **Step 2: Run static analysis on the whole project**

```bash
flutter analyze
```

Expected: no new errors introduced by this feature (pre-existing warnings elsewhere are out of scope).

- [ ] **Step 3: Re-run the query shape check from Task 3 against remote**

Via Supabase MCP `execute_sql` (project_id: `njzqcftjzskwcpforwzf`), confirm real data resolves as expected for a shopping list with at least one item:

```sql
SELECT i.name, i.category, i.store_type, ic.name_fr AS category_name_fr, ic.name_en AS category_name_en
FROM ingredient i
LEFT JOIN ingredient_category ic ON ic.code = i.category
LIMIT 5;
```

Expected: rows returned with `store_type` populated (defaulting to `'other'` for untagged ingredients) and `category_name_fr`/`category_name_en` populated wherever `category` is set.

- [ ] **Step 4: Manual verification in a running app**

Use the project's `run` skill (or a connected simulator/device) to open the shopping list screen and confirm: the sort/filter icon opens the bottom sheet, switching between Category/Price/Store visibly reorders the list with correct section headers (or none, for Price), and the store-type filter chips hide/show the expected items. Report this as done only after actually observing it — do not claim success from tests alone.
