import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';

/// Referral Management Page - Editorial Design
/// Displays user's referral code, stats, and allows code customization
class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final _logger = appLogger;
  final _codeController = TextEditingController(text: 'AKELI-SOFI');
  int _referralCount = 3;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _logger.provider('ReferralPage build()');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _logger.provider('ReferralPage disposed');
    super.dispose();
  }

  Future<void> _saveCode() async {
    _logger.userAction('Save referral code tapped', screen: 'ReferralPage');
    setState(() => _isSaving = true);

    // TODO: Integrate with referral edge function
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code mis à jour avec succès!'),
          backgroundColor: AkeliColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AkeliColors.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Parrainage',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AkeliColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        actions: const [SizedBox(width: 40)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AkeliSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AkeliSpacing.xl),

            // Hero Card - Referral Code Display
            Container(
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerLowest,
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
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AkeliColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.redeem,
                      color: AkeliColors.primary,
                      size: 32,
                      fill: 1,
                    ),
                  ),
                  const SizedBox(height: AkeliSpacing.lg),
                  Text(
                    'Votre code de parrainage',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AkeliColors.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AkeliSpacing.sm),
                  Text(
                    _isEditing ? '' : 'AKELI-SOFI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AkeliColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: AkeliSpacing.sm),
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AkeliColors.primary,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: AkeliColors.surfaceContainerHigh,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AkeliSpacing.md,
                          vertical: AkeliSpacing.sm,
                        ),
                      ),
                      autofocus: true,
                    ),
                  ],
                  const SizedBox(height: AkeliSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AkeliSpacing.md,
                      vertical: AkeliSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F1C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          color: Color(0xFFFF9F1C),
                          size: 16,
                        ),
                        const SizedBox(width: AkeliSpacing.xs),
                        Text(
                          '$_referralCount filleul(s)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF9F1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),

            // Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partagez l\'Oasis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AkeliSpacing.sm),
                  Text(
                    'Invitez vos amis à découvrir Akeli Oasis. Pour chaque ami qui s\'inscrit avec votre code, vous recevrez une invitation à un rituel de bien-être exclusif, et ils bénéficieront d\'un accueil privilégié.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AkeliColors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),

            // Change Code Section
            Container(
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerLowest,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Changer de code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AkeliSpacing.lg),
                  if (!_isEditing)
                    SizedBox(
                      height: 56,
                      child: Material(
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _logger.userAction('Edit referral code tapped', screen: 'ReferralPage');
                            setState(() => _isEditing = true);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AkeliColors.primary,
                                  AkeliColors.primaryContainer,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AkeliColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AkeliSpacing.sm),
                                  Text(
                                    'Modifier le code',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Nouveau code',
                        labelStyle: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                        hintText: 'Entrez un nouveau code',
                        hintStyle: GoogleFonts.inter(
                          color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: AkeliSpacing.md),
                    SizedBox(
                      height: 56,
                      child: Material(
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isSaving ? null : _saveCode,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AkeliColors.primary,
                                  AkeliColors.primaryContainer,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AkeliColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Enregistrer',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
