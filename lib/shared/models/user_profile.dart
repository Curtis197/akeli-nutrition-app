import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? bio;
  final String? email;
  final String role; // user | admin
  final bool onboardingDone;
  final bool isCreator;
  final String locale; // fr | en | ...
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.bio,
    this.email,
    this.role = 'user',
    required this.onboardingDone,
    required this.isCreator,
    this.locale = 'fr',
    required this.createdAt,
  });

  String get displayName =>
      username ?? (firstName != null ? '$firstName ${lastName ?? ''}' : '');

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        email: json['email'] as String?,
        role: json['role'] as String? ?? 'user',
        onboardingDone: (json['onboarding_done'] as bool?) ?? false,
        isCreator: (json['is_creator'] as bool?) ?? false,
        locale: json['locale'] as String? ?? 'fr',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  UserProfile copyWith({
    String? username,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
    bool? onboardingDone,
    bool? isCreator,
    String? locale,
  }) =>
      UserProfile(
        id: id,
        username: username ?? this.username,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        email: email,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        isCreator: isCreator ?? this.isCreator,
        locale: locale ?? this.locale,
        createdAt: createdAt,
      );
}

@immutable
class HealthProfile {
  final String userId;
  final DateTime? birthDate;
  final String? sex;
  final double? weightKg;
  final double? heightCm;
  final double? targetWeightKg;
  final String? activityLevel;
  final String? primaryGoal;
  final List<String> dietaryRestrictions;
  final List<String> cuisinePreferences;

  const HealthProfile({
    required this.userId,
    this.birthDate,
    this.sex,
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
        birthDate: json['birth_date'] != null
            ? DateTime.parse(json['birth_date'] as String)
            : null,
        sex: json['sex'] as String?,
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

  int? get age {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final hm = heightCm! / 100;
    return weightKg! / (hm * hm);
  }
}
