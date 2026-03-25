import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMessage = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      setState(() => _errorMessage = _friendlyError(state.error.toString()));
    } else if (mounted) {
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

    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      setState(() => _errorMessage = _friendlyError(state.error.toString()));
    }
    // Router redirect handles navigation to /home on success
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (raw.contains('User already registered')) {
      return 'Cet email est déjà utilisé.';
    }
    if (raw.contains('Password should be')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (raw.contains('email_not_confirmed') || raw.toLowerCase().contains('email not confirmed')) {
      return 'Veuillez confirmer votre adresse email avant de vous connecter.';
    }
    if (raw.contains('signup_email_confirmation_required')) {
      return 'Inscription réussie. Veuillez vérifier votre boîte mail pour confirmer votre compte.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AkeliSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AkeliSpacing.xxl),
              // Brand header
              Text(
                'Akeli',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AkeliColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AkeliSpacing.xs),
              Text(
                'Nutrition africaine personnalisée',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AkeliColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AkeliSpacing.xl),
              // Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AkeliSpacing.lg),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: "S'inscrire"),
                          Tab(text: 'Se connecter'),
                        ],
                      ),
                      const SizedBox(height: AkeliSpacing.lg),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(AkeliSpacing.sm),
                          margin: const EdgeInsets.only(bottom: AkeliSpacing.md),
                          decoration: BoxDecoration(
                            color: AkeliColors.error.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AkeliRadius.sm),
                            border: Border.all(
                                color: AkeliColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AkeliColors.error, size: 16),
                              const SizedBox(width: AkeliSpacing.xs),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AkeliColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 380,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _SignUpForm(
                              formKey: _signUpKey,
                              emailCtrl: _signUpEmail,
                              passwordCtrl: _signUpPassword,
                              confirmCtrl: _signUpConfirm,
                              passwordVisible: _signUpPasswordVisible,
                              confirmVisible: _signUpConfirmVisible,
                              onTogglePassword: () => setState(
                                  () => _signUpPasswordVisible = !_signUpPasswordVisible),
                              onToggleConfirm: () => setState(
                                  () => _signUpConfirmVisible = !_signUpConfirmVisible),
                              onSubmit: isLoading ? null : _signUp,
                              isLoading: isLoading,
                            ),
                            _LoginForm(
                              formKey: _loginKey,
                              emailCtrl: _loginEmail,
                              passwordCtrl: _loginPassword,
                              passwordVisible: _loginPasswordVisible,
                              onTogglePassword: () => setState(
                                  () => _loginPasswordVisible = !_loginPasswordVisible),
                              onSubmit: isLoading ? null : _signIn,
                              isLoading: isLoading,
                            ),
                          ],
                        ),
                      ),
                    ],
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
          Text('Se créer un compte',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AkeliSpacing.md),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          TextFormField(
            controller: passwordCtrl,
            obscureText: !passwordVisible,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: onTogglePassword,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              if (v.length < 8) return 'Minimum 8 caractères';
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          TextFormField(
            controller: confirmCtrl,
            obscureText: !confirmVisible,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(confirmVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: onToggleConfirm,
              ),
            ),
            validator: (v) {
              if (v != passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.xl),
          FilledButton(
            onPressed: onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Commencer'),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSubmit;
  final bool isLoading;

  const _LoginForm({
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
          Text('Heureux de vous revoir !',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AkeliSpacing.md),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requis';
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          TextFormField(
            controller: passwordCtrl,
            obscureText: !passwordVisible,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: onTogglePassword,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              return null;
            },
          ),
          const SizedBox(height: AkeliSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: navigate to forgot password
              },
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          const SizedBox(height: AkeliSpacing.md),
          FilledButton(
            onPressed: onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
