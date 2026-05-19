# Logging Standard Retrofit — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add full structured logging to every Dart file and Deno edge function in the Akeli app, then lock the standard into CLAUDE.md so it applies to every future file automatically.

**Architecture:** Infrastructure already exists — `lib/core/logger.dart` provides `appLogger` with extension methods (`.auth()`, `.db()`, `.rls()`, `.provider()`, `.edge()`, `.userAction()`) and `lib/providers/_examples/` contains reference examples. This is a pure retrofit: add `import + logger instance + log calls` to 46 files following the fixed standard in `docs/superpowers/specs/2026-05-19-logging-standard-design.md`.

**Tech Stack:** Flutter/Dart (Riverpod, Supabase), Deno/TypeScript (Supabase Edge Functions), `package:logger` (already in pubspec), `_shared/logger.ts` (already in functions).

---

## File Map

**Created:**
- `CLAUDE.md` — hard logging rule, applies every session automatically

**Modified — Flutter Core:**
- `lib/main.dart` — boot logging
- `lib/core/supabase_client.dart` — client init logging
- `lib/core/router.dart` — navigation redirect logging

**Modified — Flutter Providers:**
- `lib/providers/auth_provider.dart`
- `lib/providers/recipe_provider.dart`
- `lib/providers/user_profile_provider.dart`
- `lib/providers/meal_plan_provider.dart`
- `lib/providers/nutrition_provider.dart`
- `lib/providers/fan_mode_provider.dart`

**Modified — Flutter Pages (Wave 3–4):**
- `lib/features/auth/auth_page.dart`
- `lib/features/auth/onboarding_page.dart`
- `lib/features/home/home_page.dart`
- `lib/features/recipes/feed_page.dart`
- `lib/features/recipes/recipe_detail_page.dart`
- `lib/features/meal_planner/meal_planner_page.dart`
- `lib/features/meal_planner/meal_detail_page.dart`
- `lib/features/meal_planner/batch_cooking_page.dart`
- `lib/features/meal_planner/shopping_list_page.dart`
- `lib/features/meal_planner/widgets/meal_planner_day_row.dart`
- `lib/features/nutrition/nutrition_page.dart`
- `lib/features/profile/profile_page.dart`
- `lib/features/ai_assistant/ai_chat_page.dart`
- `lib/features/subscription/subscription_page.dart`
- `lib/features/fan_mode/fan_mode_page.dart`
- `lib/features/community/community_page.dart`
- `lib/features/community/group_chat_page.dart`
- `lib/features/community/group_detail_page.dart`
- `lib/features/notifications/notifications_page.dart`
- `lib/features/diet_plan/diet_plan_page.dart`
- `lib/features/recipes/presentation/providers/recipe_tracking_provider.dart`

**Modified — Deno Edge Functions (Wave 5):**
- `supabase/functions/complete-onboarding/index.ts`
- `supabase/functions/toggle-recipe-like/index.ts`
- `supabase/functions/generate-meal-plan/index.ts`
- `supabase/functions/log-meal-consumption/index.ts`
- `supabase/functions/validate-store-purchase/index.ts`
- `supabase/functions/send-push-notification/index.ts`
- `supabase/functions/translate-content/index.ts`
- `supabase/functions/process-fan-mode-transitions/index.ts`
- `supabase/functions/send-meal-reminders/index.ts`
- `supabase/functions/compute-monthly-revenue/index.ts`
- `supabase/functions/get-creator-dashboard/index.ts`
- `supabase/functions/activate-fan-mode/index.ts`
- `supabase/functions/cancel-fan-mode/index.ts`
- `supabase/functions/stripe-webhook/index.ts`
- `supabase/functions/ai-assistant-chat/index.ts`
- `supabase/functions/create-checkout-session/index.ts`

---

## Task 1: Create CLAUDE.md with the hard logging rule

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Create CLAUDE.md at project root**

```markdown
# Akeli — Claude Code Instructions

## Logging Standard — Mandatory, Zero Exceptions

Every Dart file and every Deno edge function written or modified in this project
MUST contain full structured logging from the first line. This is not optional.
Logs are never removed from source code. `kDebugMode` controls runtime visibility.

Reference spec: `docs/superpowers/specs/2026-05-19-logging-standard-design.md`
Reference examples:
- Flutter: `lib/providers/_examples/auth_provider_logged.dart`
- Flutter: `lib/providers/_examples/recipe_provider_logged.dart`
- Deno: `supabase/functions/_examples/complete-onboarding-logged.ts`

### Flutter — Required in every Dart file

1. Import logger at top of every file:
   ```dart
   import 'package:akeli/core/logger.dart';
   ```

2. Instantiate at class level (providers, notifiers, pages):
   ```dart
   final _logger = appLogger;
   ```

3. Provider lifecycle — build() entry + onDispose():
   ```dart
   _logger.provider('MyProvider build() | userId: $userId');
   ref.onDispose(() => _logger.provider('MyProvider disposed'));
   ```

4. DB query — BEFORE, AFTER, ERROR:
   ```dart
   _logger.db('BEFORE | table: user_profile | op: SELECT | userId: $userId');
   // ... query ...
   _logger.db('AFTER | table: user_profile | rows: ${data == null ? 0 : 1}');
   // on PostgrestException:
   } on PostgrestException catch (e, st) {
     if (e.code == '42501') {
       _logger.rls('Permission denied | table: user_profile | userId: $userId', error: e, stackTrace: st);
     } else {
       _logger.db('ERROR | table: user_profile | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
     }
   }
   ```

5. RPC calls — BEFORE, AFTER, ERROR:
   ```dart
   _logger.db('BEFORE rpc | fn: get_personalized_feed | params: $params');
   // ... rpc call ...
   _logger.db('AFTER rpc | fn: get_personalized_feed | rows: ${data.length}');
   ```

6. Edge function calls — BEFORE, AFTER, ERROR:
   ```dart
   _logger.edge('function-name', 'BEFORE | body: $body');
   // ... invoke ...
   _logger.edge('function-name', 'AFTER | success');
   // on error:
   _logger.edge('function-name', 'ERROR | $e', error: e, stackTrace: st);
   ```

7. Auth events:
   ```dart
   _logger.auth('signIn BEFORE | email: ${LogHelper.maskEmail(email)}');
   _logger.auth('signIn SUCCESS | userId: ${response.user!.id}');
   _logger.auth('signIn ERROR | ${e.message}', error: e, stackTrace: st);
   ```

8. User actions — every button tap, form submit, navigation:
   ```dart
   _logger.userAction('Login button tapped', screen: 'AuthPage');
   _logger.userAction('Sign-up form submitted', screen: 'AuthPage',
       metadata: {'email_masked': LogHelper.maskEmail(email)});
   ```

9. State transitions — every AsyncValue change:
   ```dart
   _logger.provider('MyProvider → loading');
   _logger.provider('MyProvider → data | count: ${items.length}');
   _logger.provider('MyProvider → error | $e', error: e, stackTrace: st);
   ```

10. Zero-row RLS detection after every query:
    ```dart
    if (data.isEmpty && userId != null) {
      _logger.rls('Zero rows | table: recipe | userId: $userId | possible RLS block');
    }
    ```

11. Sensitive data — always mask:
    - Email → `LogHelper.maskEmail(email)`
    - UUID → `LogHelper.maskUuid(uuid)` when logging in public context
    - Token → `LogHelper.maskToken(token)`
    - Never log: password, access_token, refresh_token, api_key, secret

### Deno Edge Functions — Required in every index.ts

1. Create logger + request ID at top of handler:
   ```typescript
   import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';
   const logger = createLogger('function-name');
   const requestId = crypto.randomUUID();
   logger.setRequestId(requestId);
   const start = Date.now();
   logger.info('⚡ ENTRY | method: ' + req.method);
   ```

2. After auth — set userId and log:
   ```typescript
   logger.setUserId(user.id);
   logger.info('👤 Auth verified | userId: ' + user.id);
   ```

3. Label every step [STEP N]:
   ```typescript
   logger.debug('[STEP 1] Parsing request body');
   logger.debug('[STEP 2] Validating params', { keys: Object.keys(body) });
   logger.debug('[STEP 3] Querying DB | table: user_profile');
   ```

4. Before each DB operation:
   ```typescript
   logRLSCheck(logger, 'table_name', 'INSERT', user.id);
   ```

5. After each DB operation:
   ```typescript
   logQueryResult(logger, 'table_name', 'INSERT', data ? 1 : 0, error ?? undefined);
   ```

6. Every early return — log reason:
   ```typescript
   logger.warn('EARLY RETURN | reason: missing recipe_id');
   return err('recipe_id is required');
   ```

7. EXIT log before every return ok():
   ```typescript
   logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
   return ok({ ... });
   ```

8. Catch-all error handler (always present):
   ```typescript
   } catch (e) {
     logger.error('💥 Unhandled error', { message: e.message, stack: e.stack });
     return serverError(e);
   }
   ```
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "chore: add mandatory logging standard to CLAUDE.md"
```

