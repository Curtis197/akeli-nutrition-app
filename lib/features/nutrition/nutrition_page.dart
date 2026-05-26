import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/nutrition_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/macro_card.dart';
import '../../providers/user_profile_provider.dart';

class NutritionPage extends ConsumerStatefulWidget {
  const NutritionPage({super.key});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _logger = appLogger;

  @override
  void initState() {
    super.initState();
    _logger.provider('NutritionPage initState()');
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _logger.provider('NutritionPage disposed');
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('NutritionPage build()');
    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Nutrition',
          style: TextStyle(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AkeliColors.primary),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AkeliColors.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: AkeliColors.primaryContainer.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AkeliColors.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: "Aujourd'hui"),
                  Tab(text: "Semaine"),
                ],
              ),
            ),
          ),
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
    appLogger.provider('TodayTab build() | todayAsync.isLoading: ${todayAsync.isLoading}');

    return todayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorState(message: err.toString()),
      data: (nutrition) {
        if (nutrition == null) {
          return const EmptyState(
            icon: Icons.restaurant_outlined,
            title: 'Aucune donnée aujourd\'hui',
            subtitle: 'Consommez des repas pour voir vos données nutritionnelles.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bilan du jour",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AkeliColors.onSurface, letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),
              MacroRow(
                calories: nutrition.calories,
                proteinG: nutrition.proteinG,
                carbsG: nutrition.carbsG,
                fatG: nutrition.fatG,
              ),
              const SizedBox(height: 24),
              // Macro donut chart inside a beautiful card
              _OrganicCard(
                child: Column(
                  children: [
                    _MacroDonutChart(
                      proteinG: nutrition.proteinG,
                      carbsG: nutrition.carbsG,
                      fatG: nutrition.fatG,
                    ),
                    const SizedBox(height: 24),
                    _MacroTargetBars(
                      proteinG: nutrition.proteinG,
                      carbsG: nutrition.carbsG,
                      fatG: nutrition.fatG,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Water tracker inside a card
              _OrganicCard(
                child: _WaterTracker(waterMl: nutrition.waterMl),
              ),
              const SizedBox(height: 24),
              // Weight log
              _OrganicCard(
                child: _WeightTrendChart(),
              ),
              const SizedBox(height: 80),
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
    appLogger.provider('WeeklyTab build() | weekAsync.isLoading: ${weekAsync.isLoading}');

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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calories cette semaine',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AkeliColors.onSurface, letterSpacing: -0.5),
              ),
              const SizedBox(height: 24),
              _OrganicCard(
                child: _WeeklyCaloriesChart(days: days),
              ),
              const SizedBox(height: 32),
              const Text(
                'Moyenne quotidienne',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AkeliColors.onSurface),
              ),
              const SizedBox(height: 16),
              _AverageStats(days: days),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _OrganicCard extends StatelessWidget {
  final Widget child;

  const _OrganicCard({required this.child});

  @override
  Widget build(BuildContext context) {
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
      child: child,
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
    appLogger.d('MacroDonutChart build()');
    final total = proteinG + carbsG + fatG;
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: proteinG,
                        color: AkeliColors.primary,
                        showTitle: false,
                        radius: 20,
                      ),
                      PieChartSectionData(
                        value: carbsG,
                        color: AkeliColors.tertiary,
                        showTitle: false,
                        radius: 20,
                      ),
                      PieChartSectionData(
                        value: fatG,
                        color: AkeliColors.warning,
                        showTitle: false,
                        radius: 20,
                      ),
                    ],
                    centerSpaceRadius: 50,
                    sectionsSpace: 4,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total.toInt()}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AkeliColors.primary),
                    ),
                    const Text(
                      'grammes',
                      style: TextStyle(fontSize: 11, color: AkeliColors.onSurfaceVariant, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Legend(color: AkeliColors.primary, label: 'Protéines', value: '${proteinG.toInt()}g'),
                const SizedBox(height: 12),
                _Legend(color: AkeliColors.tertiary, label: 'Glucides', value: '${carbsG.toInt()}g'),
                const SizedBox(height: 12),
                _Legend(color: AkeliColors.warning, label: 'Lipides', value: '${fatG.toInt()}g'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String? value;

  const _Legend({required this.color, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    appLogger.d('Legend build() | label: $label');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant),
            ),
          ],
        ),
        if (value != null)
          Text(
            value!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AkeliColors.onSurface),
          ),
      ],
    );
  }
}

