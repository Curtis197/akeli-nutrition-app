import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/user_profile_provider.dart';
import '../../l10n/app_localizations.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  List<String> _featuresList(AppLocalizations l) => [
    l.subscriptionFeature1,
    l.subscriptionFeature2,
    l.subscriptionFeature3,
    l.subscriptionFeature4,
    l.subscriptionFeature5,
    l.subscriptionFeature6,
    l.subscriptionFeature7,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final subAsync = ref.watch(subscriptionProvider);
    appLogger.provider('SubscriptionPage build() | isPremium: $isPremium');
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: Text(l10n.subscriptionMyTitle),
        backgroundColor: AkeliColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AkeliSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(AkeliSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AkeliColors.primary, Color(0xFF2A9D7F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AkeliRadius.lg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: AkeliSpacing.md),
                  Text(
                    isPremium ? l10n.subscriptionActiveTitle : l10n.subscriptionPremiumBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AkeliSpacing.sm),
                  Text(
                    isPremium
                        ? l10n.subscriptionActiveThankYou
                        : l10n.subscriptionTagline,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.xl),

            if (isPremium) ...[
              subAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (sub) => sub != null
                    ? _ActiveSubCard(sub: sub)
                    : const SizedBox.shrink(),
              ),
            ] else ...[
              Text(l10n.subscriptionIncludedTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AkeliSpacing.md),
              ..._featuresList(l10n).map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AkeliColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: AkeliSpacing.md),
                      Expanded(
                        child: Text(f,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AkeliSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AkeliSpacing.lg),
                  child: Column(
                    children: [
                      const Text(
                        '3,99€',
                        style: TextStyle(
                          color: AkeliColors.primary,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(l10n.subscriptionPerMonth,
                          style: const TextStyle(
                              color: AkeliColors.textSecondary, fontSize: 18)),
                      const SizedBox(height: AkeliSpacing.xs),
                      Text(
                        l10n.subscriptionCancelAnytime,
                        style: const TextStyle(
                            color: AkeliColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AkeliSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  appLogger.userAction('Subscribe button tapped', screen: 'SubscriptionPage');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          l10n.subscriptionMobileOnly),
                    ),
                  );
                },
                icon: const Icon(Icons.star_rounded),
                label: Text(l10n.subscriptionSubscribeViaStore),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveSubCard extends StatelessWidget {
  final Map<String, dynamic> sub;

  const _ActiveSubCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    appLogger.d('ActiveSubCard build()');
    final l10n = AppLocalizations.of(context);
    final expiresAt = sub['current_period_end'] != null
        ? DateTime.tryParse(sub['current_period_end'] as String)
        : null;
    final platform = sub['store_platform'] as String? ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AkeliSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AkeliColors.success),
                const SizedBox(width: AkeliSpacing.sm),
                Text(l10n.subscriptionActiveBadge,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AkeliColors.success,
                        )),
              ],
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: AkeliSpacing.sm),
              Text(
                l10n.subscriptionRenewalDate(_formatDate(expiresAt)),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
            ],
            if (platform.isNotEmpty) ...[
              const SizedBox(height: AkeliSpacing.xs),
              Text(
                platform == 'ios' ? l10n.subscriptionPlatformIos : l10n.subscriptionPlatformAndroid,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
