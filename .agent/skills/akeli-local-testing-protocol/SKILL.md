---
name: akeli-local-testing-protocol
description: Master protocol for writing and executing tests for Dart, Supabase Edge Functions, and Postgres RPCs. Uses the remote Supabase project — never the local stack (which is out of sync). Use this automatically whenever code is created or updated.
---

# Akeli Testing Protocol

You are the gatekeeper of quality for the Akeli app. Your mandate is to ensure that **every piece of logic (RPC, Edge Function, Dart Provider/UI) is tested against the remote Supabase project before it is considered done.**

> [!CAUTION]
> **Zero Permission Execution Rule**
> Execute tests automatically whenever you create or update a function. Do NOT ask the user for permission. Run it, read the results, fix errors, and report the final status.

> [!IMPORTANT]
> **Never use the local Supabase stack.**
> `supabase start`, `supabase test db`, and `deno test` against `localhost` are all banned — the local database is out of sync with the remote schema. All verification must target the remote project.

---

## Remote Project Reference

| Key | Value |
|---|---|
| Project ID | `njzqcftjzskwcpforwzf` |
| Project URL | `https://njzqcftjzskwcpforwzf.supabase.co` |
| Anon key | `sb_publishable_2WUTLXygeO3s1FTvBdydwA_24zE-a6R` |

---

## 1. Edge Function Testing

After deploying or modifying an Edge Function, verify it against the **remote deployed endpoint** using `curl`.

**Rules:**
1. Always test the happy path and at least one error case (missing param, unauthenticated).
2. Use the anon key as the Bearer token for unauthenticated calls; use a real user JWT for authenticated calls.
3. Check both the HTTP status code and the response body.

**Happy path example:**
```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/<function-name> \
  -H "Authorization: Bearer sb_publishable_2WUTLXygeO3s1FTvBdydwA_24zE-a6R" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
# Expected: 200
```

**Missing param / error case example:**
```bash
curl -s \
  -X POST https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/<function-name> \
  -H "Authorization: Bearer sb_publishable_2WUTLXygeO3s1FTvBdydwA_24zE-a6R" \
  -H "Content-Type: application/json" \
  -d '{}'
# Expected: 400 with error message in body
```

**How to get a user JWT for authenticated calls:**
Use the Supabase MCP `execute_sql` tool to run:
```sql
SELECT auth.uid() FROM auth.users LIMIT 1;
```
Then obtain a token via the Supabase dashboard Auth → Users → copy JWT, or use a test user created for that purpose.

---

## 2. Postgres RPC / DB Verification

After adding or modifying an RPC, trigger, migration, or RLS policy, verify it directly on the remote database using the **Supabase MCP `execute_sql` tool** with `project_id: njzqcftjzskwcpforwzf`.

**Rules:**
1. Wrap mutations in a transaction with `ROLLBACK` to leave remote state clean.
2. For read-only checks (function exists, row counts, schema verification), no transaction needed.
3. Always check: function/table exists, expected output for known input, RLS policy names present.

**Verify a function exists:**
```sql
SELECT proname, pronargs
FROM pg_proc
WHERE proname = 'my_rpc_name';
```

**Verify a table column exists:**
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'my_table'
  AND column_name = 'my_column';
```

**Test an RPC output (read-only, safe to run on remote):**
```sql
SELECT * FROM my_rpc('param1', 'param2') LIMIT 5;
```

**Test a mutation RPC safely (wrapped in ROLLBACK):**
```sql
BEGIN;
  SELECT * FROM my_mutating_rpc('test-uuid'::uuid);
  -- Assert expected output above before rollback
ROLLBACK;
```

**Verify RLS policies exist:**
```sql
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'my_table';
```

---

## 3. Dart / Flutter Testing

All Dart logic (Providers, pure functions, utils) must have unit tests. These never hit the network.

**Location:** `test/features/` or `test/providers/`
**Framework:** `flutter_test`, `mocktail`

**Rules:**
1. Mock the Supabase client with `mocktail` — no live network calls in unit tests.
2. Export pure functions from provider files so they can be tested without Riverpod setup (see `activityLevelForCalculator` / `computeCalorieGoal` in `health_profile_provider.dart` as the established pattern).
3. Run: `flutter test test/path/to/test_file.dart`
4. Run the full suite before reporting done: `flutter test`

**Example skeleton:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/my_provider.dart';

void main() {
  group('myPureFunction', () {
    test('returns expected value for known input', () {
      expect(myPureFunction('input'), 'expected');
    });

    test('returns fallback for unknown input', () {
      expect(myPureFunction('unknown'), 'fallback');
    });
  });
}
```

---

## 4. Execution Order

For any change, run all three layers that apply:

| Layer changed | Run |
|---|---|
| Dart only | `flutter test` |
| Migration / RPC / RLS | MCP `execute_sql` verification queries |
| Edge Function | `curl` against remote endpoint + `flutter test` |
| All layers | All of the above, in order: Dart → DB → Edge Function |
