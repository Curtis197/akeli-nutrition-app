import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:akeli/core/date_utils.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/providers/recipe_provider.dart';
import 'package:akeli/shared/models/meal_plan.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:akeli/features/recipes/widgets/ingredient_detail_sheet.dart';
import 'personal_meal_bottom_sheet.dart';
import 'rating_bottom_sheet.dart';

class MealDetailPage extends ConsumerStatefulWidget {
  final String mealId;
  const MealDetailPage({super.key, required this.mealId});

  @override
  ConsumerState<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends ConsumerState<MealDetailPage> {
  final _logger = appLogger;
  String? _recipeId;

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activeMealPlanProvider);
    final consumeState = ref.watch(mealConsumptionProvider);
    final consumptionOverrides = ref.watch(optimisticConsumptionProvider);
    final likeState = ref.watch(recipeLikeProvider);
    final isLiked = likeState.valueOrNull ?? false;

    _logger.provider('MealDetailPage build() | mealId: ${widget.mealId}');

    ref.listen(mealConsumptionProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de mettre à jour le repas. Réessayez.'),
          backgroundColor: AkeliColors.error,
        ));
      } else if (next.valueOrNull != null) {
        final plan = ref.read(activeMealPlanProvider).valueOrNull;
        final entry = plan?.entries.where((e) => e.id == widget.mealId).firstOrNull;
        if (entry != null && !entry.isRated) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => RatingBottomSheet(mealPlanEntryId: widget.mealId),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e', style: const TextStyle(color: AkeliColors.error)),
        ),
        data: (plan) {
          final entry = plan?.entries.where((e) => e.id == widget.mealId).firstOrNull;
          if (entry == null) return const Center(child: Text('Repas introuvable'));

          if (entry.recipeId != null && _recipeId != entry.recipeId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _recipeId = entry.recipeId);
            });
          }

          return _MealDetailBody(
            entry: entry,
            isConsumeLoading: consumeState.isLoading,
            isLiked: isLiked,
            onConsume: () {
              final effectiveIsConsumed = consumptionOverrides[entry.id] ?? entry.isConsumed;
              _logger.userAction('Mark consumed tapped | isConsumed: $effectiveIsConsumed',
                  screen: 'MealDetailPage', metadata: {'mealId': entry.id});
              ref.read(mealConsumptionProvider.notifier).toggleConsumption(
                entry.id,
                isCurrentlyConsumed: effectiveIsConsumed,
              );
            },
            onLike: _recipeId == null
                ? null
                : () {
                    _logger.userAction('Meal like tapped', screen: 'MealDetailPage',
                        metadata: {'recipeId': _recipeId!, 'isSaved': isLiked});
                    ref.read(recipeLikeProvider.notifier).toggle(_recipeId!, isLiked);
                  },
            pageContext: context,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _MealDetailBody extends ConsumerWidget {
  final MealPlanEntry entry;
  final bool isConsumeLoading;
  final bool isLiked;
  final VoidCallback onConsume;
  final VoidCallback? onLike;
  final BuildContext pageContext;

  const _MealDetailBody({
    required this.entry,
    required this.isConsumeLoading,
    required this.isLiked,
    required this.onConsume,
    required this.onLike,
    required this.pageContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('MealDetailBody build() | mealId: ${entry.id}');

    final isFuture = isFutureMeal(entry.scheduledDate);
    if (isFuture) appLogger.provider('MealDetailBody | future meal guard | mealId: ${entry.id} | scheduledDate: ${entry.scheduledDate}');

    final isBatch = entry.components.any((c) => c.cookingSessionId != null);
    final batchSessionId = isBatch
        ? entry.components.firstWhere((c) => c.cookingSessionId != null).cookingSessionId
        : null;

    final topPadding = MediaQuery.of(context).padding.top;

    final recipeAsync = entry.recipeId != null && !entry.isCustomMeal
        ? ref.watch(recipeDetailProvider(entry.recipeId!))
        : null;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── HERO ────────────────────────────────────────
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    // Image
                    if (entry.isCustomMeal || entry.recipeThumbnail == null)
                      Container(
                        color: AkeliColors.surfaceContainerHigh,
                        child: const Center(
                          child: Icon(Icons.restaurant, size: 80, color: AkeliColors.outline),
                        ),
                      )
                    else
                      Image.network(
                        entry.recipeThumbnail!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: AkeliColors.surfaceContainerHigh,
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 80, color: AkeliColors.outline),
                          ),
                        ),
                      ),

                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AkeliColors.onSurface.withValues(alpha: 0.8),
                              AkeliColors.onSurface.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Title over image
                    Positioned(
                      bottom: 40,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.mealTypeLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AkeliColors.onPrimary.withValues(alpha: 0.8),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.recipeTitle ?? 'Repas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AkeliColors.onPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── META CARD ────────────────────────────────────
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AkeliRadius.xl),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A1B1C16), blurRadius: 24, offset: Offset(0, 12)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Quick info row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _QuickInfo(
                              icon: Icons.schedule,
                              iconColor: AkeliColors.primary,
                              label: entry.totalTimeMin != null
                                  ? '${entry.totalTimeMin} min'
                                  : '--',
                            ),
                            _QuickInfo(
                              icon: Icons.local_fire_department,
                              iconColor: AkeliColors.primary,
                              label: '${entry.calories.toInt()} kcal',
                              isBold: true,
                            ),
                          ],
                        ),

                        // Consumed check — hidden for future meals
                        if (!isFuture) ...[
                          const SizedBox(height: 20),
                          GestureDetector(
                            key: const Key('consume-row'),
                            onTap: isConsumeLoading ? null : onConsume,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: entry.isConsumed
                                    ? AkeliColors.secondaryContainer
                                    : AkeliColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(AkeliRadius.md),
                              ),
                              child: Row(
                                children: [
                                  isConsumeLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: entry.isConsumed ? AkeliColors.primary : Colors.transparent,
                                            border: Border.all(
                                              color: entry.isConsumed ? AkeliColors.primary : AkeliColors.outline,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: entry.isConsumed
                                              ? const Icon(Icons.check, color: Colors.white, size: 13)
                                              : null,
                                        ),
                                  const SizedBox(width: 12),
                                  Text(
                                    entry.isConsumed ? 'Repas consommé' : 'Marquer comme consommé',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: entry.isConsumed
                                          ? AkeliColors.onSecondaryContainer
                                          : AkeliColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Divider(color: AkeliColors.surfaceContainerHighest, height: 1),
                        const SizedBox(height: 24),

                        // Macros
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
                ),
              ),

              // ── INGREDIENTS (non-batch only) ──────────────────
              if (entry.ingredients.isNotEmpty && !isBatch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AkeliRadius.xl),
                      boxShadow: const [BoxShadow(color: Color(0x051B1C16), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ingrédients',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ...entry.ingredients.map((ing) {
                          final canShowDetail = ing.ingredientId != null;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ing.ingredientName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: AkeliColors.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  ing.quantityDisplay,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AkeliColors.accentAmber,
                                  ),
                                ),
                                if (canShowDetail) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    color: AkeliColors.onSurfaceVariant,
                                    onPressed: () {
                                      appLogger.userAction('Ingredient tapped',
                                          screen: 'MealDetailPage',
                                          metadata: {'ingredientId': ing.ingredientId});
                                      IngredientDetailSheet.show(
                                        context,
                                        RecipeIngredient(
                                          ingredientId: ing.ingredientId!,
                                          name: ing.ingredientName,
                                          quantity: ing.quantity,
                                          unit: ing.unit,
                                          isOptional: false,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // ── BATCH SECTION (description + session link) ────
              if (isBatch && recipeAsync != null)
                recipeAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (recipe) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (recipe?.description != null) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AkeliColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(AkeliRadius.xl),
                              boxShadow: const [BoxShadow(color: Color(0x051B1C16), blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AkeliColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  recipe!.description!,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: AkeliColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (batchSessionId != null)
                          _BatchSessionCard(
                            sessionId: batchSessionId,
                            onTap: () {
                              appLogger.userAction(
                                'Batch session card tapped',
                                screen: 'MealDetailPage',
                                metadata: {'sessionId': batchSessionId},
                              );
                              pageContext.push(
                                AkeliRoutes.batchCookingDetailPath(batchSessionId),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

              // ── INSTRUCTIONS (non-batch only) ─────────────────
              if (recipeAsync != null && !isBatch)
                recipeAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (recipe) {
                    if (recipe == null || recipe.steps.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AkeliColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AkeliRadius.xl),
                          boxShadow: const [BoxShadow(color: Color(0x051B1C16), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Étapes',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ...() {
                              int contentNum = 0;
                              return recipe.steps.map((step) {
                                if (step.isSectionHeader) {
                                  appLogger.provider(
                                      'MealDetailPage | section header | title: "${step.sectionTitle}"');
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16, top: 4),
                                    child: Row(children: [
                                      Expanded(child: Divider(color: AkeliColors.outline.withValues(alpha: 0.25), height: 1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          step.sectionTitle ?? '',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AkeliColors.onSurfaceVariant,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: AkeliColors.outline.withValues(alpha: 0.25), height: 1)),
                                    ]),
                                  );
                                }
                                contentNum++;
                                final stepIdx = recipe.steps.indexOf(step);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: AkeliColors.surfaceContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$contentNum',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AkeliColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          step.instruction,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: AkeliColors.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.play_circle_outline),
                                        color: AkeliColors.primary,
                                        onPressed: () {
                                          appLogger.userAction('Step tapped',
                                              screen: 'MealDetailPage',
                                              metadata: {'stepNumber': step.stepNumber});
                                          pageContext.push(
                                            AkeliRoutes.recipeCookPath(recipe.id),
                                            extra: {'recipe': recipe, 'initialStepIndex': stepIdx},
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              });
                            }(),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // ── ACTION BUTTONS ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: [
                    if (!entry.isCustomMeal)
                      _ActionButton(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Changer la recette',
                        color: AkeliColors.secondary,
                        onTap: () {
                          appLogger.userAction('Swap recipe tapped', screen: 'MealDetailPage',
                              metadata: {'mealId': entry.id});
                          pageContext.push('/meal/${entry.id}/swap-recipe');
                        },
                      ),
                    if (!entry.isCustomMeal) const SizedBox(height: 12),
                    _ActionButton(
                      icon: Icons.edit_note_rounded,
                      label: 'Repas personnel (IA)',
                      color: AkeliColors.primary,
                      onTap: () {
                        appLogger.userAction('Personal meal tapped', screen: 'MealDetailPage',
                            metadata: {'mealId': entry.id});
                        showModalBottomSheet(
                          context: pageContext,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => PersonalMealBottomSheet(entryId: entry.id),
                        );
                      },
                    ),
                    if (!isFuture) ...[
                    const SizedBox(height: 12),
                    _ActionButton(
                      icon: entry.isConsumed && entry.isRated
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      label: !entry.isConsumed
                          ? 'Consommez d\'abord ce repas'
                          : entry.isRated
                              ? 'Modifier votre avis'
                              : 'Laisser un avis',
                      color: AkeliColors.accentAmber,
                      onTap: entry.isConsumed
                          ? () {
                              appLogger.userAction('Rating tapped', screen: 'MealDetailPage',
                                  metadata: {'mealId': entry.id, 'isRated': entry.isRated});
                              showModalBottomSheet(
                                context: pageContext,
                                isScrollControlled: true,
                                isDismissible: true,
                                enableDrag: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => RatingBottomSheet(mealPlanEntryId: entry.id),
                              );
                            }
                          : null,
                    ),
                    ], // end if (!isFuture) rating button
                    if (entry.recipeId != null && !entry.isCustomMeal) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          appLogger.userAction('View recipe tapped', screen: 'MealDetailPage',
                              metadata: {'recipeId': entry.recipeId!});
                          pageContext.push(AkeliRoutes.recipeDetailPath(entry.recipeId!));
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Voir la recette complète'),
                        style: TextButton.styleFrom(foregroundColor: AkeliColors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── FROSTED OVERLAY BUTTONS ────────────────────────
        Positioned(
          top: topPadding + 16,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FrostedIconButton(
                icon: Icons.arrow_back,
                onPressed: () {
                  if (pageContext.canPop()) {
                    pageContext.pop();
                  } else {
                    pageContext.go(AkeliRoutes.mealPlanner);
                  }
                },
              ),
              _FrostedIconButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                iconColor: isLiked ? AkeliColors.primary : AkeliColors.onSurface,
                onPressed: onLike ?? () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isBold;

  const _QuickInfo({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: AkeliColors.onSurfaceVariant,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AkeliColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.pill),
          ),
        ),
      ),
    );
  }
}

class _BatchSessionCard extends ConsumerWidget {
  final String sessionId;
  final VoidCallback onTap;

  const _BatchSessionCard({required this.sessionId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const portionsText = 'Session de cuisine batch';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AkeliColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          border: Border.all(
            color: AkeliColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AkeliColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.soup_kitchen_rounded,
                  color: AkeliColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Préparation batch',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    portionsText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AkeliColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AkeliColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _FrostedIconButton({
    required this.icon,
    this.iconColor = AkeliColors.onSurface,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 40,
          height: 40,
          color: AkeliColors.surfaceContainerLowest.withValues(alpha: 0.8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
