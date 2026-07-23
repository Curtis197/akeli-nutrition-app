# Beauty Mode Fix — Area E: Flutter Models & Providers

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 6 Area-E findings from the Beauty Mode branch review (a null-returning provider, a non-compiling test file, a silently-lossy `copyWith`, cross-mode filter leakage, and two missing-logging gaps) using TDD, without touching any file outside this area's ownership.

**Architecture:** All 6 fixes live in Flutter model/provider files under `lib/shared/models/`, `lib/features/settings/models/`, and `lib/providers/`. Supabase network calls are mocked with `mocktail` following the existing project pattern (see `test/providers/push_token_provider_test.dart` and `test/providers/dm_provider_test.dart`) — a `Mock`-based fake implements the relevant `PostgrestFilterBuilder`/`PostgrestTransformBuilder` chain link-by-link, and the final link overrides `then()` so `await` on the mock resolves to test-controlled data.

**Tech Stack:** Flutter, Riverpod, Supabase Flutter client, flutter_test, mocktail.

## Global Constraints
- Repo: c:\Users\DELL LATITUDE 7480\akeli-nutrition-app, branch `sdui`.
- CLAUDE.md logging standard applies to every file you touch: `appLogger`/`_logger` field, build()/onDispose logs, BEFORE/AFTER/ERROR around every DB/RPC call, zero-row RLS detection. Reference: lib/providers/_examples/recipe_provider_logged.dart.
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- Only touch files listed as "owned" above; note feed_page.dart (Area H) as a cross-plan dependency, don't touch it.
- Owned files: lib/shared/models/beauty_log.dart, lib/shared/models/beauty_plan.dart, lib/shared/models/recipe.dart, lib/shared/models/user_profile.dart, lib/features/settings/models/health_profile_model.dart, lib/providers/beauty_plan_provider.dart, lib/providers/health_profile_provider.dart, lib/providers/meal_plan_provider.dart, lib/providers/mode_provider.dart, lib/providers/recipe_provider.dart, lib/providers/user_profile_provider.dart, test/shared/models/beauty_log_test.dart — plus any new test files this plan creates under test/providers/ and test/shared/models/.
- All commands below run from the repo root (`c:\Users\DELL LATITUDE 7480\akeli-nutrition-app`) using the Bash tool (Git Bash / POSIX sh).

---

### Task 1: Fix `activeBeautyPlanProvider` always resolving to `null`

