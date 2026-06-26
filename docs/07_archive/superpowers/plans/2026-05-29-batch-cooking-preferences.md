# Batch Cooking Preferences Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users set batch cooking preferences (enabled/disabled + max portions 2–7) during onboarding alongside the cooking time question, and update all cooking/region/dietary preferences from a new dedicated Preferences page in Settings.

**Architecture:** One new `UserPreferencesModel` + `UserPreferencesNotifier` aggregates data from 4 tables. `PreferencesPage` edits a local copy and saves all at once. Onboarding gains 2 new fields passed through `complete-onboarding`. The `generate-meal-plan` edge function checks `batch_cooking_enabled` before calling `create_batch_sessions`, which gains a `p_max_portions` parameter. Two SQL migrations. No new edge functions.

**Tech Stack:** Flutter 3 / Riverpod / go_router, Supabase PostgreSQL 17, Deno edge functions, supabase_flutter SDK.

---

## File Map

| Action | Path |
|---|---|
| New migration | `supabase/migrations/20260529000009_add_batch_cooking_max_portions.sql` |
| New migration | `supabase/migrations/20260529000010_update_create_batch_sessions_max_portions.sql` |
| New | `lib/shared/models/user_preferences.dart` |
| New | `lib/providers/user_preferences_provider.dart` |
| New | `lib/features/settings/preferences_page.dart` |
| Modify | `lib/features/auth/onboarding_data.dart` |
| Modify | `lib/features/auth/onboarding_page.dart` |
| Modify | `lib/features/settings/settings_page.dart` |
| Modify | `lib/core/router.dart` |
| Modify | `supabase/functions/complete-onboarding/index.ts` |
| Modify | `supabase/functions/generate-meal-plan/index.ts` |

---

## Task 1: DB Migration — `batch_cooking_max_portions` on `user_profile`

**Files:**
- Create: `supabase/migrations/20260529000009_add_batch_cooking_max_portions.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260529000009_add_batch_cooking_max_portions.sql
ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS batch_cooking_max_portions int NOT NULL DEFAULT 4
  CHECK (batch_cooking_max_portions BETWEEN 2 AND 7);
```

- [ ] **Step 2: Apply via Supabase MCP**

Use the Supabase MCP `apply_migration` tool:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `add_batch_cooking_max_portions`
- `query`: the SQL above

- [ ] **Step 3: Verify column exists**

Run via MCP `execute_sql`:
```sql
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'user_profile'
  AND column_name = 'batch_cooking_max_portions';
```
Expected: 1 row, `data_type=integer`, `column_default=4`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260529000009_add_batch_cooking_max_portions.sql
git commit -m "feat(db): add batch_cooking_max_portions to user_profile"
```

---

## Task 2: DB Migration — `create_batch_sessions` with `p_max_portions`

**Files:**
- Create: `supabase/migrations/20260529000010_update_create_batch_sessions_max_portions.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260529000010_update_create_batch_sessions_max_portions.sql
-- Add p_max_portions parameter: only batch recipes the user can cook all at once.

