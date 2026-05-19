import 'package:akeli/core/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/i_recipe_tracking_repository.dart';
import '../../domain/entities/recipe_tracking.dart';

class MockRecipeTrackingRepository implements IRecipeTrackingRepository {
  final _logger = appLogger;

  @override
  Future<void> trackImpression({required String recipeId, required TrackingSource source}) async {
    _logger.db('BEFORE | op: trackImpression | recipeId: $recipeId | source: $source');
    try {
      _logger.db('AFTER | op: trackImpression | recipeId: $recipeId (mock)');
    } catch (e, st) {
      _logger.db('ERROR | op: trackImpression | recipeId: $recipeId', error: e, stackTrace: st);
    }
  }

  @override
  Future<RecipeOpen?> trackOpen({required String recipeId, required TrackingSource source}) async {
    _logger.db('BEFORE | op: trackOpen | recipeId: $recipeId | source: $source');
    try {
      _logger.db('AFTER | op: trackOpen | recipeId: $recipeId | result: null (mock)');
      return null;
    } catch (e, st) {
      _logger.db('ERROR | op: trackOpen | recipeId: $recipeId', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<void> trackClose({required String openId, required DateTime openedAt}) async {
    _logger.db('BEFORE | op: trackClose | openId: $openId');
    try {
      _logger.db('AFTER | op: trackClose | openId: $openId (mock)');
    } catch (e, st) {
      _logger.db('ERROR | op: trackClose | openId: $openId', error: e, stackTrace: st);
    }
  }
}

final recipeTrackingRepositoryProvider = Provider<IRecipeTrackingRepository>(
  (ref) {
    appLogger.provider('recipeTrackingRepositoryProvider created (mock)');
    return MockRecipeTrackingRepository();
  },
);
