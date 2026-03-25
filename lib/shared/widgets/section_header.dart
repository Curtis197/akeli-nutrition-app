import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// AkeliSectionHeader
// ---------------------------------------------------------------------------

class AkeliSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const AkeliSectionHeader({
    super.key,
    required this.title,
    this.color,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AkeliColors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: effectiveColor,
              ),
        ),
        if (trailingLabel != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(AkeliRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AkeliSpacing.xs,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailingLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AkeliColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AkeliColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
