# Password Flows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the forgot-password email deep-link back into the app (iOS + Android), and harden the existing in-app password change (consistent 8-char minimum, hidden for Google-only users), with full L10n compliance on the touched screens.

**Architecture:** The recovery chain (`passwordRecovery` event → router redirect → ResetPasswordPage → `recoveryUpdatePassword`) already exists; we only complete the front of the chain: a `redirectTo` deep link on `resetPasswordForEmail` plus `akeli://` URL-scheme registration on both platforms. `supabase_flutter` bundles `app_links` and handles the incoming link automatically — no new packages, no new Dart link-handling code.

**Tech Stack:** Flutter + Riverpod + supabase_flutter v2, go_router, ARB-based l10n (`flutter gen-l10n`), flutter_test widget tests.

**Spec:** `docs/superpowers/specs/2026-07-16-password-flows-design.md`

## Global Constraints

- Deep-link URI is exactly `akeli://reset-password` (scheme `akeli`, host `reset-password`).
- Minimum password length is **8** everywhere.
- L10n standard (CLAUDE.md): no hardcoded user-visible strings; add keys to BOTH `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` BEFORE referencing them; run `flutter gen-l10n` after every ARB change; key naming `<screen>_<key>` camelCase.
- Logging standard (CLAUDE.md): keep all existing `_logger` calls; any new user action/branch gets a log line; never log passwords.
- Widget tests follow the existing harness pattern in `test/features/auth/auth_page_test.dart` (ProviderScope + MaterialApp + l10n delegates).
- Run all commands from the repo root: `c:\Users\DELL LATITUDE 7480\akeli-nutrition-app`.

---

### Task 1: Deep-link redirect + platform URL-scheme registration

**Files:**
- Modify: `lib/providers/auth_provider.dart` (resetPassword, ~line 166-187)
- Modify: `android/app/src/main/AndroidManifest.xml` (MainActivity, lines 25-28)
- Modify: `ios/Runner/Info.plist` (CFBundleURLTypes array, lines 82-92)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: recovery emails that reopen the app; `AuthChangeEvent.passwordRecovery` then fires and the existing router redirect (`lib/core/router.dart:144-149`) takes over. No Dart API changes.

There is no automated test for this task (the change is a Supabase network call parameter plus platform config); verification is `flutter analyze` here and the manual smoke test in Task 5.

- [ ] **Step 1: Add the redirect constant and pass it to resetPasswordForEmail**

In `lib/providers/auth_provider.dart`, add below the imports (after line 8):

```dart
/// Where the password-recovery email deep-links back into the app.
/// Must be listed in Supabase Dashboard → Authentication → URL Configuration
/// → Redirect URLs, or Supabase silently falls back to the Site URL.
const _passwordResetRedirectUri = 'akeli://reset-password';
```

In `resetPassword()`, replace:

```dart
        _logger.db('BEFORE | op: resetPasswordForEmail | supabase.auth');
        await client.auth.resetPasswordForEmail(email);
```

with:

```dart
        _logger.db('BEFORE | op: resetPasswordForEmail | redirectTo: $_passwordResetRedirectUri');
        await client.auth.resetPasswordForEmail(
          email,
          redirectTo: _passwordResetRedirectUri,
        );
```

- [ ] **Step 2: Register the scheme on Android**

In `android/app/src/main/AndroidManifest.xml`, directly after the existing MAIN/LAUNCHER intent-filter (lines 25-28), inside the same `<activity>`:

```xml
            <!-- Supabase password-recovery deep link: akeli://reset-password -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="akeli" android:host="reset-password"/>
            </intent-filter>
```

- [ ] **Step 3: Register the scheme on iOS**

In `ios/Runner/Info.plist`, inside the existing `CFBundleURLTypes` `<array>` (after the Google dict closing `</dict>` at line 91):

```xml
			<dict>
				<key>CFBundleTypeRole</key>
				<string>Editor</string>
				<key>CFBundleURLSchemes</key>
				<array>
					<string>akeli</string>
				</array>
			</dict>
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/providers/auth_provider.dart android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "fix(auth): deep-link password recovery back into the app via akeli:// scheme"
```

---

