# Feed RPC — Filters & Order-By Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `generate_feed_personalized` with optional filter and order-by params, and simplify the Flutter `feedProvider` to always use the RPC instead of falling back to a direct table query.

**Architecture:** A single new migration replaces the existing RPC via `CREATE OR REPLACE FUNCTION`, adding 6 new optional params (all `DEFAULT NULL`) to preserve backward compatibility. The Flutter provider's `if (!params.hasFilters)` branch is removed — one RPC call handles all cases.

**Tech Stack:** PostgreSQL / plpgsql, pgvector, Supabase MCP (`execute_sql`), Dart / Flutter Riverpod, akeli-local-testing-protocol.

---

## Files

| Action | Path | Responsibility |
|---|---|---|
| Create | `supabase/migrations/20260602000008_feed_rpc_filters_orderby.sql` | Replace `generate_feed_personalized` with extended signature |
| Modify | `lib/providers/recipe_provider.dart` lines 54–181 | Remove direct-table fallback; always call RPC with all params |

---

## Task 1: Write the migration file

**Files:**
- Create: `supabase/migrations/20260602000008_feed_rpc_filters_orderby.sql`

- [ ] **Step 1: Create the migration file with the full SQL**

Create `supabase/migrations/20260602000008_feed_rpc_filters_orderby.sql` with this exact content:

```sql
-- =============================================================================
-- AKELI — Feed RPC: add filter and order-by params
-- Migration: 20260602000008_feed_rpc_filters_orderby.sql
--
-- Extends generate_feed_personalized with:
--   p_region_id    text    DEFAULT NULL
--   p_difficulty   text    DEFAULT NULL
--   p_max_time_min int     DEFAULT NULL
--   p_min_cal      numeric DEFAULT NULL
--   p_max_cal      numeric DEFAULT NULL
--   p_order_by     text    DEFAULT NULL  -- NULL=similarity | 'rating' | 'likes' | 'created_at'
--
-- All new params are optional (DEFAULT NULL) — no breaking change to existing callers.
-- Calorie filters use LEFT JOIN recipe_macro, null-safe: recipes with no macro row pass.
-- Quality gate (drop_off_rate ≤ 0.20) applies in all paths.
-- =============================================================================

CREATE OR REPLACE FUNCTION generate_feed_personalized(
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
RETURNS TABLE (
  recipe_id uuid,
  score     numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  -- Auth guard
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Cold start: no user vector → rank by like_count unless p_order_by overrides
  IF v_user_vector IS NULL THEN
    RETURN QUERY
    SELECT
      r.id AS recipe_id,
      CASE p_order_by
        WHEN 'rating'     THEN COALESCE(r.average_rating, 0)::numeric
        WHEN 'likes'      THEN COALESCE(r.like_count, 0)::numeric
        WHEN 'created_at' THEN (EXTRACT(EPOCH FROM r.created_at) / 1e9)::numeric
        ELSE              COALESCE(r.like_count, 0)::numeric
      END AS score
    FROM recipe r
    LEFT JOIN recipe_macro rm ON rm.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
      AND (p_region_id    IS NULL OR r.region         = p_region_id)
      AND (p_difficulty   IS NULL OR r.difficulty     = p_difficulty)
      AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
      AND (p_min_cal IS NULL OR rm.calories IS NULL OR rm.calories >= p_min_cal)
      AND (p_max_cal IS NULL OR rm.calories IS NULL OR rm.calories <= p_max_cal)
      AND NOT EXISTS (
        SELECT 1 FROM recipe_performance_metrics rpm
        WHERE rpm.recipe_id = r.id
          AND rpm.drop_off_rate > 0.20
      )
    ORDER BY score DESC
    LIMIT LEAST(p_limit, 200);
    RETURN;
  END IF;

  -- Vectorized path: rank by cosine similarity unless p_order_by overrides
  RETURN QUERY
  SELECT
    r.id AS recipe_id,
    CASE p_order_by
      WHEN 'rating'     THEN COALESCE(r.average_rating, 0)::numeric
      WHEN 'likes'      THEN COALESCE(r.like_count, 0)::numeric
      WHEN 'created_at' THEN (EXTRACT(EPOCH FROM r.created_at) / 1e9)::numeric
      ELSE              (1 - (rv.vector <=> v_user_vector))::numeric
    END AS score
  FROM recipe r
  JOIN  recipe_vector rv ON rv.recipe_id = r.id
  LEFT JOIN recipe_macro rm ON rm.recipe_id = r.id
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND (p_region_id    IS NULL OR r.region         = p_region_id)
    AND (p_difficulty   IS NULL OR r.difficulty     = p_difficulty)
    AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
    AND (p_min_cal IS NULL OR rm.calories IS NULL OR rm.calories >= p_min_cal)
    AND (p_max_cal IS NULL OR rm.calories IS NULL OR rm.calories <= p_max_cal)
    AND NOT EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = r.id
        AND rpm.drop_off_rate > 0.20
    )
  ORDER BY score DESC
  LIMIT LEAST(p_limit, 200);
END;
$$;
```

