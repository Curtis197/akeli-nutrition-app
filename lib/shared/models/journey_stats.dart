import 'package:flutter/foundation.dart';
import 'package:akeli/core/logger.dart';

@immutable
class RecipeWeightImpact {
  final String recipeId;
  final String mealType;
  final String recipeTitle;
  final String? recipeThumbnailUrl;
  final double avgDeltaKg;
  final int sampleCount;

  const RecipeWeightImpact({
    required this.recipeId,
    required this.mealType,
    required this.recipeTitle,
    this.recipeThumbnailUrl,
    required this.avgDeltaKg,
    required this.sampleCount,
  });

  factory RecipeWeightImpact.fromJson(Map<String, dynamic> json) {
    _logger.db('RecipeWeightImpact.fromJson | recipeId: ${json['recipe_id']} | mealType: ${json['meal_type']}');
    final recipe = json['recipe'] as Map<String, dynamic>? ?? {};
    return RecipeWeightImpact(
      recipeId:           json['recipe_id']      as String,
      mealType:           json['meal_type']       as String,
      recipeTitle:        recipe['title']         as String? ?? '',
      recipeThumbnailUrl: recipe['thumbnail_url'] as String?,
      avgDeltaKg:         (json['avg_delta_kg']   as num).toDouble(),
      sampleCount:        (json['sample_count']   as num).toInt(),
    );
  }

  bool get isWeightLoss => avgDeltaKg < 0;

  String get formattedDelta {
    final sign = avgDeltaKg >= 0 ? '+' : '';
    return '$sign${avgDeltaKg.toStringAsFixed(2)} kg';
  }
}

// ignore: unused_field
final _logger = appLogger;

@immutable
class JourneyCalendarDay {
  final DateTime date;
  final int planned;
  final int consumed;

  const JourneyCalendarDay({
    required this.date,
    required this.planned,
    required this.consumed,
  });

  factory JourneyCalendarDay.fromJson(Map<String, dynamic> json) {
    _logger.db(
      'JourneyCalendarDay.fromJson | date: ${json['date']} '
      '| planned: ${json['planned']} | consumed: ${json['consumed']}',
    );
    return JourneyCalendarDay(
      date:     DateTime.parse(json['date'] as String),
      planned:  (json['planned']  as num?)?.toInt() ?? 0,
      consumed: (json['consumed'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasNoPlan => planned == 0;
  bool get isFull    => planned > 0 && consumed == planned;
  bool get isPartial => consumed > 0 && consumed < planned;
  bool get isMissed  => planned > 0 && consumed == 0;
}

@immutable
class JourneyStats {
  final int totalDays;
  final int daysLogged;
  final int mealsConsumed;
  final int consistencyPct;
  final int currentStreak;
  final int bestStreak;
  final double? weightStartKg;
  final double? weightCurrentKg;
  final double? weightTargetKg;
  final int calorieHitPct;
  final int proteinHitPct;
  final int carbsHitPct;
  final int fatHitPct;
  final List<JourneyCalendarDay> calendar;

  const JourneyStats({
    required this.totalDays,
    required this.daysLogged,
    required this.mealsConsumed,
    required this.consistencyPct,
    required this.currentStreak,
    required this.bestStreak,
    this.weightStartKg,
    this.weightCurrentKg,
    this.weightTargetKg,
    required this.calorieHitPct,
    required this.proteinHitPct,
    required this.carbsHitPct,
    required this.fatHitPct,
    required this.calendar,
  });

  factory JourneyStats.fromJson(Map<String, dynamic> json) {
    _logger.db('JourneyStats.fromJson | keys: ${json.keys.toList()}');
    final summary  = json['summary']  as Map<String, dynamic>? ?? {};
    final streak   = json['streak']   as Map<String, dynamic>? ?? {};
    final goals    = json['goals']    as Map<String, dynamic>? ?? {};
    final calList  = json['calendar'] as List<dynamic>?        ?? [];

    return JourneyStats(
      totalDays:       (summary['total_days']      as num?)?.toInt() ?? 0,
      daysLogged:      (summary['days_logged']     as num?)?.toInt() ?? 0,
      mealsConsumed:   (summary['meals_consumed']  as num?)?.toInt() ?? 0,
      consistencyPct:  (summary['consistency_pct'] as num?)?.toInt() ?? 0,
      currentStreak:   (streak['current']          as num?)?.toInt() ?? 0,
      bestStreak:      (streak['best']             as num?)?.toInt() ?? 0,
      weightStartKg:   (goals['weight_start_kg']   as num?)?.toDouble(),
      weightCurrentKg: (goals['weight_current_kg'] as num?)?.toDouble(),
      weightTargetKg:  (goals['weight_target_kg']  as num?)?.toDouble(),
      calorieHitPct:   (goals['calorie_hit_pct']   as num?)?.toInt() ?? 0,
      proteinHitPct:   (goals['protein_hit_pct']   as num?)?.toInt() ?? 0,
      carbsHitPct:     (goals['carbs_hit_pct']     as num?)?.toInt() ?? 0,
      fatHitPct:       (goals['fat_hit_pct']       as num?)?.toInt() ?? 0,
      calendar: calList
          .map((e) => JourneyCalendarDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasWeightGoal =>
      weightStartKg != null &&
      weightCurrentKg != null &&
      weightTargetKg != null &&
      weightStartKg != weightTargetKg;

  double get weightProgressPct {
    if (!hasWeightGoal) return 0;
    final total = weightStartKg! - weightTargetKg!;
    if (total == 0) return 1;
    return ((weightStartKg! - weightCurrentKg!) / total).clamp(0.0, 1.0);
  }
}
