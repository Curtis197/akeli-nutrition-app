// lib/features/settings/models/health_profile_model.dart

import 'package:akeli/core/logger.dart';

// Logger import required by CLAUDE.md logging standard.
// Pure data model — no side-effect logging calls needed at runtime.
// ignore: unused_element
final _logger = appLogger;

class HealthProfileModel {
  final String? sex;
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String? activityLevel;
  final String? weightGoal;
  final String? muscleGoal;
  final double? startingWeightKg;
  final int? targetTimeWeeks;
  final String? goalType;

  const HealthProfileModel({
    this.sex,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.weightGoal,
    this.muscleGoal,
    this.startingWeightKg,
    this.targetTimeWeeks,
    this.goalType,
  });

  int? get age {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int years = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  HealthProfileModel copyWith({
    String? sex,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? activityLevel,
    String? weightGoal,
    String? muscleGoal,
    double? startingWeightKg,
    int? targetTimeWeeks,
    String? goalType,
    bool clearBirthDate = false,
    bool clearSex = false,
    bool clearActivityLevel = false,
    bool clearWeightGoal = false,
    bool clearMuscleGoal = false,
    bool clearGoalType = false,
  }) {
    return HealthProfileModel(
      sex: clearSex ? null : (sex ?? this.sex),
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel:
          clearActivityLevel ? null : (activityLevel ?? this.activityLevel),
      weightGoal: clearWeightGoal ? null : (weightGoal ?? this.weightGoal),
      muscleGoal: clearMuscleGoal ? null : (muscleGoal ?? this.muscleGoal),
      startingWeightKg: startingWeightKg ?? this.startingWeightKg,
      targetTimeWeeks: targetTimeWeeks ?? this.targetTimeWeeks,
      goalType: clearGoalType ? null : (goalType ?? this.goalType),
    );
  }
}
