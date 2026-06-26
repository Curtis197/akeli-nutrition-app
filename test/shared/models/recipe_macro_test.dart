import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/recipe.dart';

Map<String, dynamic> _baseJson({dynamic recipeMacro}) => {
  'id': 'r-1',
  'creator_id': 'c-1',
  'title': 'Thiéboudienne',
  'prep_time_min': 30,
  'cook_time_min': 60,
  'servings': 4,
  'difficulty': 'medium',
  'average_rating': 4.5,
  'average_rating_taste': 4.5,
  'average_rating_ease': 4.0,
  'average_rating_satiety': 4.5,
  'rating_count': 10,
  'comment_count': 5,
  'like_count': 20,
  'save_count': 8,
  'is_saved': false,
  'is_liked': false,
  'is_published': true,
  'ingredients': [],
  'steps': [],
  'tag_ids': [],
  'created_at': '2026-01-01T00:00:00.000Z',
  'recipe_macro': recipeMacro,
};

void main() {
  group('Recipe.fromJson — recipe_macro', () {
    test('parses recipe_macro when it is a bare Map (RPC shape)', () {
      final json = _baseJson(recipeMacro: {
        'calories': 250.0,
        'protein_g': 20.0,
        'carbs_g': 30.0,
        'fat_g': 5.0,
        'fiber_g': 3.0,
        'calories_per_100g': 120.0,
        'protein_per_100g': 10.0,
        'carbs_per_100g': 15.0,
        'fat_per_100g': 2.5,
      });
      final recipe = Recipe.fromJson(json);
      expect(recipe.calories100g, closeTo(120.0, 0.001));
      expect(recipe.protein100g, closeTo(10.0, 0.001));
    });

    test('parses recipe_macro when it is a List with one item (direct query shape)', () {
      final json = _baseJson(recipeMacro: [
        {
          'calories': 250.0,
          'protein_g': 20.0,
          'carbs_g': 30.0,
          'fat_g': 5.0,
          'fiber_g': 3.0,
          'calories_per_100g': 120.0,
          'protein_per_100g': 10.0,
          'carbs_per_100g': 15.0,
          'fat_per_100g': 2.5,
        }
      ]);
      final recipe = Recipe.fromJson(json);
      expect(recipe.calories100g, closeTo(120.0, 0.001));
      expect(recipe.protein100g, closeTo(10.0, 0.001));
    });

    test('returns null macro fields when recipe_macro is an empty List', () {
      final json = _baseJson(recipeMacro: <dynamic>[]);
      final recipe = Recipe.fromJson(json);
      expect(recipe.calories100g, isNull);
      expect(recipe.protein100g, isNull);
    });

    test('returns null macro fields when recipe_macro is null', () {
      final json = _baseJson(recipeMacro: null);
      final recipe = Recipe.fromJson(json);
      expect(recipe.calories100g, isNull);
      expect(recipe.protein100g, isNull);
    });
  });
}
