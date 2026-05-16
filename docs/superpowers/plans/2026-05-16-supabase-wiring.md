# Supabase Incremental Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all 6 mock providers with real Supabase queries against the local instance at `http://127.0.0.1:54321`, one provider file at a time, with `flutter analyze` passing after every task.

**Architecture:** Single `supabaseClientProvider` (`Provider<SupabaseClient>`) in `lib/core/supabase_client.dart`. Every domain provider reads the client via `ref.watch(supabaseClientProvider)` and calls queries directly — no repository layer. No UI files are touched.

**Tech Stack:** Flutter, Riverpod 2.x, supabase_flutter ^2.8.0, local Supabase (Docker, project `akeli_landing_page`)

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/core/supabase_client.dart` | Local credentials + `supabaseClientProvider` |
| Modify | `pubspec.yaml` | Add `supabase_flutter: ^2.8.0` |
| Modify | `lib/main.dart` | Call `Supabase.initialize()` before `runApp()` |
| Rewrite | `lib/providers/auth_provider.dart` | Real Supabase Auth — stream-driven |
| Rewrite | `lib/providers/user_profile_provider.dart` | `user_profile` + `user_health_profile` + `subscription` tables |
| Rewrite | `lib/providers/recipe_provider.dart` | `recipe` table + `get_personalized_feed` RPC + `toggle-recipe-like` Edge Fn |
| Rewrite | `lib/providers/nutrition_provider.dart` | `daily_nutrition_log` + `weight_log` tables |
| Rewrite | `lib/providers/meal_plan_provider.dart` | `meal_plan` + `meal_plan_entry` tables + Edge Fns |
| Rewrite | `lib/providers/fan_mode_provider.dart` | `fan_subscription` + `creator` tables + Edge Fns |
| Modify | `lib/shared/models/meal_plan.dart` | Fix `fromJson` key mismatches vs actual DB schema |
| Modify | `lib/shared/models/creator.dart` | Remove `isFanEligible` DB dependency |

---

## Task 1: Infrastructure — add supabase_flutter, client provider, initialize

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/supabase_client.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add `supabase_flutter` to pubspec.yaml**

Open `pubspec.yaml`. Under the `dependencies:` section, add the line below. Place it after `go_router`:

```yaml
  # Supabase — local dev instance
  supabase_flutter: ^2.8.0
```

- [ ] **Step 2: Fetch the new dependency**

```powershell
flutter pub get
```

Expected: `Got dependencies!` — no errors.

- [ ] **Step 3: Create `lib/core/supabase_client.dart`**

Create this file with the following content:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'http://127.0.0.1:54321';
const _supabaseAnonKey =
    'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
}

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
```

- [ ] **Step 4: Update `lib/main.dart` to call `initializeSupabase()` before `runApp()`**

The current `main()` in `lib/main.dart` is:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: AkeliApp(),
    ),
  );
}
```

Replace it with:

```dart
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();

  runApp(
    const ProviderScope(
      child: AkeliApp(),
    ),
  );
}
```

The full import block at the top of `lib/main.dart` should be:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
```

- [ ] **Step 5: Verify**

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```powershell
git add pubspec.yaml pubspec.lock lib/core/supabase_client.dart lib/main.dart
git commit -m "feat: add supabase_flutter and initialize local client"
```

---

## Task 2: Auth — replace MockUser with real Supabase Auth

**Files:**
- Rewrite: `lib/providers/auth_provider.dart`

**Background:** The current file defines `MockUser` and a `StateProvider<MockUser?>` that always starts logged-in. We replace this with a `StreamProvider` on `supabase.auth.onAuthStateChange`. The app will now start **logged-out** — the router guard redirects to login on cold start.

The provider names and signatures that the rest of the app uses must stay identical:
- `currentUserProvider` → `Provider<User?>` (now returns a Supabase `User`, not `MockUser`)
- `isAuthenticatedProvider` → `Provider<bool>`
- `authNotifierProvider` → `AsyncNotifierProvider<AuthNotifier, void>`

