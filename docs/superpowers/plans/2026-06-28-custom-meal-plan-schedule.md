# Custom Meal Plan Schedule — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users define their own daily meal slot structure (which meal types, how many, calorie % per slot, per-slot macro targets, optional nicknames) and have the meal plan generator respect that structure.

**Architecture:** Extend `meal_distribution` with 4 new columns; replace the SQL generator's hardcoded `v_meal_types` array with a per-user JSONB slot array read from `meal_distribution`; add a reusable `MealScheduleWidget` used in `NutritionPlanPage`, a new `MealSchedulePage`, and a `MealPlannerPage` bottom-sheet; add an optional onboarding step.

**Tech Stack:** Flutter 3.x + Riverpod + Supabase (PostgREST, pgTAP for SQL tests, Deno edge functions) + go_router + AppLocalizations (ARB)

## Global Constraints

- Every Dart file MUST import `package:akeli/core/logger.dart` and use `appLogger` / `final _logger = appLogger`
- Every user-visible string MUST come from `AppLocalizations.of(context)` — no hardcoded text
- ARB keys added to BOTH `lib/l10n/app_en.arb` AND `lib/l10n/app_fr.arb` before any Dart reference
- Run `flutter gen-l10n` after every ARB change
- DB migrations go in `supabase/migrations/` with filename `YYYYMMDDHHMMSS_<slug>.sql`
- SQL tests go in `supabase/tests/` and run with `supabase test db`
- Logging standard: BEFORE/AFTER/ERROR for every DB op; ENTRY/EXIT for edge functions; provider lifecycle logs

---

### Task 1: DB Migrations — Add columns + update user_profile

**Files:**
- Create: `supabase/migrations/20260628000001_add_meal_schedule_columns.sql`

**Interfaces:**
- Produces: `meal_distribution.{nickname, protein_pct, carbs_pct, fat_pct}`, `meal_plan_entry.{nickname, sort_order}`, `user_profile.has_dismissed_meal_schedule_hint`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260628000001_add_meal_schedule_columns.sql

-- meal_distribution: per-slot display label + macro targets
ALTER TABLE meal_distribution
  ADD COLUMN IF NOT EXISTS nickname    text,
  ADD COLUMN IF NOT EXISTS protein_pct double precision,
  ADD COLUMN IF NOT EXISTS carbs_pct   double precision,
  ADD COLUMN IF NOT EXISTS fat_pct     double precision;

-- meal_plan_entry: propagated from distribution at generation time
ALTER TABLE meal_plan_entry
  ADD COLUMN IF NOT EXISTS nickname   text,
  ADD COLUMN IF NOT EXISTS sort_order integer;

-- user_profile: hint banner dismissal flag
ALTER TABLE user_profile
  ADD COLUMN IF NOT EXISTS has_dismissed_meal_schedule_hint boolean NOT NULL DEFAULT false;
```

- [ ] **Step 2: Apply locally**

```bash
supabase db push
```

Expected: `Applying migration 20260628000001_add_meal_schedule_columns...` with no errors.

- [ ] **Step 3: Verify columns exist**

```bash
supabase db execute --query "SELECT column_name FROM information_schema.columns WHERE table_name = 'meal_distribution' AND column_name IN ('nickname','protein_pct','carbs_pct','fat_pct');"
```

Expected: 4 rows returned.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260628000001_add_meal_schedule_columns.sql
git commit -m "feat(db): add meal schedule columns to meal_distribution, meal_plan_entry, user_profile"
```

---

### Task 2: L10n Strings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`

**Interfaces:**
- Produces: all `mealSchedule*` and `mealTypeCategory*` keys consumed by Tasks 6, 8, 10, 11

- [ ] **Step 1: Add keys to `app_en.arb`**

Locate the end of the file (before the closing `}`) and add:

```json
  "mealScheduleTitle": "Meal Schedule",
  "@mealScheduleTitle": {},
  "mealScheduleSubtitle": "Define which meals you want each day",
  "@mealScheduleSubtitle": {},
  "mealScheduleAddSlot": "Add a meal slot",
  "@mealScheduleAddSlot": {},
  "mealScheduleSave": "Save schedule",
  "@mealScheduleSave": {},
  "mealScheduleCalorieTotal": "{total}% of daily calories",
  "@mealScheduleCalorieTotal": {
    "placeholders": { "total": { "type": "String" } }
  },
  "mealScheduleCalorieTotalError": "Total must equal 100%",
  "@mealScheduleCalorieTotalError": {},
  "mealScheduleMacroSection": "Macro targets for this slot",
  "@mealScheduleMacroSection": {},
  "mealScheduleMacroError": "Macros must equal 100%",
  "@mealScheduleMacroError": {},
  "mealScheduleNicknamePlaceholder": "Custom label (optional)",
  "@mealScheduleNicknamePlaceholder": {},
  "mealScheduleCategoryLabel": "Meal type",
  "@mealScheduleCategoryLabel": {},
  "mealScheduleApplyDialogTitle": "When to apply?",
  "@mealScheduleApplyDialogTitle": {},
  "mealScheduleApplyFromToday": "Apply from today",
  "@mealScheduleApplyFromToday": {},
  "mealScheduleApplyFromNextWeek": "Apply from next week",
  "@mealScheduleApplyFromNextWeek": {},
  "mealScheduleHintBanner": "Customize your meal schedule anytime — tap the settings icon above",
  "@mealScheduleHintBanner": {},
  "mealScheduleHintDismiss": "Got it",
  "@mealScheduleHintDismiss": {},
  "mealScheduleOnboardingTitle": "Customize your meal schedule",
  "@mealScheduleOnboardingTitle": {},
  "mealScheduleOnboardingSubtitle": "Choose which meals you want each day. You can change this anytime in Settings.",
  "@mealScheduleOnboardingSubtitle": {},
  "mealScheduleOnboardingSkip": "Skip, use default (3 meals)",
  "@mealScheduleOnboardingSkip": {},
  "mealScheduleCustomizeButton": "Customize meal structure",
  "@mealScheduleCustomizeButton": {},
  "mealScheduleDeleteSlotTooltip": "Remove this slot",
  "@mealScheduleDeleteSlotTooltip": {},
  "mealScheduleCaloriePct": "Calorie share",
  "@mealScheduleCaloriePct": {},
  "mealScheduleProteinPct": "Protein %",
  "@mealScheduleProteinPct": {},
  "mealScheduleCarbsPct": "Carbs %",
  "@mealScheduleCarbsPct": {},
  "mealScheduleFatPct": "Fat %",
  "@mealScheduleFatPct": {}
```

- [ ] **Step 2: Add same keys to `app_fr.arb`**

```json
  "mealScheduleTitle": "Planning des repas",
  "@mealScheduleTitle": {},
  "mealScheduleSubtitle": "Définissez les repas que vous souhaitez chaque jour",
  "@mealScheduleSubtitle": {},
  "mealScheduleAddSlot": "Ajouter un repas",
  "@mealScheduleAddSlot": {},
  "mealScheduleSave": "Enregistrer",
  "@mealScheduleSave": {},
  "mealScheduleCalorieTotal": "{total}% des calories journalières",
  "@mealScheduleCalorieTotal": {
    "placeholders": { "total": { "type": "String" } }
  },
  "mealScheduleCalorieTotalError": "Le total doit être égal à 100%",
  "@mealScheduleCalorieTotalError": {},
  "mealScheduleMacroSection": "Objectifs macros pour ce repas",
  "@mealScheduleMacroSection": {},
  "mealScheduleMacroError": "Les macros doivent totaliser 100%",
  "@mealScheduleMacroError": {},
  "mealScheduleNicknamePlaceholder": "Libellé personnalisé (optionnel)",
  "@mealScheduleNicknamePlaceholder": {},
  "mealScheduleCategoryLabel": "Type de repas",
  "@mealScheduleCategoryLabel": {},
  "mealScheduleApplyDialogTitle": "Quand appliquer ?",
  "@mealScheduleApplyDialogTitle": {},
  "mealScheduleApplyFromToday": "Appliquer dès aujourd'hui",
  "@mealScheduleApplyFromToday": {},
  "mealScheduleApplyFromNextWeek": "Appliquer à partir de la semaine prochaine",
  "@mealScheduleApplyFromNextWeek": {},
  "mealScheduleHintBanner": "Personnalisez votre planning repas — appuyez sur l'icône réglages ci-dessus",
  "@mealScheduleHintBanner": {},
  "mealScheduleHintDismiss": "Compris",
  "@mealScheduleHintDismiss": {},
  "mealScheduleOnboardingTitle": "Personnalisez votre planning repas",
  "@mealScheduleOnboardingTitle": {},
  "mealScheduleOnboardingSubtitle": "Choisissez les repas que vous souhaitez chaque jour. Vous pouvez modifier cela à tout moment dans les Réglages.",
  "@mealScheduleOnboardingSubtitle": {},
  "mealScheduleOnboardingSkip": "Passer, utiliser les 3 repas par défaut",
  "@mealScheduleOnboardingSkip": {},
  "mealScheduleCustomizeButton": "Personnaliser la structure des repas",
  "@mealScheduleCustomizeButton": {},
  "mealScheduleDeleteSlotTooltip": "Supprimer ce repas",
  "@mealScheduleDeleteSlotTooltip": {},
  "mealScheduleCaloriePct": "Part calorique",
  "@mealScheduleCaloriePct": {},
  "mealScheduleProteinPct": "% Protéines",
  "@mealScheduleProteinPct": {},
  "mealScheduleCarbsPct": "% Glucides",
  "@mealScheduleCarbsPct": {},
  "mealScheduleFatPct": "% Lipides",
  "@mealScheduleFatPct": {}
```

