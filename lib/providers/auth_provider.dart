import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
        data: (state) => state.session?.user,
      ) ??
      Supabase.instance.client.auth.currentUser;
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      print('Auth Log: Attempting sign up for email: $email');
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      print('Auth Log: Sign up response received. User ID: ${response.user?.id}');
      
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        print('Auth Log: Sign up successful, but email needs confirmation.');
        throw Exception('signup_email_confirmation_required');
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      print('Auth Log: Attempting sign in for email: $email');
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final user = response.user;
      print('Auth Log: Sign in response received for user: ${user?.id}');
      
      if (user != null && user.emailConfirmedAt == null) {
        print('Auth Log: Email not confirmed for user: ${user.id}. Signing out.');
        await Supabase.instance.client.auth.signOut();
        throw Exception('email_not_confirmed');
      }
      
      print('Auth Log: Sign in strictly successful, email is confirmed.');
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      print('Auth Log: Attempting sign out');
      await Supabase.instance.client.auth.signOut();
      print('Auth Log: Sign out successful');
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
