import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingData {
  final String language;
  final bool consentPrivacy;
  final bool consentCgu;
  final String name;
  final int? age;
  final String? sex; // 'male' | 'female'
  final double? weight;
  final double? height;
  final String? activityLevel;
  final double? targetWeight;
  final int timelineMonths;
  final String motivations;
  final bool noPork;
  final bool noMeat;
  final bool noGluten;
  final bool noLactose;
  final List<String> allergies;
  final List<String> cuisinePreferences;

  const OnboardingData({
    this.language = 'fr',
    this.consentPrivacy = false,
    this.consentCgu = false,
    this.name = '',
    this.age,
    this.sex,
    this.weight,
    this.height,
    this.activityLevel,
    this.targetWeight,
    this.timelineMonths = 6,
    this.motivations = '',
    this.noPork = false,
    this.noMeat = false,
    this.noGluten = false,
    this.noLactose = false,
    this.allergies = const [],
    this.cuisinePreferences = const [],
  });

  OnboardingData copyWith({
    String? language,
    bool? consentPrivacy,
    bool? consentCgu,
    String? name,
    int? age,
    String? sex,
    double? weight,
    double? height,
    String? activityLevel,
    double? targetWeight,
    int? timelineMonths,
    String? motivations,
    bool? noPork,
    bool? noMeat,
    bool? noGluten,
    bool? noLactose,
    List<String>? allergies,
    List<String>? cuisinePreferences,
  }) =>
      OnboardingData(
        language: language ?? this.language,
        consentPrivacy: consentPrivacy ?? this.consentPrivacy,
        consentCgu: consentCgu ?? this.consentCgu,
        name: name ?? this.name,
        age: age ?? this.age,
        sex: sex ?? this.sex,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        activityLevel: activityLevel ?? this.activityLevel,
        targetWeight: targetWeight ?? this.targetWeight,
        timelineMonths: timelineMonths ?? this.timelineMonths,
        motivations: motivations ?? this.motivations,
        noPork: noPork ?? this.noPork,
        noMeat: noMeat ?? this.noMeat,
        noGluten: noGluten ?? this.noGluten,
        noLactose: noLactose ?? this.noLactose,
        allergies: allergies ?? this.allergies,
        cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      );
}

class OnboardingNotifier extends Notifier<OnboardingData> {
  @override
  OnboardingData build() => const OnboardingData();

  void updateLanguage(String v) =>
      state = state.copyWith(language: v);

  void updateConsent({bool? privacy, bool? cgu}) =>
      state = state.copyWith(
          consentPrivacy: privacy, consentCgu: cgu);

  void updateProfile({
    String? name,
    int? age,
    String? sex,
    double? weight,
    double? height,
    String? activityLevel,
  }) =>
      state = state.copyWith(
          name: name,
          age: age,
          sex: sex,
          weight: weight,
          height: height,
          activityLevel: activityLevel);

  void updateGoals({
    double? targetWeight,
    int? timelineMonths,
    String? motivations,
  }) =>
      state = state.copyWith(
          targetWeight: targetWeight,
          timelineMonths: timelineMonths,
          motivations: motivations);

  void updatePreferences({
    bool? noPork,
    bool? noMeat,
    bool? noGluten,
    bool? noLactose,
    List<String>? allergies,
    List<String>? cuisinePreferences,
  }) =>
      state = state.copyWith(
          noPork: noPork,
          noMeat: noMeat,
          noGluten: noGluten,
          noLactose: noLactose,
          allergies: allergies,
          cuisinePreferences: cuisinePreferences);

  // copyWith uses ?? so it can't clear nullable fields to null.
  // Use these explicit reset methods when the user removes a previously set value.
  void clearProfile() => state = OnboardingData(
        language: state.language,
        consentPrivacy: state.consentPrivacy,
        consentCgu: state.consentCgu,
        timelineMonths: state.timelineMonths,
        motivations: state.motivations,
        noPork: state.noPork,
        noMeat: state.noMeat,
        noGluten: state.noGluten,
        noLactose: state.noLactose,
        allergies: state.allergies,
        cuisinePreferences: state.cuisinePreferences,
      );

  void clearTargetWeight() => state = OnboardingData(
        language: state.language,
        consentPrivacy: state.consentPrivacy,
        consentCgu: state.consentCgu,
        name: state.name,
        age: state.age,
        sex: state.sex,
        weight: state.weight,
        height: state.height,
        activityLevel: state.activityLevel,
        timelineMonths: state.timelineMonths,
        motivations: state.motivations,
        noPork: state.noPork,
        noMeat: state.noMeat,
        noGluten: state.noGluten,
        noLactose: state.noLactose,
        allergies: state.allergies,
        cuisinePreferences: state.cuisinePreferences,
      );

  /// Returns true if the user may advance from the given step index (0-based).
  bool canAdvance(int stepIndex) {
    switch (stepIndex) {
      case 0: // Language — always valid
        return true;
      case 1: // Consent — both boxes required
        return state.consentPrivacy && state.consentCgu;
      case 2: // Profile — name required
        return state.name.trim().isNotEmpty;
      case 3: // Goals — target weight required
        return state.targetWeight != null;
      case 4: // Preferences — no hard requirement
        return true;
      case 5: // Summary — always valid
        return true;
      default:
        return false;
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingData>(
        OnboardingNotifier.new);
