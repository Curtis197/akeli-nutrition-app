# Akeli Logging Standard — Design Spec
**Date:** 2026-05-19  
**Status:** Approved  
**Scope:** Full-stack (Flutter + Supabase Edge Functions)

---

## Philosophy

This project is complex: auth (Supabase), Riverpod providers, DB queries, RLS policies, RPC functions, and edge functions. Bugs can originate at any layer. We do not guess. We do not search blind. Every action is logged. Every step of every action is logged. There is never enough logs.

Logs are written into source code at construction time and **never removed**. In release mode, `kDebugMode` suppresses trace/debug output automatically — no code deletion required. The decision to enter production mode (and what to silence) is made by the founder, not by the development process.

---

## Hard Rule — CLAUDE.md Enforcement

The following rule is added verbatim to `CLAUDE.md`. It applies to every file touched in every session, automatically, without invocation.

```
## Logging Standard — Mandatory (Zero Exceptions)

Every Dart file and every Deno edge function written or modified in this project
MUST contain full structured logging from the first line. This is not optional.
Logs are never removed from source code. `kDebugMode` controls runtime visibility.

### Flutter — Required for every file

1. Import and instantiate logger:
   ```dart
   import 'package:akeli/core/logger.dart';
   final _logger = appLogger; // top of class or provider
   ```

2. Provider lifecycle — log every event:
   ```dart
   _logger.provider('MyProvider build() | userId: $userId');
   ref.onDispose(() => _logger.provider('MyProvider disposed'));
   ```

3. DB query — log BEFORE, AFTER, and ERROR:
   ```dart
   _logger.db('BEFORE query | table: user_profile | userId: $userId');
   // ... query ...
   _logger.db('AFTER query | rows: ${data.length} | duration: ${ms}ms');
   // on error:
   _logger.db('ERROR query | table: user_profile | code: ${e.code}', error: e, stackTrace: st);
   ```

4. RPC calls — log BEFORE, AFTER, ERROR:
   ```dart
   _logger.db('BEFORE rpc | fn: get_personalized_feed | params: $params');
   // ... call ...
   _logger.db('AFTER rpc | fn: get_personalized_feed | rows: ${data.length}');
   ```

5. Edge function calls — log BEFORE, AFTER, ERROR:
   ```dart
   _logger.edge('toggle-recipe-like', 'BEFORE | body: $body');
   // ... invoke ...
   _logger.edge('toggle-recipe-like', 'AFTER | status: success');
   ```

6. Auth events — log every state change:
   ```dart
   _logger.auth('signIn BEFORE | email: ${LogHelper.maskEmail(email)}');
   _logger.auth('signIn SUCCESS | userId: ${user.id}');
   _logger.auth('signIn ERROR | ${e.message}', error: e, stackTrace: st);
   ```

7. UI / user actions — log every tap, submit, gesture:
   ```dart
   _logger.userAction('Login button tapped', screen: 'AuthPage');
   _logger.userAction('Form submitted', screen: 'OnboardingPage', metadata: {'step': 2});
   ```

8. State transitions — log every AsyncValue change:
   ```dart
   _logger.provider('MyProvider → loading');
   _logger.provider('MyProvider → data | count: ${items.length}');
   _logger.provider('MyProvider → error | ${e}', error: e, stackTrace: st);
   ```

9. RLS zero-row detection — always check and warn:
   ```dart
   if (data.isEmpty && userId != null) {
     _logger.rls('Zero rows returned | table: recipe | userId: $userId | possible RLS block');
   }
   ```

10. PostgrestException code 42501 → always call `.rls()` not `.db()`:
    ```dart
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | table: $table | userId: $userId', error: e, stackTrace: st);
      } else {
        _logger.db('Query error | code: ${e.code}', error: e, stackTrace: st);
      }
    }
    ```

### Deno Edge Functions — Required for every function

1. Create logger and request ID at top of handler:
   ```typescript
   const logger = createLogger('function-name');
   const requestId = crypto.randomUUID();
   logger.setRequestId(requestId);
   logger.info('⚡ ENTRY | method: ${req.method}');
   ```

2. Extract and log user from JWT immediately:
   ```typescript
   logger.setUserId(user.id);
   logger.info('👤 Auth verified | userId: ${user.id}');
   ```

3. Label every step with [STEP N]:
   ```typescript
   logger.debug('[STEP 1] Parsing request body');
   logger.debug('[STEP 2] Validating params', { keys: Object.keys(body) });
   logger.debug('[STEP 3] Querying DB | table: user_profile');
   ```

4. Use logRLSCheck before every DB operation:
   ```typescript
   logRLSCheck(logger, 'user_profile', 'UPDATE', user.id);
   ```

5. Use logQueryResult after every DB operation:
   ```typescript
   logQueryResult(logger, 'user_profile', 'UPDATE', data ? 1 : 0, error);
   ```

6. Log every early return with reason:
   ```typescript
   logger.warn('EARLY RETURN | reason: missing required field | field: fitness_goal');
   return errorResponse(400, 'Missing fitness_goal');
   ```

7. Log total duration on EXIT:
   ```typescript
   logger.info(`✅ EXIT | status: 200 | duration: ${Date.now() - start}ms`);
   ```

8. Catch-all error handler always present:
   ```typescript
   } catch (error) {
     logger.error('💥 Unhandled error', { message: error.message, stack: error.stack });
     return errorResponse(500, 'Internal server error');
   }
   ```

### Sensitive data — always mask

- Email: `LogHelper.maskEmail(email)` / `sanitizeMeta({ email })`
- UUID: `LogHelper.maskUuid(uuid)` when logging in public context
- Token: `LogHelper.maskToken(token)` / strip from meta automatically
- Never log: password, access_token, refresh_token, api_key, secret, card_number, cvv
```

