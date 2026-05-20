import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import '../../core/theme.dart';

final _log = Logger();

/// Cooking Session Bottom Sheet - Editorial Design
/// Modal for creating a new batch cooking session (currently placeholder)
class CookingSessionBottomSheet extends StatelessWidget {
  const CookingSessionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    _log.i('Cooking session bottom sheet shown');
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CookingSessionBottomSheet(),
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.kitchen_rounded, size: 40, color: AkeliColors.onPrimary),
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  'Session de Batch Cooking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Organisez vos repas de la semaine',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                
                // Placeholder message
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AkeliColors.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.construction_outlined, color: AkeliColors.secondary, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bientôt disponible',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.onSecondaryContainer,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cette fonctionnalité sera disponible dans une prochaine mise à jour',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AkeliColors.onSecondaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _log.d('Cooking session bottom sheet dismissed');
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56),
                      backgroundColor: AkeliColors.primary,
                      foregroundColor: AkeliColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.lg),
                      ),
                    ),
                    child: Text(
                      'Compris',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
