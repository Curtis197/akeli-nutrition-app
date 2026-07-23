import 'package:flutter/material.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import '../../core/locale_provider.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/unit_converter.dart';
import '../../core/nutrition_calculator.dart';
import '../../core/nutrition_input_bounds.dart';
import '../../core/supabase_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_plan_provider.dart';
import '../../providers/nutrition_targets_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/models/nutrition_plan.dart';
import '../../providers/mode_provider.dart';
import '../auth/onboarding_data.dart';


// Pure function — exported for testing.
// Onboarding's Goals step collects weightGoal (required) and muscleGoal
// (optional) as the user's explicit objective. weightGoal takes priority;
// muscleGoal only breaks the tie when weightGoal is 'maintenance'.
String primaryGoalFromOnboardingSelections({
  required String? weightGoal,
  required String? muscleGoal,
}) {
  if (weightGoal == 'loss') return 'weight_loss';
  if (weightGoal == 'gain') return 'muscle_gain';
  if (weightGoal == 'maintenance') {
    if (muscleGoal == 'gain') return 'muscle_gain';
    if (muscleGoal == 'loss') return 'weight_loss';
  }
  return 'maintenance';
}

class NutritionPlanPage extends ConsumerStatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onCompleted;

  const NutritionPlanPage({
    super.key,
    this.isOnboarding = false,
    this.onCompleted,
  });

  @override
  ConsumerState<NutritionPlanPage> createState() => NutritionPlanPageState();
}

class NutritionPlanPageState extends ConsumerState<NutritionPlanPage> {
  final _logger = appLogger;

  double _weightKg = 70.0;
  late final TextEditingController _weightCtrl;
  double _heightCm = 170.0;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _heightFeetCtrl;
  late final TextEditingController _heightInchesCtrl;
  int _age = 30;
  late final TextEditingController _ageCtrl;
  String _sex = 'female';
  String _activityLevel = 'moderate';
  String _primaryGoal = 'maintenance';

  double? _bmr;
  double? _tdee;
  int _calorieGoal = 2000;

  double _proteinPct = 25.0;
  double _carbPct = 50.0;
  double _fatPct = 25.0;