CREATE OR REPLACE FUNCTION public.create_batch_sessions(
  p_meal_plan_id  uuid,
  p_user_id       uuid,
  p_max_portions  int DEFAULT 7
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_rec              RECORD;
  v_recipe_servings  numeric;
  v_scale_factor     numeric(6,3);
  v_session_id       uuid;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.meal_plan
    WHERE id = p_meal_plan_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM public.cooking_session
  WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;

  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)                AS appearance_count,
      SUM(mpe.servings)       AS total_portions_needed,
      MIN(mpe.scheduled_date) AS first_date
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2 AND COUNT(*) <= p_max_portions
  LOOP
    SELECT servings INTO v_recipe_servings
    FROM public.recipe WHERE id = v_rec.recipe_id;

    v_scale_factor := ROUND(
      (v_rec.total_portions_needed / GREATEST(COALESCE(v_recipe_servings, 1), 1))::numeric,
      3
    );

    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used, scale_factor
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, CEIL(v_rec.total_portions_needed), 0, v_scale_factor
    )
    RETURNING id INTO v_session_id;

    INSERT INTO public.cooking_session_ingredient
      (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
    SELECT
      v_session_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      ROUND((ri.quantity * v_scale_factor)::numeric, 3),
      ri.unit
    FROM public.recipe_ingredient ri
    JOIN public.ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_rec.recipe_id
      AND ri.is_optional = false;

    UPDATE public.meal_plan_entry_component mpec
    SET cooking_session_id = v_session_id
    FROM public.meal_plan_entry mpe
    WHERE mpec.meal_plan_entry_id = mpe.id
      AND mpe.meal_plan_id = p_meal_plan_id
      AND mpec.recipe_id = v_rec.recipe_id;

  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.create_batch_sessions(uuid, uuid, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_batch_sessions(uuid, uuid, int) TO authenticated;
```

- [ ] **Step 2: Apply via Supabase MCP**

Use the Supabase MCP `apply_migration` tool:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `update_create_batch_sessions_max_portions`
- `query`: the SQL above

- [ ] **Step 3: Verify function signature**

Run via MCP `execute_sql`:
```sql
SELECT proname, pg_get_function_arguments(oid) AS args
FROM pg_proc
WHERE proname = 'create_batch_sessions'
  AND pronamespace = 'public'::regnamespace;
```
Expected: args contains `p_max_portions integer DEFAULT 7`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260529000010_update_create_batch_sessions_max_portions.sql
git commit -m "feat(db): add p_max_portions to create_batch_sessions"
```

---

## Task 3: `UserPreferencesModel`

**Files:**
- Create: `lib/shared/models/user_preferences.dart`

- [ ] **Step 1: Create the model file**

```dart
// lib/shared/models/user_preferences.dart

class UserPreferencesModel {
  final String? cookingTime;       // 'quick' | 'medium' | 'any' | null
  final bool batchCookingEnabled;
  final int batchMaxPortions;      // 2–7
  final String? cuisineRegion;     // region code or null
  final bool noPork;
  final bool noMeat;
  final bool noGluten;
  final bool noLactose;
  final List<String> allergies;

  const UserPreferencesModel({
    this.cookingTime,
    this.batchCookingEnabled = false,
    this.batchMaxPortions = 4,
    this.cuisineRegion,
    this.noPork = false,
    this.noMeat = false,
    this.noGluten = false,
    this.noLactose = false,
    this.allergies = const [],
  });

  UserPreferencesModel copyWith({
    String? cookingTime,
    bool? batchCookingEnabled,
    int? batchMaxPortions,
    String? cuisineRegion,
    bool? noPork,
    bool? noMeat,
    bool? noGluten,
    bool? noLactose,
    List<String>? allergies,
    bool clearCookingTime = false,
    bool clearCuisineRegion = false,
  }) =>
      UserPreferencesModel(
        cookingTime: clearCookingTime ? null : (cookingTime ?? this.cookingTime),
        batchCookingEnabled: batchCookingEnabled ?? this.batchCookingEnabled,
        batchMaxPortions: batchMaxPortions ?? this.batchMaxPortions,
        cuisineRegion: clearCuisineRegion ? null : (cuisineRegion ?? this.cuisineRegion),
        noPork: noPork ?? this.noPork,
        noMeat: noMeat ?? this.noMeat,
        noGluten: noGluten ?? this.noGluten,
        noLactose: noLactose ?? this.noLactose,
        allergies: allergies ?? this.allergies,
      );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/models/user_preferences.dart
git commit -m "feat: add UserPreferencesModel"
```

---

## Task 4: `UserPreferencesProvider`

**Files:**
- Create: `lib/providers/user_preferences_provider.dart`

Context: The project uses Riverpod. Every Dart file must import `package:akeli/core/logger.dart` and use `appLogger` per CLAUDE.md. Supabase client is accessed via `ref.watch(supabaseClientProvider)`. User ID via `ref.watch(currentUserProvider)`.

- [ ] **Step 1: Create the provider file**

```dart
// lib/providers/user_preferences_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/user_preferences.dart';
import 'auth_provider.dart';

class UserPreferencesNotifier
    extends AutoDisposeAsyncNotifier<UserPreferencesModel> {
  final _logger = appLogger;

  static const _knownRestrictions = {'no_pork', 'no_meat', 'no_gluten', 'no_lactose'};

  @override
  Future<UserPreferencesModel> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const UserPreferencesModel();

    _logger.provider('UserPreferencesNotifier build() | userId: ${user.id}');
    ref.onDispose(() => _logger.provider('UserPreferencesNotifier disposed'));

    final client = ref.watch(supabaseClientProvider);

    _logger.db('BEFORE | tables: user_health_profile,user_profile,user_cuisine_preference,user_dietary_restriction | op: SELECT | userId: ${user.id}');

    try {
      final healthFuture = client
          .from('user_health_profile')
          .select('cooking_time')
          .eq('user_id', user.id)
          .maybeSingle();

      final profileFuture = client
          .from('user_profile')
          .select('batch_cooking_enabled, batch_cooking_max_portions')
          .eq('id', user.id)
          .single();

      final cuisineFuture = client
          .from('user_cuisine_preference')
          .select('region')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      final restrictionsFuture = client
          .from('user_dietary_restriction')
          .select('restriction')
          .eq('user_id', user.id);

      final results = await Future.wait<dynamic>([
        healthFuture,
        profileFuture,
        cuisineFuture,
        restrictionsFuture,
      ]);

      final health = results[0] as Map<String, dynamic>?;
      final profile = results[1] as Map<String, dynamic>;
      final cuisine = results[2] as Map<String, dynamic>?;
      final rawRestrictions = results[3] as List<dynamic>;

      final restrictionCodes =
          rawRestrictions.map((r) => r['restriction'] as String).toList();

      _logger.db('AFTER | tables: user_health_profile,user_profile,user_cuisine_preference,user_dietary_restriction | userId: ${user.id}');
      _logger.provider('UserPreferencesNotifier → data | userId: ${user.id}');

      return UserPreferencesModel(
        cookingTime: health?['cooking_time'] as String?,
        batchCookingEnabled: profile['batch_cooking_enabled'] as bool? ?? false,
        batchMaxPortions: profile['batch_cooking_max_portions'] as int? ?? 4,
        cuisineRegion: cuisine?['region'] as String?,
        noPork: restrictionCodes.contains('no_pork'),
        noMeat: restrictionCodes.contains('no_meat'),
        noGluten: restrictionCodes.contains('no_gluten'),
        noLactose: restrictionCodes.contains('no_lactose'),
        allergies: restrictionCodes
            .where((r) => !_knownRestrictions.contains(r))
            .toList(),
      );
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | UserPreferencesNotifier | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | UserPreferencesNotifier | code: ${e.code}', error: e, stackTrace: st);
      }
      _logger.provider('UserPreferencesNotifier → error | ${e.message}');
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | UserPreferencesNotifier | unexpected: $e', error: e, stackTrace: st);
      _logger.provider('UserPreferencesNotifier → error | $e');
      rethrow;
    }
  }

  Future<void> save(UserPreferencesModel updated) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('UserPreferences save', metadata: {
      'batchEnabled': updated.batchCookingEnabled,
      'maxPortions': updated.batchMaxPortions,
      'cookingTime': updated.cookingTime,
      'region': updated.cuisineRegion,
    });

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();

    try {
      // 1. Update cooking_time in user_health_profile
      _logger.db('BEFORE | table: user_health_profile | op: UPSERT | userId: ${user.id}');
      await client.from('user_health_profile').upsert({
        'user_id': user.id,
        if (updated.cookingTime != null) 'cooking_time': updated.cookingTime,
      });
      _logger.db('AFTER | table: user_health_profile | op: UPSERT | rows: 1');

      // 2. Update batch prefs in user_profile
      _logger.db('BEFORE | table: user_profile | op: UPDATE | userId: ${user.id}');
      await client.from('user_profile').update({
        'batch_cooking_enabled': updated.batchCookingEnabled,
        'batch_cooking_max_portions': updated.batchMaxPortions,
      }).eq('id', user.id);
      _logger.db('AFTER | table: user_profile | op: UPDATE | rows: 1');

      // 3. Replace cuisine preference (delete + re-insert)
      _logger.db('BEFORE | table: user_cuisine_preference | op: DELETE | userId: ${user.id}');
      await client
          .from('user_cuisine_preference')
          .delete()
          .eq('user_id', user.id);
      _logger.db('AFTER | table: user_cuisine_preference | op: DELETE');

      if (updated.cuisineRegion != null) {
        _logger.db('BEFORE | table: user_cuisine_preference | op: INSERT | userId: ${user.id}');
        await client.from('user_cuisine_preference').insert({
          'user_id': user.id,
          'region': updated.cuisineRegion,
          'preference_score': 1.0,
        });
        _logger.db('AFTER | table: user_cuisine_preference | op: INSERT | rows: 1');
      }

      // 4. Replace dietary restrictions (delete + re-insert)
      _logger.db('BEFORE | table: user_dietary_restriction | op: DELETE | userId: ${user.id}');
      await client
          .from('user_dietary_restriction')
          .delete()
          .eq('user_id', user.id);
      _logger.db('AFTER | table: user_dietary_restriction | op: DELETE');

      final restrictions = [
        if (updated.noPork) 'no_pork',
        if (updated.noMeat) 'no_meat',
        if (updated.noGluten) 'no_gluten',
        if (updated.noLactose) 'no_lactose',
        ...updated.allergies,
      ];
      if (restrictions.isNotEmpty) {
        _logger.db('BEFORE | table: user_dietary_restriction | op: INSERT | rows: ${restrictions.length}');
        await client.from('user_dietary_restriction').insert(
          restrictions.map((r) => {'user_id': user.id, 'restriction': r}).toList(),
        );
        _logger.db('AFTER | table: user_dietary_restriction | op: INSERT | rows: ${restrictions.length}');
      }

      _logger.provider('UserPreferencesNotifier → save success');
      ref.invalidateSelf();
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | UserPreferencesNotifier save | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | UserPreferencesNotifier save | code: ${e.code}', error: e, stackTrace: st);
      }
      _logger.provider('UserPreferencesNotifier → error (save)');
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | UserPreferencesNotifier save | unexpected: $e', error: e, stackTrace: st);
      _logger.provider('UserPreferencesNotifier → error (save unexpected)');
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final userPreferencesProvider = AsyncNotifierProvider.autoDispose<
    UserPreferencesNotifier, UserPreferencesModel>(UserPreferencesNotifier.new);
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/providers/user_preferences_provider.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/models/user_preferences.dart lib/providers/user_preferences_provider.dart
git commit -m "feat: add UserPreferencesNotifier with 4-table load and save"
```

---

## Task 5: Onboarding Data — New Fields

**Files:**
- Modify: `lib/features/auth/onboarding_data.dart`

- [ ] **Step 1: Add fields to `OnboardingData`**

Add two fields after `cookingTime` (around line 24):

```dart
  final bool batchCookingEnabled;
  final int batchMaxPortions;
```

Add defaults to the constructor (after `cookingTime,`):

```dart
    this.batchCookingEnabled = false,
    this.batchMaxPortions = 4,
```

Add to `copyWith` parameters (after `String? cookingTime,`):

```dart
    bool? batchCookingEnabled,
    int? batchMaxPortions,
```

Add to `copyWith` body (after `cookingTime: cookingTime ?? this.cookingTime,`):

```dart
        batchCookingEnabled: batchCookingEnabled ?? this.batchCookingEnabled,
        batchMaxPortions: batchMaxPortions ?? this.batchMaxPortions,
```

Add to `updateGoals()` parameters (after `String? cookingTime,`):

```dart
    bool? batchCookingEnabled,
    int? batchMaxPortions,
```

Add to `updateGoals()` body (after `cookingTime: cookingTime`):

```dart
          batchCookingEnabled: batchCookingEnabled,
          batchMaxPortions: batchMaxPortions,
```

Also add to both `clearProfile()` and `clearTargetWeight()` factory constructors — add these lines after `cookingTime: state.cookingTime,`:

```dart
        batchCookingEnabled: state.batchCookingEnabled,
        batchMaxPortions: state.batchMaxPortions,
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/auth/onboarding_data.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/onboarding_data.dart
git commit -m "feat: add batchCookingEnabled + batchMaxPortions to OnboardingData"
```

---

## Task 6: Onboarding Goals Step — Batch Cooking UI

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart`

Context: The cooking time section ends around line 1377 with a closing `),` after the last `_GoalRadioOption`. The batch cooking card must be added **after** the closing `_StepCard` for cooking time, before the final `],` that closes the `Column` children inside `_StepGoals`.

- [ ] **Step 1: Add batch cooking `_StepCard` after cooking time card**

Locate the cooking time section ending (the closing `),` of the cooking time `_StepCard` around line 1377). After it, add:

```dart
          const SizedBox(height: AkeliSpacing.lg),

          // ── Batch cooking ─────────────────────────────────────────────
          _StepCard(
            child: Consumer(
              builder: (context, ref, _) {
                final data = ref.watch(onboardingProvider);
                final notifier = ref.read(onboardingProvider.notifier);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CUISSON EN BATCH',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                    const SizedBox(height: AkeliSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Préparer plusieurs repas à la fois',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AkeliColors.onSurface)),
                              const SizedBox(height: 2),
                              Text('Cuire en grande quantité pour la semaine',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AkeliColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Switch(
                          value: data.batchCookingEnabled,
                          activeColor: AkeliColors.primary,
                          onChanged: (v) {
                            appLogger.userAction('Batch cooking toggled',
                                screen: 'OnboardingPage',
                                metadata: {'enabled': v});
                            notifier.updateGoals(batchCookingEnabled: v);
                          },
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: data.batchCookingEnabled
                          ? Padding(
                              key: const ValueKey('portions'),
                              padding: const EdgeInsets.only(top: AkeliSpacing.md),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Portions max par session',
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          color: AkeliColors.onSurface)),
                                  DropdownButton<int>(
                                    value: data.batchMaxPortions,
                                    underline: const SizedBox.shrink(),
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AkeliColors.primary),
                                    items: List.generate(6, (i) => i + 2)
                                        .map((n) => DropdownMenuItem(
                                              value: n,
                                              child: Text('$n'),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      appLogger.userAction(
                                          'Batch max portions selected',
                                          screen: 'OnboardingPage',
                                          metadata: {'portions': v});
                                      notifier.updateGoals(batchMaxPortions: v);
                                    },
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('hidden')),
                    ),
                  ],
                );
              },
            ),
          ),
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/auth/onboarding_page.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/onboarding_page.dart
git commit -m "feat: add batch cooking toggle + portions dropdown to onboarding goals step"
```

---

## Task 7: Onboarding Submit — Send New Fields

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart`

