import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Mock User Entity (Replaces Supabase User)
// ---------------------------------------------------------------------------

class MockUser {
  final String id;
  final String email;
  final String? name;

  MockUser({
    required this.id,
    required this.email,
    this.name,
  });
}

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

final authStateProvider = StateProvider<MockUser?>((ref) {
  // Par défaut, l'utilisateur est connecté pour faciliter le design
  return MockUser(
    id: 'mock-user-123',
    email: 'contact@akeli.app',
    name: 'Utilisateur Akeli',
  );
});

final currentUserProvider = Provider<MockUser?>((ref) {
  return ref.watch(authStateProvider);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ---------------------------------------------------------------------------
// Auth notifier — Mock sign-up, sign-in, sign-out
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(seconds: 1));
    ref.read(authStateProvider.notifier).state = MockUser(
      id: 'mock-user-123',
      email: email,
      name: 'Nouveau Gourmet',
    );
    state = const AsyncValue.data(null);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(seconds: 1));
    ref.read(authStateProvider.notifier).state = MockUser(
      id: 'mock-user-123',
      email: email,
      name: 'Utilisateur Akeli',
    );
    state = const AsyncValue.data(null);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 500));
    ref.read(authStateProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(seconds: 1));
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
