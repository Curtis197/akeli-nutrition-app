# Batch Cooking Preferences — Design Spec

**Goal:** Let users configure batch cooking (enabled/disabled, max portions per session) during onboarding and update it later from a new dedicated Preferences page in Settings, which also consolidates cooking time, food region, and dietary restrictions.

**Architecture:** Flutter front-end (Riverpod), one new SQL migration, one updated SQL migration, one updated Deno edge function. No new edge functions. Pure provider-based save (direct Supabase calls).

**Tech Stack:** Flutter/Riverpod, Supabase PostgreSQL 17, Deno edge functions, go_router.

---

## 1. Data Model & DB

### New migration: `add_batch_cooking_max_portions_to_user_profile`

```sql
ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS batch_cooking_max_portions int NOT NULL DEFAULT 4
  CHECK (batch_cooking_max_portions BETWEEN 2 AND 7);
```

`batch_cooking_enabled` (boolean) already exists on `user_profile`. Both columns are loaded and saved together.

### `UserPreferencesModel` (new Dart model)

```dart
class UserPreferencesModel {
  final String? cookingTime;         // 'quick' | 'medium' | 'any'
  final bool batchCookingEnabled;
  final int batchMaxPortions;        // 2–7, default 4
  final String? cuisineRegion;       // single region code
  final bool noPork;
  final bool noMeat;
  final bool noGluten;
  final bool noLactose;
  final List<String> allergies;
}
```

Loaded from 4 tables:
- `user_health_profile` → `cooking_time`
- `user_profile` → `batch_cooking_enabled`, `batch_cooking_max_portions`
- `user_cuisine_preference` → first active region code
- `user_dietary_restriction` → restriction codes mapped to bool flags + allergies

---

## 2. Onboarding Changes

### `OnboardingData` — 2 new fields

```dart
final bool batchCookingEnabled;   // default false
final int batchMaxPortions;       // default 4
```

Added to `copyWith`, `updateGoals()`, and `canAdvance()` (no new validation required).

### Goals step UI (existing step index 3)

After the cooking time radio group, append a new sub-section:

```
── Cuisson en batch ─────────────────────────────
  Préparez plusieurs repas en une fois.    [toggle]

  (visible only when toggle ON)
  Portions max par session
  [ 4 ▾ ]   ← DropdownButton values 2–7
─────────────────────────────────────────────────
```

The portions dropdown is shown/hidden with `AnimatedSwitcher` based on the toggle state.

### `complete-onboarding` edge function

Two new fields added to the request body and saved in **Step 7** (user_profile UPDATE):

```typescript
batch_cooking_enabled: boolean   // → user_profile.batch_cooking_enabled
batch_cooking_max_portions: number // → user_profile.batch_cooking_max_portions
```

The Flutter onboarding submission (`_submit()` in `onboarding_page.dart`) adds these to the body it sends.

---

## 3. `UserPreferencesProvider`

### Files

- `lib/shared/models/user_preferences.dart` — `UserPreferencesModel` with `copyWith`
- `lib/providers/user_preferences_provider.dart` — `UserPreferencesNotifier extends AsyncNotifier<UserPreferencesModel>`

### `build()`

Parallel-fetches all 4 tables using `Future.wait`:

```dart
final results = await Future.wait([
  supabase.from('user_health_profile').select('cooking_time').eq('user_id', uid).maybeSingle(),
  supabase.from('user_profile').select('batch_cooking_enabled, batch_cooking_max_portions').eq('id', uid).single(),
  supabase.from('user_cuisine_preference').select('region').eq('user_id', uid).limit(1).maybeSingle(),
  supabase.from('user_dietary_restriction').select('restriction').eq('user_id', uid),
]);
```

Assembles and returns `UserPreferencesModel`.

### `save(UserPreferencesModel updated)`

Parallel-writes all 4 tables:

```dart
await Future.wait([
  supabase.from('user_health_profile').upsert({'user_id': uid, 'cooking_time': updated.cookingTime}),
  supabase.from('user_profile').update({
    'batch_cooking_enabled': updated.batchCookingEnabled,
    'batch_cooking_max_portions': updated.batchMaxPortions,
  }).eq('id', uid),
  // Cuisine: delete all then re-insert (same pattern as complete-onboarding)
  supabase.from('user_cuisine_preference').delete().eq('user_id', uid).then((_) =>
    updated.cuisineRegion != null
      ? supabase.from('user_cuisine_preference').insert({'user_id': uid, 'region': updated.cuisineRegion, 'preference_score': 1.0})
      : Future.value()
  ),
  // Dietary restrictions: delete all then re-insert active flags + allergies
  supabase.from('user_dietary_restriction').delete().eq('user_id', uid).then((_) {
    final restrictions = [
      if (updated.noPork) 'no_pork',
      if (updated.noMeat) 'no_meat',
      if (updated.noGluten) 'no_gluten',
      if (updated.noLactose) 'no_lactose',
      ...updated.allergies,
    ];
    return restrictions.isNotEmpty
      ? supabase.from('user_dietary_restriction').insert(
          restrictions.map((r) => {'user_id': uid, 'restriction': r}).toList())
      : Future.value();
  }),
]);
```

