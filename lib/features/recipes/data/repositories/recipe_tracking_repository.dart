import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/recipe_tracking.dart';
import '../../domain/repositories/i_recipe_tracking_repository.dart';
import '../datasources/recipe_tracking_datasource.dart';

class RecipeTrackingRepository implements IRecipeTrackingRepository {
  final RecipeTrackingDatasource _datasource;
  final SupabaseClient _client;

  RecipeTrackingRepository(this._datasource, this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> trackImpression({
    required String recipeId,
    required TrackingSource source,
  }) async {
    try {
      await _datasource.insertImpression(
        recipeId: recipeId,
        source: source.value,
        userId: _currentUserId,
      );
    } catch (e) {
      // Non-bloquant — on log silencieusement, on ne throw pas
      debugPrint('[RecipeTracking] impression error: $e');
    }
  }

  @override
  Future<RecipeOpen?> trackOpen({
    required String recipeId,
    required TrackingSource source,
  }) async {
    try {
      final openedAt = DateTime.now();
      final id = await _datasource.insertOpen(
        recipeId: recipeId,
        source: source.value,
        userId: _currentUserId,
      );
      if (id == null) return null;

      return RecipeOpen(
        id: id,
        recipeId: recipeId,
        userId: _currentUserId,
        source: source,
        openedAt: openedAt,
      );
    } catch (e) {
      debugPrint('[RecipeTracking] open error: $e');
      return null;
    }
  }

  @override
  Future<void> trackClose({
    required String openId,
    required DateTime openedAt,
  }) async {
    try {
      final closedAt = DateTime.now();
      final duration = closedAt.difference(openedAt).inSeconds;

      await _datasource.updateClose(
        openId: openId,
        closedAt: closedAt,
        sessionDurationSeconds: duration,
      );
    } catch (e) {
      debugPrint('[RecipeTracking] close error: $e');
    }
  }
}
