import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/widgets/akeli_gradient_button.dart';
import 'onboarding_data.dart';
import '../../core/logger.dart';
import '../nutrition_plan/nutrition_plan_page.dart';
import '../settings/widgets/allergen_picker_widget.dart';
import '../settings/widgets/intensity_badge.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  final GlobalKey<NutritionPlanPageState> _nutritionPlanKey = GlobalKey<NutritionPlanPageState>();
  int _currentStep = 0;
  static const int _totalSteps = 7;
  static const int _nutritionPlanStep = 5;
  bool _isSubmitting = false;
  final _logger = appLogger;

  @override
  void dispose() {
    _logger.provider('_OnboardingPageState disposed');
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    _logger.userAction('Onboarding next tapped', screen: 'OnboardingPage', metadata: {'step': _currentStep});
    final notifier = ref.read(onboardingProvider.notifier);
    if (!notifier.canAdvance(_currentStep)) {
      const messages = {
        1: 'Veuillez accepter les deux conditions pour continuer.',
        2: 'Veuillez entrer votre prénom pour continuer.',
        3: 'Veuillez entrer votre poids cible pour continuer.',
      };
      final msg = messages[_currentStep];
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _back() {
    _logger.userAction('Onboarding back tapped', screen: 'OnboardingPage', metadata: {'step': _currentStep});
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _saveNutritionPlanAndNext() async {
    final state = _nutritionPlanKey.currentState;
    if (state != null) {
      setState(() => _isSubmitting = true);
      await state.savePlan();
      if (mounted) setState(() => _isSubmitting = false);
    } else {
      _next();
    }
  }

  Future<void> _submit() async {
    _logger.userAction('Onboarding submitted', screen: 'OnboardingPage', metadata: {'step': _currentStep});
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _isSubmitting = true);

    final d = ref.read(onboardingProvider);
    final client = ref.read(supabaseClientProvider);
    final now = DateTime.now().toUtc().toIso8601String();

    // Approximate birth_date from age (Jan 1 of birth year)
    final birthDate = d.age != null
        ? '${DateTime.now().year - d.age!}-01-01'
        : null;

    final restrictions = <String>[
      if (d.noPork) 'no_pork',
      if (d.noMeat) 'no_meat',
      if (d.noGluten) 'no_gluten',
      if (d.noLactose) 'no_lactose',
    ];

    // Build goal_type set from the user's explicit onboarding selections.
    // "health" is always included as a baseline.
    final goalSet = <String>{'health'};
    if (d.weightGoal == 'loss') goalSet.add('weight_loss');
    if (d.weightGoal == 'gain') goalSet.add('muscle_gain');
    if (d.weightGoal == 'maintenance') goalSet.add('maintenance');
    if (d.muscleGoal == 'gain') goalSet.add('muscle_gain');
    if (d.muscleGoal == 'loss') goalSet.add('weight_loss');
    if (d.muscleGoal == 'maintenance') goalSet.add('maintenance');
    final inferredGoals = goalSet.toList();

    final body = <String, dynamic>{
      'first_name': d.name,
      if (d.sex != null) 'sex': d.sex,
      if (birthDate != null) 'birth_date': birthDate,
      if (d.height != null) 'height_cm': d.height,
      if (d.weight != null) 'weight_kg': d.weight,
      if (d.targetWeight != null) 'target_weight_kg': d.targetWeight,
      if (d.activityLevel != null) 'activity_level': d.activityLevel,
      'goals': inferredGoals,
      if (d.weightGoal != null) 'weight_goal': d.weightGoal,
      if (d.muscleGoal != null) 'muscle_goal': d.muscleGoal,
      if (d.cookingTime != null) 'cooking_time': d.cookingTime,
      'batch_cooking_enabled': d.batchCookingEnabled,
      'batch_cooking_max_portions': d.batchMaxPortions,
      'dietary_restrictions': restrictions,
      'selectedAllergenIds': d.allergens.map((a) => a.id).toList(),
      'cuisine_preferences': d.cuisinePreferences,
      if (d.consentPrivacy) 'consent_privacy_at': now,
      if (d.consentCgu) 'consent_cgu_at': now,
    };

    try {
      _logger.edge('complete-onboarding', 'BEFORE | userId: ${LogHelper.maskUuid(user.id)}');
      await client.functions.invoke('complete-onboarding', body: body);
      _logger.edge('complete-onboarding', 'AFTER | success');
      ref.invalidate(userProfileProvider);
      // Fire-and-forget: generate first meal plan in background while navigating home.
      // The meal planner page handles loading/empty state while generation completes.
      _logger.edge('generate-meal-plan', 'BEFORE (post-onboarding) | non-blocking');
      client.functions.invoke('generate-meal-plan', body: {
        'days': 7,
        'meals_per_day': 3,
      }).then((_) {
        _logger.edge('generate-meal-plan', 'AFTER (post-onboarding) | success');
      }).catchError((Object e) {
        _logger.edge('generate-meal-plan', 'ERROR (post-onboarding) | $e');
      });
      if (mounted) context.go(AkeliRoutes.home);
    } catch (e, st) {
      _logger.edge('complete-onboarding', 'ERROR | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erreur de synchronisation. Vos données peuvent être complétées depuis votre profil.',
            ),
          ),
        );
        context.go(AkeliRoutes.home);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('OnboardingPageState build() | step: $_currentStep');
    return Scaffold(
      backgroundColor: AkeliColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingHeader(
              step: _currentStep,
              totalSteps: _totalSteps,
              onBack: _currentStep > 0 ? _back : null,
              onSkip: () {
                _logger.userAction('Onboarding skipped', screen: 'OnboardingPage', metadata: {'step': _currentStep});
                context.go(AkeliRoutes.home);
              },
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  _logger.provider('OnboardingPageState step → $i');
                  setState(() => _currentStep = i);
                },
                children: [
                  _StepLanguage(step: _currentStep),
                  _StepConsent(step: _currentStep),
                  _StepProfile(step: _currentStep),
                  _StepGoals(step: _currentStep),
                  _StepPreferences(step: _currentStep),
                  NutritionPlanPage(
                    key: _nutritionPlanKey,
                    isOnboarding: true,
                    onCompleted: _next,
                  ),
                  _StepSummary(step: _currentStep),
                ],
              ),
            ),
            _OnboardingBottomBar(
              step: _currentStep,
              totalSteps: _totalSteps,
              onBack: _currentStep > 0 ? _back : null,
              onNext: _currentStep == _nutritionPlanStep ? _saveNutritionPlanAndNext : _next,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header with progress bar ─────────────────────────────────────────────────

class _OnboardingHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const _OnboardingHeader({
    required this.step,
    required this.totalSteps,
    this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / totalSteps;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AkeliColors.primary,
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'AKELI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AkeliColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Passer',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.primary,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.lg),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Étape ${step + 1} sur $totalSteps',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.08),
                  ),
                  Text(
                    '${((progress) * 100).round()}%',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AkeliColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AkeliRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AkeliColors.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AkeliColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AkeliSpacing.md),
      ],
    );
  }
}

