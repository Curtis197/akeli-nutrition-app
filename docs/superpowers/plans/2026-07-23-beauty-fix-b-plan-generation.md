# Beauty Mode Fix — Area B: SQL Beauty Plan Generation & Scheduling

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Beauty Mode's plan-generation SQL (`beauty_plan`/`beauty_plan_slot` schema, `generate_beauty_plan`, `generate_initial_beauty_plan`, `generate_beauty_plan_from_saved`) actually run, actually enforce RLS, and actually implement the fan-mode quota, monthly-tier distinctness, partial-month anchors, and zero-row fallback behavior its own comments claim it already has.
**Architecture:** Every fix ships as a brand-new, timestamp-ordered migration file that `CREATE OR REPLACE`s the affected function(s) in full (never a partial `ALTER`/patch), so each migration is independently readable and the git history stays append-only. Each fix is proven with a pgTAP test that fails against the pre-fix function and passes once the new migration is applied, run via `supabase test db`.
**Tech Stack:** PostgreSQL/Supabase migrations, pgTAP.

## Global Constraints
- Repo: `c:\Users\DELL LATITUDE 7480\akeli-nutrition-app`, branch `sdui`.
- Every fix is a NEW migration file under `supabase/migrations/` with timestamp prefix `20260722100000+` (increment by 100 per file) — never edit an existing committed migration.
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- Only touch files listed as "owned" in the task brief; if a fix needs a file outside this list (e.g. Area A's `recommend_recipes` signature), note it as a cross-plan dependency instead of touching it.
- Test runner for this repo (validated 2026-07-03, see project memory `local-meal-plan-testing`): from the repo root, run `supabase test db`. This applies every file in `supabase/migrations/` (via an internal `db reset`) in filename order, then runs every `*.sql` file in `supabase/tests/`. Because the global pass/fail summary line and total test count grow as files are added across this whole plan, **do not** assert an exact global `Files=N Tests=N` count anywhere in this plan — instead grep the output for the specific assertion description text named in each step (pgTAP prints `ok N - <description>` / `not ok N - <description>`).
- The permanent, already-committed seed migration `supabase/migrations/20260720000011_50_starter_beauty_recipes.sql` inserts 50 published (`is_published = true`), `mode = 'beauty'`, `creator_id = NULL` recipes, 22 of which get a `frequency` tag via `20260721000001_recipe_frequency_and_beauty_plan.sql` (6 `daily`, 7 `2x_week`, 6 `1x_week`, 2 `2x_month`, 1 `1x_month`). Every `db reset` re-seeds these rows, so every test below either (a) accounts for them by giving synthetic test recipes a `created_at` far in the future (`2099-...`) so they deterministically win the `ORDER BY created_at DESC` tie-break inside `recommend_recipes`, or (b) temporarily flips the pre-existing rows' `is_published` to `false` inside the test's own transaction (safe — every test file is wrapped in `BEGIN; ... ROLLBACK;`, so this never persists).
- `generate_beauty_plan` currently exists as **two coexisting overloads**: a legacy 2-argument `generate_beauty_plan(uuid, date)` (last defined in `20260721000012_beauty_plan_slot_revenue_value.sql`, predates `is_active`, unused by any current caller) and the 3-argument `generate_beauty_plan(uuid, date, int)` (last defined in `20260721000022_beauty_plan_fan_mode_quota.sql`, the one `generate_initial_beauty_plan` and `generate_beauty_plan_from_saved`'s threshold-fallback actually call). All 7 findings below concern the **3-argument** overload only. The 2-argument overload is dead code not covered by any of the 7 findings in this plan's brief and is left untouched.
- `generate_beauty_plan_from_saved` similarly exists as two coexisting overloads: 3-argument (`20260721000019_beauty_plan_generation_trio.sql`) and 5-argument (`20260721000020_beauty_plan_saved_threshold.sql`). Finding #7 explicitly covers "both variants" — Task 7 replaces both.

---

### Task 1: Add the missing `beauty_plan.is_active` column and backfill it

**Files:**
- Create: `supabase/migrations/20260722100000_beauty_plan_is_active_column.sql`
- Create: `supabase/tests/beauty_plan_is_active_column_test.sql`

**Interfaces:** `ALTER TABLE beauty_plan ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true`, plus a backfill `UPDATE`. No function signatures change in this task.

- [ ] **Step 1: Confirm the column really doesn't exist anywhere.**
  Run:
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -rn "ADD COLUMN.*is_active" supabase/migrations/
  ```
  Expected output: zero lines mentioning `beauty_plan` (the grep may match unrelated tables like `nutrition_plan`/`meal_plan` — confirm none of the matched lines say `beauty_plan`). This confirms the column truly does not exist.

- [ ] **Step 2: Write the failing pgTAP test.**
  Create `supabase/tests/beauty_plan_is_active_column_test.sql`:
  ```sql
  -- supabase/tests/beauty_plan_is_active_column_test.sql
  BEGIN;
  SELECT plan(6);

  -- ── Seed: test user ──────────────────────────────────────────────────────────
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES ('b1000001-0000-0000-0000-000000000001', 'beautyactive.test@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES ('b1000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  -- ── Seed: one published beauty recipe with a 'daily' frequency ──────────────
  INSERT INTO recipe (id, title, instructions, is_published, mode, beauty_type, beauty_sub_type, frequency, created_at)
  VALUES ('b1000001-0000-0000-0000-000000000010', 'Test Daily Hydration Mask', 'Apply and rinse.', true, 'beauty', 'both', 'daily_hydration', 'daily', now())
  ON CONFLICT (id) DO NOTHING;

  SET LOCAL "request.jwt.claims" TO '{"sub": "b1000001-0000-0000-0000-000000000001"}';

  -- ── T1: column exists ────────────────────────────────────────────────────────
  SELECT has_column('beauty_plan', 'is_active', 'T1: beauty_plan has is_active column');

  -- ── T2/T3: column is NOT NULL with a default ─────────────────────────────────
  SELECT col_not_null('beauty_plan', 'is_active', 'T2: is_active is NOT NULL');
  SELECT col_has_default('beauty_plan', 'is_active', 'T3: is_active has a default');

  -- ── T4/T5: backfill sets only the most recent plan per user active ──────────
  INSERT INTO beauty_plan (id, user_id, start_date, end_date, created_at)
  VALUES
    ('b1000001-0000-0000-0000-000000000020', 'b1000001-0000-0000-0000-000000000001', CURRENT_DATE - 60, CURRENT_DATE - 31, now() - INTERVAL '60 days'),
    ('b1000001-0000-0000-0000-000000000021', 'b1000001-0000-0000-0000-000000000001', CURRENT_DATE - 30, CURRENT_DATE - 1, now() - INTERVAL '30 days');

  SELECT is(
    (SELECT is_active FROM beauty_plan WHERE id = 'b1000001-0000-0000-0000-000000000021'),
    true,
    'T4: most recently created plan is active'
  );
  SELECT is(
    (SELECT is_active FROM beauty_plan WHERE id = 'b1000001-0000-0000-0000-000000000020'),
    false,
    'T5: older plan is inactive'
  );

  -- ── T6: generate_beauty_plan runs without "column is_active does not exist" ─
  SELECT lives_ok(
    $$ SELECT generate_beauty_plan('b1000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 2) $$,
    'T6: generate_beauty_plan executes without is_active column error'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run the test and confirm it fails.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: beauty_plan has|T6: generate_beauty_plan executes"
  ```
  Expected output includes lines starting with `not ok` for both `T1: beauty_plan has is_active column` and `T6: generate_beauty_plan executes without is_active column error` (the latter fails with a runtime error `column "is_active" does not exist`, which `lives_ok` reports as a test failure, not a hard crash of the test run).

- [ ] **Step 4: Write the migration.**
  Create `supabase/migrations/20260722100000_beauty_plan_is_active_column.sql`:
  ```sql
  -- Migration: Add missing is_active column to beauty_plan + backfill
  -- File: supabase/migrations/20260722100000_beauty_plan_is_active_column.sql
  -- Fixes: beauty_plan.is_active is referenced by generate_beauty_plan,
  -- generate_initial_beauty_plan, and generate_beauty_plan_from_saved (both
  -- variants) via UPDATE ... SET is_active = false and INSERT ... is_active,
  -- but the column was never created on beauty_plan (created in
  -- 20260721000002_beauty_plan_schema_and_generator.sql with only
  -- id, user_id, start_date, end_date, created_at, updated_at). Every one of
  -- those RPCs fails at runtime with "column is_active does not exist".

  ALTER TABLE beauty_plan ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

  -- Backfill: only the most recently created plan per user should be active;
  -- older plans (if any already exist) must be marked inactive.
  WITH ranked_plans AS (
      SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn
      FROM beauty_plan
  )
  UPDATE beauty_plan bp
  SET is_active = (ranked_plans.rn = 1)
  FROM ranked_plans
  WHERE bp.id = ranked_plans.id;
  ```

- [ ] **Step 5: Run the test again and confirm it passes.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: beauty_plan has|T2: is_active is NOT NULL|T3: is_active has a default|T4: most recently|T5: older plan|T6: generate_beauty_plan executes"
  ```
  Expected output: all six lines start with `ok` (no `not ok`).

- [ ] **Step 6: Commit.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/migrations/20260722100000_beauty_plan_is_active_column.sql supabase/tests/beauty_plan_is_active_column_test.sql
  git commit -m "fix(beauty): add missing beauty_plan.is_active column with per-user backfill

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

### Task 2: Enable RLS on `beauty_plan` and `beauty_plan_slot`

**Files:**
- Create: `supabase/migrations/20260722100100_beauty_plan_rls_policies.sql`
- Create: `supabase/tests/beauty_plan_rls_test.sql`

**Interfaces:** `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` + 4 `CREATE POLICY` statements per table. No function signatures change in this task.

- [ ] **Step 1: Confirm zero policies exist today.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "ENABLE ROW LEVEL SECURITY\|CREATE POLICY" supabase/migrations/20260721000002_beauty_plan_schema_and_generator.sql
  ```
  Expected output: no lines (empty). This confirms `beauty_plan`/`beauty_plan_slot` were created with zero RLS.

- [ ] **Step 2: Read the idiom to mirror.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "ENABLE ROW LEVEL SECURITY\|CREATE POLICY" -A 2 supabase/migrations/20260721000007_beauty_log_evolution_tracking.sql
  ```
  Confirms the idiom: `ALTER TABLE beauty_log ENABLE ROW LEVEL SECURITY;` followed by 4 separately named `CREATE POLICY "Users can <verb> own beauty logs" ON beauty_log FOR <VERB> USING/WITH CHECK (auth.uid() = user_id);` statements — one each for SELECT/INSERT/UPDATE/DELETE.

- [ ] **Step 3: Write the failing pgTAP test.**
  Create `supabase/tests/beauty_plan_rls_test.sql`:
  ```sql
  -- supabase/tests/beauty_plan_rls_test.sql
  BEGIN;
  SELECT plan(8);

  -- ── Seed: two users ──────────────────────────────────────────────────────────
  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('b2000001-0000-0000-0000-000000000001', 'beautyrls.a@akeli.test', 'authenticated', now(), now()),
    ('b2000001-0000-0000-0000-000000000002', 'beautyrls.b@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('b2000001-0000-0000-0000-000000000001', true, false, now(), 'fr'),
    ('b2000001-0000-0000-0000-000000000002', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  -- ── Seed: beauty_plan + slot owned by user A ────────────────────────────────
  INSERT INTO recipe (id, title, instructions, is_published, mode, frequency, created_at)
  VALUES ('b2000001-0000-0000-0000-000000000010', 'RLS Test Recipe', 'Steps.', true, 'beauty', 'daily', now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO beauty_plan (id, user_id, start_date, end_date, is_active)
  VALUES ('b2000001-0000-0000-0000-000000000020', 'b2000001-0000-0000-0000-000000000001', CURRENT_DATE, CURRENT_DATE + 6, true)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO beauty_plan_slot (id, plan_id, day_of_week, routine_category, step_stage, recipe_id, day_number, week_number, frequency_tier)
  VALUES ('b2000001-0000-0000-0000-000000000030', 'b2000001-0000-0000-0000-000000000020', 1, 'both', 'daily_hydration', 'b2000001-0000-0000-0000-000000000010', 1, 1, 'daily')
  ON CONFLICT (id) DO NOTHING;

  -- ── T1/T2: RLS is enabled on both tables ─────────────────────────────────────
  SELECT ok(
    (SELECT relrowsecurity FROM pg_class WHERE oid = 'beauty_plan'::regclass),
    'T1: RLS is enabled on beauty_plan'
  );
  SELECT ok(
    (SELECT relrowsecurity FROM pg_class WHERE oid = 'beauty_plan_slot'::regclass),
    'T2: RLS is enabled on beauty_plan_slot'
  );

  -- ── T3-T7: other user (B) cannot read/write user A's rows ───────────────────
  SET LOCAL request.jwt.claims = '{"sub":"b2000001-0000-0000-0000-000000000002"}';
  SET LOCAL ROLE authenticated;

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan WHERE id = 'b2000001-0000-0000-0000-000000000020'),
    0,
    'T3: other user cannot select user A''s beauty_plan row'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot WHERE id = 'b2000001-0000-0000-0000-000000000030'),
    0,
    'T4: other user cannot select user A''s beauty_plan_slot row'
  );

  SELECT is(
    (WITH upd AS (
        UPDATE beauty_plan SET end_date = end_date + 1
        WHERE id = 'b2000001-0000-0000-0000-000000000020'
        RETURNING id
     ) SELECT count(*)::int FROM upd),
    0,
    'T5: other user UPDATE on user A''s plan affects 0 rows'
  );

  SELECT is(
    (WITH del AS (
        DELETE FROM beauty_plan_slot
        WHERE id = 'b2000001-0000-0000-0000-000000000030'
        RETURNING id
     ) SELECT count(*)::int FROM del),
    0,
    'T6: other user DELETE on user A''s slot affects 0 rows'
  );

  SELECT throws_ok(
    $$ INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
       VALUES ('b2000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, CURRENT_DATE + 6, true) $$,
    'new row violates row-level security policy for table "beauty_plan"',
    'T7: RLS prevents inserting a beauty_plan row as another user'
  );

  -- ── T8: owning user CAN select their own plan ────────────────────────────────
  SET LOCAL request.jwt.claims = '{"sub":"b2000001-0000-0000-0000-000000000001"}';
  SET LOCAL ROLE authenticated;

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan WHERE id = 'b2000001-0000-0000-0000-000000000020'),
    1,
    'T8: owning user can select own beauty_plan row'
  );

  RESET ROLE;

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 4: Run the test and confirm it fails.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: RLS is enabled|T2: RLS is enabled|T3: other user cannot select|T4: other user cannot select|T7: RLS prevents"
  ```
  Expected output: `not ok` for T1, T2, T3, T4, T7 (T3/T4 fail because with no RLS the other user CAN see the rows, so `count(*)` returns `1` not `0`; T7 fails because the INSERT succeeds instead of throwing).

- [ ] **Step 5: Write the migration.**
  Create `supabase/migrations/20260722100100_beauty_plan_rls_policies.sql`:
  ```sql
  -- Migration: Enable RLS on beauty_plan and beauty_plan_slot
  -- File: supabase/migrations/20260722100100_beauty_plan_rls_policies.sql
  -- Fixes: beauty_plan / beauty_plan_slot were created in
  -- 20260721000002_beauty_plan_schema_and_generator.sql with zero RLS
  -- policies. Any authenticated user could read/update/delete any other
  -- user's beauty plan or slots via the Supabase client SDK. Mirrors the
  -- idiom used by beauty_log's RLS policies in
  -- 20260721000007_beauty_log_evolution_tracking.sql.

  ALTER TABLE beauty_plan ENABLE ROW LEVEL SECURITY;

  CREATE POLICY "Users can read own beauty plans"
      ON beauty_plan FOR SELECT
      USING (auth.uid() = user_id);

  CREATE POLICY "Users can insert own beauty plans"
      ON beauty_plan FOR INSERT
      WITH CHECK (auth.uid() = user_id);

  CREATE POLICY "Users can update own beauty plans"
      ON beauty_plan FOR UPDATE
      USING (auth.uid() = user_id);

  CREATE POLICY "Users can delete own beauty plans"
      ON beauty_plan FOR DELETE
      USING (auth.uid() = user_id);

  ALTER TABLE beauty_plan_slot ENABLE ROW LEVEL SECURITY;

  CREATE POLICY "Users can read own beauty plan slots"
      ON beauty_plan_slot FOR SELECT
      USING (plan_id IN (SELECT id FROM beauty_plan WHERE user_id = auth.uid()));

  CREATE POLICY "Users can insert own beauty plan slots"
      ON beauty_plan_slot FOR INSERT
      WITH CHECK (plan_id IN (SELECT id FROM beauty_plan WHERE user_id = auth.uid()));

  CREATE POLICY "Users can update own beauty plan slots"
      ON beauty_plan_slot FOR UPDATE
      USING (plan_id IN (SELECT id FROM beauty_plan WHERE user_id = auth.uid()));

  CREATE POLICY "Users can delete own beauty plan slots"
      ON beauty_plan_slot FOR DELETE
      USING (plan_id IN (SELECT id FROM beauty_plan WHERE user_id = auth.uid()));
  ```

- [ ] **Step 6: Run the test again and confirm it passes.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: RLS is enabled|T2: RLS is enabled|T3: other user cannot select|T4: other user cannot select|T5: other user UPDATE|T6: other user DELETE|T7: RLS prevents|T8: owning user can select"
  ```
  Expected output: all eight lines start with `ok`.

- [ ] **Step 7: Commit.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/migrations/20260722100100_beauty_plan_rls_policies.sql supabase/tests/beauty_plan_rls_test.sql
  git commit -m "fix(beauty): enable RLS on beauty_plan and beauty_plan_slot

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

### Task 3: Make the 90% fan-mode quota actually gate and increment

**Files:**
- Create: `supabase/migrations/20260722100200_beauty_plan_fan_mode_quota_fix.sql`
- Create: `supabase/tests/beauty_plan_fan_mode_quota_test.sql`

**Interfaces:** `CREATE OR REPLACE FUNCTION generate_beauty_plan(p_user_id UUID, p_start_date DATE DEFAULT CURRENT_DATE, p_days INT DEFAULT 30) RETURNS UUID` — the 3-argument overload only (see Global Constraints).

- [ ] **Step 1: Confirm the dead-code shape today.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "v_fan_count\|v_other_count\|v_max_other_slots" supabase/migrations/20260721000022_beauty_plan_fan_mode_quota.sql
  ```
  Expected output shows `v_fan_count INT := 0;`, `v_other_count INT := 0;`, `v_max_other_slots INT;` declared, and `v_max_other_slots := FLOOR(v_total_slots * 0.10);` appearing only in the block AFTER the `WHILE` loop closes (right before `RETURN v_plan_id;`) — confirming `v_fan_count`/`v_other_count` are never incremented anywhere and the quota is computed too late to gate anything.

- [ ] **Step 2: Write the failing pgTAP test.**
  Create `supabase/tests/beauty_plan_fan_mode_quota_test.sql`:
  ```sql
  -- supabase/tests/beauty_plan_fan_mode_quota_test.sql
  BEGIN;
  SELECT plan(4);

  -- ── Seed: plan-owning user + 2 creator accounts ─────────────────────────────
  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('b3000001-0000-0000-0000-000000000001', 'beautyfan.user@akeli.test', 'authenticated', now(), now()),
    ('b3000001-0000-0000-0000-000000000002', 'beautyfan.owner1@akeli.test', 'authenticated', now(), now()),
    ('b3000001-0000-0000-0000-000000000003', 'beautyfan.owner2@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('b3000001-0000-0000-0000-000000000001', true, false, now(), 'fr'),
    ('b3000001-0000-0000-0000-000000000002', true, true, now(), 'fr'),
    ('b3000001-0000-0000-0000-000000000003', true, true, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO creator (id, user_id, display_name, created_at, updated_at) VALUES
    ('b3000001-0000-0000-0000-000000000004', 'b3000001-0000-0000-0000-000000000002', 'Fan Creator Test', now(), now()),
    ('b3000001-0000-0000-0000-000000000005', 'b3000001-0000-0000-0000-000000000003', 'Other Creator Test', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO fan_subscription (user_id, creator_id, status, effective_from) VALUES
    ('b3000001-0000-0000-0000-000000000001', 'b3000001-0000-0000-0000-000000000004', 'active', CURRENT_DATE)
  ON CONFLICT (user_id, status) DO NOTHING;

  -- created_at far in the future so these two synthetic recipes always beat
  -- the 6 permanently-seeded 'daily' starter recipes on the created_at DESC
  -- tie-break inside recommend_recipes's no-vector branch.
  INSERT INTO recipe (id, title, instructions, is_published, mode, beauty_type, beauty_sub_type, frequency, creator_id, created_at) VALUES
    ('b3000001-0000-0000-0000-000000000010', 'Fan Creator Daily Recipe', 'Steps.', true, 'beauty', 'both', 'daily_hydration', 'daily', 'b3000001-0000-0000-0000-000000000004', '2099-01-01'::timestamptz),
    ('b3000001-0000-0000-0000-000000000011', 'Other Creator Daily Recipe', 'Steps.', true, 'beauty', 'both', 'daily_hydration', 'daily', 'b3000001-0000-0000-0000-000000000005', '2099-01-02'::timestamptz)
  ON CONFLICT (id) DO NOTHING;

  -- Helper: next Monday on/after CURRENT_DATE, so a 2-day plan covers only
  -- Mon+Tue (ISODOW 1,2) and never touches the 2x_week/1x_week/monthly
  -- branches, keeping the daily-only math fully deterministic.
  CREATE OR REPLACE FUNCTION _test_b3_next_monday()
  RETURNS date LANGUAGE sql AS $$
    SELECT CURRENT_DATE + ((1 - EXTRACT(ISODOW FROM CURRENT_DATE)::int + 7) % 7);
  $$;

  SET LOCAL "request.jwt.claims" TO '{"sub": "b3000001-0000-0000-0000-000000000001"}';

  -- Estimated total slots for a 2-day, no-weekly/no-monthly plan = 2*2 + 3 = 7
  -- (see migration comment for the estimate formula) -> v_max_other_slots =
  -- FLOOR(7 * 0.10) = 0. So the "other creator" recipe must be blocked on
  -- BOTH days once the quota is enforced.
  SELECT lives_ok(
    $$ SELECT generate_beauty_plan('b3000001-0000-0000-0000-000000000001'::uuid, _test_b3_next_monday(), 2) $$,
    'T1: generate_beauty_plan executes for fan-mode quota scenario'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b3000001-0000-0000-0000-000000000001'
       AND bp.start_date = _test_b3_next_monday()
       AND bps.recipe_id = 'b3000001-0000-0000-0000-000000000011'),
    0,
    'T2: other-creator recipe is blocked once the 90% fan-mode quota is reached'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b3000001-0000-0000-0000-000000000001'
       AND bp.start_date = _test_b3_next_monday()
       AND bps.recipe_id = 'b3000001-0000-0000-0000-000000000010'),
    2,
    'T3: fan-creator recipe is still inserted on both days'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b3000001-0000-0000-0000-000000000001'
       AND bp.start_date = _test_b3_next_monday()),
    2,
    'T4: total slot count for the plan is exactly 2 (no unquota''d other-creator slots leaked in)'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run the test and confirm it fails.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T2: other-creator recipe is blocked|T4: total slot count"
  ```
  Expected output: `not ok` for both — without gating, the other-creator recipe is inserted every day (T2 sees `2` instead of the expected `0`), so the total is `4` instead of `2` (T4).

- [ ] **Step 4: Write the migration.**
  Create `supabase/migrations/20260722100200_beauty_plan_fan_mode_quota_fix.sql`:
  ```sql
  -- Migration: Make the 90% fan-mode quota on generate_beauty_plan actually
  -- gate and increment instead of being dead code.
  -- File: supabase/migrations/20260722100200_beauty_plan_fan_mode_quota_fix.sql
  --
  -- Fixes: 20260721000022_beauty_plan_fan_mode_quota.sql declared
  -- v_fan_count/v_other_count but never incremented them anywhere, and
  -- computed v_max_other_slots only AFTER every slot for the whole plan had
  -- already been inserted -- making the "90% Fan Creator slot quota" claimed
  -- in that migration's own description pure dead code.
  --
  -- Mirrors the pattern already used correctly by Nutrition mode's
  -- generate_meal_plan (supabase/migrations/20260717061116_fix_generate_meal_plan_kcal_column_name.sql):
  -- v_max_other_slots is computed BEFORE the insertion loop, and every
  -- candidate row is gated with
  --   (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR <row's creator> = v_fan_creator_id)
  -- before being inserted, incrementing v_fan_count/v_other_count as it goes.
  --
  -- Difference from Nutrition: recommend_recipes() (owned by Area A) is a
  -- set-returning function that does not return creator_id, so each
  -- candidate row's creator_id is looked up via a small supplementary query
  -- (v_row_creator_id) rather than being available directly on the row, as
  -- it is in Nutrition's single-row-per-slot SELECT.
  --
  -- v_estimated_total_slots is a deterministic UPPER-BOUND estimate computed
  -- before the loop (2 daily slots/day + 2 slots per 2x_week occurrence + 2
  -- slots per 1x_week occurrence + 3 slots for the two 2x_month anchor days
  -- and the one 1x_month anchor day), since -- unlike Nutrition's fixed
  -- slots-per-day count -- Beauty's daily/weekly/monthly recipe pools can
  -- return fewer rows than requested. This keeps v_max_other_slots a safe,
  -- deterministic ceiling computed ahead of time rather than recomputed
  -- after the fact.

  CREATE OR REPLACE FUNCTION generate_beauty_plan(
    p_user_id    UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_days       INT DEFAULT 30
  )
  RETURNS UUID
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$
  DECLARE
      v_plan_id UUID;
      v_end_date DATE := p_start_date + (p_days - 1);
      v_curr_date DATE;
      v_day_num SMALLINT;
      v_week_num SMALLINT;
      v_dow SMALLINT;
      v_rec RECORD;
      v_found BOOLEAN;
      v_total_slots INT;
      v_fan_creator_id UUID;
      v_fan_count INT := 0;
      v_other_count INT := 0;
      v_max_other_slots INT;
      v_row_creator_id UUID;
      v_estimated_total_slots INT;
      v_2x_week_days INT;
      v_1x_week_days INT;
  BEGIN
      -- Look up active Fan Subscription
      SELECT fs.creator_id INTO v_fan_creator_id
      FROM fan_subscription fs
      WHERE fs.user_id = p_user_id AND fs.status = 'active'
      LIMIT 1;

      -- Count how many 2x_week (Wed/Sat) and 1x_week (Sun) anchor days fall
      -- within this plan's date range, so the fan-mode quota can be
      -- estimated BEFORE any slot is inserted (previously computed only
      -- after all slots already existed, making the quota dead code).
      SELECT count(*) INTO v_2x_week_days
      FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
      WHERE EXTRACT(ISODOW FROM d) IN (3, 6);

      SELECT count(*) INTO v_1x_week_days
      FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
      WHERE EXTRACT(ISODOW FROM d) = 7;

      v_estimated_total_slots := (p_days * 2) + (v_2x_week_days * 2) + (v_1x_week_days * 2) + 3;
      v_max_other_slots := FLOOR(v_estimated_total_slots * 0.10);

      -- Deactivate active beauty plans overlapping this range
      UPDATE beauty_plan
      SET is_active = false
      WHERE user_id = p_user_id AND is_active = true;

      INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
      VALUES (p_user_id, p_start_date, v_end_date, true)
      RETURNING id INTO v_plan_id;

      v_day_num := 1;
      v_curr_date := p_start_date;

      WHILE v_curr_date <= v_end_date LOOP
          v_dow := EXTRACT(ISODOW FROM v_curr_date)::SMALLINT;
          v_week_num := ((v_day_num - 1) / 7) + 1;

          -- Daily routine slots
          FOR v_rec IN
              SELECT recipe_id, beauty_type, beauty_sub_type
              FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => 'daily'::TEXT)
          LOOP
              SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
              IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                      v_rec.recipe_id,
                      'daily'
                  );
                  IF v_fan_creator_id IS NOT NULL THEN
                      IF v_row_creator_id = v_fan_creator_id THEN
                          v_fan_count := v_fan_count + 1;
                      ELSE
                          v_other_count := v_other_count + 1;
                      END IF;
                  END IF;
              END IF;
          END LOOP;

          -- Midweek treatment (Wednesdays & Saturdays)
          IF v_dow IN (3, 6) THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '2x_week'::TEXT)
              LOOP
                  v_found := TRUE;
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          COALESCE(v_rec.beauty_sub_type, 'treatment'),
                          v_rec.recipe_id,
                          '2x_week'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
                  LOOP
                      SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                      IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                          INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                          VALUES (
                              v_plan_id, v_day_num, v_week_num, v_dow,
                              COALESCE(v_rec.beauty_type, 'both'),
                              'midweek_treatment',
                              v_rec.recipe_id,
                              '2x_week'
                          );
                          IF v_fan_creator_id IS NOT NULL THEN
                              IF v_row_creator_id = v_fan_creator_id THEN
                                  v_fan_count := v_fan_count + 1;
                              ELSE
                                  v_other_count := v_other_count + 1;
                              END IF;
                          END IF;
                      END IF;
                  END LOOP;
              END IF;
          END IF;

          -- Sunday Wash Day Mask
          IF v_dow = 7 THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '1x_week'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          COALESCE(v_rec.beauty_sub_type, 'wash_day_mask'),
                          v_rec.recipe_id,
                          '1x_week'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          -- Bi-weekly Clarifying & Protein Care (Day 14 & 28)
          IF v_day_num IN (14, 28) THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'protein_clarifying_care',
                          v_rec.recipe_id,
                          '2x_month'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          -- Monthly Detox Check-in (Day 28)
          IF v_day_num = 28 THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'monthly_detox_checkin',
                          v_rec.recipe_id,
                          '1x_month'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          v_day_num := v_day_num + 1;
          v_curr_date := v_curr_date + INTERVAL '1 day';
      END LOOP;

      SELECT COUNT(*) INTO v_total_slots
      FROM beauty_plan_slot
      WHERE plan_id = v_plan_id;

      IF v_total_slots > 0 THEN
          UPDATE beauty_plan_slot
          SET revenue_value = ROUND(1.0 / v_total_slots, 6)
          WHERE plan_id = v_plan_id;
      END IF;

      RETURN v_plan_id;
  END;
  $$;
  ```

- [ ] **Step 5: Run the test again and confirm it passes.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: generate_beauty_plan executes for fan-mode|T2: other-creator recipe is blocked|T3: fan-creator recipe is still|T4: total slot count"
  ```
  Expected output: all four lines start with `ok`.

- [ ] **Step 6: Commit.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/migrations/20260722100200_beauty_plan_fan_mode_quota_fix.sql supabase/tests/beauty_plan_fan_mode_quota_test.sql
  git commit -m "fix(beauty): enforce the 90% fan-mode quota in generate_beauty_plan instead of leaving it dead code

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

### Task 4: Pass `p_frequency` on the 2x_month/1x_month `recommend_recipes` calls

**Files:**
- Create: `supabase/migrations/20260722100300_beauty_plan_month_tier_frequency_fix.sql`
- Create: `supabase/tests/beauty_plan_month_tier_frequency_test.sql`

**Interfaces:** `CREATE OR REPLACE FUNCTION generate_beauty_plan(p_user_id UUID, p_start_date DATE DEFAULT CURRENT_DATE, p_days INT DEFAULT 30) RETURNS UUID` (same 3-arg overload, built on top of Task 3's version).

- [ ] **Step 1: Confirm `recommend_recipes` accepts `p_frequency` today.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "p_frequency" supabase/migrations/20260721000021_recommend_recipes_fan_mode.sql
  ```
  Expected output includes `p_frequency        TEXT DEFAULT NULL` in the function signature and `AND (p_frequency IS NULL OR r.frequency = p_frequency)` in both `WHERE` clauses inside the function body — confirming `p_frequency` is a real, currently-supported parameter and this fix has no cross-plan dependency on Area A.

- [ ] **Step 2: Write the failing pgTAP test.**
  Create `supabase/tests/beauty_plan_month_tier_frequency_test.sql`:
  ```sql
  -- supabase/tests/beauty_plan_month_tier_frequency_test.sql
  BEGIN;
  SELECT plan(4);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('b4000001-0000-0000-0000-000000000001', 'beautymonth.user@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('b4000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  -- Two synthetic recipes, each tagged with a DIFFERENT month-tier frequency,
  -- created_at far in the future so each deterministically wins its own
  -- frequency-filtered pool over the 2 pre-existing '2x_month' and 1
  -- pre-existing '1x_month' starter recipes. recipe 0011's created_at is
  -- later than 0010's, so with NO frequency filter at all (the pre-fix bug)
  -- recommend_recipes(p_limit=>1, p_mode=>'beauty') deterministically
  -- returns 0011 for every one of the three month-tier calls.
  INSERT INTO recipe (id, title, instructions, is_published, mode, beauty_type, beauty_sub_type, frequency, created_at) VALUES
    ('b4000001-0000-0000-0000-000000000010', 'Test 2x Month Clarifying Treatment', 'Steps.', true, 'beauty', 'both', 'protein_clarifying_care', '2x_month', '2099-01-01'::timestamptz),
    ('b4000001-0000-0000-0000-000000000011', 'Test 1x Month Detox Mask', 'Steps.', true, 'beauty', 'both', 'monthly_detox_checkin', '1x_month', '2099-01-02'::timestamptz)
  ON CONFLICT (id) DO NOTHING;

  SET LOCAL "request.jwt.claims" TO '{"sub": "b4000001-0000-0000-0000-000000000001"}';

  SELECT lives_ok(
    $$ SELECT generate_beauty_plan('b4000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 28) $$,
    'T1: generate_beauty_plan executes for a 28-day plan'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b4000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.frequency_tier = '2x_month'
       AND bps.recipe_id = 'b4000001-0000-0000-0000-000000000010'),
    2,
    'T2: the 2x_month tier uses the recipe actually tagged 2x_month, on both anchor days'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b4000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.frequency_tier = '1x_month'
       AND bps.recipe_id = 'b4000001-0000-0000-0000-000000000011'),
    1,
    'T3: the 1x_month tier uses the recipe actually tagged 1x_month'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b4000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.frequency_tier = '2x_month'
       AND bps.recipe_id = 'b4000001-0000-0000-0000-000000000011'),
    0,
    'T4: the 2x_month tier no longer duplicates the 1x_month recipe'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run the test and confirm it fails.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T2: the 2x_month tier uses|T4: the 2x_month tier no longer"
  ```
  Expected output: `not ok` for both — without a frequency filter, the 2x_month section picks recipe `...0011` (the globally most-recent beauty recipe) instead of `...0010`, so T2 sees `0` instead of `2`, and T4 sees `2` instead of `0`.

- [ ] **Step 4: Write the migration.**
  Create `supabase/migrations/20260722100300_beauty_plan_month_tier_frequency_fix.sql`. This is Task 3's function with exactly two additions: `p_frequency => '2x_month'::TEXT` on the Day-14/28 `recommend_recipes` call, and `p_frequency => '1x_month'::TEXT` on the Day-28 `recommend_recipes` call.
  ```sql
  -- Migration: Pass p_frequency on the 2x_month/1x_month recommend_recipes
  -- calls inside generate_beauty_plan so they stop returning the same
  -- top-1 recipe under two different tier labels.
  -- File: supabase/migrations/20260722100300_beauty_plan_month_tier_frequency_fix.sql
  --
  -- Fixes: the Day-14/28 (2x_month) and Day-28 (1x_month) sections both
  -- called recommend_recipes(p_user_id, p_limit=>1, p_mode=>'beauty') with
  -- NO p_frequency argument, so both deterministically returned the
  -- identical top-1 recipe -- inserting a duplicate remedy under two
  -- different step_stage/frequency_tier labels with no unique constraint to
  -- prevent it. p_frequency is confirmed present on the current
  -- recommend_recipes signature (20260721000021_recommend_recipes_fan_mode.sql),
  -- so this has no cross-plan dependency.

  CREATE OR REPLACE FUNCTION generate_beauty_plan(
    p_user_id    UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_days       INT DEFAULT 30
  )
  RETURNS UUID
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$
  DECLARE
      v_plan_id UUID;
      v_end_date DATE := p_start_date + (p_days - 1);
      v_curr_date DATE;
      v_day_num SMALLINT;
      v_week_num SMALLINT;
      v_dow SMALLINT;
      v_rec RECORD;
      v_found BOOLEAN;
      v_total_slots INT;
      v_fan_creator_id UUID;
      v_fan_count INT := 0;
      v_other_count INT := 0;
      v_max_other_slots INT;
      v_row_creator_id UUID;
      v_estimated_total_slots INT;
      v_2x_week_days INT;
      v_1x_week_days INT;
  BEGIN
      SELECT fs.creator_id INTO v_fan_creator_id
      FROM fan_subscription fs
      WHERE fs.user_id = p_user_id AND fs.status = 'active'
      LIMIT 1;

      SELECT count(*) INTO v_2x_week_days
      FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
      WHERE EXTRACT(ISODOW FROM d) IN (3, 6);

      SELECT count(*) INTO v_1x_week_days
      FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
      WHERE EXTRACT(ISODOW FROM d) = 7;

      v_estimated_total_slots := (p_days * 2) + (v_2x_week_days * 2) + (v_1x_week_days * 2) + 3;
      v_max_other_slots := FLOOR(v_estimated_total_slots * 0.10);

      UPDATE beauty_plan
      SET is_active = false
      WHERE user_id = p_user_id AND is_active = true;

      INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
      VALUES (p_user_id, p_start_date, v_end_date, true)
      RETURNING id INTO v_plan_id;

      v_day_num := 1;
      v_curr_date := p_start_date;

      WHILE v_curr_date <= v_end_date LOOP
          v_dow := EXTRACT(ISODOW FROM v_curr_date)::SMALLINT;
          v_week_num := ((v_day_num - 1) / 7) + 1;

          -- Daily routine slots
          FOR v_rec IN
              SELECT recipe_id, beauty_type, beauty_sub_type
              FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => 'daily'::TEXT)
          LOOP
              SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
              IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                      v_rec.recipe_id,
                      'daily'
                  );
                  IF v_fan_creator_id IS NOT NULL THEN
                      IF v_row_creator_id = v_fan_creator_id THEN
                          v_fan_count := v_fan_count + 1;
                      ELSE
                          v_other_count := v_other_count + 1;
                      END IF;
                  END IF;
              END IF;
          END LOOP;

          -- Midweek treatment (Wednesdays & Saturdays)
          IF v_dow IN (3, 6) THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '2x_week'::TEXT)
              LOOP
                  v_found := TRUE;
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          COALESCE(v_rec.beauty_sub_type, 'treatment'),
                          v_rec.recipe_id,
                          '2x_week'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
                  LOOP
                      SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                      IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                          INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                          VALUES (
                              v_plan_id, v_day_num, v_week_num, v_dow,
                              COALESCE(v_rec.beauty_type, 'both'),
                              'midweek_treatment',
                              v_rec.recipe_id,
                              '2x_week'
                          );
                          IF v_fan_creator_id IS NOT NULL THEN
                              IF v_row_creator_id = v_fan_creator_id THEN
                                  v_fan_count := v_fan_count + 1;
                              ELSE
                                  v_other_count := v_other_count + 1;
                              END IF;
                          END IF;
                      END IF;
                  END LOOP;
              END IF;
          END IF;

          -- Sunday Wash Day Mask
          IF v_dow = 7 THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '1x_week'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          COALESCE(v_rec.beauty_sub_type, 'wash_day_mask'),
                          v_rec.recipe_id,
                          '1x_week'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          -- Bi-weekly Clarifying & Protein Care (Day 14 & 28)
          IF v_day_num IN (14, 28) THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '2x_month'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'protein_clarifying_care',
                          v_rec.recipe_id,
                          '2x_month'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          -- Monthly Detox Check-in (Day 28)
          IF v_day_num = 28 THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '1x_month'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'monthly_detox_checkin',
                          v_rec.recipe_id,
                          '1x_month'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          v_day_num := v_day_num + 1;
          v_curr_date := v_curr_date + INTERVAL '1 day';
      END LOOP;

      SELECT COUNT(*) INTO v_total_slots
      FROM beauty_plan_slot
      WHERE plan_id = v_plan_id;

      IF v_total_slots > 0 THEN
          UPDATE beauty_plan_slot
          SET revenue_value = ROUND(1.0 / v_total_slots, 6)
          WHERE plan_id = v_plan_id;
      END IF;

      RETURN v_plan_id;
  END;
  $$;
  ```

- [ ] **Step 5: Run the test again and confirm it passes.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: generate_beauty_plan executes for a 28-day|T2: the 2x_month tier uses|T3: the 1x_month tier uses|T4: the 2x_month tier no longer"
  ```
  Expected output: all four lines start with `ok`.

- [ ] **Step 6: Commit.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/migrations/20260722100300_beauty_plan_month_tier_frequency_fix.sql supabase/tests/beauty_plan_month_tier_frequency_test.sql
  git commit -m "fix(beauty): pass p_frequency on 2x_month/1x_month recommend_recipes calls to stop duplicate remedy insertion

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

### Task 5: Make the monthly-tier anchors relative to the plan's actual length

**Files:**
- Create: `supabase/migrations/20260722100400_beauty_plan_relative_month_anchors.sql`
- Create: `supabase/tests/beauty_plan_relative_month_anchors_test.sql`

**Interfaces:** `CREATE OR REPLACE FUNCTION generate_beauty_plan(p_user_id UUID, p_start_date DATE DEFAULT CURRENT_DATE, p_days INT DEFAULT 30) RETURNS UUID` (same 3-arg overload, built on top of Task 4's version).

- [ ] **Step 1: Confirm the hardcoded anchors and how `generate_initial_beauty_plan` calls in with a partial-month `p_days`.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "v_day_num IN (14, 28)\|v_day_num = 28" supabase/migrations/20260721000022_beauty_plan_fan_mode_quota.sql
  grep -n -A 6 "generate_initial_beauty_plan" supabase/migrations/20260721000019_beauty_plan_generation_trio.sql | head -12
  ```
  Expected output confirms both hardcoded conditions in `generate_beauty_plan`, and confirms `generate_initial_beauty_plan` computes `v_days := (v_end_of_month - v_start_date + 1)::INT` (the remainder of the current calendar month) and calls `generate_beauty_plan(p_user_id, v_start_date, v_days)` — so any `v_days < 14` (onboarding after the 18th or so of a 31-day month, or after the 14th of a 28-day month) means `v_day_num` inside the loop never reaches 14 or 28 at all.

- [ ] **Step 2: Write the failing pgTAP test.**
  Create `supabase/tests/beauty_plan_relative_month_anchors_test.sql`:
  ```sql
  -- supabase/tests/beauty_plan_relative_month_anchors_test.sql
  BEGIN;
  SELECT plan(5);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('b5000001-0000-0000-0000-000000000001', 'beautyanchor.user@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('b5000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  -- No synthetic recipes needed: the permanently-seeded starter pool already
  -- has 2 '2x_month' and 1 '1x_month' published beauty recipes, which is
  -- enough to satisfy p_limit => 1 for each tier.

  SET LOCAL "request.jwt.claims" TO '{"sub": "b5000001-0000-0000-0000-000000000001"}';

  -- A 10-day plan simulates a user onboarding with only 10 days left in the
  -- month -- short enough that v_day_num (1..10) never reaches the
  -- hardcoded 14/28 anchors.
  SELECT lives_ok(
    $$ SELECT generate_beauty_plan('b5000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 10) $$,
    'T1: generate_beauty_plan executes for a 10-day partial-month plan'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b5000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.frequency_tier = '2x_month'),
    2,
    'T2: a 10-day plan still gets 2 slots for the 2x_month tier'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b5000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.frequency_tier = '1x_month'),
    1,
    'T3: a 10-day plan still gets 1 slot for the 1x_month tier'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b5000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.day_number = 5
       AND bps.frequency_tier = '2x_month'),
    1,
    'T4: the first 2x_month anchor lands on day GREATEST(1, 10/2) = 5'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b5000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.day_number = 10
       AND bps.frequency_tier = '1x_month'),
    1,
    'T5: the 1x_month anchor lands on the last day (10)'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run the test and confirm it fails.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T2: a 10-day plan still gets 2|T3: a 10-day plan still gets 1|T4: the first 2x_month anchor|T5: the 1x_month anchor"
  ```
  Expected output: `not ok` for T2, T3, T4, T5 — with the hardcoded `IN (14, 28)`/`= 28` anchors, a 10-day plan's `v_day_num` never reaches 14 or 28, so zero month-tier slots are ever created.

- [ ] **Step 4: Write the migration.**
  Create `supabase/migrations/20260722100400_beauty_plan_relative_month_anchors.sql`. This is Task 4's function with exactly two condition changes: `IF v_day_num IN (14, 28) THEN` becomes `IF v_day_num = GREATEST(1, p_days / 2) OR v_day_num = p_days THEN`, and `IF v_day_num = 28 THEN` becomes `IF v_day_num = p_days THEN`.
  ```sql
  -- Migration: Anchor the 2x_month/1x_month tiers to the plan's own length
  -- instead of hardcoded calendar days 14/28.
  -- File: supabase/migrations/20260722100400_beauty_plan_relative_month_anchors.sql
  --
  -- Fixes: v_day_num counts from the plan's start_date, not the calendar
  -- day-of-month. generate_initial_beauty_plan calls
  -- generate_beauty_plan(p_user_id, v_start_date, v_days) where v_days is
  -- the number of days remaining in the current calendar month -- for most
  -- onboarding dates (after day ~14-18) this is well under 28, so
  -- v_day_num never reaches the hardcoded 14/28 anchors and the user's
  -- first, partial month silently has zero 2x_month/1x_month slots.
  --
  -- This is inherent to a fixed "day 14/28" anchor design for a
  -- variable-length plan, so the anchors are made relative to p_days (the
  -- actual number of days in THIS plan, whether a full 30-day plan or a
  -- partial first month): 2x_month now fires at GREATEST(1, p_days / 2)
  -- and again at p_days (the last day); 1x_month now fires at p_days (the
  -- last day). Every other branch (daily/2x_week/1x_week) is unchanged.

  CREATE OR REPLACE FUNCTION generate_beauty_plan(
    p_user_id    UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_days       INT DEFAULT 30
  )
  RETURNS UUID
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$
  DECLARE
      v_plan_id UUID;
      v_end_date DATE := p_start_date + (p_days - 1);
      v_curr_date DATE;
      v_day_num SMALLINT;
      v_week_num SMALLINT;
      v_dow SMALLINT;
      v_rec RECORD;
      v_found BOOLEAN;
      v_total_slots INT;
      v_fan_creator_id UUID;
      v_fan_count INT := 0;
      v_other_count INT := 0;
      v_max_other_slots INT;
      v_row_creator_id UUID;
      v_estimated_total_slots INT;
      v_2x_week_days INT;
      v_1x_week_days INT;
  BEGIN
      SELECT fs.creator_id INTO v_fan_creator_id
      FROM fan_subscription fs
      WHERE fs.user_id = p_user_id AND fs.status = 'active'
      LIMIT 1;

      SELECT count(*) INTO v_2x_week_days
      FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
      WHERE EXTRACT(ISODOW FROM d) IN (3, 6);

      SELECT count(*) INTO v_1x_week_days
      FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
      WHERE EXTRACT(ISODOW FROM d) = 7;

      v_estimated_total_slots := (p_days * 2) + (v_2x_week_days * 2) + (v_1x_week_days * 2) + 3;
      v_max_other_slots := FLOOR(v_estimated_total_slots * 0.10);

      UPDATE beauty_plan
      SET is_active = false
      WHERE user_id = p_user_id AND is_active = true;

      INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
      VALUES (p_user_id, p_start_date, v_end_date, true)
      RETURNING id INTO v_plan_id;

      v_day_num := 1;
      v_curr_date := p_start_date;

      WHILE v_curr_date <= v_end_date LOOP
          v_dow := EXTRACT(ISODOW FROM v_curr_date)::SMALLINT;
          v_week_num := ((v_day_num - 1) / 7) + 1;

          -- Daily routine slots
          FOR v_rec IN
              SELECT recipe_id, beauty_type, beauty_sub_type
              FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => 'daily'::TEXT)
          LOOP
              SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
              IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                      v_rec.recipe_id,
                      'daily'
                  );
                  IF v_fan_creator_id IS NOT NULL THEN
                      IF v_row_creator_id = v_fan_creator_id THEN
                          v_fan_count := v_fan_count + 1;
                      ELSE
                          v_other_count := v_other_count + 1;
                      END IF;
                  END IF;
              END IF;
          END LOOP;

          -- Midweek treatment (Wednesdays & Saturdays)
          IF v_dow IN (3, 6) THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '2x_week'::TEXT)
              LOOP
                  v_found := TRUE;
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          COALESCE(v_rec.beauty_sub_type, 'treatment'),
                          v_rec.recipe_id,
                          '2x_week'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
                  LOOP
                      SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                      IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                          INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                          VALUES (
                              v_plan_id, v_day_num, v_week_num, v_dow,
                              COALESCE(v_rec.beauty_type, 'both'),
                              'midweek_treatment',
                              v_rec.recipe_id,
                              '2x_week'
                          );
                          IF v_fan_creator_id IS NOT NULL THEN
                              IF v_row_creator_id = v_fan_creator_id THEN
                                  v_fan_count := v_fan_count + 1;
                              ELSE
                                  v_other_count := v_other_count + 1;
                              END IF;
                          END IF;
                      END IF;
                  END LOOP;
              END IF;
          END IF;

          -- Sunday Wash Day Mask
          IF v_dow = 7 THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '1x_week'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          COALESCE(v_rec.beauty_sub_type, 'wash_day_mask'),
                          v_rec.recipe_id,
                          '1x_week'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          -- Bi-weekly Clarifying & Protein Care (relative anchors)
          IF v_day_num = GREATEST(1, p_days / 2) OR v_day_num = p_days THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '2x_month'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'protein_clarifying_care',
                          v_rec.recipe_id,
                          '2x_month'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          -- Monthly Detox Check-in (relative anchor: last day)
          IF v_day_num = p_days THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '1x_month'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'monthly_detox_checkin',
                          v_rec.recipe_id,
                          '1x_month'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          v_day_num := v_day_num + 1;
          v_curr_date := v_curr_date + INTERVAL '1 day';
      END LOOP;

      SELECT COUNT(*) INTO v_total_slots
      FROM beauty_plan_slot
      WHERE plan_id = v_plan_id;

      IF v_total_slots > 0 THEN
          UPDATE beauty_plan_slot
          SET revenue_value = ROUND(1.0 / v_total_slots, 6)
          WHERE plan_id = v_plan_id;
      END IF;

      RETURN v_plan_id;
  END;
  $$;
  ```

- [ ] **Step 5: Run the test again and confirm it passes.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: generate_beauty_plan executes for a 10-day|T2: a 10-day plan still gets 2|T3: a 10-day plan still gets 1|T4: the first 2x_month anchor|T5: the 1x_month anchor"
  ```
  Expected output: all five lines start with `ok`.

- [ ] **Step 6: Commit.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/migrations/20260722100400_beauty_plan_relative_month_anchors.sql supabase/tests/beauty_plan_relative_month_anchors_test.sql
  git commit -m "fix(beauty): anchor 2x_month/1x_month tiers to plan length instead of hardcoded days 14/28

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

### Task 6: Apply the zero-rows `v_found` fallback to the daily and 1x_week branches too

**Files:**
- Create: `supabase/migrations/20260722100500_beauty_plan_full_fallback_coverage.sql`
- Create: `supabase/tests/beauty_plan_full_fallback_coverage_test.sql`
- Modify (revert only, no edits): `supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql` (discard uncommitted working-tree diff)

**Interfaces:** `CREATE OR REPLACE FUNCTION generate_beauty_plan(p_user_id UUID, p_start_date DATE DEFAULT CURRENT_DATE, p_days INT DEFAULT 30) RETURNS UUID` (same 3-arg overload, built on top of Task 5's version).

- [ ] **Step 1: Inspect the uncommitted diff, then discard it.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git diff HEAD -- supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql
  ```
  Expected output shows the uncommitted `v_found` fallback added ONLY to the 2x_week branch (declares `v_found BOOLEAN;`, sets `v_found := FALSE;`/`v_found := TRUE;`, and adds an `IF NOT v_found THEN ... END IF;` block after the 2x_week loop). This confirms editing an already-applied migration in place is exactly the problem: it would checksum-mismatch any environment that already applied `000008`, and it does nothing for the (currently live) 3-argument `generate_beauty_plan` overload anyway, since `000008` only ever defined the 2-argument legacy overload.

  Now discard it:
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git restore -- supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql
  git diff HEAD -- supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql
  ```
  Expected output for the second command: empty (no diff) — the working tree now matches the committed version exactly.

- [ ] **Step 2: Write the failing pgTAP test.**
  Create `supabase/tests/beauty_plan_full_fallback_coverage_test.sql`:
  ```sql
  -- supabase/tests/beauty_plan_full_fallback_coverage_test.sql
  BEGIN;
  SELECT plan(4);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('b6000001-0000-0000-0000-000000000001', 'beautyfallback.user@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('b6000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  -- Ensure at least one OTHER beauty recipe remains published to serve as
  -- the fallback candidate (recommend_recipes with no frequency filter).
  INSERT INTO recipe (id, title, instructions, is_published, mode, beauty_type, beauty_sub_type, frequency, created_at) VALUES
    ('b6000001-0000-0000-0000-000000000010', 'Test Fallback Candidate Recipe', 'Steps.', true, 'beauty', 'both', 'treatment', '2x_week', now())
  ON CONFLICT (id) DO NOTHING;

  -- Simulate an empty daily / 1x_week pool. This transaction rolls back at
  -- the end of the file, so this does not permanently affect the seeded
  -- starter recipes for any other test file.
  UPDATE recipe SET is_published = false WHERE frequency = 'daily';
  UPDATE recipe SET is_published = false WHERE frequency = '1x_week';

  -- Helper: next Sunday on/after CURRENT_DATE, so a 1-day plan exercises
  -- BOTH the daily section (runs every day) and the 1x_week section (runs
  -- only on Sundays) in a single, minimal call.
  CREATE OR REPLACE FUNCTION _test_b6_next_sunday()
  RETURNS date LANGUAGE sql AS $$
    SELECT CURRENT_DATE + ((7 - EXTRACT(ISODOW FROM CURRENT_DATE)::int + 7) % 7);
  $$;

  SET LOCAL "request.jwt.claims" TO '{"sub": "b6000001-0000-0000-0000-000000000001"}';

  SELECT lives_ok(
    $$ SELECT generate_beauty_plan('b6000001-0000-0000-0000-000000000001'::uuid, _test_b6_next_sunday(), 1) $$,
    'T1: generate_beauty_plan executes with empty daily/1x_week pools'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b6000001-0000-0000-0000-000000000001'
       AND bp.start_date = _test_b6_next_sunday()
       AND bps.frequency_tier = 'daily'),
    1,
    'T2: the daily tier still produces a slot via fallback when its frequency pool is empty'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b6000001-0000-0000-0000-000000000001'
       AND bp.start_date = _test_b6_next_sunday()
       AND bps.frequency_tier = '1x_week'),
    1,
    'T3: the 1x_week tier still produces a slot via fallback when its frequency pool is empty'
  );

  SELECT is(
    (SELECT step_stage FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b6000001-0000-0000-0000-000000000001'
       AND bp.start_date = _test_b6_next_sunday()
       AND bps.frequency_tier = 'daily'),
    'daily_care_fallback',
    'T4: the daily fallback slot is labeled distinctly from the primary daily path'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run the test and confirm it fails.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T2: the daily tier still produces|T3: the 1x_week tier still produces|T4: the daily fallback slot"
  ```
  Expected output: `not ok` for T2, T3, T4 — with no fallback on the daily/1x_week branches, an empty pool yields zero rows for both tiers, so T2/T3 see `0` instead of `1`, and T4 sees `NULL` instead of `'daily_care_fallback'`.

- [ ] **Step 4: Write the migration.**
  Create `supabase/migrations/20260722100500_beauty_plan_full_fallback_coverage.sql`. This is Task 5's function with a `v_found`-guarded fallback added to the daily section (label `'daily_care_fallback'`) and the Sunday 1x_week section (label `'wash_day_fallback'`), mirroring the pattern the 2x_week section already has.
  ```sql
  -- Migration: Apply the zero-rows v_found fallback to the daily and
  -- 1x_week branches of generate_beauty_plan, not just 2x_week.
  -- File: supabase/migrations/20260722100500_beauty_plan_full_fallback_coverage.sql
  --
  -- Fixes: only the 2x_week branch had a fallback (added, then reverted
  -- from the working tree in this same task -- see Step 1) that retries
  -- recommend_recipes with no frequency filter when the frequency-tagged
  -- pool returns zero rows. The daily and 1x_week branches had the
  -- identical zero-rows risk with no fallback at all, so a user whose
  -- daily/1x_week frequency-tagged recipe pool is temporarily empty (e.g.
  -- every recipe of that tier gets unpublished) silently gets zero slots
  -- for that tier instead of a same-day generic fallback recipe.

  CREATE OR REPLACE FUNCTION generate_beauty_plan(
    p_user_id    UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_days       INT DEFAULT 30
  )
  RETURNS UUID
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$
  DECLARE
      v_plan_id UUID;
      v_end_date DATE := p_start_date + (p_days - 1);
      v_curr_date DATE;
      v_day_num SMALLINT;
      v_week_num SMALLINT;
      v_dow SMALLINT;
      v_rec RECORD;
      v_found BOOLEAN;
      v_total_slots INT;
      v_fan_creator_id UUID;
      v_fan_count INT := 0;
      v_other_count INT := 0;
      v_max_other_slots INT;
      v_row_creator_id UUID;
      v_estimated_total_slots INT;
      v_2x_week_days INT;
      v_1x_week_days INT;
  BEGIN
      SELECT fs.creator_id INTO v_fan_creator_id
      FROM fan_subscription fs
      WHERE fs.user_id = p_user_id AND fs.status = 'active'
      LIMIT 1;

      SELECT count(*) INTO v_2x_week_days
      FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
      WHERE EXTRACT(ISODOW FROM d) IN (3, 6);

      SELECT count(*) INTO v_1x_week_days
      FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
      WHERE EXTRACT(ISODOW FROM d) = 7;

      v_estimated_total_slots := (p_days * 2) + (v_2x_week_days * 2) + (v_1x_week_days * 2) + 3;
      v_max_other_slots := FLOOR(v_estimated_total_slots * 0.10);

      UPDATE beauty_plan
      SET is_active = false
      WHERE user_id = p_user_id AND is_active = true;

      INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
      VALUES (p_user_id, p_start_date, v_end_date, true)
      RETURNING id INTO v_plan_id;

      v_day_num := 1;
      v_curr_date := p_start_date;

      WHILE v_curr_date <= v_end_date LOOP
          v_dow := EXTRACT(ISODOW FROM v_curr_date)::SMALLINT;
          v_week_num := ((v_day_num - 1) / 7) + 1;

          -- Daily routine slots
          v_found := FALSE;
          FOR v_rec IN
              SELECT recipe_id, beauty_type, beauty_sub_type
              FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => 'daily'::TEXT)
          LOOP
              v_found := TRUE;
              SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
              IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                      v_rec.recipe_id,
                      'daily'
                  );
                  IF v_fan_creator_id IS NOT NULL THEN
                      IF v_row_creator_id = v_fan_creator_id THEN
                          v_fan_count := v_fan_count + 1;
                      ELSE
                          v_other_count := v_other_count + 1;
                      END IF;
                  END IF;
              END IF;
          END LOOP;
          IF NOT v_found THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'daily_care_fallback',
                          v_rec.recipe_id,
                          'daily'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          -- Midweek treatment (Wednesdays & Saturdays)
          IF v_dow IN (3, 6) THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '2x_week'::TEXT)
              LOOP
                  v_found := TRUE;
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          COALESCE(v_rec.beauty_sub_type, 'treatment'),
                          v_rec.recipe_id,
                          '2x_week'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
                  LOOP
                      SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                      IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                          INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                          VALUES (
                              v_plan_id, v_day_num, v_week_num, v_dow,
                              COALESCE(v_rec.beauty_type, 'both'),
                              'midweek_treatment',
                              v_rec.recipe_id,
                              '2x_week'
                          );
                          IF v_fan_creator_id IS NOT NULL THEN
                              IF v_row_creator_id = v_fan_creator_id THEN
                                  v_fan_count := v_fan_count + 1;
                              ELSE
                                  v_other_count := v_other_count + 1;
                              END IF;
                          END IF;
                      END IF;
                  END LOOP;
              END IF;
          END IF;

          -- Sunday Wash Day Mask
          IF v_dow = 7 THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '1x_week'::TEXT)
              LOOP
                  v_found := TRUE;
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          COALESCE(v_rec.beauty_sub_type, 'wash_day_mask'),
                          v_rec.recipe_id,
                          '1x_week'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
                  LOOP
                      SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                      IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                          INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                          VALUES (
                              v_plan_id, v_day_num, v_week_num, v_dow,
                              COALESCE(v_rec.beauty_type, 'both'),
                              'wash_day_fallback',
                              v_rec.recipe_id,
                              '1x_week'
                          );
                          IF v_fan_creator_id IS NOT NULL THEN
                              IF v_row_creator_id = v_fan_creator_id THEN
                                  v_fan_count := v_fan_count + 1;
                              ELSE
                                  v_other_count := v_other_count + 1;
                              END IF;
                          END IF;
                      END IF;
                  END LOOP;
              END IF;
          END IF;

          -- Bi-weekly Clarifying & Protein Care (relative anchors)
          IF v_day_num = GREATEST(1, p_days / 2) OR v_day_num = p_days THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '2x_month'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'protein_clarifying_care',
                          v_rec.recipe_id,
                          '2x_month'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          -- Monthly Detox Check-in (relative anchor: last day)
          IF v_day_num = p_days THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '1x_month'::TEXT)
              LOOP
                  SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                  IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'monthly_detox_checkin',
                          v_rec.recipe_id,
                          '1x_month'
                      );
                      IF v_fan_creator_id IS NOT NULL THEN
                          IF v_row_creator_id = v_fan_creator_id THEN
                              v_fan_count := v_fan_count + 1;
                          ELSE
                              v_other_count := v_other_count + 1;
                          END IF;
                      END IF;
                  END IF;
              END LOOP;
          END IF;

          v_day_num := v_day_num + 1;
          v_curr_date := v_curr_date + INTERVAL '1 day';
      END LOOP;

      SELECT COUNT(*) INTO v_total_slots
      FROM beauty_plan_slot
      WHERE plan_id = v_plan_id;

      IF v_total_slots > 0 THEN
          UPDATE beauty_plan_slot
          SET revenue_value = ROUND(1.0 / v_total_slots, 6)
          WHERE plan_id = v_plan_id;
      END IF;

      RETURN v_plan_id;
  END;
  $$;
  ```

- [ ] **Step 5: Run the test again and confirm it passes.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: generate_beauty_plan executes with empty|T2: the daily tier still produces|T3: the 1x_week tier still produces|T4: the daily fallback slot"
  ```
  Expected output: all four lines start with `ok`.

