# Feed Pagination — Infinite Scroll Design Spec

**Date:** 2026-05-30
**Scope:** Infinite scroll pagination for the recipe feed (personalized + search) and the creator feed in `FeedPage`

---

## Goal

Replace the fixed 20-item lists in the recipe feed and creator feed with infinite scroll — loading 20 more items each time the user reaches the bottom of the list.

---

## Architecture

All pagination state lives in `_FeedPageState` (already a `ConsumerStatefulWidget`). No new providers, no `AsyncNotifier`, no `StateNotifier` — the widget manages accumulated lists imperatively. The existing reactive providers (`feedProvider`, `searchRecipesProvider`, `creatorsListProvider`) continue to power the first page unchanged.

**Cursor strategy per feed:**

| Feed | Cursor | Reason |
|---|---|---|
| Personalized recipe feed | Exclude-list (`FeedParams.excludeIds`) | RPC ordering shifts nightly; exclude-list prevents duplicates across pages |
| Search results | Offset (`SearchParams.offset`, already defined, unused) | Search order is deterministic; offset is safe and simple |
| Creator feed | Exclude-list (`p_exclude` param on `generate_creators_personalized`) | Same reasoning as recipe feed |

**Scroll detection:** `NotificationListener<ScrollNotification>` wraps the `CustomScrollView`. Calls `_loadMore*()` when `notification.metrics.extentAfter < 300.0` and not already loading.

---

## State Variables

Added to `_FeedPageState`:

```dart
// Recipe feed — personalized
List<Recipe> _recipes        = [];
bool _hasMoreRecipes         = true;
bool _loadingMoreRecipes     = false;
Set<String>  _seenRecipeIds  = {};      // exclude-list cursor

// Recipe feed — search
List<Recipe> _searchResults  = [];
bool _hasMoreSearch          = true;
bool _loadingMoreSearch      = false;
int  _searchOffset           = 0;       // offset cursor

// Creator feed
List<Creator> _creators            = [];
bool          _hasMoreCreators     = true;
bool          _loadingMoreCreators = false;
Set<String>   _seenCreatorIds      = {};  // exclude-list cursor
```

---

## Seeding First Page from Existing Providers

The reactive providers still drive the first page. When their data arrives, the `.when(data: ...)` handler seeds the local lists **once** (only when the local list is empty, to avoid overwriting pages already loaded):

```dart
// Recipe feed (in SliverAppBar content area or build method):
feedAsync.when(
  data: (recipes) {
    if (_recipes.isEmpty && recipes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {
          _recipes = List.from(recipes);
          _seenRecipeIds = recipes.map((r) => r.id).toSet();
        });
      });
    }
    // render from _recipes, not from recipes
  },
  ...
)
```

The same pattern applies to `creatorsListProvider` seeding `_creators`.

---

## Load-More Methods

### `_loadMoreRecipes()` — personalized feed

```dart
Future<void> _loadMoreRecipes() async {
  if (_loadingMoreRecipes || !_hasMoreRecipes) return;
  setState(() => _loadingMoreRecipes = true);

  final params = FeedParams(
    limit: _pageSize,
    excludeIds: _seenRecipeIds.toList(),
    regionId: _regionId,
    difficulty: _difficulty,
    maxTimeMin: _maxTimeMin,
    minCal: _minCal,
    maxCal: _maxCal,
    orderBy: _orderBy,
  );

  try {
    final page = await ref.read(feedProvider(params).future);
    setState(() {
      if (page.isEmpty) {
        _hasMoreRecipes = false;
      } else {
        _recipes.addAll(page);
        _seenRecipeIds.addAll(page.map((r) => r.id));
        if (page.length < _pageSize) _hasMoreRecipes = false;
      }
    });
  } catch (e, st) {
    _logger.db('ERROR | _loadMoreRecipes | $e', error: e, stackTrace: st);
  } finally {
    if (mounted) setState(() => _loadingMoreRecipes = false);
  }
}
```

### `_loadMoreSearch()` — search mode

```dart
Future<void> _loadMoreSearch() async {
  if (_loadingMoreSearch || !_hasMoreSearch) return;
  setState(() => _loadingMoreSearch = true);

  final params = SearchParams(
    query: _searchQuery,
    regionId: _regionId,
    difficulty: _difficulty,
    maxTimeMin: _maxTimeMin,
    minCal: _minCal,
    maxCal: _maxCal,
    orderBy: _orderBy ?? 'relevance',
    limit: _pageSize,
    offset: _searchOffset,
  );

  try {
    final page = await ref.read(searchRecipesProvider(params).future);
    setState(() {
      if (page.isEmpty || page.length < _pageSize) {
        _hasMoreSearch = false;
      }
      _searchResults.addAll(page);
      _searchOffset += page.length;
    });
  } catch (e, st) {
    _logger.db('ERROR | _loadMoreSearch | $e', error: e, stackTrace: st);
  } finally {
    if (mounted) setState(() => _loadingMoreSearch = false);
  }
}
```

### `_loadMoreCreators()` — creator feed

Two-step: call RPC for ordered IDs, then fetch full creator data. Uses `ref.read(supabaseClientProvider)` directly (same logic as `creatorsListProvider` but with `p_exclude`).

