import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/user_profile_provider.dart';

class BeautyOnboardingPage extends ConsumerStatefulWidget {
  const BeautyOnboardingPage({super.key});

  // Beauty Mode Color Set (Rosewood Rose Gold Editorial — matches ColorSetModal)
  static const beautyPrimary = Color(0xFF8A3B58);
  static const beautySecondary = Color(0xFFD4AF37);
  static const beautyBackground = Color(0xFFFAF6F0);
  static const beautySurfaceHigh = Color(0xFFF3EAE1);

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

  // Step 2: Deep Skin Profile
  String _skinType = 'mixte_t';
  final Set<String> _skinConcerns = {'hyperpigmentation', 'dehydration'};
  String _bodySkinProfile = 'normal';

  // Step 3: Balanced Hair & Skin Goals
  final Set<String> _beautyGoals = {'hair_growth', 'hair_moisture', 'skin_glow', 'skin_moisture'};

  // Step 4: First Beauty Log Check-in Baseline
  double _hairLengthCm = 15.0;
  double _hairStrengthScore = 7.0;
  double _hairThicknessScore = 7.0;
  String _hairSheddingRate = 'moderate';
  double _skinHydrationLevel = 7.0;
  double _skinClarityScore = 7.0;
  final _notesCtrl = TextEditingController(text: 'Bilan initial du profil beauté');

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('BeautyOnboardingPage build() | step: $_currentStep');

