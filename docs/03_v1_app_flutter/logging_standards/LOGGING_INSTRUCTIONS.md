# Akeli Nutrition App - Logging Instructions

## 🎯 Objective
**LOG EVERYTHING. GUESS NOTHING.**

Every single action, event, state change, user interaction, network call, database query, provider lifecycle, navigation, error, exception, and UI update **MUST** be logged extensively. We do NOT guess where bugs come from. We KNOW exactly where because EVERYTHING is logged.

---

## 🚨🚨🚨 CRITICAL RULE: LOGS ARE PERMANENT - NEVER REMOVE THEM 🚨🚨🚨

### THIS IS NON-NEGOTIABLE:

**Logs are NOT temporary debugging. Logs are PERMANENT INFRASTRUCTURE.**

- ❌ **STRICTLY FORBIDDEN** to remove logs after code "works"
- ❌ **STRICTLY FORBIDDEN** to remove logs because "we don't need them anymore"
- ❌ **STRICTLY FORBIDDEN** to remove logs because "they're too verbose"
- ❌ **STRICTLY FORBIDDEN** to remove logs because "the feature is stable"
- ❌ **STRICTLY FORBIDDEN** to remove logs during refactoring
- ❌ **STRICTLY FORBIDDEN** to remove logs during cleanup
- ❌ **STRICTLY FORBIDDEN** to remove logs during optimization
- ❌ **STRICTLY FORBIDDEN** to remove logs for ANY reason before final release

### ✅ The ONLY way logs can be removed:

**EXPLICIT FINAL RELEASE INSTRUCTION** - Only when explicitly told:
> "This is the final release build - remove all debug logs"

Until that exact instruction is given, **EVERY LOG STAYS FOREVER**.

### WHY Logs Must Stay Forever:

1. **An action can work now and break later** with a slight modification in:
   - A different provider
   - A different screen
   - A different database query
   - A different Supabase policy (RLS)
   - A different version of a dependency
   - A different user permission
   - A different network condition

2. **Without logs, you're blind** when bugs appear:
   - Was it working before? Logs will tell.
   - What changed? Logs will show.
   - Where did it break? Logs will point.
   - Why did it break? Logs will explain.

3. **Logs are your production monitoring**:
   - They catch regressions immediately
   - They provide context for bug reports
   - They help diagnose user issues
   - They prevent "it works on my machine" problems

4. **Removing logs is technical debt**:
   - Adding them back costs time and tokens
   - You'll forget where they were
   - You'll forget what context they had
   - You'll waste hours debugging what logs would solve in minutes

### During Code Reviews and Refactoring:

- ✅ You CAN move logs if code structure changes
- ✅ You CAN update log messages if context changes
- ✅ You CAN adjust log levels (debug → info → warning)
- ❌ You CANNOT remove logs entirely
- ❌ You CANNOT strip logs to "clean up" code
- ❌ You CANNOT say "this doesn't need logging anymore"

---

## 📋 Logging Philosophy

### Why Log Everything?
- **Debugging is expensive**: Finding auth/RLS bugs after implementation costs 10x more
- **Context is lost**: Errors without logs are impossible to reproduce
- **RLS is tricky**: Silent failures (policies blocking access) look like "empty data"
- **State management is complex**: Riverpod state changes need traceability
- **Bugs hide everywhere**: Not just in "complex" code - simple code has bugs too

### Logging Principles
1. **Log EVERYTHING**: Entry/exit of EVERY function, EVERY callback, EVERY event handler
2. **Log decisions**: EVERY if/else branch, EVERY switch case, EVERY ternary - log which branch and WHY
3. **Log context**: Include userId, requestId, timestamp, caller stack with every log
4. **Log errors with stack traces**: NEVER swallow errors silently. EVER.
5. **Log RLS explicitly**: EVERY Supabase query must log before, after, and RLS checks
6. **Log state changes**: Old state, new state, trigger (what caused the change)
7. **Log UI renders**: EVERY conditional render - which widget shown and WHY
8. **Log navigation**: EVERY route change, redirect, push, go - from, to, trigger
9. **Log performance**: EVERY slow query, EVERY slow API, EVERY slow render
10. **When in doubt, LOG MORE, NOT LESS**

---

## 🔧 What to Log

