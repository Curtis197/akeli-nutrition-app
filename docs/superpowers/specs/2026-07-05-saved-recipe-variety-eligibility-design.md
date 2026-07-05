# Saved-Recipe Variety Eligibility — Design Spec

**Date:** 2026-07-05
**Status:** Approved

## Problem

Three related gaps let a user end up in "saved recipes only" mode with a saved-recipe pool too small to sustain their chosen variety window (`meal_variety_days`, user-configurable to 0/7/15):

1. **Generator (`generate_meal_plan_from_saved`) is purely reactive.** Every slot runs "Pass 1" (candidate query **with** the `meal_variety_days` recency blacklist) and only falls back to "Pass 2" (same query **without** the blacklist) if Pass 1 finds nothing. For a meal type whose saved pool can never satisfy the blacklist, Pass 1 always burns a query and always fails — and *when* it starts failing mid-plan is arbitrary (depends on how the blacklist fills up across the week), so variety silently degrades partway through a plan instead of being a deliberate, whole-plan decision.
2. **The eligibility gate is decoupled from `meal_variety_days`.** `evaluate_saved_recipe_eligibility` / `get_saved_recipe_eligibility_progress` require a hardcoded **7** saved recipes per meal type (breakfast/lunch/dinner) before the UI (`SavedRecipesEligibilityPage`) allows enabling `use_saved_recipes_only`. But `meal_variety_days` is independently configurable up to 15, and `MealSchedulePage` (where it's set) has zero awareness of saved-recipe counts or `use_saved_recipes_only`. A user can pass the gate with exactly 7 saved breakfast recipes, then raise variety to 15 days with no warning anywhere, and immediately hit the exact degradation described in (1).
3. **Nothing but a disabled UI switch stops a direct write.** Both write paths for `use_saved_recipes_only` (`setMealVarietyDaysProvider`'s sibling calls and `UserPreferencesNotifier.save`, in `user_preferences_provider.dart`) write straight to `user_profile` from the Flutter client with no RPC or DB check. A modified client, a bug, or a direct API call could set `use_saved_recipes_only = true` while ineligible, and nothing would correct it until the next unrelated `recipe_save` or `meal_variety_days` event re-triggers evaluation.

## Goal

- Make the generator behave deterministically and efficiently when a meal type's saved pool can't sustain the recency blacklist, instead of reactively discovering this per-slot.
- Couple the eligibility threshold to `meal_variety_days`.
- Give the user proactive, in-context feedback in the app (primary) when a change would break the saved-recipes/variety combination, backed by a DB-level guard (secondary) that enforces the invariant regardless of what the client does.

## Scope

| File / Object | Layer | Change |
|---|---|---|
| `generate_meal_plan_from_saved` | DB | Yes — pool-size precheck per meal type, guards Pass 1 |
| `evaluate_saved_recipe_eligibility` | DB | Yes — dynamic threshold formula |
| `get_saved_recipe_eligibility_progress` | DB | Yes — dynamic threshold formula (feeds UI progress bars) |
| `user_profile` trigger (on `meal_variety_days` change) | DB | New — re-evaluate eligibility |
| `user_profile` trigger (on `use_saved_recipes_only` write) | DB | New — security backstop, silently revert if ineligible |
| Migration backfill | DB | New — re-evaluate eligibility for all existing rows |
| `lib/core/saved_recipe_eligibility.dart` | Dart | New — shared `savedRecipeEligibilityTarget()` formula |
| `lib/features/settings/saved_recipes_eligibility_page.dart` | Dart | Yes — derive eligibility from counts/targets; SnackBar on blocked tap |
| `lib/features/settings/meal_schedule_page.dart` (`_VarietySection`) | Dart | Yes — SnackBar warning on chip tap when it would break eligibility |
| `lib/providers/user_profile_provider.dart` (`setMealVarietyDaysProvider`) | Dart | Yes — also invalidate `savedRecipeProgressProvider` |
| `generate_meal_plan`, `generate_meal_plan_internal` | DB | **No change** — draw from the full published catalog, not realistically small enough for this to matter |
| Eligibility generalized to `snack` / arbitrary meal types | — | **Out of scope** — tracked as a separate follow-up |

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

## Part 2 — Eligibility threshold formula (DB, source of truth)

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

Both `evaluate_saved_recipe_eligibility` (sets `is_saved_recipe_eligible`, force-disables `use_saved_recipes_only` on regression) and `get_saved_recipe_eligibility_progress` (powers the UI progress bars and `target_count` values) must use the same formula. This SQL formula is the authoritative source of truth; the Dart formula in Part 3 is a client-side mirror for responsive UI feedback and must be kept in sync with it by hand.

## Part 3 — Primary: UI (Dart) proactive guard

### 3a. Shared formula

New file `lib/core/saved_recipe_eligibility.dart`:

```dart
/// Mirrors the SQL formula in evaluate_saved_recipe_eligibility /
/// get_saved_recipe_eligibility_progress. Keep in sync by hand.
int savedRecipeEligibilityTarget(int mealVarietyDays) =>
    mealVarietyDays == 0 ? 7 : mealVarietyDays * 2;
```

### 3b. `SavedRecipesEligibilityPage`

- Derive the switch's enabled state directly from `progressData.progress.every((p) => p.savedCount >= p.targetCount)` (using the RPC's per-meal-type counts/targets, which Part 2 already makes variety-aware) instead of trusting the separately-computed `is_eligible` server field. Instant, and doesn't depend on trigger timing.
- The switch stays visually disabled (`onChanged: null` equivalent) when ineligible, but the tile is wrapped so a tap while disabled still surfaces feedback: show a SnackBar naming the specific shortfall(s), built from `progressData.progress.where((p) => p.savedCount < p.targetCount)`, e.g. *"Save 16 more lunch recipes to enable this (14/30)."* Multiple shortfalls are joined into one message.

### 3c. `MealSchedulePage._VarietySection`

- Keep the existing "instant apply on chip tap" pattern (`ref.read(setMealVarietyDaysProvider(...))`) — no new blocking confirmation dialog, consistent with how this control already behaves.
- Before/alongside that call, if `useSavedRecipesOnly` is currently `true` and `savedRecipeEligibilityTarget(days)` exceeds any of the user's current saved counts (from `savedRecipeProgressProvider`), show a SnackBar at tap time: *"Switching to 15-day variety turns off 'use only saved recipes' — you have 14/30 lunch recipes needed."*
- This SnackBar is purely informative. The actual flip of `use_saved_recipes_only` to `false` is performed authoritatively by the DB (Part 4a), not by this Dart code — the UI is telling the user what the backend is about to do, not doing it itself.

### 3d. Provider wiring

`setMealVarietyDaysProvider` (`user_profile_provider.dart:358`) currently only calls `ref.invalidate(userProfileProvider)` after a successful update. Add `ref.invalidate(savedRecipeProgressProvider)` alongside it, so that if the user navigates to `SavedRecipesEligibilityPage` right after changing variety, the displayed `target_count` values are fresh rather than cached from before the change.

## Part 4 — Secondary: DB enforcement (security net)

### 4a. Re-evaluate on variety change

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

Mirrors the existing `trg_evaluate_saved_recipe_eligibility` trigger on `recipe_save`. This is what actually performs the flip the Part 3c SnackBar warns about — raising variety from 7→15 with only 14 saved recipes immediately flips `is_saved_recipe_eligible` to `false` and force-disables `use_saved_recipes_only`.

### 4b. Guard direct writes to `use_saved_recipes_only`

```sql
CREATE OR REPLACE FUNCTION public.trg_fn_guard_use_saved_recipes_only()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.use_saved_recipes_only = true AND COALESCE(NEW.is_saved_recipe_eligible, false) = false THEN
    NEW.use_saved_recipes_only := false;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_use_saved_recipes_only ON public.user_profile;
CREATE TRIGGER trg_guard_use_saved_recipes_only
  BEFORE UPDATE OF use_saved_recipes_only ON public.user_profile
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_guard_use_saved_recipes_only();
```

Silently reverts any attempt (buggy client, direct API call, race condition) to set `use_saved_recipes_only = true` while `is_saved_recipe_eligible` is false. This is the actual enforcement the Problem statement's point 3 was missing — today, only a disabled Flutter widget stands between a client and an invalid state. Matches the existing silent-correction style already used in `evaluate_saved_recipe_eligibility` (no new exception type for the edge function or Dart layer to handle).

Known limitation: relies on `is_saved_recipe_eligible` being current at write time, which depends on 4a and the pre-existing `recipe_save` trigger having already fired. A write landing in the same instant as an eligibility-changing event has a narrow race window. Accepted as reasonable defense-in-depth, not a claim of perfect atomicity.

### 4c. Migration backfill

The migration must call `evaluate_saved_recipe_eligibility(id)` for every existing `user_profile` row (a simple loop or set-returning wrapper) so the new thresholds take effect immediately rather than waiting for the user's next recipe save/unsave or variety-day change.

**Known, accepted regression:** doubling the threshold means some users eligible **today** (e.g. exactly 7 saved recipes/type at `meal_variety_days=7`, old target was 7) will fall below the **new** target of 14 the moment this migration runs. The backfill will immediately force `is_saved_recipe_eligible = false` and, if it was on, `use_saved_recipes_only = false` for those users — identical in effect to them having unsaved a recipe. This is intentional: the new threshold is what actually guarantees their chosen variety window works.

## Tests

Extend `supabase/tests/database/generate_meal_plan_variety.test.sql` or add a new `saved_recipe_eligibility.test.sql` (pgTAP):

1. **Generator — small pool, variety on:** 5 saved breakfast recipes, `meal_variety_days=7`. Plan generates without error; no `insufficient_saved_recipes`; repeats are allowed deliberately (Pass 1 skipped for breakfast) rather than discovered via failed queries.
2. **Generator — large pool, variety on:** 20 saved breakfast recipes, `meal_variety_days=7`. Recency blacklist still enforced as today (no regression).
3. **Generator — variety off:** `meal_variety_days=0`. Output identical to pre-change behavior regardless of pool size.
4. **Eligibility — threshold scales:** user with 10 saved recipes/type at `meal_variety_days=7` (target 14) → NOT eligible. Same user with 14 saved recipes/type at `meal_variety_days=7` (target 14) → eligible. Same user (14 saved/type) after switching to `meal_variety_days=15` (target 30) → NOT eligible.
5. **Trigger 4a — variety change:** user eligible at `meal_variety_days=7` with 14 saved recipes/type and `use_saved_recipes_only=true`. Update `meal_variety_days` to 15 → `is_saved_recipe_eligible` and `use_saved_recipes_only` both flip to `false` without any `recipe_save` change.
6. **Trigger 4b — direct write guard:** with `is_saved_recipe_eligible=false`, directly `UPDATE user_profile SET use_saved_recipes_only = true` → row ends up with `use_saved_recipes_only = false` (silently reverted).
7. **Backfill:** after migration, a pre-existing user with 7 saved recipes/type and `meal_variety_days=7` (old target 7, met) has `is_saved_recipe_eligible = false` post-migration (new target 14, not met).

Dart-side (manual verification, no automated widget tests required by this spec):
8. On `SavedRecipesEligibilityPage`, tapping the disabled switch shows a SnackBar naming the exact shortfall.
9. On `MealSchedulePage`, tapping a variety chip that would break current saved-only eligibility shows the explanatory SnackBar, and the variety change still applies.
10. After changing variety and navigating to `SavedRecipesEligibilityPage`, target counts reflect the new value immediately (no stale cache).

## Out of scope

- Generalizing the eligibility gate to check `snack` or any meal type beyond breakfast/lunch/dinner (it currently ignores `snack` entirely, even though custom schedules can include snack slots). Tracked as a separate follow-up — it requires iterating the user's actual `meal_distribution` rows rather than three hardcoded meal types, which is a different mechanism from this spec's threshold-coupling fix.
- Any change to `generate_meal_plan` or `generate_meal_plan_internal`.
- A blocking confirmation dialog on the variety chips — deliberately rejected in favor of instant-apply + SnackBar, to match the page's existing interaction pattern.
- Changing the allowed `meal_variety_days` values (stays 0/7/15).
