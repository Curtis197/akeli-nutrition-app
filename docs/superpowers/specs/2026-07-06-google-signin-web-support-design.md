# Google Sign-In on Flutter Web — Design Spec

**Date:** 2026-07-06
**Status:** Approved

## Problem

`AuthNotifier.signInWithGoogle()` (`lib/providers/auth_provider.dart:218`) calls
`GoogleSignIn.instance.authenticate()`. On Flutter Web this always throws:

```
UnimplementedError: authenticate is not supported on the web.
Instead, use renderButton to create a sign-in widget.
```

Confirmed at the source (`google_sign_in_web-1.1.3/lib/google_sign_in_web.dart`):

```dart
@override
bool supportsAuthenticate() => false;

@override
Future<AuthenticationResults> authenticate(AuthenticateParameters params) async {
  throw UnimplementedError(
    'authenticate is not supported on the web. '
    'Instead, use renderButton to create a sign-in widget.',
  );
}
```

This is an intentional, permanent platform restriction (not a bug or config issue):
browser third-party-cookie/FedCM policy requires the sign-in flow to originate from
Google's own rendered button element, not an app-triggered popup. Mobile
(`google_sign_in_ios`/`google_sign_in_android`) is unaffected and keeps working as-is.

## Goal

Make "Continue with Google" work on Flutter Web by rendering Google's own button
widget there and reacting to its sign-in event, while leaving the existing mobile
flow (`authenticate()` + awaited result) completely unchanged.

## Scope