- [ ] **Step 2: Commit the migration file**

```bash
git add supabase/migrations/20260602000008_feed_rpc_filters_orderby.sql
git commit -m "feat(db): extend generate_feed_personalized with filter and order-by params"
```

---

## Task 2: Apply migration and verify on remote DB

**Testing layer: DB** — Supabase MCP `execute_sql`, project `njzqcftjzskwcpforwzf`

- [ ] **Step 1: Apply the migration via Supabase MCP**

Use the Supabase MCP `apply_migration` tool:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `feed_rpc_filters_orderby`
- `query`: the full SQL from Task 1

- [ ] **Step 2: Verify the function exists with new arity (9 params)**

```sql
SELECT proname, pronargs
FROM pg_proc
WHERE proname = 'generate_feed_personalized';
```

Expected: one row with `pronargs = 9`.

- [ ] **Step 3: Get a real user_id for RPC tests**

```sql
SELECT id FROM auth.users LIMIT 1;
```

Copy the returned UUID — use it as `<user_id>` in the steps below.

- [ ] **Step 4: Smoke test — no filters (existing behavior)**

```sql
SELECT * FROM generate_feed_personalized('<user_id>'::uuid, 5)
LIMIT 5;
```

Expected: up to 5 rows of `(recipe_id uuid, score numeric)`. No error.

- [ ] **Step 5: Filter test — region**

```sql
SELECT count(*) FROM generate_feed_personalized(
  '<user_id>'::uuid, 50, '{}', 'west_africa'
);
```

Expected: a number ≥ 0, no error. (May be 0 if no recipes in that region — that is correct behavior.)

- [ ] **Step 6: Filter test — difficulty**

```sql
SELECT count(*) FROM generate_feed_personalized(
  '<user_id>'::uuid, 50, '{}', NULL, 'easy'
);
```

Expected: a number ≥ 0, no error.

- [ ] **Step 7: Filter test — calorie range**

```sql
SELECT count(*) FROM generate_feed_personalized(
  '<user_id>'::uuid, 50, '{}', NULL, NULL, NULL, 300, 800
);
```

Expected: a number ≥ 0, no error.

- [ ] **Step 8: Order-by test — rating**

```sql
SELECT score FROM generate_feed_personalized(
  '<user_id>'::uuid, 10, '{}', NULL, NULL, NULL, NULL, NULL, 'rating'
)
LIMIT 10;
```

Expected: scores are values from `average_rating` (0–5 range), descending, no error.

- [ ] **Step 9: Order-by test — created_at**

```sql
SELECT score FROM generate_feed_personalized(
  '<user_id>'::uuid, 10, '{}', NULL, NULL, NULL, NULL, NULL, 'created_at'
)
LIMIT 10;
```