- [ ] **Step 1: Rewrite `lib/providers/auth_provider.dart`**

Replace the entire file contents with:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

// ---------------------------------------------------------------------------
// Auth stream — single source of truth
// ---------------------------------------------------------------------------

final authStreamProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStreamProvider).value?.session?.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ---------------------------------------------------------------------------
// Auth notifier — sign-up, sign-in, sign-out, reset password
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) throw Exception('Sign-up returned no user');
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signOut() async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.signOut();
    });
  }

  Future<void> resetPassword(String email) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.auth.resetPasswordForEmail(email);
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
```

- [ ] **Step 2: Verify**

```powershell
flutter analyze
```

Expected: `No issues found!`

If you see errors about `MockUser` still referenced elsewhere, search for it:

```powershell
grep -r "MockUser" lib/
```

Any file referencing `MockUser` must be updated to use `User` from `supabase_flutter` instead.

- [ ] **Step 3: Commit**

```powershell
git add lib/providers/auth_provider.dart
git commit -m "feat(auth): wire Supabase Auth replacing MockUser"
```

---

## Task 3: User Profile — wire `user_profile`, `user_health_profile`, `subscription`

**Files:**
- Rewrite: `lib/providers/user_profile_provider.dart`

**Schema notes (verified against local DB):**
- `user_profile` columns: `id`, `username`, `first_name`, `last_name`, `avatar_url`, `locale`, `is_creator`, `onboarding_done`, `created_at`. No `email`, `bio`, or `role` column — `UserProfile.fromJson` handles missing keys safely via `?? default` fallbacks already in place.
- `user_health_profile` table (not `health_profile`) — columns: `user_id`, `birth_date`, `sex`, `weight_kg`, `height_cm`, `target_weight_kg`, `activity_level`, `primary_goal`, `dietary_restrictions`, `cuisine_preferences`.
- `subscription` table — query by `user_id`.

- [ ] **Step 1: Rewrite `lib/providers/user_profile_provider.dart`**

Replace the entire file contents with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/user_profile.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// UserProfile fetch
// ---------------------------------------------------------------------------

final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('user_profile')
      .select()
      .eq('id', user.id)
      .single();
  return UserProfile.fromJson(data);
});

final healthProfileProvider =
    FutureProvider.autoDispose<HealthProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('user_health_profile')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();
  if (data == null) return null;
  return HealthProfile.fromJson(data);
});

// ---------------------------------------------------------------------------
// Profile update notifier
// ---------------------------------------------------------------------------

class UserProfileNotifier extends AutoDisposeAsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('user_profile')
        .select()
        .eq('id', user.id)
        .single();
    return UserProfile.fromJson(data);
  }

  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updates = <String, dynamic>{
        if (username != null) 'username': username,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
      if (updates.isEmpty) return state.value;

      final data = await client
          .from('user_profile')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();
      return UserProfile.fromJson(data);
    });
  }
}

final userProfileNotifierProvider =
    AsyncNotifierProvider.autoDispose<UserProfileNotifier, UserProfile?>(
        UserProfileNotifier.new);

// ---------------------------------------------------------------------------
// Subscription status
// ---------------------------------------------------------------------------

final subscriptionProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('subscription')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();
  return data;
});

final isPremiumProvider = Provider.autoDispose<bool>((ref) {
  final subAsync = ref.watch(subscriptionProvider);
  return subAsync.maybeWhen(
    data: (data) => data != null && data['status'] == 'active',
    orElse: () => false,
  );
});
```

- [ ] **Step 2: Verify**

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```powershell
git add lib/providers/user_profile_provider.dart
git commit -m "feat(profile): wire user_profile and subscription tables"
```

---

## Task 4: Recipes — wire feed RPC, detail, search, like toggle

**Files:**
- Rewrite: `lib/providers/recipe_provider.dart`

