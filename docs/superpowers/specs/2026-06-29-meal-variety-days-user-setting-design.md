# Meal Variety Days — User Setting Design

**Date:** 2026-06-29
**Status:** Approved

## Problem

The 15-day cross-plan recipe blacklist (migration `20260629000002`) is hardcoded. Different users have different recipe pool sizes and variety preferences — some want no cross-plan exclusion, some want 7 days, some want 15. The value must be user-configurable.

## Goal

Users can choose one of three cross-plan variety windows:

| Option | Value | Meaning |
|---|---|---|
| None | 0 | No cross-plan exclusion — same behaviour as before the blacklist migration |
| 7 days | 7 | Exclude recipes used in the past 7 days (default) |
| 15 days | 15 | Exclude recipes used in the past 15 days |

The setting is stored per-user, exposed in the Meal Schedule page, and read server-side by all three meal plan generators.

## Scope

- 1 DB migration (new column on `user_profile`)
- 1 generator migration (rewrite all three functions to read the column)
- Flutter: `UserProfile` model, `user_profile_provider.dart`, `MealSchedulePage` UI, L10n strings
- No changes to function signatures, no Flutter build changes

## Architecture

### DB Schema

```sql
ALTER TABLE public.user_profile
  ADD COLUMN meal_variety_days INT NOT NULL DEFAULT 7
  CONSTRAINT meal_variety_days_check CHECK (meal_variety_days IN (0, 7, 15));
```

`DEFAULT 7` — PostgreSQL backfills existing rows with 7 when the column is added. New users also start at 7.

### Generator changes

Each of the three functions (`generate_meal_plan`, `generate_meal_plan_from_saved`, `generate_meal_plan_internal`) gets:

**New DECLARE variable:**
```sql
v_variety_days  int := 7;
```

**New read after existing `user_goal` query, before the day loop:**
```sql
SELECT COALESCE(meal_variety_days, 7) INTO v_variety_days
FROM public.user_profile WHERE id = p_user_id;
```

**Updated pre-loop blacklist query** (window uses `v_variety_days` instead of hardcoded `15`):
```sql
SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
INTO v_recent_recipe_ids
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
WHERE mp.user_id         = p_user_id
  AND mpe.scheduled_date >= (p_start_date - v_variety_days)
  AND mpe.scheduled_date <   p_start_date
  AND mpec.role          = 'base';
```

When `v_variety_days = 0`, the window `[p_start_date, p_start_date)` is impossible → `v_recent_recipe_ids` stays empty → no blacklisting. No special-casing needed.

The two-pass slot selection (Pass 1 with blacklist, Pass 2 fallback) is unchanged.

### Flutter model

`lib/shared/models/user_profile.dart` — add to `UserProfile`:

```dart
final int mealVarietyDays;  // 0 | 7 | 15
```

- Constructor default: `this.mealVarietyDays = 7`
- `fromJson`: `(json['meal_variety_days'] as int?) ?? 7`
- `copyWith`: `int? mealVarietyDays`

### Provider

`lib/providers/user_profile_provider.dart` — add a fire-and-forget save method:

```dart
Future<void> setMealVarietyDays(String userId, int days) async {
  await client
    .from('user_profile')
    .update({'meal_variety_days': days})
    .eq('id', userId);
}
```

### UI — MealSchedulePage

`lib/features/settings/meal_schedule_page.dart` — add a new section below the slot editor:

- Section title: `mealScheduleVarietyTitle` ("Recipe variety" / "Variété des recettes")
- Three tappable chips in a row: `mealScheduleVarietyNone` (0), `mealScheduleVariety7Days` (7), `mealScheduleVariety15Days` (15)
- Selected chip is highlighted; tapping saves immediately via `setMealVarietyDays` (no extra Save button)
- Current value read from `userProfileProvider`

### L10n keys

Both `app_en.arb` and `app_fr.arb`:

| Key | English | French |
|---|---|---|
| `mealScheduleVarietyTitle` | "Recipe variety" | "Variété des recettes" |
| `mealScheduleVarietySubtitle` | "Avoid repeating recipes used in the past N days" | "Éviter de répéter les recettes des N derniers jours" |
| `mealScheduleVarietyNone` | "None" | "Aucune" |
| `mealScheduleVariety7Days` | "7 days" | "7 jours" |
| `mealScheduleVariety15Days` | "15 days" | "15 jours" |

## Migration files

| File | Purpose |
|---|---|
| `supabase/migrations/20260629000003_user_profile_meal_variety_days.sql` | Add `meal_variety_days` column |
| `supabase/migrations/20260629000004_generate_meal_plan_variety_days_configurable.sql` | Rewrite all three generators to read `v_variety_days` |

## Tests

Update `supabase/tests/database/generate_meal_plan_variety.test.sql`:
- Test 1 blacklist assertion remains valid (uses default 7-day window — test user has no `user_profile` row so `COALESCE(..., 7)` applies, and the week-1 plan at day+200 is within 7 days of the week-2 plan at day+207 — **adjust Test 1 week-2 date from `day+208` to `day+207` or verify gap is ≤ 7**)
- Add Test 6: user with `meal_variety_days = 0` generates two consecutive plans and shares recipes between them (blacklist disabled)
- Add Test 7: user with `meal_variety_days = 7` — plan at day+8 reuses day+1 recipes (gap = 7 days, outside the `[p_start_date-7, p_start_date)` window)

**Important:** Test 1 currently places week-2 at `CURRENT_DATE + 208` and week-1 at `CURRENT_DATE + 200` — an 8-day gap. With a 7-day default, day+200 is NOT in the window `[day+201, day+208)` (window = day+208 - 7 = day+201). The A recipes from day+200 are therefore NOT blacklisted at day+208 — Test 1 would PASS spuriously. The test must be updated to use a gap ≤ 7 days (e.g. week-2 at `day+205`, gap = 5 days, window = `[day+198, day+205)` which DOES include day+200).

## Out of scope

- A custom number input (only the three fixed values are supported)
- Per-plan variety setting
- Applying the window to `swap_meal_plan_entry`
- Changing `p_max_recipe_repeat` semantics