### 🚨 ABSOLUTE RULE: If something happens in the app, it gets logged.

### 1. Authentication (CRITICAL - LOG EVERYTHING)
**Location**: `lib/providers/auth_provider.dart`, `lib/features/auth/`

**Log every single event**:
- ✅ Sign-in attempt (email masked, timestamp, userId on success)
- ✅ Sign-up attempt (email masked, validation results, creation success/failure)
- ✅ Sign-out (triggered by user, session expired, token invalid, cleanup results)
- ✅ Token refresh (before with current token status, after with new token or failure reason)
- ✅ Auth state changes (null → user, user → null, user A → user B, with timestamps)
- ✅ Auth errors (invalid credentials, network timeout, expired token, rate limit, with stack traces)
- ✅ Session persistence (load from storage success/failure, restore success/failure, reason for failure)
- ✅ Email verification status (verified, not verified, verification failed)
- ✅ Password reset requests (initiated, completed, failed, with masked email)
- ✅ OAuth provider redirects (Google, Apple, etc. - before redirect, after callback, errors)
- ✅ Anonymous auth upgrades (anonymous → authenticated, with userId mapping)
- ✅ Multi-factor auth attempts (SMS sent, code verified, failed attempts)

**Example**:
```dart
logger.i('🔐 Auth: Sign-in attempt for email: ${LogHelper.maskEmail(email)}');
try {
  final user = await supabase.auth.signInWithPassword(email: email, password: password);
  logger.i('✅ Auth: Sign-in successful for userId: ${user.user?.id}');
  return user;
} on AuthException catch (e, st) {
  logger.e('❌ Auth: Sign-in failed: ${e.message} | code: ${e.code} | email: ${LogHelper.maskEmail(email)}', error: e, stackTrace: st);
  rethrow;
} catch (e, st) {
  logger.e('❌ Auth: Unexpected error during sign-in: $e | type: ${e.runtimeType}', error: e, stackTrace: st);
  rethrow;
}
```

---

### 2. Supabase Queries & RLS (CRITICAL - LOG BEFORE, AFTER, AND RLS CHECKS)
**Location**: All providers that fetch data from Supabase

**Log every single operation**:
- ✅ BEFORE query execution (table name, operation type SELECT/INSERT/UPDATE/DELETE, all filters, userId, expected outcome)
- ✅ AFTER query success (row count returned, duration in ms, success status)
- ✅ RLS violations (permission denied with error code 42501, policy name that blocked if available)
- ✅ RLS suspicious emptiness (0 rows returned when data expected, with userId and table name)
- ✅ Network errors (timeout duration, connection refused reason, DNS failure)
- ✅ Data transformation (JSON structure before mapping, model structure after mapping, mapping errors)
- ✅ Pagination state (current page, hasMore status, next offset, total count if available)
- ✅ Real-time subscriptions (connection established, subscription created, event received, event processed, errors)
- ✅ RPC function calls (function name, parameters summary, return value, error)
- ✅ Storage operations (file upload/download, bucket name, path, size, success/failure)

**Example**:
```dart
logger.d('📡 DB BEFORE: Fetching recipes | table: recipe | operation: SELECT | filters: {is_published: true, limit: 20} | userId: $userId');
try {
  final startTime = DateTime.now();
  
  final response = await supabase
      .from('recipe')
      .select()
      .eq('creator_id', userId)
      .limit(20);
  
  final duration = DateTime.now().difference(startTime);
  
  if (response.isEmpty) {
    logger.w('🔍 RLS WARNING: Recipe query returned 0 rows for userId: $userId | possible RLS policy blocking | check policies on recipe table for auth_uid() match');
  } else {
    logger.i('📡 DB AFTER: Retrieved ${response.length} recipes | duration: ${duration.inMilliseconds}ms | userId: $userId');
  }
  
  if (duration.inMilliseconds > 1000) {
    logger.w('⏱️ PERF WARNING: Recipe query slow | duration: ${duration.inMilliseconds}ms | threshold: 1000ms');
  }
  
  return response;
} on PostgrestException catch (e, st) {
  if (e.code == '42501') {
    logger.e('🚫 RLS ERROR: Permission denied on recipe query for userId: $userId | code: 42501 | message: ${e.message}', error: e, stackTrace: st);
  } else {
    logger.e('❌ DB ERROR: Query failed on recipe | code: ${e.code} | message: ${e.message} | userId: $userId', error: e, stackTrace: st);
  }
  rethrow;
} catch (e, st) {
  logger.e('❌ DB ERROR: Unexpected error fetching recipes | error: $e | type: ${e.runtimeType} | userId: $userId', error: e, stackTrace: st);
  rethrow;
}
```