- [ ] **Step 3: Regenerate**

```bash
flutter gen-l10n
```

Expected: no errors, `lib/l10n/app_localizations.dart` updated.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/l10n/
```

Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb
git commit -m "feat(l10n): add meal schedule strings (en + fr)"
```

---

### Task 3: Flutter Model Layer

**Files:**
- Modify: `lib/shared/models/nutrition_plan.dart`
- Modify: `lib/shared/models/meal_plan.dart`
- Modify: `lib/shared/models/user_profile.dart`

**Interfaces:**
- Produces:
  - `MealDistribution.{nickname, proteinPct, carbsPct, fatPct}` + updated `toJson/fromJson/copyWith`
  - `MealPlanEntry.{nickname, sortOrder}` + `displayLabel(AppLocalizations)`
  - `MealPlan.entriesByDay` sorts by `sortOrder` within each day
  - `UserProfile.hasDismissedMealScheduleHint`

- [ ] **Step 1: Extend `MealDistribution`**

In `lib/shared/models/nutrition_plan.dart`, update the `MealDistribution` class:

```dart
class MealDistribution {
  final String? id;
  final String? nutritionPlanId;
  final String mealType;
  final int sortOrder;
  final double caloriePct;
  final double? calorieTarget;
  final int minPortionG;
  final int maxPortionG;
  // NEW fields
  final String? nickname;
  final double? proteinPct;
  final double? carbsPct;
  final double? fatPct;

  MealDistribution({
    this.id,
    this.nutritionPlanId,
    required this.mealType,
    required this.sortOrder,
    required this.caloriePct,
    this.calorieTarget,
    this.minPortionG = 50,
    this.maxPortionG = 1500,
    this.nickname,
    this.proteinPct,
    this.carbsPct,
    this.fatPct,
  });

  factory MealDistribution.fromJson(Map<String, dynamic> json) {
    return MealDistribution(
      id: json['id'] as String?,
      nutritionPlanId: json['nutrition_plan_id'] as String?,
      mealType: json['meal_type'] as String,
      sortOrder: json['sort_order'] as int,
      caloriePct: (json['calorie_pct'] as num).toDouble(),
      calorieTarget: json['calorie_target'] != null
          ? (json['calorie_target'] as num).toDouble()
          : null,
      minPortionG: (json['min_portion_g'] as int?) ?? 50,
      maxPortionG: (json['max_portion_g'] as int?) ?? 1500,
      nickname: json['nickname'] as String?,
      proteinPct: (json['protein_pct'] as num?)?.toDouble(),
      carbsPct: (json['carbs_pct'] as num?)?.toDouble(),
      fatPct: (json['fat_pct'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (nutritionPlanId != null) 'nutrition_plan_id': nutritionPlanId,
      'meal_type': mealType,
      'sort_order': sortOrder,
      'calorie_pct': caloriePct,
      if (calorieTarget != null) 'calorie_target': calorieTarget,
      'min_portion_g': minPortionG,
      'max_portion_g': maxPortionG,
      if (nickname != null) 'nickname': nickname,
      if (proteinPct != null) 'protein_pct': proteinPct,
      if (carbsPct != null) 'carbs_pct': carbsPct,
      if (fatPct != null) 'fat_pct': fatPct,
    };
  }

  MealDistribution copyWith({
    String? id,
    String? nutritionPlanId,
    String? mealType,
    int? sortOrder,
    double? caloriePct,
    double? calorieTarget,
    int? minPortionG,
    int? maxPortionG,
    String? nickname,
    double? proteinPct,
    double? carbsPct,
    double? fatPct,
  }) {
    return MealDistribution(
      id: id ?? this.id,
      nutritionPlanId: nutritionPlanId ?? this.nutritionPlanId,
      mealType: mealType ?? this.mealType,
      sortOrder: sortOrder ?? this.sortOrder,
      caloriePct: caloriePct ?? this.caloriePct,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      minPortionG: minPortionG ?? this.minPortionG,
      maxPortionG: maxPortionG ?? this.maxPortionG,
      nickname: nickname ?? this.nickname,
      proteinPct: proteinPct ?? this.proteinPct,
      carbsPct: carbsPct ?? this.carbsPct,
      fatPct: fatPct ?? this.fatPct,
    );
  }
}
```

- [ ] **Step 2: Extend `MealPlanEntry` and update `MealPlan.entriesByDay`**

In `lib/shared/models/meal_plan.dart`:

Add two fields to `MealPlanEntry`:

```dart
final String? nickname;
final int? sortOrder;
```

Add them to the constructor, `fromJson`, and add a display helper (add import at top: `import 'package:akeli/core/meal_type_l10n.dart';` — this import is already in the project):

```dart
// In fromJson, inside the factory:
nickname: json['nickname'] as String?,
sortOrder: (json['sort_order'] as num?)?.toInt(),
```

Add display helper method to `MealPlanEntry`:

```dart
// After the existing mealTypeLabel getter:
String displayLabel(AppLocalizations l10n) =>
    (nickname != null && nickname!.isNotEmpty)
        ? nickname!
        : mealTypeLabel(l10n, mealType);
```

Add import at top of `meal_plan.dart`:
```dart
import '../../l10n/app_localizations.dart';
import '../../core/meal_type_l10n.dart';
```

Update `MealPlan.entriesByDay` to sort within each day by `sortOrder`:

```dart
Map<DateTime, List<MealPlanEntry>> get entriesByDay {
  final map = <DateTime, List<MealPlanEntry>>{};
  for (final entry in entries) {
    final day = DateTime(
      entry.scheduledDate.year,
      entry.scheduledDate.month,
      entry.scheduledDate.day,
    );
    map.putIfAbsent(day, () => []).add(entry);
  }
  for (final list in map.values) {
    list.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  }
  return map;
}
```

- [ ] **Step 3: Extend `UserProfile`**

In `lib/shared/models/user_profile.dart`, add field:

```dart
final bool hasDismissedMealScheduleHint;
```

Add to constructor:
```dart
this.hasDismissedMealScheduleHint = false,
```

Add to `fromJson`:
```dart
hasDismissedMealScheduleHint:
    (json['has_dismissed_meal_schedule_hint'] as bool?) ?? false,
```

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/shared/
```

Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/nutrition_plan.dart lib/shared/models/meal_plan.dart lib/shared/models/user_profile.dart
git commit -m "feat(models): extend MealDistribution, MealPlanEntry, UserProfile for meal schedule"
```

---

### Task 4: pgTAP SQL Tests (write first — T1–T15, initially failing)

**Files:**
- Create: `supabase/tests/generate_meal_plan_custom_schedule_test.sql`

**Interfaces:**
- Consumes: `generate_meal_plan`, `meal_distribution`, `nutrition_plan`, `meal_plan`, `meal_plan_entry`
- Produces: verified test cases T1–T15 (failing until Task 5 is done)

- [ ] **Step 1: Create test file**

