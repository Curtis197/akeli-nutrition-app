import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/logger.dart'; // ignore: unused_import
import 'package:akeli/shared/models/journey_stats.dart';

const _fullJson = {
  'summary': {
    'total_days': 103,
    'days_logged': 78,
    'meals_consumed': 234,
    'consistency_pct': 76,
  },
  'streak': {'current': 7, 'best': 14},
  'goals': {
    'weight_start_kg': 82.0,
    'weight_current_kg': 76.5,
    'weight_target_kg': 73.0,
    'calorie_hit_pct': 64,
    'protein_hit_pct': 71,
    'carbs_hit_pct': 58,
    'fat_hit_pct': 69,
  },
  'calendar': [
    {'date': '2026-06-01', 'status': 'hit'},
    {'date': '2026-06-02', 'status': 'partial'},
    {'date': '2026-06-03', 'status': 'missed'},
    {'date': '2026-06-04', 'status': 'empty'},
  ],
};

void main() {
  group('JourneyStats.fromJson', () {
    late JourneyStats stats;

    setUp(() => stats = JourneyStats.fromJson(_fullJson));

    test('parses summary fields', () {
      expect(stats.totalDays, 103);
      expect(stats.daysLogged, 78);
      expect(stats.mealsConsumed, 234);
      expect(stats.consistencyPct, 76);
    });

    test('parses streak fields', () {
      expect(stats.currentStreak, 7);
      expect(stats.bestStreak, 14);
    });

    test('parses goal hit rates', () {
      expect(stats.calorieHitPct, 64);
      expect(stats.proteinHitPct, 71);
      expect(stats.carbsHitPct, 58);
      expect(stats.fatHitPct, 69);
    });

    test('parses weight fields', () {
      expect(stats.weightStartKg, 82.0);
      expect(stats.weightCurrentKg, 76.5);
      expect(stats.weightTargetKg, 73.0);
    });

    test('hasWeightGoal is true when all weight fields present and start != target', () {
      expect(stats.hasWeightGoal, isTrue);
    });

    test('weightProgressPct is between 0 and 1', () {
      expect(stats.weightProgressPct, greaterThanOrEqualTo(0.0));
      expect(stats.weightProgressPct, lessThanOrEqualTo(1.0));
    });

    test('weightProgressPct computes correctly', () {
      // (82 - 76.5) / (82 - 73) = 5.5 / 9 ≈ 0.611
      expect(stats.weightProgressPct, closeTo(0.611, 0.001));
    });

    test('parses calendar with correct statuses', () {
      expect(stats.calendar.length, 4);
      expect(stats.calendar[0].status, JourneyDayStatus.hit);
      expect(stats.calendar[1].status, JourneyDayStatus.partial);
      expect(stats.calendar[2].status, JourneyDayStatus.missed);
      expect(stats.calendar[3].status, JourneyDayStatus.empty);
    });

    test('calendar dates parse correctly', () {
      expect(stats.calendar[0].date, DateTime(2026, 6, 1));
    });

    test('unknown status defaults to empty', () {
      final day = JourneyCalendarDay.fromJson(const {'date': '2026-06-01', 'status': 'unknown'});
      expect(day.status, JourneyDayStatus.empty);
    });
  });

  group('JourneyStats.fromJson — null / missing fields', () {
    test('handles missing calendar gracefully', () {
      final json = Map<String, dynamic>.from(_fullJson)..remove('calendar');
      final stats = JourneyStats.fromJson(json);
      expect(stats.calendar, isEmpty);
    });

    test('handles null weight fields', () {
      final goals = Map<String, dynamic>.from(_fullJson['goals'] as Map)
        ..['weight_start_kg'] = null
        ..['weight_current_kg'] = null
        ..['weight_target_kg'] = null;
      final stats = JourneyStats.fromJson({..._fullJson, 'goals': goals});
      expect(stats.hasWeightGoal, isFalse);
      expect(stats.weightProgressPct, 0.0);
    });

    test('handles empty JSON with zero defaults', () {
      final stats = JourneyStats.fromJson({});
      expect(stats.totalDays, 0);
      expect(stats.currentStreak, 0);
      expect(stats.calendar, isEmpty);
    });
  });
}
