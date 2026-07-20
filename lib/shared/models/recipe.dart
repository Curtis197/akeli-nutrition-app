import 'package:flutter/foundation.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/quantity_formatter.dart';

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
  final List<String> mealTypes;
  final double? calories100g;
  final double? protein100g;
  final double? carbs100g;
  final double? fat100g;
  final double? estimatedCostPer100g;
  final String? mode;
  final String? beautyType;
  final String? beautySubType;
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
    this.mealTypes = const [],
    this.calories100g,
    this.protein100g,
    this.carbs100g,
    this.fat100g,
    this.estimatedCostPer100g,
    this.costCurrency,
    this.mode,
    this.beautyType,
    this.beautySubType,
    required this.createdAt,
  });

  int get totalTimeMin => prepTimeMin + cookTimeMin;

  String get priceTier {
    if (estimatedCostPer100g == null || estimatedCostPer100g! <= 0) return '';
    if (estimatedCostPer100g! < 0.30) return '\$';
    if (estimatedCostPer100g! < 0.60) return '\$\$';
    return '\$\$\$';
  }

  String get pricePer100gDisplay {
    if (estimatedCostPer100g == null) return '';
    final symbol = switch (costCurrency) {
      'GBP' => '£',
      'CAD' => 'CA\$',
      'USD' => '\$',
      'EUR' => '€',
      _ => '€',
    };
    if (costCurrency == 'EUR' || costCurrency == null) {
      final formatted = estimatedCostPer100g!.toStringAsFixed(2).replaceAll('.', ',');
      return '$formatted €/100g';
    } else {
      final formatted = estimatedCostPer100g!.toStringAsFixed(2);
      return '$symbol$formatted/100g';
    }
  }

  // Per-serving helpers (for card display — normalises across different portion sizes)
  double? get caloriesPerServing => servings > 0 && calories != null ? calories! / servings : calories;
  double? get proteinPerServing  => servings > 0 && proteinG  != null ? proteinG!  / servings : proteinG;
  double? get carbsPerServing    => servings > 0 && carbsG    != null ? carbsG!    / servings : carbsG;
  double? get fatPerServing      => servings > 0 && fatG      != null ? fatG!      / servings : fatG;

  Recipe copyWith({
    String? title,
    String? description,
    List<RecipeIngredient>? ingredients,
    List<RecipeStep>? steps,
    double? estimatedCostPer100g,
    String? costCurrency,
  }) {
    return Recipe(
      id: id,
      creatorId: creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl,
      imageUrls: imageUrls,
      prepTimeMin: prepTimeMin,
      cookTimeMin: cookTimeMin,
      servings: servings,
      difficulty: difficulty,
      regionId: regionId,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      fiberG: fiberG,
      averageRating: averageRating,
      averageRatingTaste: averageRatingTaste,
      averageRatingEase: averageRatingEase,
      averageRatingSatiety: averageRatingSatiety,
      ratingCount: ratingCount,
      commentCount: commentCount,
      likeCount: likeCount,
      saveCount: saveCount,
      isSaved: isSaved,
      isLiked: isLiked,
      isPublished: isPublished,
      videoUrl: videoUrl,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      tagIds: tagIds,
      mealTypes: mealTypes,
      calories100g: calories100g,
      protein100g: protein100g,
      carbs100g: carbs100g,
      fat100g: fat100g,
      estimatedCostPer100g: estimatedCostPer100g ?? this.estimatedCostPer100g,
      costCurrency: costCurrency ?? this.costCurrency,
      createdAt: createdAt,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    appLogger.db('Recipe.fromJson | id: ${json['id']}');
    final macroRaw = json['recipe_macro'];
    final macro = macroRaw is Map<String, dynamic>
        ? macroRaw
        : (macroRaw is List<dynamic> && macroRaw.isNotEmpty)
            ? macroRaw.first as Map<String, dynamic>
            : null;
    final costRaw = json['recipe_market_cost'] ?? json['recipe_cost'];
    final cost = costRaw is Map<String, dynamic>
        ? costRaw
        : (costRaw is List<dynamic> && costRaw.isNotEmpty)
            ? costRaw.first as Map<String, dynamic>
            : null;
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
        mealTypes: (json['meal_types'] as List<dynamic>?)?.cast<String>() ?? [],
        calories100g: (macro?['calories_per_100g'] as num?)?.toDouble(),
        protein100g:  (macro?['protein_per_100g']  as num?)?.toDouble(),
        carbs100g:    (macro?['carbs_per_100g']    as num?)?.toDouble(),
        fat100g:      (macro?['fat_per_100g']      as num?)?.toDouble(),
        estimatedCostPer100g: (cost?['cost_per_100g'] as num?)?.toDouble() ?? (cost?['estimated_cost_per_100g'] as num?)?.toDouble(),
        costCurrency: (cost?['currency'] as String?) ?? (cost?['country_code'] != null ? switch (cost?['country_code'] as String) {
          'FR' || 'SN' || 'CI' || 'CM' || 'GA' => 'EUR',
          'GB' => 'GBP',
          'CA' => 'CAD',
          _ => 'USD',
        } : 'EUR'),
        mode: json['mode'] as String?,
        beautyType: json['beauty_type'] as String?,
        beautySubType: json['beauty_sub_type'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
  }
}

@immutable
class RecipeIngredient {
  final String id;
  final String ingredientId;
  final String name;
  final String? nameEn;
  final double quantity;
  final String unit;
  final bool isOptional;
  final bool isSectionHeader;
  final String? sectionTitle;

  const RecipeIngredient({
    required this.id,
    required this.ingredientId,
    required this.name,
    this.nameEn,
    required this.quantity,
    required this.unit,
    required this.isOptional,
    this.isSectionHeader = false,
    this.sectionTitle,
  });

  RecipeIngredient copyWith({String? name, String? sectionTitle}) {
    return RecipeIngredient(
      id: id,
      ingredientId: ingredientId,
      name: name ?? this.name,
      nameEn: nameEn,
      quantity: quantity,
      unit: unit,
      isOptional: isOptional,
      isSectionHeader: isSectionHeader,
      sectionTitle: sectionTitle ?? this.sectionTitle,
    );
  }

  String get quantityDisplay => formatQuantity(quantity, unit);

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    final nested = json['ingredient'] as Map<String, dynamic>?;
    final name = json['ingredient_name'] as String?
        ?? nested?['name_fr'] as String?
        ?? nested?['name'] as String?
        ?? '';
    return RecipeIngredient(
      id: json['id'] as String? ?? '',
      ingredientId: json['ingredient_id'] as String? ?? '',
      name: name,
      nameEn: nested?['name_en'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      isOptional: (json['is_optional'] as bool?) ?? false,
      isSectionHeader: (json['is_section_header'] as bool?) ?? false,
      sectionTitle: json['title'] as String?,
    );
  }
}

@immutable
class RecipeStep {
  final String id;
  final int stepNumber;
  final String instruction;
  final int? durationMin;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> ingredientIds;
  final bool isSectionHeader;
  final String? sectionTitle;

  const RecipeStep({
    required this.id,
    required this.stepNumber,
    required this.instruction,
    this.durationMin,
    this.imageUrl,
    this.videoUrl,
    this.ingredientIds = const [],
    this.isSectionHeader = false,
    this.sectionTitle,
  });

  RecipeStep copyWith({String? instruction, String? sectionTitle}) {
    return RecipeStep(
      id: id,
      stepNumber: stepNumber,
      instruction: instruction ?? this.instruction,
      durationMin: durationMin,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      ingredientIds: ingredientIds,
      isSectionHeader: isSectionHeader,
      sectionTitle: sectionTitle ?? this.sectionTitle,
    );
  }

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        id: json['id'] as String? ?? '',
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