// ── Bottom Navigation Bar ────────────────────────────────────────────────────

class _OnboardingBottomBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool isLoading;

  const _OnboardingBottomBar({
    required this.step,
    required this.totalSteps,
    this.onBack,
    required this.onNext,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AkeliSpacing.lg, AkeliSpacing.md, AkeliSpacing.lg, AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
              color: AkeliColors.outlineVariant.withValues(alpha: 0.2),
              width: 1),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AkeliColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AkeliRadius.xl),
                  ),
                  child: Center(
                    child: Text(
                      'Précédent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.primaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AkeliSpacing.md),
          ],
          Expanded(
            flex: onBack != null ? 2 : 1,
            child: AkeliGradientButton(
              label: isLast ? "Commencer l'aventure" : 'Suivant',
              onPressed: isLoading ? null : onNext,
              isLoading: isLoading,
              trailing: isLast
                  ? null
                  : const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card wrapper ──────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  
  const _StepCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B1C16),
            blurRadius: 48,
            offset: Offset(0, 24),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(AkeliSpacing.lg),
      child: child,
    );
  }
}

// ── Step 1: Language ─────────────────────────────────────────────────────────

class _StepLanguage extends ConsumerWidget {
  final int step;
  const _StepLanguage({required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisir votre langue',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AkeliColors.onSurface,
              letterSpacing: -0.02,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            "Veuillez sélectionner la langue de l'interface.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LANGUE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AkeliRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AkeliSpacing.md),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: data.language,
                      isExpanded: true,
                      style: GoogleFonts.inter(
                          fontSize: 16, color: AkeliColors.onSurface),
                      dropdownColor: AkeliColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AkeliRadius.md),
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          appLogger.userAction('Language selected', screen: 'OnboardingPage', metadata: {'language': v});
                          notifier.updateLanguage(v);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Consent ──────────────────────────────────────────────────────────

class _StepConsent extends ConsumerStatefulWidget {
  final int step;
  const _StepConsent({required this.step});

  @override
  ConsumerState<_StepConsent> createState() => _StepConsentState();
}

class _StepConsentState extends ConsumerState<_StepConsent> {
  final _logger = appLogger;
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _cguRecognizer;

  @override
  void initState() {
    super.initState();
    _logger.provider('_StepConsentState initState');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AkeliRoutes.privacyPolicy);
    _cguRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AkeliRoutes.termsOfService);
  }

