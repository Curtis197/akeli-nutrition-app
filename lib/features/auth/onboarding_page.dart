import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/router.dart';
// import '../../core/supabase_client.dart'; // Removed Supabase
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  // Page 1 — Identity
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  // Page 2 — Body
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  String? _gender;

  // Page 3 — Goals & Activity
  String? _primaryGoal;
  String? _activityLevel;

  // Page 4 — Dietary preferences
  final Set<String> _dietaryRestrictions = {};
  final Set<String> _cuisinePreferences = {};

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      // Derive birth_date from age (approximated to Jan 1st of birth year)
      // (Originally extracted for Supabase, now mocked)
      
      // Mocking the onboarding completion
      await Future.delayed(const Duration(seconds: 1));
      
      // Navigate to home after successful "mock" submission
      if (mounted) context.go(AkeliRoutes.home);
    } catch (_) {
      if (mounted) context.go(AkeliRoutes.home);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go(AkeliRoutes.home),
            child: const Text('Passer →'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildIdentityPage(),
                _buildBodyPage(),
                _buildGoalsPage(),
                _buildDietPage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AkeliSpacing.lg),
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 4,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AkeliColors.primary,
                    dotColor: AkeliColors.primary.withValues(alpha: 0.3),
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
                const SizedBox(height: AkeliSpacing.lg),
                FilledButton(
                  onPressed: _isSubmitting ? null : _nextPage,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_currentPage < 3 ? 'Suivant →' : 'Terminer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Faisons connaissance',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            'Ces informations nous permettent de personnaliser votre expérience.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AkeliColors.textSecondary),
          ),
          const SizedBox(height: AkeliSpacing.xl),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Votre prénom',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AkeliSpacing.md),
          TextFormField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Âge',
              prefixIcon: Icon(Icons.cake_outlined),
              suffixText: 'ans',
            ),
          ),
          const SizedBox(height: AkeliSpacing.md),
          Text('Genre', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AkeliSpacing.sm),
          Wrap(
            spacing: AkeliSpacing.sm,
            children: [
              _GenderChip(
                  label: 'Homme',
                  value: 'male',
                  selected: _gender == 'male',
                  onTap: () => setState(() => _gender = 'male')),
              _GenderChip(
                  label: 'Femme',
                  value: 'female',
                  selected: _gender == 'female',
                  onTap: () => setState(() => _gender = 'female')),
              _GenderChip(
                  label: 'Autre',
                  value: 'other',
                  selected: _gender == 'other',
                  onTap: () => setState(() => _gender = 'other')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre morphologie',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            'Ces données nous aident à calculer vos besoins nutritionnels.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AkeliColors.textSecondary),
          ),
          const SizedBox(height: AkeliSpacing.xl),
          TextFormField(
            controller: _weightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Poids actuel',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: AkeliSpacing.md),
          TextFormField(
            controller: _heightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Taille',
              prefixIcon: Icon(Icons.height_rounded),
              suffixText: 'cm',
            ),
          ),
          const SizedBox(height: AkeliSpacing.md),
          TextFormField(
            controller: _targetWeightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Poids cible',
              prefixIcon: Icon(Icons.flag_outlined),
              suffixText: 'kg',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    const goals = [
      ('weight_loss', 'Perdre du poids', Icons.trending_down_rounded),
      ('maintenance', 'Maintenir mon poids', Icons.balance_rounded),
      ('muscle_gain', 'Prendre du muscle', Icons.fitness_center_rounded),
      ('health', 'Améliorer ma santé', Icons.favorite_border_rounded),
    ];

    const activities = [
      ('sedentary', 'Sédentaire', 'Peu ou pas d\'exercice'),
      ('light', 'Légère', '1-3 jours/semaine'),
      ('moderate', 'Modérée', '3-5 jours/semaine'),
      ('active', 'Active', '6-7 jours/semaine'),
      ('very_active', 'Très active', 'Sportif intensif'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos objectifs',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AkeliSpacing.xl),
          Text('Mon objectif principal',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AkeliSpacing.sm),
          ...goals.map(
            (g) => _SelectionTile(
              icon: g.$3,
              label: g.$2,
              selected: _primaryGoal == g.$1,
              onTap: () => setState(() => _primaryGoal = g.$1),
            ),
          ),
          const SizedBox(height: AkeliSpacing.lg),
          Text('Niveau d\'activité physique',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AkeliSpacing.sm),
          ...activities.map(
            (a) => _SelectionTile(
              label: a.$2,
              subtitle: a.$3,
              selected: _activityLevel == a.$1,
              onTap: () => setState(() => _activityLevel = a.$1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietPage() {
    const restrictions = [
      ('vegetarian', 'Végétarien'),
      ('vegan', 'Végétalien'),
      ('gluten_free', 'Sans gluten'),
      ('lactose_free', 'Sans lactose'),
      ('halal', 'Halal'),
      ('no_pork', 'Sans porc'),
    ];

    const cuisines = [
      ('west_africa', 'Afrique de l\'Ouest'),
      ('central_africa', 'Afrique Centrale'),
      ('east_africa', 'Afrique de l\'Est'),
      ('north_africa', 'Afrique du Nord'),
      ('caribbean', 'Caraïbes'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos préférences',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AkeliSpacing.xl),
          Text('Restrictions alimentaires',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AkeliSpacing.sm),
          Wrap(
            spacing: AkeliSpacing.sm,
            runSpacing: AkeliSpacing.sm,
            children: restrictions
                .map((r) => FilterChip(
                      label: Text(r.$2),
                      selected: _dietaryRestrictions.contains(r.$1),
                      onSelected: (v) => setState(() => v
                          ? _dietaryRestrictions.add(r.$1)
                          : _dietaryRestrictions.remove(r.$1)),
                    ))
                .toList(),
          ),
          const SizedBox(height: AkeliSpacing.lg),
          Text('Cuisines préférées',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AkeliSpacing.sm),
          Wrap(
            spacing: AkeliSpacing.sm,
            runSpacing: AkeliSpacing.sm,
            children: cuisines
                .map((c) => FilterChip(
                      label: Text(c.$2),
                      selected: _cuisinePreferences.contains(c.$1),
                      onSelected: (v) => setState(() => v
                          ? _cuisinePreferences.add(c.$1)
                          : _cuisinePreferences.remove(c.$1)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.label,
    this.subtitle,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: AkeliSpacing.sm),
        padding: const EdgeInsets.all(AkeliSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AkeliColors.primary.withValues(alpha: 0.1)
              : AkeliColors.surface,
          borderRadius: BorderRadius.circular(AkeliRadius.md),
          border: Border.all(
            color: selected ? AkeliColors.primary : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color:
                      selected ? AkeliColors.primary : AkeliColors.textSecondary),
              const SizedBox(width: AkeliSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: selected
                                ? AkeliColors.primary
                                : AkeliColors.textPrimary,
                          )),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AkeliColors.textSecondary,
                            )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AkeliColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
