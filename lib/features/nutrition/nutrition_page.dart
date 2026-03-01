import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/nutrition_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/macro_card.dart';

class NutritionPage extends ConsumerStatefulWidget {
  const NutritionPage({super.key});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Aujourd'hui"),
            Tab(text: 'Semaine'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTab(),
          _WeeklyTab(),
        ],
      ),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayNutritionProvider);

    return todayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorState(message: err.toString()),
      data: (nutrition) {
        if (nutrition == null) {
          return const EmptyState(
            icon: Icons.restaurant_outlined,
            title: 'Aucune donnée aujourd\'hui',
            subtitle:
                'Consommez des repas pour voir vos données nutritionnelles.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AkeliSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bilan du jour",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AkeliSpacing.md),
              MacroRow(
                calories: nutrition.calories,
                proteinG: nutrition.proteinG,
                carbsG: nutrition.carbsG,
                fatG: nutrition.fatG,
              ),
              const SizedBox(height: AkeliSpacing.xl),
              // Macro donut chart
              _MacroDonutChart(
                proteinG: nutrition.proteinG,
                carbsG: nutrition.carbsG,
                fatG: nutrition.fatG,
              ),
              const SizedBox(height: AkeliSpacing.xl),
              // Water tracker
              _WaterTracker(waterMl: nutrition.waterMl),
              const SizedBox(height: AkeliSpacing.xl),
              // Weight log
              _WeightSection(),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weeklyNutritionProvider);

    return weekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorState(message: err.toString()),
      data: (days) {
        if (days.isEmpty) {
          return const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'Pas encore de données',
            subtitle: 'Commencez à consommer des repas pour voir votre suivi hebdomadaire.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AkeliSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calories cette semaine',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AkeliSpacing.md),
              _WeeklyCaloriesChart(days: days),
              const SizedBox(height: AkeliSpacing.xl),
              Text('Moyenne quotidienne',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AkeliSpacing.md),
              _AverageStats(days: days),
            ],
          ),
        );
      },
    );
  }
}

class _MacroDonutChart extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const _MacroDonutChart({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  @override
  Widget build(BuildContext context) {
    final total = proteinG + carbsG + fatG;
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: proteinG,
                    color: AkeliColors.primary,
                    title:
                        '${(proteinG / total * 100).toInt()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: carbsG,
                    color: AkeliColors.tertiary,
                    title:
                        '${(carbsG / total * 100).toInt()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: fatG,
                    color: AkeliColors.warning,
                    title:
                        '${(fatG / total * 100).toInt()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: AkeliSpacing.lg),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Legend(color: AkeliColors.primary, label: 'Protéines'),
              const SizedBox(height: AkeliSpacing.sm),
              _Legend(color: AkeliColors.tertiary, label: 'Glucides'),
              const SizedBox(height: AkeliSpacing.sm),
              _Legend(color: AkeliColors.warning, label: 'Lipides'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12, height: 12, color: color,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            )),
        const SizedBox(width: AkeliSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _WaterTracker extends StatefulWidget {
  final double waterMl;

  const _WaterTracker({required this.waterMl});

  @override
  State<_WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<_WaterTracker> {
  static const _targetMl = 2000.0;
  static const _glassSize = 250.0;

  @override
  Widget build(BuildContext context) {
    final current = widget.waterMl;
    final glasses = (current / _glassSize).floor();
    final targetGlasses = (_targetMl / _glassSize).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.water_drop_rounded,
                color: AkeliColors.info, size: 20),
            const SizedBox(width: AkeliSpacing.xs),
            Text('Eau', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              '${current.toInt()}ml / ${_targetMl.toInt()}ml',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AkeliColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AkeliSpacing.sm),
        Row(
          children: List.generate(
            targetGlasses,
            (i) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                i < glasses
                    ? Icons.water_drop_rounded
                    : Icons.water_drop_outlined,
                color: i < glasses ? AkeliColors.info : AkeliColors.textSecondary,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _WeightSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightAsync = ref.watch(weightLogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Mon poids',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AkeliColors.primary),
              onPressed: () => _showAddWeightDialog(context, ref),
            ),
          ],
        ),
        weightAsync.when(
          loading: () =>
              const SizedBox(height: 40, child: LinearProgressIndicator()),
          error: (_, __) =>
              const Text('Impossible de charger les données de poids.'),
          data: (entries) {
            if (entries.isEmpty) {
              return Text(
                'Ajoutez votre premier relevé de poids.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              );
            }
            final latest = entries.first;
            return Text(
              '${latest.weightKg.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AkeliColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddWeightDialog(
      BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un poids'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Poids (kg)',
            suffixText: 'kg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final kg = double.tryParse(ctrl.text);
              if (kg != null) {
                await ref
                    .read(weightLogNotifierProvider.notifier)
                    .addEntry(kg);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }
}

class _WeeklyCaloriesChart extends StatelessWidget {
  final List<DailyNutrition> days;

  const _WeeklyCaloriesChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final bars = days.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.calories,
            color: AkeliColors.primary,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: bars,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                  final idx = value.toInt();
                  if (idx < 0 || idx >= days.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(days[idx],
                      style: const TextStyle(
                          fontSize: 12,
                          color: AkeliColors.textSecondary));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AverageStats extends StatelessWidget {
  final List<DailyNutrition> days;

  const _AverageStats({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final n = days.length;
    final avgCal = days.fold(0.0, (s, d) => s + d.calories) / n;
    final avgProt = days.fold(0.0, (s, d) => s + d.proteinG) / n;
    final avgCarb = days.fold(0.0, (s, d) => s + d.carbsG) / n;
    final avgFat = days.fold(0.0, (s, d) => s + d.fatG) / n;

    return MacroRow(
      calories: avgCal,
      proteinG: avgProt,
      carbsG: avgCarb,
      fatG: avgFat,
    );
  }
}
