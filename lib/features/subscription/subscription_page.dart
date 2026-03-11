import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/user_profile_provider.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon abonnement')),
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
                    isPremium ? 'Abonnement actif' : 'Akeli Premium',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AkeliSpacing.sm),
                  Text(
                    isPremium
                        ? 'Merci de faire partie de la communauté Akeli.'
                        : 'Nutrition africaine personnalisée',
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
              Text('Ce qui est inclus',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AkeliSpacing.md),
              ..._features.map(
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
                      const Text(' / mois',
                          style: TextStyle(
                              color: AkeliColors.textSecondary, fontSize: 18)),
                      const SizedBox(height: AkeliSpacing.xs),
                      const Text(
                        'Annulable à tout moment via le Store',
                        style: TextStyle(
                            color: AkeliColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AkeliSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Abonnement disponible sur iOS et Android uniquement.'),
                    ),
                  );
                },
                icon: const Icon(Icons.star_rounded),
                label: const Text("S'abonner via le Store"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _features = [
    'Recettes africaines personnalisées avec IA',
    'Plan alimentaire hebdomadaire adapté',
    'Suivi nutritionnel détaillé',
    'Assistant IA nutritionnel',
    'Mode Fan — soutenez vos créateurs',
    'Communauté et groupes de discussion',
    'Liste de courses automatique',
  ];
}

class _ActiveSubCard extends StatelessWidget {
  final Map<String, dynamic> sub;

  const _ActiveSubCard({required this.sub});

  @override
  Widget build(BuildContext context) {
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
                Text('Abonnement Premium actif',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AkeliColors.success,
                        )),
              ],
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: AkeliSpacing.sm),
              Text(
                'Prochain renouvellement : ${_formatDate(expiresAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
            ],
            if (platform.isNotEmpty) ...[
              const SizedBox(height: AkeliSpacing.xs),
              Text(
                'Abonnement via ${platform == 'ios' ? 'App Store' : 'Google Play'}',
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
