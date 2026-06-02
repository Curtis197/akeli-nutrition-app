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

## 3. Query Shape Verification

Unit tests mock the DB and never catch query shape bugs — wrong cardinality, missing filters, wrong column names. After writing or modifying **any Supabase query in a provider**, verify the actual query shape against the remote DB using MCP `execute_sql`.

> [!CAUTION]
> **`.maybeSingle()` is the most dangerous pattern.** It throws code 406 if the table has more than one matching row — even if the schema says there should be only one. Always verify the real row count before using it.

### Cardinality check — run before using `.maybeSingle()`

For every query that uses `.maybeSingle()` or `.single()`, run this against the remote DB to confirm 0 or 1 row is actually returned for a real user:

```sql
SELECT COUNT(*)
FROM my_table
WHERE user_id = '<real-user-uuid>'
  AND <other_filters>;
-- Must return 0 or 1. If > 1, the query needs .order(...).limit(1) before .maybeSingle()
```

**Real example that caused a production bug** — `user_goal` had 4 rows for one user despite `is_active = true` filter:
```sql
SELECT COUNT(*)
FROM user_goal
WHERE user_id = 'f068c92c-b9ea-496d-af52-94f40c8fab26'
  AND is_active = true;
-- Returned 4 → .maybeSingle() would throw 406 at runtime
-- Fix: add .order('created_at', ascending: false).limit(1) before .maybeSingle()
```

### Column name check — run after every migration

After a migration renames or adds columns, verify the column names the provider selects actually exist:

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'my_table'
  AND column_name IN ('col_a', 'col_b', 'col_c');
-- Every column the provider SELECTs must appear here
```

**Real example** — `allergen.label` was renamed to `label_fr` by a migration but the Flutter query still selected `label`, causing a 42703 error:
```sql
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'allergen'
  AND column_name IN ('label', 'label_fr', 'label_en');
-- 'label' was missing → query fix required
```

### Query shape checklist

For every new or modified Supabase query in a provider, check all that apply:

| Query type | What to verify with MCP |
|---|---|
| `.maybeSingle()` | Row count ≤ 1 for a real user |
| `.single()` | Row count = exactly 1 for a real user |
| `.select('col_a, col_b')` | All selected columns exist on the table |
| `.eq('col', value)` | Column exists and has the right data type |
| `.upsert({...}, onConflict: 'col')` | Conflict column has a UNIQUE constraint |
| Foreign key join (PostgREST embed) | FK relationship exists in schema |

---

## 4. Dart / Flutter Testing

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
| New/modified Supabase query in a provider | Section 3 query shape checks (cardinality + column names) |
| Migration / RPC / RLS | MCP `execute_sql` verification queries (Section 2) |
| Edge Function | `curl` against remote endpoint + `flutter test` |
| All layers | Dart → Query shape → DB → Edge Function |
