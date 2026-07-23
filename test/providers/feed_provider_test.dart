import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:akeli/providers/recipe_provider.dart';
import 'package:akeli/providers/auth_provider.dart';
import 'package:akeli/providers/mode_provider.dart';
import 'package:akeli/core/supabase_client.dart';
import 'package:akeli/core/locale_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mocks `client.rpc(...)`, awaited directly and resolving to an empty list
/// so `feedProvider` takes its early `rpcData.isEmpty` return — this test
/// only cares about the `params` map built before the RPC call, not the
/// recipe-hydration logic that follows a non-empty result.
class FakeRpcListBuilder extends Mock implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic) onValue, {Function? onError}) {
    return Future.value(<dynamic>[]).then(onValue, onError: onError);
  }
}

class FakeNutritionModeNotifier extends ModeNotifier {
  @override
  AppMode build() => AppMode.nutrition;
}

class FakeBeautyModeNotifier extends ModeNotifier {
  @override
  AppMode build() => AppMode.beauty;
}

class FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('fr');
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

  test('clears beauty-only filters from rpcParams when active mode is nutrition', () async {
    final mockSupabaseClient = MockSupabaseClient();
    Map<String, dynamic>? captured;

    when(() => mockSupabaseClient.rpc(any(), params: any(named: 'params')))
        .thenAnswer((invocation) {
      captured = (invocation.namedArguments[#params] as Map).cast<String, dynamic>();
      return FakeRpcListBuilder();
    });

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabaseClient),
        currentUserProvider.overrideWithValue(_testUser),
        currentModeProvider.overrideWith(FakeNutritionModeNotifier.new),
        localeProvider.overrideWith(FakeLocaleNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(feedProvider(const FeedParams(
      productType: 'diy',
      routineCategory: 'hair',
      beautyGoal: 'hair_growth',
    )).future);

    expect(result, isEmpty);
    expect(captured, isNotNull);
    expect(captured!.containsKey('p_product_type'), isFalse);
    expect(captured!.containsKey('p_routine_category'), isFalse);
    expect(captured!.containsKey('p_beauty_goal'), isFalse);
  });

  test('keeps beauty-only filters in rpcParams when active mode is beauty', () async {
    final mockSupabaseClient = MockSupabaseClient();
    Map<String, dynamic>? captured;

    when(() => mockSupabaseClient.rpc(any(), params: any(named: 'params')))
        .thenAnswer((invocation) {
      captured = (invocation.namedArguments[#params] as Map).cast<String, dynamic>();
      return FakeRpcListBuilder();
    });

    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabaseClient),
        currentUserProvider.overrideWithValue(_testUser),
        currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
        localeProvider.overrideWith(FakeLocaleNotifier.new),
      ],
    );
    addTearDown(container.dispose);

    await container.read(feedProvider(const FeedParams(
      productType: 'diy',
      routineCategory: 'hair',
      beautyGoal: 'hair_growth',
    )).future);

    expect(captured, isNotNull);
    expect(captured!['p_product_type'], 'diy');
    expect(captured!['p_routine_category'], 'hair');
    expect(captured!['p_beauty_goal'], 'hair_growth');
  });
}
