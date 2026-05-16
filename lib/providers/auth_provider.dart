import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

// ---------------------------------------------------------------------------
// Auth stream — single source of truth
// ---------------------------------------------------------------------------

final authStreamProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStreamProvider).value?.session?.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ---------------------------------------------------------------------------
// Auth notifier — sign-up, sign-in, sign-out, reset password
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) throw Exception('Sign-up returned no user');
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signOut() async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.signOut();
    });
  }

  Future<void> resetPassword(String email) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.resetPasswordForEmail(email);
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
