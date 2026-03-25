import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// MacroType
// ---------------------------------------------------------------------------

enum MacroType { kcal, protein, carbs, fat }

// ---------------------------------------------------------------------------
// AkeliBadge — outlined pill tag
// ---------------------------------------------------------------------------

class AkeliBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const AkeliBadge({
    super.key,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AkeliColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: effectiveColor, width: 1),
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AkeliMacroBadge — filled colored pill for nutrition stats
// ---------------------------------------------------------------------------

class AkeliMacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final MacroType type;

  const AkeliMacroBadge({
    super.key,
    required this.label,
    required this.value,
    required this.type,
  });

  Color get _backgroundColor {
    switch (type) {
      case MacroType.kcal:
        return AkeliColors.secondary;
      case MacroType.protein:
        return AkeliColors.tertiary;
      case MacroType.carbs:
        return AkeliColors.secondary.withValues(alpha: 0.8);
      case MacroType.fat:
        return AkeliColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
