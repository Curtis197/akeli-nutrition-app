import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/recipe_usage.dart';

void main() {
  group('RecipeUsage.fromJson', () {
    test('maps all fields when present', () {
      final usage = RecipeUsage.fromJson(const {
        'recipe_id': 'r1',
        'title': 'Jollof Rice',
        'cover_image_url': 'https://example.com/jollof.jpg',
        'prep_time_min': 15,
        'cook_time_min': 40,
      });

      expect(usage.id, 'r1');
      expect(usage.title, 'Jollof Rice');
      expect(usage.thumbnailUrl, 'https://example.com/jollof.jpg');
      expect(usage.prepTimeMin, 15);
      expect(usage.cookTimeMin, 40);
    });

    test('defaults missing optional fields', () {
      final usage = RecipeUsage.fromJson(const {
        'recipe_id': 'r2',
        'title': 'Plain Rice',
        'cover_image_url': null,
        'prep_time_min': null,
        'cook_time_min': null,
      });

      expect(usage.thumbnailUrl, isNull);
      expect(usage.prepTimeMin, 0);
      expect(usage.cookTimeMin, 0);
    });
  });
}
