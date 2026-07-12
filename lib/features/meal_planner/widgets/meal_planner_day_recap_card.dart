import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';

final _logger = appLogger;

class MealPlannerDayRecapCard extends StatelessWidget {
  final DateTime date;
  final double consumedKcal;
  final double targetKcal;

  const MealPlannerDayRecapCard({
    super.key,
    required this.date,
    required this.consumedKcal,
    required this.targetKcal,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat('EEEE d MMMM', locale).format(date);
    final rawProgress = targetKcal > 0 ? consumedKcal / targetKcal : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);

    _logger.provider('MealPlannerDayRecapCard build() | date: $formattedDate | '
        'consumed: ${consumedKcal.toInt()} | target: ${targetKcal.toInt()}');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AkeliRadius.card),
        border: Border.all(color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${consumedKcal.toInt()} / ${targetKcal.toInt()} kcal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AkeliColors.accentAmber,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AkeliRadius.sm),
            child: LinearProgressIndicator(
              key: const Key('day-recap-progress'),
              value: progress,
              minHeight: 8,
              backgroundColor: AkeliColors.surfaceContainerLowest,
              valueColor: const AlwaysStoppedAnimation(AkeliColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