---

### 3. State Management (Riverpod) (LOG EVERY LIFECYCLE EVENT AND STATE CHANGE)
**Location**: All Riverpod providers in `lib/providers/` and `lib/features/*/providers/`

**Log every single event**:
- ✅ Provider initialization (build() called, provider name, initial state, dependencies setup)
- ✅ State transitions (old state full snapshot → new state full snapshot, trigger that caused change, timestamp)
- ✅ Async operations start (loading state set, previous state saved for comparison, operation description)
- ✅ Async operations complete (success with full result, failure with error type and message and stack trace)
- ✅ Provider disposal (dispose() called, cleanup actions performed, final state, reason for disposal)
- ✅ Invalidations and rebuilds (invalidate() called, reason, rebuild triggered, old data discarded)
- ✅ Listener changes (ref.listen detected change in dependency, previous value → new value, action taken)
- ✅ Provider family calls (family parameter value, cache hit or miss, new instance created or reused)
- ✅ AutoDispose lifecycle (cancel detected, dispose scheduled, resume detected, state preserved or rebuilt)
- ✅ Selector evaluations (selector called, previous result → new result, rebuild triggered or suppressed)
- ✅ State notifier updates (update method called, validation passed/failed, state mutated, listeners notified)
- ✅ AsyncValue state changes (loading → data, loading → error, data → data (refresh), error → loading (retry))

**Example**:
```dart
class RecipeNotifier extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() async {
    logger.d('🔄 LIFECYCLE: RecipeNotifier.build() called | provider initializing');
    
    ref.onDispose(() {
      logger.d('🗑️ LIFECYCLE: RecipeNotifier disposed | cleanup performed');
    });
    
    ref.onCancel(() {
      logger.d('🗑️ LIFECYCLE: RecipeNotifier cancelled | no more listeners');
    });
    
    ref.onResume(() {
      logger.d('🔄 LIFECYCLE: RecipeNotifier resumed | listener reattached');
    });
    
    ref.listen<String?>(currentUserProvider, (previous, next) {
      logger.d('🔄 LISTENER: RecipeNotifier detected currentUserProvider change | previous: $previous | next: $next');
      
      if (previous != next) {
        if (next == null) {
          logger.d('🔄 LISTENER: RecipeNotifier user logged out | invalidating provider');
        } else {
          logger.d('🔄 LISTENER: RecipeNotifier user changed | invalidating provider');
        }
        ref.invalidateSelf();
      }
    });
    
    logger.d('🔄 LIFECYCLE: RecipeNotifier.build() calling _fetchRecipes()');
    return _fetchRecipes();
  }

  Future<List<Recipe>> _fetchRecipes() async {
    final userId = ref.read(currentUserProvider)?.id;
    logger.d('📍 EXEC: RecipeNotifier._fetchRecipes() | userId: ${userId ?? "null"}');
    
    if (userId == null) {
      logger.w('⚠️ DECISION: RecipeNotifier._fetchRecipes() returning empty list | reason: no authenticated userId');
      return [];
    }
    
    logger.i('🔄 EXEC: RecipeNotifier._fetchRecipes() fetching recipes for userId: $userId');
    
    try {
      final recipes = await ref.read(recipeRepositoryProvider).fetchRecipes(userId);
      logger.i('✅ EXEC: RecipeNotifier._fetchRecipes() loaded ${recipes.length} recipes | userId: $userId');
      return recipes;
    } catch (e, st) {
      logger.e('❌ EXEC: RecipeNotifier._fetchRecipes() failed | userId: $userId | error: $e | type: ${e.runtimeType}', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    final previousState = state;
    logger.i('🔄 ACTION: RecipeNotifier.refresh() triggered | current state: ${state.isLoading ? "loading" : state.hasError ? "error" : "data with ${(state.value ?? []).length} recipes"}');
    
    state = const AsyncValue.loading();
    logger.d('🔄 STATE: RecipeNotifier.refresh() set state to loading | previous state: ${previousState.isLoading ? "loading" : previousState.hasError ? "error" : "data"}');
    
    state = await AsyncValue.guard(() async {
      logger.d('🔄 EXEC: RecipeNotifier.refresh() calling _fetchRecipes()');
      final recipes = await _fetchRecipes();
      logger.d('✅ EXEC: RecipeNotifier.refresh() fetched ${recipes.length} recipes');
      return recipes;
    });
    
    if (state.hasError) {
      logger.e('❌ ACTION: RecipeNotifier.refresh() failed | error: ${state.error} | previous state: ${previousState.isLoading ? "loading" : previousState.hasError ? "error" : "data"}');
    } else if (state.hasValue) {
      logger.i('✅ ACTION: RecipeNotifier.refresh() succeeded | recipeCount: ${state.value!.length} | previousCount: ${(previousState.valueOrNull ?? []).length}');
    }
  }
}
```

