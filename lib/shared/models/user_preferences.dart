// lib/shared/models/user_preferences.dart

import 'package:akeli/core/logger.dart';
import 'package:akeli/features/settings/models/allergen_model.dart';

class UserPreferencesModel {
  final String? cookingTime;       // 'quick' | 'medium' | 'any' | null
  final bool batchCookingEnabled;
  final int batchMaxPortions;      // 2–7
  final String? cuisineRegion;     // region code or null
  final bool noPork;
  final bool noMeat;
  final bool noGluten;
  final bool noLactose;
  final List<AllergenModel> allergens;
  final bool useSavedRecipesOnly;
  final bool isSavedRecipeEligible;

  const UserPreferencesModel({
    this.cookingTime,
    this.batchCookingEnabled = false,
    this.batchMaxPortions = 4,
    this.cuisineRegion,
    this.noPork = false,
    this.noMeat = false,
    this.noGluten = false,
    this.noLactose = false,
    this.allergens = const [],
    this.useSavedRecipesOnly = false,
    this.isSavedRecipeEligible = false,
  });

  UserPreferencesModel copyWith({
    String? cookingTime,
    bool? batchCookingEnabled,
    int? batchMaxPortions,
    String? cuisineRegion,
    bool? noPork,
    bool? noMeat,
    bool? noGluten,
    bool? noLactose,
    List<AllergenModel>? allergens,
    bool? useSavedRecipesOnly,
    bool? isSavedRecipeEligible,
    bool clearCookingTime = false,
    bool clearCuisineRegion = false,
  }) {
    appLogger.d('UserPreferencesModel.copyWith | batchEnabled: ${batchCookingEnabled ?? this.batchCookingEnabled}');
    return UserPreferencesModel(
        cookingTime: clearCookingTime ? null : (cookingTime ?? this.cookingTime),
        batchCookingEnabled: batchCookingEnabled ?? this.batchCookingEnabled,
        batchMaxPortions: batchMaxPortions ?? this.batchMaxPortions,
        cuisineRegion: clearCuisineRegion ? null : (cuisineRegion ?? this.cuisineRegion),
        noPork: noPork ?? this.noPork,
        noMeat: noMeat ?? this.noMeat,
        noGluten: noGluten ?? this.noGluten,
        noLactose: noLactose ?? this.noLactose,
        allergens: allergens ?? this.allergens,
        useSavedRecipesOnly: useSavedRecipesOnly ?? this.useSavedRecipesOnly,
        isSavedRecipeEligible: isSavedRecipeEligible ?? this.isSavedRecipeEligible,
      );
  }
}
