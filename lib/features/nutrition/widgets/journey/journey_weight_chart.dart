import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/locale_provider.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/unit_converter.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/providers/nutrition_provider.dart';
import 'package:akeli/providers/user_profile_provider.dart';

final _logger = appLogger;

class JourneyWeightChart extends ConsumerWidget {
  const JourneyWeightChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _logger.provider('JourneyWeightChart build()');

    final l10n = AppLocalizations.of(context);
    final weightAsync = ref.watch(weightLogProvider);
    final healthAsync = ref.watch(healthProfileProvider);
    final isUs = ref.watch(localeProvider).isUsLocale;
    final weightUnit = isUs ? 'lb' : 'kg';

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
              Text(
                l10n.nutritionWeightEvolution.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AkeliColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _logger.userAction('Add weight tapped', screen: 'JourneyTab');
                  _showAddWeightDialog(context, ref, isUs: isUs);
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
              return Text(
                l10n.commonLoadError,
                style: const TextStyle(color: AkeliColors.error),
              );
            },
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.nutritionAddFirstWeight,
                    style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
                  ),
                );
              }

              final targetWeightKg = healthAsync.valueOrNull?.targetWeightKg;
              final startingWeight =
                  healthAsync.valueOrNull?.weightKg ?? entries.last.weightKg;
              final currentWeightKg = entries.first.weightKg;
              final currentWeight = isUs ? UnitConverter.kgToLb(currentWeightKg) : currentWeightKg;
              final targetWeight = targetWeightKg != null
                  ? (isUs ? UnitConverter.kgToLb(targetWeightKg) : targetWeightKg)
                  : null;

              double progressPct = 0;
              if (targetWeightKg != null && startingWeight != targetWeightKg) {
                final progress =
                    (startingWeight - currentWeightKg) / (startingWeight - targetWeightKg);
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
                          Text(
                            weightUnit,
                            style: const TextStyle(
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
                            l10n.nutritionProgressPercentage(progressPct.toInt()),
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
                    Text(
                      l10n.nutritionLogAnotherWeight,
                      style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
                    )
                  else
                    _buildChart(context, entries, targetWeight, isUs: isUs),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<WeightEntry> entries, double? targetWeight, {required bool isUs}) {
    final l10n = AppLocalizations.of(context);
    final weightUnit = isUs ? 'lb' : 'kg';
    final chronological = entries.take(20).toList().reversed.toList();
    final spots = chronological
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), isUs ? UnitConverter.kgToLb(e.value.weightKg) : e.value.weightKg))
        .toList();

    final weights = spots.map((s) => s.y);
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    final chartMinY =
        (targetWeight != null && targetWeight < minWeight ? targetWeight : minWeight) - (isUs ? 2.0 : 1.0);
    final chartMaxY =
        (targetWeight != null && targetWeight > maxWeight ? targetWeight : maxWeight) + (isUs ? 2.0 : 1.0);

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
                        '${s.y.toStringAsFixed(1)} $weightUnit',
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
                            '${l10n.nutritionChartTarget}: ${line.y.toStringAsFixed(1)}$weightUnit',
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

  Future<void> _showAddWeightDialog(BuildContext context, WidgetRef ref, {required bool isUs}) async {
    final l10n = AppLocalizations.of(context);
    final weightUnit = isUs ? 'lb' : 'kg';
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AkeliColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.nutritionNewRecord, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.nutritionWeightLabel,
            suffixText: weightUnit,
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
            child: Text(l10n.commonCancel, style: const TextStyle(color: AkeliColors.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AkeliColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final entered = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (entered != null) {
                final kg = isUs ? UnitConverter.lbToKg(entered) : entered;
                _logger.userAction('Weight saved', screen: 'JourneyTab',
                    metadata: {'weightKg': kg, 'isUs': isUs});
                Navigator.pop(ctx);
                ref.read(weightLogNotifierProvider.notifier).addEntry(kg);
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }
}
