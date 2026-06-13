import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/journey_stats.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Top impact recipe per meal type — best recipe for each of breakfast/lunch/dinner
// Returns a map keyed by meal_type with the top RecipeWeightImpact for each.
// ---------------------------------------------------------------------------

final topImpactRecipesByMealTypeProvider =
    FutureProvider.autoDispose<Map<String, RecipeWeightImpact>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  _logger.provider('topImpactRecipesByMealTypeProvider build() | userId: ${user.id}');
  ref.onDispose(() => _logger.provider('topImpactRecipesByMealTypeProvider disposed'));

  final client = ref.read(supabaseClientProvider);

  _logger.db(
    'BEFORE | table: recipe_weight_impact | op: SELECT | userId: ${user.id}',
  );

  try {
    // Fetch all rows sorted ASC — first row per meal_type is the best (lowest delta).
    final rows = await client
        .from('recipe_weight_impact')
        .select('recipe_id, meal_type, avg_delta_kg, sample_count, recipe:recipe_id(title, thumbnail_url)')
        .eq('user_id', user.id)
        .inFilter('meal_type', ['breakfast', 'lunch', 'dinner'])
        .order('avg_delta_kg', ascending: true);

    _logger.db(
      'AFTER | table: recipe_weight_impact | rows: ${rows.length}',
    );

    if (rows.isEmpty) return {};

    // Pick first occurrence of each meal_type (best delta, since sorted ASC).
    final result = <String, RecipeWeightImpact>{};
    for (final row in rows) {
      final mealType = row['meal_type'] as String;
      if (!result.containsKey(mealType)) {
        result[mealType] = RecipeWeightImpact.fromJson(row);
      }
      if (result.length == 3) break;
    }

    _logger.provider(
      'topImpactRecipesByMealTypeProvider → data | mealTypes: ${result.keys.toList()}',
    );
    return result;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls(
        'Permission denied | table: recipe_weight_impact | userId: ${user.id}',
        error: e,
        stackTrace: st,
      );
    } else {
      _logger.db(
        'ERROR | table: recipe_weight_impact | code: ${e.code} | ${e.message}',
        error: e,
        stackTrace: st,
      );
    }
    rethrow;
  } catch (e, st) {
    _logger.db(
      'ERROR | table: recipe_weight_impact | $e',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

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
