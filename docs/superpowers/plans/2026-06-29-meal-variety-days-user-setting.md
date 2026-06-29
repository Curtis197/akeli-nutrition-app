# Meal Variety Days — User Setting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users choose between no cross-plan recipe exclusion, a 7-day window, or a 15-day window, stored on `user_profile` and read server-side by the meal plan generators.

**Architecture:** A new `meal_variety_days` column (INT, DEFAULT 7, CHECK IN (0,7,15)) is added to `user_profile`. All three generator functions read this value once at startup into `v_variety_days` and use it as the blacklist window length. The Flutter `UserProfile` model gains a `mealVarietyDays` field; `MealSchedulePage` gains a 3-chip selector that saves immediately.

**Tech Stack:** PostgreSQL (plpgsql, pgTAP), Dart/Flutter, Riverpod, Supabase Flutter SDK

## Global Constraints

- All Dart files must import `package:akeli/core/logger.dart` and use `final _logger = appLogger;` (or module-level `appLogger` for free functions)
- Every DB operation must log BEFORE / AFTER / ERROR with structured format
- No hardcoded user-visible strings — all go through `AppLocalizations` via `app_en.arb` + `app_fr.arb`
- `flutter gen-l10n` must be run after every ARB change
- `meal_variety_days` valid values: `0`, `7`, `15` only (CHECK constraint at DB)
- Default is `7` everywhere (DB DEFAULT, Dart field default, COALESCE fallback)
- pgTAP test file: `BEGIN; SELECT plan(N); … SELECT * FROM finish(); ROLLBACK;`
- Generator `v_variety_days = 0` must produce an empty `v_recent_recipe_ids` (impossible date range — no special-case needed)

---

### Task 1: DB Migration + pgTAP Test Updates

**Files:**
- Create: `supabase/migrations/20260629000003_user_profile_meal_variety_days.sql`
- Modify: `supabase/tests/database/generate_meal_plan_variety.test.sql`

**Interfaces:**
- Produces: `user_profile.meal_variety_days` column (INT NOT NULL DEFAULT 7, CHECK IN (0,7,15)) — used by Task 2's generator reads
- Produces: updated pgTAP test file with 6 tests — Test 6 FAILS before Task 2, PASSES after

---

- [ ] **Step 1: Create the DB migration**

Create `supabase/migrations/20260629000003_user_profile_meal_variety_days.sql`:

```sql
-- supabase/migrations/20260629000003_user_profile_meal_variety_days.sql
-- Description: Add meal_variety_days to user_profile.
-- Values: 0 (none), 7 (7-day window, default), 15 (15-day window).
-- Existing rows get DEFAULT 7 automatically.

ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS meal_variety_days INT NOT NULL DEFAULT 7
  CONSTRAINT meal_variety_days_check CHECK (meal_variety_days IN (0, 7, 15));

COMMENT ON COLUMN public.user_profile.meal_variety_days IS
  'Cross-plan recipe blacklist window in days. 0=off, 7=7-day (default), 15=15-day.';
```

- [ ] **Step 2: Update the pgTAP test file — adjust dates and add Test 6**

Open `supabase/tests/database/generate_meal_plan_variety.test.sql`. Make the following changes:

**2a. Change `plan(5)` → `plan(6)` on line 6.**

**2b. Fix Test 1 date (week-2 gap 8 → 5 days, so it is within the new 7-day default window).**

Change line 103-107 from:
```sql
-- Week 2 (1-day plan, 8 days later — within the 15-day window)
SELECT public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 208)::date, 3
);
```
To:
```sql
-- Week 2 (1-day plan, 5 days later — within the 7-day default window)
SELECT public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 205)::date, 3
);
```

Also update the assertion message and date on lines 109-123 from:
```sql
SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe
      ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'eeeeffff-0000-4000-8000-000000000099'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 208)::date
      AND mpec.role          = 'base'
      AND mpec.recipe_id IN (SELECT recipe_id FROM t_variety_w1)
  ),
  '15-day blacklist: plan at day+208 shares no recipe with plan at day+200'
);
```
To:
```sql
SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe
      ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'eeeeffff-0000-4000-8000-000000000099'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 205)::date
      AND mpec.role          = 'base'
      AND mpec.recipe_id IN (SELECT recipe_id FROM t_variety_w1)
  ),
  '7-day blacklist: plan at day+205 shares no recipe with plan at day+200 (gap=5 days)'
);
```

