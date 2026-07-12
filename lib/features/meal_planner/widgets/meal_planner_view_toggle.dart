import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/meal_plan_provider.dart';

final _logger = appLogger;

class MealPlannerViewToggle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(l10n.plannerViewToggleWeek, PlannerViewMode.week,
              const Key('planner-view-toggle-week')),
          _segment(l10n.plannerViewToggleDay, PlannerViewMode.day,
              const Key('planner-view-toggle-day')),
        ],
      ),
    );
  }

  Widget _segment(String label, PlannerViewMode mode, Key key) {
    final isActive = value == mode;
    return GestureDetector(
      key: key,
      onTap: () => _select(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AkeliColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? AkeliColors.onPrimary : AkeliColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
