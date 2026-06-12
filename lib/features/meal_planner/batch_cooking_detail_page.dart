import 'package:akeli/core/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/models/recipe.dart';
import '../recipes/widgets/ingredient_detail_sheet.dart';

class BatchCookingDetailPage extends ConsumerStatefulWidget {
  final String sessionId;
  final CookingSession? initialSession;

  const BatchCookingDetailPage({
    super.key,
    required this.sessionId,
    this.initialSession,
  });

  @override
  ConsumerState<BatchCookingDetailPage> createState() =>
      _BatchCookingDetailPageState();
}

class _BatchCookingDetailPageState
    extends ConsumerState<BatchCookingDetailPage> {
  bool _startingCook = false;

  @override
  Widget build(BuildContext context) {
    appLogger.provider(
        'BatchCookingDetailPage build() | sessionId: ${widget.sessionId}');

    final sessionsAsync = ref.watch(cookingSessionsProvider);

    final session = sessionsAsync.valueOrNull?.cast<CookingSession?>().firstWhere(
          (s) => s?.id == widget.sessionId,
          orElse: () => null,
        ) ??
        widget.initialSession;

    if (session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final recipe = session.recipeId != null
        ? ref.watch(recipeDetailProvider(session.recipeId!)).valueOrNull
        : null;

    return _SessionDetailView(
      session: session,
      recipe: recipe,
      startingCook: _startingCook,
      onToggleCooked: () => ref
          .read(cookingSessionsProvider.notifier)
          .markCooked(session.id, isCooked: !session.isCooked),
      onStartCooking: () => _startCooking(session),
    );
  }

  Future<void> _startCooking(CookingSession session) async {
    if (session.recipeId == null) return;
    setState(() => _startingCook = true);
    try {
      appLogger.userAction('Start cooking tapped', screen: 'BatchCookingDetailPage',
          metadata: {'sessionId': session.id, 'recipeId': session.recipeId});
      final recipe =
          await ref.read(recipeDetailProvider(session.recipeId!).future);
      if (recipe == null || !mounted) return;
      context.push(
        AkeliRoutes.recipeCookPath(session.recipeId!),
        extra: {'recipe': recipe, 'initialStepIndex': 0},
      );
    } catch (e, st) {
      appLogger.provider('BatchCookingDetailPage _startCooking ERROR | $e',
          error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _startingCook = false);
    }
  }
}

// ---------------------------------------------------------------------------

class _SessionDetailView extends StatelessWidget {
  final CookingSession session;
  final Recipe? recipe;
  final bool startingCook;
  final VoidCallback onToggleCooked;
  final VoidCallback onStartCooking;

  const _SessionDetailView({
    required this.session,
    required this.recipe,
    required this.startingCook,
    required this.onToggleCooked,
    required this.onStartCooking,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final progress = session.totalPortions > 0
        ? (session.portionsUsed / session.totalPortions).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HERO
                SizedBox(
                  height: 320,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (session.recipeThumbnail != null)
                        CachedNetworkImage(
                          imageUrl: session.recipeThumbnail!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const _HeroPlaceholder(),
                        )
                      else
                        const _HeroPlaceholder(),
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
                      // Hero text
                      Positioned(
                        bottom: 40,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BATCH COOKING',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.onPrimary
                                    .withValues(alpha: 0.8),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              session.recipeTitle ?? 'Préparation',
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

                // META CARD (overlapping hero)
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
                          BoxShadow(
                            color: Color(0x0A1B1C16),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _QuickInfo(
                                icon: Icons.restaurant_menu,
                                iconColor: AkeliColors.primary,
                                label: '${session.totalPortions} portions',
                              ),
                              _QuickInfo(
                                icon: Icons.scale_outlined,
                                iconColor: AkeliColors.accentAmber,
                                label:
                                    '×${(session.scaleFactor ?? 1.0).toStringAsFixed(1)}',
                              ),
                              _QuickInfo(
                                icon: Icons.check_circle_outline,
                                iconColor: progress >= 1.0
                                    ? AkeliColors.success
                                    : AkeliColors.primary,
                                label: '${session.portionsUsed} utilisées',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(
                              color: AkeliColors.surfaceContainerHighest,
                              height: 1),
                          const SizedBox(height: 20),
                          // Progress
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Portions utilisées',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AkeliColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${session.portionsUsed}/${session.totalPortions}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AkeliColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  AkeliColors.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0
                                    ? AkeliColors.outline
                                    : AkeliColors.primary,
                              ),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // INGREDIENTS SECTION
                if (session.ingredients != null &&
                    session.ingredients!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AkeliColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AkeliRadius.xl),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x051B1C16),
                              blurRadius: 12,
                              offset: Offset(0, 4)),
                        ],
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
                              Text(
                                '×${(session.scaleFactor ?? 1.0).toStringAsFixed(1)} · ${session.totalPortions} portions',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ...session.ingredients!
                              .map((ing) => _IngredientRow(ingredient: ing)),
                        ],
                      ),
                    ),
                  ),

                // STEPS SECTION
                if (recipe != null && recipe!.steps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AkeliColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AkeliRadius.xl),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x051B1C16),
                              blurRadius: 12,
                              offset: Offset(0, 4)),
                        ],
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
                            return recipe!.steps.map((step) {
                              if (step.isSectionHeader) {
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
                              final stepIdx = recipe!.steps.indexOf(step);
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
                                          shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$contentNum',
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AkeliColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        step.instruction,
                                        style: GoogleFonts.inter(
                                            fontSize: 15,
                                            height: 1.6,
                                            color: AkeliColors.onSurface),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_outline),
                                      color: AkeliColors.primary,
                                      onPressed: () {
                                        appLogger.userAction('Step tapped',
                                            screen: 'BatchCookingDetailPage',
                                            metadata: {'stepNumber': step.stepNumber});
                                        context.push(
                                          AkeliRoutes.recipeCookPath(recipe!.id),
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
                  ),
              ],
            ),
          ),

          // Back button (floating over hero)
          Positioned(
            top: topPadding + 8,
            left: 16,
            child: GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(AkeliRoutes.batchCooking);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // BOTTOM CTA BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerLowest,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Cooked toggle
                  GestureDetector(
                    onTap: onToggleCooked,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: session.isCooked
                            ? AkeliColors.primary.withValues(alpha: 0.1)
                            : AkeliColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: session.isCooked
                              ? AkeliColors.primary
                              : AkeliColors.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        session.isCooked
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: session.isCooked
                            ? AkeliColors.primary
                            : AkeliColors.outline,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Start cooking
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: startingCook ? null : onStartCooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AkeliColors.primary,
                          foregroundColor: AkeliColors.onPrimary,
                          disabledBackgroundColor:
                              AkeliColors.primary.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: startingCook
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(
                          startingCook
                              ? 'Chargement...'
                              : 'Commencer la cuisson',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: AkeliColors.background,
        child: const Center(
          child: Icon(Icons.restaurant_rounded,
              size: 80, color: AkeliColors.primary),
        ),
      );
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _QuickInfo({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AkeliColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final CookingSessionIngredient ingredient;

  const _IngredientRow({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final canShowDetail = ingredient.ingredientId != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              ingredient.ingredientName,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AkeliColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            ingredient.quantityDisplay,
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
                    screen: 'BatchCookingDetailPage',
                    metadata: {'ingredientId': ingredient.ingredientId});
                IngredientDetailSheet.show(
                  context,
                  RecipeIngredient(
                    ingredientId: ingredient.ingredientId!,
                    name: ingredient.ingredientName,
                    quantity: ingredient.quantityNeeded,
                    unit: ingredient.unit,
                    isOptional: false,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
