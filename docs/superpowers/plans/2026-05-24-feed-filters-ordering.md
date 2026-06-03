# Feed Filters & Ordering — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add region, difficulty, time, and sort filters to the Recipes feed page, wiring them to both the personalized RPC (no-filter path) and a direct table query (filtered path).

**Architecture:** `FeedParams` gains an `orderBy` field and a `hasFilters` getter. `feedProvider` branches — if no filters are active it calls `generate_feed_personalized` RPC (preserving personalization); otherwise it queries the `recipe` table directly with PostgREST filters. `searchRecipesProvider` gets the same filter chains applied. The feed page grows a horizontally-scrollable chip row below the search bar with per-chip bottom sheets. A DB migration adds a `total_time_min` generated column so PostgREST can filter by total cook + prep time.

**Tech Stack:** Flutter 3, Riverpod 2, Supabase Dart SDK (PostgREST), GoRouter 14, `AkeliColors`/`AkeliSpacing` from `lib/core/theme.dart`, `foodRegionNamesProvider` from `lib/providers/food_region_provider.dart`.

---

## File Map

**Create:**
- `supabase/migrations/20260524000003_recipe_total_time.sql` — add `total_time_min` generated column

**Modify:**
- `lib/providers/recipe_provider.dart` — `FeedParams.orderBy`, `FeedParams.hasFilters`, `feedProvider` branch, `searchRecipesProvider` filters
- `lib/features/recipes/feed_page.dart` — filter state, filter chip row, bottom sheets

---

## Task 1: DB — add `total_time_min` generated column

**Files:**
- Create: `supabase/migrations/20260524000003_recipe_total_time.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260524000003_recipe_total_time.sql
ALTER TABLE recipe
  ADD COLUMN IF NOT EXISTS total_time_min INTEGER
  GENERATED ALWAYS AS (prep_time_min + cook_time_min) STORED;

COMMENT ON COLUMN recipe.total_time_min IS 'prep_time_min + cook_time_min — used by PostgREST time filters';
```

- [ ] **Step 2: Apply the migration**

Run: `supabase db push`

Expected output: migration applied, no errors.

- [ ] **Step 3: Verify the column**

Run in Supabase SQL editor or via CLI:
```sql
SELECT id, prep_time_min, cook_time_min, total_time_min
FROM recipe
LIMIT 3;
```

Expected: `total_time_min` column present, values equal `prep_time_min + cook_time_min`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260524000003_recipe_total_time.sql
git commit -m "feat(db): add total_time_min generated column to recipe"
```

---

## Task 2: Update `recipe_provider.dart` — FeedParams + provider branching

**Files:**
- Modify: `lib/providers/recipe_provider.dart`

- [ ] **Step 1: Write a unit test for FeedParams.hasFilters**

Create `tests/providers/feed_params_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/recipe_provider.dart';

