import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/nutrition_calculator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_plan_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/models/nutrition_plan.dart';
import '../auth/onboarding_data.dart';

const _mealTypeLabels = {
  'breakfast': 'Petit-déjeuner',
  'lunch': 'Déjeuner',
  'dinner': 'Dîner',
  'snack_1': 'Collation 1',
  'snack_2': 'Collation 2',
  'snack_3': 'Collation 3',
};

String _mealLabel(String type) => _mealTypeLabels[type] ?? type;

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
  double _heightCm = 170.0;
  int _age = 30;
  String _sex = 'female';
  String _activityLevel = 'moderately_active';
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

  @override
  void initState() {
    super.initState();
    _logger.provider('NutritionPlanPage initState | isOnboarding: ${widget.isOnboarding}');
    _loadInitialData();
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
        _activityLevel = obData.activityLevel ?? 'moderately_active';
        
        if (obData.targetWeight != null && obData.weight != null) {
          if (obData.targetWeight! < obData.weight!) {
            _primaryGoal = 'weight_loss';
          } else if (obData.targetWeight! > obData.weight!) {
            _primaryGoal = 'muscle_gain';
          } else {
            _primaryGoal = 'maintenance';
          }
        } else {
          _primaryGoal = 'maintenance';
        }
      });
    } else if (healthProfile != null) {
      setState(() {
        _weightKg = healthProfile.weightKg ?? 70.0;
        _heightCm = healthProfile.heightCm ?? 170.0;
        _age = healthProfile.age ?? 30;
        _sex = healthProfile.sex ?? 'female';
        _activityLevel = healthProfile.activityLevel ?? 'moderately_active';
        _primaryGoal = healthProfile.primaryGoal ?? 'maintenance';
      });
    }

    if (activePlan != null && activePlan.distributions != null && activePlan.distributions!.isNotEmpty) {
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

  void _calculateResults() {
    _logger.userAction('Calculate button tapped', screen: 'NutritionPlanPage');

    final bmr = NutritionCalculatorService.calculateBMR(
      weightKg: _weightKg,
      heightCm: _heightCm,
      age: _age,
      sex: _sex,
    );
    final tdee = NutritionCalculatorService.calculateTDEE(bmr, _activityLevel);
    final calorieGoal = NutritionCalculatorService.calculateCalorieGoal(tdee, _primaryGoal);
    final defaultMacros = NutritionCalculatorService.getDefaultMacros(_primaryGoal);
    final defaultSplits = NutritionCalculatorService.getDefaultMealSplits(3);

    final newDistributions = defaultSplits.entries.mapIndexed((i, e) => MealDistribution(
          mealType: e.key,
          sortOrder: i,
          caloriePct: e.value,
          calorieTarget: calorieGoal.toDouble() * (e.value / 100),
        )).toList();

    _logger.provider(
        'NutritionPlanPage → calculated | bmr: ${bmr.toStringAsFixed(0)} tdee: ${tdee.toStringAsFixed(0)} goal: $calorieGoal');

    setState(() {
      _bmr = bmr;
      _tdee = tdee;
      _calorieGoal = calorieGoal;
      _proteinPct = defaultMacros['protein']!;
      _carbPct = defaultMacros['carbs']!;
      _fatPct = defaultMacros['fat']!;
      _distributions = newDistributions;
      _isCalculated = true;
    });
  }

  void _addMealSlot() {
    _logger.userAction('Add meal slot tapped', screen: 'NutritionPlanPage');
    final nextIndex = _distributions.length;
    final newType = nextIndex <= 2
        ? ['breakfast', 'lunch', 'dinner'][nextIndex]
        : 'snack_${nextIndex - 2}';
    setState(() {
      _distributions = [
        ..._distributions,
        MealDistribution(
          mealType: newType,
          sortOrder: nextIndex,
          caloriePct: 0,
          calorieTarget: 0,
        ),
      ];
    });
  }

  void _removeMealSlot(int index) {
    _logger.userAction('Remove meal slot tapped | index: $index', screen: 'NutritionPlanPage');
    setState(() {
      _distributions = [..._distributions]..removeAt(index);
    });
  }

  void _updateSlotPct(int index, double newPct) {
    setState(() {
      final updated = [..._distributions];
      updated[index] = updated[index].copyWith(
        caloriePct: newPct,
        calorieTarget: _calorieGoal * (newPct / 100),
      );
      _distributions = updated;
    });
  }

  Future<bool> savePlan() async {
    _logger.userAction('Save plan button tapped', screen: 'NutritionPlanPage');

    final totalMacros = _proteinPct + _carbPct + _fatPct;
    if ((totalMacros - 100).abs() > 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les macros doivent totaliser 100%')));
      return false;
    }
    final totalDist = _distributions.fold(0.0, (s, d) => s + d.caloriePct);
    if ((totalDist - 100).abs() > 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La répartition des repas doit totaliser 100%')));
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
      proteinGoalG: NutritionCalculatorService.calculateMacroGrams(_calorieGoal, _proteinPct, 'protein'),
      carbGoalG: NutritionCalculatorService.calculateMacroGrams(_calorieGoal, _carbPct, 'carbs'),
      fatGoalG: NutritionCalculatorService.calculateMacroGrams(_calorieGoal, _fatPct, 'fat'),
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
            const SnackBar(content: Text('Plan nutritionnel enregistré avec succès')));
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
          .showSnackBar(SnackBar(content: Text('Erreur lors de la sauvegarde: $e')));
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDist = _distributions.fold(0.0, (s, d) => s + d.caloriePct);
    final isValidDist = (totalDist - 100).abs() <= 1.0;
    final totalMacros = _proteinPct + _carbPct + _fatPct;
    final isValidMacros = (totalMacros - 100).abs() <= 1.0;

    final proteinG = NutritionCalculatorService.calculateMacroGrams(_calorieGoal, _proteinPct, 'protein');
    final carbG = NutritionCalculatorService.calculateMacroGrams(_calorieGoal, _carbPct, 'carbs');
    final fatG = NutritionCalculatorService.calculateMacroGrams(_calorieGoal, _fatPct, 'fat');

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: const Text('Mon Plan Nutritionnel'),
              backgroundColor: AkeliColors.background,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isOnboarding) ...[
              // ── Section 1: Health Parameters ──────────────────────────────
              Text('1. Paramètres de santé',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _numInput('Poids (kg)', _weightKg, (v) => setState(() => _weightKg = v))),
                  const SizedBox(width: 8),
                  Expanded(child: _numInput('Taille (cm)', _heightCm, (v) => setState(() => _heightCm = v))),
                  const SizedBox(width: 8),
                  Expanded(child: _numInput('Âge', _age.toDouble(), (v) => setState(() => _age = v.toInt()))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: const InputDecoration(labelText: 'Sexe', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'female', child: Text('Femme')),
                        DropdownMenuItem(value: 'male', child: Text('Homme')),
                      ],
                      onChanged: (v) => setState(() => _sex = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _primaryGoal,
                      decoration: const InputDecoration(labelText: 'Objectif', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'weight_loss', child: Text('Perte de poids')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintien')),
                        DropdownMenuItem(value: 'muscle_gain', child: Text('Prise de muscle')),
                      ],
                      onChanged: (v) => setState(() => _primaryGoal = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(labelText: 'Niveau d\'activité', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'sedentary', child: Text('Sédentaire')),
                  DropdownMenuItem(value: 'lightly_active', child: Text('Légèrement actif')),
                  DropdownMenuItem(value: 'moderately_active', child: Text('Modérément actif')),
                  DropdownMenuItem(value: 'very_active', child: Text('Très actif')),
                  DropdownMenuItem(value: 'extremely_active', child: Text('Extrêmement actif')),
                ],
                onChanged: (v) => setState(() => _activityLevel = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculateResults,
                  child: const Text('Calculer mon objectif'),
                ),
              ),
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
                      Text('Objectif Quotidien',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16)),
                      Text('$_calorieGoal kcal',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AkeliColors.primary)),
                      const SizedBox(height: 4),
                      Text(
                          'BMR: ${_bmr?.toStringAsFixed(0)} kcal  |  TDEE: ${_tdee?.toStringAsFixed(0)} kcal',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section 3: Macros ──────────────────────────────────────
              Text('2. Macros',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
              if (!isValidMacros)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Le total des macros doit être 100%',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 8),
              _macroRow('Protéines', _proteinPct, proteinG, Colors.blue,
                  (v) => setState(() => _proteinPct = v), min: 10, max: 60),
              _macroRow('Glucides', _carbPct, carbG, Colors.orange,
                  (v) => setState(() => _carbPct = v), min: 10, max: 70),
              _macroRow('Lipides', _fatPct, fatG, Colors.green,
                  (v) => setState(() => _fatPct = v), min: 10, max: 50),
              const SizedBox(height: 24),

              // ── Section 4: Meal Distribution ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('3. Répartition des repas',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${totalDist.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: isValidDist ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (!isValidDist)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('La répartition doit totaliser 100%',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 8),
              ..._distributions.asMap().entries.map((entry) {
                final i = entry.key;
                final dist = entry.value;
                final kcal = (_calorieGoal * (dist.caloriePct / 100)).round();
                return Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(_mealLabel(dist.mealType),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: dist.caloriePct > 0 ? AkeliColors.primary : Colors.grey,
                      onPressed: dist.caloriePct > 0 ? () => _updateSlotPct(i, dist.caloriePct - 1) : null,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${dist.caloriePct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AkeliColors.primary,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: dist.caloriePct < 100 ? AkeliColors.primary : Colors.grey,
                      onPressed: dist.caloriePct < 100 ? () => _updateSlotPct(i, dist.caloriePct + 1) : null,
                    ),
                    SizedBox(
                      width: 65,
                      child: Text('$kcal kcal',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.right),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: _distributions.length > 1 ? () => _removeMealSlot(i) : null,
                    ),
                  ],
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un repas'),
                onPressed: _distributions.length < 6 ? _addMealSlot : null,
              ),
              const SizedBox(height: 32),

              // ── Save ───────────────────────────────────────────────────
              if (!widget.isOnboarding)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isValidDist && isValidMacros && !_isSaving) ? savePlan : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AkeliColors.primary,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text(
                            'Enregistrer mon plan',
                            style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget _numInput(String label, double value, Function(double) onChanged) {
    return TextFormField(
      initialValue: value.toStringAsFixed(0),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
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
              child: Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
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

