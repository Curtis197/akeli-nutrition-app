import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
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
                  const Icon(Icons.star_rounded,
                      color: Colors.white, size: 48),
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
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.xl),

            if (isPremium) ...[
              // Active subscription details
              subAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (sub) => sub != null
                    ? _ActiveSubCard(sub: sub)
                    : const SizedBox.shrink(),
              ),
            ] else ...[
              // Features list
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
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AkeliSpacing.xl),

              // Pricing
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AkeliSpacing.lg),
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '3€',
                              style: TextStyle(
                                color: AkeliColors.primary,
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: ' / mois',
                              style: TextStyle(
                                color: AkeliColors.textSecondary,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AkeliSpacing.xs),
                      const Text(
                        'Annulable à tout moment',
                        style: TextStyle(
                            color: AkeliColors.textSecondary,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AkeliSpacing.lg),

              FilledButton.icon(
                onPressed: () => _startCheckout(context, ref),
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Commencer mon abonnement'),
              ),
              const SizedBox(height: AkeliSpacing.sm),
              const Center(
                child: Text(
                  'Paiement sécurisé par Stripe',
                  style: TextStyle(
                      color: AkeliColors.textSecondary, fontSize: 12),
                ),
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

  Future<void> _startCheckout(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await supabase.functions.invoke(
        'create-checkout-session',
        body: {'plan': 'premium_monthly'},
      );

      final url = (res.data as Map<String, dynamic>)['url'] as String?;
      if (url != null && context.mounted) {
        // Open Stripe checkout URL in-app browser
        // In a real app, use url_launcher or an in-app WebView
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Ouverture du paiement: $url')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de l\'initiation du paiement.')),
        );
      }
    }
  }
}

class _ActiveSubCard extends StatelessWidget {
  final Map<String, dynamic> sub;

  const _ActiveSubCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final expiresAt = sub['current_period_end'] != null
        ? DateTime.parse(sub['current_period_end'] as String)
        : null;

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
                'Prochain renouvellement: ${_formatDate(expiresAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: AkeliSpacing.lg),
            OutlinedButton(
              onPressed: () {
                // Handle cancellation through Stripe portal
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Gestion de l\'abonnement bientôt disponible.')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AkeliColors.error,
                side: const BorderSide(color: AkeliColors.error),
              ),
              child: const Text('Annuler l\'abonnement'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
