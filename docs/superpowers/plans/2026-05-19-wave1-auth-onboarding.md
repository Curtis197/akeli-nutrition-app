# Wave 1: Auth + Onboarding Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild `AuthPage` and `OnboardingPage` to match the "Organic Editorial" stitch designs (stitch4/auth, stitch2/onboarding) with correct tokens, typography, and 6-step onboarding flow.

**Architecture:** Single-file redesigns for Auth and Onboarding; a new `OnboardingData` model/provider holds all 6-step form state; a shared `AkeliGradientButton` widget captures the teal gradient CTA pattern used everywhere.

**Tech Stack:** Flutter 3, Riverpod 2, GoRouter 14, google_fonts (PlusJakartaSans + Inter), smooth_page_indicator

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `lib/core/theme.dart` | Fix primary/primaryContainer colors, switch Outfit→PlusJakartaSans, Poppins→Inter, fix InputDecoration |
| Create | `lib/shared/widgets/akeli_gradient_button.dart` | Reusable gradient CTA button |
| Modify | `lib/features/auth/auth_page.dart` | Full redesign: AKELI header, pill tabs, no-border fields, gradient button |
| Create | `lib/features/auth/onboarding_data.dart` | `OnboardingData` model + `OnboardingNotifier` + provider |
| Modify | `lib/features/auth/onboarding_page.dart` | Full redesign: 6-step PageView, progress bar, fixed bottom nav |
| Create | `test/core/theme_test.dart` | Token value assertions |
| Create | `test/features/auth/onboarding_data_test.dart` | Provider state mutation tests |
| Create | `test/features/auth/auth_page_test.dart` | Form validation widget tests |

---

## Task 1: Fix Design Tokens in `theme.dart`

**Files:**
- Modify: `lib/core/theme.dart`
- Create: `test/core/theme_test.dart`

The stitch uses `primary: #00504A` and `primaryContainer: #006A63`. Current theme has them swapped. Also switches fonts from Outfit/Poppins to PlusJakartaSans/Inter, and adds missing `surfaceContainer` token.

- [ ] **Step 1: Write failing token tests**

Create `test/core/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/theme.dart';

void main() {
  group('AkeliColors', () {
    test('primary is deep teal #00504A', () {
      expect(AkeliColors.primary, const Color(0xFF00504A));
    });
    test('primaryContainer is #006A63', () {
      expect(AkeliColors.primaryContainer, const Color(0xFF006A63));
    });
    test('surface is warm cream #FCFAEF', () {
      expect(AkeliColors.surface, const Color(0xFFFCFAEF));
    });
    test('surfaceContainerHighest is #E4E3D8', () {
      expect(AkeliColors.surfaceContainerHighest, const Color(0xFFE4E3D8));
    });
    test('secondaryContainer is mint #C3EAE5', () {
      expect(AkeliColors.secondaryContainer, const Color(0xFFC3EAE5));
    });
  });
}
```

- [ ] **Step 2: Run to confirm failures**

```
flutter test test/core/theme_test.dart
```

Expected: 2 failures (primary and primaryContainer have wrong values).

- [ ] **Step 3: Update `AkeliColors` and add `surfaceContainer`**

In `lib/core/theme.dart`, replace the brand color block:

```dart
abstract class AkeliColors {
  // Brand — matches stitch exactly
  static const primary = Color(0xFF00504A);            // Deep teal (CTA, Active)
  static const primaryContainer = Color(0xFF006A63);   // Mid teal (gradient end, header)
  static const onPrimary = Colors.white;
  static const secondary = Color(0xFFFF9F43);          // Orange accent
  static const accentAmber = Color(0xFFFF9F1C);        // Vivid amber (CTAs/highlights)

  // Surface Philosophy — "The Organic Layer"
  static const surface = Color(0xFFFCFAEF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF6F4E9);
  static const surfaceContainer = Color(0xFFF0EEE3);
  static const surfaceContainerHigh = Color(0xFFEAE8DE);
  static const surfaceContainerHighest = Color(0xFFE4E3D8);
  static const secondaryContainer = Color(0xFFC3EAE5);
  static const onSecondaryContainer = Color(0xFF476B67);
  static const background = surface;

  // Text
  static const onSurface = Color(0xFF1B1C16);
  static const onSurfaceVariant = Color(0xFF3E4947);
  static const outline = Color(0xFF6E7977);
  static const outlineVariant = Color(0xFFBEC9C6);

  // Tertiary / amber
  static const tertiaryFixed = Color(0xFFFFDCBC);
  static const onTertiaryFixed = Color(0xFF2C1700);

  // Semantics
  static const success = Color(0xFF249689);
  static const warning = Color(0xFFF9CF58);
  static const error = Color(0xFFBA1A1A);

  // Legacy aliases (kept for transition)
  static const textPrimary = onSurface;
  static const textSecondary = onSurfaceVariant;
  static const textMuted = Color(0xFFC8C8C8);
  static const backgroundDark = Color(0xFF1A1A2E);
  static const surfaceDark = Color(0xFF16213E);
  static const textPrimaryDark = Color(0xFFF5F5F5);
  static const textSecondaryDark = Color(0xFFB0B0C0);
}
```

- [ ] **Step 4: Update `_buildTextTheme` — switch to PlusJakartaSans + Inter**

Replace the `_buildTextTheme` function:

