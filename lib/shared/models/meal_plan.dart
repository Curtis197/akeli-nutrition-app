import 'package:flutter/foundation.dart';
import '../../core/quantity_formatter.dart';

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
  final double servings;
  final bool isConsumed;
  final bool isRated;
  final bool isCustomMeal;
  final String? customMealName;
  final double? customCalories;
  final double? customProteinG;
  final double? customCarbsG;
  final double? customFatG;
  final double? caloriesComputed;
  final double? proteinGComputed;
  final double? carbsGComputed;
  final double? fatGComputed;
  final List<MealIngredient> ingredients;
  final List<MealPlanEntryComponent> components;

  const MealPlanEntry({
    required this.id,
    required this.mealPlanId,
    required this.mealType,
    required this.scheduledDate,
    required this.servings,
    required this.isConsumed,
    required this.isRated,
    required this.isCustomMeal,
    this.customMealName,
    this.customCalories,
    this.customProteinG,
    this.customCarbsG,
    this.customFatG,
    this.caloriesComputed,
    this.proteinGComputed,
    this.carbsGComputed,
    this.fatGComputed,
    required this.ingredients,
    required this.components,
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as String,
        mealPlanId: json['meal_plan_id'] as String,
        mealType: json['meal_type'] as String,
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
        isConsumed: (json['is_consumed'] as bool?) ?? false,
        isRated: ((json['meal_consumption'] as List<dynamic>?) ?? [])
            .any((c) => (c as Map<String, dynamic>)['rating'] != null),
        isCustomMeal: (json['is_custom_meal'] as bool?) ?? false,
        customMealName: json['custom_meal_name'] as String?,
        customCalories: (json['custom_calories'] as num?)?.toDouble(),
        customProteinG: (json['custom_protein_g'] as num?)?.toDouble(),
        customCarbsG: (json['custom_carbs_g'] as num?)?.toDouble(),
        customFatG: (json['custom_fat_g'] as num?)?.toDouble(),
        caloriesComputed: (json['calories_computed'] as num?)?.toDouble(),
        proteinGComputed: (json['protein_g_computed'] as num?)?.toDouble(),
        carbsGComputed: (json['carbs_g_computed'] as num?)?.toDouble(),
        fatGComputed: (json['fat_g_computed'] as num?)?.toDouble(),
        ingredients: (json['meal_ingredient'] as List<dynamic>?)
                ?.map((e) => MealIngredient.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
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

  String? get recipeTitle =>
      isCustomMeal ? customMealName : (_base?.recipeTitle);
  String? get recipeThumbnail => _base?.recipeThumbnail;

  // Macros — pre-computed backend values when available; fall through to
  // component sum × servings (legacy entries before migration) or custom values.
  double get calories {
    if (isCustomMeal) return customCalories ?? 0.0;
    if (caloriesComputed != null) return caloriesComputed!;
    return components.fold(0.0, (s, c) => s + (c.calories ?? 0.0)) * servings;
  }

  double get proteinG {
    if (isCustomMeal) return customProteinG ?? 0.0;
    if (proteinGComputed != null) return proteinGComputed!;
    return components.fold(0.0, (s, c) => s + (c.proteinG ?? 0.0)) * servings;
  }

  double get carbsG {
    if (isCustomMeal) return customCarbsG ?? 0.0;
    if (carbsGComputed != null) return carbsGComputed!;
    return components.fold(0.0, (s, c) => s + (c.carbsG ?? 0.0)) * servings;
  }

  double get fatG {
    if (isCustomMeal) return customFatG ?? 0.0;
    if (fatGComputed != null) return fatGComputed!;
    return components.fold(0.0, (s, c) => s + (c.fatG ?? 0.0)) * servings;
  }

  // Convenience accessor — recipe ID of the base component. Null for custom meals.
  String? get recipeId => isCustomMeal ? null : _base?.recipeId;
  int? get totalTimeMin => _base?.totalTimeMin;

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
  final int? totalTimeMin;

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
    this.totalTimeMin,
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
      totalTimeMin: recipe != null
          ? ((recipe['prep_time_min'] as int?) ?? 0) +
            ((recipe['cook_time_min'] as int?) ?? 0)
          : null,
    );
  }

  bool get isBatch => cookingSessionId != null;
}