Context: `_submit()` builds a `body` map around lines 117–133. The new fields must be added to this map before `client.functions.invoke` is called.

- [ ] **Step 1: Add new fields to the body map in `_submit()`**

In the `body` map (after `if (d.cookingTime != null) 'cooking_time': d.cookingTime,`), add:

```dart
      'batch_cooking_enabled': d.batchCookingEnabled,
      'batch_cooking_max_portions': d.batchMaxPortions,
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/auth/onboarding_page.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/onboarding_page.dart
git commit -m "feat: send batch_cooking_enabled and batch_cooking_max_portions in onboarding submit"
```

---

## Task 8: `complete-onboarding` Edge Function

**Files:**
- Modify: `supabase/functions/complete-onboarding/index.ts`

Context: The function destructures body fields around lines 31–48, validates around lines 50–67, then upserts `user_health_profile` (Step 3) and updates `user_profile` (Step 7). We need to destructure the new fields and save them in Step 7.

- [ ] **Step 1: Destructure new fields from body**

In the destructuring block (after `cooking_time,` around line 43), add:

```typescript
      batch_cooking_enabled,
      batch_cooking_max_portions,
```

- [ ] **Step 2: Save new fields in Step 7 (user_profile update)**

Locate the Step 7 `user_profile` update (around line 149). The `update({...})` call currently sets `first_name`, `last_name`, `onboarding_done`, `consent_privacy_at`, `consent_cgu_at`. Add:

