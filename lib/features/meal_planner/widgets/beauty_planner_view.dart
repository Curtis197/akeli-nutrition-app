import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/logger.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/beauty_plan_provider.dart';
import '../../../shared/models/beauty_plan.dart';

class BeautyPlannerView extends ConsumerWidget {
  static final _logger = appLogger;

  const BeautyPlannerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _logger.provider('BeautyPlannerView build()');
    final l10n = AppLocalizations.of(context);
    final beautyPlanAsync = ref.watch(activeBeautyPlanProvider);

    return beautyPlanAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          l10n.beautyPlannerLoadError(err.toString()),
          style: const TextStyle(color: AkeliColors.error),
        ),
      ),
      data: (plan) {
        if (plan == null || plan.slots.isEmpty) {
          return _buildEmptyBeautyState(context, ref, l10n);
        }

        final dailySlots = plan.slots.where((s) => s.frequencyTier == 'daily').toList();
        final weeklySlots = plan.slots.where((s) => s.frequencyTier == '1x_week' || s.frequencyTier == '2x_week').toList();
        final monthlySlots = plan.slots.where((s) => s.frequencyTier == '2x_month' || s.frequencyTier == '1x_month' || s.frequencyTier == null).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.spa_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          l10n.beautyPlannerHeaderTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.beautyPlannerHeaderSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (dailySlots.isNotEmpty) ...[
                _buildSectionHeader(context, l10n, l10n.beautyPlannerDailySectionTitle, dailySlots.length),
                const SizedBox(height: 12),
                ...dailySlots.take(2).map((slot) => _buildBeautySlotCard(context, ref, l10n, slot)),
                const SizedBox(height: 24),
              ],

              if (weeklySlots.isNotEmpty) ...[
                _buildSectionHeader(context, l10n, l10n.beautyPlannerWeeklySectionTitle, weeklySlots.length),
                const SizedBox(height: 12),
                ...weeklySlots.take(4).map((slot) => _buildBeautySlotCard(context, ref, l10n, slot)),
                const SizedBox(height: 24),
              ],

              if (monthlySlots.isNotEmpty) ...[
                _buildSectionHeader(context, l10n, l10n.beautyPlannerMonthlySectionTitle, monthlySlots.length),
                const SizedBox(height: 12),
                ...monthlySlots.take(3).map((slot) => _buildBeautySlotCard(context, ref, l10n, slot)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, AppLocalizations l10n, String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AkeliColors.textPrimary,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AkeliColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.beautyPlannerSectionCount(count),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AkeliColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeautySlotCard(BuildContext context, WidgetRef ref, AppLocalizations l10n, BeautyPlanSlot slot) {
    final recipe = slot.recipe;
    final isCompleted = slot.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? AkeliColors.primary.withValues(alpha: 0.3)
              : AkeliColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      elevation: 0,
      color: isCompleted ? AkeliColors.surfaceContainerLow : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: AkeliColors.surfaceContainerHigh,
            child: recipe?.thumbnailUrl != null && recipe!.thumbnailUrl!.isNotEmpty
                ? Image.network(recipe.thumbnailUrl!, fit: BoxFit.cover)
                : const Icon(Icons.spa, color: AkeliColors.primary),
          ),
        ),
        title: Text(
          recipe?.title ?? slot.stepStage,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? AkeliColors.textSecondary : AkeliColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AkeliColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  slot.routineCategory.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.beautyPlannerDayLabel((slot.dayNumber ?? slot.dayOfWeek).toString()),
                style: const TextStyle(fontSize: 12, color: AkeliColors.textSecondary),
              ),
            ],
          ),
        ),
        trailing: Checkbox(
          value: isCompleted,
          activeColor: AkeliColors.primary,
          onChanged: (val) {
            _logger.userAction(
              'Beauty routine checkbox toggled',
              screen: 'BeautyPlannerView',
              metadata: {'slotId': slot.id, 'from': isCompleted, 'to': !isCompleted},
            );
            _logger.db('BEFORE | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
            ref
                .read(toggleBeautySlotNotifierProvider.notifier)
                .toggleCompletion(slot.id, isCompleted)
                .then((_) {
              _logger.db('AFTER | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
            }).catchError((e, st) {
              _logger.db('ERROR | toggleCompletion via BeautyPlannerView | $e', error: e, stackTrace: st);
            });
          },
        ),
        onTap: () {
          if (recipe != null) {
            context.push(AkeliRoutes.recipeDetailPath(recipe.id));
          }
        },
      ),
    );
  }

  Widget _buildEmptyBeautyState(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 64, color: AkeliColors.primary),
            const SizedBox(height: 16),
            Text(
              l10n.beautyPlannerEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.beautyPlannerEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AkeliColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AkeliColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: Text(
                l10n.beautyPlannerGenerateButton,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _logger.userAction('Générer Mon Plan Beauté tapped', screen: 'BeautyPlannerView');
                _logger.db('BEFORE rpc | fn: generate_beauty_plan');
                ref.read(generateBeautyPlanNotifierProvider.notifier).generatePlan().then((_) {
                  _logger.db('AFTER rpc | fn: generate_beauty_plan | success');
                }).catchError((e, st) {
                  _logger.db('ERROR rpc | fn: generate_beauty_plan | $e', error: e, stackTrace: st);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}