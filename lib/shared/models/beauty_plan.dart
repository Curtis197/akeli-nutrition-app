import 'package:flutter/foundation.dart';
import 'recipe.dart';

@immutable
class BeautyPlan {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final List<BeautyPlanSlot> slots;
  final DateTime createdAt;

  const BeautyPlan({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    this.slots = const [],
    required this.createdAt,
  });

  factory BeautyPlan.fromJson(Map<String, dynamic> json) {
    return BeautyPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      slots: (json['beauty_plan_slot'] as List<dynamic>?)
              ?.map((e) => BeautyPlanSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'beauty_plan_slot': slots.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@immutable
class BeautyPlanSlot {
  final String id;
  final String planId;
  final int dayOfWeek; // 1 = Mon, 7 = Sun
  final int? dayNumber; // 1 to 31 (day of month)
  final int? weekNumber; // 1 to 5 (week of month)
  final String routineCategory; // 'hair', 'skin', 'both'
  final String stepStage;
  final String? frequencyTier; // 'daily', '2x_week', '1x_week', '2x_month', '1x_month'
  final String recipeId;
  final Recipe? recipe;
  final bool isCompleted;
  final DateTime? completedAt;
  final double revenueValue;

  const BeautyPlanSlot({
    required this.id,
    required this.planId,
    required this.dayOfWeek,
    this.dayNumber,
    this.weekNumber,
    required this.routineCategory,
    required this.stepStage,
    this.frequencyTier,
    required this.recipeId,
    this.recipe,
    this.isCompleted = false,
    this.completedAt,
    this.revenueValue = 0.0,
  });

  factory BeautyPlanSlot.fromJson(Map<String, dynamic> json) {
    final recipeRaw = json['recipe'];
    return BeautyPlanSlot(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      dayOfWeek: (json['day_of_week'] as int?) ?? 1,
      dayNumber: json['day_number'] as int?,
      weekNumber: json['week_number'] as int?,
      routineCategory: (json['routine_category'] as String?) ?? 'both',
      stepStage: (json['step_stage'] as String?) ?? 'daily_hydration',
      frequencyTier: json['frequency_tier'] as String?,
      recipeId: json['recipe_id'] as String,
      recipe: recipeRaw is Map<String, dynamic> ? Recipe.fromJson(recipeRaw) : null,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      revenueValue: (json['revenue_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'day_of_week': dayOfWeek,
      'day_number': dayNumber,
      'week_number': weekNumber,
      'routine_category': routineCategory,
      'step_stage': stepStage,
      'frequency_tier': frequencyTier,
      'recipe_id': recipeId,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'revenue_value': revenueValue,
    };
  }
}
