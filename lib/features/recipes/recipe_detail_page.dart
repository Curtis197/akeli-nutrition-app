import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/recipe_provider.dart';
import '../../shared/models/recipe.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/macro_card.dart';

class RecipeDetailPage extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> {
  int _currentImageIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(recipeDetailProvider(widget.recipeId)),
        ),
        data: (recipe) {
          if (recipe == null) {
            return const ErrorState(message: 'Recette introuvable.');
          }
          return _RecipeContent(
            recipe: recipe,
            currentImageIndex: _currentImageIndex,
            pageController: _pageController,
            onImageChanged: (i) => setState(() => _currentImageIndex = i),
            onLike: () => ref
                .read(recipeLikeProvider.notifier)
                .toggle(recipe.id, recipe.isLiked),
          );
        },
      ),
    );
  }
}

class _RecipeContent extends StatelessWidget {
  final Recipe recipe;
  final int currentImageIndex;
  final PageController pageController;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onLike;

  const _RecipeContent({
    required this.recipe,
    required this.currentImageIndex,
    required this.pageController,
    required this.onImageChanged,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final images = recipe.imageUrls.isNotEmpty
        ? recipe.imageUrls
        : [if (recipe.thumbnailUrl != null) recipe.thumbnailUrl!];

    return CustomScrollView(
      slivers: [
        // Image carousel in SliverAppBar
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: const BackButton(),
          actions: [
            IconButton(
              icon: Icon(
                recipe.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: recipe.isLiked ? Colors.red : null,
              ),
              onPressed: onLike,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: images.isEmpty
                ? Container(
                    color: AkeliColors.background,
                    child: const Icon(Icons.restaurant_rounded,
                        size: 80, color: AkeliColors.primary),
                  )
                : Stack(
                    children: [
                      PageView.builder(
                        controller: pageController,
                        onPageChanged: onImageChanged,
                        itemCount: images.length,
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AkeliColors.background,
                            child: const Icon(Icons.restaurant_rounded,
                                size: 60, color: AkeliColors.primary),
                          ),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: AkeliSpacing.md,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == currentImageIndex ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == currentImageIndex
                                      ? Colors.white
                                      : Colors.white54,
                                  borderRadius:
                                      BorderRadius.circular(AkeliRadius.full),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AkeliSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Title
              Text(recipe.title,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AkeliSpacing.sm),

              // Meta row
              Wrap(
                spacing: AkeliSpacing.sm,
                runSpacing: AkeliSpacing.xs,
                children: [
                  _MetaChip(
                    icon: Icons.timer_outlined,
                    label:
                        '${recipe.totalTimeMin} min',
                  ),
                  _MetaChip(
                    icon: Icons.people_outline_rounded,
                    label: '${recipe.servings} pers.',
                  ),
                  _MetaChip(
                    icon: Icons.bar_chart_rounded,
                    label: _difficultyLabel(recipe.difficulty),
                    color: _difficultyColor(recipe.difficulty),
                  ),
                  _MetaChip(
                    icon: Icons.star_rounded,
                    label: recipe.averageRating.toStringAsFixed(1),
                    color: AkeliColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: AkeliSpacing.lg),

              // Macros
              if (recipe.calories != null) ...[
                MacroRow(
                  calories: recipe.calories,
                  proteinG: recipe.proteinG,
                  carbsG: recipe.carbsG,
                  fatG: recipe.fatG,
                ),
                const SizedBox(height: AkeliSpacing.lg),
              ],

              // Description
              if (recipe.description != null) ...[
                Text(recipe.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AkeliColors.textSecondary,
                        )),
                const SizedBox(height: AkeliSpacing.lg),
              ],

              const Divider(),
              const SizedBox(height: AkeliSpacing.md),

              // Ingredients
              if (recipe.ingredients.isNotEmpty) ...[
                Text('Ingrédients',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AkeliSpacing.md),
                ...recipe.ingredients.map(
                  (ing) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AkeliSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: AkeliColors.primary),
                        const SizedBox(width: AkeliSpacing.sm),
                        Expanded(
                          child: Text(ing.name,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        Text(
                          '${ing.quantity.toStringAsFixed(ing.quantity % 1 == 0 ? 0 : 1)} ${ing.unit}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AkeliColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (ing.isOptional)
                          Text(
                            ' (opt.)',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AkeliColors.textSecondary,
                                ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AkeliSpacing.lg),
                const Divider(),
                const SizedBox(height: AkeliSpacing.md),
              ],

              // Steps
              if (recipe.steps.isNotEmpty) ...[
                Text('Préparation',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AkeliSpacing.md),
                ...recipe.steps.map(
                  (step) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AkeliSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AkeliColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${step.stepNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AkeliSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step.instruction,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                              if (step.durationMin != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${step.durationMin} min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AkeliColors.textSecondary,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AkeliSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }

  String _difficultyLabel(String d) {
    switch (d) {
      case 'easy':
        return 'Facile';
      case 'medium':
        return 'Moyen';
      case 'hard':
        return 'Difficile';
      default:
        return d;
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'easy':
        return AkeliColors.success;
      case 'medium':
        return AkeliColors.secondary;
      case 'hard':
        return AkeliColors.error;
      default:
        return AkeliColors.textSecondary;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AkeliColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AkeliRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
