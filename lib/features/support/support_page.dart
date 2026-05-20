import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

/// Support Page - Editorial Design
/// Allows users to submit support tickets with name, email, message, and screenshot upload
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // TODO: Integrate with support edge function
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message envoyé avec succès!'),
          backgroundColor: AkeliColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
          ),
        ),
      );
      Navigator.pop(context);
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
        title: Text(
          'Akeli Oasis',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AkeliColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AkeliColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AkeliSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AkeliSpacing.xl),
            
            // Header Section
            Text(
              'Support',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AkeliColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AkeliSpacing.sm),
            Text(
              'Faîtes-nous part de votre question ou problème',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AkeliColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AkeliSpacing.xxl),

            // Form Card
            Container(
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AkeliColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 48,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Input
                    _buildInputLabel('Votre nom'),
                    const SizedBox(height: AkeliSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AkeliColors.outline,
                        ),
                        hintText: 'Entrez votre nom',
                        hintStyle: GoogleFonts.inter(
                          color: AkeliColors.outline.withValues(alpha: 0.7),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AkeliSpacing.lg),

                    // Email Input
                    _buildInputLabel('Votre mail'),
                    const SizedBox(height: AkeliSpacing.sm),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: AkeliColors.outline,
                        ),
                        hintText: 'Entrez votre email',
                        hintStyle: GoogleFonts.inter(
                          color: AkeliColors.outline.withValues(alpha: 0.7),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!value.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AkeliSpacing.lg),

                    // Message Input
                    _buildInputLabel('Votre message'),
                    const SizedBox(height: AkeliSpacing.sm),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      minLines: 4,
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Icon(
                            Icons.message_outlined,
                            color: AkeliColors.outline,
                          ),
                        ),
                        hintText: 'Décrivez votre problème...',
                        hintStyle: GoogleFonts.inter(
                          color: AkeliColors.outline.withValues(alpha: 0.7),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez décrire votre problème';
                        }
                        if (value.trim().length < 10) {
                          return 'Message trop court';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AkeliSpacing.lg),

                    // Upload Area
                    InkWell(
                      onTap: () {
                        // TODO: Implement image picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Upload screenshot - Bientôt disponible'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AkeliColors.outlineVariant.withValues(alpha: 0.5),
                            strokeAlign: BorderSide.strokeAlignInside,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: AkeliColors.surfaceContainerLow.withValues(alpha: 0.5),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AkeliColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                color: AkeliColors.primaryContainer,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: AkeliSpacing.md),
                            Text(
                              'Upload Screenshot',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AkeliColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AkeliSpacing.xs),
                            Text(
                              'PNG, JPG, max 5MB',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AkeliColors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AkeliSpacing.xl),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: Material(
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isSubmitting ? null : _submitForm,
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
                                  color: AkeliColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSubmitting)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    const Icon(
                                      Icons.receipt_long,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AkeliSpacing.sm),
                                    Text(
                                      'Envoyer',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AkeliSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AkeliColors.onSurface,
        ),
      ),
    );
  }
}
