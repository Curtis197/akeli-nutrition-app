  import 'dart:async';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';

  import 'package:akeli/providers/user_profile_provider.dart';
  import 'package:akeli/providers/auth_provider.dart';
  import 'package:akeli/core/supabase_client.dart';

  class MockSupabaseClient extends Mock implements SupabaseClient {}
  class MockFunctionsClient extends Mock implements FunctionsClient {}
  class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

  /// Mocks `.select().eq('id', ...).maybeSingle()` on `user_profile`. `.select()`
  /// returns `PostgrestFilterBuilder<PostgrestList>`; `.eq()` returns `this`;
  /// `.maybeSingle()` hands off to a second fake typed for the final awaited
  /// `Map<String, dynamic>?` result — mirroring the real Postgrest builder chain.
  class FakeUserProfileFilterBuilder extends Mock
      implements PostgrestFilterBuilder<PostgrestList> {
    FakeUserProfileFilterBuilder(this._value);
    final Map<String, dynamic>? _value;

    @override
    PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

    @override
    PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
        FakeMaybeSingleBuilder(_value);
  }

  class FakeMaybeSingleBuilder extends Mock
      implements PostgrestTransformBuilder<PostgrestMap?> {
    FakeMaybeSingleBuilder(this._value);
    final Map<String, dynamic>? _value;

    @override
    Future<R> then<R>(FutureOr<R> Function(PostgrestMap?) onValue,
        {Function? onError}) {
      return Future.value(_value).then(onValue, onError: onError);
    }
  }

  /// Mocks `client.rpc(...)`, awaited directly with the result discarded.
  class FakeRpcBuilder extends Mock implements PostgrestFilterBuilder<dynamic> {
    @override
    Future<R> then<R>(FutureOr<R> Function(dynamic) onValue,
        {Function? onError}) {
      return Future.value(null).then(onValue, onError: onError);
    }
  }

  const _testUser = User(
    id: 'test_user_id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-06-02T00:00:00Z',
  );

  void main() {
    setUpAll(() {
      registerFallbackValue(const <String, dynamic>{});
    });

    group('UserProfileNotifier.completeBeautyOnboarding', () {
      late MockSupabaseClient mockSupabaseClient;
      late MockFunctionsClient mockFunctionsClient;
      late MockSupabaseQueryBuilder mockQueryBuilder;
      ProviderContainer? container;

      setUp(() {
        mockSupabaseClient = MockSupabaseClient();
        mockFunctionsClient = MockFunctionsClient();
        mockQueryBuilder = MockSupabaseQueryBuilder();

        when(() => mockSupabaseClient.functions).thenReturn(mockFunctionsClient);
        when(() => mockSupabaseClient.from('user_profile'))
            .thenAnswer((_) => mockQueryBuilder);

        container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
            currentUserProvider.overrideWithValue(_testUser),
          ],
        );
      });

      tearDown(() => container?.dispose());

      Future<void> callCompleteBeautyOnboarding() {
        return container!.read(userProfileNotifierProvider.notifier).completeBeautyOnboarding(
              hairType: 'curly',
              porosity: 'medium',
              skinType: 'combination',
              scalpType: 'normal',
              beautyGoals: const ['hair_growth'],
            );
      }

      test('falls back to RPC when the edge function throws, and tolerates a null re-fetch', () async {
        when(() => mockFunctionsClient.invoke(any(), body: any(named: 'body')))
            .thenThrow(Exception('network error'));
        when(() => mockSupabaseClient.rpc('complete_beauty_onboarding',
            params: any(named: 'params'))).thenAnswer((_) => FakeRpcBuilder());
        when(() => mockQueryBuilder.select())
            .thenAnswer((_) => FakeUserProfileFilterBuilder(null));

        await callCompleteBeautyOnboarding();

        verify(() => mockSupabaseClient.rpc('complete_beauty_onboarding',
            params: any(named: 'params'))).called(1);
        final state = container!.read(userProfileNotifierProvider);
        expect(state.hasError, isFalse);
        expect(state.value, isNull);
      });

      test('does not fall back to RPC when the edge function succeeds', () async {
        when(() => mockFunctionsClient.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => FunctionResponse(status: 200, data: {'success': true}));
        when(() => mockQueryBuilder.select()).thenAnswer((_) =>
            FakeUserProfileFilterBuilder({
              'id': 'test_user_id',
              'onboarding_done': true,
              'is_creator': false,
              'created_at': '2026-07-21T00:00:00Z',
            }));

        await callCompleteBeautyOnboarding();

        verifyNever(() => mockSupabaseClient.rpc('complete_beauty_onboarding',
            params: any(named: 'params')));
        final state = container!.read(userProfileNotifierProvider);
        expect(state.hasError, isFalse);
        expect(state.value?.id, 'test_user_id');
      });
    });
  }
  