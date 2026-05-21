import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';

final _logger = appLogger;

/// Terms of Service Page - Editorial Design
/// Displays terms and conditions with articles on access, data collection, IP rights, and liability
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.provider('TermsOfServicePage build()');
    
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
          'Conditions Générales',
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
                  colors: [AkeliColors.secondary, AkeliColors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AkeliRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_rounded, size: 48, color: AkeliColors.onSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Bienvenue sur Akeli',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'En utilisant notre application, vous acceptez ces conditions',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AkeliColors.onSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Article 1
            _buildArticleCard(
              number: '1',
              title: 'Accès au service',
              content: '''Akeli est une application mobile gratuite dédiée à la nutrition africaine et aux recettes traditionnelles.

L'accès au service nécessite :
• Un smartphone compatible iOS ou Android
• Une connexion internet pour synchroniser les données
• La création d'un compte utilisateur

Certaines fonctionnalités premium (Fan Mode, plans personnalisés) sont accessibles via abonnement.''',
            ),
            SizedBox(height: 16),

            // Article 2
            _buildArticleCard(
              number: '2',
              title: 'Compte utilisateur',
              content: '''Vous êtes responsable de :
• La confidentialité de vos identifiants
• L'exactitude des informations fournies
• Toutes les activités effectuées depuis votre compte

Nous nous réservons le droit de suspendre ou supprimer tout compte en cas de violation des présentes conditions.''',
            ),
            SizedBox(height: 16),

            // Article 3
            _buildArticleCard(
              number: '3',
              title: 'Propriété intellectuelle',
              content: '''Tous les contenus présents sur Akeli (recettes, textes, images, logos) sont la propriété exclusive d'Akeli ou de ses partenaires.

Interdictions :
• Reproduction sans autorisation
• Utilisation commerciale non autorisée
• Modification ou altération des contenus

Les créateurs conservent les droits sur leurs recettes publiées.''',
            ),
            SizedBox(height: 16),

            // Article 4
            _buildArticleCard(
              number: '4',
              title: 'Responsabilité',
              content: '''Akeli fournit des informations nutritionnelles à titre indicatif uniquement.

Nous ne pouvons être tenus responsables :
• Des erreurs dans les informations nutritionnelles
• Des réactions allergiques ou problèmes de santé liés aux recettes
• Des interruptions temporaires du service pour maintenance

Consultez toujours un professionnel de santé pour des conseils médicaux.''',
            ),
            SizedBox(height: 16),

            // Article 5
            _buildArticleCard(
              number: '5',
              title: 'Abonnements et paiements',
              content: '''Les abonnements Fan Mode (€3/mois) sont facturés mensuellement via les stores (Google Play / App Store).

• Résiliation possible à tout moment
• Accès maintenu jusqu'à la fin de période payée
• Aucun remboursement partiel

Les créateurs reçoivent 70% des revenus générés par leurs abonnés.''',
            ),
            SizedBox(height: 16),

            // Article 6
            _buildArticleCard(
              number: '6',
              title: 'Modifications',
              content: '''Nous nous réservons le droit de modifier ces conditions à tout moment.

Les utilisateurs seront notifiés :
• Par notification push pour changements majeurs
• Par email si modification impacte les données personnelles

La poursuite de l'utilisation vaut acceptation des nouvelles conditions.''',
            ),
            SizedBox(height: 24),

            // Contact Section
            _buildSectionTitle('Contact'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AkeliRadius.lg),
                border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: AkeliColors.secondary, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'legal@akeli.app',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
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
                  color: AkeliColors.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'Version 1.0 • Dernière mise à jour: Janvier 2026',
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: AkeliColors.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AkeliColors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  gradient: LinearGradient(
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
              SizedBox(width: 12),
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
          SizedBox(height: 16),
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
