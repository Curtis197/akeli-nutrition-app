import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// MealPlan
// ---------------------------------------------------------------------------

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
        entries: (json['meal_plan_entry'] as List<dynamic>?)
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

// ---------------------------------------------------------------------------
// MealPlanEntry
// A meal slot. Macros and display data are derived from its components.
// ---------------------------------------------------------------------------

@immutable
class MealPlanEntry {
  final String id;
  final String mealPlanId;
  final String mealType;
  final DateTime scheduledDate;
  final bool isConsumed;
  final List<MealPlanEntryComponent> components;

  const MealPlanEntry({
    required this.id,
    required this.mealPlanId,
    required this.mealType,
    required this.scheduledDate,
    required this.isConsumed,
    required this.components,
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as String,
        mealPlanId: json['meal_plan_id'] as String,
        mealType: json['meal_type'] as String,
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        isConsumed: (json['is_consumed'] as bool?) ?? false,
        components: (json['meal_plan_entry_component'] as List<dynamic>?)
                ?.map((e) =>
                    MealPlanEntryComponent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  // Display helpers — derived from the base component (first with role='base').
  MealPlanEntryComponent? get _base =>
      components.where((c) => c.role == 'base').firstOrNull ??
      components.firstOrNull;

  String? get recipeTitle => _base?.recipeTitle;
  String? get recipeThumbnail => _base?.recipeThumbnail;

  // Total macros across all components.
  double get calories =>
      components.fold(0.0, (s, c) => s + (c.calories ?? 0.0));
  double get proteinG =>
      components.fold(0.0, (s, c) => s + (c.proteinG ?? 0.0));
  double get carbsG => components.fold(0.0, (s, c) => s + (c.carbsG ?? 0.0));
  double get fatG => components.fold(0.0, (s, c) => s + (c.fatG ?? 0.0));

  // Convenience accessor — recipe ID of the base component.
  String? get recipeId => _base?.recipeId;

  bool get isModular => components.length > 1;

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

// ---------------------------------------------------------------------------
// MealPlanEntryComponent
// One recipe within a meal slot (base / starch / side).
// ---------------------------------------------------------------------------

@immutable
class MealPlanEntryComponent {
  final String id;
  final String mealPlanEntryId;
  final String recipeId;
  final String? recipeTitle;
  final String? recipeThumbnail;
  final String role; // 'base' | 'starch' | 'side'
  final double consumptionWeight; // 1/N — for revenue computation
  final String? cookingSessionId;
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  const MealPlanEntryComponent({
    required this.id,
    required this.mealPlanEntryId,
    required this.recipeId,
    this.recipeTitle,
    this.recipeThumbnail,
    required this.role,
    required this.consumptionWeight,
    this.cookingSessionId,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  factory MealPlanEntryComponent.fromJson(Map<String, dynamic> json) {
    final recipe = json['recipe'] as Map<String, dynamic>?;
    // recipe_macro is a one-to-one relationship (recipe_id is PK of recipe_macro).
    // PostgREST may return it as a Map or as a List with one item.
    final macroRaw = recipe?['recipe_macro'];
    final macro = macroRaw is Map<String, dynamic>
        ? macroRaw
        : (macroRaw is List && macroRaw.isNotEmpty)
            ? macroRaw.first as Map<String, dynamic>
            : null;

    return MealPlanEntryComponent(
      id: json['id'] as String,
      mealPlanEntryId: json['meal_plan_entry_id'] as String,
      recipeId: json['recipe_id'] as String,
      recipeTitle: recipe?['title'] as String?,
      recipeThumbnail: recipe?['cover_image_url'] as String?,
      role: json['role'] as String,
      consumptionWeight:
          (json['consumption_weight'] as num?)?.toDouble() ?? 1.0,
      cookingSessionId: json['cooking_session_id'] as String?,
      calories: (macro?['calories'] as num?)?.toDouble(),
      proteinG: (macro?['protein_g'] as num?)?.toDouble(),
      carbsG: (macro?['carbs_g'] as num?)?.toDouble(),
      fatG: (macro?['fat_g'] as num?)?.toDouble(),
    );
  }

  bool get isBatch => cookingSessionId != null;
}

// ---------------------------------------------------------------------------
// CookingSession
// A batch cooking session — one recipe, N portions for the week.
// ---------------------------------------------------------------------------

@immutable
class CookingSession {
  final String id;
  final String userId;
  final String mealPlanId;
  final String? recipeId;
  final String? recipeTitle;
  final String? recipeThumbnail;
  final DateTime plannedDate;
  final int totalPortions;
  final int portionsUsed;
  final String? notes;

  const CookingSession({
    required this.id,
    required this.userId,
    required this.mealPlanId,
    this.recipeId,
    this.recipeTitle,
    this.recipeThumbnail,
    required this.plannedDate,
    required this.totalPortions,
    required this.portionsUsed,
    this.notes,
  });

  factory CookingSession.fromJson(Map<String, dynamic> json) {
    final recipe = json['recipe'] as Map<String, dynamic>?;
    return CookingSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mealPlanId: json['meal_plan_id'] as String,
      recipeId: json['recipe_id'] as String?,
      recipeTitle: recipe?['title'] as String?,
      recipeThumbnail: recipe?['cover_image_url'] as String?,
      plannedDate: DateTime.parse(json['planned_date'] as String),
      totalPortions: json['total_portions'] as int,
      portionsUsed: (json['portions_used'] as int?) ?? 0,
      notes: json['notes'] as String?,
    );
  }

  int get portionsAvailable => totalPortions - portionsUsed;
  bool get hasAvailablePortions => portionsAvailable > 0;
}

// ---------------------------------------------------------------------------
// ShoppingItem
// ---------------------------------------------------------------------------

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

  String get quantityDisplay =>
      '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} $unit';

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
