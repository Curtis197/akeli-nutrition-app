import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'package:akeli/providers/notifications_provider.dart';
import 'package:akeli/providers/auth_provider.dart';
import 'package:akeli/core/supabase_client.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockWidgetRef extends Mock implements WidgetRef {}
class FakeProvider extends Fake implements ProviderListenable<Object?> {}
final dummyProvider = Provider((ref) => null);

class MockUpdateFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    return Future.value(<Map<String, dynamic>>[]).then(onValue, onError: onError);
  }
}

class MockCountBuilder extends Mock implements ResponsePostgrestBuilder<PostgrestResponse<List<Map<String, dynamic>>>, List<Map<String, dynamic>>, List<Map<String, dynamic>>> {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestResponse<List<Map<String, dynamic>>>) onValue, {
    Function? onError,
  }) {
    const response = PostgrestResponse<List<Map<String, dynamic>>>(data: [], count: 3);
    return Future.value(response).then(onValue, onError: onError);
  }
}

class MockSelectFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    return this;
  }

  @override
  ResponsePostgrestBuilder<PostgrestResponse<List<Map<String, dynamic>>>, List<Map<String, dynamic>>, List<Map<String, dynamic>>> count([CountOption? count]) {
    return MockCountBuilder();
  }
  
  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    return Future.value(<Map<String, dynamic>>[]).then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockWidgetRef mockRef;
  ProviderContainer? container;

  setUpAll(() {
    registerFallbackValue(const <String, dynamic>{});
    registerFallbackValue(FakeProvider());
    registerFallbackValue(dummyProvider);
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockRef = MockWidgetRef();

    when(() => mockSupabaseClient.from('notification')).thenAnswer((_) => mockQueryBuilder);

    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabaseClient),
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

    when(() => mockRef.read(currentUserProvider)).thenReturn(
      const User(
        id: 'test_user_id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-06-02T00:00:00Z',
      ),
    );
    when(() => mockRef.read(supabaseClientProvider)).thenReturn(mockSupabaseClient);
    when(() => mockRef.invalidate(any())).thenReturn(null);
  });

  tearDown(() {
    container?.dispose();
  });

  test('markAllNotificationsRead updates notifications', () async {
    final mockUpdateBuilder = MockUpdateFilterBuilder();
    when(() => mockQueryBuilder.update(any())).thenAnswer((_) => mockUpdateBuilder);

    await markAllNotificationsRead(mockRef);

    verify(() => mockQueryBuilder.update({'is_read': true})).called(1);
  });

  test('unreadNotificationCountProvider fetches count', () async {
    final mockSelectBuilder = MockSelectFilterBuilder();
    when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockSelectBuilder);
    when(() => mockQueryBuilder.select()).thenAnswer((_) => mockSelectBuilder);

    final count = await container!.read(unreadNotificationCountProvider.future);

    expect(count, 3);
    verify(() => mockQueryBuilder.select()).called(1);
  });
}
