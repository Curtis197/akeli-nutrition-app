import 'package:flutter/foundation.dart';

@immutable
class SavedRecipeProgressModel {
  final bool isEligible;
  final List<MealTypeProgress> progress;

  const SavedRecipeProgressModel({
    required this.isEligible,
    required this.progress,
  });

  factory SavedRecipeProgressModel.fromJson(Map<String, dynamic> json) {
    return SavedRecipeProgressModel(
      isEligible: json['is_eligible'] as bool? ?? false,
      progress: (json['progress'] as List<dynamic>?)
              ?.map((e) => MealTypeProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

@immutable
class MealTypeProgress {
  final String mealType;
  final int savedCount;
  final int targetCount;

  const MealTypeProgress({
    required this.mealType,
    required this.savedCount,
    required this.targetCount,
  });

  factory MealTypeProgress.fromJson(Map<String, dynamic> json) {
    return MealTypeProgress(
      mealType: json['meal_type'] as String,
      savedCount: json['saved_count'] as int? ?? 0,
      targetCount: json['target_count'] as int? ?? 7,
    );
  }
}
