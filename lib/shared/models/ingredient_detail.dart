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
  final double? fiberPer100g;
  final String? substitution;
  final String? marketNotes;

  const IngredientDetail({
    required this.id,
    required this.name,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.fiberPer100g,
    this.substitution,
    this.marketNotes,
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
      fiberPer100g: (json['fiber_per_100g'] as num?)?.toDouble(),
      substitution: json['substitution'] as String?,
      marketNotes: json['market_notes'] as String?,
    );
  }
}
