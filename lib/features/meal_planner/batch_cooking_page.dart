import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/mode_provider.dart';
import '../../widgets/mode_selector.dart';
import '../../shared/models/meal_plan.dart';

class BatchCookingPage extends ConsumerWidget {
  const BatchCookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appMode = ref.watch(currentModeProvider);
    final isBeauty = appMode == AppMode.beauty;
    final accentColor = getAppModeColor(appMode);
    final title = isBeauty ? 'Prep Soins Hebdomadaire' : l10n.batchCookingTitle;

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
            icon: Icon(Icons.arrow_back, color: accentColor),
            onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(AkeliRoutes.mealPlanner);
                }
              },
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: const [],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(l10n.mealPlannerError(e.toString()),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.batchCookingThisWeek,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AkeliColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.batchCookingOngoing,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AkeliColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final session = sessions[index - 1];
                  return _CookingSessionCard(
                    session: session,
                    onToggleCooked: () => ref
                        .read(cookingSessionsProvider.notifier)
                        .markCooked(session.id, isCooked: !session.isCooked),
                    onTap: () => context.push(
                      AkeliRoutes.batchCookingDetailPath(session.id),
                      extra: {'session': session},
                    ),
                  );
                },
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
    final l10n = AppLocalizations.of(context);
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
              l10n.batchCookingNoSessionsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.batchCookingNoSessionsBody,
              style: const TextStyle(color: AkeliColors.onSurfaceVariant),
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
  final VoidCallback onToggleCooked;
  final VoidCallback onTap;
  const _CookingSessionCard({
    required this.session,
    required this.onToggleCooked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat('d MMM', locale).format(session.plannedDate);
    appLogger.provider('CookingSessionCard build() | sessionId: ${session.id}');
    final progress = session.totalPortions > 0
        ? session.portionsUsed / session.totalPortions
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Recipe image
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
                    session.localizedTitle(locale) ?? l10n.batchCookingDefaultRecipe,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedDate · ${session.totalPortions} portions',
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
                              (session.totalPortions - session.portionsUsed) > 0
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
            GestureDetector(
              onTap: onToggleCooked,
              child: Icon(
                session.isCooked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: session.isCooked ? AkeliColors.primary : AkeliColors.outline,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
