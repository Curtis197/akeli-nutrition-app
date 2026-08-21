import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/google_sign_in_client.dart';
import '../core/logger.dart';

/// Where the password-recovery email deep-links back into the app.
/// Must be listed in Supabase Dashboard → Authentication → URL Configuration
/// → Redirect URLs, or Supabase silently falls back to the Site URL.
const _passwordResetRedirectUri = 'akeli://reset-password';

// ---------------------------------------------------------------------------
// Auth stream — single source of truth
// ---------------------------------------------------------------------------

final authStreamProvider = StreamProvider<AuthState>((ref) {
  appLogger.provider('authStreamProvider build() | subscribing to onAuthStateChange');
  ref.onDispose(() => appLogger.provider('authStreamProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((state) {
    appLogger.auth(
      'Auth state changed | event: ${state.event} | userId: ${state.session?.user.id ?? "null"}',
    );
    return state;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  final user = ref.watch(authStreamProvider).value?.session?.user;
  appLogger.provider('currentUserProvider evaluated | userId: ${user?.id ?? "null"}');
  return user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final isAuth = ref.watch(currentUserProvider) != null;
  appLogger.provider('isAuthenticatedProvider evaluated | isAuth: $isAuth');
  return isAuth;
});

// ---------------------------------------------------------------------------
// Auth notifier — sign-up, sign-in, sign-out, reset password
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<void> {
  final _logger = appLogger;

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

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _logger.auth('signUp BEFORE | email: ${LogHelper.maskEmail(email)}');
    _logger.provider('AuthNotifier → loading (signUp)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: signUp | supabase.auth.signUp');
        final response = await client.auth.signUp(
          email: email,
          password: password,
        );
        if (response.user == null) {
          _logger.auth('signUp ERROR | no user returned');
          throw Exception('Sign-up returned no user');
        }
        _logger.auth('signUp SUCCESS | userId: ${response.user!.id}');
        _logger.provider('AuthNotifier → data (signUp success)');
      } on AuthException catch (e, st) {
        _logger.auth('signUp ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signUp failed)');
        rethrow;
      } catch (e, st) {
        _logger.auth('signUp ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signUp unexpected)');
        rethrow;
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _logger.auth('signIn BEFORE | email: ${LogHelper.maskEmail(email)}');
    _logger.provider('AuthNotifier → loading (signIn)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: signInWithPassword | supabase.auth');
        final response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        _logger.auth('signIn SUCCESS | userId: ${response.user?.id ?? "null"}');
        _logger.provider('AuthNotifier → data (signIn success)');
      } on AuthException catch (e, st) {
        _logger.auth('signIn ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signIn AuthException)');
        rethrow;
      } catch (e, st) {
        _logger.auth('signIn ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signIn unexpected)');
        rethrow;
      }
    });
  }

  Future<void> signOut() async {
    _logger.auth('signOut BEFORE');
    _logger.provider('AuthNotifier → loading (signOut)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: signOut | supabase.auth');
        await client.auth.signOut();
        _logger.auth('signOut SUCCESS');
        _logger.provider('AuthNotifier → data (signOut success)');
      } catch (e, st) {
        _logger.auth('signOut ERROR | $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signOut failed)');
        rethrow;
      }
    });
  }

  Future<void> resetPassword(String email) async {
    _logger.auth('resetPassword BEFORE | email: ${LogHelper.maskEmail(email)}');
    _logger.provider('AuthNotifier → loading (resetPassword)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: resetPasswordForEmail | redirectTo: $_passwordResetRedirectUri');
        await client.auth.resetPasswordForEmail(
          email,
          redirectTo: _passwordResetRedirectUri,
        );
        _logger.auth('resetPassword SUCCESS | email: ${LogHelper.maskEmail(email)}');
        _logger.provider('AuthNotifier → data (resetPassword success)');
      } on AuthException catch (e, st) {
        _logger.auth('resetPassword ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (resetPassword failed)');
        rethrow;
      } catch (e, st) {
        _logger.auth('resetPassword ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (resetPassword unexpected)');
        rethrow;
      }
    });
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _logger.auth('updatePassword BEFORE');
    _logger.provider('AuthNotifier → loading (updatePassword)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final email = client.auth.currentUser?.email;
        if (email == null) throw Exception('No authenticated user');

        _logger.db('BEFORE | op: signInWithPassword | verify current password');
        await client.auth.signInWithPassword(email: email, password: currentPassword);
        _logger.auth('updatePassword | current password verified');

        _logger.db('BEFORE | op: updateUser | new password');
        await client.auth.updateUser(UserAttributes(password: newPassword));
        _logger.auth('updatePassword SUCCESS');
        _logger.provider('AuthNotifier → data (updatePassword success)');
      } on AuthException catch (e, st) {
        _logger.auth('updatePassword ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (updatePassword failed)');
        rethrow;
      } catch (e, st) {
        _logger.auth('updatePassword ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (updatePassword unexpected)');
        rethrow;
      }
    });
  }

  Future<void> recoveryUpdatePassword(String newPassword) async {
    _logger.auth('recoveryUpdatePassword BEFORE');
    _logger.provider('AuthNotifier → loading (recoveryUpdatePassword)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: updateUser | recovery password reset');
        await client.auth.updateUser(UserAttributes(password: newPassword));
        _logger.auth('recoveryUpdatePassword SUCCESS');
        _logger.provider('AuthNotifier → data (recoveryUpdatePassword success)');
      } on AuthException catch (e, st) {
        _logger.auth('recoveryUpdatePassword ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (recoveryUpdatePassword failed)');
        rethrow;
      } catch (e, st) {
        _logger.auth('recoveryUpdatePassword ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (recoveryUpdatePassword unexpected)');
        rethrow;
      }
    });
  }

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

  Future<void> signInWithApple() async {
    _logger.auth('signInWithApple BEFORE');
    _logger.provider('AuthNotifier → loading (signInWithApple)');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final rawNonce = _generateAppleRawNonce();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
        _logger.auth('signInWithApple | launching native sheet');
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );
        final idToken = credential.identityToken;
        if (idToken == null) {
          throw Exception('Sign in with Apple: no identity token received');
        }

        final client = ref.read(supabaseClientProvider);
        _logger.db('BEFORE | op: signInWithIdToken | provider: apple');
        await client.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        );
        _logger.auth('signInWithApple SUCCESS | userId: ${client.auth.currentUser?.id}');
        _logger.provider('AuthNotifier → data (signInWithApple success)');
      } on SignInWithAppleAuthorizationException catch (e, st) {
        if (e.code == AuthorizationErrorCode.canceled) {
          _logger.auth('signInWithApple CANCELLED | user dismissed sheet');
          return;
        }
        _logger.auth('signInWithApple ERROR | AuthorizationException: ${e.code} | ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signInWithApple AuthorizationException)');
        rethrow;
      } on AuthException catch (e, st) {
        _logger.auth('signInWithApple ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signInWithApple AuthException)');
        rethrow;
      } catch (e, st) {
        _logger.auth('signInWithApple ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signInWithApple unexpected)');
        rethrow;
      }
    });
  }

  /// Raw nonce for Sign in with Apple: the SHA-256 hash goes to Apple's
  /// authorization request, the raw value goes to Supabase's
  /// `signInWithIdToken` so it can verify the identity token was issued for
  /// this exact request.
  String _generateAppleRawNonce([int length = 32]) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> deleteAccount() async {
    _logger.auth('deleteAccount BEFORE');
    _logger.provider('AuthNotifier → loading (deleteAccount)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.edge('delete-account', 'BEFORE | invoking edge function');
        final response = await client.functions.invoke('delete-account', method: HttpMethod.post);
        _logger.edge('delete-account', 'AFTER | status: ${response.status}');

        if (response.status != 200) {
          throw Exception('delete-account returned status ${response.status}');
        }

        _logger.db('BEFORE | op: signOut | after account deletion');
        await client.auth.signOut();
        _logger.auth('deleteAccount SUCCESS | user signed out');
        _logger.provider('AuthNotifier → data (deleteAccount success)');
      } catch (e, st) {
        _logger.edge('delete-account', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (deleteAccount failed)');
        rethrow;
      }
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
