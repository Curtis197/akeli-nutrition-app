import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/journey_stats.dart';
import 'package:akeli/l10n/app_localizations.dart';

final _logger = appLogger;

class JourneySummaryRow extends StatelessWidget {
  final JourneyStats stats;

  const JourneySummaryRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    _logger.provider('JourneySummaryRow build()');
    final l10n = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _StatCard(icon: '📅', value: '${stats.totalDays}', label: l10n.journeySummaryDays),
        _StatCard(icon: '✅', value: '${stats.daysLogged}', label: l10n.journeySummaryTracked),
        _StatCard(icon: '🍽️', value: '${stats.mealsConsumed}', label: l10n.journeySummaryMeals),
        _StatCard(icon: '📊', value: '${stats.consistencyPct}%', label: l10n.journeySummaryConsistency),
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
          Text(icon, style: const TextStyle(fontSize: 24)),
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