Expected: scores are normalized epoch values, descending, no error.

- [ ] **Step 10: Auth guard test — wrong user_id**

```sql
SELECT * FROM generate_feed_personalized(
  '00000000-0000-0000-0000-000000000000'::uuid, 5
);
```

Expected: error `Unauthorized` (since `auth.uid()` won't match that UUID when called via MCP as service role — if running as service role it may bypass; acceptable, since the guard runs on the app's anon/user role).

---

## Task 3: Simplify `feedProvider` in Flutter

**Files:**
- Modify: `lib/providers/recipe_provider.dart` lines 54–181

- [ ] **Step 1: Replace the entire `feedProvider` body**

In `lib/providers/recipe_provider.dart`, replace everything from line 54 to line 181 (the closing `});`) with:

```dart
final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  appLogger.provider(
      'feedProvider build() | userId: ${user?.id ?? "null"} | region: ${params.regionId} | difficulty: ${params.difficulty} | orderBy: ${params.orderBy}');
  ref.onDispose(() => appLogger.provider('feedProvider disposed'));

  if (user == null) {
    appLogger.provider('feedProvider EARLY RETURN | reason: no authenticated user');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);

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

  appLogger.db(
      'BEFORE rpc | fn: generate_feed_personalized | userId: ${user.id} | params: $rpcParams');

  try {
    final rpcData =
        await client.rpc('generate_feed_personalized', params: rpcParams)
            as List<dynamic>;
    appLogger.db(
        'AFTER rpc | fn: generate_feed_personalized | rows: ${rpcData.length}');

    if (rpcData.isEmpty) {
      appLogger.rls(
          'Zero rows | rpc: generate_feed_personalized | userId: ${user.id} | possible RLS or empty feed');
      return [];
    }

    final recipeIds = rpcData
        .cast<Map<String, dynamic>>()
        .map((e) => e['recipe_id'] as String)
        .toList();

    appLogger.db(
        'BEFORE | table: recipe | op: SELECT in | ids: ${recipeIds.length}');
    final recipeData = await client
        .from('recipe')
        .select(
            '*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .inFilter('id', recipeIds) as List<dynamic>;
    appLogger.db('AFTER | table: recipe | rows: ${recipeData.length}');

    if (recipeData.isEmpty) {
      appLogger.rls(
          'Zero rows | table: recipe | possible RLS block | userId: ${user.id}');
    }

    final recipeMap = {
      for (final r in recipeData.cast<Map<String, dynamic>>())
        r['id'] as String: r
    };
    final recipes = recipeIds
        .where(recipeMap.containsKey)
        .map((id) => Recipe.fromJson(recipeMap[id]!))
        .toList();

    appLogger.provider(
        'feedProvider → data | recipes: ${recipes.length}');
    return recipes;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls(
          'Permission denied | rpc: generate_feed_personalized | userId: ${user.id}',
          error: e,
          stackTrace: st);
    } else {
      appLogger.db(
          'ERROR rpc | fn: generate_feed_personalized | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
    }
    appLogger.provider('feedProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR rpc | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('feedProvider → error | $e');
    rethrow;
  }
});
```

- [ ] **Step 2: Remove the unused `hasFilters` getter from `FeedParams`**

In `lib/providers/recipe_provider.dart`, delete lines 33–35:

```dart
  bool get hasFilters =>
      regionId != null || difficulty != null || maxTimeMin != null || minCal != null || maxCal != null || orderBy != null;
```

Verify no other file references `hasFilters`:

```bash
grep -r "hasFilters" lib/
```

Expected: no output.

---

## Task 4: Run Flutter tests

**Testing layer: Dart**

- [ ] **Step 1: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass. If any fail, fix them before proceeding.

---

## Task 5: Commit Flutter changes

- [ ] **Step 1: Commit**

```bash
git add lib/providers/recipe_provider.dart
git commit -m "feat(feed): remove direct-table fallback, always use RPC with filter+order params"
```
