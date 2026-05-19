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

1. Create logger + request ID at top of handler (add after existing imports):
   ```typescript
   import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';
   // Note: ok, err, unauthorized, serverError come from '../_shared/response.ts' (already imported in all functions)
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