```typescript
        ...(batch_cooking_enabled !== undefined && { batch_cooking_enabled }),
        ...(batch_cooking_max_portions !== undefined && { batch_cooking_max_portions }),
```

So the full update object becomes:

```typescript
      const { error: profileUpdateError } = await admin
        .from("user_profile")
        .update({
          first_name,
          last_name,
          onboarding_done: true,
          consent_privacy_at,
          consent_cgu_at,
          ...(batch_cooking_enabled !== undefined && { batch_cooking_enabled }),
          ...(batch_cooking_max_portions !== undefined && { batch_cooking_max_portions }),
        })
        .eq("id", user.id);
```

- [ ] **Step 3: Deploy the edge function via Supabase MCP**

Use the Supabase MCP `deploy_edge_function` tool:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `complete-onboarding`
- Read the full updated file content and pass it

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/complete-onboarding/index.ts
git commit -m "feat(edge): save batch_cooking_enabled + batch_cooking_max_portions in complete-onboarding"
```

---

## Task 9: `generate-meal-plan` Edge Function

**Files:**
- Modify: `supabase/functions/generate-meal-plan/index.ts`

Context: After `generate_meal_plan` RPC succeeds (Step 3, around line 60), the function currently always calls `create_batch_sessions`. We add Step 3.5 to check the user's batch preference first.

- [ ] **Step 1: Add Step 3.5 — fetch batch preference and conditionally call `create_batch_sessions`**

Replace the existing `create_batch_sessions` call block (lines 63–74) with:

```typescript
    if (mealPlanId) {
      logger.debug("[STEP 3.5] Fetch batch cooking preference");
      const { data: profileData, error: profileError } = await client
        .from("user_profile")
        .select("batch_cooking_enabled, batch_cooking_max_portions")
        .eq("id", user.id)
        .single();

      if (profileError) {
        logger.warn("[STEP 3.5] Failed to fetch batch preference (non-fatal) | " + profileError.message);
      }

      const batchEnabled = profileData?.batch_cooking_enabled ?? false;
      const maxPortions = profileData?.batch_cooking_max_portions ?? 7;
      logger.debug("[STEP 3.5] batchEnabled: " + batchEnabled + " | maxPortions: " + maxPortions);

      if (batchEnabled) {
        logger.debug("[STEP 4] RPC call | fn: create_batch_sessions | maxPortions: " + maxPortions);
        logRLSCheck(logger, "create_batch_sessions", "RPC", user.id);
        const { error: batchError } = await client.rpc("create_batch_sessions", {
          p_meal_plan_id: mealPlanId,
          p_user_id: user.id,
          p_max_portions: maxPortions,
        });
        logQueryResult(logger, "create_batch_sessions", "RPC", 0, batchError ?? undefined);
        if (batchError) {
          logger.warn("create_batch_sessions failed (non-fatal) | " + batchError.message);
        }
      } else {
        logger.debug("[STEP 4] Skipping create_batch_sessions | batch cooking disabled for user");
      }
    }
