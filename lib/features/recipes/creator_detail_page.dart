// lib/features/recipes/creator_detail_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/creator_provider.dart';
import '../../providers/food_region_provider.dart';
import '../../shared/models/creator_detail.dart';
import '../../shared/widgets/akeli_recipe_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'domain/entities/recipe_tracking.dart';

class CreatorDetailPage extends ConsumerStatefulWidget {
  final String creatorId;

  const CreatorDetailPage({super.key, required this.creatorId});

  @override
  ConsumerState<CreatorDetailPage> createState() => _CreatorDetailPageState();
}

class _CreatorDetailPageState extends ConsumerState<CreatorDetailPage> {
  final _logger = appLogger;
  bool _becomingFan = false;

  @override
  void initState() {
    super.initState();
    _logger.provider('CreatorDetailPage initState() | creatorId: ${widget.creatorId}');
  }

  @override
  void dispose() {
    _logger.provider('CreatorDetailPage disposed');
    super.dispose();
  }

  Future<void> _onBecomeFan(CreatorDetail detail) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Become fan tapped', screen: 'CreatorDetailPage',
        metadata: {'creatorId': widget.creatorId});

    setState(() => _becomingFan = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await becomeFan(client, widget.creatorId, user.id);
      ref.invalidate(creatorDetailProvider(widget.creatorId));
    } catch (e, st) {
      _logger.edge('becomeFan', 'ERROR | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur. Veuillez réessayer.')),
        );
      }
    } finally {
      if (mounted) setState(() => _becomingFan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(creatorDetailProvider(widget.creatorId));
    final recipesAsync = ref.watch(creatorRecipesProvider(widget.creatorId));
    final regionNames = ref.watch(foodRegionNamesProvider).valueOrNull ?? {};

    _logger.provider(
        'CreatorDetailPage build() | detailAsync.isLoading: ${detailAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(creatorDetailProvider(widget.creatorId)),
        ),
        data: (detail) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(detail: detail, regionNames: regionNames)),
            SliverToBoxAdapter(child: _StatsRow(detail: detail)),
            SliverToBoxAdapter(
              child: _FanSection(
                detail: detail,
                becomingFan: _becomingFan,
                onBecomeFan: () => _onBecomeFan(detail),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AkeliSpacing.md, AkeliSpacing.lg, AkeliSpacing.md, AkeliSpacing.sm),
                child: Text(
                  'Recettes',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AkeliColors.onSurface),
                ),
              ),
            ),
            recipesAsync.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(
                child: ErrorState(
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(creatorRecipesProvider(widget.creatorId)),
                ),
              ),
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Aucune recette publiée',
                      subtitle: 'Ce créateur n\'a pas encore publié de recettes.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AkeliSpacing.md,
                    vertical: AkeliSpacing.sm,
                  ),
                  sliver: SliverList.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AkeliSpacing.md),
                        child: AkeliRecipeCard(
                          horizontal: true,
                          title: recipe.title,
                          calories: recipe.calories?.toInt() ?? 0,
                          rating: recipe.averageRating,
                          likes: recipe.likeCount,
                          comments: recipe.commentCount,
                          saves: recipe.saveCount,
                          imageUrl: recipe.thumbnailUrl,
                          region: recipe.regionId != null
                              ? regionNames[recipe.regionId!] ?? recipe.regionId
                              : null,
                          tags: recipe.tagIds.take(2).toList(),
                          onTap: () {
                            _logger.userAction('Recipe tapped from creator page',
                                screen: 'CreatorDetailPage',
                                metadata: {'recipeId': recipe.id});
                            context.push(AkeliRoutes.recipeDetailPath(recipe.id),
                                extra: TrackingSource.feed);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final CreatorDetail detail;
  final Map<String, String> regionNames;

  const _Header({required this.detail, required this.regionNames});

  @override
  Widget build(BuildContext context) {
    final creator = detail.creator;
    final regionName = creator.regionId != null
        ? regionNames[creator.regionId!] ?? creator.regionId
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.lg, vertical: AkeliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LargeAvatar(
                  avatarUrl: creator.avatarUrl,
                  displayName: creator.displayName),
              const SizedBox(width: AkeliSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AkeliColors.onSurface),
                    ),
                    if (regionName != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AkeliColors.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          regionName,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AkeliColors.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (creator.bio != null && creator.bio!.isNotEmpty) ...[
            const SizedBox(height: AkeliSpacing.md),
            Text(
              creator.bio!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;

  const _LargeAvatar({required this.avatarUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: AkeliColors.primaryContainer,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AkeliColors.onPrimaryContainer),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final CreatorDetail detail;

  const _StatsRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    final creator = detail.creator;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatPill(
                icon: Icons.restaurant_menu_rounded,
                label: '${creator.recipeCount} recettes'),
            const SizedBox(width: 8),
            _StatPill(
                icon: Icons.star_rounded,
                label: creator.averageRating.toStringAsFixed(1)),
            const SizedBox(width: 8),
            _StatPill(
                icon: Icons.favorite_rounded,
                label: '${detail.totalLikes} likes'),
            const SizedBox(width: 8),
            _StatPill(
                icon: Icons.check_circle_rounded,
                label: '${detail.userConsumptionCount} cuisinées'),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AkeliColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AkeliColors.onSurface)),
        ],
      ),
    );
  }
}

class _FanSection extends StatelessWidget {
  final CreatorDetail detail;
  final bool becomingFan;
  final VoidCallback onBecomeFan;

  const _FanSection({
    required this.detail,
    required this.becomingFan,
    required this.onBecomeFan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
      child: detail.isFan
          ? Row(
              children: [
                const Icon(Icons.verified_rounded,
                    size: 18, color: AkeliColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Vous êtes fan de ce créateur',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AkeliColors.primary),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: becomingFan ? null : onBecomeFan,
                icon: becomingFan
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.favorite_rounded, size: 18),
                label: Text(becomingFan ? 'En cours...' : 'Devenir fan'),
              ),
            ),
    );
  }
}
