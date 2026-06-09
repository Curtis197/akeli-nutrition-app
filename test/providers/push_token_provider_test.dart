import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

import 'package:akeli/providers/push_token_provider.dart';
import 'package:akeli/providers/auth_provider.dart';
import 'package:akeli/core/supabase_client.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  // Dart's await mechanism relies on the 'then' method.
  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    return Future.value(<Map<String, dynamic>>[]).then(onValue, onError: onError);
  }
}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockNotificationSettings extends Mock implements NotificationSettings {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  ProviderContainer? container;
  late StreamController<String> tokenRefreshController;

  setUpAll(() {
    registerFallbackValue(const <String, dynamic>{});
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    tokenRefreshController = StreamController<String>.broadcast();

    // Setup Supabase mocks
    when(() => mockSupabaseClient.from('push_token')).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.upsert(any(), onConflict: any(named: 'onConflict')))
        .thenAnswer((_) => MockPostgrestFilterBuilder());

    // Setup FirebaseMessaging mocks
    when(() => mockFirebaseMessaging.onTokenRefresh)
        .thenAnswer((_) => tokenRefreshController.stream);

    final mockSettings = MockNotificationSettings();
    when(() => mockSettings.authorizationStatus).thenReturn(AuthorizationStatus.authorized);
    when(() => mockFirebaseMessaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        )).thenAnswer((_) async => mockSettings);
    when(() => mockFirebaseMessaging.getToken()).thenAnswer((_) async => 'test_fcm_token');

    // Create container overriding necessary providers
    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabaseClient),
        firebaseMessagingProvider.overrideWithValue(mockFirebaseMessaging),
        // Mock currentUserProvider to return a logged-in user
        currentUserProvider.overrideWithValue(
          const User(
            id: 'test_user_id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-06-02T00:00:00Z',
          ),
        ),
      ],
    );
  });

  tearDown(() {
    tokenRefreshController.close();
    container?.dispose();
  });

  test('pushTokenProvider initializes FCM and uploads token for logged in user', () async {
    // Act
    container!.read(pushTokenProvider);

    // Assert
    // Give async operations a moment to complete
    await Future.delayed(Duration.zero);

    // Verify permissions requested
    verify(() => mockFirebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        )).called(1);

    // Verify token was fetched
    verify(() => mockFirebaseMessaging.getToken()).called(1);

    // Verify token was upserted to Supabase
    verify(() => mockQueryBuilder.upsert(
          any(that: isA<Map<String, dynamic>>().having((map) => map['token'], 'token', 'test_fcm_token')),
          onConflict: 'token',
        )).called(1);
  });

  test('pushTokenProvider responds to token refresh stream', () async {
    // Act
    container!.read(pushTokenProvider);
    await Future.delayed(Duration.zero);

    // Simulate token refresh
    tokenRefreshController.add('refreshed_fcm_token');
    await Future.delayed(Duration.zero);

    // Verify the refreshed token was upserted
    verify(() => mockQueryBuilder.upsert(
          any(that: isA<Map<String, dynamic>>().having((map) => map['token'], 'token', 'refreshed_fcm_token')),
          onConflict: 'token',
        )).called(1);
  });
}
