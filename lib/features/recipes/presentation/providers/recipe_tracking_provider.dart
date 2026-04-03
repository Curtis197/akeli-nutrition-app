import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/i_recipe_tracking_repository.dart';
import '../../domain/entities/recipe_tracking.dart';

class MockRecipeTrackingRepository implements IRecipeTrackingRepository {
  @override
  Future<void> trackImpression({required String recipeId, required TrackingSource source}) async {
    debugPrint('Mock tracking impression for $recipeId from $source');
  }

  @override
  Future<RecipeOpen?> trackOpen({required String recipeId, required TrackingSource source}) async {
    debugPrint('Mock tracking open for $recipeId from $source');
    return null;
  }

  @override
  Future<void> trackClose({required String openId, required DateTime openedAt}) async {
    debugPrint('Mock tracking close for $openId');
  }
}

final recipeTrackingRepositoryProvider = Provider<IRecipeTrackingRepository>(
  (ref) => MockRecipeTrackingRepository(),
);