---

### 4. Edge Functions (LOG EVERY INVOCATION, AUTH, OPERATION, AND RESPONSE)
**Location**: `supabase/functions/`

**Log every single event**:
- ✅ Function invocation (function name, requestId generated, timestamp, HTTP method, URL path)
- ✅ Request parsing (body parsed successfully, validation errors, missing fields, malformed data)
- ✅ RLS client mode (userClient with RLS enforced vs serviceClient with RLS bypassed, reason for choice)
- ✅ Auth verification (Authorization header present/missing, JWT extracted, user decoded, userId set for all subsequent logs)
- ✅ Auth failures (missing header, invalid token, expired token, user not found, error message)
- ✅ Database operations (table, operation SELECT/INSERT/UPDATE/DELETE, filters, userId, result row count or error)
- ✅ External API calls (payment/notifications/AI - endpoint, request payload summary, response status, duration, success/failure)
- ✅ Success responses (status code 200, response body summary, userId, duration)
- ✅ Validation errors (which field failed validation, expected vs actual value, error message returned)
- ✅ Retry attempts (operation being retried, attempt number, delay duration, result of retry)
- ✅ Unhandled errors (error caught in catch-all, error message, stack trace, 500 response returned)
- ✅ CORS preflight (OPTIONS request received, headers validated, CORS response sent)

**Example (TypeScript)**:
```typescript
serve(async (req: Request) => {
  const requestId = crypto.randomUUID();
  logger.info(`⚡ Function: complete-onboarding invoked [${requestId}] | method: ${req.method}`);
  
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      logger.error(`❌ Function: Missing Authorization header [${requestId}]`);
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }
    
    const supabase = userClient(req);
    logger.debug(`🔐 Function: Initialized userClient (RLS enforced) [${requestId}]`);
    
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      logger.error(`❌ Function: Auth failed: ${authError?.message} [${requestId}]`);
      return new Response(JSON.stringify({ error: 'Invalid token' }), { status: 401 });
    }
    
    logger.setUserId(user.id);
    logger.info(`👤 Function: User authenticated: ${user.id} [${requestId}]`);
    
    const body = await req.json();
    logger.debug(`📝 Function: Request body parsed [${requestId}] | keys: ${Object.keys(body).join(', ')}`);
    
    // Database operation with full logging
    logger.debug(`📡 DB BEFORE: Updating user_profile [${requestId}] | filters: {id: ${user.id}} | operation: UPDATE`);
    const startTime = Date.now();
    
    const { data, error } = await supabase
      .from('user_profile')
      .update({ onboarding_complete: true })
      .eq('id', user.id)
      .select()
      .single();
    
    const duration = Date.now() - startTime;
    
    if (error) {
      if (error.code === '42501') {
        logger.error(`🚫 RLS ERROR: Permission denied on user_profile UPDATE [${requestId}] | code: 42501`);
      } else {
        logger.error(`❌ DB ERROR: user_profile UPDATE failed [${requestId}] | code: ${error.code} | message: ${error.message} | duration: ${duration}ms`);
      }
      throw error;
    }
    
    logger.info(`✅ DB AFTER: user_profile UPDATE successful [${requestId}] | rows: 1 | duration: ${duration}ms`);
    logger.info(`✅ Function: Onboarding complete successful [${requestId}]`);
    
    return new Response(JSON.stringify({ success: true, data }), { status: 200 });
  } catch (error) {
    logger.error(`💥 Function: Unhandled error [${requestId}]: ${error.message}`, error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
});
```