class _MacroTargetBars extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const _MacroTargetBars({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  // Fallback targets until healthProfileProvider exposes per-macro fields
  static const _targetProt = 150.0;
  static const _targetCarbs = 250.0;
  static const _targetFat = 65.0;

  @override
  Widget build(BuildContext context) {
    appLogger.d('MacroTargetBars build() | protein: $proteinG | carbs: $carbsG | fat: $fatG');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMacroBar('Protéines', proteinG, _targetProt, AkeliColors.primary),
        const SizedBox(height: 12),
        _buildMacroBar('Glucides', carbsG, _targetCarbs, AkeliColors.tertiary),
        const SizedBox(height: 12),
        _buildMacroBar('Lipides', fatG, _targetFat, AkeliColors.warning),
      ],
    );
  }

  Widget _buildMacroBar(String label, double consumed, double target, Color color) {
    final progress = (consumed / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${consumed.toInt()}g / ${target.toInt()}g', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AkeliColors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AkeliColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
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
    appLogger.d('WaterTracker build() | waterMl: ${widget.waterMl}');
    final current = widget.waterMl;
    final glasses = (current / _glassSize).floor();
    final targetGlasses = (_targetMl / _glassSize).floor();
    final progress = (current / _targetMl).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4D96FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: Color(0xFF4D96FF), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hydratation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AkeliColors.onSurface),
                ),
              ],
            ),
            Text(
              '${current.toInt()} / ${_targetMl.toInt()} ml',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AkeliColors.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4D96FF)),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            targetGlasses,
            (i) => Icon(
              i < glasses ? Icons.local_drink_rounded : Icons.local_drink_outlined,
              color: i < glasses ? const Color(0xFF4D96FF) : AkeliColors.outlineVariant,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeightTrendChart extends ConsumerWidget {
  final _logger = appLogger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightAsync = ref.watch(weightLogProvider);
    final healthAsync = ref.watch(healthProfileProvider);

    _logger.provider('WeightTrendChart build() | weightAsync.isLoading: ${weightAsync.isLoading} | healthAsync.isLoading: ${healthAsync.isLoading}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AkeliColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.monitor_weight_rounded, color: AkeliColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mon Poids',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AkeliColors.onSurface),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AkeliColors.primary, size: 28),
              onPressed: () {
                _logger.userAction('Add weight button tapped', screen: 'NutritionPage');
                _showAddWeightDialog(context, ref);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        weightAsync.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const Text('Erreur de chargement', style: TextStyle(color: AkeliColors.error)),
          data: (entries) {
            if (entries.isEmpty) {
              return const Text(
                'Ajoutez votre premier relevé de poids pour commencer le suivi.',
                style: TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 14),
              );
            }
            final currentWeight = entries.first.weightKg;
            final startingWeight = entries.last.weightKg;
            final targetWeight = healthAsync.valueOrNull?.targetWeightKg;
            
            double progress = 0.0;
            if (targetWeight != null && startingWeight != targetWeight) {
              progress = (startingWeight - currentWeight) / (startingWeight - targetWeight);
            }
            final progressPct = (progress * 100).clamp(0, 100).toInt();

            Widget chartWidget = const SizedBox.shrink();
            
            if (entries.length < 2) {
              chartWidget = const Text(
                'Enregistrez un autre poids pour voir votre tendance.',
                style: TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
              );
            } else {
              final chronological = entries.take(10).toList().reversed.toList();
              final spots = chronological.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.weightKg);
              }).toList();
              
              final minWeight = chronological.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
              final maxWeight = chronological.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
              
              final chartMinY = (targetWeight != null && targetWeight < minWeight ? targetWeight : minWeight) - 1.0;
              final chartMaxY = (targetWeight != null && targetWeight > maxWeight ? targetWeight : maxWeight) + 1.0;

              chartWidget = SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    minY: chartMinY,
                    maxY: chartMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: AkeliColors.outline.withValues(alpha: 0.1), strokeWidth: 1);
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AkeliColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => AkeliColors.surfaceContainerHighest,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y} kg',
                              const TextStyle(color: AkeliColors.primary, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: targetWeight != null && targetWeight > 0 ? [
                        HorizontalLine(
                          y: targetWeight,
                          color: AkeliColors.tertiary,
                          strokeWidth: 2,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 5, bottom: 5),
                            style: const TextStyle(color: AkeliColors.tertiary, fontWeight: FontWeight.bold, fontSize: 10),
                            labelResolver: (line) => 'Cible: ${line.y}kg',
                          ),
                        )
                      ] : [],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AkeliColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AkeliColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentWeight.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AkeliColors.primary,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AkeliColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (targetWeight != null && targetWeight > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AkeliColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$progressPct% de l\'objectif',
                          style: const TextStyle(
                            color: AkeliColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                chartWidget,
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddWeightDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AkeliColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Nouveau relevé', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Poids',
            suffixText: 'kg',
            filled: true,
            fillColor: AkeliColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              appLogger.userAction('Weight dialog cancelled', screen: 'NutritionPage');
              Navigator.pop(ctx);
            },
            child: const Text('Annuler', style: TextStyle(color: AkeliColors.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AkeliColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final kg = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (kg != null) {
                appLogger.userAction('Weight dialog saved', screen: 'NutritionPage', metadata: {'weightKg': kg});
                Navigator.pop(ctx);
                ref.read(weightLogNotifierProvider.notifier).addEntry(kg);
              }
            },
            child: const Text('Enregistrer'),
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
    appLogger.d('WeeklyCaloriesChart build()');
    final bars = days.asMap().entries.map((entry) {
      final protCal = entry.value.proteinG * 4;
      final carbCal = entry.value.carbsG * 4;
      final fatCal = entry.value.fatG * 9;
      
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: protCal + carbCal + fatCal,
            color: Colors.transparent,
            width: 16,
            borderRadius: BorderRadius.circular(4),
            rodStackItems: [
              BarChartRodStackItem(0, protCal, AkeliColors.primary),
              BarChartRodStackItem(protCal, protCal + carbCal, AkeliColors.tertiary),
              BarChartRodStackItem(protCal + carbCal, protCal + carbCal + fatCal, AkeliColors.warning),
            ],
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: bars,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const daysStr = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                      final idx = value.toInt();
                      if (idx < 0 || idx >= daysStr.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          daysStr[idx],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Legend(color: AkeliColors.primary, label: 'Protéines'),
            _Legend(color: AkeliColors.tertiary, label: 'Glucides'),
            _Legend(color: AkeliColors.warning, label: 'Lipides'),
          ],
        ),
      ],
    );
  }
}

class _AverageStats extends StatelessWidget {
  final List<DailyNutrition> days;

  const _AverageStats({required this.days});

  @override
  Widget build(BuildContext context) {
    appLogger.d('AverageStats build()');
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
