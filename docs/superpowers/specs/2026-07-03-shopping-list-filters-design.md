# Shopping List Filter & Sort — Design

## Goal

Improve navigation, visibility, and shopping efficiency on the shopping list
screen by adding sort (category / price / store) and filter (status / store
type) controls. No specific user pain point drove this — it's a proactive
usability pass on an already-working screen.

## Branch

All work lands directly on the `price-scraper-feature` branch, not `main`.

Rationale: that branch already has a complete package-based costing
implementation — `ShoppingItem.pricePer100g`, `estimatedPrice` /
`estimatedPriceBought` getters, currency/package handling, and a working
cost-summary banner in `shopping_list_page.dart` — none of which exists on
`main` (only the underlying `ingredient_market_price` / `recipe_market_cost`
tables survived there; the Flutter side was reverted when GB/US/CA scraping
hit anti-bot blocks). Rebuilding that model from scratch on `main` would
duplicate existing, working code. Category/store grouping and sorting are new
on both branches.

This branch also carries ~20 files of unrelated changes (auth pages, feed
page, etc.) accumulated since it diverged from `main`. Reconciling that
divergence is explicitly **out of scope** for this task — it will need its
own merge effort later.

## Data Model Changes

### New column: `ingredient.store_type`

```sql
ALTER TABLE ingredient
  ADD COLUMN store_type text NOT NULL DEFAULT 'other'
    CHECK (store_type IN ('supermarket', 'epicery', 'other'));
```

- Admin-tagged directly via DB access (Supabase Studio / seed SQL). There is
  no in-app admin UI for ingredients, so populating this field is not part of
  the Flutter build in this task.
- Untagged ingredients default to `'other'`.

### `ShoppingItem` model

Add `storeType` field (`'supermarket' | 'epicery' | 'other'`), sourced from
the existing `ingredient` join (same join that already provides `category`).

- If `ingredientId` is null (item has no linked ingredient) or the joined
  `store_type` is null, `storeType` defaults to `'other'`.

### Provider query

`meal_plan_provider.dart`'s shopping list query adds `store_type` to the
existing `ingredient(...)` select alongside `name`, `name_fr`, `name_en`,
`category`.

## Sort & Filter Semantics

### Sort modes (single-select)

| Mode | Behavior | Default |
|---|---|---|
| **Category** | Section headers per category (e.g. "Produce", "Dairy"), alphabetical by name within group. Items with no category group under "Uncategorized". | Yes (default) |
| **Price** | Flat list (no section headers), ordered by `estimatedPriceBought` ascending. Tap toggles ascending/descending. | No |
| **Store** | Section headers in fixed order: **Supermarket → Épicerie → Other**, alphabetical by name within group. | No |

### Filters (combine with AND, independent of sort)

| Filter | Values | UI location |
|---|---|---|
| **Status** | All / Remaining / Bought | Existing inline chip row — unchanged |
| **Store type** | All / Supermarket / Épicerie / Other | New — bottom sheet |

### Entry point

A new sort/filter icon button (placed alongside the existing status chip
row) opens a bottom sheet containing:
- Sort mode radio group (Category / Price / Store)
- Store type filter chips (All / Supermarket / Épicerie / Other)
- Apply action

The existing status chip row (All/Bought/Remaining) stays inline above the
list, unchanged.

### Cost banner

Continues to sum over the **entire** list regardless of active sort/filter
state, matching its current behavior on `price-scraper-feature`. This is a
deliberate choice (not scoped to the filtered subset) so "Total Cost" always
means the whole shopping list.

## Edge Cases

- Item with no `category` → grouped under "Uncategorized" header (sort=Category).
- Item with `storeType == 'other'` → grouped under "Other" header (sort=Store)
  and matched by the "Other" filter chip.
- A filtered group with zero items simply doesn't render its header.
- If the entire filtered result is empty, reuse the existing `EmptyState`
  widget (same as today's empty-list case).
- Sort mode is session-only state (kept in `_ShoppingListPageState`), resets
  to Category on next page load. No persistence needed.

## L10n

New ARB keys added to both `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`
together, per project L10n standard:
- Bottom sheet title, "Sort by" label
- "Category" / "Price" / "Store" (sort mode labels)
- "Supermarket" / "Épicerie" / "Other" (store type labels, shared between
  filter chips and section headers)
- "Apply" action label

Run `flutter gen-l10n` after ARB changes, before referencing new keys in Dart.

## Logging

Per project logging standard, applied to every modified file:

- `_logger.userAction` — opening the bottom sheet, selecting a sort mode,
  toggling the store type filter.
- `_logger.provider` — state transitions if sort/filter state is lifted into
  a notifier rather than kept as local widget state.
- `_logger.db` BEFORE/AFTER — on the modified `meal_plan_provider` shopping
  list query (now also selecting `store_type`).
- New SQL migration requires no app-side logging.

## Testing

- Widget test: switching sort mode reorders the list and swaps section
  headers correctly (Category / Price / Store).
- Widget test: store-type filter hides non-matching items; combined
  correctly (AND) with the existing status filter.
- Model test: `ShoppingItem.storeType` defaults to `'other'` when
  `ingredientId` is null or the joined `store_type` is null.
- pgTAP migration test (matching `supabase/tests/` pattern): `store_type`
  column exists on `ingredient` with the correct CHECK constraint and
  default value.
