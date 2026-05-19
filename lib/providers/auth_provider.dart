import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/logger.dart';

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
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        _logger.auth('signIn SUCCESS');
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
        _logger.db('BEFORE | op: resetPasswordForEmail | supabase.auth');
        await client.auth.resetPasswordForEmail(email);
        _logger.auth('resetPassword SUCCESS | email: ${LogHelper.maskEmail(email)}');
        _logger.provider('AuthNotifier → data (resetPassword success)');
      } on AuthException catch (e, st) {
        _logger.auth('resetPassword ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (resetPassword failed)');
        rethrow;
      } catch (e, st) {
        _logger.auth('resetPassword ERROR | unexpected: $e', error: e, stackTrace: st);
        rethrow;
      }
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
