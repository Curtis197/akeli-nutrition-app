import 'package:akeli/core/logger.dart';
import 'package:flutter/foundation.dart';

final _logger = appLogger;

@immutable
class IngredientDetail {
  final String id;
  final String name;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final String? description;
  final String? imageUrl;
  final List<String> tags;

  const IngredientDetail({
    required this.id,
    required this.name,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.description,
    this.imageUrl,
    this.tags = const [],
  });

  factory IngredientDetail.fromJson(Map<String, dynamic> json) {
    _logger.db('IngredientDetail.fromJson | id: ${json['id']}');
    return IngredientDetail(
      id: json['id'] as String,
      name: json['name_fr'] as String? ?? json['name'] as String? ?? '',
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble(),
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble(),
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble(),
      description: json['description_fr'] as String?,
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
