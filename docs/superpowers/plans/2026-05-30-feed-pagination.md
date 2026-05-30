# Feed Pagination — Infinite Scroll Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add infinite scroll pagination to the recipe feed (personalized + search) and the creator feed inside `FeedPage`, loading 20 more items each time the user scrolls near the bottom.

**Architecture:** All pagination state lives in `_FeedPageState`. Existing `feedProvider` / `creatorsListProvider` seed the first page via `WidgetsBinding.addPostFrameCallback`; subsequent pages are fetched imperatively. Recipe feed uses an exclude-list cursor (`FeedParams.excludeIds`); search uses an offset cursor (`SearchParams.offset`); creator feed calls `generate_creators_personalized` directly with `p_exclude`.

**Tech Stack:** Flutter, Riverpod (`FutureProvider.family`), Supabase PostgREST, `NotificationListener<ScrollNotification>`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/recipes/feed_page.dart` | Modify | All pagination state, load-more methods, scroll detection, footer slivers |

No other files need changes.

---

## Task 1: Add Imports, State Variables, and Reset Methods

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

- [ ] **Step 1: Add missing imports**

At the top of `lib/features/recipes/feed_page.dart`, after the existing imports (after line 17), add:

```dart
import '../../core/supabase_client.dart';
import '../../providers/auth_provider.dart';
import '../../shared/models/creator.dart';
import '../../shared/models/recipe.dart';
```

- [ ] **Step 2: Add pagination state variables to `_FeedPageState`**

In `_FeedPageState`, after the line `int _tabIndex = 0;` (around line 39), add:

```dart
  // ---- Recipe feed pagination (personalized) ----
  List<Recipe> _recipes = [];
  bool _hasMoreRecipes = true;
  bool _loadingMoreRecipes = false;
  Set<String> _seenRecipeIds = {};

  // ---- Recipe feed pagination (search) ----
  List<Recipe> _searchResults = [];
  bool _hasMoreSearch = true;
  bool _loadingMoreSearch = false;
  int _searchOffset = 0;

  // ---- Creator feed pagination ----
  List<Creator> _creators = [];
  bool _hasMoreCreators = true;
  bool _loadingMoreCreators = false;
  Set<String> _seenCreatorIds = {};
```

- [ ] **Step 3: Add `_resetRecipes()` and `_resetCreators()` methods**

After the `dispose()` method, add:

```dart
  void _resetRecipes() {
    _recipes.clear();
    _seenRecipeIds.clear();
    _hasMoreRecipes = true;
    _loadingMoreRecipes = false;
    _searchResults.clear();
    _searchOffset = 0;
    _hasMoreSearch = true;
    _loadingMoreSearch = false;
  }

  void _resetCreators() {
    _creators.clear();
    _seenCreatorIds.clear();
    _hasMoreCreators = true;
    _loadingMoreCreators = false;
  }
```

- [ ] **Step 4: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: No errors (new state variables unused yet — that's fine).

- [ ] **Step 5: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat(feed/pagination): add pagination state variables and reset methods"
```

---

## Task 2: Add Load-More Methods

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

- [ ] **Step 1: Add `_loadMoreRecipes()` after `_resetCreators()`**

```dart
  Future<void> _loadMoreRecipes() async {
    if (_loadingMoreRecipes || !_hasMoreRecipes) return;
    _logger.userAction('Load more recipes triggered', screen: 'FeedPage',
        metadata: {'seenCount': _seenRecipeIds.length.toString()});
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
      _logger.db('AFTER rpc | fn: generate_feed_personalized | page rows: ${page.length}');
      if (mounted) setState(() {
        if (page.isEmpty || page.length < _pageSize) _hasMoreRecipes = false;
        _recipes.addAll(page);
        _seenRecipeIds.addAll(page.map((r) => r.id));
      });
    } catch (e, st) {
      _logger.db('ERROR | _loadMoreRecipes | $e', error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _loadingMoreRecipes = false);
    }
  }
```

