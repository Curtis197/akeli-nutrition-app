import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// AkeliProgressCircle
// ---------------------------------------------------------------------------

class AkeliProgressCircle extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final double progress;
  final Color? color;
  final VoidCallback? onTap;

  const AkeliProgressCircle({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.progress,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AkeliColors.primary;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: clampedProgress,
                    strokeWidth: 6,
                    color: effectiveColor,
                    backgroundColor: AkeliColors.textMuted,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: effectiveColor,
                          ),
                    ),
                    if (unit != null)
                      Text(
                        unit!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AkeliColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AkeliSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AkeliColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