- [ ] **Step 6: Commit.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql supabase/migrations/20260722100500_beauty_plan_full_fallback_coverage.sql supabase/tests/beauty_plan_full_fallback_coverage_test.sql
  git commit -m "fix(beauty): apply zero-rows fallback to daily and 1x_week tiers; discard uncommitted in-place edit to an already-applied migration

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```
  Note: `supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql` is included in this commit purely to record that its working-tree diff was discarded (the `git add` stages the now-clean, unmodified file — `git status` should show it as no longer modified after this commit).

---

### Task 7: Add 2x_month/1x_month tiers to `generate_beauty_plan_from_saved` (both overloads)

**Files:**
- Create: `supabase/migrations/20260722100600_beauty_plan_from_saved_monthly_tiers.sql`
- Create: `supabase/tests/beauty_plan_from_saved_monthly_tiers_test.sql`

**Interfaces:**
- `CREATE OR REPLACE FUNCTION generate_beauty_plan_from_saved(p_user_id UUID, p_start_date DATE DEFAULT CURRENT_DATE, p_days INT DEFAULT 30) RETURNS UUID` (3-arg overload, from `20260721000019_beauty_plan_generation_trio.sql`)
- `CREATE OR REPLACE FUNCTION generate_beauty_plan_from_saved(p_user_id UUID, p_start_date DATE DEFAULT CURRENT_DATE, p_days INT DEFAULT 30, p_min_saved_threshold INT DEFAULT 3, p_fallback_to_recommended BOOLEAN DEFAULT true) RETURNS UUID` (5-arg overload, from `20260721000020_beauty_plan_saved_threshold.sql`)

- [ ] **Step 1: Confirm neither overload has any 2x_month/1x_month section today.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "2x_month\|1x_month" supabase/migrations/20260721000019_beauty_plan_generation_trio.sql supabase/migrations/20260721000020_beauty_plan_saved_threshold.sql
  ```
  Expected output: no matches inside `generate_beauty_plan_from_saved`'s body in either file (matches for `generate_beauty_plan`/`generate_initial_beauty_plan` in `000019` are fine — those are the other two functions in that file's "trio").

