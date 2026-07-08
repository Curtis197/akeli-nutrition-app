// lib/providers/health_profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import '../core/supabase_client.dart';
import '../core/nutrition_calculator.dart';
import '../features/settings/models/health_profile_model.dart';
import '../shared/models/nutrition_plan.dart';
import '../providers/auth_provider.dart';
import '../providers/nutrition_plan_provider.dart';
import '../providers/nutrition_targets_provider.dart';

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
              'sex, birth_date, height_cm, weight_kg, target_weight_kg, activity_level, weight_goal, muscle_goal, starting_weight_kg, target_date')
          .eq('user_id', user.id)
          .maybeSingle();

      final goalFuture = client
          .from('user_goal')
          .select('goal_type')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
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

    _logger.userAction('HealthProfileNotifier save',
        screen: 'HealthProfilePage',
        metadata: {
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
        if (updated.targetDate != null)
          'target_date':
              updated.targetDate!.toIso8601String().split('T').first,
      }, onConflict: 'user_id');
      _logger
          .db('AFTER | table: user_health_profile | op: UPSERT | rows: 1');

      // 2. Recompute the full target set from the updated profile.
      final age = updated.age;
      NutritionTargetsResult? targets;
      if (age != null && updated.weightKg != null && updated.heightCm != null && updated.goalType != null) {
        targets = await fetchNutritionTargets(
          client,
          weightKg: updated.weightKg!,
          heightCm: updated.heightCm!,
          age: age,
          sex: updated.sex ?? 'male',
          activityLevel: updated.activityLevel ?? 'sedentary',
          primaryGoal: updated.goalType!,
          targetWeightKg: updated.targetWeightKg,
          remainingWeeks: remainingWeeksFromDate(updated.targetDate),
          muscleGoal: updated.muscleGoal,
        );
      }

      if (targets == null) {
        // Missing weight/height/age/goal — cannot recompute. Refresh the plan
        // provider and stop; there is nothing consistent to persist.
        _logger.provider(
            'HealthProfileNotifier save | incomplete profile — skipping plan recompute');
        ref.invalidate(activeNutritionPlanProvider);
        _logger.provider('HealthProfileNotifier → save success (no recompute)');
        state = AsyncData(updated);
        return;
      }

      // 3. Preserve the user's existing meal-split structure and rescale each
      //    slot's calorie_target to the NEW calorie goal. Fall back to the
      //    default 3-meal split when no plan exists yet.
      final existing = await ref.read(activeNutritionPlanProvider.future);
      final splitSource = (existing?.distributions != null &&
              existing!.distributions!.isNotEmpty)
          ? existing.distributions!
          : _defaultMealSplits();

      final distributions = splitSource
          .map((d) => MealDistribution(
                mealType: d.mealType,
                sortOrder: d.sortOrder,
                caloriePct: d.caloriePct,
                calorieTarget: double.parse(
                    (targets!.calorieGoal * d.caloriePct / 100)
                        .toStringAsFixed(1)),
              ))
          .toList();

      // 4. Persist nutrition_plan + meal_distribution + user_goal through the
      //    single shared writer so the generator and swap read one consistent
      //    target. Replaces the old bare `ref.invalidate`, which only re-read
      //    the stale plan and left meal_distribution behind (calorie drift).
      final plan = NutritionPlan(
        userId: user.id,
        calorieGoal: targets.calorieGoal,
        proteinGoalG: targets.proteinG,
        carbGoalG: targets.carbG,
        fatGoalG: targets.fatG,
        bmr: targets.bmr,
        tdee: targets.tdee,
        isActive: true,
      );

      _logger.provider(
          'HealthProfileNotifier save → recompute plan via savePlan | cal: ${targets.calorieGoal} | goalType: ${updated.goalType}');
      await ref
          .read(nutritionPlanNotifierProvider.notifier)
          .savePlan(plan, distributions, goalType: updated.goalType);

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

  /// Default 3-meal split (breakfast/lunch/dinner) used when the user has no
  /// existing meal_distribution to preserve. calorie_target is filled in by the
  /// caller once the new calorie goal is known.
  List<MealDistribution> _defaultMealSplits() {
    final splits = NutritionCalculatorService.getDefaultMealSplits(3);
    var order = 0;
    return splits.entries
        .map((e) => MealDistribution(
              mealType: e.key,
              sortOrder: order++,
              caloriePct: e.value,
            ))
        .toList();
  }
}

final healthProfileProvider = AsyncNotifierProvider.autoDispose<
    HealthProfileNotifier,
    HealthProfileModel>(HealthProfileNotifier.new);