**2c. Fix Test 5 — change day+212 → day+207 (both A at day+200 and B at day+205 must be in 7-day window).**

The window for day+207 = [day+200, day+207): includes day+200 (A) ✓ and day+205 (B) ✓ → pool exhausted.

Change the Test 5 `lives_ok` from:
```sql
-- ─── Test 5: fallback path — pool exhausted, Pass 2 generates without error ──
-- day+212 window = [day+197, day+212): contains day+200 (A) and day+208 (B) → all 6 recipes blacklisted.
SELECT lives_ok(
  $$ SELECT public.generate_meal_plan(
       'eeeeffff-0000-4000-8000-000000000099'::uuid,
       1, 3, (CURRENT_DATE + 212)::date, 3
     ) $$,
  'fallback: when entire pool is blacklisted (day+212, both A+B in window), Pass 2 generates plan successfully'
);
```
To:
```sql
-- ─── Test 5: fallback path — pool exhausted, Pass 2 generates without error ──
-- day+207 window = [day+200, day+207): contains day+200 (A) and day+205 (B) → all 6 recipes blacklisted.
SELECT lives_ok(
  $$ SELECT public.generate_meal_plan(
       'eeeeffff-0000-4000-8000-000000000099'::uuid,
       1, 3, (CURRENT_DATE + 207)::date, 3
     ) $$,
  'fallback: when entire pool is blacklisted (day+207, both A+B in 7-day window), Pass 2 generates plan successfully'
);
```

**2d. Add Test 6 — append before `SELECT * FROM finish();`.**

Test 6 verifies that `meal_variety_days = 0` disables the blacklist entirely. It fails before Task 2 (generator still uses hardcoded 15 → blacklists day+600 recipes at day+603) and passes after (generator reads 0 → empty window → A reused):

```sql
-- ─── Test 6: meal_variety_days = 0 disables cross-plan blacklist ─────────────
-- With variety=0 the window = [p_start_date, p_start_date) which is impossible,
-- so v_recent_recipe_ids is always empty and A recipes are reused each week.
-- BEFORE Task 2 migration: generator ignores the column (hardcoded 15) →
--   day+600 recipes are blacklisted at day+603 → B used → assertion FAILS.
-- AFTER Task 2 migration: reads variety=0 → empty window → A reused → PASSES.

UPDATE public.user_profile
SET meal_variety_days = 0
WHERE id = 'eeeeffff-0000-4000-8000-000000000099'::uuid;

SELECT public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 600)::date, 3
);

CREATE TEMP TABLE t_variety_v0 AS
SELECT DISTINCT mpec.recipe_id
FROM public.meal_plan mp
JOIN public.meal_plan_entry mpe  ON mpe.meal_plan_id = mp.id
JOIN public.meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
WHERE mp.user_id         = 'eeeeffff-0000-4000-8000-000000000099'::uuid
  AND mpe.scheduled_date = (CURRENT_DATE + 600)::date
  AND mpec.role          = 'base';

SELECT public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 603)::date, 3
);

SELECT ok(
  EXISTS(
    SELECT 1
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe  ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'eeeeffff-0000-4000-8000-000000000099'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 603)::date
      AND mpec.role          = 'base'
      AND mpec.recipe_id IN (SELECT recipe_id FROM t_variety_v0)
  ),
  'variety=0: plan at day+603 reuses day+600 recipes — no blacklist when meal_variety_days=0'
);
```

- [ ] **Step 3: Run `supabase db reset` (PowerShell, wait ~60s for healthy)**

```powershell
cd "C:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
supabase db reset
```

Expected: completes without error.

- [ ] **Step 4: Run `supabase test db` and confirm TDD gate**

```powershell
supabase test db
```

Expected output:
```
Files=4, Tests=32, Result: FAIL
```

Test 1 and Test 5 now use different dates but should still PASS (hardcoded 15-day generator covers 5-day and 7-day gaps). Test 6 should FAIL (generator uses hardcoded 15 → blacklists day+600 A recipes at day+603). If other tests fail unexpectedly, investigate before proceeding.

