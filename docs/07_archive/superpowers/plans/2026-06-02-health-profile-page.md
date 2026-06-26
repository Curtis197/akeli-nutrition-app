# Health Profile & Goals Page — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a "Santé & Objectifs" settings page that lets users update their health biometrics and nutritional goal, auto-recomputing calorie/macro targets on save.

**Architecture:** Single scrollable `ConsumerStatefulWidget` with local state, two card sections (health params + goal), one save button. A new `HealthProfileNotifier` reads from `user_health_profile` + `user_goal` and writes back with computed targets. Shared private widgets are extracted from `preferences_page.dart` into a shared file first.

**Tech Stack:** Flutter 3, Riverpod (AutoDisposeAsyncNotifier), Supabase (postgrest), GoRouter, `NutritionCalculatorService` (lib/core/nutrition_calculator.dart), mocktail for tests.

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `lib/features/settings/widgets/settings_widgets.dart` | Shared UI primitives: `SettingsSectionHeader`, `SettingsCard`, `SettingsLabel`, `SettingsRadioRow` |
| Modify | `lib/features/settings/preferences_page.dart` | Replace inlined private widgets with imports from `settings_widgets.dart` |
| Create | `lib/features/settings/models/health_profile_model.dart` | Immutable model for health + goal data |
| Create | `lib/providers/health_profile_provider.dart` | `HealthProfileNotifier` — fetch, compute, save |
| Create | `lib/features/settings/health_profile_page.dart` | The full page UI |
| Modify | `lib/core/router.dart` | Add `healthProfile` route constant + `GoRoute` |
| Modify | `lib/features/settings/settings_page.dart` | Add "Santé & Objectifs" menu item |
| Create | `test/features/settings/health_profile_model_test.dart` | Unit tests for model `copyWith` |
| Create | `test/providers/health_profile_provider_test.dart` | Unit tests for provider build + save logic |

---

## Task 1: Extract shared settings widgets

**Files:**
- Create: `lib/features/settings/widgets/settings_widgets.dart`
- Modify: `lib/features/settings/preferences_page.dart`

- [ ] **Step 1: Create `settings_widgets.dart` with the four shared widgets**

```dart
// lib/features/settings/widgets/settings_widgets.dart

import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  const SettingsSectionHeader({super.key, required this.title});

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

class SettingsCard extends StatelessWidget {
  final Widget child;
  const SettingsCard({super.key, required this.child});

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

class SettingsLabel extends StatelessWidget {
  final String text;
  const SettingsLabel(this.text, {super.key});

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

class SettingsRadioRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SettingsRadioRow({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
```

- [ ] **Step 2: Update `preferences_page.dart` to use the shared widgets**

Replace the four private widget class definitions at the bottom of `preferences_page.dart` (the `_SectionHeader`, `_Card`, `_Label`, `_RadioRow` classes) with an import, and rename their usages at the call sites.

Add this import near the top of the file (after existing imports):
```dart
import 'widgets/settings_widgets.dart';
```

Then do a rename pass in the file body:
- `_SectionHeader(` → `SettingsSectionHeader(`
- `_Card(` → `SettingsCard(`
- `_Label(` → `SettingsLabel(`
- `_RadioRow(` → `SettingsRadioRow(`

Then delete the four private class definitions (`_SectionHeader`, `_Card`, `_Label`, `_RadioRow`) from the bottom of `preferences_page.dart`.

- [ ] **Step 3: Verify the app still compiles**

```
flutter analyze lib/features/settings/preferences_page.dart lib/features/settings/widgets/settings_widgets.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```
git add lib/features/settings/widgets/settings_widgets.dart lib/features/settings/preferences_page.dart
git commit -m "refactor(settings): extract shared widgets to settings_widgets.dart"
```

---

## Task 2: Create `HealthProfileModel`

**Files:**
- Create: `lib/features/settings/models/health_profile_model.dart`
- Create: `test/features/settings/health_profile_model_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/settings/health_profile_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/settings/models/health_profile_model.dart';

