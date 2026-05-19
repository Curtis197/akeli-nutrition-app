import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/akeli_gradient_button.dart';

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

  @override
  void dispose() {
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _signUpConfirm.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_signUpKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _signUpEmail.text.trim(),
          password: _signUpPassword.text,
        );
    if (!mounted) return;
    final s = ref.read(authNotifierProvider);
    if (s.hasError) {
      setState(() => _errorMessage = _friendly(s.error.toString()));
    } else {
      context.go(AkeliRoutes.onboarding);
    }
  }

  Future<void> _signIn() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _loginEmail.text.trim(),
          password: _loginPassword.text,
        );
    if (!mounted) return;
    final s = ref.read(authNotifierProvider);
    if (s.hasError) {
      setState(() => _errorMessage = _friendly(s.error.toString()));
    }
    // Router redirect handles /home on success
  }

  String _friendly(String raw) {
    if (raw.contains('Invalid login credentials')) return 'Email ou mot de passe incorrect.';
    if (raw.contains('User already registered')) return 'Cet email est déjà utilisé.';
    if (raw.contains('Password should be')) return 'Le mot de passe doit contenir au moins 6 caractères.';
    if (raw.contains('email_not_confirmed') ||
        raw.toLowerCase().contains('email not confirmed')) {
      return 'Veuillez confirmer votre adresse email avant de vous connecter.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
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
                'Bienvenue sur Akeli',
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
                          // Forms — animated switch between sign-up and login
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isLogin
                                ? _LoginForm(
                                    key: const ValueKey('login'),
                                    formKey: _loginKey,
                                    emailCtrl: _loginEmail,
                                    passwordCtrl: _loginPassword,
                                    passwordVisible: _loginPasswordVisible,
                                    onTogglePassword: () => setState(() =>
                                        _loginPasswordVisible =
                                            !_loginPasswordVisible),
                                    onSubmit: isLoading ? null : _signIn,
                                    isLoading: isLoading,
                                  )
                                : _SignUpForm(
                                    key: const ValueKey('signup'),
                                    formKey: _signUpKey,
                                    emailCtrl: _signUpEmail,
                                    passwordCtrl: _signUpPassword,
                                    confirmCtrl: _signUpConfirm,
                                    passwordVisible: _signUpPasswordVisible,
                                    confirmVisible: _signUpConfirmVisible,
                                    onTogglePassword: () => setState(() =>
                                        _signUpPasswordVisible =
                                            !_signUpPasswordVisible),
                                    onToggleConfirm: () => setState(() =>
                                        _signUpConfirmVisible =
                                            !_signUpConfirmVisible),
                                    onSubmit: isLoading ? null : _signUp,
                                    isLoading: isLoading,
                                  ),
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
    return Row(
      children: [
        _Tab(
          label: "S'inscrire",
          active: !isLogin,
          onTap: () => onToggle(false),
        ),
        const SizedBox(width: AkeliSpacing.sm),
        _Tab(
          label: 'Se connecter',
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
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Créer votre compte',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Rejoignez la communauté Akeli',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _AuthField(
            controller: emailCtrl,
            placeholder: 'Entrez votre email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          _AuthField(
            controller: passwordCtrl,
            placeholder: 'Créez un mot de passe',
            icon: Icons.lock_outline_rounded,
            obscureText: !passwordVisible,
            suffixIcon: _VisibilityToggle(
                visible: passwordVisible, onTap: onTogglePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              if (v.length < 8) return 'Minimum 8 caractères';
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          _AuthField(
            controller: confirmCtrl,
            placeholder: 'Confirmez le mot de passe',
            icon: Icons.lock_outline_rounded,
            obscureText: !confirmVisible,
            suffixIcon: _VisibilityToggle(
                visible: confirmVisible, onTap: onToggleConfirm),
            validator: (v) {
              if (v != passwordCtrl.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.xl),
          AkeliGradientButton(
            label: 'Commencer',
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
  final bool isLoading;

  const _LoginForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Heureux de vous revoir !',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Connectez-vous à votre compte',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _AuthField(
            controller: emailCtrl,
            placeholder: 'Email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requis';
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          _AuthField(
            controller: passwordCtrl,
            placeholder: 'Mot de passe',
            icon: Icons.lock_outline_rounded,
            obscureText: !passwordVisible,
            suffixIcon: _VisibilityToggle(
                visible: passwordVisible, onTap: onTogglePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Réinitialisation du mot de passe — bientôt disponible')),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AkeliColors.primary,
                padding: const EdgeInsets.symmetric(
                    vertical: AkeliSpacing.sm),
              ),
              child: Text(
                'Mot de passe oublié ?',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          AkeliGradientButton(
            label: 'Se connecter',
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