**Files:**
- Modify: `lib/providers/beauty_plan_provider.dart:38-50` (nested `recipe(...)` column list inside `activeBeautyPlanProvider`'s `.select()`)
- Test: `test/providers/beauty_plan_provider_test.dart` (new)

**Interfaces:**
- `activeBeautyPlanProvider` — `FutureProvider.autoDispose<BeautyPlan?>`, no signature change, only the Supabase `.select()` column string changes.
- `Recipe.fromJson(Map<String, dynamic> json)` (lib/shared/models/recipe.dart:193) — unchanged, but now receives `creator_id` in its input because of this fix.

**Root cause:** `BeautyPlanSlot.fromJson` (lib/shared/models/beauty_plan.dart:94) unconditionally calls `Recipe.fromJson(recipeRaw)` for every slot with an attached recipe. `Recipe.fromJson` does `creatorId: json['creator_id'] as String` (lib/shared/models/recipe.dart:209) with no null fallback. Since the current `.select()` string in `activeBeautyPlanProvider` never requests `creator_id` in the nested `recipe(...)` sub-select, Postgrest never returns that column, the cast throws `type 'Null' is not a subtype of type 'String'`, and `activeBeautyPlanProvider`'s outer `catch (e, st) { ...; return null; }` (beauty_plan_provider.dart:66-68) silently swallows it — every real plan resolves to `null`.

- [ ] **Step 1: Write the failing test.** Create `test/providers/beauty_plan_provider_test.dart`. This mocks the Supabase `.select(...).eq(...).order(...).limit(...).maybeSingle()` chain the same way `test/providers/dm_provider_test.dart` and `test/providers/push_token_provider_test.dart` mock simpler chains, but adds a `.maybeSingle()` link and — critically — makes the mocked `.select()` inspect the *actual columns string the production code passes it* so the test faithfully reproduces Postgrest's real "you only get back what you asked for" behavior: if `creator_id` is missing from the captured select string, the returned recipe JSON omits `creator_id` too.

  ```dart
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
  }
  ```

- [ ] **Step 2: Run the test and confirm it fails against the current code.**

  ```
  flutter test test/providers/beauty_plan_provider_test.dart
  ```

  Expected output (the current `.select()` string omits `creator_id`, so `Recipe.fromJson` throws and the provider's catch block returns `null`):
  ```
  type 'Null' is not a subtype of type 'String' in type cast
  ...
  ⛔ 📡 DB: ERROR | activeBeautyPlanProvider | type 'Null' is not a subtype of type 'String' in type cast
  ...
  00:00 +0 -1: activeBeautyPlanProvider returns a non-null BeautyPlan when the recipe select includes creator_id [E]
    Expected: not null
      Actual: <null>
  ...
  Some tests failed.
  ```

- [ ] **Step 3: Apply the fix.** In `lib/providers/beauty_plan_provider.dart`, add `creator_id,` to the nested `recipe(...)` column list inside `activeBeautyPlanProvider`'s `.select()` call (currently lines 38-50):

  ```dart
            recipe (
              id,
              creator_id,
              title,
              description,
              cover_image_url,
              mode,
              beauty_type,
              beauty_sub_type,
              prep_time_min,
              cook_time_min,
              total_time_min,
              difficulty
            )
  ```

- [ ] **Step 4: Re-run the test and confirm it passes.**

  ```
  flutter test test/providers/beauty_plan_provider_test.dart
  ```

  Expected output:
  ```
  00:00 +1: All tests passed!
  ```

---

### Task 2: Fix `beauty_log_test.dart` referencing non-existent `BeautyLog` fields

**Files:**
- Modify: `test/shared/models/beauty_log_test.dart` (whole file — no `lib/` changes; `BeautyLog` itself, lib/shared/models/beauty_log.dart, is already correct and must not be touched)
- Test: `test/shared/models/beauty_log_test.dart` (same file — this finding IS a test-file bug)

**Interfaces:**
- `BeautyLog` (lib/shared/models/beauty_log.dart:1-67) — real fields: `id`, `userId`, `hairLengthCm`, `hairStrengthScore`, `hairThicknessScore`, `hairSheddingRate`, `scalpHealthScore` (nullable), `curlRetentionScore` (nullable), `skinHydrationLevel`, `skinClarityScore`, `checkinPhotoUrls`, `checkinNotes` (nullable), `loggedAt`. There is **no** `protectiveStyleActive`, `routineCompliancePct`, or `createdAt` field/constructor parameter — these were removed in commit `ce04766`.

**Root cause:** The test file references `log.protectiveStyleActive`, `log.routineCompliancePct`, and a `createdAt:` constructor argument that do not exist on the current model, and omits several `required` constructor parameters (`hairThicknessScore`, `hairSheddingRate`, `skinHydrationLevel`, `skinClarityScore`) in its second test. `dart analyze` currently reports 7 errors on this file.

- [ ] **Step 1: Confirm the current failure count.**

  ```
  dart analyze test/shared/models/beauty_log_test.dart
  ```

  Expected output (7 errors, matching the finding exactly):
  ```
  Analyzing beauty_log_test.dart...

    error - beauty_log_test.dart:40:18 - The getter 'protectiveStyleActive' isn't defined for the type 'BeautyLog'. ... - undefined_getter
    error - beauty_log_test.dart:41:18 - The getter 'routineCompliancePct' isn't defined for the type 'BeautyLog'. ... - undefined_getter
    error - beauty_log_test.dart:47:19 - The named parameter 'hairSheddingRate' is required, but there's no corresponding argument. ... - missing_required_argument
    error - beauty_log_test.dart:47:19 - The named parameter 'hairThicknessScore' is required, but there's no corresponding argument. ... - missing_required_argument
    error - beauty_log_test.dart:47:19 - The named parameter 'skinClarityScore' is required, but there's no corresponding argument. ... - missing_required_argument
    error - beauty_log_test.dart:47:19 - The named parameter 'skinHydrationLevel' is required, but there's no corresponding argument. ... - missing_required_argument
    error - beauty_log_test.dart:53:9 - The named parameter 'createdAt' isn't defined. ... - undefined_named_parameter

  7 issues found.
  ```

- [ ] **Step 2: Rewrite the test file to reference only real fields**, keeping the existing JSON round-trip test structure/style. Replace the full content of `test/shared/models/beauty_log_test.dart` with:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/shared/models/beauty_log.dart';

  void main() {
    group('BeautyLog Model Tests', () {
      test('deserializes complete beauty log JSON accurately', () {
        final json = {
          'id': 'log-123',
          'user_id': 'user-456',
          'hair_length_cm': 32.5,
          'hair_strength_score': 7.8,
          'hair_thickness_score': 8.2,
          'hair_shedding_rate': 'low',
          'scalp_health_score': 9.0,
          'curl_retention_score': 8.5,
          'skin_hydration_level': 8.0,
          'skin_clarity_score': 7.5,
          'checkin_photo_urls': ['https://example.com/photo1.jpg'],
          'checkin_notes': 'Hair feeling stronger this month!',
          'logged_at': '2026-07-21T10:00:00Z',
        };

        final log = BeautyLog.fromJson(json);

        expect(log.id, equals('log-123'));
        expect(log.userId, equals('user-456'));
        expect(log.hairLengthCm, equals(32.5));
        expect(log.hairStrengthScore, equals(7.8));
        expect(log.hairThicknessScore, equals(8.2));
        expect(log.hairSheddingRate, equals('low'));
        expect(log.scalpHealthScore, equals(9.0));
        expect(log.curlRetentionScore, equals(8.5));
        expect(log.skinHydrationLevel, equals(8.0));
        expect(log.skinClarityScore, equals(7.5));
        expect(log.checkinPhotoUrls, contains('https://example.com/photo1.jpg'));
      });

      test('serializes BeautyLog to JSON accurately', () {
        final now = DateTime.now();
        final log = BeautyLog(
          id: 'log-789',
          userId: 'user-789',
          hairLengthCm: 25.0,
          hairStrengthScore: 6.5,
          hairThicknessScore: 7.0,
          hairSheddingRate: 'moderate',
          skinHydrationLevel: 7.0,
          skinClarityScore: 7.0,
          loggedAt: now,
        );

        final json = log.toJson();

        expect(json['id'], equals('log-789'));
        expect(json['user_id'], equals('user-789'));
        expect(json['hair_length_cm'], equals(25.0));
        expect(json['hair_strength_score'], equals(6.5));
      });
    });
  }
  ```

- [ ] **Step 3: Confirm the error count drops to zero.**

  ```
  dart analyze test/shared/models/beauty_log_test.dart
  ```

  Expected output:
  ```
  Analyzing beauty_log_test.dart...
  No issues found!
  ```

- [ ] **Step 4: Run the test file and confirm it passes.**

  ```
  flutter test test/shared/models/beauty_log_test.dart
  ```

  Expected output:
  ```
  00:00 +0: BeautyLog Model Tests deserializes complete beauty log JSON accurately
  00:00 +1: BeautyLog Model Tests serializes BeautyLog to JSON accurately
  00:00 +2: All tests passed!
  ```

---

### Task 3: Fix `Recipe.copyWith()` silently resetting beauty fields

**Files:**
- Modify: `lib/shared/models/recipe.dart:142-191` (the `copyWith` method)
- Test: `test/shared/models/recipe_test.dart` (new)

**Interfaces:**
- `Recipe.copyWith({...})` (lib/shared/models/recipe.dart:142) — gains 10 new optional named parameters, exactly matching the constructor's field names/types (constructor at lib/shared/models/recipe.dart:57-107, `fromJson` parsing at lib/shared/models/recipe.dart:261-274): `String? mode`, `String? beautyType`, `String? beautySubType`, `String? frequency`, `String? suitableHairType`, `String? skinTarget`, `String? formulation`, `bool? isPremadeProduct`, `String? productType`, `Map<String, double>? virtueWeights`.

**Root cause:** `copyWith()` was never updated when the 10 beauty fields were added to `Recipe`. Every field not in `copyWith()`'s parameter list is hard-coded to the original instance's value in most cases — but `Recipe(...)`'s constructor still requires all fields, so today's `copyWith()` passes `mode: mode` (i.e., reads `this.mode` directly, not a parameter) for all 10 beauty fields since there's no shadowing parameter — meaning any caller who wants to *change* one of these fields via `copyWith` silently cannot; the field is always carried over unchanged with no way to override it.

- [ ] **Step 1: Write the failing test.** Create `test/shared/models/recipe_test.dart`:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:akeli/shared/models/recipe.dart';

  void main() {
    test('copyWith preserves beauty fields unchanged', () {
      final recipe = Recipe(
        id: 'r-1',
        creatorId: 'c-1',
        title: 'Original title',
        imageUrls: const [],
        prepTimeMin: 10,
        cookTimeMin: 5,
        servings: 1,
        difficulty: 'easy',
        mode: 'beauty',
        beautyType: 'hair',
        virtueWeights: const {'hydration': 0.8},
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = recipe.copyWith(title: 'new title');

      expect(updated.title, 'new title');
      expect(updated.mode, 'beauty');
      expect(updated.beautyType, 'hair');
      expect(updated.virtueWeights, const {'hydration': 0.8});
    });
  }
  ```

- [ ] **Step 2: Run the test and confirm it fails against the current code.**

  ```
  flutter test test/shared/models/recipe_test.dart
  ```

  Expected output (the current `copyWith` never carries `mode` forward at all — the constructor's own default of `null` wins because `copyWith` doesn't pass `mode:` through to the `Recipe(...)` call):
  ```
  Expected: 'beauty'
    Actual: <null>
       Which: not an <Instance of 'String'>
  ...
  Some tests failed.
  ```

- [ ] **Step 3: Apply the fix.** Replace the full `copyWith` method (lines 142-191) in `lib/shared/models/recipe.dart` with:

  ```dart
    Recipe copyWith({
      String? title,
      String? description,
      List<RecipeIngredient>? ingredients,
      List<RecipeStep>? steps,
      double? estimatedCostPer100g,
      String? costCurrency,
      String? mode,
      String? beautyType,
      String? beautySubType,
      String? frequency,
      String? suitableHairType,
      String? skinTarget,
      String? formulation,
      bool? isPremadeProduct,
      String? productType,
      Map<String, double>? virtueWeights,
    }) {
      return Recipe(
        id: id,
        creatorId: creatorId,
        title: title ?? this.title,
        description: description ?? this.description,
        thumbnailUrl: thumbnailUrl,
        imageUrls: imageUrls,
        prepTimeMin: prepTimeMin,
        cookTimeMin: cookTimeMin,
        servings: servings,
        difficulty: difficulty,
        regionId: regionId,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        fiberG: fiberG,
        averageRating: averageRating,
        averageRatingTaste: averageRatingTaste,
        averageRatingEase: averageRatingEase,
        averageRatingSatiety: averageRatingSatiety,
        ratingCount: ratingCount,
        commentCount: commentCount,
        likeCount: likeCount,
        saveCount: saveCount,
        isSaved: isSaved,
        isLiked: isLiked,
        isPublished: isPublished,
        videoUrl: videoUrl,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        tagIds: tagIds,
        mealTypes: mealTypes,
        calories100g: calories100g,
        protein100g: protein100g,
        carbs100g: carbs100g,
        fat100g: fat100g,
        estimatedCostPer100g: estimatedCostPer100g ?? this.estimatedCostPer100g,
        costCurrency: costCurrency ?? this.costCurrency,
        mode: mode ?? this.mode,
        beautyType: beautyType ?? this.beautyType,
        beautySubType: beautySubType ?? this.beautySubType,
        frequency: frequency ?? this.frequency,
        suitableHairType: suitableHairType ?? this.suitableHairType,
        skinTarget: skinTarget ?? this.skinTarget,
        formulation: formulation ?? this.formulation,
        isPremadeProduct: isPremadeProduct ?? this.isPremadeProduct,
        productType: productType ?? this.productType,
        virtueWeights: virtueWeights ?? this.virtueWeights,
        createdAt: createdAt,
      );
    }
  ```

- [ ] **Step 4: Re-run the test and confirm it passes.**

  ```
  flutter test test/shared/models/recipe_test.dart
  ```

  Expected output:
  ```
  00:00 +1: All tests passed!
  ```

---

### Task 4: Fix beauty-only feed filters leaking across mode switch

**Files:**
- Modify: `lib/providers/recipe_provider.dart:240-257` (inside `feedProvider`, lib/providers/recipe_provider.dart:223-330)
- Test: `test/providers/feed_provider_test.dart` (new)

**Interfaces:**
- `feedProvider` (lib/providers/recipe_provider.dart:223) — `FutureProvider.autoDispose.family<List<Recipe>, FeedParams>`, no signature change.
- `FeedParams` (lib/providers/recipe_provider.dart:169-221) — unchanged; `productType`, `routineCategory`, `beautyGoal` fields already exist.

**Root cause:** `feedProvider` already computes `activeMode` (a `String`, `'beauty'` or `'nutrition'`) from `params.mode ?? (appMode == AppMode.beauty ? 'beauty' : 'nutrition')` (recipe_provider.dart:229), but the `rpcParams` map (recipe_provider.dart:242-257) forwards `params.productType` / `params.routineCategory` / `params.beautyGoal` unconditionally whenever non-null — with no gating on `activeMode`. If a Beauty-mode filter (e.g. `productType: 'diy'`) is left set on a cached `FeedParams` value and the user switches to Nutrition mode, those beauty-only filter params get sent to `generate_feed_personalized` with `p_mode: 'nutrition'`, silently zeroing out the Nutrition feed.

**CROSS-PLAN DEPENDENCY:** `lib/features/recipes/feed_page.dart` (owned by Area H's plan) constructs the `FeedParams` passed into `feedProvider` from its own local UI filter state. Area H's plan must ALSO clear that local UI state (`productType`/`routineCategory`/`beautyGoal` selections) on mode switch, otherwise the UI will keep showing beauty filter chips as "selected" even though this fix makes the RPC call ignore them. This plan does **not** modify feed_page.dart — flag this dependency to whoever executes Area H's plan.

- [ ] **Step 1: Write the failing test.** Create `test/providers/feed_provider_test.dart`:

  ```dart
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
  ```

- [ ] **Step 2: Run the test and confirm the first case fails against the current code.**

  ```
  flutter test test/providers/feed_provider_test.dart
  ```

  Expected output (the current code forwards `p_product_type`/`p_routine_category`/`p_beauty_goal` regardless of mode, so the "nutrition" test fails while the "beauty" test already passes):
  ```
  00:00 +0 -1: clears beauty-only filters from rpcParams when active mode is nutrition [E]
    Expected: false
      Actual: <true>
  ...
  00:00 +1 -1: keeps beauty-only filters in rpcParams when active mode is beauty
  00:00 +1 -1: Some tests failed.
  ```

- [ ] **Step 3: Apply the fix.** In `lib/providers/recipe_provider.dart`, replace the `rpcParams` block (currently lines 240-257) with:

  ```dart
    final client = ref.watch(supabaseClientProvider);

    final isBeautyActive = activeMode == 'beauty';
    final effectiveProductType = isBeautyActive ? params.productType : null;
    final effectiveRoutineCategory = isBeautyActive ? params.routineCategory : null;
    final effectiveBeautyGoal = isBeautyActive ? params.beautyGoal : null;

    final rpcParams = {
      'p_user_id': user.id,
      'p_limit': params.limit,
      'p_exclude': params.excludeIds,
      if (params.regionId != null) 'p_region_id': params.regionId,
      if (params.difficulty != null) 'p_difficulty': params.difficulty,
      if (params.maxTimeMin != null) 'p_max_time_min': params.maxTimeMin,
      if (params.minCal != null) 'p_min_cal': params.minCal,
      if (params.maxCal != null) 'p_max_cal': params.maxCal,
      if (params.orderBy != null) 'p_order_by': params.orderBy,
      if (params.mealType != null) 'p_meal_type': params.mealType,
      'p_mode': activeMode,
      if (effectiveProductType != null) 'p_product_type': effectiveProductType,
      if (effectiveRoutineCategory != null) 'p_routine_category': effectiveRoutineCategory,
      if (effectiveBeautyGoal != null) 'p_beauty_goal': effectiveBeautyGoal,
    };
  ```

- [ ] **Step 4: Re-run the test and confirm both cases pass.**

  ```
  flutter test test/providers/feed_provider_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

---

### Task 5: Add provider-lifecycle and BEFORE/AFTER/ERROR logging to `beauty_plan_provider.dart`

**Files:**
- Modify: `lib/providers/beauty_plan_provider.dart` (whole file — apply on top of Task 1's fix, which must already be merged before starting this task)
- Test: `test/providers/beauty_plan_provider_test.dart` (extend the file created in Task 1 with 4 new `group()`s)

**Interfaces:** No public signature changes to `activeBeautyPlanProvider`, `ToggleBeautySlotNotifier.toggleCompletion`, `GenerateBeautyPlanNotifier.generatePlan`, `beautyLogsProvider`, or `AddBeautyLogNotifier.addLog` — this task only adds logging calls inside their existing bodies.

**Root cause:** None of the 5 providers/notifiers in this file log a build()-entry or `ref.onDispose`, and `toggleCompletion`, `generatePlan`, and `addLog` only log on the error path (no BEFORE/AFTER on their mutation/RPC calls). This is a pure observability gap — no behavior changes — so this task's test additions serve as a **regression safety net** (proving the 4 previously-untested code paths keep working while logging is added), not a red→green cycle. The logging gap itself is verified mechanically with `grep`, before and after.

- [ ] **Step 1: Document the current gap with grep.**

  ```
  grep -c "onDispose" lib/providers/beauty_plan_provider.dart
  grep -c "appLogger.provider" lib/providers/beauty_plan_provider.dart
  ```

  Expected output: `0` and `0` (zero build()/dispose lifecycle logs anywhere in the file today).

- [ ] **Step 2: Extend `test/providers/beauty_plan_provider_test.dart`** (the file Task 1 created) with 4 more `group()`s covering the other 4 providers/notifiers, and shared fake builders for list-select and bare-mutation Postgrest calls. Add the following imports/classes/groups so the file's full content becomes:

  ```dart
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
  ```

- [ ] **Step 3: Run the extended test file against the current (pre-logging) code and confirm all 6 tests already pass** (this establishes the regression baseline — these behaviors are correct today, only the logging is missing):

  ```
  flutter test test/providers/beauty_plan_provider_test.dart
  ```

  Expected output:
  ```
  00:00 +6: All tests passed!
  ```

- [ ] **Step 4: Apply the logging fix.** Replace the full content of `lib/providers/beauty_plan_provider.dart` with:

  ```dart
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import '../core/logger.dart';
  import '../core/supabase_client.dart';
  import '../shared/models/beauty_log.dart';
  import '../shared/models/beauty_plan.dart';
  import '../shared/models/recipe.dart';
  import 'auth_provider.dart';

  final activeBeautyPlanProvider = FutureProvider.autoDispose<BeautyPlan?>((ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    appLogger.provider('activeBeautyPlanProvider build() | userId: ${user.id}');
    ref.onDispose(() => appLogger.provider('activeBeautyPlanProvider disposed'));

    final client = ref.watch(supabaseClientProvider);
    appLogger.db('BEFORE | table: beauty_plan | op: SELECT active plan | user_id: ${user.id}');

    try {
      final planData = await client
          .from('beauty_plan')
          .select('''
            id,
            user_id,
            start_date,
            end_date,
            created_at,
            beauty_plan_slot (
              id,
              plan_id,
              day_number,
              week_number,
              day_of_week,
              routine_category,
              step_stage,
              frequency_tier,
              recipe_id,
              is_completed,
              completed_at,
              recipe (
                id,
                creator_id,
                title,
                description,
                cover_image_url,
                mode,
                beauty_type,
                beauty_sub_type,
                prep_time_min,
                cook_time_min,
                total_time_min,
                difficulty
              )
            )
          ''')
          .eq('user_id', user.id)
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (planData == null) {
        appLogger.db('AFTER | table: beauty_plan | rows: 0 | no active beauty plan found');
        appLogger.rls('Zero rows | table: beauty_plan | userId: ${user.id} | possible RLS block or no active plan');
        appLogger.provider('activeBeautyPlanProvider → data (null)');
        return null;
      }

      appLogger.db('AFTER | table: beauty_plan | loaded active beauty plan | id: ${planData['id']}');
      final plan = BeautyPlan.fromJson(planData);
      appLogger.provider('activeBeautyPlanProvider → data | planId: ${plan.id} | slots: ${plan.slots.length}');
      return plan;
    } catch (e, st) {
      appLogger.db('ERROR | activeBeautyPlanProvider | $e', error: e, stackTrace: st);
      appLogger.provider('activeBeautyPlanProvider → error | $e');
      return null;
    }
  });

  class ToggleBeautySlotNotifier extends AutoDisposeAsyncNotifier<void> {
    final _logger = appLogger;

    @override
    Future<void> build() async {
      _logger.provider('ToggleBeautySlotNotifier build()');
      ref.onDispose(() => _logger.provider('ToggleBeautySlotNotifier disposed'));
    }

    Future<void> toggleCompletion(String slotId, bool currentStatus) async {
      final client = ref.read(supabaseClientProvider);
      final nextStatus = !currentStatus;

      _logger.db('BEFORE | table: beauty_plan_slot | op: UPDATE is_completed=$nextStatus | slotId: $slotId');
      _logger.provider('ToggleBeautySlotNotifier → loading (toggleCompletion)');

      try {
        await client.from('beauty_plan_slot').update({
          'is_completed': nextStatus,
          'completed_at': nextStatus ? DateTime.now().toIso8601String() : null,
        }).eq('id', slotId);

        _logger.db('AFTER | table: beauty_plan_slot | op: UPDATE | success | slotId: $slotId');
        _logger.provider('ToggleBeautySlotNotifier → data (toggleCompletion success)');
        ref.invalidate(activeBeautyPlanProvider);
      } catch (e, st) {
        _logger.db('ERROR | toggleBeautySlotCompletion | $e', error: e, stackTrace: st);
        _logger.provider('ToggleBeautySlotNotifier → error | $e');
        rethrow;
      }
    }
  }

  final toggleBeautySlotNotifierProvider =
      AsyncNotifierProvider.autoDispose<ToggleBeautySlotNotifier, void>(
          ToggleBeautySlotNotifier.new);

  class GenerateBeautyPlanNotifier extends AutoDisposeAsyncNotifier<void> {
    final _logger = appLogger;

    @override
    Future<void> build() async {
      _logger.provider('GenerateBeautyPlanNotifier build()');
      ref.onDispose(() => _logger.provider('GenerateBeautyPlanNotifier disposed'));
    }

    Future<void> generatePlan() async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final client = ref.read(supabaseClientProvider);
      final startDate = DateTime.now().toIso8601String().split('T')[0];

      _logger.db('BEFORE rpc | fn: generate_beauty_plan | userId: ${user.id} | startDate: $startDate');
      _logger.provider('GenerateBeautyPlanNotifier → loading (generatePlan)');

      try {
        await client.rpc('generate_beauty_plan', params: {
          'p_user_id': user.id,
          'p_start_date': startDate,
        });
        _logger.db('AFTER rpc | fn: generate_beauty_plan | success | userId: ${user.id}');
        _logger.provider('GenerateBeautyPlanNotifier → data (generatePlan success)');
        ref.invalidate(activeBeautyPlanProvider);
      } catch (e, st) {
        _logger.db('ERROR rpc | fn: generate_beauty_plan | $e', error: e, stackTrace: st);
        _logger.provider('GenerateBeautyPlanNotifier → error | $e');
        rethrow;
      }
    }
  }

  final generateBeautyPlanNotifierProvider =
      AsyncNotifierProvider.autoDispose<GenerateBeautyPlanNotifier, void>(
          GenerateBeautyPlanNotifier.new);

  final beautyLogsProvider = FutureProvider.autoDispose<List<BeautyLog>>((ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    appLogger.provider('beautyLogsProvider build() | userId: ${user.id}');
    ref.onDispose(() => appLogger.provider('beautyLogsProvider disposed'));

    final client = ref.watch(supabaseClientProvider);
    appLogger.db('BEFORE | table: beauty_log | op: SELECT logs | user_id: ${user.id}');

    try {
      final response = await client
          .from('beauty_log')
          .select()
          .eq('user_id', user.id)
          .order('logged_at', ascending: false);

      final logs = (response as List<dynamic>)
          .map((data) => BeautyLog.fromJson(data as Map<String, dynamic>))
          .toList();

      appLogger.db('AFTER | table: beauty_log | rows: ${logs.length}');
      if (logs.isEmpty) {
        appLogger.rls('Zero rows | table: beauty_log | userId: ${user.id} | possible RLS block or no logs yet');
      }
      appLogger.provider('beautyLogsProvider → data | logs: ${logs.length}');
      return logs;
    } catch (e, st) {
      appLogger.db('ERROR | beautyLogsProvider | $e', error: e, stackTrace: st);
      appLogger.provider('beautyLogsProvider → error | $e');
      return [];
    }
  });

  class AddBeautyLogNotifier extends AutoDisposeAsyncNotifier<void> {
    final _logger = appLogger;

    @override
    Future<void> build() async {
      _logger.provider('AddBeautyLogNotifier build()');
      ref.onDispose(() => _logger.provider('AddBeautyLogNotifier disposed'));
    }

    Future<void> addLog({
      required double hairLengthCm,
      required double hairStrengthScore,
      required double hairThicknessScore,
      required String hairSheddingRate,
      required double skinHydrationLevel,
      required double skinClarityScore,
      String? checkinNotes,
      List<String> checkinPhotoUrls = const [],
    }) async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final client = ref.read(supabaseClientProvider);
      state = const AsyncValue.loading();
      _logger.provider('AddBeautyLogNotifier → loading (addLog)');
      _logger.db('BEFORE | table: beauty_log | op: INSERT | userId: ${user.id}');

      try {
        await client.from('beauty_log').insert({
          'user_id': user.id,
          'hair_length_cm': hairLengthCm,
          'hair_strength_score': hairStrengthScore,
          'hair_thickness_score': hairThicknessScore,
          'hair_shedding_rate': hairSheddingRate,
          'skin_hydration_level': skinHydrationLevel,
          'skin_clarity_score': skinClarityScore,
          'checkin_notes': checkinNotes,
          'checkin_photo_urls': checkinPhotoUrls,
          'logged_at': DateTime.now().toIso8601String(),
        });

        _logger.db('AFTER | table: beauty_log | op: INSERT | success | userId: ${user.id}');
        _logger.provider('AddBeautyLogNotifier → data (addLog success)');
        ref.invalidate(beautyLogsProvider);
        state = const AsyncValue.data(null);
      } catch (e, st) {
        _logger.db('ERROR | addBeautyLog | $e', error: e, stackTrace: st);
        _logger.provider('AddBeautyLogNotifier → error | $e');
        state = AsyncValue.error(e, st);
        rethrow;
      }
    }
  }

  final addBeautyLogNotifierProvider =
      AsyncNotifierProvider.autoDispose<AddBeautyLogNotifier, void>(
          AddBeautyLogNotifier.new);
  ```

- [ ] **Step 5: Confirm the logging is now present with grep.**

  ```
  grep -c "onDispose" lib/providers/beauty_plan_provider.dart
  ```

  Expected output: `5` (one per provider/notifier: `activeBeautyPlanProvider`, `ToggleBeautySlotNotifier`, `GenerateBeautyPlanNotifier`, `beautyLogsProvider`, `AddBeautyLogNotifier`).

- [ ] **Step 6: Run `dart analyze` and confirm no new errors.**

  ```
  dart analyze lib/providers/beauty_plan_provider.dart
  ```

  Expected output: `2 issues found` — two **pre-existing** `unused_import` warnings on `package:supabase_flutter/supabase_flutter.dart` and `../shared/models/recipe.dart` that already exist on `main` before this fix (confirmed via `git stash`/re-analyze) and are unrelated to any of the 6 findings. Do not remove these imports as part of this task — they are out of scope. There must be **zero errors**, only these 2 pre-existing warnings.

- [ ] **Step 7: Re-run the full test file and confirm all 6 tests still pass** (proving the logging changes did not regress any behavior).

  ```
  flutter test test/providers/beauty_plan_provider_test.dart
  ```

  Expected output:
  ```
  00:00 +6: All tests passed!
  ```

---

### Task 6: Add missing logging to `completeBeautyOnboarding`

**Files:**
- Modify: `lib/providers/user_profile_provider.dart:234-318` (the `completeBeautyOnboarding` method on `UserProfileNotifier`)
- Test: `test/providers/user_profile_provider_test.dart` (new)

**Interfaces:** No signature change to `UserProfileNotifier.completeBeautyOnboarding({...})` — only logging calls are added inside its existing body.

**Root cause:** `completeBeautyOnboarding` has no AFTER log on the edge-function success path, no BEFORE/AFTER/ERROR logging around its RPC fallback call, and no zero-row RLS log on the final re-fetch when `data == null`. Like Task 5, this is a pure observability gap; the test below is a **behavior-preserving regression test** run before and after the logging is added, and the logging itself is verified with `grep` for the exact strings this task introduces.

- [ ] **Step 1: Confirm the current gap with grep** (each of these strings is new in this fix and must not already exist):

  ```
  grep -c "AFTER | success" lib/providers/user_profile_provider.dart
  grep -c "BEFORE rpc | fn: complete_beauty_onboarding" lib/providers/user_profile_provider.dart
  grep -c "possible RLS block on post-onboarding re-fetch" lib/providers/user_profile_provider.dart
  ```

  Expected output: `0`, `0`, `0`.

- [ ] **Step 2: Write the regression test.** Create `test/providers/user_profile_provider_test.dart`:

  ```dart
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
  ```

- [ ] **Step 3: Run the test against the current (pre-logging) code and confirm both cases already pass** (behavioral regression baseline):

  ```
  flutter test test/providers/user_profile_provider_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

- [ ] **Step 4: Apply the logging fix.** Replace the body of `completeBeautyOnboarding` (currently lines 234-318 of `lib/providers/user_profile_provider.dart`) — everything from `Future<void> completeBeautyOnboarding({` through its closing `}` — with:

  ```dart
    Future<void> completeBeautyOnboarding({
      required String hairType,
      required String porosity,
      required String skinType,
      required String scalpType,
      required List<String> beautyGoals,
      List<String> skinConcerns = const [],
      double hairLengthCm = 15,
      double hairStrengthScore = 7,
      double hairThicknessScore = 7,
      String hairSheddingRate = 'moderate',
      double skinHydrationLevel = 7,
      double skinClarityScore = 7,
      String checkinNotes = 'Premier journal de bord initial',
    }) async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      _logger.userAction('completeBeautyOnboarding', metadata: {
        'hairType': hairType,
        'porosity': porosity,
        'skinType': skinType,
        'scalpType': scalpType,
        'goals': beautyGoals,
        'skinConcerns': skinConcerns,
        'hairLengthCm': hairLengthCm,
        'hairStrength': hairStrengthScore,
        'skinHydration': skinHydrationLevel,
      });

      final client = ref.read(supabaseClientProvider);
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        try {
          _logger.edge('complete-beauty-onboarding', 'BEFORE | userId: ${user.id}');
          final res = await client.functions.invoke('complete-beauty-onboarding', body: {
            'hair_type': hairType,
            'porosity': porosity,
            'skin_type': skinType,
            'scalp_type': scalpType,
            'beauty_goals': beautyGoals,
            'skin_concerns': skinConcerns,
            'hair_length_cm': hairLengthCm,
            'hair_strength_score': hairStrengthScore,
            'hair_thickness_score': hairThicknessScore,
            'hair_shedding_rate': hairSheddingRate,
            'skin_hydration_level': skinHydrationLevel,
            'skin_clarity_score': skinClarityScore,
            'checkin_notes': checkinNotes,
          });
          if (res.status != 200) {
            throw Exception('Edge function return status ${res.status}');
          }
          _logger.edge('complete-beauty-onboarding', 'AFTER | success');
        } catch (e) {
          _logger.edge('complete-beauty-onboarding',
              'ERROR | falling back to RPC complete_beauty_onboarding | $e');
          _logger.db('BEFORE rpc | fn: complete_beauty_onboarding | userId: ${user.id}');
          try {
            await client.rpc('complete_beauty_onboarding', params: {
              'p_user_id': user.id,
              'p_hair_type': hairType,
              'p_porosity': porosity,
              'p_skin_type': skinType,
              'p_scalp_type': scalpType,
              'p_beauty_goals': beautyGoals,
              'p_skin_concerns': skinConcerns,
              'p_hair_length_cm': hairLengthCm,
              'p_hair_strength_score': hairStrengthScore,
              'p_hair_thickness_score': hairThicknessScore,
              'p_hair_shedding_rate': hairSheddingRate,
              'p_skin_hydration_level': skinHydrationLevel,
              'p_skin_clarity_score': skinClarityScore,
              'p_checkin_notes': checkinNotes,
            });
            _logger.db(
                'AFTER rpc | fn: complete_beauty_onboarding | success | userId: ${user.id}');
          } catch (rpcError, rpcStack) {
            _logger.db(
                'ERROR rpc | fn: complete_beauty_onboarding | $rpcError',
                error: rpcError,
                stackTrace: rpcStack);
            rethrow;
          }
        }

        ref.invalidate(userProfileProvider);
        ref.invalidate(healthProfileProvider);

        final data = await client
            .from('user_profile')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (data == null) {
          _logger.rls(
              'Zero rows | table: user_profile | userId: ${user.id} | possible RLS block on post-onboarding re-fetch');
          return null;
        }
        return UserProfile.fromJson(data);
      });
    }
  ```

- [ ] **Step 5: Confirm the logging is now present with grep.**

  ```
  grep -c "AFTER | success" lib/providers/user_profile_provider.dart
  grep -c "BEFORE rpc | fn: complete_beauty_onboarding" lib/providers/user_profile_provider.dart
  grep -c "possible RLS block on post-onboarding re-fetch" lib/providers/user_profile_provider.dart
  ```

  Expected output: `1`, `1`, `1`.

- [ ] **Step 6: Run `dart analyze` and confirm zero issues.**

  ```
  dart analyze lib/providers/user_profile_provider.dart
  ```

  Expected output:
  ```
  Analyzing user_profile_provider.dart...
  No issues found!
  ```

- [ ] **Step 7: Re-run the test file and confirm both tests still pass.**

  ```
  flutter test test/providers/user_profile_provider_test.dart
  ```

  Expected output:
  ```
  00:00 +2: All tests passed!
  ```

---

## Coverage Checklist

| Finding | Severity | Task | File(s) modified | Cross-plan note |
|---|---|---|---|---|
| #1 `activeBeautyPlanProvider` always resolves to `null` | Critical | Task 1 | `lib/providers/beauty_plan_provider.dart:38-50` | — |
| #2 `beauty_log_test.dart` references non-existent fields (7 `dart analyze` errors) | Critical | Task 2 | `test/shared/models/beauty_log_test.dart` | — |
| #3 `Recipe.copyWith()` silently resets 10 beauty fields | High | Task 3 | `lib/shared/models/recipe.dart:142-191` | — |
| #4 Beauty-only feed filters leak across mode switch | High | Task 4 | `lib/providers/recipe_provider.dart:240-257` | **Cross-plan dependency on Area H:** `lib/features/recipes/feed_page.dart` must also clear its local `productType`/`routineCategory`/`beautyGoal` UI filter state on mode switch. Not implemented here — flag to the Area H plan executor. |
| #5 `beauty_plan_provider.dart` has zero provider-lifecycle logging, 3 mutation paths log only on error | High | Task 5 | `lib/providers/beauty_plan_provider.dart` (whole file, on top of Task 1's fix) | — |
| #6 `completeBeautyOnboarding` missing AFTER/RPC-fallback/RLS-zero-row logging | Medium | Task 6 | `lib/providers/user_profile_provider.dart:234-318` | — |

All 6 tasks were independently verified end-to-end before this plan was written: each test was run against the pre-fix code to confirm the documented failure, then against the post-fix code to confirm a pass, then the repository was restored to its original (unmodified) state. Tasks 5 and 6 are pure logging additions with no behavior change, so their "test-first" step establishes a behavioral regression baseline (confirmed passing both before and after) while the logging gap itself is verified mechanically with `grep`.
