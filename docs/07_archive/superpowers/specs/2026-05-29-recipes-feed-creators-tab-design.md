# Recipes Feed — Créateurs Tab & Creator Detail Page

**Date:** 2026-05-29  
**Branch:** feature/recipes-creators-tab  
**Scope:** Feed page tab system, creator list, creator detail page, creator card on recipe/meal detail

---

## Goal

Add a "Créateurs" tab to the recipes feed page so users can browse creator profiles alongside recipes. Tapping a creator opens a dedicated detail page. Recipe/meal detail pages replace the hardcoded creator card with a real, tappable one.

---

## 1. Feed Page — Tab System

### Approach
State-driven tab using the existing `AkeliTabBar` widget. A `_tabIndex` local state variable (0 = Recettes, 1 = Créateurs) controls which view renders.

### Tab Bar Placement
`AkeliTabBar` is placed inside `SliverAppBar.bottom`, below the search bar row. The `PreferredSize` height expands to include both rows when on the Recettes tab, or shrinks to just the tab bar height on the Créateurs tab (search/filters hidden).

### Tab 0 — Recettes
Identical to current behaviour: search bar, filter chips, sort button, recipe grid. No changes.

### Tab 1 — Créateurs
- Search bar and filter chips are hidden.
- Body: `SliverList` of `CreatorCard` widgets.
- Powered by a new `creatorsListProvider` (see Section 3).
- No pagination in V1 — load all creators (capped at 50 by provider).

---

## 2. Creator Card Widget (Feed List)

**File:** `lib/shared/widgets/creator_card.dart`

Each card in the Créateurs tab displays:
| Element | Detail |
|---|---|
| Avatar | Circle, 56 px, falls back to initials |
| Display name | Bold, single line |
| Food region | Small label chip |
| Description | 2-line clamp |
| Recipe count | e.g. "12 recettes" |
| Tap | Navigates to `CreatorDetailPage(/creators/:creatorId)` |

No fan/like action on this card — kept intentionally lightweight.

---

## 3. Creator List Provider

**File:** `lib/providers/creator_provider.dart`

```
creatorsListProvider → AsyncValue<List<Creator>>
```

Queries the `creator` table, ordered by `recipe_count DESC`, limit 50. Uses the existing `Creator` model from `lib/shared/models/creator.dart`.

---

## 4. Creator Detail Page

**File:** `lib/features/recipes/creator_detail_page.dart`  
**Route:** `/creators/:creatorId`

### Layout

**Header Section**
- Large avatar (96 px circle)
- Display name (headline)
- Food region label
- Full bio text

**Stats Row** (4 pills, horizontal scroll if needed)
| Stat | Source |
|---|---|
| Recipe count | `creator.recipeCount` |
| Avg rating | Average of all their recipe ratings |
| Total likes | Sum of `like_count` across all their recipes — computed at query time |
| Your consumption | Count of how many of their recipes appear in the current user's meal plan history |

**Fan Button**
- Shown only when `!creator.isMyFanCreator`
- Label: "Devenir fan"
- On tap: inserts a row into `fan_subscription` (status = `active`, effectiveFrom = now)
- After success: button disappears, replaced by a "Fan ✓" label (non-interactive)

**Recipe Grid**
- 2-column grid, same `AkeliRecipeCard` as feed
- Powered by `creatorRecipesProvider(creatorId)` — queries recipes filtered by `creator_id`
- Tapping a card navigates to `RecipeDetailPage`

### Provider

```
creatorDetailProvider(creatorId) → AsyncValue<CreatorDetail>
```

`CreatorDetail` is a new local model bundling:
- `Creator` object
- `totalLikes: int`
- `avgRating: double`
- `userConsumptionCount: int`
- `isFan: bool`

Fetched via a single RPC or a composed provider (two parallel queries: creator + stats).

---

## 5. Creator Card on Recipe/Meal Detail

The hardcoded "Chef Amina" card in `recipe_detail_page.dart` (lines 592–642) is replaced with a real `CreatorCard` that:
- Loads the creator using `creatorByIdProvider(recipe.creatorId)`
- Displays avatar, name, region, description (same as feed card)
- Is tappable → `context.push('/creators/${recipe.creatorId}')`

Same treatment applied to the meal detail page if it has an equivalent creator section.

---

## 6. Routing

Add to the app router:

```dart
GoRoute(
  path: '/creators/:creatorId',
  builder: (context, state) => CreatorDetailPage(
    creatorId: state.pathParameters['creatorId']!,
  ),
),
```

---

## 7. Out of Scope (V1)

- Fan subscription management (cancel fan, fan tier)
- Creator search / filter on the Créateurs tab
- Push notifications for new creator recipes
- Creator analytics dashboard

---

## 8. Files Created / Modified

| File | Action |
|---|---|
| `lib/features/recipes/feed_page.dart` | Add tab bar, Créateurs tab body |
| `lib/features/recipes/creator_detail_page.dart` | New |
| `lib/features/recipes/recipe_detail_page.dart` | Replace hardcoded creator card |
| `lib/shared/widgets/creator_card.dart` | New |
| `lib/providers/creator_provider.dart` | New — `creatorsListProvider`, `creatorDetailProvider`, `creatorByIdProvider`, `creatorRecipesProvider` |
| `lib/shared/models/creator_detail.dart` | New local aggregate model |
| `lib/core/router.dart` | Add `/creators/:creatorId` route |
