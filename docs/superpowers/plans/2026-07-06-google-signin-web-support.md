# Google Sign-In on Flutter Web — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make "Continue with Google" work on Flutter Web by rendering Google's own GSI button there and reacting to its sign-in event, without changing the existing mobile (`authenticate()`-awaited) flow at all.

**Architecture:** A conditionally-exported widget (`GoogleWebSignInButton`) renders Google's real button via `google_sign_in_web`'s `renderButton()` on web only; a stub keeps mobile builds free of web-only Dart libraries. `AuthNotifier` gains a `kIsWeb`-guarded subscription to `GoogleSignIn.instance.authenticationEvents` that reuses the same idToken→Supabase exchange helper the mobile path already uses (extracted, not duplicated). `google_sign_in_client.dart` is fixed to initialize with the correct OAuth client type per platform — required for the button to work at all, found while tracing the code.

**Tech Stack:** Flutter/Dart, `google_sign_in: ^7.2.0`, `google_sign_in_web: ^1.1.3` (new direct dependency), `flutter_riverpod`, `supabase_flutter`.

## Global Constraints

- Every Dart file created or modified MUST import `package:akeli/core/logger.dart` and use structured logging from the first line — auth events via `_logger.auth(...)`/`appLogger.auth(...)`, provider lifecycle/state transitions via `_logger.provider(...)`, per `CLAUDE.md`. Email addresses are always masked via `LogHelper.maskEmail(...)`.
- No hardcoded user-visible strings — reuse the existing `l10n.authContinueWithGoogle` / `l10n.authErrorGoogleSignIn` keys already in `app_en.arb`/`app_fr.arb`. This plan introduces no new user-visible strings, so no ARB changes are needed.
- Mobile's existing `GoogleSignIn.instance.authenticate()` path must remain behaviorally unchanged — every task that touches shared code must preserve it exactly.
- Spec: `docs/superpowers/specs/2026-07-06-google-signin-web-support-design.md`.

---

### Task 1: Add `google_sign_in_web` as a direct dependency

**Files:**
- Modify: `pubspec.yaml:60`