---

## Task 2: Wave 1 — Flutter Core (main.dart, supabase_client.dart, router.dart)

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/core/supabase_client.dart`
- Modify: `lib/core/router.dart`

- [ ] **Step 1: Add boot logging to lib/main.dart**

Replace the entire file with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'core/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.i('🚀 Akeli app starting | initializing Supabase');

  await initializeSupabase();
  appLogger.i('✅ Supabase initialized | launching ProviderScope');

  runApp(
    const ProviderScope(
      child: AkeliApp(),
    ),
  );
}

class AkeliApp extends ConsumerWidget {
  const AkeliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.d('🔄 AkeliApp.build() | evaluating router');
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Akeli',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Add init logging to lib/core/supabase_client.dart**

Replace the entire file with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger.dart';

const _supabaseUrl = 'http://127.0.0.1:54321';
const _supabaseAnonKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

Future<void> initializeSupabase() async {
  appLogger.d('📡 Supabase: initializing | url: $_supabaseUrl');
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
  appLogger.i('✅ Supabase: client ready');
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  ref.keepAlive();
  appLogger.d('🔄 Provider: supabaseClientProvider created (keepAlive)');
  return Supabase.instance.client;
});
```

- [ ] **Step 3: Add redirect logging to lib/core/router.dart**

In the `redirect` callback of `routerProvider`, replace the existing redirect function with:

```dart
redirect: (context, state) {
  final user = ref.read(currentUserProvider);
  final isAuth = user != null;
  final isOnAuthPage = state.uri.path == AkeliRoutes.auth;
  final isOnOnboarding = state.uri.path == AkeliRoutes.onboarding;

  appLogger.navigation(
    state.uri.path,
    '',
    reason: 'redirect check | isAuth: $isAuth',
  );

  if (!isAuth && !isOnAuthPage) {
    appLogger.navigation(state.uri.path, AkeliRoutes.auth, reason: 'unauthenticated → redirect to auth');
    return AkeliRoutes.auth;
  }
  if (isAuth && isOnAuthPage) {
    appLogger.navigation(state.uri.path, AkeliRoutes.home, reason: 'already authenticated → redirect to home');
    return AkeliRoutes.home;
  }
  if (isAuth && isOnOnboarding) {
    appLogger.d('🧭 Router: onboarding allowed | userId: ${user.id}');
    return null;
  }
  return null;
},
```

Also add the import at the top of `router.dart`:
```dart
import 'logger.dart';
```

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/core/supabase_client.dart lib/core/router.dart
git commit -m "feat(logging): add boot, client-init, and navigation logging to Flutter core"
```

---

## Task 3: Wave 2 — auth_provider.dart

**Files:**
- Modify: `lib/providers/auth_provider.dart`

- [ ] **Step 1: Replace lib/providers/auth_provider.dart with fully logged version**

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/logger.dart';

// ---------------------------------------------------------------------------
// Auth stream — single source of truth
// ---------------------------------------------------------------------------

final authStreamProvider = StreamProvider<AuthState>((ref) {
  appLogger.provider('authStreamProvider build() | subscribing to onAuthStateChange');
  ref.onDispose(() => appLogger.provider('authStreamProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((state) {
    appLogger.auth(
      'Auth state changed | event: ${state.event} | userId: ${state.session?.user.id ?? "null"}',
    );
    return state;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  final user = ref.watch(authStreamProvider).value?.session?.user;
  appLogger.provider('currentUserProvider evaluated | userId: ${user?.id ?? "null"}');
  return user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final isAuth = ref.watch(currentUserProvider) != null;
  appLogger.provider('isAuthenticatedProvider evaluated | isAuth: $isAuth');
  return isAuth;
});

// ---------------------------------------------------------------------------
// Auth notifier — sign-up, sign-in, sign-out, reset password
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<void> {
  final _logger = appLogger;

  @override
  FutureOr<void> build() {
    _logger.provider('AuthNotifier build()');
    ref.onDispose(() => _logger.provider('AuthNotifier disposed'));
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _logger.auth('signUp BEFORE | email: ${LogHelper.maskEmail(email)}');
    _logger.provider('AuthNotifier → loading (signUp)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: signUp | supabase.auth.signUp');
        final response = await client.auth.signUp(
          email: email,
          password: password,
        );
        if (response.user == null) {
          _logger.auth('signUp ERROR | no user returned');
          throw Exception('Sign-up returned no user');
        }
        _logger.auth('signUp SUCCESS | userId: ${response.user!.id}');
        _logger.provider('AuthNotifier → data (signUp success)');
      } on AuthException catch (e, st) {
        _logger.auth('signUp ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signUp failed)');
        rethrow;
      } catch (e, st) {
        _logger.auth('signUp ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signUp unexpected)');
        rethrow;
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _logger.auth('signIn BEFORE | email: ${LogHelper.maskEmail(email)}');
    _logger.provider('AuthNotifier → loading (signIn)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: signInWithPassword | supabase.auth');
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        _logger.auth('signIn SUCCESS');
        _logger.provider('AuthNotifier → data (signIn success)');
      } on AuthException catch (e, st) {
        _logger.auth('signIn ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signIn AuthException)');
        rethrow;
      } catch (e, st) {
        _logger.auth('signIn ERROR | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signIn unexpected)');
        rethrow;
      }
    });
  }

  Future<void> signOut() async {
    _logger.auth('signOut BEFORE');
    _logger.provider('AuthNotifier → loading (signOut)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: signOut | supabase.auth');
        await client.auth.signOut();
        _logger.auth('signOut SUCCESS');
        _logger.provider('AuthNotifier → data (signOut success)');
      } catch (e, st) {
        _logger.auth('signOut ERROR | $e', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (signOut failed)');
        rethrow;
      }
    });
  }

  Future<void> resetPassword(String email) async {
    _logger.auth('resetPassword BEFORE | email: ${LogHelper.maskEmail(email)}');
    _logger.provider('AuthNotifier → loading (resetPassword)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | op: resetPasswordForEmail | supabase.auth');
        await client.auth.resetPasswordForEmail(email);
        _logger.auth('resetPassword SUCCESS | email: ${LogHelper.maskEmail(email)}');
        _logger.provider('AuthNotifier → data (resetPassword success)');
      } on AuthException catch (e, st) {
        _logger.auth('resetPassword ERROR | AuthException: ${e.message}', error: e, stackTrace: st);
        _logger.provider('AuthNotifier → error (resetPassword failed)');
        rethrow;
      } catch (e, st) {
        _logger.auth('resetPassword ERROR | unexpected: $e', error: e, stackTrace: st);
        rethrow;
      }
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/auth_provider.dart
git commit -m "feat(logging): add full auth logging to auth_provider"
```

