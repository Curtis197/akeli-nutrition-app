import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

/// Privacy Policy Page - Editorial Design
/// Displays privacy policy with sections on data collection, user rights (RGPD), and contact info
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Akeli Oasis',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AkeliColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AkeliColors.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: AkeliColors.onSecondaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: AkeliSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AkeliSpacing.lg,
          32,
          AkeliSpacing.lg,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AkeliSpacing.xl),
            
            // Hero Section
            Text(
              'Politique de Confidentialité',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AkeliColors.primary,
                letterSpacing: -1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AkeliSpacing.md),
            Text(
              'Dernière mise à jour : 15 Octobre 2023',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AkeliColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),

            // Summary Card
            Container(
              decoration: BoxDecoration(
                color: AkeliColors.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AkeliColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 48,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AkeliColors.onSecondaryContainer,
                        size: 24,
                      ),
                      const SizedBox(width: AkeliSpacing.sm),
                      Text(
                        'En Bref',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AkeliSpacing.lg),
                  _buildSummaryItem(
                    'Nous ne vendons jamais vos données personnelles à des tiers.',
                    highlight: 'jamais',
                  ),
                  const SizedBox(height: AkeliSpacing.md),
                  _buildSummaryItem(
                    'Vos données sont sécurisées et hébergées au sein de l\'Union Européenne.',
                  ),
                  const SizedBox(height: AkeliSpacing.md),
                  _buildSummaryItem(
                    'Vous gardez le contrôle total : consultez, modifiez ou supprimez vos données à tout moment.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),

            // Policy Sections
            _buildSection(
              icon: Icons.business_outlined,
              iconColor: AkeliColors.tertiaryFixedDim,
              title: '1. Responsable du traitement',
              content:
                  'Le responsable du traitement des données à caractère personnel collectées via la plateforme Akeli Oasis est la société Akeli Oasis SAS, immatriculée au RCS de Paris sous le numéro 123 456 789, dont le siège social est situé au 10 Rue de la Paix, 75002 Paris.',
            ),
            const SizedBox(height: AkeliSpacing.lg),

            _buildSection(
              icon: Icons.database_outlined,
              iconColor: AkeliColors.tertiaryFixedDim,
              title: '2. Données collectées',
              content: 'Nous collectons les données suivantes lors de votre utilisation de nos services :',
              bullets: [
                'Données d\'identification : Nom, prénom, adresse e-mail.',
                'Données de connexion : Adresse IP, logs de connexion, type de navigateur.',
                'Données d\'utilisation : Pages visitées, temps passé, interactions avec l\'interface.',
              ],
            ),
            const SizedBox(height: AkeliSpacing.lg),

            _buildSection(
              icon: Icons.target_outlined,
              iconColor: AkeliColors.tertiaryFixedDim,
              title: '3. Finalités du traitement',
              content: 'Vos données sont collectées pour les finalités suivantes :',
              bullets: [
                'Fourniture et gestion de nos services.',
                'Amélioration de l\'expérience utilisateur et personnalisation du contenu.',
                'Sécurité de la plateforme et prévention des fraudes.',
                'Communication (newsletters, alertes de sécurité) avec votre consentement préalable.',
              ],
            ),
            const SizedBox(height: AkeliSpacing.lg),

            _buildSection(
              icon: Icons.gavel_outlined,
              iconColor: AkeliColors.tertiaryFixedDim,
              title: '4. Vos Droits (RGPD)',
              content:
                  'Conformément au Règlement Général sur la Protection des Données (RGPD), vous disposez des droits suivants concernant vos données :',
              gridItems: [
                _buildGridItem('Droit d\'accès', 'Obtenir la confirmation que vos données sont traitées et en recevoir une copie.'),
                _buildGridItem('Droit de rectification', 'Demander la correction de données inexactes ou incomplètes.'),
                _buildGridItem('Droit à l\'effacement', 'Demander la suppression de vos données ("droit à l\'oubli").'),
                _buildGridItem('Droit d\'opposition', 'Vous opposer à certains traitements, notamment à des fins de prospection.'),
              ],
            ),
            const SizedBox(height: AkeliSpacing.lg),

            _buildSection(
              icon: Icons.shield_outlined,
              iconColor: AkeliColors.tertiaryFixedDim,
              title: '5. Sécurité des données',
              content:
                  'Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour protéger vos données personnelles contre l\'altération, la perte accidentelle ou illicite, l\'utilisation, la divulgation ou l\'accès non autorisé, notamment via le chiffrement des communications (SSL/TLS) et des bases de données hautement sécurisées.',
            ),
            const SizedBox(height: AkeliSpacing.lg),

            _buildSection(
              icon: Icons.cookie_outlined,
              iconColor: AkeliColors.tertiaryFixedDim,
              title: '6. Utilisation des cookies',
              content:
                  'Notre site utilise des cookies essentiels pour assurer son bon fonctionnement. Nous utilisons également des cookies analytiques pour comprendre comment vous interagissez avec notre plateforme. Vous pouvez gérer vos préférences de cookies à tout moment via notre bannière de gestion des consentements.',
            ),
            const SizedBox(height: AkeliSpacing.xxl),

            // Contact Section
            Container(
              decoration: BoxDecoration(
                color: AkeliColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AkeliColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 48,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: AkeliSpacing.sm),
                      Text(
                        '7. Contact',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AkeliSpacing.md),
                  Text(
                    'Pour toute question relative à la présente politique de confidentialité ou pour exercer vos droits, veuillez nous contacter à l\'adresse suivante :',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: AkeliSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AkeliSpacing.lg,
                      vertical: AkeliSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AkeliColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'dpo@akelioasis.fr',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String text, {String? highlight}) {
    if (highlight != null) {
      final parts = text.split(highlight);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AkeliColors.primary,
            size: 20,
          ),
          const SizedBox(width: AkeliSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AkeliColors.onSecondaryContainer.withValues(alpha: 0.9),
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: parts[0]),
                  TextSpan(
                    text: highlight,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (parts.length > 1) TextSpan(text: parts[1]),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          color: AkeliColors.primary,
          size: 20,
        ),
        const SizedBox(width: AkeliSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AkeliColors.onSecondaryContainer.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    List<String>? bullets,
    List<Widget>? gridItems,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AkeliColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
        border: Border.all(
          color: AkeliColors.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: AkeliSpacing.sm),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AkeliSpacing.md),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AkeliColors.onSurface.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
          if (bullets != null) ...[
            const SizedBox(height: AkeliSpacing.md),
            ...bullets.map((bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: GoogleFonts.inter(fontSize: 14)),
                  Expanded(
                    child: Text(
                      bullet,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AkeliColors.onSurface.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (gridItems != null) ...[
            const SizedBox(height: AkeliSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AkeliSpacing.md,
              crossAxisSpacing: AkeliSpacing.md,
              children: gridItems,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridItem(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AkeliColors.onSurface,
            ),
          ),
          const SizedBox(height: AkeliSpacing.xs),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AkeliColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
