# Creators Tab — Search, Filter & Sort Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a search bar + filter icon (🎚) + sort icon (🔃) to the Créateurs tab in `FeedPage`, with client-side filter/sort on the 20-creator RPC result.

**Architecture:** Four new state fields in `_FeedPageState` drive a synchronous `_filteredCreators` getter. Two new bottom-sheet methods mirror the existing recipe filter/sort sheets. A new `_buildCreatorSearchControls` sliver is injected before the creator list in `build()`.

**Tech Stack:** Flutter/Riverpod, Dart, `flutter_test`

---

## File Map

| File | Change |
|------|--------|
| `lib/features/recipes/feed_page.dart` | State fields, getters, sheet methods, search controls widget, `build()` wiring |
| `test/features/recipes/creators_filter_test.dart` | Unit tests for `filterAndSortCreators` |

---

### Task 1: Extract and test the filter/sort logic

**Files:**
- Create: `test/features/recipes/creators_filter_test.dart`
- Modify: `lib/features/recipes/feed_page.dart` (add top-level function before `class FeedPage`)

- [ ] **Step 1: Write the failing test**

Create `test/features/recipes/creators_filter_test.dart`:

```dart
// test/features/recipes/creators_filter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/creator.dart';
import 'package:akeli/features/recipes/feed_page.dart';

Creator _c({
  required String id,
  required String name,
  String? regionId,
  List<String> specialties = const [],
  int fanCount = 0,
  int recipeCount = 0,
  double averageRating = 0.0,
}) =>
    Creator(
      id: id,
      userId: 'u$id',
      displayName: name,
      specialties: specialties,
      recipeCount: recipeCount,
      fanCount: fanCount,
      isFanEligible: false,
      isMyFanCreator: false,
      averageRating: averageRating,
      regionId: regionId,
    );

void main() {
  final creators = [
    _c(id: '1', name: 'Aminata Mbaye', regionId: 'sn', specialties: ['Cuisine traditionnelle'], fanCount: 200, recipeCount: 24, averageRating: 4.8),
    _c(id: '2', name: 'Fatou Konaté',  regionId: 'ml', specialties: ['Cuisine familiale'],      fanCount: 80,  recipeCount: 17, averageRating: 4.2),
    _c(id: '3', name: 'Grace Nkosi',   regionId: 'cm', specialties: ['Cuisine fusion'],          fanCount: 350, recipeCount: 31, averageRating: 4.6),
  ];

  group('filterAndSortCreators', () {
    test('no filters returns all creators in original order', () {
      final result = filterAndSortCreators(creators);
      expect(result.map((c) => c.id).toList(), ['1', '2', '3']);
    });

    test('query filters by displayName case-insensitively', () {
      final result = filterAndSortCreators(creators, query: 'aminata');
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('query with no match returns empty list', () {
      final result = filterAndSortCreators(creators, query: 'zzz');
      expect(result, isEmpty);
    });

    test('regionId filters by regionId', () {
      final result = filterAndSortCreators(creators, regionId: 'ml');
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('specialty filters by specialties list containment', () {
      final result = filterAndSortCreators(creators, specialty: 'Cuisine fusion');
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('orderBy rating sorts descending by averageRating', () {
      final result = filterAndSortCreators(creators, orderBy: 'rating');
      expect(result.map((c) => c.id).toList(), ['1', '3', '2']);
    });

    test('orderBy fans sorts descending by fanCount', () {
      final result = filterAndSortCreators(creators, orderBy: 'fans');
      expect(result.map((c) => c.id).toList(), ['3', '1', '2']);
    });

    test('orderBy recipes sorts descending by recipeCount', () {
      final result = filterAndSortCreators(creators, orderBy: 'recipes');
      expect(result.map((c) => c.id).toList(), ['3', '1', '2']);
    });

    test('combined query + regionId', () {
      final result = filterAndSortCreators(creators, query: 'at', regionId: 'sn');
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('combined query + regionId with no match returns empty', () {
      final result = filterAndSortCreators(creators, query: 'Grace', regionId: 'sn');
      expect(result, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/features/recipes/creators_filter_test.dart
```

