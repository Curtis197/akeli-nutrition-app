import 'package:akeli/core/logger.dart';
import 'package:flutter/foundation.dart';

final _logger = appLogger;

@immutable
class IngredientDetail {
  final String id;
  final String name; // French name as primary (ingredientName style)
  final String? nameEn; // English name
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final String? description;
  final String? descriptionEn;
  final String? imageUrl;
  final List<String> tags;
  final double? pricePer100g;
  final String? currency;

  const IngredientDetail({
    required this.id,
    required this.name,
    this.nameEn,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.description,
    this.descriptionEn,
    this.imageUrl,
    this.tags = const [],
    this.pricePer100g,
    this.currency,
  });

  String localizedName(String locale) {
    return (locale == 'en' ? nameEn : null) ?? name;
  }

  String? localizedDescription(String locale) {
    return (locale == 'en' ? descriptionEn : null) ?? description;
  }

  String get priceDisplay {
    if (pricePer100g == null) return '';
    final symbol = switch (currency) {
      'GBP' => '£',
      'CAD' => 'CA\$',
      'USD' => '\$',
      'EUR' => '€',
      _ => '€',
    };
    final formatted = currency == 'EUR' || currency == null
        ? pricePer100g!.toStringAsFixed(2).replaceAll('.', ',')
        : pricePer100g!.toStringAsFixed(2);
    return currency == 'EUR' || currency == null
        ? '$formatted €/100g'
        : '$symbol$formatted/100g';
  }

  factory IngredientDetail.fromJson(Map<String, dynamic> json) {
    _logger.db('IngredientDetail.fromJson | id: ${json['id']}');
    final priceList = json['ingredient_market_price'] as List<dynamic>?;
    final priceMap = priceList != null && priceList.isNotEmpty ? priceList.first : null;
    return IngredientDetail(
      id: json['id'] as String,
      name: json['name_fr'] as String? ?? json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['name'] as String?,
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble(),
      proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble(),
      fatPer100g: (json['fat_per_100g'] as num?)?.toDouble(),
      description: json['description_fr'] as String?,
      descriptionEn: json['description_en'] as String?,
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      pricePer100g: (priceMap?['price_per_100g'] as num?)?.toDouble(),
      currency: priceMap?['currency'] as String?,
    );
  }
}
