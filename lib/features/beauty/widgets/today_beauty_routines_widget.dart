import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../providers/beauty_plan_provider.dart';
import '../../../shared/models/beauty_plan.dart';
import '../../../shared/widgets/empty_state.dart';

class TodayBeautyRoutinesWidget extends ConsumerWidget {
  const TodayBeautyRoutinesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                'Vos Rituels du Jour 👑',
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Planning (30j)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AkeliColors.primary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: AkeliColors.primary),
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
                  title: 'Aucun rituel aujourd\'hui',
                  subtitle: 'Générez votre planning mensuel dans l\'onglet Routine.',
                ),
              );
            }

            final today = DateTime.now();
            final todayDayNumber = today.day;
            final todayDayOfWeek = today.weekday; // 1 = Mon, 7 = Sun

            // Filter slots scheduled for today (by dayNumber or dayOfWeek fallback)
            final todaySlots = plan.slots.where((s) {
              if (s.dayNumber != null) {
                return s.dayNumber == todayDayNumber;
              }
              return s.dayOfWeek == todayDayOfWeek;
            }).toList();

            if (todaySlots.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AkeliColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AkeliColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Journée de repos pour votre cuir chevelu & peau !',
                        style: TextStyle(
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
                return _buildTodaySlotCard(context, ref, slot);
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
              'Erreur lors du chargement des rituels : $err',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySlotCard(
      BuildContext context, WidgetRef ref, BeautyPlanSlot slot) {
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
                slot.frequencyTier != null ? 'Tier: ${slot.frequencyTier}' : 'Rituel',
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
            ref
                .read(toggleBeautySlotNotifierProvider.notifier)
                .toggleCompletion(slot.id, isCompleted);
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
