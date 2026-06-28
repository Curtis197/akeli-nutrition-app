import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

final _logger = appLogger;

/// Terms of Service Page - Editorial Design
/// Displays terms and conditions with articles on access, data collection, IP rights, and liability
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.provider('TermsOfServicePage build()');
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AkeliColors.surfaceContainerLow,
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
            _logger.userAction('Back tapped', screen: 'TermsOfServicePage');
            context.pop();
          },
        ),
        title: Text(
          l10n.legalTermsTitle,
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
                  colors: [AkeliColors.secondary, AkeliColors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AkeliRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description_rounded, size: 48, color: AkeliColors.onSecondary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.legalTermsHeroTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.legalTermsHeroSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AkeliColors.onSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Article 1
            _buildArticleCard(
              number: '1',
              title: l10n.legalTermsArticle1Title,
              content: l10n.legalTermsArticle1Content,
            ),
            const SizedBox(height: 16),

            // Article 2
            _buildArticleCard(
              number: '2',
              title: l10n.legalTermsArticle2Title,
              content: l10n.legalTermsArticle2Content,
            ),
            const SizedBox(height: 16),

            // Article 3
            _buildArticleCard(
              number: '3',
              title: l10n.legalTermsArticle3Title,
              content: l10n.legalTermsArticle3Content,
            ),
            const SizedBox(height: 16),

            // Article 4
            _buildArticleCard(
              number: '4',
              title: l10n.legalTermsArticle4Title,
              content: l10n.legalTermsArticle4Content,
            ),
            const SizedBox(height: 16),

            // Article 5
            _buildArticleCard(
              number: '5',
              title: l10n.legalTermsArticle5Title,
              content: l10n.legalTermsArticle5Content,
            ),
            const SizedBox(height: 16),

            // Article 6
            _buildArticleCard(
              number: '6',
              title: l10n.legalTermsArticle6Title,
              content: l10n.legalTermsArticle6Content,
            ),
            const SizedBox(height: 24),

            // Contact Section
            _buildSectionTitle(l10n.legalTermsContactTitle),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AkeliRadius.lg),
                border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, color: AkeliColors.secondary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    l10n.legalTermsContactEmail,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
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
                  color: AkeliColors.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  l10n.legalTermsVersion,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AkeliColors.onTertiaryContainer,
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

  Widget _buildArticleCard({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AkeliColors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AkeliColors.secondary, AkeliColors.tertiary],
                  ),
                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: AkeliColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
