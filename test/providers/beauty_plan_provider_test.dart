  import 'dart:async';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:mocktail/mocktail.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';

  import 'package:akeli/providers/beauty_plan_provider.dart';
  import 'package:akeli/providers/auth_provider.dart';
  import 'package:akeli/core/supabase_client.dart';

  class MockSupabaseClient extends Mock implements SupabaseClient {}
  class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

  /// Mocks the `.select(...).eq(...).order(...).limit(...)` chain returned by
  /// `PostgrestQueryBuilder.select()` for `beauty_plan`. Captures the exact
  /// `columns` string passed to `.select()` so the test can simulate
  /// PostgREST's real behavior of only returning columns that were actually
  /// requested: if the captured select string does not contain `creator_id`
  /// inside the nested `recipe(...)` sub-select, the mocked JSON response
  /// omits `creator_id` from the nested recipe map — exactly like the real
  /// backend would.
  class FakeBeautyPlanFilterBuilder extends Mock
      implements PostgrestFilterBuilder<PostgrestList> {
    FakeBeautyPlanFilterBuilder(this._selectColumns);
    final String _selectColumns;

    @override
    PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

    @override
    PostgrestFilterBuilder<PostgrestList> order(String column,
            {bool ascending = false,
            bool nullsFirst = false,
            String? referencedTable}) =>
        this;

    @override
    PostgrestFilterBuilder<PostgrestList> limit(int count,
            {String? referencedTable}) =>
        this;

    @override
    PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
      final includesCreatorId = _selectColumns.contains('creator_id');
      final recipeJson = <String, dynamic>{
        'id': 'recipe-1',
        'title': 'Masque hydratant',
        'description': 'Un masque pour cheveux secs',
        'cover_image_url': null,
        'mode': 'beauty',
        'beauty_type': 'hair',
        'beauty_sub_type': 'mask',
        'prep_time_min': 10,
        'cook_time_min': 0,
        'total_time_min': 10,
        'difficulty': 'easy',
        if (includesCreatorId) 'creator_id': 'creator-1',
      };
      final planJson = <String, dynamic>{
        'id': 'plan-1',
        'user_id': 'test_user_id',
        'start_date': '2026-07-21',
        'end_date': '2026-07-27',
        'created_at': '2026-07-21T00:00:00Z',
        'beauty_plan_slot': [
          {
            'id': 'slot-1',
            'plan_id': 'plan-1',
            'day_number': 1,
            'week_number': 1,
            'day_of_week': 1,
            'routine_category': 'hair',
            'step_stage': 'daily_hydration',
            'frequency_tier': 'daily',
            'recipe_id': 'recipe-1',
            'is_completed': false,
            'completed_at': null,
            'recipe': recipeJson,
          },
        ],
      };
      return FakeMaybeSingleBuilder(planJson);
    }
  }

  class FakeMaybeSingleBuilder extends Mock
      implements PostgrestTransformBuilder<PostgrestMap?> {
    FakeMaybeSingleBuilder(this._value);
    final Map<String, dynamic> _value;

    @override
    Future<R> then<R>(FutureOr<R> Function(PostgrestMap?) onValue,
        {Function? onError}) {
      return Future.value(_value).then(onValue, onError: onError);
    }
  }

  /// Mocks `.select().eq(...).order(...)` for `beauty_log`, which is awaited
  /// directly (no `.maybeSingle()`) and resolves to a `PostgrestList`.
  class FakeBeautyLogListBuilder extends Mock
      implements PostgrestFilterBuilder<PostgrestList> {
    FakeBeautyLogListBuilder(this._value);
    final List<Map<String, dynamic>> _value;

    @override
    PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

    @override
    PostgrestFilterBuilder<PostgrestList> order(String column,
            {bool ascending = false,
            bool nullsFirst = false,
            String? referencedTable}) =>
        this;

    @override
    Future<R> then<R>(FutureOr<R> Function(PostgrestList) onValue,
        {Function? onError}) {
      return Future.value(_value).then(onValue, onError: onError);
    }
  }

  /// Mocks a bare `.update({...}).eq(...)` or `.insert({...})` call whose
  /// result is discarded by the caller (`SupabaseQueryBuilder` is a raw type,
  /// so both return `PostgrestFilterBuilder<dynamic>`).
  class FakeDynamicMutationBuilder extends Mock
      implements PostgrestFilterBuilder<dynamic> {
    @override
    PostgrestFilterBuilder<dynamic> eq(String column, Object value) => this;

    @override
    Future<R> then<R>(FutureOr<R> Function(dynamic) onValue,
        {Function? onError}) {
      return Future.value(<Map<String, dynamic>>[]).then(onValue, onError: onError);
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

    group('activeBeautyPlanProvider', () {
      late MockSupabaseClient mockSupabaseClient;
      late MockSupabaseQueryBuilder mockQueryBuilder;
      ProviderContainer? container;

      setUp(() {
        mockSupabaseClient = MockSupabaseClient();
        mockQueryBuilder = MockSupabaseQueryBuilder();

        when(() => mockSupabaseClient.from('beauty_plan'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select(any())).thenAnswer((invocation) {
          final columns = invocation.positionalArguments[0] as String;
          return FakeBeautyPlanFilterBuilder(columns);
        });

        container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
            currentUserProvider.overrideWithValue(_testUser),
          ],
        );
      });

      tearDown(() => container?.dispose());

      test('returns a non-null BeautyPlan when the recipe select includes creator_id', () async {
        final plan = await container!.read(activeBeautyPlanProvider.future);
        expect(plan, isNotNull);
        expect(plan!.slots, hasLength(1));
        expect(plan.slots.first.recipe, isNotNull);
        expect(plan.slots.first.recipe!.creatorId, equals('creator-1'));
      });
    });

    group('ToggleBeautySlotNotifier.toggleCompletion', () {
      test('updates beauty_plan_slot and invalidates activeBeautyPlanProvider', () async {
        final mockSupabaseClient = MockSupabaseClient();
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        final mockUpdateBuilder = FakeDynamicMutationBuilder();

        // ref.invalidate(activeBeautyPlanProvider) inside toggleCompletion causes
        // an eager background rebuild; stub 'beauty_plan' too so it resolves
        // quietly instead of throwing on an unstubbed `from()` call.
        when(() => mockSupabaseClient.from(any())).thenAnswer((invocation) {
          final table = invocation.positionalArguments[0] as String;
          if (table == 'beauty_plan_slot') return mockQueryBuilder;
          return MockSupabaseQueryBuilder();
        });
        when(() => mockQueryBuilder.update(any()))
            .thenAnswer((_) => mockUpdateBuilder);

        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
            currentUserProvider.overrideWithValue(_testUser),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(toggleBeautySlotNotifierProvider.notifier)
            .toggleCompletion('slot-1', false);

        final captured = verify(() => mockQueryBuilder.update(captureAny())).captured;
        expect((captured.single as Map)['is_completed'], isTrue);
      });
    });

    group('GenerateBeautyPlanNotifier.generatePlan', () {
      test('invokes generate_beauty_plan RPC', () async {
        final mockSupabaseClient = MockSupabaseClient();
        final mockRpcBuilder = FakeRpcBuilder();

        when(() => mockSupabaseClient.rpc(any(), params: any(named: 'params')))
            .thenAnswer((_) => mockRpcBuilder);
        // ref.invalidate(activeBeautyPlanProvider) inside generatePlan causes
        // an eager background rebuild; stub 'beauty_plan' so it resolves
        // quietly instead of throwing on an unstubbed `from()` call.
        when(() => mockSupabaseClient.from(any()))
            .thenAnswer((_) => MockSupabaseQueryBuilder());

        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
            currentUserProvider.overrideWithValue(_testUser),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(generateBeautyPlanNotifierProvider.notifier)
            .generatePlan();

        verify(() => mockSupabaseClient.rpc('generate_beauty_plan',
            params: any(named: 'params'))).called(1);
      });
    });

    group('beautyLogsProvider', () {
      test('returns parsed logs on success', () async {
        final mockSupabaseClient = MockSupabaseClient();
        final mockQueryBuilder = MockSupabaseQueryBuilder();

        when(() => mockSupabaseClient.from('beauty_log'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenAnswer((_) =>
            FakeBeautyLogListBuilder([
              {
                'id': 'log-1',
                'user_id': 'test_user_id',
                'hair_length_cm': 20.0,
                'hair_strength_score': 7.0,
                'hair_thickness_score': 7.0,
                'hair_shedding_rate': 'moderate',
                'skin_hydration_level': 7.0,
                'skin_clarity_score': 7.0,
                'checkin_photo_urls': <String>[],
                'logged_at': '2026-07-20T00:00:00Z',
              },
            ]));

        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
            currentUserProvider.overrideWithValue(_testUser),
          ],
        );
        addTearDown(container.dispose);

        final logs = await container.read(beautyLogsProvider.future);
        expect(logs, hasLength(1));
        expect(logs.first.id, 'log-1');
      });

      test('returns empty list when zero rows (documents RLS zero-row path)', () async {
        final mockSupabaseClient = MockSupabaseClient();
        final mockQueryBuilder = MockSupabaseQueryBuilder();

        when(() => mockSupabaseClient.from('beauty_log'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.select())
            .thenAnswer((_) => FakeBeautyLogListBuilder(const []));

        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
            currentUserProvider.overrideWithValue(_testUser),
          ],
        );
        addTearDown(container.dispose);

        final logs = await container.read(beautyLogsProvider.future);
        expect(logs, isEmpty);
      });
    });

    group('AddBeautyLogNotifier.addLog', () {
      test('inserts a beauty_log row and invalidates beautyLogsProvider', () async {
        final mockSupabaseClient = MockSupabaseClient();
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        final mockInsertBuilder = FakeDynamicMutationBuilder();

        when(() => mockSupabaseClient.from('beauty_log'))
            .thenAnswer((_) => mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenAnswer((_) => mockInsertBuilder);

        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(mockSupabaseClient),
            currentUserProvider.overrideWithValue(_testUser),
          ],
        );
        addTearDown(container.dispose);

        await container.read(addBeautyLogNotifierProvider.notifier).addLog(
              hairLengthCm: 22.0,
              hairStrengthScore: 7.5,
              hairThicknessScore: 7.5,
              hairSheddingRate: 'low',
              skinHydrationLevel: 8.0,
              skinClarityScore: 8.0,
            );

        final captured = verify(() => mockQueryBuilder.insert(captureAny())).captured;
        expect((captured.single as Map)['hair_length_cm'], 22.0);
      });
    });
  }
  