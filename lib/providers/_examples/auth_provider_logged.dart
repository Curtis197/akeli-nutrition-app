// lib/providers/_examples/auth_provider_logged.dart
/**
 * EXAMPLE: Authentication Provider with Comprehensive Logging
 * 
 * This example demonstrates how to implement comprehensive logging
 * in a Riverpod authentication provider following Akeli's logging standards.
 * 
 * You can use this as a template for other providers.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/logger.dart' show LogHelper;

/// Auth state model
class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  const AuthState.initial()
      : user = null,
        profile = null,
        isLoading = false,
        error = null;

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool isLoading = false,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null && error == null;
}

/// Simple user profile model
class UserProfile {
  final String id;
  final String email;
  final String? displayName;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
    );
  }
}

/// Auth notifier with comprehensive logging
class AuthNotifier extends AsyncNotifier<AuthState> {
  final _logger = appLogger;

  @override
  Future<AuthState> build() async {
    _logger.provider('AuthNotifier initialized');
    
    // Listen to auth state changes from Supabase
    ref.onDispose(() {
      _logger.provider('AuthNotifier disposed');
    });
    
    // Check for existing session
    return await _loadSession();
  }

  /// Load existing session from storage
  Future<AuthState> _loadSession() async {
    _logger.auth('Loading existing session');
    
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      if (session == null) {
        _logger.auth('No existing session found');
        return const AuthState.initial();
      }
      
      _logger.auth('Existing session found for userId: ${session.user.id}');
      
      // Load user profile
      final profile = await _loadUserProfile(session.user.id);
      
      _logger.auth('Session loaded successfully with profile');
      
      return AuthState(
        user: session.user,
        profile: profile,
      );
    } catch (e, st) {
      _logger.auth('Failed to load session: $e', error: e, stackTrace: st);
      // Clear invalid session
      await signOut();
      return const AuthState.initial();
    }
  }

  /// Sign in with email and password
  Future<AuthState> signIn({
    required String email,
    required String password,
  }) async {
    final maskedEmail = LogHelper.maskEmail(email);
    _logger.auth('Sign-in attempt for email: $maskedEmail');
    
    state = const AsyncValue.data(
      AuthState(isLoading: true),
    );
    
    return state = await AsyncValue.guard(() async {
      try {
        final supabase = Supabase.instance.client;
        
        _logger.debug('📡 DB: Attempting sign-in with Supabase Auth');
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (response.user == null) {
          _logger.auth('Sign-in failed: No user returned');
          throw Exception('Sign-in failed: No user returned');
        }
        
        _logger.auth('Sign-in successful for userId: ${response.user!.id}');
        
        // Load user profile
        final profile = await _loadUserProfile(response.user!.id);
        
        _logger.auth('User profile loaded successfully');
        
        return AuthState(
          user: response.user,
          profile: profile,
        );
      } on AuthException catch (e, st) {
        _logger.auth('Sign-in failed with AuthException: ${e.message}', error: e, stackTrace: st);
        rethrow;
      } catch (e, st) {
        _logger.auth('Sign-in failed with unexpected error: $e', error: e, stackTrace: st);
        rethrow;
      }
    });
  }

  /// Sign up with email and password
  Future<AuthState> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final maskedEmail = LogHelper.maskEmail(email);
    _logger.auth('Sign-up attempt for email: $maskedEmail');
    
    state = const AsyncValue.data(
      AuthState(isLoading: true),
    );
    
    return state = await AsyncValue.guard(() async {
      try {
        final supabase = Supabase.instance.client;
        
        _logger.debug('📡 DB: Attempting sign-up with Supabase Auth');
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            if (displayName != null) 'display_name': displayName,
          },
        );
        
        if (response.user == null) {
          _logger.auth('Sign-up failed: No user returned');
          throw Exception('Sign-up failed: No user returned');
        }
        
        _logger.auth('Sign-up successful for userId: ${response.user!.id}');
        
        // Create user profile
        await _createUserProfile(response.user!.id, email, displayName);
        
        // Load user profile
        final profile = await _loadUserProfile(response.user!.id);
        
        _logger.auth('User profile created and loaded successfully');
        
        return AuthState(
          user: response.user,
          profile: profile,
        );
      } on AuthException catch (e, st) {
        _logger.auth('Sign-up failed with AuthException: ${e.message}', error: e, stackTrace: st);
        rethrow;
      } catch (e, st) {
        _logger.auth('Sign-up failed with unexpected error: $e', error: e, stackTrace: st);
        rethrow;
      }
    });
  }

  /// Sign out
  Future<void> signOut() async {
    _logger.auth('Sign-out triggered');
    
    state = const AsyncValue.data(
      AuthState(isLoading: true),
    );
    
    await AsyncValue.guard(() async {
      try {
        final supabase = Supabase.instance.client;
        
        _logger.debug('📡 DB: Calling Supabase auth.signOut()');
        await supabase.auth.signOut();
        
        _logger.auth('Sign-out successful, clearing state');
        
        state = const AsyncValue.data(AuthState.initial());
      } catch (e, st) {
        _logger.auth('Sign-out failed: $e', error: e, stackTrace: st);
        // Still clear state even if sign-out fails
        state = const AsyncValue.data(AuthState.initial());
      }
    });
  }

  /// Load user profile from database
  Future<UserProfile?> _loadUserProfile(String userId) async {
    _logger.db('Loading user profile for userId: $userId');
    
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('user_profile')
          .select('id, email, display_name')
          .eq('id', userId)
          .single();
      
      final profile = UserProfile.fromJson(response);
      
      _logger.db('User profile loaded successfully');
      
      return profile;
    } catch (e, st) {
      _logger.db('Failed to load user profile: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Create user profile in database
  Future<void> _createUserProfile(
    String userId,
    String email,
    String? displayName,
  ) async {
    _logger.db('Creating user profile for userId: $userId');
    
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase.from('user_profile').insert({
        'id': userId,
        'email': email,
        'display_name': displayName,
      }).select().single();
      
      _logger.db('User profile created successfully');
    } catch (e, st) {
      _logger.db('Failed to create user profile: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}

/// Provider for auth state
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value?.user;
});

/// Provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value?.isAuthenticated ?? false;
});
