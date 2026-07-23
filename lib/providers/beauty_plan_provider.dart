  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../core/logger.dart';
  import '../core/supabase_client.dart';
  import '../shared/models/beauty_log.dart';
  import '../shared/models/beauty_plan.dart';
  import 'auth_provider.dart';

  final activeBeautyPlanProvider = FutureProvider.autoDispose<BeautyPlan?>((ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    appLogger.provider('activeBeautyPlanProvider build() | userId: ${user.id}');
    ref.onDispose(() => appLogger.provider('activeBeautyPlanProvider disposed'));

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
                creator_id,
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
        appLogger.rls('Zero rows | table: beauty_plan | userId: ${user.id} | possible RLS block or no active plan');
        appLogger.provider('activeBeautyPlanProvider → data (null)');
        return null;
      }

      appLogger.db('AFTER | table: beauty_plan | loaded active beauty plan | id: ${planData['id']}');
      final plan = BeautyPlan.fromJson(planData);
      appLogger.provider('activeBeautyPlanProvider → data | planId: ${plan.id} | slots: ${plan.slots.length}');
      return plan;
    } catch (e, st) {
      appLogger.db('ERROR | activeBeautyPlanProvider | $e', error: e, stackTrace: st);
      appLogger.provider('activeBeautyPlanProvider → error | $e');
      return null;
    }
  });

  class ToggleBeautySlotNotifier extends AutoDisposeAsyncNotifier<void> {
    final _logger = appLogger;

    @override
    Future<void> build() async {
      _logger.provider('ToggleBeautySlotNotifier build()');
      ref.onDispose(() => _logger.provider('ToggleBeautySlotNotifier disposed'));
    }

    Future<void> toggleCompletion(String slotId, bool currentStatus) async {
      final client = ref.read(supabaseClientProvider);
      final nextStatus = !currentStatus;

      _logger.db('BEFORE | table: beauty_plan_slot | op: UPDATE is_completed=$nextStatus | slotId: $slotId');
      _logger.provider('ToggleBeautySlotNotifier → loading (toggleCompletion)');

      try {
        await client.from('beauty_plan_slot').update({
          'is_completed': nextStatus,
          'completed_at': nextStatus ? DateTime.now().toIso8601String() : null,
        }).eq('id', slotId);

        _logger.db('AFTER | table: beauty_plan_slot | op: UPDATE | success | slotId: $slotId');
        _logger.provider('ToggleBeautySlotNotifier → data (toggleCompletion success)');
        ref.invalidate(activeBeautyPlanProvider);
      } catch (e, st) {
        _logger.db('ERROR | toggleBeautySlotCompletion | $e', error: e, stackTrace: st);
        _logger.provider('ToggleBeautySlotNotifier → error | $e');
        rethrow;
      }
    }
  }

  final toggleBeautySlotNotifierProvider =
      AsyncNotifierProvider.autoDispose<ToggleBeautySlotNotifier, void>(
          ToggleBeautySlotNotifier.new);

  class GenerateBeautyPlanNotifier extends AutoDisposeAsyncNotifier<void> {
    final _logger = appLogger;

    @override
    Future<void> build() async {
      _logger.provider('GenerateBeautyPlanNotifier build()');
      ref.onDispose(() => _logger.provider('GenerateBeautyPlanNotifier disposed'));
    }

    Future<void> generatePlan() async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final client = ref.read(supabaseClientProvider);
      final startDate = DateTime.now().toIso8601String().split('T')[0];

      _logger.db('BEFORE rpc | fn: generate_beauty_plan | userId: ${user.id} | startDate: $startDate');
      _logger.provider('GenerateBeautyPlanNotifier → loading (generatePlan)');

      try {
        await client.rpc('generate_beauty_plan', params: {
          'p_user_id': user.id,
          'p_start_date': startDate,
        });
        _logger.db('AFTER rpc | fn: generate_beauty_plan | success | userId: ${user.id}');
        _logger.provider('GenerateBeautyPlanNotifier → data (generatePlan success)');
        ref.invalidate(activeBeautyPlanProvider);
      } catch (e, st) {
        _logger.db('ERROR rpc | fn: generate_beauty_plan | $e', error: e, stackTrace: st);
        _logger.provider('GenerateBeautyPlanNotifier → error | $e');
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

    appLogger.provider('beautyLogsProvider build() | userId: ${user.id}');
    ref.onDispose(() => appLogger.provider('beautyLogsProvider disposed'));

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
      if (logs.isEmpty) {
        appLogger.rls('Zero rows | table: beauty_log | userId: ${user.id} | possible RLS block or no logs yet');
      }
      appLogger.provider('beautyLogsProvider → data | logs: ${logs.length}');
      return logs;
    } catch (e, st) {
      appLogger.db('ERROR | beautyLogsProvider | $e', error: e, stackTrace: st);
      appLogger.provider('beautyLogsProvider → error | $e');
      return [];
    }
  });

  class AddBeautyLogNotifier extends AutoDisposeAsyncNotifier<void> {
    final _logger = appLogger;

    @override
    Future<void> build() async {
      _logger.provider('AddBeautyLogNotifier build()');
      ref.onDispose(() => _logger.provider('AddBeautyLogNotifier disposed'));
    }

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
      _logger.provider('AddBeautyLogNotifier → loading (addLog)');
      _logger.db('BEFORE | table: beauty_log | op: INSERT | userId: ${user.id}');

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

        _logger.db('AFTER | table: beauty_log | op: INSERT | success | userId: ${user.id}');
        _logger.provider('AddBeautyLogNotifier → data (addLog success)');
        ref.invalidate(beautyLogsProvider);
        state = const AsyncValue.data(null);
      } catch (e, st) {
        _logger.db('ERROR | addBeautyLog | $e', error: e, stackTrace: st);
        _logger.provider('AddBeautyLogNotifier → error | $e');
        state = AsyncValue.error(e, st);
        rethrow;
      }
    }
  }

  final addBeautyLogNotifierProvider =
      AsyncNotifierProvider.autoDispose<AddBeautyLogNotifier, void>(
          AddBeautyLogNotifier.new);
  