**Interfaces:**
- Produces: `package:google_sign_in_web/web_only.dart` importable from app code (currently only a transitive dependency, not directly importable per Dart's package visibility rules).

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, right after the existing `google_sign_in` line:

```yaml
  google_sign_in: ^7.2.0
  google_sign_in_web: ^1.1.3
  crypto: ^3.0.7
```

- [ ] **Step 2: Resolve it**

Run: `flutter pub get`
Expected: completes with no version conflicts (1.1.3 is already the resolved version transitively, per `pubspec.lock`, so this should be a no-op resolution).

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add google_sign_in_web as a direct dependency"
```

---

### Task 2: Fix `initializeGoogleSignIn()` for web's OAuth client requirements

**Files:**
- Modify: `lib/core/google_sign_in_client.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `initializeGoogleSignIn()` behavior unchanged on mobile; on web, initializes with the web OAuth client instead of the iOS one and omits `serverClientId` (unsupported there).

**Context:** `GoogleSignInPlugin.init()` (the web platform implementation) asserts `params.serverClientId == null` — passing one is invalid on web. It also requires `clientId` to be a **web** OAuth client for GIS to accept the page's origin; the current code always passes `_iosClientId`, which is wrong for web regardless of the render-button fix. `_webClientId` already exists in this file and is already the audience Supabase's Google provider accepts (it's used as `serverClientId` for the mobile flow today), so no new Google Cloud Console configuration is needed.

- [ ] **Step 1: Read current file for exact context**

Current content of `lib/core/google_sign_in_client.dart`:

```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'logger.dart';

const _iosClientId = '1080340252277-bk0ihbgua0a2avus25ri7os1lq0e8kti.apps.googleusercontent.com';
const _webClientId = '1080340252277-d412699vsp80741vg65draja56em44st.apps.googleusercontent.com';

String? _googleSignInRawNonce;

/// Raw nonce to pass to Supabase's `signInWithIdToken`. google_sign_in only
/// accepts a nonce at `initialize()` time (once per app session) rather than
/// per sign-in attempt, so every Google sign-in during this session reuses it.
String? get googleSignInRawNonce => _googleSignInRawNonce;

Future<void> initializeGoogleSignIn() async {
  final rawNonce = _generateRawNonce();
  final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
  _googleSignInRawNonce = rawNonce;

  appLogger.auth('GoogleSignIn: initializing | clientId: ios | serverClientId: web');
  await GoogleSignIn.instance.initialize(
    clientId: _iosClientId,
    serverClientId: _webClientId,
    nonce: hashedNonce,
  );
  appLogger.i('✅ GoogleSignIn: initialized');
}

String _generateRawNonce([int length = 32]) {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}
```

- [ ] **Step 2: Add the `kIsWeb` branch**

Replace the `initializeGoogleSignIn` function body:

```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'logger.dart';

const _iosClientId = '1080340252277-bk0ihbgua0a2avus25ri7os1lq0e8kti.apps.googleusercontent.com';
const _webClientId = '1080340252277-d412699vsp80741vg65draja56em44st.apps.googleusercontent.com';

String? _googleSignInRawNonce;

/// Raw nonce to pass to Supabase's `signInWithIdToken`. google_sign_in only
/// accepts a nonce at `initialize()` time (once per app session) rather than
/// per sign-in attempt, so every Google sign-in during this session reuses it.
String? get googleSignInRawNonce => _googleSignInRawNonce;

Future<void> initializeGoogleSignIn() async {
  final rawNonce = _generateRawNonce();
  final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
  _googleSignInRawNonce = rawNonce;

  if (kIsWeb) {
    // Web's GIS SDK requires a web-type OAuth client for the current page's
    // origin, and does not support serverClientId at all (the platform
    // plugin asserts on it).
    appLogger.auth('GoogleSignIn: initializing | platform: web | clientId: web');
    await GoogleSignIn.instance.initialize(
      clientId: _webClientId,
      nonce: hashedNonce,
    );
  } else {
    appLogger.auth('GoogleSignIn: initializing | platform: mobile | clientId: ios | serverClientId: web');
    await GoogleSignIn.instance.initialize(
      clientId: _iosClientId,
      serverClientId: _webClientId,
      nonce: hashedNonce,
    );
  }
  appLogger.i('✅ GoogleSignIn: initialized');
}

String _generateRawNonce([int length = 32]) {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/core/google_sign_in_client.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/google_sign_in_client.dart
git commit -m "fix(auth): use web OAuth client id when initializing GoogleSignIn on web"
```

---

### Task 3: Create the conditionally-exported web sign-in button widget

**Files:**
- Create: `lib/features/auth/google_web_signin_button_stub.dart`
- Create: `lib/features/auth/google_web_signin_button_web.dart`
- Create: `lib/features/auth/google_web_signin_button.dart`

**Interfaces:**
- Produces: `GoogleWebSignInButton({required bool isLoading})` — a `StatelessWidget`, importable from `google_web_signin_button.dart` on every platform. On non-web it renders nothing (never actually reached, since Task 5 branches on `kIsWeb` before constructing it). On web it renders Google's real GSI button, dimmed and non-interactive while `isLoading` is true.

- [ ] **Step 1: Create the non-web stub**

`lib/features/auth/google_web_signin_button_stub.dart`:

```dart
import 'package:flutter/widgets.dart';
import '../../core/logger.dart';

/// Non-web stub. `auth_page.dart` only ever instantiates the real
/// [GoogleWebSignInButton] (from `google_web_signin_button_web.dart`) when
/// `kIsWeb` is true, so this branch is never actually built — it exists so
/// mobile builds don't pull in `dart:ui_web` / `package:web`, which the web
/// implementation depends on.
class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({required this.isLoading, super.key});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    appLogger.provider('GoogleWebSignInButton (stub) build() | isLoading: $isLoading');
    return const SizedBox.shrink();
  }
}
```

- [ ] **Step 2: Create the real web implementation**

`lib/features/auth/google_web_signin_button_web.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;
import '../../core/logger.dart';

/// Renders Google's own GSI button widget, which is the only supported way
/// to trigger Google Sign-In on Flutter Web (see
/// `docs/superpowers/specs/2026-07-06-google-signin-web-support-design.md`).
/// The actual sign-in result arrives asynchronously via
/// `GoogleSignIn.instance.authenticationEvents`, handled in `AuthNotifier`.
class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({required this.isLoading, super.key});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    appLogger.provider('GoogleWebSignInButton build() | isLoading: $isLoading');
    return IgnorePointer(
      ignoring: isLoading,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: web_only.renderButton(
            configuration: web_only.GSIButtonConfiguration(
              theme: web_only.GSIButtonTheme.outline,
              size: web_only.GSIButtonSize.large,
              shape: web_only.GSIButtonShape.pill,
              text: web_only.GSIButtonText.continueWith,
              logoAlignment: web_only.GSIButtonLogoAlignment.center,
              minimumWidth: 320,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create the conditional-export barrel file**

`lib/features/auth/google_web_signin_button.dart`:

```dart
export 'google_web_signin_button_stub.dart'
    if (dart.library.js_interop) 'google_web_signin_button_web.dart';
```

- [ ] **Step 4: Verify all three files compile**

Run: `flutter analyze lib/features/auth/google_web_signin_button.dart lib/features/auth/google_web_signin_button_stub.dart lib/features/auth/google_web_signin_button_web.dart`
Expected: `No issues found!` — the analyzer type-checks both conditional branches directly (each file is checked independently by its own imports), regardless of the app's default run target.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/google_web_signin_button.dart lib/features/auth/google_web_signin_button_stub.dart lib/features/auth/google_web_signin_button_web.dart
git commit -m "feat(auth): add conditional Google Sign-In web button widget"
```

---

### Task 4: Extract shared idToken→Supabase exchange in `AuthNotifier`

**Files:**
- Modify: `lib/providers/auth_provider.dart:211-254` (the `signInWithGoogle` method)

**Interfaces:**
- Consumes: nothing new (same `GoogleSignInAccount`, `OAuthProvider`, `googleSignInRawNonce` already used today).
- Produces: `Future<void> _completeGoogleSignIn(GoogleSignInAccount account)` — private helper on `AuthNotifier`, used by both the existing mobile path (this task) and the new web stream path (Task 5). Throws on missing idToken or Supabase `AuthException`, exactly like the code it replaces.

**Context:** This is a pure refactor — mobile behavior must be identical before and after. No new test is added here because there is no existing automated test harness for `AuthNotifier` (it requires a live/mocked Supabase client and the `GoogleSignIn` platform singleton, neither of which are set up anywhere in this repo today) — this matches the existing test coverage pattern for this file. Correctness is verified by `flutter analyze` plus the manual mobile check in Task 6.

- [ ] **Step 1: Replace `signInWithGoogle` with the refactored version + new helper**

In `lib/providers/auth_provider.dart`, replace the entire `signInWithGoogle` method (currently lines 211-254) with:

```dart
  Future<void> signInWithGoogle() async {
    _logger.auth('signInWithGoogle BEFORE');
    _logger.provider('AuthNotifier → loading (signInWithGoogle)');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.auth('signInWithGoogle | launching picker');
        final googleUser = await GoogleSignIn.instance.authenticate();
        await _completeGoogleSignIn(googleUser);
      } on GoogleSignInException catch (e, st) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          _logger.auth('signInWithGoogle CANCELLED | user dismissed picker');
          return;
        }
        _logger.auth('signInWithGoogle ERROR | GoogleSignInException: ${e.code} | ${e.description}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signInWithGoogle GoogleSignInException)');
        rethrow;
      } on AuthException catch (e, st) {
        _logger.auth('signInWithGoogle ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signInWithGoogle AuthException)');
        rethrow;
      } catch (e, st) {
        _logger.auth('signInWithGoogle ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signInWithGoogle unexpected)');
        rethrow;
      }
    });
  }

  /// Exchanges a Google [account]'s ID token for a Supabase session. Shared
  /// by the mobile flow (called after `authenticate()` resolves, above) and
  /// the web flow (called from an `authenticationEvents` sign-in event, see
  /// `build()` below) — web has no imperative `authenticate()` call to await.
  Future<void> _completeGoogleSignIn(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google Sign-In: no ID token received');
    }
    _logger.auth('signInWithGoogle | user selected | email: ${LogHelper.maskEmail(account.email)}');

    final client = ref.read(supabaseClientProvider);
    _logger.db('BEFORE | op: signInWithIdToken | provider: google');
    // accessToken omitted: google_sign_in v7 requires a separate scope
    // authorization step that isn't needed for basic identity sign-in.
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      nonce: googleSignInRawNonce,
    );
    _logger.auth('signInWithGoogle SUCCESS | userId: ${client.auth.currentUser?.id}');
    _logger.provider('AuthNotifier → data (signInWithGoogle success)');
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/providers/auth_provider.dart`
Expected: `No issues found!`

- [ ] **Step 3: Run the existing test suite to confirm no regressions**

Run: `flutter test test/features/auth/auth_page_test.dart`
Expected: all 4 existing tests still pass (they exercise sign-up/login form widgets, not this method directly, but confirm nothing else in the auth feature broke).

- [ ] **Step 4: Commit**

```bash
git add lib/providers/auth_provider.dart
git commit -m "refactor(auth): extract shared Google idToken exchange in AuthNotifier"
```

---

### Task 5: Subscribe to `authenticationEvents` on web in `AuthNotifier.build()`

**Files:**
- Modify: `lib/providers/auth_provider.dart:1-49` (imports + `build()`)

**Interfaces:**
- Consumes: `_completeGoogleSignIn` from Task 4.
- Produces: on web, `AuthNotifier`'s `state` transitions to `AsyncLoading()`/`AsyncData(null)`/`AsyncError` in response to `GoogleSignIn.instance.authenticationEvents`, without any caller ever invoking `signInWithGoogle()` — this is what Task 6's `ref.listen` in `auth_page.dart` reacts to.

- [ ] **Step 1: Add the `kIsWeb` import**

In `lib/providers/auth_provider.dart`, change line 1-2 from:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

to:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

- [ ] **Step 2: Add the web subscription in `build()`**

Replace the current `build()` method:

```dart
  @override
  FutureOr<void> build() {
    _logger.provider('AuthNotifier build()');
    ref.onDispose(() => _logger.provider('AuthNotifier disposed'));
  }
```

with:

```dart
  @override
  FutureOr<void> build() {
    _logger.provider('AuthNotifier build()');
    ref.onDispose(() => _logger.provider('AuthNotifier disposed'));

    if (kIsWeb) {
      _logger.auth('signInWithGoogle (web) | subscribing to authenticationEvents');
      final subscription = GoogleSignIn.instance.authenticationEvents.listen(
        _handleGoogleAuthEvent,
        onError: (Object e, StackTrace st) {
          _logger.auth('signInWithGoogle (web) ERROR | authenticationEvents stream: $e', error: e, stackTrace: st);
          _logger.provider('AuthNotifier → error (signInWithGoogle web stream)');
          state = AsyncError(e, st);
        },
      );
      ref.onDispose(subscription.cancel);
    }
  }

  void _handleGoogleAuthEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        _logger.auth('signInWithGoogle (web) | authenticationEvents: sign-in received | email: ${LogHelper.maskEmail(event.user.email)}');
        unawaited(_handleWebGoogleSignIn(event.user));
      case GoogleSignInAuthenticationEventSignOut():
        _logger.auth('signInWithGoogle (web) | authenticationEvents: sign-out');
    }
  }

  Future<void> _handleWebGoogleSignIn(GoogleSignInAccount account) async {
    _logger.provider('AuthNotifier → loading (signInWithGoogle web)');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _completeGoogleSignIn(account));
    if (state.hasError) {
      _logger.auth('signInWithGoogle (web) ERROR | ${state.error}', error: state.error, stackTrace: state.stackTrace);
      _logger.provider('AuthNotifier → error (signInWithGoogle web)');
    }
  }
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/providers/auth_provider.dart`
Expected: `No issues found!`

- [ ] **Step 4: Run the existing test suite to confirm no regressions**

Run: `flutter test test/features/auth/auth_page_test.dart`
Expected: all 4 existing tests still pass — `flutter test` runs on the Dart VM, where `kIsWeb` is always `false`, so this new branch is not exercised by this command (that's expected; it's verified manually in Task 6).

- [ ] **Step 5: Commit**

```bash
git add lib/providers/auth_provider.dart
git commit -m "feat(auth): handle Google Sign-In authenticationEvents on web"
```

---

### Task 6: Wire the web button into `AuthPage` and surface web errors

**Files:**
- Modify: `lib/features/auth/auth_page.dart:1-11` (imports)
- Modify: `lib/features/auth/auth_page.dart:240-260` (approximate — inside `build()`, before the `return Scaffold(...)`)
- Modify: `lib/features/auth/auth_page.dart:354-356` (the `_GoogleSignInButton(...)` call site)
- Test: `test/features/auth/auth_page_test.dart`

**Interfaces:**
- Consumes: `GoogleWebSignInButton` from `google_web_signin_button.dart` (Task 3); `authNotifierProvider` state (Task 4/5).
- Produces: on web, the rendered Google button replaces `_GoogleSignInButton`; on mobile, nothing changes.

- [ ] **Step 1: Write the failing regression test first**

This test locks in that the mobile button (identified by its localized text) still renders — since `flutter test` always has `kIsWeb == false`, this exercises exactly the branch mobile users hit and would fail if the upcoming edit accidentally inverted the condition or removed the mobile branch.

Add to `test/features/auth/auth_page_test.dart`, inside the `group('AuthPage', ...)` block, after the last existing test:

```dart
    testWidgets('shows native Google button on non-web platforms', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pumpAndSettle();
      expect(find.text('Continuer avec Google'), findsOneWidget);
    });
```

- [ ] **Step 2: Run it to confirm it currently passes (baseline)**

Run: `flutter test test/features/auth/auth_page_test.dart -N "shows native Google button on non-web platforms"`
Expected: PASS — this confirms the baseline before the widget-swap edit, so a later regression is attributable to that edit.

- [ ] **Step 3: Add the imports**

In `lib/features/auth/auth_page.dart`, change lines 1-4 from:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
```

to:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
```

and add, after the existing `import '../../l10n/app_localizations.dart';` line:

```dart
import 'google_web_signin_button.dart';
```

- [ ] **Step 4: Add the `ref.listen` for web error surfacing**

In `_AuthPageState.build()`, find this existing line (currently around line 243):

```dart
    final isLoading = ref.watch(authNotifierProvider).isLoading;
```

Add immediately after it:

```dart
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
```

(Guarded by `!kIsWeb` so mobile's existing direct-await error handling in `_signInWithGoogle()` is unaffected — no double-set, no duplicate log lines.)

- [ ] **Step 5: Branch the button widget on `kIsWeb`**

Find the existing button call site (currently lines 354-356):

```dart
                          _GoogleSignInButton(
                            onPressed: isLoading ? null : _signInWithGoogle,
                          ),
```

Replace with:

```dart
                          kIsWeb
                              ? GoogleWebSignInButton(isLoading: isLoading)
                              : _GoogleSignInButton(
                                  onPressed: isLoading ? null : _signInWithGoogle,
                                ),
```

- [ ] **Step 6: Run the full auth test file**

Run: `flutter test test/features/auth/auth_page_test.dart`
Expected: all 5 tests pass (4 pre-existing + the new one from Step 1), confirming the mobile branch renders identically to before.

- [ ] **Step 7: Verify the whole app compiles**

Run: `flutter analyze`
Expected: `No issues found!` (or only pre-existing, unrelated warnings if the project already had any — no new issues introduced by this plan's files).

- [ ] **Step 8: Commit**

```bash
git add lib/features/auth/auth_page.dart test/features/auth/auth_page_test.dart
git commit -m "feat(auth): render Google's native button on web, wire up error display"
```

---

### Task 7: Manual end-to-end verification

**Files:** none (verification only).

- [ ] **Step 1: Run on web**

Run: `flutter run -d chrome`

- [ ] **Step 2: Click through the web Google Sign-In flow**

On the auth page, confirm:
- The native Google button renders where the custom button used to be (outline theme, pill shape, "Continuer avec Google"/"Continue with Google" text).
- Clicking it opens Google's own account chooser (not a crash, not the old `UnimplementedError`).
- Completing sign-in lands the app on the same post-auth screen mobile users reach (router redirect via `authStreamProvider`).
- While the sign-in is in flight, the button visibly dims and does not respond to a second click.

- [ ] **Step 3: Confirm mobile is unaffected**

Run: `flutter run` targeting an iOS simulator or connected device (or `flutter build ios --simulator` if no device is available), and click through Google Sign-In there.
Expected: identical behavior to before this plan — same `_GoogleSignInButton`, same `authenticate()` flow, no regressions.

- [ ] **Step 4: Final full-suite check**

Run: `flutter analyze && flutter test`
Expected: no issues, all tests pass.

No commit for this task — it's verification of work already committed in Tasks 1-6.

---

## Plan Self-Review Notes

- **Spec coverage:** Task 1 → dependency; Task 2 → the addendum (client-id fix); Task 3 → conditional button widget + styling decisions; Tasks 4-5 → `AuthNotifier` refactor + web stream handling; Task 6 → `auth_page.dart` wiring + error surfacing + regression test; Task 7 → the spec's manual "Testing" section. All spec sections are covered.
- **Placeholder scan:** none found — every step has complete, final code.
- **Type consistency:** `GoogleWebSignInButton({required bool isLoading})` is identical across the stub (Task 3, Step 1) and web impl (Task 3, Step 2), and used identically at the call site (Task 6, Step 5). `_completeGoogleSignIn(GoogleSignInAccount account)` (Task 4) is called identically from `signInWithGoogle()` (Task 4) and `_handleWebGoogleSignIn` (Task 5).
