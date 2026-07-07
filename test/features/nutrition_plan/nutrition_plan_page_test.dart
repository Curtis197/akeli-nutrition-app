// test/features/nutrition_plan/nutrition_plan_page_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/nutrition_plan/nutrition_plan_page.dart';

void main() {
  group('primaryGoalFromOnboardingSelections', () {
    test('weightGoal loss maps to weight_loss regardless of muscleGoal', () {
      expect(
          primaryGoalFromOnboardingSelections(
              weightGoal: 'loss', muscleGoal: 'gain'),
          'weight_loss');
    });

    test('weightGoal gain maps to muscle_gain regardless of muscleGoal', () {
      expect(
          primaryGoalFromOnboardingSelections(
              weightGoal: 'gain', muscleGoal: 'loss'),
          'muscle_gain');
    });

    test('weightGoal maintenance + muscleGoal gain falls back to muscle_gain',
        () {
      expect(
          primaryGoalFromOnboardingSelections(
              weightGoal: 'maintenance', muscleGoal: 'gain'),
          'muscle_gain');
    });

    test('weightGoal maintenance + muscleGoal loss falls back to weight_loss',
        () {
      expect(
          primaryGoalFromOnboardingSelections(
              weightGoal: 'maintenance', muscleGoal: 'loss'),
          'weight_loss');
    });

    test('weightGoal maintenance + muscleGoal maintenance stays maintenance',
        () {
      expect(
          primaryGoalFromOnboardingSelections(
              weightGoal: 'maintenance', muscleGoal: 'maintenance'),
          'maintenance');
    });

    test('weightGoal maintenance + null muscleGoal stays maintenance', () {
      expect(
          primaryGoalFromOnboardingSelections(
              weightGoal: 'maintenance', muscleGoal: null),
          'maintenance');
    });

    test('both null falls back to maintenance', () {
      expect(
          primaryGoalFromOnboardingSelections(
              weightGoal: null, muscleGoal: null),
          'maintenance');
    });
  });
}
