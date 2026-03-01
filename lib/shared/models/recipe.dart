import 'package:flutter/foundation.dart';

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
  final int ratingCount;
  final int likeCount;
  final bool isLiked;
  final bool isPublished;
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
    required this.ratingCount,
    required this.likeCount,
    required this.isLiked,
    required this.isPublished,
    required this.ingredients,
    required this.steps,
    required this.tagIds,
    required this.createdAt,
  });

  int get totalTimeMin => prepTimeMin + cookTimeMin;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        creatorId: json['creator_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        imageUrls:
            (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
        prepTimeMin: (json['prep_time_min'] as int?) ?? 0,
        cookTimeMin: (json['cook_time_min'] as int?) ?? 0,
        servings: (json['servings'] as int?) ?? 1,
        difficulty: (json['difficulty'] as String?) ?? 'medium',
        regionId: json['food_region_id'] as String?,
        calories: (json['calories'] as num?)?.toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
        fiberG: (json['fiber_g'] as num?)?.toDouble(),
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: (json['rating_count'] as int?) ?? 0,
        likeCount: (json['like_count'] as int?) ?? 0,
        isLiked: (json['is_liked'] as bool?) ?? false,
        isPublished: (json['is_published'] as bool?) ?? true,
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

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        ingredientId: json['ingredient_id'] as String,
        name: json['ingredient_name'] as String? ?? json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        isOptional: (json['is_optional'] as bool?) ?? false,
      );
}

@immutable
class RecipeStep {
  final int stepNumber;
  final String instruction;
  final int? durationMin;
  final String? imageUrl;

  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.durationMin,
    this.imageUrl,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        stepNumber: json['step_number'] as int,
        instruction: json['instruction'] as String,
        durationMin: json['duration_min'] as int?,
        imageUrl: json['image_url'] as String?,
      );
}
