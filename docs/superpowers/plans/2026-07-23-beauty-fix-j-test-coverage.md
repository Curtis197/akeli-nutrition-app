# Beauty Mode Fix — Area J: SQL & Python Test Coverage Expansion

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. **Several tasks in this plan are blocked on Areas A, B, C, D, and F completing first — check each task's prerequisite note before running it.**

**Goal:** Close the zero-SQL/Python-test-coverage gap on the payout engine, fan-mode boost, and plan generator, and replace the four misleading/incomplete Flutter tests identified in Area J's review with assertions that would actually fail if the underlying logic regressed.
**Architecture:** New pgTAP files under `supabase/tests/` (one function each), each written against the POST-FIX behavior documented in the owning area's plan (Area A for `recommend_recipes`, Area B for `generate_beauty_plan`, Area C for `calculate_creator_payouts`) rather than the current buggy behavior — these files are correctness regression tests for the fixed state, not red/green TDD tests for a bug this plan itself fixes. One Flutter widget test is extended in place. One documentation sentence is inserted based on an actual `flutter test` run.
**Tech Stack:** pgTAP, pytest/FastAPI TestClient, flutter_test.

## Global Constraints
- Repo: c:\Users\DELL LATITUDE 7480\akeli-nutrition-app, branch `sdui`.
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- Before starting any task, check whether the referenced other-area plan file already covers it — do not duplicate work.
- Test runner convention for every new pgTAP file in this plan (matches `supabase/tests/calculate_nutrition_targets_test.sql` and the convention documented in Areas A/B/C's own plans): from the repo root, `supabase db reset` then `supabase test db`. This re-applies every file in `supabase/migrations/` in filename order, then runs every `*.sql` file in `supabase/tests/`. Because the global pass/fail summary line's total test count grows as other areas' plans add their own files, do **not** assert an exact global `Files=N Tests=N` count anywhere in this plan — grep the output for the specific assertion description text named in each step instead.
- Every new pgTAP file in this plan is written against the CORRECTED behavior of another area's function (post-fix), not the current buggy behavior — so unlike a normal red/green TDD cycle, these tests are expected to only pass once the prerequisite migration(s) named in each task exist. Do not attempt to run them before their stated prerequisite lands.

---

### Task 1: `supabase/tests/calculate_creator_payouts_test.sql` — new pgTAP coverage for the corrected payout engine

**Prerequisite: BLOCKED on Area C Task 2** (`## Task 2: calculate_creator_payouts — remove fan-mode double counting`, migration `supabase/migrations/20260722110100_fix_beauty_payout_fan_double_counting.sql`). That migration both fixes the double-counting bug and repairs a schema mismatch (`creator_monthly_payouts` missing `updated_at` / wrong `creator_id` FK target) that Area C's own plan documents as pre-existing — `calculate_creator_payouts` cannot run at all today without it. Do not run this file until that migration exists.

**Files:**
- Create: `supabase/tests/calculate_creator_payouts_test.sql`

**Interfaces:**
- Tests: `calculate_creator_payouts(target_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE, plan_revenue_cents INT DEFAULT 100) RETURNS VOID` (Area C Task 2's corrected 2-arg signature) and the `creator_monthly_payouts` table it writes to.

- [ ] **Step 1: Confirm the prerequisite migration exists**

  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -l "pool_earnings_cents := ROUND" supabase/migrations/20260722110100_fix_beauty_payout_fan_double_counting.sql
  ```
  Expected output: the file path echoed back (confirms Area C Task 2 has landed). If this file does not exist, STOP — do not proceed with this task yet.

- [ ] **Step 2: Create the test file**

  Create `supabase/tests/calculate_creator_payouts_test.sql`:
  ```sql
  -- supabase/tests/calculate_creator_payouts_test.sql
  -- Beauty Mode Branch Review 2026-07-23, Area J, Finding #1(a): zero SQL/RPC
  -- test coverage exists for calculate_creator_payouts. Written against the
  -- CORRECTED function body from Area C Task 2
  -- (supabase/migrations/20260722110100_fix_beauty_payout_fan_double_counting.sql),
  -- which removes the double-counted fan_earnings_cents component and computes
  -- pool_earnings_cents as ROUND(SUM(bps.revenue_value) * plan_revenue_cents)
  -- over each creator's completed beauty_plan_slot rows in the target month.
  --
  -- PREREQUISITE: BLOCKED on Area C Task 2. Do not run this file until that
  -- migration exists in supabase/migrations/.
  BEGIN;
  SELECT plan(7);

  -- ── Seed: plan-owner user, 3 creators (X completes partially, Y completes
  -- fully, Z has a recipe but zero completed slots) ─────────────────────────
  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('j1000001-0000-0000-0000-000000000001', 'payout.owner@akeli.test', 'authenticated', now(), now()),
    ('j1000001-0000-0000-0000-000000000002', 'payout.creatorx@akeli.test', 'authenticated', now(), now()),
    ('j1000001-0000-0000-0000-000000000003', 'payout.creatory@akeli.test', 'authenticated', now(), now()),
    ('j1000001-0000-0000-0000-000000000004', 'payout.creatorz@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('j1000001-0000-0000-0000-000000000001', true, false, now(), 'fr'),
    ('j1000001-0000-0000-0000-000000000002', true, true, now(), 'fr'),
    ('j1000001-0000-0000-0000-000000000003', true, true, now(), 'fr'),
    ('j1000001-0000-0000-0000-000000000004', true, true, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO creator (id, user_id, display_name) VALUES
    ('j1000001-0000-0000-0000-000000000010', 'j1000001-0000-0000-0000-000000000002', 'Payout Creator X'),
    ('j1000001-0000-0000-0000-000000000011', 'j1000001-0000-0000-0000-000000000003', 'Payout Creator Y'),
    ('j1000001-0000-0000-0000-000000000012', 'j1000001-0000-0000-0000-000000000004', 'Payout Creator Z')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO recipe (id, creator_id, title, instructions, is_published, mode) VALUES
    ('j1000001-0000-0000-0000-000000000020', 'j1000001-0000-0000-0000-000000000010', 'Payout Test Recipe X', 'Steps.', true, 'beauty'),
    ('j1000001-0000-0000-0000-000000000021', 'j1000001-0000-0000-0000-000000000011', 'Payout Test Recipe Y', 'Steps.', true, 'beauty'),
    ('j1000001-0000-0000-0000-000000000022', 'j1000001-0000-0000-0000-000000000012', 'Payout Test Recipe Z', 'Steps.', true, 'beauty')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO beauty_plan (id, user_id, start_date, end_date) VALUES (
    'j1000001-0000-0000-0000-000000000030',
    'j1000001-0000-0000-0000-000000000001',
    date_trunc('month', current_date)::date,
    (date_trunc('month', current_date) + interval '1 month - 1 day')::date
  ) ON CONFLICT (id) DO NOTHING;

  -- Creator X: 3 completed slots @ revenue_value 0.25 (sum 0.75) + 1 INCOMPLETE
  -- slot @ 0.25 that must NOT be counted.
  INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id, is_completed, completed_at, revenue_value) VALUES
    ('j1000001-0000-0000-0000-000000000030', 1, 'hair', 'daily_hydration', 'j1000001-0000-0000-0000-000000000020', true,  now(), 0.25),
    ('j1000001-0000-0000-0000-000000000030', 2, 'hair', 'daily_hydration', 'j1000001-0000-0000-0000-000000000020', true,  now(), 0.25),
    ('j1000001-0000-0000-0000-000000000030', 3, 'hair', 'daily_hydration', 'j1000001-0000-0000-0000-000000000020', true,  now(), 0.25),
    ('j1000001-0000-0000-0000-000000000030', 4, 'hair', 'daily_hydration', 'j1000001-0000-0000-0000-000000000020', false, NULL, 0.25);

  -- Creator Y: 2 completed slots @ revenue_value 0.5 (sum 1.0).
  INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id, is_completed, completed_at, revenue_value) VALUES
    ('j1000001-0000-0000-0000-000000000030', 5, 'skin', 'treatment', 'j1000001-0000-0000-0000-000000000021', true, now(), 0.5),
    ('j1000001-0000-0000-0000-000000000030', 6, 'skin', 'treatment', 'j1000001-0000-0000-0000-000000000021', true, now(), 0.5);

  -- Creator Z: recipe exists in the plan, but its only slot is NOT completed —
  -- Creator Z must get no payout row at all this month.
  INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id, is_completed, completed_at, revenue_value) VALUES
    ('j1000001-0000-0000-0000-000000000030', 7, 'both', 'wash_day_mask', 'j1000001-0000-0000-0000-000000000022', false, NULL, 1.0);

  -- ── Act ──────────────────────────────────────────────────────────────────
  SELECT lives_ok(
    $$ SELECT calculate_creator_payouts(date_trunc('month', current_date)::date) $$,
    'calculate_creator_payouts executes without error'
  );

  -- Creator X: ROUND(0.75 * 100) = 75 cents. The incomplete 4th slot's 0.25 is
  -- deliberately excluded from this sum — if it were wrongly included this
  -- would be 100, not 75.
  SELECT is(
    (SELECT pool_earnings_cents FROM creator_monthly_payouts
     WHERE creator_id = 'j1000001-0000-0000-0000-000000000010'
       AND period_month = date_trunc('month', current_date)::date),
    75,
    'Creator X payout is exactly ROUND(0.75 * 100) = 75 cents, excluding the incomplete slot'
  );

  -- Creator Y: ROUND(1.0 * 100) = 100 cents.
  SELECT is(
    (SELECT pool_earnings_cents FROM creator_monthly_payouts
     WHERE creator_id = 'j1000001-0000-0000-0000-000000000011'
       AND period_month = date_trunc('month', current_date)::date),
    100,
    'Creator Y payout is exactly ROUND(1.0 * 100) = 100 cents'
  );

  -- fan_earnings_cents must stay at its table default of 0 — Area C Task 2
  -- deliberately never computes fan-mode revenue in this function anymore.
  SELECT is(
    (SELECT fan_earnings_cents FROM creator_monthly_payouts
     WHERE creator_id = 'j1000001-0000-0000-0000-000000000010'
       AND period_month = date_trunc('month', current_date)::date),
    0,
    'Creator X fan_earnings_cents remains 0 (not double-counted by this function)'
  );

  SELECT is(
    (SELECT status FROM creator_monthly_payouts
     WHERE creator_id = 'j1000001-0000-0000-0000-000000000010'
       AND period_month = date_trunc('month', current_date)::date),
    'pending',
    'Creator X payout row status defaults to pending'
  );

  -- Creator Z has zero completed slots this month -> no payout row at all.
  SELECT is(
    (SELECT count(*)::int FROM creator_monthly_payouts
     WHERE creator_id = 'j1000001-0000-0000-0000-000000000012'
       AND period_month = date_trunc('month', current_date)::date),
    0,
    'Creator Z (zero completed slots) gets no creator_monthly_payouts row'
  );

  -- Exactly 2 of our 3 test creators (X and Y) got a row this month.
  SELECT is(
    (SELECT count(*)::int FROM creator_monthly_payouts
     WHERE creator_id IN (
       'j1000001-0000-0000-0000-000000000010',
       'j1000001-0000-0000-0000-000000000011',
       'j1000001-0000-0000-0000-000000000012'
     )
     AND period_month = date_trunc('month', current_date)::date),
    2,
    'exactly 2 of the 3 test creators received a payout row this month'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run and confirm all 7 assertions pass**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase db reset
  supabase test db 2>&1 | grep -E "calculate_creator_payouts executes without error|Creator X payout is exactly|Creator Y payout is exactly|Creator X fan_earnings_cents remains 0|Creator X payout row status defaults|Creator Z \(zero completed slots\)|exactly 2 of the 3 test creators"
  ```
  Expected output: 7 lines, every one starting with `ok`.

- [ ] **Step 4: Commit**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/tests/calculate_creator_payouts_test.sql
  git commit -m "$(cat <<'EOF'
  test(beauty): add pgTAP coverage for the corrected calculate_creator_payouts payout math

  Zero SQL/RPC test coverage existed for the payout engine despite it being
  the highest money-correctness-risk logic in Beauty Mode. Asserts exact
  ROUND(sum(revenue_value) * plan_revenue_cents) payout amounts per creator,
  that incomplete slots are excluded, and that a creator with zero completed
  slots gets no payout row.

  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 2: `supabase/tests/recommend_recipes_fan_mode_test.sql` — new pgTAP coverage for the corrected 1.5x fan-mode boost

**Prerequisite: BLOCKED on Area A Task 2** (`### Task 2: Restore recommend_recipes auth check, drop stale overloads, clamp similarity`, migration `supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql`). That migration both restores the `auth.uid()` check this test relies on and clamps the fan-mode boost to `LEAST(raw_similarity * 1.5, 1.0)`. Do not run this file until that migration exists.

**Files:**
- Create: `supabase/tests/recommend_recipes_fan_mode_test.sql`

**Interfaces:**
- Tests: `recommend_recipes(p_user_id UUID, p_limit INT DEFAULT 10, p_mode TEXT DEFAULT NULL, p_beauty_type TEXT DEFAULT NULL, p_beauty_sub_type TEXT DEFAULT NULL, p_frequency TEXT DEFAULT NULL) RETURNS TABLE(recipe_id UUID, title TEXT, description TEXT, mode TEXT, beauty_type TEXT, beauty_sub_type TEXT, frequency TEXT, similarity DOUBLE PRECISION)` (Area A Task 2's corrected 6-arg signature).

- [ ] **Step 1: Confirm the prerequisite migration exists**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -l "CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id THEN 1.5" supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql
  ```
  Expected output: the file path echoed back. If this file does not exist, STOP — do not proceed with this task yet.

- [ ] **Step 2: Create the test file**

  Create `supabase/tests/recommend_recipes_fan_mode_test.sql`:
  ```sql
  -- supabase/tests/recommend_recipes_fan_mode_test.sql
  -- Beauty Mode Branch Review 2026-07-23, Area J, Finding #1(b): zero SQL/RPC
  -- test coverage exists for the fan-mode 1.5x recommendation boost. Written
  -- against the CORRECTED recommend_recipes body from Area A Task 2
  -- (supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql),
  -- which restores the auth.uid() check and clamps the fan-mode boosted
  -- similarity to LEAST(raw_similarity * 1.5, 1.0).
  --
  -- PREREQUISITE: BLOCKED on Area A Task 2. Do not run this file until that
  -- migration exists in supabase/migrations/.
  --
  -- Vector design: the user vector has 25 leading 1.0 dims (rest 0.0); BOTH the
  -- fan-subscribed creator's recipe and the non-fan creator's recipe share the
  -- IDENTICAL vector with 9 leading 1.0 dims (rest 0.0) -- i.e. equal base
  -- similarity for both. cosine_similarity = dot / (|u| * |r|) = 9 / (5 * 3) =
  -- 0.6 exactly for both recipes before the fan-mode multiplier is applied.
  -- 0.6 * 1.5 = 0.9, which is < 1.0, so the fan-subscribed recipe's boosted
  -- score is NOT clamped -- this test exercises the actual 1.5x multiplier
  -- itself, not just the clamp ceiling (already covered by Area A's own test).
  BEGIN;
  SELECT plan(5);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('j2000001-0000-0000-0000-000000000001', 'fanboost.user@akeli.test', 'authenticated', now(), now()),
    ('j2000001-0000-0000-0000-000000000002', 'fanboost.fancreator@akeli.test', 'authenticated', now(), now()),
    ('j2000001-0000-0000-0000-000000000003', 'fanboost.othercreator@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('j2000001-0000-0000-0000-000000000001', true, false, now(), 'fr'),
    ('j2000001-0000-0000-0000-000000000002', true, true, now(), 'fr'),
    ('j2000001-0000-0000-0000-000000000003', true, true, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO creator (id, user_id, display_name) VALUES
    ('j2000001-0000-0000-0000-000000000010', 'j2000001-0000-0000-0000-000000000002', 'Fan Boost Fan Creator'),
    ('j2000001-0000-0000-0000-000000000011', 'j2000001-0000-0000-0000-000000000003', 'Fan Boost Other Creator')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO fan_subscription (user_id, creator_id, status) VALUES
    ('j2000001-0000-0000-0000-000000000001', 'j2000001-0000-0000-0000-000000000010', 'active')
  ON CONFLICT (user_id, status) DO NOTHING;

  INSERT INTO recipe (id, creator_id, title, instructions, is_published, mode) VALUES
    ('j2000001-0000-0000-0000-000000000020', 'j2000001-0000-0000-0000-000000000010', 'Fan Creator Recipe (boosted)', 'Steps.', true, 'beauty'),
    ('j2000001-0000-0000-0000-000000000021', 'j2000001-0000-0000-0000-000000000011', 'Other Creator Recipe (baseline)', 'Steps.', true, 'beauty')
  ON CONFLICT (id) DO NOTHING;

  -- User vector: dims 1-25 = 1.0, dims 26-50 = 0.0. |u| = sqrt(25) = 5.
  INSERT INTO user_vector (user_id, vector) VALUES (
    'j2000001-0000-0000-0000-000000000001',
    (SELECT ('[' || string_agg(CASE WHEN gs <= 25 THEN '1' ELSE '0' END, ',' ORDER BY gs) || ']')::vector(50)
     FROM generate_series(1, 50) AS gs)
  ) ON CONFLICT (user_id) DO UPDATE SET vector = EXCLUDED.vector;

  -- BOTH recipes get the IDENTICAL vector: dims 1-9 = 1.0, dims 10-50 = 0.0.
  -- |r| = sqrt(9) = 3. dot(u,r) = 9. cosine_similarity = 9 / (5*3) = 0.6 for both.
  INSERT INTO recipe_vector (recipe_id, vector) VALUES
    ('j2000001-0000-0000-0000-000000000020',
     (SELECT ('[' || string_agg(CASE WHEN gs <= 9 THEN '1' ELSE '0' END, ',' ORDER BY gs) || ']')::vector(50)
      FROM generate_series(1, 50) AS gs)),
    ('j2000001-0000-0000-0000-000000000021',
     (SELECT ('[' || string_agg(CASE WHEN gs <= 9 THEN '1' ELSE '0' END, ',' ORDER BY gs) || ']')::vector(50)
      FROM generate_series(1, 50) AS gs))
  ON CONFLICT (recipe_id) DO UPDATE SET vector = EXCLUDED.vector;

  SET LOCAL "request.jwt.claims" TO '{"sub": "j2000001-0000-0000-0000-000000000001"}';

  SELECT lives_ok(
    $$ SELECT * FROM recommend_recipes('j2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL) $$,
    'recommend_recipes executes for the owning user'
  );

  -- Non-fan creator's recipe returns its raw, un-boosted similarity: 0.6 exactly.
  SELECT is(
    (SELECT ROUND(similarity::numeric, 4) FROM recommend_recipes('j2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL)
     WHERE recipe_id = 'j2000001-0000-0000-0000-000000000021'::uuid),
    0.6000::numeric,
    'non-fan creator recipe raw similarity is exactly 0.6 (unboosted baseline)'
  );

  -- Fan-subscribed creator's recipe (equal base similarity) is boosted to
  -- exactly 0.6 * 1.5 = 0.9 -- below the 1.0 clamp ceiling, so this proves the
  -- actual multiplier, not just the clamp.
  SELECT is(
    (SELECT ROUND(similarity::numeric, 4) FROM recommend_recipes('j2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL)
     WHERE recipe_id = 'j2000001-0000-0000-0000-000000000020'::uuid),
    0.9000::numeric,
    'fan-subscribed creator recipe similarity is boosted to exactly 0.9 (0.6 * 1.5)'
  );

  -- The boost ratio between the two equal-baseline recipes is exactly 1.5.
  SELECT is(
    (SELECT ROUND(
       (fan.similarity / other.similarity)::numeric, 2
     )
     FROM recommend_recipes('j2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL) fan,
          recommend_recipes('j2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL) other
     WHERE fan.recipe_id = 'j2000001-0000-0000-0000-000000000020'::uuid
       AND other.recipe_id = 'j2000001-0000-0000-0000-000000000021'::uuid),
    1.50::numeric,
    'fan-mode boost ratio between two equal-baseline recipes is exactly 1.5x'
  );

  -- The fan-subscribed recipe ranks strictly first when ordered by similarity.
  SELECT is(
    (SELECT recipe_id FROM recommend_recipes('j2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL)
     ORDER BY similarity DESC LIMIT 1),
    'j2000001-0000-0000-0000-000000000020'::uuid,
    'fan-subscribed creator recipe ranks first once boosted, despite equal base similarity'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run and confirm all 5 assertions pass**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase db reset
  supabase test db 2>&1 | grep -E "recommend_recipes executes for the owning user|non-fan creator recipe raw similarity|fan-subscribed creator recipe similarity is boosted|fan-mode boost ratio between|fan-subscribed creator recipe ranks first"
  ```
  Expected output: 5 lines, every one starting with `ok`.

- [ ] **Step 4: Commit**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/tests/recommend_recipes_fan_mode_test.sql
  git commit -m "$(cat <<'EOF'
  test(beauty): add pgTAP coverage for the corrected fan-mode 1.5x recommendation boost

  Zero SQL/RPC test coverage existed for the fan-mode similarity boost.
  Asserts the exact 1.5x multiplier (not just its 1.0 clamp ceiling) using
  two recipes with identical raw cosine similarity, and that the
  fan-subscribed creator's recipe ranks first as a result.

  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 3: `supabase/tests/generate_beauty_plan_test.sql` — new pgTAP coverage for the corrected 30-day plan generator

**Prerequisite: BLOCKED on Area B Tasks 1, 4, 5 and 6** (`beauty_plan.is_active` column, `p_frequency` passed on month-tier calls, plan-length-relative month anchors, and the full fallback-coverage migration `supabase/migrations/20260722100500_beauty_plan_full_fallback_coverage.sql`, which is the final `CREATE OR REPLACE` of `generate_beauty_plan` in Area B's plan). Do not run this file until all four of those migrations exist.

**Files:**
- Create: `supabase/tests/generate_beauty_plan_test.sql`

**Interfaces:**
- Tests: `generate_beauty_plan(p_user_id UUID, p_start_date DATE DEFAULT CURRENT_DATE, p_days INT DEFAULT 30) RETURNS UUID` (the 3-argument overload, Area B's final corrected version).

- [ ] **Step 1: Confirm the prerequisite migration exists**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -l "daily_care_fallback" supabase/migrations/20260722100500_beauty_plan_full_fallback_coverage.sql
  ```
  Expected output: the file path echoed back (confirms Area B Task 6, the final version, has landed). If this file does not exist, STOP — do not proceed with this task yet.

- [ ] **Step 2: Create the test file**

  Create `supabase/tests/generate_beauty_plan_test.sql`:
  ```sql
  -- supabase/tests/generate_beauty_plan_test.sql
  -- Beauty Mode Branch Review 2026-07-23, Area J, Finding #1(c): zero SQL/RPC
  -- test coverage exists for generate_beauty_plan / the monthly plan generator.
  -- Written against the FINAL corrected function from Area B Task 6
  -- (supabase/migrations/20260722100500_beauty_plan_full_fallback_coverage.sql),
  -- built on top of Area B Tasks 1, 4 and 5 (is_active column, p_frequency
  -- passed on month-tier calls, and plan-length-relative month anchors).
  --
  -- PREREQUISITE: BLOCKED on Area B Tasks 1, 4, 5 and 6. Do not run this file
  -- until all four of those migrations exist in supabase/migrations/ --
  -- generate_beauty_plan will error with "column is_active does not exist"
  -- (Task 1 missing) or insert a day-30 duplicate recipe under two frequency
  -- tiers (Tasks 4/5 missing) otherwise.
  --
  -- No synthetic recipes are seeded here: the permanently-seeded starter
  -- catalog (supabase/migrations/20260720000011, tagged by 20260721000001)
  -- already ships 6 'daily', 7 '2x_week', 6 '1x_week', 2 '2x_month' and 1
  -- '1x_month' published beauty recipes -- enough to generate a full 30-day
  -- plan with zero fallback branches triggering.
  BEGIN;
  SELECT plan(8);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('j3000001-0000-0000-0000-000000000001', 'planintegrity.user@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
    ('j3000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  SET LOCAL "request.jwt.claims" TO '{"sub": "j3000001-0000-0000-0000-000000000001"}';

  SELECT lives_ok(
    $$ SELECT generate_beauty_plan('j3000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 30) $$,
    'generate_beauty_plan executes for a full 30-day plan'
  );

  -- Every one of the 30 days has at least one slot.
  SELECT is(
    (SELECT count(DISTINCT bps.day_number)::int
     FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'j3000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE),
    30,
    'all 30 days of the plan have at least one slot'
  );

  -- No (day_number, recipe_id) pair repeats -- the exact regression this
  -- finding is about (2x_month/1x_month both landing the same top-1 recipe on
  -- the same day under two different labels).
  SELECT is(
    (SELECT count(*)::int FROM (
       SELECT bps.day_number, bps.recipe_id
       FROM beauty_plan_slot bps
       JOIN beauty_plan bp ON bp.id = bps.plan_id
       WHERE bp.user_id = 'j3000001-0000-0000-0000-000000000001'
         AND bp.start_date = CURRENT_DATE
       GROUP BY bps.day_number, bps.recipe_id
       HAVING count(*) > 1
     ) dupes),
    0,
    'no recipe_id is inserted twice for the same day_number anywhere in the plan'
  );

  -- Exactly 2 total 2x_month-tier slots across the whole plan (day 15 and day 30).
  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'j3000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.frequency_tier = '2x_month'),
    2,
    'exactly 2 total 2x_month-tier slots exist (anchors at day 15 and day 30)'
  );

  -- Exactly 1 total 1x_month-tier slot across the whole plan (day 30 only).
  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'j3000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.frequency_tier = '1x_month'),
    1,
    'exactly 1 total 1x_month-tier slot exists (anchor at day 30 only)'
  );

  -- Day 30 has exactly one 2x_month slot...
  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'j3000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.day_number = 30
       AND bps.frequency_tier = '2x_month'),
    1,
    'day 30 has exactly one 2x_month slot'
  );

  -- ...and exactly one 1x_month slot...
  SELECT is(
    (SELECT count(*)::int FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'j3000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
       AND bps.day_number = 30
       AND bps.frequency_tier = '1x_month'),
    1,
    'day 30 has exactly one 1x_month slot'
  );

  -- ...and those two same-day slots reference DIFFERENT recipes.
  SELECT ok(
    (SELECT
       (SELECT bps.recipe_id FROM beauty_plan_slot bps JOIN beauty_plan bp ON bp.id = bps.plan_id
        WHERE bp.user_id = 'j3000001-0000-0000-0000-000000000001' AND bp.start_date = CURRENT_DATE
          AND bps.day_number = 30 AND bps.frequency_tier = '2x_month')
       IS DISTINCT FROM
       (SELECT bps.recipe_id FROM beauty_plan_slot bps JOIN beauty_plan bp ON bp.id = bps.plan_id
        WHERE bp.user_id = 'j3000001-0000-0000-0000-000000000001' AND bp.start_date = CURRENT_DATE
          AND bps.day_number = 30 AND bps.frequency_tier = '1x_month')
    ),
    'day 30''s 2x_month and 1x_month slots reference two different recipes, not a duplicate'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 3: Run and confirm all 8 assertions pass**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  supabase db reset
  supabase test db 2>&1 | grep -E "generate_beauty_plan executes for a full 30-day plan|all 30 days of the plan have|no recipe_id is inserted twice|exactly 2 total 2x_month-tier|exactly 1 total 1x_month-tier|day 30 has exactly one 2x_month|day 30 has exactly one 1x_month|reference two different recipes"
  ```
  Expected output: 8 lines, every one starting with `ok`.

- [ ] **Step 4: Commit**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add supabase/tests/generate_beauty_plan_test.sql
  git commit -m "$(cat <<'EOF'
  test(beauty): add pgTAP coverage for the corrected 30-day plan generator

  Zero SQL/RPC test coverage existed for generate_beauty_plan. Asserts every
  day of a 30-day plan gets at least one slot, that no recipe is duplicated
  within the same day, and specifically that the day-30 2x_month/1x_month
  anchors (which previously collided on the same top-1 recipe) reference two
  distinct recipes.

  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 4: FastAPI `/compute-user-vector` beauty-mode endpoint test — already covered, no action needed

**Prerequisite:** none — this task is a documentation-only conclusion, not an implementation step.

**Files:** none.

**Interfaces:** none.

- [ ] **Step 1: Confirm Area D's plan already adds this exact test**

  Read `docs/superpowers/plans/2026-07-23-beauty-fix-d-python-vectorization.md`, Task 11 (`### Task 11: test_main.py never posts mode: "beauty" through the actual FastAPI endpoint`). It appends this test to `python/tests/test_main.py`:
  ```python
  @patch("main.upsert_user_vector")
  @patch("main.compute_user_vector")
  def test_compute_user_vector_endpoint_beauty_mode(mock_compute, mock_upsert):
      """/compute-user-vector must thread mode="beauty" through to compute_user_vector
      end-to-end via the real FastAPI TestClient (Finding #11 — this path was never
      exercised; only mocked-function unit assertions existed before)."""
      mock_compute.return_value = np.zeros(VECTOR_DIM, dtype=np.float32)

      response = client.post("/compute-user-vector", json={"user_id": "user_beauty_1", "mode": "beauty"})

      assert response.status_code == 200
      assert response.json()["user_id"] == "user_beauty_1"
      assert response.json()["mode"] == "beauty"
      assert response.json()["vector_computed"] is True
      mock_compute.assert_called_once_with("user_beauty_1", mode="beauty")
      mock_upsert.assert_called_once()
  ```
  This is exactly this finding's required assertion (POST `{"user_id": ..., "mode": "beauty"}` to `/compute-user-vector`, asserting the downstream `compute_user_vector` call received `mode="beauty"`).

- [ ] **Step 2: Conclusion — DROP this task**

  No new work is added here. This finding is fully addressed by Area D Task 11. See the Coverage Checklist below.

---

### Task 5: `test/features/beauty/widgets/beauty_checkin_sheet_test.dart` — already covered, no action needed

**Prerequisite:** none — this task is a documentation-only conclusion, not an implementation step.

**Files:** none.

**Interfaces:** none.

- [ ] **Step 1: Confirm Area F's plan already rewrites this exact test file**

  Read `docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md`, `## Task 1: Fix check-in key-casing mismatch (Critical)`. Its Step 1 **replaces the entire file** `test/features/beauty/widgets/beauty_checkin_sheet_test.dart` with two `testWidgets` blocks that assert against the real, correct camelCase keys `beauty_analytics_page.dart` actually reads — not the sheet's own (previously wrong) output. Confirmed verbatim in Area F's plan:
  ```dart
  expect(submittedData!['userId'], equals('test-user-123'));
  expect(submittedData!['hairLengthCm'], equals(30.0));
  expect(submittedData!['hairStrengthScore'], equals(8.0));
  // hairThicknessScore / skinClarityScore are new fields this task adds;
  // they must reach the payload even when the user never touches them.
  expect(submittedData!['hairThicknessScore'], equals(7.0));
  expect(submittedData!['skinClarityScore'], equals(7.0));
  ```
  and, in the file's second test (dragging the hair-length slider to a non-default value via direct `Slider.onChanged` invocation rather than a pixel-based drag):
  ```dart
  // This assertion fails against the current snake_case payload: the
  // key `hair_length_cm` exists but `hairLengthCm` does not, so
  // `submittedData!['hairLengthCm']` reads `null`, and `null == 25.0`
  // is false.
  expect(submittedData!['hairLengthCm'], equals(25.0));
  ```
  Area F's plan also appends an integration-level test to `test/features/beauty/beauty_analytics_page_test.dart` exercising the full `_openCheckinSheet` → `addBeautyLogNotifierProvider.addLog(...)` round trip. This is exactly the "assert against the real integration point, not the sheet's own wrong output" fix this finding calls for.

- [ ] **Step 2: Conclusion — DROP this task**

  No new work is added here. This finding is fully addressed by Area F Task 1. See the Coverage Checklist below.

---

### Task 6: `test/features/beauty/widgets/today_beauty_routines_widget_test.dart` — already covered, no action needed

**Prerequisite:** none — this task is a documentation-only conclusion, not an implementation step.

**Files:** none.

**Interfaces:** none.

- [ ] **Step 1: Confirm Area F's plan already rewrites this exact test file**

  Read `docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md`, `## Task 2: Fix "Today's Rituals" day-filter bug (Critical)`. Its Step 1 **replaces the entire file** `test/features/beauty/widgets/today_beauty_routines_widget_test.dart`, adding a `TodayBeautyRoutinesWidget({..., this.now = DateTime.now})` clock-injection parameter and a second test that seeds a plan starting mid-month (`DateTime(2026, 7, 10)`) with two slots:
  ```dart
  // Correct slot for "today" (July 12): plan day 3.
  BeautyPlanSlot(..., dayNumber: 3, stepStage: 'Soin Jour 3 Correct', ...),
  // Under the OLD buggy logic (`dayNumber == today.day`), this slot
  // (dayNumber: 12) would incorrectly match "today" (July 12, i.e.
  // today.day == 12) even though its real calendar date is plan
  // day 12 = July 21, not today.
  BeautyPlanSlot(..., dayNumber: 12, stepStage: 'Soin Jour 12 Ne Doit Pas Apparaitre', ...),
  ```
  then, with a fixed injected clock (`now: () => DateTime(2026, 7, 12)`), asserts:
  ```dart
  expect(find.text('Soin Jour 3 Correct'), findsOneWidget);
  expect(find.text('Soin Jour 12 Ne Doit Pas Apparaitre'), findsNothing);
  ```
  This is a deterministic, non-coincidental regression test for the exact bug this finding describes (the old mock fixture's `dayNumber: now.day` trick, which artificially satisfied the buggy comparison, is gone — replaced by a decoy slot specifically engineered to expose it).

- [ ] **Step 2: Conclusion — DROP this task**

  No new work is added here. This finding is fully addressed by Area F Task 2. See the Coverage Checklist below.

---

### Task 7: `test/shared/widgets/color_set_modal_test.dart` — already covered by Area F Task 7, no action needed here

**CORRECTION (orchestrator self-review, 2026-07-23):** This task originally concluded Area F's plan did not address this finding, based on a read of `docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md` taken while that file was still being written concurrently (it had only 3 tasks at read time). Area F's finished plan has **7 tasks**; its Task 7 ("Give `ColorSetModal` real Hive persistence via a new `color_set_provider.dart`") does exactly the work this task was about to flag as unowned:

- It creates `lib/providers/color_set_provider.dart` (`ColorSetNotifier`/`colorSetProvider`), persisting the selected preset to the existing `mode_state` Hive box under key `selected_color_set_id`.
- It adds a **new** test file `test/providers/color_set_provider_test.dart` with 3 real, non-hollow assertions: default preset when nothing is persisted, `selectPreset` writes through to Hive and updates state, and a fresh provider instance round-trips a previously-persisted value from Hive.
- It wires `ColorSetModal`'s own Apply button to `colorSetProvider.notifier.selectPreset(...)`.
- It explicitly documents (its own Step 6) that `test/shared/widgets/color_set_modal_test.dart` itself is deliberately left asserting only the modal's returned preset value, in isolation — because the persistence behavior now has its own dedicated, correct test (`color_set_provider_test.dart`) rather than being bolted onto the widget test. That is the right shape for this test suite, not a gap: a widget test should assert what the widget renders/returns; a provider test should assert persistence. Splitting them is preferable to one file doing both.
- Area F's Task 7 also explicitly documents what remains **out of its scope** (and is not part of any test-coverage gap): `lib/core/theme.dart` (Area G) doesn't yet read `colorSetProvider`, and no screen (Area H's `settings_page.dart`) yet calls `ColorSetModal.show(...)`. Those are feature-wiring gaps, not test-coverage gaps — out of scope for this Area J plan either way.

**Conclusion: no task needed here.** `color_set_modal_test.dart` staying narrow is correct once `color_set_provider_test.dart` exists; do not modify `color_set_modal_test.dart` as part of this plan. If, at execution time, `docs/superpowers/plans/2026-07-23-beauty-fix-f-beauty-ui.md`'s Task 7 has NOT actually landed in the codebase yet (verify with `grep -n "colorSetProvider" lib/providers/color_set_provider.dart` — expect a match; if the file doesn't exist, Area F's Task 7 hasn't run yet), re-check this conclusion before skipping, since the correction above assumes Area F's Task 7 executes as written.

---

### Task 8: `test/features/beauty/beauty_onboarding_page_test.dart` — exercise the final submit button end-to-end

**Prerequisite:** none — this test exercises code that already exists and compiles today; it is not blocked on any other area's fix.

**Files:**
- Modify: `test/features/beauty/beauty_onboarding_page_test.dart`

**Interfaces:**
- Tests: `UserProfileNotifier.completeBeautyOnboarding({required String hairType, required String porosity, required String skinType, required String scalpType, required List<String> beautyGoals, List<String> skinConcerns, double hairLengthCm, double hairStrengthScore, double hairThicknessScore, String hairSheddingRate, double skinHydrationLevel, double skinClarityScore, String checkinNotes})` (`lib/providers/user_profile_provider.dart:234-248`), invoked from `BeautyOnboardingPage._handleNextOrSubmit()` (`lib/features/beauty/beauty_onboarding_page.dart:704-744`).

- [ ] **Step 1: Confirm the current gap**

  The existing `test/features/beauty/beauty_onboarding_page_test.dart` only pumps a bare `BeautyOnboardingPage` (no `ProviderScope` overrides, no `GoRouter`) and stops after asserting Step 5's summary text is visible — it never taps `'Confirmer & Générer Mon Plan 30 Jours ✨'`. Confirm this by reading the file:
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -c "Confirmer & Générer" test/features/beauty/beauty_onboarding_page_test.dart
  grep -c "tester.tap" test/features/beauty/beauty_onboarding_page_test.dart
  ```
  Expected output: `1` (the button text appears once, only in an `expect(find.text(...), findsOneWidget)` assertion) and `4` (four `tester.tap` calls, one per `'Étape Suivante ➔'` navigation — none of them tap the submit button itself).

- [ ] **Step 2: Add the new test**

  Open `test/features/beauty/beauty_onboarding_page_test.dart`. Find the existing imports at the top:
  ```dart
  import 'package:akeli/features/beauty/beauty_onboarding_page.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  ```
  Replace with:
  ```dart
  import 'package:akeli/core/router.dart';
  import 'package:akeli/features/beauty/beauty_onboarding_page.dart';
  import 'package:akeli/providers/user_profile_provider.dart';
  import 'package:akeli/shared/models/user_profile.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:go_router/go_router.dart';

  /// Records the exact arguments BeautyOnboardingPage's submit handler passes
  /// to completeBeautyOnboarding, without touching Supabase/auth at all —
  /// this fully overrides the method body rather than calling super, so the
  /// real UserProfileNotifier.build()'s dependency on currentUserProvider is
  /// never exercised.
  class _RecordingUserProfileNotifier extends UserProfileNotifier {
    bool wasCalled = false;
    Map<String, dynamic>? capturedArgs;

    @override
    Future<UserProfile?> build() async => null;

    @override
    Future<void> completeBeautyOnboarding({
      required String hairType,
      required String porosity,
      required String skinType,
      required String scalpType,
      required List<String> beautyGoals,
      List<String> skinConcerns = const [],
      double hairLengthCm = 15,
      double hairStrengthScore = 7,
      double hairThicknessScore = 7,
      String hairSheddingRate = 'moderate',
      double skinHydrationLevel = 7,
      double skinClarityScore = 7,
      String checkinNotes = 'Premier journal de bord initial',
    }) async {
      wasCalled = true;
      capturedArgs = {
        'hairType': hairType,
        'porosity': porosity,
        'skinType': skinType,
        'scalpType': scalpType,
        'beautyGoals': beautyGoals,
        'skinConcerns': skinConcerns,
        'hairLengthCm': hairLengthCm,
        'hairStrengthScore': hairStrengthScore,
        'hairThicknessScore': hairThicknessScore,
        'hairSheddingRate': hairSheddingRate,
        'skinHydrationLevel': skinHydrationLevel,
        'skinClarityScore': skinClarityScore,
        'checkinNotes': checkinNotes,
      };
    }
  }
  ```

  Now find the closing of `void main() { ... }` — the file ends with the existing `testWidgets(...)` block followed by:
  ```dart
    // Tap Next → Step 5: Resume & Confirmation
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Résumé & Confirmation'), findsOneWidget);
    expect(find.textContaining('👑 Profil Capillaire'), findsOneWidget);
    expect(find.textContaining('✨ Diagnostic Cutané'), findsOneWidget);
    expect(find.textContaining('📊 Mesures du Premier Bilan'), findsOneWidget);
    expect(find.text('Confirmer & Générer Mon Plan 30 Jours ✨'), findsOneWidget);
  });
  }
  ```
  Insert a second `testWidgets` block immediately after that closing `});` and before the final `}` of `void main()`:
  ```dart

    testWidgets(
      'BeautyOnboardingPage completes all 5 wizard steps, taps the final submit '
      'button, calls completeBeautyOnboarding with the accumulated form data, '
      'and navigates away on success',
      (WidgetTester tester) async {
    final fakeNotifier = _RecordingUserProfileNotifier();

    final testRouter = GoRouter(
      initialLocation: '/beauty-onboarding-test',
      routes: [
        GoRoute(
          path: '/beauty-onboarding-test',
          builder: (context, state) => const BeautyOnboardingPage(),
        ),
        GoRoute(
          path: AkeliRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('Home Placeholder')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileNotifierProvider.overrideWith(() => fakeNotifier),
        ],
        child: MaterialApp.router(routerConfig: testRouter),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: Hair — change porosity from its default 'medium' to 'high'.
    expect(find.text('Profil Beauté Botanique'), findsOneWidget);
    await tester.tap(find.text('Fortement Poreuse (Écailles ouvertes)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();

    // Step 2: Skin — uncheck the default 'dehydration' concern, check 'acne_imperfections'.
    expect(find.textContaining('Diagnostic Cutané Profond'), findsOneWidget);
    await tester.tap(find.text('💧 Déshydratation Profonde & Perte d\'Éclat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌋 Boutons & Imperfections'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();

    // Step 3: Goals — uncheck the default 'skin_moisture' goal, check 'skin_anti_spot'.
    expect(find.textContaining('Objectifs Beauté & Priorités'), findsOneWidget);
    await tester.tap(find.text('💧 Hydratation & Souplesse Cutanée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌖 Atténuation des Taches & Hyperpigmentation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();

    // Step 4: First Beauty Log — leave every slider/field at its default value.
    expect(find.textContaining('Premier Bilan Initial'), findsOneWidget);
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();

    // Step 5: Resume & Confirmation — tap the final submit button.
    expect(find.textContaining('Résumé & Confirmation'), findsOneWidget);
    await tester.tap(find.text('Confirmer & Générer Mon Plan 30 Jours ✨'));
    await tester.pumpAndSettle();

    // completeBeautyOnboarding was called exactly once, with the exact
    // accumulated form data (defaults except the 3 fields changed above).
    expect(fakeNotifier.wasCalled, isTrue);
    expect(
      fakeNotifier.capturedArgs,
      equals({
        'hairType': '4C',
        'porosity': 'high',
        'skinType': 'mixte_t',
        'scalpType': 'normal',
        'beautyGoals': ['hair_growth', 'hair_moisture', 'skin_glow', 'skin_anti_spot'],
        'skinConcerns': ['hyperpigmentation', 'acne_imperfections'],
        'hairLengthCm': 15.0,
        'hairStrengthScore': 7.0,
        'hairThicknessScore': 7.0,
        'hairSheddingRate': 'moderate',
        'skinHydrationLevel': 7.0,
        'skinClarityScore': 7.0,
        'checkinNotes': 'Bilan initial du profil beauté',
      }),
    );

    // A success navigation away from the onboarding wizard occurred.
    expect(find.text('Home Placeholder'), findsOneWidget);
    expect(find.byType(BeautyOnboardingPage), findsNothing);
      },
    );
  }
  ```

- [ ] **Step 3: Run and confirm it passes**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  flutter test test/features/beauty/beauty_onboarding_page_test.dart
  ```
  Expected output: `00:0X +2: All tests passed!` (the pre-existing render test plus the new submit-flow test, both green).

- [ ] **Step 4: Commit**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add test/features/beauty/beauty_onboarding_page_test.dart
  git commit -m "$(cat <<'EOF'
  test(beauty): exercise BeautyOnboardingPage's final submit button end-to-end

  The existing test never tapped 'Confirmer & Générer Mon Plan 30 Jours' —
  the one meaningfully risky code path (onboarding completion + accumulated
  form-data threading) was never exercised. Adds a full 5-step walkthrough
  that changes a selection on 3 of the 5 steps, taps the real submit button,
  and asserts completeBeautyOnboarding is called with the exact accumulated
  data plus a success navigation away from the wizard.

  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  EOF
  )"
  ```

---

### Task 9: `python/tests/test_main.py` nightly-batch mode assertion — already covered, no action needed

**Prerequisite:** none — this task is a documentation-only conclusion, not an implementation step.

**Files:** none.

**Interfaces:** none.

- [ ] **Step 1: Confirm Area D's plan already adds this exact assertion**

  Read `docs/superpowers/plans/2026-07-23-beauty-fix-d-python-vectorization.md`, Task 1 (`### Task 1: Nightly batch must resolve each user's actual mode instead of defaulting to nutrition [Critical]`). Its Step 5 rewrites `test_run_nightly_batch` in `python/tests/test_main.py` to mock `main.get_user_last_mode` and assert:
  ```python
  mock_get_last_mode.side_effect = lambda uid: "beauty" if uid == "user1" else "nutrition"
  ...
  # Finding #1: each user's mode must be resolved via get_user_last_mode and
  # threaded through to compute_user_vector — nightly batch must not silently
  # default every user to mode="nutrition".
  mock_comp_user.assert_any_call("user1", mode="beauty")
  mock_comp_user.assert_any_call("user2", mode="nutrition")
  ```
  This is exactly this finding's required assertion (the nightly-batch test must assert what `mode` argument `compute_user_vector` receives, not just that it was called).

- [ ] **Step 2: Conclusion — DROP this task**

  No new work is added here. This finding is fully addressed by Area D Task 1. See the Coverage Checklist below.

---

### Task 10: Reconcile the Flutter test-count claims in `docs/BEAUTY_MODE_ARCHITECTURE_LOG.md`

**Prerequisite:** none for running the command itself, but the NUMBERS you record will only be meaningful once Areas A-I have landed their fixes (in particular Area E's fix to `test/shared/models/beauty_log_test.dart`, which currently fails to compile — see Step 1). Run this task LAST, after every other area's plan (A-I) and this plan's own Tasks 1-9 have been committed.

**Files:**
- Modify: `docs/BEAUTY_MODE_ARCHITECTURE_LOG.md`

**Interfaces:** none — documentation only.

- [ ] **Step 1: Run the full Flutter test suite and capture the real summary**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  flutter test 2>&1 | tail -5
  ```
  Read the final line of output. It will be in one of these two shapes:
  ```
  01:39 +249 -1: Some tests failed.
  ```
  or, if every test passes:
  ```
  01:39 +249: All tests passed!
  ```
  The `+N` number is the passing-test count; the `-M` number (if present) is the failing-test count; the total is `N + M` (or just `N` if there is no `-M`).

  **Worked example — this plan's own verified baseline run, 2026-07-23, on this branch's HEAD before any Area A-J fixes were applied:**
  ```
  01:39 +249 -1: Some tests failed.
  ```
  i.e. 249 passing, 1 failing, 250 total. The single failure was confirmed (via `grep -n "Failed to load" ` on the full log) to be a compilation error in `test/shared/models/beauty_log_test.dart` — the exact bug the branch review's Executive Summary #9 describes. **Do not reuse these numbers verbatim** — by the time you run this task, Area E's plan should have already fixed `beauty_log_test.dart` and every other area's new tests (including this plan's own Tasks 1, 2, 3, 8) will have changed the total. Use the actual numbers from YOUR OWN run in Step 2 below.

- [ ] **Step 2: Insert the reconciliation sentence**

  Open `docs/BEAUTY_MODE_ARCHITECTURE_LOG.md`. Find these exact opening lines:
  ```markdown
  # 👑 Akeli Beauty Mode — 50D Vector Engine, Evolution System & Creator Payout Architecture
  > **Technical Architecture, Data Models, SQL Migrations, UI Components & Royalty Engine Specification**  
  > *Last Updated: July 21, 2026*

  ---

  ## 📑 Executive Summary
  ```
  Insert one new blockquote line immediately after the `---` and before the blank line preceding `## 📑 Executive Summary`, so the block reads:
  ```markdown
  # 👑 Akeli Beauty Mode — 50D Vector Engine, Evolution System & Creator Payout Architecture
  > **Technical Architecture, Data Models, SQL Migrations, UI Components & Royalty Engine Specification**  
  > *Last Updated: July 21, 2026*

  ---

  > **Verified test count reconciliation (add today's date here, e.g. 2026-0X-XX):** An independent full run of `flutter test` on this branch recorded **<N> passing / <M> failing / <N+M> total** Flutter tests (see `docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md` and `docs/superpowers/plans/2026-07-23-beauty-fix-j-test-coverage.md` for methodology). This is the one authoritative count for this date; it supersedes every `243`/`244`/`245` figure quoted throughout the entries below, none of which was independently reconciled at the time it was written.

  ## 📑 Executive Summary
  ```
  Replace `<N>`, `<M>`, `<N+M>`, and the date placeholder with the exact numbers and date from your own Step 1 run — for example, if your run reproduces this plan's own baseline exactly, the sentence would read:
  ```markdown
  > **Verified test count reconciliation (2026-07-23):** An independent full run of `flutter test` on this branch recorded **249 passing / 1 failing / 250 total** Flutter tests (see `docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md` and `docs/superpowers/plans/2026-07-23-beauty-fix-j-test-coverage.md` for methodology). This is the one authoritative count for this date; it supersedes every `243`/`244`/`245` figure quoted throughout the entries below, none of which was independently reconciled at the time it was written.
  ```
  Do not leave any `<...>` placeholder text in the committed file — every angle-bracket token above must be replaced with a real number or date before you save.

- [ ] **Step 3: Verify the edit**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  grep -n "Verified test count reconciliation" docs/BEAUTY_MODE_ARCHITECTURE_LOG.md
  ```
  Expected output: exactly one matching line, with no `<N>`/`<M>`/`<N+M>`/date placeholder tokens remaining in it.

- [ ] **Step 4: Commit**
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
  git add docs/BEAUTY_MODE_ARCHITECTURE_LOG.md
  git commit -m "$(cat <<'EOF'
  docs(beauty): reconcile the architecture log's repeated 243/244/245 test-count claims to one verified number

  The log's own Flutter test-count claims (243 -> 245 -> 244) were never
  reconciled to a single stable, independently-verified total across
  successive entries. Adds one dated sentence at the top of the document
  recording the actual result of a full `flutter test` run.

  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  EOF
  )"
  ```

---

## Coverage Checklist

| # | Finding | Task | Status |
|---|---------|------|--------|
| 1(a) | Zero SQL/RPC test coverage for `calculate_creator_payouts` payout math | Task 1 | New pgTAP test added (`supabase/tests/calculate_creator_payouts_test.sql`) — **blocked on Area C Task 2** |
| 1(b) | Zero SQL/RPC test coverage for the fan-mode 1.5x recommendation boost | Task 2 | New pgTAP test added (`supabase/tests/recommend_recipes_fan_mode_test.sql`) — **blocked on Area A Task 2** |
| 1(c) | Zero SQL/RPC test coverage for `generate_beauty_plan` / the monthly plan generator | Task 3 | New pgTAP test added (`supabase/tests/generate_beauty_plan_test.sql`) — **blocked on Area B Tasks 1, 4, 5, 6** |
| 2 | FastAPI `/compute-user-vector` beauty-mode endpoint path untested | Task 4 | **Already covered by Area D Task 11** (`test_compute_user_vector_endpoint_beauty_mode`) — dropped, no duplicate added |
| 3(a) | `beauty_checkin_sheet_test.dart` asserts the sheet's own (wrong) key names | Task 5 | **Already covered by Area F Task 1** — file fully rewritten to assert real camelCase contract — dropped, no duplicate added |
| 3(b) | `today_beauty_routines_widget_test.dart` mock fixture artificially satisfies the buggy day filter | Task 6 | **Already covered by Area F Task 2** — file fully rewritten with a deterministic decoy-slot regression test — dropped, no duplicate added |
| 3(c) | `color_set_modal_test.dart` tests a modal with no real wiring/persistence | Task 7 | **CORRECTED (orchestrator self-review):** initially flagged as unowned based on a stale concurrent read of Area F's in-progress plan. Area F's *finished* plan has 7 tasks; Task 7 adds `lib/providers/color_set_provider.dart` + a new, real `test/providers/color_set_provider_test.dart` covering persistence with 3 non-hollow assertions. `color_set_modal_test.dart` itself correctly stays narrow (widget-only assertions) by design — no fix needed here. |
| 3(d) | `beauty_onboarding_page_test.dart` never taps the final submit button | Task 8 | Fixed — new test added exercising all 5 wizard steps + real submit, asserting exact accumulated `completeBeautyOnboarding` args and success navigation |
| 3(e) | `test_main.py` nightly-batch test never asserts the `mode` argument | Task 9 | **Already covered by Area D Task 1** (`mock_comp_user.assert_any_call("user1", mode="beauty")` etc.) — dropped, no duplicate added |
| 3(f) | Architecture log's `243`/`244`/`245` test-count claims never reconciled | Task 10 | Fixed — one dated, verified-count sentence inserted at the top of `docs/BEAUTY_MODE_ARCHITECTURE_LOG.md`, based on an actual `flutter test` run (baseline run recorded 2026-07-23: 249 passing / 1 failing / 250 total) |

**Summary:** 5 of 10 findings result in new test coverage authored by this plan (Tasks 1, 2, 3, 8, 10); 5 are already fully covered by other areas' plans and are explicitly dropped here to avoid duplication (Tasks 4, 5, 6, 7, 9) — Task 7 (`color_set_modal_test.dart`) was corrected during orchestrator self-review after being initially (and incorrectly) flagged as unowned based on a stale read of Area F's plan while it was still being written concurrently.
