import 'package:flutter/material.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';

class BeautyCheckinSheet extends StatefulWidget {
  final String userId;
  final double? initialHairLengthCm;
  final double? initialHairStrengthScore;
  final double? initialHairThicknessScore;
  final double? initialSkinHydrationLevel;
  final double? initialSkinClarityScore;
  final Function(Map<String, dynamic> checkinData)? onSubmit;

  const BeautyCheckinSheet({
    super.key,
    required this.userId,
    this.initialHairLengthCm,
    this.initialHairStrengthScore,
    this.initialHairThicknessScore,
    this.initialSkinHydrationLevel,
    this.initialSkinClarityScore,
    this.onSubmit,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String userId,
    double? initialHairLengthCm,
    double? initialHairStrengthScore,
    double? initialHairThicknessScore,
    double? initialSkinHydrationLevel,
    double? initialSkinClarityScore,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BeautyCheckinSheet(
        userId: userId,
        initialHairLengthCm: initialHairLengthCm,
        initialHairStrengthScore: initialHairStrengthScore,
        initialHairThicknessScore: initialHairThicknessScore,
        initialSkinHydrationLevel: initialSkinHydrationLevel,
        initialSkinClarityScore: initialSkinClarityScore,
      ),
    );
  }

  @override
  State<BeautyCheckinSheet> createState() => _BeautyCheckinSheetState();
}

class _BeautyCheckinSheetState extends State<BeautyCheckinSheet> {
  final _logger = appLogger;
  late double _hairLengthCm;
  late double _hairStrengthScore;
  late double _hairThicknessScore;
  late double _skinHydrationLevel;
  late double _skinClarityScore;
  String _hairSheddingRate = 'normal';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hairLengthCm = widget.initialHairLengthCm ?? 20.0;
    _hairStrengthScore = widget.initialHairStrengthScore ?? 7.0;
    _hairThicknessScore = widget.initialHairThicknessScore ?? 7.0;
    _skinHydrationLevel = widget.initialSkinHydrationLevel ?? 7.0;
    _skinClarityScore = widget.initialSkinClarityScore ?? 7.0;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    _logger.userAction('Save Progress Check-In tapped', screen: 'BeautyCheckinSheet', metadata: {
      'hairLengthCm': _hairLengthCm,
      'hairStrengthScore': _hairStrengthScore,
      'hairThicknessScore': _hairThicknessScore,
      'skinHydrationLevel': _skinHydrationLevel,
      'skinClarityScore': _skinClarityScore,
      'hairSheddingRate': _hairSheddingRate,
    });
    final payload = <String, dynamic>{
      'userId': widget.userId,
      'hairLengthCm': _hairLengthCm,
      'hairStrengthScore': _hairStrengthScore,
      'hairThicknessScore': _hairThicknessScore,
      'skinHydrationLevel': _skinHydrationLevel,
      'skinClarityScore': _skinClarityScore,
      'hairSheddingRate': _hairSheddingRate,
      'checkinNotes': _notesController.text.trim(),
      'loggedAt': DateTime.now().toIso8601String(),
    };
    _logger.provider('BeautyCheckinSheet payload built | keys: ${payload.keys.join(', ')}');
    if (widget.onSubmit != null) {
      widget.onSubmit!(payload);
    }
    Navigator.of(context).pop(payload);
  }

  Widget _buildSheddingChip(String label, String value) {
    final isSelected = _hairSheddingRate == value;
    return ChoiceChip(
      key: Key('shedding_rate_chip_$value'),
      label: Text(label),
      selected: isSelected,
      selectedColor: AkeliColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AkeliColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        _logger.userAction('Shedding rate chip selected', screen: 'BeautyCheckinSheet', metadata: {'value': value});
        setState(() => _hairSheddingRate = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.beautyCheckinTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.beautyCheckinSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AkeliColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            Text(
              l10n.beautyCheckinHairLengthLabel(_hairLengthCm.toStringAsFixed(1)),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              key: const Key('hair_length_slider'),
              value: _hairLengthCm,
              min: 2.0,
              max: 100.0,
              divisions: 196,
              activeColor: AkeliColors.primary,
              onChanged: (val) => setState(() => _hairLengthCm = val),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.beautyCheckinHairStrengthLabel(_hairStrengthScore.toStringAsFixed(1)),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              key: const Key('hair_strength_slider'),
              value: _hairStrengthScore,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              activeColor: AkeliColors.accentAmber,
              onChanged: (val) => setState(() => _hairStrengthScore = val),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.beautyCheckinHairThicknessLabel(_hairThicknessScore.toStringAsFixed(1)),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              key: const Key('hair_thickness_slider'),
              value: _hairThicknessScore,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              activeColor: AkeliColors.accentAmber,
              onChanged: (val) => setState(() => _hairThicknessScore = val),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.beautyCheckinSkinHydrationLabel(_skinHydrationLevel.toStringAsFixed(1)),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              key: const Key('skin_hydration_slider'),
              value: _skinHydrationLevel,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              activeColor: AkeliColors.primaryContainer,
              onChanged: (val) => setState(() => _skinHydrationLevel = val),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.beautyCheckinSkinClarityLabel(_skinClarityScore.toStringAsFixed(1)),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              key: const Key('skin_clarity_slider'),
              value: _skinClarityScore,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              activeColor: AkeliColors.primaryContainer,
              onChanged: (val) => setState(() => _skinClarityScore = val),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.beautyCheckinSheddingLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildSheddingChip(l10n.beautyCheckinSheddingLow, 'low'),
                _buildSheddingChip(l10n.beautyCheckinSheddingModerate, 'moderate'),
                _buildSheddingChip(l10n.beautyCheckinSheddingHigh, 'high'),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.beautyCheckinNotesLabel,
                hintText: l10n.beautyCheckinNotesHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('save_beauty_checkin_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AkeliColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _handleSave,
                child: Text(
                  l10n.beautyCheckinSaveButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}