**Schema notes:**
- `get_personalized_feed` RPC exists (verified in migration `20260301000002_rpc_functions.sql`). Parameters: `p_user_id uuid, p_limit int, p_offset int` — optional filter params may differ; the RPC returns rows castable to `Recipe.fromJson`.
- `toggle-recipe-like` Edge Function requires JWT — called via `client.functions.invoke`.
- `FeedParams` and `SearchParams` classes keep identical signatures.

- [ ] **Step 1: Rewrite `lib/providers/recipe_provider.dart`**

Replace the entire file contents with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../shared/models/recipe.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Feed
// ---------------------------------------------------------------------------

class FeedParams {
  final int limit;
  final int offset;
  final String? regionId;
  final String? difficulty;
  final int? maxTimeMin;

  const FeedParams({
    this.limit = 20,
    this.offset = 0,
    this.regionId,
    this.difficulty,
    this.maxTimeMin,
  });
}

final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final data = await client.rpc('get_personalized_feed', params: {
    'p_user_id': user.id,
    'p_limit': params.limit,
    'p_offset': params.offset,
  }) as List<dynamic>;

  return data
      .cast<Map<String, dynamic>>()
      .map(Recipe.fromJson)
      .toList();
});

// ---------------------------------------------------------------------------
// Recipe detail
// ---------------------------------------------------------------------------

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('recipe')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return Recipe.fromJson(data);
});

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

class SearchParams {
  final String query;
  final String? regionId;
  final String? difficulty;
  final int? maxTimeMin;
  final String orderBy;
  final int limit;
  final int offset;

  const SearchParams({
    required this.query,
    this.regionId,
    this.difficulty,
    this.maxTimeMin,
    this.orderBy = 'relevance',
    this.limit = 20,
    this.offset = 0,
  });
}

final searchRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, SearchParams>(
        (ref, params) async {
  if (params.query.length < 2) return [];

  final client = ref.watch(supabaseClientProvider);
  var query = client
      .from('recipe')
      .select()
      .ilike('title', '%${params.query}%')
      .limit(params.limit);

  final data = await query as List<dynamic>;
  return data
      .cast<Map<String, dynamic>>()
      .map(Recipe.fromJson)
      .toList();
});

// ---------------------------------------------------------------------------
// Toggle like — Edge Function
// ---------------------------------------------------------------------------

class RecipeLikeNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<bool> toggle(String recipeId, bool currentlyLiked) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    final newLiked = !currentlyLiked;
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'toggle-recipe-like',
        body: {'recipe_id': recipeId, 'liked': newLiked},
      );
      return newLiked;
    });
    return newLiked;
  }
}

final recipeLikeProvider =
    AsyncNotifierProvider.autoDispose<RecipeLikeNotifier, bool>(
        RecipeLikeNotifier.new);
