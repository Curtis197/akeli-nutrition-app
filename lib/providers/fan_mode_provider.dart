import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/logger.dart';
import '../shared/models/creator.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// My fan subscription
// ---------------------------------------------------------------------------

final myFanSubscriptionProvider =
    FutureProvider.autoDispose<FanSubscription?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  appLogger.provider('myFanSubscriptionProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('myFanSubscriptionProvider disposed'));
  appLogger.db('BEFORE | table: fan_subscription | op: SELECT | userId: ${user.id}');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('fan_subscription')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    appLogger.db('AFTER | table: fan_subscription | rows: ${data == null ? 0 : 1} | userId: ${user.id}');
    if (data == null) {
      appLogger.rls('Zero rows | table: fan_subscription | userId: ${user.id} | no subscription or RLS block');
      appLogger.provider('myFanSubscriptionProvider → data (null)');
      return null;
    }
    appLogger.provider('myFanSubscriptionProvider → data | userId: ${user.id}');
    return FanSubscription.fromJson(data);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: fan_subscription | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: fan_subscription | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('myFanSubscriptionProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: fan_subscription | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('myFanSubscriptionProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Fan-eligible creators (all creators — no is_fan_eligible column in DB)
// ---------------------------------------------------------------------------

final fanEligibleCreatorsProvider =
    FutureProvider.autoDispose<List<Creator>>((ref) async {
  appLogger.provider('fanEligibleCreatorsProvider build()');
  ref.onDispose(() => appLogger.provider('fanEligibleCreatorsProvider disposed'));
  ref.watch(currentUserProvider);

  appLogger.db('BEFORE | table: creator | op: SELECT all');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client.from('creator').select();
    appLogger.db('AFTER | table: creator | rows: ${data.length}');
    if (data.isEmpty) {
      appLogger.rls('Zero rows | table: creator | possible RLS block');
    }
    final eligible = data.map(Creator.fromJson).where((c) => c.isFanEligible).toList();
    appLogger.provider('fanEligibleCreatorsProvider → data | eligible: ${eligible.length}');
    return eligible;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: creator', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: creator | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('fanEligibleCreatorsProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: creator | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('fanEligibleCreatorsProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Creator public profile
// ---------------------------------------------------------------------------

final creatorProfileProvider =
    FutureProvider.autoDispose.family<Creator?, String>((ref, creatorId) async {
  appLogger.provider('creatorProfileProvider build() | creatorId: $creatorId');
  ref.onDispose(() => appLogger.provider('creatorProfileProvider disposed | creatorId: $creatorId'));
  appLogger.db('BEFORE | table: creator | op: SELECT | creatorId: $creatorId');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('creator')
        .select()
        .eq('id', creatorId)
        .maybeSingle();
    appLogger.db('AFTER | table: creator | rows: ${data == null ? 0 : 1} | creatorId: $creatorId');
    if (data == null) {
      appLogger.rls('Zero rows | table: creator | creatorId: $creatorId | possible RLS block or not found');
      appLogger.provider('creatorProfileProvider → data (null)');
      return null;
    }
    appLogger.provider('creatorProfileProvider → data | creatorId: $creatorId');
    return Creator.fromJson(data);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: creator | creatorId: $creatorId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: creator | creatorId: $creatorId | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('creatorProfileProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: creator | creatorId: $creatorId | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('creatorProfileProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Pure aggregation — exported for testability
// ---------------------------------------------------------------------------

String currentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

List<CreatorConsumption> aggregateConsumption(
  List<Map<String, dynamic>> rows,
  Map<String, Creator> creatorMap,
) {
  if (rows.isEmpty) return [];
  final counts = <String, int>{};
  for (final row in rows) {
    final id = row['creator_id'] as String?;
    if (id == null || !creatorMap.containsKey(id)) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final total = counts.values.fold(0, (a, b) => a + b);
  final result = counts.entries.map((e) {
    final c = creatorMap[e.key]!;
    return CreatorConsumption.fromAggregated(
      creatorId: c.id,
      creatorName: c.displayName,
      avatarUrl: c.avatarUrl,
      count: e.value,
      totalMeals: total,
    );
  }).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return result;
}

// ---------------------------------------------------------------------------
// Creator consumption ratio — current month, aggregated client-side
// ---------------------------------------------------------------------------

final creatorConsumptionProvider =
    FutureProvider.autoDispose<List<CreatorConsumption>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  appLogger.provider('creatorConsumptionProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('creatorConsumptionProvider disposed'));

  final monthKey = currentMonthKey();
  final client = ref.watch(supabaseClientProvider);

  // Step 1: fetch this month's consumption rows
  appLogger.db('BEFORE | table: meal_consumption | op: SELECT | userId: ${user.id} | month: $monthKey');
  late final List<Map<String, dynamic>> consumptionRows;
  try {
    consumptionRows = await client
        .from('meal_consumption')
        .select('creator_id')
        .eq('user_id', user.id)
        .eq('month_key', monthKey);
    appLogger.db('AFTER | table: meal_consumption | rows: ${consumptionRows.length}');
    if (consumptionRows.isEmpty) {
      appLogger.rls('Zero rows | table: meal_consumption | userId: ${user.id} | month: $monthKey | no meals or RLS');
      appLogger.provider('creatorConsumptionProvider → data (empty)');
      return [];
    }
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: meal_consumption | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: meal_consumption | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('creatorConsumptionProvider → error | ${e.message}');
    rethrow;
  }

  // Step 2: fetch creator details for distinct IDs found in consumption
  final creatorIds = consumptionRows
      .map((r) => r['creator_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  appLogger.db('BEFORE | table: creator | op: SELECT | ids: ${creatorIds.length}');
  late final List<Map<String, dynamic>> creatorRows;
  try {
    creatorRows = await client
        .from('creator')
        .select()
        .inFilter('id', creatorIds);
    appLogger.db('AFTER | table: creator | rows: ${creatorRows.length}');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: creator', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: creator | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('creatorConsumptionProvider → error | ${e.message}');
    rethrow;
  }

  final creatorMap = {for (final r in creatorRows) r['id'] as String: Creator.fromJson(r)};
  final result = aggregateConsumption(consumptionRows, creatorMap);
  appLogger.provider('creatorConsumptionProvider → data | creators: ${result.length}');
  return result;
});

// ---------------------------------------------------------------------------
// Fan external recipe counter — current month (0 if no row yet)
// ---------------------------------------------------------------------------

final fanExternalCounterProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  appLogger.provider('fanExternalCounterProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('fanExternalCounterProvider disposed'));

  final monthKey = currentMonthKey();
  final client = ref.watch(supabaseClientProvider);

  appLogger.db('BEFORE | table: fan_external_recipe_counter | op: SELECT | userId: ${user.id} | month: $monthKey');
  try {
    final data = await client
        .from('fan_external_recipe_counter')
        .select('external_recipe_count')
        .eq('user_id', user.id)
        .eq('month_key', monthKey)
        .maybeSingle();
    final count = (data?['external_recipe_count'] as int?) ?? 0;
    appLogger.db('AFTER | table: fan_external_recipe_counter | count: $count');
    appLogger.provider('fanExternalCounterProvider → data | count: $count');
    return count;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: fan_external_recipe_counter | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: fan_external_recipe_counter | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('fanExternalCounterProvider → error | ${e.message}');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Fan mode notifier — activate / cancel via Edge Functions
// ---------------------------------------------------------------------------

class FanModeNotifier extends AutoDisposeAsyncNotifier<void> {
  final _logger = appLogger;

  @override
  FutureOr<void> build() {
    _logger.provider('FanModeNotifier build()');
    ref.onDispose(() => _logger.provider('FanModeNotifier disposed'));
  }

  Future<void> activate(String creatorId) async {
    _logger.userAction('Activate fan mode', metadata: {'creatorId': creatorId});
    _logger.edge('activate-fan-mode', 'BEFORE | creatorId: $creatorId');
    _logger.provider('FanModeNotifier → loading (activate)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'activate-fan-mode',
          body: {'creator_id': creatorId},
        );
        _logger.edge('activate-fan-mode', 'AFTER | success | creatorId: $creatorId');
        _logger.provider('FanModeNotifier → data (activate success)');
      } catch (e, st) {
        _logger.edge('activate-fan-mode', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('FanModeNotifier → error (activate)');
        rethrow;
      }
    });
    if (state is AsyncData) ref.invalidate(myFanSubscriptionProvider);
  }

  Future<void> cancel() async {
    _logger.userAction('Cancel fan mode');
    _logger.edge('cancel-fan-mode', 'BEFORE');
    _logger.provider('FanModeNotifier → loading (cancel)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke('cancel-fan-mode', body: {});
        _logger.edge('cancel-fan-mode', 'AFTER | success');
        _logger.provider('FanModeNotifier → data (cancel success)');
      } catch (e, st) {
        _logger.edge('cancel-fan-mode', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('FanModeNotifier → error (cancel)');
        rethrow;
      }
    });
    if (state is AsyncData) ref.invalidate(myFanSubscriptionProvider);
  }
}

final fanModeNotifierProvider =
    AsyncNotifierProvider.autoDispose<FanModeNotifier, void>(
        FanModeNotifier.new);
