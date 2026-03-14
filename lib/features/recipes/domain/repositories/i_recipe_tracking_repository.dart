import '../entities/recipe_tracking.dart';

abstract class IRecipeTrackingRepository {
  /// Enregistre une impression (carte vue dans le feed/search/meal planner).
  /// Fire-and-forget — ne throw pas.
  Future<void> trackImpression({
    required String recipeId,
    required TrackingSource source,
  });

  /// Enregistre l'ouverture d'une recette.
  /// Retourne le RecipeOpen avec l'id Supabase (nécessaire pour le PATCH de fermeture).
  /// Retourne null en cas d'erreur (non-bloquant).
  Future<RecipeOpen?> trackOpen({
    required String recipeId,
    required TrackingSource source,
  });

  /// Met à jour la session à la fermeture de la vue détail.
  /// Fire-and-forget — ne throw pas.
  Future<void> trackClose({
    required String openId,
    required DateTime openedAt,
  });
}
