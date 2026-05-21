import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Journaling Bottom Sheet - Editorial Design
/// Modal for daily journal entry with media upload, description, and meal type selection
class JournalingBottomSheet extends ConsumerStatefulWidget {
  const JournalingBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    appLogger.userAction('Journaling sheet opened', screen: 'JournalingBottomSheet');
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JournalingBottomSheet(),
    );
  }

  @override
  ConsumerState<JournalingBottomSheet> createState() => _JournalingBottomSheetState();
}

class _JournalingBottomSheetState extends ConsumerState<JournalingBottomSheet> {
  final _logger = appLogger;
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  String _selectedMealType = 'Déjeuner';
  bool _isSaving = false;
  List<XFile> _selectedImages = [];

  final List<String> _mealTypes = ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation'];

  @override
  void initState() {
    super.initState();
    _logger.provider('JournalingBottomSheet build()');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _logger.provider('JournalingBottomSheet disposed');
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_descriptionController.text.isEmpty) {
      _logger.provider('JournalingBottomSheet | save blocked | empty description');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez ajouter une description'),
          backgroundColor: AkeliColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
      return;
    }

    _logger.userAction('Save journal entry tapped', screen: 'JournalingBottomSheet');
    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider);
    final client = ref.read(supabaseClientProvider);

    try {
      _logger.db('BEFORE | table: journal_entry | op: INSERT | userId: ${user?.id}');
      await client.from('journal_entry').insert({
        'user_id': user?.id,
        'meal_type': _selectedMealType,
        'description': _descriptionController.text.trim(),
        'photo_urls': <String>[],
      });
      _logger.db('AFTER | table: journal_entry | rows: 1');
      _logger.provider('JournalingBottomSheet | entry saved');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entrée enregistrée avec succès!'),
            backgroundColor: AkeliColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AkeliRadius.lg),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on PostgrestException catch (e, st) {
      _logger.db('ERROR | table: journal_entry | code: ${e.code}', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de l\'enregistrement'),
            backgroundColor: AkeliColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AkeliRadius.lg),
            ),
          ),
        );
      }
    } catch (e, st) {
      _logger.db('ERROR | journal_entry | unexpected | $e', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _uploadMedia() async {
    _logger.userAction('Add photo tapped', screen: 'JournalingBottomSheet');
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty && mounted) {
      setState(() => _selectedImages = images);
    }
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AkeliColors.tertiary, AkeliColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(AkeliRadius.md),
                        ),
                        child: const Icon(Icons.edit_note_rounded, size: 28, color: AkeliColors.onTertiary),
                      ),
                      const SizedBox(width: 16),
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
                  const SizedBox(height: 24),

                  // Media Upload
                  Text(
                    'Photos',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      child: _selectedImages.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AkeliColors.primary,
                                ),
                                const SizedBox(height: 8),
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
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) => ClipRRect(
                                borderRadius: BorderRadius.circular(AkeliRadius.md),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Meal Type Selector
                  Text(
                    'Type de repas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            _logger.userAction('Meal type selected: $type', screen: 'JournalingBottomSheet');
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
                  const SizedBox(height: 24),

                  // Description Field
                  Text(
                    'Description',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveEntry,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AkeliColors.onPrimary),
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Enregistrement...' : 'Enregistrer l\'entrée',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
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
