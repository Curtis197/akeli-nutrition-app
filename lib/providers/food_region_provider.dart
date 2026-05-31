import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import 'user_profile_provider.dart';

/// Returns a map of food_region code → localized name based on the user's
/// locale. Falls back to name_fr for unsupported locales.
///
/// food_region is public-readable static reference data — queried once and
/// kept alive for the session.
final foodRegionNamesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  ref.keepAlive();

  final logger = appLogger;
  logger.provider('foodRegionNamesProvider build()');

  final locale = ref.watch(userProfileProvider).valueOrNull?.locale ?? 'fr';
  final nameColumn = _localeToColumn(locale);

  logger.db(
      'BEFORE | table: food_region | op: SELECT | locale: $locale | column: $nameColumn');

  final client = ref.watch(supabaseClientProvider);
  try {
    final rows = await client
        .from('food_region')
        .select('code, name_fr, name_en, name_es, name_pt');

    logger.db('AFTER | table: food_region | rows: ${rows.length}');

    final map = <String, String>{};
    for (final row in rows) {
      final code = row['code'] as String;
      final name = (row[nameColumn] as String?) ??
          (row['name_fr'] as String?) ??
          code;
      map[code] = name;
    }

    logger.provider('foodRegionNamesProvider → data | count: ${map.length}');
    return map;
  } on Exception catch (e, st) {
    logger.db(
        'ERROR | table: food_region | ${e.toString()}',
        error: e,
        stackTrace: st);
    rethrow;
  }
});

String _localeToColumn(String locale) {
  switch (locale) {
    case 'en':
      return 'name_en';
    case 'es':
      return 'name_es';
    case 'pt':
      return 'name_pt';
    default:
      return 'name_fr';
  }
}

/// Returns a map of food_region code → localized name (for group browse/edit dropdowns)
final foodRegionsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  ref.keepAlive();

  final logger = appLogger;
  logger.provider('foodRegionsProvider build()');

  final locale = ref.watch(userProfileProvider).valueOrNull?.locale ?? 'fr';
  final nameColumn = _localeToColumn(locale);

  logger.db('BEFORE | table: food_region | op: SELECT | locale: $locale');

  final client = ref.watch(supabaseClientProvider);
  try {
    final rows = await client
        .from('food_region')
        .select('code, name_fr, name_en, name_es, name_pt');

    final map = <String, String>{};
    for (final row in rows) {
      final code = row['code'] as String;
      final name = (row[nameColumn] as String?) ??
          (row['name_fr'] as String?) ??
          code;
      map[code] = name;
    }
    logger.db('AFTER | table: food_region | rows: ${map.length}');
    return map;
  } on Exception catch (e, st) {
    logger.db('ERROR | table: food_region | ${e.toString()}', error: e, stackTrace: st);
    rethrow;
  }
});
