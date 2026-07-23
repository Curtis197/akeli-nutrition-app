# Beauty Mode Fix — Area C: SQL Revenue/Payout Engine, Onboarding, Community & Shopping

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the 10 confirmed Area C findings — broken/missing authorization on 4 RPCs, a cross-system revenue double-count, an ambiguous function overload, a wrong RLS idiom, a missing cron wire-up, a missing community mode filter, a non-compliant logging pattern, and a stale audit doc — without touching any file outside this plan's ownership.

**Architecture:** Every SQL fix is a new, additive migration (`CREATE OR REPLACE FUNCTION`, `DROP FUNCTION`, `DROP POLICY`/`CREATE POLICY`, or `REVOKE`/`GRANT`) layered on top of the existing chain of Beauty Mode migrations — nothing already applied is edited in place. One new Deno edge function mirrors the existing `compute-monthly-revenue` cron pattern. One Dart provider gains a mode-aware RPC parameter, resolved internally from `currentModeProvider` so no caller needs to change.

**Tech Stack:** PostgreSQL/Supabase migrations, Deno edge functions, pgTAP.

## Global Constraints

- Repo: `c:\Users\DELL LATITUDE 7480\akeli-nutrition-app`, branch `sdui`.
- Every SQL fix is a NEW migration file under `supabase/migrations/` with timestamp prefix `20260722110000+` (increment by 100 per file) — never edit an existing committed migration.
- CLAUDE.md's Deno logging standard applies to any edge function you touch or create.
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- Only touch files listed as "owned" above (plus the two new files Finding #4 explicitly requires: `supabase/functions/compute-monthly-beauty-revenue/index.ts` and the `[functions.compute-monthly-beauty-revenue]` block in `supabase/config.toml` — both did not exist before this plan, so they cannot have been "owned" previously).
- Test execution command for every task in this plan: `supabase db reset` then `supabase test db` (matches this repo's existing pgTAP convention, see `docs/superpowers/plans/2026-07-17-creator-blog-v2-phase1-schema-backend.md`).
- **Known cross-plan dependency (Area B, not owned by this plan):** `beauty_plan.is_active` is referenced by `generate_beauty_plan`/`generate_initial_beauty_plan`/`generate_beauty_plan_from_saved` (all in Area B's `20260721000019/20/21/22`) but the column is never added to `beauty_plan` anywhere in the codebase (confirmed by grep). This means the **full success path** of `complete_beauty_onboarding` (Task 1) — a legitimate user completing onboarding end-to-end — cannot be exercised today regardless of this plan's fix, because it calls `generate_initial_beauty_plan` → `generate_beauty_plan`, which will error on the missing column. Task 1's pgTAP test is deliberately scoped to prove only the authorization boundary (which is fully self-contained and unaffected by the Area B gap); it explicitly does not assert full onboarding success. Once Area B adds `beauty_plan.is_active`, no further change is needed here.
- **Adjacent bug fixed inline (within this plan's own owned files, not a new finding):** `creator_monthly_payouts` was created by `20260521000003` with `creator_id UUID REFERENCES auth.users(id)` and no `updated_at` column. `20260721000013`'s own `CREATE TABLE IF NOT EXISTS creator_monthly_payouts` (with the correct `creator_id → creator(id)` shape and an `updated_at` column) therefore never actually applied — Postgres's `CREATE TABLE IF NOT EXISTS` is an all-or-nothing no-op when the relation already exists. Consequently, as shipped, **every call to `calculate_creator_payouts` already fails today** — either with a foreign-key violation (`recipe.creator_id`/`creator.id` values do not exist in `auth.users`) or, past that, `column "updated_at" of relation "creator_monthly_payouts" does not exist`. Task 2 (Finding #2, the only task that rewrites this function and needs it to actually run in order to be pgTAP-testable) repairs this schema mismatch as a required prerequisite, using a dynamic constraint-name lookup (not a guessed name) so it is safe regardless of what Postgres auto-named the original constraint.

---

## Task 1: `complete_beauty_onboarding` — add owner-only authorization check

**Files:**
- Create: `supabase/migrations/20260722110000_fix_complete_beauty_onboarding_authorization.sql`
- Create: `supabase/tests/complete_beauty_onboarding_authorization_test.sql`

**Interfaces:**
- `complete_beauty_onboarding(p_user_id uuid, p_hair_type text, p_porosity text, p_skin_type text, p_scalp_type text, p_beauty_goals text[], p_skin_concerns text[] DEFAULT '{}', p_hair_length_cm numeric DEFAULT 15, p_hair_strength_score numeric DEFAULT 7, p_hair_thickness_score numeric DEFAULT 7, p_hair_shedding_rate text DEFAULT 'moderate', p_skin_hydration_level numeric DEFAULT 7, p_skin_clarity_score numeric DEFAULT 7, p_checkin_notes text DEFAULT 'Premier journal de bord initial') RETURNS boolean` — signature unchanged, `CREATE OR REPLACE` in place.

The current live version of this function was confirmed by reading `20260721000016`, `20260721000017`, and `20260721000018` (the final rewrite; no migration after it touches `complete_beauty_onboarding` — confirmed via `grep -rl "complete_beauty_onboarding" supabase/migrations/`). It has no `auth.uid()` check at all.

- [ ] **Step 1: Write the failing pgTAP test**

  Create `supabase/tests/complete_beauty_onboarding_authorization_test.sql`:

  ```sql
  -- supabase/tests/complete_beauty_onboarding_authorization_test.sql
  -- Finding #1 (Area C): complete_beauty_onboarding has no auth.uid() = p_user_id
  -- check. Any authenticated client can overwrite another user's beauty
  -- health profile / onboarding flag / plan by calling the RPC directly.
  --
  -- NOTE: this test deliberately does NOT assert the full onboarding success
  -- path for the legitimate owner. generate_initial_beauty_plan ->
  -- generate_beauty_plan references beauty_plan.is_active, a column that
  -- Area B (not this plan) never actually adds to the table — see this
  -- plan's Global Constraints. Test 4 below only proves the new guard does
  -- not itself block the rightful owner; it does not require the whole
  -- chain to succeed.
  BEGIN;
  SELECT plan(4);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('a1000001-0000-0000-0000-000000000001'::uuid, 'victim-onboarding@test.local', 'authenticated', now(), now()),
    ('a1000001-0000-0000-0000-000000000002'::uuid, 'attacker-onboarding@test.local', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_profile (id, first_name) VALUES
    ('a1000001-0000-0000-0000-000000000001'::uuid, 'VictimUser'),
    ('a1000001-0000-0000-0000-000000000002'::uuid, 'AttackerUser')
  ON CONFLICT (id) DO NOTHING;

  -- 1. Signature is unchanged (CREATE OR REPLACE must replace in place, not
  --    create a new ambiguous overload).
  SELECT has_function(
    'public', 'complete_beauty_onboarding',
    ARRAY['uuid','text','text','text','text','text[]','text[]','numeric','numeric','numeric','text','numeric','numeric','text'],
    'complete_beauty_onboarding retains its exact 14-parameter signature after the authorization fix'
  );

  -- 2. Still SECURITY DEFINER (unchanged).
  SELECT is(
    (SELECT prosecdef FROM pg_proc WHERE proname = 'complete_beauty_onboarding' LIMIT 1),
    true,
    'complete_beauty_onboarding remains SECURITY DEFINER'
  );

  -- 3. THE core regression test: an attacker cannot onboard on behalf of
  --    another user's p_user_id.
  SET LOCAL "request.jwt.claims" TO '{"sub": "a1000001-0000-0000-0000-000000000002"}';

  SELECT throws_ok(
    $$ SELECT complete_beauty_onboarding(
         'a1000001-0000-0000-0000-000000000001'::uuid,
         'straight', 'low', 'oily', 'normal', ARRAY['hydration']::text[]
       ) $$,
    'Unauthorized',
    'attacker cannot call complete_beauty_onboarding with another user''s p_user_id'
  );

  -- 4. The legitimate owner is never blocked by the new guard (whatever
  --    happens further down the call chain is a separate, already-flagged
  --    Area B concern, not this fix's responsibility).
  SET LOCAL "request.jwt.claims" TO '{"sub": "a1000001-0000-0000-0000-000000000001"}';

  DO $$
  DECLARE
    v_msg text := 'NO_EXCEPTION';
  BEGIN
    BEGIN
      PERFORM complete_beauty_onboarding(
        'a1000001-0000-0000-0000-000000000001'::uuid,
        'straight', 'low', 'oily', 'normal', ARRAY['hydration']::text[]
      );
    EXCEPTION WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
    END;
    PERFORM set_config('pgtap_test.owner_call_result', v_msg, true);
  END;
  $$;

  SELECT isnt(
    current_setting('pgtap_test.owner_call_result', true),
    'Unauthorized',
    'legitimate owner (auth.uid() = p_user_id) is never blocked by the new Unauthorized guard'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 2: Confirm it fails**

  Run: `supabase db reset` then `supabase test db`.
  Expected: test 3 (`throws_ok ... 'Unauthorized'`) FAILS — today, calling as the attacker raises no exception matching `'Unauthorized'` (there is no guard at all, so the call either proceeds or fails on an unrelated error). Tests 1, 2, 4 pass already (they are regression guards, not the vulnerability proof).

- [ ] **Step 3: Implement the fix**

  Create `supabase/migrations/20260722110000_fix_complete_beauty_onboarding_authorization.sql`:

  ```sql
  -- Migration: 20260722110000_fix_complete_beauty_onboarding_authorization.sql
  -- Finding #1 (Area C, Critical): complete_beauty_onboarding is
  -- SECURITY DEFINER with no auth.uid() = p_user_id check. Any authenticated
  -- client can call it directly via supabase.rpc(...), bypassing the
  -- complete-beauty-onboarding edge function's own auth entirely, and
  -- overwrite another user's health profile / onboarding flag / plan.
  --
  -- This CREATE OR REPLACE targets the exact 14-parameter signature that is
  -- live today (confirmed by reading 20260721000016, 20260721000017, and
  -- 20260721000018 — the final rewrite; no later migration touches this
  -- function). Every line below Step 0 is unchanged from 20260721000018.

  CREATE OR REPLACE FUNCTION complete_beauty_onboarding(
    p_user_id              uuid,
    p_hair_type            text,
    p_porosity             text,
    p_skin_type            text,
    p_scalp_type           text,
    p_beauty_goals         text[],
    p_skin_concerns        text[] DEFAULT '{}',
    p_hair_length_cm       numeric DEFAULT 15,
    p_hair_strength_score   numeric DEFAULT 7,
    p_hair_thickness_score  numeric DEFAULT 7,
    p_hair_shedding_rate   text DEFAULT 'moderate',
    p_skin_hydration_level numeric DEFAULT 7,
    p_skin_clarity_score   numeric DEFAULT 7,
    p_checkin_notes        text DEFAULT 'Premier journal de bord initial'
  )
  RETURNS boolean
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$
  BEGIN
    -- Step 0 (new): reject any caller who is not the profile owner.
    IF auth.uid() IS DISTINCT FROM p_user_id THEN
      RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- 1. Upsert user_health_profile
    INSERT INTO user_health_profile (
      user_id, hair_type, porosity, skin_type, sensitive_scalp, beauty_goals, skin_concerns, updated_at
    )
    VALUES (
      p_user_id, p_hair_type, p_porosity, p_skin_type, (p_scalp_type = 'sensitive'), p_beauty_goals, p_skin_concerns, NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
      hair_type = EXCLUDED.hair_type,
      porosity = EXCLUDED.porosity,
      skin_type = EXCLUDED.skin_type,
      sensitive_scalp = EXCLUDED.sensitive_scalp,
      beauty_goals = EXCLUDED.beauty_goals,
      skin_concerns = EXCLUDED.skin_concerns,
      updated_at = NOW();

    -- 2. Mark beauty_onboarding_done = true on user_profile
    UPDATE user_profile
    SET beauty_onboarding_done = true
    WHERE id = p_user_id;

    -- 3. Insert initial baseline beauty_log checkin
    INSERT INTO beauty_log (
      user_id,
      hair_length_cm,
      hair_strength_score,
      hair_thickness_score,
      hair_shedding_rate,
      skin_hydration_level,
      skin_clarity_score,
      checkin_notes,
      logged_at
    )
    VALUES (
      p_user_id,
      p_hair_length_cm,
      p_hair_strength_score,
      p_hair_thickness_score,
      p_hair_shedding_rate,
      p_skin_hydration_level,
      p_skin_clarity_score,
      p_checkin_notes,
      NOW()
    );

    -- 4. Generate initial Beauty Plan for remainder of current week until Sunday (matching Nutrition mode parity)
    PERFORM generate_initial_beauty_plan(p_user_id);

    RETURN true;
  END;
  $$;
  ```

- [ ] **Step 4: Confirm it passes**

  Run: `supabase db reset` then `supabase test db`.
  Expected: all 4 assertions in `complete_beauty_onboarding_authorization_test.sql` pass.

- [ ] **Step 5: Commit**

  ```bash
  git add supabase/migrations/20260722110000_fix_complete_beauty_onboarding_authorization.sql
  git add supabase/tests/complete_beauty_onboarding_authorization_test.sql
  git commit -m "fix(beauty): add owner-only auth check to complete_beauty_onboarding RPC"
  ```

---

## Task 2: `calculate_creator_payouts` — remove fan-mode double counting

**Files:**
- Create: `supabase/migrations/20260722110100_fix_beauty_payout_fan_double_counting.sql`
- Create: `supabase/tests/beauty_payout_fan_double_counting_test.sql`

**Interfaces:**
- `calculate_creator_payouts(target_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE, plan_revenue_cents INT DEFAULT 100) RETURNS VOID` — signature unchanged.
- `creator_monthly_payouts` — schema prerequisite fix only (add `updated_at`, correct the `creator_id` FK target); no column dropped.

- [ ] **Step 1: Write the failing pgTAP test**

  Create `supabase/tests/beauty_payout_fan_double_counting_test.sql`:

  ```sql
  -- supabase/tests/beauty_payout_fan_double_counting_test.sql
  -- Finding #2 (Area C, Critical): calculate_creator_payouts counts active
  -- fan_subscription rows into fan_earnings_cents, but Nutrition's existing
  -- compute-monthly-revenue edge function ALREADY counts the exact same
  -- fan_subscription rows into creator_balance.balance. This double-counts
  -- the same euro. Fix keeps only pool_earnings_cents (plan-slot-completion
  -- revenue), which is genuinely beauty-specific and not double-counted
  -- anywhere else.
  BEGIN;
  SELECT plan(4);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('c2000001-0000-0000-0000-000000000001'::uuid, 'creator2@test.local', 'authenticated', now(), now()),
    ('c2000001-0000-0000-0000-000000000002'::uuid, 'planowner2@test.local', 'authenticated', now(), now()),
    ('c2000001-0000-0000-0000-000000000003'::uuid, 'fan2@test.local', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_profile (id, first_name) VALUES
    ('c2000001-0000-0000-0000-000000000001'::uuid, 'CreatorUser2'),
    ('c2000001-0000-0000-0000-000000000002'::uuid, 'PlanOwnerUser2'),
    ('c2000001-0000-0000-0000-000000000003'::uuid, 'FanUser2')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.creator (id, user_id, display_name)
  VALUES ('c2000001-0000-0000-0000-000000000010'::uuid, 'c2000001-0000-0000-0000-000000000001'::uuid, 'Test Creator Two')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.recipe (id, creator_id, title, mode, is_published)
  VALUES ('c2000001-0000-0000-0000-000000000020'::uuid, 'c2000001-0000-0000-0000-000000000010'::uuid, 'Test Beauty Recipe Two', 'beauty', true)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.beauty_plan (id, user_id, start_date, end_date)
  VALUES (
    'c2000001-0000-0000-0000-000000000030'::uuid,
    'c2000001-0000-0000-0000-000000000002'::uuid,
    date_trunc('month', current_date)::date,
    (date_trunc('month', current_date) + interval '1 month - 1 day')::date
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id, is_completed, completed_at, revenue_value)
  VALUES (
    'c2000001-0000-0000-0000-000000000030'::uuid, 1, 'hair', 'daily_hydration',
    'c2000001-0000-0000-0000-000000000020'::uuid, true, now(), 1.0
  );

  INSERT INTO public.fan_subscription (user_id, creator_id, status, subscribed_at)
  VALUES (
    'c2000001-0000-0000-0000-000000000003'::uuid,
    'c2000001-0000-0000-0000-000000000010'::uuid,
    'active', now()
  );

  -- 1. The function must be callable at all (today it is not: the
  --    creator_id FK still points at auth.users while this INSERT supplies
  --    a creator.id value — see this plan's Global Constraints).
  SELECT lives_ok(
    $$ SELECT calculate_creator_payouts(date_trunc('month', current_date)::date) $$,
    'calculate_creator_payouts executes without error'
  );

  -- 2. fan-mode revenue must NOT be recomputed here (compute-monthly-revenue
  --    already owns it).
  SELECT is(
    (SELECT fan_earnings_cents FROM creator_monthly_payouts
     WHERE creator_id = 'c2000001-0000-0000-0000-000000000010'::uuid
       AND period_month = date_trunc('month', current_date)::date),
    0,
    'fan-mode revenue is not double-counted by the beauty payout engine'
  );

  -- 3. The genuinely beauty-specific pool revenue must still be computed.
  SELECT ok(
    (SELECT pool_earnings_cents FROM creator_monthly_payouts
     WHERE creator_id = 'c2000001-0000-0000-0000-000000000010'::uuid
       AND period_month = date_trunc('month', current_date)::date) > 0,
    'plan-slot-completion pool revenue is still computed correctly'
  );

  -- 4. No remaining reference to fan_earnings_cents anywhere in the function body.
  SELECT is(
    (SELECT prosrc ~ 'fan_earnings_cents' FROM pg_proc WHERE proname = 'calculate_creator_payouts' AND pronargs = 2),
    false,
    'calculate_creator_payouts (2-arg) no longer references fan_earnings_cents anywhere in its body'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 2: Confirm it fails**

  Run: `supabase db reset` then `supabase test db`.
  Expected: test 1 (`lives_ok`) FAILS today with a foreign-key violation (`creator_monthly_payouts_creator_id_fkey`) or, if that constraint happens to already be absent in your environment, `column "updated_at" of relation "creator_monthly_payouts" does not exist`. Because test 1 fails, its INSERT is rolled back to its internal savepoint, so tests 2 and 3 also fail (no row exists to read). Test 4 fails because `fan_earnings_cents` is still referenced in the live `prosrc`.

- [ ] **Step 3: Implement the fix**

  Create `supabase/migrations/20260722110100_fix_beauty_payout_fan_double_counting.sql`:

  ```sql
  -- Migration: 20260722110100_fix_beauty_payout_fan_double_counting.sql
  -- Finding #2 (Area C, Critical): calculate_creator_payouts's
  -- fan_earnings_cents computation double-counts the same fan_subscription
  -- rows already recognized as revenue by
  -- supabase/functions/compute-monthly-revenue (which writes them into
  -- creator_balance.balance). Beauty-side pool_earnings_cents (plan-slot
  -- completion revenue) is NOT double-counted anywhere and is preserved.
  --
  -- Prerequisite schema fix (required for this function to run at all —
  -- see this plan's Global Constraints): creator_monthly_payouts was first
  -- created by 20260521000003 with creator_id UUID REFERENCES auth.users(id)
  -- and no updated_at column. 20260721000013's own
  -- `CREATE TABLE IF NOT EXISTS creator_monthly_payouts` never actually
  -- applied (the table already existed), so its corrected creator_id shape
  -- and updated_at column were silently never created, even though
  -- calculate_creator_payouts's ON CONFLICT ... DO UPDATE SET
  -- updated_at = NOW() and its INSERT of recipe.creator_id (== creator.id,
  -- NOT auth.users.id) values both assume that shape. Both statements below
  -- are idempotent. The constraint name is looked up dynamically rather
  -- than guessed, so this is safe regardless of what Postgres auto-named it.

  ALTER TABLE creator_monthly_payouts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

  DO $$
  DECLARE
    v_conname text;
  BEGIN
    SELECT con.conname INTO v_conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = ANY(con.conkey)
    WHERE rel.relname = 'creator_monthly_payouts'
      AND con.contype = 'f'
      AND att.attname = 'creator_id'
    LIMIT 1;

    IF v_conname IS NOT NULL THEN
      EXECUTE format('ALTER TABLE creator_monthly_payouts DROP CONSTRAINT %I', v_conname);
    END IF;
  END;
  $$;

  ALTER TABLE creator_monthly_payouts
    ADD CONSTRAINT creator_monthly_payouts_creator_id_fkey
    FOREIGN KEY (creator_id) REFERENCES creator(id) ON DELETE CASCADE;

  -- Replacement calculate_creator_payouts: pool_earnings_cents only.
  CREATE OR REPLACE FUNCTION calculate_creator_payouts(
      target_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE,
      plan_revenue_cents INT DEFAULT 100
  )
  RETURNS VOID
  LANGUAGE plpgsql
  AS $$
  DECLARE
      v_rec RECORD;
      v_creator_points NUMERIC(12, 6);
      v_pool_share_cents INT;
  BEGIN
      -- Iterate through all creators with completed beauty plan slots in target month
      FOR v_rec IN
          SELECT DISTINCT r.creator_id
          FROM beauty_plan_slot bps
          JOIN recipe r ON bps.recipe_id = r.id
          WHERE bps.is_completed = TRUE
            AND r.creator_id IS NOT NULL
            AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', target_month)
      LOOP
          -- Calculate Creator's total weighted revenue points (each point = 1.00€ share)
          SELECT COALESCE(SUM(bps.revenue_value), 0.0) INTO v_creator_points
          FROM beauty_plan_slot bps
          JOIN recipe r ON bps.recipe_id = r.id
          WHERE r.creator_id = v_rec.creator_id
            AND bps.is_completed = TRUE
            AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', target_month);

          v_pool_share_cents := ROUND(v_creator_points * plan_revenue_cents)::INT;

          -- NOTE: fan-mode revenue is intentionally NOT computed here.
          -- supabase/functions/compute-monthly-revenue already recognizes
          -- every active fan_subscription row as revenue into
          -- creator_balance.balance; computing it again here would
          -- double-count the same subscription.

          INSERT INTO creator_monthly_payouts (creator_id, period_month, pool_earnings_cents, status)
          VALUES (v_rec.creator_id, DATE_TRUNC('month', target_month)::DATE, v_pool_share_cents, 'pending')
          ON CONFLICT (creator_id, period_month) DO UPDATE
          SET
              pool_earnings_cents = EXCLUDED.pool_earnings_cents,
              updated_at = NOW();
      END LOOP;
  END;
  $$;
  ```

- [ ] **Step 4: Confirm it passes**

  Run: `supabase db reset` then `supabase test db`.
  Expected: all 4 assertions in `beauty_payout_fan_double_counting_test.sql` pass.

- [ ] **Step 5: Commit**

  ```bash
  git add supabase/migrations/20260722110100_fix_beauty_payout_fan_double_counting.sql
  git add supabase/tests/beauty_payout_fan_double_counting_test.sql
  git commit -m "fix(beauty): stop double-counting fan-mode revenue in calculate_creator_payouts"
  ```

---

## Task 3: Authorization checks on the 3 unauthenticated payout-reporting RPCs

**Files:**
- Create: `supabase/migrations/20260722110200_add_beauty_payout_rpc_authorization.sql`
- Create: `supabase/tests/beauty_payout_rpc_authorization_test.sql`

**Interfaces:**
- `get_creator_beauty_revenue_share(p_creator_id UUID, p_start_date DATE DEFAULT ..., p_end_date DATE DEFAULT ...)` — adds an ownership check; signature unchanged.
- `get_creator_beauty_payout_breakdown(p_creator_id UUID, p_target_month DATE DEFAULT ..., p_plan_revenue_cents INT DEFAULT 100)` — adds an ownership check; signature unchanged.
- `get_platform_retained_beauty_revenue(p_target_month DATE DEFAULT ..., p_plan_revenue_cents INT DEFAULT 100)` — no body change; access restricted via `REVOKE`/`GRANT` (the codebase's established idiom for service-role-only RPCs — see `supabase/migrations/20260626000001_fix_generate_meal_plan_from_saved_service_role.sql` and `20260705000001_fix_meal_plan_from_saved_service_role.sql`; an in-body `IF auth.role() <> 'service_role'` check is not used anywhere in this codebase for functions, only in table RLS policies, so it is not the correct idiom to copy here).

- [ ] **Step 1: Write the failing pgTAP test**

  Create `supabase/tests/beauty_payout_rpc_authorization_test.sql`:

  ```sql
  -- supabase/tests/beauty_payout_rpc_authorization_test.sql
  -- Finding #3 (Area C, High): no authorization check on
  -- get_creator_beauty_payout_breakdown, get_platform_retained_beauty_revenue,
  -- get_creator_beauty_revenue_share. Any user can query any creator's/
  -- platform's financial data.
  BEGIN;
  SELECT plan(4);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('c3000001-0000-0000-0000-000000000001'::uuid, 'creatorA3@test.local', 'authenticated', now(), now()),
    ('c3000001-0000-0000-0000-000000000002'::uuid, 'creatorB3@test.local', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_profile (id, first_name) VALUES
    ('c3000001-0000-0000-0000-000000000001'::uuid, 'CreatorAUser3'),
    ('c3000001-0000-0000-0000-000000000002'::uuid, 'CreatorBUser3')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.creator (id, user_id, display_name) VALUES
    ('c3000001-0000-0000-0000-000000000010'::uuid, 'c3000001-0000-0000-0000-000000000001'::uuid, 'Creator A Three'),
    ('c3000001-0000-0000-0000-000000000020'::uuid, 'c3000001-0000-0000-0000-000000000002'::uuid, 'Creator B Three')
  ON CONFLICT (id) DO NOTHING;

  -- Impersonate Creator B, attempt to query Creator A's revenue.
  SET LOCAL "request.jwt.claims" TO '{"sub": "c3000001-0000-0000-0000-000000000002"}';

  SELECT throws_ok(
    $$ SELECT * FROM get_creator_beauty_revenue_share('c3000001-0000-0000-0000-000000000010'::uuid) $$,
    'Unauthorized',
    'creator B cannot query creator A''s get_creator_beauty_revenue_share'
  );

  SELECT throws_ok(
    $$ SELECT * FROM get_creator_beauty_payout_breakdown('c3000001-0000-0000-0000-000000000010'::uuid) $$,
    'Unauthorized',
    'creator B cannot query creator A''s get_creator_beauty_payout_breakdown'
  );

  SELECT ok(
    NOT has_function_privilege('authenticated', 'get_platform_retained_beauty_revenue(date, integer)', 'EXECUTE'),
    'authenticated role loses EXECUTE on get_platform_retained_beauty_revenue'
  );

  SELECT ok(
    has_function_privilege('service_role', 'get_platform_retained_beauty_revenue(date, integer)', 'EXECUTE'),
    'service_role retains EXECUTE on get_platform_retained_beauty_revenue'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 2: Confirm it fails**

  Run: `supabase db reset` then `supabase test db`.
  Expected: assertions 1, 2, and 3 FAIL today (both RPCs currently return data with no exception for a non-owner; `authenticated` currently retains default `EXECUTE` on `get_platform_retained_beauty_revenue`). Assertion 4 already passes (no regression risk there).

- [ ] **Step 3: Implement the fix**

  Create `supabase/migrations/20260722110200_add_beauty_payout_rpc_authorization.sql`:

  ```sql
  -- Migration: 20260722110200_add_beauty_payout_rpc_authorization.sql
  -- Finding #3 (Area C, High): no authorization check on
  -- get_creator_beauty_payout_breakdown / get_platform_retained_beauty_revenue
  -- / get_creator_beauty_revenue_share.
  --
  -- get_creator_beauty_revenue_share / get_creator_beauty_payout_breakdown:
  -- caller must own the creator row being queried (creator.user_id is the
  -- FK to the creator's own auth uid — confirmed via
  -- supabase/migrations/20260301000001_initial_schema.sql).
  --
  -- get_platform_retained_beauty_revenue: restricted to service_role only,
  -- via REVOKE/GRANT — this codebase's established idiom for
  -- service-role-only RPCs (see 20260626000001_fix_generate_meal_plan_from_saved_service_role.sql,
  -- 20260705000001_fix_meal_plan_from_saved_service_role.sql). This function's
  -- body is intentionally unchanged.
  --
  -- Note on scope: get_creator_beauty_payout_breakdown's own fan-earnings
  -- display math (recomputed live from fan_subscription, separate from
  -- calculate_creator_payouts / creator_monthly_payouts) is left untouched.
  -- Finding #2 is scoped explicitly to calculate_creator_payouts's ledger
  -- write; changing this read-only reporting RPC's math is a different,
  -- unassigned finding.

  CREATE OR REPLACE FUNCTION get_creator_beauty_revenue_share(
      p_creator_id UUID,
      p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 month',
      p_end_date DATE DEFAULT CURRENT_DATE
  )
  RETURNS TABLE (
      completed_slots_count INT,
      total_revenue_points NUMERIC(10, 6)
  )
  LANGUAGE plpgsql
  AS $$
  BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM creator WHERE id = p_creator_id AND user_id = auth.uid()
      ) THEN
        RAISE EXCEPTION 'Unauthorized';
      END IF;

      RETURN QUERY
      SELECT
          COUNT(*)::INT AS completed_slots_count,
          COALESCE(SUM(bps.revenue_value), 0.0)::NUMERIC(10, 6) AS total_revenue_points
      FROM beauty_plan_slot bps
      JOIN recipe r ON bps.recipe_id = r.id
      JOIN beauty_plan bp ON bps.plan_id = bp.id
      WHERE r.creator_id = p_creator_id
        AND bps.is_completed = TRUE
        AND bp.start_date >= p_start_date
        AND bp.end_date <= p_end_date;
  END;
  $$;

  CREATE OR REPLACE FUNCTION get_creator_beauty_payout_breakdown(
      p_creator_id UUID,
      p_target_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE,
      p_plan_revenue_cents INT DEFAULT 100
  )
  RETURNS TABLE (
      out_creator_id UUID,
      out_period_month DATE,
      completed_slots_count INT,
      creator_revenue_points NUMERIC(10, 6),
      creator_earned_euros NUMERIC(10, 4),
      pool_earnings_cents INT,
      fan_earnings_cents INT,
      total_payout_cents INT
  )
  LANGUAGE plpgsql
  AS $$
  DECLARE
      v_creator_points NUMERIC(12, 6);
      v_completed_count INT;
      v_fan_count INT;
      v_pool_share_cents INT;
      v_fan_cents INT;
  BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM creator WHERE id = p_creator_id AND user_id = auth.uid()
      ) THEN
        RAISE EXCEPTION 'Unauthorized';
      END IF;

      -- Creator points in month
      SELECT
          COUNT(*)::INT,
          COALESCE(SUM(bps.revenue_value), 0.0)
      INTO v_completed_count, v_creator_points
      FROM beauty_plan_slot bps
      JOIN recipe r ON bps.recipe_id = r.id
      WHERE r.creator_id = p_creator_id
        AND bps.is_completed = TRUE
        AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', p_target_month);

      -- Fan count
      SELECT COUNT(*)::INT INTO v_fan_count
      FROM fan_subscription fs
      WHERE fs.creator_id = p_creator_id
        AND fs.status = 'active'
        AND DATE_TRUNC('month', COALESCE(fs.subscribed_at, fs.created_at)) <= DATE_TRUNC('month', p_target_month);

      v_pool_share_cents := ROUND(v_creator_points * p_plan_revenue_cents)::INT;
      v_fan_cents := v_fan_count * 100;

      RETURN QUERY
      SELECT
          p_creator_id,
          DATE_TRUNC('month', p_target_month)::DATE,
          v_completed_count,
          v_creator_points::NUMERIC(10, 6),
          (v_creator_points * (p_plan_revenue_cents / 100.0))::NUMERIC(10, 4),
          v_pool_share_cents,
          v_fan_cents,
          (v_pool_share_cents + v_fan_cents);
  END;
  $$;

  REVOKE ALL ON FUNCTION get_platform_retained_beauty_revenue(DATE, INT) FROM PUBLIC;
  REVOKE ALL ON FUNCTION get_platform_retained_beauty_revenue(DATE, INT) FROM anon;
  REVOKE ALL ON FUNCTION get_platform_retained_beauty_revenue(DATE, INT) FROM authenticated;
  GRANT EXECUTE ON FUNCTION get_platform_retained_beauty_revenue(DATE, INT) TO service_role;
  ```

- [ ] **Step 4: Confirm it passes**

  Run: `supabase db reset` then `supabase test db`.
  Expected: all 4 assertions in `beauty_payout_rpc_authorization_test.sql` pass.

- [ ] **Step 5: Commit**

  ```bash
  git add supabase/migrations/20260722110200_add_beauty_payout_rpc_authorization.sql
  git add supabase/tests/beauty_payout_rpc_authorization_test.sql
  git commit -m "fix(beauty): add authorization checks to 3 beauty payout reporting RPCs"
  ```

---

## Task 4: Wire `calculate_creator_payouts` into a monthly cron edge function

**Files:**
- Create: `supabase/functions/compute-monthly-beauty-revenue/index.ts`
- Create: `supabase/migrations/20260722110300_register_compute_monthly_beauty_revenue_cron.sql`
- Create: `supabase/tests/compute_monthly_beauty_revenue_cron_test.sql`
- Edit: `supabase/config.toml` (add `[functions.compute-monthly-beauty-revenue]` block)

**Interfaces:**
- New edge function `compute-monthly-beauty-revenue` — internal-secret-gated, calls `calculate_creator_payouts` via `serviceClient()`. Mirrors `supabase/functions/compute-monthly-revenue/index.ts` exactly in structure (ENTRY/EXIT/catch-all, `logRLSCheck`/`logQueryResult`).
- Cron job `compute-monthly-beauty-revenue`, `0 2 1 * *` (02:00 UTC on the 1st of each month — one hour after `compute-monthly-revenue`'s own documented, but never actually registered, 01:00 UTC slot; see Step 3 note).

- [ ] **Step 1: Write the failing pgTAP test**

  Create `supabase/tests/compute_monthly_beauty_revenue_cron_test.sql`:

  ```sql
  -- supabase/tests/compute_monthly_beauty_revenue_cron_test.sql
  -- Finding #4 (Area C, High): the entire beauty payout system has no
  -- cron/edge-function invocation anywhere (confirmed: no reference to
  -- calculate_creator_payouts outside its own migration file, prior to this
  -- fix). This test verifies the SQL-testable half of the fix: the cron
  -- registration. The edge function itself (Deno code) is verified by a
  -- direct file-existence check in Step 4 below, since pgTAP cannot invoke
  -- Deno functions.
  BEGIN;
  SELECT plan(2);

  SELECT has_function(
    'public', 'calculate_creator_payouts', ARRAY['date','integer'],
    'calculate_creator_payouts(date, integer) exists for the monthly beauty revenue cron to call'
  );

  -- NOTE: this repository's local/CI environment does not have the
  -- pg_cron extension installed (same reason every other cron-registration
  -- migration in this repo, e.g. 20260703000001_register_recalculate_nutrition_plans_cron.sql,
  -- guards its own PERFORM cron.schedule(...) call behind this exact
  -- schema check). Where pg_cron IS available (staging/prod), this
  -- assertion is a real integration check that fails before the migration
  -- and passes after. Where it is not available, it SKIPs rather than
  -- silently passing.
  DO $$
  BEGIN
    PERFORM set_config(
      'pgtap_test.cron_available',
      (EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron'))::text,
      true
    );
  END;
  $$;

  SELECT CASE current_setting('pgtap_test.cron_available', true)
    WHEN 'true' THEN (
      SELECT is(
        (SELECT count(*)::int FROM cron.job WHERE jobname = 'compute-monthly-beauty-revenue'),
        1,
        'compute-monthly-beauty-revenue is registered as a monthly cron job'
      )
    )
    ELSE (
      SELECT skip('pg_cron schema not installed in this environment (expected on local/CI without the extension) — see note above')
    )
  END AS result;

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 2: Confirm it fails (or skips)**

  Run: `supabase db reset` then `supabase test db`.
  Expected: assertion 1 passes already (function exists from Task 2). Assertion 2 either FAILS (if your environment has `pg_cron`) or SKIPs (if it does not — this repo's local/CI environment is expected to skip, matching the existing 4 cron-registration migrations' identical guard).

- [ ] **Step 3: Implement the edge function**

  Create `supabase/functions/compute-monthly-beauty-revenue/index.ts`:

  ```typescript
  // Cron — 1er de chaque mois à 02:00 UTC (une heure après compute-monthly-revenue)
  // Calcule les paiements créateurs beauté (pool plan-slot-completion uniquement,
  // le fan-mode est déjà comptabilisé par compute-monthly-revenue) du mois écoulé.
  import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
  import { ok, serverError } from "../_shared/response.ts";
  import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
  import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

  serve(async (req) => {
    const logger = createLogger("compute-monthly-beauty-revenue");
    const requestId = crypto.randomUUID();
    logger.setRequestId(requestId);
    const start = Date.now();
    logger.info("⚡ ENTRY | method: " + req.method);

    try {
      logger.debug("[STEP 1] Verify internal secret");
      if (!verifyInternalSecret(req)) {
        logger.warn("EARLY RETURN | reason: invalid internal secret");
        return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
      }

      const admin = serviceClient();

      // Mois écoulé (ex: si on est le 1er mars 2026 → calcule février 2026)
      const prevDate = new Date();
      prevDate.setMonth(prevDate.getMonth() - 1);
      const monthKey = prevDate.toISOString().slice(0, 7); // ex: '2026-02'
      const targetMonth = monthKey + "-01";

      logger.debug("[STEP 2] Computing beauty creator pool payouts for month: " + targetMonth);

      logRLSCheck(logger, "creator_monthly_payouts", "INSERT", "cron");
      const { error: payoutError } = await admin.rpc("calculate_creator_payouts", {
        target_month: targetMonth,
      });
      logQueryResult(logger, "creator_monthly_payouts", "INSERT", payoutError ? 0 : 1, payoutError ?? undefined);

      if (payoutError) throw payoutError;

      logger.info("✅ EXIT | status: 200 | month: " + targetMonth + " | duration: " + (Date.now() - start) + "ms");
      return ok({ month_key: monthKey, status: "beauty_payouts_computed" });
    } catch (e) {
      logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
      return serverError(e);
    }
  });
  ```

  Edit `supabase/config.toml` — add this block immediately after the existing `[functions.compute-monthly-revenue]` block:

  ```toml
  [functions.compute-monthly-beauty-revenue]
  verify_jwt = false
  ```

- [ ] **Step 4: Confirm the edge function file and config entry exist**

  Run:
  ```bash
  ls supabase/functions/compute-monthly-beauty-revenue/index.ts
  grep -n "compute-monthly-beauty-revenue" supabase/config.toml
  grep -n "calculate_creator_payouts" supabase/functions/compute-monthly-beauty-revenue/index.ts
  ```
  Expected: the file exists, `config.toml` has the new `verify_jwt = false` block, and the function body references `calculate_creator_payouts` — i.e. Finding #4's "no reference outside its own migration file" is no longer true.

- [ ] **Step 5: Implement the cron registration migration**

  Create `supabase/migrations/20260722110300_register_compute_monthly_beauty_revenue_cron.sql`:

  ```sql
  -- Migration: 20260722110300_register_compute_monthly_beauty_revenue_cron.sql
  -- Finding #4 (Area C, High): registers the compute-monthly-beauty-revenue
  -- cron job, mirroring the pattern used by
  -- 20260703000001_register_recalculate_nutrition_plans_cron.sql. Scheduled
  -- one hour after compute-monthly-revenue's own documented (but, per grep,
  -- never actually registered by any tracked migration) 01:00 UTC slot, to
  -- avoid resource contention.
  --
  -- Cron registration — skipped silently on local where pg_cron is not installed.
  DO $$
  BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'cron') THEN
      -- Idempotent: unschedule first so re-runs don't error or duplicate
      PERFORM cron.unschedule(jobid)
      FROM cron.job
      WHERE jobname = 'compute-monthly-beauty-revenue';

      PERFORM cron.schedule(
        'compute-monthly-beauty-revenue',
        '0 2 1 * *',
        $cmd$
        SELECT net.http_post(
          url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/compute-monthly-beauty-revenue',
          headers := jsonb_build_object(
            'Content-Type',      'application/json',
            'x-internal-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'INTERNAL_SECRET' ORDER BY created_at DESC LIMIT 1)
          ),
          body    := '{}'::jsonb
        ) AS request_id;
        $cmd$
      );
    END IF;
  END;
  $$;
  ```

- [ ] **Step 6: Confirm it passes (or still cleanly skips)**

  Run: `supabase db reset` then `supabase test db`.
  Expected: both assertions in `compute_monthly_beauty_revenue_cron_test.sql` now pass (assertion 2 becomes a real `is(...)` pass in a `pg_cron`-enabled environment, or remains an honest `skip` locally — never a false pass).

- [ ] **Step 7: Commit**

  ```bash
  git add supabase/functions/compute-monthly-beauty-revenue/index.ts
  git add supabase/config.toml
  git add supabase/migrations/20260722110300_register_compute_monthly_beauty_revenue_cron.sql
  git add supabase/tests/compute_monthly_beauty_revenue_cron_test.sql
  git commit -m "feat(beauty): wire calculate_creator_payouts into a monthly cron edge function"
  ```

---

## Task 5: Drop the ambiguous 1-arg `calculate_creator_payouts` overload

**Files:**
- Create: `supabase/migrations/20260722110400_drop_legacy_calculate_creator_payouts_overload.sql`
- Create: `supabase/tests/calculate_creator_payouts_overload_test.sql`

**Interfaces:**
- `DROP FUNCTION calculate_creator_payouts(DATE)` — the stale 1-arg overload from `20260521000003`. The 2-arg overload (fixed in Task 2) is untouched.

- [ ] **Step 1: Write the failing pgTAP test**

  Create `supabase/tests/calculate_creator_payouts_overload_test.sql`:

  ```sql
  -- supabase/tests/calculate_creator_payouts_overload_test.sql
  -- Finding #5 (Area C, High): calculate_creator_payouts has 2 coexisting
  -- overloads — a stale 1-arg version (20260521000003) operating on dead
  -- tables (beauty_care_logs, fan_allocations — confirmed unreferenced
  -- anywhere in lib/ or supabase/functions/ via grep), and the real 2-arg
  -- version (20260721000013, fixed in this plan's Task 2). Two overloads of
  -- the same name is exactly the shape that produces PostgREST's PGRST203
  -- "could not choose the best candidate function" ambiguity error.
  BEGIN;
  SELECT plan(3);

  SELECT hasnt_function(
    'public', 'calculate_creator_payouts', ARRAY['date'],
    'legacy 1-arg calculate_creator_payouts(date) overload is dropped'
  );

  SELECT has_function(
    'public', 'calculate_creator_payouts', ARRAY['date','integer'],
    'calculate_creator_payouts(date, integer) 2-arg overload remains'
  );

  SELECT is(
    (SELECT count(*)::int FROM pg_proc WHERE proname = 'calculate_creator_payouts'),
    1,
    'exactly one calculate_creator_payouts overload exists (no PostgREST ambiguity risk)'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 2: Confirm it fails**

  Run: `supabase db reset` then `supabase test db`.
  Expected: assertion 1 (`hasnt_function`) FAILS (the 1-arg overload still exists). Assertion 3 FAILS (`count` is 2, not 1). Assertion 2 already passes.

- [ ] **Step 3: Implement the fix**

  Create `supabase/migrations/20260722110400_drop_legacy_calculate_creator_payouts_overload.sql`:

  ```sql
  -- Migration: 20260722110400_drop_legacy_calculate_creator_payouts_overload.sql
  -- Finding #5 (Area C, High): drops the stale 1-arg
  -- calculate_creator_payouts(date) overload from
  -- 20260521000003_fix_beauty_remuneration_and_fan_mode.sql, which operated
  -- on the dead beauty_care_logs / fan_allocations tables (confirmed
  -- unreferenced anywhere in lib/ or supabase/functions/). The real, current
  -- 2-arg overload calculate_creator_payouts(date, integer) from
  -- 20260721000013 (fixed by 20260722110100) is untouched by this
  -- migration.
  --
  -- Out of scope (see this plan's Coverage Checklist): the dead tables
  -- themselves — beauty_plans, user_beauty_subscriptions, fan_allocations,
  -- beauty_care_logs — are intentionally left in place, untouched.
  DROP FUNCTION IF EXISTS calculate_creator_payouts(DATE);
  ```

- [ ] **Step 4: Confirm it passes**

  Run: `supabase db reset` then `supabase test db`.
  Expected: all 3 assertions in `calculate_creator_payouts_overload_test.sql` pass.

- [ ] **Step 5: Commit**

  ```bash
  git add supabase/migrations/20260722110400_drop_legacy_calculate_creator_payouts_overload.sql
  git add supabase/tests/calculate_creator_payouts_overload_test.sql
  git commit -m "fix(beauty): drop the ambiguous legacy 1-arg calculate_creator_payouts overload"
  ```

---

## Task 6: Fix `creator_monthly_payouts` RLS policy idiom

**Files:**
- Create: `supabase/migrations/20260722110500_fix_creator_monthly_payouts_rls.sql`
- Create: `supabase/tests/creator_monthly_payouts_rls_test.sql`

**Interfaces:**
- RLS policy `"Creators view own payouts"` on `creator_monthly_payouts` — corrected to the same ownership idiom used elsewhere in this codebase (e.g. `fan_subscription`'s policies): `creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())`.

This task depends on Task 2's `creator_monthly_payouts.creator_id` FK correction (to `creator(id)`) already being applied — this plan's own migration ordering (`110100` before `110500`) guarantees that.

- [ ] **Step 1: Write the failing pgTAP test**

  Create `supabase/tests/creator_monthly_payouts_rls_test.sql`:

  ```sql
  -- supabase/tests/creator_monthly_payouts_rls_test.sql
  -- Finding #6 (Area C, Medium): creator_monthly_payouts' only RLS policy
  -- compares auth.uid() = creator_id, but creator_id stores creator.id (a
  -- separate table's PK, populated from recipe.creator_id by
  -- calculate_creator_payouts), not the creator's own auth uid. Legitimate
  -- creators can never see their own payout row through this policy.
  BEGIN;
  SELECT plan(3);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('c6000001-0000-0000-0000-000000000001'::uuid, 'creatorA6@test.local', 'authenticated', now(), now()),
    ('c6000001-0000-0000-0000-000000000002'::uuid, 'creatorB6@test.local', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_profile (id, first_name) VALUES
    ('c6000001-0000-0000-0000-000000000001'::uuid, 'CreatorAUser6'),
    ('c6000001-0000-0000-0000-000000000002'::uuid, 'CreatorBUser6')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.creator (id, user_id, display_name) VALUES
    ('c6000001-0000-0000-0000-000000000010'::uuid, 'c6000001-0000-0000-0000-000000000001'::uuid, 'Creator A Six')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.creator_monthly_payouts (creator_id, period_month, pool_earnings_cents, status)
  VALUES ('c6000001-0000-0000-0000-000000000010'::uuid, date_trunc('month', current_date)::date, 500, 'pending')
  ON CONFLICT (creator_id, period_month) DO NOTHING;

  -- Creator A (rightful owner) must be able to see their own payout row.
  SET LOCAL "request.jwt.claims" TO '{"sub": "c6000001-0000-0000-0000-000000000001"}';
  SET LOCAL ROLE authenticated;

  SELECT is(
    (SELECT count(*)::int FROM creator_monthly_payouts WHERE creator_id = 'c6000001-0000-0000-0000-000000000010'::uuid),
    1,
    'creator A can see their own payout row via the corrected RLS policy'
  );

  -- Creator B must NOT see creator A's payout row.
  SET LOCAL "request.jwt.claims" TO '{"sub": "c6000001-0000-0000-0000-000000000002"}';
  SET LOCAL ROLE authenticated;

  SELECT is(
    (SELECT count(*)::int FROM creator_monthly_payouts WHERE creator_id = 'c6000001-0000-0000-0000-000000000010'::uuid),
    0,
    'creator B cannot see creator A''s payout row'
  );

  RESET ROLE;

  -- Sanity: the policy definition itself uses the corrected subquery idiom.
  SELECT ok(
    (SELECT qual FROM pg_policies WHERE tablename = 'creator_monthly_payouts' AND policyname = 'Creators view own payouts') LIKE '%SELECT id FROM creator%',
    'RLS policy uses the creator-ownership subquery idiom, not a raw auth.uid() = creator_id comparison'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 2: Confirm it fails**

  Run: `supabase db reset` then `supabase test db`.
  Expected: assertion 1 FAILS today (`auth.uid() = creator_id` never matches since `creator_id` holds `creator.id`, not the creator's own uid — creator A sees 0 rows, not 1). Assertion 3 FAILS (the live policy text does not contain the corrected subquery). Assertion 2 already passes (both are 0 either way), which is expected and fine.

- [ ] **Step 3: Implement the fix**

  Create `supabase/migrations/20260722110500_fix_creator_monthly_payouts_rls.sql`:

  ```sql
  -- Migration: 20260722110500_fix_creator_monthly_payouts_rls.sql
  -- Finding #6 (Area C, Medium): creator_monthly_payouts' only RLS policy
  -- compares auth.uid() = creator_id, but creator_id stores creator.id (a
  -- separate table's PK), not the creator's own auth uid. Corrected idiom
  -- matches fan_subscription's existing pattern in this codebase.
  DROP POLICY IF EXISTS "Creators view own payouts" ON creator_monthly_payouts;

  CREATE POLICY "Creators view own payouts" ON creator_monthly_payouts
    FOR SELECT USING (
      creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())
    );
  ```

- [ ] **Step 4: Confirm it passes**

  Run: `supabase db reset` then `supabase test db`.
  Expected: all 3 assertions in `creator_monthly_payouts_rls_test.sql` pass.

- [ ] **Step 5: Commit**

  ```bash
  git add supabase/migrations/20260722110500_fix_creator_monthly_payouts_rls.sql
  git add supabase/tests/creator_monthly_payouts_rls_test.sql
  git commit -m "fix(beauty): correct creator_monthly_payouts RLS ownership idiom"
  ```

---

## Task 7: Mode filter for Community "Browse Groups"

**Files:**
- Create: `supabase/migrations/20260722110600_add_mode_filter_generate_groups_personalized.sql`
- Create: `supabase/tests/generate_groups_personalized_mode_filter_test.sql`
- Edit: `lib/providers/dm_provider.dart` (only the `BrowseGroupsParams` class and `browseGroupsProvider` — the community-group mode-filter portion; this is the ONE Dart file edit in this plan)

**Interfaces:**
- `generate_groups_personalized(p_user_id uuid, p_limit int DEFAULT 20, p_exclude uuid[] DEFAULT '{}', p_mode text DEFAULT NULL) RETURNS TABLE (group_id uuid, score numeric)` — new 4th parameter, appended at the end so existing named-parameter callers (`p_user_id`, `p_limit` only) are unaffected.
- `BrowseGroupsParams` gains a `mode` field. `browseGroupsProvider` resolves the effective mode internally via `params.mode ?? ref.watch(currentModeProvider).name`, so `lib/features/community/browse_groups_page.dart` (which never sets `mode` today) is automatically fixed with no change to that file.

- [ ] **Step 1: Write the failing pgTAP test**

  Create `supabase/tests/generate_groups_personalized_mode_filter_test.sql`:

  ```sql
  -- supabase/tests/generate_groups_personalized_mode_filter_test.sql
  -- Finding #7 (Area C, High): Community "Browse Groups" has no mode filter.
  -- Beauty groups leak into Nutrition mode's discovery feed and vice versa.
  BEGIN;
  SELECT plan(4);

  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES ('70000001-0000-0000-0000-000000000001'::uuid, 'browsegroups7@test.local', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_profile (id, first_name, locale)
  VALUES ('70000001-0000-0000-0000-000000000001'::uuid, 'BrowseUser7', 'fr')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.community_group (id, name, "mode", topic, language, is_public, member_count)
  VALUES
    ('70000001-0000-0000-0000-000000000002'::uuid, 'Nutrition Test Group Seven', 'nutrition', 'nutrition', 'fr', true, 10),
    ('70000001-0000-0000-0000-000000000003'::uuid, 'Beauty Test Group Seven', 'beauty', 'chebe_care', 'fr', true, 10)
  ON CONFLICT (id) DO NOTHING;

  -- 1. The 4-arg overload must exist (schema-level check, never throws).
  SELECT has_function(
    'public', 'generate_groups_personalized', ARRAY['uuid','integer','uuid[]','text'],
    'generate_groups_personalized accepts a 4th p_mode text parameter'
  );

  SET LOCAL "request.jwt.claims" TO '{"sub": "70000001-0000-0000-0000-000000000001"}';

  -- 2. Behavioral check, gated on the 4-arg overload actually existing so
  --    this never throws an uncaught exception pre-fix.
  DO $$
  BEGIN
    PERFORM set_config(
      'pgtap_test.mode_param_exists',
      (EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = 'generate_groups_personalized' AND p.pronargs = 4
      ))::text,
      true
    );
  END;
  $$;

  SELECT CASE current_setting('pgtap_test.mode_param_exists', true)
    WHEN 'true' THEN (
      SELECT is(
        (SELECT array_agg(group_id ORDER BY group_id) FROM generate_groups_personalized(
          p_user_id => '70000001-0000-0000-0000-000000000001'::uuid,
          p_limit   => 20,
          p_exclude => '{}'::uuid[],
          p_mode    => 'beauty'
        )),
        ARRAY['70000001-0000-0000-0000-000000000003'::uuid],
        'p_mode=beauty returns only the seeded beauty-mode group'
      )
    )
    ELSE fail('generate_groups_personalized(...,p_mode) not callable yet — Finding #7 fix not applied')
  END AS beauty_filter_result;

  SELECT CASE current_setting('pgtap_test.mode_param_exists', true)
    WHEN 'true' THEN (
      SELECT is(
        (SELECT array_agg(group_id ORDER BY group_id) FROM generate_groups_personalized(
          p_user_id => '70000001-0000-0000-0000-000000000001'::uuid,
          p_limit   => 20,
          p_exclude => '{}'::uuid[],
          p_mode    => 'nutrition'
        )),
        ARRAY['70000001-0000-0000-0000-000000000002'::uuid],
        'p_mode=nutrition returns only the seeded nutrition-mode group'
      )
    )
    ELSE fail('generate_groups_personalized(...,p_mode) not callable yet — Finding #7 fix not applied')
  END AS nutrition_filter_result;

  -- 4. p_mode omitted (NULL default) preserves prior no-filter behavior.
  SELECT CASE current_setting('pgtap_test.mode_param_exists', true)
    WHEN 'true' THEN (
      SELECT is(
        (SELECT count(*)::int FROM generate_groups_personalized(
          p_user_id => '70000001-0000-0000-0000-000000000001'::uuid,
          p_limit   => 20,
          p_exclude => '{}'::uuid[]
        ) WHERE group_id IN ('70000001-0000-0000-0000-000000000002'::uuid, '70000001-0000-0000-0000-000000000003'::uuid)),
        2,
        'p_mode omitted (NULL default) returns both seeded groups — backward compatible'
      )
    )
    ELSE fail('generate_groups_personalized(...,p_mode) not callable yet — Finding #7 fix not applied')
  END AS no_filter_result;

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 2: Confirm it fails**

  Run: `supabase db reset` then `supabase test db`.
  Expected: assertion 1 FAILS (only the 3-arg overload exists today). Assertions 2, 3, 4 all report the explicit `fail(...)` message (the 4-arg overload does not exist yet, so the gate short-circuits to `fail`, never attempting the unsupported call).

- [ ] **Step 3: Implement the SQL fix**

  Create `supabase/migrations/20260722110600_add_mode_filter_generate_groups_personalized.sql`:

  ```sql
  -- Migration: 20260722110600_add_mode_filter_generate_groups_personalized.sql
  -- Finding #7 (Area C, High): Community "Browse Groups" has no mode filter.
  -- Adds p_mode TEXT DEFAULT NULL to generate_groups_personalized, filtering
  -- both the cold-start fallback branch and the personalized vector-search
  -- branch. Appended as the 4th parameter so existing callers that only
  -- pass p_user_id/p_limit/p_exclude are unaffected. SET search_path and
  -- STABLE SECURITY DEFINER preserved unchanged from the live version
  -- (confirmed via supabase/migrations/20260717053537_reconcile_local_with_prod_schema.sql).
  CREATE OR REPLACE FUNCTION generate_groups_personalized(
    p_user_id  uuid,
    p_limit    int     DEFAULT 20,
    p_exclude  uuid[]  DEFAULT '{}',
    p_mode     text    DEFAULT NULL
  )
  RETURNS TABLE (group_id uuid, score numeric)
  LANGUAGE plpgsql STABLE SECURITY DEFINER
  SET search_path = public, pg_temp
  AS $$
  DECLARE
    v_user_vector vector(50);
  BEGIN
    IF auth.uid() IS DISTINCT FROM p_user_id THEN
      RAISE EXCEPTION 'Unauthorized';
    END IF;

    SELECT uv.vector INTO v_user_vector
    FROM user_vector uv WHERE uv.user_id = p_user_id;

    -- Cold start: fallback to profile field matching
    IF v_user_vector IS NULL THEN
      RETURN QUERY
      SELECT cg.id AS group_id, 0::numeric AS score
      FROM community_group cg
      LEFT JOIN user_profile up ON up.id = p_user_id
      WHERE cg.is_public = true
        AND cg.id <> ALL(p_exclude)
        AND (p_mode IS NULL OR cg.mode = p_mode)
        AND (
          cg.language = up.locale
          OR cg.region_code IN (
            SELECT ucp.region FROM user_cuisine_preference ucp
            WHERE ucp.user_id = p_user_id
          )
        )
      ORDER BY cg.member_count DESC
      LIMIT LEAST(p_limit, 100);
      RETURN;
    END IF;

    -- Personalized path: cosine similarity
    RETURN QUERY
    SELECT
      cg.id                                           AS group_id,
      (1 - (gv.vector <=> v_user_vector))::numeric    AS score
    FROM community_group cg
    JOIN group_vector gv ON gv.group_id = cg.id
    WHERE cg.is_public = true
      AND cg.id <> ALL(p_exclude)
      AND (p_mode IS NULL OR cg.mode = p_mode)
    ORDER BY (gv.vector <=> v_user_vector) ASC
    LIMIT LEAST(p_limit, 100);
  END;
  $$;
  ```

- [ ] **Step 4: Implement the Dart fix**

  In `lib/providers/dm_provider.dart`, replace the entire `BrowseGroupsParams` class and `browseGroupsProvider` definition (the block currently starting at `class BrowseGroupsParams {` and ending at the closing `});` of `browseGroupsProvider`) with:

  ```dart
  class BrowseGroupsParams {
    final String? userId;
    final String? regionId;
    final String? language;
    final String? topic;
    final String? mode;

    const BrowseGroupsParams({this.userId, this.regionId, this.language, this.topic, this.mode});

    @override
    bool operator ==(Object other) =>
        identical(this, other) ||
        other is BrowseGroupsParams &&
            runtimeType == other.runtimeType &&
            userId == other.userId &&
            regionId == other.regionId &&
            language == other.language &&
            topic == other.topic &&
            mode == other.mode;

    @override
    int get hashCode =>
        userId.hashCode ^ regionId.hashCode ^ language.hashCode ^ topic.hashCode ^ mode.hashCode;
  }

  final browseGroupsProvider = FutureProvider.autoDispose
      .family<List<Map<String, dynamic>>, BrowseGroupsParams>((ref, params) async {
    final logger = appLogger;
    logger.provider('browseGroupsProvider build()');
    ref.onDispose(() => logger.provider('browseGroupsProvider disposed'));

    final client = ref.watch(supabaseClientProvider);
    // Finding #7 fix: resolve the effective mode from params.mode if the
    // caller set one explicitly, otherwise from the globally active mode.
    // This fixes browse_groups_page.dart's call site (which never sets
    // `mode` today) with no change needed to that file.
    final effectiveMode = params.mode ?? ref.watch(currentModeProvider).name;

    final hasFilters = params.regionId != null || params.language != null || params.topic != null;

    try {
      if (!hasFilters && params.userId != null) {
        // Path 1: Personalized RPC
        logger.db('BEFORE | RPC: generate_groups_personalized | mode: $effectiveMode');
        try {
          final rpcResult = await client
              .rpc('generate_groups_personalized', params: {
                'p_user_id': params.userId,
                'p_limit': 50,
                'p_mode': effectiveMode,
              }) as List<dynamic>;

          logger.db('AFTER | RPC: generate_groups_personalized | rows: ${rpcResult.length}');

          if (rpcResult.isNotEmpty) {
            final groupIds = rpcResult
                .cast<Map<String, dynamic>>()
                .map((r) => r['group_id'] as String)
                .toList();

            logger.db('BEFORE | table: v_community_group | op: SELECT public IN');
            final groupsData = await client
                .from('v_community_group')
                .select('id, name, description, member_count, max_members, region_code, language, topic, creator_id, cover_url')
                .inFilter('id', groupIds);

            final groupsMap = {
              for (final g in groupsData.cast<Map<String, dynamic>>())
                g['id'] as String: g
            };

            final orderedGroups = groupIds
                .map((id) => groupsMap[id])
                .whereType<Map<String, dynamic>>()
                .toList();

            if (orderedGroups.isNotEmpty) return orderedGroups;
            // RPC returned IDs but none had group_vector rows yet — fall through to direct query
          }
        } catch (rpcError, st) {
          logger.db('ERROR | RPC: generate_groups_personalized | fallback to direct query', error: rpcError, stackTrace: st);
        }
      }

      // Path 2 or Fallback: Direct query — also mode-scoped (Finding #7:
      // this direct/fallback path previously had no mode filter at all).
      logger.db('BEFORE | table: v_community_group | op: SELECT public (direct) | mode: $effectiveMode');
      var query = client
          .from('v_community_group')
          .select('id, name, description, member_count, max_members, region_code, language, topic, creator_id, cover_url')
          .eq('is_public', true)
          .eq('app_mode', effectiveMode);

      if (params.regionId != null) query = query.eq('region_code', params.regionId!);
      if (params.language != null) query = query.eq('language', params.language!);
      if (params.topic != null) query = query.eq('topic', params.topic!);

      final rows = await query.order('member_count', ascending: false).limit(50);

      logger.db('AFTER | table: community_group | rows: ${rows.length}');
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (e, st) {
      logger.db('ERROR | table: community_group | SELECT public | code: ${e.code}', error: e, stackTrace: st);
      rethrow;
    }
  });
  ```

  Note: the direct/fallback query filters on `app_mode` (not `mode`) because it reads from the `v_community_group` view, whose column is aliased `cg."mode" AS app_mode` (see `supabase/migrations/20260721000011_community_mode_and_beauty_topics.sql`).

- [ ] **Step 5: Confirm it passes**

  Run: `supabase db reset` then `supabase test db`.
  Expected: all 4 assertions in `generate_groups_personalized_mode_filter_test.sql` pass.

  Run: `flutter analyze lib/providers/dm_provider.dart`
  Expected: no new errors or warnings introduced by the edit.

- [ ] **Step 6: Commit**

  ```bash
  git add supabase/migrations/20260722110600_add_mode_filter_generate_groups_personalized.sql
  git add supabase/tests/generate_groups_personalized_mode_filter_test.sql
  git add lib/providers/dm_provider.dart
  git commit -m "fix(community): scope Browse Groups to the active app mode"
  ```

---

## Task 8: Bring `complete-beauty-onboarding` in line with the Deno logging standard

**Files:**
- Edit: `supabase/functions/complete-beauty-onboarding/index.ts`

**Interfaces:** No RPC/signature change — logging only.

This is a Deno-only fix (no SQL, no migration, no pgTAP test — CLAUDE.md's logging standard is verified by direct source inspection, matching how Finding #8 itself was identified).

- [ ] **Step 1: Confirm the current gap**

  Run:
  ```bash
  grep -n "logRLSCheck\|logQueryResult\|stack:" supabase/functions/complete-beauty-onboarding/index.ts
  ```
  Expected: no matches (the file imports only `createLogger`, never calls `logRLSCheck`/`logQueryResult`, and its catch-all omits `stack:`).

- [ ] **Step 2: Implement the fix**

  Replace the full contents of `supabase/functions/complete-beauty-onboarding/index.ts` with:

  ```typescript
  import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
  import { handleCors } from "../_shared/cors.ts";
  import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
  import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
  import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

  const PYTHON_SERVICE_URL = Deno.env.get("PYTHON_SERVICE_URL");

  serve(async (req) => {
    const corsResponse = handleCors(req);
    if (corsResponse) return corsResponse;

    const logger = createLogger("complete-beauty-onboarding");
    const requestId = crypto.randomUUID();
    logger.setRequestId(requestId);
    const start = Date.now();
    logger.info("⚡ ENTRY | method: " + req.method);

    try {
      const { user, client } = await getAuthUser(req);
      if (!user || !client) {
        logger.warn("EARLY RETURN | reason: unauthorized | no authenticated user");
        return unauthorized();
      }

      logger.setUserId(user.id);
      logger.info("👤 Auth verified | userId: " + user.id);

      const body = await req.json();
      const {
        hair_type,
        porosity,
        skin_type,
        scalp_type,
        beauty_goals = [],
        skin_concerns = [],
        hair_length_cm = 15,
        hair_strength_score = 7,
        hair_thickness_score = 7,
        hair_shedding_rate = "moderate",
        skin_hydration_level = 7,
        skin_clarity_score = 7,
        checkin_notes = "Premier journal de bord initial",
      } = body;

      if (!hair_type || !porosity || !skin_type) {
        logger.warn("EARLY RETURN | reason: missing required beauty profile fields");
        return err("Missing required beauty profile fields (hair_type, porosity, skin_type)");
      }

      const admin = serviceClient();

      // 1. Execute complete_beauty_onboarding RPC
      logger.debug("[STEP 1] Executing complete_beauty_onboarding RPC");
      logRLSCheck(logger, "user_health_profile", "UPSERT", user.id);
      const { error: rpcError } = await admin.rpc("complete_beauty_onboarding", {
        p_user_id: user.id,
        p_hair_type: hair_type,
        p_porosity: porosity,
        p_skin_type: skin_type,
        p_scalp_type: scalp_type ?? "normal",
        p_beauty_goals: beauty_goals,
        p_skin_concerns: skin_concerns,
        p_hair_length_cm: hair_length_cm,
        p_hair_strength_score: hair_strength_score,
        p_hair_thickness_score: hair_thickness_score,
        p_hair_shedding_rate: hair_shedding_rate,
        p_skin_hydration_level: skin_hydration_level,
        p_skin_clarity_score: skin_clarity_score,
        p_checkin_notes: checkin_notes,
      });
      logQueryResult(logger, "user_health_profile", "UPSERT", rpcError ? 0 : 1, rpcError ?? undefined);

      if (rpcError) {
        logger.error("💥 RPC complete_beauty_onboarding failed", rpcError);
        throw rpcError;
      }

      // 2. Trigger Beauty User Vectorization via Python recommendation engine (non-blocking)
      if (PYTHON_SERVICE_URL) {
        logger.debug("[STEP 2] FIRE compute-user-vector (mode: beauty, non-blocking)");
        fetch(`${PYTHON_SERVICE_URL}/compute-user-vector`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ user_id: user.id, mode: "beauty" }),
        }).catch((e) => logger.warn("[STEP 2] Python beauty vectorization trigger error: " + e.message));
      }

      logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
      return ok({ message: "Beauty onboarding completed successfully with vectorization trigger", user_id: user.id });
    } catch (e) {
      logger.error("💥 Unhandled error", { message: (e as Error).message, stack: (e as Error).stack });
      return serverError(e);
    }
  });
  ```

- [ ] **Step 3: Confirm the fix**

  Run:
  ```bash
  grep -n "logRLSCheck\|logQueryResult\|stack:" supabase/functions/complete-beauty-onboarding/index.ts
  ```
  Expected: 3 matches — the `logRLSCheck(...)` call before the RPC, the `logQueryResult(...)` call after it, and `stack: (e as Error).stack` in the catch-all.

- [ ] **Step 4: Commit**

  ```bash
  git add supabase/functions/complete-beauty-onboarding/index.ts
  git commit -m "fix(beauty): bring complete-beauty-onboarding in line with the Deno logging standard"
  ```

---

## Task 9: Rewrite `BEAUTY_MODE_REMUNERATION_AUDIT.md`

**Files:**
- Edit: `BEAUTY_MODE_REMUNERATION_AUDIT.md`

**Interfaces:** Documentation only.

- [ ] **Step 1: Confirm the current staleness**

  Run:
  ```bash
  grep -n "beauty_care_logs\|fan_allocations\|20240103000001" BEAUTY_MODE_REMUNERATION_AUDIT.md
  ```
  Expected: multiple matches — the document currently describes the abandoned tokenized-pool/fan-allocation model and a migration filename (`20240103000001_fix_beauty_remuneration_and_fan_mode.sql`) that has never existed in this repository (the real file is `20260521000003_fix_beauty_remuneration_and_fan_mode.sql`).

- [ ] **Step 2: Implement the fix**

  Replace the full contents of `BEAUTY_MODE_REMUNERATION_AUDIT.md` with:

  ```markdown
  # Beauty Mode Remuneration & Database Audit

  > Rewritten 2026-07-23 to describe the system as actually shipped. The
  > previous version of this document described an abandoned tokenized
  > pool/fan-allocation model (`beauty_care_logs`, `fan_allocations`,
  > migration `20240103000001_fix_beauty_remuneration_and_fan_mode.sql`) that
  > was never the live implementation and does not match any migration
  > filename that has ever existed in this repository. See
  > `docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md`
  > for the audit that surfaced this discrepancy and the fixes applied
  > alongside this rewrite.

  ## Shipped model: `revenue_value = 1 / N` proportional plan-slot payout

  - **Migrations:** `supabase/migrations/20260721000012_beauty_plan_slot_revenue_value.sql`
    (adds `beauty_plan_slot.revenue_value`, computed by `generate_beauty_plan`
    as `1 / total_slots_in_plan` once a plan is generated) and
    `supabase/migrations/20260721000013_beauty_payouts_revenue_value.sql`
    (creator payout aggregation).
  - **Mechanism:** every slot in a user's monthly beauty plan is worth an
    equal fraction (`1 / N`) of a fixed 1.00€ (100 cents) creator pool per
    plan. When the user marks a slot `is_completed = true`, that slot's
    `revenue_value` counts toward its recipe's creator.
  - **Aggregation:** `calculate_creator_payouts(target_month, plan_revenue_cents)`
    sums `revenue_value` across all completed slots for each creator in a
    given month, converts the sum to cents (`ROUND(points * plan_revenue_cents)`),
    and upserts the result into `creator_monthly_payouts.pool_earnings_cents`.
  - **Reporting RPCs:** `get_creator_beauty_revenue_share` and
    `get_creator_beauty_payout_breakdown` recompute the same points/cents math
    on demand for a single creator (dashboard display); both are now
    authorization-gated to the creator's own `auth.uid()`
    (see `docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md`,
    Task 3). `get_platform_retained_beauty_revenue` computes the
    platform-retained remainder across all plans for a month and is now
    restricted to `service_role` only (same plan, Task 3).

  ## Fan-mode revenue is NOT computed by the beauty payout engine

  Earlier drafts of `calculate_creator_payouts` additionally counted active
  `fan_subscription` rows into a `fan_earnings_cents` column. This was removed
  (`docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md`, Task 2):
  Nutrition's existing `supabase/functions/compute-monthly-revenue` edge
  function already recognizes every active `fan_subscription` row as revenue
  into `creator_balance.balance`, once per creator per month. Counting the
  same rows again in the beauty payout engine would double-count the same
  euro. Fan-mode revenue for creators — beauty or nutrition — is
  authoritatively tracked by `compute-monthly-revenue` /
  `creator_balance` / `creator_revenue_log` only.
  `creator_monthly_payouts.fan_earnings_cents` remains in the schema for
  backward compatibility but is never written by `calculate_creator_payouts`
  and should be treated as always `0`.

  ## Automation

  `calculate_creator_payouts` is invoked monthly by the
  `compute-monthly-beauty-revenue` edge function (mirrors
  `compute-monthly-revenue`'s internal-secret-gated cron pattern), registered
  via `supabase/migrations/20260722110300_register_compute_monthly_beauty_revenue_cron.sql`.
  Before this, the function existed in the schema but was never called by
  anything in production
  (`docs/superpowers/plans/2026-07-23-beauty-fix-c-revenue-community.md`, Task 4).

  ## Known out-of-scope legacy artifacts

  `supabase/migrations/20260521000003_fix_beauty_remuneration_and_fan_mode.sql`
  created an earlier, abandoned schema (`beauty_plans`,
  `user_beauty_subscriptions`, `fan_allocations`, `beauty_care_logs`) and a
  now-dropped 1-arg `calculate_creator_payouts(date)` overload (dropped by
  `20260722110400_drop_legacy_calculate_creator_payouts_overload.sql`). Those
  dead tables are confirmed unreferenced anywhere in `lib/` or
  `supabase/functions/` and are left in place, untouched, as an accepted
  cleanup item for a future migration — dropping them is out of scope for
  this document's audit and for the 2026-07-23 fix plan.
  ```

- [ ] **Step 3: Confirm the fix**

  Run:
  ```bash
  grep -n "beauty_care_logs\|fan_allocations\|20240103000001" BEAUTY_MODE_REMUNERATION_AUDIT.md
  ```
  Expected: any remaining matches are only in the "Known out-of-scope legacy artifacts" section, explicitly describing them as dead/unreferenced — not presented as the live model.

- [ ] **Step 4: Commit**

  ```bash
  git add BEAUTY_MODE_REMUNERATION_AUDIT.md
  git commit -m "docs(beauty): rewrite remuneration audit to describe the actual shipped revenue_value system"
  ```

---

## Task 10: `generate_beauty_shopping_list` — add authorization check

**Files:**
- Create: `supabase/migrations/20260722110700_fix_beauty_shopping_list_authorization.sql`
- Create: `supabase/tests/beauty_shopping_list_authorization_test.sql`

**Interfaces:**
- `generate_beauty_shopping_list(p_beauty_plan_id uuid) RETURNS TABLE (...)` — signature unchanged. Since this function takes only `p_beauty_plan_id` (not `p_user_id`), the owner must be resolved from the plan row itself before the check can run — mirroring this codebase's own equivalent Nutrition-side function `generate_shopping_list_internal`, which uses the identical `IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN RAISE EXCEPTION 'Unauthorized'; END IF;` pattern (confirmed in `supabase/migrations/20260717053537_reconcile_local_with_prod_schema.sql`).

- [ ] **Step 1: Write the failing pgTAP test**

  Create `supabase/tests/beauty_shopping_list_authorization_test.sql`:

  ```sql
  -- supabase/tests/beauty_shopping_list_authorization_test.sql
  -- Finding #10 (Area C, Medium): generate_beauty_shopping_list has no
  -- auth.uid() check on p_beauty_plan_id — same IDOR pattern as Finding #1.
  BEGIN;
  SELECT plan(3);

  INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
    ('c1000001-0000-0000-0000-000000000001'::uuid, 'shopowner10@test.local', 'authenticated', now(), now()),
    ('c1000001-0000-0000-0000-000000000002'::uuid, 'shopattacker10@test.local', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_profile (id, first_name) VALUES
    ('c1000001-0000-0000-0000-000000000001'::uuid, 'ShopOwnerUser10'),
    ('c1000001-0000-0000-0000-000000000002'::uuid, 'ShopAttackerUser10')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.recipe (id, title, mode, is_published)
  VALUES ('c1000001-0000-0000-0000-000000000020'::uuid, 'Test Shopping Recipe Ten', 'beauty', true)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.ingredient (id, name, name_fr)
  VALUES ('c1000001-0000-0000-0000-000000000021'::uuid, 'Shea Butter Test Ten', 'Beurre de Karité Test Dix')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity)
  VALUES ('c1000001-0000-0000-0000-000000000020'::uuid, 'c1000001-0000-0000-0000-000000000021'::uuid, 2.0);

  INSERT INTO public.beauty_plan (id, user_id, start_date, end_date)
  VALUES (
    'c1000001-0000-0000-0000-000000000030'::uuid,
    'c1000001-0000-0000-0000-000000000001'::uuid,
    current_date, current_date + 6
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id)
  VALUES ('c1000001-0000-0000-0000-000000000030'::uuid, 1, 'hair', 'daily_hydration', 'c1000001-0000-0000-0000-000000000020'::uuid);

  -- Attacker cannot generate a shopping list for someone else's beauty plan.
  SET LOCAL "request.jwt.claims" TO '{"sub": "c1000001-0000-0000-0000-000000000002"}';

  SELECT throws_ok(
    $$ SELECT * FROM generate_beauty_shopping_list('c1000001-0000-0000-0000-000000000030'::uuid) $$,
    'Unauthorized',
    'attacker cannot generate a shopping list for another user''s beauty plan'
  );

  -- Owner can still generate their own shopping list.
  SET LOCAL "request.jwt.claims" TO '{"sub": "c1000001-0000-0000-0000-000000000001"}';

  SELECT lives_ok(
    $$ SELECT * FROM generate_beauty_shopping_list('c1000001-0000-0000-0000-000000000030'::uuid) $$,
    'owner can still generate their own beauty shopping list'
  );

  SELECT is(
    (SELECT ingredient_name FROM generate_beauty_shopping_list('c1000001-0000-0000-0000-000000000030'::uuid) LIMIT 1),
    'Beurre de Karité Test Dix',
    'owner''s shopping list still aggregates the recipe''s ingredient correctly'
  );

  SELECT * FROM finish();
  ROLLBACK;
  ```

- [ ] **Step 2: Confirm it fails**

  Run: `supabase db reset` then `supabase test db`.
  Expected: assertion 1 (`throws_ok ... 'Unauthorized'`) FAILS today (the attacker's call currently succeeds with no exception). Assertions 2 and 3 already pass (no regression risk there).

- [ ] **Step 3: Implement the fix**

  Create `supabase/migrations/20260722110700_fix_beauty_shopping_list_authorization.sql`:

  ```sql
  -- Migration: 20260722110700_fix_beauty_shopping_list_authorization.sql
  -- Finding #10 (Area C, Medium): generate_beauty_shopping_list has no
  -- auth.uid() check on p_beauty_plan_id — same IDOR pattern as Finding #1.
  -- The check cannot be the literal first statement (there is no p_user_id
  -- parameter; ownership must be resolved from the plan row itself first),
  -- so it is placed immediately after the existing "plan not found" check
  -- and before any DELETE/INSERT side effects — the same placement used by
  -- this codebase's own Nutrition-side equivalent,
  -- generate_shopping_list_internal (confirmed in
  -- supabase/migrations/20260717053537_reconcile_local_with_prod_schema.sql).
  CREATE OR REPLACE FUNCTION generate_beauty_shopping_list(p_beauty_plan_id uuid)
  RETURNS TABLE (
    shopping_list_id  uuid,
    shopping_item_id  uuid,
    ingredient_id     uuid,
    ingredient_name   text,
    category          text,
    total_quantity    numeric,
    unit              text,
    is_checked        boolean
  )
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$
  DECLARE
    v_user_id uuid;
    v_list_id uuid;
  BEGIN
    -- Get owner of beauty plan
    SELECT user_id INTO v_user_id
    FROM beauty_plan
    WHERE id = p_beauty_plan_id;

    IF v_user_id IS NULL THEN
      RAISE EXCEPTION 'Beauty plan % not found', p_beauty_plan_id;
    END IF;

    IF v_user_id IS DISTINCT FROM auth.uid() THEN
      RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Delete existing shopping list for this beauty plan
    DELETE FROM shopping_list WHERE beauty_plan_id = p_beauty_plan_id;

    -- Create container row in shopping_list
    INSERT INTO shopping_list (user_id, beauty_plan_id, name)
    VALUES (v_user_id, p_beauty_plan_id, 'Routine Beauté — Liste de Courses')
    RETURNING id INTO v_list_id;

    -- Aggregate ingredients across all slots in the beauty plan
    WITH plan_recipes AS (
      SELECT DISTINCT bps.recipe_id
      FROM beauty_plan_slot bps
      WHERE bps.plan_id = p_beauty_plan_id
        AND bps.recipe_id IS NOT NULL
    ),
    aggregated_ingredients AS (
      SELECT
        ri.ingredient_id,
        COALESCE(ri.unit, '') AS unit,
        SUM(COALESCE(ri.quantity, 1.0)) AS total_quantity
      FROM plan_recipes pr
      JOIN recipe_ingredient ri ON ri.recipe_id = pr.recipe_id
      WHERE ri.ingredient_id IS NOT NULL
      GROUP BY ri.ingredient_id, COALESCE(ri.unit, '')
    )
    INSERT INTO shopping_list_item (shopping_list_id, ingredient_id, quantity, unit, is_checked)
    SELECT
      v_list_id,
      ai.ingredient_id,
      ai.total_quantity,
      ai.unit,
      FALSE
    FROM aggregated_ingredients ai;

    -- Return results with ingredient metadata
    RETURN QUERY
    SELECT
      v_list_id AS shopping_list_id,
      sli.id AS shopping_item_id,
      sli.ingredient_id,
      COALESCE(i.name_fr, i.name, 'Ingrédient Botanique') AS ingredient_name,
      COALESCE(i.category, 'Soins Naturels') AS category,
      sli.quantity AS total_quantity,
      sli.unit,
      sli.is_checked
    FROM shopping_list_item sli
    LEFT JOIN ingredient i ON i.id = sli.ingredient_id
    WHERE sli.shopping_list_id = v_list_id;
  END;
  $$;
  ```

- [ ] **Step 4: Confirm it passes**

  Run: `supabase db reset` then `supabase test db`.
  Expected: all 3 assertions in `beauty_shopping_list_authorization_test.sql` pass.

- [ ] **Step 5: Commit**

  ```bash
  git add supabase/migrations/20260722110700_fix_beauty_shopping_list_authorization.sql
  git add supabase/tests/beauty_shopping_list_authorization_test.sql
  git commit -m "fix(beauty): add owner-only auth check to generate_beauty_shopping_list RPC"
  ```

---

## Coverage Checklist

| # | Finding | Severity | Task |
|---|---|---|---|
| 1 | `complete_beauty_onboarding` RPC has no `auth.uid() = p_user_id` check | Critical | Task 1 |
| 2 | Cross-system double-counting of `fan_subscription` revenue | Critical | Task 2 |
| 3 | No authorization check on `get_creator_beauty_payout_breakdown` / `get_platform_retained_beauty_revenue` / `get_creator_beauty_revenue_share` | High | Task 3 |
| 4 | Beauty payout system has no cron/edge-function invocation anywhere | High | Task 4 |
| 5 | `calculate_creator_payouts` has 2 coexisting overloads | High | Task 5 |
| 6 | `creator_monthly_payouts` RLS policy uses the wrong ownership idiom | Medium | Task 6 |
| 7 | Community "Browse Groups" has no mode filter | High | Task 7 |
| 8 | `complete-beauty-onboarding/index.ts` violates the Deno logging standard | Medium | Task 8 |
| 9 | `BEAUTY_MODE_REMUNERATION_AUDIT.md` documents an abandoned system | Low | Task 9 |
| 10 | `generate_beauty_shopping_list` has no `auth.uid()` check on `p_beauty_plan_id` | Medium | Task 10 |

**Explicitly out of scope (confirmed during research, not part of the 10 assigned findings):**
- Dead tables `beauty_care_logs`, `fan_allocations`, `beauty_plans`, `user_beauty_subscriptions` (from `20260521000003`) are left in place untouched — only the ambiguous 1-arg function overload operating on them is dropped (Task 5).
- `get_platform_retained_beauty_revenue` not filtering out slots with a `NULL` creator_id, and no idempotency guard once a payout is `'paid'` — both real Medium findings from the full review, but not among this plan's 10 assigned findings; not fixed here.
- `get_creator_beauty_payout_breakdown`'s own fan-earnings display math (separate from the `calculate_creator_payouts` ledger write fixed in Task 2) is left unchanged — out of scope per Finding #2's exact wording (see Task 3's migration comment).

**Cross-plan dependency flag (Area B, not owned by this plan):** `beauty_plan.is_active` is referenced by `generate_beauty_plan` / `generate_initial_beauty_plan` / `generate_beauty_plan_from_saved` but the column is never added anywhere in the codebase. This blocks the full end-to-end success path of `complete_beauty_onboarding` (Task 1) regardless of this plan's fix. Task 1's test is scoped to prove only the authorization boundary, which is unaffected by this gap. No action is needed from this plan once Area B lands its fix.
