import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/user_profile_provider.dart';

class BeautyOnboardingPage extends ConsumerStatefulWidget {
  const BeautyOnboardingPage({super.key});

  @override
  ConsumerState<BeautyOnboardingPage> createState() => _BeautyOnboardingPageState();
}

class _BeautyOnboardingPageState extends ConsumerState<BeautyOnboardingPage> {
  final _logger = appLogger;
  int _currentStep = 0;
  bool _submitting = false;

  // Step 1: Hair & Scalp
  String _hairType = '4C';
  String _porosity = 'medium';
  String _scalpType = 'normal';

  // Step 2: Skin
  String _skinType = 'combination';

  // Step 3: Goals
  final Set<String> _beautyGoals = {'hair_growth', 'moisture'};

  @override
  Widget build(BuildContext context) {
    _logger.provider('BeautyOnboardingPage build() | step: $_currentStep');

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        title: const Text(
          'Profil Beauté Botanique',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
        ),
        backgroundColor: AkeliColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: isActive ? AkeliColors.primary : AkeliColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(),
              ),
            ),
            // Bottom Action Bar
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _submitting ? null : () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Retour'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _handleNextOrSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AkeliColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _currentStep == 2
                                  ? 'Générer Mon Plan 30 Jours ✨'
                                  : 'Étape Suivante ➔',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Hair();
      case 1:
        return _buildStep2Skin();
      case 2:
        return _buildStep3Goals();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Hair() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👑 Empreinte Capillaire',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AkeliColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Définissez la texture naturelle et la porosité de vos cheveux pour adapter les actifs botaniques.',
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        const Text('Texture Capillaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip('4C (Crépu très serré)', '4C', _hairType, (val) => setState(() => _hairType = val)),
            _buildSelectableChip('4B (Crépu en Z)', '4B', _hairType, (val) => setState(() => _hairType = val)),
            _buildSelectableChip('4A (Crépu bouclé)', '4A', _hairType, (val) => setState(() => _hairType = val)),
            _buildSelectableChip('3C (Frisé volumineux)', '3C', _hairType, (val) => setState(() => _hairType = val)),
            _buildSelectableChip('3B (Bouclé)', '3B', _hairType, (val) => setState(() => _hairType = val)),
            _buildSelectableChip('2C-1A (Ondulé / Lisse)', '2C', _hairType, (val) => setState(() => _hairType = val)),
          ],
        ),
        const SizedBox(height: 28),
        const Text('Porosité des Cheveux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip('Faible (Écailles fermées)', 'low', _porosity, (val) => setState(() => _porosity = val)),
            _buildSelectableChip('Moyenne (Équilibre parfait)', 'medium', _porosity, (val) => setState(() => _porosity = val)),
            _buildSelectableChip('Fortement Porrice (Écailles ouvertes)', 'high', _porosity, (val) => setState(() => _porosity = val)),
          ],
        ),
        const SizedBox(height: 28),
        const Text('État du Cuir Chevelu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip('Normal / Équilibré', 'normal', _scalpType, (val) => setState(() => _scalpType = val)),
            _buildSelectableChip('Sec & Démangeaisons', 'dry', _scalpType, (val) => setState(() => _scalpType = val)),
            _buildSelectableChip('Gras / Pellicules', 'oily', _scalpType, (val) => setState(() => _scalpType = val)),
            _buildSelectableChip('Sensible / Irrité', 'sensitive', _scalpType, (val) => setState(() => _scalpType = val)),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Skin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✨ Diagnostic de Peau',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AkeliColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez votre type de peau pour personnaliser les masques botaniques et sérums huiles.',
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        const Text('Type de Peau Visage & Corps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip('Mixte (Zone T brillante)', 'combination', _skinType, (val) => setState(() => _skinType = val)),
            _buildSelectableChip('Sèche & Tiraillements', 'dry', _skinType, (val) => setState(() => _skinType = val)),
            _buildSelectableChip('Grasse & Imperfections', 'oily', _skinType, (val) => setState(() => _skinType = val)),
            _buildSelectableChip('Normale', 'normal', _skinType, (val) => setState(() => _skinType = val)),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Goals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🌱 Objectifs Beauté & Priorités',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AkeliColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez vos objectifs prioritaires pour calibrer les recommandations de soins quotidiens.',
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildGoalCheckbox('🌱 Pousse & Longueur (Chébé, Nigelle)', 'hair_growth'),
        _buildGoalCheckbox('🛡️ Force & Anti-Casse', 'anti_breakage'),
        _buildGoalCheckbox('💧 Hydratation Profonde & Souplesse', 'moisture'),
        _buildGoalCheckbox('💆 Soin Apaisant Cuir Chevelu', 'scalp_soothing'),
        _buildGoalCheckbox('✨ Barrière Cutanée & Éclat du Teint', 'skin_barrier'),
      ],
    );
  }

  Widget _buildSelectableChip(String label, String value, String currentValue, ValueChanged<String> onSelect) {
    final isSelected = currentValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AkeliColors.primary,
      backgroundColor: AkeliColors.surfaceContainerHigh,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AkeliColors.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelect(value),
    );
  }

  Widget _buildGoalCheckbox(String title, String key) {
    final isSelected = _beautyGoals.contains(key);
    return CheckboxListTile(
      value: isSelected,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      activeColor: AkeliColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _beautyGoals.add(key);
          } else {
            _beautyGoals.remove(key);
          }
        });
      },
    );
  }

  Future<void> _handleNextOrSubmit() async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      return;
    }

    _logger.userAction('Complete Beauty Onboarding submitted', screen: 'BeautyOnboardingPage');
    setState(() => _submitting = true);

    try {
      await ref.read(userProfileNotifierProvider.notifier).completeBeautyOnboarding(
            hairType: _hairType,
            porosity: _porosity,
            skinType: _skinType,
            scalpType: _scalpType,
            beautyGoals: _beautyGoals.toList(),
          );
      if (mounted) {
        context.go(AkeliRoutes.home);
      }
    } catch (e, st) {
      _logger.db('ERROR | completeBeautyOnboarding failed | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