// ---------------------------------------------------------------------------
// CookingSession
// A batch cooking session — one recipe, N portions for the week.
// ---------------------------------------------------------------------------

@immutable
class CookingSessionIngredient {
  final String id;
  final String cookingSessionId;
  final String? ingredientId;
  final String ingredientName;
  final double quantityNeeded;
  final String unit;

  const CookingSessionIngredient({
    required this.id,
    required this.cookingSessionId,
    this.ingredientId,
    required this.ingredientName,
    required this.quantityNeeded,
    required this.unit,
  });

  factory CookingSessionIngredient.fromJson(Map<String, dynamic> json) {
    return CookingSessionIngredient(
      id: json['id'] as String,
      cookingSessionId: json['cooking_session_id'] as String,
      ingredientId: json['ingredient_id'] as String?,
      ingredientName: json['ingredient_name'] as String,
      quantityNeeded: (json['quantity_needed'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  String get quantityDisplay => formatQuantity(quantityNeeded, unit);
}

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
  final bool isCooked;
  final double? scaleFactor;
  final String? notes;
  final List<CookingSessionIngredient>? ingredients;

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
    required this.isCooked,
    this.scaleFactor,
    this.notes,
    this.ingredients,
  });

  factory CookingSession.fromJson(Map<String, dynamic> json) {
    final recipe = json['recipe'] as Map<String, dynamic>?;
    final rawIngredients = json['cooking_session_ingredient'] as List<dynamic>?;
    return CookingSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mealPlanId: json['meal_plan_id'] as String,
      recipeId: json['recipe_id'] as String?,
      recipeTitle: recipe?['title'] as String?,
      recipeThumbnail: recipe?['cover_image_url'] as String?,
      plannedDate: DateTime.parse(json['planned_date'] as String),
      totalPortions: (json['total_portions'] as num).toInt(),
      portionsUsed: (json['portions_used'] as num?)?.toInt() ?? 0,
      isCooked: (json['is_cooked'] as bool?) ?? false,
      scaleFactor: json['scale_factor'] != null
          ? (json['scale_factor'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      ingredients: rawIngredients
          ?.map((e) => CookingSessionIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
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
  final String id;
  final String? ingredientId;
  final String name;
  final double quantity;
  final String unit;
  final String? category;
  final bool isChecked;

  const ShoppingItem({
    required this.id,
    this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.category,
    required this.isChecked,
  });

  String get quantityDisplay => formatQuantity(quantity, unit);

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String? ?? '', // Fallback if missing
        ingredientId: json['ingredient_id'] as String?,
        name: json['ingredient_name'] as String? ?? 'Unknown',
        quantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? '',
        category: json['category'] as String?,
        isChecked: (json['is_checked'] as bool?) ?? false,
      );

  ShoppingItem copyWith({bool? isChecked}) => ShoppingItem(
        id: id,
        ingredientId: ingredientId,
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        isChecked: isChecked ?? this.isChecked,
      );
}

// ---------------------------------------------------------------------------
// MealIngredient
// Pre-computed ingredient quantity for a meal entry (scaled to user portion).
// ---------------------------------------------------------------------------

@immutable
class MealIngredient {
  final String id;
  final String mealPlanEntryId;
  final String? ingredientId;
  final String ingredientName;
  final double quantity;
  final String unit;

  const MealIngredient({
    required this.id,
    required this.mealPlanEntryId,
    this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) => MealIngredient(
        id: json['id'] as String,
        mealPlanEntryId: json['meal_plan_entry_id'] as String,
        ingredientId: json['ingredient_id'] as String?,
        ingredientName: json['ingredient_name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
      );

  String get quantityDisplay => formatQuantity(quantity, unit);
}
