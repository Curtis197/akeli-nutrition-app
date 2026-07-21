// lib/features/settings/models/health_profile_model.dart

import 'package:akeli/core/logger.dart';

// ignore: unused_element
final _logger = appLogger;

class HealthProfileModel {
  // Nutrition fields
  final String? sex;
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final String? activityLevel;
  final String? weightGoal;
  final String? muscleGoal;
  final double? startingWeightKg;
  final DateTime? targetDate;
  final String? goalType;

  // Beauty fields
  final String? hairType;
  final String? porosity;
  final String? skinType;
  final bool? sensitiveScalp;
  final List<String> beautyGoals;
  final List<String> skinConcerns;

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
    this.targetDate,
    this.goalType,
    this.hairType,
    this.porosity,
    this.skinType,
    this.sensitiveScalp,
    this.beautyGoals = const [],
    this.skinConcerns = const [],
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
    DateTime? targetDate,
    String? goalType,
    String? hairType,
    String? porosity,
    String? skinType,
    bool? sensitiveScalp,
    List<String>? beautyGoals,
    List<String>? skinConcerns,
    bool clearBirthDate = false,
    bool clearSex = false,
    bool clearActivityLevel = false,
    bool clearWeightGoal = false,
    bool clearMuscleGoal = false,
    bool clearTargetDate = false,
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
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      goalType: clearGoalType ? null : (goalType ?? this.goalType),
      hairType: hairType ?? this.hairType,
      porosity: porosity ?? this.porosity,
      skinType: skinType ?? this.skinType,
      sensitiveScalp: sensitiveScalp ?? this.sensitiveScalp,
      beautyGoals: beautyGoals ?? this.beautyGoals,
      skinConcerns: skinConcerns ?? this.skinConcerns,
    );
  }

  factory HealthProfileModel.fromJson({
    Map<String, dynamic>? health,
    Map<String, dynamic>? goal,
  }) {
    return HealthProfileModel(
      sex: health?['sex'] as String?,
      birthDate: health?['birth_date'] != null
          ? DateTime.tryParse(health!['birth_date'] as String)
          : null,
      heightCm: (health?['height_cm'] as num?)?.toDouble(),
      weightKg: (health?['weight_kg'] as num?)?.toDouble(),
      targetWeightKg: (health?['target_weight_kg'] as num?)?.toDouble(),
      activityLevel: health?['activity_level'] as String?,
      weightGoal: health?['weight_goal'] as String?,
      muscleGoal: health?['muscle_goal'] as String?,
      startingWeightKg: (health?['starting_weight_kg'] as num?)?.toDouble(),
      targetDate: health?['target_date'] != null
          ? DateTime.tryParse(health!['target_date'] as String)
          : null,
      goalType: goal?['goal_type'] as String?,
      hairType: health?['hair_type'] as String?,
      porosity: health?['porosity'] as String?,
      skinType: health?['skin_type'] as String?,
      sensitiveScalp: health?['sensitive_scalp'] as bool?,
      beautyGoals: (health?['beauty_goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      skinConcerns: (health?['skin_concerns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
