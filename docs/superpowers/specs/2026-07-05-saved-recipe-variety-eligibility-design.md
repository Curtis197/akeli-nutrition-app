# Saved-Recipe Variety Eligibility — Design Spec

**Date:** 2026-07-05
**Status:** Approved

## Problem

Two related gaps let a user end up in "saved recipes only" mode with a saved-recipe pool too small to sustain their chosen variety window (`meal_variety_days`, user-configurable to 0/7/15):

1. **Generator (`generate_meal_plan_from_saved`) is purely reactive.** Every slot runs "Pass 1" (candidate query **with** the `meal_variety_days` recency blacklist) and only falls back to "Pass 2" (same query **without** the blacklist) if Pass 1 finds nothing. For a meal type whose saved pool can never satisfy the blacklist, Pass 1 always burns a query and always fails — and *when* it starts failing mid-plan is arbitrary (depends on how the blacklist fills up across the week), so variety silently degrades partway through a plan instead of being a deliberate, whole-plan decision.
2. **The eligibility gate is decoupled from `meal_variety_days`.** `evaluate_saved_recipe_eligibility` / `get_saved_recipe_eligibility_progress` require a hardcoded **7** saved recipes per meal type (breakfast/lunch/dinner) before the UI (`SavedRecipesEligibilityPage`) allows enabling `use_saved_recipes_only`. But `meal_variety_days` is independently configurable up to 15. A user can pass the gate with exactly 7 saved breakfast recipes, then raise variety to 15 days, and immediately hit the exact degradation described in (1) — the gate never re-checks against the variety setting.

## Goal

- Make the generator behave deterministically and efficiently when a meal type's saved pool can't sustain the recency blacklist, instead of reactively discovering this per-slot.
- Couple the eligibility threshold to `meal_variety_days` so the gate reflects what's actually needed for the user's chosen variety window, and keep it live as that setting changes.

## Scope

| Function / Object | Change |
|---|---|
| `generate_meal_plan_from_saved` | Yes — pool-size precheck per meal type, guards Pass 1 |
| `evaluate_saved_recipe_eligibility` | Yes — dynamic threshold formula |
| `get_saved_recipe_eligibility_progress` | Yes — dynamic threshold formula (progress bars) |
| `user_profile` trigger | New — re-evaluate eligibility on `meal_variety_days` change |
| Migration backfill | New — re-evaluate eligibility for all existing rows |
| `generate_meal_plan`, `generate_meal_plan_internal` | **No change** — draw from the full published catalog, not realistically small enough for this to matter |
| Eligibility check generalized to `snack` / arbitrary meal types | **Out of scope** — tracked as a separate follow-up (see below) |

## Part 1 — Generator: pool-size precheck

Before the day loop in `generate_meal_plan_from_saved`, compute a per-meal-type eligibility flag:

```sql
-- New declarations
v_variety_eligible_types  text[] := ARRAY[]::text[];
v_pool_count              int;
v_type                    text;

-- After v_recent_recipe_ids is computed, before the day loop:
FOR v_type IN SELECT DISTINCT (s->>'meal_type') FROM unnest(v_slots) AS s LOOP
  SELECT count(DISTINCT r.id) INTO v_pool_count
  FROM recipe r
  INNER JOIN recipe_save rs ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id
    AND r.is_published = true
    AND v_type = ANY(r.meal_types)
    AND NOT (r.allergen_tags && v_user_allergens);

  IF v_variety_days = 0 OR v_pool_count >= v_variety_days THEN
    v_variety_eligible_types := v_variety_eligible_types || v_type;
  END IF;
END LOOP;
```

Inside the slot loop:
- Pass 1 (the recency-blacklisted query) only runs `IF v_meal_type = ANY(v_variety_eligible_types)`.
- `v_recipe` is reset to `NULL` at the top of each slot iteration.
- Pass 2's guard simplifies from `IF v_recipe.id IS NULL AND array_length(v_recent_recipe_ids,1) IS NOT NULL` to `IF v_recipe.id IS NULL THEN` — this naturally covers both "Pass 1 was skipped" and "Pass 1 ran but found nothing."
- All other logic (budget check, exception raising, insert logic) is unchanged.

This check uses the raw `v_variety_days` (no floor) — it is a pure generation-correctness check, distinct from the eligibility floor in Part 2.

### Edge cases