```

- [ ] **Step 2: Verify**

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```powershell
git add lib/providers/recipe_provider.dart
git commit -m "feat(recipes): wire recipe feed, detail, search, and like toggle"
```

---

## Task 5: Nutrition — wire `daily_nutrition_log` and `weight_log`

**Files:**
- Rewrite: `lib/providers/nutrition_provider.dart`

**Schema notes (verified against local DB):**
- `daily_nutrition_log` columns: `id`, `user_id`, `date` (type `date`), `total_calories`, `total_protein_g`, `total_carbs_g`, `total_fat_g`. No `fiber_g`, `water_ml`.
- The current `DailyNutrition.fromJson` reads `log_date`, `calories`, `protein_g`, etc. — all wrong. The `fromJson` factory is updated inside this file to match the real columns. No `fiber_g`/`waterMl` data available; those fields will always be `0.0`.
- `weight_log` columns: `id`, `user_id`, `weight_kg`, `note`, `logged_at`.

- [ ] **Step 1: Rewrite `lib/providers/nutrition_provider.dart`**

Replace the entire file contents with:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Daily nutrition
// ---------------------------------------------------------------------------

@immutable
class DailyNutrition {
  final DateTime date;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double waterMl;

  const DailyNutrition({
    required this.date,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0.0,
    this.waterMl = 0.0,
  });

  // Columns: date, total_calories, total_protein_g, total_carbs_g, total_fat_g
  factory DailyNutrition.fromJson(Map<String, dynamic> json) => DailyNutrition(
        date: DateTime.parse(json['date'] as String),
        calories: (json['total_calories'] as num?)?.toDouble() ?? 0,
        proteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['total_carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0,
      );

  DailyNutrition operator +(DailyNutrition other) => DailyNutrition(
        date: date,
        calories: calories + other.calories,
        proteinG: proteinG + other.proteinG,
        carbsG: carbsG + other.carbsG,
        fatG: fatG + other.fatG,
      );
}

final todayNutritionProvider =
    FutureProvider.autoDispose<DailyNutrition?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final data = await client
      .from('daily_nutrition_log')
      .select()
      .eq('user_id', user.id)
      .eq('date', dateStr)
      .maybeSingle();
  if (data == null) return null;
  return DailyNutrition.fromJson(data);
});

final weeklyNutritionProvider =
    FutureProvider.autoDispose<List<DailyNutrition>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final weekAgoStr =
      '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';

  final data = await client
      .from('daily_nutrition_log')
      .select()
      .eq('user_id', user.id)
      .gte('date', weekAgoStr)
      .order('date') as List<dynamic>;

  return data
      .cast<Map<String, dynamic>>()
      .map(DailyNutrition.fromJson)
      .toList();
});

// ---------------------------------------------------------------------------
// Weight log
// ---------------------------------------------------------------------------

@immutable
class WeightEntry {
  final DateTime date;
  final double weightKg;
  final String? note;

  const WeightEntry({
    required this.date,
    required this.weightKg,
    this.note,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        date: DateTime.parse(json['logged_at'] as String),
        weightKg: (json['weight_kg'] as num).toDouble(),
        note: json['note'] as String?,
      );
}

final weightLogProvider =
    FutureProvider.autoDispose<List<WeightEntry>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('weight_log')
      .select()
      .eq('user_id', user.id)
      .order('logged_at', ascending: false) as List<dynamic>;

  return data
      .cast<Map<String, dynamic>>()
      .map(WeightEntry.fromJson)
      .toList();
});

class WeightLogNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addEntry(double weightKg, {String? note}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.from('weight_log').insert({
        'user_id': user.id,
        'weight_kg': weightKg,
        if (note != null) 'note': note,
        'logged_at': DateTime.now().toIso8601String(),
      });
      ref.invalidate(weightLogProvider);
    });
  }
}

final weightLogNotifierProvider =
    AsyncNotifierProvider.autoDispose<WeightLogNotifier, void>(
        WeightLogNotifier.new);
```

- [ ] **Step 2: Verify**

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```powershell
git add lib/providers/nutrition_provider.dart
git commit -m "feat(nutrition): wire daily nutrition log and weight log"
```

---

## Task 6: Meal Plan — fix model mismatches + wire tables + Edge Functions

**Files:**
- Modify: `lib/shared/models/meal_plan.dart`
- Rewrite: `lib/providers/meal_plan_provider.dart`

**Schema notes (verified against local DB):**

`meal_plan` columns: `id`, `user_id`, `name`, `start_date`, `end_date`, `is_active` (bool).
- Active plan query: `.eq('is_active', true)` — not `.eq('status', 'active')`.

`meal_plan_entry` columns: `id`, `meal_plan_id`, `recipe_id`, `date`, `meal_type`, `servings`.
- No `is_consumed`, `recipe_title`, `recipe_thumbnail`, `calories`, `protein_g`, `carbs_g`, `fat_g`.
- `MealPlanEntry.fromJson` reads `scheduled_date` — must be changed to `date`.
- `isConsumed` will default to `false` (no DB column).