---

## Infrastructure (Already Built — Do Not Recreate)

### Flutter — `lib/core/logger.dart`
- `AkeliLogger` singleton → `appLogger`
- Extension methods: `.auth()`, `.db()`, `.rls()`, `.provider()`, `.edge()`, `.userAction()`, `.navigation()`, `.performance()`
- `LogHelper`: `maskEmail()`, `maskUuid()`, `maskToken()`, `sanitizeData()`
- `RLSDebugHelper`: `debugQuery()`, `logPolicyCheck()`
- Log level: `Level.trace` in debug mode, `Level.warning` in release mode

### Deno — `supabase/functions/_shared/logger.ts`
- `createLogger(functionName)` → `EdgeLogger` instance with `.debug()`, `.info()`, `.warn()`, `.error()`
- `logger.setRequestId()` / `logger.setUserId()` — attach context to all subsequent logs
- `logRLSCheck()` — log RLS check before DB operation
- `logQueryResult()` — log DB result or error, auto-detects 42501 RLS violation

### Reference examples (do not modify, use as reference)
- Flutter: `lib/providers/_examples/auth_provider_logged.dart`
- Flutter: `lib/providers/_examples/recipe_provider_logged.dart`
- Deno: `supabase/functions/_examples/complete-onboarding-logged.ts`
- Flutter annotation template: `lib/_annotation_template.dart`

---

## Emoji Reference

| Emoji | Layer | Meaning |
|-------|-------|---------|
| 🔐 | Auth | Authentication event |
| 📡 | DB | Database query / RPC |
| 🔍 | RLS | RLS check (pre-query) |
| 🚫 | RLS | RLS block / 42501 |
| 🔄 | Provider | Provider lifecycle |
| ⚡ | Edge | Edge function call |
| 🎯 | UI | User action / button tap |
| 🧭 | Nav | Navigation / routing |
| ⏱️ | Perf | Performance / duration |
| ✅ | Any | Success |
| ❌ | Any | Error |
| ⚠️ | Any | Warning |
| 💥 | Any | Critical / unhandled |
| 👤 | Auth | User context set |
| 🗑️ | Provider | Dispose / cleanup |

---

## Retrofit Scope — 46 Files

