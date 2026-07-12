import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';

final _logger = appLogger;

class MealPlannerDaySelector extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const MealPlannerDaySelector({
    super.key,
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final isActive = _isSameDay(date, selected);
          return _DayChip(
            date: date,
            label: DateFormat.E(locale).format(date),
            isActive: isActive,
            onTap: () {
              if (isActive) return;
              HapticFeedback.selectionClick();
              _logger.userAction('Planner day chip selected', screen: 'MealPlannerPage',
                  metadata: {'date': date.toIso8601String()});
              onSelect(date);
            },
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime date;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DayChip({
    required this.date,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('day-chip-${date.toIso8601String()}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AkeliColors.primary : AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
          border: Border.all(
            color: isActive ? AkeliColors.primary : AkeliColors.outline.withValues(alpha: 0.2),
          ),
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
