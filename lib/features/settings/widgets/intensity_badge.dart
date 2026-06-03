// lib/features/settings/widgets/intensity_badge.dart

import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Pill badge showing weight-loss pace: Intense / Modéré / Durable.
///
/// Returns SizedBox.shrink() when inputs are insufficient to compute.
class IntensityBadge extends StatelessWidget {
  final double? currentKg;
  final double? targetKg;
  /// Timeline in months (use weeks / 4.33 to convert from weeks).
  final double? months;

  const IntensityBadge({
    super.key,
    required this.currentKg,
    required this.targetKg,
    required this.months,
  });

  static (String label, Color bg, Color fg) _compute(double kgPerMonth) {
    if (kgPerMonth >= 2) {
      return (
        'Intense',
        AkeliColors.error.withValues(alpha: 0.12),
        AkeliColors.error,
      );
    } else if (kgPerMonth >= 1) {
      return (
        'Modéré',
        AkeliColors.tertiaryFixed,
        AkeliColors.onTertiaryFixed,
      );
    } else {
      return (
        'Durable',
        AkeliColors.secondaryContainer,
        AkeliColors.onSecondaryContainer,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentKg == null ||
        targetKg == null ||
        months == null ||
        months! <= 0) {
      return const SizedBox.shrink();
    }
    final delta = (targetKg! - currentKg!).abs();
    if (delta == 0) return const SizedBox.shrink();

    final kgPerMonth = delta / months!;
    final (label, bg, fg) = _compute(kgPerMonth);

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
