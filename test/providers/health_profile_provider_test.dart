// test/providers/health_profile_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/settings/models/health_profile_model.dart';
import 'package:akeli/providers/health_profile_provider.dart';

void main() {
  group('activityLevelForCalculator', () {
    test('maps sedentary correctly', () {
      expect(activityLevelForCalculator('sedentary'), 'sedentary');
    });

    test('maps light correctly', () {
      expect(activityLevelForCalculator('light'), 'lightly_active');
    });

    test('maps moderate correctly', () {
      expect(activityLevelForCalculator('moderate'), 'moderately_active');
    });

    test('maps active correctly', () {
      expect(activityLevelForCalculator('active'), 'very_active');
    });

    test('maps very_active correctly', () {
      expect(activityLevelForCalculator('very_active'), 'extremely_active');
    });

    test('unknown value returns sedentary fallback', () {
      expect(activityLevelForCalculator('unknown'), 'sedentary');
    });
  });

  group('computeCalorieGoal', () {
    test('returns null when age is null', () {
      const model = HealthProfileModel(
        weightKg: 70,
        heightCm: 170,
        sex: 'male',
        activityLevel: 'moderate',
        goalType: 'maintenance',
      );
      expect(computeCalorieGoal(model), isNull);
    });

    test('returns null when weightKg is null', () {
      final model = HealthProfileModel(
        birthDate: DateTime(1990, 1, 1),
        heightCm: 170,
        sex: 'male',
        activityLevel: 'moderate',
        goalType: 'maintenance',
      );
      expect(computeCalorieGoal(model), isNull);
    });

    test('returns null when heightCm is null', () {
      final model = HealthProfileModel(
        birthDate: DateTime(1990, 1, 1),
        weightKg: 70,
        sex: 'male',
        activityLevel: 'moderate',
        goalType: 'maintenance',
      );
      expect(computeCalorieGoal(model), isNull);
    });

    test('returns a positive integer for complete data', () {
      final model = HealthProfileModel(
        birthDate: DateTime(1990, 1, 1),
        weightKg: 70,
        heightCm: 170,
        sex: 'male',
        activityLevel: 'moderate',
        goalType: 'maintenance',
      );
      final result = computeCalorieGoal(model);
      expect(result, isNotNull);
      expect(result, greaterThan(0));
    });
  });
}
