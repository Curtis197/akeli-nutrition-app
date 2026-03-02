import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/user_profile_provider.dart';

// Product ID must match what you created in Google Play Console and App Store Connect
const _kProductId = 'akeli_premium_monthly';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _product;
  bool _storeAvailable = true;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final available = await _iap.isAvailable();
    if (!available) {
      setState(() {
        _storeAvailable = false;
        _loading = false;
      });
      return;
    }

    final response = await _iap.queryProductDetails({_kProductId});
    setState(() {
      _product = response.productDetails.isNotEmpty
          ? response.productDetails.first
          : null;
      _loading = false;
    });
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _validateAndActivate(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        setState(() => _purchasing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  purchase.error?.message ?? 'Erreur lors du paiement'),
            ),
          );
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        setState(() => _purchasing = false);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _validateAndActivate(PurchaseDetails purchase) async {
    try {
      // Server-side receipt validation — updates the subscription table
      // which activate-fan-mode then checks before allowing Fan Mode
      await supabase.functions.invoke(
        'validate-store-purchase',
        body: {
          'platform': purchase.verificationData.source,
          'purchase_token': purchase.verificationData.serverVerificationData,
          'product_id': purchase.productID,
        },
      );

      ref.invalidate(subscriptionProvider);
      ref.invalidate(isPremiumProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement Premium activé !'),
            backgroundColor: AkeliColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Paiement reçu mais une erreur est survenue. Contactez le support.'),
          ),
        );
      }
    } finally {
      setState(() => _purchasing = false);
    }
  }

  Future<void> _subscribe() async {
    if (_product == null || _purchasing) return;
    setState(() => _purchasing = true);
    final param = PurchaseParam(productDetails: _product!);
    // Subscriptions are treated as non-consumable on both stores
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  void _openStoreSubscriptionSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Platform.isIOS
              ? 'Allez dans Réglages > Votre nom > Abonnements pour gérer votre abonnement.'
              : 'Allez dans le Play Store > Abonnements pour gérer votre abonnement.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              subAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (sub) => sub != null
                    ? _ActiveSubCard(
                        sub: sub,
                        onManage: _openStoreSubscriptionSettings,
                      )
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
                      if (_loading)
                        const CircularProgressIndicator()
                      else if (!_storeAvailable)
                        const Text('Store non disponible sur cet appareil.')
                      else
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                // Show price from store if loaded, else fallback
                                text: _product?.price ?? '3,99€',
                                style: const TextStyle(
                                  color: AkeliColors.primary,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(
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
                        'Annulable à tout moment via le Store',
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
                onPressed: (_loading || !_storeAvailable || _purchasing)
                    ? null
                    : _subscribe,
                icon: _purchasing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Platform.isIOS
                            ? Icons.apple
                            : Icons.android,
                      ),
                label: Text(_purchasing
                    ? 'Traitement...'
                    : 'S\'abonner via le Store'),
              ),
              const SizedBox(height: AkeliSpacing.sm),
              Center(
                child: Text(
                  Platform.isIOS
                      ? 'Paiement géré par l\'App Store'
                      : 'Paiement géré par le Google Play Store',
                  style: const TextStyle(
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
}

class _ActiveSubCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final VoidCallback onManage;

  const _ActiveSubCard({required this.sub, required this.onManage});

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
            const SizedBox(height: AkeliSpacing.lg),
            OutlinedButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Gérer l\'abonnement via le Store'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AkeliColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