- [ ] **Step 5: Commit**

```powershell
git add supabase/migrations/20260629000003_user_profile_meal_variety_days.sql
git add supabase/tests/database/generate_meal_plan_variety.test.sql
git commit -m "feat(meal-plan): add meal_variety_days column + update pgTAP variety tests for 7-day default"
```

---

### Task 2: Generator Migration — Read `meal_variety_days` from `user_profile`

**Files:**
- Create: `supabase/migrations/20260629000004_generate_meal_plan_variety_days_configurable.sql`

**Interfaces:**
- Consumes: `user_profile.meal_variety_days` column (from Task 1)
- Produces: three rewritten generator functions that read `v_variety_days` instead of hardcoding `15`

---

The source functions are in `supabase/migrations/20260629000002_generate_meal_plan_15day_variety.sql`. Read that file first, then apply **exactly three changes per function**:

1. Add `v_variety_days int := 7;` to the `DECLARE` block
2. Add a SELECT to read `meal_variety_days` from `user_profile` (after the `user_goal` SELECT, before the day loop)
3. Replace `(p_start_date - 15)` with `(p_start_date - v_variety_days)` in the pre-loop blacklist query

- [ ] **Step 1: Create the migration file**

Create `supabase/migrations/20260629000004_generate_meal_plan_variety_days_configurable.sql`.

Start with this header:
```sql
-- supabase/migrations/20260629000004_generate_meal_plan_variety_days_configurable.sql
-- Description: Make the cross-plan recipe blacklist window configurable per user.
-- Reads meal_variety_days from user_profile (0=off, 7=7-day, 15=15-day).
-- Previously hardcoded to 15 in migration 20260629000002.
```

Then copy all three function bodies from `20260629000002` and apply the changes below.

**Change A — DECLARE block (all three functions):**

Add `v_variety_days int := 7;` immediately after `v_recent_recipe_ids uuid[] := ARRAY[]::uuid[];`:

```sql
  v_recent_recipe_ids      uuid[] := ARRAY[]::uuid[];
  v_variety_days           int    := 7;
```

**Change B — New read query (all three functions):**

Add this query after the `user_goal` SELECT and before the `SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id)...` pre-loop query:

```sql
  SELECT COALESCE(meal_variety_days, 7) INTO v_variety_days
  FROM public.user_profile WHERE id = p_user_id;
```

**Change C — Pre-loop blacklist query (all three functions):**

Replace the hardcoded `15` in:
```sql
    AND mpe.scheduled_date >= (p_start_date - 15)
```
with:
```sql
    AND mpe.scheduled_date >= (p_start_date - v_variety_days)
```

**REVOKE/GRANT** — copy the full REVOKE/GRANT block from `20260629000002` verbatim at the bottom of the new file (it covers all three functions including the `GRANT EXECUTE TO authenticated` for `generate_meal_plan`).

The rest of each function body is identical to `20260629000002`.

- [ ] **Step 2: Run `supabase db reset`**

```powershell
supabase db reset
```

Expected: completes without error.

- [ ] **Step 3: Run `supabase test db` — all 6 variety tests must pass**

```powershell
supabase test db
```

Expected:
```
All tests successful.
Files=4, Tests=32, Result: PASS
```

If Test 6 still fails: verify that `v_variety_days` is read from `user_profile` in the no-vector branch of `generate_meal_plan` (both Pass 1 and Pass 2 use the same `v_variety_days` declared at function scope — there is no per-branch read needed). If Test 1 fails: verify the window is `>= (p_start_date - v_variety_days)` not `> (p_start_date - v_variety_days)`.

- [ ] **Step 4: Commit**

```powershell
git add supabase/migrations/20260629000004_generate_meal_plan_variety_days_configurable.sql
git commit -m "feat(meal-plan): read meal_variety_days from user_profile in generators (0/7/15, default 7)"
```

---

### Task 3: Flutter Model + Provider

**Files:**
- Modify: `lib/shared/models/user_profile.dart`
- Modify: `lib/providers/user_profile_provider.dart`

