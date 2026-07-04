import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import 'auth_provider.dart';

final _logger = appLogger;

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final pushTokenProvider = Provider.autoDispose<void>((ref) {
  _logger.provider('pushTokenProvider build()');
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    _logger.provider('pushTokenProvider → no user, skipping FCM setup');
    return;
  }
  ref.onDispose(() => _logger.provider('pushTokenProvider disposed'));

  _logger.provider('pushTokenProvider → setting up FCM | userId: ${user.id}');
  final client = ref.read(supabaseClientProvider);
  final messaging = ref.watch(firebaseMessagingProvider);

  messaging.onTokenRefresh.listen((newToken) {
    _logger.provider('pushTokenProvider → token refreshed, re-uploading');
    _uploadToken(client, user.id, newToken);
  });

  _initFCM(client, messaging, user.id);
});

Future<void> _initFCM(SupabaseClient client, FirebaseMessaging messaging, String userId) async {
  _logger.provider('_initFCM | requesting permission | userId: $userId');
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  _logger.provider('_initFCM | permission: ${settings.authorizationStatus}');

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _uploadToken(client, userId, token);
      } else {
        _logger.provider('_initFCM | getToken returned null | userId: $userId');
      }
    } catch (e, st) {
      _logger.provider('_initFCM | ERROR getting token | $e', error: e, stackTrace: st);
    }
  }
}

Future<void> _uploadToken(SupabaseClient client, String userId, String token) async {
  _logger.db('BEFORE | table: push_token | op: UPSERT | userId: $userId');
  try {
    await client.from('push_token').upsert({
      'token': token,
      'user_id': userId,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
    _logger.db('AFTER | table: push_token | rows: 1');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls('Permission denied | table: push_token | userId: $userId', error: e, stackTrace: st);
    } else {
      _logger.db('ERROR | table: push_token | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
  } catch (e, st) {
    _logger.db('ERROR | table: push_token | $e', error: e, stackTrace: st);
  }
}
