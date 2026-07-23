# Beauty Mode Fix — Area A: SQL Vector Engine & Recommendation Core

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the IDOR/privacy-leak holes, overload ambiguity, unclamped scoring, duplicate-ingredient data corruption, lost virtue-weight data, and missing `search_path` hardening in the Beauty Mode vector engine and recommendation RPCs, each behind a pgTAP regression test.

**Architecture:** Every fix is a brand-new, additive migration file (never an edit to an already-committed migration) that either `CREATE OR REPLACE`s a function in place to patch its body, or runs corrective `UPDATE`/`DELETE`/`ALTER TABLE` statements against existing rows. Each task is proven with a pgTAP test in `supabase/tests/` that is red against the pre-fix schema and green once the new migration is applied.

**Tech Stack:** PostgreSQL/Supabase migrations, pgvector (`vector(50)`, `<=>` cosine distance operator), pgTAP (`plan()`, `throws_ok()`, `lives_ok()`, `is()`, `ok()`, `finish()`).

## Global Constraints
- Repo: `c:\Users\DELL LATITUDE 7480\akeli-nutrition-app`, branch `sdui`.
- Every fix is a NEW migration file under `supabase/migrations/` with timestamp prefix `20260722090000`, incrementing by `100` per file (`090000`, `090100`, `090200`, ...) — never edit an existing committed migration in place. Stay strictly below `20260722100000` (Area B owns `20260722100000+`, Area C owns `20260722110000+`).
- Only touch the 19 files this area owns (listed in the review's Area A section) as **read-only reference** — never edit them directly. Any fix that would require editing a file outside this list is called out as a cross-plan dependency instead of being touched here.
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- pgTAP test run convention already established in this repo (see `supabase/tests/calculate_nutrition_targets_test.sql`, `supabase/tests/generate_meal_plan_custom_schedule_test.sql`): `BEGIN; SELECT plan(N); ... SELECT * FROM finish(); ROLLBACK;`, executed locally via `supabase db reset; supabase test db supabase/tests/<file>.sql` (repo root, local Supabase stack via `supabase start`). To simulate a specific caller's `auth.uid()`, use `SET LOCAL "request.jwt.claims" TO '{"sub": "<uuid>"}';` before the RPC call — this is the exact idiom already used in `generate_meal_plan_custom_schedule_test.sql:114`.
- `RAISE EXCEPTION 'Unauthorized'` (no explicit `USING ERRCODE`) always raises SQLSTATE `P0001` — this is what every `throws_ok(..., 'P0001', 'Unauthorized', ...)` assertion in this plan checks for.
- Finding #4 (SQL-side selective virtue masking) is explicitly **out of scope** for this plan per the task brief — see the Coverage Checklist for the reasoning; no task implements it.
- This plan also fixes one **verified-but-unlisted** bug found while re-reading the owned files (`generate_feed_personalized`'s auth check was silently dropped the same way `recommend_recipes`'s was) — see Task 3, flagged there and in the Coverage Checklist as not one of the original 8 findings.

---

### Task 1: Restore missing `auth.uid()` check in `generate_routine_plan`

**Files:**
- Create: `supabase/migrations/20260722090000_fix_generate_routine_plan_auth_check.sql`
- Test: `supabase/tests/generate_routine_plan_auth_check_test.sql`

**Interfaces:**
- Produces: `generate_routine_plan(p_user_id uuid, p_days integer DEFAULT 7) RETURNS uuid` — signature unchanged from `20260720000001_beauty_mode_database_update.sql:90`; now raises `EXCEPTION 'Unauthorized'` (SQLSTATE `P0001`) when `auth.uid() IS DISTINCT FROM p_user_id`, before touching any row.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/generate_routine_plan_auth_check_test.sql`:

```sql
-- supabase/tests/generate_routine_plan_auth_check_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #1 (Critical).
-- generate_routine_plan is SECURITY DEFINER with no auth.uid() = p_user_id
-- check, so any authenticated user can pass another user's UUID and
-- deactivate/overwrite their beauty routine plan.
BEGIN;
SELECT plan(3);

-- Seed two distinct test users (idempotent).
DO $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES
    ('00000000-0000-0000-0000-000000000101', 'routine-owner@akeli.test', 'authenticated', now(), now()),
    ('00000000-0000-0000-0000-000000000102', 'routine-attacker@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES
    ('00000000-0000-0000-0000-000000000101', true, false, now(), 'fr'),
    ('00000000-0000-0000-0000-000000000102', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;
END $$;

-- Act as the attacker (user 102) and attempt to generate/overwrite user 101's plan.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000102"}';

SELECT throws_ok(
  $$ SELECT generate_routine_plan('00000000-0000-0000-0000-000000000101'::uuid, 7) $$,
  'P0001',
  'Unauthorized',
  'generate_routine_plan rejects a caller passing a different user''s p_user_id'
);

-- Confirm no rogue plan row was inserted for the victim during the failed attempt.
SELECT is(
  (SELECT count(*)::int FROM meal_plan WHERE user_id = '00000000-0000-0000-0000-000000000101' AND mode = 'beauty'),
  0,
  'no beauty plan row was created for the victim by the unauthorized call'
);

-- Now act as the legitimate owner (user 101) — this must succeed.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000101"}';

SELECT lives_ok(
  $$ SELECT generate_routine_plan('00000000-0000-0000-0000-000000000101'::uuid, 7) $$,
  'generate_routine_plan succeeds when auth.uid() matches p_user_id'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase db reset; supabase test db supabase/tests/generate_routine_plan_auth_check_test.sql`

Expected (against the current buggy migration, which has no auth check at all): assertion 1 fails because no exception is raised (the attacker's call succeeds silently), assertion 2 fails because a plan row for the victim *was* created (count is `1`, not `0`), assertion 3 passes (the legitimate call always succeeds regardless of the bug):

```
not ok 1 - generate_routine_plan rejects a caller passing a different user's p_user_id
not ok 2 - no beauty plan row was created for the victim by the unauthorized call
ok 3 - generate_routine_plan succeeds when auth.uid() matches p_user_id
# Looks like you failed 2 tests of 3
Files=1, Tests=3, ...
Result: FAIL
```

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20260722090000_fix_generate_routine_plan_auth_check.sql`:

```sql
-- Migration: Restore missing auth.uid() authorization check in generate_routine_plan
-- File: supabase/migrations/20260722090000_fix_generate_routine_plan_auth_check.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #1 (Critical).
--
-- generate_routine_plan (20260720000001_beauty_mode_database_update.sql:90-126) is
-- SECURITY DEFINER with no auth.uid() = p_user_id check, so any authenticated user
-- can pass another user's UUID and deactivate/overwrite their beauty routine plan.
-- This restores the exact idiom already used correctly by recommend_recipes in the
-- same migration file (20260720000002_adapt_vector_rpcs_for_beauty_mode.sql:40):
--   IF auth.uid() IS DISTINCT FROM p_user_id THEN RAISE EXCEPTION 'Unauthorized'; END IF;
--
-- Signature is unchanged (uuid, integer), so CREATE OR REPLACE patches the existing
-- function in place without needing a DROP FUNCTION first.

CREATE OR REPLACE FUNCTION generate_routine_plan(
  p_user_id uuid,
  p_days integer DEFAULT 7
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan_id uuid;
  v_start_date date := CURRENT_DATE;
  v_end_date date := CURRENT_DATE + (p_days - 1);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Deactivate existing beauty plans for user
  UPDATE meal_plan
  SET is_active = false
  WHERE user_id = p_user_id AND mode = 'beauty' AND is_active = true;

  -- Create new beauty routine plan
  INSERT INTO meal_plan (
    user_id,
    start_date,
    end_date,
    is_active,
    mode
  ) VALUES (
    p_user_id,
    v_start_date,
    v_end_date,
    true,
    'beauty'
  )
  RETURNING id INTO v_plan_id;

  RETURN v_plan_id;
END;
$$;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `supabase db reset; supabase test db supabase/tests/generate_routine_plan_auth_check_test.sql`

Expected:

```
ok 1 - generate_routine_plan rejects a caller passing a different user's p_user_id
ok 2 - no beauty plan row was created for the victim by the unauthorized call
ok 3 - generate_routine_plan succeeds when auth.uid() matches p_user_id
Files=1, Tests=3, ...
Result: PASS
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260722090000_fix_generate_routine_plan_auth_check.sql supabase/tests/generate_routine_plan_auth_check_test.sql
git commit -m "fix(beauty): restore missing auth.uid() check in generate_routine_plan

Any authenticated user could pass another user's UUID and deactivate/
overwrite their beauty routine plan (SECURITY DEFINER with no ownership
check). Adds the same auth.uid() IS DISTINCT FROM p_user_id guard already
used correctly by recommend_recipes in the same original migration."
```

---

### Task 2: Restore `recommend_recipes` auth check, drop stale overloads, clamp similarity

**Files:**
- Create: `supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql`
- Test: `supabase/tests/recommend_recipes_auth_overloads_clamp_test.sql`

**Interfaces:**
- Produces: `recommend_recipes(p_user_id uuid, p_limit int DEFAULT 10, p_mode text DEFAULT NULL, p_beauty_type text DEFAULT NULL, p_beauty_sub_type text DEFAULT NULL, p_frequency text DEFAULT NULL) RETURNS TABLE(recipe_id uuid, title text, description text, mode text, beauty_type text, beauty_sub_type text, frequency text, similarity double precision)` — same signature `20260721000021_recommend_recipes_fan_mode.sql` shipped, now with the auth check restored and `similarity` clamped to `<= 1.0`. The two stale overloads `recommend_recipes(uuid,int,int,text,text,int,text)` (from `20260720000002`) and `recommend_recipes(uuid,int,int,text,text,int,text,text,text)` (from `20260720000008`) no longer exist after this migration.
- **Cross-plan note (informational, no action needed):** Area B's beauty-plan-generator RPCs (`20260721000008`, `000012`, `000019`, `000020`, `000022` — out of this plan's scope) call `recommend_recipes` with **named-parameter notation** and, in several call sites, only 3 of the 6 params (e.g. `recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)`). Before this task, with 3 overloads live, that call shape was ambiguous across all 3 candidates (a genuine live risk of Postgres raising `function recommend_recipes(...) is not unique`). After this task only one overload exists, so those calls resolve unambiguously. This task is a net fix for Area B's callers, not a breaking change, and those nested calls pass through the same `p_user_id` the outer (already-authorized) function received, so the new auth check does not break them.
- **Verification note (read during planning, not blindly trusted from the review):** `20260721000006_hybrid_virtue_masking_recommendations.sql` and `20260721000021_recommend_recipes_fan_mode.sql` both declare the *identical* argument type list `recommend_recipes(uuid, int, text, text, text, text)`, so `20260721000021`'s `CREATE OR REPLACE` replaced `20260721000006`'s function in place rather than creating a 4th distinct overload. There are therefore only **3** distinct overloads live today, not 4: the 7-arg version from `20260720000002`, the 9-arg version from `20260720000008`, and the 6-arg version whose current body comes from `20260721000021`. This migration drops the first two stale overloads and patches the third in place — 2 `DROP FUNCTION` statements, not 3.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/recommend_recipes_auth_overloads_clamp_test.sql`:

```sql
-- supabase/tests/recommend_recipes_auth_overloads_clamp_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Findings #2 (Critical),
-- #3 (High), #8 (Medium).
BEGIN;
SELECT plan(3);

-- Seed: legitimate owner, attacker, and a creator the owner fan-subscribes to,
-- plus a recipe/user vector pair with raw cosine similarity of exactly 1.0 so the
-- fan-mode 1.5x boost would push similarity to 1.5 if left unclamped.
DO $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES
    ('00000000-0000-0000-0000-000000000201', 'rr-owner@akeli.test', 'authenticated', now(), now()),
    ('00000000-0000-0000-0000-000000000202', 'rr-attacker@akeli.test', 'authenticated', now(), now()),
    ('00000000-0000-0000-0000-000000000203', 'rr-creator@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES
    ('00000000-0000-0000-0000-000000000201', true, false, now(), 'fr'),
    ('00000000-0000-0000-0000-000000000202', true, false, now(), 'fr'),
    ('00000000-0000-0000-0000-000000000203', true, true, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO creator (id, user_id, display_name)
  VALUES ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000203', 'RR Test Creator')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO fan_subscription (user_id, creator_id, status)
  VALUES ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', 'active')
  ON CONFLICT (user_id, status) DO NOTHING;

  INSERT INTO recipe (id, creator_id, title, instructions, is_published, mode)
  VALUES (
    '00000000-0000-0000-0000-000000000401',
    '00000000-0000-0000-0000-000000000301',
    'RR Test Fan Recipe',
    'Mix and apply.',
    true,
    'beauty'
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_vector (user_id, vector)
  VALUES (
    '00000000-0000-0000-0000-000000000201',
    ('[' || array_to_string(array_fill(0.42::numeric, ARRAY[50]), ',') || ']')::vector(50)
  )
  ON CONFLICT (user_id) DO UPDATE SET vector = EXCLUDED.vector;

  INSERT INTO recipe_vector (recipe_id, vector)
  VALUES (
    '00000000-0000-0000-0000-000000000401',
    ('[' || array_to_string(array_fill(0.42::numeric, ARRAY[50]), ',') || ']')::vector(50)
  )
  ON CONFLICT (recipe_id) DO UPDATE SET vector = EXCLUDED.vector;
END $$;

-- Assertion 1: an attacker cannot pull the owner's personalized recommendations.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000202"}';

SELECT throws_ok(
  $$ SELECT * FROM recommend_recipes('00000000-0000-0000-0000-000000000201'::uuid, 10, NULL, NULL, NULL, NULL) $$,
  'P0001',
  'Unauthorized',
  'recommend_recipes rejects a caller passing a different user''s p_user_id'
);

-- Assertion 2: only one recommend_recipes overload remains (no PGRST203-style risk).
SELECT is(
  (SELECT count(*)::int FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE p.proname = 'recommend_recipes' AND n.nspname = 'public'),
  1,
  'exactly one recommend_recipes overload exists after dropping the 2 stale signatures'
);

-- Assertion 3: fan-mode 1.5x boost is clamped to 1.0, not left at 1.5.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000201"}';

SELECT is(
  (SELECT similarity FROM recommend_recipes(
     '00000000-0000-0000-0000-000000000201'::uuid, 1000, NULL, NULL, NULL, NULL
   ) WHERE recipe_id = '00000000-0000-0000-0000-000000000401'::uuid),
  1.0::double precision,
  'fan-mode boosted similarity is clamped to 1.0 for an identical-vector, fan-subscribed-creator recipe'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase db reset; supabase test db supabase/tests/recommend_recipes_auth_overloads_clamp_test.sql`

Expected (against the current buggy migrations): assertion 1 fails (no exception raised, current function has no auth check), assertion 2 fails (3 overloads exist, not 1), assertion 3 fails (similarity is `1.5`, not `1.0`):

```
not ok 1 - recommend_recipes rejects a caller passing a different user's p_user_id
not ok 2 - exactly one recommend_recipes overload exists after dropping the 2 stale signatures
not ok 3 - fan-mode boosted similarity is clamped to 1.0 for an identical-vector, fan-subscribed-creator recipe
# Looks like you failed 3 tests of 3
Files=1, Tests=3, ...
Result: FAIL
```

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql`:

```sql
-- Migration: Restore missing auth.uid() check in recommend_recipes, drop the 2
-- stale overloads left behind by prior CREATE OR REPLACE drift, and clamp the
-- fan-mode similarity boost to <= 1.0.
-- File: supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Findings #2 (Critical),
-- #3 (High), #8 (Medium).
--
-- 20260721000006_hybrid_virtue_masking_recommendations.sql and
-- 20260721000021_recommend_recipes_fan_mode.sql both declare the identical
-- argument type list recommend_recipes(uuid, int, text, text, text, text), so
-- 20260721000021's CREATE OR REPLACE replaced 20260721000006's function in
-- place rather than creating a 4th distinct overload. There are therefore only
-- 3 distinct overloads live today: the 7-arg int/text mix from 20260720000002,
-- the 9-arg version from 20260720000008, and the 6-arg uuid/int/text version
-- whose current body comes from 20260721000021. This migration drops the first
-- two stale overloads and patches the third in place.

DROP FUNCTION IF EXISTS recommend_recipes(uuid, int, int, text, text, int, text);
DROP FUNCTION IF EXISTS recommend_recipes(uuid, int, int, text, text, int, text, text, text);

CREATE OR REPLACE FUNCTION recommend_recipes(
    p_user_id          UUID,
    p_limit            INT DEFAULT 10,
    p_mode             TEXT DEFAULT NULL,
    p_beauty_type      TEXT DEFAULT NULL,
    p_beauty_sub_type  TEXT DEFAULT NULL,
    p_frequency        TEXT DEFAULT NULL
)
RETURNS TABLE (
    recipe_id          UUID,
    title              TEXT,
    description        TEXT,
    mode               TEXT,
    beauty_type        TEXT,
    beauty_sub_type    TEXT,
    frequency          TEXT,
    similarity         DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_vector vector(50);
    v_fan_creator_id UUID;
BEGIN
    IF auth.uid() IS DISTINCT FROM p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    SELECT vector INTO v_user_vector
    FROM user_vector
    WHERE user_id = p_user_id;

    -- Check active Fan Subscription
    SELECT fs.creator_id INTO v_fan_creator_id
    FROM fan_subscription fs
    WHERE fs.user_id = p_user_id AND fs.status = 'active'
    LIMIT 1;

    IF v_user_vector IS NULL THEN
        RETURN QUERY
        SELECT
            r.id AS recipe_id,
            r.title::TEXT,
            r.description::TEXT,
            COALESCE(r.mode, 'nutrition')::TEXT AS mode,
            r.beauty_type::TEXT,
            r.beauty_sub_type::TEXT,
            r.frequency::TEXT,
            LEAST(
              (CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1.5 ELSE 1.0 END)::DOUBLE PRECISION,
              1.0::DOUBLE PRECISION
            ) AS similarity
        FROM recipe r
        WHERE r.is_published = TRUE
          AND (p_mode IS NULL OR r.mode = p_mode)
          AND (p_beauty_type IS NULL OR r.beauty_type = p_beauty_type OR r.beauty_type = 'both')
          AND (p_beauty_sub_type IS NULL OR r.beauty_sub_type = p_beauty_sub_type)
          AND (p_frequency IS NULL OR r.frequency = p_frequency)
        ORDER BY (CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1 ELSE 2 END) ASC, r.created_at DESC
        LIMIT p_limit;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        r.id AS recipe_id,
        r.title::TEXT,
        r.description::TEXT,
        COALESCE(r.mode, 'nutrition')::TEXT AS mode,
        r.beauty_type::TEXT,
        r.beauty_sub_type::TEXT,
        r.frequency::TEXT,
        LEAST(
          ((1.0 - (rv.vector <=> v_user_vector)) *
           (CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1.5 ELSE 1.0 END)
          )::DOUBLE PRECISION,
          1.0::DOUBLE PRECISION
        ) AS similarity
    FROM recipe r
    JOIN recipe_vector rv ON r.id = rv.recipe_id
    WHERE r.is_published = TRUE
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND (p_beauty_type IS NULL OR r.beauty_type = p_beauty_type OR r.beauty_type = 'both')
      AND (p_beauty_sub_type IS NULL OR r.beauty_sub_type = p_beauty_sub_type)
      AND (p_frequency IS NULL OR r.frequency = p_frequency)
    ORDER BY similarity DESC
    LIMIT p_limit;
END;
$$;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `supabase db reset; supabase test db supabase/tests/recommend_recipes_auth_overloads_clamp_test.sql`

Expected:

```
ok 1 - recommend_recipes rejects a caller passing a different user's p_user_id
ok 2 - exactly one recommend_recipes overload exists after dropping the 2 stale signatures
ok 3 - fan-mode boosted similarity is clamped to 1.0 for an identical-vector, fan-subscribed-creator recipe
Files=1, Tests=3, ...
Result: PASS
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql supabase/tests/recommend_recipes_auth_overloads_clamp_test.sql
git commit -m "fix(beauty): restore recommend_recipes auth check, drop stale overloads, clamp similarity

recommend_recipes's two most recent rewrites dropped the auth.uid() =
p_user_id check present in earlier versions, letting any user pull another
user's personalized (and beauty-diagnostic-revealing) recommendation
ranking. Also drops the 2 stale overloads left behind by prior
CREATE OR REPLACE drift (removing a live named-parameter-call ambiguity
risk) and clamps the fan-mode 1.5x similarity boost to <= 1.0."
```

---

### Task 3 (found during verification, not one of the original 8 findings): Restore missing `auth.uid()` check in `generate_feed_personalized`

While re-reading every function this area owns to get exact current signatures for Task 2, the same "auth check silently dropped across rewrites" pattern was found in a second function that the review's Area A section never mentions: `generate_feed_personalized`. Its original definition in `20260720000002_adapt_vector_rpcs_for_beauty_mode.sql:104-161` has the `auth.uid() IS DISTINCT FROM p_user_id` guard. `20260721000010_unify_feed_personalized_with_mode.sql` and `20260721000015_feed_beauty_filters.sql` (both owned by this area) each `DROP FUNCTION` the old overloads and `CREATE OR REPLACE` a new one — and neither carries the guard forward. This is the identical Critical-severity IDOR bug as Task 2, in a function squarely inside this area's file list, so it is fixed here rather than left unreported.

**Files:**
- Create: `supabase/migrations/20260722090200_fix_generate_feed_personalized_auth_check.sql`
- Test: `supabase/tests/generate_feed_personalized_auth_check_test.sql`

**Interfaces:**
- Produces: `generate_feed_personalized(p_user_id uuid, p_limit integer DEFAULT 20, p_exclude uuid[] DEFAULT '{}', p_region_id text DEFAULT NULL, p_difficulty text DEFAULT NULL, p_max_time_min integer DEFAULT NULL, p_min_cal numeric DEFAULT NULL, p_max_cal numeric DEFAULT NULL, p_order_by text DEFAULT NULL, p_meal_type text DEFAULT NULL, p_mode text DEFAULT NULL, p_product_type text DEFAULT NULL, p_routine_category text DEFAULT NULL, p_beauty_goal text DEFAULT NULL) RETURNS TABLE(recipe_id uuid, score numeric)` — same signature `20260721000015_feed_beauty_filters.sql` shipped, now with the auth check restored.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/generate_feed_personalized_auth_check_test.sql`:

```sql
-- supabase/tests/generate_feed_personalized_auth_check_test.sql
-- Fixes: bug found during Area A verification (not one of the review's original
-- 8 listed findings). generate_feed_personalized's auth.uid() = p_user_id check
-- was dropped by 20260721000010/20260721000015 the same way recommend_recipes's
-- was (Finding #2) — any user can pull another user's personalized feed.
BEGIN;
SELECT plan(2);

DO $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES
    ('00000000-0000-0000-0000-000000000501', 'gfp-owner@akeli.test', 'authenticated', now(), now()),
    ('00000000-0000-0000-0000-000000000502', 'gfp-attacker@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES
    ('00000000-0000-0000-0000-000000000501', true, false, now(), 'fr'),
    ('00000000-0000-0000-0000-000000000502', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;
END $$;

SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000502"}';

SELECT throws_ok(
  $$ SELECT * FROM generate_feed_personalized('00000000-0000-0000-0000-000000000501'::uuid, 20) $$,
  'P0001',
  'Unauthorized',
  'generate_feed_personalized rejects a caller passing a different user''s p_user_id'
);

SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000501"}';

SELECT lives_ok(
  $$ SELECT * FROM generate_feed_personalized('00000000-0000-0000-0000-000000000501'::uuid, 20) $$,
  'generate_feed_personalized succeeds when auth.uid() matches p_user_id'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase db reset; supabase test db supabase/tests/generate_feed_personalized_auth_check_test.sql`

Expected (against the current buggy migration): assertion 1 fails (no exception raised), assertion 2 passes (the call always succeeds regardless of the bug):

```
not ok 1 - generate_feed_personalized rejects a caller passing a different user's p_user_id
ok 2 - generate_feed_personalized succeeds when auth.uid() matches p_user_id
# Looks like you failed 1 test of 2
Files=1, Tests=2, ...
Result: FAIL
```

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20260722090200_fix_generate_feed_personalized_auth_check.sql`:

```sql
-- Migration: Restore missing auth.uid() authorization check in
-- generate_feed_personalized.
-- File: supabase/migrations/20260722090200_fix_generate_feed_personalized_auth_check.sql
-- Fixes: bug found during Area A verification (not one of the review's 8 listed
-- findings, but the same class of bug as Finding #2). The original definition in
-- 20260720000002_adapt_vector_rpcs_for_beauty_mode.sql:104 had the
-- auth.uid() = p_user_id guard; 20260721000010_unify_feed_personalized_with_mode.sql
-- and 20260721000015_feed_beauty_filters.sql each DROP FUNCTION + CREATE OR REPLACE
-- a new version and neither carries the guard forward.
--
-- Signature is unchanged from 20260721000015, so this is a straight CREATE OR
-- REPLACE with the auth check inserted at the top of the body; every other line
-- of logic is preserved verbatim.

CREATE OR REPLACE FUNCTION public.generate_feed_personalized(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_exclude UUID[] DEFAULT '{}'::UUID[],
    p_region_id TEXT DEFAULT NULL::TEXT,
    p_difficulty TEXT DEFAULT NULL::TEXT,
    p_max_time_min INTEGER DEFAULT NULL::INTEGER,
    p_min_cal NUMERIC DEFAULT NULL::NUMERIC,
    p_max_cal NUMERIC DEFAULT NULL::NUMERIC,
    p_order_by TEXT DEFAULT NULL::TEXT,
    p_meal_type TEXT DEFAULT NULL::TEXT,
    p_mode TEXT DEFAULT NULL::TEXT,
    p_product_type TEXT DEFAULT NULL::TEXT,
    p_routine_category TEXT DEFAULT NULL::TEXT,
    p_beauty_goal TEXT DEFAULT NULL::TEXT
)
RETURNS TABLE (
    recipe_id UUID,
    score NUMERIC
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
AS $$
DECLARE
    v_user_vector vector(50);
BEGIN
    IF auth.uid() IS DISTINCT FROM p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    SELECT uv.vector INTO v_user_vector
    FROM user_vector uv WHERE uv.user_id = p_user_id;

    IF v_user_vector IS NULL THEN
        RETURN QUERY
        SELECT r.id AS recipe_id, 0.5::numeric AS score
        FROM recipe r
        WHERE r.is_published = true
          AND r.is_private = false
          AND (p_mode IS NULL OR r.mode = p_mode)
          AND (p_region_id IS NULL OR r.region = p_region_id)
          AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
          AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
          AND (p_product_type IS NULL OR r.product_type = p_product_type)
          AND (p_routine_category IS NULL OR r.beauty_type = p_routine_category OR r.beauty_sub_type = p_routine_category)
          AND (p_beauty_goal IS NULL OR (r.virtue_weights IS NOT NULL AND (r.virtue_weights->>p_beauty_goal)::numeric > 0))
          AND r.id <> ALL(p_exclude)
        ORDER BY r.created_at DESC
        LIMIT LEAST(p_limit, 200);
        RETURN;
    END IF;

    RETURN QUERY
    WITH user_allergens AS (
        SELECT COALESCE(array_agg(a.slug), '{}') AS tags
        FROM user_allergy ua
        JOIN allergen a ON a.id = ua.allergen_id
        WHERE ua.user_id = p_user_id
    )
    SELECT
        r.id AS recipe_id,
        (1 - (rv.vector <=> v_user_vector))::numeric AS score
    FROM recipe r
    JOIN recipe_vector rv ON rv.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND (p_mode IS NULL OR r.mode = p_mode)
      AND (p_region_id IS NULL OR r.region = p_region_id)
      AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
      AND (p_max_time_min IS NULL OR r.total_time_min <= p_max_time_min)
      AND (p_product_type IS NULL OR r.product_type = p_product_type)
      AND (p_routine_category IS NULL OR r.beauty_type = p_routine_category OR r.beauty_sub_type = p_routine_category)
      AND (p_beauty_goal IS NULL OR (r.virtue_weights IS NOT NULL AND (r.virtue_weights->>p_beauty_goal)::numeric > 0))
      AND r.id <> ALL(p_exclude)
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
    ORDER BY score DESC
    LIMIT LEAST(p_limit, 200);
END;
$$;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `supabase db reset; supabase test db supabase/tests/generate_feed_personalized_auth_check_test.sql`

Expected:

```
ok 1 - generate_feed_personalized rejects a caller passing a different user's p_user_id
ok 2 - generate_feed_personalized succeeds when auth.uid() matches p_user_id
Files=1, Tests=2, ...
Result: PASS
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260722090200_fix_generate_feed_personalized_auth_check.sql supabase/tests/generate_feed_personalized_auth_check_test.sql
git commit -m "fix(beauty): restore missing auth.uid() check in generate_feed_personalized

Found while verifying Task 2's fix: generate_feed_personalized's auth
check was dropped by the same DROP-FUNCTION-then-recreate pattern as
recommend_recipes, letting any user pull another user's personalized
feed. Not called out in the branch review's Area A section, but same
severity and squarely in this area's owned files."
```

---

### Task 4: De-duplicate `ingredient` rows for the 9 re-inserted `active_key`s and add a UNIQUE constraint

**Files:**
- Create: `supabase/migrations/20260722090300_dedupe_ingredient_active_key_and_constraint.sql`
- Test: `supabase/tests/ingredient_active_key_dedup_test.sql`

**Interfaces:**
- Produces: `ingredient(active_key)` now has a `UNIQUE` constraint named `ingredient_active_key_unique` (NULLs, used by all non-beauty ingredients, remain unaffected — Postgres UNIQUE permits multiple NULLs). Any future `INSERT ... ON CONFLICT (active_key) DO ...` becomes a real, meaningful conflict target.
- **Verified side-effect also fixed here:** `20260720000012_beauty_recipe_ingredients_steps_and_translations.sql` links recipe ingredients via `JOIN ingredient i ON i.active_key = '<key>'`, which fans out across both duplicate rows and inserts the same conceptual line item twice per recipe (e.g. recipe `b0000001` currently has 2 `recipe_ingredient` rows for `shea_butter`). Step 2 below collapses those duplicate line items as part of this same migration, since the review describes this fan-out as part of Finding #5 itself, not a separate issue.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/ingredient_active_key_dedup_test.sql`:

```sql
-- supabase/tests/ingredient_active_key_dedup_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #5 (Medium/High).
-- ingredient has no UNIQUE constraint on active_key, so ON CONFLICT DO NOTHING in
-- 20260720000009_extensive_ingredient_seed_catalog.sql was a no-op against rows
-- already inserted by 20260720000005_ingredient_virtues_micronutrients.sql for the
-- same 9 active_keys, producing duplicate ingredient rows (and, via
-- 20260720000012's `JOIN ingredient ON active_key = '<key>'` linking pattern,
-- duplicate recipe_ingredient line items too).
BEGIN;
SELECT plan(12);

SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'shea_butter'), 1, 'exactly one shea_butter ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'chebe'), 1, 'exactly one chebe ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'aloe_vera'), 1, 'exactly one aloe_vera ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'black_seed'), 1, 'exactly one black_seed ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'argan'), 1, 'exactly one argan ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'ricin'), 1, 'exactly one ricin ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'hibiscus'), 1, 'exactly one hibiscus ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'clay'), 1, 'exactly one clay ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'jojoba'), 1, 'exactly one jojoba ingredient row remains');

-- The kept row is the more complete copy (20260720000009's insert has a superset
-- of beauty_virtues vs. 20260720000005's original — e.g. shea_butter gained
-- 'protective_care').
SELECT ok(
  (SELECT bool_or('protective_care' = ANY(beauty_virtues)) FROM ingredient WHERE active_key = 'shea_butter'),
  'the shea_butter row that survives has protective_care in beauty_virtues'
);

-- A real UNIQUE constraint on active_key now exists.
SELECT ok(
  EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'ingredient'
      AND constraint_name = 'ingredient_active_key_unique'
      AND constraint_type = 'UNIQUE'
  ),
  'ingredient_active_key_unique UNIQUE constraint exists on ingredient(active_key)'
);

-- The fan-out into duplicate recipe_ingredient line items is also collapsed.
SELECT is(
  (SELECT count(*)::int FROM recipe_ingredient ri
   JOIN ingredient i ON i.id = ri.ingredient_id
   WHERE ri.recipe_id = 'b0000001-0000-0000-0000-000000000001'::uuid
     AND i.active_key = 'shea_butter'),
  1,
  'recipe b0000001 has exactly one shea_butter line item, not a duplicate'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase db reset; supabase test db supabase/tests/ingredient_active_key_dedup_test.sql`

Expected (against the current buggy migrations, where duplicates already exist because `20260720000005` and `20260720000009` both ran): the 9 count checks fail (each active_key currently has 2 rows), the `bool_or` completeness check passes (at least one of the 2 existing duplicates already has `protective_care`), the constraint-exists check fails, and the `recipe_ingredient` dedup check fails (2 line items, not 1):

```
not ok 1 - exactly one shea_butter ingredient row remains
not ok 2 - exactly one chebe ingredient row remains
not ok 3 - exactly one aloe_vera ingredient row remains
not ok 4 - exactly one black_seed ingredient row remains
not ok 5 - exactly one argan ingredient row remains
not ok 6 - exactly one ricin ingredient row remains
not ok 7 - exactly one hibiscus ingredient row remains
not ok 8 - exactly one clay ingredient row remains
not ok 9 - exactly one jojoba ingredient row remains
ok 10 - the shea_butter row that survives has protective_care in beauty_virtues
not ok 11 - ingredient_active_key_unique UNIQUE constraint exists on ingredient(active_key)
not ok 12 - recipe b0000001 has exactly one shea_butter line item, not a duplicate
# Looks like you failed 11 tests of 12
Files=1, Tests=12, ...
Result: FAIL
```

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20260722090300_dedupe_ingredient_active_key_and_constraint.sql`:

```sql
-- Migration: De-duplicate ingredient rows for the 9 beauty active_keys re-inserted
-- by 20260720000009_extensive_ingredient_seed_catalog.sql (ON CONFLICT DO NOTHING
-- was a no-op because ingredient has no UNIQUE constraint on active_key), collapse
-- the resulting duplicate recipe_ingredient line items, then add a real UNIQUE
-- constraint so this cannot recur.
-- File: supabase/migrations/20260722090300_dedupe_ingredient_active_key_and_constraint.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #5 (Medium/High).

-- Step 1: reassign recipe_ingredient rows pointing at a duplicate (to-be-deleted)
-- ingredient row over to the row we are keeping for that active_key. We keep the
-- most recently inserted row per active_key (20260720000009's copy, which carries
-- a superset of beauty_virtues vs. 20260720000005's original insert — e.g.
-- shea_butter/chebe/ricin gain 'protective_care', black_seed/argan/clay gain
-- 'glow_brightening', jojoba gains 'scalp_soothing'); ties broken by id descending
-- for determinism.
WITH ranked AS (
  SELECT
    id,
    active_key,
    ROW_NUMBER() OVER (
      PARTITION BY active_key
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM ingredient
  WHERE active_key IN (
    'shea_butter', 'chebe', 'aloe_vera', 'black_seed',
    'argan', 'ricin', 'hibiscus', 'clay', 'jojoba'
  )
),
keepers AS (
  SELECT active_key, id AS keep_id FROM ranked WHERE rn = 1
),
duplicates AS (
  SELECT r.id AS dup_id, k.keep_id
  FROM ranked r
  JOIN keepers k ON k.active_key = r.active_key
  WHERE r.rn > 1
)
UPDATE recipe_ingredient ri
SET ingredient_id = d.keep_id
FROM duplicates d
WHERE ri.ingredient_id = d.dup_id;

-- Step 2: 20260720000012_beauty_recipe_ingredients_steps_and_translations.sql
-- links recipe ingredients via `JOIN ingredient i ON i.active_key = '<key>'`,
-- which fanned out across both duplicate ingredient rows and inserted the same
-- conceptual line item twice per recipe. After the reassignment above, those
-- pairs are now identical (recipe_id, ingredient_id) rows — collapse them,
-- keeping the lowest id.
WITH dup_lines AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY recipe_id, ingredient_id
      ORDER BY id
    ) AS rn
  FROM recipe_ingredient
  WHERE ingredient_id IN (
    SELECT id FROM ingredient WHERE active_key IN (
      'shea_butter', 'chebe', 'aloe_vera', 'black_seed',
      'argan', 'ricin', 'hibiscus', 'clay', 'jojoba'
    )
  )
)
DELETE FROM recipe_ingredient
USING dup_lines
WHERE recipe_ingredient.id = dup_lines.id
  AND dup_lines.rn > 1;

-- Step 3: delete the now-unreferenced duplicate ingredient rows.
WITH ranked AS (
  SELECT
    id,
    active_key,
    ROW_NUMBER() OVER (
      PARTITION BY active_key
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM ingredient
  WHERE active_key IN (
    'shea_butter', 'chebe', 'aloe_vera', 'black_seed',
    'argan', 'ricin', 'hibiscus', 'clay', 'jojoba'
  )
)
DELETE FROM ingredient
USING ranked
WHERE ingredient.id = ranked.id
  AND ranked.rn > 1;

-- Step 4: add a real UNIQUE constraint on active_key so ON CONFLICT (active_key)
-- becomes meaningful and this class of duplicate can't recur. NULLs (nutrition
-- ingredients with no active_key) are unaffected — Postgres UNIQUE allows
-- multiple NULLs. Guarded idempotently, matching the existence-check idiom
-- already used for CREATE POLICY in 20260522000001_create_sdui_layouts.sql.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'ingredient'
      AND constraint_name = 'ingredient_active_key_unique'
  ) THEN
    ALTER TABLE ingredient
      ADD CONSTRAINT ingredient_active_key_unique UNIQUE (active_key);
  END IF;
END $$;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `supabase db reset; supabase test db supabase/tests/ingredient_active_key_dedup_test.sql`

Expected:

```
ok 1 - exactly one shea_butter ingredient row remains
ok 2 - exactly one chebe ingredient row remains
ok 3 - exactly one aloe_vera ingredient row remains
ok 4 - exactly one black_seed ingredient row remains
ok 5 - exactly one argan ingredient row remains
ok 6 - exactly one ricin ingredient row remains
ok 7 - exactly one hibiscus ingredient row remains
ok 8 - exactly one clay ingredient row remains
ok 9 - exactly one jojoba ingredient row remains
ok 10 - the shea_butter row that survives has protective_care in beauty_virtues
ok 11 - ingredient_active_key_unique UNIQUE constraint exists on ingredient(active_key)
ok 12 - recipe b0000001 has exactly one shea_butter line item, not a duplicate
Files=1, Tests=12, ...
Result: PASS
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260722090300_dedupe_ingredient_active_key_and_constraint.sql supabase/tests/ingredient_active_key_dedup_test.sql
git commit -m "fix(beauty): dedupe ingredient rows for 9 active_keys, add UNIQUE constraint

20260720000009's ON CONFLICT DO NOTHING was a no-op against rows already
inserted by 20260720000005 for the same 9 active_keys (no UNIQUE
constraint existed to arbitrate). Reassigns recipe_ingredient references
to the surviving (more complete) row, collapses the duplicate line items
this fan-out produced on recipe b0000001+, deletes the stale duplicates,
and adds a real UNIQUE constraint on ingredient(active_key) so it can't
recur."
```

---

### Task 5: Re-merge virtue-weight keys discarded by the standardization overwrite

**Files:**
- Create: `supabase/migrations/20260722090400_restore_lost_ingredient_virtue_weights.sql`
- Test: `supabase/tests/restore_lost_ingredient_virtue_weights_test.sql`

**Interfaces:**
- Produces: no signature changes. `ingredient.virtue_weights` / `ingredient.skin_virtue_weights` JSONB payloads for the 9 active_keys (`shea_butter`, `chebe`, `aloe_vera`, `black_seed`, `argan`, `ricin`, `hibiscus`, `clay`, `jojoba`) now contain the union of every key ever set for them by `20260720000006`/`20260720000007` and `20260721000004`, instead of only the latter's overwritten subset.
- Depends on Task 4 having already run (so each `WHERE active_key = 'x'` below touches exactly the one surviving row per key, not two duplicates).

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/restore_lost_ingredient_virtue_weights_test.sql`:

```sql
-- supabase/tests/restore_lost_ingredient_virtue_weights_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #6 (Medium).
-- 20260721000004_standardize_ingredient_virtue_vectors.sql does a full
-- virtue_weights/skin_virtue_weights JSONB replace for these 9 ingredients,
-- silently discarding keys set by 20260720000006/20260720000007.
BEGIN;
SELECT plan(25);

-- 1. Shea Butter: restored virtue_weights key, preserved current key, restored skin key.
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'shea_butter'), 0.40::numeric, 'shea_butter: growth_retention restored');
SELECT is((SELECT (virtue_weights->>'intense_hydration')::numeric FROM ingredient WHERE active_key = 'shea_butter'), 0.95::numeric, 'shea_butter: intense_hydration (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'dry_skin_moisture')::numeric FROM ingredient WHERE active_key = 'shea_butter'), 0.90::numeric, 'shea_butter: dry_skin_moisture (skin) restored');

-- 2. Chébé: restored virtue_weights key, preserved current key (no skin data existed before).
SELECT is((SELECT (virtue_weights->>'moisture')::numeric FROM ingredient WHERE active_key = 'chebe'), 0.35::numeric, 'chebe: moisture restored');
SELECT is((SELECT (virtue_weights->>'anti_breakage')::numeric FROM ingredient WHERE active_key = 'chebe'), 0.95::numeric, 'chebe: anti_breakage (current) preserved');

-- 3. Aloé Véra
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'aloe_vera'), 0.50::numeric, 'aloe_vera: growth_retention restored');
SELECT is((SELECT (virtue_weights->>'intense_hydration')::numeric FROM ingredient WHERE active_key = 'aloe_vera'), 0.95::numeric, 'aloe_vera: intense_hydration (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'dry_skin_moisture')::numeric FROM ingredient WHERE active_key = 'aloe_vera'), 0.95::numeric, 'aloe_vera: dry_skin_moisture (skin) restored');

-- 4. Black Seed / Nigelle
SELECT is((SELECT (virtue_weights->>'sebum_balance')::numeric FROM ingredient WHERE active_key = 'black_seed'), 0.90::numeric, 'black_seed: sebum_balance restored');
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'black_seed'), 0.85::numeric, 'black_seed: growth_retention (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'oily_acne_sebum')::numeric FROM ingredient WHERE active_key = 'black_seed'), 0.95::numeric, 'black_seed: oily_acne_sebum (skin) restored');

-- 5. Argan Oil
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'argan'), 0.50::numeric, 'argan: growth_retention restored');
SELECT is((SELECT (virtue_weights->>'shine_softness')::numeric FROM ingredient WHERE active_key = 'argan'), 0.95::numeric, 'argan: shine_softness (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'dry_skin_moisture')::numeric FROM ingredient WHERE active_key = 'argan'), 0.85::numeric, 'argan: dry_skin_moisture (skin) restored');

-- 6. Castor Oil (Ricin) — no skin data existed before.
SELECT is((SELECT (virtue_weights->>'moisture')::numeric FROM ingredient WHERE active_key = 'ricin'), 0.50::numeric, 'ricin: moisture restored');
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'ricin'), 0.95::numeric, 'ricin: growth_retention (current) preserved');

