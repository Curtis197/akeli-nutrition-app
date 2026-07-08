import 'package:akeli/core/logger.dart';
import 'package:akeli/core/nutrition_input_bounds.dart';
import 'package:akeli/features/settings/models/allergen_model.dart';
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
  final List<AllergenModel> allergens;
  final List<String> cuisinePreferences;
  final String? weightGoal;   // 'loss' | 'maintenance' | 'gain'
  final String? muscleGoal;   // 'loss' | 'maintenance' | 'gain'
  final String? cookingTime;  // 'quick' | 'medium' | 'any'
  final bool batchCookingEnabled;
  final int batchMaxPortions;

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
    this.allergens = const [],
    this.cuisinePreferences = const [],
    this.weightGoal,
    this.muscleGoal,
    this.cookingTime,
    this.batchCookingEnabled = false,
    this.batchMaxPortions = 4,
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
    List<AllergenModel>? allergens,
    List<String>? cuisinePreferences,
    String? weightGoal,
    String? muscleGoal,
    String? cookingTime,
    bool? batchCookingEnabled,
    int? batchMaxPortions,
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
        allergens: allergens ?? this.allergens,
        cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
        weightGoal: weightGoal ?? this.weightGoal,
        muscleGoal: muscleGoal ?? this.muscleGoal,
        cookingTime: cookingTime ?? this.cookingTime,
        batchCookingEnabled: batchCookingEnabled ?? this.batchCookingEnabled,
        batchMaxPortions: batchMaxPortions ?? this.batchMaxPortions,
      );
}

class OnboardingNotifier extends Notifier<OnboardingData> {
  final _logger = appLogger;

  @override
  OnboardingData build() {
    _logger.provider('OnboardingNotifier build()');
    return const OnboardingData();
  }

  void updateLanguage(String v) {
    _logger.provider('OnboardingNotifier → updateLanguage | $v');
    state = state.copyWith(language: v);
  }

  void updateConsent({bool? privacy, bool? cgu}) {
    _logger.provider('OnboardingNotifier → updateConsent | privacy: $privacy | cgu: $cgu');
    state = state.copyWith(consentPrivacy: privacy, consentCgu: cgu);
  }

  void updateProfile({
    String? name,
    int? age,
    String? sex,
    double? weight,
    double? height,
    String? activityLevel,
  }) {
    _logger.provider('OnboardingNotifier → updateProfile | name: $name | sex: $sex');
    state = state.copyWith(
        name: name,
        age: age,
        sex: sex,
        weight: weight,
        height: height,
        activityLevel: activityLevel);
  }

  void updateGoals({
    double? targetWeight,
    int? timelineMonths,
    String? motivations,
    String? weightGoal,
    String? muscleGoal,
    String? cookingTime,
    bool? batchCookingEnabled,
    int? batchMaxPortions,
  }) {
    _logger.provider('OnboardingNotifier → updateGoals | cookingTime: $cookingTime | batchEnabled: $batchCookingEnabled | batchMax: $batchMaxPortions');
    state = state.copyWith(
        targetWeight: targetWeight,
        timelineMonths: timelineMonths,
        motivations: motivations,
        weightGoal: weightGoal,
        muscleGoal: muscleGoal,
        cookingTime: cookingTime,
        batchCookingEnabled: batchCookingEnabled,
        batchMaxPortions: batchMaxPortions);
  }

  void updatePreferences({
    bool? noPork,
    bool? noMeat,
    bool? noGluten,
    bool? noLactose,
    List<AllergenModel>? allergens,
    List<String>? cuisinePreferences,
  }) {
    _logger.provider('OnboardingNotifier → updatePreferences | noPork: $noPork | noMeat: $noMeat | noGluten: $noGluten | noLactose: $noLactose');
    state = state.copyWith(
        noPork: noPork,
        noMeat: noMeat,
        noGluten: noGluten,
        noLactose: noLactose,
        allergens: allergens,
        cuisinePreferences: cuisinePreferences);
  }

  void updateCuisineRegion(String code) {
    final current = state.cuisinePreferences;
    _logger.provider('OnboardingNotifier → updateCuisineRegion | code: $code');
    state = state.copyWith(
      cuisinePreferences: current.length == 1 && current[0] == code ? [] : [code],
    );
  }

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
        allergens: state.allergens,
        cuisinePreferences: state.cuisinePreferences,
        weightGoal: state.weightGoal,
        muscleGoal: state.muscleGoal,
        cookingTime: state.cookingTime,
        batchCookingEnabled: state.batchCookingEnabled,
        batchMaxPortions: state.batchMaxPortions,
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
        allergens: state.allergens,
        cuisinePreferences: state.cuisinePreferences,
        weightGoal: state.weightGoal,
        muscleGoal: state.muscleGoal,
        cookingTime: state.cookingTime,
        batchCookingEnabled: state.batchCookingEnabled,
        batchMaxPortions: state.batchMaxPortions,
      );

  /// Returns true if the user may advance from the given step index (0-based).
  bool canAdvance(int stepIndex) {
    switch (stepIndex) {
      case 0: // Language — always valid
        return true;
      case 1: // Consent — both boxes required
        return state.consentPrivacy && state.consentCgu;
      case 2: // Profile — name, age, weight, height required and within bounds
        if (state.name.trim().isEmpty) return false;
        if (state.age == null || state.age! < NutritionInputBounds.minAge || state.age! > NutritionInputBounds.maxAge) {
          return false;
        }
        if (state.weight == null || state.weight! < NutritionInputBounds.minWeightKg || state.weight! > NutritionInputBounds.maxWeightKg) {
          return false;
        }
        if (state.height == null || state.height! < NutritionInputBounds.minHeightCm || state.height! > NutritionInputBounds.maxHeightCm) {
          return false;
        }
        return true;
      case 3: // Goals — weight goal required, targetWeight required and within bounds
        if (state.weightGoal == null) return false;
        if (state.targetWeight == null || state.targetWeight! < NutritionInputBounds.minWeightKg || state.targetWeight! > NutritionInputBounds.maxWeightKg) {
          return false;
        }
        if (state.timelineMonths < 1 || state.timelineMonths > 12) {
          return false;
        }
        return true;
      case 4: // Preferences — no hard requirement
        return true;
      case 5: // NutritionPlanPage — already validated via savePlan
        return true;
      case 6: // MealScheduleOnboardingStep — already validated via onCompleted/onSkipped
        return true;
      case 7: // Summary — always valid
        return true;
      default:
        return false;
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingData>(
        OnboardingNotifier.new);
