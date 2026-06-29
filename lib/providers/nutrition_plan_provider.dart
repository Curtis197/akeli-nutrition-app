import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/nutrition_plan.dart';
import 'auth_provider.dart';

final _logger = appLogger;

final activeNutritionPlanProvider = FutureProvider<NutritionPlan?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    _logger.provider('activeNutritionPlanProvider build() | null user');
    return null;
  }

  _logger.provider('activeNutritionPlanProvider build() | userId: ${user.id}');
  ref.onDispose(() => _logger.provider('activeNutritionPlanProvider disposed'));

  final client = ref.watch(supabaseClientProvider);

  try {
    _logger.db('BEFORE | table: nutrition_plan | op: SELECT | userId: ${user.id}');
    final response = await client
        .from('nutrition_plan')
        .select('*, distributions:meal_distribution(*)')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();

    _logger.db('AFTER | table: nutrition_plan | rows: ${response == null ? 0 : 1}');

    if (response == null) {
      _logger.rls('Zero rows | table: nutrition_plan | userId: ${user.id} | possible RLS block or no active plan');
      return null;
    }

    return NutritionPlan.fromJson(response);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls('Permission denied | table: nutrition_plan | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      _logger.db('ERROR | table: nutrition_plan | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    return null;
  } catch (e, st) {
    _logger.provider('activeNutritionPlanProvider ERROR | $e', error: e, stackTrace: st);
    return null;
  }
});

class NutritionPlanNotifier extends StateNotifier<AsyncValue<NutritionPlan?>> {
  final Ref ref;
  final _logger = appLogger;

  NutritionPlanNotifier(this.ref) : super(const AsyncValue.loading()) {
    _logger.provider('NutritionPlanNotifier build()');
    _load();
  }

  Future<void> _load() async {
    _logger.provider('NutritionPlanNotifier → loading');
    state = const AsyncValue.loading();
    try {
      final plan = await ref.read(activeNutritionPlanProvider.future);
      _logger.provider('NutritionPlanNotifier → data | plan_exists: ${plan != null}');
      state = AsyncValue.data(plan);
    } catch (e, st) {
      _logger.provider('NutritionPlanNotifier → error | $e', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Single source of truth for persisting a nutrition plan.
  /// Writes nutrition_plan + meal_distribution + user_goal atomically so the
  /// generator (reads meal_distribution) and the swap (reads user_goal) can
  /// never diverge. [goalType] is persisted on user_goal so a profile-driven
  /// recompute keeps the goal_type the health profile screen reads back.
  Future<void> savePlan(NutritionPlan plan, List<MealDistribution> distributions,
      {String? goalType}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _logger.provider('NutritionPlanNotifier savePlan ERROR: No user');
      return;
    }

    final client = ref.read(supabaseClientProvider);
    _logger.provider('NutritionPlanNotifier savePlan | userId: ${user.id} | targetCal: ${plan.calorieGoal} | goalType: $goalType');
    state = const AsyncValue.loading();

    try {
      // 0. Deactivate existing active plans
      _logger.db('BEFORE | table: nutrition_plan | op: UPDATE (deactivate old)');
      await client
          .from('nutrition_plan')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('is_active', true);

      // 1. Save NutritionPlan
      _logger.db('BEFORE | table: nutrition_plan | op: INSERT new active plan');
      final planMap = plan.toJson()..remove('id');
      final planResponse = await client
          .from('nutrition_plan')
          .insert(planMap)
          .select()
          .single();
      
      _logger.db('AFTER | table: nutrition_plan | rows: 1');
      final savedPlanId = planResponse['id'];

      // 2. Save MealDistributions
      final distsToSave = distributions.map((d) {
        final distMap = d.toJson();
        distMap.remove('id');
        distMap.remove('created_at');
        distMap['nutrition_plan_id'] = savedPlanId;
        return distMap;
      }).toList();

      _logger.db('BEFORE | table: meal_distribution | op: INSERT | count: ${distsToSave.length}');
      await client.from('meal_distribution').insert(distsToSave);
      _logger.db('AFTER | table: meal_distribution | inserted');

      // 3. Update user_goal for backwards compatibility
      _logger.db('BEFORE | table: user_goal | op: UPDATE (deactivate old)');
      await client
          .from('user_goal')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('is_active', true);
      _logger.db('AFTER | table: user_goal | old rows deactivated');

      _logger.db('BEFORE | table: user_goal | op: INSERT');
      await client.from('user_goal').insert({
        'user_id': user.id,
        'calorie_goal': plan.calorieGoal,
        'protein_goal': plan.proteinGoalG,
        'carbs_goal': plan.carbGoalG,
        'fat_goal': plan.fatGoalG,
        if (goalType != null) 'goal_type': goalType,
        'is_active': true,
      });
      _logger.db('AFTER | table: user_goal | inserted');

      // Reload
      ref.invalidate(activeNutritionPlanProvider);
      await _load();
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied saving plan | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | table: nutrition_plan | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
      }
      state = AsyncValue.error(e, st);
      rethrow;
    } catch (e, st) {
      _logger.provider('NutritionPlanNotifier savePlan ERROR | $e', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final nutritionPlanNotifierProvider =
    StateNotifierProvider<NutritionPlanNotifier, AsyncValue<NutritionPlan?>>((ref) {
  return NutritionPlanNotifier(ref);
});