---

### 5. Navigation & Routing (LOG EVERY ROUTE CHANGE AND REDIRECT DECISION)
**Location**: `lib/core/router.dart`, all navigation calls

**Log every single event**:
- ✅ Route changes (from full URI → to full URI, reason for change, trigger - user tap, redirect, deep link)
- ✅ Auth guard redirects (unauthenticated user blocked, redirect to /auth, attempted URI saved for post-login)
- ✅ Deep link handling (deep link received, target route parsed, user authenticated status, navigation allowed/blocked)
- ✅ Navigation errors (route not found, parameters invalid, context missing, push/go failed with error)
- ✅ Redirect decisions (redirect evaluated, conditions checked - isAuthenticated, isAuthRoute, redirect returned or null)
- ✅ Route guards (guard evaluated, condition passed/failed, navigation allowed/blocked, reason)
- ✅ Path parameters (route matched, parameters extracted - recipeId, userId, validation passed)
- ✅ Query parameters (query string parsed, parameters extracted, pagination filters applied)
- ✅ Nested routes (parent route matched, child route matched, full path constructed)
- ✅ GoRouter state changes (router state updated, location changed, previous location saved)

**Example**:
```dart
final router = GoRouter(
  redirect: (context, state) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final isAuthRoute = state.uri.toString().startsWith('/auth');
    
    logger.d('🧭 ROUTER: redirect evaluated | uri: ${state.uri} | isAuthenticated: $isAuthenticated | isAuthRoute: $isAuthRoute');
    
    if (!isAuthenticated && !isAuthRoute) {
      logger.d('🧭 ROUTER: redirect to /auth | reason: user not authenticated | blockedUri: ${state.uri} | will redirect after login');
      return '/auth?redirect=${state.uri.toString()}';
    }
    
    if (isAuthenticated && isAuthRoute) {
      logger.d('🧭 ROUTER: redirect to /home | reason: user already authenticated | blocking auth page access');
      return '/home';
    }
    
    logger.d('🧭 ROUTER: no redirect needed | uri: ${state.uri} | allowing navigation');
    return null;
  },
  
  routes: [
    GoRoute(
      path: '/recipes/:recipeId',
      builder: (context, state) {
        final recipeId = state.pathParameters['recipeId']!;
        logger.d('🧭 ROUTER: Route matched /recipes/:recipeId | recipeId: $recipeId | building RecipeDetailPage');
        return RecipeDetailPage(recipeId: recipeId);
      },
    ),
  ],
);

// Navigation calls
void onRecipeTap(BuildContext context, String recipeId) {
  final currentRoute = GoRouterState.of(context).uri.toString();
  logger.i('🧭 NAV: onRecipeTap() called | from: $currentRoute | to: /recipes/$recipeId | trigger: user tap on recipe card');
  
  if (currentRoute == '/recipes/$recipeId') {
    logger.d('⚠️ NAV: onRecipeTap() no-op | already on target route | skipping navigation');
    return;
  }
  
  try {
    context.push('/recipes/$recipeId');
    logger.i('✅ NAV: onRecipeTap() navigation initiated | from: $currentRoute | to: /recipes/$recipeId');
  } catch (e, st) {
    logger.e('❌ NAV: onRecipeTap() navigation failed | from: $currentRoute | to: /recipes/$recipeId | error: $e', error: e, stackTrace: st);
  }
}
```

---

### 6. User Actions (LOG EVERY TAP, SWIPE, SUBMISSION, AND GESTURE)
**Location**: UI components, gesture handlers, form widgets

