import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/nutrition_provider.dart';
import 'package:akeli/providers/user_profile_provider.dart';

final _logger = appLogger;

class JourneyWeightChart extends ConsumerWidget {
  const JourneyWeightChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _logger.provider('JourneyWeightChart build()');

    final weightAsync = ref.watch(weightLogProvider);
    final healthAsync = ref.watch(healthProfileProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ÉVOLUTION DU POIDS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AkeliColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _logger.userAction('Add weight tapped', screen: 'JourneyTab');
                  _showAddWeightDialog(context, ref);
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AkeliColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded, color: AkeliColors.primary, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          weightAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) {
              _logger.provider('JourneyWeightChart → error | $e', error: e, stackTrace: st);
              return const Text(
                'Erreur de chargement',
                style: TextStyle(color: AkeliColors.error),
              );
            },
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Ajoutez votre premier relevé de poids pour commencer le suivi.',
                    style: TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
                  ),
                );
              }

              final targetWeight = healthAsync.valueOrNull?.targetWeightKg;
              final startingWeight =
                  healthAsync.valueOrNull?.weightKg ?? entries.last.weightKg;
              final currentWeight = entries.first.weightKg;

              double progressPct = 0;
              if (targetWeight != null && startingWeight != targetWeight) {
                final progress =
                    (startingWeight - currentWeight) / (startingWeight - targetWeight);
                progressPct = (progress * 100).clamp(0, 100);
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
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AkeliColors.primary,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'kg',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AkeliColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (targetWeight != null && targetWeight > 0 && progressPct > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AkeliColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${progressPct.toInt()}% de l\'objectif',
                            style: const TextStyle(
                              color: AkeliColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (entries.length < 2)
                    const Text(
                      'Enregistrez un autre poids pour voir votre tendance.',
                      style: TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
                    )
                  else
                    _buildChart(entries, targetWeight),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<WeightEntry> entries, double? targetWeight) {
    final chronological = entries.take(20).toList().reversed.toList();
    final spots = chronological
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg))
        .toList();

    final weights = chronological.map((e) => e.weightKg);
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    final chartMinY =
        (targetWeight != null && targetWeight < minWeight ? targetWeight : minWeight) - 1.0;
    final chartMaxY =
        (targetWeight != null && targetWeight > maxWeight ? targetWeight : maxWeight) + 1.0;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AkeliColors.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
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
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AkeliColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AkeliColors.surfaceContainerHighest,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} kg',
                        const TextStyle(
                          color: AkeliColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ))
                  .toList(),
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: targetWeight != null && targetWeight > 0
                ? [
                    HorizontalLine(
                      y: targetWeight,
                      color: AkeliColors.tertiary,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 5, bottom: 5),
                        style: const TextStyle(
                          color: AkeliColors.tertiary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        labelResolver: (line) =>
                            'Cible: ${line.y.toStringAsFixed(1)}kg',
                      ),
                    ),
                  ]
                : [],
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
              _logger.userAction('Weight dialog cancelled', screen: 'JourneyTab');
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
                _logger.userAction('Weight saved', screen: 'JourneyTab',
                    metadata: {'weightKg': kg});
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