**Interfaces:**
- Produces: `UserProfile.mealVarietyDays` (int, default 7) — used by Task 4's UI
- Produces: `setMealVarietyDaysProvider` — `FutureProvider.autoDispose.family<void, ({String userId, int days})>` — used by Task 4's save handler

---

- [ ] **Step 1: Update `UserProfile` model**

In `lib/shared/models/user_profile.dart`, add `mealVarietyDays` field to the `UserProfile` class:

**Add field** after `hasDismissedMealScheduleHint`:
```dart
  final int mealVarietyDays;  // 0 | 7 | 15
```

**Add to constructor** (with default):
```dart
    this.mealVarietyDays = 7,
```

**Add to `fromJson`** after the `hasDismissedMealScheduleHint` line:
```dart
        mealVarietyDays:
            (json['meal_variety_days'] as int?) ?? 7,
```

**Add to `copyWith` parameter list**:
```dart
    int? mealVarietyDays,
```

**Add to `copyWith` return** inside the `UserProfile(...)` constructor call:
```dart
        mealVarietyDays: mealVarietyDays ?? this.mealVarietyDays,
```

Also add `mealVarietyDays` to the `UserProfile` constructor call inside `copyWith` — the constructor requires it:
```dart
        createdAt: createdAt,
        consentPrivacyAt: consentPrivacyAt,
        consentCguAt: consentCguAt,
        hasDismissedMealScheduleHint:
            hasDismissedMealScheduleHint ?? this.hasDismissedMealScheduleHint,
        mealVarietyDays: mealVarietyDays ?? this.mealVarietyDays,
```

- [ ] **Step 2: Add `setMealVarietyDaysProvider` to `user_profile_provider.dart`**

Append at the end of `lib/providers/user_profile_provider.dart`, following the same pattern as `dismissMealScheduleHintProvider`:

```dart
// ---------------------------------------------------------------------------
// Meal variety days — fire-and-forget update
// ---------------------------------------------------------------------------

final setMealVarietyDaysProvider =
    FutureProvider.autoDispose.family<void, ({String userId, int days})>(
        (ref, args) async {
  appLogger.provider(
      'setMealVarietyDaysProvider | userId: ${LogHelper.maskUuid(args.userId)} | days: ${args.days}');
  final client = ref.watch(supabaseClientProvider);
  appLogger.db(
      'BEFORE | table: user_profile | op: UPDATE meal_variety_days=${args.days} | userId: ${LogHelper.maskUuid(args.userId)}');
  try {
    await client
        .from('user_profile')
        .update({'meal_variety_days': args.days})
        .eq('id', args.userId);
    appLogger.db('AFTER | table: user_profile | op: UPDATE meal_variety_days | success');
    ref.invalidate(userProfileProvider);
  } on PostgrestException catch (e, st) {
    appLogger.db(
        'ERROR | table: user_profile | UPDATE meal_variety_days | ${e.message}',
        error: e,
        stackTrace: st);
    rethrow;
  }
});
```

`LogHelper` is already imported in the file (used in `dismissMealScheduleHintProvider`). If not, add `import '../core/log_helper.dart';` (check existing imports at the top of the file and match them).

- [ ] **Step 3: Verify `flutter analyze` passes**

```powershell
cd "C:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
flutter analyze lib/shared/models/user_profile.dart lib/providers/user_profile_provider.dart
```

Expected: no errors. Fix any type or missing-field errors before proceeding.

- [ ] **Step 4: Commit**

```powershell
git add lib/shared/models/user_profile.dart lib/providers/user_profile_provider.dart
git commit -m "feat(meal-plan): add mealVarietyDays to UserProfile model + setMealVarietyDaysProvider"
```

---

### Task 4: L10n + MealSchedulePage UI

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/features/settings/meal_schedule_page.dart`

**Interfaces:**
- Consumes: `UserProfile.mealVarietyDays` from Task 3
- Consumes: `setMealVarietyDaysProvider` from Task 3
- Produces: chip selector in `MealSchedulePage` that saves immediately on tap

---

- [ ] **Step 1: Add L10n keys to `app_en.arb`**

Insert after `"mealScheduleSavedSuccess"` block (around line 2242):

```json
  "mealScheduleVarietyTitle": "Recipe variety",
  "@mealScheduleVarietyTitle": {},
  "mealScheduleVarietySubtitle": "Avoid repeating recipes used recently",
  "@mealScheduleVarietySubtitle": {},
  "mealScheduleVarietyNone": "None",
  "@mealScheduleVarietyNone": {},
  "mealScheduleVariety7Days": "7 days",
  "@mealScheduleVariety7Days": {},
  "mealScheduleVariety15Days": "15 days",
  "@mealScheduleVariety15Days": {}