**Log every single event**:
- ✅ Button taps (action name, screen context, userId, parameters passed to action)
- ✅ Form submissions (form name, validation results per field, submit success/failure, error messages)
- ✅ Swipe gestures (swipe direction, item acted upon - recipeId, result - like/dislike, success/failure)
- ✅ Screen views (screen name, parameters received, userId, view tracked in analytics)
- ✅ Text input changes (field name, new value length, validation triggered, validation result)
- ✅ Dropdown selections (dropdown name, selected value, previous value, action triggered)
- ✅ Toggle switches (toggle name, old state → new state, action triggered, API call success/failure)
- ✅ Pull-to-refresh (screen name, refresh triggered, data reloaded, refresh completed with result)
- ✅ Scroll events (list name, scroll direction, pagination triggered, more data loaded)
- ✅ Dismiss actions (item dismissed, swipe direction, undo action available, database update success/failure)
- ✅ Share actions (item shared, share method selected - native/dialog, share success/failure, error message)
- ✅ Long press actions (item long-pressed, context menu shown, user selection from menu)

**Example**:
```dart
// Button with full logging
ElevatedButton(
  onPressed: () {
    logger.i('🎯 UI: Like button tapped | recipeId: ${recipe.id} | currentlyLiked: ${recipe.isLikedByUser} | userId: ${currentUser?.id} | screen: RecipeDetailPage');
    
    ref.read(recipeNotifierProvider.notifier).toggleLike(recipe.id).then((_) {
      logger.i('✅ UI: Like button action completed successfully | recipeId: ${recipe.id} | newLikedState: ${recipe.isLikedByUser}');
    }).catchError((error, st) {
      logger.e('❌ UI: Like button action failed | recipeId: ${recipe.id} | error: $error | type: ${error.runtimeType}', error: error, stackTrace: st);
    });
  },
  child: Text(recipe.isLikedByUser ? 'Unlike' : 'Like'),
)

// Form with full logging
void onFormSubmit() {
  logger.i('🎯 UI: Recipe form submit triggered | screen: CreateRecipePage | userId: ${currentUser?.id}');
  
  // Validate fields
  final titleValid = _validateTitle(titleController.text);
  final descValid = _validateDescription(descController.text);
  
  logger.d('📝 UI: Form validation results | titleValid: $titleValid | descValid: $descValid');
  
  if (!titleValid || !descValid) {
    logger.w('⚠️ UI: Form validation failed | blocking submission | invalid fields: ${!titleValid ? "title" : ""}, ${!descValid ? "description" : ""}');
    setState(() => _showValidationErrors = true);
    return;
  }
  
  logger.d('✅ UI: Form validation passed | proceeding with submission');
  
  ref.read(recipeNotifierProvider.notifier).createRecipe(
    title: titleController.text,
    description: descController.text,
  ).then((recipeId) {
    logger.i('✅ UI: Recipe created successfully | recipeId: $recipeId | navigating to detail page');
    context.push('/recipes/$recipeId');
  }).catchError((error, st) {
    logger.e('❌ UI: Recipe creation failed | error: $error | type: ${error.runtimeType}', error: error, stackTrace: st);
    setState(() => _submissionError = error.toString());
  });
}

// Conditional render with logging
Widget build(BuildContext context) {
  logger.d('🎯 UI: RecipeCard.build() evaluating state | isLoading: ${state.isLoading} | hasError: ${state.hasError} | hasData: ${state.hasValue}');
  
  if (state.isLoading) {
    logger.d('🎯 UI: RecipeCard.render() showing ShimmerLoading | reason: state.isLoading == true');
    return ShimmerLoading();
  }
  
  if (state.hasError) {
    logger.d('🎯 UI: RecipeCard.render() showing ErrorView | reason: state.hasError == true | error: ${state.error}');
    return ErrorView(error: state.error!);
  }
  
  if (!state.hasValue || state.value!.isEmpty) {
    logger.d('🎯 UI: RecipeCard.render() showing EmptyState | reason: state.value is null or empty');
    return EmptyState();
  }
  
  logger.d('🎯 UI: RecipeCard.render() showing RecipeList | reason: state.value has ${state.value!.length} recipes');
  return RecipeList(recipes: state.value!);
}
```

---

## 🏗️ Logging Infrastructure

### Flutter Client-Side

**Use the `logger` package** (already in `pubspec.yaml`):

```yaml
dependencies:
  logger: ^2.3.0
```

**Create a centralized logger instance**:
```dart
// lib/core/logger.dart
import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
  level: kDebugMode ? Level.trace : Level.warning,
);
```