- [ ] **Step 2: Add `_loadMoreSearch()` after `_loadMoreRecipes()`**

```dart
  Future<void> _loadMoreSearch() async {
    if (_loadingMoreSearch || !_hasMoreSearch) return;
    _logger.userAction('Load more search triggered', screen: 'FeedPage',
        metadata: {'offset': _searchOffset.toString(), 'query': _searchQuery});
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
      _logger.db('AFTER | searchRecipesProvider | page rows: ${page.length} | offset: $_searchOffset');
      if (mounted) setState(() {
        if (page.isEmpty || page.length < _pageSize) _hasMoreSearch = false;
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

- [ ] **Step 3: Add `_loadMoreCreators()` after `_loadMoreSearch()`**

```dart
  Future<void> _loadMoreCreators() async {
    if (_loadingMoreCreators || !_hasMoreCreators) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Load more creators triggered', screen: 'FeedPage',
        metadata: {'seenCount': _seenCreatorIds.length.toString()});
    setState(() => _loadingMoreCreators = true);

    final client = ref.read(supabaseClientProvider);
    try {
      _logger.db('BEFORE rpc | fn: generate_creators_personalized | p_exclude: ${_seenCreatorIds.length}');
      final rpcRows = await client.rpc('generate_creators_personalized', params: {
        'p_user_id': user.id,
        'p_limit': _pageSize,
        'p_exclude': _seenCreatorIds.toList(),
      }) as List<dynamic>;
      _logger.db('AFTER rpc | fn: generate_creators_personalized | rows: ${rpcRows.length}');

      if (rpcRows.isEmpty) {
        if (mounted) setState(() => _hasMoreCreators = false);
        return;
      }

      final orderedIds = rpcRows
          .map((r) => (r as Map<String, dynamic>)['creator_id'] as String)
          .toList();

      _logger.db('BEFORE | table: creator | op: SELECT IN | ids: ${orderedIds.length}');
      final rows = await client
          .from('creator')
          .select('id, user_id, display_name, avatar_url, bio, specialties, recipe_count, fan_count, average_rating, food_region_id')
          .inFilter('id', orderedIds) as List<dynamic>;
      _logger.db('AFTER | table: creator | rows: ${rows.length}');

      final creatorMap = {
        for (final r in rows)
          (r as Map<String, dynamic>)['id'] as String: Creator.fromJson(r)
      };
      final page = orderedIds
          .where((id) => creatorMap.containsKey(id))
          .map((id) => creatorMap[id]!)
          .toList();

      if (mounted) setState(() {
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

- [ ] **Step 4: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat(feed/pagination): add _loadMoreRecipes, _loadMoreSearch, _loadMoreCreators"
```

---

## Task 3: Wire Reset Calls to Filter/Search/Tab Changes

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

Every state change that invalidates the current list must call the appropriate reset method before the `setState` that changes the param.

- [ ] **Step 1: Reset on search query change**

Find the `onChanged` handler of the `SearchBar` widget (around line 354). It currently reads:
```dart
onChanged: (v) {
  setState(() => _searchQuery = v);
},
```

Replace with:
```dart
onChanged: (v) {
  _logger.userAction('Search query changed', screen: 'FeedPage');
  _resetRecipes();
  setState(() => _searchQuery = v);
},
```

- [ ] **Step 2: Reset on filter apply**

In `_showCombinedFilterSheet`, find the "Appliquer" / apply button's `onPressed` callback. It currently calls `setState(() { _regionId = ...; _difficulty = ...; })`. Add `_resetRecipes()` before the setState:

```dart
onPressed: () {
  _resetRecipes();
  setState(() {
    _regionId = tempRegion;
    _difficulty = tempDiff;
    _maxTimeMin = tempTime;
    _minCal = tempMinCal;
    _maxCal = tempMaxCal;
  });
  Navigator.pop(context);
},
```

Also find the "Tout effacer" TextButton `onPressed` (around line 467) which resets all filters. Add `_resetRecipes()` before its setState:

```dart
onPressed: () {
  _resetRecipes();
  setState(() {
    _regionId = null;
    _difficulty = null;
    _maxTimeMin = null;
    _minCal = null;
    _maxCal = null;
    _orderBy = null;
  });
},
```

- [ ] **Step 3: Reset on sort change**

In `_showSortSheet`, the `onSelect` callback reads `setState(() => _orderBy = key)`. Replace with:

```dart
onSelect: (key) {
  _logger.userAction('Sort selected', screen: 'FeedPage',
      metadata: {'orderBy': key});
  _resetRecipes();
  setState(() => _orderBy = key);
},
```

- [ ] **Step 4: Reset on search clear**

Find the clear `IconButton` in the `SearchBar.trailing` list. It currently calls:
```dart
onPressed: () {
  _logger.userAction('Search cleared', screen: 'FeedPage');
  _searchCtrl.clear();
  setState(() => _searchQuery = '');
},
```

Add `_resetRecipes()` before the setState:
```dart
onPressed: () {
  _logger.userAction('Search cleared', screen: 'FeedPage');
  _resetRecipes();
  _searchCtrl.clear();
  setState(() => _searchQuery = '');
},
```

- [ ] **Step 5: Reset on tab switch**

Find the `onTabSelected` callback of `AkeliTabBar` (around line 338). It currently reads:
```dart
onTabSelected: (i) {
  _logger.userAction('Feed tab selected', screen: 'FeedPage',
      metadata: {'tabIndex': i.toString()});
  setState(() => _tabIndex = i);
},
```

Replace with:
```dart
onTabSelected: (i) {
  _logger.userAction('Feed tab selected', screen: 'FeedPage',
      metadata: {'tabIndex': i.toString()});
  if (i == 1) _resetCreators();  // switching TO creators tab
  if (i == 0) _resetRecipes();   // switching TO recipes tab
  setState(() => _tabIndex = i);
},
```

- [ ] **Step 6: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat(feed/pagination): reset pagination state on filter/search/tab changes"
```

---

## Task 4: Seed First Page and Render from Local State

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

Replace reactive `feedAsync.when(...)` and `creatorsAsync.when(...)` rendering with local-state rendering. Providers still load the first page; `addPostFrameCallback` seeds local state on arrival.

- [ ] **Step 1: Seed recipe list in `build()`**

In the `build()` method, after the `feedAsync` and `creatorsAsync` declarations (after line 299 roughly), add seeding logic:

```dart
    // Seed recipes from first-page provider result
    feedAsync.whenData((firstPage) {
      final localEmpty = isSearching ? _searchResults.isEmpty : _recipes.isEmpty;
      if (localEmpty && firstPage.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final stillEmpty = isSearching ? _searchResults.isEmpty : _recipes.isEmpty;
          if (stillEmpty) setState(() {
            if (isSearching) {
              _searchResults = List.from(firstPage);
              _searchOffset = firstPage.length;
              _hasMoreSearch = firstPage.length >= _pageSize;
            } else {
              _recipes = List.from(firstPage);
              _seenRecipeIds = firstPage.map((r) => r.id).toSet();
              _hasMoreRecipes = firstPage.length >= _pageSize;
            }
          });
        });
      }
    });

    // Seed creators from first-page provider result
    final creatorsAsync = ref.watch(creatorsListProvider);
    creatorsAsync.whenData((firstPage) {
      if (_creators.isEmpty && firstPage.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_creators.isEmpty) setState(() {
            _creators = List.from(firstPage);
            _seenCreatorIds = firstPage.map((c) => c.id).toSet();
            _hasMoreCreators = firstPage.length >= _pageSize;
          });
        });
      }
    });
```

Note: `creatorsAsync` was previously declared inside `_buildCreateursSliver`. Move the declaration to `build()` as shown above, then pass it into the sliver builder.

- [ ] **Step 2: Replace the recipe content sliver with local-state rendering**

Find the `// Content` section (around line 490). The current code is:

```dart
        if (_tabIndex == 0)
          feedAsync.when(...)
        else
          _buildCreateursSliver(regionNames),
```

Replace the recipe content sliver (the `feedAsync.when(...)` block) with a new helper call, keeping the else branch:

```dart
        if (_tabIndex == 0)
          _buildRecipeSliver(feedAsync, isSearching, regionNames)
        else
          _buildCreateursSliver(creatorsAsync, regionNames),
```

- [ ] **Step 3: Add `_buildRecipeSliver` method**

Add this method after `_buildCreateursSliver` (before the closing `}` of the class):

```dart
  Widget _buildRecipeSliver(
    AsyncValue feedAsync,
    bool isSearching,
    Map<String, String> regionNames,
  ) {
    final localItems = isSearching ? _searchResults : _recipes;

    // While local list is empty, fall back to reactive state for loading/error/empty display
    if (localItems.isEmpty) {
      return feedAsync.when(
        loading: () => const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => SliverFillRemaining(
          child: ErrorState(
            message: err.toString(),
            onRetry: () => isSearching
                ? ref.invalidate(searchRecipesProvider)
                : ref.invalidate(feedProvider),
          ),
        ),
        data: (data) {
          if (data.isEmpty) {
            return SliverFillRemaining(
              child: EmptyState(
                icon: Icons.restaurant_menu_rounded,
                title: isSearching ? 'Aucune recette trouvée' : 'Pas encore de recettes',
                subtitle: isSearching
                    ? 'Essayez d\'autres termes de recherche.'
                    : 'Explorez et découvrez des recettes africaines.',
              ),
            );
          }
          // Data arrived, seeding is in progress (addPostFrameCallback not yet fired)
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AkeliSpacing.md,
          mainAxisSpacing: AkeliSpacing.md,
          childAspectRatio: 0.68,
        ),
        itemCount: localItems.length,
        itemBuilder: (context, index) {
          final recipe = localItems[index];
          return AkeliRecipeCard(
            hasImage: true,
            title: recipe.title,
            calories: recipe.calories?.toInt() ?? 0,
            rating: recipe.averageRating,
            likes: recipe.likeCount,
            comments: 0,
            saves: 0,
            emoji: null,
            region: recipe.regionId != null
                ? regionNames[recipe.regionId!] ?? recipe.regionId
                : null,
            tags: recipe.tagIds.take(2).toList(),
            onTap: () {
              _logger.userAction('Recipe card tapped', screen: 'FeedPage',
                  metadata: {'recipeId': recipe.id});
              if (widget.swapEntryId != null) {
                ref.read(mealPlanSwapProvider.notifier).swapMeal(widget.swapEntryId!, recipe.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Repas remplacé avec succès'),
                  backgroundColor: AkeliColors.primary,
                ));
                context.pop();
              } else {
                context.push(
                  AkeliRoutes.recipeDetailPath(recipe.id),
                  extra: TrackingSource.feed,
                );
              }
            },
          );
        },
      ),
    );
  }
```

- [ ] **Step 4: Update `_buildCreateursSliver` signature and rendering**

Change the signature from:
```dart
Widget _buildCreateursSliver(Map<String, String> regionNames) {
  final creatorsAsync = ref.watch(creatorsListProvider);
```
to:
```dart
Widget _buildCreateursSliver(AsyncValue<List<Creator>> creatorsAsync, Map<String, String> regionNames) {
```

Then replace the `data: (creators)` branch body. Find:
```dart
      data: (creators) {
        if (creators.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyState(
              icon: Icons.person_rounded,
              title: 'Aucun créateur disponible',
              subtitle: 'Les créateurs apparaîtront ici.',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final creator = creators[index];
```

Replace the entire `data:` callback with:

```dart
      data: (serverData) {
        // Use local state if seeded; fall back to serverData for empty check
        final creators = _creators.isNotEmpty ? _creators : serverData;
        if (creators.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyState(
              icon: Icons.person_rounded,
              title: 'Aucun créateur disponible',
              subtitle: 'Les créateurs apparaîtront ici.',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final creator = creators[index];
```

- [ ] **Step 5: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat(feed/pagination): seed first page and render from local state"
```

---

## Task 5: Scroll Detection + Footer Slivers

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

- [ ] **Step 1: Wrap `CustomScrollView` with `NotificationListener`**

In `build()`, find the line:
```dart
    return CustomScrollView(
```

Replace it with:
```dart
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 300.0) {
          if (_tabIndex == 0) {
            final searching = _searchQuery.length >= 2;
            if (searching) {
              _loadMoreSearch();
            } else {
              _loadMoreRecipes();
            }
          } else {
            _loadMoreCreators();
          }
        }
        return false;
      },
      child: CustomScrollView(
```

And close the `NotificationListener` by adding `)` after the existing closing `)` of `CustomScrollView`. The structure becomes:

```dart
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) { ... },
      child: CustomScrollView(
        slivers: [
          // ... existing slivers ...
        ],
      ),  // end CustomScrollView
    );    // end NotificationListener