```

- [ ] **Step 2: Deploy the edge function via Supabase MCP**

Use the Supabase MCP `deploy_edge_function` tool:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `generate-meal-plan`
- Read the full updated file content and pass it

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/generate-meal-plan/index.ts
git commit -m "feat(edge): check batch_cooking_enabled before create_batch_sessions in generate-meal-plan"
```

---

## Task 10: `PreferencesPage`

**Files:**
- Create: `lib/features/settings/preferences_page.dart`

Context: Follow the `SettingsPage` visual pattern (frosted glass AppBar, `AkeliColors`, `Plus Jakarta Sans` font). The page holds a local `UserPreferencesModel` copy in `_localPrefs` and only writes to the provider on "Enregistrer". Region codes used in `user_cuisine_preference` are strings like `'west_africa'`, `'east_africa'`, etc. — display them the same way as onboarding's `_StepPreferences` region selection.

- [ ] **Step 1: Create the page file**

```dart
// lib/features/settings/preferences_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/user_preferences_provider.dart';
import '../../shared/models/user_preferences.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  UserPreferencesModel? _localPrefs;
  bool _saving = false;
  final _logger = appLogger;

  static const _cookingTimeOptions = [
    ('quick', 'Rapide (< 30 min)', Icons.bolt_rounded),
    ('medium', 'Moyen (30–60 min)', Icons.timer_outlined),
    ('any', 'Peu importe', Icons.all_inclusive_rounded),
  ];

  static const _regionOptions = [
    ('west_africa', 'Afrique de l\'Ouest'),
    ('east_africa', 'Afrique de l\'Est'),
    ('north_africa', 'Afrique du Nord'),
    ('central_africa', 'Afrique Centrale'),
    ('south_africa', 'Afrique du Sud'),
    ('caribbean', 'Caraïbes'),
    ('occidental', 'Occidental'),
  ];

  @override
  Widget build(BuildContext context) {
    _logger.provider('PreferencesPage build()');
    final prefsAsync = ref.watch(userPreferencesProvider);

    return prefsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (prefs) {
        _localPrefs ??= prefs;
        final local = _localPrefs!;

        return Scaffold(
          backgroundColor: AkeliColors.background,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 16),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: AkeliColors.surface.withValues(alpha: 0.8),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: AkeliColors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AkeliColors.onSurfaceVariant,
                          onPressed: () {
                            _logger.userAction('PreferencesPage back tapped',
                                screen: 'PreferencesPage');
                            if (context.canPop()) context.pop();
                          },
                        ),
                      ),
                      const Text(
                        'Préférences',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AkeliColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 32,
              left: 16,
              right: 16,
              bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cuisson ─────────────────────────────────────────────
                _SectionHeader(title: 'CUISSON'),
                const SizedBox(height: 8),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Temps de préparation'),
                      const SizedBox(height: 12),
                      ..._cookingTimeOptions.map((opt) {
                        final (value, label, icon) = opt;
                        return _RadioRow(
                          icon: icon,
                          label: label,
                          selected: local.cookingTime == value,
                          onTap: () {
                            _logger.userAction('Cooking time selected',
                                screen: 'PreferencesPage',
                                metadata: {'value': value});
                            setState(() {
                              _localPrefs = local.copyWith(cookingTime: value);
                            });
                          },
                        );
                      }),
                      const Divider(height: 24),
                      const _Label('Cuisson en batch'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Préparer plusieurs repas à la fois',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AkeliColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cuire en grande quantité pour la semaine',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AkeliColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: local.batchCookingEnabled,
                            activeColor: AkeliColors.primary,
                            onChanged: (v) {
                              _logger.userAction('Batch cooking toggled',
                                  screen: 'PreferencesPage',
                                  metadata: {'enabled': v});
                              setState(() {
                                _localPrefs =
                                    local.copyWith(batchCookingEnabled: v);
                              });
                            },
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: local.batchCookingEnabled
                            ? Padding(
                                key: const ValueKey('portions'),
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Portions max par session',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AkeliColors.onSurface,
                                      ),
                                    ),
                                    DropdownButton<int>(
                                      value: local.batchMaxPortions,
                                      underline: const SizedBox.shrink(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AkeliColors.primary,
                                      ),
                                      items: List.generate(6, (i) => i + 2)
                                          .map((n) => DropdownMenuItem(
                                                value: n,
                                                child: Text('$n'),
                                              ))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v == null) return;
                                        _logger.userAction(
                                            'Batch max portions changed',
                                            screen: 'PreferencesPage',
                                            metadata: {'portions': v});
                                        setState(() {
                                          _localPrefs = local.copyWith(
                                              batchMaxPortions: v);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('hidden')),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Région culinaire ─────────────────────────────────────
                _SectionHeader(title: 'RÉGION CULINAIRE'),
                const SizedBox(height: 8),
                _Card(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _regionOptions.map((opt) {
                      final (code, name) = opt;
                      final selected = local.cuisineRegion == code;
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (_) {
                          _logger.userAction('Region selected',
                              screen: 'PreferencesPage',
                              metadata: {'region': code});
                          setState(() {
                            _localPrefs = selected
                                ? local.copyWith(clearCuisineRegion: true)
                                : local.copyWith(cuisineRegion: code);
                          });
                        },
                        selectedColor:
                            AkeliColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AkeliColors.primary,
                        labelStyle: TextStyle(
                          color: selected
                              ? AkeliColors.primary
                              : AkeliColors.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Restrictions alimentaires ─────────────────────────────
                _SectionHeader(title: 'RESTRICTIONS ALIMENTAIRES'),
                const SizedBox(height: 8),
                _Card(
                  child: Column(
                    children: [
                      _ToggleRow(
                        label: 'Sans porc',
                        icon: Icons.no_meals_rounded,
                        value: local.noPork,
                        onChanged: (v) {
                          _logger.userAction('noPork toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(
                              () => _localPrefs = local.copyWith(noPork: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: 'Sans viande',
                        icon: Icons.grass_rounded,
                        value: local.noMeat,
                        onChanged: (v) {
                          _logger.userAction('noMeat toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(
                              () => _localPrefs = local.copyWith(noMeat: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: 'Sans gluten',
                        icon: Icons.grain_rounded,
                        value: local.noGluten,
                        onChanged: (v) {
                          _logger.userAction('noGluten toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(
                              () => _localPrefs = local.copyWith(noGluten: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: 'Sans lactose',
                        icon: Icons.water_drop_outlined,
                        value: local.noLactose,
                        onChanged: (v) {
                          _logger.userAction('noLactose toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(() =>
                              _localPrefs = local.copyWith(noLactose: v));
                        },
                      ),
                      if (local.allergies.isNotEmpty) ...[
                        const Divider(height: 1, indent: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Allergies',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: local.allergies
                                    .map((a) => Chip(label: Text(a)))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Save button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AkeliColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_localPrefs == null) return;
    _logger.userAction('PreferencesPage save tapped', screen: 'PreferencesPage');
    setState(() => _saving = true);
    try {
      await ref
          .read(userPreferencesProvider.notifier)
          .save(_localPrefs!);
      _localPrefs = null; // reset so next build re-reads from provider
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préférences enregistrées.')),
        );
        context.pop();
      }
    } catch (e) {
      _logger.provider('PreferencesPage save error | $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Private widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AkeliColors.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AkeliColors.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      );
}

class _RadioRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioRow(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? AkeliColors.primary
                      : AkeliColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: selected
                        ? AkeliColors.primary
                        : AkeliColors.onSurface,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AkeliColors.primary, size: 20),
            ],
          ),
        ),
      );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label,
      required this.icon,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AkeliColors.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, color: AkeliColors.onSurface)),
            ),
            Switch(
              value: value,
              activeColor: AkeliColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/settings/preferences_page.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/preferences_page.dart
git commit -m "feat: add PreferencesPage with cooking, region, and dietary sections"
```

