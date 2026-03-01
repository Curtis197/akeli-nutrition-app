import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? email;
  final bool onboardingDone;
  final bool isCreator;
  final String? preferredLanguage;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.email,
    required this.onboardingDone,
    required this.isCreator,
    this.preferredLanguage,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        email: json['email'] as String?,
        onboardingDone: (json['onboarding_done'] as bool?) ?? false,
        isCreator: (json['is_creator'] as bool?) ?? false,
        preferredLanguage: json['preferred_language'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? onboardingDone,
    bool? isCreator,
    String? preferredLanguage,
  }) =>
      UserProfile(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        email: email,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        isCreator: isCreator ?? this.isCreator,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        createdAt: createdAt,
      );
}

@immutable
class HealthProfile {
  final String userId;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final double? targetWeightKg;
  final String? activityLevel;
  final String? primaryGoal;
  final List<String> dietaryRestrictions;
  final List<String> cuisinePreferences;

  const HealthProfile({
    required this.userId,
    this.age,
    this.weightKg,
    this.heightCm,
    this.targetWeightKg,
    this.activityLevel,
    this.primaryGoal,
    required this.dietaryRestrictions,
    required this.cuisinePreferences,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) => HealthProfile(
        userId: json['user_id'] as String,
        age: json['age'] as int?,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
        activityLevel: json['activity_level'] as String?,
        primaryGoal: json['primary_goal'] as String?,
        dietaryRestrictions:
            (json['dietary_restrictions'] as List<dynamic>?)?.cast<String>() ??
                [],
        cuisinePreferences:
            (json['cuisine_preferences'] as List<dynamic>?)?.cast<String>() ??
                [],
      );

  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final hm = heightCm! / 100;
    return weightKg! / (hm * hm);
  }
}
