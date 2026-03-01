import 'package:flutter/material.dart';
import '../../core/theme.dart';

class MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;
  final IconData? icon;

  const MacroCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AkeliColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AkeliSpacing.md,
        vertical: AkeliSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: cardColor),
            const SizedBox(height: 2),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cardColor,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: cardColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AkeliColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class MacroRow extends StatelessWidget {
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  const MacroRow({
    super.key,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (calories != null)
          Expanded(
            child: MacroCard(
              label: 'Calories',
              value: calories!.toInt().toString(),
              unit: 'kcal',
              color: AkeliColors.secondary,
              icon: Icons.local_fire_department_rounded,
            ),
          ),
        if (calories != null && proteinG != null)
          const SizedBox(width: AkeliSpacing.sm),
        if (proteinG != null)
          Expanded(
            child: MacroCard(
              label: 'Protéines',
              value: '${proteinG!.toInt()}g',
              unit: 'g',
              color: AkeliColors.primary,
              icon: Icons.fitness_center_rounded,
            ),
          ),
        if (proteinG != null && carbsG != null)
          const SizedBox(width: AkeliSpacing.sm),
        if (carbsG != null)
          Expanded(
            child: MacroCard(
              label: 'Glucides',
              value: '${carbsG!.toInt()}g',
              unit: 'g',
              color: AkeliColors.tertiary,
              icon: Icons.grain_rounded,
            ),
          ),
        if (carbsG != null && fatG != null)
          const SizedBox(width: AkeliSpacing.sm),
        if (fatG != null)
          Expanded(
            child: MacroCard(
              label: 'Lipides',
              value: '${fatG!.toInt()}g',
              unit: 'g',
              color: AkeliColors.warning,
              icon: Icons.water_drop_rounded,
            ),
          ),
      ],
    );
  }
}
