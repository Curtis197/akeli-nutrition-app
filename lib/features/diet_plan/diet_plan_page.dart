import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:intl/intl.dart';

/// [Akeli] DietPlanPage - High-Fidelity Editorial Redesign
/// This page presents the weekly meal plan with an editorial summary and a vertical
/// list of meals per day, matching the "akeli_diet_plan_editorial" HTML aesthetic.
class DietPlanPage extends ConsumerStatefulWidget {
  const DietPlanPage({super.key});

  @override
  ConsumerState<DietPlanPage> createState() => _DietPlanPageState();
}

class _DietPlanPageState extends ConsumerState<DietPlanPage> {
  final _logger = appLogger;

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activeMealPlanProvider);
    _logger.provider('DietPlanPage build() | planAsync.isLoading: ${planAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Récapitulatif',
              style: TextStyle(
                color: AkeliColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Votre plan diététique',
              style: TextStyle(
                color: AkeliColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AkeliColors.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: AkeliColors.surfaceContainerLowest,
            ),
          ),
        ),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Erreur: $e',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.error),
          ),
        ),
        data: (plan) {
          final entries = plan?.entries ?? [];
          
          // Group entries by date
          final groupedMeals = <DateTime, List<dynamic>>{};
          for (final entry in entries) {
            final date = DateTime(
              entry.scheduledDate.year,
              entry.scheduledDate.month,
              entry.scheduledDate.day,
            );
            groupedMeals.putIfAbsent(date, () => []).add(entry);
          }

          // Generate date list for the week (starting today)
          final today = DateTime.now();
          final startOfWeek = DateTime(today.year, today.month, today.day);
          final weekDates = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSummaryCard(context),
              const SizedBox(height: 32),
              
              // Daily Recaps
              ...weekDates.map((date) {
                final meals = groupedMeals[date] ?? [];
                if (meals.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildDailyRecapCard(context, date, meals),
                );
              }),

              const SizedBox(height: 16),
              _buildActionButtons(context),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AkeliColors.primaryContainer.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.track_changes, color: AkeliColors.primary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '5 kg',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AkeliColors.primary, letterSpacing: -0.5),
                      ),
                      const Text(
                        'À PERDRE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AkeliColors.onSurfaceVariant, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AkeliColors.tertiary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_menu, color: AkeliColors.tertiary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '3 mois',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AkeliColors.tertiary, letterSpacing: -0.5),
                      ),
                      const Text(
                        'OBJECTIF',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AkeliColors.onSurfaceVariant, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AkeliColors.secondaryContainer, AkeliColors.surfaceContainerLow],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AkeliColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department, color: AkeliColors.secondary),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1800 kcal/jour',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AkeliColors.onSecondaryContainer),
                    ),
                    Text(
                      'Objectif calorique',
                      style: TextStyle(fontSize: 14, color: AkeliColors.onSecondaryContainer),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'RESTRICTIONS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AkeliColors.onSurfaceVariant, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AkeliColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.eco, size: 18, color: AkeliColors.primary),
                    SizedBox(width: 8),
                    Text('Végétarien', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AkeliColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AkeliColors.error.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, size: 18, color: AkeliColors.error),
                    SizedBox(width: 8),
                    Text('Gluten', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AkeliColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecapCard(BuildContext context, DateTime date, List<dynamic> meals) {
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(date);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr.replaceFirst(dateStr[0], dateStr[0].toUpperCase()),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AkeliColors.onSurface),
          ),
          const SizedBox(height: 24),
          ...meals.map((m) {
            IconData icon;
            Color iconColor = AkeliColors.primary;
            switch (m.mealType) {
              case 'breakfast':
                icon = Icons.sunny;
                break;
              case 'lunch':
                icon = Icons.lunch_dining;
                break;
              case 'dinner':
                icon = Icons.dark_mode;
                iconColor = AkeliColors.tertiary;
                break;
              default:
                icon = Icons.restaurant;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _logger.userAction('Meal item tapped', screen: 'DietPlanPage', metadata: {'mealId': m.id});
                    context.go(AkeliRoutes.mealDetailPath(m.id));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AkeliColors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.mealTypeLabel,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AkeliColors.onSurface),
                              ),
                              Text(
                                m.recipeTitle ?? 'Repas',
                                style: const TextStyle(fontSize: 14, color: AkeliColors.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(m.calories ?? 0).toInt()} kcal',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AkeliColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              _logger.userAction('Regenerate plan tapped', screen: 'DietPlanPage');
              await ref.read(mealPlanGeneratorProvider.notifier).generate();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Régénérer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AkeliColors.onSurface,
              side: BorderSide(color: AkeliColors.outlineVariant.withValues(alpha: 0.5), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              _logger.userAction('Shopping list button tapped', screen: 'DietPlanPage');
              context.go(AkeliRoutes.shoppingList);
            },
            icon: const Icon(Icons.shopping_basket),
            label: const Text('Liste courses'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AkeliColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
