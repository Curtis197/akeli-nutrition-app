import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import '../core/supabase_client.dart';
import '../features/settings/models/saved_recipe_progress_model.dart';
import 'auth_provider.dart';

final savedRecipeProgressProvider = FutureProvider.autoDispose<SavedRecipeProgressModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final logger = appLogger;
  final client = ref.watch(supabaseClientProvider);

  logger.db('BEFORE | fn: get_saved_recipe_eligibility_progress | userId: ${user.id}');
  try {
    final res = await client.rpc('get_saved_recipe_eligibility_progress', params: {
      'p_user_id': user.id,
    });
    
    logger.db('AFTER | fn: get_saved_recipe_eligibility_progress');
    
    if (res == null) return null;
    return SavedRecipeProgressModel.fromJson(res as Map<String, dynamic>);
  } catch (e, st) {
    logger.db('ERROR | fn: get_saved_recipe_eligibility_progress', error: e, stackTrace: st);
    return null;
  }
});