-- 7. Hibiscus / Karkadé
SELECT is((SELECT (virtue_weights->>'glow_brightening')::numeric FROM ingredient WHERE active_key = 'hibiscus'), 0.90::numeric, 'hibiscus: glow_brightening restored');
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'hibiscus'), 0.80::numeric, 'hibiscus: growth_retention (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'brightening_anti_spots')::numeric FROM ingredient WHERE active_key = 'hibiscus'), 0.95::numeric, 'hibiscus: brightening_anti_spots (skin) restored');

-- 8. Green / White Clay (Argile)
SELECT is((SELECT (virtue_weights->>'sebum_balance')::numeric FROM ingredient WHERE active_key = 'clay'), 1.00::numeric, 'clay: sebum_balance restored');
SELECT is((SELECT (virtue_weights->>'scalp_detox')::numeric FROM ingredient WHERE active_key = 'clay'), 0.95::numeric, 'clay: scalp_detox (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'oily_acne_sebum')::numeric FROM ingredient WHERE active_key = 'clay'), 1.00::numeric, 'clay: oily_acne_sebum (skin) restored');

-- 9. Jojoba Oil
SELECT is((SELECT (virtue_weights->>'sebum_balance')::numeric FROM ingredient WHERE active_key = 'jojoba'), 0.90::numeric, 'jojoba: sebum_balance restored');
SELECT is((SELECT (virtue_weights->>'scalp_soothing')::numeric FROM ingredient WHERE active_key = 'jojoba'), 0.85::numeric, 'jojoba: scalp_soothing (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'oily_acne_sebum')::numeric FROM ingredient WHERE active_key = 'jojoba'), 0.90::numeric, 'jojoba: oily_acne_sebum (skin) restored');

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase db reset; supabase test db supabase/tests/restore_lost_ingredient_virtue_weights_test.sql`

Expected (against the current buggy migrations, applied after Task 4's dedup fix is already in place from the previous task): every "restored" key assertion fails because the key is currently absent (`NULL`) from the overwritten JSONB; every "preserved current key" assertion already passes since Task 5 hasn't touched anything yet:

```
not ok 1 - shea_butter: growth_retention restored
ok 2 - shea_butter: intense_hydration (current) preserved
not ok 3 - shea_butter: dry_skin_moisture (skin) restored
not ok 4 - chebe: moisture restored
ok 5 - chebe: anti_breakage (current) preserved
not ok 6 - aloe_vera: growth_retention restored
ok 7 - aloe_vera: intense_hydration (current) preserved
not ok 8 - aloe_vera: dry_skin_moisture (skin) restored
not ok 9 - black_seed: sebum_balance restored
ok 10 - black_seed: growth_retention (current) preserved
not ok 11 - black_seed: oily_acne_sebum (skin) restored
not ok 12 - argan: growth_retention restored
ok 13 - argan: shine_softness (current) preserved
not ok 14 - argan: dry_skin_moisture (skin) restored
not ok 15 - ricin: moisture restored
ok 16 - ricin: growth_retention (current) preserved
not ok 17 - hibiscus: glow_brightening restored
ok 18 - hibiscus: growth_retention (current) preserved
not ok 19 - hibiscus: brightening_anti_spots (skin) restored
not ok 20 - clay: sebum_balance restored
ok 21 - clay: scalp_detox (current) preserved
not ok 22 - clay: oily_acne_sebum (skin) restored
not ok 23 - jojoba: sebum_balance restored
ok 24 - jojoba: scalp_soothing (current) preserved
not ok 25 - jojoba: oily_acne_sebum (skin) restored
# Looks like you failed 16 tests of 25
Files=1, Tests=25, ...
Result: FAIL
```

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20260722090400_restore_lost_ingredient_virtue_weights.sql`:

```sql
-- Migration: Re-merge virtue_weights/skin_virtue_weights keys that
-- 20260721000004_standardize_ingredient_virtue_vectors.sql silently discarded via
-- a full-object overwrite instead of a merge, for the 9 beauty ingredients it
-- touched. Values below are the exact originals from
-- 20260720000006_ingredient_virtue_weight_vectors.sql (virtue_weights) and
-- 20260720000007_ingredient_skin_virtue_vectors.sql (skin_virtue_weights),
-- restricted to keys whose names do not already exist in the post-20260721000004
-- objects (keys present in both, e.g. shea_butter's anti_breakage, are left at
-- their current value — only missing keys are re-added).
-- File: supabase/migrations/20260722090400_restore_lost_ingredient_virtue_weights.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #6 (Medium).
--
-- Runs after Task 4's dedup, so each UPDATE ... WHERE active_key = 'x' below
-- touches exactly the one surviving row per active_key.

-- 1. Shea Butter (Karité)
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"moisture": 0.90, "growth_retention": 0.40, "scalp_soothing": 0.40, "sebum_balance": 0.10, "glow_brightening": 0.20}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"dry_skin_moisture": 0.90, "barrier_repair": 0.95, "anti_aging_elasticity": 0.75, "sensitive_skin_soothing": 0.60, "oily_acne_sebum": 0.10}'::jsonb
WHERE active_key = 'shea_butter';

-- 2. Chébé (no 20260720000007 skin data existed for chebe)
UPDATE ingredient
SET virtue_weights = virtue_weights || '{"moisture": 0.35, "scalp_soothing": 0.20, "sebum_balance": 0.10, "glow_brightening": 0.10}'::jsonb
WHERE active_key = 'chebe';

-- 3. Aloé Véra
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"moisture": 0.95, "glow_brightening": 0.75, "growth_retention": 0.50, "sebum_balance": 0.50, "anti_breakage": 0.30, "protective_care": 0.60}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"dry_skin_moisture": 0.95, "sensitive_skin_soothing": 0.90, "brightening_anti_spots": 0.75, "barrier_repair": 0.80, "anti_aging_elasticity": 0.60}'::jsonb
WHERE active_key = 'aloe_vera';

-- 4. Black Seed / Nigelle
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"sebum_balance": 0.90, "glow_brightening": 0.65, "moisture": 0.30, "anti_breakage": 0.50, "protective_care": 0.40}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"oily_acne_sebum": 0.95, "sensitive_skin_soothing": 0.85, "brightening_anti_spots": 0.70, "barrier_repair": 0.60, "dry_skin_moisture": 0.30}'::jsonb
WHERE active_key = 'black_seed';

-- 5. Argan Oil
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"moisture": 0.85, "growth_retention": 0.50, "glow_brightening": 0.60, "scalp_soothing": 0.40, "sebum_balance": 0.40, "protective_care": 0.50}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"dry_skin_moisture": 0.85, "barrier_repair": 0.80, "brightening_anti_spots": 0.60}'::jsonb
WHERE active_key = 'argan';

-- 6. Castor Oil (Ricin) (no 20260720000007 skin data existed for ricin)
UPDATE ingredient
SET virtue_weights = virtue_weights || '{"moisture": 0.50, "scalp_soothing": 0.45, "protective_care": 0.50, "glow_brightening": 0.30, "sebum_balance": 0.20}'::jsonb
WHERE active_key = 'ricin';

-- 7. Hibiscus / Karkadé
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"glow_brightening": 0.90, "anti_breakage": 0.50, "moisture": 0.40, "sebum_balance": 0.40, "scalp_soothing": 0.30, "protective_care": 0.30}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"brightening_anti_spots": 0.95, "anti_aging_elasticity": 0.80, "dry_skin_moisture": 0.50, "sensitive_skin_soothing": 0.40}'::jsonb
WHERE active_key = 'hibiscus';

-- 8. Green / White Clay (Argile)
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"sebum_balance": 1.00, "glow_brightening": 0.50, "moisture": 0.10, "anti_breakage": 0.20, "growth_retention": 0.20, "protective_care": 0.20}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"oily_acne_sebum": 1.00, "sensitive_skin_soothing": 0.60, "brightening_anti_spots": 0.50, "dry_skin_moisture": 0.10}'::jsonb
WHERE active_key = 'clay';

-- 9. Jojoba Oil
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"sebum_balance": 0.90, "protective_care": 0.85, "moisture": 0.60, "glow_brightening": 0.50, "growth_retention": 0.40, "anti_breakage": 0.40}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"oily_acne_sebum": 0.90, "barrier_repair": 0.85, "dry_skin_moisture": 0.70, "sensitive_skin_soothing": 0.60}'::jsonb
WHERE active_key = 'jojoba';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `supabase db reset; supabase test db supabase/tests/restore_lost_ingredient_virtue_weights_test.sql`

Expected:

```
ok 1 - shea_butter: growth_retention restored
ok 2 - shea_butter: intense_hydration (current) preserved
ok 3 - shea_butter: dry_skin_moisture (skin) restored
ok 4 - chebe: moisture restored
ok 5 - chebe: anti_breakage (current) preserved
ok 6 - aloe_vera: growth_retention restored
ok 7 - aloe_vera: intense_hydration (current) preserved
ok 8 - aloe_vera: dry_skin_moisture (skin) restored
ok 9 - black_seed: sebum_balance restored
ok 10 - black_seed: growth_retention (current) preserved
ok 11 - black_seed: oily_acne_sebum (skin) restored
ok 12 - argan: growth_retention restored
ok 13 - argan: shine_softness (current) preserved
ok 14 - argan: dry_skin_moisture (skin) restored
ok 15 - ricin: moisture restored
ok 16 - ricin: growth_retention (current) preserved
ok 17 - hibiscus: glow_brightening restored
ok 18 - hibiscus: growth_retention (current) preserved
ok 19 - hibiscus: brightening_anti_spots (skin) restored
ok 20 - clay: sebum_balance restored
ok 21 - clay: scalp_detox (current) preserved
ok 22 - clay: oily_acne_sebum (skin) restored
ok 23 - jojoba: sebum_balance restored
ok 24 - jojoba: scalp_soothing (current) preserved
ok 25 - jojoba: oily_acne_sebum (skin) restored
Files=1, Tests=25, ...
Result: PASS
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260722090400_restore_lost_ingredient_virtue_weights.sql supabase/tests/restore_lost_ingredient_virtue_weights_test.sql
git commit -m "fix(beauty): re-merge virtue_weights/skin_virtue_weights keys lost to overwrite

20260721000004_standardize_ingredient_virtue_vectors.sql fully replaced
(rather than merged) virtue_weights/skin_virtue_weights for 9 ingredients,
silently discarding keys set by 20260720000006/20260720000007 (e.g. shea
butter lost growth_retention, scalp_soothing, sebum_balance,
glow_brightening, and its entire prior skin_virtue_weights object). Merges
every lost key back in via jsonb || without touching any key the
standardization migration intentionally set."
```

---

### Task 6: Set `search_path` on every `SECURITY DEFINER` function in this area

**Files:**
- Create: `supabase/migrations/20260722090500_set_search_path_beauty_vector_functions.sql`
- Test: `supabase/tests/beauty_vector_functions_search_path_test.sql`

**Interfaces:**
- Produces: no signature or behavior changes; all 6 `SECURITY DEFINER` functions in this area's owned files now have `search_path` pinned to `public, pg_temp`.
- Consumes: the final, current signatures produced by Tasks 1–3 (`generate_routine_plan`, `recommend_recipes`, `generate_feed_personalized`) — this task must run last so its `ALTER FUNCTION` statements resolve against each function's post-fix argument-type list.
- The 6 functions covered (with their exact current argument-type lists, enumerated by reading every file this area owns): `generate_routine_plan(uuid, integer)`, `recommend_recipes(uuid, integer, text, text, text, text)`, `search_recipes(text, text, text, integer, text, integer, integer)`, `generate_feed_personalized(uuid, integer, uuid[], text, text, integer, numeric, numeric, text, text, text, text, text, text)`, `generate_feed_exploration(uuid, integer, uuid[], text)`, `compute_recipe_virtues(uuid)`.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/beauty_vector_functions_search_path_test.sql`:

```sql
-- supabase/tests/beauty_vector_functions_search_path_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #7 (Medium).
-- No SECURITY DEFINER function in this area sets search_path, which is the
-- Postgres/Supabase linter's function_search_path_mutable risk. Existing
-- project precedent: 20260603000001_fix_generate_meal_plan_security_definer.sql.
BEGIN;
SELECT plan(6);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'generate_routine_plan' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'generate_routine_plan has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'recommend_recipes' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'recommend_recipes has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'search_recipes' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'search_recipes has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'generate_feed_personalized' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'generate_feed_personalized has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'generate_feed_exploration' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'generate_feed_exploration has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'compute_recipe_virtues' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'compute_recipe_virtues has search_path pinned to public, pg_temp'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase db reset; supabase test db supabase/tests/beauty_vector_functions_search_path_test.sql`

Expected (against the current migrations, none of which set `search_path`, so `p.proconfig` is `NULL` for all 6 functions and `unnest(NULL)` yields zero rows):

```
not ok 1 - generate_routine_plan has search_path pinned to public, pg_temp
not ok 2 - recommend_recipes has search_path pinned to public, pg_temp
not ok 3 - search_recipes has search_path pinned to public, pg_temp
not ok 4 - generate_feed_personalized has search_path pinned to public, pg_temp
not ok 5 - generate_feed_exploration has search_path pinned to public, pg_temp
not ok 6 - compute_recipe_virtues has search_path pinned to public, pg_temp
# Looks like you failed 6 tests of 6
Files=1, Tests=6, ...
Result: FAIL
```

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20260722090500_set_search_path_beauty_vector_functions.sql`:

```sql
-- Migration: Set a fixed search_path on every SECURITY DEFINER function in the
-- Beauty Mode vector/recommendation area, closing the Postgres/Supabase linter's
-- function_search_path_mutable finding. Exact syntax matches the project's
-- existing precedent in 20260603000001_fix_generate_meal_plan_security_definer.sql
-- (SECURITY DEFINER SET search_path = public, pg_temp).
-- File: supabase/migrations/20260722090500_set_search_path_beauty_vector_functions.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #7 (Medium).
--
-- Run after Tasks 1-3 so every ALTER FUNCTION below targets each function's
-- final, current argument-type signature.

ALTER FUNCTION generate_routine_plan(uuid, integer) SET search_path = public, pg_temp;
ALTER FUNCTION recommend_recipes(uuid, integer, text, text, text, text) SET search_path = public, pg_temp;
ALTER FUNCTION search_recipes(text, text, text, integer, text, integer, integer) SET search_path = public, pg_temp;
ALTER FUNCTION generate_feed_personalized(uuid, integer, uuid[], text, text, integer, numeric, numeric, text, text, text, text, text, text) SET search_path = public, pg_temp;
ALTER FUNCTION generate_feed_exploration(uuid, integer, uuid[], text) SET search_path = public, pg_temp;
ALTER FUNCTION compute_recipe_virtues(uuid) SET search_path = public, pg_temp;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `supabase db reset; supabase test db supabase/tests/beauty_vector_functions_search_path_test.sql`

Expected:

```
ok 1 - generate_routine_plan has search_path pinned to public, pg_temp
ok 2 - recommend_recipes has search_path pinned to public, pg_temp
ok 3 - search_recipes has search_path pinned to public, pg_temp
ok 4 - generate_feed_personalized has search_path pinned to public, pg_temp
ok 5 - generate_feed_exploration has search_path pinned to public, pg_temp
ok 6 - compute_recipe_virtues has search_path pinned to public, pg_temp
Files=1, Tests=6, ...
Result: PASS
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260722090500_set_search_path_beauty_vector_functions.sql supabase/tests/beauty_vector_functions_search_path_test.sql
git commit -m "fix(beauty): pin search_path on every SECURITY DEFINER vector/recommendation fn

Closes the function_search_path_mutable linter finding for the 6
SECURITY DEFINER functions in the Beauty Mode vector engine area
(generate_routine_plan, recommend_recipes, search_recipes,
generate_feed_personalized, generate_feed_exploration,
compute_recipe_virtues), matching the SET search_path = public, pg_temp
precedent already established in
20260603000001_fix_generate_meal_plan_security_definer.sql."
```

---

## Coverage Checklist

| Finding | Severity | Fixed by |
|---|---|---|
| #1 — `generate_routine_plan` missing `auth.uid()` check | Critical | Task 1 |
| #2 — `recommend_recipes` dropped `auth.uid()` check across rewrites | Critical | Task 2 |
| #3 — `recommend_recipes` 4 unreconciled overloads (verified: 3 distinct signatures live, not 4 — `20260721000006`/`20260721000021` share one signature) | High | Task 2 |
| #4 — Hybrid Selective Virtue Masking not implemented in SQL (Python `active_goals` masking never wired to a DB-side parameter) | High | **Out of scope, see note below** — not fixed here |
| #5 — Duplicate `ingredient` rows for 9 `active_key`s (no UNIQUE constraint) | Medium/High | Task 4 |
| #6 — `20260721000004` full-object overwrite discarded prior `virtue_weights`/`skin_virtue_weights` keys | Medium | Task 5 |
| #7 — No `search_path` on any `SECURITY DEFINER` function in this area | Medium | Task 6 |
| #8 — Fan-mode 1.5x similarity boost unclamped (can exceed 1.0) | Medium | Task 2 |
| *(unlisted, found during verification)* — `generate_feed_personalized` also lost its `auth.uid()` check | Critical | Task 3 |

**Finding #4 — why it is out of scope:** the current `recommend_recipes` body computes similarity as a single scalar `1 - (recipe_vector.vector <=> user_vector)` cosine distance over the full 50-dimension vector — there is no per-goal/per-dimension breakdown available at the SQL layer to selectively mask against. The real masking logic (zeroing goal-related dimensions while preserving physical/diagnostic ones) exists only in `python/engine/vectorization.py`'s `compute_recipe_vector(active_goals=...)`, and the actual gap is that `python/main.py` never passes `active_goals` to it — a Python-layer fix, owned by a different plan (Area D), not this one. Adding a `p_active_goals TEXT[] DEFAULT NULL` parameter to `recommend_recipes` that does nothing (a no-op placeholder) would be exactly the kind of fake/incomplete implementation this plan is required not to write. **Real SQL-side masking requires a design decision beyond this review — flagged as future work, not fixed here.**

**Self-review performed:** re-read every task against the 8 findings and the file each cites; confirmed no step uses "TBD," "handle edge cases," or "similar to Task N" placeholder language; confirmed `recommend_recipes`'s signature (`uuid, int, text, text, text, text` → `recipe_id, title, description, mode, beauty_type, beauty_sub_type, frequency, similarity`) is written identically across Task 2's migration, Task 2's test, and Task 6's `ALTER FUNCTION` call; confirmed `generate_feed_personalized`'s 14-argument signature is written identically across Task 3's migration, Task 3's test, and Task 6's `ALTER FUNCTION` call; confirmed Task 5 depends on and runs after Task 4 (dedup) so its `WHERE active_key = 'x'` updates cannot double-apply to duplicate rows; confirmed every `DROP FUNCTION` argument-type list in Task 2 matches the exact `CREATE OR REPLACE FUNCTION` parameter types read from `20260720000002` and `20260720000008`.
