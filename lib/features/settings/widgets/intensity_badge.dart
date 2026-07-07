// lib/features/settings/widgets/intensity_badge.dart

import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Pill badge showing weight evolution pace intensity: Relaxed / Ideal / Aggressive / Dangerous.
///
/// Returns SizedBox.shrink() when inputs are insufficient to compute.
class IntensityBadge extends StatelessWidget {
  final double? paceKgWeek;
  final bool isGain;

  const IntensityBadge({
    super.key,
    required this.paceKgWeek,
    required this.isGain,
  });

  static (String label, Color bg, Color fg) _compute(
    double pace,
    bool isGain,
    AppLocalizations l10n,
  ) {
    if (pace < 0.25) {
      return (
        l10n.intensityRelaxed,
        AkeliColors.secondaryContainer,
        AkeliColors.onSecondaryContainer,
      );
    }

    if (isGain) {
      if (pace <= 0.5) {
        return (
          l10n.intensityIdeal,
          AkeliColors.tertiaryFixed,
          AkeliColors.onTertiaryFixed,
        );
      }
      if (pace <= 0.75) {
        return (
          l10n.intensityAggressive,
          AkeliColors.error.withValues(alpha: 0.12),
          AkeliColors.error,
        );
      }
      return (l10n.intensityDangerous, AkeliColors.error, Colors.white);
    } else {
      // Weight loss
      if (pace <= 1.0) {
        return (
          l10n.intensityIdeal,
          AkeliColors.tertiaryFixed,
          AkeliColors.onTertiaryFixed,
        );
      }
      if (pace <= 1.5) {
        return (
          l10n.intensityAggressive,
          AkeliColors.error.withValues(alpha: 0.12),
          AkeliColors.error,
        );
      }
      return (l10n.intensityDangerous, AkeliColors.error, Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (paceKgWeek == null || paceKgWeek! <= 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final (label, bg, fg) = _compute(paceKgWeek!, isGain, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.08,
        ),
      ),
    );
  }
}
