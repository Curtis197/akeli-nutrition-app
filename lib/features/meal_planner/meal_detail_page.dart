import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/shared/models/meal_plan.dart';
import 'package:akeli/shared/widgets/badge.dart';
import 'package:akeli/shared/widgets/section_header.dart';

class MealDetailPage extends ConsumerWidget {
  final String mealId;
  const MealDetailPage({super.key, required this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeMealPlanProvider);
    final consumeState = ref.watch(mealConsumptionProvider);

    appLogger.provider('MealDetailPage build() | mealId: $mealId | planAsync.isLoading: ${planAsync.isLoading}');

    ref.listen(mealConsumptionProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: AkeliColors.error,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Détail du repas'),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.error)),
        ),
        data: (plan) {
          final entry =
              plan?.entries.where((e) => e.id == mealId).firstOrNull;
          if (entry == null) {
            return const Center(child: Text('Repas introuvable'));
          }
          return _MealDetailBody(
            entry: entry,
            isConsumeLoading: consumeState.isLoading,
            onConsume: () {
              appLogger.userAction('Mark consumed button tapped', screen: 'MealDetailPage', metadata: {'mealId': entry.id});
              ref.read(mealConsumptionProvider.notifier).logConsumption(entry.id);
            },
          );
        },
      ),
    );
  }
}

class _MealDetailBody extends StatelessWidget {
  final MealPlanEntry entry;
  final bool isConsumeLoading;
  final VoidCallback onConsume;

  const _MealDetailBody({
    required this.entry,
    required this.isConsumeLoading,
    required this.onConsume,
  });

  @override
  Widget build(BuildContext context) {
    appLogger.provider('MealDetailBody build() | mealId: ${entry.id}');
    final hasBatch = entry.components.any((c) => c.isBatch);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image placeholder ──────────────────────────────────────
          Container(
            height: 200,
            width: double.infinity,
            color: AkeliColors.primary.withValues(alpha: 0.08),
            child: const Center(
              child: Text('🍽️', style: TextStyle(fontSize: 64)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AkeliSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title + badges ─────────────────────────────────
                Text(
                  entry.recipeTitle ?? 'Repas',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                Wrap(
                  spacing: AkeliSpacing.sm,
                  children: [
                    AkeliBadge(label: entry.mealTypeLabel),
                    if (entry.isConsumed)
                      const AkeliBadge(
                          label: 'Consommé ✓',
                          color: AkeliColors.success),
                    if (entry.isModular)
                      const AkeliBadge(
                          label: 'Modulaire',
                          color: AkeliColors.primaryContainer),
                  ],
                ),

                // ── Components (modular only) ──────────────────────
                if (entry.isModular) ...[
                  const SizedBox(height: AkeliSpacing.lg),
                  const AkeliSectionHeader(title: 'Composants'),
                  const SizedBox(height: AkeliSpacing.sm),
                  Wrap(
                    spacing: AkeliSpacing.sm,
                    runSpacing: AkeliSpacing.sm,
                    children: entry.components
                        .map((c) => _ComponentChip(component: c))
                        .toList(),
                  ),
                ],

                // ── Macros ─────────────────────────────────────────
                const SizedBox(height: AkeliSpacing.lg),
                const AkeliSectionHeader(title: 'Macronutriments'),
                const SizedBox(height: AkeliSpacing.sm),
                Wrap(
                  spacing: AkeliSpacing.sm,
                  runSpacing: AkeliSpacing.sm,
                  children: [
                    AkeliMacroBadge(
                        label: 'Glucides',
                        value: '${entry.carbsG.toInt()}g',
                        type: MacroType.carbs),
                    AkeliMacroBadge(
                        label: 'Protéines',
                        value: '${entry.proteinG.toInt()}g',
                        type: MacroType.protein),
                    AkeliMacroBadge(
                        label: 'Graisses',
                        value: '${entry.fatG.toInt()}g',
                        type: MacroType.fat),
                    AkeliMacroBadge(
                        label: 'Calories',
                        value: '${entry.calories.toInt()}',
                        type: MacroType.kcal),
                  ],
                ),

                // ── Links ──────────────────────────────────────────
                const SizedBox(height: AkeliSpacing.lg),
                if (entry.recipeId != null)
                  _LinkRow(
                    icon: Icons.menu_book_outlined,
                    label: 'Voir la recette',
                    onTap: () {
                      appLogger.userAction('View recipe tapped', screen: 'MealDetailPage', metadata: {'recipeId': entry.recipeId});
                      context.push(AkeliRoutes.recipeDetailPath(entry.recipeId!));
                    },
                  ),
                if (hasBatch) ...[
                  const SizedBox(height: AkeliSpacing.sm),
                  _LinkRow(
                    icon: Icons.soup_kitchen_outlined,
                    label: 'Voir le batch cooking',
                    onTap: () {
                      appLogger.userAction('View batch cooking tapped', screen: 'MealDetailPage');
                      context.push(AkeliRoutes.batchCooking);
                    },
                  ),
                ],

                // ── Consume button ─────────────────────────────────
                if (!entry.isConsumed) ...[
                  const SizedBox(height: AkeliSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isConsumeLoading ? null : onConsume,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AkeliColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AkeliSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.md),
                        ),
                      ),
                      child: isConsumeLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Marquer comme consommé',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentChip extends StatelessWidget {
  final MealPlanEntryComponent component;
  const _ComponentChip({required this.component});

  IconData get _icon {
    switch (component.role) {
      case 'starch':
        return Icons.grain;
      case 'side':
        return Icons.eco_outlined;
      default:
        return Icons.restaurant;
    }
  }

  String get _roleLabel {
    switch (component.role) {
      case 'base':
        return 'Base';
      case 'starch':
        return 'Féculent';
      case 'side':
        return 'Accompagnement';
      default:
        return component.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    appLogger.provider('ComponentChip build() | role: ${component.role}');
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.sm),
        border: Border.all(color: AkeliColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: AkeliColors.primary),
          const SizedBox(width: 4),
          Text(
            '${component.recipeTitle ?? _roleLabel} · $_roleLabel',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AkeliColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (component.isBatch) ...[
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AkeliColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'BATCH',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AkeliColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    appLogger.provider('LinkRow build() | label: $label');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AkeliRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AkeliColors.primary),
            const SizedBox(width: AkeliSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AkeliColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AkeliColors.outline),
          ],
        ),
      ),
    );
  }
}
