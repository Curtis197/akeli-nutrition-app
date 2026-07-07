// test/providers/health_profile_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
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
}