  @override
  void dispose() {
    _logger.provider('_StepConsentState disposed');
    _privacyRecognizer.dispose();
    _cguRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue sur Akeli',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AkeliColors.primary,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            "Avant de plonger dans l'expérience, prenons un instant pour clarifier la protection de votre vie privée.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.lg, 0),
                  child: Column(
                    children: [
                      _ConsentSection(
                        title: 'Données collectées',
                        items: [
                          ('Identité et contact :', "Nom, prénom et adresse email pour sécuriser votre compte."),
                          ("Usage de l'application :", "Statistiques anonymes pour améliorer votre expérience quotidienne."),
                        ],
                      ),
                      SizedBox(height: AkeliSpacing.lg),
                      _ConsentSection(
                        title: 'Vos droits',
                        items: [
                          ('Accès total :', "Consultez, modifiez ou exportez vos données à tout moment depuis les paramètres."),
                          ("Droit à l'oubli :", "Suppression définitive de votre compte et de vos données sur simple demande."),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AkeliSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AkeliSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AkeliColors.surfaceContainerLow,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AkeliRadius.xl),
                      bottomRight: Radius.circular(AkeliRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      _ConsentCheckbox(
                        value: data.consentPrivacy,
                        onChanged: (v) =>
                            notifier.updateConsent(privacy: v),
                        label: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AkeliColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: "J'accepte la "),
                              TextSpan(
                                text: "Politique de Confidentialité",
                                style: const TextStyle(
                                  color: AkeliColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: _privacyRecognizer,
                              ),
                              const TextSpan(text: " et confirme avoir lu les informations concernant le traitement de mes données personnelles (RGPD)."),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AkeliSpacing.md),
                      _ConsentCheckbox(
                        value: data.consentCgu,
                        onChanged: (v) =>
                            notifier.updateConsent(cgu: v),
                        label: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AkeliColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: "J'accepte les "),
                              TextSpan(
                                text: "Conditions Générales d'Utilisation (CGU)",
                                style: const TextStyle(
                                  color: AkeliColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: _cguRecognizer,
                              ),
                              const TextSpan(text: " d'Akeli."),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentSection extends StatelessWidget {
  final String title;
  final List<(String, String)> items;

  const _ConsentSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AkeliColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.info_outline,
                    color: AkeliColors.onSecondaryContainer, size: 20),
              ),
            ),
            const SizedBox(width: AkeliSpacing.sm),
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurface)),
          ],
        ),
        const SizedBox(height: AkeliSpacing.md),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AkeliColors.primary, size: 18),
                  const SizedBox(width: AkeliSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AkeliColors.onSurfaceVariant),
                        children: [
                          TextSpan(
                              text: item.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AkeliColors.onSurface)),
                          TextSpan(text: ' ${item.$2}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;

  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appLogger.userAction('Consent checkbox toggled', screen: 'OnboardingPage', metadata: {'checked': !value});
        onChanged(!value);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AkeliColors.primary : AkeliColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AkeliColors.primary : AkeliColors.outlineVariant,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: label,
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Profile ──────────────────────────────────────────────────────────

class _StepProfile extends ConsumerStatefulWidget {
  final int step;
  const _StepProfile({required this.step});
  @override
  ConsumerState<_StepProfile> createState() => _StepProfileState();
}

class _StepProfileState extends ConsumerState<_StepProfile> {
  final _logger = appLogger;
  late final TextEditingController _nameCtrl;

  static const _activities = [
    ('sedentary', 'Sédentaire',
        "Travail de bureau, peu ou pas d'exercice quotidien.", Icons.weekend_rounded),
    ('light', 'Légère',
        "1-3 jours/semaine d'exercice léger.", Icons.directions_walk_rounded),
    ('moderate', 'Modérée',
        '3-5 jours/semaine.', Icons.directions_run_rounded),
    ('active', 'Active',
        '6-7 jours/semaine.', Icons.fitness_center_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: ref.read(onboardingProvider).name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('_StepProfileState build()');
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre profil',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.02)),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comment vous appelez-vous ?',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AkeliColors.onSurface)),
                const SizedBox(height: AkeliSpacing.sm),
                TextField(
                  controller: _nameCtrl,
                  onChanged: (v) => notifier.updateProfile(name: v),
                  decoration: InputDecoration(
                    hintText: 'Prénom ou surnom',
                    filled: true,
                    fillColor: AkeliColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.sm),
                        borderSide: BorderSide.none),
                  ),
                  style: GoogleFonts.inter(
                      fontSize: 16, color: AkeliColors.onSurface),
                ),
                const SizedBox(height: AkeliSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quel est votre âge ?',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface)),
                          const SizedBox(height: AkeliSpacing.sm),
                          _MetricField(
                            value: data.age?.toString() ?? '',
                            suffix: 'ans',
                            onChanged: (v) => notifier.updateProfile(
                                age: int.tryParse(v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AkeliSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sexe biologique',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface)),
                          const SizedBox(height: AkeliSpacing.sm),
                          _SexSegment(
                            value: data.sex,
                            onChanged: (v) =>
                                notifier.updateProfile(sex: v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Poids',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface)),
                          const SizedBox(height: AkeliSpacing.sm),
                          _MetricField(
                            value: data.weight?.toString() ?? '',
                            suffix: 'kg',
                            onChanged: (v) => notifier.updateProfile(
                                weight: double.tryParse(v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AkeliSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Taille',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface)),
                          const SizedBox(height: AkeliSpacing.sm),
                          _MetricField(
                            value: data.height?.toString() ?? '',
                            suffix: 'cm',
                            onChanged: (v) => notifier.updateProfile(
                                height: double.tryParse(v)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.xl),
                Text("Niveau d'activité physique",
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AkeliColors.onSurface)),
                const SizedBox(height: AkeliSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AkeliSpacing.sm,
                  mainAxisSpacing: AkeliSpacing.sm,
                  childAspectRatio: 1.2,
                  children: _activities.map((a) {
                    final selected = data.activityLevel == a.$1;
                    return GestureDetector(
                      onTap: () {
                        _logger.userAction('Activity level selected', screen: 'OnboardingPage', metadata: {'level': a.$1});
                        notifier.updateProfile(activityLevel: a.$1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(AkeliSpacing.md),
                        decoration: BoxDecoration(
                          color: selected
                              ? AkeliColors.secondaryContainer.withValues(alpha: 0.4)
                              : AkeliColors.surface,
                          borderRadius: BorderRadius.circular(AkeliRadius.xl),
                          border: Border.all(
                            color: selected
                                ? AkeliColors.secondaryContainer
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(a.$4,
                                    color: selected
                                        ? AkeliColors.primary
                                        : AkeliColors.onSurfaceVariant,
                                    size: 28),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? AkeliColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? AkeliColors.primary
                                          : AkeliColors.outlineVariant,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: selected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 12)
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: AkeliSpacing.sm),
                            Text(a.$2,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AkeliColors.onSurface)),
                            Text(a.$3,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AkeliColors.onSurfaceVariant),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatefulWidget {
  final String value;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _MetricField({
    required this.value,
    required this.suffix,
    required this.onChanged,
  });

  @override
  State<_MetricField> createState() => _MetricFieldState();
}

class _MetricFieldState extends State<_MetricField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MetricField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AkeliRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface),
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              widget.suffix,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurfaceVariant,
                  letterSpacing: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SexSegment extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  const _SexSegment({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
      ),
      child: Row(
        children: [
          _SexOption(
              label: 'Femme',
              selected: value == 'female',
              onTap: () {
                appLogger.userAction('Sex selected', screen: 'OnboardingPage', metadata: {'sex': 'female'});
                onChanged('female');
              }),
          _SexOption(
              label: 'Homme',
              selected: value == 'male',
              onTap: () {
                appLogger.userAction('Sex selected', screen: 'OnboardingPage', metadata: {'sex': 'male'});
                onChanged('male');
              }),
        ],
      ),
    );
  }
}

class _SexOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SexOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? AkeliColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        color: Color(0x0F1B1C16),
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AkeliColors.primary
                    : AkeliColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step 4: Goals ────────────────────────────────────────────────────────────

class _StepGoals extends ConsumerStatefulWidget {
  final int step;
  const _StepGoals({required this.step});

  @override
  ConsumerState<_StepGoals> createState() => _StepGoalsState();
}

class _StepGoalsState extends ConsumerState<_StepGoals> {
  final _logger = appLogger;
  late final TextEditingController _motivationsCtrl;

  @override
  void initState() {
    super.initState();
    _motivationsCtrl = TextEditingController(
      text: ref.read(onboardingProvider).motivations,
    );
  }

  @override
  void dispose() {
    _motivationsCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_StepGoals old) {
    super.didUpdateWidget(old);
    final providerText = ref.read(onboardingProvider).motivations;
    if (providerText != _motivationsCtrl.text) {
      _motivationsCtrl.text = providerText;
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('_StepGoals build()');
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos objectifs',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.02)),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
              'Définissons ensemble ce que vous souhaitez accomplir.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AkeliSpacing.xl),

          // ── Weight goal ──────────────────────────────────────────────────
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OBJECTIF POIDS',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.md),
                _GoalRadioOption(
                  value: 'loss',
                  groupValue: data.weightGoal,
                  label: 'Perdre du poids',
                  icon: Icons.trending_down_rounded,
                  onChanged: (v) {
                    _logger.userAction('Weight goal selected',
                        screen: 'OnboardingPage', metadata: {'weightGoal': v});
                    notifier.updateGoals(weightGoal: v);
                  },
                ),
                _GoalRadioOption(
                  value: 'maintenance',
                  groupValue: data.weightGoal,
                  label: 'Maintenir mon poids',
                  icon: Icons.balance_rounded,
                  onChanged: (v) {
                    _logger.userAction('Weight goal selected',
                        screen: 'OnboardingPage', metadata: {'weightGoal': v});
                    notifier.updateGoals(weightGoal: v);
                  },
                ),
                _GoalRadioOption(
                  value: 'gain',
                  groupValue: data.weightGoal,
                  label: 'Prendre de la masse',
                  icon: Icons.trending_up_rounded,
                  onChanged: (v) {
                    _logger.userAction('Weight goal selected',
                        screen: 'OnboardingPage', metadata: {'weightGoal': v});
                    notifier.updateGoals(weightGoal: v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AkeliSpacing.lg),

          // ── Muscle goal ──────────────────────────────────────────────────
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OBJECTIF MUSCULAIRE',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.md),
                _GoalRadioOption(
                  value: 'loss',
                  groupValue: data.muscleGoal,
                  label: 'Réduire la masse musculaire',
                  icon: Icons.remove_circle_outline_rounded,
                  onChanged: (v) {
                    _logger.userAction('Muscle goal selected',
                        screen: 'OnboardingPage', metadata: {'muscleGoal': v});
                    notifier.updateGoals(muscleGoal: v);
                  },
                ),
                _GoalRadioOption(
                  value: 'maintenance',
                  groupValue: data.muscleGoal,
                  label: 'Maintenir mes muscles',
                  icon: Icons.fitness_center_rounded,
                  onChanged: (v) {
                    _logger.userAction('Muscle goal selected',
                        screen: 'OnboardingPage', metadata: {'muscleGoal': v});
                    notifier.updateGoals(muscleGoal: v);
                  },
                ),
                _GoalRadioOption(
                  value: 'gain',
                  groupValue: data.muscleGoal,
                  label: 'Développer mes muscles',
                  icon: Icons.add_circle_outline_rounded,
                  onChanged: (v) {
                    _logger.userAction('Muscle goal selected',
                        screen: 'OnboardingPage', metadata: {'muscleGoal': v});
                    notifier.updateGoals(muscleGoal: v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AkeliSpacing.lg),

          // ── Target weight + timeline ──────────────────────────────────────
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('POIDS CIBLE',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.md),
                _MetricField(
                  value: data.targetWeight?.toString() ?? '',
                  suffix: 'kg',
                  onChanged: (v) {
                    _logger.userAction('Target weight changed',
                        screen: 'OnboardingPage',
                        metadata: {'value': v});
                    if (v.isEmpty) {
                      notifier.clearTargetWeight();
                    } else {
                      notifier.updateGoals(targetWeight: double.tryParse(v));
                    }
                  },
                ),
                const SizedBox(height: AkeliSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DÉLAI ESTIMÉ',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                    IntensityBadge(
                      currentKg: data.weight,
                      targetKg: data.targetWeight,
                      months: data.timelineMonths.toDouble(),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.md),
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${data.timelineMonths} ',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: AkeliColors.primary,
                              height: 1),
                        ),
                        TextSpan(
                          text: 'mois',
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              color: AkeliColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AkeliColors.secondaryContainer,
                    inactiveTrackColor: AkeliColors.surfaceContainerHighest,
                    thumbColor: AkeliColors.surfaceContainerLowest,
                    overlayColor:
                        AkeliColors.primary.withValues(alpha: 0.1),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 14),
                    trackHeight: 10,
                  ),
                  child: Slider(
                    value: data.timelineMonths.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    onChanged: (v) {
                      _logger.userAction('Timeline months changed',
                          screen: 'OnboardingPage',
                          metadata: {'months': v.round()});
                      notifier.updateGoals(timelineMonths: v.round());
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 mois',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                    Text('12 mois',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.xl),
                Text('VOS MOTIVATIONS',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AkeliRadius.sm),
                  ),
                  child: TextField(
                    controller: _motivationsCtrl,
                    maxLines: 3,
                    onChanged: (v) {
                      _logger.userAction('Motivations changed',
                          screen: 'OnboardingPage');
                      notifier.updateGoals(motivations: v);
                    },
                    style: GoogleFonts.inter(
                        fontSize: 15, color: AkeliColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Qu\'est-ce qui vous motive ?',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: AkeliColors.onSurfaceVariant),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.all(AkeliSpacing.md),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AkeliSpacing.lg),

          // ── Cooking time ─────────────────────────────────────────────────
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TEMPS DE CUISINE',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.md),
                _GoalRadioOption(
                  value: 'quick',
                  groupValue: data.cookingTime,
                  label: 'Rapide (< 30 min)',
                  icon: Icons.bolt_rounded,
                  onChanged: (v) {
                    _logger.userAction('Cooking time selected',
                        screen: 'OnboardingPage', metadata: {'cookingTime': v});
                    notifier.updateGoals(cookingTime: v);
                  },
                ),
                _GoalRadioOption(
                  value: 'medium',
                  groupValue: data.cookingTime,
                  label: 'Moyen (30–60 min)',
                  icon: Icons.timer_outlined,
                  onChanged: (v) {
                    _logger.userAction('Cooking time selected',
                        screen: 'OnboardingPage', metadata: {'cookingTime': v});
                    notifier.updateGoals(cookingTime: v);
                  },
                ),
                _GoalRadioOption(
                  value: 'any',
                  groupValue: data.cookingTime,
                  label: 'Peu importe',
                  icon: Icons.all_inclusive_rounded,
                  onChanged: (v) {
                    _logger.userAction('Cooking time selected',
                        screen: 'OnboardingPage', metadata: {'cookingTime': v});
                    notifier.updateGoals(cookingTime: v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AkeliSpacing.lg),

          // ── Batch cooking ─────────────────────────────────────────────
          _StepCard(
            child: Consumer(
              builder: (context, ref, _) {
                final data = ref.watch(onboardingProvider);
                final notifier = ref.read(onboardingProvider.notifier);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CUISSON EN BATCH',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                    const SizedBox(height: AkeliSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Préparer plusieurs repas à la fois',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AkeliColors.onSurface)),
                              const SizedBox(height: 2),
                              Text('Cuire en grande quantité pour la semaine',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AkeliColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Switch(
                          value: data.batchCookingEnabled,
                          activeThumbColor: AkeliColors.primary,
                          onChanged: (v) {
                            _logger.userAction('Batch cooking toggled',
                                screen: 'OnboardingPage',
                                metadata: {'enabled': v});
                            notifier.updateGoals(batchCookingEnabled: v);
                          },
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: data.batchCookingEnabled
                          ? Padding(
                              key: const ValueKey('portions'),
                              padding: const EdgeInsets.only(top: AkeliSpacing.md),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Portions max par session',
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          color: AkeliColors.onSurface)),
                                  DropdownButton<int>(
                                    value: data.batchMaxPortions,
                                    underline: const SizedBox.shrink(),
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AkeliColors.primary),
                                    items: List.generate(6, (i) => i + 2)
                                        .map((n) => DropdownMenuItem(
                                              value: n,
                                              child: Text('$n'),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      _logger.userAction(
                                          'Batch max portions selected',
                                          screen: 'OnboardingPage',
                                          metadata: {'portions': v});
                                      notifier.updateGoals(batchMaxPortions: v);
                                    },
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('hidden')),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable radio row used inside _StepGoals sections.
class _GoalRadioOption extends StatelessWidget {
  final String value;
  final String? groupValue;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _GoalRadioOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: AkeliSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm + 2),
        decoration: BoxDecoration(
          color: selected
              ? AkeliColors.primaryContainer
              : AkeliColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AkeliRadius.sm),
          border: Border.all(
            color: selected ? AkeliColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? AkeliColors.primary
                    : AkeliColors.onSurfaceVariant),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? AkeliColors.onPrimaryContainer
                          : AkeliColors.onSurface)),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AkeliColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Step 5: Preferences ──────────────────────────────────────────────────────

class _StepPreferences extends ConsumerStatefulWidget {
  final int step;
  const _StepPreferences({required this.step});
  @override
  ConsumerState<_StepPreferences> createState() => _StepPreferencesState();
}

class _StepPreferencesState extends ConsumerState<_StepPreferences> {
  final _logger = appLogger;

  static const _kRegions = [
    ('west_africa',    'Afrique de l\'Ouest'),
    ('east_africa',    'Afrique de l\'Est'),
    ('north_africa',   'Afrique du Nord'),
    ('central_africa', 'Afrique Centrale'),
    ('south_africa',   'Afrique Australe'),
    ('caribbean',      'Caraïbes'),
    ('occidental',     'Occident'),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('_StepPreferencesState build()');
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos préférences',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.02)),
          const SizedBox(height: AkeliSpacing.sm),
          Text('Personnalisons votre expérience culinaire.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Régime alimentaire',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface)),
                const SizedBox(height: AkeliSpacing.md),
                _DietToggle(
                  icon: Icons.no_meals_rounded,
                  label: 'Sans Porc',
                  description: 'Exclure tous les plats contenant du porc',
                  value: data.noPork,
                  onChanged: (v) => notifier.updatePreferences(noPork: v),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                _DietToggle(
                  icon: Icons.eco_rounded,
                  label: 'Sans Viande',
                  description: 'Options végétariennes uniquement',
                  value: data.noMeat,
                  onChanged: (v) => notifier.updatePreferences(noMeat: v),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                _DietToggle(
                  icon: Icons.grain_rounded,
                  label: 'Sans Gluten',
                  description: 'Exclure le gluten de votre alimentation',
                  value: data.noGluten,
                  onChanged: (v) => notifier.updatePreferences(noGluten: v),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                _DietToggle(
                  icon: Icons.local_drink_outlined,
                  label: 'Sans Lactose',
                  description: 'Exclure les produits laitiers',
                  value: data.noLactose,
                  onChanged: (v) => notifier.updatePreferences(noLactose: v),
                ),
                const SizedBox(height: AkeliSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Allergies & Intolérances',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.onSurface)),
                        Text('Ajoutez les ingrédients à éviter.',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AkeliColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.md),
                AllergenPickerWidget(
                  selectedAllergens: data.allergens,
                  onChanged: (updated) {
                    notifier.updatePreferences(allergens: updated);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspirations Régionales',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface),
                ),
                const SizedBox(height: AkeliSpacing.xs),
                Text(
                  'Sélectionnez votre région de prédilection pour des recommandations ciblées.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AkeliColors.onSurfaceVariant),
                ),
                const SizedBox(height: AkeliSpacing.md),
                ..._kRegions.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: AkeliSpacing.xs),
                      child: _RegionTile(
                        label: r.$2,
                        selected: data.cuisinePreferences.isNotEmpty &&
                            data.cuisinePreferences[0] == r.$1,
                        onTap: () {
                          _logger.userAction('Region selected',
                              screen: 'OnboardingPage',
                              metadata: {'region': r.$1});
                          notifier.updateCuisineRegion(r.$1);
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DietToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DietToggle({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AkeliColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: AkeliColors.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface)),
                Text(description,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AkeliColors.onSurfaceVariant)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AkeliColors.primary,
            activeTrackColor: AkeliColors.secondaryContainer,
          ),
        ],
      ),
    );
  }
}

// ── Step 6: Summary ──────────────────────────────────────────────────────────

class _StepSummary extends ConsumerWidget {
  final int step;
  const _StepSummary({required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Récapitulatif',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.02)),
          const SizedBox(height: AkeliSpacing.sm),
          Text('Votre profil est prêt. Vérifions les détails avant de commencer.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AkeliSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: AkeliColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AkeliRadius.xl),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0F1B1C16),
                    blurRadius: 48,
                    offset: Offset(0, 24))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  top: -48,
                  right: -48,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AkeliColors.secondaryContainer.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AkeliSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AkeliColors.surfaceContainerHigh,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AkeliColors.surfaceContainerLowest,
                                  width: 3),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: AkeliColors.outline, size: 36),
                          ),
                          const SizedBox(width: AkeliSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.name.isNotEmpty ? data.name : 'Votre nom',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AkeliColors.onSurface),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: AkeliSpacing.xs,
                                  children: [
                                    if (data.age != null)
                                      _SummaryChip('${data.age} ans'),
                                    if (data.height != null)
                                      _SummaryChip('${data.height?.toInt()} cm'),
                                    if (data.weight != null)
                                      _SummaryChip('${data.weight?.toInt()} kg'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AkeliSpacing.lg),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AkeliSpacing.sm,
                        mainAxisSpacing: AkeliSpacing.sm,
                        childAspectRatio: 1.4,
                        children: [
                          _SummaryCard(
                            icon: Icons.directions_run_rounded,
                            title: "Niveau d'activité",
                            value: data.activityLevel ?? 'Non défini',
                          ),
                          _SummaryCard(
                            icon: Icons.flag_rounded,
                            title: 'Objectif poids',
                            value: data.targetWeight != null
                                ? '${data.targetWeight?.toInt()} kg'
                                : 'Non défini',
                            iconColor: AkeliColors.primary,
                          ),
                        ],
                      ),
                      if (data.noPork || data.noMeat || data.noGluten || data.noLactose) ...[
                        const SizedBox(height: AkeliSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AkeliSpacing.md),
                          decoration: BoxDecoration(
                            color: AkeliColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AkeliRadius.xl),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AkeliColors.tertiaryFixed.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.restaurant_rounded,
                                        size: 18),
                                  ),
                                  const SizedBox(width: AkeliSpacing.sm),
                                  Text('Préférences alimentaires',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AkeliColors.onSurface)),
                                ],
                              ),
                              const SizedBox(height: AkeliSpacing.sm),
                              Wrap(
                                spacing: AkeliSpacing.xs,
                                runSpacing: AkeliSpacing.xs,
                                children: [
                                  if (data.noPork)
                                    const _SummaryChip('Sans Porc'),
                                  if (data.noMeat)
                                    const _SummaryChip('Végétarien'),
                                  if (data.noGluten)
                                    const _SummaryChip('Sans Gluten'),
                                  if (data.noLactose)
                                    const _SummaryChip('Sans Lactose'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  const _SummaryChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AkeliColors.onSurfaceVariant)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor == Colors.transparent
                  ? AkeliColors.secondaryContainer
                  : iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: iconColor == Colors.transparent
                    ? AkeliColors.onSecondaryContainer
                    : iconColor,
                size: 18),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AkeliColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Region tile ──────────────────────────────────────────────────────────────

class _RegionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RegionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AkeliSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AkeliColors.secondaryContainer.withValues(alpha: 0.4)
              : AkeliColors.surface,
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          border: Border.all(
            color: selected
                ? AkeliColors.secondaryContainer
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.public_rounded,
              color: selected
                  ? AkeliColors.primary
                  : AkeliColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AkeliColors.onSurface,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? AkeliColors.primary
                  : AkeliColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