```sql
-- supabase/tests/generate_meal_plan_custom_schedule_test.sql
BEGIN;
SELECT plan(15);

-- ── Shared seed helpers ──────────────────────────────────────────────────────

-- We test with a fixed test user uuid that must exist in auth.users.
-- In the local Supabase environment, use the seeded test user.
DO $$
BEGIN
  -- Ensure test user exists in auth.users (idempotent)
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES ('00000000-0000-0000-0000-000000000001', 'test@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, role, locale)
  VALUES ('00000000-0000-0000-0000-000000000001', true, false, now(), 'user', 'fr')
  ON CONFLICT (id) DO NOTHING;

  -- Test calorie goal
  INSERT INTO user_goal (user_id, calorie_goal, protein_goal, fat_goal, is_active, created_at)
  VALUES ('00000000-0000-0000-0000-000000000001', 2000, 125, 55, true, now())
  ON CONFLICT DO NOTHING;
END $$;

-- Helper: upsert a nutrition_plan + distributions for the test user
CREATE OR REPLACE FUNCTION _test_setup_plan(p_distributions JSONB[])
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  v_plan_id uuid;
  v_dist JSONB;
  v_idx int := 0;
BEGIN
  -- Deactivate existing
  UPDATE nutrition_plan SET is_active = false
  WHERE user_id = '00000000-0000-0000-0000-000000000001';

  INSERT INTO nutrition_plan (user_id, calorie_goal, protein_goal_g, carb_goal_g, fat_goal_g, is_active)
  VALUES ('00000000-0000-0000-0000-000000000001', 2000, 125, 225, 55, true)
  RETURNING id INTO v_plan_id;

  FOREACH v_dist IN ARRAY p_distributions LOOP
    INSERT INTO meal_distribution (nutrition_plan_id, meal_type, sort_order, calorie_pct,
      calorie_target, nickname, protein_pct, fat_pct, carbs_pct)
    VALUES (
      v_plan_id,
      v_dist->>'meal_type',
      v_idx,
      (v_dist->>'calorie_pct')::double precision,
      (v_dist->>'calorie_target')::double precision,
      v_dist->>'nickname',
      (v_dist->>'protein_pct')::double precision,
      (v_dist->>'fat_pct')::double precision,
      (v_dist->>'carbs_pct')::double precision
    );
    v_idx := v_idx + 1;
  END LOOP;

  RETURN v_plan_id;
END $$;

-- Helper: count entries per day for a generated plan
CREATE OR REPLACE FUNCTION _test_entries_per_day(p_user_id uuid, p_date date)
RETURNS int LANGUAGE sql AS $$
  SELECT count(*)::int FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = p_user_id AND mpe.scheduled_date = p_date;
$$;

-- Helper: get meal_types for a day, sorted
CREATE OR REPLACE FUNCTION _test_meal_types_for_day(p_user_id uuid, p_date date)
RETURNS text[] LANGUAGE sql AS $$
  SELECT array_agg(mpe.meal_type ORDER BY mpe.sort_order)
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = p_user_id AND mpe.scheduled_date = p_date;
$$;

-- Set auth.uid() context for all calls
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001"}';

-- ── T1: Default fallback — no distribution ───────────────────────────────────
UPDATE nutrition_plan SET is_active = false
WHERE user_id = '00000000-0000-0000-0000-000000000001';

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 3, CURRENT_DATE, 3) $$,
  'T1: generates with default 3-meal fallback'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE),
  3,
  'T1: 3 entries generated for today'
);

-- ── T2: Standard 3-meal explicit ─────────────────────────────────────────────
PERFORM _test_setup_plan(ARRAY[
  '{"meal_type":"breakfast","calorie_pct":30,"calorie_target":600}'::JSONB,
  '{"meal_type":"lunch","calorie_pct":35,"calorie_target":700}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":35,"calorie_target":700}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 3, CURRENT_DATE + 1, 3) $$,
  'T2: generates 3-meal plan'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 1),
  3,
  'T2: 3 entries for tomorrow'
);

-- ── T3: No breakfast ─────────────────────────────────────────────────────────
PERFORM _test_setup_plan(ARRAY[
  '{"meal_type":"lunch","calorie_pct":40,"calorie_target":800}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":60,"calorie_target":1200}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 2, CURRENT_DATE + 2, 3) $$,
  'T3: generates no-breakfast plan'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 2),
  2,
  'T3: exactly 2 entries (no breakfast)'
);
SELECT ok(
  NOT ('breakfast' = ANY(_test_meal_types_for_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 2))),
  'T3: no breakfast entry'
);

-- ── T4: 3 collations + lunch + dinner ────────────────────────────────────────
PERFORM _test_setup_plan(ARRAY[
  '{"meal_type":"lunch","calorie_pct":25,"calorie_target":500}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":35,"calorie_target":700}'::JSONB,
  '{"meal_type":"snack","calorie_pct":15,"calorie_target":300,"nickname":"Collation matin"}'::JSONB,
  '{"meal_type":"snack","calorie_pct":15,"calorie_target":300,"nickname":"Collation après-midi"}'::JSONB,
  '{"meal_type":"snack","calorie_pct":10,"calorie_target":200,"nickname":"Collation soir"}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 5, CURRENT_DATE + 3, 3) $$,
  'T4: generates 5-slot plan (lunch+dinner+3 snacks)'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 3),
  5,
  'T4: 5 entries generated'
);

-- ── T5: Heavy dinner, light lunch ────────────────────────────────────────────
PERFORM _test_setup_plan(ARRAY[
  '{"meal_type":"lunch","calorie_pct":20,"calorie_target":400}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":55,"calorie_target":1100}'::JSONB,
  '{"meal_type":"snack","calorie_pct":25,"calorie_target":500}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 3, CURRENT_DATE + 4, 3) $$,
  'T5: heavy dinner plan generates'
);
SELECT is(
  _test_entries_per_day('00000000-0000-0000-0000-000000000001'::uuid, CURRENT_DATE + 4),
  3,
  'T5: 3 entries'
);

-- ── T9: Nickname propagation ──────────────────────────────────────────────────
PERFORM _test_setup_plan(ARRAY[
  '{"meal_type":"snack","calorie_pct":50,"calorie_target":1000,"nickname":"Collation du matin"}'::JSONB,
  '{"meal_type":"snack","calorie_pct":50,"calorie_target":1000,"nickname":"Collation du soir"}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 2, CURRENT_DATE + 5, 3) $$,
  'T9: nickname plan generates'
);
SELECT ok(
  EXISTS(
    SELECT 1 FROM meal_plan_entry mpe
    JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mp.user_id = '00000000-0000-0000-0000-000000000001'
      AND mpe.scheduled_date = CURRENT_DATE + 5
      AND mpe.nickname = 'Collation du matin'
  ),
  'T9: nickname "Collation du matin" propagated to entry'
);

-- ── T11: sort_order preserved ─────────────────────────────────────────────────
PERFORM _test_setup_plan(ARRAY[
  '{"meal_type":"lunch","calorie_pct":40,"calorie_target":800}'::JSONB,
  '{"meal_type":"dinner","calorie_pct":60,"calorie_target":1200}'::JSONB
]);

SELECT lives_ok(
  $$ SELECT generate_meal_plan(
       '00000000-0000-0000-0000-000000000001'::uuid,
       1, 2, CURRENT_DATE + 6, 3) $$,
  'T11: generates with sort_order'
);
SELECT ok(
  (SELECT array_agg(mpe.sort_order ORDER BY mpe.sort_order)
   FROM meal_plan_entry mpe
   JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
   WHERE mp.user_id = '00000000-0000-0000-0000-000000000001'
     AND mpe.scheduled_date = CURRENT_DATE + 6) = ARRAY[0, 1],
  'T11: sort_order 0 and 1 set on entries'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run tests — expect failures**

```bash
supabase test db
```

Expected: multiple failures because `generate_meal_plan` still uses hardcoded `v_meal_types` and doesn't write `nickname`/`sort_order`.

- [ ] **Step 3: Commit**

```bash
git add supabase/tests/generate_meal_plan_custom_schedule_test.sql
git commit -m "test(sql): add pgTAP tests T1-T11 for custom meal schedule generation"
```

---

### Task 5: SQL Generator — Read from Distribution

**Files:**
- Create: `supabase/migrations/20260628000002_generate_meal_plan_read_distribution.sql`

**Interfaces:**
- Consumes: `meal_distribution.{meal_type, sort_order, calorie_target, protein_pct, fat_pct, nickname}`, `nutrition_plan`
- Produces: updated `generate_meal_plan` and `generate_meal_plan_from_saved` that write `meal_plan_entry.{nickname, sort_order}` and read slot structure from user distribution

The migration rewrites the `generate_meal_plan` function. The key changes are:
1. Replace `v_meal_types text[]` and related `IF p_meals_per_day` block with a `v_slots JSONB[]` read from `meal_distribution`
2. Replace `FOREACH v_meal_type IN ARRAY v_meal_types LOOP` with `FOREACH v_slot_rec IN ARRAY v_slots LOOP` that extracts per-slot data
3. Remove the per-loop `SELECT md.calorie_target INTO v_target_meal_cal` (now comes from slot rec)
4. Use per-slot `protein_pct` / `fat_pct` for macro density scoring
5. Add `nickname`, `sort_order` to `meal_plan_entry` INSERT

- [ ] **Step 1: Create the migration**

```sql
-- supabase/migrations/20260628000002_generate_meal_plan_read_distribution.sql

