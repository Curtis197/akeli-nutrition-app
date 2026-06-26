# Journey Dashboard (Parcours Tab) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Parcours" third tab to NutritionPage showing all-time summary stats, a calorie-streak pill, goal progress bars (weight + 4 macros), and a navigable monthly calendar colour-coded by calorie-target adherence.

**Architecture:** A single Postgres RPC `get_journey_stats(p_year, p_month)` returns all data in one call. Flutter calls it via `.rpc()`, a `FutureProvider.autoDispose.family` keyed on `(year, month)` holds the result, and five focused widgets compose the tab. NutritionPage gains a third tab entry.

**Tech Stack:** Flutter / Riverpod / Supabase (`.rpc()`) / Dart `@immutable` models / mocktail (tests)

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/20260612120000_get_journey_stats.sql` | SQL RPC function |
| Create | `lib/shared/models/journey_stats.dart` | `JourneyStats`, `JourneyCalendarDay`, `JourneyDayStatus` |
| Create | `test/models/journey_stats_test.dart` | `fromJson` unit tests |
| Create | `lib/providers/journey_provider.dart` | `journeyStatsProvider` family |
| Create | `lib/features/nutrition/widgets/journey/journey_summary_row.dart` | 2×2 stat cards |
| Create | `lib/features/nutrition/widgets/journey/journey_streak_pill.dart` | Streak + record pill |
| Create | `lib/features/nutrition/widgets/journey/journey_goals_card.dart` | 5 progress bars |
| Create | `lib/features/nutrition/widgets/journey/journey_calendar.dart` | Monthly calendar + navigation |
| Create | `lib/features/nutrition/widgets/journey/journey_tab.dart` | Root widget, reads provider |
| Modify | `lib/features/nutrition/nutrition_page.dart` | Add third tab |

---

## Task 1: SQL Migration — `get_journey_stats` RPC

**Files:**
- Create: `supabase/migrations/20260612120000_get_journey_stats.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- Migration: 20260612120000_get_journey_stats.sql
-- Description: RPC returning all-time journey stats + monthly calendar for a user.
-- Executes as the calling user (SECURITY INVOKER) — RLS applies on all tables.

