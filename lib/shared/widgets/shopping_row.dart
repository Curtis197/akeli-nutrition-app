import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// AkeliShoppingRow
// ---------------------------------------------------------------------------

class AkeliShoppingRow extends StatelessWidget {
  final String quantity;
  final String ingredient;
  final bool checked;
  final VoidCallback onToggle;

  const AkeliShoppingRow({
    super.key,
    required this.quantity,
    required this.ingredient,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Opacity(
        opacity: checked ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AkeliSpacing.sm,
            horizontal: AkeliSpacing.xs,
          ),
          child: Row(
            children: [
              Text(
                quantity,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.secondary,
                    ),
              ),
              const SizedBox(width: AkeliSpacing.sm),
              Expanded(
                child: Text(
                  ingredient,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AkeliColors.textPrimary,
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                      ),
                ),
              ),
              const SizedBox(width: AkeliSpacing.sm),
              _AkeliCheckbox(checked: checked),
            ],
          ),
        ),
      ),
    );
  }
}

class _AkeliCheckbox extends StatelessWidget {
  final bool checked;

  const _AkeliCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AkeliColors.primary : Colors.transparent,
        border: Border.all(
          color: AkeliColors.primary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AkeliRadius.sm / 2),
      ),
      child: checked
          ? const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }
}
