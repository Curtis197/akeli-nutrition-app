// test/core/saved_recipe_eligibility_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/saved_recipe_eligibility.dart';

void main() {
  group('savedRecipeEligibilityTarget', () {
    test('variety off (0) returns the baseline floor of 7', () {
      expect(savedRecipeEligibilityTarget(0), 7);
    });
    test('7-day variety returns 14', () {
      expect(savedRecipeEligibilityTarget(7), 14);
    });
    test('15-day variety returns 30', () {
      expect(savedRecipeEligibilityTarget(15), 30);
    });
  });
}