```

- [ ] **Step 2: Add `_buildRecipeFooter()` and `_buildCreatorFooter()` methods**

Add after `_buildRecipeSliver`:

```dart
  Widget _buildRecipeFooter(bool isSearching) {
    final loading = isSearching ? _loadingMoreSearch : _loadingMoreRecipes;
    final hasMore = isSearching ? _hasMoreSearch : _hasMoreRecipes;
    final hasItems = isSearching ? _searchResults.isNotEmpty : _recipes.isNotEmpty;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!hasMore && hasItems) {
      return const Center(
        child: Text(
          'Vous avez tout vu ✓',
          style: TextStyle(color: AkeliColors.textSecondary, fontSize: 13),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCreatorFooter() {
    if (_loadingMoreCreators) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasMoreCreators && _creators.isNotEmpty) {
      return const Center(
        child: Text(
          'Vous avez tout vu ✓',
          style: TextStyle(color: AkeliColors.textSecondary, fontSize: 13),
        ),
      );
    }
    return const SizedBox.shrink();
  }
```

- [ ] **Step 3: Add footer slivers**

In the `slivers:` list of `CustomScrollView`, after the content sliver (after `_buildRecipeSliver(...)` / `_buildCreateursSliver(...)` line), add:

```dart
        // Pagination footer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: _tabIndex == 0
                ? _buildRecipeFooter(isSearching)
                : _buildCreatorFooter(),
          ),
        ),
