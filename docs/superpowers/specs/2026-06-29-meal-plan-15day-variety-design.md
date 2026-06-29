# Meal Plan 15-Day Variety — Design Spec

**Date:** 2026-06-29  
**Status:** Approved  

## Problem

`generate_meal_plan` (and its batch/internal variants) produce the same recipes every week. The root cause: `v_used_recipe_ids` is only pre-loaded from the **current active plan's past entries**. When the Monday cron creates a new weekly plan row, `v_used_recipe_ids` starts empty → the deterministic cosine-similarity scorer always picks the same top recipe for each slot.

## Goal

Recipes used in the **past 15 days** must not be selected for the new plan. If the recipe pool for a slot type is fully exhausted by the blacklist, the function falls back silently to the best available recipe ignoring the 15-day filter (pool-size tradeoff is the user's responsibility).

## Scope

Three SQL functions, one new migration, one new pgTAP test file. No schema changes. No Flutter changes.

| Function | Role | Change |
|---|---|---|
| `generate_meal_plan` | User-facing RPC (authenticated) | Yes |
| `generate_meal_plan_from_saved` | Batch cron, saved recipes only | Yes |
| `generate_meal_plan_internal` | Onboarding batch / cron recovery | Yes |

## Architecture

### New variable

Added to `DECLARE` in each function:

```sql
v_recent_recipe_ids  uuid[] := ARRAY[]::uuid[];
```

### New pre-loop query

Runs **once per function call**, after the existing `v_used_recipe_ids` load:

```sql
SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
INTO v_recent_recipe_ids
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
WHERE mp.user_id        = p_user_id
  AND mpe.scheduled_date >= (p_start_date - 15)
  AND mpe.scheduled_date <   p_start_date
  AND mpec.role = 'base';
```

The window is `p_start_date - 15` (relative to the new plan's start date, not `CURRENT_DATE`) so mid-week regeneration stays consistent.

### Two-pass slot selection

For every slot in the day loop, two SELECT attempts are made:

**Pass 1 — with 15-day blacklist:**
```sql
WHERE ...existing filters...
  AND r.id != ALL(v_recent_recipe_ids)
ORDER BY score DESC
LIMIT 1;
```

**Pass 2 — fallback (only runs if Pass 1 returns NULL):**
```sql
WHERE ...existing filters...
-- v_recent_recipe_ids filter omitted
ORDER BY score DESC
LIMIT 1;
```

**Still NULL after Pass 2** → `RAISE EXCEPTION 'insufficient_recipes'` (unchanged — truly empty pool).

### Invariants preserved

- `v_used_recipe_ids` (within-run deduplication via `p_max_recipe_repeat`) applies in **both** passes.
- Scoring weights, calorie math, ingredient inserts, SECURITY DEFINER, and REVOKE grants are all untouched.
- `generate_meal_plan_from_saved` retains its `ORDER BY score DESC, random()` tiebreaker.

### Vector / no-vector branches

`generate_meal_plan` and `generate_meal_plan_internal` each have two scoring branches (with `user_vector` and without). Each branch needs Pass 1 + Pass 2, resulting in 4 SELECT blocks per function. They share identical WHERE filters — the only diff between Pass 1 and Pass 2 is the `AND r.id != ALL(v_recent_recipe_ids)` line.

## Migration

**File:** `supabase/migrations/20260629000001_generate_meal_plan_15day_variety.sql`

Single file — drops and rewrites all three functions atomically. REVOKE grants for `generate_meal_plan_from_saved` and `generate_meal_plan_internal` are re-applied at the bottom, identical to the previous migrations.

## Tests

**File:** `supabase/tests/database/generate_meal_plan_variety.test.sql`

| # | Test | Setup | Assertion |
|---|---|---|---|
| 1 | Week 2 avoids week 1 recipes | Generate week 1 (start = today+7) then week 2 (start = today+14) for User A | No recipe_id in week 2 entries appears in week 1 entries |
| 2 | Fallback when pool exhausted | Generate enough consecutive weekly plans to exhaust User A's recipe pool | Final plan still generates without error |
| 3 | 15-day window is date-relative | Generate plan at today+1, then at today+20 | today+1 recipes are NOT blacklisted for the today+20 plan (gap = 19 days > 15) |
| 4 | Within-run dedup still works | Generate a 3-day plan for User A | No recipe appears more than `p_max_recipe_repeat` times within that single run |

Expected totals: **Files=4, Tests=31+** (baseline: Files=3, Tests=27).

## Out of scope

- Changing `p_max_recipe_repeat` semantics
- Any Flutter UI changes
- Personalising the 15-day window per user
- Applying the blacklist to `swap_meal_plan_entry`
