import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/journey_stats.dart';
import 'auth_provider.dart';

final _logger = appLogger;

final journeyStatsProvider = FutureProvider.autoDispose
    .family<JourneyStats?, ({int year, int month})>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  _logger.provider(
    'journeyStatsProvider build() | userId: ${user.id} | ${params.year}-${params.month}',
  );

  ref.onDispose(() => _logger.provider(
    'journeyStatsProvider disposed | ${params.year}-${params.month}',
  ));

  final client = ref.read(supabaseClientProvider);

  _logger.db(
    'BEFORE rpc | fn: get_journey_stats | year: ${params.year} | month: ${params.month}',
  );

  try {
    final data = await client.rpc('get_journey_stats', params: {
      'p_year':  params.year,
      'p_month': params.month,
    });

    _logger.db('AFTER rpc | fn: get_journey_stats | rows: ${data == null ? 0 : 1}');
    if (data == null) return null;

    final stats = JourneyStats.fromJson(data as Map<String, dynamic>);
    _logger.provider(
      'journeyStatsProvider → data | calendar days: ${stats.calendar.length}',
    );
    return stats;
  } on PostgrestException catch (e, st) {
    _logger.db(
      'ERROR rpc | fn: get_journey_stats | code: ${e.code} | ${e.message}',
      error: e,
      stackTrace: st,
    );
    rethrow;
  } catch (e, st) {
    _logger.db('ERROR rpc | fn: get_journey_stats | $e', error: e, stackTrace: st);
    rethrow;
  }
});
