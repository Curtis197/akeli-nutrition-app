# Creators Tab — Search, Filter & Sort

**Date:** 2026-06-11
**Feature:** Add search bar, region/specialty filter, and sort to the Créateurs tab in `FeedPage`

---

## Context

The Créateurs tab in `FeedPage` (`lib/features/recipes/feed_page.dart`) currently renders a plain vertical list of `CreatorCard` widgets loaded by `creatorsListProvider`. That provider calls the `generate_creators_personalized` RPC (up to 20 results) then fetches full creator rows, storing them in `_creators` inside `_FeedPageState`. There is no search, filter, or sort.

---

## Goal

Let users find and rank creators by name, region, and specialty without leaving the Créateurs tab. The existing RPC call and pagination remain untouched; all filtering and sorting operate on the already-loaded `_creators` list.

---

## Architecture

### Approach chosen: in-widget state (Option 1)

Filter/sort state lives in `_FeedPageState` alongside the existing recipe filter fields. A synchronous computed getter `_filteredCreators` derives the display list from `_creators`. No new provider, no new file.

**Why:** The Recettes tab already manages `_searchQuery`, `_regionId`, `_difficulty`, etc. in `_FeedPageState`. Adding four analogous creator fields is consistent with the existing pattern.

---

## State additions

Four new fields in `_FeedPageState`:

```dart
final _creatorsSearchCtrl = TextEditingController();
String  _creatorsQuery    = '';
String? _creatorsRegionId;
String? _creatorsSpecialty;
String? _creatorsOrderBy;  // null = RPC order | 'rating' | 'fans' | 'recipes'
```

Dispose `_creatorsSearchCtrl` in `dispose()`.

### Computed getters

```dart
bool get _hasActiveCreatorFilter =>
    _creatorsRegionId != null || _creatorsSpecialty != null || _creatorsOrderBy != null;

List<Creator> get _filteredCreators {
  var list = _creators.where((c) {
    if (_creatorsQuery.isNotEmpty &&
        !c.displayName.toLowerCase().contains(_creatorsQuery.toLowerCase())) return false;
    if (_creatorsRegionId != null && c.regionId != _creatorsRegionId) return false;
    if (_creatorsSpecialty != null &&
        !(c.specialties ?? []).contains(_creatorsSpecialty)) return false;
    return true;
  }).toList();

  if (_creatorsOrderBy == 'rating') {
    list.sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
  } else if (_creatorsOrderBy == 'fans') {
    list.sort((a, b) => (b.fanCount ?? 0).compareTo(a.fanCount ?? 0));
  } else if (_creatorsOrderBy == 'recipes') {
    list.sort((a, b) => b.recipeCount.compareTo(a.recipeCount));
  }
  // null = keep RPC order

  return list;
}
```

---

## UI layout

`_buildCreateursSliver` returns a `SliverMainAxisGroup` (or `MultiSliver`) with two children:

1. **`SliverToBoxAdapter`** — search controls (always visible when Créateurs tab is active)
2. **`SliverPadding` / `SliverList`** — creator cards using `_filteredCreators`

### Search controls widget

```
[ 🔍 TextField ────────────────── ] [ 🎚 ] [ 🔃 ]
[ chip: Sénégal × ] [ chip: Cuisine trad. × ] [ chip: Mieux notés × ]   ← only if hasActiveCreatorFilter
```

- **TextField** — `_creatorsSearchCtrl`, hint `'Rechercher un créateur…'`, `onChanged` → `setState(() => _creatorsQuery = value)`
- **Filter icon button** (`Icons.tune_rounded`) — `AkeliColors.primary` when `_hasActiveCreatorFilter`, otherwise `AkeliColors.textSecondary`. Taps → `_showCreatorFilterSheet(regionNames)`
- **Sort icon button** (`Icons.sort_rounded`) — highlighted when `_creatorsOrderBy != null`. Taps → `_showCreatorSortSheet()`
- **Active filter chip row** — same `_ActiveFilterChip` widget already used by the Recettes tab; one chip per active filter; `onDeleted` clears that field and calls `setState`

### Empty state copy

When `_filteredCreators.isEmpty` and (`_creatorsQuery.isNotEmpty || _hasActiveCreatorFilter`):
> "Aucun créateur ne correspond à votre recherche."

Otherwise keep the existing "Aucun créateur disponible" copy.

---

## Filter bottom sheet — `_showCreatorFilterSheet`

Same `showModalBottomSheet` call as `_showCombinedFilterSheet`:
- `backgroundColor: AkeliColors.surface`
- `isScrollControlled: true`
- Uses the existing `_FilterSheet<T>` widget (already in the file) — call it twice: once for region, once for specialty

Two sections inside a `Column`:

| Section | Options source | Binding |
|---------|---------------|---------|
| Région | `regionNames` map (passed in) | `_creatorsRegionId` |
| Spécialité | Hardcoded list (see below) | `_creatorsSpecialty` |

**Hardcoded specialties:**
```dart
const _creatorSpecialties = [
  'Cuisine traditionnelle',
  'Cuisine fusion',
  'Cuisine végétarienne',
  'Pâtisserie',
  'Street food',
];
```

An **Appliquer** button (`FilledButton`) at the bottom pops the sheet and calls `setState`.

---

## Sort bottom sheet — `_showCreatorSortSheet`

Same pattern as the existing `_showSortSheet`. Single-select list of four options:

| Label | `_creatorsOrderBy` value |
|-------|--------------------------|
| Personnalisé | `null` |
| Mieux notés | `'rating'` |
| Plus de fans | `'fans'` |
| Plus de recettes | `'recipes'` |

Tapping an option sets `_creatorsOrderBy`, pops, calls `setState`.

---

## Files to change

| File | Change |
|------|--------|
| `lib/features/recipes/feed_page.dart` | All state, getters, search controls, sheet methods |

No other files need to change.

---

## Logging

Follow the project logging standard. New user actions to log:
```dart
_logger.userAction('Creators search query changed', screen: 'FeedPage', metadata: {'query': value});
_logger.userAction('Creators filter applied', screen: 'FeedPage', metadata: {'regionId': _creatorsRegionId, 'specialty': _creatorsSpecialty});
_logger.userAction('Creators sort changed', screen: 'FeedPage', metadata: {'orderBy': _creatorsOrderBy});
```

---

## Out of scope

- Server-side search (Supabase full-text on `display_name`) — not needed for 20 results
- Filter by fan status — excluded by design decision
- Pagination reset on filter change — `_filteredCreators` is computed, no pagination to reset
