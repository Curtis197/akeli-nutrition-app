import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

/// Terms of Service Page - Editorial Design
/// Displays terms and conditions with articles on access, data collection, IP rights, and liability
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Service',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AkeliColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        // Trailing placeholder for balance as per design
        actions: const [SizedBox(width: 48)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AkeliSpacing.lg,
          32,
          AkeliSpacing.lg,
          128,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AkeliSpacing.xl),
            
            // Hero Title Section
            Text(
              'Conditions Générales d\'Utilisation',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AkeliColors.onSurface,
                letterSpacing: -1.5,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AkeliSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AkeliSpacing.md,
                vertical: AkeliSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history,
                    color: AkeliColors.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: AkeliSpacing.xs),
                  Text(
                    'En vigueur au 15 Mars 2024',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AkeliColors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),

            // Article 1: Access
            _buildArticle(
              icon: Icons.login_outlined,
              title: 'Article 1 : Accès au site',
              paragraphs: [
                'L\'accès au service est réservé aux personnes majeures et capables juridiquement de souscrire des contrats en droit français. Nous nous efforçons de maintenir un accès continu au site, 7 jours sur 7 et 24 heures sur 24.',
                'Toutefois, l\'accès peut être temporairement suspendu pour des raisons de maintenance, de mise à jour ou en raison de circonstances indépendantes de notre volonté (force majeure). La responsabilité de l\'éditeur ne saurait être engagée en cas d\'impossibilité d\'accès.',
              ],
            ),
            const SizedBox(height: AkeliSpacing.lg),

            // Article 2: Data Collection
            _buildArticle(
              icon: Icons.lock_outline,
              title: 'Article 2 : Collecte des données',
              paragraphs: [
                'Le site assure à l\'utilisateur une collecte et un traitement d\'informations personnelles dans le respect de la vie privée conformément à la loi n°78-17 du 6 janvier 1978 relative à l\'informatique, aux fichiers et aux libertés, ainsi qu\'au Règlement Général sur la Protection des Données (RGPD).',
                'Vous disposez d\'un droit d\'accès, de rectification, de suppression et d\'opposition de vos données personnelles. L\'exercice de ce droit s\'effectue via votre espace personnel ou en contactant notre service dédié.',
              ],
            ),
            const SizedBox(height: AkeliSpacing.lg),

            // Article 3: Intellectual Property
            _buildArticle(
              icon: Icons.copyright_outlined,
              title: 'Article 3 : Propriété intellectuelle',
              paragraphs: [
                'Les marques, logos, signes ainsi que l\'ensemble des contenus du site (textes, images, son) font l\'objet d\'une protection par le Code de la propriété intellectuelle et plus particulièrement par le droit d\'auteur.',
                'L\'utilisateur doit solliciter l\'autorisation préalable du site pour toute reproduction, publication, copie des différents contenus. Il s\'engage à une utilisation des contenus du site dans un cadre strictement privé. Toute utilisation à des fins commerciales est strictement interdite.',
              ],
            ),
            const SizedBox(height: AkeliSpacing.lg),

            // Article 4: Liability
            _buildArticle(
              icon: Icons.gavel_outlined,
              title: 'Article 4 : Responsabilité',
              paragraphs: [
                'Les sources des informations diffusées sur le site sont réputées fiables mais le site ne garantit pas qu\'il soit exempt de défauts, d\'erreurs ou d\'omissions. Les informations communiquées sont présentées à titre indicatif et général sans valeur contractuelle.',
                'Le site ne peut être tenu responsable de l\'utilisation et de l\'interprétation de l\'information contenue dans ce site. La responsabilité de l\'éditeur ne peut être engagée en cas de force majeure ou du fait imprévisible et insurmontable d\'un tiers.',
              ],
            ),
            const SizedBox(height: AkeliSpacing.xxl),

            // Bottom Action Button
            SizedBox(
              width: double.infinity,
              child: Material(
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AkeliColors.primary,
                          AkeliColors.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AkeliColors.primary.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Retour à l\'accueil',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildArticle({
    required IconData icon,
    required String title,
    required List<String> paragraphs,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AkeliColors.onSurface.withValues(alpha: 0.02),
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
              Icon(
                icon,
                color: AkeliColors.primary,
                size: 28,
              ),
              const SizedBox(width: AkeliSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AkeliSpacing.lg),
          ...paragraphs.map((paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: AkeliSpacing.md),
            child: Text(
              paragraph,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AkeliColors.onSurface.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
