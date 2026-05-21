import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';

final _logger = appLogger;

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
  void initState() {
    super.initState();
    _logger.provider('SupportPage build()');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _logger.provider('SupportPage disposed');
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _logger.provider('SupportPage | form validation failed');
      return;
    }

    _logger.userAction('Submit support ticket tapped', screen: 'SupportPage');

    setState(() => _isSubmitting = true);

    try {
      // TODO: Integrate with support edge function
      await Future.delayed(const Duration(seconds: 1));

      _logger.provider('SupportPage | ticket submitted');

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
    } catch (e, stackTrace) {
      _logger.provider('SupportPage | submit error | $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi. Veuillez réessayer.'),
            backgroundColor: AkeliColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AkeliRadius.lg),
            ),
          ),
        );
      }
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
          icon: Icon(Icons.arrow_back_ios_new, color: AkeliColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Support',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AkeliColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                    Icon(
                      Icons.support_agent_rounded,
                      size: 48,
                      color: AkeliColors.onPrimary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Comment pouvons-nous vous aider?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AkeliColors.onPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Notre équipe est là pour répondre à vos questions',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AkeliColors.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              
              // Name field
              Text(
                'Nom complet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Votre nom',
                  filled: true,
                  fillColor: AkeliColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // Email field
              Text(
                'Email',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'votre@email.com',
                  filled: true,
                  fillColor: AkeliColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // Message field
              Text(
                'Message',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Décrivez votre problème...',
                  filled: true,
                  fillColor: AkeliColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    borderSide: BorderSide(color: AkeliColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre message';
                  }
                  if (value.length < 10) {
                    return 'Le message doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              
              // Screenshot upload button
              OutlinedButton.icon(
                onPressed: () {
                  _logger.userAction('Add screenshot tapped', screen: 'SupportPage');
                  // TODO: Implement image picker
                },
                icon: Icon(Icons.add_photo_alternate_outlined, color: AkeliColors.primary),
                label: Text(
                  'Ajouter une capture d\'écran',
                  style: GoogleFonts.plusJakartaSans(
                    color: AkeliColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                  side: BorderSide(color: AkeliColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.lg),
                  ),
                ),
              ),
              SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                    backgroundColor: _isSubmitting ? AkeliColors.outline : AkeliColors.primary,
                    foregroundColor: AkeliColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AkeliColors.onPrimary),
                          ),
                        )
                      : Text(
                          'Envoyer le message',
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
      ),
    );
  }
}
