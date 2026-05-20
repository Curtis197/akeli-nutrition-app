import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

/// Journaling Bottom Sheet - Editorial Design
/// Modal for daily journal entry with media upload, description, and meal type selection
class JournalingBottomSheet extends StatefulWidget {
  const JournalingBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JournalingBottomSheet(),
    );
  }

  @override
  State<JournalingBottomSheet> createState() => _JournalingBottomSheetState();
}

class _JournalingBottomSheetState extends State<JournalingBottomSheet> {
  final _descriptionController = TextEditingController();
  String _selectedMealType = 'Déjeuner';

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    // TODO: Integrate with journaling edge function
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entrée enregistrée avec succès!'),
          backgroundColor: AkeliColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AkeliColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 48,
            offset: const Offset(0, -24),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle & Header
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: AkeliColors.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AkeliSpacing.lg,
              AkeliSpacing.md,
              AkeliSpacing.lg,
              100, // Extra padding for floating action button
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Dites nous ce que vous avez mangé',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.onSurface,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkeliSpacing.xxl),

                // Section: Media
                Text(
                  'MEDIA',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AkeliColors.outline,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                InkWell(
                  onTap: () {
                    // TODO: Implement image picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Upload photo - Bientôt disponible'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AkeliColors.outlineVariant.withValues(alpha: 0.5),
                        strokeAlign: BorderSide.strokeAlignInside,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: AkeliColors.surfaceContainerLow,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AkeliColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: AkeliColors.onSurface.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: AkeliColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: AkeliSpacing.md),
                        Text(
                          'Ajouter une photo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AkeliSpacing.xs),
                        Text(
                          'JPG, PNG jusqu\'à 10MB',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AkeliColors.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AkeliSpacing.xxl),

                // Section: Description
                Text(
                  'DESCRIPTION',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AkeliColors.outline,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                Container(
                  constraints: const BoxConstraints(minHeight: 160),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: null,
                    minLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Décrivez votre repas ou vos sensations...',
                      hintStyle: GoogleFonts.inter(
                        color: AkeliColors.outline.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AkeliColors.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AkeliSpacing.xxl),

                // Bento Style Secondary Options
                Container(
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  decoration: BoxDecoration(
                    color: AkeliColors.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        color: AkeliColors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: AkeliSpacing.sm),
                      Text(
                        'Type',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AkeliColors.onSecondaryContainer,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AkeliSpacing.xs),
                      DropdownButton<String>(
                        value: _selectedMealType,
                        underline: const SizedBox.shrink(),
                        items: ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AkeliColors.onSurface,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMealType = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Floating Action Button Area
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: RadialGradient(
          colors: [
            AkeliColors.surface,
            AkeliColors.surface.withValues(alpha: 0.9),
            AkeliColors.surface.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.7, 1.0],
          center: Alignment.bottomCenter,
          radius: 1.2,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Positioned(
      bottom: AkeliSpacing.lg,
      left: AkeliSpacing.lg,
      right: AkeliSpacing.lg,
      child: Material(
        borderRadius: BorderRadius.circular(50),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: _saveEntry,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AkeliColors.primary,
                  AkeliColors.primaryContainer,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AkeliColors.primary.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.save_rounded,
                  color: Colors.white,
                  size: 24,
                  fill: 1,
                ),
                const SizedBox(width: AkeliSpacing.sm),
                Text(
                  'Enregistrer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
