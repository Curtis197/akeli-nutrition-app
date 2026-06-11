import 'package:flutter/foundation.dart';
import 'package:akeli/core/logger.dart';

@immutable
class Recipe {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final List<String> imageUrls;
  final int prepTimeMin;
  final int cookTimeMin;
  final int servings;
  final String difficulty; // easy / medium / hard
  final String? regionId;
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double averageRating;
  final double averageRatingTaste;
  final double averageRatingEase;
  final double averageRatingSatiety;
  final int ratingCount;
  final int commentCount;
  final int likeCount;
  final int saveCount;
  final bool isSaved;
  final bool isLiked;
  final bool isPublished;
  final String? videoUrl;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> tagIds;
  final DateTime createdAt;

  const Recipe({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.imageUrls,
    required this.prepTimeMin,
    required this.cookTimeMin,
    required this.servings,
    required this.difficulty,
    this.regionId,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    required this.averageRating,
    required this.averageRatingTaste,
    required this.averageRatingEase,
    required this.averageRatingSatiety,
    required this.ratingCount,
    required this.commentCount,
    required this.likeCount,
    required this.saveCount,
    required this.isSaved,
    required this.isLiked,
    required this.isPublished,
    this.videoUrl,
    required this.ingredients,
    required this.steps,
    required this.tagIds,
    required this.createdAt,
  });

  int get totalTimeMin => prepTimeMin + cookTimeMin;

  // Per-serving helpers (for card display — normalises across different portion sizes)
  double? get caloriesPerServing => servings > 0 && calories != null ? calories! / servings : calories;
  double? get proteinPerServing  => servings > 0 && proteinG  != null ? proteinG!  / servings : proteinG;
  double? get carbsPerServing    => servings > 0 && carbsG    != null ? carbsG!    / servings : carbsG;
  double? get fatPerServing      => servings > 0 && fatG      != null ? fatG!      / servings : fatG;

  // Total ingredient weight in grams (g + ml units only, best-effort).
  double get totalWeightG => ingredients
      .where((i) => i.unit == 'g' || i.unit == 'ml')
      .fold(0.0, (s, i) => s + i.quantity);

  // Per-100g helpers — only meaningful when ingredients are loaded.
  double? get calories100g {
    final w = totalWeightG;
    return (w > 0 && calories != null) ? calories! / w * 100 : null;
  }

  double? get protein100g {
    final w = totalWeightG;
    return (w > 0 && proteinG != null) ? proteinG! / w * 100 : null;
  }

  double? get carbs100g {
    final w = totalWeightG;
    return (w > 0 && carbsG != null) ? carbsG! / w * 100 : null;
  }

  double? get fat100g {
    final w = totalWeightG;
    return (w > 0 && fatG != null) ? fatG! / w * 100 : null;
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    appLogger.db('Recipe.fromJson | id: ${json['id']}');
    final macro = json['recipe_macro'] as Map<String, dynamic>?;
    return Recipe(
        id: json['id'] as String,
        creatorId: json['creator_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        thumbnailUrl: json['cover_image_url'] as String?,
        imageUrls: (json['recipe_image'] as List<dynamic>?)
                ?.map((e) => e['url'] as String)
                .toList() ??
            [],
        prepTimeMin: (json['prep_time_min'] as int?) ?? 0,
        cookTimeMin: (json['cook_time_min'] as int?) ?? 0,
        servings: (json['servings'] as int?) ?? 1,
        difficulty: (json['difficulty'] as String?) ?? 'medium',
        regionId: json['region'] as String?,
        calories: (json['calories'] as num?)?.toDouble() ?? (macro?['calories'] as num?)?.toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? (macro?['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? (macro?['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble() ?? (macro?['fat_g'] as num?)?.toDouble(),
        fiberG: (json['fiber_g'] as num?)?.toDouble() ?? (macro?['fiber_g'] as num?)?.toDouble(),
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
        averageRatingTaste: (json['average_rating_taste'] as num?)?.toDouble() ?? 0.0,
        averageRatingEase: (json['average_rating_ease'] as num?)?.toDouble() ?? 0.0,
        averageRatingSatiety: (json['average_rating_satiety'] as num?)?.toDouble() ?? 0.0,
        ratingCount: (json['rating_count'] as int?) ?? 0,
        commentCount: (json['comment_count'] as int?) ?? 0,
        likeCount: (json['like_count'] as int?) ?? 0,
        saveCount: (json['save_count'] as int?) ?? 0,
        isSaved: (json['is_saved'] as bool?) ?? ((json['recipe_save'] as List<dynamic>?)?.isNotEmpty ?? false),
        isLiked: (json['is_liked'] as bool?) ?? ((json['recipe_like'] as List<dynamic>?)?.isNotEmpty ?? false),
        isPublished: (json['is_published'] as bool?) ?? true,
        videoUrl: json['video_url'] as String?,
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.map((e) =>
                    RecipeIngredient.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        steps: (json['steps'] as List<dynamic>?)
                ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        tagIds: (json['tag_ids'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  }
}

@immutable
class RecipeIngredient {
  final String ingredientId;
  final String name;
  final double quantity;
  final String unit;
  final bool isOptional;

  const RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isOptional,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    final nested = json['ingredient'] as Map<String, dynamic>?;
    final name = json['ingredient_name'] as String?
        ?? nested?['name_fr'] as String?
        ?? nested?['name'] as String?
        ?? '';
    return RecipeIngredient(
      ingredientId: json['ingredient_id'] as String? ?? '',
      name: name,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      isOptional: (json['is_optional'] as bool?) ?? false,
    );
  }
}

@immutable
class RecipeStep {
  final int stepNumber;
  final String instruction;
  final int? durationMin;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> ingredientIds;
  final bool isSectionHeader;
  final String? sectionTitle;

  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.durationMin,
    this.imageUrl,
    this.videoUrl,
    this.ingredientIds = const [],
    this.isSectionHeader = false,
    this.sectionTitle,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        stepNumber: json['step_number'] as int,
        instruction: json['instruction'] as String?
            ?? json['content'] as String? ?? '',
        durationMin: json['duration_min'] as int?
            ?? ((json['timer_seconds'] as int?) != null
                ? ((json['timer_seconds'] as int) / 60).round()
                : null),
        imageUrl: json['image_url'] as String?,
        videoUrl: json['video_url'] as String?,
        ingredientIds: (json['ingredient_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        isSectionHeader: json['is_section_header'] as bool? ?? false,
        sectionTitle: json['title'] as String?,
      );
}
