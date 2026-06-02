// test/features/settings/health_profile_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/settings/models/health_profile_model.dart';

void main() {
  group('HealthProfileModel', () {
    const base = HealthProfileModel(
      sex: 'male',
      heightCm: 175.0,
      weightKg: 75.0,
      targetWeightKg: 70.0,
      activityLevel: 'moderate',
      weightGoal: 'loss',
      muscleGoal: 'maintenance',
      startingWeightKg: 80.0,
      targetTimeWeeks: 12,
      goalType: 'weight_loss',
    );

    test('copyWith replaces provided fields', () {
      final updated = base.copyWith(weightKg: 74.0, goalType: 'maintenance');
      expect(updated.weightKg, 74.0);
      expect(updated.goalType, 'maintenance');
      expect(updated.sex, 'male'); // unchanged
      expect(updated.heightCm, 175.0); // unchanged
    });

    test('copyWith clearBirthDate removes birthDate', () {
      final withDate = base.copyWith(birthDate: DateTime(1990, 5, 15));
      expect(withDate.birthDate, isNotNull);
      final cleared = withDate.copyWith(clearBirthDate: true);
      expect(cleared.birthDate, isNull);
    });

    test('default constructor produces empty model', () {
      const empty = HealthProfileModel();
      expect(empty.sex, isNull);
      expect(empty.weightKg, isNull);
      expect(empty.goalType, isNull);
    });

    test('age returns correct value when birthDate set', () {
      final model = base.copyWith(
        birthDate: DateTime(DateTime.now().year - 30, 1, 1),
      );
      expect(model.age, 30);
    });

    test('age returns null when birthDate is null', () {
      expect(base.age, isNull);
    });
  });
}