**Log levels**:
- `trace`: Extremely detailed (every state change)
- `debug`: Developer debugging (query details, provider lifecycle)
- `info`: Important events (auth success, user actions)
- `warning`: Potential issues (deprecated API, near limits)
- `error`: Actual errors (exceptions, failed operations)

---

### Supabase Server-Side (Edge Functions)

**Use Deno's console** with structured logging:

```typescript
// supabase/functions/_shared/logger.ts
export function createLogger(functionName: string) {
  return {
    debug: (msg: string, meta?: any) => 
      console.log(`🐛 [${functionName}] ${msg}`, meta ? JSON.stringify(meta) : ''),
    info: (msg: string, meta?: any) => 
      console.log(`ℹ️ [${functionName}] ${msg}`, meta ? JSON.stringify(meta) : ''),
    warn: (msg: string, meta?: any) => 
      console.warn(`⚠️ [${functionName}] ${msg}`, meta ? JSON.stringify(meta) : ''),
    error: (msg: string, meta?: any) => 
      console.error(`❌ [${functionName}] ${msg}`, meta ? JSON.stringify(meta) : ''),
  };
}
```

---

## 📊 RLS-Specific Logging

### Why RLS Logging is Special
RLS policies can **silently block queries** without throwing errors. You'll get an empty array instead of data, which looks like "no data exists" when it's actually "you don't have permission".

### RLS Logging Strategy

**1. Log the query context**:
```dart
logger.d('🔍 RLS: Querying "recipe" table with userId: ${user?.id}');
logger.d('🔍 RLS: Expected policy: "Users can view recipes from followed creators"');
```

**2. Log the result with expectations**:
```dart
if (response.isEmpty) {
  logger.w('⚠️ RLS: Query returned 0 rows. Possible RLS policy blocking userId: ${user?.id}');
  logger.w('⚠️ RLS: Check policies on "recipe" table for auth_uid() match');
}
```

**3. Log policy evaluation in Edge Functions**:
```typescript
console.log(`🔍 RLS: Using userClient (RLS enforced) for userId: ${userId}`);
// vs
console.log(`🔍 RLS: Using serviceClient (RLS bypassed) for admin operation`);
```

**4. Create an RLS debug helper**:
```dart
/// Call this when you suspect RLS is blocking access
Future<void> debugRLS(String tableName, String userId) async {
  logger.w('🔍 RLS DEBUG: Checking policies on table: $tableName');
  
  final policies = await supabase
      .from('pg_policies')
      .select()
      .eq('tablename', tableName);
  
  logger.w('🔍 RLS DEBUG: Policies found: ${policies.length}');
  for (final policy in policies) {
    logger.w('  - ${policy['policyname']}: ${policy['cmd']} | ${policy['qual']}');
  }
}
```

---

## 🎯 Implementation Priority

### Phase 1: Critical (Day 1)
- [ ] Auth provider logging (sign-in, sign-up, sign-out, errors)
- [ ] Supabase query logging (all fetches, inserts, updates)
- [ ] RLS violation detection logging
- [ ] Edge function invocation logging

### Phase 2: Important (Day 2-3)
- [ ] Riverpod provider lifecycle logging
- [ ] Navigation/routing logging
- [ ] User action logging (buttons, forms)
- [ ] Error boundary logging (try/catch everywhere)

### Phase 3: Nice to Have (Day 4+)
- [ ] Performance timing (how long queries take)
- [ ] Analytics events (screen views, user flows)
- [ ] Remote logging (send critical errors to Supabase logs table)
- [ ] Log filtering by category (auth, db, ui, etc.)

---

## 🚨 Common Bugs Caught by Logging

### Auth Bugs
- ❌ User appears logged in but token is expired
- ❌ Sign-up succeeds but profile isn't created
- ❌ Token refresh fails silently → user logged out unexpectedly

### RLS Bugs
- ❌ Query returns empty array → actually RLS blocking, not no data
- ❌ Insert fails → RLS policy doesn't allow INSERT for this role
- ❌ Update affects 0 rows → policy check uses wrong column

### State Management Bugs
- ❌ Provider rebuilds unnecessarily → performance issue
- ❌ Provider doesn't update → missing `ref.notifyListeners()`
- ❌ Stale data → provider not invalidated after mutation

