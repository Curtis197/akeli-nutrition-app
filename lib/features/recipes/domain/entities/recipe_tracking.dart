enum TrackingSource {
  feed,
  search,
  mealPlanner;

  String get value {
    switch (this) {
      case TrackingSource.feed:
        return 'feed';
      case TrackingSource.search:
        return 'search';
      case TrackingSource.mealPlanner:
        return 'meal_planner';
    }
  }
}

class RecipeImpression {
  final String recipeId;
  final String? userId; // nullable — utilisateur non connecté possible
  final TrackingSource source;
  final DateTime seenAt;

  const RecipeImpression({
    required this.recipeId,
    this.userId,
    required this.source,
    required this.seenAt,
  });
}

class RecipeOpen {
  final String id; // UUID retourné par Supabase après l'insert
  final String recipeId;
  final String? userId;
  final TrackingSource source;
  final DateTime openedAt;

  const RecipeOpen({
    required this.id,
    required this.recipeId,
    this.userId,
    required this.source,
    required this.openedAt,
  });
}
