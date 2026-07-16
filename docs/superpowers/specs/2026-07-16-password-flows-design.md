# Password Flows — Forgot-Password Fix + In-App Change Verification

**Date:** 2026-07-16
**Status:** Approved
**Platforms:** iOS + Android (web out of scope)

## Problem

1. **Forgot-password is broken on mobile.** `resetPasswordForEmail(email)` is called
   without `redirectTo` ([auth_provider.dart:174](../../../lib/providers/auth_provider.dart)),
   and no custom URL scheme is registered on either platform. The reset email links to
   the Supabase Site URL (a web address), so tapping it opens a browser dead-end. The
   `AuthChangeEvent.passwordRecovery` event the router waits for
   ([router.dart:144-149](../../../lib/core/router.dart)) can never fire on a phone,
   even though the downstream ResetPasswordPage is fully built.

2. **In-app password change exists but is unverified**, and has two consistency gaps:
   - Minimum password length is 8 chars on the Account page but 6 on the ResetPasswordPage.
   - Google-only users (no password set) see the change-password form; the current-password
     verification fails with a misleading "invalid password" error.

3. **L10n violations** on the affected screens: ResetPasswordPage and the
   forgot-password dialog in auth_page.dart use hardcoded
   `localeName == 'en' ? ... : ...` ternaries, violating the mandatory L10n standard.

## Design

### 1. Deep-link plumbing (chosen over OTP-code entry)

The email link redirects back into the app via a custom scheme. Chosen because the
entire downstream flow (recovery event → router redirect → ResetPasswordPage →
`recoveryUpdatePassword`) already exists; this is the smallest change that completes
the chain. Known limitation, accepted: the email must be opened on the same device
where the app is installed (PKCE code verifier is stored locally).

- **Flutter** — `resetPassword()` in `lib/providers/auth_provider.dart`:

  ```dart
  await client.auth.resetPasswordForEmail(email, redirectTo: 'akeli://reset-password');
  ```

- **Android** — `android/app/src/main/AndroidManifest.xml`: second `intent-filter`
  on `MainActivity`:

  ```xml
  <intent-filter>
      <action android:name="android.intent.action.VIEW"/>
      <category android:name="android.intent.category.DEFAULT"/>
      <category android:name="android.intent.category.BROWSABLE"/>
      <data android:scheme="akeli" android:host="reset-password"/>
  </intent-filter>
  ```

- **iOS** — `ios/Runner/Info.plist`: second dict under `CFBundleURLTypes` declaring
  the `akeli` scheme (alongside the existing Google Sign-In scheme).

- **No new packages.** `supabase_flutter` bundles `app_links` and handles the
  incoming link automatically (cold start and warm start), fires `passwordRecovery`.

- **Manual dashboard step (Curtis):** Supabase Dashboard → Authentication →
  URL Configuration → add `akeli://reset-password` to Redirect URLs. Without it,
  Supabase silently falls back to the Site URL.

### 2. In-app password change — verify + consistency fixes

- Verify the existing Settings → Account flow end-to-end: wrong current password,
  mismatched confirmation, happy path.
- Standardize minimum password length to **8** everywhere (raise ResetPasswordPage
  validator from 6 to 8).
- Hide the password section on the Account page when the user's only auth provider
  is `google` (read `user.appMetadata['providers']`); such users have no password
  to change.

### 3. L10n cleanup (mandated by CLAUDE.md)

Replace every `localeName == 'en' ? ... : ...` ternary on the touched screens with
proper ARB keys in both `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`:

- `lib/features/auth/reset_password_page.dart` (title, field hints, validators,
  button label, success snackbar)
- Forgot-password dialog + result snackbar in `lib/features/auth/auth_page.dart`

Key naming follows the `<screen>_<key>` camelCase convention
(e.g. `resetPasswordTitle`, `authForgotDialogBody`). Run `flutter gen-l10n` after.

## Error handling

- Reset email send failure: existing `AuthException` path in `resetPassword()`
  surfaces the error on the auth page — unchanged.
- Recovery link expired/invalid: Supabase redirects with an error fragment and no
  session is created; no `passwordRecovery` event fires, so the app stays on the
  auth page. Acceptable for this iteration.
- `recoveryUpdatePassword` failure: existing error display on ResetPasswordPage —
  unchanged.

## Testing

- `flutter analyze` clean after changes.
- Deep-link smoke test without the email round-trip:
  - Android: `adb shell am start -d "akeli://reset-password"`
  - iOS simulator: `xcrun simctl openurl booted akeli://reset-password`
- Full forgot-password flow with a real email on device (after the dashboard
  allowlist step).
- Manual test of the in-app change-password flow with a test account, including
  the Google-only account hiding behavior.

## Out of scope (YAGNI)

- Web platform support for the recovery link
- OTP-code fallback flow
- Password strength meter
- Signing out other sessions after a password change
