import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/fan_mode_provider.dart';
import '../../shared/models/creator.dart';
import '../../shared/widgets/empty_state.dart';

class FanModePage extends ConsumerWidget {
  const FanModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fanSubAsync = ref.watch(myFanSubscriptionProvider);
    appLogger.provider('FanModePage build() | isLoading: ${fanSubAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: const Text('Mode Fan'),
        backgroundColor: AkeliColors.background,
        elevation: 0,
      ),
      body: fanSubAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Center(child: Text('Erreur de chargement')),
        data: (sub) {
          final isFan = sub != null && (sub.isActive || sub.isPending);
          appLogger.provider('FanModePage → isFan: $isFan | status: ${sub?.status}');
          if (isFan) return _FanUserView(sub: sub);
          return const _NoFanUserView();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View A — Non-fan
// ─────────────────────────────────────────────────────────────────────────────

class _NoFanUserView extends ConsumerWidget {
  const _NoFanUserView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumptionAsync = ref.watch(creatorConsumptionProvider);
    final creatorsAsync = ref.watch(fanEligibleCreatorsProvider);
    appLogger.provider('_NoFanUserView build()');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: consumptionAsync.when(
            loading: () {
              appLogger.provider('_NoFanUserView consumptionAsync → loading');
              return const LinearProgressIndicator();
            },
            error: (e, st) {
              appLogger.provider('_NoFanUserView consumptionAsync → error | $e', error: e, stackTrace: st);
              return const SizedBox.shrink();
            },
            data: (consumption) {
              appLogger.provider('_NoFanUserView consumptionAsync → data | count: ${consumption.length}');
              return _ConsumptionCard(consumption: consumption);
            },
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créateurs à soutenir',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('Votre créateur dominant est mis en avant.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AkeliColors.textSecondary)),
              ],
            ),
          ),
        ),

        creatorsAsync.when(
          loading: () {
            appLogger.provider('_NoFanUserView creatorsAsync → loading');
            return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()));
          },
          error: (err, st) {
            appLogger.provider('_NoFanUserView creatorsAsync → error | $err', error: err, stackTrace: st);
            return SliverToBoxAdapter(child: ErrorState(message: err.toString()));
          },
          data: (creators) {
            appLogger.provider('_NoFanUserView creatorsAsync → data | count: ${creators.length}');
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
            final dominantId = consumptionAsync.valueOrNull?.isNotEmpty == true
                ? consumptionAsync.valueOrNull!.first.creatorId
                : null;
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _EligibleCreatorCard(
                  creator: creators[i],
                  isDominant: creators[i].id == dominantId,
                  onActivate: () => _activateFanMode(context, ref, creators[i]),
                ),
                childCount: creators.length,
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AkeliSpacing.xxl)),
      ],
    );
  }

  Future<void> _activateFanMode(
      BuildContext context, WidgetRef ref, Creator creator) async {
    appLogger.userAction('Activate fan mode button tapped',
        screen: 'FanModePage',
        metadata: {'creatorId': LogHelper.maskUuid(creator.id)});
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activer le Mode Fan'),
        content: Text(
          'Vous allez soutenir ${creator.displayName} avec 1€/mois, '
          'inclus dans votre abonnement Akeli.\n\n'
          'Règle 90/10 : 90% de vos repas devront venir du catalogue de ce créateur '
          '(max 9 recettes externes par mois).\n\n'
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

    appLogger.userAction('Activate fan mode confirmed', screen: 'FanModePage');
    await ref.read(fanModeNotifierProvider.notifier).activate(creator.id);
    final state = ref.read(fanModeNotifierProvider);
    if (!context.mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'activation.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous soutenez maintenant ${creator.displayName} !'),
          backgroundColor: AkeliColors.success,
        ),
      );
    }
  }
}

class _ConsumptionCard extends StatelessWidget {
  final List<CreatorConsumption> consumption;
  const _ConsumptionCard({required this.consumption});

  @override
  Widget build(BuildContext context) {
    final total = consumption.fold(0, (s, c) => s + c.count);
    return Container(
      margin: const EdgeInsets.all(AkeliSpacing.lg),
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vos recettes ce mois',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.textSecondary,
                  letterSpacing: 0.7)),
          const SizedBox(height: AkeliSpacing.sm),
          if (consumption.isEmpty)
            Text('Aucune recette enregistrée ce mois',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AkeliColors.textSecondary))
          else ...[
            Container(
              decoration: BoxDecoration(
                color: AkeliColors.background,
                borderRadius: BorderRadius.circular(AkeliRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AkeliSpacing.md, vertical: AkeliSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍽 ', style: TextStyle(fontSize: 13)),
                  Text('$total repas enregistrés',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AkeliColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.md),
            ...consumption.map((c) => _CreatorRatioRow(c: c)),
          ],
        ],
      ),
    );
  }
}

