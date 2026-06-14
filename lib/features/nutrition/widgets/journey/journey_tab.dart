import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/journey_provider.dart';
import 'journey_summary_row.dart';
import 'journey_streak_pill.dart';
import 'journey_goals_card.dart';
import 'journey_weight_chart.dart';
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
            const JourneyWeightChart(),
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
