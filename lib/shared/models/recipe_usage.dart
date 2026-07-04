import 'package:akeli/core/logger.dart';
import 'package:flutter/foundation.dart';

@immutable
class RecipeUsage {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final int prepTimeMin;
  final int cookTimeMin;

  const RecipeUsage({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.prepTimeMin,
    required this.cookTimeMin,
  });

  factory RecipeUsage.fromJson(Map<String, dynamic> json) {
    appLogger.db('RecipeUsage.fromJson | recipeId: ${json['recipe_id']}');
    return RecipeUsage(
      id: json['recipe_id'] as String,
      title: json['title'] as String? ?? '',
      thumbnailUrl: json['cover_image_url'] as String?,
      prepTimeMin: (json['prep_time_min'] as num?)?.toInt() ?? 0,
      cookTimeMin: (json['cook_time_min'] as num?)?.toInt() ?? 0,
    );
  }
}
