// test/providers/health_profile_provider_test.dart
//
// activityLevelForCalculator, computeCalorieGoal, and computeNutritionTargets
// were deleted along with the Dart formula copies — the SQL function
// calculate_nutrition_targets() is now the single source of truth (spec
// docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md)
// and is covered by supabase/tests/calculate_nutrition_targets_test.sql.

import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/settings/models/health_profile_model.dart';

void main() {
  group('HealthProfileModel goalType passthrough', () {
    test('fromJson reads goal_type from the goal row', () {
      final m = HealthProfileModel.fromJson(
          health: null, goal: {'goal_type': 'weight_loss'});
      expect(m.goalType, 'weight_loss');
    });
  });
}
