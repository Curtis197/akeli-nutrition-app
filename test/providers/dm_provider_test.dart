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

  group('ChatMessage.fromJson', () {
    final baseJson = {
      'id': 'msg-1',
      'conversation_id': 'conv-1',
      'sender_id': 'user-1',
      'user_profile': {'first_name': 'Alice', 'avatar_url': null},
      'content': 'Hello',
      'message_type': 'text',
      'recipe_id': null,
      'caption': null,
      'sent_at': '2026-06-12T10:00:00.000Z',
    };

    test('parses caption as null when absent', () {
      final msg = ChatMessage.fromJson(baseJson, currentUserId: 'user-2');
      expect(msg.caption, isNull);
    });

    test('parses caption value when present', () {
      final json = {...baseJson, 'caption': 'Délicieux!'};
      final msg = ChatMessage.fromJson(json, currentUserId: 'user-2');
      expect(msg.caption, equals('Délicieux!'));
    });

    test('isMine is true when senderId matches currentUserId', () {
      final msg = ChatMessage.fromJson(baseJson, currentUserId: 'user-1');
      expect(msg.isMine, isTrue);
    });

    test('isMine is false when senderId does not match', () {
      final msg = ChatMessage.fromJson(baseJson, currentUserId: 'user-2');
      expect(msg.isMine, isFalse);
    });
  });
}
