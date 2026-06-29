import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/unit_converter.dart';
import 'package:akeli/l10n/app_localizations.dart';

final _logger = appLogger;

class AkeliWeightStepper extends StatelessWidget {
  final double weight;
  final bool isUs;
  final ValueChanged<double> onChanged;

  const AkeliWeightStepper({
    super.key,
    required this.weight,
    required this.isUs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayWeight = isUs ? UnitConverter.kgToLb(weight) : weight;
    final displayUnit = isUs ? l10n.unitPounds : l10n.unitKilograms;

    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onPressed: () {
              final newDisplayWeight = double.parse((displayWeight - 0.1).toStringAsFixed(1));
              final newWeightKg = isUs ? UnitConverter.lbToKg(newDisplayWeight) : newDisplayWeight;
              _logger.userAction('Weight stepper −', screen: 'AkeliWeightStepper',
                  metadata: {'from': weight, 'to': newWeightKg, 'displayFrom': displayWeight, 'displayTo': newDisplayWeight});
              onChanged(newWeightKg);
            },
            isActive: false,
          ),
          const SizedBox(width: AkeliSpacing.xl),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayWeight.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AkeliColors.primaryContainer,
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                      letterSpacing: -1.5,
                    ),
              ),
              Text(
                displayUnit,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
              ),
            ],
          ),
          const SizedBox(width: AkeliSpacing.xl),
          _StepperButton(
            icon: Icons.add,
            onPressed: () {
              final newDisplayWeight = double.parse((displayWeight + 0.1).toStringAsFixed(1));
              final newWeightKg = isUs ? UnitConverter.lbToKg(newDisplayWeight) : newDisplayWeight;
              _logger.userAction('Weight stepper +', screen: 'AkeliWeightStepper',
                  metadata: {'from': weight, 'to': newWeightKg, 'displayFrom': displayWeight, 'displayTo': newDisplayWeight});
              onChanged(newWeightKg);
            },
            isActive: true,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AkeliColors.primaryContainer : AkeliColors.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AkeliColors.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
