import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class BeautyCheckinSheet extends StatefulWidget {
  final String userId;
  final double? initialHairLengthCm;
  final double? initialHairStrengthScore;
  final double? initialSkinHydrationLevel;
  final Function(Map<String, dynamic> checkinData)? onSubmit;

  const BeautyCheckinSheet({
    super.key,
    required this.userId,
    this.initialHairLengthCm,
    this.initialHairStrengthScore,
    this.initialSkinHydrationLevel,
    this.onSubmit,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String userId,
    double? initialHairLengthCm,
    double? initialHairStrengthScore,
    double? initialSkinHydrationLevel,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BeautyCheckinSheet(
        userId: userId,
        initialHairLengthCm: initialHairLengthCm,
        initialHairStrengthScore: initialHairStrengthScore,
        initialSkinHydrationLevel: initialSkinHydrationLevel,
      ),
    );
  }

  @override
  State<BeautyCheckinSheet> createState() => _BeautyCheckinSheetState();
}

class _BeautyCheckinSheetState extends State<BeautyCheckinSheet> {
  late double _hairLengthCm;
  late double _hairStrengthScore;
  late double _skinHydrationLevel;
  String _hairSheddingRate = 'normal';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hairLengthCm = widget.initialHairLengthCm ?? 20.0;
    _hairStrengthScore = widget.initialHairStrengthScore ?? 7.0;
    _skinHydrationLevel = widget.initialSkinHydrationLevel ?? 7.0;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final payload = <String, dynamic>{
      'user_id': widget.userId,
      'hair_length_cm': _hairLengthCm,
      'hair_strength_score': _hairStrengthScore,
      'skin_hydration_level': _skinHydrationLevel,
      'hair_shedding_rate': _hairSheddingRate,
      'checkin_notes': _notesController.text.trim(),
      'logged_at': DateTime.now().toIso8601String(),
    };
    if (widget.onSubmit != null) {
      widget.onSubmit!(payload);
    }
    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
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
              'Beauty Check-In & Evolution',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Record your monthly hair length and skin barrier check-in.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AkeliColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            // 1. Hair Length (cm) Slider
            Text(
              'Hair Length: ${_hairLengthCm.toStringAsFixed(1)} cm',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _hairLengthCm,
              min: 2.0,
              max: 100.0,
              divisions: 196,
              activeColor: AkeliColors.primary,
              onChanged: (val) => setState(() => _hairLengthCm = val),
            ),
            const SizedBox(height: 16),

            // 2. Hair Strength Score (1-10) Slider
            Text(
              'Hair Strength Score: ${_hairStrengthScore.toStringAsFixed(1)} / 10',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _hairStrengthScore,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              activeColor: AkeliColors.accentGold,
              onChanged: (val) => setState(() => _hairStrengthScore = val),
            ),
            const SizedBox(height: 16),

            // 3. Skin Hydration Level (1-10) Slider
            Text(
              'Skin Hydration Level: ${_skinHydrationLevel.toStringAsFixed(1)} / 10',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _skinHydrationLevel,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              activeColor: AkeliColors.infoBlue,
              onChanged: (val) => setState(() => _skinHydrationLevel = val),
            ),
            const SizedBox(height: 16),

            // 4. Notes input
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Check-in Journal Notes (Optional)',
                hintText: 'e.g. Hair feeling noticeably softer after Chébé mask!',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save Action Button
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
                child: const Text(
                  'Save Progress Check-In',
                  style: TextStyle(
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