- `meal_variety_days = 0` (variety off): every type trivially eligible; behavior is unchanged (blacklist window is empty anyway).
- Plan shorter than the variety window (e.g. `p_days=3`, `meal_variety_days=15`): a pool of 10 recipes would be flagged "not eligible" even though it could have satisfied Pass 1 for those 3 days. Accepted trade-off for simplicity — this forgoes some achievable freshness but never breaks correctness.
- Budget-constrained path (`weekly_budget` / `recipe_market_cost`): the pool-count check ignores budget on purpose (it's an availability check, not a cost check); the existing `insufficient_budget` vs `insufficient_saved_recipes` exception logic downstream is unaffected.
- A meal type with **zero** saved recipes (e.g. `snack`, which the eligibility gate doesn't check — see Out of Scope): both Pass 1 and Pass 2 fail regardless of this change, and `insufficient_saved_recipes` is raised exactly as today. This fix does not paper over a truly empty pool.

## Part 2 — Eligibility threshold formula

Replace the hardcoded `7` in `evaluate_saved_recipe_eligibility` and `get_saved_recipe_eligibility_progress` with:

```sql
v_target_count := CASE WHEN v_variety_days = 0 THEN 7 ELSE v_variety_days * 2 END;
```

| `meal_variety_days` | Old target | New target |
|---|---|---|
| 0 (off) | 7 | 7 (unchanged — baseline UX floor even with variety off) |
| 7 | 7 | 14 |
| 15 | 7 | 30 |

The doubling (rather than a 1x match to `v_variety_days`) gives headroom: as the blacklist window rolls forward day by day, a pool of exactly `N` recipes for an `N`-day window is fragile (any uneven usage exhausts it); `2N` keeps a comfortable rotation buffer. This is intentionally more conservative than the generator's own Part 1 check, which uses raw `v_variety_days` — the eligibility gate sets the bar for *entering* saved-only mode, the generator check is a runtime backstop for cases the gate can't fully prevent.

Both `evaluate_saved_recipe_eligibility` (which sets `is_saved_recipe_eligible` and force-disables `use_saved_recipes_only` on regression) and `get_saved_recipe_eligibility_progress` (which powers the UI progress bars and `target_count` values shown to the user) must use the same formula.

## Part 3 — Keeping eligibility live

Add a trigger on `user_profile`:

```sql
CREATE OR REPLACE FUNCTION public.trg_fn_evaluate_saved_recipe_eligibility_on_variety_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.evaluate_saved_recipe_eligibility(NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_evaluate_saved_recipe_eligibility_on_variety_change ON public.user_profile;
CREATE TRIGGER trg_evaluate_saved_recipe_eligibility_on_variety_change
  AFTER UPDATE OF meal_variety_days ON public.user_profile
  FOR EACH ROW
  WHEN (OLD.meal_variety_days IS DISTINCT FROM NEW.meal_variety_days)
  EXECUTE FUNCTION public.trg_fn_evaluate_saved_recipe_eligibility_on_variety_change();
```

This mirrors the existing `trg_evaluate_saved_recipe_eligibility` trigger on `recipe_save`. Raising variety from 7→15 with only, say, 14 saved recipes immediately flips `is_saved_recipe_eligible` to `false` and force-disables `use_saved_recipes_only` — same mechanism as unsaving a recipe today.

## Migration backfill

The migration must call `evaluate_saved_recipe_eligibility(id)` for every existing `user_profile` row (a simple `SELECT id FROM user_profile` loop, or `PERFORM` via a set-returning wrapper) so the new thresholds take effect immediately rather than waiting for the user's next recipe save/unsave or variety-day change.

**Known, accepted regression:** doubling the threshold means some users eligible **today** (e.g. exactly 7 saved recipes/type at `meal_variety_days=7`, old target was 7) will fall below the **new** target of 14 the moment this migration runs. The backfill will immediately force `is_saved_recipe_eligible = false` and, if it was on, `use_saved_recipes_only = false` for those users — identical in effect to them having unsaved a recipe. This is intentional: the new threshold is what actually guarantees their chosen variety window works.

## Tests

Extend `supabase/tests/database/generate_meal_plan_variety.test.sql` or add a new `saved_recipe_eligibility.test.sql`:

1. **Generator — small pool, variety on:** 5 saved breakfast recipes, `meal_variety_days=7`. Plan generates without error; no `insufficient_saved_recipes`; repeats are allowed deliberately (Pass 1 skipped for breakfast) rather than discovered via failed queries.
2. **Generator — large pool, variety on:** 20 saved breakfast recipes, `meal_variety_days=7`. Recency blacklist still enforced as today (no regression).
3. **Generator — variety off:** `meal_variety_days=0`. Output identical to pre-change behavior regardless of pool size.
4. **Eligibility — threshold scales:** user with 10 saved recipes/type at `meal_variety_days=7` (target 14) → NOT eligible. Same user with 14 saved recipes/type at `meal_variety_days=7` (target 14) → eligible. Same user (14 saved/type) after switching to `meal_variety_days=15` (target 30) → NOT eligible.
5. **Trigger — variety change:** user eligible at `meal_variety_days=7` with 14 saved recipes/type and `use_saved_recipes_only=true`. Update `meal_variety_days` to 15 → `is_saved_recipe_eligible` and `use_saved_recipes_only` both flip to `false` without any `recipe_save` change.
6. **Backfill:** after migration, a pre-existing user with 7 saved recipes/type and `meal_variety_days=7` (old target 7, met) has `is_saved_recipe_eligible = false` post-migration (new target 14, not met).

## Out of scope

- Generalizing the eligibility gate to check `snack` or any meal type beyond breakfast/lunch/dinner (it currently ignores `snack` entirely, even though custom schedules can include snack slots). Tracked as a separate follow-up — it requires iterating the user's actual `meal_distribution` rows rather than three hardcoded meal types, which is a different mechanism from this spec's threshold-coupling fix.
- Any change to `generate_meal_plan` or `generate_meal_plan_internal`.
- Any Flutter/UI changes beyond what naturally follows from the RPC's `target_count` values changing (the existing `SavedRecipesEligibilityPage` already renders whatever `target_count` the RPC returns — no code change needed there).
- Changing the allowed `meal_variety_days` values (stays 0/7/15).
