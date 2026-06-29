import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/shared/models/journey_stats.dart';

final _logger = appLogger;

class JourneyStreakPill extends StatelessWidget {
  final JourneyStats stats;

  const JourneyStreakPill({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    _logger.provider('JourneyStreakPill build()');
    final l10n = AppLocalizations.of(context);
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
                l10n.journeyStreak(stats.currentStreak),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AkeliColors.onSurface,
                  height: 1,
                ),
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
              Text(
                l10n.journeyBestStreakRecord,
                style: const TextStyle(fontSize: 10, color: AkeliColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