  List<MealDistribution> _distributions = [];
  bool _isCalculated = false;
  bool _isSaving = false;
  bool _isScheduleValid = true;
  bool _isLoading = false;
  String? _errorText;
  double? _effectivePaceKgWeek;
  double? _estimatedWeeksToTarget;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: '70');
    _heightCtrl = TextEditingController(text: '170');
    _heightFeetCtrl = TextEditingController();
    _heightInchesCtrl = TextEditingController();
    _ageCtrl = TextEditingController(text: '30');
    _logger.provider('NutritionPlanPage initState | isOnboarding: ${widget.isOnboarding}');
    _loadInitialData();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _heightFeetCtrl.dispose();
    _heightInchesCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _syncHealthParamCtrls() {
    final isUs = ref.read(localeProvider).isUsLocale;
    _weightCtrl.text = isUs
        ? UnitConverter.kgToLb(_weightKg).toStringAsFixed(1)
        : _weightKg.toStringAsFixed(1);
    if (isUs) {
      final (feet, inches) = UnitConverter.cmToFeetIn(_heightCm);
      _heightFeetCtrl.text = feet.toString();
      _heightInchesCtrl.text = inches.toString();
    } else {
      _heightCtrl.text = _heightCm.toStringAsFixed(0);
    }
    _ageCtrl.text = _age.toString();
  }

  Future<void> _loadInitialData() async {
    _logger.provider('NutritionPlanPage _loadInitialData');
    final healthProfile = await ref.read(healthProfileProvider.future);
    final activePlan = await ref.read(activeNutritionPlanProvider.future);

    if (!mounted) return;

    if (widget.isOnboarding) {
      final obData = ref.read(onboardingProvider);
      setState(() {
        _weightKg = obData.weight ?? 70.0;
        _heightCm = obData.height ?? 170.0;
        _age = obData.age ?? 30;
        _sex = obData.sex ?? 'female';
        _activityLevel = obData.activityLevel ?? 'moderate';
        _primaryGoal = primaryGoalFromOnboardingSelections(
          weightGoal: obData.weightGoal,
          muscleGoal: obData.muscleGoal,
        );
      });
      _syncHealthParamCtrls();
    } else if (healthProfile != null) {
      setState(() {
        _weightKg = healthProfile.weightKg ?? 70.0;
        _heightCm = healthProfile.heightCm ?? 170.0;
        _age = healthProfile.age ?? 30;
        _sex = healthProfile.sex ?? 'female';
        _activityLevel = healthProfile.activityLevel ?? 'moderate';
        _primaryGoal = healthProfile.primaryGoal ?? 'maintenance';
      });
      _syncHealthParamCtrls();
    }

    // Onboarding must always compute a fresh plan from what was just
    // entered (Profile/Goals steps) — never silently reuse a leftover
    // active plan from a previous session on this account. Reusing an
    // existing plan is only correct for the Settings entry point.
    if (!widget.isOnboarding && activePlan != null && activePlan.distributions != null && activePlan.distributions!.isNotEmpty) {
      _logger.provider('NutritionPlanPage → loaded existing plan | calorieGoal: ${activePlan.calorieGoal}');
      final totalGramsCal =
          (activePlan.proteinGoalG * 4) + (activePlan.carbGoalG * 4) + (activePlan.fatGoalG * 9);
      setState(() {
        _bmr = activePlan.bmr;
        _tdee = activePlan.tdee;
        _calorieGoal = activePlan.calorieGoal;
        if (totalGramsCal > 0) {
          _proteinPct = ((activePlan.proteinGoalG * 4) / totalGramsCal) * 100;
          _carbPct = ((activePlan.carbGoalG * 4) / totalGramsCal) * 100;
          _fatPct = ((activePlan.fatGoalG * 9) / totalGramsCal) * 100;
        }
        _distributions = activePlan.distributions!;
        _isCalculated = true;
      });
    } else {
      _calculateResults();
    }
  }

  Future<void> _calculateResults() async {
    _logger.userAction('Calculate results', screen: 'NutritionPlanPage');
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    // Bounds guard checks (spec §1.9/§1.10)
    if (_weightKg < NutritionInputBounds.minWeightKg || _weightKg > NutritionInputBounds.maxWeightKg ||
        _heightCm < NutritionInputBounds.minHeightCm || _heightCm > NutritionInputBounds.maxHeightCm ||
        _age < NutritionInputBounds.minAge || _age > NutritionInputBounds.maxAge) {
      setState(() {
        _errorText = l10n.nutritionPlanCalculateError;
        _isCalculated = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final client = ref.read(supabaseClientProvider);

    // Onboarding: target weight + timeline live only in the in-memory
    // onboardingProvider until final submit — nothing is persisted to
    // user_health_profile yet, so reading healthProfileProvider here would
    // silently ignore whatever was just typed in the Goals step (and, on an
    // account with a pre-existing profile, would use its stale saved values
    // instead). Settings: the saved profile IS the source of truth.
    double? targetWeightKg;
    int? remainingWeeks;
    String? muscleGoal;
    if (widget.isOnboarding) {
      final obData = ref.read(onboardingProvider);
      targetWeightKg = obData.targetWeight;
      remainingWeeks = obData.targetWeight != null
          ? remainingWeeksFromMonths(obData.timelineMonths)
          : null;
      muscleGoal = obData.muscleGoal;
    } else {
      final healthProfile = await ref.read(healthProfileProvider.future);
      targetWeightKg = healthProfile?.targetWeightKg;
      remainingWeeks = remainingWeeksFromDate(healthProfile?.targetDate);
      muscleGoal = healthProfile?.muscleGoal;
    }

    try {
      final targets = await fetchNutritionTargets(
        client,
        weightKg: _weightKg,
        heightCm: _heightCm,
        age: _age,
        sex: _sex,
        activityLevel: _activityLevel,
        primaryGoal: _primaryGoal,
        targetWeightKg: targetWeightKg,
        remainingWeeks: remainingWeeks,
        muscleGoal: muscleGoal,
      );

      if (!mounted) return;

      if (targets == null) {
        setState(() {
          _errorText = l10n.nutritionPlanCalculateError;
          _isLoading = false;
          _isCalculated = false;
        });
        return;
      }

      // Macro percentages are derived from the RPC's computed grams (g/kg
      // bodyweight based — spec §1.7), NOT a fixed lookup table, so they
      // actually vary with the calculated plan rather than just the goal
      // label.
      final totalMacroCal =
          (targets.proteinG * 4) + (targets.carbG * 4) + (targets.fatG * 9);

      final defaultSplits = NutritionCalculatorService.getDefaultMealSplits(3);
      final newDistributions = defaultSplits.entries.mapIndexed((i, e) => MealDistribution(
            mealType: e.key,
            sortOrder: i,
            caloriePct: e.value,
            calorieTarget: targets.calorieGoal.toDouble() * (e.value / 100),
          )).toList();

      setState(() {
        _bmr = targets.bmr;
        _tdee = targets.tdee;
        _calorieGoal = targets.calorieGoal;
        if (totalMacroCal > 0) {
          _proteinPct = ((targets.proteinG * 4) / totalMacroCal) * 100;
          _carbPct = ((targets.carbG * 4) / totalMacroCal) * 100;
          _fatPct = ((targets.fatG * 9) / totalMacroCal) * 100;
        }
        _distributions = newDistributions;
        _effectivePaceKgWeek = targets.effectivePaceKgWeek;
        _estimatedWeeksToTarget = targets.estimatedWeeksToTarget;
        _isCalculated = true;
        _isLoading = false;
      });
    } catch (e, st) {
      _logger.provider('NutritionPlanPage calculate error: $e', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _errorText = l10n.nutritionPlanCalculateError;
          _isLoading = false;
          _isCalculated = false;
        });
      }
    }
  }

  Future<bool> savePlan() async {
    _logger.userAction('Save plan button tapped', screen: 'NutritionPlanPage');
    final l10n = AppLocalizations.of(context);

    if (!_isScheduleValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mealScheduleCalorieTotalError)),
      );
      return false;
    }

    final totalMacros = _proteinPct + _carbPct + _fatPct;
    if ((totalMacros - 100).abs() > 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealScheduleMacroError)));
      return false;
    }
    final totalDist = _distributions.fold(0.0, (s, d) => s + d.caloriePct);
    if ((totalDist - 100).abs() > 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealScheduleCalorieTotalError)));
      return false;
    }

    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSaving = false);
      return false;
    }

    final plan = NutritionPlan(
      userId: user.id,
      calorieGoal: _calorieGoal,
      proteinGoalG: (_calorieGoal * _proteinPct / 100) / 4.0,
      carbGoalG: (_calorieGoal * _carbPct / 100) / 4.0,
      fatGoalG: (_calorieGoal * _fatPct / 100) / 9.0,
      bmr: _bmr,
      tdee: _tdee,
      isActive: true,
    );

    try {
      await ref.read(nutritionPlanNotifierProvider.notifier).savePlan(plan, _distributions);
      _logger.provider('NutritionPlanPage → save success');

      if (!mounted) return true;
      if (widget.isOnboarding && widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.nutritionPlanSaveSuccess)));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go(AkeliRoutes.home);
        }
      }
      return true;
    } catch (e, st) {
      _logger.provider('NutritionPlanPage → save error | $e', error: e, stackTrace: st);
      if (!mounted) return false;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.nutritionPlanSaveError(e.toString()))));
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appMode = ref.watch(currentModeProvider);
    final isBeauty = appMode == AppMode.beauty;
    final title = isBeauty ? l10n.nutritionPlanBeautyTitle : l10n.nutritionPlanTitle;
    final isUs = ref.watch(localeProvider).isUsLocale;
    final totalMacros = _proteinPct + _carbPct + _fatPct;
    final isValidMacros = (totalMacros - 100).abs() <= 1.0;

    final proteinG = (_calorieGoal * _proteinPct / 100) / 4.0;
    final carbG = (_calorieGoal * _carbPct / 100) / 4.0;
    final fatG = (_calorieGoal * _fatPct / 100) / 9.0;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: Text(title),
              backgroundColor: AkeliColors.background,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isOnboarding) ...[
              // ── Section 1: Health Parameters ──────────────────────────────
              Text(l10n.nutritionPlanHealthParamsSection,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      decoration: InputDecoration(
                        labelText: '${l10n.healthCurrentWeight} (${isUs ? 'lb' : 'kg'})',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setState(() => _weightKg = isUs ? UnitConverter.lbToKg(parsed) : parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isUs) ...[
                    Expanded(
                      child: TextFormField(
                        controller: _heightFeetCtrl,
                        decoration: InputDecoration(
                          labelText: '${l10n.healthHeight} (ft)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final feet = int.tryParse(v);
                          if (feet != null) {
                            final inches = int.tryParse(_heightInchesCtrl.text) ?? 0;
                            setState(() => _heightCm = UnitConverter.feetInToCm(feet, inches));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _heightInchesCtrl,
                        decoration: const InputDecoration(
                          labelText: '(in)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final inches = int.tryParse(v);
                          if (inches != null) {
                            final feet = int.tryParse(_heightFeetCtrl.text) ?? 0;
                            setState(() => _heightCm = UnitConverter.feetInToCm(feet, inches));
                          }
                        },
                      ),
                    ),
                  ] else
                    Expanded(
                      child: TextFormField(
                        controller: _heightCtrl,
                        decoration: InputDecoration(
                          labelText: '${l10n.healthHeight} (cm)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null) setState(() => _heightCm = parsed);
                        },
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.healthProfileAge,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null) setState(() => _age = parsed);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: InputDecoration(labelText: l10n.healthSex, border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'female', child: Text(l10n.healthSexFemale)),
                        DropdownMenuItem(value: 'male', child: Text(l10n.healthSexMale)),
                      ],
                      onChanged: (v) => setState(() => _sex = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _primaryGoal,
                      decoration: InputDecoration(labelText: l10n.nutritionPlanGoalLabel, border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'weight_loss', child: Text(l10n.healthGoalWeightLoss)),
                        DropdownMenuItem(value: 'maintenance', child: Text(l10n.healthGoalMaintenance)),
                        DropdownMenuItem(value: 'muscle_gain', child: Text(l10n.healthGoalMuscleGain)),
                      ],
                      onChanged: (v) => setState(() => _primaryGoal = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _activityLevel,
                decoration: InputDecoration(labelText: l10n.healthActivityLevel, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'sedentary', child: Text(l10n.healthActivitySedentary)),
                  DropdownMenuItem(value: 'light', child: Text(l10n.healthActivityLight)),
                  DropdownMenuItem(value: 'moderate', child: Text(l10n.healthActivityModerate)),
                  DropdownMenuItem(value: 'active', child: Text(l10n.healthActivityActive)),
                  DropdownMenuItem(value: 'very_active', child: Text(l10n.healthActivityVeryActive)),
                ],
                onChanged: (v) => setState(() => _activityLevel = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _calculateResults,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.nutritionPlanCalculateButton),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 24),
            ],

            if (_isCalculated) ...[
              // ── Section 2: Result Card ─────────────────────────────────
              Card(
                color: AkeliColors.primary.withValues(alpha: 0.1),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(l10n.nutritionPlanDailyGoalTitle,
                          style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                      Text('$_calorieGoal kcal',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AkeliColors.primary)),
                      const SizedBox(height: 4),
                      Text(
                          l10n.nutritionPlanBmrTdeeLabel(
                              _bmr?.toStringAsFixed(0) ?? '–', _tdee?.toStringAsFixed(0) ?? '–'),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (_effectivePaceKgWeek != null && _effectivePaceKgWeek! > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          _primaryGoal == 'muscle_gain' || _primaryGoal == 'weight_gain'
                              ? l10n.onboardingGoalPaceGain(_effectivePaceKgWeek!.toStringAsFixed(2))
                              : l10n.onboardingGoalPaceLoss(_effectivePaceKgWeek!.toStringAsFixed(2)),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AkeliColors.primary),
                        ),
                      ],
                      if (_estimatedWeeksToTarget != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.healthTargetDuration} : ${_estimatedWeeksToTarget!.round()} ${l10n.healthWeeksShort(_estimatedWeeksToTarget!.round())}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section 3: Macros ──────────────────────────────────────
              Text(l10n.nutritionPlanMacrosSection,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
              if (!isValidMacros)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l10n.mealScheduleMacroError,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 8),
              _macroRow(l10n.nutritionProtein, _proteinPct, proteinG, Colors.blue,
                  (v) => setState(() => _proteinPct = v), min: 10, max: 60),
              _macroRow(l10n.nutritionCarbs, _carbPct, carbG, Colors.orange,
                  (v) => setState(() => _carbPct = v), min: 10, max: 70),
              _macroRow(l10n.nutritionFat, _fatPct, fatG, Colors.green,
                  (v) => setState(() => _fatPct = v), min: 10, max: 50),
              const SizedBox(height: 24),

              // ── Section 4: Meal Distribution ───────────────────────────
              // Skipped during onboarding: MealScheduleOnboardingStep is a
              // dedicated later step covering the same distribution editor —
              // showing both back-to-back duplicated the same UI twice.
              if (!widget.isOnboarding) ...[
                Text(l10n.nutritionPlanMealDistributionSection,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                MealScheduleWidget(
                  initialDistributions: _distributions,
                  totalCalorieGoal: _calorieGoal,
                  onChanged: (dists) => setState(() => _distributions = dists),
                  onSaveEnabled: (valid) => setState(() => _isScheduleValid = valid),
                ),
                const SizedBox(height: 32),
              ],

              // ── Save ───────────────────────────────────────────────────
              if (!widget.isOnboarding)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isScheduleValid && isValidMacros && !_isSaving && !_isLoading) ? savePlan : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AkeliColors.primary,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            AppLocalizations.of(context).nutritionPlanSaveButton,
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              if (widget.isOnboarding) const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }


  Widget _macroRow(String label, double pct, double grams, Color color,
      ValueChanged<double> onChanged, {required double min, required double max}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: pct > min ? color : Colors.grey,
            onPressed: pct > min ? () => onChanged(pct - 1) : null,
          ),
          Expanded(
            child: Center(
              child: _InlinePercentField(
                value: pct,
                min: min,
                max: max,
                color: color,
                onChanged: onChanged,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: pct < max ? color : Colors.grey,
            onPressed: pct < max ? () => onChanged(pct + 1) : null,
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${grams.toStringAsFixed(0)}g',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlinePercentField extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _InlinePercentField({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  State<_InlinePercentField> createState() => _InlinePercentFieldState();
}

class _InlinePercentFieldState extends State<_InlinePercentField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toStringAsFixed(0));
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        final entered = double.tryParse(_ctrl.text);
        if (entered == null || entered < widget.min || entered > widget.max) {
          _ctrl.text = widget.value.toStringAsFixed(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_InlinePercentField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value.toStringAsFixed(0) != _ctrl.text) {
      _ctrl.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AkeliRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) {
                final entered = double.tryParse(v);
                if (entered != null) {
                  if (entered >= widget.min && entered <= widget.max) {
                    widget.onChanged(entered);
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: widget.color.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