CREATE OR REPLACE FUNCTION get_journey_stats(
  p_year  INT,
  p_month INT
) RETURNS JSON
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_user_id      UUID    := auth.uid();
  v_start_date   DATE;
  v_today        DATE    := CURRENT_DATE;
  v_month_start  DATE    := make_date(p_year, p_month, 1);
  v_month_end    DATE    := (v_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  -- Summary
  v_total_days      INT;
  v_days_logged     INT;
  v_meals_consumed  INT;
  v_consistency_pct INT;

  -- Nutrition targets
  v_calorie_goal  NUMERIC;
  v_protein_goal  NUMERIC;
  v_carb_goal     NUMERIC;
  v_fat_goal      NUMERIC;

  -- Goal hit rates
  v_calorie_hit_pct INT := 0;
  v_protein_hit_pct INT := 0;
  v_carbs_hit_pct   INT := 0;
  v_fat_hit_pct     INT := 0;

  -- Streak
  v_current_streak  INT := 0;
  v_best_streak     INT := 0;

  -- Weight
  v_weight_start   NUMERIC;
  v_weight_current NUMERIC;
  v_weight_target  NUMERIC;

  -- Calendar
  v_calendar JSON;
BEGIN
  -- ── 1. Start date ─────────────────────────────────────────────────────────
  SELECT created_at::DATE INTO v_start_date
  FROM user_profile WHERE id = v_user_id;
  IF v_start_date IS NULL THEN v_start_date := v_today; END IF;

  -- ── 2. Summary ────────────────────────────────────────────────────────────
  v_total_days := GREATEST(1, v_today - v_start_date + 1);

  SELECT COUNT(DISTINCT log_date) INTO v_days_logged
  FROM daily_nutrition_log
  WHERE user_id = v_user_id
    AND log_date BETWEEN v_start_date AND v_today;

  SELECT COUNT(*) INTO v_meals_consumed
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = v_user_id AND mpe.is_consumed = TRUE;

  v_consistency_pct := ROUND(v_days_logged::NUMERIC / v_total_days * 100);

  -- ── 3. Active nutrition targets ───────────────────────────────────────────
  SELECT calorie_goal, protein_goal_g, carb_goal_g, fat_goal_g
  INTO v_calorie_goal, v_protein_goal, v_carb_goal, v_fat_goal
  FROM nutrition_plan
  WHERE user_id = v_user_id AND is_active = TRUE
  ORDER BY created_at DESC
  LIMIT 1;

  -- ── 4. Goal hit rates (only when targets exist and days were logged) ──────
  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND v_days_logged > 0 THEN
    SELECT
      ROUND(100.0 * SUM(CASE WHEN ABS(calories - v_calorie_goal) / v_calorie_goal <= 0.10 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_protein_goal > 0 AND ABS(protein_g - v_protein_goal) / v_protein_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_carb_goal > 0 AND ABS(carbs_g - v_carb_goal) / v_carb_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_fat_goal > 0 AND ABS(fat_g - v_fat_goal) / v_fat_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*))
    INTO v_calorie_hit_pct, v_protein_hit_pct, v_carbs_hit_pct, v_fat_hit_pct
    FROM daily_nutrition_log
    WHERE user_id = v_user_id
      AND log_date BETWEEN v_start_date AND v_today
      AND calories > 0;
  END IF;

  -- ── 5. Streak (islands technique) ────────────────────────────────────────
  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
    WITH all_days AS (
      SELECT generate_series(v_start_date, v_today, '1 day')::DATE AS d
    ),
    day_status AS (
      SELECT ad.d,
        COALESCE(
          dnl.calories IS NOT NULL
          AND ABS(dnl.calories - v_calorie_goal) / v_calorie_goal <= 0.10,
          FALSE
        ) AS is_hit
      FROM all_days ad
      LEFT JOIN daily_nutrition_log dnl
        ON dnl.user_id = v_user_id AND dnl.log_date = ad.d
    ),
    grp_assigned AS (
      SELECT d, is_hit,
        d - (ROW_NUMBER() OVER (PARTITION BY is_hit ORDER BY d) || ' days')::INTERVAL AS grp
      FROM day_status
    ),
    streak_lengths AS (
      SELECT MIN(d) AS s_start, MAX(d) AS s_end, COUNT(*) AS len
      FROM grp_assigned
      WHERE is_hit
      GROUP BY grp
    )
    SELECT
      COALESCE(MAX(len), 0),
      COALESCE(
        (SELECT len FROM streak_lengths WHERE s_end >= v_today - 1 ORDER BY s_end DESC LIMIT 1),
        0
      )
    INTO v_best_streak, v_current_streak
    FROM streak_lengths;
  END IF;

  -- ── 6. Weight ─────────────────────────────────────────────────────────────
  SELECT starting_weight_kg, target_weight_kg, weight_kg
  INTO v_weight_start, v_weight_target, v_weight_current
  FROM user_health_profile WHERE user_id = v_user_id;

  -- Latest actual weight from weight_log overrides profile snapshot
  SELECT weight_kg INTO v_weight_current
  FROM weight_log WHERE user_id = v_user_id ORDER BY logged_at DESC LIMIT 1;

  IF v_weight_start IS NULL THEN v_weight_start := v_weight_current; END IF;

  -- ── 7. Calendar ───────────────────────────────────────────────────────────
  SELECT json_agg(
    json_build_object(
      'date', d.day::TEXT,
      'status', CASE
        WHEN d.day > v_today THEN 'empty'
        WHEN dnl.calories IS NULL OR dnl.calories = 0 THEN
          CASE WHEN EXISTS (
            SELECT 1 FROM meal_plan_entry mpe
            JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
            WHERE mp.user_id = v_user_id AND mpe.scheduled_date = d.day
          ) THEN 'missed' ELSE 'empty' END
        WHEN v_calorie_goal IS NULL OR v_calorie_goal = 0 THEN 'partial'
        WHEN ABS(dnl.calories - v_calorie_goal) / v_calorie_goal <= 0.10 THEN 'hit'
        ELSE 'partial'
      END
    )
    ORDER BY d.day
  ) INTO v_calendar
  FROM generate_series(v_month_start, v_month_end, '1 day'::INTERVAL) AS d(day)
  LEFT JOIN daily_nutrition_log dnl
    ON dnl.user_id = v_user_id AND dnl.log_date = d.day::DATE;

  -- ── 8. Return ─────────────────────────────────────────────────────────────
  RETURN json_build_object(
    'summary', json_build_object(
      'total_days',       v_total_days,
      'days_logged',      v_days_logged,
      'meals_consumed',   v_meals_consumed,
      'consistency_pct',  v_consistency_pct
    ),
    'streak', json_build_object(
      'current', v_current_streak,
      'best',    v_best_streak
    ),
    'goals', json_build_object(
      'weight_start_kg',   v_weight_start,
      'weight_current_kg', v_weight_current,
      'weight_target_kg',  v_weight_target,
      'calorie_hit_pct',   v_calorie_hit_pct,
      'protein_hit_pct',   v_protein_hit_pct,
      'carbs_hit_pct',     v_carbs_hit_pct,
      'fat_hit_pct',       v_fat_hit_pct
    ),
    'calendar', COALESCE(v_calendar, '[]'::JSON)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_journey_stats(INT, INT) TO authenticated;
```

- [ ] **Step 2: Apply migration**

```bash
supabase db push
```

Expected: migration applies without error. Verify with:
```bash
supabase db diff
```
Expected: no pending diff.

- [ ] **Step 3: Smoke-test the RPC in Supabase SQL editor**

Run as an authenticated user:
```sql
SELECT get_journey_stats(2026, 6);
```
Expected: JSON object with keys `summary`, `streak`, `goals`, `calendar`. `calendar` should have 30 entries for June.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260612120000_get_journey_stats.sql
git commit -m "feat(db): get_journey_stats RPC — journey summary, streak, goals, calendar"
```

---

## Task 2: Dart Model

**Files:**
- Create: `lib/shared/models/journey_stats.dart`

- [ ] **Step 1: Create the model file**

```dart
import 'package:flutter/foundation.dart';

enum JourneyDayStatus { hit, partial, missed, empty }

@immutable
class JourneyCalendarDay {
  final DateTime date;
  final JourneyDayStatus status;

  const JourneyCalendarDay({required this.date, required this.status});

  factory JourneyCalendarDay.fromJson(Map<String, dynamic> json) {
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/models/journey_stats.dart
git commit -m "feat(model): JourneyStats + JourneyCalendarDay models"
```

---

## Task 3: Model Unit Tests

**Files:**
- Create: `test/models/journey_stats_test.dart`

- [ ] **Step 1: Create the test file**

```dart
import 'package:flutter_test/flutter_test.dart';
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
      final day = JourneyCalendarDay.fromJson({'date': '2026-06-01', 'status': 'unknown'});
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
```

- [ ] **Step 2: Run tests — expect all pass**

```bash
flutter test test/models/journey_stats_test.dart -v
```

Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add test/models/journey_stats_test.dart
git commit -m "test(model): JourneyStats fromJson unit tests"
```

---

## Task 4: Dart Provider

**Files:**
- Create: `lib/providers/journey_provider.dart`

- [ ] **Step 1: Create the provider file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/journey_stats.dart';
import 'auth_provider.dart';

final _logger = appLogger;

final journeyStatsProvider = FutureProvider.autoDispose
    .family<JourneyStats?, ({int year, int month})>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  _logger.provider(
    'journeyStatsProvider build() | userId: ${user.id} | ${params.year}-${params.month}',
  );

  final client = ref.read(supabaseClientProvider);

  _logger.db(
    'BEFORE rpc | fn: get_journey_stats | year: ${params.year} | month: ${params.month}',
  );

  try {
    final data = await client.rpc('get_journey_stats', params: {
      'p_year':  params.year,
      'p_month': params.month,
    });

    _logger.db('AFTER rpc | fn: get_journey_stats | success');

    if (data == null) {
      _logger.db('AFTER rpc | fn: get_journey_stats | rows: 0');
      return null;
    }

    final stats = JourneyStats.fromJson(data as Map<String, dynamic>);
    _logger.provider(
      'journeyStatsProvider → data | calendar days: ${stats.calendar.length}',
    );
    return stats;
  } on PostgrestException catch (e, st) {
    _logger.db(
      'ERROR rpc | fn: get_journey_stats | code: ${e.code} | ${e.message}',
      error: e,
      stackTrace: st,
    );
    rethrow;
  } catch (e, st) {
    _logger.db('ERROR rpc | fn: get_journey_stats | $e', error: e, stackTrace: st);
    rethrow;
  }
});
```

- [ ] **Step 2: Add missing import at the top**

`PostgrestException` comes from `supabase_flutter`. Add:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

Full import block at top of `lib/providers/journey_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/journey_stats.dart';
import 'auth_provider.dart';
```

- [ ] **Step 3: Commit**

```bash
git add lib/providers/journey_provider.dart
git commit -m "feat(provider): journeyStatsProvider family (get_journey_stats RPC)"
```

---

## Task 5: `JourneySummaryRow` + `JourneyStreakPill`

**Files:**
- Create: `lib/features/nutrition/widgets/journey/journey_summary_row.dart`
- Create: `lib/features/nutrition/widgets/journey/journey_streak_pill.dart`

- [ ] **Step 1: Create `journey_summary_row.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/journey_stats.dart';

class JourneySummaryRow extends StatelessWidget {
  final JourneyStats stats;

  const JourneySummaryRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    appLogger.provider('JourneySummaryRow build()');
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _StatCard(icon: '📅', value: '${stats.totalDays}', label: 'Jours de parcours'),
        _StatCard(icon: '✅', value: '${stats.daysLogged}', label: 'Jours logués'),
        _StatCard(icon: '🍽️', value: '${stats.mealsConsumed}', label: 'Repas consommés'),
        _StatCard(icon: '📊', value: '${stats.consistencyPct}%', label: 'Régularité'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AkeliColors.onSurface,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AkeliColors.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create `journey_streak_pill.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/journey_stats.dart';

class JourneyStreakPill extends StatelessWidget {
  final JourneyStats stats;

  const JourneyStreakPill({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    appLogger.provider('JourneyStreakPill build()');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AkeliColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${stats.currentStreak}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AkeliColors.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'jours · objectif calorique',
                style: TextStyle(fontSize: 11, color: AkeliColors.onSurfaceVariant),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.bestStreak}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.primary,
                ),
              ),
              const Text(
                'Record',
                style: TextStyle(fontSize: 10, color: AkeliColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/nutrition/widgets/journey/journey_summary_row.dart \
        lib/features/nutrition/widgets/journey/journey_streak_pill.dart
git commit -m "feat(ui): JourneySummaryRow + JourneyStreakPill widgets"
```

---

## Task 6: `JourneyGoalsCard`

**Files:**
- Create: `lib/features/nutrition/widgets/journey/journey_goals_card.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/journey_stats.dart';

class JourneyGoalsCard extends StatelessWidget {
  final JourneyStats stats;

  const JourneyGoalsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    appLogger.provider('JourneyGoalsCard build()');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.hasWeightGoal) ...[
            _GoalBar(
              label: '⚖️  Poids',
              value:
                  '${stats.weightCurrentKg?.toStringAsFixed(1)} kg → ${stats.weightTargetKg?.toStringAsFixed(1)} kg',
              progress: stats.weightProgressPct,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFFACC15), Color(0xFF4ADE80)],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _GoalBar(
            label: '🎯  Calories',
            value: '${stats.calorieHitPct}% des jours logués',
            progress: stats.calorieHitPct / 100,
            color: AkeliColors.primary,
          ),
          const SizedBox(height: 12),
          _GoalBar(
            label: '💪  Protéines',
            value: '${stats.proteinHitPct}%',
            progress: stats.proteinHitPct / 100,
            color: AkeliColors.secondary,
          ),
          const SizedBox(height: 12),
          _GoalBar(
            label: '🌾  Glucides',
            value: '${stats.carbsHitPct}%',
            progress: stats.carbsHitPct / 100,
            color: AkeliColors.accentAmber,
          ),
          const SizedBox(height: 12),
          _GoalBar(
            label: '🥑  Lipides',
            value: '${stats.fatHitPct}%',
            progress: stats.fatHitPct / 100,
            color: AkeliColors.warning,
          ),
        ],
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color? color;
  final Gradient? gradient;

  const _GoalBar({
    required this.label,
    required this.value,
    required this.progress,
    this.color,
    this.gradient,
  }) : assert(color != null || gradient != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AkeliColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 7,
            child: Stack(
              children: [
                Container(color: AkeliColors.surfaceContainerHigh),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: gradient != null
                      ? Container(decoration: BoxDecoration(gradient: gradient))
                      : Container(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/nutrition/widgets/journey/journey_goals_card.dart
git commit -m "feat(ui): JourneyGoalsCard with weight + macro progress bars"
```

---

## Task 7: `JourneyCalendar`

**Files:**
- Create: `lib/features/nutrition/widgets/journey/journey_calendar.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/journey_stats.dart';

class JourneyCalendar extends StatelessWidget {
  final int year;
  final int month;
  final List<JourneyCalendarDay> days;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool canGoNext;

  const JourneyCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.days,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.canGoNext,
  });

  static const _monthNames = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];
  static const _dayHeaders = ['Di', 'Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa'];

  @override
  Widget build(BuildContext context) {
    appLogger.provider('JourneyCalendar build() | $year-$month');

    final firstOfMonth = DateTime(year, month, 1);
    final startDow = firstOfMonth.weekday % 7; // 0=Sun … 6=Sat
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final today = DateTime.now();
    final isCurrentMonth = today.year == year && today.month == month;

    final dayMap = {for (final d in days) d.date.day: d};

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // ── Month navigation ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AkeliColors.onSurfaceVariant),
                onPressed: onPrevMonth,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '${_monthNames[month]} $year',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoNext ? AkeliColors.onSurfaceVariant : AkeliColors.outlineVariant,
                ),
                onPressed: canGoNext ? onNextMonth : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Day-of-week headers ──
          Row(
            children: _dayHeaders
                .map(
                  (h) => Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          // ── Day grid ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startDow + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startDow) return const SizedBox.shrink();
              final dayNum = i - startDow + 1;
              final isToday = isCurrentMonth && dayNum == today.day;
              final isFuture = DateTime(year, month, dayNum).isAfter(today);
              final dayData = dayMap[dayNum];
              return _DayCell(
                dayNum: dayNum,
                isToday: isToday,
                isFuture: isFuture,
                status: isFuture ? null : dayData?.status,
              );
            },
          ),
          const SizedBox(height: 10),
          // ── Legend ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: Color(0xFF4ADE80), label: 'Atteint'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFFFACC15), label: 'Partiel'),
              SizedBox(width: 12),
              _LegendDot(color: Color(0xFFEF4444), label: 'Manqué'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int dayNum;
  final bool isToday;
  final bool isFuture;
  final JourneyDayStatus? status;

  const _DayCell({
    required this.dayNum,
    required this.isToday,
    required this.isFuture,
    this.status,
  });

  Color _bgColor() {
    if (isFuture || status == null) return AkeliColors.surfaceContainer;
    return switch (status!) {
      JourneyDayStatus.hit     => const Color(0xFFDCFCE7),
      JourneyDayStatus.partial => const Color(0xFFFEF9C3),
      JourneyDayStatus.missed  => const Color(0xFFFEE2E2),
      JourneyDayStatus.empty   => AkeliColors.surfaceContainer,
    };
  }

  Color _textColor() {
    if (isFuture) return AkeliColors.outlineVariant;
    return switch (status) {
      JourneyDayStatus.hit     => const Color(0xFF166534),
      JourneyDayStatus.partial => const Color(0xFF854D0E),
      JourneyDayStatus.missed  => const Color(0xFF991B1B),
      _                        => AkeliColors.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AkeliColors.primary, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          '$dayNum',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday ? AkeliColors.primary : _textColor(),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AkeliColors.onSurfaceVariant)),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/nutrition/widgets/journey/journey_calendar.dart
git commit -m "feat(ui): JourneyCalendar monthly grid with navigation and legend"
```

---

## Task 8: `JourneyTab` Root Widget

**Files:**
- Create: `lib/features/nutrition/widgets/journey/journey_tab.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/journey_provider.dart';
import 'journey_summary_row.dart';
import 'journey_streak_pill.dart';
import 'journey_goals_card.dart';
import 'journey_calendar.dart';

class JourneyTab extends ConsumerStatefulWidget {
  const JourneyTab({super.key});

  @override
  ConsumerState<JourneyTab> createState() => _JourneyTabState();
}

class _JourneyTabState extends ConsumerState<JourneyTab> {
  final _logger = appLogger;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _logger.provider('JourneyTab initState()');
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  void dispose() {
    _logger.provider('JourneyTab disposed');
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
    _logger.userAction('Journey prev month', screen: 'JourneyTab',
        metadata: {'year': _year, 'month': _month});
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year > now.year || (_year == now.year && _month >= now.month)) return;
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
    _logger.userAction('Journey next month', screen: 'JourneyTab',
        metadata: {'year': _year, 'month': _month});
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _year < now.year || (_year == now.year && _month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('JourneyTab build() | $_year-$_month');

    final statsAsync = ref.watch(
      journeyStatsProvider((year: _year, month: _month)),
    );

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        _logger.provider('JourneyTab → error | $e', error: e, stackTrace: st);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AkeliColors.error, size: 40),
              const SizedBox(height: 12),
              const Text('Impossible de charger le parcours',
                  style: TextStyle(color: AkeliColors.onSurfaceVariant)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(
                  journeyStatsProvider((year: _year, month: _month)),
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
      },
      data: (stats) {
        if (stats == null) {
          return const Center(
            child: Text('Aucune donnée disponible',
                style: TextStyle(color: AkeliColors.onSurfaceVariant)),
          );
        }
        _logger.provider('JourneyTab → data | streak: ${stats.currentStreak}');
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            JourneySummaryRow(stats: stats),
            const SizedBox(height: 12),
            JourneyStreakPill(stats: stats),
            const SizedBox(height: 12),
            JourneyGoalsCard(stats: stats),
            const SizedBox(height: 12),
            JourneyCalendar(
              year: _year,
              month: _month,
              days: stats.calendar,
              onPrevMonth: _prevMonth,
              onNextMonth: _nextMonth,
              canGoNext: _canGoNext,
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/nutrition/widgets/journey/journey_tab.dart
git commit -m "feat(ui): JourneyTab root widget with month navigation and loading/error states"
```

---

## Task 9: Wire into `NutritionPage`

**Files:**
- Modify: `lib/features/nutrition/nutrition_page.dart`

- [ ] **Step 1: Change `TabController` length from 2 to 3**

In `_NutritionPageState.initState()`, find:
```dart
_tabController = TabController(length: 2, vsync: this);
```
Replace with:
```dart
_tabController = TabController(length: 3, vsync: this);
```

- [ ] **Step 2: Add "Parcours" to the `tabs` list**

Find:
```dart
tabs: const [
  Tab(text: "Aujourd'hui"),
  Tab(text: "Semaine"),
],
```
Replace with:
```dart
tabs: const [
  Tab(text: "Aujourd'hui"),
  Tab(text: "Semaine"),
  Tab(text: "Parcours"),
],
```

- [ ] **Step 3: Add `JourneyTab` to `TabBarView`**

Find:
```dart
body: TabBarView(
  controller: _tabController,
  children: const [
    _TodayTab(),
    _WeeklyTab(),
  ],
),
```
Replace with:
```dart
body: TabBarView(
  controller: _tabController,
  children: const [
    _TodayTab(),
    _WeeklyTab(),
    JourneyTab(),
  ],
),
```

- [ ] **Step 4: Add the import at the top of `nutrition_page.dart`**

After the last existing import, add:
```dart
import 'widgets/journey/journey_tab.dart';
```

- [ ] **Step 5: Build to verify no compile errors**

```bash
flutter build apk --debug 2>&1 | tail -20
```
Expected: `BUILD SUCCESSFUL` with no errors.

- [ ] **Step 6: Run tests**

```bash
flutter test test/models/journey_stats_test.dart -v
```
Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/nutrition/nutrition_page.dart
git commit -m "feat: wire JourneyTab as third tab in NutritionPage"
```

---

## Self-Review Checklist

- [x] **SQL migration** — covers summary, streak (islands technique), goal hit rates, calendar, weight
- [x] **Null safety** — all `fromJson` fields use `?? 0` / `.toDouble()` / `?.toInt()` fallbacks
- [x] **`hasWeightGoal`** — used in `JourneyGoalsCard` to conditionally render weight bar
- [x] **`canGoNext`** — prevents navigation past current month
- [x] **Logging** — every provider, user action, DB call logged per CLAUDE.md standard
- [x] **Empty state** — handled in `JourneyTab` when `stats == null`
- [x] **Error + retry** — `JourneyTab` error branch invalidates provider on retry tap
- [x] **Type consistency** — `journeyStatsProvider` family uses `({int year, int month})` record throughout Tasks 4, 8
- [x] **`weightProgressPct`** defined in Task 2, used in Task 6 — matches
- [x] **`JourneyDayStatus`** defined in Task 2, used in Tasks 7 and 3 — matches