```dart
TextTheme _buildTextTheme(Color baseColor) => TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 56, fontWeight: FontWeight.w800, color: baseColor, letterSpacing: -0.02),
      displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 40, fontWeight: FontWeight.w800, color: baseColor, letterSpacing: 0.02),
      displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w700, color: baseColor),
      headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: baseColor),
      headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: baseColor),
      headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w700, color: baseColor),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w600, color: baseColor),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: baseColor),
      titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: baseColor),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: AkeliColors.onSurfaceVariant, height: 1.6),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: AkeliColors.onSurfaceVariant),
      bodySmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400, color: AkeliColors.onSurfaceVariant),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant, letterSpacing: 0.05),
      labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: AkeliColors.onSurfaceVariant, letterSpacing: 0.05),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: AkeliColors.outlineVariant, letterSpacing: 0.08),
    );
```

- [ ] **Step 5: Fix `inputDecorationTheme` — no border, surfaceContainerHighest fill**

In `buildLightTheme()` replace `inputDecorationTheme`:

```dart
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: AkeliColors.surfaceContainerHighest,
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AkeliSpacing.md,
    vertical: AkeliSpacing.md,
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AkeliRadius.md),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AkeliRadius.md),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AkeliRadius.md),
    borderSide: const BorderSide(
        color: Color(0x66006A63), width: 2), // primary at 40%
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AkeliRadius.md),
    borderSide: const BorderSide(color: AkeliColors.error),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AkeliRadius.md),
    borderSide: const BorderSide(color: AkeliColors.error, width: 2),
  ),
  labelStyle: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AkeliColors.onSurfaceVariant,
      letterSpacing: 0.08),
  hintStyle: GoogleFonts.inter(color: AkeliColors.outline),
),
```

Also update `appBarTheme` title to use PlusJakartaSans:

```dart
titleTextStyle: GoogleFonts.plusJakartaSans(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: AkeliColors.onSurface,
),
```

And `filledButtonTheme` text style:

```dart
textStyle: GoogleFonts.plusJakartaSans(
  fontSize: 16,
  fontWeight: FontWeight.w700,
),
```

- [ ] **Step 6: Run tests — all should pass**

```
flutter test test/core/theme_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 7: Verify app still compiles**

```
flutter analyze lib/core/theme.dart
```

Expected: No errors. Fix any references to removed constants.

- [ ] **Step 8: Commit**

```bash
git add lib/core/theme.dart test/core/theme_test.dart
git commit -m "feat(theme): align tokens to stitch — primary #00504A, PlusJakartaSans/Inter typography, no-border inputs"
```

---

## Task 2: `AkeliGradientButton` shared widget

**Files:**
- Create: `lib/shared/widgets/akeli_gradient_button.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

class AkeliGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final Widget? trailing;

  const AkeliGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !isLoading;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AkeliRadius.xl),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : const LinearGradient(
                    colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: disabled ? AkeliColors.surfaceContainerHighest : null,
            borderRadius: BorderRadius.circular(AkeliRadius.xl),
            boxShadow: disabled
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x3300504A),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: SizedBox(
            height: height,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: disabled
                                ? AkeliColors.outline
                                : Colors.white,
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```
flutter analyze lib/shared/widgets/akeli_gradient_button.dart
```

Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/akeli_gradient_button.dart
git commit -m "feat(ui): add AkeliGradientButton shared widget"
```

---

## Task 3: Redesign `AuthPage`

**Files:**
- Modify: `lib/features/auth/auth_page.dart`
- Create: `test/features/auth/auth_page_test.dart`

Design reference: `stitch4/stitch_modern_dashboard_akeli_victoire/akeli_auth_login/` and `akeli_auth_sign_up/`.

Key elements:
- Scaffold background: `AkeliColors.background`
- Header: "AKELI" in PlusJakartaSans 40px bold, letter-spacing 0.05em, color `primary`
- Sub-header: "Bienvenue sur Akeli" body text
- Card: `surfaceContainerLowest`, 24px radius, ambient shadow `rgba(27,28,22,0.06)`
- Thin gradient stripe at top of card (2px, opacity 20%)
- Tabs: Row of two pill `TextButton`s — active has `secondaryContainer` fill + `primaryContainer` text; inactive is ghost
- Fields: no label (just placeholder), `surfaceContainerLow` fill, 16px radius, leading icon in `outline` color
- Submit: `AkeliGradientButton` full width
- Forgot password: center-aligned `TextButton`

- [ ] **Step 1: Write widget tests**

Create `test/features/auth/auth_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/auth/auth_page.dart';
import 'package:akeli/core/theme.dart';

// Minimal fake app to pump AuthPage without Supabase
Widget _testApp(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: buildLightTheme(),
        home: child,
      ),
    );

