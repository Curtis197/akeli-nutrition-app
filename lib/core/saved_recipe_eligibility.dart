// lib/core/saved_recipe_eligibility.dart
import 'package:akeli/core/logger.dart';

final _logger = appLogger;

/// Mirrors the SQL formula in evaluate_saved_recipe_eligibility /
/// get_saved_recipe_eligibility_progress (supabase/migrations/
/// 20260705000002_saved_recipe_variety_eligibility.sql). Keep both in sync
/// by hand if this formula ever changes.
int savedRecipeEligibilityTarget(int mealVarietyDays) {
  final target = mealVarietyDays == 0 ? 7 : mealVarietyDays * 2;
  _logger.d('savedRecipeEligibilityTarget | varietyDays: $mealVarietyDays -> target: $target');
  return target;
}
