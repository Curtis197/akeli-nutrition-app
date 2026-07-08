// test/providers/nutrition_targets_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/nutrition_targets_provider.dart';

void main() {
  group('buildCalculateTargetsParams', () {
    test('maps every input to its p_ column name', () {
      final p = buildCalculateTargetsParams(
        weightKg: 70, heightCm: 170, age: 30, sex: 'female',
        activityLevel: 'moderate', primaryGoal: 'weight_loss',
        targetWeightKg: 60, remainingWeeks: 26, muscleGoal: 'gain',
      );
      expect(p, {
        'p_weight_kg': 70.0, 'p_height_cm': 170.0, 'p_age': 30,
        'p_sex': 'female', 'p_activity_level': 'moderate',
        'p_primary_goal': 'weight_loss',
        'p_target_weight_kg': 60.0, 'p_remaining_weeks': 26,
        'p_muscle_goal': 'gain',
      });
    });

    test('optional params pass through as null', () {
      final p = buildCalculateTargetsParams(
        weightKg: 70, heightCm: 170, age: 30, sex: 'male',
        activityLevel: null, primaryGoal: 'maintenance',
      );
      expect(p['p_target_weight_kg'], isNull);
      expect(p['p_remaining_weeks'], isNull);
      expect(p['p_activity_level'], isNull);
      expect(p['p_muscle_goal'], isNull);
    });
  });

  group('remainingWeeks helpers', () {
    test('from months: 6 months -> 26 weeks', () {
      expect(remainingWeeksFromMonths(6), 26);
    });
    test('from months: floors at 4 (1 month -> 4, not 4.33-rounded-below)', () {
      expect(remainingWeeksFromMonths(1), 4);
    });
    test('from date: null -> null', () {
      expect(remainingWeeksFromDate(null), isNull);
    });
    test('from date: 140 days out -> 20 weeks', () {
      final now = DateTime(2026, 7, 7);
      expect(remainingWeeksFromDate(now.add(const Duration(days: 140)), now: now), 20);
    });
    test('from date: overdue -> floor 4', () {
      final now = DateTime(2026, 7, 7);
      expect(remainingWeeksFromDate(now.subtract(const Duration(days: 10)), now: now), 4);
    });
  });

  group('NutritionTargetsResult.fromRpcRow', () {
    test('parses numeric row including null estimated weeks', () {
      final r = NutritionTargetsResult.fromRpcRow({
        'bmr': 1451.5, 'tdee': 2249.825, 'calorie_goal': 1827,
        'protein_g': 120.0, 'carb_g': 222.6, 'fat_g': 50.8,
        'effective_pace_kg_week': 0.38, 'estimated_weeks_to_target': 26.0,
      });
      expect(r.calorieGoal, 1827);
      expect(r.effectivePaceKgWeek, 0.38);
      expect(r.estimatedWeeksToTarget, 26.0);

      final m = NutritionTargetsResult.fromRpcRow({
        'bmr': 1620, 'tdee': 1944, 'calorie_goal': 1944,
        'protein_g': 89.6, 'carb_g': 274.9, 'fat_g': 54.0,
        'effective_pace_kg_week': 0, 'estimated_weeks_to_target': null,
      });
      expect(m.estimatedWeeksToTarget, isNull);
      expect(m.bmr, 1620.0);
    });
  });
}
