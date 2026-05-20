import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

/// Cooking Session Bottom Sheet - Editorial Design
/// Modal for creating a new batch cooking session (currently placeholder)
class CookingSessionBottomSheet extends StatelessWidget {
  const CookingSessionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
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
          // Drag Handle
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
              AkeliSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nouvelle session',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AkeliColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AkeliColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AkeliColors.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.xxl),

                // Content Canvas
                Column(
                  children: [
                    // Decorative Visual Element
                    Container(
                      width: double.infinity,
                      height: 128,
                      decoration: BoxDecoration(
                        color: AkeliColors.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AkeliColors.primary.withValues(alpha: 0.05),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          Center(
                            child: Icon(
                              Icons.calendar_month_outlined,
                              color: AkeliColors.primary.withValues(alpha: 0.2),
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AkeliSpacing.lg),

                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(AkeliSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0), // muted-orange from stitch
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AkeliColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AkeliSpacing.sm),
                          Expanded(
                            child: Text(
                              'La création de sessions batch sera disponible prochainement…',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AkeliColors.onSurface.withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.xl),

                // Footer Action - Disabled Button
                SizedBox(
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Bientôt disponible',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AkeliColors.outline,
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
