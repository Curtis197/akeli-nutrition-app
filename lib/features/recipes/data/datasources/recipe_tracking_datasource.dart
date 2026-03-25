import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeTrackingDatasource {
  final SupabaseClient _client;

  RecipeTrackingDatasource(this._client);

  Future<void> insertImpression({
    required String recipeId,
    required String source,
    String? userId,
  }) async {
    await _client.from('recipe_impression').insert({
      'recipe_id': recipeId,
      'user_id': userId,
      'source': source,
      'seen_at': DateTime.now().toIso8601String(),
    });
  }

  /// Retourne l'id de la ligne insérée (nécessaire pour le PATCH de fermeture).
  Future<String?> insertOpen({
    required String recipeId,
    required String source,
    String? userId,
  }) async {
    final response = await _client
        .from('recipe_open')
        .insert({
          'recipe_id': recipeId,
          'user_id': userId,
          'source': source,
          'opened_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return response['id'] as String?;
  }

  Future<void> updateClose({
    required String openId,
    required DateTime closedAt,
    required int sessionDurationSeconds,
  }) async {
    await _client.from('recipe_open').update({
      'closed_at': closedAt.toIso8601String(),
      'session_duration_seconds': sessionDurationSeconds,
    }).eq('id', openId);
  }
}
