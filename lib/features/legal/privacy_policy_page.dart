import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';

final _logger = appLogger;

/// Privacy Policy Page - Editorial Design
/// Displays privacy policy with sections on data collection, user rights (RGPD), and contact info
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.provider('PrivacyPolicyPage build()');
    
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
          'Politique de Confidentialité',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AkeliColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AkeliRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_rounded, size: 48, color: AkeliColors.onPrimary),
                  SizedBox(height: 16),
                  Text(
                    'Vos données sont protégées',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nous nous engageons à protéger votre vie privée conformément au RGPD',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AkeliColors.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Summary Highlights
            _buildSectionTitle('En bref'),
            SizedBox(height: 12),
            _buildHighlightCard(
              icon: Icons.data_usage_outlined,
              title: 'Collecte minimale',
              description: 'Seules les données nécessaires au fonctionnement de l\'application',
            ),
            SizedBox(height: 12),
            _buildHighlightCard(
              icon: Icons.lock_outline,
              title: 'Sécurité maximale',
              description: 'Chiffrement de bout en bout et stockage sécurisé',
            ),
            SizedBox(height: 12),
            _buildHighlightCard(
              icon: Icons.person_outline,
              title: 'Contrôle total',
              description: 'Vous pouvez accéder, modifier ou supprimer vos données à tout moment',
            ),
            SizedBox(height: 32),

            // Section 1
            _buildSectionTitle('1. Collecte de données'),
            SizedBox(height: 12),
            _buildContentCard(
              content: '''Nous collectons uniquement les données nécessaires pour vous offrir la meilleure expérience :

• Informations de profil (nom, email, préférences alimentaires)
• Historique de navigation dans l'application
• Données de santé que vous choisissez de partager
• Préférences de contenu et interactions''',
            ),
            SizedBox(height: 24),

            // Section 2
            _buildSectionTitle('2. Utilisation des données'),
            SizedBox(height: 12),
            _buildContentCard(
              content: '''Vos données nous permettent de :

• Personnaliser vos recommandations de recettes
• Améliorer continuellement notre service
• Vous envoyer des notifications pertinentes
• Assurer la sécurité de votre compte''',
            ),
            SizedBox(height: 24),

            // Section 3 - RGPD Rights Grid
            _buildSectionTitle('3. Vos droits RGPD'),
            SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildRightsCard(
                  icon: Icons.visibility_outlined,
                  title: 'Accès',
                  description: 'Consulter vos données',
                ),
                _buildRightsCard(
                  icon: Icons.edit_outlined,
                  title: 'Rectification',
                  description: 'Modifier vos informations',
                ),
                _buildRightsCard(
                  icon: Icons.delete_outline,
                  title: 'Effacement',
                  description: 'Supprimer votre compte',
                ),
                _buildRightsCard(
                  icon: Icons.download_outlined,
                  title: 'Portabilité',
                  description: 'Exporter vos données',
                ),
              ],
            ),
            SizedBox(height: 24),

            // Section 4
            _buildSectionTitle('4. Partage des données'),
            SizedBox(height: 12),
            _buildContentCard(
              content: '''Nous ne vendons jamais vos données personnelles.

Elles peuvent être partagées uniquement avec :
• Nos prestataires techniques hébergés en UE
• Les autorités légales si requis par la loi
• Vos créateurs favoris (uniquement avec votre consentement explicite)''',
            ),
            SizedBox(height: 24),

            // Section 5
            _buildSectionTitle('5. Conservation'),
            SizedBox(height: 12),
            _buildContentCard(
              content: '''Vos données sont conservées :
• Tant que votre compte est actif
• Jusqu'à 3 ans après votre dernière connexion
• Immédiatement supprimées après demande de suppression de compte''',
            ),
            SizedBox(height: 24),

            // Contact Card
            _buildSectionTitle('Contact DPO'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(20),
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
                      Icon(Icons.mail_outline, color: AkeliColors.primary, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'dpo@akeli.app',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Notre délégué à la protection des données répond sous 48h ouvrées à toute demande concernant vos données personnelles.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AkeliColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Version Badge
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AkeliColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'Version 1.0 • Dernière mise à jour: Janvier 2026',
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AkeliColors.primary, AkeliColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(AkeliRadius.md),
            ),
            child: Icon(icon, color: AkeliColors.onPrimary, size: 24),
          ),
          SizedBox(width: 16),
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
                SizedBox(height: 4),
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
      padding: EdgeInsets.all(20),
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
      padding: EdgeInsets.all(16),
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
          SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AkeliColors.onSurface,
            ),
          ),
          SizedBox(height: 4),
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