On success, calls `ref.invalidateSelf()` to re-fetch fresh state.

---

## 4. `PreferencesPage`

### File

`lib/features/settings/preferences_page.dart`

### Visual structure

Frosted glass AppBar ("Préférences"), same pattern as `SettingsPage`. Body is a `SingleChildScrollView` with three card sections and a bottom save button.

**Section — Cuisson**
- Cooking time: 3 radio chips inline (Rapide `<30min` / Moyen `30–60min` / Peu importe)
- Batch cooking toggle row with subtitle
- Portions max dropdown row (2–7), animated in/out with `AnimatedSwitcher` when toggle changes

**Section — Région culinaire**
- Single-select region chips (same component as onboarding)

**Section — Restrictions alimentaires**
- Toggle rows: Sans porc / Sans viande / Sans gluten / Sans lactose
- Allergies: read-only chips row, tappable to open edit bottom sheet (same UI as onboarding)

**Bottom button**: full-width `FilledButton` "Enregistrer". On tap:
1. Calls `ref.read(userPreferencesProvider.notifier).save(localState)`
2. Shows success `SnackBar` on completion
3. Pops the page

The page holds a **local copy** of the model (initialized from the provider's async value) and edits it in `setState`. The provider is not updated until "Enregistrer" is tapped.

### Route

New route `/settings/preferences` in `lib/core/router.dart`.

### Settings page

Add to the "Menu" section in `settings_page.dart`:

```dart
_MenuItem(
  icon: Icons.tune_rounded,
  label: 'Préférences',
  onTap: () => context.push(AkeliRoutes.preferences),
),
```

---

## 5. Edge Function & `create_batch_sessions` Update

### `generate-meal-plan/index.ts` — Step 3.5

After `generate_meal_plan` RPC succeeds and before `create_batch_sessions`, fetch the user's batch preference:

```typescript
logger.debug("[STEP 3.5] Fetch batch cooking preference");
const { data: profileData } = await client
  .from("user_profile")
  .select("batch_cooking_enabled, batch_cooking_max_portions")
  .eq("id", user.id)
  .single();

const batchEnabled = profileData?.batch_cooking_enabled ?? false;
const maxPortions = profileData?.batch_cooking_max_portions ?? 4;
```

- If `batchEnabled === false` → skip `create_batch_sessions`, log reason.
- If `batchEnabled === true` → call `create_batch_sessions` with `p_max_portions: maxPortions`.

### `create_batch_sessions` RPC — new parameter

New migration updates the function signature:

```sql
CREATE OR REPLACE FUNCTION public.create_batch_sessions(
  p_meal_plan_id  uuid,
  p_user_id       uuid,
  p_max_portions  int DEFAULT 7
) ...
```

The HAVING clause becomes:

```sql
HAVING COUNT(*) >= 2 AND COUNT(*) <= p_max_portions
```

Recipes appearing more times than `p_max_portions` are not batched — the user cannot cook that many portions in a single session.

---

## What Does NOT Change

- `generate_meal_plan` RPC: no changes (batch preference is enforced at the edge function level)
- Existing onboarding steps 0–2, 4 (Preferences), 5 (NutritionPlan), 6 (Summary): unchanged
- RLS policies: unchanged
- All other settings menu items: unchanged

---

## Files Created / Modified

| Action | File |
|---|---|
| New migration | `supabase/migrations/YYYYMMDD_add_batch_cooking_max_portions.sql` |
| New migration | `supabase/migrations/YYYYMMDD_update_create_batch_sessions_max_portions.sql` |
| New | `lib/shared/models/user_preferences.dart` |
| New | `lib/providers/user_preferences_provider.dart` |
| New | `lib/features/settings/preferences_page.dart` |
| Modified | `lib/features/auth/onboarding_data.dart` |
| Modified | `lib/features/auth/onboarding_page.dart` |
| Modified | `lib/features/settings/settings_page.dart` |
| Modified | `lib/core/router.dart` |
| Modified | `supabase/functions/complete-onboarding/index.ts` |
| Modified | `supabase/functions/generate-meal-plan/index.ts` |