Supabase join key: when querying `meal_plan` with `select('*, meal_plan_entry(*)')`, the nested entries arrive under the key `meal_plan_entry`, not `entries`. `MealPlan.fromJson` currently reads `json['entries']` — must be changed to `json['meal_plan_entry']`.

- [ ] **Step 1: Fix `lib/shared/models/meal_plan.dart`**

Two changes:
1. In `MealPlan.fromJson`: change `json['entries']` → `json['meal_plan_entry']`
2. In `MealPlanEntry.fromJson`: change `json['scheduled_date']` → `json['date']`

Find this block in `MealPlan.fromJson`:
```dart
        entries: (json['entries'] as List<dynamic>?)
                ?.map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
```

Replace with:
```dart
        entries: (json['meal_plan_entry'] as List<dynamic>?)
                ?.map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
```

Find this line in `MealPlanEntry.fromJson`:
```dart
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
```

Replace with:
```dart
        scheduledDate: DateTime.parse(json['date'] as String),
```

- [ ] **Step 2: Rewrite `lib/providers/meal_plan_provider.dart`**

Replace the entire file contents with:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/meal_plan.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Active meal plan — joins meal_plan_entry
// ---------------------------------------------------------------------------

final activeMealPlanProvider =
    FutureProvider.autoDispose<MealPlan?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('meal_plan')
      .select('*, meal_plan_entry(*)')
      .eq('user_id', user.id)
      .eq('is_active', true)
      .maybeSingle();
  if (data == null) return null;
  return MealPlan.fromJson(data);
});

// ---------------------------------------------------------------------------
// Generate meal plan — Edge Function
// ---------------------------------------------------------------------------

class MealPlanGeneratorNotifier extends AutoDisposeAsyncNotifier<MealPlan?> {
  @override
  Future<MealPlan?> build() async => null;

  Future<void> generate({int days = 7, int mealsPerDay = 3}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'generate-meal-plan',
        body: {'days': days, 'meals_per_day': mealsPerDay},
      );
      ref.invalidate(activeMealPlanProvider);
      return ref.read(activeMealPlanProvider.future);
    });
  }
}

final mealPlanGeneratorProvider =
    AsyncNotifierProvider.autoDispose<MealPlanGeneratorNotifier, MealPlan?>(
        MealPlanGeneratorNotifier.new);

// ---------------------------------------------------------------------------
// Shopping list — kept as mock until ingredient data is seeded
// ---------------------------------------------------------------------------

final shoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) async {
  final plan = await ref.watch(activeMealPlanProvider.future);
  if (plan == null) return [];

  // No ingredient data seeded yet — returns empty list.
  return [];
});

// ---------------------------------------------------------------------------
// Log meal consumption — Edge Function
// ---------------------------------------------------------------------------

class MealConsumptionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> logConsumption(String entryId, String recipeId) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'log-meal-consumption',
        body: {'entry_id': entryId, 'recipe_id': recipeId},
      );
      ref.invalidate(activeMealPlanProvider);
    });
  }
}

final mealConsumptionProvider =
    AsyncNotifierProvider.autoDispose<MealConsumptionNotifier, void>(
        MealConsumptionNotifier.new);
```

- [ ] **Step 3: Verify**

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```powershell
git add lib/shared/models/meal_plan.dart lib/providers/meal_plan_provider.dart
git commit -m "feat(meal-plan): fix model key mismatches and wire meal plan tables and Edge Functions"
```

---

## Task 7: Fan Mode — fix Creator model + wire subscription and creator tables

**Files:**
- Modify: `lib/shared/models/creator.dart`
- Rewrite: `lib/providers/fan_mode_provider.dart`

**Schema notes (verified against local DB):**
- `creator` has no `is_fan_eligible` column, no `average_rating`, no `food_region_id`. `Creator.fromJson` reads these safely via `?? default` fallbacks — they'll be `false`/`0.0`/`null`.
- `fanEligibleCreatorsProvider` returns all creators (no eligibility filter exists).
- `fan_subscription` columns: `id`, `user_id`, `creator_id`, `status` (`active`/`cancelled`), `subscribed_at`, `cancelled_at`, `created_at`. No `effective_from`/`effective_until`. `FanSubscription.fromJson` reads these as nullable — they'll be `null` harmlessly.

- [ ] **Step 1: Update `Creator.isFanEligible` in `lib/shared/models/creator.dart`**

The `isFanEligible` field is used in the UI but has no DB column. Change its `fromJson` mapping to derive it from `recipe_count` (same business rule: `recipe_count >= 30`) instead of reading a non-existent DB column.

Find this line in `Creator.fromJson`:
```dart
        isFanEligible: (json['is_fan_eligible'] as bool?) ?? false,