void main() {
  group('AuthPage', () {
    testWidgets('shows AKELI brand header', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      expect(find.text('AKELI'), findsOneWidget);
    });

    testWidgets('shows S\'inscrire and Se connecter tabs', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      expect(find.text("S'inscrire"), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('sign-up form validates empty email', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      // Tap submit without filling fields
      final btn = find.text('Commencer');
      await tester.tap(btn);
      await tester.pump();
      expect(find.text('Email requis'), findsOneWidget);
    });

    testWidgets('login form validates empty fields', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      // Switch to login tab
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Se connecter',
          skipOffstage: false)); // submit button
      await tester.pump();
      expect(find.text('Email requis'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run to confirm expected failures**

```
flutter test test/features/auth/auth_page_test.dart
```

Expected: Failures — AKELI header and S'inscrire/Se connecter tabs not found in current design.

- [ ] **Step 3: Rewrite `auth_page.dart`**

Replace the entire file with:

```dart
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
  bool _isLogin = false; // false = sign-up, true = login

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
    final s = ref.read(authNotifierProvider);
    if (s.hasError) {
      setState(() => _errorMessage = _friendly(s.error.toString()));
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
    if (raw.contains('email_not_confirmed') || raw.toLowerCase().contains('email not confirmed')) {
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
              // ── Brand Header ──────────────────────────────────
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
              // ── Auth Card ─────────────────────────────────────
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
                    // Thin gradient accent stripe
                    Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AkeliSpacing.lg),
                      child: Column(
                        children: [
                          const SizedBox(height: AkeliSpacing.sm),
                          // ── Pill Tab Bar ──────────────────────
                          _PillTabBar(
                            isLogin: _isLogin,
                            onToggle: (v) => setState(() {
                              _isLogin = v;
                              _errorMessage = null;
                            }),
                          ),
                          const SizedBox(height: AkeliSpacing.xl),
                          // ── Error Banner ──────────────────────
                          if (_errorMessage != null) ...[
                            _ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: AkeliSpacing.md),
                          ],
                          // ── Forms ─────────────────────────────
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isLogin
                                ? _LoginForm(
                                    key: const ValueKey('login'),
                                    formKey: _loginKey,
                                    emailCtrl: _loginEmail,
                                    passwordCtrl: _loginPassword,
                                    passwordVisible: _loginPasswordVisible,
                                    onTogglePassword: () => setState(
                                        () => _loginPasswordVisible = !_loginPasswordVisible),
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
                                    onTogglePassword: () => setState(
                                        () => _signUpPasswordVisible = !_signUpPasswordVisible),
                                    onToggleConfirm: () => setState(
                                        () => _signUpConfirmVisible = !_signUpConfirmVisible),
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

// ── Pill Tab Bar ─────────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AkeliColors.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? AkeliColors.primaryContainer : AkeliColors.outline,
          ),
        ),
      ),
    );
  }
}

// ── Error Banner ─────────────────────────────────────────────────────────────

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
            child: Text(message,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AkeliColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Sign-Up Form ─────────────────────────────────────────────────────────────

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
          Text('Créer votre compte',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Rejoignez la communauté Akeli',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
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
              if (v != passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
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

// ── Login Form ───────────────────────────────────────────────────────────────

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
          Text('Heureux de vous revoir !',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Connectez-vous à votre compte',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
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
              onPressed: () {},
              style: TextButton.styleFrom(
                  foregroundColor: AkeliColors.primary,
                  padding: const EdgeInsets.symmetric(
                      vertical: AkeliSpacing.sm)),
              child: Text('Mot de passe oublié ?',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500)),
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

// ── Shared Field ─────────────────────────────────────────────────────────────

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
      style: GoogleFonts.inter(
          fontSize: 15, color: AkeliColors.onSurface),
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
          borderSide: const BorderSide(color: Color(0x6600504A), width: 2),
        ),
        filled: true,
        fillColor: AkeliColors.surfaceContainerLow,
      ),
      validator: validator,
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _VisibilityToggle({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AkeliColors.outline,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}
```

- [ ] **Step 4: Run auth tests**

```
flutter test test/features/auth/auth_page_test.dart
```

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/auth_page.dart \
        lib/shared/widgets/akeli_gradient_button.dart \
        test/features/auth/auth_page_test.dart
git commit -m "feat(auth): redesign AuthPage to Organic Editorial stitch — AKELI header, pill tabs, no-border fields, gradient button"
```

---

## Task 4: `OnboardingData` model + Riverpod provider

**Files:**
- Create: `lib/features/auth/onboarding_data.dart`
- Create: `test/features/auth/onboarding_data_test.dart`

- [ ] **Step 1: Write provider tests**

Create `test/features/auth/onboarding_data_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/auth/onboarding_data.dart';

ProviderContainer _container() => ProviderContainer();

void main() {
  group('OnboardingNotifier', () {
    test('initial language is fr', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(onboardingProvider).language, 'fr');
    });

    test('updateLanguage mutates language', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(onboardingProvider.notifier).updateLanguage('en');
      expect(c.read(onboardingProvider).language, 'en');
    });

    test('updateConsent sets both flags', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(onboardingProvider.notifier)
          .updateConsent(privacy: true, cgu: true);
      final d = c.read(onboardingProvider);
      expect(d.consentPrivacy, isTrue);
      expect(d.consentCgu, isTrue);
    });

    test('updateProfile stores name and age', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(onboardingProvider.notifier)
          .updateProfile(name: 'Sophie', age: 28);
      final d = c.read(onboardingProvider);
      expect(d.name, 'Sophie');
      expect(d.age, 28);
    });

    test('canAdvance returns false when consent not given on step 2', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(onboardingProvider.notifier).canAdvance(1), isFalse);
    });

    test('canAdvance returns true on step 1 always', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(onboardingProvider.notifier).canAdvance(0), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run to confirm failures**

```
flutter test test/features/auth/onboarding_data_test.dart
```

Expected: File not found error.

- [ ] **Step 3: Create `onboarding_data.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingData {
  final String language;
  final bool consentPrivacy;
  final bool consentCgu;
  final String name;
  final int? age;
  final String? sex; // 'male' | 'female'
  final double? weight;
  final double? height;
  final String? activityLevel;
  final double? targetWeight;
  final int timelineMonths;
  final String motivations;
  final bool noPork;
  final bool noMeat;
  final bool noGluten;
  final bool noLactose;
  final List<String> allergies;
  final List<String> cuisinePreferences;

  const OnboardingData({
    this.language = 'fr',
    this.consentPrivacy = false,
    this.consentCgu = false,
    this.name = '',
    this.age,
    this.sex,
    this.weight,
    this.height,
    this.activityLevel,
    this.targetWeight,
    this.timelineMonths = 6,
    this.motivations = '',
    this.noPork = false,
    this.noMeat = false,
    this.noGluten = false,
    this.noLactose = false,
    this.allergies = const [],
    this.cuisinePreferences = const [],
  });

  OnboardingData copyWith({
    String? language,
    bool? consentPrivacy,
    bool? consentCgu,
    String? name,
    int? age,
    String? sex,
    double? weight,
    double? height,
    String? activityLevel,
    double? targetWeight,
    int? timelineMonths,
    String? motivations,
    bool? noPork,
    bool? noMeat,
    bool? noGluten,
    bool? noLactose,
    List<String>? allergies,
    List<String>? cuisinePreferences,
  }) =>
      OnboardingData(
        language: language ?? this.language,
        consentPrivacy: consentPrivacy ?? this.consentPrivacy,
        consentCgu: consentCgu ?? this.consentCgu,
        name: name ?? this.name,
        age: age ?? this.age,
        sex: sex ?? this.sex,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        activityLevel: activityLevel ?? this.activityLevel,
        targetWeight: targetWeight ?? this.targetWeight,
        timelineMonths: timelineMonths ?? this.timelineMonths,
        motivations: motivations ?? this.motivations,
        noPork: noPork ?? this.noPork,
        noMeat: noMeat ?? this.noMeat,
        noGluten: noGluten ?? this.noGluten,
        noLactose: noLactose ?? this.noLactose,
        allergies: allergies ?? this.allergies,
        cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      );
}

class OnboardingNotifier extends Notifier<OnboardingData> {
  @override
  OnboardingData build() => const OnboardingData();

  void updateLanguage(String v) =>
      state = state.copyWith(language: v);

  void updateConsent({bool? privacy, bool? cgu}) =>
      state = state.copyWith(
          consentPrivacy: privacy, consentCgu: cgu);

  void updateProfile({
    String? name,
    int? age,
    String? sex,
    double? weight,
    double? height,
    String? activityLevel,
  }) =>
      state = state.copyWith(
          name: name,
          age: age,
          sex: sex,
          weight: weight,
          height: height,
          activityLevel: activityLevel);

  void updateGoals({
    double? targetWeight,
    int? timelineMonths,
    String? motivations,
  }) =>
      state = state.copyWith(
          targetWeight: targetWeight,
          timelineMonths: timelineMonths,
          motivations: motivations);

  void updatePreferences({
    bool? noPork,
    bool? noMeat,
    bool? noGluten,
    bool? noLactose,
    List<String>? allergies,
    List<String>? cuisinePreferences,
  }) =>
      state = state.copyWith(
          noPork: noPork,
          noMeat: noMeat,
          noGluten: noGluten,
          noLactose: noLactose,
          allergies: allergies,
          cuisinePreferences: cuisinePreferences);

  /// Returns true if the user may advance from the given step index (0-based).
  bool canAdvance(int stepIndex) {
    switch (stepIndex) {
      case 0: // Language — always valid
        return true;
      case 1: // Consent — both boxes required
        return state.consentPrivacy && state.consentCgu;
      case 2: // Profile — name required
        return state.name.trim().isNotEmpty;
      case 3: // Goals — target weight required
        return state.targetWeight != null;
      case 4: // Preferences — no hard requirement
        return true;
      case 5: // Summary — always valid
        return true;
      default:
        return false;
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingData>(
        OnboardingNotifier.new);
```

- [ ] **Step 4: Run tests**

```
flutter test test/features/auth/onboarding_data_test.dart
```

Expected: 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/onboarding_data.dart \
        test/features/auth/onboarding_data_test.dart
git commit -m "feat(onboarding): add OnboardingData model and NotifierProvider with canAdvance validation"
```

---

## Task 5: Onboarding Page shell + Step 1 (Language)

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart`

This task rewrites the file with: PageView scaffold, shared progress bar + back/next bottom bar, and Step 1 (language dropdown).

- [ ] **Step 1: Rewrite `onboarding_page.dart` — shell + step 1**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/akeli_gradient_button.dart';
import 'onboarding_data.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 6;
  bool _isSubmitting = false;

  void _next() {
    final notifier = ref.read(onboardingProvider.notifier);
    if (!notifier.canAdvance(_currentStep)) return;
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _isSubmitting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.go(AkeliRoutes.home);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkeliColors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingHeader(
              step: _currentStep,
              totalSteps: _totalSteps,
              onBack: _currentStep > 0 ? _back : null,
              onSkip: () => context.go(AkeliRoutes.home),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _StepLanguage(step: _currentStep),
                  _StepConsent(step: _currentStep),
                  _StepProfile(step: _currentStep),
                  _StepGoals(step: _currentStep),
                  _StepPreferences(step: _currentStep),
                  _StepSummary(step: _currentStep),
                ],
              ),
            ),
            _OnboardingBottomBar(
              step: _currentStep,
              totalSteps: _totalSteps,
              onBack: _currentStep > 0 ? _back : null,
              onNext: _next,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header with progress bar ─────────────────────────────────────────────────

class _OnboardingHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const _OnboardingHeader({
    required this.step,
    required this.totalSteps,
    this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / totalSteps;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AkeliColors.primary,
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'AKELI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AkeliColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Passer',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.primary,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.lg),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Étape ${step + 1} sur $totalSteps',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.08),
                  ),
                  Text(
                    '${((progress) * 100).round()}%',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AkeliColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AkeliRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AkeliColors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AkeliColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AkeliSpacing.md),
      ],
    );
  }
}