### Flutter Providers (6)
| File | Priority |
|------|----------|
| `lib/providers/auth_provider.dart` | P0 — all other providers depend on auth |
| `lib/providers/user_profile_provider.dart` | P0 |
| `lib/providers/recipe_provider.dart` | P1 |
| `lib/providers/meal_plan_provider.dart` | P1 |
| `lib/providers/nutrition_provider.dart` | P1 |
| `lib/providers/fan_mode_provider.dart` | P1 |

### Flutter Core (3)
| File | Priority |
|------|----------|
| `lib/main.dart` | P0 — app boot |
| `lib/core/router.dart` | P0 — navigation |
| `lib/core/supabase_client.dart` | P0 — client init |

### Flutter Pages & Widgets (21)
| File |
|------|
| `lib/features/auth/auth_page.dart` |
| `lib/features/auth/onboarding_page.dart` |
| `lib/features/home/home_page.dart` |
| `lib/features/recipes/feed_page.dart` |
| `lib/features/recipes/recipe_detail_page.dart` |
| `lib/features/meal_planner/meal_planner_page.dart` |
| `lib/features/meal_planner/meal_detail_page.dart` |
| `lib/features/meal_planner/batch_cooking_page.dart` |
| `lib/features/meal_planner/shopping_list_page.dart` |
| `lib/features/meal_planner/widgets/meal_planner_day_row.dart` |
| `lib/features/nutrition/nutrition_page.dart` |
| `lib/features/profile/profile_page.dart` |
| `lib/features/ai_assistant/ai_chat_page.dart` |
| `lib/features/subscription/subscription_page.dart` |
| `lib/features/fan_mode/fan_mode_page.dart` |
| `lib/features/community/community_page.dart` |
| `lib/features/community/group_chat_page.dart` |
| `lib/features/community/group_detail_page.dart` |
| `lib/features/notifications/notifications_page.dart` |
| `lib/features/diet_plan/diet_plan_page.dart` |
| `lib/features/recipes/presentation/providers/recipe_tracking_provider.dart` |

### Deno Edge Functions (16)
| File |
|------|
| `supabase/functions/complete-onboarding/index.ts` |
| `supabase/functions/generate-meal-plan/index.ts` |
| `supabase/functions/toggle-recipe-like/index.ts` |
| `supabase/functions/log-meal-consumption/index.ts` |
| `supabase/functions/validate-store-purchase/index.ts` |
| `supabase/functions/send-push-notification/index.ts` |
| `supabase/functions/translate-content/index.ts` |
| `supabase/functions/process-fan-mode-transitions/index.ts` |
| `supabase/functions/send-meal-reminders/index.ts` |
| `supabase/functions/compute-monthly-revenue/index.ts` |
| `supabase/functions/get-creator-dashboard/index.ts` |
| `supabase/functions/activate-fan-mode/index.ts` |
| `supabase/functions/cancel-fan-mode/index.ts` |
| `supabase/functions/stripe-webhook/index.ts` |
| `supabase/functions/ai-assistant-chat/index.ts` |
| `supabase/functions/create-checkout-session/index.ts` |

---

## Implementation Waves

| Wave | Contents | Rationale |
|------|----------|-----------|
| Wave 1 | CLAUDE.md rule + Flutter core (main.dart, router.dart, supabase_client.dart) | Foundation — boot and nav logging first |
| Wave 2 | Flutter providers (6 files) | Data layer — all UI depends on these |
| Wave 3 | Flutter auth + home pages | Critical path — first thing user sees |
| Wave 4 | Flutter feature pages (remaining 19) | Full UI coverage |
| Wave 5 | Deno edge functions (16 files) | Full-stack coverage |

---

## Success Criteria

- Every method call in every provider logs BEFORE and AFTER
- Every DB query surface: table name, operation, user ID, row count, duration
- Every error: full error object + stack trace + context
- Every edge function: ENTRY, each STEP, EARLY RETURNS, EXIT with duration
- RLS code 42501 always routed to `.rls()` / `logQueryResult` error path
- Zero rows returned with authenticated user always triggers `.rls()` warning
- Sensitive fields (email, token, UUID) always masked before logging
- No log line removed from source code (only runtime level filtered by kDebugMode)
