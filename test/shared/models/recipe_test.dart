import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/recipe.dart';

void main() {
  test('copyWith preserves beauty fields unchanged', () {
    final recipe = Recipe(
      id: 'r-1',
      creatorId: 'c-1',
      title: 'Original title',
      imageUrls: const [],
      prepTimeMin: 10,
      cookTimeMin: 5,
      servings: 1,
      difficulty: 'easy',
      mode: 'beauty',
      beautyType: 'hair',
      virtueWeights: const {'hydration': 0.8},
      createdAt: DateTime(2026, 1, 1),
    );

    final updated = recipe.copyWith(title: 'new title');

    expect(updated.title, 'new title');
    expect(updated.mode, 'beauty');
    expect(updated.beautyType, 'hair');
    expect(updated.virtueWeights, const {'hydration': 0.8});
  });
}
