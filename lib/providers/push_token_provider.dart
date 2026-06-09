import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import 'auth_provider.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final pushTokenProvider = Provider.autoDispose<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  appLogger.provider('pushTokenProvider | User logged in. Setting up FCM.');
  
  final client = ref.read(supabaseClientProvider);
  final messaging = ref.watch(firebaseMessagingProvider);
  
  // Set up background token refresh
  messaging.onTokenRefresh.listen((newToken) {
    _uploadToken(client, user.id, newToken);
  });

  // Request permissions and initial token
  _initFCM(client, messaging, user.id);
});

Future<void> _initFCM(SupabaseClient client, FirebaseMessaging messaging, String userId) async {
  // Request permissions (primarily for iOS)
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  appLogger.provider('FCM Permission status: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _uploadToken(client, userId, token);
      }
    } catch (e) {
      appLogger.provider('Error getting FCM token: $e');
    }
  }
}

Future<void> _uploadToken(SupabaseClient client, String userId, String token) async {
  try {
    appLogger.db('Upserting FCM token for user $userId');
    await client.from('push_token').upsert({
      'token': token,
      'user_id': userId,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
    appLogger.db('FCM token upsert successful');
  } catch (e) {
    appLogger.db('Failed to upsert FCM token: $e');
  }
}
