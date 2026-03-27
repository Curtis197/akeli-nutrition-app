import 'package:flutter/foundation.dart';

@immutable
class MealPlan {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<MealPlanEntry> entries;

  const MealPlan({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.entries,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        isActive: (json['is_active'] as bool?) ?? true,
        entries: (json['entries'] as List<dynamic>?)
                ?.map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  List<MealPlanEntry> entriesForDate(DateTime date) => entries
      .where((e) =>
          e.scheduledDate.year == date.year &&
          e.scheduledDate.month == date.month &&
          e.scheduledDate.day == date.day)
      .toList();

  Map<DateTime, List<MealPlanEntry>> get entriesByDay {
    final map = <DateTime, List<MealPlanEntry>>{};
    for (final entry in entries) {
      final day = DateTime(
        entry.scheduledDate.year,
        entry.scheduledDate.month,
        entry.scheduledDate.day,
      );
      map.putIfAbsent(day, () => []).add(entry);
    }
    return map;
  }
}

@immutable
class MealPlanEntry {
  final String id;
  final String mealPlanId;
  final String recipeId;
  final String? recipeTitle;
  final String? recipeThumbnail;
  final String mealType; // breakfast / lunch / dinner / snack
  final DateTime scheduledDate;
  final bool isConsumed;
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  const MealPlanEntry({
    required this.id,
    required this.mealPlanId,
    required this.recipeId,
    this.recipeTitle,
    this.recipeThumbnail,
    required this.mealType,
    required this.scheduledDate,
    required this.isConsumed,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as String,
        mealPlanId: json['meal_plan_id'] as String,
        recipeId: json['recipe_id'] as String,
        recipeTitle: json['recipe_title'] as String?,
        recipeThumbnail: json['recipe_thumbnail'] as String?,
        mealType: json['meal_type'] as String,
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        isConsumed: (json['is_consumed'] as bool?) ?? false,
        calories: (json['calories'] as num?)?.toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
      );

  String get mealTypeLabel {
    switch (mealType) {
      case 'breakfast':
        return 'Petit-déjeuner';
      case 'lunch':
        return 'Déjeuner';
      case 'dinner':
        return 'Dîner';
      case 'snack':
        return 'Collation';
      default:
        return mealType;
    }
  }
}

@immutable
class ShoppingItem {
  final String ingredientId;
  final String name;
  final double quantity;
  final String unit;
  final String? category;
  final bool isChecked;

  const ShoppingItem({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.category,
    required this.isChecked,
  });

  String get quantityDisplay => '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} $unit';

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        ingredientId: json['ingredient_id'] as String,
        name: json['ingredient_name'] as String,
        quantity: (json['total_quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        category: json['category'] as String?,
        isChecked: (json['is_checked'] as bool?) ?? false,
      );

  ShoppingItem copyWith({bool? isChecked}) => ShoppingItem(
        ingredientId: ingredientId,
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        isChecked: isChecked ?? this.isChecked,
      );
}
