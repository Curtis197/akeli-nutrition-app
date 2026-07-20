import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mode_provider.dart';
import '../../widgets/mode_selector.dart';
import '../../l10n/app_localizations.dart';

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  final _logger = appLogger;
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  File? _screenshotFile;

  @override
  void initState() {
    super.initState();
    _logger.provider('SupportPage initState()');
    final user = ref.read(currentUserProvider);
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _logger.provider('SupportPage disposed');
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    _logger.userAction('Add screenshot tapped', screen: 'SupportPage');
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked != null) {
      setState(() => _screenshotFile = File(picked.path));
      _logger.userAction('Screenshot selected', screen: 'SupportPage',
          metadata: {'path': picked.path});
    }
  }

  Future<String?> _uploadScreenshot(String userId) async {
    if (_screenshotFile == null) return null;

    final client = ref.read(supabaseClientProvider);
    final ext = _screenshotFile!.path.split('.').last.toLowerCase();
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    _logger.edge('storage', 'BEFORE | bucket: support-screenshots | path: $fileName');
    try {
      await client.storage
          .from('support-screenshots')
          .upload(fileName, _screenshotFile!,
              fileOptions: const FileOptions(upsert: false));

      final url = client.storage
          .from('support-screenshots')
          .getPublicUrl(fileName);

      _logger.edge('storage', 'AFTER | url: $url');
      return url;
    } catch (e, st) {
      _logger.edge('storage', 'ERROR | $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      _logger.provider('SupportPage | form validation failed');
      return;
    }

    _logger.userAction('Submit support ticket tapped', screen: 'SupportPage');
    setState(() => _isSubmitting = true);

    final user = ref.read(currentUserProvider);
    final client = ref.read(supabaseClientProvider);

    try {
      String? screenshotUrl;
      if (_screenshotFile != null && user != null) {
        screenshotUrl = await _uploadScreenshot(user.id);
      }

      _logger.db(
          'BEFORE | table: support_message | op: INSERT | userId: ${user?.id}');
      await client.from('support_message').insert({
        'user_id': user?.id,
        'email': _emailController.text.trim(),
        'subject': _subjectController.text.trim(),
        'content': _messageController.text.trim(),
        if (screenshotUrl != null) 'screenshot_url': screenshotUrl,
      });
      _logger.db('AFTER | table: support_message | rows: 1');

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.supportMessageSent),
            backgroundColor: AkeliColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AkeliRadius.lg),
            ),
          ),
        );
        context.pop();
      }
    } on PostgrestException catch (e, st) {
      _logger.db(
          'ERROR | table: support_message | code: ${e.code}',
          error: e,
          stackTrace: st);
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorSnackbar();
      }
    } catch (e, st) {
      _logger.db('ERROR | support submit | unexpected | $e',
          error: e, stackTrace: st);
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorSnackbar();
      }
    }
  }

  void _showErrorSnackbar() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.supportSendError),
        backgroundColor: AkeliColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AkeliColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          ref.watch(currentModeProvider) == AppMode.beauty ? 'Support Beauté & Soins' : l10n.supportTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AkeliColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      getAppModeColor(ref.watch(currentModeProvider)),
                      getAppModeColor(ref.watch(currentModeProvider)).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AkeliRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent_rounded,
                        size: 48, color: AkeliColors.onPrimary),
                    const SizedBox(height: 16),
                    Text(
                      l10n.supportHeaderTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AkeliColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.supportHeaderSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AkeliColors.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Subject field
              Text(
                l10n.supportSubjectLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: _fieldDecoration(l10n.supportSubjectHint),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.supportSubjectRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Email field
              Text(
                l10n.accountEmail,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration(l10n.supportEmailHint),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.supportEmailRequired;
                  }
                  if (!value.contains('@')) {
                    return l10n.supportEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Message field
              Text(
                l10n.supportMessageLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: _fieldDecoration(l10n.supportMessageHint),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.supportMessageRequired;
                  }
                  if (value.length < 10) {
                    return l10n.supportMessageTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Screenshot picker
              _screenshotFile == null
                  ? OutlinedButton.icon(
                      onPressed: _pickScreenshot,
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          color: AkeliColors.primary),
                      label: Text(
                        l10n.supportAddScreenshot,
                        style: GoogleFonts.plusJakartaSans(
                          color: AkeliColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: const BorderSide(color: AkeliColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AkeliRadius.lg),
                        ),
                      ),
                    )
                  : _ScreenshotPreview(
                      file: _screenshotFile!,
                      onRemove: () {
                        _logger.userAction('Screenshot removed',
                            screen: 'SupportPage');
                        setState(() => _screenshotFile = null);
                      },
                      onReplace: _pickScreenshot,
                    ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: _isSubmitting
                        ? AkeliColors.outline
                        : AkeliColors.primary,
                    foregroundColor: AkeliColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AkeliRadius.lg),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AkeliColors.onPrimary),
                          ),
                        )
                      : Text(
                          l10n.supportSendMessage,
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

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AkeliColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        borderSide: const BorderSide(color: AkeliColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        borderSide: const BorderSide(color: AkeliColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        borderSide: const BorderSide(color: AkeliColors.primary, width: 2),
      ),
    );
  }
}

class _ScreenshotPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _ScreenshotPreview({
    required this.file,
    required this.onRemove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: AkeliColors.primary.withValues(alpha: 0.4)),
        color: AkeliColors.surfaceContainerLow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Image.file(
                file,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onReplace,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(context).supportChangeScreenshot,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AkeliColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