void main() {
  group('HealthProfileModel', () {
    const base = HealthProfileModel(
      sex: 'male',
      heightCm: 175.0,
      weightKg: 75.0,
      targetWeightKg: 70.0,
      activityLevel: 'moderate',
      weightGoal: 'loss',
      muscleGoal: 'maintenance',
      startingWeightKg: 80.0,
      targetTimeWeeks: 12,
      goalType: 'weight_loss',
    );

    test('copyWith replaces provided fields', () {
      final updated = base.copyWith(weightKg: 74.0, goalType: 'maintenance');
      expect(updated.weightKg, 74.0);
      expect(updated.goalType, 'maintenance');
      expect(updated.sex, 'male'); // unchanged
      expect(updated.heightCm, 175.0); // unchanged
    });

    test('copyWith clearBirthDate removes birthDate', () {
      final withDate = base.copyWith(birthDate: DateTime(1990, 5, 15));
      expect(withDate.birthDate, isNotNull);
      final cleared = withDate.copyWith(clearBirthDate: true);
      expect(cleared.birthDate, isNull);
    });

    test('default constructor produces empty model', () {
      const empty = HealthProfileModel();
      expect(empty.sex, isNull);
      expect(empty.weightKg, isNull);
      expect(empty.goalType, isNull);
    });

    test('age returns correct value when birthDate set', () {
      final model = base.copyWith(
        birthDate: DateTime(DateTime.now().year - 30, 1, 1),
      );
      expect(model.age, 30);
    });

    test('age returns null when birthDate is null', () {
      expect(base.age, isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```
flutter test test/features/settings/health_profile_model_test.dart
```

Expected: compilation error — `HealthProfileModel` not found.

- [ ] **Step 3: Implement `HealthProfileModel`**

```dart
// lib/features/settings/models/health_profile_model.dart

class HealthProfileModel {
  final String? sex;
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String? activityLevel;
  final String? weightGoal;
  final String? muscleGoal;
  final double? startingWeightKg;
  final int? targetTimeWeeks;
  final String? goalType;

  const HealthProfileModel({
    this.sex,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.weightGoal,
    this.muscleGoal,
    this.startingWeightKg,
    this.targetTimeWeeks,
    this.goalType,
  });

  int? get age {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int years = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  HealthProfileModel copyWith({
    String? sex,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? activityLevel,
    String? weightGoal,
    String? muscleGoal,
    double? startingWeightKg,
    int? targetTimeWeeks,
    String? goalType,
    bool clearBirthDate = false,
    bool clearSex = false,
    bool clearActivityLevel = false,
    bool clearWeightGoal = false,
    bool clearMuscleGoal = false,
    bool clearGoalType = false,
  }) {
    return HealthProfileModel(
      sex: clearSex ? null : (sex ?? this.sex),
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: clearActivityLevel ? null : (activityLevel ?? this.activityLevel),
      weightGoal: clearWeightGoal ? null : (weightGoal ?? this.weightGoal),
      muscleGoal: clearMuscleGoal ? null : (muscleGoal ?? this.muscleGoal),
      startingWeightKg: startingWeightKg ?? this.startingWeightKg,
      targetTimeWeeks: targetTimeWeeks ?? this.targetTimeWeeks,
      goalType: clearGoalType ? null : (goalType ?? this.goalType),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/features/settings/health_profile_model_test.dart
```

Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```
git add lib/features/settings/models/health_profile_model.dart test/features/settings/health_profile_model_test.dart
git commit -m "feat(health-profile): add HealthProfileModel with copyWith and age getter"
```

---

## Task 3: Create `HealthProfileProvider`

**Files:**
- Create: `lib/providers/health_profile_provider.dart`
- Create: `test/providers/health_profile_provider_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/providers/health_profile_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/settings/models/health_profile_model.dart';
import 'package:akeli/providers/health_profile_provider.dart';

void main() {
  group('activityLevelForCalculator', () {
    test('maps sedentary correctly', () {
      expect(activityLevelForCalculator('sedentary'), 'sedentary');
    });

    test('maps light correctly', () {
      expect(activityLevelForCalculator('light'), 'lightly_active');
    });

    test('maps moderate correctly', () {
      expect(activityLevelForCalculator('moderate'), 'moderately_active');
    });

    test('maps active correctly', () {
      expect(activityLevelForCalculator('active'), 'very_active');
    });

    test('maps very_active correctly', () {
      expect(activityLevelForCalculator('very_active'), 'extremely_active');
    });

    test('unknown value returns sedentary fallback', () {
      expect(activityLevelForCalculator('unknown'), 'sedentary');
    });
  });

  group('computeCalorieGoal', () {
    test('returns null when age is null', () {
      const model = HealthProfileModel(
        weightKg: 70,
        heightCm: 170,
        sex: 'male',
        activityLevel: 'moderate',
        goalType: 'maintenance',
      );
      expect(computeCalorieGoal(model), isNull);
    });

    test('returns null when weightKg is null', () {
      final model = HealthProfileModel(
        birthDate: DateTime(1990, 1, 1),
        heightCm: 170,
        sex: 'male',
        activityLevel: 'moderate',
        goalType: 'maintenance',
      );
      expect(computeCalorieGoal(model), isNull);
    });

    test('returns null when heightCm is null', () {
      final model = HealthProfileModel(
        birthDate: DateTime(1990, 1, 1),
        weightKg: 70,
        sex: 'male',
        activityLevel: 'moderate',
        goalType: 'maintenance',
      );
      expect(computeCalorieGoal(model), isNull);
    });

    test('returns a positive integer for complete data', () {
      final model = HealthProfileModel(
        birthDate: DateTime(1990, 1, 1),
        weightKg: 70,
        heightCm: 170,
        sex: 'male',
        activityLevel: 'moderate',
        goalType: 'maintenance',
      );
      final result = computeCalorieGoal(model);
      expect(result, isNotNull);
      expect(result, greaterThan(0));
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```
flutter test test/providers/health_profile_provider_test.dart
```

Expected: compilation error — symbols not found.

- [ ] **Step 3: Implement `health_profile_provider.dart`**

```dart
// lib/providers/health_profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import '../core/supabase_client.dart';
import '../core/nutrition_calculator.dart';
import '../features/settings/models/health_profile_model.dart';
import '../providers/auth_provider.dart';
import '../providers/nutrition_plan_provider.dart';

// Pure function — exported for testing
String activityLevelForCalculator(String dbValue) {
  switch (dbValue) {
    case 'sedentary':
      return 'sedentary';
    case 'light':
      return 'lightly_active';
    case 'moderate':
      return 'moderately_active';
    case 'active':
      return 'very_active';
    case 'very_active':
      return 'extremely_active';
    default:
      return 'sedentary';
  }
}

// Pure function — exported for testing
int? computeCalorieGoal(HealthProfileModel model) {
  final age = model.age;
  if (age == null || model.weightKg == null || model.heightCm == null) {
    return null;
  }
  final sex = model.sex ?? 'male';
  final bmr = NutritionCalculatorService.calculateBMR(
    weightKg: model.weightKg!,
    heightCm: model.heightCm!,
    age: age,
    sex: sex,
  );
  final calcActivity = activityLevelForCalculator(model.activityLevel ?? 'sedentary');
  final tdee = NutritionCalculatorService.calculateTDEE(bmr, calcActivity);
  final goalType = model.goalType ?? 'maintenance';
  return NutritionCalculatorService.calculateCalorieGoal(tdee, goalType);
}

class HealthProfileNotifier
    extends AutoDisposeAsyncNotifier<HealthProfileModel> {
  final _logger = appLogger;

  @override
  Future<HealthProfileModel> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const HealthProfileModel();

    _logger.provider('HealthProfileNotifier build() | userId: ${user.id}');
    ref.onDispose(() => _logger.provider('HealthProfileNotifier disposed'));

    final client = ref.watch(supabaseClientProvider);

    _logger.db(
        'BEFORE | tables: user_health_profile,user_goal | op: SELECT | userId: ${user.id}');

    try {
      final healthFuture = client
          .from('user_health_profile')
          .select(
              'sex, birth_date, height_cm, weight_kg, target_weight_kg, activity_level, weight_goal, muscle_goal, starting_weight_kg, target_time_weeks')
          .eq('user_id', user.id)
          .maybeSingle();

      final goalFuture = client
          .from('user_goal')
          .select('goal_type')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      final results = await Future.wait<dynamic>([healthFuture, goalFuture]);

      final health = results[0] as Map<String, dynamic>?;
      final goal = results[1] as Map<String, dynamic>?;

      _logger.db(
          'AFTER | tables: user_health_profile,user_goal | userId: ${user.id}');

      if (health == null) _logger.rls('Zero rows | table: user_health_profile | userId: ${user.id} | possible RLS block');

      return HealthProfileModel(
        sex: health?['sex'] as String?,
        birthDate: health?['birth_date'] != null
            ? DateTime.tryParse(health!['birth_date'] as String)
            : null,
        heightCm: (health?['height_cm'] as num?)?.toDouble(),
        weightKg: (health?['weight_kg'] as num?)?.toDouble(),
        targetWeightKg: (health?['target_weight_kg'] as num?)?.toDouble(),
        activityLevel: health?['activity_level'] as String?,
        weightGoal: health?['weight_goal'] as String?,
        muscleGoal: health?['muscle_goal'] as String?,
        startingWeightKg: (health?['starting_weight_kg'] as num?)?.toDouble(),
        targetTimeWeeks: health?['target_time_weeks'] as int?,
        goalType: goal?['goal_type'] as String?,
      );
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls(
            'Permission denied | HealthProfileNotifier | userId: ${user.id}',
            error: e,
            stackTrace: st);
      } else {
        _logger.db('ERROR | HealthProfileNotifier | code: ${e.code}',
            error: e, stackTrace: st);
      }
      _logger.provider('HealthProfileNotifier → error | ${e.message}');
      rethrow;
    }
  }

  Future<void> save(HealthProfileModel updated) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('HealthProfileNotifier save', metadata: {
      'goalType': updated.goalType,
      'activityLevel': updated.activityLevel,
    });

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();

    try {
      // 1. Upsert user_health_profile
      _logger.db(
          'BEFORE | table: user_health_profile | op: UPSERT | userId: ${user.id}');
      await client.from('user_health_profile').upsert({
        'user_id': user.id,
        if (updated.sex != null) 'sex': updated.sex,
        if (updated.birthDate != null)
          'birth_date': updated.birthDate!.toIso8601String().split('T').first,
        if (updated.heightCm != null) 'height_cm': updated.heightCm,
        if (updated.weightKg != null) 'weight_kg': updated.weightKg,
        if (updated.targetWeightKg != null)
          'target_weight_kg': updated.targetWeightKg,
        if (updated.activityLevel != null)
          'activity_level': updated.activityLevel,
        if (updated.weightGoal != null) 'weight_goal': updated.weightGoal,
        if (updated.muscleGoal != null) 'muscle_goal': updated.muscleGoal,
        if (updated.startingWeightKg != null)
          'starting_weight_kg': updated.startingWeightKg,
        if (updated.targetTimeWeeks != null)
          'target_time_weeks': updated.targetTimeWeeks,
      }, onConflict: 'user_id');
      _logger.db(
          'AFTER | table: user_health_profile | op: UPSERT | rows: 1');

      // 2. Compute calorie/macro targets
      final calorieGoal = computeCalorieGoal(updated);
      double? proteinGoal;
      double? fatGoal;
      if (calorieGoal != null && updated.goalType != null) {
        final macros =
            NutritionCalculatorService.getDefaultMacros(updated.goalType!);
        proteinGoal = NutritionCalculatorService.calculateMacroGrams(
            calorieGoal, macros['protein']!, 'protein');
        fatGoal = NutritionCalculatorService.calculateMacroGrams(
            calorieGoal, macros['fat']!, 'fat');
      }

      // 3. Delete existing user_goal rows
      _logger.db(
          'BEFORE | table: user_goal | op: DELETE | userId: ${user.id}');
      await client.from('user_goal').delete().eq('user_id', user.id);
      _logger.db('AFTER | table: user_goal | op: DELETE');

      // 4. Insert new active user_goal
      if (updated.goalType != null) {
        _logger.db(
            'BEFORE | table: user_goal | op: INSERT | userId: ${user.id}');
        await client.from('user_goal').insert({
          'user_id': user.id,
          'goal_type': updated.goalType,
          'is_active': true,
          if (calorieGoal != null) 'calorie_goal': calorieGoal,
          if (proteinGoal != null) 'protein_goal': proteinGoal,
          if (fatGoal != null) 'fat_goal': fatGoal,
        });
        _logger.db('AFTER | table: user_goal | op: INSERT | rows: 1');
      }

      // 5. Invalidate nutrition plan so it picks up new targets
      ref.invalidate(activeNutritionPlanProvider);

      _logger.provider('HealthProfileNotifier → save success');
      state = AsyncData(updated);
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls(
            'Permission denied | HealthProfileNotifier save | userId: ${user.id}',
            error: e,
            stackTrace: st);
      } else {
        _logger.db('ERROR | HealthProfileNotifier save | code: ${e.code}',
            error: e, stackTrace: st);
      }
      _logger.provider('HealthProfileNotifier → error (save)');
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | HealthProfileNotifier save | unexpected: $e',
          error: e, stackTrace: st);
      _logger.provider('HealthProfileNotifier → error (save unexpected)');
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final healthProfileProvider = AsyncNotifierProvider.autoDispose<
    HealthProfileNotifier,
    HealthProfileModel>(HealthProfileNotifier.new);
```

- [ ] **Step 4: Run tests — expect pass**

```
flutter test test/providers/health_profile_provider_test.dart
```

Expected: All 8 tests pass.

- [ ] **Step 5: Analyze**

```
flutter analyze lib/providers/health_profile_provider.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```
git add lib/providers/health_profile_provider.dart test/providers/health_profile_provider_test.dart
git commit -m "feat(health-profile): add HealthProfileProvider with TDEE auto-compute"
```

---

## Task 4: Create `HealthProfilePage`

**Files:**
- Create: `lib/features/settings/health_profile_page.dart`

- [ ] **Step 1: Create the page file**

```dart
// lib/features/settings/health_profile_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/health_profile_provider.dart';
import '../settings/models/health_profile_model.dart';
import 'widgets/settings_widgets.dart';

class HealthProfilePage extends ConsumerStatefulWidget {
  const HealthProfilePage({super.key});

  @override
  ConsumerState<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends ConsumerState<HealthProfilePage> {
  HealthProfileModel? _local;
  bool _saving = false;
  final _logger = appLogger;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  static const _activityOptions = [
    ('sedentary', 'Sédentaire', Icons.weekend_outlined),
    ('light', 'Légèrement actif', Icons.directions_walk_rounded),
    ('moderate', 'Modérément actif', Icons.directions_bike_outlined),
    ('active', 'Actif', Icons.fitness_center_rounded),
    ('very_active', 'Très actif', Icons.bolt_rounded),
  ];

  static const _goalTypeOptions = [
    ('weight_loss', 'Perte de poids'),
    ('muscle_gain', 'Prise de muscle'),
    ('maintenance', 'Maintien'),
    ('health', 'Santé'),
    ('performance', 'Performance'),
  ];

  static const _weightGoalOptions = [
    ('loss', 'Perdre'),
    ('maintenance', 'Maintenir'),
    ('gain', 'Prendre'),
  ];

  static const _muscleGoalOptions = [
    ('loss', 'Perdre'),
    ('maintenance', 'Maintenir'),
    ('gain', 'Prendre'),
  ];

  static const _sexOptions = [
    ('male', 'Homme'),
    ('female', 'Femme'),
    ('other', 'Autre'),
  ];

  @override
  void dispose() {
    _logger.provider('HealthProfilePage disposed');
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  void _initControllers(HealthProfileModel prefs) {
    if (_heightCtrl.text.isEmpty && prefs.heightCm != null) {
      _heightCtrl.text = prefs.heightCm!.toStringAsFixed(1);
    }
    if (_weightCtrl.text.isEmpty && prefs.weightKg != null) {
      _weightCtrl.text = prefs.weightKg!.toStringAsFixed(1);
    }
    if (_targetWeightCtrl.text.isEmpty && prefs.targetWeightKg != null) {
      _targetWeightCtrl.text = prefs.targetWeightKg!.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('HealthProfilePage build()');
    final profileAsync = ref.watch(healthProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (prefs) {
        if (_local == null) {
          _local = prefs;
          _initControllers(prefs);
        }
        final local = _local!;

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
                            _logger.userAction('HealthProfilePage back tapped',
                                screen: 'HealthProfilePage');
                            if (context.canPop()) context.pop();
                          },
                        ),
                      ),
                      const Text(
                        'Santé & Objectifs',
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
                // ── Paramètres de santé ──────────────────────────────────
                const SettingsSectionHeader(title: 'PARAMÈTRES DE SANTÉ'),
                const SizedBox(height: 8),
                SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sexe
                      const SettingsLabel('Sexe'),
                      const SizedBox(height: 12),
                      _ChipSelector(
                        options: _sexOptions,
                        selected: local.sex,
                        onSelected: (v) {
                          _logger.userAction('Sex selected',
                              screen: 'HealthProfilePage',
                              metadata: {'value': v});
                          setState(() => _local = local.copyWith(sex: v));
                        },
                        onCleared: () {
                          _logger.userAction('Sex cleared',
                              screen: 'HealthProfilePage');
                          setState(() => _local = local.copyWith(clearSex: true));
                        },
                      ),

                      const Divider(height: 24),

                      // Date de naissance
                      const SettingsLabel('Date de naissance'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          _logger.userAction('Birth date tapped',
                              screen: 'HealthProfilePage');
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: local.birthDate ?? DateTime(1990, 1, 1),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            _logger.userAction('Birth date picked',
                                screen: 'HealthProfilePage',
                                metadata: {'date': picked.toIso8601String()});
                            setState(() =>
                                _local = local.copyWith(birthDate: picked));
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 20,
                                  color: AkeliColors.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  local.birthDate != null
                                      ? DateFormat('d MMMM yyyy', 'fr')
                                          .format(local.birthDate!)
                                      : 'Non renseignée',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: local.birthDate != null
                                        ? AkeliColors.onSurface
                                        : AkeliColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AkeliColors.outline, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 24),

                      // Taille
                      const SettingsLabel('Taille'),
                      const SizedBox(height: 8),
                      _NumericField(
                        controller: _heightCtrl,
                        suffix: 'cm',
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() =>
                                _local = local.copyWith(heightCm: parsed));
                          }
                        },
                      ),

                      const Divider(height: 24),

                      // Poids actuel
                      const SettingsLabel('Poids actuel'),
                      const SizedBox(height: 8),
                      _NumericField(
                        controller: _weightCtrl,
                        suffix: 'kg',
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() =>
                                _local = local.copyWith(weightKg: parsed));
                          }
                        },
                      ),

                      const Divider(height: 24),

                      // Poids cible
                      const SettingsLabel('Poids cible'),
                      const SizedBox(height: 8),
                      _NumericField(
                        controller: _targetWeightCtrl,
                        suffix: 'kg',
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() =>
                                _local = local.copyWith(targetWeightKg: parsed));
                          }
                        },
                      ),

                      const Divider(height: 24),

                      // Niveau d'activité
                      const SettingsLabel("Niveau d'activité"),
                      const SizedBox(height: 12),
                      ..._activityOptions.map((opt) {
                        final (value, label, icon) = opt;
                        return SettingsRadioRow(
                          icon: icon,
                          label: label,
                          selected: local.activityLevel == value,
                          onTap: () {
                            _logger.userAction('Activity level selected',
                                screen: 'HealthProfilePage',
                                metadata: {'value': value});
                            setState(() => _local =
                                local.copyWith(activityLevel: value));
                          },
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Objectif ─────────────────────────────────────────────
                const SettingsSectionHeader(title: 'OBJECTIF'),
                const SizedBox(height: 8),
                SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type d'objectif
                      const SettingsLabel("Type d'objectif"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _goalTypeOptions.map((opt) {
                          final (code, name) = opt;
                          final selected = local.goalType == code;
                          return FilterChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (_) {
                              _logger.userAction('Goal type selected',
                                  screen: 'HealthProfilePage',
                                  metadata: {'goalType': code});
                              setState(() => selected
                                  ? _local =
                                      local.copyWith(clearGoalType: true)
                                  : _local = local.copyWith(goalType: code));
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

                      const Divider(height: 24),

                      // Objectif poids
                      const SettingsLabel('Objectif poids'),
                      const SizedBox(height: 12),
                      _ChipSelector(
                        options: _weightGoalOptions,
                        selected: local.weightGoal,
                        onSelected: (v) {
                          _logger.userAction('Weight goal selected',
                              screen: 'HealthProfilePage',
                              metadata: {'value': v});
                          setState(() => _local = local.copyWith(weightGoal: v));
                        },
                        onCleared: () {
                          setState(() =>
                              _local = local.copyWith(clearWeightGoal: true));
                        },
                      ),

                      const Divider(height: 24),

                      // Objectif muscle
                      const SettingsLabel('Objectif muscle'),
                      const SizedBox(height: 12),
                      _ChipSelector(
                        options: _muscleGoalOptions,
                        selected: local.muscleGoal,
                        onSelected: (v) {
                          _logger.userAction('Muscle goal selected',
                              screen: 'HealthProfilePage',
                              metadata: {'value': v});
                          setState(() => _local = local.copyWith(muscleGoal: v));
                        },
                        onCleared: () {
                          setState(() =>
                              _local = local.copyWith(clearMuscleGoal: true));
                        },
                      ),

                      const Divider(height: 24),

                      // Durée cible
                      const SettingsLabel('Durée cible'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: (local.targetTimeWeeks ?? 12).toDouble(),
                              min: 4,
                              max: 52,
                              divisions: 48,
                              activeColor: AkeliColors.primary,
                              label:
                                  '${local.targetTimeWeeks ?? 12} semaines',
                              onChanged: (v) {
                                setState(() => _local = local.copyWith(
                                    targetTimeWeeks: v.round()));
                              },
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              '${local.targetTimeWeeks ?? 12} sem.',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
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
    if (_local == null) return;
    _logger.userAction('HealthProfilePage save tapped',
        screen: 'HealthProfilePage');
    setState(() => _saving = true);
    try {
      await ref.read(healthProfileProvider.notifier).save(_local!);
      _local = null;
      if (mounted) {
        final kcal = computeCalorieGoal(_local ?? const HealthProfileModel());
        final msg = kcal != null
            ? 'Profil mis à jour · $kcal kcal/jour'
            : 'Profil mis à jour';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        context.pop();
      }
    } catch (e, st) {
      _logger.provider('HealthProfilePage save error | $e',
          error: e, stackTrace: st);
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

// ── Private widgets ──────────────────────────────────────────────────────────

class _ChipSelector extends StatelessWidget {
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onCleared;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (code, name) = opt;
        final isSelected = selected == code;
        return ChoiceChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (_) => isSelected ? onCleared() : onSelected(code),
          selectedColor: AkeliColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AkeliColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AkeliColors.primary : AkeliColors.onSurface,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _NumericField({
    required this.controller,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: AkeliColors.onSurfaceVariant,
          fontSize: 15,
        ),
        filled: true,
        fillColor: AkeliColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AkeliColors.onSurface,
      ),
      onChanged: onChanged,
    );
  }
}
```

- [ ] **Step 2: Note on `intl` package**

The page uses `DateFormat('d MMMM yyyy', 'fr')` from the `intl` package. Check that it's already a dependency:

```
grep "intl:" pubspec.yaml
```

If not listed, add it to `pubspec.yaml` under `dependencies` and run `flutter pub get`. If it is already there, no action needed.

- [ ] **Step 3: Analyze**

```
flutter analyze lib/features/settings/health_profile_page.dart
```

Expected: no errors.

- [ ] **Step 4: Fix the snackbar message — `_local` is reset before reading**

In `_save()`, the snackbar reads `_local` after it was set to null. Fix by capturing the model before the call:

The `_save()` method sets `_local = null` after save succeeds. To build the snackbar message, capture it beforehand:

```dart
Future<void> _save() async {
    if (_local == null) return;
    _logger.userAction('HealthProfilePage save tapped',
        screen: 'HealthProfilePage');
    final saved = _local!;   // capture before reset
    setState(() => _saving = true);
    try {
      await ref.read(healthProfileProvider.notifier).save(saved);
      _local = null;
      if (mounted) {
        final kcal = computeCalorieGoal(saved);
        final msg = kcal != null
            ? 'Profil mis à jour · $kcal kcal/jour'
            : 'Profil mis à jour';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        context.pop();
      }
    } catch (e, st) {
      _logger.provider('HealthProfilePage save error | $e',
          error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
```

Apply this corrected `_save()` in place of the one in Step 1.

- [ ] **Step 5: Commit**

```
git add lib/features/settings/health_profile_page.dart
git commit -m "feat(health-profile): add HealthProfilePage UI"
```

---

## Task 5: Wire routing and settings menu entry

**Files:**
- Modify: `lib/core/router.dart`
- Modify: `lib/features/settings/settings_page.dart`

- [ ] **Step 1: Add route constant to `AkeliRoutes` in `router.dart`**

In `lib/core/router.dart`, inside the `AkeliRoutes` abstract class, add after `static const preferences = "/preferences";`:

```dart
static const healthProfile = '/health-profile';
```

- [ ] **Step 2: Add import for `HealthProfilePage` in `router.dart`**

Add to the imports block of `router.dart`:

```dart
import '../features/settings/health_profile_page.dart';
```

- [ ] **Step 3: Register the GoRoute in `router.dart`**

In the `routes` list inside `routerProvider`, add after the preferences route (search for the `preferences` `GoRoute`):

```dart
GoRoute(
  path: AkeliRoutes.healthProfile,
  builder: (context, state) => const HealthProfilePage(),
),
```

- [ ] **Step 4: Add menu item to `settings_page.dart`**

In `lib/features/settings/settings_page.dart`, inside the `_Section(title: 'Menu', items: [...])` list, add after the `_MenuItem` for 'Préférences':

```dart
_MenuItem(
  icon: Icons.monitor_heart_outlined,
  label: 'Santé & Objectifs',
  onTap: () {
    appLogger.userAction('Health profile menu tapped', screen: 'SettingsPage');
    context.push(AkeliRoutes.healthProfile);
  },
),
```

- [ ] **Step 5: Analyze all modified files**

```
flutter analyze lib/core/router.dart lib/features/settings/settings_page.dart
```

Expected: no errors.

- [ ] **Step 6: Run all tests**

```
flutter test
```

Expected: all tests pass (no regressions).

- [ ] **Step 7: Commit**

```
git add lib/core/router.dart lib/features/settings/settings_page.dart
git commit -m "feat(health-profile): wire route and settings menu entry"
```

---

## Self-Review Checklist

- [x] **Spec §1 (HealthProfileModel)** — Task 2 covers all 11 fields + `age` getter + `copyWith` with `clearBirthDate`
- [x] **Spec §2 (HealthProfileProvider)** — Task 3: `build()` parallel queries, `save()` upsert + delete/insert + `invalidate(activeNutritionPlanProvider)`, activity level mapping exported as `activityLevelForCalculator`
- [x] **Spec §3 (Page)** — Task 4: all sections, all fields, frosted glass AppBar, `_ChipSelector`, `_NumericField`, save button
- [x] **Spec §4 (Shared widgets)** — Task 1: extracted to `settings_widgets.dart`, `preferences_page.dart` updated
- [x] **Spec §5 (Save flow)** — Task 4 Step 4: captures `saved` before `_local` reset; snackbar with kcal
- [x] **Spec §6 (Routing)** — Task 5: route constant + `GoRoute` + settings menu item
- [x] **Spec §8 (Logging)** — All provider lifecycle, DB ops, and user actions logged per CLAUDE.md
- [x] **Provider name** — uses `activeNutritionPlanProvider` (actual name in codebase), not `nutritionPlanProvider`
- [x] **No placeholders** — all code is complete and explicit
