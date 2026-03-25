import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/widgets/empty_state.dart';

class MealPlannerPage extends ConsumerWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeMealPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: const Text('Mes repas'),
        backgroundColor: AkeliColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push(AkeliRoutes.shoppingList),
            tooltip: 'Liste de courses',
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(activeMealPlanProvider),
        ),
        data: (plan) {
          if (plan == null) {
            return EmptyState(
              icon: Icons.calendar_today_rounded,
              title: 'Aucun plan actif',
              subtitle:
                  'Générez votre plan alimentaire personnalisé pour la semaine.',
              actionLabel: 'Générer mon plan',
              onAction: () => _generatePlan(context, ref),
            );
          }
          return _MealPlanContent(plan: plan);
        },
      ),
      floatingActionButton: planAsync.when(
        data: (plan) => plan != null
            ? FloatingActionButton.extended(
                onPressed: () => _generatePlan(context, ref),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Nouveau plan'),
                backgroundColor: AkeliColors.primary,
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Future<void> _generatePlan(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await ref.read(mealPlanGeneratorProvider.notifier).generate();
    final state = ref.read(mealPlanGeneratorProvider);
    if (state.hasError) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Impossible de générer le plan.')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('Plan généré avec succès !'),
            backgroundColor: AkeliColors.success),
      );
    }
  }
}

class _MealPlanContent extends StatelessWidget {
  final MealPlan plan;

  const _MealPlanContent({required this.plan});

  @override
  Widget build(BuildContext context) {
    final days = _buildDays();

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(AkeliSpacing.md),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final (date, entries) = days[i];
          return _DaySection(date: date, entries: entries);
        },
      ),
    );
  }

  List<(DateTime, List<MealPlanEntry>)> _buildDays() {
    final result = <(DateTime, List<MealPlanEntry>)>[];
    var current = plan.startDate;
    final end = plan.endDate;

    while (!current.isAfter(end)) {
      final entries = plan.entriesForDate(current);
      result.add((current, entries));
      current = current.add(const Duration(days: 1));
    }

    return result;
  }
}

class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<MealPlanEntry> entries;

  const _DaySection({required this.date, required this.entries});

  static const _dayNames = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  static const _mealOrder = [
    'breakfast', 'lunch', 'dinner', 'snack'
  ];

  String get _dayLabel {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Aujourd'hui";
    }
    return _dayNames[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isToday = () {
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }();

    // Group entries by meal type
    final byType = <String, MealPlanEntry>{};
    for (final e in entries) {
      byType[e.mealType] = e;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
          child: Row(
            children: [
              Text(
                _dayLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isToday ? AkeliColors.primary : null,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    ),
              ),
              if (isToday) ...[
                const SizedBox(width: AkeliSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AkeliSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AkeliColors.primary,
                    borderRadius: BorderRadius.circular(AkeliRadius.full),
                  ),
                  child: const Text(
                    'Aujourd\'hui',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
        ..._mealOrder.map((type) {
          final entry = byType[type];
          return _MealSlot(type: type, entry: entry);
        }),
        const SizedBox(height: AkeliSpacing.sm),
        const Divider(),
        const SizedBox(height: AkeliSpacing.sm),
      ],
    );
  }
}

class _MealSlot extends ConsumerWidget {
  final String type;
  final MealPlanEntry? entry;

  const _MealSlot({required this.type, this.entry});

  String get _typeLabel {
    switch (type) {
      case 'breakfast':
        return 'Petit-déjeuner';
      case 'lunch':
        return 'Déjeuner';
      case 'dinner':
        return 'Dîner';
      case 'snack':
        return 'Collation';
      default:
        return type;
    }
  }

  IconData get _typeIcon {
    switch (type) {
      case 'breakfast':
        return Icons.coffee_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snack':
        return Icons.apple_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
      child: entry == null
          ? _EmptySlot(typeLabel: _typeLabel, icon: _typeIcon)
          : _FilledSlot(
              entry: entry!,
              typeLabel: _typeLabel,
              icon: _typeIcon,
              onTap: () => context
                  .push(AkeliRoutes.recipeDetailPath(entry!.recipeId)),
              onConsume: () async {
                await ref
                    .read(mealConsumptionProvider.notifier)
                    .logConsumption(entry!.id, entry!.recipeId);
              },
            ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String typeLabel;
  final IconData icon;

  const _EmptySlot({required this.typeLabel, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
            color: AkeliColors.primary.withValues(alpha: 0.3), width: 1.5,
            style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AkeliColors.textSecondary),
          const SizedBox(width: AkeliSpacing.md),
          Text(typeLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.textSecondary)),
          const Spacer(),
          const Icon(Icons.add_rounded, color: AkeliColors.primary, size: 20),
        ],
      ),
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final MealPlanEntry entry;
  final String typeLabel;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onConsume;

  const _FilledSlot({
    required this.entry,
    required this.typeLabel,
    required this.icon,
    required this.onTap,
    required this.onConsume,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AkeliSpacing.md),
        decoration: BoxDecoration(
          color: entry.isConsumed
              ? AkeliColors.success.withValues(alpha: 0.08)
              : AkeliColors.surface,
          borderRadius: BorderRadius.circular(AkeliRadius.md),
          border: Border.all(
            color: entry.isConsumed
                ? AkeliColors.success.withValues(alpha: 0.4)
                : const Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (entry.recipeThumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AkeliRadius.sm),
                child: Image.network(
                  entry.recipeThumbnail!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AkeliColors.background,
                      borderRadius: BorderRadius.circular(AkeliRadius.sm),
                    ),
                    child: Icon(icon, size: 24, color: AkeliColors.primary),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AkeliColors.background,
                  borderRadius: BorderRadius.circular(AkeliRadius.sm),
                ),
                child: Icon(icon, size: 24, color: AkeliColors.primary),
              ),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AkeliColors.textSecondary,
                          )),
                  const SizedBox(height: 2),
                  Text(
                    entry.recipeTitle ?? 'Recette',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: entry.isConsumed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.calories != null)
                    Text(
                      '${entry.calories!.toInt()} kcal',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AkeliColors.secondary),
                    ),
                ],
              ),
            ),
            if (!entry.isConsumed)
              IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded,
                    color: AkeliColors.success),
                onPressed: onConsume,
                tooltip: 'Marquer comme consommé',
              )
            else
              const Icon(Icons.check_circle_rounded,
                  color: AkeliColors.success, size: 24),
          ],
        ),
      ),
    );
  }
}
