import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/logger.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/beauty_plan_provider.dart';
import '../../../shared/models/beauty_plan.dart';
import '../../../shared/widgets/empty_state.dart';

class TodayBeautyRoutinesWidget extends ConsumerWidget {
  final DateTime Function() now;
  static final _logger = appLogger;

  const TodayBeautyRoutinesWidget({super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _logger.provider('TodayBeautyRoutinesWidget build()');
    final l10n = AppLocalizations.of(context);
    final beautyPlanAsync = ref.watch(activeBeautyPlanProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.todayBeautyRoutinesTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.textPrimary,
                    ),
              ),
              TextButton(
                key: const Key('open_beauty_planner_button'),
                onPressed: () {
                  context.push(AkeliRoutes.mealPlanner);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.todayBeautyRoutinesPlanningLink,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AkeliColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: AkeliColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        beautyPlanAsync.when(
          data: (plan) {
            if (plan == null || plan.slots.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: EmptyState(
                  icon: Icons.spa_outlined,
                  title: l10n.todayBeautyRoutinesEmptyTitle,
                  subtitle: l10n.todayBeautyRoutinesEmptySubtitle,
                ),
              );
            }

            final today = now();

            final todaySlots = plan.slots.where((s) {
              if (s.dayNumber != null) {
                final slotDate = plan.startDate.add(Duration(days: s.dayNumber! - 1));
                return slotDate.year == today.year &&
                    slotDate.month == today.month &&
                    slotDate.day == today.day;
              }
              return s.dayOfWeek == today.weekday;
            }).toList();

            if (todaySlots.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AkeliColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AkeliColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.todayBeautyRoutinesRestDay,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AkeliColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: todaySlots.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final slot = todaySlots[index];
                return _buildTodaySlotCard(context, ref, l10n, slot);
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.todayBeautyRoutinesLoadError(err.toString()),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySlotCard(
      BuildContext context, WidgetRef ref, AppLocalizations l10n, BeautyPlanSlot slot) {
    final isCompleted = slot.isCompleted;
    final recipe = slot.recipe;

    return Card(
      elevation: 0,
      color: isCompleted
          ? AkeliColors.surfaceContainerLow
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? Colors.transparent
              : AkeliColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 48,
            height: 48,
            color: AkeliColors.secondaryContainer,
            child: recipe?.thumbnailUrl != null && recipe!.thumbnailUrl!.isNotEmpty
                ? Image.network(recipe.thumbnailUrl!, fit: BoxFit.cover)
                : const Icon(Icons.spa, color: AkeliColors.primary),
          ),
        ),
        title: Text(
          recipe?.title ?? slot.stepStage,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted
                ? AkeliColors.textSecondary
                : AkeliColors.textPrimary,
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
                slot.frequencyTier != null
                    ? l10n.todayBeautyRoutinesTierLabel(slot.frequencyTier!)
                    : l10n.todayBeautyRoutinesDefaultLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AkeliColors.textSecondary,
                ),
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
              screen: 'TodayBeautyRoutinesWidget',
              metadata: {'slotId': slot.id, 'from': isCompleted, 'to': !isCompleted},
            );
            _logger.db('BEFORE | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
            ref
                .read(toggleBeautySlotNotifierProvider.notifier)
                .toggleCompletion(slot.id, isCompleted)
                .then((_) {
              _logger.db('AFTER | table: beauty_plan_slot | op: UPDATE is_completed | slotId: ${slot.id}');
            }).catchError((e, st) {
              _logger.db('ERROR | toggleCompletion via TodayBeautyRoutinesWidget | $e', error: e, stackTrace: st);
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
}