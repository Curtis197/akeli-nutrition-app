import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/fan_mode_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/models/creator.dart';
import '../../shared/widgets/empty_state.dart';

class FanModePage extends ConsumerWidget {
  const FanModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fanSubAsync = ref.watch(myFanSubscriptionProvider);
    final creatorsAsync = ref.watch(fanEligibleCreatorsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mode Fan')),
      body: !isPremium
          ? _PremiumRequired()
          : CustomScrollView(
              slivers: [
                // Current fan subscription status
                SliverToBoxAdapter(
                  child: fanSubAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (sub) => sub != null
                        ? _ActiveFanBanner(sub: sub, ref: ref)
                        : _FanModeExplanation(),
                  ),
                ),

                // Eligible creators list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AkeliSpacing.lg,
                      AkeliSpacing.lg,
                      AkeliSpacing.lg,
                      AkeliSpacing.sm,
                    ),
                    child: Text(
                      'Créateurs à soutenir',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),

                creatorsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
                    child: ErrorState(message: err.toString()),
                  ),
                  data: (creators) {
                    if (creators.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'Aucun créateur éligible',
                          subtitle:
                              'Les créateurs doivent publier 30 recettes pour être éligibles.',
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final creator = creators[i];
                          final currentSub =
                              fanSubAsync.valueOrNull;
                          final isCurrentFan =
                              currentSub?.creatorId == creator.id &&
                                  (currentSub?.isActive == true ||
                                      currentSub?.isPending == true);

                          return _CreatorCard(
                            creator: creator,
                            isCurrentFan: isCurrentFan,
                            onActivate: () =>
                                _activateFanMode(context, ref, creator),
                            onCancel: () =>
                                _cancelFanMode(context, ref),
                          );
                        },
                        childCount: creators.length,
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: AkeliSpacing.xxl)),
              ],
            ),
    );
  }

  Future<void> _activateFanMode(
      BuildContext context, WidgetRef ref, Creator creator) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activer le Mode Fan'),
        content: Text(
          'Vous allez soutenir ${creator.displayName} avec 1€/mois, '
          'inclus dans votre abonnement Akeli.\n\n'
          'Actif à partir du 1er du mois prochain.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(fanModeNotifierProvider.notifier).activate(creator.id);
    final state = ref.read(fanModeNotifierProvider);
    if (!context.mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'activation.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Vous soutenez maintenant ${creator.displayName} !'),
          backgroundColor: AkeliColors.success,
        ),
      );
    }
  }

  Future<void> _cancelFanMode(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le Mode Fan'),
        content: const Text(
          'Votre soutien se terminera à la fin du mois en cours.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Garder')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AkeliColors.error),
            child: const Text('Annuler le soutien'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(fanModeNotifierProvider.notifier).cancel();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mode Fan annulé.')),
    );
  }
}

class _PremiumRequired extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.star_rounded,
      title: 'Fonctionnalité Premium',
      subtitle:
          'Le Mode Fan est disponible avec un abonnement Akeli Premium.',
      actionLabel: 'Voir les offres',
    );
  }
}

class _FanModeExplanation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AkeliSpacing.lg),
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AkeliColors.primary.withOpacity(0.1),
            AkeliColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded,
              color: AkeliColors.primary, size: 32),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            'Soutenez vos créateurs préférés',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            '1€ de votre abonnement mensuel est reversé directement '
            'au créateur que vous choisissez. Changez de créateur quand vous voulez.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AkeliColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActiveFanBanner extends StatelessWidget {
  final FanSubscription sub;
  final WidgetRef ref;

  const _ActiveFanBanner({required this.sub, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AkeliSpacing.lg),
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border:
            Border.all(color: AkeliColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded,
              color: AkeliColors.success, size: 28),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.isPending ? 'Mode Fan en attente' : 'Mode Fan actif',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AkeliColors.success,
                      ),
                ),
                if (sub.isPending)
                  Text(
                    'Actif à partir du 1er du mois prochain.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AkeliColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final Creator creator;
  final bool isCurrentFan;
  final VoidCallback onActivate;
  final VoidCallback onCancel;

  const _CreatorCard({
    required this.creator,
    required this.isCurrentFan,
    required this.onActivate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.md, vertical: AkeliSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AkeliSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AkeliColors.primary.withOpacity(0.1),
              backgroundImage: creator.avatarUrl != null
                  ? CachedNetworkImageProvider(creator.avatarUrl!)
                  : null,
              child: creator.avatarUrl == null
                  ? Text(
                      creator.displayName[0].toUpperCase(),
                      style: const TextStyle(
                          color: AkeliColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(creator.displayName,
                      style: Theme.of(context).textTheme.titleSmall),
                  if (creator.specialties.isNotEmpty)
                    Text(
                      creator.specialties.join(' • '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AkeliColors.textSecondary),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu_rounded,
                          size: 12, color: AkeliColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${creator.recipeCount} recettes',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                                color: AkeliColors.textSecondary),
                      ),
                      const SizedBox(width: AkeliSpacing.sm),
                      const Icon(Icons.people_outline_rounded,
                          size: 12, color: AkeliColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${creator.fanCount} fans',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                                color: AkeliColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AkeliSpacing.sm),
            isCurrentFan
                ? OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AkeliColors.error,
                      side: const BorderSide(color: AkeliColors.error),
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Arrêter'),
                  )
                : FilledButton(
                    onPressed: onActivate,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(80, 36)),
                    child: const Text('Soutenir'),
                  ),
          ],
        ),
      ),
    );
  }
}