    return Scaffold(
      backgroundColor: BeautyOnboardingPage.beautyBackground,
      appBar: AppBar(
        title: const Text(
          'Profil Beauté Botanique',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Plus Jakarta Sans',
            color: BeautyOnboardingPage.beautyPrimary,
          ),
        ),
        backgroundColor: BeautyOnboardingPage.beautyBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: BeautyOnboardingPage.beautyPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator Header (5 Steps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(5, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? BeautyOnboardingPage.beautyPrimary
                            : BeautyOnboardingPage.beautySurfaceHigh,
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
                        foregroundColor: BeautyOnboardingPage.beautyPrimary,
                        side: const BorderSide(color: BeautyOnboardingPage.beautyPrimary, width: 1.5),
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
                        backgroundColor: BeautyOnboardingPage.beautyPrimary,
                        foregroundColor: Colors.white,
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
                              _currentStep == 4
                                  ? 'Confirmer & Générer Mon Plan 30 Jours ✨'
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
      case 3:
        return _buildStep4FirstLog();
      case 4:
        return _buildStep5Summary();
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
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Définissez la composition précise et la porosité de vos cheveux pour personnaliser vos soins botaniques.',
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        const Text(
          'Composition & Texture Capillaire',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _hairType,
          decoration: InputDecoration(
            filled: true,
            fillColor: BeautyOnboardingPage.beautySurfaceHigh,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BeautyOnboardingPage.beautyPrimary, width: 2),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: BeautyOnboardingPage.beautyPrimary),
          dropdownColor: Colors.white,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: '4C', child: Text('4C — Crépu Très Serré (Trame en Z, Shrinkage fort)')),
            DropdownMenuItem(value: '4B', child: Text('4B — Crépu Zigzag en Z (Boucles en Z définies)')),
            DropdownMenuItem(value: '4A', child: Text('4A — Crépu Spirales en S (Spirales denses)')),
            DropdownMenuItem(value: '3C', child: Text('3C — Boucles Frisées Denses (Spirales serrées)')),
            DropdownMenuItem(value: '3B', child: Text('3B — Boucles Serrées en Tire-bouchon')),
            DropdownMenuItem(value: '3A', child: Text('3A — Boucles Amples Souples')),
            DropdownMenuItem(value: '2C', child: Text('2C — Ondulations Épaisses')),
            DropdownMenuItem(value: '2B', child: Text('2B — Ondulations Définies')),
            DropdownMenuItem(value: '2A', child: Text('2A — Ondulations Légères')),
            DropdownMenuItem(value: '1C', child: Text('1C — Cheveux Lisses Épais')),
            DropdownMenuItem(value: '1B', child: Text('1B — Cheveux Lisses Moyens')),
            DropdownMenuItem(value: '1A', child: Text('1A — Cheveux Lisses Très Fins')),
            DropdownMenuItem(value: 'Locks', child: Text('Locks / Dreadlocks (Verrouillés)')),
            DropdownMenuItem(value: 'Transition', child: Text('Cheveux en Transition (Post-Défrisage)')),
            DropdownMenuItem(value: 'Protective', child: Text('Soin Sous Tresses / Perruque')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _hairType = val);
          },
        ),
        const SizedBox(height: 28),
        const Text(
          'Porosité des Cheveux',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip('Faible (Écailles fermées)', 'low', _porosity, (val) => setState(() => _porosity = val)),
            _buildSelectableChip('Moyenne (Équilibre parfait)', 'medium', _porosity, (val) => setState(() => _porosity = val)),
            _buildSelectableChip('Fortement Poreuse (Écailles ouvertes)', 'high', _porosity, (val) => setState(() => _porosity = val)),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'État du Cuir Chevelu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
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
          '✨ Diagnostic Cutané Profond',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Analysez la typologie globale et les défis spécifiques de votre peau (visage & corps).',
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        const Text(
          'Composition & Typologie Cutanée',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _skinType,
          decoration: InputDecoration(
            filled: true,
            fillColor: BeautyOnboardingPage.beautySurfaceHigh,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BeautyOnboardingPage.beautyPrimary, width: 2),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: BeautyOnboardingPage.beautyPrimary),
          dropdownColor: Colors.white,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'mixte_t', child: Text('Peau Mixte (Zone T brillante, joues normales/sèches)')),
            DropdownMenuItem(value: 'seche_deshydratee', child: Text('Peau Sèche & Déshydratée (Tiraillements & desquamation)')),
            DropdownMenuItem(value: 'grasse_acneique', child: Text('Peau Grasse & Acnéique (Excès de sébum, pores dilatés)')),
            DropdownMenuItem(value: 'sensible_reactive', child: Text('Peau Sensible & Réactive (Rougeurs, rosacée)')),
            DropdownMenuItem(value: 'hypermentee', child: Text('Peau Sujette à l\'Hyperpigmentation (Taches sombres, mélasma)')),
            DropdownMenuItem(value: 'mature', child: Text('Peau Mature (Perte de fermeté & rides d\'expression)')),
            DropdownMenuItem(value: 'normale', child: Text('Peau Normale / Équilibrée')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _skinType = val);
          },
        ),
        const SizedBox(height: 28),
        const Text(
          'Préoccupations Cutanées (Visage & Décolleté)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        _buildSkinConcernCheckbox('🌖 Taches Sombres & Teint Irrégulier', 'hyperpigmentation'),
        _buildSkinConcernCheckbox('🌋 Boutons & Imperfections', 'acne_imperfections'),
        _buildSkinConcernCheckbox('💧 Déshydratation Profonde & Perte d\'Éclat', 'dehydration'),
        _buildSkinConcernCheckbox('🛡️ Barrière Cutanée Fragilisée & Sensibilité', 'barrier_damage'),
        _buildSkinConcernCheckbox('✨ Brillance Excessive & Pores Dilatés', 'excess_sebum'),
        _buildSkinConcernCheckbox('🌿 Perte d\'Élasticité & Rides d\'Expression', 'aging_elasticity'),
        const SizedBox(height: 28),
        const Text(
          'Particularités du Corps',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip('Normal / Sans Problème', 'normal', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            _buildSelectableChip('Kératose Pilaire (Peau de poule)', 'keratose', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            _buildSelectableChip('Eczéma / Sujet aux Poussées', 'eczema', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            _buildSelectableChip('Prévention Vergetures', 'vergetures', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            _buildSelectableChip('Peau du Corps Très Sèche (Crocodile)', 'corps_sec', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
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
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez vos priorités capillaires et cutanées pour calibrer votre routine sur 30 jours.',
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        const Text(
          'Objectifs Capillaires 👑',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        _buildGoalCheckbox('🌱 Pousse, Densité & Longueur', 'hair_growth'),
        _buildGoalCheckbox('🛡️ Force, Retention & Anti-Casse', 'anti_breakage'),
        _buildGoalCheckbox('💧 Hydratation Profonde & Définition', 'hair_moisture'),
        _buildGoalCheckbox('💆 Équilibre & Apaisement du Cuir Chevelu', 'scalp_soothing'),

        const SizedBox(height: 28),
        const Text(
          'Objectifs Cutanés & Teint ✨',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        _buildGoalCheckbox('✨ Éclat du Teint & Teint Uniforme', 'skin_glow'),
        _buildGoalCheckbox('🌖 Atténuation des Taches & Hyperpigmentation', 'skin_anti_spot'),
        _buildGoalCheckbox('💧 Hydratation & Souplesse Cutanée', 'skin_moisture'),
        _buildGoalCheckbox('🌋 Clarification & Anti-Imperfections', 'skin_anti_imperfection'),
        _buildGoalCheckbox('🛡️ Renforcement de la Barrière Cutanée', 'skin_barrier'),
      ],
    );
  }

  Widget _buildStep4FirstLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Premier Bilan Initial (First Beauty Log)',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez vos mesures et observations de départ. Ce premier journal servira de point de référence pour mesurer vos progrès au fil des 30 jours.',
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        
        // Hair Length Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📏 Longueur Actuelle des Cheveux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${_hairLengthCm.toInt()} cm', style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary)),
          ],
        ),
        Slider(
          value: _hairLengthCm,
          min: 1.0,
          max: 100.0,
          divisions: 99,
          activeColor: BeautyOnboardingPage.beautyPrimary,
          onChanged: (val) => setState(() => _hairLengthCm = val),
        ),

        const SizedBox(height: 20),
        // Hair Strength Score Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('💪 Force & Résistance Capillaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${_hairStrengthScore.toInt()}/10', style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary)),
          ],
        ),
        Slider(
          value: _hairStrengthScore,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          activeColor: BeautyOnboardingPage.beautyPrimary,
          onChanged: (val) => setState(() => _hairStrengthScore = val),
        ),

        const SizedBox(height: 20),
        // Hair Shedding Rate
        const Text('📊 Taux de Chute Actuel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            _buildSelectableChip('Faible', 'low', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
            _buildSelectableChip('Modéré', 'moderate', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
            _buildSelectableChip('Élevé', 'high', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
          ],
        ),

        const SizedBox(height: 20),
        // Skin Hydration Level Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('💧 Niveau d\'Hydratation de la Peau', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${_skinHydrationLevel.toInt()}/10', style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary)),
          ],
        ),
        Slider(
          value: _skinHydrationLevel,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          activeColor: BeautyOnboardingPage.beautyPrimary,
          onChanged: (val) => setState(() => _skinHydrationLevel = val),
        ),

        const SizedBox(height: 20),
        // Skin Clarity Score Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('✨ Éclat & Clarté du Teint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${_skinClarityScore.toInt()}/10', style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary)),
          ],
        ),
        Slider(
          value: _skinClarityScore,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          activeColor: BeautyOnboardingPage.beautyPrimary,
          onChanged: (val) => setState(() => _skinClarityScore = val),
        ),

        const SizedBox(height: 24),
        const Text('📝 Notes Initiales & Observations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Notes sur l\'état de vos cheveux et de votre peau...',
            filled: true,
            fillColor: BeautyOnboardingPage.beautySurfaceHigh,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildStep5Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Résumé & Confirmation',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez la synthèse de votre profil beauté avant d\'activer votre programme personnalisé 30 jours.',
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),

        // Card 1: Hair Profile Summary
        _buildSummaryCard(
          title: '👑 Profil Capillaire',
          onEdit: () => setState(() => _currentStep = 0),
          children: [
            _buildSummaryRow('Texture / Type:', _hairType),
            _buildSummaryRow('Porosité:', _porosity == 'low' ? 'Faible' : _porosity == 'high' ? 'Poreuse' : 'Moyenne'),
            _buildSummaryRow('Cuir Chevelu:', _scalpType == 'dry' ? 'Sec' : _scalpType == 'oily' ? 'Gras' : _scalpType == 'sensitive' ? 'Sensible' : 'Normal'),
          ],
        ),

        const SizedBox(height: 16),
        // Card 2: Skin Diagnostic Summary
        _buildSummaryCard(
          title: '✨ Diagnostic Cutané',
          onEdit: () => setState(() => _currentStep = 1),
          children: [
            _buildSummaryRow('Typologie:', _skinType.replaceAll('_', ' ').toUpperCase()),
            _buildSummaryRow('Préoccupations:', _skinConcerns.isEmpty ? 'Aucune' : _skinConcerns.join(', ')),
            _buildSummaryRow('Particularité Corps:', _bodySkinProfile),
          ],
        ),

        const SizedBox(height: 16),
        // Card 3: Beauty Goals Summary
        _buildSummaryCard(
          title: '🌱 Objectifs Sélectionnés',
          onEdit: () => setState(() => _currentStep = 2),
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _beautyGoals.map((g) {
                return Chip(
                  label: Text(g.replaceAll('_', ' ')),
                  backgroundColor: BeautyOnboardingPage.beautySurfaceHigh,
                  labelStyle: const TextStyle(fontSize: 12, color: BeautyOnboardingPage.beautyPrimary, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 16),
        // Card 4: First Log Summary
        _buildSummaryCard(
          title: '📊 Mesures du Premier Bilan',
          onEdit: () => setState(() => _currentStep = 3),
          children: [
            _buildSummaryRow('Longueur Cheveux:', '${_hairLengthCm.toInt()} cm'),
            _buildSummaryRow('Force Capillaire:', '${_hairStrengthScore.toInt()}/10'),
            _buildSummaryRow('Taux de Chute:', _hairSheddingRate),
            _buildSummaryRow('Hydratation Peau:', '${_skinHydrationLevel.toInt()}/10'),
            _buildSummaryRow('Éclat Teint:', '${_skinClarityScore.toInt()}/10'),
            if (_notesCtrl.text.isNotEmpty) _buildSummaryRow('Notes:', _notesCtrl.text),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String title, required VoidCallback onEdit, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: BeautyOnboardingPage.beautyPrimary),
                onPressed: onEdit,
                tooltip: 'Modifier',
              ),
            ],
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip(String label, String value, String currentValue, ValueChanged<String> onSelect) {
    final isSelected = currentValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: BeautyOnboardingPage.beautyPrimary,
      backgroundColor: BeautyOnboardingPage.beautySurfaceHigh,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AkeliColors.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelect(value),
    );
  }

  Widget _buildSkinConcernCheckbox(String title, String key) {
    final isSelected = _skinConcerns.contains(key);
    return CheckboxListTile(
      value: isSelected,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      activeColor: BeautyOnboardingPage.beautyPrimary,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _skinConcerns.add(key);
          } else {
            _skinConcerns.remove(key);
          }
        });
      },
    );
  }

  Widget _buildGoalCheckbox(String title, String key) {
    final isSelected = _beautyGoals.contains(key);
    return CheckboxListTile(
      value: isSelected,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      activeColor: BeautyOnboardingPage.beautyPrimary,
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
    if (_currentStep < 4) {
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
            skinConcerns: _skinConcerns.toList(),
            hairLengthCm: _hairLengthCm,
            hairStrengthScore: _hairStrengthScore,
            hairThicknessScore: _hairThicknessScore,
            hairSheddingRate: _hairSheddingRate,
            skinHydrationLevel: _skinHydrationLevel,
            skinClarityScore: _skinClarityScore,
            checkinNotes: _notesCtrl.text,
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
