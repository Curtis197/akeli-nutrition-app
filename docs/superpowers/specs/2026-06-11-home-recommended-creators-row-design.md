# Home Page — Recommended Creators Row

**Date:** 2026-06-11
**Status:** Approved

## Goal

Add a "Créateurs pour vous" horizontal strip to the home page showing the 5 most aligned creators the user is not yet a fan of. Surfaces creator discovery without leaving the home screen.

## Data Source

Reuse the existing `creatorsListProvider` (`FutureProvider.autoDispose<List<Creator>>`), which calls the `generate_creators_personalized` RPC with `p_limit: 20`. The provider already returns creators sorted by alignment score and already sets `isMyFanCreator` on each `Creator`.

In the home page, the list is filtered to `isMyFanCreator == false` and `.take(5)` is applied. No new provider, no new migration, no extra DB round-trip (the provider is shared with the feed page and will be cached if both are visited in the same session).

The section is hidden entirely when the filtered list is empty (user already follows everyone, no creators exist, or provider errors).

## New Widget: `_HomeCreatorChip` (private, in `home_page.dart`)

Compact vertical card used in the horizontal row.

**Layout:**
```
┌────────────┐
│    ○○○○    │   CircleAvatar radius 32
│  Firstname │   2-line max, centered, 11px, Inter SemiBold
│  Lastname  │
└────────────┘
```

- Width: 80px, internal padding: 8px
- Background: `AkeliColors.surfaceContainerLowest`, shadow: `AkeliShadows.sm`, corner radius: `AkeliRadius.lg`
- Avatar: `CachedNetworkImageProvider` if `avatarUrl` non-null, else initials letter on `AkeliColors.primaryContainer`
- `onTap` → `context.go('/creator/${creator.id}')`

## Home Page Section

Inserted after the "Recettes recommandées" section, before the bottom spacer.

```
AkeliSectionHeader(title: 'Créateurs pour vous')
SizedBox(height: 12)
SizedBox(height: 100)
  └─ ListView.builder(scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: 16))
       └─ _HomeCreatorChip × up to 5
SizedBox(height: 24)
```

States:
- **Loading:** `CircularProgressIndicator` centered in the `SizedBox(height: 100)`
- **Error:** `SizedBox.shrink()` — silent fail, not critical content
- **Empty filtered list:** entire section omitted (no section header rendered)

## Logging

Follows the mandatory CLAUDE.md logging standard:

```dart
_logger.provider('[home-creators] data | total rpc: ${creators.length} | after fan filter + take5: ${shown.length}');
_logger.userAction('Creator chip tapped', screen: 'HomePage', metadata: {'creatorId': creator.id});
```

Loading and error states logged with `_logger.provider('[home-creators] loading')` and `_logger.provider('[home-creators] ERROR: $e')`.

## Files Changed

| File | Change |
|------|--------|
| `lib/features/home/home_page.dart` | Add `_HomeCreatorChip` widget class; add section in `build()`; watch `creatorsListProvider` |
| `lib/providers/creator_provider.dart` | No change |
| `lib/shared/models/creator.dart` | No change |

## Out of Scope

- Fan button on the chip (tap navigates to detail page where fan action lives)
- Sorting / filtering beyond what the RPC already provides
- Any new migration or RPC change