```

- [ ] **Step 4: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat(feed/pagination): add scroll detection and footer slivers"
```

---

## Task 6: Manual Testing Checklist

- [ ] **Step 1: Run the app**

```
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
flutter run
```

- [ ] **Step 2: Test recipe feed infinite scroll**

1. Navigate to the Recettes tab.
2. Confirm the first 20 recipes load.
3. Scroll to the bottom — confirm a `CircularProgressIndicator` appears briefly.
4. Confirm more recipes load and are appended (total > 20).
5. When no more recipes remain, confirm "Vous avez tout vu ✓" appears.

- [ ] **Step 3: Test search infinite scroll**

1. Type at least 2 characters in the search bar.
2. Confirm first 20 results load.
3. Scroll to bottom — confirm more results load (offset increments).
4. Clear search — confirm recipe list resets to personalized feed.

- [ ] **Step 4: Test filter reset**

1. Load the recipe feed (first page seeded).
2. Open filters, change a filter (e.g., select "Facile" difficulty).
3. Apply — confirm the recipe list resets and reloads from page 1 with the new filter.
4. Confirm no duplicate items from before the filter change.

- [ ] **Step 5: Test creator feed infinite scroll**

1. Switch to the "Créateurs" tab.
2. Confirm the first creators load.
3. Scroll to bottom — confirm more creators load (if > 20 exist) or "Vous avez tout vu ✓" appears.

- [ ] **Step 6: Commit sign-off**

```bash
git commit --allow-empty -m "test(feed/pagination): manual test pass — infinite scroll working on recipe and creator feeds"
```
