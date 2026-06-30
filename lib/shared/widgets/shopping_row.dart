import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/quantity_formatter.dart';
import 'package:akeli/core/unit_converter.dart';
import 'package:akeli/shared/models/meal_plan.dart';

class AkeliShoppingRow extends StatelessWidget {
  final ShoppingItem item;
  final bool isChecked;
  final VoidCallback onToggle;
  final bool isUsLocale;
  final String locale;

  const AkeliShoppingRow({
    super.key,
    required this.item,
    required this.isChecked,
    required this.onToggle,
    this.isUsLocale = false,
    this.locale = 'fr',
  });

  @override
  Widget build(BuildContext context) {
    final converted = isUsLocale
        ? UnitConverter.toImperial(item.quantity, item.unit)
        : (quantity: item.quantity, unit: item.unit);
    final qtyText = formatQuantity(
      converted.quantity,
      converted.unit,
      locale: locale,
      ingredientId: item.ingredientId,
      ingredientName: item.name,
    );

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isChecked
              ? AkeliColors.surfaceContainerLow
              : AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isChecked
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Opacity(
          opacity: isChecked ? 0.6 : 1.0,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked ? AkeliColors.primary : Colors.transparent,
                  border: isChecked
                      ? null
                      : Border.all(color: AkeliColors.outlineVariant, width: 2),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isChecked
                            ? AkeliColors.onSurfaceVariant
                            : AkeliColors.onSurface,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (item.pricePer100g > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${item.priceDisplay} (${item.rateDisplay})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isChecked
                              ? AkeliColors.onSurfaceVariant.withValues(alpha: 0.7)
                              : AkeliColors.primary,
                        ),
                      ),
                      if (item.packageSize != null && item.packageSize! > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${item.getBuyDisplay(Localizations.localeOf(context).languageCode)} • ${item.priceBoughtDisplay}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isChecked
                                ? AkeliColors.onSurfaceVariant.withValues(alpha: 0.5)
                                : AkeliColors.secondary,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isChecked
                      ? AkeliColors.surfaceContainerHighest
                      : AkeliColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  qtyText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.onSurfaceVariant,
                    decoration:
                        isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
