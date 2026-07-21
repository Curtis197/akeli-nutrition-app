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
  final String routineCategory; // 'hair', 'skin', 'both'
  final String stepStage;
  final String recipeId;
  final Recipe? recipe;
  final bool isCompleted;
  final DateTime? completedAt;

  const BeautyPlanSlot({
    required this.id,
    required this.planId,
    required this.dayOfWeek,
    required this.routineCategory,
    required this.stepStage,
    required this.recipeId,
    this.recipe,
    this.isCompleted = false,
    this.completedAt,
  });

  factory BeautyPlanSlot.fromJson(Map<String, dynamic> json) {
    final recipeRaw = json['recipe'];
    return BeautyPlanSlot(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      dayOfWeek: (json['day_of_week'] as int?) ?? 1,
      routineCategory: (json['routine_category'] as String?) ?? 'both',
      stepStage: (json['step_stage'] as String?) ?? 'daily_hydration',
      recipeId: json['recipe_id'] as String,
      recipe: recipeRaw is Map<String, dynamic> ? Recipe.fromJson(recipeRaw) : null,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'day_of_week': dayOfWeek,
      'routine_category': routineCategory,
      'step_stage': stepStage,
      'recipe_id': recipeId,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
