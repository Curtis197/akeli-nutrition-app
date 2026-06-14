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
            value: '${stats.calorieHitPct}%',
            progress: stats.calorieHitPct / 100,
            color: AkeliColors.primary,
            subtitle: 'Vous avez atteint votre objectif calorique ${stats.calorieHitPct}% des jours logués.',
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
  final String? subtitle;

  const _GoalBar({
    required this.label,
    required this.value,
    required this.progress,
    this.color,
    this.gradient,
    this.subtitle,
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
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 11, color: AkeliColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