### Task 2: ResetPasswordPage — L10n compliance + 8-char minimum

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`
- Modify: `lib/features/auth/reset_password_page.dart`
- Test: `test/features/auth/reset_password_page_test.dart` (create)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: ARB keys `resetPasswordTitle`, `resetPasswordNewHint`, `resetPasswordConfirmHint`, `resetPasswordRequired`, `resetPasswordTooShort`, `resetPasswordConfirmRequired`, `resetPasswordMismatch`, `resetPasswordSubmit`, `resetPasswordSuccess` (available on `AppLocalizations` after gen-l10n).

- [ ] **Step 1: Write the widget tests**

Create `test/features/auth/reset_password_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/auth/reset_password_page.dart';
import 'package:akeli/core/theme.dart';

Widget _testApp(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        home: child,
      ),
    );

void main() {
  group('ResetPasswordPage', () {
    testWidgets('shows localized title', (tester) async {
      await tester.pumpWidget(_testApp(const ResetPasswordPage()));
      await tester.pump();
      expect(find.text('Réinitialiser votre mot de passe'), findsOneWidget);
    });

    testWidgets('empty submit shows required error', (tester) async {
      await tester.pumpWidget(_testApp(const ResetPasswordPage()));
      await tester.pumpAndSettle();
      final submit = find.text('Mettre à jour le mot de passe');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Le mot de passe est requis'), findsOneWidget);
    });

    testWidgets('rejects passwords shorter than 8 characters', (tester) async {
      await tester.pumpWidget(_testApp(const ResetPasswordPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'abc123');
      final submit = find.text('Mettre à jour le mot de passe');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Le mot de passe doit faire au moins 8 caractères'),
        findsOneWidget,
      );
    });

    testWidgets('rejects mismatched confirmation', (tester) async {
      await tester.pumpWidget(_testApp(const ResetPasswordPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'longpassword1');
      await tester.enterText(find.byType(TextFormField).last, 'different1');
      final submit = find.text('Mettre à jour le mot de passe');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Les mots de passe ne correspondent pas'),
        findsOneWidget,
      );
    });
  });
}
```

- [ ] **Step 2: Run tests — the 8-char test must FAIL**

Run: `flutter test test/features/auth/reset_password_page_test.dart`
Expected: `rejects passwords shorter than 8 characters` FAILS (current validator accepts 6 chars, so no error text renders). The other three pass already — they pin the current French copy during the refactor.

- [ ] **Step 3: Add ARB keys**

In `lib/l10n/app_en.arb`, after the `"authForgotPassword"` entry (line ~91):

```json
  "resetPasswordTitle": "Reset your password",
  "resetPasswordNewHint": "New Password",
  "resetPasswordConfirmHint": "Confirm Password",
  "resetPasswordRequired": "Password is required",
  "resetPasswordTooShort": "Password must be at least 8 characters",
  "resetPasswordConfirmRequired": "Please confirm your password",
  "resetPasswordMismatch": "Passwords do not match",
  "resetPasswordSubmit": "Update Password",
  "resetPasswordSuccess": "Password updated successfully!",
```

In `lib/l10n/app_fr.arb`, after the `"authForgotPassword"` entry (line ~35):

```json
  "resetPasswordTitle": "Réinitialiser votre mot de passe",
  "resetPasswordNewHint": "Nouveau mot de passe",
  "resetPasswordConfirmHint": "Confirmer le mot de passe",
  "resetPasswordRequired": "Le mot de passe est requis",
  "resetPasswordTooShort": "Le mot de passe doit faire au moins 8 caractères",
  "resetPasswordConfirmRequired": "Veuillez confirmer votre mot de passe",
  "resetPasswordMismatch": "Les mots de passe ne correspondent pas",
  "resetPasswordSubmit": "Mettre à jour le mot de passe",
  "resetPasswordSuccess": "Mot de passe mis à jour avec succès !",
```

Run: `flutter gen-l10n`
Expected: exits silently (code 0).

- [ ] **Step 4: Refactor the page**

In `lib/features/auth/reset_password_page.dart`, replace every `l10n.localeName == 'en' ? ... : ...` ternary with the new keys, and raise the length check:

Success snackbar in `_onSubmit`:

```dart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetPasswordSuccess),
            backgroundColor: AkeliColors.primary,
          ),
        );
