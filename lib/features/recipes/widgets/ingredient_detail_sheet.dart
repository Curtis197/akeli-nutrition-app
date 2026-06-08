import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/ingredient_provider.dart';
import 'package:akeli/shared/models/ingredient_detail.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class IngredientDetailSheet extends ConsumerWidget {
  final RecipeIngredient ingredient;

  const IngredientDetailSheet({super.key, required this.ingredient});

  static Future<void> show(BuildContext context, RecipeIngredient ingredient) {
    appLogger.userAction('IngredientDetailSheet opened',
        screen: 'IngredientDetailSheet',
        metadata: {'ingredientId': ingredient.ingredientId});
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IngredientDetailSheet(ingredient: ingredient),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider(
        'IngredientDetailSheet build() | ingredientId: ${ingredient.ingredientId}');
    final detailAsync =
        ref.watch(ingredientDetailProvider(ingredient.ingredientId));

    return Container(
      decoration: const BoxDecoration(
        color: AkeliColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AkeliRadius.xl)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AkeliColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ingredient.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AkeliColors.onSurface,
                        ),
                      ),
                    ),
                    if (ingredient.isOptional)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AkeliColors.surfaceContainer,
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.pill),
                        ),
                        child: Text(
                          'Optionnel',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AkeliColors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        AkeliColors.accentAmber.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AkeliRadius.pill),
                  ),
                  child: Text(
                    '${ingredient.quantity.toStringAsFixed(ingredient.quantity % 1 == 0 ? 0 : 1)} ${ingredient.unit}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.accentAmber,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: AkeliColors.surfaceContainerHighest),
                const SizedBox(height: 16),
                detailAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AkeliColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (detail) {
                    if (detail == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detail.caloriesPer100g != null ||
                            detail.proteinPer100g != null)
                          _NutritionSection(detail: detail),
                        if (detail.substitution != null)
                          _SubstitutionSection(text: detail.substitution!),
                        if (detail.marketNotes != null)
                          _MarketNotesSection(text: detail.marketNotes!),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  final IngredientDetail detail;
  const _NutritionSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valeurs nutritives (pour 100g)',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AkeliColors.onSurface),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (detail.caloriesPer100g != null)
              Expanded(
                  child: _MacroChip(
                      label: 'Calories',
                      value:
                          '${detail.caloriesPer100g!.toStringAsFixed(0)} kcal')),
            if (detail.proteinPer100g != null) ...[
              const SizedBox(width: 8),
              Expanded(
                  child: _MacroChip(
                      label: 'Protéines',
                      value: '${detail.proteinPer100g!.toStringAsFixed(1)}g')),
            ],
            if (detail.carbsPer100g != null) ...[
              const SizedBox(width: 8),
              Expanded(
                  child: _MacroChip(
                      label: 'Glucides',
                      value: '${detail.carbsPer100g!.toStringAsFixed(1)}g')),
            ],
          ],
        ),
        if (detail.fatPer100g != null || detail.fiberPer100g != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (detail.fatPer100g != null)
                Expanded(
                    child: _MacroChip(
                        label: 'Lipides',
                        value: '${detail.fatPer100g!.toStringAsFixed(1)}g')),
              if (detail.fiberPer100g != null) ...[
                const SizedBox(width: 8),
                Expanded(
                    child: _MacroChip(
                        label: 'Fibres',
                        value: '${detail.fiberPer100g!.toStringAsFixed(1)}g')),
              ],
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AkeliColors.onSurfaceVariant,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AkeliColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SubstitutionSection extends StatelessWidget {
  final String text;
  const _SubstitutionSection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AkeliColors.accentAmber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
          border: Border.all(
              color: AkeliColors.accentAmber.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.swap_horiz_rounded,
                color: AkeliColors.accentAmber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Substitution',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: AkeliColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketNotesSection extends StatelessWidget {
  final String text;
  const _MarketNotesSection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
          border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined,
                color: Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Où trouver',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: AkeliColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
