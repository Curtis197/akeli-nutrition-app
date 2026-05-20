import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../shared/models/meal_plan.dart';

class BatchCookingPage extends ConsumerWidget {
  const BatchCookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(cookingSessionsProvider);

    appLogger.provider('BatchCookingPage build() | sessionsAsync.isLoading: ${sessionsAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AkeliColors.primary),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        title: const Text(
          'Batch Cooking',
          style: TextStyle(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: AkeliColors.primary),
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          appLogger.userAction('Create batch session FAB tapped', screen: 'BatchCookingPage');
          _showCreateSessionSheet(context);
        },
        backgroundColor: AkeliColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.error)),
        ),
        data: (sessions) => sessions.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                itemCount: sessions.length + 1, // +1 for the header
                separatorBuilder: (_, index) => index == 0 ? const SizedBox.shrink() : const SizedBox(height: 16),
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cette semaine',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AkeliColors.onSurface,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Vos préparations en cours',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AkeliColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Voir tout', style: TextStyle(color: AkeliColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }
                  return _CookingSessionCard(session: sessions[index - 1]);
                },
              ),
      ),
    );
  }

  void _showCreateSessionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AkeliColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle session',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AkeliColors.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AkeliColors.primary, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La création de sessions batch sera disponible prochainement avec le sélecteur de recettes.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AkeliColors.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AkeliColors.primary,
                  disabledBackgroundColor: AkeliColors.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Bientôt disponible', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    appLogger.provider('BatchCookingEmptyState build()');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍲', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              'Aucune session cette semaine',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Appuyez sur + pour créer votre première session batch.',
              style: TextStyle(color: AkeliColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CookingSessionCard extends StatelessWidget {
  final CookingSession session;
  const _CookingSessionCard({required this.session});

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${date.day} ${months[date.month - 1]}.';
  }

  @override
  Widget build(BuildContext context) {
    appLogger.provider('CookingSessionCard build() | sessionId: ${session.id}');
    final progress = session.totalPortions > 0
        ? session.portionsUsed / session.totalPortions
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Recipe image / emoji
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AkeliColors.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: session.recipeThumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(session.recipeThumbnail!, fit: BoxFit.cover),
                  )
                : const Center(child: Text('🍲', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 20),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.recipeTitle ?? 'Recette',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AkeliColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(session.plannedDate)} · ${session.totalPortions} portions',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AkeliColors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            session.hasAvailablePortions
                                ? AkeliColors.primary
                                : AkeliColors.outline,
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${session.portionsUsed}/${session.totalPortions}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AkeliColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // More vert button
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AkeliColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: AkeliColors.onSurfaceVariant, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
