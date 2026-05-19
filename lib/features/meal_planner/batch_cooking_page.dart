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
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Batch Cooking'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          appLogger.userAction('Create batch session FAB tapped', screen: 'BatchCookingPage');
          _showCreateSessionSheet(context);
        },
        backgroundColor: AkeliColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.error)),
        ),
        data: (sessions) => sessions.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    AkeliSpacing.md, AkeliSpacing.md, AkeliSpacing.md, 100),
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AkeliSpacing.sm),
                itemBuilder: (_, i) =>
                    _CookingSessionCard(session: sessions[i]),
              ),
      ),
    );
  }

  void _showCreateSessionSheet(BuildContext context) {
    appLogger.userAction('Create session sheet opened', screen: 'BatchCookingPage');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AkeliColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AkeliSpacing.lg,
          AkeliSpacing.lg,
          AkeliSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AkeliSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle session',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AkeliSpacing.md),
            Container(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              decoration: BoxDecoration(
                color: AkeliColors.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AkeliRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AkeliColors.primary, size: 18),
                  const SizedBox(width: AkeliSpacing.sm),
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
            const SizedBox(height: AkeliSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AkeliColors.primary,
                  disabledBackgroundColor:
                      AkeliColors.surfaceContainerHighest,
                  padding:
                      const EdgeInsets.symmetric(vertical: AkeliSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AkeliRadius.md)),
                ),
                child: Text('Bientôt disponible',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AkeliColors.outline,
                          fontWeight: FontWeight.w700,
                        )),
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
        padding: const EdgeInsets.all(AkeliSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍲', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AkeliSpacing.md),
            Text(
              'Aucune session cette semaine',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AkeliSpacing.sm),
            Text(
              'Appuyez sur + pour créer votre première session batch.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.outline),
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
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AkeliRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Recipe image / emoji
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AkeliColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AkeliRadius.sm),
            ),
            child: session.recipeThumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AkeliRadius.sm),
                    child: Image.network(session.recipeThumbnail!,
                        fit: BoxFit.cover),
                  )
                : const Center(
                    child: Text('🍲', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: AkeliSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.recipeTitle ?? 'Recette',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(session.plannedDate)} · ${session.totalPortions} portions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AkeliColors.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              AkeliColors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            session.hasAvailablePortions
                                ? AkeliColors.primary
                                : AkeliColors.outline,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: AkeliSpacing.sm),
                    Text(
                      '${session.portionsUsed}/${session.totalPortions}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AkeliColors.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
