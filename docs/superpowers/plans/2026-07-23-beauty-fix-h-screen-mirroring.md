# Beauty Mode Fix — Area H: Flutter Existing-Screen Mode Mirroring

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 9 Area-H findings from the Beauty Mode branch review — a deleted Nutrition-mode health form, a mis-routed settings item, a no-op AI-mode flag, two cross-mode content leaks, a systemic l10n gap across 14 files, one piece of dead UI code, and an onboarding payload that ignores the user's chosen mode — using TDD, without touching any file outside this area's ownership.

**Architecture:** All fixes live in Flutter screen/widget files under `lib/features/**` plus `lib/l10n/app_en.arb` / `lib/l10n/app_fr.arb` (additive only). Supabase/edge-function calls are mocked with `mocktail` following the existing project pattern (see `test/providers/push_token_provider_test.dart`); widget tests follow the existing `*_beauty_test.dart` pattern (see `test/features/settings/settings_page_beauty_test.dart`) of overriding `currentModeProvider`/`localeProvider`/`userProfileProvider` inside a bare `ProviderScope` + `MaterialApp`.

**Tech Stack:** Flutter, Riverpod, flutter_test, mocktail, ARB/l10n (`flutter gen-l10n`).

## Global Constraints
- Repo: c:\Users\DELL LATITUDE 7480\akeli-nutrition-app, branch `sdui`.
- CLAUDE.md Logging Standard AND L10n Standard both apply to every file you touch. Every new/modified method must keep or add `_logger`/`appLogger` BEFORE/AFTER/ERROR calls per the standard; no new hardcoded user-visible strings may be introduced anywhere in this plan's own code (test fixture data like a mock recipe title is not user-visible UI chrome and is exempt).
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- Only touch files listed as "owned" below; `lib/providers/profile_tabs_provider.dart` and `supabase/functions/ai-assistant-chat/index.ts` are READ-ONLY references — note them as unassigned follow-up work, don't touch them.
- Owned files: `lib/features/settings/settings_page.dart`, `lib/features/settings/health_profile_page.dart`, `lib/features/settings/meal_schedule_page.dart`, `lib/features/settings/preferences_page.dart`, `lib/features/nutrition/nutrition_page.dart`, `lib/features/nutrition_plan/nutrition_plan_page.dart`, `lib/features/meal_planner/batch_cooking_page.dart`, `lib/features/meal_planner/meal_planner_page.dart`, `lib/features/meal_planner/shopping_list_page.dart`, `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart`, `lib/features/recipes/feed_page.dart`, `lib/features/recipes/saved_recipes_page.dart`, `lib/features/community/community_page.dart`, `lib/features/profile/profile_page.dart`, `lib/features/support/support_page.dart`, `lib/features/ai_assistant/ai_chat_page.dart`, `lib/features/auth/onboarding_data.dart`, `lib/features/auth/onboarding_page.dart`, `lib/features/home/home_page.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (additive only) — plus any new test files this plan creates under `test/features/**`.
- `home_page.dart`, `settings_page.dart`'s `AkeliColors.primary → Theme.of(context).colorScheme.primary/accentColor` refactor is already complete and correct in both files — do not touch it. `nutrition_page.dart`, `meal_planner_page.dart` (beauty-swap logic itself), `community_page.dart` (mode-scoped query), `feed_page.dart` (filter wiring itself) are already "done well" per the review — this plan only adds l10n to their new strings, it does not change their logic, except where a specific numbered task below says otherwise.
- All commands below run from the repo root (`c:\Users\DELL LATITUDE 7480\akeli-nutrition-app`) using the Bash tool (Git Bash / POSIX sh).

---

### Task 1: Restore the deleted Nutrition-mode health form in `health_profile_page.dart`

**Files:**
- Modify: `lib/features/settings/health_profile_page.dart` (whole file)
- Test: `test/features/settings/health_profile_page_test.dart` (new — no pre-branch version existed; confirmed via `git show origin/main -- test/features/settings/health_profile_page_test.dart` → "does not exist in 'origin/main'")

**Interfaces:**
- `_buildNutritionHealthForm(HealthProfileModel local, AppLocalizations l10n, bool isUs)` changes return type from `Widget` to `(Widget, bool)` — a record of `(form widget, hasValidationError)`. Its only caller is `build()` in the same file.
- Two private widgets are re-added (verbatim from `origin/main`): `_ChipSelector` (options/selected/onSelected/onCleared) and `_NumericField` (controller/suffix/onChanged/errorText). Both are file-private, no external callers.
- `_buildBeautyHealthForm(HealthProfileModel local)` is untouched.
- `HealthProfileModel`, `remainingWeeksFromDate`, `IntensityBadge`, `NutritionInputBounds`, `SettingsRadioRow` are all read-only dependencies already imported in this file (verified: `nutrition_input_bounds.dart`, `nutrition_targets_provider.dart show remainingWeeksFromDate`, `widgets/intensity_badge.dart`, `widgets/settings_widgets.dart` are already imported at the top of the current file — no import changes needed).

**Root cause:** the branch's "isolate Beauty fields" refactor replaced the entire pre-branch nutrition body (age/birth-date with validation, goal-type chips, weight-goal/muscle-goal chips, target-duration pace slider with `IntensityBadge`, underweight/contradicts-goal warnings, and the `hasError`-gated Save button) with a 5-field stub (sex/height/weight/target-weight/activity only, no validation). It also deleted the `_ChipSelector`/`_NumericField` private widgets those fields depended on. Separately, the height `TextField` in the stub is unconditionally bound to `_heightCtrl`, but `_initControllers` (unchanged, still correct) only ever populates `_heightFeetCtrl`/`_heightInchesCtrl` for US-locale users — so US users see a permanently blank height field.

- [ ] **Step 1: Write the failing test.** Create `test/features/settings/health_profile_page_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:akeli/features/settings/health_profile_page.dart';
  import 'package:akeli/providers/health_profile_provider.dart';
  import 'package:akeli/providers/mode_provider.dart';
  import 'package:akeli/core/locale_provider.dart';
  import 'package:akeli/features/settings/models/health_profile_model.dart';
  import 'package:akeli/l10n/app_localizations.dart';

  class FakeHealthProfileNotifier extends HealthProfileNotifier {
    final HealthProfileModel _initial;
    FakeHealthProfileNotifier(this._initial);

    @override
    Future<HealthProfileModel> build() async => _initial;
  }

  class FakeNutritionModeNotifier extends ModeNotifier {
    @override
    AppMode build() => AppMode.nutrition;
  }

  class FakeUsLocaleNotifier extends LocaleNotifier {
    @override
    Locale build() => const Locale('en', 'US');
  }

  void main() {
    final testNutritionModel = HealthProfileModel(
      sex: 'female',
      birthDate: DateTime(1990, 5, 15),
      heightCm: 170.0, // 170cm == 5'7" via UnitConverter.cmToFeetIn
      weightKg: 70.0,
      targetWeightKg: 65.0,
      activityLevel: 'moderate',
      goalType: 'weight_loss',
      weightGoal: 'loss',
      muscleGoal: 'maintenance',
      targetDate: DateTime.now().add(const Duration(days: 84)),
    );

    testWidgets(
        'HealthProfilePage renders Nutrition age, goal-type and US-locale height fields when appMode is Nutrition',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentModeProvider.overrideWith(FakeNutritionModeNotifier.new),
            healthProfileProvider
                .overrideWith(() => FakeHealthProfileNotifier(testNutritionModel)),
            localeProvider.overrideWith(FakeUsLocaleNotifier.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en', 'US'),
            home: HealthProfilePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Age / birth-date field must render (the deleted date picker row).
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);

      // Goal-type filter chips must render.
      expect(find.text('Weight loss'), findsOneWidget);

      // Weight-goal section label must render.
      expect(find.text('Weight goal'), findsOneWidget);

      // US-locale height must render as feet/inches (170cm == 5'7"),
      // not the blank-cm-field bug: the single _heightCtrl TextField is
      // never populated for US users, so its (missing) text would never
      // contain '5'/'7' either way — this asserts the real fix, not a
      // false positive.
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      final texts = textFields.map((tf) => tf.controller?.text).toList();
      expect(texts, contains('5'));
      expect(texts, contains('7'));
    });
  }
  ```

- [ ] **Step 2: Run the test and confirm it fails against the current code.**

  ```
  flutter test test/features/settings/health_profile_page_test.dart
  ```

  Expected output (current `_buildNutritionHealthForm` has no birth-date icon, no goal-type chips, no "Weight goal" label, and the height field is bound to the always-empty `_heightCtrl` for US locale):
  ```
  00:00 +0 -1: HealthProfilePage renders Nutrition age, goal-type and US-locale height fields when appMode is Nutrition [E]
    Expected: exactly one matching candidate
      Actual: _WidgetTypeFinder:<zero widgets with type "Icon" (ignoring offstage widgets) that match Icons.calendar_today_outlined>
       Which: means none were found but one was expected
  ...
  Some tests failed.
  ```

- [ ] **Step 3: Apply the fix.** Replace the full content of `lib/features/settings/health_profile_page.dart` with:

  ```dart
  // lib/features/settings/health_profile_page.dart

  import 'dart:ui';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:intl/intl.dart';

  import '../../core/locale_provider.dart';
  import '../../core/logger.dart';
  import '../../core/theme.dart';
  import '../../core/unit_converter.dart';
  import '../../core/nutrition_input_bounds.dart';
  import '../../l10n/app_localizations.dart';
  import '../../providers/health_profile_provider.dart';
  import '../../providers/mode_provider.dart';
  import '../../widgets/mode_selector.dart';
  import '../../providers/nutrition_targets_provider.dart' show remainingWeeksFromDate;
  import 'models/health_profile_model.dart';
  import 'widgets/intensity_badge.dart';
  import 'widgets/settings_widgets.dart';

  class HealthProfilePage extends ConsumerStatefulWidget {
    const HealthProfilePage({super.key});

    @override
    ConsumerState<HealthProfilePage> createState() => _HealthProfilePageState();
  }

  class _HealthProfilePageState extends ConsumerState<HealthProfilePage> {
    HealthProfileModel? _local;
    bool _saving = false;
    final _logger = appLogger;

    final _heightCtrl = TextEditingController();
    final _heightFeetCtrl = TextEditingController();
    final _heightInchesCtrl = TextEditingController();
    final _weightCtrl = TextEditingController();
    final _targetWeightCtrl = TextEditingController();

    static const Color _rosewood = Color(0xFF8A3B58);
    static const Color _gold = Color(0xFFD4AF37);

    final List<String> _hairTypes = const [
      'Type 1A - Lisse fin',
      'Type 1B - Lisse moyen',
      'Type 1C - Lisse épais',
      'Type 2A - Ondulé fin',
      'Type 2B - Ondulé moyen',
      'Type 2C - Ondulé épais',
      'Type 3A - Bouclé lâche',
      'Type 3B - Bouclé serré',
      'Type 3C - Frisé / Tirbouchon',
      'Type 4A - Crépu doux',
      'Type 4B - Crépu en Z',
      'Type 4C - Crépu très dense',
      'Locks / Dreadlocks',
      'Cheveux en Transition',
      'Soin Sous Tresses / Perruque',
    ];

    final List<String> _skinTypologies = const [
      'Peau Mixte (Zone T brillante)',
      'Peau Sèche & Déshydratée',
      'Peau Grasse & Acnéique',
      'Peau Sensible & Réactive',
      'Peau Hyperpigmentée / Taches',
      'Peau Mature / Perte de Fermeté',
      'Peau Normale & Équilibrée',
    ];

    final List<String> _allSkinConcerns = const [
      'Hyperpigmentation & Taches',
      'Acné & Imperfections',
      'Déshydratation & Tiraillements',
      'Barrière Cutanée Fragilisée',
      'Excès de Sébum & Brillance',
      'Perte d\'Élasticité & Fermeté',
    ];

    final List<String> _allBeautyGoals = const [
      'Pousse & Longueur',
      'Densité & Volume',
      'Force & Anti-Casse',
      'Hydratation Capillaire',
      'Apaisement Cuir Chevelu',
      'Éclat du Teint',
      'Atténuation des Taches',
      'Hydratation Cutanée',
      'Clarification Anti-Imperfections',
      'Fortification Barrière Cutanée',
    ];

    @override
    void dispose() {
      _logger.provider('HealthProfilePage disposed');
      _heightCtrl.dispose();
      _heightFeetCtrl.dispose();
      _heightInchesCtrl.dispose();
      _weightCtrl.dispose();
      _targetWeightCtrl.dispose();
      super.dispose();
    }

    void _initControllers(HealthProfileModel prefs, bool isUs) {
      if (prefs.heightCm != null) {
        if (isUs) {
          if (_heightFeetCtrl.text.isEmpty && _heightInchesCtrl.text.isEmpty) {
            final (feet, inches) = UnitConverter.cmToFeetIn(prefs.heightCm!);
            _heightFeetCtrl.text = feet.toString();
            _heightInchesCtrl.text = inches.toString();
          }
        } else if (_heightCtrl.text.isEmpty) {
          _heightCtrl.text = prefs.heightCm!.toStringAsFixed(1);
        }
      }
      if (_weightCtrl.text.isEmpty && prefs.weightKg != null) {
        _weightCtrl.text = (isUs
                ? UnitConverter.kgToLb(prefs.weightKg!)
                : prefs.weightKg!)
            .toStringAsFixed(1);
      }
      if (_targetWeightCtrl.text.isEmpty && prefs.targetWeightKg != null) {
        _targetWeightCtrl.text = (isUs
                ? UnitConverter.kgToLb(prefs.targetWeightKg!)
                : prefs.targetWeightKg!)
            .toStringAsFixed(1);
      }
    }

    @override
    Widget build(BuildContext context) {
      _logger.provider('HealthProfilePage build()');
      final l10n = AppLocalizations.of(context);
      final profileAsync = ref.watch(healthProfileProvider);
      final isUs = ref.watch(localeProvider).isUsLocale;
      final currentMode = ref.watch(currentModeProvider);

      return profileAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('${l10n.healthProfileError}: $e')),
        ),
        data: (prefs) {
          if (_local == null) {
            _local = prefs;
            _initControllers(prefs, isUs);
          }
          final local = _local!;

          Widget healthForm;
          bool hasError = false;
          if (currentMode == AppMode.beauty) {
            healthForm = _buildBeautyHealthForm(local);
          } else {
            final built = _buildNutritionHealthForm(local, l10n, isUs);
            healthForm = built.$1;
            hasError = built.$2;
          }

          return Scaffold(
            backgroundColor: AkeliColors.background,
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 16),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: AkeliColors.surface.withValues(alpha: 0.8),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      bottom: 8,
                      left: 16,
                      right: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: AkeliColors.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AkeliColors.onSurfaceVariant,
                            onPressed: () {
                              _logger.userAction('HealthProfilePage back tapped',
                                  screen: 'HealthProfilePage');
                              if (context.canPop()) context.pop();
                            },
                          ),
                        ),
                        Text(
                          currentMode == AppMode.beauty ? 'Diagnostic & Profil Beauté 🌸' : l10n.healthProfileTitle,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: getAppModeColor(currentMode),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 32,
                left: 16,
                right: 16,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  healthForm,

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_saving || hasError) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentMode == AppMode.beauty ? _rosewood : AkeliColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'Enregistrer le Profil',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Widget _buildBeautyHealthForm(HealthProfileModel local) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Empreinte Capillaire
          const SettingsSectionHeader(title: 'Empreinte Capillaire 👑'),
          const SizedBox(height: 8),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsLabel('Type / Texture Capillaire'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _hairTypes.contains(local.hairType) ? local.hairType : _hairTypes.first,
                  dropdownColor: AkeliColors.surfaceContainerHighest,
                  style: const TextStyle(color: AkeliColors.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AkeliColors.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _hairTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) {
                    setState(() => _local = local.copyWith(hairType: val));
                  },
                ),
                const SizedBox(height: 16),
                const SettingsLabel('Porosité'),
                const SizedBox(height: 8),
                Row(
                  children: ['Faible', 'Moyenne', 'Élevée'].map((p) {
                    final selected = local.porosity == p;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(p),
                          selected: selected,
                          selectedColor: _rosewood.withOpacity(0.3),
                          checkmarkColor: _gold,
                          labelStyle: TextStyle(
                            color: selected ? _gold : AkeliColors.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() => _local = local.copyWith(porosity: p));
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: _gold,
                  title: const Text('Cuir Chevelu Sensible / Réactif', style: TextStyle(color: AkeliColors.onSurface, fontSize: 14)),
                  subtitle: const Text('Tendance aux démangeaisons ou rougeurs', style: TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 12)),
                  value: local.sensitiveScalp ?? false,
                  onChanged: (val) {
                    setState(() => _local = local.copyWith(sensitiveScalp: val));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Diagnostic Cutané Profond
          const SettingsSectionHeader(title: 'Diagnostic Cutané Profond ✨'),
          const SizedBox(height: 8),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsLabel('Typologie de Peau'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _skinTypologies.contains(local.skinType) ? local.skinType : _skinTypologies.first,
                  dropdownColor: AkeliColors.surfaceContainerHighest,
                  style: const TextStyle(color: AkeliColors.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AkeliColors.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _skinTypologies.map((skin) => DropdownMenuItem(value: skin, child: Text(skin))).toList(),
                  onChanged: (val) {
                    setState(() => _local = local.copyWith(skinType: val));
                  },
                ),
                const SizedBox(height: 16),
                const SettingsLabel('Préoccupations Dermatologiques'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allSkinConcerns.map((concern) {
                    final isSelected = local.skinConcerns.contains(concern);
                    return FilterChip(
                      label: Text(concern),
                      selected: isSelected,
                      selectedColor: _rosewood.withOpacity(0.3),
                      checkmarkColor: _gold,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? _gold : AkeliColors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        final updated = List<String>.from(local.skinConcerns);
                        if (selected) {
                          updated.add(concern);
                        } else {
                          updated.remove(concern);
                        }
                        setState(() => _local = local.copyWith(skinConcerns: updated));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Objectifs Rituel Beauté
          const SettingsSectionHeader(title: 'Objectifs Rituel Beauté 🌸'),
          const SizedBox(height: 8),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsLabel('Priorités Capillaires & Cutanées'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allBeautyGoals.map((goal) {
                    final isSelected = local.beautyGoals.contains(goal);
                    return FilterChip(
                      label: Text(goal),
                      selected: isSelected,
                      selectedColor: _rosewood.withOpacity(0.3),
                      checkmarkColor: _gold,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? _gold : AkeliColors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        final updated = List<String>.from(local.beautyGoals);
                        if (selected) {
                          updated.add(goal);
                        } else {
                          updated.remove(goal);
                        }
                        setState(() => _local = local.copyWith(beautyGoals: updated));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    (Widget, bool) _buildNutritionHealthForm(HealthProfileModel local, AppLocalizations l10n, bool isUs) {
      final activityOptions = [
        ('sedentary',  l10n.healthActivitySedentary,  Icons.weekend_outlined),
        ('light',      l10n.healthActivityLight,       Icons.directions_walk_rounded),
        ('moderate',   l10n.healthActivityModerate,    Icons.directions_bike_outlined),
        ('active',     l10n.healthActivityActive,      Icons.fitness_center_rounded),
        ('very_active',l10n.healthActivityVeryActive,  Icons.bolt_rounded),
      ];

      final goalTypeOptions = [
        ('weight_loss',  l10n.healthGoalWeightLoss),
        ('muscle_gain',  l10n.healthGoalMuscleGain),
        ('maintenance',  l10n.healthGoalMaintenance),
        ('health',       l10n.healthGoalHealth),
        ('performance',  l10n.healthGoalPerformance),
      ];

      final weightGoalOptions = [
        ('loss',        l10n.healthGoalLose),
        ('maintenance', l10n.healthGoalMaintain),
        ('gain',        l10n.healthGoalGain),
      ];

      final muscleGoalOptions = [
        ('loss',        l10n.healthGoalLose),
        ('maintenance', l10n.healthGoalMaintain),
        ('gain',        l10n.healthGoalGain),
      ];

      final sexOptions = [
        ('male',   l10n.healthSexMale),
        ('female', l10n.healthSexFemale),
        ('other',  l10n.healthSexOther),
      ];

      int? age;
      if (local.birthDate != null) {
        final now = DateTime.now();
        age = now.year - local.birthDate!.year;
        if (now.month < local.birthDate!.month || (now.month == local.birthDate!.month && now.day < local.birthDate!.day)) {
          age--;
        }
      }

      final String? ageError = (age != null && (age < NutritionInputBounds.minAge || age > NutritionInputBounds.maxAge))
          ? (age < NutritionInputBounds.minAge ? l10n.onboardingValidationAgeMin : l10n.onboardingValidationAgeMax)
          : null;

      final String? weightError = (local.weightKg != null && (local.weightKg! < NutritionInputBounds.minWeightKg || local.weightKg! > NutritionInputBounds.maxWeightKg))
          ? (local.weightKg! < NutritionInputBounds.minWeightKg ? l10n.onboardingValidationWeightMin : l10n.onboardingValidationWeightMax)
          : null;

      final String? targetWeightError = (local.targetWeightKg != null && (local.targetWeightKg! < NutritionInputBounds.minWeightKg || local.targetWeightKg! > NutritionInputBounds.maxWeightKg))
          ? (local.targetWeightKg! < NutritionInputBounds.minWeightKg ? l10n.onboardingValidationWeightMin : l10n.onboardingValidationWeightMax)
          : null;

      final String? heightError = (local.heightCm != null && (local.heightCm! < NutritionInputBounds.minHeightCm || local.heightCm! > NutritionInputBounds.maxHeightCm))
          ? (local.heightCm! < NutritionInputBounds.minHeightCm ? l10n.onboardingValidationHeightMin : l10n.onboardingValidationHeightMax)
          : null;

      final heightM = local.heightCm != null ? local.heightCm! / 100.0 : null;
      final bool showUnderweightWarning = targetWeightError == null &&
          local.targetWeightKg != null &&
          heightM != null &&
          (local.targetWeightKg! / (heightM * heightM)) < 18.5;

      // Weight coherence (spec D3): non-blocking, mirrors onboarding.
      final bool showContradictsLoss = targetWeightError == null &&
          local.weightGoal == 'loss' &&
          local.targetWeightKg != null &&
          local.weightKg != null &&
          local.targetWeightKg! >= local.weightKg!;
      final bool showContradictsGain = targetWeightError == null &&
          local.weightGoal == 'gain' &&
          local.targetWeightKg != null &&
          local.weightKg != null &&
          local.targetWeightKg! <= local.weightKg!;

      final bool hasError = ageError != null || weightError != null || targetWeightError != null || heightError != null;

      final targetWeeks = (remainingWeeksFromDate(local.targetDate) ?? 26).clamp(4, 52);

      final widget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Health parameters ────────────────────────────────────────
          SettingsSectionHeader(title: l10n.healthParamsSection),
          const SizedBox(height: 8),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsLabel(l10n.healthSex),
                const SizedBox(height: 12),
                _ChipSelector(
                  options: sexOptions,
                  selected: local.sex,
                  onSelected: (v) {
                    _logger.userAction('Sex selected',
                        screen: 'HealthProfilePage',
                        metadata: {'value': v});
                    setState(() => _local = local.copyWith(sex: v));
                  },
                  onCleared: () {
                    _logger.userAction('Sex cleared', screen: 'HealthProfilePage');
                    setState(() => _local = local.copyWith(clearSex: true));
                  },
                ),

                const Divider(height: 24),

                SettingsLabel(l10n.healthBirthDate),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    _logger.userAction('Birth date tapped', screen: 'HealthProfilePage');
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: local.birthDate ?? DateTime(1990, 1, 1),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      _logger.userAction('Birth date picked',
                          screen: 'HealthProfilePage',
                          metadata: {'date': picked.toIso8601String()});
                      setState(() => _local = local.copyWith(birthDate: picked));
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 20, color: AkeliColors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            local.birthDate != null
                                ? DateFormat.yMMMMd().format(local.birthDate!)
                                : l10n.healthBirthDateEmpty,
                            style: TextStyle(
                              fontSize: 15,
                              color: local.birthDate != null
                                  ? AkeliColors.onSurface
                                  : AkeliColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AkeliColors.outline, size: 20),
                      ],
                    ),
                  ),
                ),
                if (ageError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ageError,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AkeliColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const Divider(height: 24),

                SettingsLabel(l10n.healthHeight),
                const SizedBox(height: 8),
                if (isUs)
                  Row(
                    children: [
                      Expanded(
                        child: _NumericField(
                          controller: _heightFeetCtrl,
                          suffix: 'ft',
                          onChanged: (v) {
                            _logger.userAction('Height changed', screen: 'HealthProfilePage');
                            final feet = int.tryParse(v);
                            final inches = int.tryParse(_heightInchesCtrl.text) ?? 0;
                            if (feet != null) {
                              setState(() => _local = local.copyWith(
                                  heightCm: UnitConverter.feetInToCm(feet, inches)));
                            }
                          },
                          errorText: heightError != null ? '' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NumericField(
                          controller: _heightInchesCtrl,
                          suffix: 'in',
                          onChanged: (v) {
                            _logger.userAction('Height changed', screen: 'HealthProfilePage');
                            final inches = int.tryParse(v);
                            final feet = int.tryParse(_heightFeetCtrl.text) ?? 0;
                            if (inches != null) {
                              setState(() => _local = local.copyWith(
                                  heightCm: UnitConverter.feetInToCm(feet, inches)));
                            }
                          },
                          errorText: heightError,
                        ),
                      ),
                    ],
                  )
                else
                  _NumericField(
                    controller: _heightCtrl,
                    suffix: 'cm',
                    onChanged: (v) {
                      _logger.userAction('Height changed', screen: 'HealthProfilePage');
                      final parsed = double.tryParse(v);
                      if (parsed != null && parsed > 0) {
                        setState(() => _local = local.copyWith(heightCm: parsed));
                      }
                    },
                    errorText: heightError,
                  ),

                const Divider(height: 24),

                SettingsLabel(l10n.healthCurrentWeight),
                const SizedBox(height: 8),
                _NumericField(
                  controller: _weightCtrl,
                  suffix: isUs ? 'lb' : 'kg',
                  onChanged: (v) {
                    _logger.userAction('Weight changed', screen: 'HealthProfilePage');
                    final parsed = double.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      final kg = isUs ? UnitConverter.lbToKg(parsed) : parsed;
                      setState(() => _local = local.copyWith(weightKg: kg));
                    }
                  },
                  errorText: weightError,
                ),

                const Divider(height: 24),

                SettingsLabel(l10n.healthTargetWeight),
                const SizedBox(height: 8),
                _NumericField(
                  controller: _targetWeightCtrl,
                  suffix: isUs ? 'lb' : 'kg',
                  onChanged: (v) {
                    _logger.userAction('Target weight changed', screen: 'HealthProfilePage');
                    final parsed = double.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      final kg = isUs ? UnitConverter.lbToKg(parsed) : parsed;
                      setState(() => _local = local.copyWith(targetWeightKg: kg));
                    }
                  },
                  errorText: targetWeightError,
                ),
                if (showUnderweightWarning) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.onboardingWarningUnderweightTarget,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (showContradictsLoss || showContradictsGain) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          showContradictsLoss
                              ? l10n.onboardingWarningTargetContradictsLoss
                              : l10n.onboardingWarningTargetContradictsGain,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 24),

                SettingsLabel(l10n.healthActivityLevel),
                const SizedBox(height: 12),
                ...activityOptions.map((opt) {
                  final (value, label, icon) = opt;
                  return SettingsRadioRow(
                    icon: icon,
                    label: label,
                    selected: local.activityLevel == value,
                    onTap: () {
                      _logger.userAction('Activity level selected',
                          screen: 'HealthProfilePage',
                          metadata: {'value': value});
                      setState(() => _local = local.copyWith(activityLevel: value));
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Goal ─────────────────────────────────────────────────────
          SettingsSectionHeader(title: l10n.healthGoalSection),
          const SizedBox(height: 8),
          SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsLabel(l10n.healthGoalType),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: goalTypeOptions.map((opt) {
                    final (code, name) = opt;
                    final selected = local.goalType == code;
                    return FilterChip(
                      label: Text(name),
                      selected: selected,
                      onSelected: (_) {
                        _logger.userAction('Goal type selected',
                            screen: 'HealthProfilePage',
                            metadata: {'goalType': code});
                        setState(() => selected
                            ? _local = local.copyWith(clearGoalType: true)
                            : _local = local.copyWith(goalType: code));
                      },
                      selectedColor: AkeliColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AkeliColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AkeliColors.primary : AkeliColors.onSurface,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),

                const Divider(height: 24),

                SettingsLabel(l10n.healthWeightGoal),
                const SizedBox(height: 12),
                _ChipSelector(
                  options: weightGoalOptions,
                  selected: local.weightGoal,
                  onSelected: (v) {
                    _logger.userAction('Weight goal selected',
                        screen: 'HealthProfilePage',
                        metadata: {'value': v});
                    setState(() => _local = local.copyWith(weightGoal: v));
                  },
                  onCleared: () {
                    _logger.userAction('Weight goal cleared', screen: 'HealthProfilePage');
                    setState(() => _local = local.copyWith(clearWeightGoal: true));
                  },
                ),

                const Divider(height: 24),

                SettingsLabel(l10n.healthMuscleGoal),
                const SizedBox(height: 12),
                _ChipSelector(
                  options: muscleGoalOptions,
                  selected: local.muscleGoal,
                  onSelected: (v) {
                    _logger.userAction('Muscle goal selected',
                        screen: 'HealthProfilePage',
                        metadata: {'value': v});
                    setState(() => _local = local.copyWith(muscleGoal: v));
                  },
                  onCleared: () {
                    _logger.userAction('Muscle goal cleared', screen: 'HealthProfilePage');
                    setState(() => _local = local.copyWith(clearMuscleGoal: true));
                  },
                ),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SettingsLabel(l10n.healthTargetDuration),
                    IntensityBadge(
                      paceKgWeek: (local.weightKg != null && local.targetWeightKg != null)
                          ? (local.targetWeightKg! - local.weightKg!).abs() / targetWeeks
                          : null,
                      isGain: (local.targetWeightKg ?? 0) > (local.weightKg ?? 0),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: targetWeeks.toDouble(),
                        min: 4,
                        max: 52,
                        divisions: 48,
                        activeColor: AkeliColors.primary,
                        label: l10n.healthWeeks(targetWeeks),
                        onChanged: (v) {
                          _logger.userAction('Target weeks changed',
                              screen: 'HealthProfilePage',
                              metadata: {'weeks': v.round()});
                          setState(() => _local = local.copyWith(
                              targetDate: DateTime.now()
                                  .add(Duration(days: v.round() * 7))));
                        },
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        l10n.healthWeeksShort(targetWeeks),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

      return (widget, hasError);
    }

    Future<void> _save() async {
      if (_local == null) return;
      setState(() => _saving = true);
      try {
        await ref.read(healthProfileProvider.notifier).save(_local!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil enregistré avec succès !')),
          );
          Navigator.of(context).maybePop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  // ── Private widgets (restored from origin/main) ──────────────────────────────

  class _ChipSelector extends StatelessWidget {
    final List<(String, String)> options;
    final String? selected;
    final ValueChanged<String> onSelected;
    final VoidCallback onCleared;

    const _ChipSelector({
      required this.options,
      required this.selected,
      required this.onSelected,
      required this.onCleared,
    });

    @override
    Widget build(BuildContext context) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final (code, name) = opt;
          final isSelected = selected == code;
          return ChoiceChip(
            label: Text(name),
            selected: isSelected,
            onSelected: (_) => isSelected ? onCleared() : onSelected(code),
            selectedColor: AkeliColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AkeliColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AkeliColors.primary : AkeliColors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        }).toList(),
      );
    }
  }

  class _NumericField extends StatelessWidget {
    final TextEditingController controller;
    final String suffix;
    final ValueChanged<String> onChanged;
    final String? errorText;

    const _NumericField({
      required this.controller,
      required this.suffix,
      required this.onChanged,
      this.errorText,
    });

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: const TextStyle(
                color: AkeliColors.onSurfaceVariant,
                fontSize: 15,
              ),
              filled: true,
              fillColor: AkeliColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: errorText != null
                    ? const BorderSide(color: AkeliColors.error, width: 1.5)
                    : BorderSide.none,
              ),
              focusedBorder: errorText != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AkeliColors.error, width: 1.5),
                    )
                  : null,
              enabledBorder: errorText != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AkeliColors.error, width: 1.5),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AkeliColors.onSurface,
            ),
            onChanged: onChanged,
          ),
          if (errorText != null && errorText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: AkeliColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    }
  }
  ```

  Note: this step deliberately leaves the AppBar title conditional, the shared Save button's hardcoded `'Enregistrer le Profil'` label, and the two `_save()` snackbar strings exactly as they are on the branch today — those are pure l10n violations (not functional regressions) and are fixed by Task 6b, which runs after this task.

- [ ] **Step 4: Re-run the test and confirm it passes.**

  ```
  flutter test test/features/settings/health_profile_page_test.dart
  ```

  Expected output:
  ```
  00:00 +1: All tests passed!
  ```

- [ ] **Step 5: Confirm the pre-existing Beauty-mode test still passes (no regression to the form this task did not touch).**

  ```
  flutter test test/features/settings/health_profile_page_beauty_test.dart
  ```

  Expected output:
  ```
  00:00 +1: All tests passed!
  ```

---

### Task 2: Route Beauty-mode "meal schedule" settings item to the real routine planner

**Files:**
- Modify: `lib/features/settings/settings_page.dart:312-319` (the meal-schedule `_MenuItem`'s `onTap`)
- Test: `test/features/settings/settings_page_meal_schedule_navigation_test.dart` (new)

**Interfaces:** No public signature changes — only the closure body of one `_MenuItem.onTap` callback changes. Uses `AkeliRoutes.mealPlanner` (`"/meal-planner"`) and `AkeliRoutes.mealSchedule` (`"/meal-schedule"`), both already defined in `lib/core/router.dart`.

**Root cause:** `meal_schedule_page.dart`'s entire body is the nutrition calorie-percentage editor (`MealScheduleWidget`) with zero further mode branching — only its AppBar title swaps to "Horaires des Routines & Soins". It is reachable in Beauty mode purely because `settings_page.dart`'s "Planification des Soins" menu item unconditionally calls `context.push(AkeliRoutes.mealSchedule)` regardless of `currentMode`. The already-existing, real Beauty routine planner is `MealPlannerPage` (`lib/features/meal_planner/meal_planner_page.dart`), which already renders `BeautyPlannerView()` when `appMode == AppMode.beauty` — this task only needs to point the settings item at it.

- [ ] **Step 1: Write the failing test.** Create `test/features/settings/settings_page_meal_schedule_navigation_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
  import 'package:akeli/core/router.dart';
  import 'package:akeli/features/settings/settings_page.dart';
  import 'package:akeli/providers/mode_provider.dart';
  import 'package:akeli/providers/user_profile_provider.dart';
  import 'package:akeli/core/locale_provider.dart';
  import 'package:akeli/shared/models/user_profile.dart';
  import 'package:akeli/l10n/app_localizations.dart';

  class FakeBeautyModeNotifier extends ModeNotifier {
    @override
    AppMode build() => AppMode.beauty;
  }

  class FakeNutritionModeNotifier extends ModeNotifier {
    @override
    AppMode build() => AppMode.nutrition;
  }

  class FakeLocaleNotifier extends LocaleNotifier {
    @override
    Locale build() => const Locale('fr');
  }

  final _testProfile = UserProfile(
    id: 'test_user',
    username: 'Marie Akeli',
    email: 'marie@akeli.com',
    onboardingDone: true,
    beautyOnboardingDone: true,
    isCreator: false,
    createdAt: DateTime.now(),
  );

  Widget _appUnderTest(AppMode mode) {
    final router = GoRouter(
      initialLocation: '/settings-test',
      routes: [
        GoRoute(
          path: '/settings-test',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: AkeliRoutes.mealSchedule,
          builder: (context, state) => const Scaffold(body: Text('MEAL_SCHEDULE_MARKER')),
        ),
        GoRoute(
          path: AkeliRoutes.mealPlanner,
          builder: (context, state) => const Scaffold(body: Text('MEAL_PLANNER_MARKER')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        currentModeProvider.overrideWith(
            mode == AppMode.beauty ? FakeBeautyModeNotifier.new : FakeNutritionModeNotifier.new),
        userProfileProvider.overrideWith((ref) async => _testProfile),
        isPremiumProvider.overrideWith((ref) => false),
        localeProvider.overrideWith(FakeLocaleNotifier.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ),
    );
  }

  void main() {
    testWidgets(
        'tapping the meal-schedule settings item in Beauty mode navigates to the meal-planner route, not mealSchedule',
        (tester) async {
      await tester.pumpWidget(_appUnderTest(AppMode.beauty));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Planification des Soins'));
      await tester.pumpAndSettle();

      expect(find.text('MEAL_PLANNER_MARKER'), findsOneWidget);
      expect(find.text('MEAL_SCHEDULE_MARKER'), findsNothing);
    });

    testWidgets(
        'tapping the meal-schedule settings item in Nutrition mode still navigates to mealSchedule',
        (tester) async {
      await tester.pumpWidget(_appUnderTest(AppMode.nutrition));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Planning des repas'));
      await tester.pumpAndSettle();

      expect(find.text('MEAL_SCHEDULE_MARKER'), findsOneWidget);
      expect(find.text('MEAL_PLANNER_MARKER'), findsNothing);
    });
  }
  ```

- [ ] **Step 2: Run the test and confirm the Beauty-mode case fails against the current code.**

  ```
  flutter test test/features/settings/settings_page_meal_schedule_navigation_test.dart
  ```

  Expected output (current code always pushes `AkeliRoutes.mealSchedule` regardless of mode):
  ```
  00:00 +0 -1: tapping the meal-schedule settings item in Beauty mode navigates to the meal-planner route, not mealSchedule [E]
    Expected: exactly one matching candidate
      Actual: _WidgetTypeFinder:<zero widgets with text "MEAL_PLANNER_MARKER" (ignoring offstage widgets)>
       Which: means none were found but one was expected
  00:00 +1 -1: tapping the meal-schedule settings item in Nutrition mode still navigates to mealSchedule
  00:00 +1 -1: Some tests failed.
  ```

- [ ] **Step 3: Apply the fix.** In `lib/features/settings/settings_page.dart`, replace this `_MenuItem` (currently lines 312-319):

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.calendar_month_outlined : Icons.restaurant_outlined,
                            label: currentMode == AppMode.beauty ? 'Planification des Soins' : l10n.mealScheduleTitle,
                            onTap: () {
                              appLogger.userAction('Meal schedule settings tapped', screen: 'SettingsPage');
                              context.push(AkeliRoutes.mealSchedule);
                            },
                          ),
  ```

  with:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.calendar_month_outlined : Icons.restaurant_outlined,
                            label: currentMode == AppMode.beauty ? 'Planification des Soins' : l10n.mealScheduleTitle,
                            onTap: () {
                              if (currentMode == AppMode.beauty) {
                                appLogger.userAction('Beauty routine planner settings tapped', screen: 'SettingsPage');
                                context.push(AkeliRoutes.mealPlanner);
                              } else {
                                appLogger.userAction('Meal schedule settings tapped', screen: 'SettingsPage');
                                context.push(AkeliRoutes.mealSchedule);
                              }
                            },
                          ),
  ```

- [ ] **Step 4: Re-run the test and confirm both cases pass.**

  ```
  flutter test test/features/settings/settings_page_meal_schedule_navigation_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

- [ ] **Step 5: Confirm the pre-existing settings tests still pass.**

  ```
  flutter test test/features/settings/settings_page_beauty_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

---

### Task 3: Send the active mode flag to the AI chat edge function

**Files:**
- Modify: `lib/features/ai_assistant/ai_chat_page.dart:64-73` (`AiChatNotifier.sendMessage`)
- Test: `test/features/ai_assistant/ai_chat_page_test.dart` (new)

**Interfaces:** `AiChatNotifier.sendMessage(String content)` — no signature change. The `body` map passed to `client.functions.invoke('ai-assistant-chat', body: body)` gains one new key: `'mode': currentMode.name` (`'nutrition'` or `'beauty'`).

**CROSS-CUTTING FOLLOW-UP (out of scope):** `supabase/functions/ai-assistant-chat/index.ts` currently has a single hardcoded `SYSTEM_PROMPT` ("Tu es Akeli, un assistant nutritionnel bienveillant et expert...") and never reads any `mode` field from the request body. This task only makes the Dart client *send* the mode; the edge function must still be updated (read `mode` from the parsed body, select a beauty-appropriate system prompt when `mode === 'beauty'`) before Beauty-mode users actually get non-nutrition answers. This is unassigned work outside this file's ownership — flag to the user.

- [ ] **Step 1: Create the test directory if it doesn't exist.**

  ```
  mkdir -p test/features/ai_assistant
  ```

- [ ] **Step 2: Write the failing test.** Create `test/features/ai_assistant/ai_chat_page_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:akeli/features/ai_assistant/ai_chat_page.dart';
  import 'package:akeli/core/supabase_client.dart';
  import 'package:akeli/providers/mode_provider.dart';
  import 'package:akeli/l10n/app_localizations.dart';

  class MockSupabaseClient extends Mock implements SupabaseClient {}
  class MockFunctionsClient extends Mock implements FunctionsClient {}

  class FakeBeautyModeNotifier extends ModeNotifier {
    @override
    AppMode build() => AppMode.beauty;
  }

  void main() {
    late MockSupabaseClient mockClient;
    late MockFunctionsClient mockFunctions;

    setUpAll(() {
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      mockClient = MockSupabaseClient();
      mockFunctions = MockFunctionsClient();
      when(() => mockClient.functions).thenReturn(mockFunctions);
      when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
          .thenAnswer((_) async => FunctionResponse(
                data: {'conversation_id': 'conv-1', 'response': 'Bonjour !'},
                status: 200,
              ));
    });

    testWidgets(
        'AiChatPage sends mode: beauty in the invoked function body when appMode is Beauty',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
            supabaseClientProvider.overrideWithValue(mockClient),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: AiChatPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Bonjour');
      await tester.tap(find.byIcon(Icons.send));
      // Bounded pumps instead of pumpAndSettle(): the typing-indicator dots
      // use repeating AnimationControllers while a message is in flight,
      // which would make pumpAndSettle() time out.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final captured = verify(() =>
              mockFunctions.invoke('ai-assistant-chat', body: captureAny(named: 'body')))
          .captured;
      expect(captured.single, isA<Map<String, dynamic>>().having((m) => m['mode'], 'mode', 'beauty'));
    });
  }
  ```

- [ ] **Step 3: Run the test and confirm it fails against the current code.**

  ```
  flutter test test/features/ai_assistant/ai_chat_page_test.dart
  ```

  Expected output (the current `body` map has no `mode` key at all):
  ```
  00:00 +0 -1: AiChatPage sends mode: beauty in the invoked function body when appMode is Beauty [E]
    Expected: an object with mode that <'beauty'>
      Actual: <{message: Bonjour, mode: <missing>}>
  ...
  Some tests failed.
  ```

- [ ] **Step 4: Apply the fix.** In `lib/features/ai_assistant/ai_chat_page.dart`, replace this block inside `AiChatNotifier.sendMessage`:

  ```dart
      final client = ref.read(supabaseClientProvider);
      final body = <String, dynamic>{
        'message': content.trim(),
        if (_conversationId != null) 'conversation_id': _conversationId,
      };

      appLogger.edge('ai-assistant-chat', 'BEFORE | conversationId: ${_conversationId ?? "new"} | messageLength: ${content.trim().length}');
  ```

  with:

  ```dart
      final client = ref.read(supabaseClientProvider);
      final currentMode = ref.read(currentModeProvider);
      final body = <String, dynamic>{
        'message': content.trim(),
        if (_conversationId != null) 'conversation_id': _conversationId,
        'mode': currentMode.name,
      };

      appLogger.edge('ai-assistant-chat', 'BEFORE | mode: ${currentMode.name} | conversationId: ${_conversationId ?? "new"} | messageLength: ${content.trim().length}');
  ```

  (`mode_provider.dart` is already imported at the top of this file — no import changes needed.)

- [ ] **Step 5: Re-run the test and confirm it passes.**

  ```
  flutter test test/features/ai_assistant/ai_chat_page_test.dart
  ```

  Expected output:
  ```
  00:00 +1: All tests passed!
  ```

---

### Task 4: Filter `profile_page.dart`'s liked-recipes tab by active mode

**Files:**
- Modify: `lib/features/profile/profile_page.dart:485-516` (the Recipes tab's `userLikedRecipesAsync.when(... data: (recipes) => ...)`)
- Test: `test/features/profile/profile_page_test.dart` (new)

**Interfaces:** No provider signature changes. `userLikedRecipesProvider(String userId)` (in `lib/providers/profile_tabs_provider.dart`, READ-ONLY reference) keeps returning `List<Recipe>` unfiltered by mode — the filter is applied client-side on the already-fetched list, using the existing `Recipe.mode` field (`'nutrition'` or `'beauty'`, DB column is `NOT NULL DEFAULT 'nutrition'` per `supabase/migrations/20260720000001_beauty_mode_database_update.sql:7`, so every recipe always has a mode value).

**Root cause:** the two profile tab *labels* ("Soins & Remèdes" / "Groupes Beauté") already swap per mode, but `userLikedRecipesProvider` has no mode filter at all — Nutrition and Beauty liked recipes are shown together under whichever label happens to be active.

**FOLLOW-UP (preferred, out of scope for this plan):** the correct long-term fix is a server-side `.eq('recipe.mode', ...)` filter inside `userLikedRecipesProvider` itself (`lib/providers/profile_tabs_provider.dart`, not owned by this plan) so the over-fetch never leaves the network. This task's client-side filter is a safe, self-contained stopgap that fixes the user-visible bug today without touching that file.

- [ ] **Step 1: Create the test directory if it doesn't exist.**

  ```
  mkdir -p test/features/profile
  ```

- [ ] **Step 2: Write the failing test.** Create `test/features/profile/profile_page_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:akeli/features/profile/profile_page.dart';
  import 'package:akeli/providers/auth_provider.dart';
  import 'package:akeli/providers/user_profile_provider.dart';
  import 'package:akeli/providers/profile_tabs_provider.dart';
  import 'package:akeli/providers/mode_provider.dart';
  import 'package:akeli/shared/models/recipe.dart';
  import 'package:akeli/shared/models/user_profile.dart';
  import 'package:akeli/l10n/app_localizations.dart';

  class FakeBeautyModeNotifier extends ModeNotifier {
    @override
    AppMode build() => AppMode.beauty;
  }

  const _testUser = User(
    id: 'user-1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-06-02T00:00:00Z',
  );

  final _testProfile = UserProfile(
    id: 'user-1',
    username: 'Marie Akeli',
    email: 'marie@akeli.com',
    onboardingDone: true,
    beautyOnboardingDone: true,
    isCreator: false,
    createdAt: DateTime.now(),
  );

  Recipe _recipe(String id, String title, String mode) => Recipe(
        id: id,
        creatorId: 'creator-1',
        title: title,
        imageUrls: const [],
        prepTimeMin: 10,
        cookTimeMin: 10,
        servings: 2,
        difficulty: 'easy',
        mode: mode,
        createdAt: DateTime(2026, 1, 1),
      );

  void main() {
    testWidgets(
        'ProfilePage Recipes tab shows only Beauty-mode recipes when appMode is Beauty',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
            currentUserProvider.overrideWithValue(_testUser),
            userProfileProvider.overrideWith((ref) async => _testProfile),
            userLikedRecipesProvider('user-1').overrideWith((ref) async => [
                  _recipe('r-nutrition', 'Nutrition Recipe', 'nutrition'),
                  _recipe('r-beauty', 'Beauty Remedy', 'beauty'),
                ]),
            userCommentsProvider('user-1').overrideWith((ref) async => <Map<String, dynamic>>[]),
            userGroupsProvider('user-1').overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: ProfilePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Beauty Remedy'), findsOneWidget);
      expect(find.text('Nutrition Recipe'), findsNothing);
    });
  }
  ```

- [ ] **Step 3: Run the test and confirm it fails against the current code.**

  ```
  flutter test test/features/profile/profile_page_test.dart
  ```

  Expected output (both recipes render today, unfiltered):
  ```
  00:00 +0 -1: ProfilePage Recipes tab shows only Beauty-mode recipes when appMode is Beauty [E]
    Expected: no matching candidates
      Actual: _WidgetTypeFinder:<exactly one widget with text "Nutrition Recipe" (ignoring offstage widgets)>
       Which: means one was found but none were expected
  ...
  Some tests failed.
  ```

- [ ] **Step 4: Apply the fix.** In `lib/features/profile/profile_page.dart`, replace the Recipes tab's `data:` branch (currently the `userLikedRecipesAsync.when(...)` block, lines 485-516):

  ```dart
                              userLikedRecipesAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (_, __) => Center(
                                  child: Text(l10n.profileLoadError2, style: const TextStyle(color: AkeliColors.outline)),
                                ),
                                data: (recipes) {
                                  if (recipes.isEmpty) {
                                    return Center(
                                      child: Text(l10n.profileNoLikedRecipes, style: const TextStyle(color: AkeliColors.outline)),
                                    );
                                  }
                                  return ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: recipes.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final r = recipes[index];
  ```

  with:

  ```dart
                              userLikedRecipesAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (_, __) => Center(
                                  child: Text(l10n.profileLoadError2, style: const TextStyle(color: AkeliColors.outline)),
                                ),
                                data: (recipes) {
                                  // Client-side mode filter — stopgap until userLikedRecipesProvider
                                  // (lib/providers/profile_tabs_provider.dart) filters server-side.
                                  final currentMode = ref.watch(currentModeProvider);
                                  final modeFilteredRecipes = recipes
                                      .where((recipe) => recipe.mode == (currentMode == AppMode.beauty ? 'beauty' : 'nutrition'))
                                      .toList();
                                  if (modeFilteredRecipes.isEmpty) {
                                    return Center(
                                      child: Text(l10n.profileNoLikedRecipes, style: const TextStyle(color: AkeliColors.outline)),
                                    );
                                  }
                                  return ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: modeFilteredRecipes.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final r = modeFilteredRecipes[index];
  ```

- [ ] **Step 5: Re-run the test and confirm it passes.**

  ```
  flutter test test/features/profile/profile_page_test.dart
  ```

  Expected output:
  ```
  00:00 +1: All tests passed!
  ```

---

### Task 5: Filter `saved_recipes_page.dart` by active mode

**Files:**
- Modify: `lib/features/recipes/saved_recipes_page.dart:56-64` (the `savedRecipesAsync.when(... data: (recipes) => ...)` block)
- Test: `test/features/recipes/saved_recipes_page_test.dart` (new)

**Interfaces:** No provider signature changes. Same filter pattern as Task 4, applied to `userSavedRecipesProvider(String userId)` (in `lib/providers/profile_tabs_provider.dart`, READ-ONLY reference), reusing the `isBeauty` local already computed at the top of `build()`.

**Root cause:** identical pattern to Task 4 — `saved_recipes_page.dart`'s title/empty-subtitle already swap per mode, but the underlying `userSavedRecipesProvider` list has no mode filter, so Nutrition and Beauty saved items mix together.

**FOLLOW-UP (preferred, out of scope for this plan):** same as Task 4 — a server-side filter inside `userSavedRecipesProvider` (`lib/providers/profile_tabs_provider.dart`) is the correct long-term fix; not owned by this plan.

- [ ] **Step 1: Write the failing test.** Create `test/features/recipes/saved_recipes_page_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:akeli/features/recipes/saved_recipes_page.dart';
  import 'package:akeli/providers/auth_provider.dart';
  import 'package:akeli/providers/profile_tabs_provider.dart';
  import 'package:akeli/providers/mode_provider.dart';
  import 'package:akeli/shared/models/recipe.dart';
  import 'package:akeli/l10n/app_localizations.dart';

  class FakeBeautyModeNotifier extends ModeNotifier {
    @override
    AppMode build() => AppMode.beauty;
  }

  const _testUser = User(
    id: 'user-1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-06-02T00:00:00Z',
  );

  Recipe _recipe(String id, String title, String mode) => Recipe(
        id: id,
        creatorId: 'creator-1',
        title: title,
        imageUrls: const [],
        prepTimeMin: 10,
        cookTimeMin: 10,
        servings: 2,
        difficulty: 'easy',
        mode: mode,
        createdAt: DateTime(2026, 1, 1),
      );

  void main() {
    testWidgets(
        'SavedRecipesPage shows only Beauty-mode recipes when appMode is Beauty',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
            currentUserProvider.overrideWithValue(_testUser),
            userSavedRecipesProvider('user-1').overrideWith((ref) async => [
                  _recipe('r-nutrition', 'Nutrition Recipe', 'nutrition'),
                  _recipe('r-beauty', 'Beauty Remedy', 'beauty'),
                ]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: SavedRecipesPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Beauty Remedy'), findsOneWidget);
      expect(find.text('Nutrition Recipe'), findsNothing);
    });
  }
  ```

- [ ] **Step 2: Run the test and confirm it fails against the current code.**

  ```
  flutter test test/features/recipes/saved_recipes_page_test.dart
  ```

  Expected output:
  ```
  00:00 +0 -1: SavedRecipesPage shows only Beauty-mode recipes when appMode is Beauty [E]
    Expected: no matching candidates
      Actual: _WidgetTypeFinder:<exactly one widget with text "Nutrition Recipe" (ignoring offstage widgets)>
       Which: means one was found but none were expected
  ...
  Some tests failed.
  ```

- [ ] **Step 3: Apply the fix.** In `lib/features/recipes/saved_recipes_page.dart`, replace:

  ```dart
        data: (recipes) {
            if (recipes.isEmpty) {
              return Center(
                child: Text(
                  emptySubtitle,
                  style: const TextStyle(color: AkeliColors.outline, fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
  ```

  with:

  ```dart
        data: (recipes) {
            // Client-side mode filter — stopgap until userSavedRecipesProvider
            // (lib/providers/profile_tabs_provider.dart) filters server-side.
            final modeFilteredRecipes = recipes
                .where((recipe) => recipe.mode == (isBeauty ? 'beauty' : 'nutrition'))
                .toList();
            if (modeFilteredRecipes.isEmpty) {
              return Center(
                child: Text(
                  emptySubtitle,
                  style: const TextStyle(color: AkeliColors.outline, fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: modeFilteredRecipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final recipe = modeFilteredRecipes[index];
  ```

- [ ] **Step 4: Re-run the test and confirm it passes.**

  ```
  flutter test test/features/recipes/saved_recipes_page_test.dart
  ```

  Expected output:
  ```
  00:00 +1: All tests passed!
  ```

---

### Task 6a: l10n sweep — `settings_page.dart`, `preferences_page.dart`, `meal_schedule_page.dart`

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (additive)
- Modify: `lib/features/settings/settings_page.dart`, `lib/features/settings/preferences_page.dart`, `lib/features/settings/meal_schedule_page.dart`

**Interfaces:** No widget signature changes — string literals only.

**New hardcoded strings found in this branch's diff (`git diff origin/main -- <file>`):**
- `settings_page.dart`: `'Suivi Rituel Beauté'`, `'Remèdes & Recettes Favoris'`, `'Diagnostic Cheveux & Peau'`, `'Planification des Soins'`, `'Mode d\'application (SDUI)'`
- `preferences_page.dart`: `'Préférences Cosmétiques & Soins'`
- `meal_schedule_page.dart`: `'Horaires des Routines & Soins'`

**Additional fix in this task (found during orchestrator self-review, not a static string literal so it wasn't caught by the grep above):** `lib/features/settings/settings_page.dart:339` does `ref.watch(currentModeProvider).displayName` — this renders `AppMode.displayName`'s hardcoded French value (`'Nutrition'/'Beauté'/'Santé'/'Sport'/'Famille'`, defined in `lib/providers/mode_provider.dart`) directly, unlocalized. Area G's plan (`docs/superpowers/plans/2026-07-23-beauty-fix-g-core-infra.md`, Task 10) fixes the same bug at its own 2 owned files (`main_shell.dart`, `mode_selector.dart`) by adding a top-level helper `String appModeLabel(AppMode mode, AppLocalizations l10n)` in `lib/widgets/mode_selector.dart` plus 5 new ARB keys (`appModeNutrition`/`appModeBeauty`/`appModeHealth`/`appModeSport`/`appModeFamily`, already added to both ARB files by that task). In this task, after Area G's Task 10 has run (check by grepping `lib/widgets/mode_selector.dart` for `String appModeLabel` — if absent, run Area G's Task 10 first): import it (`import 'package:akeli/widgets/mode_selector.dart' show appModeLabel;`) and replace `ref.watch(currentModeProvider).displayName` at `settings_page.dart:339` with `appModeLabel(ref.watch(currentModeProvider), l10n)` (an `l10n` local variable already exists in this build method — confirm before use). Add one widget-test assertion to this task's Step 4 (below) covering this specific line: pump `SettingsPage` with `locale: const Locale('en')` and `AppMode.beauty` active, assert `find.text('Beauté')` is `findsNothing` and `find.text('Beauty')` is `findsOneWidget`.

- [ ] **Step 1: Add ARB keys.** In `lib/l10n/app_en.arb`, find:

  ```json
    "settingsHealthGoals": "Health & Goals",
    "@settingsHealthGoals": {},
  ```

  and replace with:

  ```json
    "settingsHealthGoals": "Health & Goals",
    "@settingsHealthGoals": {},
    "settingsBeautyTrackingLabel": "Beauty Ritual Tracking",
    "@settingsBeautyTrackingLabel": {},
    "settingsBeautySavedRecipesLabel": "Favorite Remedies & Recipes",
    "@settingsBeautySavedRecipesLabel": {},
    "settingsBeautyHealthProfileLabel": "Hair & Skin Diagnostic",
    "@settingsBeautyHealthProfileLabel": {},
    "settingsBeautyMealScheduleLabel": "Care Scheduling",
    "@settingsBeautyMealScheduleLabel": {},
    "settingsAppModeLabel": "App Mode (SDUI)",
    "@settingsAppModeLabel": {},
  ```

  In `lib/l10n/app_en.arb`, find:

  ```json
    "preferencesTitle": "Preferences",
    "@preferencesTitle": {},
  ```

  and replace with:

  ```json
    "preferencesTitle": "Preferences",
    "@preferencesTitle": {},
    "preferencesBeautyTitle": "Cosmetic & Care Preferences",
    "@preferencesBeautyTitle": {},
  ```

  In `lib/l10n/app_en.arb`, find:

  ```json
    "mealScheduleTitle": "Meal Schedule",
    "@mealScheduleTitle": {},
  ```

  and replace with:

  ```json
    "mealScheduleTitle": "Meal Schedule",
    "@mealScheduleTitle": {},
    "mealScheduleBeautyTitle": "Routine & Care Schedule",
    "@mealScheduleBeautyTitle": {},
  ```

- [ ] **Step 2: Mirror the same keys in `lib/l10n/app_fr.arb`.** Find:

  ```json
    "settingsHealthGoals": "Santé & Objectifs",
  ```

  and replace with:

  ```json
    "settingsHealthGoals": "Santé & Objectifs",
    "settingsBeautyTrackingLabel": "Suivi Rituel Beauté",
    "settingsBeautySavedRecipesLabel": "Remèdes & Recettes Favoris",
    "settingsBeautyHealthProfileLabel": "Diagnostic Cheveux & Peau",
    "settingsBeautyMealScheduleLabel": "Planification des Soins",
    "settingsAppModeLabel": "Mode d'application (SDUI)",
  ```

  Find:

  ```json
    "preferencesTitle": "Préférences",
  ```

  and replace with:

  ```json
    "preferencesTitle": "Préférences",
    "preferencesBeautyTitle": "Préférences Cosmétiques & Soins",
  ```

  Find:

  ```json
    "mealScheduleTitle": "Planning des repas",
  ```

  and replace with:

  ```json
    "mealScheduleTitle": "Planning des repas",
    "mealScheduleBeautyTitle": "Horaires des Routines & Soins",
  ```

- [ ] **Step 3: Replace the hardcoded strings in `lib/features/settings/settings_page.dart`.** Replace:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.spa_outlined : Icons.monitor_weight_outlined,
                            label: currentMode == AppMode.beauty ? 'Suivi Rituel Beauté' : l10n.settingsNutritionTracking,
  ```

  with:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.spa_outlined : Icons.monitor_weight_outlined,
                            label: currentMode == AppMode.beauty ? l10n.settingsBeautyTrackingLabel : l10n.settingsNutritionTracking,
  ```

  Replace:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.auto_awesome_outlined : Icons.bookmark_outline_rounded,
                            label: currentMode == AppMode.beauty ? 'Remèdes & Recettes Favoris' : l10n.settingsSavedRecipes,
  ```

  with:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.auto_awesome_outlined : Icons.bookmark_outline_rounded,
                            label: currentMode == AppMode.beauty ? l10n.settingsBeautySavedRecipesLabel : l10n.settingsSavedRecipes,
  ```

  Replace:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.face_retouching_natural_outlined : Icons.monitor_heart_outlined,
                            label: currentMode == AppMode.beauty ? 'Diagnostic Cheveux & Peau' : l10n.settingsHealthGoals,
  ```

  with:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.face_retouching_natural_outlined : Icons.monitor_heart_outlined,
                            label: currentMode == AppMode.beauty ? l10n.settingsBeautyHealthProfileLabel : l10n.settingsHealthGoals,
  ```

  Replace:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.calendar_month_outlined : Icons.restaurant_outlined,
                            label: currentMode == AppMode.beauty ? 'Planification des Soins' : l10n.mealScheduleTitle,
  ```

  with:

  ```dart
                          _MenuItem(
                            icon: currentMode == AppMode.beauty ? Icons.calendar_month_outlined : Icons.restaurant_outlined,
                            label: currentMode == AppMode.beauty ? l10n.settingsBeautyMealScheduleLabel : l10n.mealScheduleTitle,
  ```

  Replace:

  ```dart
                        _MenuItem(
                          icon: getAppModeIcon(ref.watch(currentModeProvider)),
                          label: 'Mode d\'application (SDUI)',
  ```

  with:

  ```dart
                        _MenuItem(
                          icon: getAppModeIcon(ref.watch(currentModeProvider)),
                          label: l10n.settingsAppModeLabel,
  ```

- [ ] **Step 4: Replace the hardcoded string in `lib/features/settings/preferences_page.dart`.** Replace:

  ```dart
                      Text(
                        ref.watch(currentModeProvider) == AppMode.beauty ? 'Préférences Cosmétiques & Soins' : l10n.preferencesTitle,
  ```

  with:

  ```dart
                      Text(
                        ref.watch(currentModeProvider) == AppMode.beauty ? l10n.preferencesBeautyTitle : l10n.preferencesTitle,
  ```

- [ ] **Step 5: Replace the hardcoded string in `lib/features/settings/meal_schedule_page.dart`.** Replace:

  ```dart
      final title = isBeauty ? 'Horaires des Routines & Soins' : l10n.mealScheduleTitle;
  ```

  with:

  ```dart
      final title = isBeauty ? l10n.mealScheduleBeautyTitle : l10n.mealScheduleTitle;
  ```

- [ ] **Step 6: Run `flutter gen-l10n`, then confirm the pre-existing widget tests still pass.**

  ```
  flutter gen-l10n
  flutter test test/features/settings/settings_page_beauty_test.dart test/features/settings/settings_page_meal_schedule_navigation_test.dart
  ```

  Expected output:
  ```
  00:00 +4: All tests passed!
  ```

---

### Task 6b: l10n sweep — `health_profile_page.dart`

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (additive)
- Modify: `lib/features/settings/health_profile_page.dart` (must run after Task 1)

**Interfaces:** No widget signature changes — string literals only.

**Scope note (deliberate exception):** the hair-type / porosity / skin-type / skin-concern / beauty-goal *option values* inside `_buildBeautyHealthForm` (e.g. `'Type 4C - Crépu très dense'`, `'Faible'`, `'Peau Mixte (Zone T brillante)'`) are **not** localized by this task. `health_profile_model.dart` (line: `hairType: health?['hair_type'] as String?`) and the Python vectorization spectrum matcher (Area D, `HAIR_TYPE_SPECTRUM` etc.) both consume these exact French strings as the *stored data value*, not just display text — they are not `models/health_profile_model.dart`-owned by this plan, and relabeling them via l10n without a coordinated code/label split across the DB, the model, and the Python spectra would silently break vectorization for every Beauty user. This is flagged as unassigned cross-cutting follow-up (see Coverage Checklist). Only the static section headers, field labels, switch title/subtitle, Save button, AppBar title, and snackbar messages are in scope here.

**New/still-hardcoded strings in scope:**
`'Diagnostic & Profil Beauté 🌸'` (AppBar title), `'Enregistrer le Profil'` (Save button), `'Profil enregistré avec succès !'` / `'Erreur lors de l\'enregistrement: $e'` (snackbars — these can reuse the pre-existing `healthProfileSaved`/`healthProfileError` keys), `'Empreinte Capillaire 👑'`, `'Type / Texture Capillaire'`, `'Porosité'`, `'Cuir Chevelu Sensible / Réactif'`, `'Tendance aux démangeaisons ou rougeurs'`, `'Diagnostic Cutané Profond ✨'`, `'Typologie de Peau'`, `'Préoccupations Dermatologiques'`, `'Objectifs Rituel Beauté 🌸'`, `'Priorités Capillaires & Cutanées'`.

- [ ] **Step 1: Add ARB keys.** In `lib/l10n/app_en.arb`, find:

  ```json
    "healthGoalGain": "Gain",
    "@healthGoalGain": {},
  ```

  and replace with:

  ```json
    "healthGoalGain": "Gain",
    "@healthGoalGain": {},
    "healthProfileBeautyTitle": "Beauty Diagnostic & Profile 🌸",
    "@healthProfileBeautyTitle": {},
    "healthProfileSaveBeauty": "Save My Profile",
    "@healthProfileSaveBeauty": {},
    "healthBeautyHairSectionTitle": "Hair Fingerprint 👑",
    "@healthBeautyHairSectionTitle": {},
    "healthBeautyHairTypeLabel": "Hair Type / Texture",
    "@healthBeautyHairTypeLabel": {},
    "healthBeautyPorosityLabel": "Porosity",
    "@healthBeautyPorosityLabel": {},
    "healthBeautySensitiveScalpTitle": "Sensitive / Reactive Scalp",
    "@healthBeautySensitiveScalpTitle": {},
    "healthBeautySensitiveScalpSubtitle": "Prone to itching or redness",
    "@healthBeautySensitiveScalpSubtitle": {},
    "healthBeautySkinSectionTitle": "Deep Skin Diagnostic ✨",
    "@healthBeautySkinSectionTitle": {},
    "healthBeautySkinTypeLabel": "Skin Type",
    "@healthBeautySkinTypeLabel": {},
    "healthBeautySkinConcernsLabel": "Dermatological Concerns",
    "@healthBeautySkinConcernsLabel": {},
    "healthBeautyGoalsSectionTitle": "Beauty Ritual Goals 🌸",
    "@healthBeautyGoalsSectionTitle": {},
    "healthBeautyGoalsLabel": "Hair & Skin Priorities",
    "@healthBeautyGoalsLabel": {},
  ```

- [ ] **Step 2: Mirror in `lib/l10n/app_fr.arb`.** Find:

  ```json
    "healthGoalGain": "Prendre",
  ```

  and replace with:

  ```json
    "healthGoalGain": "Prendre",
    "healthProfileBeautyTitle": "Diagnostic & Profil Beauté 🌸",
    "healthProfileSaveBeauty": "Enregistrer le Profil",
    "healthBeautyHairSectionTitle": "Empreinte Capillaire 👑",
    "healthBeautyHairTypeLabel": "Type / Texture Capillaire",
    "healthBeautyPorosityLabel": "Porosité",
    "healthBeautySensitiveScalpTitle": "Cuir Chevelu Sensible / Réactif",
    "healthBeautySensitiveScalpSubtitle": "Tendance aux démangeaisons ou rougeurs",
    "healthBeautySkinSectionTitle": "Diagnostic Cutané Profond ✨",
    "healthBeautySkinTypeLabel": "Typologie de Peau",
    "healthBeautySkinConcernsLabel": "Préoccupations Dermatologiques",
    "healthBeautyGoalsSectionTitle": "Objectifs Rituel Beauté 🌸",
    "healthBeautyGoalsLabel": "Priorités Capillaires & Cutanées",
  ```

- [ ] **Step 3: Replace the hardcoded strings in `lib/features/settings/health_profile_page.dart`.**

  Replace the AppBar title:
  ```dart
                        Text(
                          currentMode == AppMode.beauty ? 'Diagnostic & Profil Beauté 🌸' : l10n.healthProfileTitle,
  ```
  with:
  ```dart
                        Text(
                          currentMode == AppMode.beauty ? l10n.healthProfileBeautyTitle : l10n.healthProfileTitle,
  ```

  Replace the Save button label:
  ```dart
                          : Text(
                              'Enregistrer le Profil',
                              style: const TextStyle(
  ```
  with:
  ```dart
                          : Text(
                              currentMode == AppMode.beauty ? l10n.healthProfileSaveBeauty : l10n.healthProfileSave,
                              style: const TextStyle(
  ```

  Replace the two `_save()` snackbar strings:
  ```dart
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil enregistré avec succès !')),
          );
  ```
  with:
  ```dart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).healthProfileSaved)),
          );
  ```
  and:
  ```dart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
          );
  ```
  with:
  ```dart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context).healthProfileError}: $e')),
          );
  ```

  Replace the Beauty-form section headers/labels — in `_buildBeautyHealthForm`, replace each hardcoded `Text`/`SettingsSectionHeader`/`SettingsLabel` argument below (leave the `Column`/`SettingsCard` structure and all option-value lists untouched):

  ```dart
        const SettingsSectionHeader(title: 'Empreinte Capillaire 👑'),
  ```
  →
  ```dart
        SettingsSectionHeader(title: AppLocalizations.of(context).healthBeautyHairSectionTitle),
  ```

  ```dart
              const SettingsLabel('Type / Texture Capillaire'),
  ```
  →
  ```dart
              SettingsLabel(AppLocalizations.of(context).healthBeautyHairTypeLabel),
  ```

  ```dart
              const SettingsLabel('Porosité'),
  ```
  →
  ```dart
              SettingsLabel(AppLocalizations.of(context).healthBeautyPorosityLabel),
  ```

  ```dart
                  title: const Text('Cuir Chevelu Sensible / Réactif', style: TextStyle(color: AkeliColors.onSurface, fontSize: 14)),
                  subtitle: const Text('Tendance aux démangeaisons ou rougeurs', style: TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 12)),
  ```
  →
  ```dart
                  title: Text(AppLocalizations.of(context).healthBeautySensitiveScalpTitle, style: const TextStyle(color: AkeliColors.onSurface, fontSize: 14)),
                  subtitle: Text(AppLocalizations.of(context).healthBeautySensitiveScalpSubtitle, style: const TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 12)),
  ```

  ```dart
        const SettingsSectionHeader(title: 'Diagnostic Cutané Profond ✨'),
  ```
  →
  ```dart
        SettingsSectionHeader(title: AppLocalizations.of(context).healthBeautySkinSectionTitle),
  ```

  ```dart
              const SettingsLabel('Typologie de Peau'),
  ```
  →
  ```dart
              SettingsLabel(AppLocalizations.of(context).healthBeautySkinTypeLabel),
  ```

  ```dart
              const SettingsLabel('Préoccupations Dermatologiques'),
  ```
  →
  ```dart
              SettingsLabel(AppLocalizations.of(context).healthBeautySkinConcernsLabel),
  ```

  ```dart
        const SettingsSectionHeader(title: 'Objectifs Rituel Beauté 🌸'),
  ```
  →
  ```dart
        SettingsSectionHeader(title: AppLocalizations.of(context).healthBeautyGoalsSectionTitle),
  ```

  ```dart
              const SettingsLabel('Priorités Capillaires & Cutanées'),
  ```
  →
  ```dart
              SettingsLabel(AppLocalizations.of(context).healthBeautyGoalsLabel),
  ```

  Since `_buildBeautyHealthForm(HealthProfileModel local)` has no `context` parameter, change its signature to accept one:
  ```dart
    Widget _buildBeautyHealthForm(BuildContext context, HealthProfileModel local) {
  ```
  and update its one call site in `build()`:
  ```dart
            healthForm = _buildBeautyHealthForm(local);
  ```
  →
  ```dart
            healthForm = _buildBeautyHealthForm(context, local);
  ```

- [ ] **Step 4: Run `flutter gen-l10n`, then confirm both existing health-profile tests still pass.**

  ```
  flutter gen-l10n
  flutter test test/features/settings/health_profile_page_test.dart test/features/settings/health_profile_page_beauty_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

---

### Task 6c: l10n sweep — `ai_chat_page.dart`, `support_page.dart`, `nutrition_plan_page.dart`

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (additive)
- Modify: `lib/features/ai_assistant/ai_chat_page.dart` (must run after Task 3), `lib/features/support/support_page.dart`, `lib/features/nutrition_plan/nutrition_plan_page.dart`

**New hardcoded strings found in this branch's diff:**
- `ai_chat_page.dart`: `'Assistant Beauté & Soins IA'`, and 4 suggestion strings.
- `support_page.dart`: `'Support Beauté & Soins'`.
- `nutrition_plan_page.dart`: `'Mon Programme de Soins & Routines'`.

- [ ] **Step 1: Add ARB keys.** In `lib/l10n/app_en.arb`, find:

  ```json
    "aiAssistantSuggestion4": "Give me a recipe for tonight.",
    "@aiAssistantSuggestion4": {},
  ```

  and replace with:

  ```json
    "aiAssistantSuggestion4": "Give me a recipe for tonight.",
    "@aiAssistantSuggestion4": {},
    "aiAssistantBeautyTitle": "Beauty & Care AI Assistant",
    "@aiAssistantBeautyTitle": {},
    "aiAssistantBeautySuggestion1": "What's the best hydrating routine for 4C hair?",
    "@aiAssistantBeautySuggestion1": {},
    "aiAssistantBeautySuggestion2": "How do I use raw shea butter for acne and dark spots?",
    "@aiAssistantBeautySuggestion2": {},
    "aiAssistantBeautySuggestion3": "Which natural actives boost growth and stop breakage?",
    "@aiAssistantBeautySuggestion3": {},
    "aiAssistantBeautySuggestion4": "Suggest a soothing homemade scalp mask.",
    "@aiAssistantBeautySuggestion4": {},
  ```

  Find:

  ```json
    "supportTitle": "Help & FAQ",
    "@supportTitle": {},
  ```

  and replace with:

  ```json
    "supportTitle": "Help & FAQ",
    "@supportTitle": {},
    "supportBeautyTitle": "Beauty & Care Support",
    "@supportBeautyTitle": {},
  ```

  Find:

  ```json
    "nutritionPlanTitle": "My Nutrition Plan",
    "@nutritionPlanTitle": {},
  ```

  and replace with:

  ```json
    "nutritionPlanTitle": "My Nutrition Plan",
    "@nutritionPlanTitle": {},
    "nutritionPlanBeautyTitle": "My Care & Routine Program",
    "@nutritionPlanBeautyTitle": {},
  ```

- [ ] **Step 2: Mirror in `lib/l10n/app_fr.arb`.** Find:

  ```json
    "aiAssistantSuggestion4": "Donne-moi une recette pour ce soir.",
  ```

  and replace with:

  ```json
    "aiAssistantSuggestion4": "Donne-moi une recette pour ce soir.",
    "aiAssistantBeautyTitle": "Assistant Beauté & Soins IA",
    "aiAssistantBeautySuggestion1": "Quelle est la meilleure routine hydratante pour cheveux 4C ?",
    "aiAssistantBeautySuggestion2": "Comment utiliser le beurre de karité brut contre l'acné et les taches ?",
    "aiAssistantBeautySuggestion3": "Quels actifs naturels favorisent la pousse et stoppent la casse ?",
    "aiAssistantBeautySuggestion4": "Propose-moi un masque fait maison apaisant pour cuir chevelu.",
  ```

  Find:

  ```json
    "supportTitle": "Aide & FAQ",
  ```

  and replace with:

  ```json
    "supportTitle": "Aide & FAQ",
    "supportBeautyTitle": "Support Beauté & Soins",
  ```

  Find:

  ```json
    "nutritionPlanTitle": "Mon Plan Nutritionnel",
  ```

  and replace with:

  ```json
    "nutritionPlanTitle": "Mon Plan Nutritionnel",
    "nutritionPlanBeautyTitle": "Mon Programme de Soins & Routines",
  ```

- [ ] **Step 3: Replace the hardcoded strings in `lib/features/ai_assistant/ai_chat_page.dart`.** Replace:

  ```dart
                          Text(
                            ref.watch(currentModeProvider) == AppMode.beauty ? 'Assistant Beauté & Soins IA' : l10n.aiAssistantTitle,
  ```
  with:
  ```dart
                          Text(
                            ref.watch(currentModeProvider) == AppMode.beauty ? l10n.aiAssistantBeautyTitle : l10n.aiAssistantTitle,
  ```

  Replace:
  ```dart
                    suggestions: ref.watch(currentModeProvider) == AppMode.beauty
                        ? [
                            'Quelle est la meilleure routine hydratante pour cheveux 4C ?',
                            'Comment utiliser le beurre de karité brut contre l\'acné et les taches ?',
                            'Quels actifs naturels favorisent la pousse et stoppent la casse ?',
                            'Propose-moi un masque fait maison apaisant pour cuir chevelu.',
                          ]
                        : [
                            l10n.aiAssistantSuggestion1,
                            l10n.aiAssistantSuggestion2,
                            l10n.aiAssistantSuggestion3,
                            l10n.aiAssistantSuggestion4,
                          ],
  ```
  with:
  ```dart
                    suggestions: ref.watch(currentModeProvider) == AppMode.beauty
                        ? [
                            l10n.aiAssistantBeautySuggestion1,
                            l10n.aiAssistantBeautySuggestion2,
                            l10n.aiAssistantBeautySuggestion3,
                            l10n.aiAssistantBeautySuggestion4,
                          ]
                        : [
                            l10n.aiAssistantSuggestion1,
                            l10n.aiAssistantSuggestion2,
                            l10n.aiAssistantSuggestion3,
                            l10n.aiAssistantSuggestion4,
                          ],
  ```

- [ ] **Step 4: Replace the hardcoded string in `lib/features/support/support_page.dart`.** Replace:

  ```dart
          title: Text(
            ref.watch(currentModeProvider) == AppMode.beauty ? 'Support Beauté & Soins' : l10n.supportTitle,
  ```
  with:
  ```dart
          title: Text(
            ref.watch(currentModeProvider) == AppMode.beauty ? l10n.supportBeautyTitle : l10n.supportTitle,
  ```

- [ ] **Step 5: Replace the hardcoded string in `lib/features/nutrition_plan/nutrition_plan_page.dart`.** Replace:

  ```dart
      final title = isBeauty ? 'Mon Programme de Soins & Routines' : l10n.nutritionPlanTitle;
  ```
  with:
  ```dart
      final title = isBeauty ? l10n.nutritionPlanBeautyTitle : l10n.nutritionPlanTitle;
  ```

- [ ] **Step 6: Run `flutter gen-l10n`, then confirm the AI chat test still passes.**

  ```
  flutter gen-l10n
  flutter test test/features/ai_assistant/ai_chat_page_test.dart
  ```

  Expected output:
  ```
  00:00 +1: All tests passed!
  ```

---

### Task 6d: l10n sweep — `profile_page.dart`, `saved_recipes_page.dart`, `community_page.dart`

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (additive)
- Modify: `lib/features/profile/profile_page.dart` (must run after Task 4), `lib/features/recipes/saved_recipes_page.dart` (must run after Task 5), `lib/features/community/community_page.dart`

**New hardcoded strings found in this branch's diff:**
- `profile_page.dart`: `'Soins & Remèdes'`, `'Groupes Beauté'`.
- `saved_recipes_page.dart`: `'Mes Remèdes & Soins Favoris'`, `'Aucun soin sauvegardé pour le moment.'`.
- `community_page.dart`: `'Communauté Beauté'`.

- [ ] **Step 1: Add ARB keys.** In `lib/l10n/app_en.arb`, find:

  ```json
    "profileTabGroups": "Groups",
    "@profileTabGroups": {},
  ```

  and replace with:

  ```json
    "profileTabGroups": "Groups",
    "@profileTabGroups": {},
    "profileBeautyTabRecipes": "Care & Remedies",
    "@profileBeautyTabRecipes": {},
    "profileBeautyTabGroups": "Beauty Groups",
    "@profileBeautyTabGroups": {},
  ```

  Find:

  ```json
    "savedRecipesEmpty": "No saved recipes yet",
    "@savedRecipesEmpty": {},
  ```

  and replace with:

  ```json
    "savedRecipesEmpty": "No saved recipes yet",
    "@savedRecipesEmpty": {},
    "savedRecipesBeautyTitle": "My Favorite Remedies & Care",
    "@savedRecipesBeautyTitle": {},
    "savedRecipesBeautyEmpty": "No care items saved yet.",
    "@savedRecipesBeautyEmpty": {},
  ```

  Find:

  ```json
    "communityTitle": "Community",
    "@communityTitle": {},
  ```

  and replace with:

  ```json
    "communityTitle": "Community",
    "@communityTitle": {},
    "communityBeautyTitle": "Beauty Community",
    "@communityBeautyTitle": {},
  ```

- [ ] **Step 2: Mirror in `lib/l10n/app_fr.arb`.** Find:

  ```json
    "profileTabGroups": "Groupes",
  ```

  and replace with:

  ```json
    "profileTabGroups": "Groupes",
    "profileBeautyTabRecipes": "Soins & Remèdes",
    "profileBeautyTabGroups": "Groupes Beauté",
  ```

  Find:

  ```json
    "savedRecipesEmpty": "Aucune recette sauvegardée",
  ```

  and replace with:

  ```json
    "savedRecipesEmpty": "Aucune recette sauvegardée",
    "savedRecipesBeautyTitle": "Mes Remèdes & Soins Favoris",
    "savedRecipesBeautyEmpty": "Aucun soin sauvegardé pour le moment.",
  ```

  Find:

  ```json
    "communityTitle": "Communauté",
  ```

  and replace with:

  ```json
    "communityTitle": "Communauté",
    "communityBeautyTitle": "Communauté Beauté",
  ```

- [ ] **Step 3: Replace the hardcoded strings in `lib/features/profile/profile_page.dart`.** Replace:

  ```dart
                          Tab(text: ref.watch(currentModeProvider) == AppMode.beauty ? 'Soins & Remèdes' : l10n.profileTabRecipes),
                          Tab(text: l10n.profileTabComments),
                          Tab(text: ref.watch(currentModeProvider) == AppMode.beauty ? 'Groupes Beauté' : l10n.profileTabGroups),
  ```
  with:
  ```dart
                          Tab(text: ref.watch(currentModeProvider) == AppMode.beauty ? l10n.profileBeautyTabRecipes : l10n.profileTabRecipes),
                          Tab(text: l10n.profileTabComments),
                          Tab(text: ref.watch(currentModeProvider) == AppMode.beauty ? l10n.profileBeautyTabGroups : l10n.profileTabGroups),
  ```

- [ ] **Step 4: Replace the hardcoded strings in `lib/features/recipes/saved_recipes_page.dart`.** Replace:

  ```dart
      final title = isBeauty ? 'Mes Remèdes & Soins Favoris' : l10n.savedRecipesTitle;
      final emptySubtitle = isBeauty ? 'Aucun soin sauvegardé pour le moment.' : l10n.savedRecipesEmpty;
  ```
  with:
  ```dart
      final title = isBeauty ? l10n.savedRecipesBeautyTitle : l10n.savedRecipesTitle;
      final emptySubtitle = isBeauty ? l10n.savedRecipesBeautyEmpty : l10n.savedRecipesEmpty;
  ```

- [ ] **Step 5: Replace the hardcoded string in `lib/features/community/community_page.dart`.** Replace:

  ```dart
      final title = isBeauty ? 'Communauté Beauté' : l10n.communityTitle;
  ```
  with:
  ```dart
      final title = isBeauty ? l10n.communityBeautyTitle : l10n.communityTitle;
  ```

- [ ] **Step 6: Run `flutter gen-l10n`, then confirm the profile/saved-recipes tests still pass.**

  ```
  flutter gen-l10n
  flutter test test/features/profile/profile_page_test.dart test/features/recipes/saved_recipes_page_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

---

### Task 6e: l10n sweep — `feed_page.dart`

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (additive)
- Modify: `lib/features/recipes/feed_page.dart`

**New hardcoded strings found in this branch's diff** (24 keys — the Beauty combined-filter sheet's 3 chip groups, the Beauty feed tabs, the Beauty search hint, and the two page-title branches, one of which reuses a pre-existing hardcoded string this branch's diff also touches):

- [ ] **Step 1: Add ARB keys.** In `lib/l10n/app_en.arb`, find:

  ```json
    "feedSearchHint": "Search recipes...",
    "@feedSearchHint": {},
  ```

  and replace with:

  ```json
    "feedSearchHint": "Search recipes...",
    "@feedSearchHint": {},
    "feedBeautyCategoryLabel": "Care Category",
    "@feedBeautyCategoryLabel": {},
    "feedBeautyCategoryAll": "All",
    "@feedBeautyCategoryAll": {},
    "feedBeautyCategoryHair": "👑 Hair",
    "@feedBeautyCategoryHair": {},
    "feedBeautyCategoryScalp": "🌿 Scalp",
    "@feedBeautyCategoryScalp": {},
    "feedBeautyCategorySkin": "✨ Face",
    "@feedBeautyCategorySkin": {},
    "feedBeautyCategoryBody": "🧴 Body",
    "@feedBeautyCategoryBody": {},
    "feedBeautyFormulaLabel": "Formula Type",
    "@feedBeautyFormulaLabel": {},
    "feedBeautyFormulaAll": "All",
    "@feedBeautyFormulaAll": {},
    "feedBeautyFormulaDiy": "🧪 DIY Recipe",
    "@feedBeautyFormulaDiy": {},
    "feedBeautyFormulaArtisanal": "🌿 Artisanal",
    "@feedBeautyFormulaArtisanal": {},
    "feedBeautyFormulaIndustrial": "🏬 Commercial",
    "@feedBeautyFormulaIndustrial": {},
    "feedBeautyGoalLabel": "Goal & Virtue",
    "@feedBeautyGoalLabel": {},
    "feedBeautyGoalAll": "All",
    "@feedBeautyGoalAll": {},
    "feedBeautyGoalHairGrowth": "🌱 Growth & Length",
    "@feedBeautyGoalHairGrowth": {},
    "feedBeautyGoalAntiBreakage": "🛡️ Anti-Breakage Strength",
    "@feedBeautyGoalAntiBreakage": {},
    "feedBeautyGoalMoisture": "💧 Moisture",
    "@feedBeautyGoalMoisture": {},
    "feedBeautyGoalScalpSoothing": "💆 Soothing Care",
    "@feedBeautyGoalScalpSoothing": {},
    "feedBeautyGoalSkinBarrier": "✨ Skin Barrier",
    "@feedBeautyGoalSkinBarrier": {},
    "feedBeautyTabRemedies": "Remedies",
    "@feedBeautyTabRemedies": {},
    "feedBeautyTabByActives": "By Actives",
    "@feedBeautyTabByActives": {},
    "feedBeautyTabCreators": "Beauty Creators",
    "@feedBeautyTabCreators": {},
    "feedBeautySearchHint": "Search a remedy, mask or active (Shea, Aloe...)",
    "@feedBeautySearchHint": {},
    "feedBeautySelectTitle": "Select a care item",
    "@feedBeautySelectTitle": {},
    "feedBeautyPageTitle": "Remedies & Care",
    "@feedBeautyPageTitle": {},
    "feedSelectRecipeTitle": "Select a recipe",
    "@feedSelectRecipeTitle": {},
  ```

- [ ] **Step 2: Mirror in `lib/l10n/app_fr.arb`.** Find:

  ```json
    "feedSearchHint": "Rechercher des recettes...",
  ```

  and replace with:

  ```json
    "feedSearchHint": "Rechercher des recettes...",
    "feedBeautyCategoryLabel": "Catégorie de Soin",
    "feedBeautyCategoryAll": "Toutes",
    "feedBeautyCategoryHair": "👑 Cheveux",
    "feedBeautyCategoryScalp": "🌿 Cuir Chevelu",
    "feedBeautyCategorySkin": "✨ Visage",
    "feedBeautyCategoryBody": "🧴 Corps",
    "feedBeautyFormulaLabel": "Type de Formule",
    "feedBeautyFormulaAll": "Toutes",
    "feedBeautyFormulaDiy": "🧪 Recette DIY",
    "feedBeautyFormulaArtisanal": "🌿 Artisanal",
    "feedBeautyFormulaIndustrial": "🏬 Commercial",
    "feedBeautyGoalLabel": "Objectif & Vertu",
    "feedBeautyGoalAll": "Tous",
    "feedBeautyGoalHairGrowth": "🌱 Pousse & Longueur",
    "feedBeautyGoalAntiBreakage": "🛡️ Force Anti-Casse",
    "feedBeautyGoalMoisture": "💧 Hydratation",
    "feedBeautyGoalScalpSoothing": "💆 Soin Apaisant",
    "feedBeautyGoalSkinBarrier": "✨ Barrière Cutanée",
    "feedBeautyTabRemedies": "Remèdes",
    "feedBeautyTabByActives": "Par Actifs",
    "feedBeautyTabCreators": "Créateurs Beauté",
    "feedBeautySearchHint": "Rechercher un remède, masque ou actif (Karité, Aloé...)",
    "feedBeautySelectTitle": "Sélectionner un soin",
    "feedBeautyPageTitle": "Remèdes & Soins",
    "feedSelectRecipeTitle": "Sélectionner une recette",
  ```

- [ ] **Step 3: Replace the hardcoded strings in `lib/features/recipes/feed_page.dart`.**

  Replace the Beauty filter sheet's category group:
  ```dart
                      Text('Catégorie de Soin', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Toutes'),
                            selected: tempCategory == null,
                            onSelected: (v) => setModalState(() => tempCategory = null),
                          ),
                          ChoiceChip(
                            label: const Text('👑 Cheveux'),
                            selected: tempCategory == 'hair',
                            onSelected: (v) => setModalState(() => tempCategory = 'hair'),
                          ),
                          ChoiceChip(
                            label: const Text('🌿 Cuir Chevelu'),
                            selected: tempCategory == 'scalp',
                            onSelected: (v) => setModalState(() => tempCategory = 'scalp'),
                          ),
                          ChoiceChip(
                            label: const Text('✨ Visage'),
                            selected: tempCategory == 'skin',
                            onSelected: (v) => setModalState(() => tempCategory = 'skin'),
                          ),
                          ChoiceChip(
                            label: const Text('🧴 Corps'),
                            selected: tempCategory == 'body',
                            onSelected: (v) => setModalState(() => tempCategory = 'body'),
                          ),
                        ],
                      ),
  ```
  with:
  ```dart
                      Text(l10n.feedBeautyCategoryLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.feedBeautyCategoryAll),
                            selected: tempCategory == null,
                            onSelected: (v) => setModalState(() => tempCategory = null),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyCategoryHair),
                            selected: tempCategory == 'hair',
                            onSelected: (v) => setModalState(() => tempCategory = 'hair'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyCategoryScalp),
                            selected: tempCategory == 'scalp',
                            onSelected: (v) => setModalState(() => tempCategory = 'scalp'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyCategorySkin),
                            selected: tempCategory == 'skin',
                            onSelected: (v) => setModalState(() => tempCategory = 'skin'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyCategoryBody),
                            selected: tempCategory == 'body',
                            onSelected: (v) => setModalState(() => tempCategory = 'body'),
                          ),
                        ],
                      ),
  ```

  Replace the Beauty filter sheet's formula group:
  ```dart
                      Text('Type de Formule', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Toutes'),
                            selected: tempProductType == null,
                            onSelected: (v) => setModalState(() => tempProductType = null),
                          ),
                          ChoiceChip(
                            label: const Text('🧪 Recette DIY'),
                            selected: tempProductType == 'diy',
                            onSelected: (v) => setModalState(() => tempProductType = 'diy'),
                          ),
                          ChoiceChip(
                            label: const Text('🌿 Artisanal'),
                            selected: tempProductType == 'artisanal',
                            onSelected: (v) => setModalState(() => tempProductType = 'artisanal'),
                          ),
                          ChoiceChip(
                            label: const Text('🏬 Commercial'),
                            selected: tempProductType == 'industrial',
                            onSelected: (v) => setModalState(() => tempProductType = 'industrial'),
                          ),
                        ],
                      ),
  ```
  with:
  ```dart
                      Text(l10n.feedBeautyFormulaLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.feedBeautyFormulaAll),
                            selected: tempProductType == null,
                            onSelected: (v) => setModalState(() => tempProductType = null),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyFormulaDiy),
                            selected: tempProductType == 'diy',
                            onSelected: (v) => setModalState(() => tempProductType = 'diy'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyFormulaArtisanal),
                            selected: tempProductType == 'artisanal',
                            onSelected: (v) => setModalState(() => tempProductType = 'artisanal'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyFormulaIndustrial),
                            selected: tempProductType == 'industrial',
                            onSelected: (v) => setModalState(() => tempProductType = 'industrial'),
                          ),
                        ],
                      ),
  ```

  Replace the Beauty filter sheet's goal group:
  ```dart
                      Text('Objectif & Vertu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Tous'),
                            selected: tempGoal == null,
                            onSelected: (v) => setModalState(() => tempGoal = null),
                          ),
                          ChoiceChip(
                            label: const Text('🌱 Pousse & Longueur'),
                            selected: tempGoal == 'hair_growth',
                            onSelected: (v) => setModalState(() => tempGoal = 'hair_growth'),
                          ),
                          ChoiceChip(
                            label: const Text('🛡️ Force Anti-Casse'),
                            selected: tempGoal == 'anti_breakage',
                            onSelected: (v) => setModalState(() => tempGoal = 'anti_breakage'),
                          ),
                          ChoiceChip(
                            label: const Text('💧 Hydratation'),
                            selected: tempGoal == 'moisture',
                            onSelected: (v) => setModalState(() => tempGoal = 'moisture'),
                          ),
                          ChoiceChip(
                            label: const Text('💆 Soin Apaisant'),
                            selected: tempGoal == 'scalp_soothing',
                            onSelected: (v) => setModalState(() => tempGoal = 'scalp_soothing'),
                          ),
                          ChoiceChip(
                            label: const Text('✨ Barrière Cutanée'),
                            selected: tempGoal == 'skin_barrier',
                            onSelected: (v) => setModalState(() => tempGoal = 'skin_barrier'),
                          ),
                        ],
                      ),
  ```
  with:
  ```dart
                      Text(l10n.feedBeautyGoalLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.feedBeautyGoalAll),
                            selected: tempGoal == null,
                            onSelected: (v) => setModalState(() => tempGoal = null),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyGoalHairGrowth),
                            selected: tempGoal == 'hair_growth',
                            onSelected: (v) => setModalState(() => tempGoal = 'hair_growth'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyGoalAntiBreakage),
                            selected: tempGoal == 'anti_breakage',
                            onSelected: (v) => setModalState(() => tempGoal = 'anti_breakage'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyGoalMoisture),
                            selected: tempGoal == 'moisture',
                            onSelected: (v) => setModalState(() => tempGoal = 'moisture'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyGoalScalpSoothing),
                            selected: tempGoal == 'scalp_soothing',
                            onSelected: (v) => setModalState(() => tempGoal = 'scalp_soothing'),
                          ),
                          ChoiceChip(
                            label: Text(l10n.feedBeautyGoalSkinBarrier),
                            selected: tempGoal == 'skin_barrier',
                            onSelected: (v) => setModalState(() => tempGoal = 'skin_barrier'),
                          ),
                        ],
                      ),
  ```

  Replace the feed tabs / search hint / page title block:
  ```dart
      final isBeauty = appMode == AppMode.beauty;
      final feedTabs = isBeauty
          ? ['Remèdes', 'Par Actifs', 'Créateurs Beauté']
          : [l10n.feedTabRecipes, l10n.feedTabByIngredients, l10n.feedTabCreators];
      final searchHint = isBeauty
          ? 'Rechercher un remède, masque ou actif (Karité, Aloé...)'
          : l10n.feedSearchHint;
      final pageTitle = isBeauty
          ? (widget.swapEntryId != null ? 'Sélectionner un soin' : 'Remèdes & Soins')
          : (widget.swapEntryId != null ? 'Sélectionner une recette' : l10n.feedTabRecipes);
  ```
  with:
  ```dart
      final isBeauty = appMode == AppMode.beauty;
      final feedTabs = isBeauty
          ? [l10n.feedBeautyTabRemedies, l10n.feedBeautyTabByActives, l10n.feedBeautyTabCreators]
          : [l10n.feedTabRecipes, l10n.feedTabByIngredients, l10n.feedTabCreators];
      final searchHint = isBeauty ? l10n.feedBeautySearchHint : l10n.feedSearchHint;
      final pageTitle = isBeauty
          ? (widget.swapEntryId != null ? l10n.feedBeautySelectTitle : l10n.feedBeautyPageTitle)
          : (widget.swapEntryId != null ? l10n.feedSelectRecipeTitle : l10n.feedTabRecipes);
  ```

- [ ] **Step 4: Run `flutter gen-l10n`, then run `flutter analyze` on this file to confirm no unused-import or missing-symbol errors.**

  ```
  flutter gen-l10n
  dart analyze lib/features/recipes/feed_page.dart
  ```

  Expected output:
  ```
  Analyzing feed_page.dart...
  No issues found!
  ```

---

### Task 6f: l10n sweep — `batch_cooking_page.dart`, `meal_planner_page.dart`, `shopping_list_page.dart`

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (additive)
- Modify: `lib/features/meal_planner/batch_cooking_page.dart`, `lib/features/meal_planner/meal_planner_page.dart`, `lib/features/meal_planner/shopping_list_page.dart`

**New hardcoded strings found in this branch's diff:**
- `batch_cooking_page.dart`: `'Prep Soins Hebdomadaire'`.
- `meal_planner_page.dart`: `'Mon Plan de Routines'` (×2, both branches), `'Personnaliser la structure des soins'`.
- `shopping_list_page.dart`: `'Liste d\'Achat Produits & Actifs'`, `'Aucun actif ni produit dans votre liste. Ajoutez des soins depuis vos remèdes.'`.

- [ ] **Step 1: Add ARB keys.** In `lib/l10n/app_en.arb`, find:

  ```json
    "batchCookingTitle": "Batch Cooking",
    "@batchCookingTitle": {},
  ```

  and replace with:

  ```json
    "batchCookingTitle": "Batch Cooking",
    "@batchCookingTitle": {},
    "batchCookingBeautyTitle": "Weekly Care Prep",
    "@batchCookingBeautyTitle": {},
  ```

  Find:

  ```json
    "mealPlannerTitle": "Your Meals",
    "@mealPlannerTitle": {},
  ```

  and replace with:

  ```json
    "mealPlannerTitle": "Your Meals",
    "@mealPlannerTitle": {},
    "mealPlannerBeautyTitle": "My Routine Plan",
    "@mealPlannerBeautyTitle": {},
    "mealPlannerBeautyCustomizeTooltip": "Customize care structure",
    "@mealPlannerBeautyCustomizeTooltip": {},
  ```

  Find:

  ```json
    "shoppingListEmpty": "Your shopping list is empty",
    "@shoppingListEmpty": {},
  ```

  and replace with:

  ```json
    "shoppingListEmpty": "Your shopping list is empty",
    "@shoppingListEmpty": {},
    "shoppingListBeautyTitle": "Products & Actives Shopping List",
    "@shoppingListBeautyTitle": {},
    "shoppingListBeautyEmpty": "No actives or products in your list yet. Add care items from your remedies.",
    "@shoppingListBeautyEmpty": {},
  ```

- [ ] **Step 2: Mirror in `lib/l10n/app_fr.arb`.** Find:

  ```json
    "batchCookingTitle": "Cuisine en lot",
  ```

  and replace with:

  ```json
    "batchCookingTitle": "Cuisine en lot",
    "batchCookingBeautyTitle": "Prep Soins Hebdomadaire",
  ```

  Find:

  ```json
    "mealPlannerTitle": "Vos repas",
  ```

  and replace with:

  ```json
    "mealPlannerTitle": "Vos repas",
    "mealPlannerBeautyTitle": "Mon Plan de Routines",
    "mealPlannerBeautyCustomizeTooltip": "Personnaliser la structure des soins",
  ```

  Find:

  ```json
    "shoppingListEmpty": "Votre liste de courses est vide",
  ```

  and replace with:

  ```json
    "shoppingListEmpty": "Votre liste de courses est vide",
    "shoppingListBeautyTitle": "Liste d'Achat Produits & Actifs",
    "shoppingListBeautyEmpty": "Aucun actif ni produit dans votre liste. Ajoutez des soins depuis vos remèdes.",
  ```

- [ ] **Step 3: Replace the hardcoded string in `lib/features/meal_planner/batch_cooking_page.dart`.** Replace:

  ```dart
      final title = isBeauty ? 'Prep Soins Hebdomadaire' : l10n.batchCookingTitle;
  ```
  with:
  ```dart
      final title = isBeauty ? l10n.batchCookingBeautyTitle : l10n.batchCookingTitle;
  ```

- [ ] **Step 4: Replace the hardcoded strings in `lib/features/meal_planner/meal_planner_page.dart`.** Replace the Beauty early-return branch's title:

  ```dart
      if (appMode == AppMode.beauty) {
        return Scaffold(
          backgroundColor: AkeliColors.surface,
          appBar: AppBar(
            title: Text(
              'Mon Plan de Routines',
  ```
  with:
  ```dart
      if (appMode == AppMode.beauty) {
        return Scaffold(
          backgroundColor: AkeliColors.surface,
          appBar: AppBar(
            title: Text(
              l10n.mealPlannerBeautyTitle,
  ```

  Replace the Nutrition-branch title variable and the customize tooltip:
  ```dart
            final title = isBeauty ? 'Mon Plan de Routines' : l10n.mealPlannerTitle;
  ```
  with:
  ```dart
            final title = isBeauty ? l10n.mealPlannerBeautyTitle : l10n.mealPlannerTitle;
  ```

  ```dart
                          tooltip: isBeauty ? 'Personnaliser la structure des soins' : l10n.mealScheduleCustomizeButton,
  ```
  with:
  ```dart
                          tooltip: isBeauty ? l10n.mealPlannerBeautyCustomizeTooltip : l10n.mealScheduleCustomizeButton,
  ```

- [ ] **Step 5: Replace the hardcoded strings in `lib/features/meal_planner/shopping_list_page.dart`.** Replace:

  ```dart
      final title = isBeauty ? 'Liste d\'Achat Produits & Actifs' : l10n.shoppingListTitle;
      final emptySubtitle = isBeauty
          ? 'Aucun actif ni produit dans votre liste. Ajoutez des soins depuis vos remèdes.'
          : l10n.shoppingListEmpty;
  ```
  with:
  ```dart
      final title = isBeauty ? l10n.shoppingListBeautyTitle : l10n.shoppingListTitle;
      final emptySubtitle = isBeauty ? l10n.shoppingListBeautyEmpty : l10n.shoppingListEmpty;
  ```

- [ ] **Step 6: Run `flutter gen-l10n`, then run `flutter analyze` on all three files.**

  ```
  flutter gen-l10n
  dart analyze lib/features/meal_planner/batch_cooking_page.dart lib/features/meal_planner/meal_planner_page.dart lib/features/meal_planner/shopping_list_page.dart
  ```

  Expected output:
  ```
  Analyzing batch_cooking_page.dart, meal_planner_page.dart, shopping_list_page.dart...
  No issues found!
  ```

---

### Task 6g: Final l10n verification — `flutter gen-l10n` + `flutter analyze`

**Files:** none (verification only).

- [ ] **Step 1: Regenerate localizations from the final ARB state.**

  ```
  flutter gen-l10n
  ```

  Expected output: no errors (silent success or a short generation summary; a non-zero exit code here means an ARB key was added to only one of the two files — re-check Tasks 6a–6f for a key present in `app_en.arb` but missing from `app_fr.arb` or vice versa).

- [ ] **Step 2: Run `flutter analyze` scoped to the directories this plan touched.**

  ```
  flutter analyze lib/features/ lib/shared/ lib/widgets/
  ```

  Expected output:
  ```
  Analyzing features, shared, widgets...
  No issues found!
  ```

  If pre-existing issues unrelated to this plan's 19 owned files appear (e.g. from Areas F/G's beauty-only widgets), confirm via `git diff --stat` that none of the reported files were touched by this plan before treating them as out of scope.

- [ ] **Step 3: Run the full test suite for every file this plan touched, as a final regression pass.**

  ```
  flutter test test/features/settings/ test/features/ai_assistant/ test/features/profile/ test/features/recipes/ test/features/meal_planner/ test/features/auth/
  ```

  Expected output: `All tests passed!` with a count matching every test file created or already present under these directories (no failures, no compile errors).

---

### Task 7: Remove the unreachable "Month" segment from `meal_planner_view_toggle.dart`

**Files:**
- Modify: `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart`
- Test: `test/features/meal_planner/meal_planner_view_toggle_test.dart` (verify only — already has no Month-segment references to remove)

**Interfaces:** `MealPlannerViewToggle` keeps its `ConsumerWidget` signature (`value`, `onChanged`) and its `PlannerViewMode` day/week toggle behavior unchanged. Only the private `_segment(...)` call list and the now-unused `isBeauty` local are removed.

**Root cause:** `meal_planner_page.dart`'s Beauty branch returns `BeautyPlannerView()` directly from its own early `if (appMode == AppMode.beauty) { return Scaffold(...) }` block (see `meal_planner_page.dart:27-45`) — it never reaches the `NestedScrollView`/`MealPlannerViewToggle` widget tree at all. The Nutrition branch never sets `isBeauty` to true either. So `if (isBeauty) _segment('Mois 🗓️', ...)` can never render in either mode — it is dead code.

- [ ] **Step 1: Confirm the dead code and its blast radius with grep** (documents the "before" state):

  ```
  grep -n "PlannerViewMode.month\|planner-view-toggle-month\|isBeauty" lib/features/meal_planner/widgets/meal_planner_view_toggle.dart
  ```

  Expected output: 3 matches, all inside `meal_planner_view_toggle.dart` itself (no other file in the repo references `PlannerViewMode.month` or `planner-view-toggle-month`, confirmed via a repo-wide grep during plan authoring).

- [ ] **Step 2: Apply the fix.** Replace the full content of `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart` with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../../core/logger.dart';
  import '../../../core/theme.dart';
  import '../../../l10n/app_localizations.dart';
  import '../../../providers/meal_plan_provider.dart';
  import '../../../providers/mode_provider.dart';

  final _logger = appLogger;

  class MealPlannerViewToggle extends ConsumerWidget {
    final PlannerViewMode value;
    final ValueChanged<PlannerViewMode> onChanged;

    const MealPlannerViewToggle({
      super.key,
      required this.value,
      required this.onChanged,
    });

    void _select(PlannerViewMode mode) {
      if (mode == value) return;
      HapticFeedback.selectionClick();
      _logger.userAction('Planner view toggle changed', screen: 'MealPlannerPage',
          metadata: {'mode': mode.name});
      onChanged(mode);
    }

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final l10n = AppLocalizations.of(context);
      final appMode = ref.watch(currentModeProvider);
      final accentColor = getAppModeColor(appMode);

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _segment(l10n.plannerViewToggleDay, PlannerViewMode.day,
                const Key('planner-view-toggle-day'), accentColor),
            _segment(l10n.plannerViewToggleWeek, PlannerViewMode.week,
                const Key('planner-view-toggle-week'), accentColor),
          ],
        ),
      );
    }

    Widget _segment(String label, PlannerViewMode mode, Key key, Color accentColor) {
      final isActive = value == mode;
      return GestureDetector(
        key: key,
        onTap: () => _select(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AkeliRadius.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AkeliColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
  }
  ```

  (This removes the now-unused `mode_selector.dart` import along with the dead branch — it was only needed by the deleted Month segment's styling context, not by anything else in this file.)

- [ ] **Step 3: Confirm `test/features/meal_planner/meal_planner_view_toggle_test.dart` needs no edits** — it already contains no `PlannerViewMode.month`/`planner-view-toggle-month` references (confirmed by reading the file during plan authoring: it only has "tapping Jour calls onChanged with day" and "tapping the already-active segment does not call onChanged"). No action needed here beyond re-running it in Step 4.

- [ ] **Step 4: Run the existing test file and confirm both tests still pass.**

  ```
  flutter test test/features/meal_planner/meal_planner_view_toggle_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

- [ ] **Step 5: Run `dart analyze` to confirm the removed `mode_selector.dart` import isn't needed elsewhere in this file.**

  ```
  dart analyze lib/features/meal_planner/widgets/meal_planner_view_toggle.dart
  ```

  Expected output:
  ```
  Analyzing meal_planner_view_toggle.dart...
  No issues found!
  ```

---

### Task 8: Cross-reference note — `health_profile_page_beauty_test.dart` coverage gap

**Files:** none (verification/documentation only — no code changes).

**Finding:** `test/features/settings/health_profile_page_beauty_test.dart` only ever pumps `HealthProfilePage` with `currentModeProvider` overridden to `AppMode.beauty` — structurally, it could never have caught Task 1's Nutrition-mode regression, no matter how thoroughly it asserted the Beauty form. This is not a bug in that test; it is a coverage gap: a per-mode test suite needs a test for *every* mode a shared page renders, not just the one that was hand-modified.

**Resolution:** naturally closed by Task 1, which adds `test/features/settings/health_profile_page_test.dart` asserting the Nutrition-mode render path. No new code is needed for this finding specifically — this task exists only to make the resolution explicit and independently verifiable.

- [ ] **Step 1: Confirm both mode-specific test files exist side by side and both pass together** (this is the concrete, checkable artifact of "coverage gap closed"):

  ```
  ls test/features/settings/health_profile_page_test.dart test/features/settings/health_profile_page_beauty_test.dart
  flutter test test/features/settings/health_profile_page_test.dart test/features/settings/health_profile_page_beauty_test.dart
  ```

  Expected output:
  ```
  test/features/settings/health_profile_page_beauty_test.dart
  test/features/settings/health_profile_page_test.dart
  00:00 +2: All tests passed!
  ```

---

### Task 9: Gate onboarding's hardcoded Beauty defaults on the chosen mode

**Files:**
- Modify: `lib/features/auth/onboarding_data.dart` (add a new pure helper function)
- Modify: `lib/features/auth/onboarding_page.dart:94-158` (`_submit()`'s `body` map construction)
- Test: `test/features/auth/onboarding_data_test.dart` (new)

**Interfaces:**
- New top-level function in `onboarding_data.dart`: `Map<String, dynamic> beautyOnboardingFields(OnboardingData d, AppMode mode)` — returns `{}` when `mode != AppMode.beauty`, otherwise returns the 6 beauty keys (`hair_type`, `porosity`, `skin_type`, `sensitive_scalp`, `beauty_goals`, `preferred_actives`) exactly as `_submit()` builds them today.
- `_OnboardingPageState._submit()` — no signature change; its `body` map now spreads `beautyOnboardingFields(d, currentMode)` instead of unconditionally listing the 6 beauty keys.

**Root cause:** every Nutrition-mode signup silently submits `hair_type: '4C'`, `porosity: 'medium'`, `skin_type: 'combination'`, `sensitive_scalp: false`, `beauty_goals: []`, `preferred_actives: []` to `complete-onboarding` regardless of which mode the user actually chose, because `_submit()`'s `body` map lists these 6 keys unconditionally. Extracting the gating into a pure, directly-unit-testable function (rather than driving the full 8-step onboarding `PageView` in a widget test) keeps this fix fast and deterministic.

- [ ] **Step 1: Write the failing test.** Create `test/features/auth/onboarding_data_test.dart`:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/features/auth/onboarding_data.dart';
  import 'package:akeli/providers/mode_provider.dart';

  void main() {
    group('beautyOnboardingFields', () {
      test('omits hair/skin/porosity fields for a Nutrition-mode signup', () {
        const data = OnboardingData(name: 'Test User');

        final body = beautyOnboardingFields(data, AppMode.nutrition);

        expect(body.containsKey('hair_type'), isFalse);
        expect(body.containsKey('porosity'), isFalse);
        expect(body.containsKey('skin_type'), isFalse);
        expect(body.containsKey('sensitive_scalp'), isFalse);
        expect(body.containsKey('beauty_goals'), isFalse);
        expect(body.containsKey('preferred_actives'), isFalse);
        expect(body, isEmpty);
      });

      test('includes hair/skin/porosity fields for a Beauty-mode signup', () {
        const data = OnboardingData(
          name: 'Test User',
          hairType: '4C',
          porosity: 'medium',
          skinType: 'combination',
          sensitiveScalp: true,
          beautyGoals: ['hair_growth'],
          preferredActives: ['shea_butter'],
        );

        final body = beautyOnboardingFields(data, AppMode.beauty);

        expect(body['hair_type'], '4C');
        expect(body['porosity'], 'medium');
        expect(body['skin_type'], 'combination');
        expect(body['sensitive_scalp'], true);
        expect(body['beauty_goals'], ['hair_growth']);
        expect(body['preferred_actives'], ['shea_butter']);
      });
    });
  }
  ```

- [ ] **Step 2: Run the test and confirm it fails to compile against the current code** (`beautyOnboardingFields` does not exist yet):

  ```
  flutter test test/features/auth/onboarding_data_test.dart
  ```

  Expected output:
  ```
  Error: Method not found: 'beautyOnboardingFields'.
  ...
  Compilation failed.
  ```

- [ ] **Step 3: Apply the fix — add the helper to `onboarding_data.dart`.** Add this import to the top of `lib/features/auth/onboarding_data.dart`:

  ```dart
  import 'package:akeli/providers/mode_provider.dart';
  ```

  Then add this top-level function anywhere after the imports (e.g. immediately above `class OnboardingData`):

  ```dart
  /// Beauty-diagnostic fields to submit to `complete-onboarding`.
  /// Returns an empty map for Nutrition-mode signups — the placeholder
  /// defaults on [OnboardingData] (hairType/porosity/skinType etc.) must
  /// never be written for a user who never went through the Beauty
  /// diagnostic. Real Beauty values are captured later by
  /// `BeautyOnboardingPage` and submitted via `complete-beauty-onboarding`;
  /// this only concerns the initial Nutrition-flow submission.
  Map<String, dynamic> beautyOnboardingFields(OnboardingData d, AppMode mode) {
    if (mode != AppMode.beauty) return const {};
    return {
      'hair_type': d.hairType,
      'porosity': d.porosity,
      'skin_type': d.skinType,
      'sensitive_scalp': d.sensitiveScalp,
      'beauty_goals': d.beautyGoals,
      'preferred_actives': d.preferredActives,
    };
  }
  ```

- [ ] **Step 4: Apply the fix — use the helper in `onboarding_page.dart`.** Add this import to the top of `lib/features/auth/onboarding_page.dart`:

  ```dart
  import '../../providers/mode_provider.dart';
  ```

  In `_submit()`, replace:

  ```dart
      final d = ref.read(onboardingProvider);
      final client = ref.read(supabaseClientProvider);
      final now = DateTime.now().toUtc().toIso8601String();
  ```

  with:

  ```dart
      final d = ref.read(onboardingProvider);
      final currentMode = ref.read(currentModeProvider);
      final client = ref.read(supabaseClientProvider);
      final now = DateTime.now().toUtc().toIso8601String();
  ```

  Then replace the `body` map's tail:

  ```dart
        if (d.consentPrivacy) 'consent_privacy_at': now,
        if (d.consentCgu) 'consent_cgu_at': now,
        'hair_type': d.hairType,
        'porosity': d.porosity,
        'skin_type': d.skinType,
        'sensitive_scalp': d.sensitiveScalp,
        'beauty_goals': d.beautyGoals,
        'preferred_actives': d.preferredActives,
      };
  ```

  with:

  ```dart
        if (d.consentPrivacy) 'consent_privacy_at': now,
        if (d.consentCgu) 'consent_cgu_at': now,
        ...beautyOnboardingFields(d, currentMode),
      };
  ```

- [ ] **Step 5: Re-run the test and confirm it passes.**

  ```
  flutter test test/features/auth/onboarding_data_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

- [ ] **Step 6: Run `dart analyze` on both modified files to confirm the new import and call site are clean.**

  ```
  dart analyze lib/features/auth/onboarding_data.dart lib/features/auth/onboarding_page.dart
  ```

  Expected output:
  ```
  Analyzing onboarding_data.dart, onboarding_page.dart...
  No issues found!
  ```

---

## Coverage Checklist

| # | Finding | Severity | Task(s) | Files touched |
|---|---|---|---|---|
| 1 | `health_profile_page.dart` Nutrition-mode form/validation deleted + US blank-height bug | Critical | Task 1 (fix), Task 6b (l10n) | `lib/features/settings/health_profile_page.dart`, `test/features/settings/health_profile_page_test.dart` |
| 2 | `meal_schedule_page.dart` reachable in Beauty mode with 100% nutrition content | Critical | Task 2 | `lib/features/settings/settings_page.dart`, `test/features/settings/settings_page_meal_schedule_navigation_test.dart` |
| 3 | `ai_chat_page.dart` sends no mode flag; edge function ignores it | Critical | Task 3 (Dart fix), Task 6c (l10n) | `lib/features/ai_assistant/ai_chat_page.dart`, `test/features/ai_assistant/ai_chat_page_test.dart` |
| 4 | `profile_page.dart` liked-recipes tab mixes modes | High | Task 4 (fix), Task 6d (l10n) | `lib/features/profile/profile_page.dart`, `test/features/profile/profile_page_test.dart` |
| 5 | `saved_recipes_page.dart` saved-recipes mixes modes | High | Task 5 (fix), Task 6d (l10n) | `lib/features/recipes/saved_recipes_page.dart`, `test/features/recipes/saved_recipes_page_test.dart` |
| 6 | Systemic l10n gap across 14 of the 19 owned files (~80 new hardcoded strings; `home_page.dart`, `nutrition_page.dart`, `onboarding_data.dart`, `onboarding_page.dart`, `meal_planner_view_toggle.dart` needed none) | High (cross-cutting) | Tasks 6a–6g | `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `settings_page.dart`, `preferences_page.dart`, `meal_schedule_page.dart`, `health_profile_page.dart`, `ai_chat_page.dart`, `support_page.dart`, `nutrition_plan_page.dart`, `profile_page.dart`, `saved_recipes_page.dart`, `community_page.dart`, `feed_page.dart`, `batch_cooking_page.dart`, `meal_planner_page.dart`, `shopping_list_page.dart` |
| 7 | `meal_planner_view_toggle.dart`'s "Month" segment is dead code | Medium | Task 7 | `lib/features/meal_planner/widgets/meal_planner_view_toggle.dart` |
| 8 | `health_profile_page_beauty_test.dart` structurally can't catch a Nutrition-mode regression | Medium | Task 8 (resolved by Task 1; verification-only) | none (verification) |
| 9 | `onboarding_page.dart`/`onboarding_data.dart` write hardcoded Beauty defaults regardless of chosen mode | Low | Task 9 | `lib/features/auth/onboarding_data.dart`, `lib/features/auth/onboarding_page.dart`, `test/features/auth/onboarding_data_test.dart` |

**Unassigned follow-up work flagged to the user (explicitly out of scope for this plan):**
- `lib/providers/profile_tabs_provider.dart` — `userLikedRecipesProvider`/`userSavedRecipesProvider` should filter by `recipe.mode` server-side (`.eq('recipe.mode', ...)`) instead of relying on Tasks 4/5's client-side stopgap filters in `profile_page.dart`/`saved_recipes_page.dart`.
- `supabase/functions/ai-assistant-chat/index.ts` — must read the new `mode` field (sent as of Task 3) from the request body and select a beauty-appropriate system prompt instead of the current hardcoded nutrition-only `SYSTEM_PROMPT`. Until this ships, Beauty-mode users get correctly-labeled UI talking to a nutrition-only assistant.
- `health_profile_page.dart`'s Beauty-form *option values* (hair type, porosity, skin type, skin concerns, beauty goals — see Task 6b's scope note) are not localized: they are stored verbatim as data values consumed by `health_profile_model.dart` and the Python vectorization spectrum matcher (Area D). Fully localizing them requires a coordinated code/label split across the DB column, the Dart model, and the Python spectra — out of scope for a Dart-only l10n sweep.

## Self-Review Notes

- **Placeholder scan:** no "TBD", no "add appropriate error handling", no "handle edge cases", no "similar to Task N" appears anywhere above; every step that changes code shows the exact before/after Dart or JSON.
- **Route/name consistency:** `AkeliRoutes.mealSchedule` / `AkeliRoutes.mealPlanner` / `AkeliRoutes.settings` (Task 2), `currentModeProvider` / `AppMode.beauty` / `AppMode.nutrition` (all tasks), `userLikedRecipesProvider` / `userSavedRecipesProvider` (Tasks 4/5, matching the READ-ONLY `profile_tabs_provider.dart` reference), and every new ARB key name (`settingsBeauty*`, `healthBeauty*`, `feedBeauty*`, etc.) are used identically between the ARB-insertion steps and the Dart call-site steps within each task.
