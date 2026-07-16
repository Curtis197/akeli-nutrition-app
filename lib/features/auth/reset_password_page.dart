import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/akeli_gradient_button.dart';
import '../../l10n/app_localizations.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .recoveryUpdatePassword(_passwordCtrl.text.trim());
      
      if (!mounted) return;

      final s = ref.read(authNotifierProvider);
      if (s.hasError) {
        setState(() => _errorMessage = s.error.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetPasswordSuccess),
            backgroundColor: AkeliColors.primary,
          ),
        );
        context.go(AkeliRoutes.home);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AkeliSpacing.lg, vertical: AkeliSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AKELI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AkeliColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.resetPasswordTitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AkeliSpacing.xl),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AkeliRadius.xl),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F1B1C16),
                        blurRadius: 48,
                        offset: Offset(0, 24),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AkeliSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AkeliSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: AkeliSpacing.md),
                        ],
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: !_passwordVisible,
                          style: GoogleFonts.inter(
                              fontSize: 15, color: AkeliColors.onSurface),
                          decoration: InputDecoration(
                            hintText: l10n.resetPasswordNewHint,
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AkeliColors.outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AkeliColors.outline,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _passwordVisible = !_passwordVisible),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AkeliColors.surfaceContainerLow,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.resetPasswordRequired;
                            }
                            if (v.length < 8) {
                              return l10n.resetPasswordTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AkeliSpacing.md),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: !_confirmVisible,
                          style: GoogleFonts.inter(
                              fontSize: 15, color: AkeliColors.onSurface),
                          decoration: InputDecoration(
                            hintText: l10n.resetPasswordConfirmHint,
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AkeliColors.outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AkeliColors.outline,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _confirmVisible = !_confirmVisible),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AkeliColors.surfaceContainerLow,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.resetPasswordConfirmRequired;
                            }
                            if (v != _passwordCtrl.text) {
                              return l10n.resetPasswordMismatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AkeliSpacing.lg),
                        AkeliGradientButton(
                          label: l10n.resetPasswordSubmit,
                          onPressed: _onSubmit,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
