import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';
import 'widgets/snack_picker_sheet.dart';

final _logger = appLogger;

/// Toggles a meal plan entry's consumed state, with optimistic UI update
/// and error snackbar on failure. Shared by MealPlannerPage's week view
/// and MealPlannerDayTabView's day view so both stay behaviorally identical.
Future<void> toggleMealConsumption(
  BuildContext context,
  WidgetRef ref, {
  required String entryId,
  required bool isCurrentlyConsumed,
  required String screen,
}) async {
  try {
    await ref.read(mealConsumptionProvider.notifier).toggleConsumption(
          entryId,
          isCurrentlyConsumed: isCurrentlyConsumed,
        );
  } catch (e) {
    _logger.userAction('toggleConsumption ERROR | $e',
        screen: screen, metadata: {'error': e.toString()});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).mealPlannerConsumptionError),
        ),
      );
    }
  }
}

/// Opens the snack picker sheet and adds the selection to [mealPlanId] on
/// [date]. Shared by MealPlannerPage's week view and MealPlannerDayTabView's
/// day view so both stay behaviorally identical.
Future<void> addSnackToDay(
  BuildContext context,
  WidgetRef ref,
  String mealPlanId,
  DateTime date, {
  required String screen,
}) async {
  _logger.userAction('Add snack tapped', screen: screen,
      metadata: {'date': date.toIso8601String()});
  final l10n = AppLocalizations.of(context);

  final selection = await showModalBottomSheet<SnackSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SnackPickerSheet(),
  );
  if (selection == null || !context.mounted) return;

  try {
    switch (selection) {
      case RecipeSnackSelection(:final recipeId, :final weightG):
        await ref.read(snackEntryProvider.notifier).addSnack(
              mealPlanId: mealPlanId,
              recipeId: recipeId,
              scheduledDate: date,
              weightG: weightG,
            );
      case CustomSnackSelection(:final name, :final calories,
          :final proteinG, :final carbsG, :final fatG):
        await ref.read(snackEntryProvider.notifier).addCustomSnack(
              mealPlanId: mealPlanId,
              scheduledDate: date,
              name: name,
              calories: calories,
              proteinG: proteinG,
              carbsG: carbsG,
              fatG: fatG,
            );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.feedAddedToMealPlan),
          backgroundColor: AkeliColors.primary,
        ),
      );
    }
  } catch (e) {
    _logger.edge('add-snack', 'ERROR | $e', error: e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mealPlannerError(e.toString())),
          backgroundColor: AkeliColors.error,
        ),
      );
    }
  }
}