```

Replace with:
```dart
        isFanEligible: ((json['recipe_count'] as int?) ?? 0) >= 30,
```

- [ ] **Step 2: Rewrite `lib/providers/fan_mode_provider.dart`**

Replace the entire file contents with:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/creator.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// My fan subscription
// ---------------------------------------------------------------------------

final myFanSubscriptionProvider =
    FutureProvider.autoDispose<FanSubscription?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('fan_subscription')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();
  if (data == null) return null;
  return FanSubscription.fromJson(data);
});

// ---------------------------------------------------------------------------
// Fan-eligible creators (all creators — no is_fan_eligible column in DB)
// ---------------------------------------------------------------------------

final fanEligibleCreatorsProvider =
    FutureProvider.autoDispose<List<Creator>>((ref) async {
  ref.watch(currentUserProvider);

  final client = ref.watch(supabaseClientProvider);
  final data = await client.from('creator').select() as List<dynamic>;

  return data
      .cast<Map<String, dynamic>>()
      .map(Creator.fromJson)
      .where((c) => c.isFanEligible)
      .toList();
});

// ---------------------------------------------------------------------------
// Creator public profile
// ---------------------------------------------------------------------------

final creatorProfileProvider =
    FutureProvider.autoDispose.family<Creator?, String>((ref, creatorId) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('creator')
      .select()
      .eq('id', creatorId)
      .maybeSingle();
  if (data == null) return null;
  return Creator.fromJson(data);
});

// ---------------------------------------------------------------------------
// Fan mode notifier — activate / cancel via Edge Functions
// ---------------------------------------------------------------------------

class FanModeNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> activate(String creatorId) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'activate-fan-mode',
        body: {'creator_id': creatorId},
      );
      ref.invalidate(myFanSubscriptionProvider);
    });
  }

  Future<void> cancel() async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke('cancel-fan-mode', body: {});
      ref.invalidate(myFanSubscriptionProvider);
    });
  }
}

final fanModeNotifierProvider =
    AsyncNotifierProvider.autoDispose<FanModeNotifier, void>(
        FanModeNotifier.new);
```

- [ ] **Step 3: Verify**

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```powershell
git add lib/shared/models/creator.dart lib/providers/fan_mode_provider.dart
git commit -m "feat(fan-mode): wire fan subscription and creator tables"
```

---

## Final Verification

After all 7 tasks are committed, run a clean analyze pass:

- [ ] **Confirm `flutter analyze` is clean**

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Confirm `MockData` is no longer imported by any provider**

```powershell
grep -r "mock_data" lib/providers/
```

Expected: no output (all mock imports removed).

- [ ] **Confirm all 7 commits are present**

```powershell
git log --oneline -8
```

Expected to see (most recent first):
```
feat(fan-mode): wire fan subscription and creator tables
feat(meal-plan): fix model key mismatches and wire meal plan tables and Edge Functions
feat(nutrition): wire daily nutrition log and weight log
feat(recipes): wire recipe feed, detail, search, and like toggle
feat(profile): wire user_profile and subscription tables
feat(auth): wire Supabase Auth replacing MockUser
feat: add supabase_flutter and initialize local client
```
