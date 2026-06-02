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
  final calcActivity =
      activityLevelForCalculator(model.activityLevel ?? 'sedentary');
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

      if (health == null) {
        _logger.rls(
            'Zero rows | table: user_health_profile | userId: ${user.id} | possible RLS block');
      }

      _logger.provider(
          'HealthProfileNotifier → data | userId: ${user.id}');

      return HealthProfileModel.fromJson(health: health, goal: goal);
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
          'birth_date':
              updated.birthDate!.toIso8601String().split('T').first,
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
      _logger
          .db('AFTER | table: user_health_profile | op: UPSERT | rows: 1');

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
        _logger.db(
            'ERROR | HealthProfileNotifier save | code: ${e.code}',
            error: e,
            stackTrace: st);
      }
      _logger.provider('HealthProfileNotifier → error (save)');
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      _logger.db(
          'ERROR | HealthProfileNotifier save | unexpected: $e',
          error: e,
          stackTrace: st);
      _logger.provider('HealthProfileNotifier → error (save unexpected)');
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final healthProfileProvider = AsyncNotifierProvider.autoDispose<
    HealthProfileNotifier,
    HealthProfileModel>(HealthProfileNotifier.new);
