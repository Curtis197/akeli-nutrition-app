import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../providers/mode_provider.dart';

final _logger = appLogger;

class MealPlannerViewToggle extends ConsumerWidget {
  final PlannerViewMode value;
  final ValueChanged<PlannerViewMode> onChanged;

  const MealPlannerViewToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _select(PlannerViewMode mode) {
    if (mode == value) return;
    HapticFeedback.selectionClick();
    _logger.userAction('Planner view toggle changed', screen: 'MealPlannerPage',
        metadata: {'mode': mode.name});
    onChanged(mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appMode = ref.watch(currentModeProvider);
    final isBeauty = appMode == AppMode.beauty;
    final accentColor = getAppModeColor(appMode);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(l10n.plannerViewToggleDay, PlannerViewMode.day,
              const Key('planner-view-toggle-day'), accentColor),
          _segment(l10n.plannerViewToggleWeek, PlannerViewMode.week,
              const Key('planner-view-toggle-week'), accentColor),
        ],
      ),
    );
  }

  Widget _segment(String label, PlannerViewMode mode, Key key, Color accentColor) {
    final isActive = value == mode;
    return GestureDetector(
      key: key,
      onTap: () => _select(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AkeliColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