Expected: compile error — `filterAndSortCreators` not defined.

- [ ] **Step 3: Add `filterAndSortCreators` to `feed_page.dart`**

Add this top-level function **before** `class FeedPage` (after the last import and before line 24):

```dart
List<Creator> filterAndSortCreators(
  List<Creator> all, {
  String query = '',
  String? regionId,
  String? specialty,
  String? orderBy,
}) {
  var list = all.where((c) {
    if (query.isNotEmpty &&
        !c.displayName.toLowerCase().contains(query.toLowerCase())) return false;
    if (regionId != null && c.regionId != regionId) return false;
    if (specialty != null && !c.specialties.contains(specialty)) return false;
    return true;
  }).toList();

  if (orderBy == 'rating') {
    list.sort((a, b) => b.averageRating.compareTo(a.averageRating));
  } else if (orderBy == 'fans') {
    list.sort((a, b) => b.fanCount.compareTo(a.fanCount));
  } else if (orderBy == 'recipes') {
    list.sort((a, b) => b.recipeCount.compareTo(a.recipeCount));
  }

  return list;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/features/recipes/creators_filter_test.dart
```

Expected: all 10 tests PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/recipes/feed_page.dart test/features/recipes/creators_filter_test.dart
git commit -m "feat: add filterAndSortCreators function with tests"
```

---

### Task 2: Add state fields and computed getters to `_FeedPageState`

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

- [ ] **Step 1: Add four state fields**

In `_FeedPageState`, after the existing creator pagination fields (after line 62 `final Set<String> _seenCreatorIds = {};`), add:

```dart
  // ---- Creator search/filter/sort ----
  final _creatorsSearchCtrl = TextEditingController();
  String  _creatorsQuery    = '';
  String? _creatorsRegionId;
  String? _creatorsSpecialty;
  String? _creatorsOrderBy;
```

- [ ] **Step 2: Dispose the new controller**

In the `dispose()` method, add `_creatorsSearchCtrl.dispose();` before `super.dispose()`:

```dart
  @override
  void dispose() {
    _searchCtrl.dispose();
    _creatorsSearchCtrl.dispose();
    _logger.provider('FeedPage disposed');
    super.dispose();
  }
```

- [ ] **Step 3: Add computed getters**

After the existing `bool get _hasActiveFilter =>` getter (around line 64), add:

```dart
  bool get _hasActiveCreatorFilter =>
      _creatorsRegionId != null || _creatorsSpecialty != null || _creatorsOrderBy != null;

  List<Creator> get _filteredCreators => filterAndSortCreators(
        _creators,
        query: _creatorsQuery,
        regionId: _creatorsRegionId,
        specialty: _creatorsSpecialty,
        orderBy: _creatorsOrderBy,
      );
```

- [ ] **Step 4: Add label helpers**

After the existing `_sortLabel()` method (around line 277), add:

```dart
  String _creatorsRegionLabel() {
    if (_creatorsRegionId == null) return 'Région';
    final names = ref.read(foodRegionNamesProvider).valueOrNull ?? {};
    return names[_creatorsRegionId] ?? _creatorsRegionId!;
  }

  String _creatorsSpecialtyLabel() => _creatorsSpecialty ?? 'Spécialité';

  String _creatorsSortLabel() => switch (_creatorsOrderBy) {
        'rating'  => 'Mieux notés',
        'fans'    => 'Plus de fans',
        'recipes' => 'Plus de recettes',
        _         => 'Tri',
      };
