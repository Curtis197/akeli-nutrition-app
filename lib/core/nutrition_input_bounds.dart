// lib/core/nutrition_input_bounds.dart

import 'package:akeli/core/logger.dart';

// Logger import required by CLAUDE.md logging standard.
// Pure constants/predicates — no side-effect logging calls needed at runtime.
// ignore: unused_element
final _logger = appLogger;

/// Client-side mirror of the plausibility bounds enforced by
/// public.calculate_nutrition_targets() (which returns zero rows when
/// violated). Spec §1.10/§1.11, D11:
/// docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md
/// If the SQL bounds ever change, change these together.
class NutritionInputBounds {
  static const double minWeightKg = 30;
  static const double maxWeightKg = 300;
  static const double minHeightCm = 120;
  static const double maxHeightCm = 230;
  static const int minAge = 18;
  static const int maxAge = 100;
  static const double underweightBmi = 18.5;

  /// null passes: required-ness is each form's concern, not the bounds'.
  static bool weightOk(double? kg) =>
      kg == null || (kg >= minWeightKg && kg <= maxWeightKg);

  static bool heightOk(double? cm) =>
      cm == null || (cm >= minHeightCm && cm <= maxHeightCm);

  static bool ageOk(int? years) =>
      years == null || (years >= minAge && years <= maxAge);

  /// True when a target weight implies an underweight BMI for the given
  /// height — soft warning only (§1.11), never blocks.
  static bool targetUnderweight(double? targetKg, double? heightCm) {
    if (targetKg == null || heightCm == null || heightCm <= 0) return false;
    final hM = heightCm / 100;
    return targetKg / (hM * hM) < underweightBmi;
  }
}
