import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'package:akeli/providers/dm_provider.dart';
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

    when(() => mockSupabaseClient.from(any())).thenAnswer((_) => mockQueryBuilder);

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

  test('markConversationRead updates last_read_at', () async {
    final mockUpdateBuilder = MockUpdateFilterBuilder();
    when(() => mockQueryBuilder.update(any())).thenAnswer((_) => mockUpdateBuilder);

    await markConversationRead(mockRef, 'test_conv_id');

    final captured = verify(() => mockQueryBuilder.update(captureAny())).captured;
    expect(captured.single, isA<Map>());
    expect((captured.single as Map).containsKey('last_read_at'), isTrue);
  });
}