void main() {
  group('FeedParams.hasFilters', () {
    test('returns false when no filters set', () {
      const p = FeedParams(limit: 20);
      expect(p.hasFilters, isFalse);
    });

    test('returns true when regionId set', () {
      const p = FeedParams(limit: 20, regionId: 'west_africa');
      expect(p.hasFilters, isTrue);
    });

    test('returns true when difficulty set', () {
      const p = FeedParams(limit: 20, difficulty: 'easy');
      expect(p.hasFilters, isTrue);
    });

    test('returns true when maxTimeMin set', () {
      const p = FeedParams(limit: 20, maxTimeMin: 30);
      expect(p.hasFilters, isTrue);
    });

    test('returns true when orderBy set', () {
      const p = FeedParams(limit: 20, orderBy: 'rating');
      expect(p.hasFilters, isTrue);
    });

    test('equality includes orderBy', () {
      const a = FeedParams(limit: 20, orderBy: 'rating');
      const b = FeedParams(limit: 20, orderBy: 'rating');
      const c = FeedParams(limit: 20, orderBy: 'likes');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test tests/providers/feed_params_test.dart`

Expected: FAIL — `FeedParams` has no `orderBy` or `hasFilters`.

- [ ] **Step 3: Update `FeedParams` with `orderBy` + `hasFilters`**

In `lib/providers/recipe_provider.dart`, replace the `FeedParams` class:

```dart
class FeedParams {
  final int limit;
  final List<String> excludeIds;
  final String? regionId;
  final String? difficulty;
  final int? maxTimeMin;
  final String? orderBy; // 'rating' | 'likes' | 'created_at' | null = personalized

  const FeedParams({
    this.limit = 20,
    this.excludeIds = const [],
    this.regionId,
    this.difficulty,
    this.maxTimeMin,
    this.orderBy,
  });

  bool get hasFilters =>
      regionId != null || difficulty != null || maxTimeMin != null || orderBy != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedParams &&
          limit == other.limit &&
          excludeIds.length == other.excludeIds.length &&
          regionId == other.regionId &&
          difficulty == other.difficulty &&
          maxTimeMin == other.maxTimeMin &&
          orderBy == other.orderBy;

  @override
  int get hashCode =>
      Object.hash(limit, excludeIds.length, regionId, difficulty, maxTimeMin, orderBy);
}
```

- [ ] **Step 4: Run the unit test — should pass**

Run: `flutter test tests/providers/feed_params_test.dart`

Expected: PASS (6 tests).

- [ ] **Step 5: Update `feedProvider` with branching logic**

In `lib/providers/recipe_provider.dart`, replace the `feedProvider` body (keep imports and class structure intact):

```dart
final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  appLogger.provider(
      'feedProvider build() | userId: ${user?.id ?? "null"} | hasFilters: ${params.hasFilters} | orderBy: ${params.orderBy}');
  ref.onDispose(() => appLogger.provider('feedProvider disposed'));

  if (user == null) {
    appLogger.provider('feedProvider EARLY RETURN | reason: no authenticated user');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);

  if (!params.hasFilters) {
    // Personalized path — RPC preserves recommendation scores
    final rpcParams = {
      'p_user_id': user.id,
      'p_limit': params.limit,
      'p_exclude': params.excludeIds,
    };
    appLogger.db('BEFORE rpc | fn: generate_feed_personalized | userId: ${user.id} | params: $rpcParams');

    try {
      final rpcData =
          await client.rpc('generate_feed_personalized', params: rpcParams) as List<dynamic>;
      appLogger.db('AFTER rpc | fn: generate_feed_personalized | rows: ${rpcData.length}');

      if (rpcData.isEmpty) {
        appLogger.rls(
            'Zero rows | rpc: generate_feed_personalized | userId: ${user.id} | possible RLS or empty feed');
        return [];
      }

      final recipeIds = rpcData
          .cast<Map<String, dynamic>>()
          .map((e) => e['recipe_id'] as String)
          .toList();

      appLogger.db('BEFORE | table: recipe | op: SELECT in | ids: ${recipeIds.length}');
      final recipeData = await client
          .from('recipe')
          .select()
          .inFilter('id', recipeIds) as List<dynamic>;
      appLogger.db('AFTER | table: recipe | rows: ${recipeData.length}');

      if (recipeData.isEmpty) {
        appLogger.rls('Zero rows | table: recipe | possible RLS block | userId: ${user.id}');
      }

      final recipeMap = {
        for (final r in recipeData.cast<Map<String, dynamic>>()) r['id'] as String: r
      };
      final recipes = recipeIds
          .where(recipeMap.containsKey)
          .map((id) => Recipe.fromJson(recipeMap[id]!))
          .toList();

      appLogger.provider('feedProvider → data (personalized) | recipes: ${recipes.length}');
      return recipes;
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        appLogger.rls('Permission denied | rpc: generate_feed_personalized | userId: ${user.id}',
            error: e, stackTrace: st);
      } else {
        appLogger.db('ERROR rpc | fn: generate_feed_personalized | code: ${e.code} | ${e.message}',
            error: e, stackTrace: st);
      }
      appLogger.provider('feedProvider → error | ${e.message}');
      rethrow;
    } catch (e, st) {
      appLogger.db('ERROR rpc | unexpected: $e', error: e, stackTrace: st);
      appLogger.provider('feedProvider → error | $e');
      rethrow;
    }
  } else {
    // Filtered path — direct recipe table query
    appLogger.db(
        'BEFORE | table: recipe | op: SELECT filtered | region: ${params.regionId} | difficulty: ${params.difficulty} | maxTime: ${params.maxTimeMin} | orderBy: ${params.orderBy}');

    try {
      var query = client.from('recipe').select().eq('is_published', true);

      if (params.regionId != null) query = query.eq('region', params.regionId!);
      if (params.difficulty != null) query = query.eq('difficulty', params.difficulty!);
      if (params.maxTimeMin != null) query = query.lte('total_time_min', params.maxTimeMin!);

      final orderColumn = switch (params.orderBy) {
        'rating' => 'average_rating',
        'likes' => 'like_count',
        'created_at' => 'created_at',
        _ => 'created_at',
      };

      final data = await query
          .order(orderColumn, ascending: false)
          .limit(params.limit) as List<dynamic>;

      appLogger.db('AFTER | table: recipe | rows: ${data.length}');

      if (data.isEmpty) {
        appLogger
            .rls('Zero rows | table: recipe | filtered | userId: ${user.id} | possible RLS or no matches');
      }

      final recipes = data.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
      appLogger.provider('feedProvider → data (filtered) | recipes: ${recipes.length}');
      return recipes;
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        appLogger.rls('Permission denied | table: recipe | filtered | userId: ${user.id}',
            error: e, stackTrace: st);
      } else {
        appLogger.db('ERROR | table: recipe | filtered | code: ${e.code} | ${e.message}',
            error: e, stackTrace: st);
      }
      appLogger.provider('feedProvider → error | ${e.message}');
      rethrow;
    } catch (e, st) {
      appLogger.db('ERROR | table: recipe | filtered | unexpected: $e', error: e, stackTrace: st);
      appLogger.provider('feedProvider → error | $e');
      rethrow;
    }
  }
});
```

- [ ] **Step 6: Fix `searchRecipesProvider` to apply filter params**

Replace the `searchRecipesProvider` body in `lib/providers/recipe_provider.dart`:

```dart
final searchRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, SearchParams>(
        (ref, params) async {
  appLogger.provider(
      'searchRecipesProvider build() | query: "${params.query}" | region: ${params.regionId} | difficulty: ${params.difficulty} | maxTime: ${params.maxTimeMin} | orderBy: ${params.orderBy}');
  ref.onDispose(() => appLogger.provider('searchRecipesProvider disposed | query: "${params.query}"'));

  if (params.query.length < 2) {
    appLogger.provider(
        'searchRecipesProvider EARLY RETURN | reason: query too short (${params.query.length} chars)');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);
  appLogger.db(
      'BEFORE | table: recipe | op: SELECT ilike+filters | query: "${params.query}" | limit: ${params.limit}');

  try {
    var query = client.from('recipe').select().ilike('title', '%${params.query}%');

    if (params.regionId != null) query = query.eq('region', params.regionId!);
    if (params.difficulty != null) query = query.eq('difficulty', params.difficulty!);
    if (params.maxTimeMin != null) query = query.lte('total_time_min', params.maxTimeMin!);

    final orderColumn = switch (params.orderBy) {
      'rating' => 'average_rating',
      'likes' => 'like_count',
      'created_at' => 'created_at',
      _ => null, // relevance = let DB return ilike matches in natural order
    };

    final limitedQuery = orderColumn != null
        ? query.order(orderColumn, ascending: false).limit(params.limit)
        : query.limit(params.limit);

    final data = await limitedQuery as List<dynamic>;

    appLogger.db('AFTER | table: recipe | rows: ${data.length} | query: "${params.query}"');

    if (data.isEmpty) {
      appLogger.rls(
          'Zero rows | table: recipe | search query: "${params.query}" | possible RLS block or no matches');
      appLogger.provider(
          'searchRecipesProvider → data (empty) | no results for "${params.query}"');
    }

    final recipes = data.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
    appLogger.provider('searchRecipesProvider → data | recipes: ${recipes.length}');
    return recipes;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: recipe | search query', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: recipe | search | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('searchRecipesProvider → error | ${e.message}');
    rethrow;
  }
});
```

- [ ] **Step 7: Verify compile — no red squiggles**

Run: `flutter analyze lib/providers/recipe_provider.dart`

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/providers/recipe_provider.dart tests/providers/feed_params_test.dart
git commit -m "feat: FeedParams.orderBy + feedProvider filter branch + searchRecipesProvider filters"
```

---

## Task 3: FeedPage filter UI

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

- [ ] **Step 1: Add filter state fields to `_FeedPageState`**

In `lib/features/recipes/feed_page.dart`, add four fields after `String _searchQuery = '';`:

```dart
String? _regionId;
String? _difficulty;
int? _maxTimeMin;
String? _orderBy;

bool get _hasActiveFilter =>
    _regionId != null || _difficulty != null || _maxTimeMin != null || _orderBy != null;
```

- [ ] **Step 2: Wire filter state into provider params**

Replace the two provider calls at the top of `build()`:

```dart
final isSearching = _searchQuery.length >= 2;
final feedAsync = isSearching
    ? ref.watch(searchRecipesProvider(SearchParams(
        query: _searchQuery,
        regionId: _regionId,
        difficulty: _difficulty,
        maxTimeMin: _maxTimeMin,
        orderBy: _orderBy ?? 'relevance',
        limit: _pageSize,
      )))
    : ref.watch(feedProvider(FeedParams(
        limit: _pageSize,
        regionId: _regionId,
        difficulty: _difficulty,
        maxTimeMin: _maxTimeMin,
        orderBy: _orderBy,
      )));
```

- [ ] **Step 3: Increase `PreferredSize` height from 56 to 104**

In `lib/features/recipes/feed_page.dart`, replace:

```dart
bottom: PreferredSize(
  preferredSize: const Size.fromHeight(56),
```

with:

```dart
bottom: PreferredSize(
  preferredSize: const Size.fromHeight(104),
```

- [ ] **Step 4: Add filter chip row below the SearchBar**

Replace the `child: Padding(...)` content inside the `PreferredSize`. The full `bottom:` block becomes:

```dart
bottom: PreferredSize(
  preferredSize: const Size.fromHeight(104),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AkeliSpacing.md, 0, AkeliSpacing.md, AkeliSpacing.xs),
        child: Theme(
          data: Theme.of(context).copyWith(
            searchBarTheme: const SearchBarThemeData(
              backgroundColor:
                  WidgetStatePropertyAll(AkeliColors.surfaceContainerLow),
            ),
          ),
          child: SearchBar(
            controller: _searchCtrl,
            hintText: 'Rechercher une recette...',
            leading: const Icon(Icons.search_rounded),
            trailing: _searchQuery.isNotEmpty
                ? [
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _logger.userAction('Search cleared', screen: 'FeedPage');
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  ]
                : null,
            onChanged: (v) {
              _logger.userAction('Search query changed',
                  screen: 'FeedPage',
                  metadata: {'length': v.length, 'triggerSearch': v.length >= 2});
              setState(() => _searchQuery = v);
            },
            elevation: const WidgetStatePropertyAll(1),
          ),
        ),
      ),
      SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
          children: [
            _FilterChip(
              label: _regionLabel(),
              active: _regionId != null,
              onTap: () => _showRegionSheet(context),
            ),
            const SizedBox(width: AkeliSpacing.xs),
            _FilterChip(
              label: _difficultyLabel(),
              active: _difficulty != null,
              onTap: () => _showDifficultySheet(context),
            ),
            const SizedBox(width: AkeliSpacing.xs),
            _FilterChip(
              label: _timeLabel(),
              active: _maxTimeMin != null,
              onTap: () => _showTimeSheet(context),
            ),
            const SizedBox(width: AkeliSpacing.xs),
            _FilterChip(
              label: _sortLabel(),
              active: _orderBy != null,
              onTap: () => _showSortSheet(context),
            ),
            if (_hasActiveFilter) ...[
              const SizedBox(width: AkeliSpacing.xs),
              _FilterChip(
                label: '× Effacer',
                active: false,
                onTap: () {
                  _logger.userAction('Feed filters cleared', screen: 'FeedPage');
                  setState(() {
                    _regionId = null;
                    _difficulty = null;
                    _maxTimeMin = null;
                    _orderBy = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AkeliSpacing.xs),
    ],
  ),
),
```

- [ ] **Step 5: Add label helpers and bottom sheet methods to `_FeedPageState`**

Add these methods inside `_FeedPageState` (before `build()`):

```dart
String _regionLabel() {
  if (_regionId == null) return 'Région ▾';
  final names = ref.read(foodRegionNamesProvider).valueOrNull ?? {};
  return names[_regionId!] ?? _regionId!;
}

String _difficultyLabel() => switch (_difficulty) {
      'easy' => 'Facile',
      'medium' => 'Moyen',
      'hard' => 'Difficile',
      _ => 'Difficulté ▾',
    };

String _timeLabel() => switch (_maxTimeMin) {
      30 => '< 30 min',
      60 => '< 60 min',
      90 => '< 90 min',
      _ => 'Temps ▾',
    };

String _sortLabel() => switch (_orderBy) {
      'rating' => 'Mieux noté',
      'likes' => 'Populaire',
      'created_at' => 'Plus récent',
      _ => 'Trier ▾',
    };

void _showRegionSheet(BuildContext context) {
  _logger.userAction('Region filter sheet opened', screen: 'FeedPage');
  final regionNames = ref.read(foodRegionNamesProvider).valueOrNull ?? {};
  final options = [
    const MapEntry<String?, String>(null, 'Toutes les régions'),
    ...regionNames.entries.map((e) => MapEntry<String?, String>(e.key, e.value)),
  ];
  showModalBottomSheet(
    context: context,
    builder: (_) => _FilterSheet(
      title: 'Région',
      options: options,
      selectedKey: _regionId,
      onSelect: (key) {
        _logger.userAction('Region filter selected', screen: 'FeedPage',
            metadata: {'regionId': key});
        setState(() => _regionId = key);
      },
    ),
  );
}

void _showDifficultySheet(BuildContext context) {
  _logger.userAction('Difficulty filter sheet opened', screen: 'FeedPage');
  showModalBottomSheet(
    context: context,
    builder: (_) => _FilterSheet(
      title: 'Difficulté',
      options: const [
        MapEntry(null, 'Tous'),
        MapEntry('easy', 'Facile'),
        MapEntry('medium', 'Moyen'),
        MapEntry('hard', 'Difficile'),
      ],
      selectedKey: _difficulty,
      onSelect: (key) {
        _logger.userAction('Difficulty filter selected', screen: 'FeedPage',
            metadata: {'difficulty': key});
        setState(() => _difficulty = key);
      },
    ),
  );
}

void _showTimeSheet(BuildContext context) {
  _logger.userAction('Time filter sheet opened', screen: 'FeedPage');
  showModalBottomSheet(
    context: context,
    builder: (_) => _FilterSheet<int>(
      title: 'Temps de préparation',
      options: const [
        MapEntry(null, 'Tous'),
        MapEntry(30, 'Moins de 30 min'),
        MapEntry(60, 'Moins de 60 min'),
        MapEntry(90, 'Moins de 90 min'),
      ],
      selectedKey: _maxTimeMin,
      onSelect: (key) {
        _logger.userAction('Time filter selected', screen: 'FeedPage',
            metadata: {'maxTimeMin': key});
        setState(() => _maxTimeMin = key);
      },
    ),
  );
}

void _showSortSheet(BuildContext context) {
  _logger.userAction('Sort sheet opened', screen: 'FeedPage');
  showModalBottomSheet(
    context: context,
    builder: (_) => _FilterSheet(
      title: 'Trier par',
      options: const [
        MapEntry(null, 'Pertinence'),
        MapEntry('rating', 'Mieux noté'),
        MapEntry('likes', 'Plus populaire'),
        MapEntry('created_at', 'Plus récent'),
      ],
      selectedKey: _orderBy,
      onSelect: (key) {
        _logger.userAction('Sort selected', screen: 'FeedPage',
            metadata: {'orderBy': key});
        setState(() => _orderBy = key);
      },
    ),
  );
}
```

- [ ] **Step 6: Add `_FilterChip` and `_FilterSheet` private widgets**

Add at the bottom of `feed_page.dart` (outside `_FeedPageState`, after the class):

```dart
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AkeliSpacing.sm, vertical: AkeliSpacing.xs),
        decoration: BoxDecoration(
          color: active ? AkeliColors.primary : AkeliColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AkeliColors.primary
                : AkeliColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? AkeliColors.onPrimary : AkeliColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FilterSheet<T> extends StatelessWidget {
  final String title;
  final List<MapEntry<T?, String>> options;
  final T? selectedKey;
  final void Function(T? key) onSelect;

  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AkeliSpacing.lg, AkeliSpacing.md, AkeliSpacing.lg, AkeliSpacing.xs),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...options.map((entry) => ListTile(
                title: Text(entry.value),
                trailing: entry.key == selectedKey
                    ? const Icon(Icons.check_rounded, color: AkeliColors.primary)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(entry.key);
                },
              )),
          const SizedBox(height: AkeliSpacing.sm),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Analyze the file**

Run: `flutter analyze lib/features/recipes/feed_page.dart`

Expected: no errors. Fix any type mismatches before committing.

- [ ] **Step 8: Hot-reload smoke test**

Launch the app (`flutter run`) and verify:
1. Feed page shows the filter chip row below the search bar
2. Tapping "Région ▾" opens a bottom sheet listing regions from `foodRegionNamesProvider`
3. Selecting a region updates the chip label and re-fetches recipes
4. Tapping "× Effacer" resets all chips
5. Tapping "Difficulté ▾" → "Facile" → feed shows only easy recipes
6. Tapping "Trier ▾" → "Mieux noté" → feed shows highest rated recipes first
7. Typing in the search bar while filters are active applies both search text + filters

- [ ] **Step 9: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat: feed filter chip row — region, difficulty, time, sort"
```

---

## Spec Coverage Check

| Spec requirement | Covered by |
|---|---|
| `FeedParams.orderBy` field | Task 2 Step 3 |
| `FeedParams.hasFilters` getter | Task 2 Step 3 |
| `feedProvider` branches RPC vs direct query | Task 2 Step 5 |
| `searchRecipesProvider` applies filters | Task 2 Step 6 |
| `_regionId`, `_difficulty`, `_maxTimeMin`, `_orderBy` state | Task 3 Step 1 |
| Filter state wired to providers | Task 3 Step 2 |
| `PreferredSize` height 56 → 104 | Task 3 Step 3 |
| Horizontally scrollable chip row | Task 3 Steps 4–6 |
| Region bottom sheet from `foodRegionNamesProvider` | Task 3 Step 5 |
| Difficulté: Tous/Facile/Moyen/Difficile | Task 3 Step 5 |
| Temps: Tous/<30/<60/<90 min | Task 3 Step 5 |
| Trier: Pertinence/Mieux noté/Plus populaire/Plus récent | Task 3 Step 5 |
| `× Effacer` when any filter active | Task 3 Step 4 |
| Active chip: primary background | Task 3 Step 6 (`_FilterChip`) |
| `total_time_min` DB column for time filter | Task 1 |
