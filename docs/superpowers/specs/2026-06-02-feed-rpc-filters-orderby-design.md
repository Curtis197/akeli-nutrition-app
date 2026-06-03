# Feed RPC — Filters & Order-By Support

**Date:** 2026-06-02
**Branch:** fix-compliance-and-router-issues-814be
**Status:** Approved

---

## Problem

`generate_feed_personalized` accepts no filter or sort params. When the user applies filters (region, difficulty, cooking time, calories) or a custom sort order, the Flutter `feedProvider` bypasses the RPC entirely and falls back to a raw `recipe` table query. This loses personalization scoring and duplicates query logic.

---

## Goal

Extend `generate_feed_personalized` to accept optional filter and sort params so all feed queries — filtered or not — go through the single RPC and stay personalized.

---

## Architecture

### 1. Database — new migration

**File:** `supabase/migrations/20260602000008_feed_rpc_filters_orderby.sql`

Replace the existing function via `CREATE OR REPLACE FUNCTION`.

**New signature:**
```sql
generate_feed_personalized(
  p_user_id      uuid,
  p_limit        int     DEFAULT 140,
  p_exclude      uuid[]  DEFAULT '{}',
  p_region_id    text    DEFAULT NULL,
  p_difficulty   text    DEFAULT NULL,
  p_max_time_min int     DEFAULT NULL,
  p_min_cal      numeric DEFAULT NULL,
  p_max_cal      numeric DEFAULT NULL,
  p_order_by     text    DEFAULT NULL
)
RETURNS TABLE (recipe_id uuid, score numeric)
```

**Filter handling:**
- Each filter uses a null-guard: `AND (p_region_id IS NULL OR r.region = p_region_id)`
- Calorie filters use a LEFT JOIN on `recipe_macro`, null-safe — recipes without a macro row pass through (same benefit-of-the-doubt pattern as `drop_off_rate`)
- Quality gate (`drop_off_rate ≤ 0.20`) applies in all paths, with and without filters

**Order-by handling (`p_order_by`):**

| Value | `score` field | ORDER BY |
|---|---|---|
| `NULL` (default) | cosine similarity (or `like_count` for cold start) | `score DESC` |
| `'rating'` | `r.average_rating` | `score DESC` |
| `'likes'` | `r.like_count` | `score DESC` |
| `'created_at'` | normalized epoch | `score DESC` |

The return type `(recipe_id, score)` is unchanged — Flutter reads only `recipe_id`.

**Two execution paths (unchanged structure):**
- **Cold start** (no `user_vector`): rank by `like_count` unless `p_order_by` overrides. All filters apply.
- **Vectorized** (has `user_vector`): rank by cosine similarity unless `p_order_by` overrides. All filters apply.

### 2. Flutter — `lib/providers/recipe_provider.dart`

Remove the `if (!params.hasFilters)` branch and the direct-table fallback. The provider always calls the RPC, passing all `FeedParams` fields as optional params (nulls omitted from the map).

```dart
final rpcParams = {
  'p_user_id': user.id,
  'p_limit': params.limit,
  'p_exclude': params.excludeIds,
  if (params.regionId != null) 'p_region_id': params.regionId,
  if (params.difficulty != null) 'p_difficulty': params.difficulty,
  if (params.maxTimeMin != null) 'p_max_time_min': params.maxTimeMin,
  if (params.minCal != null) 'p_min_cal': params.minCal,
  if (params.maxCal != null) 'p_max_cal': params.maxCal,
  if (params.orderBy != null) 'p_order_by': params.orderBy,
};
```

No changes to `FeedParams`, `feed_page.dart`, or any other file.

---

## Data Flow

```
User applies filters → FeedParams built → feedProvider
  → generate_feed_personalized RPC (all params)
    → WHERE: quality gate + null-guarded filters
    → ORDER BY: similarity OR p_order_by column
    → RETURNS: (recipe_id, score)
  → Flutter fetches full recipe objects by ID
  → FeedPage renders
```

---

## Testing (akeli-local-testing-protocol)

**Layer: DB** — Supabase MCP `execute_sql`, project `njzqcftjzskwcpforwzf`

1. Verify new arity:
   ```sql
   SELECT proname, pronargs FROM pg_proc WHERE proname = 'generate_feed_personalized';
   ```

2. Smoke — no filters (existing behavior):
   ```sql
   SELECT * FROM generate_feed_personalized('<user_id>'::uuid, 5) LIMIT 5;
   ```

3. Region + difficulty filter:
   ```sql
   SELECT * FROM generate_feed_personalized('<user_id>'::uuid, 5, '{}', 'west_africa', 'easy') LIMIT 5;
   ```

4. Calorie range filter:
   ```sql
   SELECT * FROM generate_feed_personalized('<user_id>'::uuid, 5, '{}', NULL, NULL, NULL, 300, 800) LIMIT 5;
   ```

5. Order by rating:
   ```sql
   SELECT * FROM generate_feed_personalized('<user_id>'::uuid, 5, '{}', NULL, NULL, NULL, NULL, NULL, 'rating') LIMIT 5;
   ```

**Layer: Dart** — `flutter test` (full suite) after provider simplification.

**Getting a real user_id for RPC tests:**
```sql
SELECT id FROM auth.users LIMIT 1;
```

---

## Key Invariants

- All new params are optional with `DEFAULT NULL` — no breaking change to existing callers
- Filters that find no results return empty (no automatic filter relaxation)
- Recipes without `recipe_macro` pass calorie filters (null-safe)
- `p_order_by` with an unrecognized value falls back to similarity (ELSE branch in CASE)
- Cold-start path respects `p_order_by` the same way as the vectorized path