```

Subtitle under the AKELI header:

```dart
                Text(
                  l10n.resetPasswordTitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
```

New-password field hint and validator:

```dart
                            hintText: l10n.resetPasswordNewHint,
```

```dart
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.resetPasswordRequired;
                            }
                            if (v.length < 8) {
                              return l10n.resetPasswordTooShort;
                            }
                            return null;
                          },
```

Confirm field hint and validator:

```dart
                            hintText: l10n.resetPasswordConfirmHint,
```

```dart
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.resetPasswordConfirmRequired;
                            }
                            if (v != _passwordCtrl.text) {
                              return l10n.resetPasswordMismatch;
                            }
                            return null;
                          },
```

Submit button:

```dart
                        AkeliGradientButton(
                          label: l10n.resetPasswordSubmit,
                          onPressed: _onSubmit,
                          isLoading: isLoading,
                        ),
```

- [ ] **Step 5: Run tests — all four must PASS**

Run: `flutter test test/features/auth/reset_password_page_test.dart`
Expected: 4 tests pass.

- [ ] **Step 6: Analyze and commit**

Run: `flutter analyze` — expected `No issues found!`

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/features/auth/reset_password_page.dart test/features/auth/reset_password_page_test.dart
git commit -m "fix(auth): l10n-compliant ResetPasswordPage with 8-char minimum"
```

(If `flutter gen-l10n` writes generated files under `lib/l10n/` that git tracks — `app_localizations*.dart` — stage those too.)

---