DROP FUNCTION IF EXISTS generate_meal_plan(uuid, integer, integer, date, integer);

CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id            uuid,
  p_days               integer,
  p_meals_per_day      integer,   -- kept for backward compat; ignored when distribution exists
  p_start_date         date,
  p_max_recipe_repeat  integer DEFAULT 3
)
RETURNS TABLE (
  meal_plan_id    uuid,
  entry_id        uuid,
  component_id    uuid,
  scheduled_date  date,
  meal_type       text,
  recipe_id       uuid,
  recipe_title    text,
  cover_image_url text,
  calories        numeric,
  protein_g       numeric,
  score           double precision
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_vector            vector(50);
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_existing_plan_id       uuid;
  -- Replaced: v_meal_types text[]
  v_slots                  JSONB[];
  v_slot_rec               JSONB;
  v_slot_nickname          text;
  v_slot_sort_order        integer;
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_protein_goal           numeric;
  v_fat_goal               numeric;
  v_target_meal_cal        numeric;
  v_target_protein_density numeric;
  v_target_fat_density     numeric;
  v_grams                  integer;
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- ── Read slot structure from user's active distribution ────────────────────
  SELECT array_agg(
    jsonb_build_object(
      'meal_type',      md.meal_type,
      'calorie_target', COALESCE(md.calorie_target, 0),
      'protein_pct',    COALESCE(md.protein_pct, 25.0),
      'fat_pct',        COALESCE(md.fat_pct, 25.0),
      'nickname',       md.nickname,
      'sort_order',     md.sort_order
    ) ORDER BY md.sort_order
  ) INTO v_slots
  FROM meal_distribution md
  JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
  WHERE np.user_id = p_user_id AND np.is_active = true;

  -- Fallback: default 3-meal structure if no distribution is saved
  IF v_slots IS NULL THEN
    v_slots := ARRAY[
      jsonb_build_object('meal_type','breakfast','calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',0),
      jsonb_build_object('meal_type','lunch',    'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',1),
      jsonb_build_object('meal_type','dinner',   'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',2)
    ];
  END IF;

  v_total_slots     := p_days * array_length(v_slots, 1);
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), ARRAY[]::text[]) INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  -- ── Plan reuse ──────────────────────────────────────────────────────────────
  SELECT id INTO v_existing_plan_id
  FROM public.meal_plan
  WHERE user_id    =  p_user_id
    AND start_date <= (p_start_date + (p_days - 1))
    AND end_date   >=  p_start_date
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_existing_plan_id IS NOT NULL THEN
    DELETE FROM meal_plan_entry AS e
    WHERE e.meal_plan_id    = v_existing_plan_id
      AND e.scheduled_date >= CURRENT_DATE;

    UPDATE public.meal_plan
    SET end_date = GREATEST(end_date, p_start_date + (p_days - 1))
    WHERE id = v_existing_plan_id;

    v_plan_id := v_existing_plan_id;
  ELSE
    INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
    VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
    RETURNING id INTO v_plan_id;
  END IF;

  SELECT COALESCE(array_agg(mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_used_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  WHERE mpe.meal_plan_id   = v_plan_id
    AND mpe.scheduled_date < CURRENT_DATE
    AND mpec.role = 'base';

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    IF v_current_date < CURRENT_DATE THEN
      CONTINUE;
    END IF;

    -- ── Iterate over user-defined slots ──────────────────────────────────────
    FOREACH v_slot_rec IN ARRAY v_slots LOOP
      v_meal_type       := v_slot_rec->>'meal_type';
      v_slot_nickname   := v_slot_rec->>'nickname';
      v_slot_sort_order := (v_slot_rec->>'sort_order')::integer;

      -- Per-slot calorie target (fall back to equal split)
      v_target_meal_cal := (v_slot_rec->>'calorie_target')::numeric;
      IF (v_target_meal_cal IS NULL OR v_target_meal_cal = 0)
         AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / array_length(v_slots, 1);
      END IF;

      -- Per-slot macro density targets
      IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_protein_density := (v_slot_rec->>'protein_pct')::numeric;
        v_target_fat_density     := (v_slot_rec->>'fat_pct')::numeric;
      ELSE
        v_target_protein_density := 7.5;
        v_target_fat_density     := 3.3;
      END IF;

      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g,
               r.creator_id,
               (
                 0.50 * (1 - (rv.vector <=> v_user_vector))
                        * CASE WHEN v_fan_creator_id IS NOT NULL
                                    AND r.creator_id = v_fan_creator_id
                               THEN 1.5 ELSE 1.0 END
                 + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                         - v_target_protein_density)
                     / NULLIF(v_target_protein_density, 0.001), 1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001), 1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500
          )
          AND NOT (r.allergen_tags && v_user_allergens)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g,
               r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500
          )
          AND NOT (r.allergen_tags && v_user_allergens)
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.kcal_per_100g > 0 THEN
        v_grams := GREATEST(50, LEAST(1500,
          ROUND(v_target_meal_cal / (v_recipe.kcal_per_100g / 100))::integer));
      ELSE
        v_grams := 300;
      END IF;

      -- Insert entry with nickname + sort_order
      INSERT INTO meal_plan_entry (
        meal_plan_id, scheduled_date, meal_type, servings,
        calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed,
        nickname, sort_order
      )
      VALUES (
        v_plan_id, v_current_date, v_meal_type, v_grams,
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.carbs_per_100g   * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.fat_per_100g     * v_grams / 100)::numeric, 1),
        v_slot_nickname,
        v_slot_sort_order
      )
      RETURNING id INTO v_entry_id;

      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
      SELECT
        v_entry_id,
        ri.ingredient_id,
        COALESCE(i.name_fr, i.name),
        round_to_step(
          ri.quantity * v_grams / NULLIF(v_recipe.total_weight_g, 0),
          COALESCE(
            (SELECT rounding_step FROM ingredient_rounding_rule
             WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
            (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
          )
        ),
        ri.unit
      FROM recipe_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = v_recipe.id
        AND ri.is_optional = false;

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

      RETURN QUERY SELECT
        v_plan_id, v_entry_id, v_component_id,
        v_current_date, v_meal_type,
        v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.kcal_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        NULL::double precision;

    END LOOP; -- slots
  END LOOP; -- days
END;
$$;
```

- [ ] **Step 2: Apply locally and run SQL tests**

```bash
supabase db push
supabase test db
```

Expected: T1, T2, T3, T4, T5, T9, T11 pass.

- [ ] **Step 3: Update `generate_meal_plan_from_saved` with the same slot logic**

Open the most recent `generate_meal_plan_from_saved` definition (find with `grep -r "generate_meal_plan_from_saved" supabase/migrations/ | tail -1`). Create a new migration applying the same changes:
- Replace `v_meal_types text[]` with `v_slots JSONB[]`
- Replace `FOREACH v_meal_type IN ARRAY v_meal_types LOOP` with `FOREACH v_slot_rec IN ARRAY v_slots LOOP`
- Extract per-slot fields from `v_slot_rec`
- Add `nickname`, `sort_order` to the `meal_plan_entry` INSERT

File: `supabase/migrations/20260628000003_generate_meal_plan_from_saved_distribution.sql`

- [ ] **Step 4: Update the edge function — remove `meals_per_day`**

In `supabase/functions/generate-meal-plan/index.ts`, change the body parsing block:

```typescript
// BEFORE:
const {
  start_date = new Date().toISOString().split("T")[0],
  days = 7,
  meals_per_day = 3,
} = body;
logger.debug("[STEP 1] Body parsed", { start_date, days, meals_per_day });
```

```typescript
// AFTER:
const {
  start_date = new Date().toISOString().split("T")[0],
  days = 7,
} = body;
const meals_per_day = 3; // kept for RPC signature compat; SQL reads distribution instead
logger.debug("[STEP 1] Body parsed", { start_date, days });
```

- [ ] **Step 5: Update Flutter `MealPlanGeneratorNotifier.generate()`**

In `lib/providers/meal_plan_provider.dart`, update the `generate()` method signature and edge function call:

```dart
// BEFORE:
Future<void> generate({int? days, int mealsPerDay = 3}) async {
  // ...
  final res = await client.functions.invoke(
    'generate-meal-plan',
    body: {'days': effectiveDays, 'meals_per_day': mealsPerDay, 'start_date': todayStr},
  );

// AFTER:
Future<void> generate({int? days}) async {
  // ...
  final res = await client.functions.invoke(
    'generate-meal-plan',
    body: {'days': effectiveDays, 'start_date': todayStr},
  );
```

Also update the `_logger.userAction` call:
```dart
_logger.userAction('Generate meal plan', metadata: {'days': effectiveDays});
```

And `_logger.edge` call:
```dart
_logger.edge('generate-meal-plan', 'BEFORE | days: $effectiveDays | userId: ${user.id}');
```

- [ ] **Step 6: Update all callers of `generate()`**

Search for all callers:
```bash
grep -rn "generate(" lib/ --include="*.dart" | grep "mealPlanGenerator\|generate(mealsPerDay"
```

In `lib/features/meal_planner/meal_planner_page.dart`, change:
```dart
// BEFORE:
await ref.read(mealPlanGeneratorProvider.notifier).generate();
// AFTER: (no change needed — default param removed, call stays the same)
await ref.read(mealPlanGeneratorProvider.notifier).generate();
```

- [ ] **Step 7: Analyze and test**

```bash
flutter analyze lib/providers/meal_plan_provider.dart
supabase test db
```

Expected: all SQL tests pass, no analyzer issues.

- [ ] **Step 8: Commit**

```bash
git add supabase/migrations/20260628000002_generate_meal_plan_read_distribution.sql
git add supabase/migrations/20260628000003_generate_meal_plan_from_saved_distribution.sql
git add supabase/functions/generate-meal-plan/index.ts
git add lib/providers/meal_plan_provider.dart
git commit -m "feat(backend): generate_meal_plan reads slot structure from meal_distribution"
```

---

### Task 6: MealScheduleWidget + Widget Tests

**Files:**
- Create: `lib/features/nutrition_plan/widgets/meal_schedule_widget.dart`
- Create: `test/features/nutrition_plan/meal_schedule_widget_test.dart`

**Interfaces:**
- Consumes: `MealDistribution` (Task 3), L10n keys `mealSchedule*` (Task 2)
- Produces: `MealScheduleWidget({required List<MealDistribution> initialDistributions, required int totalCalorieGoal, required void Function(List<MealDistribution>) onChanged})`

- [ ] **Step 1: Write failing widget tests**

```dart
// test/features/nutrition_plan/meal_schedule_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: Scaffold(body: child),
    );

MealDistribution _slot(String type, double pct, {String? nickname}) =>
    MealDistribution(mealType: type, sortOrder: 0, caloriePct: pct, nickname: nickname);

void main() {
  group('MealScheduleWidget', () {
    testWidgets('W1: save enabled when calorie % sums to 100', (tester) async {
      bool saveEnabled = false;
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [
          _slot('breakfast', 30),
          _slot('lunch', 35),
          _slot('dinner', 35),
        ],
        totalCalorieGoal: 2000,
        onChanged: (_) {},
        onSaveEnabled: (v) => saveEnabled = v,
      )));
      await tester.pumpAndSettle();
      expect(saveEnabled, isTrue); // W1
    });

    testWidgets('W2: save disabled when calorie % does not sum to 100', (tester) async {
      bool saveEnabled = true;
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [
          _slot('breakfast', 30),
          _slot('lunch', 30), // total = 60%, not 100
        ],
        totalCalorieGoal: 2000,
        onChanged: (_) {},
        onSaveEnabled: (v) => saveEnabled = v,
      )));
      await tester.pumpAndSettle();
      expect(saveEnabled, isFalse); // W2
    });

    testWidgets('W5: add slot increments count', (tester) async {
      final List<MealDistribution> emitted = [];
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [_slot('breakfast', 100)],
        totalCalorieGoal: 2000,
        onChanged: (dists) => emitted.addAll(dists),
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addSlotButton')));
      await tester.pumpAndSettle();

      expect(emitted.last.length, 2); // W5
    });

    testWidgets('W6: remove slot decrements count', (tester) async {
      final List<List<MealDistribution>> emitted = [];
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [
          _slot('breakfast', 50),
          _slot('lunch', 50),
        ],
        totalCalorieGoal: 2000,
        onChanged: (dists) => emitted.add(List.of(dists)),
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteSlot_0')));
      await tester.pumpAndSettle();

      expect(emitted.last.length, 1); // W6
    });

    testWidgets('W7: cannot delete last slot', (tester) async {
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [_slot('breakfast', 100)],
        totalCalorieGoal: 2000,
        onChanged: (_) {},
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('deleteSlot_0')), findsNothing); // W7
    });

    testWidgets('W8: saving with empty nickname succeeds', (tester) async {
      List<MealDistribution>? last;
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [_slot('breakfast', 50), _slot('lunch', 50)],
        totalCalorieGoal: 2000,
        onChanged: (d) => last = d,
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();
      expect(last?.first.nickname, isNull); // W8
    });

    testWidgets('W10: category picker changes mealType', (tester) async {
      List<MealDistribution>? last;
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [_slot('breakfast', 100)],
        totalCalorieGoal: 2000,
        onChanged: (d) => last = d,
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();

      // Open the dropdown for slot 0
      await tester.tap(find.byKey(const Key('categoryDropdown_0')));
      await tester.pumpAndSettle();

      // Select 'dinner'
      await tester.tap(find.byKey(const Key('categoryOption_dinner')).last);
      await tester.pumpAndSettle();

      expect(last?.first.mealType, 'dinner'); // W10
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failures**

```bash
flutter test test/features/nutrition_plan/meal_schedule_widget_test.dart
```

Expected: compile error — `MealScheduleWidget` does not exist yet.

- [ ] **Step 3: Implement `MealScheduleWidget`**

```dart
// lib/features/nutrition_plan/widgets/meal_schedule_widget.dart
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/meal_type_l10n.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

class MealScheduleWidget extends StatefulWidget {
  final List<MealDistribution> initialDistributions;
  final int totalCalorieGoal;
  final void Function(List<MealDistribution> distributions) onChanged;
  final void Function(bool isValid) onSaveEnabled;

  const MealScheduleWidget({
    super.key,
    required this.initialDistributions,
    required this.totalCalorieGoal,
    required this.onChanged,
    required this.onSaveEnabled,
  });

  @override
  State<MealScheduleWidget> createState() => _MealScheduleWidgetState();
}

class _MealScheduleWidgetState extends State<MealScheduleWidget> {
  final _logger = appLogger;
  // Stable per-slot keys so ReorderableListView doesn't lose focus
  late List<(int key, MealDistribution dist)> _slots;
  int _nextKey = 0;
  final Set<int> _expandedMacroIndices = {};

  static const _categories = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  void initState() {
    super.initState();
    _logger.provider('MealScheduleWidget initState | slots: ${widget.initialDistributions.length}');
    _slots = widget.initialDistributions
        .map((d) => (_nextKey++, d))
        .toList();
    _emit();
  }

  double get _totalCaloriePct =>
      _slots.fold(0.0, (s, e) => s + e.$2.caloriePct);

  bool get _isCalorieValid => (_totalCaloriePct - 100).abs() <= 1.0;

  bool _isMacroValid(MealDistribution d) {
    if (d.proteinPct == null) return true; // macros not set — optional
    final total = (d.proteinPct ?? 0) + (d.carbsPct ?? 0) + (d.fatPct ?? 0);
    return (total - 100).abs() <= 1.0;
  }

  void _emit() {
    final dists = _slots
        .asMap()
        .entries
        .map((e) => e.value.$2.copyWith(sortOrder: e.key))
        .toList();
    widget.onChanged(dists);
    widget.onSaveEnabled(_isCalorieValid && dists.every(_isMacroValid));
  }

  void _addSlot() {
    _logger.userAction('MealScheduleWidget add slot');
    setState(() {
      _slots = [..._slots, (_nextKey++, MealDistribution(
        mealType: 'snack',
        sortOrder: _slots.length,
        caloriePct: 0,
      ))];
    });
    _emit();
  }

  void _removeSlot(int index) {
    _logger.userAction('MealScheduleWidget remove slot | index: $index');
    setState(() {
      _slots = List.of(_slots)..removeAt(index);
      _expandedMacroIndices.remove(index);
    });
    _emit();
  }

  void _updateSlot(int index, MealDistribution updated) {
    setState(() {
      final list = List.of(_slots);
      list[index] = (list[index].$1, updated);
      _slots = list;
    });
    _emit();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final list = List.of(_slots);
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      _slots = list;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _logger.provider('MealScheduleWidget build() | slots: ${_slots.length} | calTotal: ${_totalCaloriePct.toStringAsFixed(1)}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mealScheduleCalorieTotal(_totalCaloriePct.toStringAsFixed(0)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (!_isCalorieValid)
                Text(
                  l10n.mealScheduleCalorieTotalError,
                  style: const TextStyle(color: AkeliColors.error, fontSize: 12),
                ),
            ],
          ),
        ),

        // Slot list
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _slots.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final (key, dist) = _slots[index];
            final isMacroExpanded = _expandedMacroIndices.contains(index);
            return _SlotCard(
              key: ValueKey(key),
              index: index,
              distribution: dist,
              totalCalorieGoal: widget.totalCalorieGoal,
              canDelete: _slots.length > 1,
              isMacroExpanded: isMacroExpanded,
              onToggleMacro: () => setState(() {
                if (isMacroExpanded) {
                  _expandedMacroIndices.remove(index);
                } else {
                  _expandedMacroIndices.add(index);
                }
              }),
              onUpdate: (updated) => _updateSlot(index, updated),
              onDelete: () => _removeSlot(index),
            );
          },
        ),

        // Add slot button
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            key: const Key('addSlotButton'),
            onPressed: _addSlot,
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.mealScheduleAddSlot),
            style: OutlinedButton.styleFrom(
              foregroundColor: AkeliColors.primary,
              side: BorderSide(color: AkeliColors.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AkeliRadius.md)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Internal slot card ──────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final int index;
  final MealDistribution distribution;
  final int totalCalorieGoal;
  final bool canDelete;
  final bool isMacroExpanded;
  final VoidCallback onToggleMacro;
  final void Function(MealDistribution) onUpdate;
  final VoidCallback onDelete;

  const _SlotCard({
    super.key,
    required this.index,
    required this.distribution,
    required this.totalCalorieGoal,
    required this.canDelete,
    required this.isMacroExpanded,
    required this.onToggleMacro,
    required this.onUpdate,
    required this.onDelete,
  });

  static const _categories = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kcal = (totalCalorieGoal * distribution.caloriePct / 100).round();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: drag handle + category + delete
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: AkeliColors.outline),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    key: Key('categoryDropdown_$index'),
                    value: distribution.mealType,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: _categories.map((cat) => DropdownMenuItem(
                      key: Key('categoryOption_$cat'),
                      value: cat,
                      child: Text(mealTypeLabel(l10n, cat)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) onUpdate(distribution.copyWith(mealType: val));
                    },
                  ),
                ),
                if (canDelete)
                  IconButton(
                    key: Key('deleteSlot_$index'),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: l10n.mealScheduleDeleteSlotTooltip,
                    color: AkeliColors.error,
                    onPressed: onDelete,
                  ),
              ],
            ),

            // Nickname field
            TextFormField(
              initialValue: distribution.nickname ?? '',
              decoration: InputDecoration(
                hintText: l10n.mealScheduleNicknamePlaceholder,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) => onUpdate(distribution.copyWith(
                nickname: val.trim().isEmpty ? null : val.trim(),
              )),
            ),

            // Calorie % slider
            Row(
              children: [
                Text(l10n.mealScheduleCaloriePct,
                    style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: distribution.caloriePct.clamp(0, 100),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: AkeliColors.primary,
                    onChanged: (val) => onUpdate(distribution.copyWith(
                      caloriePct: val,
                      calorieTarget: totalCalorieGoal * val / 100,
                    )),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${distribution.caloriePct.toStringAsFixed(0)}% · $kcal kcal',
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),

            // Macro section (expandable)
            InkWell(
              onTap: onToggleMacro,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(l10n.mealScheduleMacroSection,
                        style: const TextStyle(fontSize: 12, color: AkeliColors.primary)),
                    const Spacer(),
                    Icon(isMacroExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16, color: AkeliColors.primary),
                  ],
                ),
              ),
            ),
            if (isMacroExpanded) ...[
              _macroSlider(context, l10n.mealScheduleProteinPct,
                  distribution.proteinPct ?? 25.0,
                  (v) => onUpdate(distribution.copyWith(proteinPct: v))),
              _macroSlider(context, l10n.mealScheduleCarbsPct,
                  distribution.carbsPct ?? 50.0,
                  (v) => onUpdate(distribution.copyWith(carbsPct: v))),
              _macroSlider(context, l10n.mealScheduleFatPct,
                  distribution.fatPct ?? 25.0,
                  (v) => onUpdate(distribution.copyWith(fatPct: v))),
              _macroTotalIndicator(context, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _macroSlider(BuildContext context, String label, double value,
      void Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11))),
        Expanded(
          child: Slider(
            value: value.clamp(0, 100),
            min: 0, max: 100, divisions: 100,
            activeColor: AkeliColors.accentAmber,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text('${value.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _macroTotalIndicator(BuildContext context, AppLocalizations l10n) {
    final total = (distribution.proteinPct ?? 25) +
        (distribution.carbsPct ?? 50) +
        (distribution.fatPct ?? 25);
    final isValid = (total - 100).abs() <= 1.0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${total.toStringAsFixed(0)}% ${isValid ? '✓' : '— ${l10n.mealScheduleMacroError}'}',
        style: TextStyle(
          fontSize: 11,
          color: isValid ? AkeliColors.primary : AkeliColors.error,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run widget tests**

```bash
flutter test test/features/nutrition_plan/meal_schedule_widget_test.dart
```

Expected: W1, W2, W5, W6, W7, W8, W10 pass.

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/nutrition_plan/widgets/meal_schedule_widget.dart
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/nutrition_plan/widgets/meal_schedule_widget.dart
git add test/features/nutrition_plan/meal_schedule_widget_test.dart
git commit -m "feat(ui): add MealScheduleWidget with widget tests W1-W10"
```

---

### Task 7: NutritionPlanPage Refactor

**Files:**
- Modify: `lib/features/nutrition_plan/nutrition_plan_page.dart`

**Interfaces:**
- Consumes: `MealScheduleWidget` (Task 6)
- Produces: `NutritionPlanPage` embeds `MealScheduleWidget`; save flow unchanged

- [ ] **Step 1: Replace manual slot methods with `MealScheduleWidget`**

In `lib/features/nutrition_plan/nutrition_plan_page.dart`:

1. Add import:
```dart
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
```

2. Remove the methods `_addMealSlot`, `_removeMealSlot`, `_updateSlotPct`, `_updateSlotBounds` entirely.

3. Add state field for save-enabled tracking:
```dart
bool _isScheduleValid = true;
```

4. In `build()`, locate the section that renders `_distributions` (the loop/list over distributions with add/remove buttons). Replace the entire distributions UI block with:

```dart
MealScheduleWidget(
  initialDistributions: _distributions,
  totalCalorieGoal: _calorieGoal,
  onChanged: (dists) => setState(() => _distributions = dists),
  onSaveEnabled: (valid) => setState(() => _isScheduleValid = valid),
),
```

5. In `savePlan()`, add validation using `_isScheduleValid`:
```dart
if (!_isScheduleValid) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.mealScheduleCalorieTotalError)),
  );
  return false;
}
```
(Place this before the existing `totalDist` validation check.)

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/nutrition_plan/nutrition_plan_page.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/nutrition_plan/nutrition_plan_page.dart
git commit -m "refactor(nutrition-plan): replace manual slot editing with MealScheduleWidget"
```

---

### Task 8: MealSchedulePage + Route + Settings Entry

**Files:**
- Create: `lib/features/settings/meal_schedule_page.dart`
- Modify: `lib/core/router.dart`
- Modify: `lib/features/settings/settings_page.dart`

**Interfaces:**
- Consumes: `MealScheduleWidget` (Task 6), `nutritionPlanNotifierProvider` (Task 3), L10n keys
- Produces: `AkeliRoutes.mealSchedule = '/meal-schedule'`; `MealSchedulePage`

- [ ] **Step 1: Add route constant**

In `lib/core/router.dart`, add to `AkeliRoutes`:
```dart
static const mealSchedule = '/meal-schedule';
```

- [ ] **Step 2: Register route in the router**

Find the `GoRouter` or `router` definition in `router.dart`. Add a `GoRoute`:
```dart
import '../features/settings/meal_schedule_page.dart';
// ...
GoRoute(
  path: AkeliRoutes.mealSchedule,
  builder: (context, state) => const MealSchedulePage(),
),
```

- [ ] **Step 3: Create `MealSchedulePage`**

```dart
// lib/features/settings/meal_schedule_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

class MealSchedulePage extends ConsumerStatefulWidget {
  const MealSchedulePage({super.key});

  @override
  ConsumerState<MealSchedulePage> createState() => _MealSchedulePageState();
}

class _MealSchedulePageState extends ConsumerState<MealSchedulePage> {
  final _logger = appLogger;
  List<MealDistribution>? _distributions;
  bool _isValid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _logger.provider('MealSchedulePage initState');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _logger.provider('MealSchedulePage build()');

    final planAsync = ref.watch(activeNutritionPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: Text(l10n.mealScheduleTitle),
        backgroundColor: AkeliColors.background,
        actions: [
          TextButton(
            onPressed: (_isValid && !_saving) ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.mealScheduleSave),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (plan) {
          if (plan == null) {
            return Center(child: Text(l10n.mealScheduleSubtitle));
          }
          final initialDists = _distributions ??
              (plan.distributions ?? [
                MealDistribution(mealType: 'breakfast', sortOrder: 0, caloriePct: 30, calorieTarget: (plan.calorieGoal * 0.30)),
                MealDistribution(mealType: 'lunch',     sortOrder: 1, caloriePct: 35, calorieTarget: (plan.calorieGoal * 0.35)),
                MealDistribution(mealType: 'dinner',    sortOrder: 2, caloriePct: 35, calorieTarget: (plan.calorieGoal * 0.35)),
              ]);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    _logger.userAction('MealSchedulePage save tapped');
    if (_distributions == null) return;

    setState(() => _saving = true);
    try {
      final plan = ref.read(activeNutritionPlanProvider).valueOrNull;
      if (plan == null) return;

      _logger.provider('MealSchedulePage → saving ${_distributions!.length} distributions');
      await ref.read(nutritionPlanNotifierProvider.notifier)
          .savePlan(plan, _distributions!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).mealScheduleSave)),
        );
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      _logger.provider('MealSchedulePage → save error | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AkeliColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
```

- [ ] **Step 4: Add Settings entry**

In `lib/features/settings/settings_page.dart`, find the list of settings items (look for the section with `HealthProfilePage`, `PreferencesPage`, etc.) and add a new tile:

```dart
_buildSettingsTile(
  context,
  icon: Icons.restaurant_outlined,
  title: l10n.mealScheduleTitle,
  onTap: () {
    appLogger.userAction('Meal schedule settings tapped', screen: 'SettingsPage');
    context.push(AkeliRoutes.mealSchedule);
  },
),
```

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/settings/meal_schedule_page.dart lib/core/router.dart lib/features/settings/settings_page.dart
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/meal_schedule_page.dart lib/core/router.dart lib/features/settings/settings_page.dart
git commit -m "feat(settings): add MealSchedulePage + route + settings entry"
```

---

### Task 9: MealPlannerDayRow — Nickname + Sort Order Display

**Files:**
- Modify: `lib/features/meal_planner/widgets/meal_planner_day_row.dart`

**Interfaces:**
- Consumes: `MealPlanEntry.displayLabel(l10n)` (Task 3), `MealPlan.entriesByDay` sort (Task 3)
- Produces: day rows show nickname or localized type label; entries ordered by `sort_order`

- [ ] **Step 1: Update `AkeliMealCard` title in `_buildMealList`**

In `lib/features/meal_planner/widgets/meal_planner_day_row.dart`, in the `itemBuilder` of `_buildMealList`, change:

```dart
// BEFORE:
title: entry.localizedTitle(locale) ?? '',
```

```dart
// AFTER:
title: entry.localizedTitle(locale) ?? entry.displayLabel(AppLocalizations.of(context)),
```

Also add import at top:
```dart
import 'package:akeli/l10n/app_localizations.dart';
```

(Note: `entry.displayLabel()` is the method added in Task 3. It returns `nickname` if set, otherwise the localized `mealType` label.)

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/meal_planner/widgets/meal_planner_day_row.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/meal_planner/widgets/meal_planner_day_row.dart
git commit -m "feat(meal-planner): show slot nickname in day row, respect sort_order"
```

---

### Task 10: MealPlannerPage — Customize Flow + Hint Banner

**Files:**
- Modify: `lib/features/meal_planner/meal_planner_page.dart`
- Modify: `lib/providers/user_profile_provider.dart`

**Interfaces:**
- Consumes: `MealScheduleWidget`, `mealPlanGeneratorProvider.generate()`, `userProfileProvider`, L10n keys
- Produces: customize icon in header → bottom sheet → confirmation dialog; hint banner dismissed via `user_profile`

- [ ] **Step 1: Add hint dismissal notifier to `user_profile_provider.dart`**

Add at the bottom of `lib/providers/user_profile_provider.dart`:

```dart
// Hint dismissal — fire-and-forget upsert
final dismissMealScheduleHintProvider =
    FutureProvider.autoDispose.family<void, String>((ref, userId) async {
  appLogger.provider('dismissMealScheduleHintProvider | userId: ${LogHelper.maskUuid(userId)}');
  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: user_profile | op: UPDATE has_dismissed_meal_schedule_hint=true | userId: ${LogHelper.maskUuid(userId)}');
  try {
    await client
        .from('user_profile')
        .update({'has_dismissed_meal_schedule_hint': true})
        .eq('id', userId);
    appLogger.db('AFTER | table: user_profile | op: UPDATE | success');
    ref.invalidate(userProfileProvider);
  } on PostgrestException catch (e, st) {
    appLogger.db('ERROR | table: user_profile | UPDATE | ${e.message}', error: e, stackTrace: st);
    rethrow;
  }
});
```

Also add missing import if not present:
```dart
import '../core/logger.dart';
```

- [ ] **Step 2: Add customize button and bottom sheet to `MealPlannerPage`**

In `lib/features/meal_planner/meal_planner_page.dart`, update the `SliverPadding` header to add a customize icon:

```dart
// In the SliverPadding header section, wrap the title Text in a Row:
SliverPadding(
  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
  sliver: SliverToBoxAdapter(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dayKeys.length > 3 ? l10n.mealPlannerWeekTitle : l10n.mealPlannerDaysTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.0,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: l10n.mealScheduleCustomizeButton,
          color: AkeliColors.primary,
          onPressed: () {
            appLogger.userAction('Customize meal structure tapped', screen: 'MealPlannerPage');
            _showCustomizeSheet(context, ref, plan);
          },
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 3: Add hint banner**

Below the quick actions `SliverPadding` section and before the `SliverList`, add:

```dart
// Hint banner — shown once, dismissed by user
Consumer(builder: (context, ref, _) {
  final profileAsync = ref.watch(userProfileProvider);
  final profile = profileAsync.valueOrNull;
  if (profile == null || profile.hasDismissedMealScheduleHint) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
  return SliverToBoxAdapter(
    child: MaterialBanner(
      content: Text(l10n.mealScheduleHintBanner),
      actions: [
        TextButton(
          onPressed: () {
            appLogger.userAction('Meal schedule hint dismissed', screen: 'MealPlannerPage');
            ref.read(dismissMealScheduleHintProvider(profile.id));
          },
          child: Text(l10n.mealScheduleHintDismiss),
        ),
      ],
    ),
  );
}),
```

- [ ] **Step 4: Add `_showCustomizeSheet` method**

Add this private method to `MealPlannerPage`:

```dart
Future<void> _showCustomizeSheet(BuildContext context, WidgetRef ref, MealPlan plan) async {
  final l10n = AppLocalizations.of(context);
  final nutritionPlan = ref.read(activeNutritionPlanProvider).valueOrNull;
  if (nutritionPlan == null) return;

  List<MealDistribution> pending = nutritionPlan.distributions ?? [
    MealDistribution(mealType: 'breakfast', sortOrder: 0, caloriePct: 30, calorieTarget: nutritionPlan.calorieGoal * 0.30),
    MealDistribution(mealType: 'lunch',     sortOrder: 1, caloriePct: 35, calorieTarget: nutritionPlan.calorieGoal * 0.35),
    MealDistribution(mealType: 'dinner',    sortOrder: 2, caloriePct: 35, calorieTarget: nutritionPlan.calorieGoal * 0.35),
  ];
  bool isValid = true;

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AkeliColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AkeliColors.outline,
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.mealScheduleTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MealScheduleWidget(
                    initialDistributions: pending,
                    totalCalorieGoal: nutritionPlan.calorieGoal,
                    onChanged: (dists) => setModalState(() => pending = dists),
                    onSaveEnabled: (v) => setModalState(() => isValid = v),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: ElevatedButton(
                  onPressed: isValid ? () => Navigator.of(ctx).pop(true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AkeliColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.lg)),
                  ),
                  child: Text(l10n.mealScheduleSave),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // Save distributions
  await ref.read(nutritionPlanNotifierProvider.notifier)
      .savePlan(nutritionPlan, pending);

  if (!context.mounted) return;

  // Ask when to apply
  final applyNow = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.mealScheduleApplyDialogTitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.mealScheduleApplyFromNextWeek),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AkeliColors.primary),
          child: Text(l10n.mealScheduleApplyFromToday),
        ),
      ],
    ),
  );

  if (applyNow == true && context.mounted) {
    try {
      await ref.read(mealPlanGeneratorProvider.notifier).generate();
    } catch (e) {
      appLogger.edge('generate-meal-plan', 'ERROR | $e', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).mealPlannerError(e.toString())),
              backgroundColor: AkeliColors.error),
        );
      }
    }
  }
}
```

Also add missing imports to `meal_planner_page.dart`:
```dart
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/providers/user_profile_provider.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';
```

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/meal_planner/meal_planner_page.dart lib/providers/user_profile_provider.dart
```

Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/meal_planner/meal_planner_page.dart lib/providers/user_profile_provider.dart
git commit -m "feat(meal-planner): add customize sheet, apply dialog, hint banner"
```

---

### Task 11: Onboarding — Optional Meal Schedule Step

**Files:**
- Create: `lib/features/auth/widgets/meal_schedule_onboarding_step.dart`
- Modify: `lib/features/auth/onboarding_page.dart`

**Interfaces:**
- Consumes: `MealScheduleWidget`, `nutritionPlanNotifierProvider`
- Produces: optional onboarding step after `NutritionPlanPage` step; skippable

- [ ] **Step 1: Create `MealScheduleOnboardingStep`**

```dart
// lib/features/auth/widgets/meal_schedule_onboarding_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

class MealScheduleOnboardingStep extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;
  final VoidCallback onSkipped;

  const MealScheduleOnboardingStep({
    super.key,
    required this.onCompleted,
    required this.onSkipped,
  });

  @override
  ConsumerState<MealScheduleOnboardingStep> createState() =>
      _MealScheduleOnboardingStepState();
}

class _MealScheduleOnboardingStepState
    extends ConsumerState<MealScheduleOnboardingStep> {
  final _logger = appLogger;
  List<MealDistribution>? _distributions;
  bool _isValid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _logger.provider('MealScheduleOnboardingStep initState');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _logger.provider('MealScheduleOnboardingStep build()');

    final planAsync = ref.watch(activeNutritionPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      body: SafeArea(
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (plan) {
            if (plan == null) {
              // No plan yet — skip silently
              WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSkipped());
              return const SizedBox.shrink();
            }
            final initialDists = _distributions ?? [
              MealDistribution(mealType: 'breakfast', sortOrder: 0, caloriePct: 30, calorieTarget: plan.calorieGoal * 0.30),
              MealDistribution(mealType: 'lunch',     sortOrder: 1, caloriePct: 35, calorieTarget: plan.calorieGoal * 0.35),
              MealDistribution(mealType: 'dinner',    sortOrder: 2, caloriePct: 35, calorieTarget: plan.calorieGoal * 0.35),
            ];

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.mealScheduleOnboardingTitle,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(l10n.mealScheduleOnboardingSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AkeliColors.onSurfaceVariant)),
                        const SizedBox(height: 24),
                        MealScheduleWidget(
                          initialDistributions: initialDists,
                          totalCalorieGoal: plan.calorieGoal,
                          onChanged: (dists) => setState(() => _distributions = dists),
                          onSaveEnabled: (v) => setState(() => _isValid = v),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: (_isValid && !_saving) ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AkeliColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AkeliRadius.lg)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(l10n.mealScheduleSave),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onSkipped,
                        child: Text(l10n.mealScheduleOnboardingSkip,
                            style: const TextStyle(color: AkeliColors.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    _logger.userAction('MealScheduleOnboardingStep save tapped');
    if (_distributions == null) return;
    setState(() => _saving = true);
    try {
      final plan = ref.read(activeNutritionPlanProvider).valueOrNull;
      if (plan == null) {
        widget.onSkipped();
        return;
      }
      await ref.read(nutritionPlanNotifierProvider.notifier)
          .savePlan(plan, _distributions!);
      _logger.provider('MealScheduleOnboardingStep → save success');
      if (mounted) widget.onCompleted();
    } catch (e, st) {
      _logger.provider('MealScheduleOnboardingStep → save error | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AkeliColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
```

- [ ] **Step 2: Integrate into `OnboardingPage`**

In `lib/features/auth/onboarding_page.dart`, find the step list/index system. After the nutrition plan step (the step that renders `NutritionPlanPage`), add `MealScheduleOnboardingStep`:

```dart
import 'package:akeli/features/auth/widgets/meal_schedule_onboarding_step.dart';
```

Locate where steps are advanced (the `onCompleted` callback of the `NutritionPlanPage` onboarding step). After that step completes, instead of going directly to the final step, go to the new meal schedule step:

```dart
// In the step builder, after NutritionPlanPage step:
MealScheduleOnboardingStep(
  onCompleted: _advanceStep,  // or whatever the existing advance-step function is
  onSkipped: _advanceStep,    // both paths advance — skip just doesn't save custom structure
),
```

The exact insertion point depends on the `OnboardingPage` step controller. Look for a `List<Widget>` or `switch (stepIndex)` and insert the new step at the right index.

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/auth/
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/widgets/meal_schedule_onboarding_step.dart lib/features/auth/onboarding_page.dart
git commit -m "feat(onboarding): add optional meal schedule step with skip support"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| `meal_distribution` 4 new columns | Task 1 |
| `meal_plan_entry.nickname + sort_order` | Task 1 |
| `user_profile.has_dismissed_meal_schedule_hint` | Task 1 |
| L10n keys (en + fr) | Task 2 |
| `MealDistribution` model extended | Task 3 |
| `MealPlanEntry.displayLabel`, `entriesByDay` sort | Task 3 |
| `UserProfile.hasDismissedMealScheduleHint` | Task 3 |
| pgTAP SQL tests T1–T11 | Task 4 |
| `generate_meal_plan` reads from distribution | Task 5 |
| `generate_meal_plan_from_saved` same update | Task 5 |
| Edge function drops `meals_per_day` | Task 5 |
| Flutter removes `mealsPerDay` param | Task 5 |
| `MealScheduleWidget` reusable | Task 6 |
| Widget tests W1–W10 | Task 6 |
| `NutritionPlanPage` embeds `MealScheduleWidget` | Task 7 |
| `MealSchedulePage` + route + settings entry | Task 8 |
| Day row shows nickname + sort order | Task 9 |
| Customize flow from `MealPlannerPage` | Task 10 |
| Confirmation dialog apply today/next week | Task 10 |
| Hint banner + dismissal | Task 10 |
| Onboarding optional step + skip | Task 11 |

**Placeholder scan:** No TBDs. All code blocks show actual implementation.

**Type consistency:**
- `MealDistribution.copyWith(mealType:)` used in Task 6 — defined in Task 3 ✓
- `MealPlanEntry.displayLabel(l10n)` used in Task 9 — defined in Task 3 ✓
- `MealScheduleWidget(onSaveEnabled:)` param added in Task 6, used in Tasks 7, 8, 10, 11 ✓
- `generate()` (no `mealsPerDay`) updated in Task 5, called in Task 10 ✓
- `AkeliRoutes.mealSchedule` defined in Task 8 ✓