### Network Bugs
- ❌ Timeout on slow connection → no retry logic
- ❌ CORS errors in web → Supabase URL misconfigured
- ❌ Rate limiting → too many requests without caching

---

## 📝 Log Format Standard

### Flutter (Dart)
```
🔐 Auth: [action] [context] [userId if available]
📡 DB: [action] [table] [filters] [userId]
🔍 RLS: [action] [table] [policy expectation] [userId]
🔄 Provider: [providerName] [action] [state change]
⚡ Edge: [functionName] [action] [requestId]
🎯 UI: [action] [screen] [context]
```

### Edge Functions (TypeScript)
```
[emoji] [category]: [message] [requestId] [userId if available]
```

**Emoji Legend**:
- 🔐 Authentication
- 📡 Database query
- 🔍 RLS check
- 🔄 Provider lifecycle
- ⚡ Edge function
- 🎯 User action
- ✅ Success
- ❌ Error
- ⚠️ Warning
- 🚫 Blocked/Denied
- 💥 Critical failure

---

## 🔒 Security Notes

### NEVER Log:
- ❌ Passwords or password hashes
- ❌ Full JWT tokens (log only userId or first/last 4 chars)
- ❌ Payment card numbers
- ❌ Personal identifiable information (PII) without hashing
- ❌ API keys or service role keys

### ALWAYS Log:
- ✅ User IDs (UUIDs, not emails)
- ✅ Timestamps
- ✅ Request IDs for correlation
- ✅ Error types and messages (not stack traces in production)
- ✅ Operation success/failure

---

## 🧪 Testing Logs

### How to Verify Logging Works
1. **Auth flow**: Sign in, sign out, fail intentionally → check logs
2. **RLS policy**: Query a table with wrong permissions → verify RLS log
3. **Provider lifecycle**: Navigate between screens → check provider init/dispose logs
4. **Edge function**: Invoke with invalid data → check error logs

### Log Output Example
```
┌──────────────────────────────────────────────
│ 🕐 14:32:15.123 
│ 📍 main.dart:42 <main>
│
│ 🔐 Auth: Initializing auth provider
│ 📍 userId: null
└──────────────────────────────────────────────

┌──────────────────────────────────────────────
│ 🕐 14:32:16.456 
│ 📍 auth_provider.dart:78 <signIn>
│
│ 🔐 Auth: Sign-in attempt for email: tes***@gmail.com
└──────────────────────────────────────────────

┌──────────────────────────────────────────────
│ 🕐 14:32:17.789 
│ 📍 auth_provider.dart:85 <signIn>
│
│ ✅ Auth: Sign-in successful for userId: abc123-def456
└──────────────────────────────────────────────

┌──────────────────────────────────────────────
│ 🕐 14:32:18.012 
│ 📍 recipe_provider.dart:34 <build>
│
│ 📡 DB: Fetching recipes for userId: abc123-def456, filters: {limit: 20}
└──────────────────────────────────────────────

┌──────────────────────────────────────────────
│ 🕐 14:32:18.345 
│ 📍 recipe_provider.dart:42 <build>
│
│ ⚠️ RLS: Query returned 0 rows. Possible RLS policy blocking userId: abc123-def456
│ ⚠️ RLS: Check policies on "recipe" table for auth_uid() match
└──────────────────────────────────────────────
```

---

## 🚀 Quick Start Checklist

When implementing a new feature, add logging FIRST:

1. [ ] Add logger imports at the top of the file
2. [ ] Log the entry point (function/provider initialization)
3. [ ] Log the main operation (query, mutation, auth call)
4. [ ] Log the result (success with count, or error with details)
5. [ ] Add RLS check if querying Supabase
6. [ ] Wrap in try/catch and log errors with stack traces
7. [ ] Test the happy path → verify logs appear
8. [ ] Test error paths → verify errors are logged

---

## 📚 References

- **Logger Package**: https://pub.dev/packages/logger
- **Supabase RLS**: https://supabase.com/docs/guides/auth/row-level-security
- **Riverpod Logging**: https://riverpod.dev/docs/concepts/provider_lifecycle
- **Edge Functions Logging**: https://supabase.com/docs/guides/functions/logs

---

**Last Updated**: 2026-04-13  
**Version**: 1.0.0  
**Maintainer**: Akeli Dev Team