```

- [ ] **Step 2: Add L10n keys to `app_fr.arb`**

Find the matching position (after `mealScheduleSavedSuccess`) and add:

```json
  "mealScheduleVarietyTitle": "Variété des recettes",
  "@mealScheduleVarietyTitle": {},
  "mealScheduleVarietySubtitle": "Éviter de répéter les recettes récentes",
  "@mealScheduleVarietySubtitle": {},
  "mealScheduleVarietyNone": "Aucune",
  "@mealScheduleVarietyNone": {},
  "mealScheduleVariety7Days": "7 jours",
  "@mealScheduleVariety7Days": {},
  "mealScheduleVariety15Days": "15 jours",
  "@mealScheduleVariety15Days": {}
```

- [ ] **Step 3: Run `flutter gen-l10n`**

```powershell
flutter gen-l10n
```

Expected: no errors. The new keys become available as `l10n.mealScheduleVarietyTitle` etc.

- [ ] **Step 4: Update `MealSchedulePage`**

In `lib/features/settings/meal_schedule_page.dart`:

**Add imports** at the top (after existing imports):
```dart
import 'package:akeli/providers/user_profile_provider.dart';
```

**Update `build()` method** to also watch `userProfileProvider`:

After `final planAsync = ref.watch(activeNutritionPlanProvider);` add:
```dart
    final profileAsync = ref.watch(userProfileProvider);
    final currentVarietyDays = profileAsync.valueOrNull?.mealVarietyDays ?? 7;
    final profileId = profileAsync.valueOrNull?.id;
```

**Extend the `SingleChildScrollView` Column children** — add the variety section after `MealScheduleWidget`. Replace the existing `children: [...]` block with:

```dart
              children: [
                Text(l10n.mealScheduleSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AkeliColors.onSurfaceVariant)),
                const SizedBox(height: 16),
                MealScheduleWidget(
                  initialDistributions: initialDists,
                  totalCalorieGoal: plan.calorieGoal,
                  onChanged: (dists) => setState(() => _distributions = dists),
                  onSaveEnabled: (v) => setState(() => _isValid = v),
                ),
                const SizedBox(height: 24),
                _VarietySection(
                  current: currentVarietyDays,
                  profileId: profileId,
                ),
              ],
```

**Add the `_VarietySection` widget** as a private class at the bottom of the file (below `_MealSchedulePageState`):

```dart
class _VarietySection extends ConsumerWidget {
  final int current;
  final String? profileId;

  const _VarietySection({required this.current, required this.profileId});

  final _logger = appLogger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final options = [
      (0,  l10n.mealScheduleVarietyNone),
      (7,  l10n.mealScheduleVariety7Days),
      (15, l10n.mealScheduleVariety15Days),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mealScheduleVarietyTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.mealScheduleVarietySubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AkeliColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final (days, label) = opt;
            final selected = current == days;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                if (profileId == null || selected) return;
                _logger.userAction(
                    'MealSchedulePage variety chip tapped',
                    screen: 'MealSchedulePage',
                    metadata: {'days': days.toString()});
                ref.read(setMealVarietyDaysProvider(
                        (userId: profileId!, days: days))
                    .future);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Run `flutter analyze`**

```powershell
flutter analyze lib/features/settings/meal_schedule_page.dart
```

Expected: no errors. Common issues to watch for:
- Missing `ConsumerWidget` import (`flutter_riverpod`) — already imported in the file
- `AkeliColors.onSurfaceVariant` — confirm this color exists in `lib/core/theme.dart`; if not, use `AkeliColors.secondaryText` or the closest available

- [ ] **Step 6: Commit**

```powershell
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb
git add lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart
git add lib/features/settings/meal_schedule_page.dart
git commit -m "feat(meal-plan): meal variety days selector in MealSchedulePage (none / 7d / 15d)"
```
