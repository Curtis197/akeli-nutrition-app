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

## L10n Standard — Mandatory, Zero Exceptions

Every Dart widget and page written or modified in this project MUST use
`AppLocalizations` for every user-visible string. No hardcoded strings in UI.
Both `app_en.arb` and `app_fr.arb` must be updated together before any string
appears in Dart code.

### Rules

1. **No hardcoded user-visible strings** in any widget or page.
2. **ARB-first**: add to both `lib/l10n/app_en.arb` AND `lib/l10n/app_fr.arb`
   before referencing in code.
3. **Access pattern** — inside `build()`:
   ```dart
   import 'package:akeli/l10n/app_localizations.dart';
   // ...
   final l10n = AppLocalizations.of(context);
   ```
4. **Key naming**: `<screen>_<key>` camelCase (e.g. `legalPrivacyTitle`,
   `cookingSessionGotIt`). Shared keys use existing `common_` bucket.
5. **Outside widget tree** (FCM handlers etc.):
   ```dart
   AppLocalizations.of(rootScaffoldMessengerKey.currentContext!)
       ?.notificationSeeLabel ?? 'View'
   ```
6. **Providers and notifiers never resolve l10n strings** — widget layer only.
7. **Plurals/placeholders** use standard ARB format:
   ```json
   "screenCount": "{count, plural, one{{count} item} other{{count} items}}",
   "@screenCount": { "placeholders": { "count": { "type": "int" } } }
   ```
8. Run `flutter gen-l10n` after every ARB change before building/analyzing.

## Migration Workflow — Mandatory, Zero Exceptions

Every migration created in this project MUST be applied to **both** the local
database and the linked remote project (`Akeli V1`) in the same work session
it is created. Never leave a migration file in `supabase/migrations/` applied
to only one side — that drift is exactly what caused past incidents (see
`supabase/README.md` and the local/prod schema drift history).

### Required sequence, every time a migration is created or edited

1. Create the file with a timestamp prefix (`supabase migration new <name>`,
   or hand-authored `YYYYMMDDHHMMSS_description.sql`) and write the SQL.
2. Apply it locally immediately:
   ```bash
   supabase migration up
   ```
3. Push it to the linked remote project immediately after — do not batch
   several migrations before pushing:
   ```bash
   supabase db push
   ```
4. Verify both sides recorded it before doing anything else:
   ```bash
   supabase migration list
   ```
   The new timestamp MUST appear in **both** the `Local` and `Remote`
   columns. If either is blank, stop and fix it — do not start another task
   with a dangling migration.
5. Only after step 4 passes, commit the migration file to git.

### Rules

- Never create a migration "for later." If it's written, it gets applied to
  both databases before you touch anything else.
- If `supabase db push` fails (remote ahead, conflict, etc.), resolve it
  immediately rather than leaving the databases diverged.
- Migrations containing `DROP`, `TRUNCATE`, or unfiltered `DELETE FROM` need
  extra care: confirm with the user before pushing, and never bulk-push a
  backlog of unreviewed destructive migrations.
- Before adding a new migration, run `supabase migration list` — if local and
  remote have already drifted, stop and reconcile the existing drift before
  stacking new migrations on top of it.