// ── Bottom Navigation Bar ────────────────────────────────────────────────────

class _OnboardingBottomBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool isLoading;

  const _OnboardingBottomBar({
    required this.step,
    required this.totalSteps,
    this.onBack,
    required this.onNext,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AkeliSpacing.lg, AkeliSpacing.md, AkeliSpacing.lg, AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
              color: AkeliColors.outlineVariant.withValues(alpha: 0.2),
              width: 1),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AkeliColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AkeliRadius.xl),
                  ),
                  child: Center(
                    child: Text(
                      'Précédent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.primaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AkeliSpacing.md),
          ],
          Expanded(
            flex: onBack != null ? 2 : 1,
            child: AkeliGradientButton(
              label: isLast ? 'Commencer l\'aventure' : 'Suivant',
              onPressed: isLoading ? null : onNext,
              isLoading: isLoading,
              trailing: isLast
                  ? null
                  : const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card wrapper ──────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final Widget child;
  const _StepCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: child,
    );
  }
}

// ── Step 1: Language ─────────────────────────────────────────────────────────

class _StepLanguage extends ConsumerWidget {
  final int step;
  const _StepLanguage({required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisir votre langue',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AkeliColors.onSurface,
              letterSpacing: -0.02,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            'Veuillez sélectionner la langue de l\'interface.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LANGUE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AkeliRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AkeliSpacing.md),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: data.language,
                      isExpanded: true,
                      style: GoogleFonts.inter(
                          fontSize: 16, color: AkeliColors.onSurface),
                      dropdownColor: AkeliColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AkeliRadius.md),
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      ],
                      onChanged: (v) {
                        if (v != null) notifier.updateLanguage(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Consent ──────────────────────────────────────────────────────────

class _StepConsent extends ConsumerStatefulWidget {
  final int step;
  const _StepConsent({required this.step});

  @override
  ConsumerState<_StepConsent> createState() => _StepConsentState();
}

class _StepConsentState extends ConsumerState<_StepConsent> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue sur Akeli',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AkeliColors.primary,
              letterSpacing: -0.02,
            ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
            'Avant de plonger dans l\'expérience, prenons un instant pour clarifier la protection de votre vie privée.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              children: [
                _ConsentSection(
                  icon: 'database',
                  title: 'Données collectées',
                  items: const [
                    ('Identité et contact :', 'Nom, prénom et adresse email pour sécuriser votre compte.'),
                    ('Usage de l\'application :', 'Statistiques anonymes pour améliorer votre expérience quotidienne.'),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.lg),
                _ConsentSection(
                  icon: 'shield_person',
                  title: 'Vos droits',
                  items: const [
                    ('Accès total :', 'Consultez, modifiez ou exportez vos données à tout moment depuis les paramètres.'),
                    ('Droit à l\'oubli :', 'Suppression définitive de votre compte et de vos données sur simple demande.'),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.lg),
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: -AkeliSpacing.lg),
                  padding: const EdgeInsets.all(AkeliSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AkeliColors.surfaceContainerLow,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AkeliRadius.xl),
                      bottomRight: Radius.circular(AkeliRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      _ConsentCheckbox(
                        value: data.consentPrivacy,
                        onChanged: (v) =>
                            notifier.updateConsent(privacy: v),
                        label:
                            'J\'accepte la Politique de Confidentialité et confirme avoir lu les informations concernant le traitement de mes données personnelles (RGPD).',
                      ),
                      const SizedBox(height: AkeliSpacing.md),
                      _ConsentCheckbox(
                        value: data.consentCgu,
                        onChanged: (v) =>
                            notifier.updateConsent(cgu: v),
                        label:
                            'J\'accepte les Conditions Générales d\'Utilisation (CGU) d\'Akeli.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentSection extends StatelessWidget {
  final String icon;
  final String title;
  final List<(String, String)> items;

  const _ConsentSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AkeliColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.info_outline,
                    color: AkeliColors.onSecondaryContainer, size: 20),
              ),
            ),
            const SizedBox(width: AkeliSpacing.sm),
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurface)),
          ],
        ),
        const SizedBox(height: AkeliSpacing.md),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AkeliSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AkeliColors.primary, size: 18),
                  const SizedBox(width: AkeliSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AkeliColors.onSurfaceVariant),
                        children: [
                          TextSpan(
                              text: item.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AkeliColors.onSurface)),
                          TextSpan(text: ' ${item.$2}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AkeliColors.primary : AkeliColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AkeliColors.primary : AkeliColors.outlineVariant,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AkeliColors.onSurfaceVariant, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Profile ──────────────────────────────────────────────────────────

class _StepProfile extends ConsumerStatefulWidget {
  final int step;
  const _StepProfile({required this.step});
  @override
  ConsumerState<_StepProfile> createState() => _StepProfileState();
}

class _StepProfileState extends ConsumerState<_StepProfile> {
  late final TextEditingController _nameCtrl;

  static const _activities = [
    ('sedentary', 'Sédentaire',
        'Travail de bureau, peu ou pas d\'exercice quotidien.', Icons.weekend_rounded),
    ('light', 'Légère',
        '1-3 jours/semaine d\'exercice léger.', Icons.directions_walk_rounded),
    ('moderate', 'Modérée',
        '3-5 jours/semaine.', Icons.directions_run_rounded),
    ('active', 'Active',
        '6-7 jours/semaine.', Icons.fitness_center_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: ref.read(onboardingProvider).name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre profil',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.02)),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text('Comment vous appelez-vous ?',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AkeliColors.onSurface)),
                const SizedBox(height: AkeliSpacing.sm),
                TextField(
                  controller: _nameCtrl,
                  onChanged: (v) => notifier.updateProfile(name: v),
                  decoration: InputDecoration(
                    hintText: 'Prénom ou surnom',
                    filled: true,
                    fillColor: AkeliColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.sm),
                        borderSide: BorderSide.none),
                  ),
                  style: GoogleFonts.inter(
                      fontSize: 16, color: AkeliColors.onSurface),
                ),
                const SizedBox(height: AkeliSpacing.xl),
                // Age + Sex
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quel est votre âge ?',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface)),
                          const SizedBox(height: AkeliSpacing.sm),
                          _MetricField(
                            value: data.age?.toString() ?? '',
                            suffix: 'ans',
                            onChanged: (v) => notifier.updateProfile(
                                age: int.tryParse(v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AkeliSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sexe biologique',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface)),
                          const SizedBox(height: AkeliSpacing.sm),
                          _SexSegment(
                            value: data.sex,
                            onChanged: (v) =>
                                notifier.updateProfile(sex: v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.xl),
                // Weight + Height
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Poids',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface)),
                          const SizedBox(height: AkeliSpacing.sm),
                          _MetricField(
                            value: data.weight?.toString() ?? '',
                            suffix: 'kg',
                            onChanged: (v) => notifier.updateProfile(
                                weight: double.tryParse(v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AkeliSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Taille',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface)),
                          const SizedBox(height: AkeliSpacing.sm),
                          _MetricField(
                            value: data.height?.toString() ?? '',
                            suffix: 'cm',
                            onChanged: (v) => notifier.updateProfile(
                                height: double.tryParse(v)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.xl),
                // Activity Level
                Text('Niveau d\'activité physique',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AkeliColors.onSurface)),
                const SizedBox(height: AkeliSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AkeliSpacing.sm,
                  mainAxisSpacing: AkeliSpacing.sm,
                  childAspectRatio: 1.2,
                  children: _activities.map((a) {
                    final selected = data.activityLevel == a.$1;
                    return GestureDetector(
                      onTap: () => notifier.updateProfile(activityLevel: a.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(AkeliSpacing.md),
                        decoration: BoxDecoration(
                          color: selected
                              ? AkeliColors.secondaryContainer.withValues(alpha: 0.4)
                              : AkeliColors.surface,
                          borderRadius: BorderRadius.circular(AkeliRadius.xl),
                          border: Border.all(
                            color: selected
                                ? AkeliColors.secondaryContainer
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(a.$4,
                                    color: selected
                                        ? AkeliColors.primary
                                        : AkeliColors.onSurfaceVariant,
                                    size: 28),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? AkeliColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? AkeliColors.primary
                                          : AkeliColors.outlineVariant,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: selected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 12)
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: AkeliSpacing.sm),
                            Text(a.$2,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AkeliColors.onSurface)),
                            Text(a.$3,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AkeliColors.onSurfaceVariant),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  final String value;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _MetricField({
    required this.value,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AkeliRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface),
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              suffix,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurfaceVariant,
                  letterSpacing: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SexSegment extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  const _SexSegment({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
      ),
      child: Row(
        children: [
          _SexOption(
              label: 'Femme',
              selected: value == 'female',
              onTap: () => onChanged('female')),
          _SexOption(
              label: 'Homme',
              selected: value == 'male',
              onTap: () => onChanged('male')),
        ],
      ),
    );
  }
}

class _SexOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SexOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? AkeliColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        color: Color(0x0F1B1C16),
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AkeliColors.primary
                    : AkeliColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step 4: Goals ────────────────────────────────────────────────────────────

class _StepGoals extends ConsumerStatefulWidget {
  final int step;
  const _StepGoals({required this.step});
  @override
  ConsumerState<_StepGoals> createState() => _StepGoalsState();
}

class _StepGoalsState extends ConsumerState<_StepGoals> {
  late final TextEditingController _targetWeightCtrl;
  late final TextEditingController _motivationsCtrl;

  @override
  void initState() {
    super.initState();
    final d = ref.read(onboardingProvider);
    _targetWeightCtrl =
        TextEditingController(text: d.targetWeight?.toString() ?? '');
    _motivationsCtrl = TextEditingController(text: d.motivations);
  }

  @override
  void dispose() {
    _targetWeightCtrl.dispose();
    _motivationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos objectifs',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.02)),
          const SizedBox(height: AkeliSpacing.sm),
          Text(
              'Définissons ensemble ce que vous souhaitez accomplir.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target weight
                Text('POIDS CIBLE (KG)',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AkeliRadius.sm),
                  ),
                  child: TextField(
                    controller: _targetWeightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => notifier.updateGoals(
                        targetWeight: double.tryParse(v)),
                    style: GoogleFonts.inter(
                        fontSize: 18, color: AkeliColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Ex: 65',
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AkeliSpacing.md),
                      suffixText: 'kg',
                      suffixStyle: GoogleFonts.inter(
                          fontSize: 13, color: AkeliColors.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(height: AkeliSpacing.xl),
                // Timeline slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DÉLAI ESTIMÉ',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AkeliColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(AkeliRadius.pill),
                      ),
                      child: Text('Modéré',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AkeliColors.onTertiaryFixed,
                              letterSpacing: 0.08)),
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.md),
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${data.timelineMonths} ',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: AkeliColors.primary,
                              height: 1),
                        ),
                        TextSpan(
                          text: 'mois',
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              color: AkeliColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AkeliColors.secondaryContainer,
                    inactiveTrackColor: AkeliColors.surfaceContainerHighest,
                    thumbColor: AkeliColors.surfaceContainerLowest,
                    overlayColor: AkeliColors.primary.withValues(alpha: 0.1),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                    trackHeight: 10,
                  ),
                  child: Slider(
                    value: data.timelineMonths.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    onChanged: (v) =>
                        notifier.updateGoals(timelineMonths: v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 mois',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                    Text('12 mois',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AkeliColors.onSurfaceVariant,
                            letterSpacing: 0.1)),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.xl),
                // Motivations
                Text('VOS MOTIVATIONS',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurfaceVariant,
                        letterSpacing: 0.1)),
                const SizedBox(height: AkeliSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AkeliRadius.sm),
                  ),
                  child: TextField(
                    controller: _motivationsCtrl,
                    maxLines: 4,
                    onChanged: (v) => notifier.updateGoals(motivations: v),
                    style: GoogleFonts.inter(
                        fontSize: 15, color: AkeliColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Pourquoi souhaitez-vous atteindre cet objectif ?',
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AkeliSpacing.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 5: Preferences ──────────────────────────────────────────────────────

class _StepPreferences extends ConsumerStatefulWidget {
  final int step;
  const _StepPreferences({required this.step});
  @override
  ConsumerState<_StepPreferences> createState() => _StepPreferencesState();
}

class _StepPreferencesState extends ConsumerState<_StepPreferences> {
  final _allergyCtrl = TextEditingController();

  @override
  void dispose() {
    _allergyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos préférences',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.02)),
          const SizedBox(height: AkeliSpacing.sm),
          Text('Personnalisons votre expérience culinaire.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AkeliSpacing.xl),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Régime alimentaire',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface)),
                const SizedBox(height: AkeliSpacing.md),
                _DietToggle(
                  icon: Icons.no_meals_rounded,
                  label: 'Sans Porc',
                  description: 'Exclure tous les plats contenant du porc',
                  value: data.noPork,
                  onChanged: (v) => notifier.updatePreferences(noPork: v),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                _DietToggle(
                  icon: Icons.eco_rounded,
                  label: 'Sans Viande',
                  description: 'Options végétariennes uniquement',
                  value: data.noMeat,
                  onChanged: (v) => notifier.updatePreferences(noMeat: v),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                _DietToggle(
                  icon: Icons.grain_rounded,
                  label: 'Sans Gluten',
                  description: 'Exclure le gluten de votre alimentation',
                  value: data.noGluten,
                  onChanged: (v) => notifier.updatePreferences(noGluten: v),
                ),
                const SizedBox(height: AkeliSpacing.sm),
                _DietToggle(
                  icon: Icons.local_drink_outlined,
                  label: 'Sans Lactose',
                  description: 'Exclure les produits laitiers',
                  value: data.noLactose,
                  onChanged: (v) => notifier.updatePreferences(noLactose: v),
                ),
                const SizedBox(height: AkeliSpacing.xl),
                // Allergies
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Allergies & Intolérances',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.onSurface)),
                        Text('Ajoutez les ingrédients à éviter.',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AkeliColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AkeliSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _allergyCtrl,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AkeliColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Ex: arachides, noix...',
                          filled: true,
                          fillColor: AkeliColors.surfaceContainerHighest,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AkeliRadius.md),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: AkeliSpacing.md,
                              vertical: AkeliSpacing.sm),
                        ),
                      ),
                    ),
                    const SizedBox(width: AkeliSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        final txt = _allergyCtrl.text.trim();
                        if (txt.isNotEmpty) {
                          final updated = [...data.allergies, txt];
                          notifier.updatePreferences(allergies: updated);
                          _allergyCtrl.clear();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AkeliColors.primary,
                          borderRadius: BorderRadius.circular(AkeliRadius.md),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
                if (data.allergies.isNotEmpty) ...[
                  const SizedBox(height: AkeliSpacing.md),
                  Wrap(
                    spacing: AkeliSpacing.sm,
                    runSpacing: AkeliSpacing.sm,
                    children: data.allergies.map((a) {
                      return Chip(
                        label: Text(a,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AkeliColors.onSurface)),
                        backgroundColor: AkeliColors.surfaceContainerLow,
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          final updated = data.allergies
                              .where((x) => x != a)
                              .toList();
                          notifier.updatePreferences(allergies: updated);
                        },
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AkeliRadius.pill)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DietToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DietToggle({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AkeliColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: AkeliColors.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface)),
                Text(description,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AkeliColors.onSurfaceVariant)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AkeliColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Step 6: Summary ──────────────────────────────────────────────────────────

class _StepSummary extends ConsumerWidget {
  final int step;
  const _StepSummary({required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Récapitulatif',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AkeliColors.onSurface,
                  letterSpacing: -0.02)),
          const SizedBox(height: AkeliSpacing.sm),
          Text('Votre profil est prêt. Vérifions les détails avant de commencer.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AkeliSpacing.xl),
          // Summary card
          Container(
            decoration: BoxDecoration(
              color: AkeliColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AkeliRadius.xl),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0F1B1C16),
                    blurRadius: 48,
                    offset: Offset(0, 24))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Decorative blob
                Positioned(
                  top: -48,
                  right: -48,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AkeliColors.secondaryContainer.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AkeliSpacing.lg),
                  child: Column(
                    children: [
                      // Profile header
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AkeliColors.surfaceContainerHigh,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AkeliColors.surfaceContainerLowest,
                                  width: 3),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: AkeliColors.outline, size: 36),
                          ),
                          const SizedBox(width: AkeliSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.name.isNotEmpty ? data.name : 'Votre nom',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AkeliColors.onSurface),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: AkeliSpacing.xs,
                                  children: [
                                    if (data.age != null)
                                      _SummaryChip('${data.age} ans'),
                                    if (data.height != null)
                                      _SummaryChip('${data.height?.toInt()} cm'),
                                    if (data.weight != null)
                                      _SummaryChip('${data.weight?.toInt()} kg'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AkeliSpacing.lg),
                      // Bento grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AkeliSpacing.sm,
                        mainAxisSpacing: AkeliSpacing.sm,
                        childAspectRatio: 1.4,
                        children: [
                          _SummaryCard(
                            icon: Icons.directions_run_rounded,
                            title: 'Niveau d\'activité',
                            value: data.activityLevel ?? 'Non défini',
                          ),
                          _SummaryCard(
                            icon: Icons.flag_rounded,
                            title: 'Objectif poids',
                            value: data.targetWeight != null
                                ? '${data.targetWeight?.toInt()} kg'
                                : 'Non défini',
                            iconColor: AkeliColors.primary,
                          ),
                        ],
                      ),
                      if (data.noPork || data.noMeat || data.noGluten || data.noLactose) ...[
                        const SizedBox(height: AkeliSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AkeliSpacing.md),
                          decoration: BoxDecoration(
                            color: AkeliColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AkeliRadius.xl),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AkeliColors.tertiaryFixed.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.restaurant_rounded,
                                        size: 18),
                                  ),
                                  const SizedBox(width: AkeliSpacing.sm),
                                  Text('Préférences alimentaires',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AkeliColors.onSurface)),
                                ],
                              ),
                              const SizedBox(height: AkeliSpacing.sm),
                              Wrap(
                                spacing: AkeliSpacing.xs,
                                runSpacing: AkeliSpacing.xs,
                                children: [
                                  if (data.noPork)
                                    _SummaryChip('Sans Porc'),
                                  if (data.noMeat)
                                    _SummaryChip('Végétarien'),
                                  if (data.noGluten)
                                    _SummaryChip('Sans Gluten'),
                                  if (data.noLactose)
                                    _SummaryChip('Sans Lactose'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  const _SummaryChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AkeliColors.onSurfaceVariant)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor == Colors.transparent
                  ? AkeliColors.secondaryContainer
                  : iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: iconColor == Colors.transparent
                    ? AkeliColors.onSecondaryContainer
                    : iconColor,
                size: 18),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurface)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AkeliColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```
flutter analyze lib/features/auth/onboarding_page.dart
```

Fix any errors, then:

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/onboarding_page.dart \
        lib/features/auth/onboarding_data.dart
git commit -m "feat(onboarding): full 6-step redesign — language, consent, profile, goals, preferences, summary"
```

---

## Task 6: Full test run + verify app compiles

- [ ] **Step 1: Run all tests**

```
flutter test
```

Expected: All tests pass.

- [ ] **Step 2: Check full project analysis**

```
flutter analyze
```

Fix any errors or warnings.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat(wave1): complete Wave 1 — design tokens, auth redesign, 6-step onboarding"
```

---

## Quick Reference: Design Token Mapping

| Stitch class | Flutter constant |
|---|---|
| `bg-surface` / `bg-background` | `AkeliColors.background` |
| `bg-surface-container-low` | `AkeliColors.surfaceContainerLow` |
| `bg-surface-container-lowest` | `AkeliColors.surfaceContainerLowest` |
| `bg-surface-container-highest` | `AkeliColors.surfaceContainerHighest` |
| `bg-secondary-container` | `AkeliColors.secondaryContainer` |
| `text-primary` | `AkeliColors.primary` |
| `text-on-surface-variant` | `AkeliColors.onSurfaceVariant` |
| `text-outline` | `AkeliColors.outline` |
| `rounded-DEFAULT` (1rem) | `AkeliRadius.xl` (24px) |
| `rounded-full` | `AkeliRadius.pill` |
| `font-headline` | `GoogleFonts.plusJakartaSans()` |
| `font-body` / `font-label` | `GoogleFonts.inter()` |
| gradient `from-primary to-primary-container` | `LinearGradient([primary, primaryContainer])` |
