import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/beauty_log.dart';
import '../shared/models/beauty_plan.dart';
import '../shared/models/recipe.dart';
import 'auth_provider.dart';

final activeBeautyPlanProvider = FutureProvider.autoDispose<BeautyPlan?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: beauty_plan | op: SELECT active plan | user_id: ${user.id}');

  try {
    final planData = await client
        .from('beauty_plan')
        .select('''
          id,
          user_id,
          start_date,
          end_date,
          created_at,
          beauty_plan_slot (
            id,
            plan_id,
            day_number,
            week_number,
            day_of_week,
            routine_category,
            step_stage,
            frequency_tier,
            recipe_id,
            is_completed,
            completed_at,
            recipe (
              id,
              title,
              description,
              cover_image_url,
              mode,
              beauty_type,
              beauty_sub_type,
              prep_time_min,
              cook_time_min,
              total_time_min,
              difficulty
            )
          )
        ''')
        .eq('user_id', user.id)
        .order('start_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (planData == null) {
      appLogger.db('AFTER | table: beauty_plan | rows: 0 | no active beauty plan found');
      return null;
    }

    appLogger.db('AFTER | table: beauty_plan | loaded active beauty plan | id: ${planData['id']}');
    return BeautyPlan.fromJson(planData);
  } catch (e, st) {
    appLogger.db('ERROR | activeBeautyPlanProvider | $e', error: e, stackTrace: st);
    return null;
  }
});

class ToggleBeautySlotNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggleCompletion(String slotId, bool currentStatus) async {
    final client = ref.read(supabaseClientProvider);
    final nextStatus = !currentStatus;

    try {
      await client.from('beauty_plan_slot').update({
        'is_completed': nextStatus,
        'completed_at': nextStatus ? DateTime.now().toIso8601String() : null,
      }).eq('id', slotId);

      ref.invalidate(activeBeautyPlanProvider);
    } catch (e, st) {
      appLogger.db('ERROR | toggleBeautySlotCompletion | $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}

final toggleBeautySlotNotifierProvider =
    AsyncNotifierProvider.autoDispose<ToggleBeautySlotNotifier, void>(
        ToggleBeautySlotNotifier.new);

class GenerateBeautyPlanNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> generatePlan() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final client = ref.read(supabaseClientProvider);

    try {
      await client.rpc('generate_beauty_plan', params: {
        'p_user_id': user.id,
        'p_start_date': DateTime.now().toIso8601String().split('T')[0],
      });
      ref.invalidate(activeBeautyPlanProvider);
    } catch (e, st) {
      appLogger.db('ERROR | generateBeautyPlan | $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}

    final generateBeautyPlanNotifierProvider =
    AsyncNotifierProvider.autoDispose<GenerateBeautyPlanNotifier, void>(
        GenerateBeautyPlanNotifier.new);

final beautyLogsProvider = FutureProvider.autoDispose<List<BeautyLog>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: beauty_log | op: SELECT logs | user_id: ${user.id}');

  try {
    final response = await client
        .from('beauty_log')
        .select()
        .eq('user_id', user.id)
        .order('logged_at', ascending: false);

    final logs = (response as List<dynamic>)
        .map((data) => BeautyLog.fromJson(data as Map<String, dynamic>))
        .toList();

    appLogger.db('AFTER | table: beauty_log | rows: ${logs.length}');
    return logs;
  } catch (e, st) {
    appLogger.db('ERROR | beautyLogsProvider | $e', error: e, stackTrace: st);
    return [];
  }
});

class AddBeautyLogNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addLog({
    required double hairLengthCm,
    required double hairStrengthScore,
    required double hairThicknessScore,
    required String hairSheddingRate,
    required double skinHydrationLevel,
    required double skinClarityScore,
    String? checkinNotes,
    List<String> checkinPhotoUrls = const [],
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final client = ref.read(supabaseClientProvider);
    state = const AsyncValue.loading();

    try {
      await client.from('beauty_log').insert({
        'user_id': user.id,
        'hair_length_cm': hairLengthCm,
        'hair_strength_score': hairStrengthScore,
        'hair_thickness_score': hairThicknessScore,
        'hair_shedding_rate': hairSheddingRate,
        'skin_hydration_level': skinHydrationLevel,
        'skin_clarity_score': skinClarityScore,
        'checkin_notes': checkinNotes,
        'checkin_photo_urls': checkinPhotoUrls,
        'logged_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(beautyLogsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      appLogger.db('ERROR | addBeautyLog | $e', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final addBeautyLogNotifierProvider =
    AsyncNotifierProvider.autoDispose<AddBeautyLogNotifier, void>(
        AddBeautyLogNotifier.new);