```

- [ ] **Step 5: Verify the app still compiles**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: no new errors.

- [ ] **Step 6: Commit**

```
git add lib/features/recipes/feed_page.dart
git commit -m "feat: add creator filter/sort state fields and computed getters"
```

---

### Task 3: Add `_showCreatorFilterSheet` method

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

- [ ] **Step 1: Add the method**

Add `_showCreatorFilterSheet` after `_showSortSheet` (after line 471). This mirrors `_showCombinedFilterSheet` but only has Region + Spécialité:

```dart
  static const _creatorSpecialties = [
    'Cuisine traditionnelle',
    'Cuisine fusion',
    'Cuisine végétarienne',
    'Pâtisserie',
    'Street food',
  ];

  void _showCreatorFilterSheet(BuildContext context, Map<String, String> regionNames) {
    _logger.userAction('Creator filter sheet opened', screen: 'FeedPage');
    String? tempRegion    = _creatorsRegionId;
    String? tempSpecialty = _creatorsSpecialty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AkeliColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AkeliSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filtres', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Région', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Toutes'),
                          selected: tempRegion == null,
                          onSelected: (_) => setModalState(() => tempRegion = null),
                        ),
                        ...regionNames.entries.map((e) => ChoiceChip(
                          label: Text(e.value),
                          selected: tempRegion == e.key,
                          onSelected: (_) => setModalState(() => tempRegion = e.key),
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Spécialité', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Toutes'),
                          selected: tempSpecialty == null,
                          onSelected: (_) => setModalState(() => tempSpecialty = null),
                        ),
                        ..._creatorSpecialties.map((s) => ChoiceChip(
                          label: Text(s),
                          selected: tempSpecialty == s,
                          onSelected: (_) => setModalState(() => tempSpecialty = s),
                        )),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          _logger.userAction('Creator filter applied', screen: 'FeedPage',
                              metadata: {'regionId': tempRegion, 'specialty': tempSpecialty});
                          setState(() {
                            _creatorsRegionId  = tempRegion;
                            _creatorsSpecialty = tempSpecialty;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Appliquer les filtres'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
```

- [ ] **Step 2: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```
git add lib/features/recipes/feed_page.dart
git commit -m "feat: add _showCreatorFilterSheet bottom sheet"
```

---

### Task 4: Add `_showCreatorSortSheet` method

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

- [ ] **Step 1: Add the method**

Add `_showCreatorSortSheet` immediately after `_showCreatorFilterSheet`:

```dart
  void _showCreatorSortSheet(BuildContext context) {
    _logger.userAction('Creator sort sheet opened', screen: 'FeedPage');
    showModalBottomSheet(
      context: context,
      backgroundColor: AkeliColors.surface,
      builder: (_) => _FilterSheet<String>(
        title: 'Trier par',
        options: const [
          MapEntry(null, 'Personnalisé'),
          MapEntry('rating', 'Mieux notés'),
          MapEntry('fans', 'Plus de fans'),
          MapEntry('recipes', 'Plus de recettes'),
        ],
        selectedKey: _creatorsOrderBy,
        onSelect: (key) {
          _logger.userAction('Creator sort changed', screen: 'FeedPage',
              metadata: {'orderBy': key});
          setState(() => _creatorsOrderBy = key);
        },
      ),
    );
  }
```

- [ ] **Step 2: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```
git add lib/features/recipes/feed_page.dart
git commit -m "feat: add _showCreatorSortSheet bottom sheet"
```

---

### Task 5: Build the search controls sliver and wire into `build()`

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

- [ ] **Step 1: Add `_buildCreatorSearchControls` method**

Add this method after `_buildCreateursSliver` (after line 930, before the `// Private widgets` comment):

```dart
  Widget _buildCreatorSearchControls(Map<String, String> regionNames) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AkeliSpacing.md, AkeliSpacing.sm, AkeliSpacing.md, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search row: text field + filter icon + sort icon
            Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _creatorsSearchCtrl,
                    hintText: 'Rechercher un créateur…',
                    leading: const Icon(Icons.search_rounded),
                    trailing: _creatorsQuery.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _creatorsSearchCtrl.clear();
                                setState(() => _creatorsQuery = '');
                              },
                            )
                          ]
                        : null,
                    onChanged: (v) {
                      _logger.userAction('Creators search query changed',
                          screen: 'FeedPage', metadata: {'query': v});
                      setState(() => _creatorsQuery = v);
                    },
                    elevation: const WidgetStatePropertyAll(0),
                    padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12)),
                    constraints:
                        const BoxConstraints(minHeight: 48, maxHeight: 48),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _hasActiveCreatorFilter
                        ? AkeliColors.primaryContainer
                        : AkeliColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    color: _hasActiveCreatorFilter
                        ? AkeliColors.onPrimaryContainer
                        : AkeliColors.onSurfaceVariant,
                    onPressed: () =>
                        _showCreatorFilterSheet(context, regionNames),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _creatorsOrderBy != null
                        ? AkeliColors.primaryContainer
                        : AkeliColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.sort_rounded),
                    color: _creatorsOrderBy != null
                        ? AkeliColors.onPrimaryContainer
                        : AkeliColors.onSurfaceVariant,
                    onPressed: () => _showCreatorSortSheet(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Active filter chips row
            SizedBox(
              height: _hasActiveCreatorFilter || _creatorsOrderBy != null ? 36 : 0,
              child: !_hasActiveCreatorFilter
                  ? const SizedBox.shrink()
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (_creatorsRegionId != null) ...[
                          _ActiveFilterChip(
                            label: _creatorsRegionLabel(),
                            onDeleted: () =>
                                setState(() => _creatorsRegionId = null),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_creatorsSpecialty != null) ...[
                          _ActiveFilterChip(
                            label: _creatorsSpecialtyLabel(),
                            onDeleted: () =>
                                setState(() => _creatorsSpecialty = null),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_creatorsOrderBy != null) ...[
                          _ActiveFilterChip(
                            label: _creatorsSortLabel(),
                            onDeleted: () =>
                                setState(() => _creatorsOrderBy = null),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: () => setState(() {
                            _creatorsRegionId  = null;
                            _creatorsSpecialty = null;
                            _creatorsOrderBy   = null;
                          }),
                          child: const Text('Tout effacer',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 2: Update `_buildCreateursSliver` to use `_filteredCreators` and updated empty state**

In `_buildCreateursSliver`, find the `data:` callback. Make two changes:

**Change 1** — replace `final displayList = _creators;` with:
```dart
        final displayList = _filteredCreators;
```

**Change 2** — replace the existing empty state return:
```dart
        if (displayList.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyState(
              icon: Icons.person_rounded,
              title: 'Aucun créateur disponible',
              subtitle: 'Les créateurs apparaîtront ici.',
            ),
          );
        }
```
with:
```dart
        if (displayList.isEmpty) {
          final isFiltered = _creatorsQuery.isNotEmpty || _hasActiveCreatorFilter;
          return SliverFillRemaining(
            child: EmptyState(
              icon: Icons.person_rounded,
              title: isFiltered
                  ? 'Aucun créateur trouvé'
                  : 'Aucun créateur disponible',
              subtitle: isFiltered
                  ? 'Essayez d\'autres termes ou réinitialisez les filtres.'
                  : 'Les créateurs apparaîtront ici.',
            ),
          );
        }
```

- [ ] **Step 3: Inject the controls sliver in `build()`**

In `build()`, find this block (around line 849):

```dart
        if (_tabIndex != 0)
          _buildCreateursSliver(regionNames),
```

Replace it with:

```dart
        if (_tabIndex != 0) ...[
          _buildCreatorSearchControls(regionNames),
          _buildCreateursSliver(regionNames),
        ],
```

- [ ] **Step 4: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: no errors.

- [ ] **Step 5: Run all tests**

```
flutter test
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```
git add lib/features/recipes/feed_page.dart
git commit -m "feat: add search/filter/sort controls to Créateurs tab"
```

---

## Manual verification checklist

After all tasks complete, verify these flows in the app:

- [ ] Créateurs tab shows search bar + two icon buttons below the app bar
- [ ] Typing in the search bar narrows the creator list in real time
- [ ] Clearing the search field (× button) restores all creators
- [ ] 🎚 icon opens the filter sheet with Région and Spécialité sections
- [ ] Selecting a region/specialty and tapping "Appliquer" filters the list and shows chips
- [ ] 🔃 icon opens the sort sheet with 4 options; selecting one re-orders the list
- [ ] Tapping × on a filter chip removes that filter
- [ ] "Tout effacer" removes all creator filters at once
- [ ] 🎚 icon turns green when any filter is active
- [ ] 🔃 icon turns green when a sort is active
- [ ] No results state shows correct copy when query/filter matches nothing
- [ ] Recipe tab search/filter/sort is unaffected
