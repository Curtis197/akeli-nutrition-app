import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/locale_provider.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/unit_converter.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/nutrition_plan_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/macro_card.dart';
import '../../providers/user_profile_provider.dart';
import 'widgets/journey/journey_tab.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.nutritionTitle,
          style: const TextStyle(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AkeliColors.primary),
            onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(AkeliRoutes.home);
                }
              },
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
                tabs: [
                  Tab(text: l10n.nutritionTabToday),
                  Tab(text: l10n.nutritionTabWeek),
                  Tab(text: l10n.nutritionTabJourney),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TodayTab(),
          _WeeklyTab(),
          JourneyTab(),
        ],
      ),
    );
  }
}

class _TodayTab extends ConsumerStatefulWidget {
  const _TodayTab();

  @override
  ConsumerState<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends ConsumerState<_TodayTab> {
  late DateTime _selected;

  static DateTime _truncateToDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime get _today => _truncateToDay(DateTime.now());

  @override
  void initState() {
    super.initState();
    _selected = _today;
  }

  String get _dateStr =>
      '${_selected.year}-${_selected.month.toString().padLeft(2, '0')}-${_selected.day.toString().padLeft(2, '0')}';

  bool get _isToday => _selected == _today;

  String _formatLabel(BuildContext context, DateTime d) {
    final today = _today;
    final l10n = AppLocalizations.of(context);
    if (d == today) return l10n.nutritionToday;
    if (d == today.subtract(const Duration(days: 1))) return l10n.nutritionYesterday;
    final locale = Localizations.localeOf(context).languageCode;
    final formatted = DateFormat('E d MMM', locale).format(d);
    if (formatted.isNotEmpty) {
      return formatted[0].toUpperCase() + formatted.substring(1);
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final nutritionAsync = ref.watch(dailyNutritionForDateProvider(_dateStr));
    final plan = ref.watch(activeNutritionPlanProvider).valueOrNull;
    appLogger.provider('TodayTab build() | date: $_dateStr | nutritionAsync.isLoading: ${nutritionAsync.isLoading} | plan: ${plan != null}');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _NavBar(
            label: _formatLabel(context, _selected),
            onPrev: () {
              appLogger.userAction('NutritionPage today nav prev', screen: 'NutritionPage', metadata: {'from': _dateStr});
              setState(() => _selected = _selected.subtract(const Duration(days: 1)));
            },
            onNext: _isToday
                ? null
                : () {
                    appLogger.userAction('NutritionPage today nav next', screen: 'NutritionPage', metadata: {'from': _dateStr});
                    setState(() => _selected = _selected.add(const Duration(days: 1)));
                  },
          ),
        ),
        Expanded(
          child: nutritionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorState(message: err.toString()),
            data: (nutrition) {
              if (nutrition == null) {
                final l10n = AppLocalizations.of(context);
                return EmptyState(
                  icon: PhosphorIconsRegular.forkKnife,
                  title: l10n.nutritionEmptyStateTodayTitle,
                  subtitle: l10n.nutritionEmptyStateTodaySubtitle,
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CalorieRingCard(
                      calories: nutrition.calories,
                      calorieGoal: plan?.calorieGoal ?? 2000,
                    ),
                    const SizedBox(height: 10),
                    _CompactMacroStrip(
                      proteinG: nutrition.proteinG,
                      carbsG: nutrition.carbsG,
                      fatG: nutrition.fatG,
                      targetProtG: plan?.proteinGoalG ?? 150.0,
                      targetCarbsG: plan?.carbGoalG ?? 250.0,
                      targetFatG: plan?.fatGoalG ?? 65.0,
                    ),
                    const SizedBox(height: 10),
                    _OrganicCard(
                      child: _WaterTracker(
                        waterMl: nutrition.waterMl,
                        onAddGlass: _isToday
                            ? () {
                                appLogger.userAction('Add water glass tapped', screen: 'NutritionPage');
                                ref.read(waterLogNotifierProvider.notifier).addGlass();
                              }
                            : null,
                        onRemoveGlass: _isToday
                            ? () {
                                appLogger.userAction('Remove water glass tapped', screen: 'NutritionPage');
                                ref.read(waterLogNotifierProvider.notifier).removeGlass();
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ConsumedRecipesList(dateStr: _dateStr),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeeklyTab extends ConsumerStatefulWidget {
  const _WeeklyTab();

  @override
  ConsumerState<_WeeklyTab> createState() => _WeeklyTabState();
}

class _WeeklyTabState extends ConsumerState<_WeeklyTab> {
  int _weekOffset = 0;

  static DateTime _truncateToDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime get _today => _truncateToDay(DateTime.now());
  static String _toDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime get _until => _today.subtract(Duration(days: _weekOffset * 7));
  DateTime get _since => _until.subtract(const Duration(days: 6));
  WeekRange get _range => (since: _toDateStr(_since), until: _toDateStr(_until));

  String _formatWeekLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = _since;
    final u = _until;

    final sMonth = DateFormat.MMM(locale).format(s);
    final uMonth = DateFormat.MMM(locale).format(u);

    final sMonthCap = sMonth.isNotEmpty ? sMonth[0].toUpperCase() + sMonth.substring(1) : sMonth;
    final uMonthCap = uMonth.isNotEmpty ? uMonth[0].toUpperCase() + uMonth.substring(1) : uMonth;

    if (s.month == u.month) return '${s.day} – ${u.day} $uMonthCap';
    return '${s.day} $sMonthCap – ${u.day} $uMonthCap';
  }

  @override
  Widget build(BuildContext context) {
    final weekAsync = ref.watch(weeklyNutritionForRangeProvider(_range));
    final plan = ref.watch(activeNutritionPlanProvider).valueOrNull;
    final isUs = ref.watch(localeProvider).isUsLocale;
    final allWeights = ref.watch(weightLogProvider).valueOrNull ?? [];
    final weekWeights = allWeights.where((e) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      return !day.isBefore(_since) && !day.isAfter(_until);
    }).toList();
    final double? weekWeightDelta = weekWeights.length >= 2
        ? weekWeights.first.weightKg - weekWeights.last.weightKg
        : null;
    appLogger.provider('WeeklyTab build() | weekAsync.isLoading: ${weekAsync.isLoading} | offset: $_weekOffset | weekWeightDelta: $weekWeightDelta');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _NavBar(
            label: _formatWeekLabel(context),
            onPrev: () {
              appLogger.userAction('NutritionPage week nav prev', screen: 'NutritionPage', metadata: {'offset': _weekOffset + 1});
              setState(() => _weekOffset++);
            },
            onNext: _weekOffset == 0
                ? null
                : () {
                    appLogger.userAction('NutritionPage week nav next', screen: 'NutritionPage', metadata: {'offset': _weekOffset - 1});
                    setState(() => _weekOffset--);
                  },
          ),
        ),
        Expanded(
          child: weekAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorState(message: err.toString()),
            data: (days) {
              if (days.isEmpty) {
                final l10n = AppLocalizations.of(context);
                return EmptyState(
                  icon: PhosphorIconsRegular.chartBar,
                  title: l10n.nutritionEmptyStateWeekTitle,
                  subtitle: l10n.nutritionEmptyStateWeekSubtitle,
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeeklySummaryCard(
                      days: days,
                      since: _since,
                      until: _until,
                      calorieGoal: plan?.calorieGoal ?? 2000,
                      weekWeightDelta: weekWeightDelta,
                      isUs: isUs,
                    ),
                    const SizedBox(height: 10),
                    _OrganicCard(child: _WeeklyCaloriesChart(days: days)),
                    const SizedBox(height: 10),
                    _AverageStats(days: days),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _NavBar({required this.label, required this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, size: 28),
          onPressed: onPrev,
          color: AkeliColors.primary,
          style: IconButton.styleFrom(
            backgroundColor: AkeliColors.primaryContainer.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AkeliColors.onSurface),
        ),
        IconButton(
          icon: Icon(
            PhosphorIconsRegular.caretRight,
            size: 28,
            color: onNext != null ? AkeliColors.primary : AkeliColors.outlineVariant,
          ),
          onPressed: onNext,
          style: IconButton.styleFrom(
            backgroundColor: onNext != null
                ? AkeliColors.primaryContainer.withValues(alpha: 0.15)
                : AkeliColors.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
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

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    appLogger.d('Legend build() | label: $label');
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant)),
      ],
    );
  }
}



class _WaterTracker extends StatelessWidget {
  final double waterMl;
  final VoidCallback? onAddGlass;
  final VoidCallback? onRemoveGlass;

  const _WaterTracker({required this.waterMl, this.onAddGlass, this.onRemoveGlass});

  static const _targetMl = 2000.0;
  static const _glassSize = 250.0;

  @override
  Widget build(BuildContext context) {
    appLogger.d('WaterTracker build() | waterMl: $waterMl');
    final l10n = AppLocalizations.of(context);
    final glasses = (waterMl / _glassSize).floor();
    final targetGlasses = (_targetMl / _glassSize).floor();
    final progress = (waterMl / _targetMl).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4D96FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsFill.drop, color: Color(0xFF4D96FF), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.nutritionHydration,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AkeliColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${waterMl.toInt()} / ${_targetMl.toInt()} ml',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                if (onRemoveGlass != null && waterMl > 0) ...[
                  GestureDetector(
                    onTap: onRemoveGlass,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D96FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.minus,
                        color: Color(0xFF4D96FF),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: onAddGlass,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: onAddGlass != null
                          ? const Color(0xFF4D96FF).withValues(alpha: 0.12)
                          : AkeliColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.plus,
                      color: onAddGlass != null ? const Color(0xFF4D96FF) : AkeliColors.outlineVariant,
                      size: 18,
                    ),
                  ),
                ),
              ],
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
              i < glasses ? PhosphorIconsFill.drop : PhosphorIconsRegular.drop,
              color: i < glasses ? const Color(0xFF4D96FF) : AkeliColors.outlineVariant,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _WeightTrendChart extends ConsumerWidget {
  final _logger = appLogger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final weightAsync = ref.watch(weightLogProvider);
    final healthAsync = ref.watch(healthProfileProvider);
    final isUs = ref.watch(localeProvider).isUsLocale;
    final weightUnit = isUs ? 'lb' : 'kg';

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
                  child: const Icon(PhosphorIconsFill.scales, color: AkeliColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.nutritionMyWeight,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AkeliColors.onSurface),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(PhosphorIconsFill.plusCircle, color: AkeliColors.primary, size: 28),
              onPressed: () {
                _logger.userAction('Add weight button tapped', screen: 'NutritionPage');
                _showAddWeightDialog(context, ref, isUs: isUs);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        weightAsync.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => Text(l10n.commonLoadError, style: const TextStyle(color: AkeliColors.error)),
          data: (entries) {
            if (entries.isEmpty) {
              return Text(
                l10n.nutritionAddFirstWeight,
                style: const TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 14),
              );
            }
            final currentWeightKg = entries.first.weightKg;
            final currentWeight = isUs ? UnitConverter.kgToLb(currentWeightKg) : currentWeightKg;
            // Use onboarding weight as origin — same logic as home page.
            // entries.last is unreliable (same-day taps skew it vs. real start).
            final startingWeightKg = healthAsync.valueOrNull?.weightKg ?? entries.last.weightKg;
            final targetWeightKg = healthAsync.valueOrNull?.targetWeightKg;
            final targetWeight = targetWeightKg != null
                ? (isUs ? UnitConverter.kgToLb(targetWeightKg) : targetWeightKg)
                : null;
            
            double progress = 0.0;
            if (targetWeightKg != null && startingWeightKg != targetWeightKg) {
              progress = (startingWeightKg - currentWeightKg) / (startingWeightKg - targetWeightKg);
            }
            final progressPct = (progress * 100).clamp(0, 100).toInt();

            Widget chartWidget = const SizedBox.shrink();
            
            if (entries.length < 2) {
              chartWidget = Text(
                l10n.nutritionLogAnotherWeight,
                style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
              );
            } else {
              final chronological = entries.take(10).toList().reversed.toList();
              final spots = chronological.asMap().entries.map((e) {
                final y = isUs ? UnitConverter.kgToLb(e.value.weightKg) : e.value.weightKg;
                return FlSpot(e.key.toDouble(), y);
              }).toList();

              final spotYs = spots.map((s) => s.y);
              final minWeight = spotYs.reduce((a, b) => a < b ? a : b);
              final maxWeight = spotYs.reduce((a, b) => a > b ? a : b);

              final chartMinY = (targetWeight != null && targetWeight < minWeight ? targetWeight : minWeight) - (isUs ? 2.0 : 1.0);
              final chartMaxY = (targetWeight != null && targetWeight > maxWeight ? targetWeight : maxWeight) + (isUs ? 2.0 : 1.0);

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
                              '${spot.y} $weightUnit',
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
                            labelResolver: (line) => '${l10n.nutritionChartTarget}: ${line.y}$weightUnit',
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
                        Text(
                          weightUnit,
                          style: const TextStyle(
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
                          l10n.nutritionProgressPercentage(progressPct),
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
              appLogger.userAction('Weight dialog cancelled', screen: 'NutritionPage');
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
                appLogger.userAction('Weight dialog saved', screen: 'NutritionPage', metadata: {'weightKg': kg, 'isUs': isUs});
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
                      final idx = value.toInt();
                      if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                      final locale = Localizations.localeOf(context).languageCode;
                      final dayLetter = DateFormat.E(locale).format(days[idx].date).substring(0, 1).toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dayLetter,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Legend(color: AkeliColors.primary, label: AppLocalizations.of(context).nutritionProtein),
            _Legend(color: AkeliColors.tertiary, label: AppLocalizations.of(context).nutritionCarbs),
            _Legend(color: AkeliColors.warning, label: AppLocalizations.of(context).nutritionFat),
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

// ---------------------------------------------------------------------------
// Consumed recipes for the selected day
// ---------------------------------------------------------------------------

class _ConsumedRecipesList extends ConsumerWidget {
  final String dateStr;

  const _ConsumedRecipesList({required this.dateStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recipesAsync = ref.watch(consumedRecipesForDateProvider(dateStr));
    appLogger.provider('_ConsumedRecipesList build() | date: $dateStr | recipesAsync.isLoading: ${recipesAsync.isLoading}');

    return recipesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recipes) {
        if (recipes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AkeliColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsFill.cookingPot, color: AkeliColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.nutritionConsumedMeals,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AkeliColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recipes.map((r) => _ConsumedRecipeRow(recipe: r)),
          ],
        );
      },
    );
  }
}

class _ConsumedRecipeRow extends StatelessWidget {
  final ConsumedRecipeSummary recipe;

  const _ConsumedRecipeRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        '${recipe.consumedAt.hour.toString().padLeft(2, '0')}:${recipe.consumedAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        appLogger.userAction('Consumed recipe tapped', screen: 'NutritionPage', metadata: {'recipeId': recipe.recipeId});
        context.push(AkeliRoutes.recipeDetailPath(recipe.recipeId));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: recipe.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: recipe.thumbnailUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AkeliColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(PhosphorIconsRegular.caretRight, size: 18, color: AkeliColors.outlineVariant),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: AkeliColors.surfaceContainerHigh,
        child: const Icon(PhosphorIconsRegular.forkKnife, color: AkeliColors.outline, size: 22),
      );
}

// ── Today tab: Calorie ring ────────────────────────────────────────────────────

class _CalorieRingCard extends StatelessWidget {
  final double calories;
  final int calorieGoal;

  const _CalorieRingCard({required this.calories, required this.calorieGoal});

  @override
  Widget build(BuildContext context) {
    appLogger.d('_CalorieRingCard build() | calories: $calories | goal: $calorieGoal');
    final l10n = AppLocalizations.of(context);
    final ratio = calorieGoal > 0 ? calories / calorieGoal : 0.0;
    final remaining = calorieGoal - calories;
    final isOver = remaining < 0;
    final ringColor = isOver
        ? AkeliColors.error
        : ratio >= 0.85
            ? const Color(0xFF4ADE80)
            : AkeliColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(110, 110),
                  painter: _CalorieRingPainter(
                    progress: ratio.clamp(0.0, 1.0),
                    ringColor: ringColor,
                    trackColor: AkeliColors.surfaceContainerHigh,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      calories.toInt().toString(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AkeliColors.onSurface, height: 1),
                    ),
                    const Text('kcal', style: TextStyle(fontSize: 10, color: AkeliColors.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      '${(ratio * 100).clamp(0, 999).toInt()}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ringColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalStat(label: l10n.nutritionGoal, value: '$calorieGoal kcal'),
                const SizedBox(height: 12),
                _CalStat(
                  label: l10n.nutritionRemaining,
                  value: '${remaining.abs().toInt()} kcal',
                  valueColor: isOver ? AkeliColors.error : const Color(0xFF4ADE80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CalStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AkeliColors.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: valueColor ?? AkeliColors.onSurface)),
      ],
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;

  const _CalorieRingPainter({required this.progress, required this.ringColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CalorieRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}

// ── Today tab: Compact macro strip ────────────────────────────────────────────

class _CompactMacroStrip extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double targetProtG;
  final double targetCarbsG;
  final double targetFatG;

  const _CompactMacroStrip({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.targetProtG,
    required this.targetCarbsG,
    required this.targetFatG,
  });

  @override
  Widget build(BuildContext context) {
    appLogger.d('_CompactMacroStrip build()');
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: _MacroMiniCard(label: l10n.nutritionProtein, value: proteinG, target: targetProtG, color: AkeliColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _MacroMiniCard(label: l10n.nutritionCarbs, value: carbsG, target: targetCarbsG, color: AkeliColors.tertiary)),
        const SizedBox(width: 8),
        Expanded(child: _MacroMiniCard(label: l10n.nutritionFat, value: fatG, target: targetFatG, color: const Color(0xFF38BDF8))),
      ],
    );
  }
}

class _MacroMiniCard extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;

  const _MacroMiniCard({required this.label, required this.value, required this.target, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AkeliColors.onSurfaceVariant, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text('${value.toInt()}g', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AkeliColors.onSurface, height: 1)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AkeliColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text('/ ${target.toInt()}g', style: const TextStyle(fontSize: 10, color: AkeliColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Weekly tab: Summary card ───────────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  final List<DailyNutrition> days;
  final DateTime since;
  final DateTime until;
  final int calorieGoal;
  final double? weekWeightDelta;
  final bool isUs;

  const _WeeklySummaryCard({
    required this.days,
    required this.since,
    required this.until,
    required this.calorieGoal,
    this.weekWeightDelta,
    this.isUs = false,
  });

  static DateTime _truncate(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    appLogger.d('_WeeklySummaryCard build() | days: ${days.length} | goal: $calorieGoal | delta: $weekWeightDelta');
    final l10n = AppLocalizations.of(context);

    final dayMap = {for (final d in days) _truncate(d.date): d};

    final loggedDays = days.where((d) => d.calories > 0).toList();
    final avgKcal = loggedDays.isEmpty
        ? 0
        : (loggedDays.fold(0.0, (s, d) => s + d.calories) / loggedDays.length).round();
    final onTarget = loggedDays.where((d) {
      if (calorieGoal <= 0) return false;
      final r = d.calories / calorieGoal;
      return r >= 0.9 && r <= 1.1;
    }).length;

    final deltaKg = weekWeightDelta;
    final String wdValue;
    final Color wdColor;
    if (deltaKg == null) {
      wdValue = '–';
      wdColor = AkeliColors.onSurfaceVariant;
    } else {
      final displayDelta = isUs ? UnitConverter.kgToLb(deltaKg.abs()) : deltaKg.abs();
      final unit = isUs ? 'lb' : 'kg';
      if (deltaKg < 0) {
        wdValue = '↓${displayDelta.toStringAsFixed(1)} $unit';
        wdColor = const Color(0xFF4ADE80);
      } else if (deltaKg > 0) {
        wdValue = '↑${displayDelta.toStringAsFixed(1)} $unit';
        wdColor = AkeliColors.error;
      } else {
        wdValue = '–';
        wdColor = AkeliColors.onSurfaceVariant;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.nutritionSummary,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AkeliColors.onSurfaceVariant, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                _SummaryMetric(value: '$avgKcal', label: l10n.nutritionAvgKcal, valueColor: AkeliColors.onSurface),
                const _VertDivider(),
                _SummaryMetric(value: wdValue, label: l10n.nutritionWeightVariation, valueColor: wdColor),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.nutritionTargetAchieved(onTarget),
            style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.nutritionEveryDay,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AkeliColors.outlineVariant, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = DateTime(since.year, since.month, since.day + i);
              return _DayPip(date: date, nutrition: dayMap[_truncate(date)], calorieGoal: calorieGoal);
            }),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _SummaryMetric({required this.value, required this.label, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: valueColor, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 9, color: AkeliColors.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AkeliColors.outlineVariant.withValues(alpha: 0.3));
  }
}

class _DayPip extends StatelessWidget {
  final DateTime date;
  final DailyNutrition? nutrition;
  final int calorieGoal;

  const _DayPip({required this.date, required this.nutrition, required this.calorieGoal});

  @override
  Widget build(BuildContext context) {
    final cal = nutrition?.calories ?? 0;
    final isLogged = cal > 0;
    final locale = Localizations.localeOf(context).languageCode;
    final dayLetter = DateFormat.E(locale).format(date).substring(0, 1).toUpperCase();

    Color bg;
    Color textColor;
    if (!isLogged) {
      bg = AkeliColors.surfaceContainerHigh;
      textColor = AkeliColors.outlineVariant;
    } else if (calorieGoal > 0 && cal / calorieGoal >= 0.9 && cal / calorieGoal <= 1.1) {
      bg = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
    } else {
      bg = const Color(0xFFFEF9C3);
      textColor = const Color(0xFF854D0E);
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(
            dayLetter,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          isLogged ? '${cal.toInt()}' : '–',
          style: const TextStyle(fontSize: 8, color: AkeliColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
