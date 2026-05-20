import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import '../../core/theme.dart';

final _log = Logger();

/// Journaling Bottom Sheet - Editorial Design
/// Modal for daily journal entry with media upload, description, and meal type selection
class JournalingBottomSheet extends StatefulWidget {
  const JournalingBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    _log.i('Journaling bottom sheet shown');
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
  bool _isSaving = false;
  List<String> _uploadedMedia = [];

  final List<String> _mealTypes = ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'];

  @override
  void initState() {
    super.initState();
    _log.i('Journaling bottom sheet initialized');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _log.d('Journaling bottom sheet disposed');
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_descriptionController.text.isEmpty) {
      _log.w('Attempted to save empty journal entry');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez ajouter une description'),
          backgroundColor: AkeliColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
      return;
    }

    _log.i('Saving journal entry', {
      'mealType': _selectedMealType,
      'descriptionLength': _descriptionController.text.length,
      'mediaCount': _uploadedMedia.length,
    });

    setState(() => _isSaving = true);

    try {
      // TODO: Integrate with journaling edge function
      await Future.delayed(const Duration(milliseconds: 500));
      
      _log.i('Journal entry saved successfully');

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
    } catch (e, stackTrace) {
      _log.e('Failed to save journal entry', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            backgroundColor: AkeliColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AkeliRadius.lg),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _uploadMedia() {
    _log.i('Media upload triggered');
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sélectionnez une photo dans votre galerie'),
        backgroundColor: AkeliColors.secondaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AkeliRadius.xl)),
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
          // Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AkeliColors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AkeliColors.tertiary, AkeliColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(AkeliRadius.md),
                        ),
                        child: Icon(Icons.edit_note_rounded, size: 28, color: AkeliColors.onTertiary),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nouvelle entrée',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AkeliColors.onSurface,
                              ),
                            ),
                            Text(
                              'Notez votre expérience culinaire',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AkeliColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Media Upload
                  Text(
                    'Photos',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: _uploadMedia,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AkeliRadius.lg),
                        border: Border.all(
                          color: AkeliColors.outline.withValues(alpha: 0.3),
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: _uploadedMedia.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AkeliColors.primary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ajouter des photos',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: AkeliColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                              padding: EdgeInsets.all(8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: _uploadedMedia.length,
                              itemBuilder: (context, index) => Container(
                                decoration: BoxDecoration(
                                  color: AkeliColors.primaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                                ),
                                child: Icon(Icons.image, color: AkeliColors.primary),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Meal Type Selector
                  Text(
                    'Type de repas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealTypes.map((type) {
                      final isSelected = _selectedMealType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _log.i('Meal type selected', {'type': type});
                            setState(() => _selectedMealType = type);
                          }
                        },
                        selectedColor: AkeliColors.primary,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AkeliColors.onPrimary : AkeliColors.onSurface,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  
                  // Description Field
                  Text(
                    'Description',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Comment s\'est passé ce repas? Goûts, textures, émotions...',
                      filled: true,
                      fillColor: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveEntry,
                      icon: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AkeliColors.onPrimary),
                              ),
                            )
                          : Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Enregistrement...' : 'Enregistrer l\'entrée',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 56),
                        backgroundColor: AkeliColors.primary,
                        foregroundColor: AkeliColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AkeliRadius.lg),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
