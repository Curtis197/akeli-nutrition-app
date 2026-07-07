// lib/providers/nutrition_targets_provider.dart

import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';

final _logger = appLogger;

/// Output row of public.calculate_nutrition_targets() — the backend single
/// source of truth (spec §2). No calorie/macro math may be done in Dart.
class NutritionTargetsResult {
  final double bmr;
  final double tdee;
  final int calorieGoal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double effectivePaceKgWeek;
  final double? estimatedWeeksToTarget;

  const NutritionTargetsResult({
    required this.bmr,
    required this.tdee,
    required this.calorieGoal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.effectivePaceKgWeek,
    this.estimatedWeeksToTarget,
  });

  factory NutritionTargetsResult.fromRpcRow(Map<String, dynamic> row) =>
      NutritionTargetsResult(
        bmr: (row['bmr'] as num).toDouble(),
        tdee: (row['tdee'] as num).toDouble(),
        calorieGoal: (row['calorie_goal'] as num).toInt(),
        proteinG: (row['protein_g'] as num).toDouble(),
        carbG: (row['carb_g'] as num).toDouble(),
        fatG: (row['fat_g'] as num).toDouble(),
        effectivePaceKgWeek:
            (row['effective_pace_kg_week'] as num).toDouble(),
        estimatedWeeksToTarget:
            (row['estimated_weeks_to_target'] as num?)?.toDouble(),
      );
}

Map<String, dynamic> buildCalculateTargetsParams({
  required double weightKg,
  required double heightCm,
  required int age,
  required String sex,
  required String? activityLevel,
  required String primaryGoal,
  double? targetWeightKg,
  int? remainingWeeks,
}) =>
    {
      'p_weight_kg': weightKg,
      'p_height_cm': heightCm,
      'p_age': age,
      'p_sex': sex,
      'p_activity_level': activityLevel,
      'p_primary_goal': primaryGoal,
      'p_target_weight_kg': targetWeightKg,
      'p_remaining_weeks': remainingWeeks,
    };

/// Onboarding: target_date is "today + timelineMonths", so remaining weeks
/// is the whole timeline. Spec §1.3/§4.1: floor 4.
int remainingWeeksFromMonths(int months) =>
    math.max(4, (months * 4.33).round());

/// Settings/anywhere with a stored target_date. Spec §1.3: floor 4,
/// NULL date -> NULL (calculator applies its default pace).
int? remainingWeeksFromDate(DateTime? targetDate, {DateTime? now}) {
  if (targetDate == null) return null;
  final days = targetDate.difference(now ?? DateTime.now()).inDays;
  return math.max(4, (days / 7).ceil());
}

/// Calls the backend calculator. Returns null when the function returns zero
/// rows (invalid inputs, spec §1.10) — callers show an error and keep prior
/// values. Never falls back to local math.
Future<NutritionTargetsResult?> fetchNutritionTargets(
  SupabaseClient client, {
  required double weightKg,
  required double heightCm,
  required int age,
  required String sex,
  required String? activityLevel,
  required String primaryGoal,
  double? targetWeightKg,
  int? remainingWeeks,
}) async {
  final params = buildCalculateTargetsParams(
    weightKg: weightKg,
    heightCm: heightCm,
    age: age,
    sex: sex,
    activityLevel: activityLevel,
    primaryGoal: primaryGoal,
    targetWeightKg: targetWeightKg,
    remainingWeeks: remainingWeeks,
  );
  _logger.db('BEFORE rpc | fn: calculate_nutrition_targets | params: $params');
  try {
    final rows = await client.rpc('calculate_nutrition_targets',
        params: params) as List<dynamic>;
    _logger.db(
        'AFTER rpc | fn: calculate_nutrition_targets | rows: ${rows.length}');
    if (rows.isEmpty) return null;
    return NutritionTargetsResult.fromRpcRow(
        rows.first as Map<String, dynamic>);
  } on PostgrestException catch (e, st) {
    _logger.db(
        'ERROR rpc | fn: calculate_nutrition_targets | code: ${e.code} | ${e.message}',
        error: e, stackTrace: st);
    rethrow;
  }
}
