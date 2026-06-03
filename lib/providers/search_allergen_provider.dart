import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/logger.dart';
import '../../core/supabase_client.dart';
import '../features/settings/models/allergen_model.dart';

part 'search_allergen_provider.g.dart';

@riverpod
Future<List<AllergenModel>> searchAllergen(SearchAllergenRef ref, String query) async {
  final logger = appLogger;
  
  if (query.trim().isEmpty) return [];

  var isCancelled = false;
  ref.onDispose(() => isCancelled = true);
  
  await Future.delayed(const Duration(milliseconds: 300));
  if (isCancelled) return [];

  final client = ref.watch(supabaseClientProvider);
  logger.db('search_allergens | query: $query');

  try {
    final res = await client.rpc('search_allergens', params: {'p_query': query});
    final list = res as List<dynamic>;
    return list.map((e) => AllergenModel.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e, st) {
    logger.db('ERROR | search_allergens', error: e, stackTrace: st);
    return [];
  }
}
