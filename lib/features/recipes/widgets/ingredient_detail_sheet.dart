import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/ingredient_provider.dart';
import 'package:akeli/shared/models/ingredient_detail.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:akeli/core/quantity_formatter.dart';
import 'package:akeli/l10n/app_localizations.dart';

class IngredientDetailSheet extends ConsumerWidget {
  final RecipeIngredient ingredient;
  final ScrollController? scrollController;

  const IngredientDetailSheet({
    super.key,
    required this.ingredient,
    this.scrollController,
  });

  static Future<void> show(BuildContext context, RecipeIngredient ingredient) {
    appLogger.userAction('IngredientDetailSheet opened',
        screen: 'IngredientDetailSheet',
        metadata: {'ingredientId': ingredient.ingredientId});
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => IngredientDetailSheet(
          ingredient: ingredient,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    appLogger.provider(
        'IngredientDetailSheet build() | ingredientId: ${ingredient.ingredientId}');
    final detailAsync =
        ref.watch(ingredientDetailProvider(ingredient.ingredientId));
    final bottomPad = MediaQuery.of(context).padding.bottom + 24;

    final tagLabels = {
      'high_protein': l10n.ingredientDetailTagHighProtein,
      'low_fat': l10n.ingredientDetailTagLowFat,
      'gluten_free': l10n.ingredientDetailTagGlutenFree,
      'african_staple': l10n.ingredientDetailTagAfricanStaple,
      'very_hard_to_find_eu': l10n.ingredientDetailTagHardToFindEu,
    };

    return Container(
      decoration: const BoxDecoration(
        color: AkeliColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AkeliRadius.xl)),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.only(bottom: bottomPad),
        children: [
          // Drag handle
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
          // Hero image — full width
          detailAsync.whenOrNull(
            data: (detail) {
              if (detail?.imageUrl == null) return null;
              return CachedNetworkImage(
                imageUrl: detail!.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: AkeliColors.surfaceContainerLow,
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              );
            },
          ) ?? const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + optional badge
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
                          l10n.ingredientDetailOptional,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AkeliColors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
                // Tags pills
                detailAsync.whenOrNull(
                  data: (detail) {
                    if (detail == null || detail.tags.isEmpty) return null;
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: detail.tags
                            .map((tag) => _TagPill(
                                  tag: tag,
                                  label: tagLabels[tag] ?? tag.replaceAll('_', ' '),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ) ?? const SizedBox.shrink(),
                const SizedBox(height: 12),
                // Quantity pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AkeliColors.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AkeliRadius.pill),
                  ),
                  child: Text(
                    formatQuantity(
                      ingredient.quantity,
                      ingredient.unit,
                      locale: AppLocalizations.of(context).localeName,
                      ingredientId: ingredient.ingredientId,
                      ingredientName: ingredient.name,
                    ),
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
                        if (detail.description != null)
                          _DescriptionSection(text: detail.description!),
                        if (detail.caloriesPer100g != null ||
                            detail.proteinPer100g != null)
                          _NutritionSection(detail: detail),
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

class _TagPill extends StatelessWidget {
  final String tag;
  final String label;
  const _TagPill({required this.tag, required this.label});

  static const _tagColors = {
    'high_protein': Color(0xFF2E7D32),
    'low_fat': Color(0xFF1565C0),
    'gluten_free': Color(0xFF6A1B9A),
    'african_staple': Color(0xFFE65100),
    'very_hard_to_find_eu': Color(0xFF78350F),
  };

  @override
  Widget build(BuildContext context) {
    final color = _tagColors[tag] ?? AkeliColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String text;
  const _DescriptionSection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.65,
          color: AkeliColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  final IngredientDetail detail;
  const _NutritionSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ingredientDetailNutritionTitle,
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
                      label: l10n.ingredientDetailEnergy,
                      value:
                          '${detail.caloriesPer100g!.toStringAsFixed(0)} kcal')),
            if (detail.proteinPer100g != null) ...[
              const SizedBox(width: 8),
              Expanded(
                  child: _MacroChip(
                      label: l10n.nutritionProtein,
                      value: '${detail.proteinPer100g!.toStringAsFixed(1)} g')),
            ],
            if (detail.carbsPer100g != null) ...[
              const SizedBox(width: 8),
              Expanded(
                  child: _MacroChip(
                      label: l10n.nutritionCarbs,
                      value: '${detail.carbsPer100g!.toStringAsFixed(1)} g')),
            ],
          ],
        ),
        if (detail.fatPer100g != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _MacroChip(
                      label: l10n.nutritionFat,
                      value: '${detail.fatPer100g!.toStringAsFixed(1)} g')),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
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
