// lib/features/nutrition_plan/widgets/meal_schedule_widget.dart
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/meal_type_l10n.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

class MealScheduleWidget extends StatefulWidget {
  final List<MealDistribution> initialDistributions;
  final int totalCalorieGoal;
  final void Function(List<MealDistribution> distributions) onChanged;
  final void Function(bool isValid) onSaveEnabled;

  const MealScheduleWidget({
    super.key,
    required this.initialDistributions,
    required this.totalCalorieGoal,
    required this.onChanged,
    required this.onSaveEnabled,
  });

  @override
  State<MealScheduleWidget> createState() => _MealScheduleWidgetState();
}

class _MealScheduleWidgetState extends State<MealScheduleWidget> {
  final _logger = appLogger;
  // Stable per-slot keys so ReorderableListView doesn't lose focus
  late List<(int key, MealDistribution dist)> _slots;
  int _nextKey = 0;
  final Set<int> _expandedMacroIndices = {};

  @override
  void initState() {
    super.initState();
    _logger.provider(
        'MealScheduleWidget initState | slots: ${widget.initialDistributions.length}');
    _slots = widget.initialDistributions.map((d) => (_nextKey++, d)).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emit();
      }
    });
  }

  double get _totalCaloriePct =>
      _slots.fold(0.0, (s, e) => s + e.$2.caloriePct);

  bool get _isCalorieValid => (_totalCaloriePct - 100).abs() <= 1.0;

  bool _isMacroValid(MealDistribution d) {
    if (d.proteinPct == null) return true; // macros not set — optional
    final total = (d.proteinPct ?? 0) + (d.carbsPct ?? 0) + (d.fatPct ?? 0);
    return (total - 100).abs() <= 1.0;
  }

  void _emit() {
    final dists = _slots
        .asMap()
        .entries
        .map((e) => e.value.$2.copyWith(sortOrder: e.key))
        .toList();
    widget.onChanged(dists);
    widget.onSaveEnabled(_isCalorieValid && dists.every(_isMacroValid));
  }

  void _addSlot() {
    _logger.userAction('MealScheduleWidget add slot');
    setState(() {
      _slots = [
        ..._slots,
        (
          _nextKey++,
          MealDistribution(
            mealType: 'snack',
            sortOrder: _slots.length,
            caloriePct: 0,
          )
        ),
      ];
    });
    _emit();
  }

  void _removeSlot(int index) {
    _logger.userAction('MealScheduleWidget remove slot | index: $index');
    setState(() {
      _slots = List.of(_slots)..removeAt(index);
      // Shift expanded indices after the removed slot
      final shifted = <int>{};
      for (final i in _expandedMacroIndices) {
        if (i < index) {
          shifted.add(i);
        } else if (i > index) {
          shifted.add(i - 1);
        }
        // i == index is the removed slot, drop it
      }
      _expandedMacroIndices
        ..clear()
        ..addAll(shifted);
    });
    _emit();
  }

  void _updateSlot(int index, MealDistribution updated) {
    setState(() {
      final list = List.of(_slots);
      list[index] = (list[index].$1, updated);
      _slots = list;
    });
    _emit();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final list = List.of(_slots);
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      _slots = list;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _logger.provider(
        'MealScheduleWidget build() | slots: ${_slots.length} | calTotal: ${_totalCaloriePct.toStringAsFixed(1)}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total calorie indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mealScheduleCalorieTotal(
                      _totalCaloriePct.toStringAsFixed(0)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (!_isCalorieValid)
                Text(
                  l10n.mealScheduleCalorieTotalError,
                  style:
                      const TextStyle(color: AkeliColors.error, fontSize: 12),
                ),
            ],
          ),
        ),

        // Slot list
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _slots.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final (key, dist) = _slots[index];
            final isMacroExpanded = _expandedMacroIndices.contains(index);
            return _SlotCard(
              key: ValueKey(key),
              index: index,
              distribution: dist,
              totalCalorieGoal: widget.totalCalorieGoal,
              canDelete: _slots.length > 1,
              isMacroExpanded: isMacroExpanded,
              onToggleMacro: () => setState(() {
                if (isMacroExpanded) {
                  _expandedMacroIndices.remove(index);
                } else {
                  _expandedMacroIndices.add(index);
                }
              }),
              onUpdate: (updated) => _updateSlot(index, updated),
              onDelete: () => _removeSlot(index),
            );
          },
        ),

        // Add slot button
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            key: const Key('addSlotButton'),
            onPressed: _addSlot,
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.mealScheduleAddSlot),
            style: OutlinedButton.styleFrom(
              foregroundColor: AkeliColors.primary,
              side:
                  BorderSide(color: AkeliColors.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AkeliRadius.md)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Internal slot card ──────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final int index;
  final MealDistribution distribution;
  final int totalCalorieGoal;
  final bool canDelete;
  final bool isMacroExpanded;
  final VoidCallback onToggleMacro;
  final void Function(MealDistribution) onUpdate;
  final VoidCallback onDelete;

  const _SlotCard({
    super.key,
    required this.index,
    required this.distribution,
    required this.totalCalorieGoal,
    required this.canDelete,
    required this.isMacroExpanded,
    required this.onToggleMacro,
    required this.onUpdate,
    required this.onDelete,
  });

  static const _categories = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kcal = (totalCalorieGoal * distribution.caloriePct / 100).round();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: drag handle + category dropdown + delete
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle,
                      color: AkeliColors.outline),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    key: Key('categoryDropdown_$index'),
                    value: distribution.mealType,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              key: Key('categoryOption_$cat'),
                              value: cat,
                              child: Text(mealTypeLabel(l10n, cat)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        onUpdate(distribution.copyWith(mealType: val));
                      }
                    },
                  ),
                ),
                if (canDelete)
                  IconButton(
                    key: Key('deleteSlot_$index'),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: l10n.mealScheduleDeleteSlotTooltip,
                    color: AkeliColors.error,
                    onPressed: onDelete,
                  ),
              ],
            ),

            // Nickname field
            TextFormField(
              initialValue: distribution.nickname ?? '',
              decoration: InputDecoration(
                hintText: l10n.mealScheduleNicknamePlaceholder,
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) => onUpdate(distribution.copyWith(
                nickname: val.trim().isEmpty ? null : val.trim(),
              )),
            ),

            // Calorie % input
            Row(
              children: [
                Text(l10n.mealScheduleCaloriePct,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AkeliColors.onSurfaceVariant)),
                const Spacer(),
                _InlinePercentField(
                  value: distribution.caloriePct,
                  min: 0,
                  max: 100,
                  color: AkeliColors.primary,
                  onChanged: (val) => onUpdate(distribution.copyWith(
                    caloriePct: val,
                    calorieTarget: totalCalorieGoal * val / 100,
                  )),
                ),
                const SizedBox(width: 8),
                Text(
                  '· $kcal kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Macro section (expandable)
            InkWell(
              onTap: onToggleMacro,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(l10n.mealScheduleMacroSection,
                        style: const TextStyle(
                            fontSize: 12, color: AkeliColors.primary)),
                    const Spacer(),
                    Icon(
                        isMacroExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 16,
                        color: AkeliColors.primary),
                  ],
                ),
              ),
            ),
            if (isMacroExpanded) ...[
              _macroInput(
                context,
                l10n.mealScheduleProteinPct,
                distribution.proteinPct ?? 25.0,
                (v) => onUpdate(distribution.copyWith(proteinPct: v)),
              ),
              _macroInput(
                context,
                l10n.mealScheduleCarbsPct,
                distribution.carbsPct ?? 50.0,
                (v) => onUpdate(distribution.copyWith(carbsPct: v)),
              ),
              _macroInput(
                context,
                l10n.mealScheduleFatPct,
                distribution.fatPct ?? 25.0,
                (v) => onUpdate(distribution.copyWith(fatPct: v)),
              ),
              _macroTotalIndicator(context, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _macroInput(
    BuildContext context,
    String label,
    double value,
    void Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AkeliColors.onSurfaceVariant)),
          const Spacer(),
          _InlinePercentField(
            value: value,
            min: 0,
            max: 100,
            color: AkeliColors.accentAmber,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _macroTotalIndicator(BuildContext context, AppLocalizations l10n) {
    final total = (distribution.proteinPct ?? 25) +
        (distribution.carbsPct ?? 50) +
        (distribution.fatPct ?? 25);
    final isValid = (total - 100).abs() <= 1.0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${total.toStringAsFixed(0)}% ${isValid ? '✓' : '— ${l10n.mealScheduleMacroError}'}',
        style: TextStyle(
          fontSize: 11,
          color: isValid ? AkeliColors.primary : AkeliColors.error,
        ),
      ),
    );
  }
}

class _InlinePercentField extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _InlinePercentField({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  State<_InlinePercentField> createState() => _InlinePercentFieldState();
}

class _InlinePercentFieldState extends State<_InlinePercentField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toStringAsFixed(0));
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        final entered = double.tryParse(_ctrl.text);
        if (entered == null || entered < widget.min || entered > widget.max) {
          _ctrl.text = widget.value.toStringAsFixed(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_InlinePercentField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value.toStringAsFixed(0) != _ctrl.text) {
      _ctrl.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AkeliRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onChanged: (v) {
                final entered = double.tryParse(v);
                if (entered != null) {
                  if (entered >= widget.min && entered <= widget.max) {
                    widget.onChanged(entered);
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: widget.color.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
