import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

final _logger = appLogger;

/// Privacy Policy Page - Editorial Design
/// Displays privacy policy with sections on data collection, user rights (RGPD), and contact info
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.provider('PrivacyPolicyPage build()');
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AkeliColors.surfaceContainerLowest.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AkeliColors.primary,
              size: 20,
            ),
          ),
          onPressed: () {
            _logger.userAction('Back tapped', screen: 'PrivacyPolicyPage');
            context.pop();
          },
        ),
        title: Text(
          l10n.legalPrivacyTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AkeliColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AkeliRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.security_rounded, size: 48, color: AkeliColors.onPrimary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.legalPrivacyHeroTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.legalPrivacyHeroSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AkeliColors.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Summary Highlights
            _buildSectionTitle(l10n.legalPrivacySummaryTitle),
            const SizedBox(height: 12),
            _buildHighlightCard(
              icon: Icons.data_usage_outlined,
              title: l10n.legalPrivacyCollectionTitle,
              description: l10n.legalPrivacyCollectionDesc,
            ),
            const SizedBox(height: 12),
            _buildHighlightCard(
              icon: Icons.lock_outline,
              title: l10n.legalPrivacySecurityTitle,
              description: l10n.legalPrivacySecurityDesc,
            ),
            const SizedBox(height: 12),
            _buildHighlightCard(
              icon: Icons.person_outline,
              title: l10n.legalPrivacyControlTitle,
              description: l10n.legalPrivacyControlDesc,
            ),
            const SizedBox(height: 32),

            // Section 1
            _buildSectionTitle(l10n.legalPrivacySection1Title),
            const SizedBox(height: 12),
            _buildContentCard(
              content: l10n.legalPrivacySection1Content,
            ),
            const SizedBox(height: 24),

            // Section 2
            _buildSectionTitle(l10n.legalPrivacySection2Title),
            const SizedBox(height: 12),
            _buildContentCard(
              content: l10n.legalPrivacySection2Content,
            ),
            const SizedBox(height: 24),

            // Section 3 - RGPD Rights Grid
            _buildSectionTitle(l10n.legalPrivacySection3Title),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildRightsCard(
                  icon: Icons.visibility_outlined,
                  title: l10n.legalPrivacyRightAccess,
                  description: l10n.legalPrivacyRightAccessDesc,
                ),
                _buildRightsCard(
                  icon: Icons.edit_outlined,
                  title: l10n.legalPrivacyRightRectification,
                  description: l10n.legalPrivacyRightRectificationDesc,
                ),
                _buildRightsCard(
                  icon: Icons.delete_outline,
                  title: l10n.legalPrivacyRightErasure,
                  description: l10n.legalPrivacyRightErasureDesc,
                ),
                _buildRightsCard(
                  icon: Icons.download_outlined,
                  title: l10n.legalPrivacyRightPortability,
                  description: l10n.legalPrivacyRightPortabilityDesc,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 4
            _buildSectionTitle(l10n.legalPrivacySection4Title),
            const SizedBox(height: 12),
            _buildContentCard(
              content: l10n.legalPrivacySection4Content,
            ),
            const SizedBox(height: 24),

            // Section 5
            _buildSectionTitle(l10n.legalPrivacySection5Title),
            const SizedBox(height: 12),
            _buildContentCard(
              content: l10n.legalPrivacySection5Content,
            ),
            const SizedBox(height: 24),

            // Contact Card
            _buildSectionTitle(l10n.legalPrivacyDpoTitle),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AkeliRadius.lg),
                border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mail_outline, color: AkeliColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        l10n.legalPrivacyDpoEmail,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.legalPrivacyDpoDesc,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AkeliColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Version Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AkeliColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  l10n.legalPrivacyVersion,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AkeliColors.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AkeliColors.onSurface,
      ),
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AkeliColors.primary, AkeliColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(AkeliRadius.md),
            ),
            child: Icon(icon, color: AkeliColors.onPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
    );
  }

  Widget _buildContentCard({required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.3)),
      ),
      child: Text(
        content,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.6,
          color: AkeliColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRightsCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AkeliColors.secondaryContainer.withValues(alpha: 0.3),
            AkeliColors.tertiaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AkeliColors.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AkeliColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AkeliColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
