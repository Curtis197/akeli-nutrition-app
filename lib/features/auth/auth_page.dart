import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/akeli_gradient_button.dart';
import '../../core/logger.dart';
import '../../l10n/app_localizations.dart';
import 'google_web_signin_button.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _isLogin = false; // false = sign-up tab, true = login tab

  // Sign-up fields
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _signUpConfirm = TextEditingController();
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmVisible = false;
  final _signUpKey = GlobalKey<FormState>();

  // Login fields
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _loginPasswordVisible = false;
  final _loginKey = GlobalKey<FormState>();

  String? _errorMessage;

  final _logger = appLogger;

  @override
  void dispose() {
    _logger.provider('_AuthPageState disposed');
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _signUpConfirm.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context);
    _logger.userAction('Sign-up form submitted', screen: 'AuthPage',
        metadata: {'email_masked': LogHelper.maskEmail(_signUpEmail.text.trim())});
    _logger.auth('signUp triggered from AuthPage | email: ${LogHelper.maskEmail(_signUpEmail.text.trim())}');
    if (!_signUpKey.currentState!.validate()) return;
    _logger.d('AuthPage: sign-up form validation passed');
    setState(() => _errorMessage = null);
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _signUpEmail.text.trim(),
          password: _signUpPassword.text,
        );
    if (!mounted) return;
    final s = ref.read(authNotifierProvider);
    if (s.hasError) {
      _logger.auth('signUp ERROR displayed to user | error: ${s.error}');
      setState(() => _errorMessage = _friendly(s.error.toString(), l10n));
    } else {
      _logger.auth('signUp SUCCESS | navigating to onboarding');
      context.go(AkeliRoutes.onboarding);
    }
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    _logger.userAction('Login form submitted', screen: 'AuthPage',
        metadata: {'email_masked': LogHelper.maskEmail(_loginEmail.text.trim())});
    _logger.auth('signIn triggered from AuthPage | email: ${LogHelper.maskEmail(_loginEmail.text.trim())}');
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _loginEmail.text.trim(),
          password: _loginPassword.text,
        );
    if (!mounted) return;
    final s = ref.read(authNotifierProvider);
    if (s.hasError) {
      _logger.auth('signIn ERROR displayed to user | error: ${s.error}');
      setState(() => _errorMessage = _friendly(s.error.toString(), l10n));
    } else {
      _logger.auth('signIn SUCCESS | router redirect will handle navigation');
    }
  }

  Future<void> _signInWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    _logger.userAction('Google Sign-In button tapped', screen: 'AuthPage');
    setState(() => _errorMessage = null);
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    final s = ref.read(authNotifierProvider);
    if (s.hasError) {
      final raw = s.error.toString();
      if (raw.contains('cancelled') || raw.contains('canceled') ||
          raw.contains('sign_in_canceled')) {
        return;
      }
      _logger.auth('Google signIn ERROR displayed | error: $raw');
      setState(() => _errorMessage = _friendly(raw, l10n));
    } else {
      _logger.auth('Google signIn SUCCESS | router redirect will handle navigation');
    }
  }

  String _friendly(String raw, AppLocalizations l10n) {
    if (raw.contains('Invalid login credentials')) return l10n.authErrorInvalidCredentials;
    if (raw.contains('User already registered')) return l10n.authErrorEmailInUse;
    if (raw.contains('Password should be')) return l10n.authErrorPasswordShort;
    if (raw.contains('email_not_confirmed') ||
        raw.toLowerCase().contains('email not confirmed')) {
      return l10n.authErrorEmailNotConfirmed;
    }
    if (raw.contains('sign_in_failed') || raw.contains('ApiException') ||
        raw.contains('Google Sign-In')) {
      return l10n.authErrorGoogleSignIn;
    }
    return l10n.authErrorGeneric;
  }

  Future<void> _handleForgotPassword() async {
    final l10n = AppLocalizations.of(context);
    final email = _loginEmail.text.trim();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController(text: email);
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          backgroundColor: AkeliColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.localeName == 'en' ? 'Reset Password' : 'Mot de passe oublié',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.localeName == 'en'
                      ? 'Enter your email address to receive a password reset link.'
                      : 'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
                  style: GoogleFonts.inter(fontSize: 14, color: AkeliColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 15, color: AkeliColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined, color: AkeliColors.outline, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AkeliColors.surfaceContainerLow,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.localeName == 'en' ? 'Email is required' : 'L\'email est requis';
                    }
                    if (!v.contains('@')) {
                      return l10n.localeName == 'en' ? 'Invalid email format' : 'Email invalide';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.localeName == 'en' ? 'Cancel' : 'Annuler',
                style: GoogleFonts.inter(color: AkeliColors.outline, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, ctrl.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AkeliColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                l10n.localeName == 'en' ? 'Send' : 'Envoyer',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _errorMessage = null);
      try {
        await ref.read(authNotifierProvider.notifier).resetPassword(result);
        if (!mounted) return;
        
        final s = ref.read(authNotifierProvider);
        if (s.hasError) {
          setState(() => _errorMessage = s.error.toString());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.localeName == 'en'
                  ? 'A password reset link has been sent to $result'
                  : 'Un lien de réinitialisation a été envoyé à $result'),
              backgroundColor: AkeliColors.primary,
            ),
          );
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('_AuthPageState build() | tab: ${_isLogin ? "login" : "signup"}');
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      if (!kIsWeb) return;
      if (next.hasError && previous?.hasError != true) {
        final raw = next.error.toString();
        if (raw.contains('cancelled') || raw.contains('canceled')) return;
        _logger.auth('Google signIn (web) ERROR displayed | error: $raw');
        setState(() => _errorMessage = _friendly(raw, AppLocalizations.of(context)));
      }
    });

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AkeliColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AkeliSpacing.lg, vertical: AkeliSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: AkeliSpacing.xxl),
              // Brand Header
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
                l10n.authWelcome,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AkeliSpacing.xl),
              // Auth Card
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
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Thin gradient accent stripe at top of card
                    Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AkeliColors.primary,
                            AkeliColors.primaryContainer
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AkeliSpacing.lg),
                      child: Column(
                        children: [
                          const SizedBox(height: AkeliSpacing.sm),
                          // Pill Tab Bar
                          _PillTabBar(
                            isLogin: _isLogin,
                            onToggle: (v) => setState(() {
                              _logger.userAction('Auth tab toggled', screen: 'AuthPage', metadata: {'tab': v ? 'login' : 'signup'});
                              _isLogin = v;
                              _errorMessage = null;
                            }),
                          ),
                          const SizedBox(height: AkeliSpacing.xl),
                          // Error Banner
                          if (_errorMessage != null) ...[
                            _ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: AkeliSpacing.md),
                          ],
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 200),
                            crossFadeState: _isLogin
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: _SignUpForm(
                              key: const ValueKey('signup'),
                              formKey: _signUpKey,
                              emailCtrl: _signUpEmail,
                              passwordCtrl: _signUpPassword,
                              confirmCtrl: _signUpConfirm,
                              passwordVisible: _signUpPasswordVisible,
                              confirmVisible: _signUpConfirmVisible,
                              onTogglePassword: () => setState(() =>
                                  _signUpPasswordVisible = !_signUpPasswordVisible),
                              onToggleConfirm: () => setState(() =>
                                  _signUpConfirmVisible = !_signUpConfirmVisible),
                              onSubmit: isLoading ? null : _signUp,
                              isLoading: isLoading,
                            ),
                            secondChild: _LoginForm(
                              key: const ValueKey('login'),
                              formKey: _loginKey,
                              emailCtrl: _loginEmail,
                              passwordCtrl: _loginPassword,
                              passwordVisible: _loginPasswordVisible,
                              onTogglePassword: () => setState(() =>
                                  _loginPasswordVisible = !_loginPasswordVisible),
                              onSubmit: isLoading ? null : _signIn,
                              onForgotPassword: _handleForgotPassword,
                              isLoading: isLoading,
                            ),
                          ),
                          const SizedBox(height: AkeliSpacing.lg),
                          const _OrDivider(),
                          const SizedBox(height: AkeliSpacing.md),
                          kIsWeb
                              ? GoogleWebSignInButton(isLoading: isLoading)
                              : _GoogleSignInButton(
                                  onPressed: isLoading ? null : _signInWithGoogle,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pill Tab Bar
// ---------------------------------------------------------------------------

class _PillTabBar extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onToggle;
  const _PillTabBar({required this.isLogin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _Tab(
          label: l10n.authSignUp,
          active: !isLogin,
          onTap: () => onToggle(false),
        ),
        const SizedBox(width: AkeliSpacing.sm),
        _Tab(
          label: l10n.authLogIn,
          active: isLogin,
          onTap: () => onToggle(true),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AkeliColors.secondaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AkeliRadius.pill),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active
                  ? AkeliColors.primaryContainer
                  : AkeliColors.outline,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error Banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AkeliColors.error, size: 16),
          const SizedBox(width: AkeliSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: AkeliColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign-Up Form
// ---------------------------------------------------------------------------

class _SignUpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool passwordVisible;
  final bool confirmVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback? onSubmit;
  final bool isLoading;

  const _SignUpForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.passwordVisible,
    required this.confirmVisible,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.authCreateAccount,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.authJoinCommunity,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _AuthField(
            controller: emailCtrl,
            placeholder: l10n.authEmailPlaceholder,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.authEmailRequired;
              if (!v.contains('@')) return l10n.authEmailInvalid;
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          _AuthField(
            controller: passwordCtrl,
            placeholder: l10n.authPasswordCreate,
            icon: Icons.lock_outline_rounded,
            obscureText: !passwordVisible,
            suffixIcon: _VisibilityToggle(
                visible: passwordVisible, onTap: onTogglePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.authPasswordRequired;
              if (v.length < 8) return l10n.authPasswordMinLength;
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          _AuthField(
            controller: confirmCtrl,
            placeholder: l10n.authConfirmPassword,
            icon: Icons.lock_outline_rounded,
            obscureText: !confirmVisible,
            suffixIcon: _VisibilityToggle(
                visible: confirmVisible, onTap: onToggleConfirm),
            validator: (v) {
              if (v != passwordCtrl.text) return l10n.authPasswordMismatch;
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.xl),
          AkeliGradientButton(
            label: l10n.authGetStarted,
            onPressed: onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login Form
// ---------------------------------------------------------------------------

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSubmit;
  final VoidCallback? onForgotPassword;
  final bool isLoading;

  const _LoginForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.authWelcomeBack,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.authSignInToAccount,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _AuthField(
            controller: emailCtrl,
            placeholder: l10n.authEmailField,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.authEmailRequired;
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          _AuthField(
            controller: passwordCtrl,
            placeholder: l10n.authPasswordField,
            icon: Icons.lock_outline_rounded,
            obscureText: !passwordVisible,
            suffixIcon: _VisibilityToggle(
                visible: passwordVisible, onTap: onTogglePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.authPasswordRequired;
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AkeliColors.primary,
                padding: const EdgeInsets.symmetric(
                    vertical: AkeliSpacing.sm),
              ),
              child: Text(
                l10n.authForgotPassword,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          AkeliGradientButton(
            label: l10n.authSignIn,
            onPressed: onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Auth Field
// ---------------------------------------------------------------------------

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const _AuthField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.inter(fontSize: 15, color: AkeliColors.onSurface),
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: Icon(icon, color: AkeliColors.outline, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: AkeliColors.primaryContainer.withValues(alpha: 0.4),
              width: 2),
        ),
        filled: true,
        fillColor: AkeliColors.surfaceContainerLow,
      ),
      validator: validator,
    );
  }
}

// ---------------------------------------------------------------------------
// Visibility Toggle
// ---------------------------------------------------------------------------

class _VisibilityToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _VisibilityToggle({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: AkeliColors.outline,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Or Divider
// ---------------------------------------------------------------------------

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AkeliColors.outline, thickness: 0.5),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
          child: Text(
            l10n.authOrDivider,
            style: GoogleFonts.inter(fontSize: 13, color: AkeliColors.outline),
          ),
        ),
        const Expanded(
          child: Divider(color: AkeliColors.outline, thickness: 0.5),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Google Sign-In Button
// ---------------------------------------------------------------------------

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: AkeliColors.outline.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: AkeliColors.surfaceContainerLow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
          ),
          const SizedBox(width: AkeliSpacing.sm),
          Text(
            l10n.authContinueWithGoogle,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AkeliColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
