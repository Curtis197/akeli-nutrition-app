import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// AkeliTabBar
// ---------------------------------------------------------------------------

class AkeliTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color? indicatorColor;

  const AkeliTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = indicatorColor ?? AkeliColors.primary;
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = index == selectedIndex;
        return InkWell(
          onTap: () => onTabSelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: isSelected
                    ? BorderSide(color: effectiveColor, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Text(
              tabs[index],
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? effectiveColor
                        : AkeliColors.textSecondary,
                  ),
            ),
          ),
        );
      }),
    );
  }
}
