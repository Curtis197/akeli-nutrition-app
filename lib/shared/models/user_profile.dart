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
  final bool isPrivate;
  final String locale; // fr | en | ...
  final DateTime createdAt;
  final DateTime? consentPrivacyAt;
  final DateTime? consentCguAt;
  final bool hasDismissedMealScheduleHint;
  final int mealVarietyDays; // 0 | 7 | 15
  final bool mealScheduleRandom;
  final double? weeklyBudget;
  final String budgetCurrency;
  final String countryCode;

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
    this.isPrivate = false,
    this.locale = 'fr',
    required this.createdAt,
    this.consentPrivacyAt,
    this.consentCguAt,
    this.hasDismissedMealScheduleHint = false,
    this.mealVarietyDays = 7,
    this.mealScheduleRandom = false,
    this.weeklyBudget,
    this.budgetCurrency = 'EUR',
    this.countryCode = 'FR',
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
        isPrivate: (json['is_private'] as bool?) ?? false,
        locale: json['locale'] as String? ?? 'fr',
        createdAt: DateTime.parse(json['created_at'] as String),
        consentPrivacyAt: json['consent_privacy_at'] != null
             ? DateTime.parse(json['consent_privacy_at'] as String)
             : null,
        consentCguAt: json['consent_cgu_at'] != null
             ? DateTime.parse(json['consent_cgu_at'] as String)
             : null,
        hasDismissedMealScheduleHint:
            (json['has_dismissed_meal_schedule_hint'] as bool?) ?? false,
        mealVarietyDays:
            (json['meal_variety_days'] as int?) ?? 7,
        mealScheduleRandom:
            (json['meal_schedule_random'] as bool?) ?? false,
        weeklyBudget: (json['weekly_budget'] as num?)?.toDouble(),
        budgetCurrency: json['budget_currency'] as String? ?? 'EUR',
        countryCode: json['country_code'] as String? ?? 'FR',
      );

  UserProfile copyWith({
    String? username,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
    bool? onboardingDone,
    bool? isCreator,
    bool? isPrivate,
    String? locale,
    bool? hasDismissedMealScheduleHint,
    int? mealVarietyDays,
    bool? mealScheduleRandom,
    double? weeklyBudget,
    String? budgetCurrency,
    String? countryCode,
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
        isPrivate: isPrivate ?? this.isPrivate,
        locale: locale ?? this.locale,
        createdAt: createdAt,
        hasDismissedMealScheduleHint: hasDismissedMealScheduleHint ?? this.hasDismissedMealScheduleHint,
        mealVarietyDays: mealVarietyDays ?? this.mealVarietyDays,
        mealScheduleRandom: mealScheduleRandom ?? this.mealScheduleRandom,
        weeklyBudget: weeklyBudget ?? this.weeklyBudget,
        budgetCurrency: budgetCurrency ?? this.budgetCurrency,
        countryCode: countryCode ?? this.countryCode,
      );
}

@immutable
class HealthProfile {
  final String userId;
  final DateTime? birthDate;
  final String? sex;
  final double? weightKg;
  final double? startingWeightKg;
  final double? heightCm;
  final double? targetWeightKg;
  final DateTime? targetDate;
  final String? activityLevel;
  final String? primaryGoal;
  final List<String> dietaryRestrictions;
  final List<String> cuisinePreferences;

  const HealthProfile({
    required this.userId,
    this.birthDate,
    this.sex,
    this.weightKg,
    this.startingWeightKg,
    this.heightCm,
    this.targetWeightKg,
    this.targetDate,
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
        startingWeightKg: (json['starting_weight_kg'] as num?)?.toDouble(),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
        targetDate: json['target_date'] != null
            ? DateTime.parse(json['target_date'] as String)
            : null,
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