```dart
Future<void> _loadMoreCreators() async {
  if (_loadingMoreCreators || !_hasMoreCreators) return;
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  setState(() => _loadingMoreCreators = true);
  final client = ref.read(supabaseClientProvider);

  try {
    final rpcRows = await client.rpc('generate_creators_personalized', params: {
      'p_user_id': user.id,
      'p_limit': _pageSize,
      'p_exclude': _seenCreatorIds.toList(),
    }) as List<dynamic>;

    if (rpcRows.isEmpty) {
      setState(() => _hasMoreCreators = false);
      return;
    }

    final orderedIds = rpcRows
        .map((r) => (r as Map<String, dynamic>)['creator_id'] as String)
        .toList();

    final rows = await client
        .from('creator')
        .select('id, user_id, display_name, avatar_url, bio, specialties, recipe_count, fan_count, average_rating, food_region_id')
        .inFilter('id', orderedIds) as List<dynamic>;

    final creatorMap = {
      for (final r in rows)
        (r as Map<String, dynamic>)['id'] as String: Creator.fromJson(r)
    };
    final page = orderedIds
        .where((id) => creatorMap.containsKey(id))
        .map((id) => creatorMap[id]!)
        .toList();

    setState(() {
      if (page.isEmpty || page.length < _pageSize) _hasMoreCreators = false;
      _creators.addAll(page);
      _seenCreatorIds.addAll(page.map((c) => c.id));
    });
  } catch (e, st) {
    _logger.db('ERROR | _loadMoreCreators | $e', error: e, stackTrace: st);
  } finally {
    if (mounted) setState(() => _loadingMoreCreators = false);
  }
}
```

---

## Reset on State Changes

Any change to filters, search query, or tab triggers a reset of the affected list:

```dart
// Recipe reset (call before any setState that changes filter/search params):
void _resetRecipes() {
  _recipes.clear();
  _seenRecipeIds.clear();
  _hasMoreRecipes = true;
  _loadingMoreRecipes = false;
  // Also reset search state if was searching:
  _searchResults.clear();
  _searchOffset = 0;
  _hasMoreSearch = true;
  _loadingMoreSearch = false;
}

// Creator reset (call on tab switch to Créateurs):
void _resetCreators() {
  _creators.clear();
  _seenCreatorIds.clear();
  _hasMoreCreators = true;
  _loadingMoreCreators = false;
}
```

Called:
- `_resetRecipes()` — on filter change, sort change, search query change
- `_resetCreators()` — on tab switch to Créateurs (tab index 1)
- Both — on tab switch away from a tab with loaded data

---

## Scroll Detection

```dart
// Wrap CustomScrollView:
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification.metrics.extentAfter < 300.0) {
      if (_tabIndex == 0) {
        final isSearching = _searchQuery.length >= 2;
        isSearching ? _loadMoreSearch() : _loadMoreRecipes();
      } else {
        _loadMoreCreators();
      }
    }
    return false; // don't absorb the notification
  },
  child: CustomScrollView(...),
)
```

---

## UI Footer Slivers

Added as the last sliver in each tab's sliver list:

```dart
// After recipe grid / creator list:
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: _tabIndex == 0
        ? _buildRecipeFooter()
        : _buildCreatorFooter(),
  ),
)

Widget _buildRecipeFooter() {
  final loading = _searchQuery.length >= 2 ? _loadingMoreSearch : _loadingMoreRecipes;
  final hasMore = _searchQuery.length >= 2 ? _hasMoreSearch : _hasMoreRecipes;
  final hasItems = _searchQuery.length >= 2 ? _searchResults.isNotEmpty : _recipes.isNotEmpty;
  if (loading) return const Center(child: CircularProgressIndicator());
  if (!hasMore && hasItems) return const Center(child: Text('Vous avez tout vu ✓', style: TextStyle(color: AkeliColors.textSecondary)));
  return const SizedBox.shrink();
}

Widget _buildCreatorFooter() {
  if (_loadingMoreCreators) return const Center(child: CircularProgressIndicator());
  if (!_hasMoreCreators && _creators.isNotEmpty) return const Center(child: Text('Vous avez tout vu ✓', style: TextStyle(color: AkeliColors.textSecondary)));
  return const SizedBox.shrink();
}
```

---

## SliverGrid / SliverList render from local state

The recipe grid switches from watching `feedAsync` to rendering `_recipes` (or `_searchResults`):

```dart
// Replace feedAsync.when(data: (recipes) { SliverGrid(recipes) })
// with:
if (_recipes.isNotEmpty)
  SliverPadding(
    padding: const EdgeInsets.all(AkeliSpacing.md),
    sliver: SliverGrid.builder(
      itemCount: _recipes.length,   // from local state
      itemBuilder: (context, index) => AkeliRecipeCard(recipe: _recipes[index], ...),
      ...
    ),
  )
else
  feedAsync.when(
    loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
    error: ...
    data: (firstPage) {
      // seed _recipes on first arrival
      ...
    }
  )
```

Similarly `_buildCreateursSliver` renders from `_creators` once seeded.

---

## Files Modified

| File | Change |
|---|---|
| `lib/features/recipes/feed_page.dart` | Add pagination state, load-more methods, NotificationListener, footer slivers, seed logic |

No other files need changes — existing providers are reused as-is.

---

## Out of Scope (V1)

- Pull-to-refresh (invalidates providers, resets state — separate feature)
- Page size configuration (always `_pageSize = 20`)
- Prefetching next page before user reaches bottom