| File / Object | Change |
|---|---|
| `lib/features/auth/google_web_signin_button.dart` | New — conditional export (web impl vs. stub) |
| `lib/features/auth/google_web_signin_button_stub.dart` | New — non-web stub, never actually rendered |
| `lib/features/auth/google_web_signin_button_web.dart` | New — real web button using `google_sign_in_web`'s `renderButton()` |
| `lib/features/auth/auth_page.dart` | Yes — branch button widget on `kIsWeb`; add `ref.listen` for web error surfacing |
| `lib/providers/auth_provider.dart` (`AuthNotifier`) | Yes — extract shared idToken→Supabase exchange helper; subscribe to `authenticationEvents` on web |
| Mobile `signInWithGoogle()` / `_GoogleSignInButton` | **No change** — existing `authenticate()`-awaited flow stays as-is |
| Pixel-perfect visual match to the custom mobile button | **Out of scope** — accepted trade-off (see Decisions) |
| `lib/core/google_sign_in_client.dart` (`initializeGoogleSignIn`) | Yes — **addendum, found during planning**: unconditionally passes `clientId: _iosClientId` + `serverClientId: _webClientId` today. On web, `serverClientId` isn't supported at all (the plugin asserts on it) and the `clientId` must be a **web** OAuth client, not the iOS one — otherwise GIS rejects the origin regardless of the render-button fix. Branch on `kIsWeb`: web passes `clientId: _webClientId` and omits `serverClientId`; mobile keeps today's call unchanged. No new Google Cloud Console config needed — `_webClientId` already exists and is already the audience Supabase accepts (it's used as `serverClientId` today). |

## Decisions (confirmed with user)

1. **Native Google-styled button on web**, not a transparent-overlay hack. Configured
   via `GSIButtonConfiguration` to get as close as reasonably possible to the app's
   look (outline theme, pill shape, large size, "continue with" text, centered logo),
   but Google controls the actual chrome/font — it will not be pixel-identical to
   `_GoogleSignInButton`.
2. **Loading/disabled state**: since Google's rendered button has no `onPressed` to
   null out, wrap it in `IgnorePointer` + dimmed `AnimatedOpacity` when
   `AuthNotifier`'s `isLoading` is true, matching the disabled look of the rest of
   the form.

## Architecture

### 1. Conditional web button widget

`google_web_signin_button.dart` is the only file imported elsewhere:

```dart
export 'google_web_signin_button_stub.dart'
    if (dart.library.html) 'google_web_signin_button_web.dart';
```

This keeps `dart:ui_web` / `package:web` (pulled in transitively by
`google_sign_in_web/web_only.dart`) out of the mobile build entirely — the stub
exists purely so mobile compiles; it is never actually built into the widget tree
because `auth_page.dart` branches on `kIsWeb` before choosing which widget class to
instantiate.

`google_web_signin_button_web.dart`:

```dart
class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({required this.isLoading, super.key});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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

### 2. `auth_page.dart`

Replace the single button call with a platform branch; mobile path untouched:

```dart
kIsWeb
    ? GoogleWebSignInButton(isLoading: isLoading)
    : _GoogleSignInButton(onPressed: isLoading ? null : _signInWithGoogle),
```

Add, in `build()`, a `kIsWeb`-guarded listener so the web flow's asynchronous state
change (driven by the stream, not a tap handler) still surfaces errors the same way
every other auth method here does:

```dart
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

Guarding with `kIsWeb` means mobile's existing direct-await error handling in
`_signInWithGoogle()` is unaffected (no double-set, no duplicate log lines).

### 3. `auth_provider.dart` (`AuthNotifier`)

Extract the idToken → `signInWithIdToken` body currently inline in
`signInWithGoogle()` into a shared private helper:

```dart
Future<void> _completeGoogleSignIn(GoogleSignInAccount account) async {
  final idToken = account.authentication.idToken;
  if (idToken == null) {
    throw Exception('Google Sign-In: no ID token received');
  }
  _logger.auth('signInWithGoogle | user selected | email: ${LogHelper.maskEmail(account.email)}');

  final client = ref.read(supabaseClientProvider);
  _logger.db('BEFORE | op: signInWithIdToken | provider: google');
  await client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    nonce: googleSignInRawNonce,
  );
  _logger.auth('signInWithGoogle SUCCESS | userId: ${client.auth.currentUser?.id}');
  _logger.provider('AuthNotifier → data (signInWithGoogle success)');
}
```

`signInWithGoogle()` (mobile path) calls this after `authenticate()` resolves —
behavior identical to today, just refactored.

In `build()`, subscribe to the web event stream and clean it up on dispose (mirrors
the existing `authStreamProvider` subscription pattern already in this file):

```dart
@override
FutureOr<void> build() {
  _logger.provider('AuthNotifier build()');
  ref.onDispose(() => _logger.provider('AuthNotifier disposed'));

  if (kIsWeb) {
    final sub = GoogleSignIn.instance.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _logger.auth('signInWithGoogle (web) | authenticationEvents: sign-in received');
          unawaited(_handleWebGoogleSignIn(event.user));
        case GoogleSignInAuthenticationEventSignOut():
          _logger.auth('signInWithGoogle (web) | authenticationEvents: sign-out');
      }
    }, onError: (Object e, StackTrace st) {
      _logger.auth('signInWithGoogle (web) ERROR | authenticationEvents stream: $e', error: e, stackTrace: st);
      state = AsyncError(e, st);
    });
    ref.onDispose(sub.cancel);
  }
}

Future<void> _handleWebGoogleSignIn(GoogleSignInAccount account) async {
  _logger.provider('AuthNotifier → loading (signInWithGoogle web)');
  state = const AsyncLoading();
  state = await AsyncValue.guard(() => _completeGoogleSignIn(account));
}
```

## Data flow (web)

1. `AuthPage` builds with `kIsWeb == true` → renders `GoogleWebSignInButton`.
2. User clicks Google's embedded button → Google Identity Services SDK runs the
   OAuth popup/FedCM flow entirely inside its own iframe/JS — no app code involved.
3. On completion, `google_sign_in_web`'s internal `GisSdkClient` emits an event →
   surfaces on `GoogleSignIn.instance.authenticationEvents` as
   `GoogleSignInAuthenticationEventSignIn`.
4. `AuthNotifier`'s listener (subscribed in `build()`) fires, extracts the idToken,
   calls `_completeGoogleSignIn`.
5. `client.auth.signInWithIdToken(...)` succeeds → Supabase session updates →
   the already-existing `authStreamProvider` (`onAuthStateChange`) and router
   redirect take over navigation, identical to the mobile success path today.

No auto/silent sign-in is introduced by this change — confirmed nothing in the app
currently calls `attemptLightweightAuthentication` or `signInSilently`, so the
stream only ever fires in response to an explicit button click.

## Error handling

- **Stream error** (`onError`): logged via `_logger.auth(...)`, sets `AsyncError`
  state → picked up by `auth_page.dart`'s `kIsWeb`-guarded `ref.listen` → shown via
  the existing `_friendly()` message mapping.
- **Cancelled/dismissed popup**: Google's own UI handles this client-side; if it
  surfaces as an error string containing "cancelled"/"canceled", it's swallowed
  the same way the mobile path already does.
- **Missing idToken**: same `Exception('Google Sign-In: no ID token received')`
  thrown in the shared helper, on both platforms.

## Logging (per project standard)

All new/modified auth events and provider state transitions follow the existing
`_logger.auth(...)` / `_logger.provider(...)` conventions already used throughout
`auth_provider.dart` — BEFORE/SUCCESS/ERROR for the sign-in exchange, and explicit
`AuthNotifier → loading/data/error` provider transition logs. Email is masked via
`LogHelper.maskEmail` exactly as in the existing mobile path.

## Testing

- Manual: `flutter run -d chrome`, click the Google button, verify sign-in
  completes and lands on the same post-auth screen as mobile.
- Manual: verify mobile (iOS) Google Sign-In is unaffected — `authenticate()` path
  untouched.
- Manual: trigger an error (e.g. deny consent) on web and confirm the friendly
  error message appears via the new `ref.listen` path.
