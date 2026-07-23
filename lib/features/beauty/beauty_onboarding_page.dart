import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
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
  final double _hairThicknessScore = 7.0;
  String _hairSheddingRate = 'moderate';
  double _skinHydrationLevel = 7.0;
  double _skinClarityScore = 7.0;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    // Default notes text is set in didChangeDependencies once l10n is
    // available (AppLocalizations.of(context) cannot be called from
    // initState).
    _notesCtrl = TextEditingController();
  }

  bool _defaultNotesApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultNotesApplied) {
      _notesCtrl.text = AppLocalizations.of(context).beautyOnboardingDefaultNotes;
      _defaultNotesApplied = true;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _porositySummaryValue(AppLocalizations l10n) {
    switch (_porosity) {
      case 'low':
        return l10n.beautyOnboardingSummaryPorosityLowValue;
      case 'high':
        return l10n.beautyOnboardingSummaryPorosityHighValue;
      default:
        return l10n.beautyOnboardingSummaryPorosityMediumValue;
    }
  }

  String _scalpSummaryValue(AppLocalizations l10n) {
    switch (_scalpType) {
      case 'dry':
        return l10n.beautyOnboardingSummaryScalpDryValue;
      case 'oily':
        return l10n.beautyOnboardingSummaryScalpOilyValue;
      case 'sensitive':
        return l10n.beautyOnboardingSummaryScalpSensitiveValue;
      default:
        return l10n.beautyOnboardingSummaryScalpNormalValue;
    }
  }

  String _sheddingRateLabel(AppLocalizations l10n, String rate) {
    switch (rate) {
      case 'low':
        return l10n.beautyOnboardingSheddingLow;
      case 'high':
        return l10n.beautyOnboardingSheddingHigh;
      default:
        return l10n.beautyOnboardingSheddingModerate;
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('BeautyOnboardingPage build() | step: $_currentStep');
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: BeautyOnboardingPage.beautyBackground,
      appBar: AppBar(
        title: Text(
          l10n.beautyOnboardingTitle,
          style: const TextStyle(
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
                child: _buildStepContent(l10n),
              ),
            ),
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
                      child: Text(l10n.beautyOnboardingBackButton),
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
                              _currentStep == 4 ? l10n.beautyOnboardingSubmitButton : l10n.beautyOnboardingNextButton,
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

  Widget _buildStepContent(AppLocalizations l10n) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Hair(l10n);
      case 1:
        return _buildStep2Skin(l10n);
      case 2:
        return _buildStep3Goals(l10n);
      case 3:
        return _buildStep4FirstLog(l10n);
      case 4:
        return _buildStep5Summary(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Hair(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.beautyOnboardingStep1Title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.beautyOnboardingStep1Subtitle,
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.beautyOnboardingHairCompositionLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _hairType,
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
          items: [
            DropdownMenuItem(value: '4C', child: Text(l10n.beautyOnboardingHairType4c)),
            DropdownMenuItem(value: '4B', child: Text(l10n.beautyOnboardingHairType4b)),
            DropdownMenuItem(value: '4A', child: Text(l10n.beautyOnboardingHairType4a)),
            DropdownMenuItem(value: '3C', child: Text(l10n.beautyOnboardingHairType3c)),
            DropdownMenuItem(value: '3B', child: Text(l10n.beautyOnboardingHairType3b)),
            DropdownMenuItem(value: '3A', child: Text(l10n.beautyOnboardingHairType3a)),
            DropdownMenuItem(value: '2C', child: Text(l10n.beautyOnboardingHairType2c)),
            DropdownMenuItem(value: '2B', child: Text(l10n.beautyOnboardingHairType2b)),
            DropdownMenuItem(value: '2A', child: Text(l10n.beautyOnboardingHairType2a)),
            DropdownMenuItem(value: '1C', child: Text(l10n.beautyOnboardingHairType1c)),
            DropdownMenuItem(value: '1B', child: Text(l10n.beautyOnboardingHairType1b)),
            DropdownMenuItem(value: '1A', child: Text(l10n.beautyOnboardingHairType1a)),
            DropdownMenuItem(value: 'Locks', child: Text(l10n.beautyOnboardingHairTypeLocks)),
            DropdownMenuItem(value: 'Transition', child: Text(l10n.beautyOnboardingHairTypeTransition)),
            DropdownMenuItem(value: 'Protective', child: Text(l10n.beautyOnboardingHairTypeProtective)),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _hairType = val);
          },
        ),
        const SizedBox(height: 28),
        Text(
          l10n.beautyOnboardingPorosityLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip(l10n.beautyOnboardingPorosityLow, 'low', _porosity, (val) => setState(() => _porosity = val)),
            _buildSelectableChip(l10n.beautyOnboardingPorosityMedium, 'medium', _porosity, (val) => setState(() => _porosity = val)),
            _buildSelectableChip(l10n.beautyOnboardingPorosityHigh, 'high', _porosity, (val) => setState(() => _porosity = val)),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          l10n.beautyOnboardingScalpLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip(l10n.beautyOnboardingScalpNormal, 'normal', _scalpType, (val) => setState(() => _scalpType = val)),
            _buildSelectableChip(l10n.beautyOnboardingScalpDry, 'dry', _scalpType, (val) => setState(() => _scalpType = val)),
            _buildSelectableChip(l10n.beautyOnboardingScalpOily, 'oily', _scalpType, (val) => setState(() => _scalpType = val)),
            _buildSelectableChip(l10n.beautyOnboardingScalpSensitive, 'sensitive', _scalpType, (val) => setState(() => _scalpType = val)),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Skin(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.beautyOnboardingStep2Title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.beautyOnboardingStep2Subtitle,
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.beautyOnboardingSkinTypeLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _skinType,
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
          items: [
            DropdownMenuItem(value: 'mixte_t', child: Text(l10n.beautyOnboardingSkinTypeMixte)),
            DropdownMenuItem(value: 'seche_deshydratee', child: Text(l10n.beautyOnboardingSkinTypeSeche)),
            DropdownMenuItem(value: 'grasse_acneique', child: Text(l10n.beautyOnboardingSkinTypeGrasse)),
            DropdownMenuItem(value: 'sensible_reactive', child: Text(l10n.beautyOnboardingSkinTypeSensible)),
            DropdownMenuItem(value: 'hypermentee', child: Text(l10n.beautyOnboardingSkinTypeHyperpigmentation)),
            DropdownMenuItem(value: 'mature', child: Text(l10n.beautyOnboardingSkinTypeMature)),
            DropdownMenuItem(value: 'normale', child: Text(l10n.beautyOnboardingSkinTypeNormale)),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _skinType = val);
          },
        ),
        const SizedBox(height: 28),
        Text(
          l10n.beautyOnboardingSkinConcernsLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernHyperpigmentation, 'hyperpigmentation'),
        _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernAcne, 'acne_imperfections'),
        _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernDehydration, 'dehydration'),
        _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernBarrier, 'barrier_damage'),
        _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernSebum, 'excess_sebum'),
        _buildSkinConcernCheckbox(l10n.beautyOnboardingConcernAging, 'aging_elasticity'),
        const SizedBox(height: 28),
        Text(
          l10n.beautyOnboardingBodyProfileLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSelectableChip(l10n.beautyOnboardingBodyNormal, 'normal', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            _buildSelectableChip(l10n.beautyOnboardingBodyKeratose, 'keratose', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            _buildSelectableChip(l10n.beautyOnboardingBodyEczema, 'eczema', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            _buildSelectableChip(l10n.beautyOnboardingBodyVergetures, 'vergetures', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
            _buildSelectableChip(l10n.beautyOnboardingBodyDrySkin, 'corps_sec', _bodySkinProfile, (val) => setState(() => _bodySkinProfile = val)),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Goals(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.beautyOnboardingStep3Title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.beautyOnboardingStep3Subtitle,
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.beautyOnboardingHairGoalsLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalHairGrowth, 'hair_growth'),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalAntiBreakage, 'anti_breakage'),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalHairMoisture, 'hair_moisture'),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalScalpSoothing, 'scalp_soothing'),

        const SizedBox(height: 28),
        Text(
          l10n.beautyOnboardingSkinGoalsLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BeautyOnboardingPage.beautyPrimary),
        ),
        const SizedBox(height: 12),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalSkinGlow, 'skin_glow'),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalAntiSpot, 'skin_anti_spot'),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalSkinMoisture, 'skin_moisture'),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalAntiImperfection, 'skin_anti_imperfection'),
        _buildGoalCheckbox(l10n.beautyOnboardingGoalSkinBarrier, 'skin_barrier'),
      ],
    );
  }

  Widget _buildStep4FirstLog(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.beautyOnboardingStep4Title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.beautyOnboardingStep4Subtitle,
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.beautyOnboardingHairLengthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              l10n.beautyOnboardingValueCm(_hairLengthCm.toInt().toString()),
              style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary),
            ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.beautyOnboardingHairStrengthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              l10n.beautyOnboardingValueOutOfTen(_hairStrengthScore.toInt().toString()),
              style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary),
            ),
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
        Text(l10n.beautyOnboardingSheddingRateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            _buildSelectableChip(l10n.beautyOnboardingSheddingLow, 'low', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
            _buildSelectableChip(l10n.beautyOnboardingSheddingModerate, 'moderate', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
            _buildSelectableChip(l10n.beautyOnboardingSheddingHigh, 'high', _hairSheddingRate, (val) => setState(() => _hairSheddingRate = val)),
          ],
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.beautyOnboardingSkinHydrationLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              l10n.beautyOnboardingValueOutOfTen(_skinHydrationLevel.toInt().toString()),
              style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary),
            ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.beautyOnboardingSkinClarityLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              l10n.beautyOnboardingValueOutOfTen(_skinClarityScore.toInt().toString()),
              style: const TextStyle(fontWeight: FontWeight.bold, color: BeautyOnboardingPage.beautyPrimary),
            ),
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
        Text(l10n.beautyOnboardingNotesLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.beautyOnboardingNotesHint,
            filled: true,
            fillColor: BeautyOnboardingPage.beautySurfaceHigh,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildStep5Summary(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.beautyOnboardingSummaryTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: BeautyOnboardingPage.beautyPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.beautyOnboardingSummarySubtitle,
          style: TextStyle(color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8), height: 1.4),
        ),
        const SizedBox(height: 24),

        _buildSummaryCard(
          l10n,
          title: l10n.beautyOnboardingSummaryHairCardTitle,
          onEdit: () => setState(() => _currentStep = 0),
          children: [
            _buildSummaryRow(l10n.beautyOnboardingSummaryHairTypeRow, _hairType),
            _buildSummaryRow(l10n.beautyOnboardingSummaryPorosityRow, _porositySummaryValue(l10n)),
            _buildSummaryRow(l10n.beautyOnboardingSummaryScalpRow, _scalpSummaryValue(l10n)),
          ],
        ),

        const SizedBox(height: 16),
        _buildSummaryCard(
          l10n,
          title: l10n.beautyOnboardingSummarySkinCardTitle,
          onEdit: () => setState(() => _currentStep = 1),
          children: [
            _buildSummaryRow(l10n.beautyOnboardingSummarySkinTypeRow, _skinType.replaceAll('_', ' ').toUpperCase()),
            _buildSummaryRow(
              l10n.beautyOnboardingSummaryConcernsRow,
              _skinConcerns.isEmpty ? l10n.beautyOnboardingSummaryConcernsNone : _skinConcerns.join(', '),
            ),
            _buildSummaryRow(l10n.beautyOnboardingSummaryBodyProfileRow, _bodySkinProfile),
          ],
        ),

        const SizedBox(height: 16),
        _buildSummaryCard(
          l10n,
          title: l10n.beautyOnboardingSummaryGoalsCardTitle,
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
        _buildSummaryCard(
          l10n,
          title: l10n.beautyOnboardingSummaryFirstLogCardTitle,
          onEdit: () => setState(() => _currentStep = 3),
          children: [
            _buildSummaryRow(l10n.beautyOnboardingSummaryHairLengthRow, l10n.beautyOnboardingValueCm(_hairLengthCm.toInt().toString())),
            _buildSummaryRow(l10n.beautyOnboardingSummaryHairStrengthRow, l10n.beautyOnboardingValueOutOfTen(_hairStrengthScore.toInt().toString())),
            _buildSummaryRow(l10n.beautyOnboardingSummarySheddingRow, _sheddingRateLabel(l10n, _hairSheddingRate)),
            _buildSummaryRow(l10n.beautyOnboardingSummarySkinHydrationRow, l10n.beautyOnboardingValueOutOfTen(_skinHydrationLevel.toInt().toString())),
            _buildSummaryRow(l10n.beautyOnboardingSummaryClarityRow, l10n.beautyOnboardingValueOutOfTen(_skinClarityScore.toInt().toString())),
            if (_notesCtrl.text.isNotEmpty) _buildSummaryRow(l10n.beautyOnboardingSummaryNotesRow, _notesCtrl.text),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    AppLocalizations l10n, {
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
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
                tooltip: l10n.beautyOnboardingSummaryEditTooltip,
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
          Text(label, style: const TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 14)),
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
          SnackBar(content: Text(AppLocalizations.of(context).beautyOnboardingSaveErrorSnackbar(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}