- [ ] **Step 2: Write the failing pgTAP test.**
  Create `supabase/tests/beauty_plan_from_saved_monthly_tiers_test.sql`:
  ```sql
  -- supabase/tests/beauty_plan_from_saved_monthly_tiers_test.sql
  BEGIN;
  SELECT plan(6);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('b7000001-0000-0000-0000-000000000001', 'beautysaved.user@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('b7000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO recipe (id, title, instructions, is_published, mode, beauty_type, beauty_sub_type, created_at) VALUES
    ('b7000001-0000-0000-0000-000000000010', 'Test Saved Beauty Recipe', 'Steps.', true, 'beauty', 'both', 'daily_hydration', now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO recipe_save (user_id, recipe_id) VALUES
    ('b7000001-0000-0000-0000-000000000001', 'b7000001-0000-0000-0000-000000000010')
  ON CONFLICT DO NOTHING;

  SET LOCAL "request.jwt.claims" TO '{"sub": "b7000001-0000-0000-0000-000000000001"}';

  -- 3-arg overload
  SELECT lives_ok(
    $$ SELECT generate_beauty_plan_from_saved('b7000001-0000-0000-0000-000000000001'::uuid, '2027-03-01'::date, 10) $$,
    'T1: 3-arg generate_beauty_plan_from_saved executes'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b7000001-0000-0000-0000-000000000001'
       AND bp.start_date = '2027-03-01'::date
       AND bps.frequency_tier IN ('2x_month', '1x_month')),
    3,
    'T2: 3-arg variant now generates 2x_month + 1x_month slots from the saved pool'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b7000001-0000-0000-0000-000000000001'
       AND bp.start_date = '2027-03-01'::date
       AND bps.day_number = 5
       AND bps.frequency_tier = '2x_month'
       AND bps.recipe_id = 'b7000001-0000-0000-0000-000000000010'),
    1,
    'T3: 3-arg variant sources the 2x_month slot from the user''s saved recipe'
  );

  -- 5-arg overload
  SELECT lives_ok(
    $$ SELECT generate_beauty_plan_from_saved('b7000001-0000-0000-0000-000000000001'::uuid, '2027-06-01'::date, 10, 1, true) $$,
    'T4: 5-arg generate_beauty_plan_from_saved executes'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b7000001-0000-0000-0000-000000000001'
       AND bp.start_date = '2027-06-01'::date
       AND bps.frequency_tier IN ('2x_month', '1x_month')),
    3,
    'T5: 5-arg variant now generates 2x_month + 1x_month slots from the saved pool'
  );

  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'b7000001-0000-0000-0000-000000000001'
       AND bp.start_date = '2027-06-01'::date
       AND bps.day_number = 10
       AND bps.frequency_tier = '1x_month'
       AND bps.recipe_id = 'b7000001-0000-0000-0000-000000000010'),
    1,
    'T6: 5-arg variant sources the 1x_month slot from the user''s saved recipe'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run the test and confirm it fails.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T2: 3-arg variant now generates|T3: 3-arg variant sources|T5: 5-arg variant now generates|T6: 5-arg variant sources"
  ```
  Expected output: `not ok` for T2, T3, T5, T6 (both overloads currently have zero 2x_month/1x_month slots at all; T1/T4's `lives_ok` pass either way since the function itself does not error).

- [ ] **Step 4: Write the migration.**
  Create `supabase/migrations/20260722100600_beauty_plan_from_saved_monthly_tiers.sql`:
  ```sql
  -- Migration: Add 2x_month/1x_month tiers to generate_beauty_plan_from_saved
  -- (both the 3-arg and 5-arg overloads).
  -- File: supabase/migrations/20260722100600_beauty_plan_from_saved_monthly_tiers.sql
  --
  -- Fixes: generate_beauty_plan_from_saved never generated 2x_month/1x_month
  -- slots at all, unlike the standard generate_beauty_plan -- an asymmetry
  -- vs. the standard generator. Adds the same two tiers, sourced from the
  -- user's saved-recipes pool (recipe_save) first -- mirroring exactly how
  -- the existing daily/2x_week/1x_week sections in each of these two
  -- functions already source from the saved pool (plain LIMIT for the 3-arg
  -- overload, ORDER BY RANDOM() LIMIT for the 5-arg overload) -- falling
  -- back to recommend_recipes(p_frequency => ...) when the user has no
  -- saved recipe at all, and anchoring on p_days-relative days
  -- (GREATEST(1, p_days / 2) and p_days) exactly as
  -- 20260722100400_beauty_plan_relative_month_anchors.sql did for the
  -- standard generator.

  -- 1. Three-argument overload (generate_beauty_plan_from_saved(uuid, date, int))
  CREATE OR REPLACE FUNCTION generate_beauty_plan_from_saved(
    p_user_id    UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_days       INT DEFAULT 30
  )
  RETURNS UUID
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$
  DECLARE
      v_plan_id UUID;
      v_end_date DATE := p_start_date + (p_days - 1);
      v_curr_date DATE;
      v_day_num SMALLINT;
      v_week_num SMALLINT;
      v_dow SMALLINT;
      v_rec RECORD;
      v_found BOOLEAN;
      v_total_slots INT;
  BEGIN
      UPDATE beauty_plan
      SET is_active = false
      WHERE user_id = p_user_id AND is_active = true;

      INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
      VALUES (p_user_id, p_start_date, v_end_date, true)
      RETURNING id INTO v_plan_id;

      v_day_num := 1;
      v_curr_date := p_start_date;

      WHILE v_curr_date <= v_end_date LOOP
          v_dow := EXTRACT(ISODOW FROM v_curr_date)::SMALLINT;
          v_week_num := ((v_day_num - 1) / 7) + 1;

          -- Daily routine slots from saved recipes
          v_found := FALSE;
          FOR v_rec IN
              SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
              FROM recipe r
              JOIN recipe_save rs ON r.id = rs.recipe_id
              WHERE rs.user_id = p_user_id
                AND r.is_published = true
                AND r.mode = 'beauty'
              LIMIT 2
          LOOP
              v_found := TRUE;
              INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
              VALUES (
                  v_plan_id, v_day_num, v_week_num, v_dow,
                  COALESCE(v_rec.beauty_type, 'both'),
                  COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                  v_rec.recipe_id,
                  'daily'
              );
          END LOOP;

          -- Fallback to recommend_recipes if user has no saved beauty recipes
          IF NOT v_found THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => 'daily'::TEXT)
              LOOP
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                      v_rec.recipe_id,
                      'daily'
                  );
              END LOOP;
          END IF;

          -- Midweek treatment (Wednesdays & Saturdays)
          IF v_dow IN (3, 6) THEN
              FOR v_rec IN
                  SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
                  FROM recipe r
                  JOIN recipe_save rs ON r.id = rs.recipe_id
                  WHERE rs.user_id = p_user_id
                    AND r.is_published = true
                    AND r.mode = 'beauty'
                  LIMIT 1
              LOOP
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'treatment'),
                      v_rec.recipe_id,
                      '2x_week'
                  );
              END LOOP;
          END IF;

          -- Sunday Wash Day Mask
          IF v_dow = 7 THEN
              FOR v_rec IN
                  SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
                  FROM recipe r
                  JOIN recipe_save rs ON r.id = rs.recipe_id
                  WHERE rs.user_id = p_user_id
                    AND r.is_published = true
                    AND r.mode = 'beauty'
                  LIMIT 1
              LOOP
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'wash_day_mask'),
                      v_rec.recipe_id,
                      '1x_week'
                  );
              END LOOP;
          END IF;

          -- Bi-weekly Clarifying & Protein Care (relative anchors) from saved recipes
          IF v_day_num = GREATEST(1, p_days / 2) OR v_day_num = p_days THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
                  FROM recipe r
                  JOIN recipe_save rs ON r.id = rs.recipe_id
                  WHERE rs.user_id = p_user_id
                    AND r.is_published = true
                    AND r.mode = 'beauty'
                  LIMIT 1
              LOOP
                  v_found := TRUE;
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      'protein_clarifying_care',
                      v_rec.recipe_id,
                      '2x_month'
                  );
              END LOOP;

              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '2x_month'::TEXT)
                  LOOP
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'protein_clarifying_care',
                          v_rec.recipe_id,
                          '2x_month'
                      );
                  END LOOP;
              END IF;
          END IF;

          -- Monthly Detox Check-in (relative anchor: last day) from saved recipes
          IF v_day_num = p_days THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
                  FROM recipe r
                  JOIN recipe_save rs ON r.id = rs.recipe_id
                  WHERE rs.user_id = p_user_id
                    AND r.is_published = true
                    AND r.mode = 'beauty'
                  LIMIT 1
              LOOP
                  v_found := TRUE;
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      'monthly_detox_checkin',
                      v_rec.recipe_id,
                      '1x_month'
                  );
              END LOOP;

              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '1x_month'::TEXT)
                  LOOP
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'monthly_detox_checkin',
                          v_rec.recipe_id,
                          '1x_month'
                      );
                  END LOOP;
              END IF;
          END IF;

          v_day_num := v_day_num + 1;
          v_curr_date := v_curr_date + INTERVAL '1 day';
      END LOOP;

      SELECT COUNT(*) INTO v_total_slots
      FROM beauty_plan_slot
      WHERE plan_id = v_plan_id;

      IF v_total_slots > 0 THEN
          UPDATE beauty_plan_slot
          SET revenue_value = ROUND(1.0 / v_total_slots, 6)
          WHERE plan_id = v_plan_id;
      END IF;

      RETURN v_plan_id;
  END;
  $$;

  -- 2. Five-argument overload (generate_beauty_plan_from_saved(uuid, date, int, int, boolean))
  CREATE OR REPLACE FUNCTION generate_beauty_plan_from_saved(
    p_user_id                    UUID,
    p_start_date                 DATE DEFAULT CURRENT_DATE,
    p_days                       INT DEFAULT 30,
    p_min_saved_threshold        INT DEFAULT 3,
    p_fallback_to_recommended    BOOLEAN DEFAULT true
  )
  RETURNS UUID
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$
  DECLARE
      v_plan_id UUID;
      v_end_date DATE := p_start_date + (p_days - 1);
      v_curr_date DATE;
      v_day_num SMALLINT;
      v_week_num SMALLINT;
      v_dow SMALLINT;
      v_rec RECORD;
      v_found BOOLEAN;
      v_total_slots INT;
      v_saved_pool_count INT;
  BEGIN
      SELECT COUNT(DISTINCT r.id) INTO v_saved_pool_count
      FROM recipe r
      JOIN recipe_save rs ON r.id = rs.recipe_id
      WHERE rs.user_id = p_user_id
        AND r.is_published = true
        AND r.mode = 'beauty';

      IF v_saved_pool_count < p_min_saved_threshold THEN
          IF p_fallback_to_recommended THEN
              RAISE NOTICE 'Pool of saved beauty recipes (%) is below threshold (%). Falling back to standard recommended beauty plan.', v_saved_pool_count, p_min_saved_threshold;
              RETURN generate_beauty_plan(p_user_id, p_start_date, p_days);
          ELSE
              RAISE EXCEPTION 'insufficient_saved_beauty_recipes'
                USING DETAIL = 'Nombre de recettes beauté enregistrées (' || v_saved_pool_count || ') insuffisant (seuil minimum: ' || p_min_saved_threshold || ').';
          END IF;
      END IF;

      UPDATE beauty_plan
      SET is_active = false
      WHERE user_id = p_user_id AND is_active = true;

      INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
      VALUES (p_user_id, p_start_date, v_end_date, true)
      RETURNING id INTO v_plan_id;

      v_day_num := 1;
      v_curr_date := p_start_date;

      WHILE v_curr_date <= v_end_date LOOP
          v_dow := EXTRACT(ISODOW FROM v_curr_date)::SMALLINT;
          v_week_num := ((v_day_num - 1) / 7) + 1;

          -- Daily routine slots from saved recipes
          v_found := FALSE;
          FOR v_rec IN
              SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
              FROM recipe r
              JOIN recipe_save rs ON r.id = rs.recipe_id
              WHERE rs.user_id = p_user_id
                AND r.is_published = true
                AND r.mode = 'beauty'
              ORDER BY RANDOM()
              LIMIT 2
          LOOP
              v_found := TRUE;
              INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
              VALUES (
                  v_plan_id, v_day_num, v_week_num, v_dow,
                  COALESCE(v_rec.beauty_type, 'both'),
                  COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                  v_rec.recipe_id,
                  'daily'
              );
          END LOOP;

          IF NOT v_found THEN
              FOR v_rec IN
                  SELECT recipe_id, beauty_type, beauty_sub_type
                  FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => 'daily'::TEXT)
              LOOP
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                      v_rec.recipe_id,
                      'daily'
                  );
              END LOOP;
          END IF;

          -- Midweek treatment (Wednesdays & Saturdays)
          IF v_dow IN (3, 6) THEN
              FOR v_rec IN
                  SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
                  FROM recipe r
                  JOIN recipe_save rs ON r.id = rs.recipe_id
                  WHERE rs.user_id = p_user_id
                    AND r.is_published = true
                    AND r.mode = 'beauty'
                  ORDER BY RANDOM()
                  LIMIT 1
              LOOP
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'treatment'),
                      v_rec.recipe_id,
                      '2x_week'
                  );
              END LOOP;
          END IF;

          -- Sunday Wash Day Mask
          IF v_dow = 7 THEN
              FOR v_rec IN
                  SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
                  FROM recipe r
                  JOIN recipe_save rs ON r.id = rs.recipe_id
                  WHERE rs.user_id = p_user_id
                    AND r.is_published = true
                    AND r.mode = 'beauty'
                  ORDER BY RANDOM()
                  LIMIT 1
              LOOP
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      COALESCE(v_rec.beauty_sub_type, 'wash_day_mask'),
                      v_rec.recipe_id,
                      '1x_week'
                  );
              END LOOP;
          END IF;

          -- Bi-weekly Clarifying & Protein Care (relative anchors) from saved recipes
          IF v_day_num = GREATEST(1, p_days / 2) OR v_day_num = p_days THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
                  FROM recipe r
                  JOIN recipe_save rs ON r.id = rs.recipe_id
                  WHERE rs.user_id = p_user_id
                    AND r.is_published = true
                    AND r.mode = 'beauty'
                  ORDER BY RANDOM()
                  LIMIT 1
              LOOP
                  v_found := TRUE;
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      'protein_clarifying_care',
                      v_rec.recipe_id,
                      '2x_month'
                  );
              END LOOP;

              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '2x_month'::TEXT)
                  LOOP
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'protein_clarifying_care',
                          v_rec.recipe_id,
                          '2x_month'
                      );
                  END LOOP;
              END IF;
          END IF;

          -- Monthly Detox Check-in (relative anchor: last day) from saved recipes
          IF v_day_num = p_days THEN
              v_found := FALSE;
              FOR v_rec IN
                  SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type
                  FROM recipe r
                  JOIN recipe_save rs ON r.id = rs.recipe_id
                  WHERE rs.user_id = p_user_id
                    AND r.is_published = true
                    AND r.mode = 'beauty'
                  ORDER BY RANDOM()
                  LIMIT 1
              LOOP
                  v_found := TRUE;
                  INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                  VALUES (
                      v_plan_id, v_day_num, v_week_num, v_dow,
                      COALESCE(v_rec.beauty_type, 'both'),
                      'monthly_detox_checkin',
                      v_rec.recipe_id,
                      '1x_month'
                  );
              END LOOP;

              IF NOT v_found THEN
                  FOR v_rec IN
                      SELECT recipe_id, beauty_type, beauty_sub_type
                      FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT, p_frequency => '1x_month'::TEXT)
                  LOOP
                      INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                      VALUES (
                          v_plan_id, v_day_num, v_week_num, v_dow,
                          COALESCE(v_rec.beauty_type, 'both'),
                          'monthly_detox_checkin',
                          v_rec.recipe_id,
                          '1x_month'
                      );
                  END LOOP;
              END IF;
          END IF;

          v_day_num := v_day_num + 1;
          v_curr_date := v_curr_date + INTERVAL '1 day';
      END LOOP;

      SELECT COUNT(*) INTO v_total_slots
      FROM beauty_plan_slot
      WHERE plan_id = v_plan_id;

      IF v_total_slots > 0 THEN
          UPDATE beauty_plan_slot
          SET revenue_value = ROUND(1.0 / v_total_slots, 6)
          WHERE plan_id = v_plan_id;
      END IF;

      RETURN v_plan_id;
  END;
  $$;
  ```

- [ ] **Step 5: Run the test again and confirm it passes.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase test db 2>&1 | grep -E "T1: 3-arg generate_beauty_plan_from_saved|T2: 3-arg variant now generates|T3: 3-arg variant sources|T4: 5-arg generate_beauty_plan_from_saved|T5: 5-arg variant now generates|T6: 5-arg variant sources"
  ```
  Expected output: all six lines start with `ok`.

- [ ] **Step 6: Commit.**
  ```
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/migrations/20260722100600_beauty_plan_from_saved_monthly_tiers.sql supabase/tests/beauty_plan_from_saved_monthly_tiers_test.sql
  git commit -m "fix(beauty): add 2x_month/1x_month tiers to both generate_beauty_plan_from_saved overloads

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
  ```

---

## Coverage Checklist

| # | Finding | Task | Migration |
|---|---------|------|-----------|
| 1 | `beauty_plan.is_active` referenced everywhere but never created | Task 1 | `20260722100000_beauty_plan_is_active_column.sql` |
| 2 | Zero RLS on `beauty_plan`/`beauty_plan_slot` | Task 2 | `20260722100100_beauty_plan_rls_policies.sql` |
| 3 | 90% fan-mode quota is dead code (never incremented, computed post-loop) | Task 3 | `20260722100200_beauty_plan_fan_mode_quota_fix.sql` |
| 4 | 2x_month/1x_month calls omit `p_frequency`, causing duplicate remedy | Task 4 | `20260722100300_beauty_plan_month_tier_frequency_fix.sql`. **No cross-plan dependency**: Step 1 of Task 4 confirms `p_frequency` already exists on the current `recommend_recipes` signature (`20260721000021_recommend_recipes_fan_mode.sql`), so this fix does not need to wait on Area A's plan. |
| 5 | `v_day_num` anchors (14/28) lose the monthly tiers for partial first months | Task 5 | `20260722100400_beauty_plan_relative_month_anchors.sql` |
| 6 | Uncommitted `v_found` fallback only covers 2x_week; daily/1x_week lack it; in-place edit of an applied migration violates append-only policy | Task 6 | `20260722100500_beauty_plan_full_fallback_coverage.sql` (plus reverting the uncommitted diff on `20260721000008`) |
| 7 | `generate_beauty_plan_from_saved` (both overloads) never generates 2x_month/1x_month slots | Task 7 | `20260722100600_beauty_plan_from_saved_monthly_tiers.sql` |

## Self-Review

- **Placeholder scan:** no `TBD`, no "add appropriate error handling", no "handle edge cases", no "similar to Task N" shorthand anywhere in this plan — every task shows the complete function body being created, in full, every time it is replaced.
- **Function-name/signature consistency:**
  - `generate_beauty_plan(p_user_id UUID, p_start_date DATE DEFAULT CURRENT_DATE, p_days INT DEFAULT 30) RETURNS UUID` is the exact signature re-declared identically across Tasks 3, 4, 5, and 6 (only the body changes each time); Task 1's `lives_ok` call and every subsequent task's calls all pass exactly 3 positional arguments, matching this overload unambiguously (the coexisting 2-arg legacy overload cannot match a 3-argument call).
  - `v_fan_creator_id`, `v_fan_count`, `v_other_count`, `v_max_other_slots` are declared with those exact names, unchanged, in every version of `generate_beauty_plan` from Task 3 onward, per the brief's instruction to keep the diff minimal and traceable.
  - `generate_beauty_plan_from_saved`'s two overloads (3-arg and 5-arg) are both re-declared with their original exact signatures in Task 7, and both test calls (`generate_beauty_plan_from_saved(uuid, date, int)` and `generate_beauty_plan_from_saved(uuid, date, int, int, boolean)`) match by argument count, not by ambiguous default-filling.
  - `beauty_plan_slot.frequency_tier` values used consistently everywhere: `'daily'`, `'2x_week'`, `'1x_week'`, `'2x_month'`, `'1x_month'`.
- **Test isolation:** every test file uses a distinct UUID prefix block (`b1000001-...` through `b7000001-...`) and wraps everything in `BEGIN; ... ROLLBACK;`, so no test's seed data (including the temporary `is_published = false` flips in Task 6) leaks into another test file's run.