### Task 3: Forgot-password dialog — L10n compliance

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`
- Modify: `lib/features/auth/auth_page.dart` (`_handleForgotPassword`, lines 132-240)
- Test: `test/features/auth/auth_page_test.dart` (extend)

**Interfaces:**
- Consumes: existing ARB keys `authEmailField` ("Email"), `authEmailRequired` ("Email requis"), `authEmailInvalid` ("Email invalide"), `commonCancel` ("Annuler") — reuse, do not duplicate.
- Produces: ARB keys `authForgotDialogTitle`, `authForgotDialogBody`, `authForgotSend`, `authForgotSentTo(email)`.

- [ ] **Step 1: Extend the AuthPage widget tests**

Append inside the existing `group('AuthPage', ...)` in `test/features/auth/auth_page_test.dart`:

```dart
    testWidgets('forgot-password dialog shows localized copy and validates empty email',
        (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pumpAndSettle();
      // Switch to the login tab (first 'Se connecter' is the pill tab).
      await tester.tap(find.text('Se connecter').first);
      await tester.pumpAndSettle();
      final forgotLink = find.text('Mot de passe oublié ?');
      await tester.ensureVisible(forgotLink);
      await tester.tap(forgotLink);
      await tester.pumpAndSettle();

      expect(
        find.text('Entrez votre adresse email pour recevoir un lien de réinitialisation.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();
      expect(find.text('Email requis'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Envoyer'), findsNothing);
    });
```

- [ ] **Step 2: Run the new test — expect PASS (regression pin)**

Run: `flutter test test/features/auth/auth_page_test.dart`
Expected: all pass. The French copy is identical before and after; this test pins the dialog's behavior through the l10n refactor. (Exception: if `Email requis` fails because the current hardcoded validator says `L'email est requis`, that mismatch is exactly what Step 4 fixes — the test encodes the target state using the shared `authEmailRequired` key. In that case expect this single assertion to FAIL now and pass after Step 4.)

- [ ] **Step 3: Add ARB keys**

In `lib/l10n/app_en.arb`, after the `resetPassword*` block added in Task 2:

```json
  "authForgotDialogTitle": "Reset Password",
  "authForgotDialogBody": "Enter your email address to receive a password reset link.",
  "authForgotSend": "Send",
  "authForgotSentTo": "A password reset link has been sent to {email}",
  "@authForgotSentTo": {
    "placeholders": { "email": { "type": "String" } }
  },
```

In `lib/l10n/app_fr.arb`, after the `resetPassword*` block added in Task 2:

```json
  "authForgotDialogTitle": "Mot de passe oublié",
  "authForgotDialogBody": "Entrez votre adresse email pour recevoir un lien de réinitialisation.",
  "authForgotSend": "Envoyer",
  "authForgotSentTo": "Un lien de réinitialisation a été envoyé à {email}",
  "@authForgotSentTo": {
    "placeholders": { "email": { "type": "String" } }
  },
```

Run: `flutter gen-l10n`
Expected: exits silently (code 0).

- [ ] **Step 4: Refactor `_handleForgotPassword`**

In `lib/features/auth/auth_page.dart`, replace the hardcoded strings:

Dialog title:

```dart
          title: Text(
            l10n.authForgotDialogTitle,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
```

Dialog body text:

```dart
                Text(
                  l10n.authForgotDialogBody,
                  style: GoogleFonts.inter(fontSize: 14, color: AkeliColors.onSurfaceVariant),
                ),
```

Email field hint and validator:

```dart
                    hintText: l10n.authEmailField,
```

```dart
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return l10n.authEmailRequired;
                    }
                    if (!v.contains('@')) {
                      return l10n.authEmailInvalid;
                    }
                    return null;
                  },
```

Cancel button label:

```dart
              child: Text(
                l10n.commonCancel,
                style: GoogleFonts.inter(color: AkeliColors.outline, fontWeight: FontWeight.w600),
              ),
```

Send button label:

```dart
              child: Text(
                l10n.authForgotSend,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
```

Success snackbar:

```dart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.authForgotSentTo(result)),
              backgroundColor: AkeliColors.primary,
            ),
          );
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/features/auth/auth_page_test.dart`
Expected: all pass (including the new dialog test).

- [ ] **Step 6: Analyze and commit**

Run: `flutter analyze` — expected `No issues found!`

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/features/auth/auth_page.dart test/features/auth/auth_page_test.dart
git commit -m "refactor(auth): l10n-compliant forgot-password dialog"
```

(Stage regenerated `lib/l10n/app_localizations*.dart` too if git tracks them.)

---

### Task 4: AccountPage — hide password section for Google-only users

**Files:**
- Modify: `lib/features/settings/account_page.dart`
- Test: `test/features/settings/account_page_test.dart` (create)

**Interfaces:**
- Consumes: `currentUserProvider` (`Provider<User?>`) from `lib/providers/auth_provider.dart` (already imported by the page).
- Produces: no new APIs. Behavior: the PASSWORD `_SectionCard` renders only when the user can have a password (providers list empty/missing, or contains `'email'`).

- [ ] **Step 1: Write the widget tests**

Create `test/features/settings/account_page_test.dart`. English locale is used so assertions can rely on the known `accountPasswordSection` value (`"PASSWORD"`). The `User` is built directly — `currentUserProvider` is overridden so `Supabase.instance` is never touched:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/features/settings/account_page.dart';
import 'package:akeli/providers/auth_provider.dart';
import 'package:akeli/core/theme.dart';

User _user({required List<String> providers}) => User(
      id: 'test-user-id',
      appMetadata: {'provider': providers.first, 'providers': providers},
      userMetadata: const {},
      aud: 'authenticated',
      email: 'test@example.com',
      createdAt: '2026-01-01T00:00:00Z',
    );

Widget _testApp(Widget child, {required User? user}) => ProviderScope(
      overrides: [currentUserProvider.overrideWithValue(user)],
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('en'),
        home: child,
      ),
    );

void main() {
  group('AccountPage password section visibility', () {
    testWidgets('shows password section for email users', (tester) async {
      await tester.pumpWidget(
        _testApp(const AccountPage(), user: _user(providers: ['email'])),
      );
      await tester.pump();
      expect(find.text('PASSWORD'), findsOneWidget);
    });

    testWidgets('hides password section for Google-only users', (tester) async {
      await tester.pumpWidget(
        _testApp(const AccountPage(), user: _user(providers: ['google'])),
      );
      await tester.pump();
      expect(find.text('PASSWORD'), findsNothing);
    });

    testWidgets('shows password section for email+google users', (tester) async {
      await tester.pumpWidget(
        _testApp(const AccountPage(), user: _user(providers: ['email', 'google'])),
      );
      await tester.pump();
      expect(find.text('PASSWORD'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL**

Run: `flutter test test/features/settings/account_page_test.dart`
Expected: FAIL — either an exception from `Supabase.instance` not being initialized (the page reads it directly today), or `hides password section for Google-only users` finding 'PASSWORD'. Both prove the refactor is needed.

- [ ] **Step 3: Refactor the page**

In `lib/features/settings/account_page.dart`:

Replace (build method, ~line 52):

```dart
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    _logger.provider('AccountPage build() | email: ${LogHelper.maskEmail(email)}');
```

with:

```dart
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';
    final providers =
        (user?.appMetadata['providers'] as List?)?.cast<String>() ?? const <String>[];
    // No providers info → assume email auth (fail open so the section stays usable).
    final canChangePassword = providers.isEmpty || providers.contains('email');
    _logger.provider(
      'AccountPage build() | email: ${LogHelper.maskEmail(email)} | canChangePassword: $canChangePassword',
    );
```

Wrap the password `_SectionCard` (and its preceding spacer) in a conditional. Replace:

```dart
            const SizedBox(height: 24),

            _SectionCard(
              title: l10n.accountPasswordSection,
```

with:

```dart
            if (canChangePassword) ...[
              const SizedBox(height: 24),

              _SectionCard(
                title: l10n.accountPasswordSection,
```

and close the collection-if with `],` after that section card's closing `),` (re-indent the section's contents by one level, before the `const SizedBox(height: 24),` that precedes the danger-zone card).

Remove the now-unused import if nothing else references it:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

(`flutter analyze` in Step 5 will confirm whether it is still needed — the catch clauses in this file don't reference Supabase types directly.)

- [ ] **Step 4: Run tests — expect PASS**

Run: `flutter test test/features/settings/account_page_test.dart`
Expected: 3 tests pass.

- [ ] **Step 5: Analyze and commit**

Run: `flutter analyze` — expected `No issues found!`

```bash
git add lib/features/settings/account_page.dart test/features/settings/account_page_test.dart
git commit -m "fix(account): hide password change for Google-only users, read user via provider"
```

---

### Task 5: Full verification + manual steps

**Files:** none (verification only).

**Interfaces:**
- Consumes: everything above.
- Produces: verified release-ready state.

- [ ] **Step 1: Full automated suite**

Run: `flutter analyze` — expected `No issues found!`
Run: `flutter test` — expected: all tests pass (including the pre-existing suite).

- [ ] **Step 2: Supabase dashboard allowlist (MANUAL — Curtis)**

Supabase Dashboard → project `njzqcftjzskwcpforwzf` → Authentication → URL Configuration → Redirect URLs → add:

```
akeli://reset-password
```

Without this the emailed link falls back to the Site URL and the deep link never fires. Optional while there: set Auth → Providers → Email → Minimum password length to 8 to match the client.

- [ ] **Step 3: Deep-link smoke test (no email round-trip)**

With the app installed on a device/emulator:

- Android: `adb shell am start -d "akeli://reset-password"`
- iOS simulator: `xcrun simctl openurl booted akeli://reset-password`

Expected: the app opens (foreground). Note: launching the raw URI without Supabase tokens won't fire `passwordRecovery` — this only proves scheme registration.

- [ ] **Step 4: Full forgot-password flow (real email, on device)**

1. Sign out. On the login tab tap "Mot de passe oublié ?", enter a real test-account email, send.
2. Open the email **on the same device**, tap the reset link.
3. Expected: app opens → ResetPasswordPage appears automatically (router redirect on `passwordRecovery`).
4. Set a new 8+ char password → success snackbar → lands on home, signed in.
5. Sign out, sign back in with the new password.

- [ ] **Step 5: In-app password change verification (manual)**

In Settings → Account with an email-auth test account:

1. Wrong current password → localized "invalid password" error, no change.
2. New/confirm mismatch → mismatch error.
3. New password < 8 chars → too-short error.
4. Happy path → success snackbar; sign out and back in with the new password.
5. With a Google-only account: the PASSWORD section is absent.