---

## Task 11: Router + Settings Page Wiring

**Files:**
- Modify: `lib/core/router.dart`
- Modify: `lib/features/settings/settings_page.dart`

- [ ] **Step 1: Add the route constant to `AkeliRoutes`**

In `lib/core/router.dart`, add to the `AkeliRoutes` class (after `static const referral = "/referral";`):

```dart
  static const preferences = "/preferences";
```

- [ ] **Step 2: Add the `GoRoute` to the router**

In `lib/core/router.dart`, add the import at the top:

```dart
import '../features/settings/preferences_page.dart';
```

Then add the route to the `routes` list (after the `referral` GoRoute):

```dart
      GoRoute(
        path: AkeliRoutes.preferences,
        builder: (context, state) => const PreferencesPage(),
      ),
```

- [ ] **Step 3: Add "Préférences" menu item to `SettingsPage`**

In `lib/features/settings/settings_page.dart`, in the "Menu" `_Section` items list, add after the `_MenuItem` for "Mode Fan":

```dart
                        _MenuItem(
                          icon: Icons.tune_rounded,
                          label: 'Préférences',
                          onTap: () {
                            appLogger.userAction('Preferences menu tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.preferences);
                          },
                        ),
```

- [ ] **Step 4: Verify it compiles**

```bash
flutter analyze lib/core/router.dart lib/features/settings/settings_page.dart
```
Expected: No errors.

