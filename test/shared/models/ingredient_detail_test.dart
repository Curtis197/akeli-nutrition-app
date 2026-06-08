import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/ingredient_detail.dart';
import 'package:akeli/shared/models/recipe.dart';

void main() {
  group('IngredientDetail.fromJson', () {
    test('maps all fields when present', () {
      final detail = IngredientDetail.fromJson(const {
        'id': 'ing-1',
        'name_fr': 'Gombo',
        'calories_per_100g': 33.0,
        'protein_per_100g': 1.9,
        'carbs_per_100g': 7.5,
        'fat_per_100g': 0.2,
        'fiber_per_100g': 3.2,
        'substitution': 'Haricots verts',
        'market_notes': 'Épicerie africaine',
      });

      expect(detail.id, 'ing-1');
      expect(detail.name, 'Gombo');
      expect(detail.caloriesPer100g, 33.0);
      expect(detail.proteinPer100g, 1.9);
      expect(detail.substitution, 'Haricots verts');
      expect(detail.marketNotes, 'Épicerie africaine');
    });

    test('returns null for nullable fields when absent', () {
      final detail = IngredientDetail.fromJson(const {
        'id': 'ing-2',
        'name': 'Okra',
      });

      expect(detail.caloriesPer100g, isNull);
      expect(detail.substitution, isNull);
      expect(detail.marketNotes, isNull);
    });

    test('prefers name_fr over name', () {
      final detail = IngredientDetail.fromJson(const {
        'id': 'ing-3',
        'name_fr': 'Gombo',
        'name': 'Okra',
      });
      expect(detail.name, 'Gombo');
    });
  });

  group('RecipeStep.fromJson with new fields', () {
    test('parses video_url and ingredient_ids', () {
      final step = RecipeStep.fromJson(const {
        'step_number': 1,
        'instruction': 'Couper les légumes',
        'video_url': 'https://example.com/step1.mp4',
        'ingredient_ids': ['id-a', 'id-b'],
      });

      expect(step.videoUrl, 'https://example.com/step1.mp4');
      expect(step.ingredientIds, ['id-a', 'id-b']);
    });

    test('defaults ingredient_ids to empty list when null', () {
      final step = RecipeStep.fromJson(const {
        'step_number': 1,
        'instruction': 'Couper',
      });
      expect(step.ingredientIds, isEmpty);
      expect(step.videoUrl, isNull);
    });
  });

  group('Recipe.fromJson videoUrl', () {
    test('parses video_url field', () {
      final recipe = Recipe.fromJson(const {
        'id': 'r1',
        'creator_id': 'c1',
        'title': 'Thiéboudienne',
        'prep_time_min': 30,
        'cook_time_min': 60,
        'servings': 4,
        'difficulty': 'medium',
        'average_rating': 4.5,
        'average_rating_taste': 4.5,
        'average_rating_ease': 4.0,
        'average_rating_satiety': 4.0,
        'rating_count': 10,
        'comment_count': 2,
        'like_count': 5,
        'save_count': 3,
        'is_saved': false,
        'is_liked': false,
        'is_published': true,
        'video_url': 'https://example.com/recipe.mp4',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(recipe.videoUrl, 'https://example.com/recipe.mp4');
    });

    test('videoUrl is null when absent', () {
      final recipe = Recipe.fromJson(const {
        'id': 'r1',
        'creator_id': 'c1',
        'title': 'Thiéboudienne',
        'prep_time_min': 30,
        'cook_time_min': 60,
        'servings': 4,
        'difficulty': 'medium',
        'average_rating': 4.5,
        'average_rating_taste': 4.5,
        'average_rating_ease': 4.0,
        'average_rating_satiety': 4.0,
        'rating_count': 10,
        'comment_count': 2,
        'like_count': 5,
        'save_count': 3,
        'is_saved': false,
        'is_liked': false,
        'is_published': true,
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(recipe.videoUrl, isNull);
    });
  });
}
