import 'package:flutter/foundation.dart';
import 'package:akeli/core/logger.dart';

// ignore: unused_field
final _logger = appLogger;

enum JourneyDayStatus { hit, partial, missed, empty }

@immutable
class JourneyCalendarDay {
  final DateTime date;
  final JourneyDayStatus status;

  const JourneyCalendarDay({required this.date, required this.status});

  factory JourneyCalendarDay.fromJson(Map<String, dynamic> json) {
    _logger.db('JourneyCalendarDay.fromJson | date: ${json['date']}');
    return JourneyCalendarDay(
      date: DateTime.parse(json['date'] as String),
      status: switch (json['status'] as String? ?? 'empty') {
        'hit'     => JourneyDayStatus.hit,
        'partial' => JourneyDayStatus.partial,
        'missed'  => JourneyDayStatus.missed,
        _         => JourneyDayStatus.empty,
      },
    );
  }
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