class _CreatorRatioRow extends StatelessWidget {
  final CreatorConsumption c;
  const _CreatorRatioRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final color = _creatorColor(c.creatorId);
    return Padding(
      padding: const EdgeInsets.only(bottom: AkeliSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            backgroundImage: c.avatarUrl != null
                ? CachedNetworkImageProvider(c.avatarUrl!)
                : null,
            child: c.avatarUrl == null
                ? Text(
                    c.creatorName.isNotEmpty
                        ? c.creatorName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: AkeliSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.creatorName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: c.pct,
                    backgroundColor: AkeliColors.background,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AkeliSpacing.sm),
          Text('${(c.pct * 100).round()}%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Color _creatorColor(String id) {
    const colors = [
      Color(0xFFF472B6),
      Color(0xFF60A5FA),
      Color(0xFF4ADE80),
      Color(0xFFA78BFA),
      Color(0xFFFBBF24),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}

class _EligibleCreatorCard extends StatelessWidget {
  final Creator creator;
  final bool isDominant;
  final VoidCallback onActivate;

  const _EligibleCreatorCard({
    required this.creator,
    required this.isDominant,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    appLogger.provider('_EligibleCreatorCard build() | creatorId: ${creator.id} | isDominant: $isDominant');
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.md, vertical: AkeliSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AkeliSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AkeliColors.primary.withValues(alpha: 0.1),
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
                      Row(children: [
                        const Icon(Icons.restaurant_menu_rounded,
                            size: 12, color: AkeliColors.textSecondary),
                        const SizedBox(width: 2),
                        Text('${creator.recipeCount} recettes',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AkeliColors.textSecondary)),
                        const SizedBox(width: AkeliSpacing.sm),
                        const Icon(Icons.people_outline_rounded,
                            size: 12, color: AkeliColors.textSecondary),
                        const SizedBox(width: 2),
                        Text('${creator.fanCount} fans',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AkeliColors.textSecondary)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AkeliSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onActivate,
                style: FilledButton.styleFrom(
                  backgroundColor: isDominant ? AkeliColors.primary : null,
                ),
                child: const Text('Soutenir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View B — Fan
// ─────────────────────────────────────────────────────────────────────────────

class _FanUserView extends ConsumerWidget {
  final FanSubscription sub;
  const _FanUserView({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extCounterAsync = ref.watch(fanExternalCounterProvider);
    final creatorAsync = ref.watch(creatorProfileProvider(sub.creatorId));
    appLogger.provider('_FanUserView build() | status: ${sub.status}');

    final creator = creatorAsync.valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBanner(sub: sub, creator: creator),
          const SizedBox(height: AkeliSpacing.lg),

          if (sub.isActive)
            extCounterAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (count) => _ExternalCounterCard(count: count),
            ),
          if (sub.isActive) const SizedBox(height: AkeliSpacing.lg),

          _FanExplanationCard(creator: creator),
          const SizedBox(height: AkeliSpacing.lg),

          OutlinedButton(
            onPressed: () => _cancelFanMode(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AkeliColors.error,
              side: const BorderSide(color: AkeliColors.error),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Quitter le Mode Fan'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelFanMode(BuildContext context, WidgetRef ref) async {
    appLogger.userAction('Cancel fan mode button tapped', screen: 'FanModePage');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le Mode Fan'),
        content: const Text(
            'Votre soutien se terminera à la fin du mois en cours.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Garder')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AkeliColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    appLogger.userAction('Cancel fan mode confirmed', screen: 'FanModePage');
    await ref.read(fanModeNotifierProvider.notifier).cancel();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mode Fan annulé.')),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final FanSubscription sub;
  final Creator? creator;
  const _StatusBanner({required this.sub, this.creator});

  @override
  Widget build(BuildContext context) {
    final isPending = sub.isPending;
    final bannerColor =
        isPending ? const Color(0xFFFBBF24) : AkeliColors.primary;

    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: bannerColor.withValues(alpha: 0.15),
            backgroundImage: creator?.avatarUrl != null
                ? CachedNetworkImageProvider(creator!.avatarUrl!)
                : null,
            child: creator?.avatarUrl == null
                ? Text(
                    (creator?.displayName ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                        color: bannerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator?.displayName ?? '…',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (creator?.specialties.isNotEmpty == true)
                  Text(
                    creator!.specialties.first,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AkeliColors.textSecondary),
                  ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AkeliSpacing.sm, vertical: 2),
                  child: Text(
                    isPending
                        ? '⏳ Actif le 1er du mois prochain'
                        : '❤️ Mode Fan actif',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: bannerColor),
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

class _ExternalCounterCard extends StatelessWidget {
  final int count;
  const _ExternalCounterCard({required this.count});

  Color get _color {
    if (count <= 4) return AkeliColors.success;
    if (count <= 7) return const Color(0xFFFBBF24);
    return AkeliColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recettes externes ce mois',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AkeliColors.textSecondary,
                letterSpacing: 0.7),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recettes hors catalogue',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AkeliColors.textSecondary),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _color),
                    ),
                    const TextSpan(
                      text: ' / 9',
                      style: TextStyle(
                          fontSize: 14,
                          color: AkeliColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AkeliSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (count / 9).clamp(0.0, 1.0),
              backgroundColor: AkeliColors.background,
              valueColor: AlwaysStoppedAnimation(_color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FanExplanationCard extends StatelessWidget {
  final Creator? creator;
  const _FanExplanationCard({this.creator});

  @override
  Widget build(BuildContext context) {
    final name = creator?.displayName ?? 'votre créateur';
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Mode Fan',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AkeliColors.textSecondary,
                letterSpacing: 0.7),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                  fontSize: 13,
                  color: AkeliColors.textSecondary,
                  height: 1.6),
              children: [
                const TextSpan(text: 'Vous soutenez '),
                TextSpan(
                    text: name,
                    style: const TextStyle(
                        color: AkeliColors.onSurface,
                        fontWeight: FontWeight.w600)),
                const TextSpan(text: ' avec '),
                const TextSpan(
                    text: '1€/mois garanti',
                    style: TextStyle(
                        color: AkeliColors.onSurface,
                        fontWeight: FontWeight.w600)),
                const TextSpan(
                    text:
                        ', inclus dans votre abonnement.\n\nRègle 90/10 : 90% de vos repas doivent venir du catalogue de ce créateur. Vous pouvez utiliser jusqu\'à '),
                const TextSpan(
                    text: '9 recettes externes',
                    style: TextStyle(
                        color: AkeliColors.onSurface,
                        fontWeight: FontWeight.w600)),
                const TextSpan(text: ' par mois.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