---

## Task 4: Wave 2 — recipe_provider.dart

**Files:**
- Modify: `lib/providers/recipe_provider.dart`

- [ ] **Step 1: Replace lib/providers/recipe_provider.dart with fully logged version**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../core/logger.dart';
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedParams &&
          limit == other.limit &&
          offset == other.offset &&
          regionId == other.regionId &&
          difficulty == other.difficulty &&
          maxTimeMin == other.maxTimeMin;

  @override
  int get hashCode => Object.hash(limit, offset, regionId, difficulty, maxTimeMin);
}

final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  appLogger.provider('feedProvider build() | userId: ${user?.id ?? "null"} | params: limit=${params.limit} offset=${params.offset}');
  ref.onDispose(() => appLogger.provider('feedProvider disposed | params: limit=${params.limit}'));

  if (user == null) {
    appLogger.provider('feedProvider EARLY RETURN | reason: no authenticated user');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);
  final rpcParams = {
    'p_user_id': user.id,
    'p_limit': params.limit,
    'p_offset': params.offset,
  };

  appLogger.db('BEFORE rpc | fn: get_personalized_feed | userId: ${user.id} | params: $rpcParams');

  try {
    final data = await client.rpc('get_personalized_feed', params: rpcParams) as List<dynamic>;
    appLogger.db('AFTER rpc | fn: get_personalized_feed | rows: ${data.length}');

    if (data.isEmpty) {
      appLogger.rls('Zero rows | rpc: get_personalized_feed | userId: ${user.id} | possible RLS or empty feed');
    }

    final recipes = data.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
    appLogger.provider('feedProvider → data | recipes: ${recipes.length}');
    return recipes;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | rpc: get_personalized_feed | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR rpc | fn: get_personalized_feed | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    appLogger.provider('feedProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR rpc | fn: get_personalized_feed | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('feedProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Recipe detail
// ---------------------------------------------------------------------------

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe?, String>((ref, id) async {
  appLogger.provider('recipeDetailProvider build() | recipeId: $id');
  ref.onDispose(() => appLogger.provider('recipeDetailProvider disposed | recipeId: $id'));

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: recipe | op: SELECT | recipeId: $id');

  try {
    final data = await client
        .from('recipe')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) {
      appLogger.db('AFTER | table: recipe | rows: 0 | recipeId: $id | not found');
      appLogger.provider('recipeDetailProvider → data (null)');
      return null;
    }

    appLogger.db('AFTER | table: recipe | rows: 1 | recipeId: $id');
    final recipe = Recipe.fromJson(data);
    appLogger.provider('recipeDetailProvider → data | title: ${recipe.title}');
    return recipe;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: recipe | recipeId: $id', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: recipe | recipeId: $id | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('recipeDetailProvider → error | ${e.message}');
    rethrow;
  }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          query == other.query &&
          regionId == other.regionId &&
          difficulty == other.difficulty &&
          maxTimeMin == other.maxTimeMin &&
          orderBy == other.orderBy &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(query, regionId, difficulty, maxTimeMin, orderBy, limit, offset);
}

final searchRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, SearchParams>(
        (ref, params) async {
  appLogger.provider('searchRecipesProvider build() | query: "${params.query}" | limit: ${params.limit}');
  ref.onDispose(() => appLogger.provider('searchRecipesProvider disposed | query: "${params.query}"'));

  if (params.query.length < 2) {
    appLogger.provider('searchRecipesProvider EARLY RETURN | reason: query too short (${params.query.length} chars)');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: recipe | op: SELECT ilike | query: "${params.query}" | limit: ${params.limit}');

  try {
    final data = await client
        .from('recipe')
        .select()
        .ilike('title', '%${params.query}%')
        .limit(params.limit) as List<dynamic>;

    appLogger.db('AFTER | table: recipe | rows: ${data.length} | query: "${params.query}"');

    if (data.isEmpty) {
      appLogger.provider('searchRecipesProvider → data (empty) | no results for "${params.query}"');
    }

    final recipes = data.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
    appLogger.provider('searchRecipesProvider → data | recipes: ${recipes.length}');
    return recipes;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: recipe | search query', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: recipe | search | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('searchRecipesProvider → error | ${e.message}');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Toggle like — Edge Function
// ---------------------------------------------------------------------------

class RecipeLikeNotifier extends AutoDisposeAsyncNotifier<bool> {
  final _logger = appLogger;

  @override
  Future<bool> build() async {
    _logger.provider('RecipeLikeNotifier build()');
    ref.onDispose(() => _logger.provider('RecipeLikeNotifier disposed'));
    return false;
  }

  Future<bool> toggle(String recipeId, bool currentlyLiked) async {
    _logger.userAction('Recipe like toggle', metadata: {'recipeId': recipeId, 'currentlyLiked': currentlyLiked});
    _logger.provider('RecipeLikeNotifier → loading (toggle)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    final newLiked = !currentlyLiked;

    _logger.edge('toggle-recipe-like', 'BEFORE | recipeId: $recipeId | newLiked: $newLiked');

    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'toggle-recipe-like',
          body: {'recipe_id': recipeId, 'liked': newLiked},
        );
        _logger.edge('toggle-recipe-like', 'AFTER | success | recipeId: $recipeId | liked: $newLiked');
        _logger.provider('RecipeLikeNotifier → data | liked: $newLiked');
        return newLiked;
      } catch (e, st) {
        _logger.edge('toggle-recipe-like', 'ERROR | recipeId: $recipeId | $e', error: e, stackTrace: st);
        _logger.provider('RecipeLikeNotifier → error | $e');
        rethrow;
      }
    });
    return state.valueOrNull ?? currentlyLiked;
  }
}

final recipeLikeProvider =
    AsyncNotifierProvider.autoDispose<RecipeLikeNotifier, bool>(
        RecipeLikeNotifier.new);
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/recipe_provider.dart
git commit -m "feat(logging): add full logging to recipe_provider"
```

---

## Task 5: Wave 2 — user_profile_provider.dart

**Files:**
- Modify: `lib/providers/user_profile_provider.dart`

- [ ] **Step 1: Add logging to all providers in lib/providers/user_profile_provider.dart**

Add `import '../core/logger.dart';` after the existing imports.

Then apply these specific changes:

**`userProfileProvider`** — add after `if (user == null) return null;`:
```dart
appLogger.provider('userProfileProvider build() | userId: ${user.id}');
ref.onDispose(() => appLogger.provider('userProfileProvider disposed'));
appLogger.db('BEFORE | table: user_profile | op: SELECT | userId: ${user.id}');
```
Add after `if (data == null) return null;`:
```dart
appLogger.db('AFTER | table: user_profile | rows: 0 | userId: ${user.id}');
appLogger.rls('Zero rows | table: user_profile | userId: ${user.id} | possible RLS block');
```
Add before `return UserProfile.fromJson(data);`:
```dart
appLogger.db('AFTER | table: user_profile | rows: 1 | userId: ${user.id}');
```

**`healthProfileProvider`** — same pattern with `user_health_profile`.

**`UserProfileNotifier.build()`**:
```dart
appLogger.provider('UserProfileNotifier build() | userId: ${user.id}');
ref.onDispose(() => appLogger.provider('UserProfileNotifier disposed'));
appLogger.db('BEFORE | table: user_profile | op: SELECT | userId: ${user.id}');
```

**`UserProfileNotifier.updateProfile()`** — add at start:
```dart
appLogger.userAction('updateProfile', metadata: {'fields': updates.keys.toList()});
appLogger.db('BEFORE | table: user_profile | op: UPDATE | userId: ${user.id} | fields: ${updates.keys.toList()}');
appLogger.provider('UserProfileNotifier → loading (updateProfile)');
```
Add in the guard success path before `return UserProfile.fromJson(data);`:
```dart
appLogger.db('AFTER | table: user_profile | op: UPDATE | rows: 1 | userId: ${user.id}');
appLogger.provider('UserProfileNotifier → data (updateProfile success)');
```

**`subscriptionProvider`** — add after `if (user == null) return null;`:
```dart
appLogger.provider('subscriptionProvider build() | userId: ${user.id}');
appLogger.db('BEFORE | table: subscription | op: SELECT | userId: ${user.id}');
```
Add before `return data;`:
```dart
appLogger.db('AFTER | table: subscription | rows: ${data == null ? 0 : 1} | userId: ${user.id}');
```

Wrap the query in each provider with try/catch:
```dart
} on PostgrestException catch (e, st) {
  if (e.code == '42501') {
    appLogger.rls('Permission denied | table: user_profile | userId: ${user.id}', error: e, stackTrace: st);
  } else {
    appLogger.db('ERROR | table: user_profile | code: ${e.code}', error: e, stackTrace: st);
  }
  rethrow;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/user_profile_provider.dart
git commit -m "feat(logging): add full logging to user_profile_provider"
```

---

## Task 6: Wave 2 — meal_plan_provider.dart

**Files:**
- Modify: `lib/providers/meal_plan_provider.dart`

- [ ] **Step 1: Add logging to lib/providers/meal_plan_provider.dart**

Add `import '../core/logger.dart';` after the existing imports.

**`activeMealPlanProvider`**:
```dart
appLogger.provider('activeMealPlanProvider build() | userId: ${user.id}');
ref.onDispose(() => appLogger.provider('activeMealPlanProvider disposed'));
appLogger.db('BEFORE | table: meal_plan | op: SELECT with joins | userId: ${user.id} | is_active: true');
// after query:
appLogger.db('AFTER | table: meal_plan | rows: ${data == null ? 0 : 1} | userId: ${user.id}');
if (data == null) {
  appLogger.rls('Zero rows | table: meal_plan | userId: ${user.id} | no active plan or RLS block');
}
```

**`MealPlanGeneratorNotifier.build()`**:
```dart
appLogger.provider('MealPlanGeneratorNotifier build()');
ref.onDispose(() => appLogger.provider('MealPlanGeneratorNotifier disposed'));
```

**`MealPlanGeneratorNotifier.generate()`** — add at start:
```dart
appLogger.userAction('Generate meal plan', metadata: {'days': days, 'mealsPerDay': mealsPerDay});
appLogger.edge('generate-meal-plan', 'BEFORE | days: $days | mealsPerDay: $mealsPerDay | userId: ${user.id}');
appLogger.provider('MealPlanGeneratorNotifier → loading (generate)');
```
Add in guard success path:
```dart
appLogger.edge('generate-meal-plan', 'AFTER | success');
appLogger.provider('MealPlanGeneratorNotifier → data (generate success)');
```
Add error path inside guard:
```dart
} catch (e, st) {
  appLogger.edge('generate-meal-plan', 'ERROR | $e', error: e, stackTrace: st);
  appLogger.provider('MealPlanGeneratorNotifier → error | $e');
  rethrow;
}
```

**`MealConsumptionNotifier.logConsumption()`**:
```dart
appLogger.userAction('Log meal consumption', metadata: {'mealPlanEntryId': mealPlanEntryId});
appLogger.edge('log-meal-consumption', 'BEFORE | mealPlanEntryId: $mealPlanEntryId');
appLogger.provider('MealConsumptionNotifier → loading');
// in guard success:
appLogger.edge('log-meal-consumption', 'AFTER | success');
appLogger.provider('MealConsumptionNotifier → data (logConsumption success)');
// in catch:
appLogger.edge('log-meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
```

**`cookingSessionsProvider`**:
```dart
appLogger.provider('cookingSessionsProvider build() | mealPlanId: ${plan.id}');
appLogger.db('BEFORE | table: cooking_session | op: SELECT with recipe join | mealPlanId: ${plan.id}');
// after query:
appLogger.db('AFTER | table: cooking_session | rows: ${data.length} | mealPlanId: ${plan.id}');
```

**`CookingSessionNotifier.create()`**:
```dart
appLogger.userAction('Create cooking session', metadata: {'recipeId': recipeId, 'plannedDate': plannedDate.toIso8601String()});
appLogger.db('BEFORE | table: cooking_session | op: INSERT | userId: ${user.id} | recipeId: $recipeId');
appLogger.provider('CookingSessionNotifier → loading (create)');
// in guard success:
appLogger.db('AFTER | table: cooking_session | op: INSERT | success');
appLogger.provider('CookingSessionNotifier → data (create success)');
// in catch:
appLogger.db('ERROR | table: cooking_session | op: INSERT | $e', error: e, stackTrace: st);
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/meal_plan_provider.dart
git commit -m "feat(logging): add full logging to meal_plan_provider"
```

---

## Task 7: Wave 2 — nutrition_provider.dart + fan_mode_provider.dart

**Files:**
- Modify: `lib/providers/nutrition_provider.dart`
- Modify: `lib/providers/fan_mode_provider.dart`

- [ ] **Step 1: Add logging to lib/providers/nutrition_provider.dart**

Add `import '../core/logger.dart';` after existing imports.

**`todayNutritionProvider`**:
```dart
appLogger.provider('todayNutritionProvider build() | userId: ${user.id} | date: $dateStr');
ref.onDispose(() => appLogger.provider('todayNutritionProvider disposed'));
appLogger.db('BEFORE | table: daily_nutrition_log | op: SELECT | userId: ${user.id} | date: $dateStr');
// after query:
appLogger.db('AFTER | table: daily_nutrition_log | rows: ${data == null ? 0 : 1} | userId: ${user.id}');
```

**`weeklyNutritionProvider`**:
```dart
appLogger.provider('weeklyNutritionProvider build() | userId: ${user.id} | since: $weekAgoStr');
appLogger.db('BEFORE | table: daily_nutrition_log | op: SELECT range | userId: ${user.id} | since: $weekAgoStr');
// after query:
appLogger.db('AFTER | table: daily_nutrition_log | rows: ${data.length} | userId: ${user.id}');
```

**`weightLogProvider`**:
```dart
appLogger.provider('weightLogProvider build() | userId: ${user.id}');
appLogger.db('BEFORE | table: weight_log | op: SELECT | userId: ${user.id}');
// after query:
appLogger.db('AFTER | table: weight_log | rows: ${data.length} | userId: ${user.id}');
```

**`WeightLogNotifier.addEntry()`**:
```dart
appLogger.userAction('Add weight entry', metadata: {'weightKg': weightKg});
appLogger.db('BEFORE | table: weight_log | op: INSERT | userId: ${user.id} | weightKg: $weightKg');
appLogger.provider('WeightLogNotifier → loading (addEntry)');
// in guard success:
appLogger.db('AFTER | table: weight_log | op: INSERT | success');
appLogger.provider('WeightLogNotifier → data (addEntry success)');
// in catch:
appLogger.db('ERROR | table: weight_log | op: INSERT | $e', error: e, stackTrace: st);
```

Wrap all queries in PostgrestException catch blocks:
```dart
} on PostgrestException catch (e, st) {
  if (e.code == '42501') {
    appLogger.rls('Permission denied | table: daily_nutrition_log | userId: ${user.id}', error: e, stackTrace: st);
  } else {
    appLogger.db('ERROR | table: daily_nutrition_log | code: ${e.code}', error: e, stackTrace: st);
  }
  rethrow;
}
```

- [ ] **Step 2: Add logging to lib/providers/fan_mode_provider.dart**

Add `import '../core/logger.dart';` after existing imports.

**`myFanSubscriptionProvider`**:
```dart
appLogger.provider('myFanSubscriptionProvider build() | userId: ${user.id}');
ref.onDispose(() => appLogger.provider('myFanSubscriptionProvider disposed'));
appLogger.db('BEFORE | table: fan_subscription | op: SELECT | userId: ${user.id}');
// after query:
appLogger.db('AFTER | table: fan_subscription | rows: ${data == null ? 0 : 1} | userId: ${user.id}');
```

**`fanEligibleCreatorsProvider`**:
```dart
appLogger.provider('fanEligibleCreatorsProvider build()');
appLogger.db('BEFORE | table: creator | op: SELECT all');
// after query:
appLogger.db('AFTER | table: creator | rows: ${data.length}');
```

**`creatorProfileProvider`**:
```dart
appLogger.provider('creatorProfileProvider build() | creatorId: $creatorId');
appLogger.db('BEFORE | table: creator | op: SELECT | creatorId: $creatorId');
// after query:
appLogger.db('AFTER | table: creator | rows: ${data == null ? 0 : 1} | creatorId: $creatorId');
```

**`FanModeNotifier.activate()`**:
```dart
appLogger.userAction('Activate fan mode', metadata: {'creatorId': creatorId});
appLogger.edge('activate-fan-mode', 'BEFORE | creatorId: $creatorId');
appLogger.provider('FanModeNotifier → loading (activate)');
// in guard success:
appLogger.edge('activate-fan-mode', 'AFTER | success');
appLogger.provider('FanModeNotifier → data (activate success)');
// in catch:
appLogger.edge('activate-fan-mode', 'ERROR | $e', error: e, stackTrace: st);
```

**`FanModeNotifier.cancel()`**:
```dart
appLogger.userAction('Cancel fan mode');
appLogger.edge('cancel-fan-mode', 'BEFORE');
appLogger.provider('FanModeNotifier → loading (cancel)');
// in guard success:
appLogger.edge('cancel-fan-mode', 'AFTER | success');
appLogger.provider('FanModeNotifier → data (cancel success)');
```

- [ ] **Step 3: Commit**

```bash
git add lib/providers/nutrition_provider.dart lib/providers/fan_mode_provider.dart
git commit -m "feat(logging): add full logging to nutrition_provider and fan_mode_provider"
```

---

## Task 8: Wave 3 — auth_page.dart

**Files:**
- Modify: `lib/features/auth/auth_page.dart`

- [ ] **Step 1: Add logging to lib/features/auth/auth_page.dart**

Add `import '../../core/logger.dart';` after existing imports.

In `_AuthPageState`, add at class level:
```dart
final _logger = appLogger;
```

In `_signUp()` — add at start:
```dart
_logger.userAction('Sign-up form submitted', screen: 'AuthPage',
    metadata: {'email_masked': LogHelper.maskEmail(_signUpEmail.text.trim())});
_logger.auth('signUp triggered from AuthPage | email: ${LogHelper.maskEmail(_signUpEmail.text.trim())}');
```
Add after `if (!_signUpKey.currentState!.validate()) return;`:
```dart
_logger.d('AuthPage: sign-up form validation passed');
```
Add after checking `s.hasError`:
```dart
if (s.hasError) {
  _logger.auth('signUp ERROR displayed to user | error: ${s.error}');
  setState(() => _errorMessage = _friendly(s.error.toString()));
} else {
  _logger.auth('signUp SUCCESS | navigating to onboarding');
  context.go(AkeliRoutes.onboarding);
}
```

In `_signIn()` — add at start:
```dart
_logger.userAction('Login form submitted', screen: 'AuthPage',
    metadata: {'email_masked': LogHelper.maskEmail(_loginEmail.text.trim())});
_logger.auth('signIn triggered from AuthPage | email: ${LogHelper.maskEmail(_loginEmail.text.trim())}');
```
Add after checking `s.hasError`:
```dart
if (s.hasError) {
  _logger.auth('signIn ERROR displayed to user | error: ${s.error}');
  setState(() => _errorMessage = _friendly(s.error.toString()));
} else {
  _logger.auth('signIn SUCCESS | router redirect will handle navigation');
}
```

In `_PillTabBar.onToggle` callbacks — add inside the `setState`:
```dart
onToggle: (v) => setState(() {
  _logger.userAction('Auth tab toggled', screen: 'AuthPage', metadata: {'tab': v ? 'login' : 'signup'});
  _isLogin = v;
  _errorMessage = null;
}),
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/auth/auth_page.dart
git commit -m "feat(logging): add full user action and auth logging to auth_page"
```

---

## Task 9: Wave 3 — onboarding_page.dart + home_page.dart

**Files:**
- Modify: `lib/features/auth/onboarding_page.dart`
- Modify: `lib/features/home/home_page.dart`

- [ ] **Step 1: Add logging to lib/features/auth/onboarding_page.dart**

Read the file first, then add `import '../../core/logger.dart';`.

Add `final _logger = appLogger;` at the class level of the state class.

For each step navigation method (next/previous/submit), add:
```dart
_logger.userAction('Onboarding step advanced', screen: 'OnboardingPage', metadata: {'step': _currentStep});
```

For the form submission call to the edge function, add:
```dart
_logger.edge('complete-onboarding', 'BEFORE | userId: ${user?.id}');
// after invoke:
_logger.edge('complete-onboarding', 'AFTER | success');
// on error:
_logger.edge('complete-onboarding', 'ERROR | $e', error: e, stackTrace: st);
```

- [ ] **Step 2: Add logging to lib/features/home/home_page.dart**

Add `import '../../core/logger.dart';` after existing imports.

Add `final _logger = appLogger;` at the class level of `_HomePageState`.

In `build()` — add at the start after provider subscriptions:
```dart
_logger.provider('HomePage build() | profileAsync.isLoading: ${profileAsync.isLoading} | mealPlanAsync.isLoading: ${mealPlanAsync.isLoading}');
```

For each navigation action (notifications icon, settings icon, meal card tap, recipe card tap), add:
```dart
// notifications button:
_logger.userAction('Notifications button tapped', screen: 'HomePage');
// settings button:
_logger.userAction('Settings button tapped', screen: 'HomePage');
// meal card:
_logger.userAction('Meal card tapped', screen: 'HomePage', metadata: {'mealId': entry.id});
// recipe card:
_logger.userAction('Recipe card tapped', screen: 'HomePage', metadata: {'recipeId': recipe.id});
```

In `_filterShoppingItems` — add:
```dart
_logger.d('HomePage: filtering shopping items | filter: $_activeFilter | total: ${allItems.length} | filtered: ${filtered.length}');
```

For the weight stepper `onChanged`:
```dart
onChanged: (newWeight) {
  HapticFeedback.lightImpact();
  _logger.userAction('Weight stepper changed', screen: 'HomePage', metadata: {'newWeight': newWeight});
  setState(() => _currentWeight = newWeight);
},
```

For filter chip taps:
```dart
_logger.userAction('Shopping filter changed', screen: 'HomePage', metadata: {'filter': 'tout'});
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/onboarding_page.dart lib/features/home/home_page.dart
git commit -m "feat(logging): add logging to onboarding and home pages"
```

---

## Task 10: Wave 4 — Recipe Feature Pages

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`
- Modify: `lib/features/recipes/recipe_detail_page.dart`
- Modify: `lib/features/recipes/presentation/providers/recipe_tracking_provider.dart`

- [ ] **Step 1: Apply logging standard to each file**

For each file, add `import '../../core/logger.dart';` (adjust path depth as needed).

**feed_page.dart** — add `final _logger = appLogger;` to state class. Log:
```dart
// in build():
_logger.provider('FeedPage build() | recipesAsync.isLoading: ${recipesAsync.isLoading}');
// on recipe card tap:
_logger.userAction('Recipe card tapped', screen: 'FeedPage', metadata: {'recipeId': recipe.id});
// on search submit:
_logger.userAction('Search submitted', screen: 'FeedPage', metadata: {'query': query});
// on filter change:
_logger.userAction('Feed filter changed', screen: 'FeedPage', metadata: {'filter': selectedFilter});
```

**recipe_detail_page.dart** — add `final _logger = appLogger;`. Log:
```dart
// in build():
_logger.provider('RecipeDetailPage build() | recipeId: $recipeId | recipeAsync.isLoading: ${recipeAsync.isLoading}');
// on like tap:
_logger.userAction('Like button tapped', screen: 'RecipeDetailPage', metadata: {'recipeId': recipeId});
// on save tap:
_logger.userAction('Save button tapped', screen: 'RecipeDetailPage', metadata: {'recipeId': recipeId});
// on creator tap:
_logger.userAction('Creator profile tapped', screen: 'RecipeDetailPage', metadata: {'creatorId': creatorId});
```

**recipe_tracking_provider.dart** — read file first, then add logger with `appLogger.provider(...)` on build/dispose and `appLogger.db(...)` on every DB call.

- [ ] **Step 2: Commit**

```bash
git add lib/features/recipes/
git commit -m "feat(logging): add logging to recipe feature pages and tracking provider"
```

---

## Task 11: Wave 4 — Meal Planner Pages

**Files:**
- Modify: `lib/features/meal_planner/meal_planner_page.dart`
- Modify: `lib/features/meal_planner/meal_detail_page.dart`
- Modify: `lib/features/meal_planner/batch_cooking_page.dart`
- Modify: `lib/features/meal_planner/shopping_list_page.dart`
- Modify: `lib/features/meal_planner/widgets/meal_planner_day_row.dart`

- [ ] **Step 1: Apply logging standard to all meal planner pages**

For each file, add `import '../../core/logger.dart';` (or `../../../core/logger.dart` for the widget).

Add `final _logger = appLogger;` at class level for stateful widgets.

**meal_planner_page.dart** — log:
```dart
_logger.provider('MealPlannerPage build() | mealPlanAsync.isLoading: ${mealPlanAsync.isLoading}');
// on day row tap:
_logger.userAction('Meal plan day tapped', screen: 'MealPlannerPage', metadata: {'date': date.toIso8601String()});
// on generate meal plan:
_logger.userAction('Generate meal plan tapped', screen: 'MealPlannerPage');
```

**meal_detail_page.dart** — log:
```dart
_logger.provider('MealDetailPage build() | mealId: $mealId');
// on log consumption:
_logger.userAction('Log consumption tapped', screen: 'MealDetailPage', metadata: {'mealId': mealId});
```

**batch_cooking_page.dart** — log:
```dart
_logger.provider('BatchCookingPage build()');
// on session create:
_logger.userAction('Create cooking session', screen: 'BatchCookingPage');
```

**shopping_list_page.dart** — log:
```dart
_logger.provider('ShoppingListPage build()');
// on item check toggle:
_logger.userAction('Shopping item toggled', screen: 'ShoppingListPage', metadata: {'itemId': itemId});
```

**meal_planner_day_row.dart** — log:
```dart
_logger.provider('MealPlannerDayRow build() | date: $date');
// on tap:
_logger.userAction('Day row tapped', screen: 'MealPlannerPage', metadata: {'date': date.toIso8601String()});
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/meal_planner/
git commit -m "feat(logging): add logging to all meal planner pages"
```

---

## Task 12: Wave 4 — Remaining Feature Pages

**Files:**
- Modify: `lib/features/nutrition/nutrition_page.dart`
- Modify: `lib/features/profile/profile_page.dart`
- Modify: `lib/features/ai_assistant/ai_chat_page.dart`
- Modify: `lib/features/subscription/subscription_page.dart`
- Modify: `lib/features/fan_mode/fan_mode_page.dart`
- Modify: `lib/features/community/community_page.dart`
- Modify: `lib/features/community/group_chat_page.dart`
- Modify: `lib/features/community/group_detail_page.dart`
- Modify: `lib/features/notifications/notifications_page.dart`
- Modify: `lib/features/diet_plan/diet_plan_page.dart`

- [ ] **Step 1: Apply logging standard to all remaining pages**

For each file, add the logger import and instantiation, then add these log calls:

**nutrition_page.dart**:
```dart
_logger.provider('NutritionPage build() | nutritionAsync.isLoading: ${nutritionAsync.isLoading}');
_logger.userAction('Log water intake', screen: 'NutritionPage', metadata: {'ml': amount});
_logger.userAction('Log meal tapped', screen: 'NutritionPage');
```

**profile_page.dart**:
```dart
_logger.provider('ProfilePage build() | profileAsync.isLoading: ${profileAsync.isLoading}');
_logger.userAction('Edit profile tapped', screen: 'ProfilePage');
_logger.userAction('Sign out tapped', screen: 'ProfilePage');
_logger.userAction('Profile form submitted', screen: 'ProfilePage');
```

**ai_chat_page.dart**:
```dart
_logger.provider('AiChatPage build()');
_logger.userAction('Chat message sent', screen: 'AiChatPage', metadata: {'messageLength': message.length});
_logger.edge('ai-assistant-chat', 'BEFORE | message length: ${message.length}');
// after response:
_logger.edge('ai-assistant-chat', 'AFTER | success');
// on error:
_logger.edge('ai-assistant-chat', 'ERROR | $e', error: e, stackTrace: st);
```

**subscription_page.dart**:
```dart
_logger.provider('SubscriptionPage build()');
_logger.userAction('Subscribe button tapped', screen: 'SubscriptionPage', metadata: {'plan': planId});
_logger.edge('create-checkout-session', 'BEFORE | planId: $planId');
_logger.edge('create-checkout-session', 'AFTER | success');
```

**fan_mode_page.dart**:
```dart
_logger.provider('FanModePage build()');
_logger.userAction('Fan mode activate tapped', screen: 'FanModePage', metadata: {'creatorId': creatorId});
_logger.userAction('Fan mode cancel tapped', screen: 'FanModePage');
```

**community_page.dart**:
```dart
_logger.provider('CommunityPage build()');
_logger.userAction('Group card tapped', screen: 'CommunityPage', metadata: {'groupId': groupId});
```

**group_chat_page.dart**:
```dart
_logger.provider('GroupChatPage build() | groupId: $groupId');
_logger.userAction('Chat message sent', screen: 'GroupChatPage', metadata: {'groupId': groupId});
```

**group_detail_page.dart**:
```dart
_logger.provider('GroupDetailPage build() | groupId: $groupId');
_logger.userAction('Join group tapped', screen: 'GroupDetailPage', metadata: {'groupId': groupId});
```

**notifications_page.dart**:
```dart
_logger.provider('NotificationsPage build()');
_logger.userAction('Notification tapped', screen: 'NotificationsPage', metadata: {'notificationId': id});
_logger.userAction('Mark all read tapped', screen: 'NotificationsPage');
```

**diet_plan_page.dart**:
```dart
_logger.provider('DietPlanPage build()');
_logger.userAction('Diet plan action', screen: 'DietPlanPage');
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/nutrition/ lib/features/profile/ lib/features/ai_assistant/ \
  lib/features/subscription/ lib/features/fan_mode/ lib/features/community/ \
  lib/features/notifications/ lib/features/diet_plan/
git commit -m "feat(logging): add logging to all remaining feature pages"
```

---

## Task 13: Wave 5 — Deno Edge Functions (Auth & Onboarding Group)

**Files:**
- Modify: `supabase/functions/complete-onboarding/index.ts`
- Modify: `supabase/functions/validate-store-purchase/index.ts`
- Modify: `supabase/functions/create-checkout-session/index.ts`
- Modify: `supabase/functions/stripe-webhook/index.ts`

The reference example is at `supabase/functions/_examples/complete-onboarding-logged.ts`. Use it as the exact pattern.

- [ ] **Step 1: Retrofit complete-onboarding/index.ts**

This file has 6 sequential DB operations. Add logging as follows. Add at the top of `serve()`:

```typescript
import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger('complete-onboarding');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info('⚡ ENTRY | method: ' + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn('EARLY RETURN | reason: unauthorized');
      return unauthorized();
    }
    logger.setUserId(user.id);
    logger.info('👤 Auth verified | userId: ' + user.id);

    logger.debug('[STEP 1] Parsing request body');
    const body = await req.json();
    const { first_name, last_name, sex, birth_date, height_cm, weight_kg,
            target_weight_kg, activity_level, goals, dietary_restrictions,
            cuisine_preferences } = body;
    logger.debug('[STEP 1] Body parsed', { keys: Object.keys(body) });

    logger.debug('[STEP 2] Validating required fields');
    if (!sex || !birth_date || !height_cm || !weight_kg || !activity_level) {
      logger.warn('EARLY RETURN | reason: missing required health profile fields', {
        missing: { sex: !sex, birth_date: !birth_date, height_cm: !height_cm,
                   weight_kg: !weight_kg, activity_level: !activity_level }
      });
      return err('Missing required health profile fields');
    }

    const admin = serviceClient();

    logger.debug('[STEP 3] Upserting user_health_profile');
    logRLSCheck(logger, 'user_health_profile', 'INSERT', user.id);
    const { error: healthError } = await admin.from('user_health_profile').upsert({
      user_id: user.id, sex, birth_date, height_cm, weight_kg,
      target_weight_kg, activity_level,
    });
    logQueryResult(logger, 'user_health_profile', 'INSERT', healthError ? 0 : 1, healthError ?? undefined);
    if (healthError) throw healthError;

    logger.debug('[STEP 4] Replacing user_goal records');
    logRLSCheck(logger, 'user_goal', 'DELETE', user.id);
    await admin.from('user_goal').delete().eq('user_id', user.id);
    logQueryResult(logger, 'user_goal', 'DELETE', 1);
    if (goals?.length) {
      logRLSCheck(logger, 'user_goal', 'INSERT', user.id);
      await admin.from('user_goal').insert(
        goals.map((goal_type: string) => ({ user_id: user.id, goal_type, is_active: true }))
      );
      logQueryResult(logger, 'user_goal', 'INSERT', goals.length);
      logger.debug('[STEP 4] user_goal inserted | count: ' + goals.length);
    }

    logger.debug('[STEP 5] Replacing dietary restrictions');
    logRLSCheck(logger, 'user_dietary_restriction', 'DELETE', user.id);
    await admin.from('user_dietary_restriction').delete().eq('user_id', user.id);
    if (dietary_restrictions?.length) {
      logRLSCheck(logger, 'user_dietary_restriction', 'INSERT', user.id);
      await admin.from('user_dietary_restriction').insert(
        dietary_restrictions.map((restriction: string) => ({ user_id: user.id, restriction }))
      );
      logQueryResult(logger, 'user_dietary_restriction', 'INSERT', dietary_restrictions.length);
    }

    logger.debug('[STEP 6] Replacing cuisine preferences');
    await admin.from('user_cuisine_preference').delete().eq('user_id', user.id);
    if (cuisine_preferences?.length) {
      await admin.from('user_cuisine_preference').insert(
        (cuisine_preferences as string[]).map((region) => ({
          user_id: user.id, region, preference_score: 1.0,
        }))
      );
      logQueryResult(logger, 'user_cuisine_preference', 'INSERT', cuisine_preferences.length);
    }

    logger.debug('[STEP 7] Updating user_profile onboarding_done');
    logRLSCheck(logger, 'user_profile', 'UPDATE', user.id);
    const { error: profileError } = await admin.from('user_profile')
      .update({ first_name, last_name, onboarding_done: true })
      .eq('id', user.id);
    logQueryResult(logger, 'user_profile', 'UPDATE', profileError ? 0 : 1, profileError ?? undefined);

    logger.debug('[STEP 8] Triggering Python vector computation (non-blocking)');
    fetch(`${PYTHON_SERVICE_URL}/compute-user-vector`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: user.id }),
    }).catch((e) => logger.error('Python vector computation failed (non-blocking)', { error: e.message }));

    logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
    return ok({ message: 'Onboarding completed', user_id: user.id });

  } catch (e) {
    logger.error('💥 Unhandled error', { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 2: Retrofit validate-store-purchase/index.ts, create-checkout-session/index.ts, stripe-webhook/index.ts**

Read each file, then apply the Deno logging pattern:
1. Add `import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';` after existing imports
2. Add logger + requestId + start at top of `serve()`
3. Add `logger.setUserId(user.id)` after auth verification
4. Label each existing block with `logger.debug('[STEP N] ...')`
5. Add `logRLSCheck` before each DB operation
6. Add `logQueryResult` after each DB operation
7. Add `logger.warn('EARLY RETURN | reason: ...')` before each early return
8. Add `logger.info('✅ EXIT | ...')` before each `return ok(...)`
9. Add `logger.error('💥 Unhandled error', ...)` in the catch block

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/complete-onboarding/ supabase/functions/validate-store-purchase/ \
  supabase/functions/create-checkout-session/ supabase/functions/stripe-webhook/
git commit -m "feat(logging): add full structured logging to auth/payment edge functions"
```

---

## Task 14: Wave 5 — Deno Edge Functions (Recipe & Fan Mode Group)

**Files:**
- Modify: `supabase/functions/toggle-recipe-like/index.ts`
- Modify: `supabase/functions/activate-fan-mode/index.ts`
- Modify: `supabase/functions/cancel-fan-mode/index.ts`
- Modify: `supabase/functions/process-fan-mode-transitions/index.ts`

- [ ] **Step 1: Retrofit toggle-recipe-like/index.ts**

Replace with logged version:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger('toggle-recipe-like');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info('⚡ ENTRY | method: ' + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn('EARLY RETURN | reason: unauthorized');
      return unauthorized();
    }
    logger.setUserId(user.id);
    logger.info('👤 Auth verified | userId: ' + user.id);

    logger.debug('[STEP 1] Parsing request body');
    const { recipe_id } = await req.json();
    if (!recipe_id) {
      logger.warn('EARLY RETURN | reason: missing recipe_id');
      return err('recipe_id is required');
    }
    logger.debug('[STEP 1] recipe_id: ' + recipe_id);

    logger.debug('[STEP 2] Checking existing like | table: recipe_like');
    logRLSCheck(logger, 'recipe_like', 'SELECT', user.id);
    const { data: existing } = await client
      .from('recipe_like')
      .select('user_id')
      .eq('user_id', user.id)
      .eq('recipe_id', recipe_id)
      .maybeSingle();
    logQueryResult(logger, 'recipe_like', 'SELECT', existing ? 1 : 0);

    if (existing) {
      logger.debug('[STEP 3] Unlike — deleting existing like');
      logRLSCheck(logger, 'recipe_like', 'DELETE', user.id);
      const { error } = await client
        .from('recipe_like')
        .delete()
        .eq('user_id', user.id)
        .eq('recipe_id', recipe_id);
      logQueryResult(logger, 'recipe_like', 'DELETE', error ? 0 : 1, error ?? undefined);
      if (error) throw error;
      logger.info('✅ EXIT | liked: false | duration: ' + (Date.now() - start) + 'ms');
      return ok({ liked: false });
    } else {
      logger.debug('[STEP 3] Like — inserting new like');
      logRLSCheck(logger, 'recipe_like', 'INSERT', user.id);
      const { error } = await client
        .from('recipe_like')
        .insert({ user_id: user.id, recipe_id });
      logQueryResult(logger, 'recipe_like', 'INSERT', error ? 0 : 1, error ?? undefined);
      if (error) throw error;
      logger.info('✅ EXIT | liked: true | duration: ' + (Date.now() - start) + 'ms');
      return ok({ liked: true });
    }
  } catch (e) {
    logger.error('💥 Unhandled error', { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
```

- [ ] **Step 2: Retrofit activate-fan-mode, cancel-fan-mode, process-fan-mode-transitions**

Read each file and apply the same pattern: logger + requestId + start, setUserId after auth, [STEP N] labels, logRLSCheck + logQueryResult around each DB op, EARLY RETURN warns, EXIT info, catch-all error.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/toggle-recipe-like/ supabase/functions/activate-fan-mode/ \
  supabase/functions/cancel-fan-mode/ supabase/functions/process-fan-mode-transitions/
git commit -m "feat(logging): add full structured logging to recipe and fan mode edge functions"
```

---

## Task 15: Wave 5 — Deno Edge Functions (Meal Plan & Utility Group)

**Files:**
- Modify: `supabase/functions/generate-meal-plan/index.ts`
- Modify: `supabase/functions/log-meal-consumption/index.ts`
- Modify: `supabase/functions/send-push-notification/index.ts`
- Modify: `supabase/functions/translate-content/index.ts`
- Modify: `supabase/functions/send-meal-reminders/index.ts`
- Modify: `supabase/functions/compute-monthly-revenue/index.ts`
- Modify: `supabase/functions/get-creator-dashboard/index.ts`
- Modify: `supabase/functions/ai-assistant-chat/index.ts`

- [ ] **Step 1: Read each file, then apply the Deno logging pattern**

For all 8 files, the pattern is identical to Task 13 Step 2:

1. Add import: `import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';`
2. First lines of `serve()`:
   ```typescript
   const logger = createLogger('function-name'); // use actual function name
   const requestId = crypto.randomUUID();
   logger.setRequestId(requestId);
   const start = Date.now();
   logger.info('⚡ ENTRY | method: ' + req.method);
   ```
3. After `getAuthUser`:
   ```typescript
   logger.setUserId(user.id);
   logger.info('👤 Auth verified | userId: ' + user.id);
   ```
4. Label each logical block: `logger.debug('[STEP N] description');`
5. Before each DB call: `logRLSCheck(logger, 'table', 'OPERATION', user.id);`
6. After each DB call: `logQueryResult(logger, 'table', 'OPERATION', rowCount, error ?? undefined);`
7. Before each early return: `logger.warn('EARLY RETURN | reason: ...');`
8. Before each `return ok(...)`: `logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');`
9. In catch: `logger.error('💥 Unhandled error', { message: e.message, stack: e.stack });`

Key specifics per function:
- `generate-meal-plan`: logs Python service call separately as non-blocking
- `log-meal-consumption`: logs each meal entry component processed
- `send-push-notification`: logs recipient userId + notification type
- `translate-content`: logs content type + language pair
- `send-meal-reminders`: logs how many reminders sent
- `compute-monthly-revenue`: logs revenue period + total computed
- `get-creator-dashboard`: logs creatorId + data shapes returned
- `ai-assistant-chat`: logs conversation_id + message length (never log message content)

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/generate-meal-plan/ supabase/functions/log-meal-consumption/ \
  supabase/functions/send-push-notification/ supabase/functions/translate-content/ \
  supabase/functions/send-meal-reminders/ supabase/functions/compute-monthly-revenue/ \
  supabase/functions/get-creator-dashboard/ supabase/functions/ai-assistant-chat/
git commit -m "feat(logging): add full structured logging to meal plan and utility edge functions"
```

---

## Task 16: Verify & Final Commit

- [ ] **Step 1: Verify Flutter app compiles**

```bash
flutter analyze
```
Expected: no errors related to logger (warnings about unused variables in pages are acceptable temporarily).

- [ ] **Step 2: Verify no file is missing the logger import**

```bash
grep -rL "core/logger.dart" lib/providers/ lib/features/ lib/core/
grep -rL "createLogger" supabase/functions/complete-onboarding/ supabase/functions/toggle-recipe-like/
```
Expected: no output (all files have the import).

- [ ] **Step 3: Verify CLAUDE.md exists and contains the rule**

```bash
grep -c "Logging Standard" CLAUDE.md
```
Expected: `1`

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat(logging): complete logging retrofit — all 46 files, CLAUDE.md hard rule added"
```
