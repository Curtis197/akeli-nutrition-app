import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/shared/models/meal_plan.dart';

class MealDetailPage extends ConsumerWidget {
  final String mealId;
  const MealDetailPage({super.key, required this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeMealPlanProvider);
    final consumeState = ref.watch(mealConsumptionProvider);

    appLogger.provider('MealDetailPage build() | mealId: $mealId');

    ref.listen(mealConsumptionProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: AkeliColors.error,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.7),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AkeliColors.primaryContainer),
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: AkeliColors.surfaceContainerLow,
            ),
          ),
        ),
        title: const Text(
          'Détail du repas',
          style: TextStyle(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: AkeliColors.primaryContainer),
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: AkeliColors.surfaceContainerLow,
              ),
            ),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e', style: const TextStyle(color: AkeliColors.error)),
        ),
        data: (plan) {
          final entry = plan?.entries.where((e) => e.id == mealId).firstOrNull;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HERO IMAGE ──────────────────────────────────────
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                entry.recipeThumbnail != null
                    ? Image.network(entry.recipeThumbnail!, fit: BoxFit.cover)
                    : Container(color: AkeliColors.surfaceContainerHigh),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AkeliColors.surface,
                          AkeliColors.surface.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── OVERLAPPING HEADER CARD ───────────────────────
          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AkeliColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(
                          label: entry.mealTypeLabel,
                          backgroundColor: AkeliColors.secondaryContainer,
                          textColor: AkeliColors.onSecondaryContainer,
                        ),
                        _Badge(
                          label: '${entry.calories.toInt()} kcal',
                          backgroundColor: AkeliColors.accentAmber.withValues(alpha: 0.15),
                          textColor: AkeliColors.accentAmber,
                        ),
                        _Badge(
                          label: '25 min',
                          backgroundColor: AkeliColors.surfaceContainerLow,
                          textColor: AkeliColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      entry.recipeTitle ?? 'Repas',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── CONSUMED BANNER ──────────────────────────────
          if (entry.isConsumed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AkeliColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AkeliColors.primary,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Vous avez consommé ce repas',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── METADATA CHIPS ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: AkeliColors.primary),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TEMPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AkeliColors.outline)),
                            Text('25 min', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, color: AkeliColors.primary),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DIFFICULTÉ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AkeliColors.outline)),
                            Text('Facile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── MACROS ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Macronutriments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _MacroBox(label: 'PROTÉINES', value: '${entry.proteinG.toInt()}g')),
                    const SizedBox(width: 12),
                    Expanded(child: _MacroBox(label: 'GLUCIDES', value: '${entry.carbsG.toInt()}g')),
                    const SizedBox(width: 12),
                    Expanded(child: _MacroBox(label: 'LIPIDES', value: '${entry.fatG.toInt()}g')),
                  ],
                ),
              ],
            ),
          ),

          // ── INGREDIENTS / COMPONENTS ──────────────────
          if (entry.components.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingrédients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...entry.components.map((c) => _ComponentRow(component: c)),
                ],
              ),
            ),

          // ── BOTTOM CTAs ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            child: Column(
              children: [
                if (entry.recipeId != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        appLogger.userAction('View recipe tapped', screen: 'MealDetailPage', metadata: {'recipeId': entry.recipeId!});
                        context.push(AkeliRoutes.recipeDetailPath(entry.recipeId!));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AkeliColors.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.pill)),
                      ),
                      child: const Text('Voir la recette', style: TextStyle(color: AkeliColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 12),
                if (!entry.isConsumed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isConsumeLoading ? null : onConsume,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AkeliColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.pill)),
                        elevation: 4,
                      ),
                      child: isConsumeLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Marquer comme consommé', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _Badge({required this.label, required this.backgroundColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MacroBox extends StatelessWidget {
  final String label;
  final String value;

  const _MacroBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AkeliColors.outline)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AkeliColors.primary)),
        ],
      ),
    );
  }
}

class _ComponentRow extends StatelessWidget {
  final MealPlanEntryComponent component;

  const _ComponentRow({required this.component});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AkeliColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  component.role == 'starch' ? Icons.grain : Icons.eco,
                  color: AkeliColors.outline,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                component.recipeTitle ?? component.role,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          if (component.isBatch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AkeliColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('BATCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AkeliColors.secondary)),
            ),
        ],
      ),
    );
  }
}