- [ ] **Step 5: Full analyze**

```bash
flutter analyze
```
Expected: No errors (warnings about unused imports are acceptable; errors are not).

- [ ] **Step 6: Commit**

```bash
git add lib/core/router.dart lib/features/settings/settings_page.dart
git commit -m "feat: add /preferences route and Préférences menu item in Settings"
```

---

## Self-Review Checklist

**Spec coverage:**
- ✅ DB: `batch_cooking_max_portions` migration (Task 1)
- ✅ DB: `create_batch_sessions` with `p_max_portions` HAVING clause (Task 2)
- ✅ `UserPreferencesModel` with all 9 fields (Task 3)
- ✅ `UserPreferencesNotifier` build (4-table load) + save (4-table write) (Task 4)
- ✅ `OnboardingData` new fields + `updateGoals` (Task 5)
- ✅ Goals step UI: batch toggle + portions dropdown with `AnimatedSwitcher` (Task 6)
- ✅ `_submit()` sends new fields (Task 7)
- ✅ `complete-onboarding` destructures + saves new fields (Task 8)
- ✅ `generate-meal-plan` checks `batch_cooking_enabled`, passes `p_max_portions` (Task 9)
- ✅ `PreferencesPage` with all 3 sections + Save button (Task 10)
- ✅ Route `/preferences` + Settings menu item (Task 11)
