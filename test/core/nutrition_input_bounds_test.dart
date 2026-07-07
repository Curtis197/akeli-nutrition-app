// test/core/nutrition_input_bounds_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/nutrition_input_bounds.dart';

void main() {
  group('NutritionInputBounds', () {
    test('weight bounds inclusive', () {
      expect(NutritionInputBounds.weightOk(30), isTrue);
      expect(NutritionInputBounds.weightOk(300), isTrue);
      expect(NutritionInputBounds.weightOk(29.9), isFalse);
      expect(NutritionInputBounds.weightOk(300.1), isFalse);
      expect(NutritionInputBounds.weightOk(null), isTrue); // optional-field semantics
    });

    test('height bounds inclusive', () {
      expect(NutritionInputBounds.heightOk(120), isTrue);
      expect(NutritionInputBounds.heightOk(230), isTrue);
      expect(NutritionInputBounds.heightOk(119.9), isFalse);
      expect(NutritionInputBounds.heightOk(230.1), isFalse);
      expect(NutritionInputBounds.heightOk(null), isTrue);
    });

    test('age bounds inclusive', () {
      expect(NutritionInputBounds.ageOk(18), isTrue);
      expect(NutritionInputBounds.ageOk(100), isTrue);
      expect(NutritionInputBounds.ageOk(17), isFalse);
      expect(NutritionInputBounds.ageOk(101), isFalse);
      expect(NutritionInputBounds.ageOk(null), isTrue);
    });

    test('underweight target detection at BMI 18.5', () {
      // 170 cm -> BMI 18.5 at 53.465 kg
      expect(NutritionInputBounds.targetUnderweight(53.0, 170), isTrue);
      expect(NutritionInputBounds.targetUnderweight(54.0, 170), isFalse);
      expect(NutritionInputBounds.targetUnderweight(null, 170), isFalse);
      expect(NutritionInputBounds.targetUnderweight(53.0, null), isFalse);
    });
  });
}
