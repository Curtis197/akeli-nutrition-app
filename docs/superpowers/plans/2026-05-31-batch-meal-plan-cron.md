# Batch Meal Plan Generation — Cron Job Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate a weekly meal plan for every user automatically every Sunday at 11pm UTC, using a self-chaining edge function that processes users in batches of 500 to support 10k–50k users without hitting the 150s edge function timeout.

**Architecture:** A pg_cron job fires Sunday 11pm UTC and calls the `batch-generate-meal-plans` edge function with `offset: 0`. The function processes 500 users, calling a new `generate_meal_plan_internal` SQL function (VOID, no auth check, idempotency guard) for each user, then fire-and-forgets a call to itself with the next offset if more users remain. The chain terminates naturally when a batch returns fewer than 500 users.

**Tech Stack:** pg_cron, pg_net, Supabase Edge Functions (Deno), supabase-js service role client, existing `generate_meal_plan` SQL logic.

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `supabase/functions/batch-generate-meal-plans/index.ts` | **Create** | Batch orchestrator edge function |
| DB: `public.generate_meal_plan_internal` | **Create via SQL** | VOID version of `generate_meal_plan`, no auth check, idempotency guard |
| DB: `cron.job` | **Register via SQL** | Sunday 11pm UTC cron entry |

---

## Task 1: Create `generate_meal_plan_internal` SQL function

This is a VOID copy of the existing `generate_meal_plan` function with three changes:
1. No `auth.uid()` authorization check (removed entirely)
2. Returns `void` instead of `TABLE(...)` — batch callers discard results
3. Idempotency guard — skips users who already have an active plan starting on `p_start_date`

**Files:**
- Apply via: Supabase MCP `execute_sql` on project `njzqcftjzskwcpforwzf`

- [ ] **Step 1: Apply the SQL function via MCP execute_sql**

Run this SQL on project `njzqcftjzskwcpforwzf`:

```sql
CREATE OR REPLACE FUNCTION public.generate_meal_plan_internal(
  p_user_id       uuid,
  p_days          integer DEFAULT 7,
  p_meals_per_day integer DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_vector            vector(50);
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_meal_types             text[] := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_calorie_goal           numeric;
  v_protein_goal           numeric;
  v_fat_goal               numeric;
  v_target_meal_cal        numeric;
  v_target_protein_density numeric;
  v_target_fat_density     numeric;
  v_servings               numeric(4,1);
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
BEGIN
  -- Idempotency: skip if an active plan already exists for this start date
  IF EXISTS (
    SELECT 1 FROM meal_plan
    WHERE user_id = p_user_id
      AND start_date = p_start_date
      AND is_active = true
  ) THEN
    RETURN;
  END IF;

  v_total_slots     := p_days * p_meals_per_day;
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND p_meals_per_day > 0 THEN
    v_target_protein_density :=
      COALESCE(v_protein_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
    v_target_fat_density :=
      COALESCE(v_fat_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
  ELSE
    v_target_protein_density := 7.5;
    v_target_fat_density     := 3.3;
  END IF;

  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      v_target_meal_cal := NULL;
      SELECT md.calorie_target INTO v_target_meal_cal
      FROM meal_distribution md
      JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
      WHERE np.user_id = p_user_id
        AND np.is_active = true
        AND md.meal_type = v_meal_type
      LIMIT 1;

      IF v_target_meal_cal IS NULL AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / p_meals_per_day;
      END IF;

      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (
                 0.50 * (1 - (rv.vector <=> v_user_vector))
                        * CASE WHEN v_fan_creator_id IS NOT NULL
                                    AND r.creator_id = v_fan_creator_id
                               THEN 1.5 ELSE 1.0 END
                 + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                         - v_target_protein_density)
                     / NULLIF(v_target_protein_density, 0.001),
                     1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001),
                     1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.calories > 0 THEN
        v_servings := GREATEST(0.1, LEAST(4.0,
          ROUND((v_target_meal_cal / v_recipe.calories)::numeric, 1)));
      ELSE
        v_servings := 1.0;
      END IF;

      INSERT INTO meal_plan_entry (
        meal_plan_id, scheduled_date, meal_type, servings,
        calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed
      )
      VALUES (
        v_plan_id, v_current_date, v_meal_type, v_servings,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        ROUND((v_recipe.carbs_g   * v_servings)::numeric, 1),
        ROUND((v_recipe.fat_g     * v_servings)::numeric, 1)
      )
      RETURNING id INTO v_entry_id;

      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
      SELECT
        v_entry_id,
        ri.ingredient_id,
        COALESCE(i.name_fr, i.name),
        ROUND((ri.quantity * v_servings)::numeric, 3),
        ri.unit
      FROM recipe_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = v_recipe.id
        AND ri.is_optional = false;

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

    END LOOP;
  END LOOP;
END;
$function$;
```

- [ ] **Step 2: Verify the function was created**

Run via MCP execute_sql:
```sql
SELECT proname, prorettype::regtype, prosecdef
FROM pg_proc
WHERE proname = 'generate_meal_plan_internal'
  AND pronamespace = 'public'::regnamespace;
```

Expected output:
```
proname                      | prorettype | prosecdef
generate_meal_plan_internal  | void       | true
```

- [ ] **Step 3: Smoke-test the function with a real user**

Fetch a valid user ID:
```sql
SELECT id FROM user_profile LIMIT 1;
```

Then call the function (replace `<user-id>` with the result):
```sql
SELECT generate_meal_plan_internal(
  '<user-id>'::uuid,
  7,
  3,
  (CURRENT_DATE + INTERVAL '1 day')::date
);
```

Expected: no exception, returns void. Verify a plan was created:
```sql
SELECT id, start_date, is_active
FROM meal_plan
WHERE user_id = '<user-id>'::uuid
ORDER BY created_at DESC
LIMIT 1;
```

Expected: one row with `is_active = true` and `start_date = tomorrow`.

- [ ] **Step 4: Test idempotency — call the function again for the same user and date**

```sql
SELECT generate_meal_plan_internal(
  '<user-id>'::uuid,
  7,
  3,
  (CURRENT_DATE + INTERVAL '1 day')::date
);
```

Expected: no error, no duplicate plan. Verify count is still 1:
```sql
SELECT COUNT(*)
FROM meal_plan
WHERE user_id = '<user-id>'::uuid
  AND start_date = (CURRENT_DATE + INTERVAL '1 day')::date
  AND is_active = true;
```

Expected: `count = 1`

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(db): add generate_meal_plan_internal for batch cron use"
```

---

## Task 2: Create `batch-generate-meal-plans` edge function

The function authenticates via `INTERNAL_SECRET`, pages through `user_profile` in chunks of 500, calls `generate_meal_plan_internal` per user, and self-chains by fire-and-forgetting a fetch to itself with the next offset when the batch is full.

**Files:**
- Create: `supabase/functions/batch-generate-meal-plans/index.ts`

- [ ] **Step 1: Create the file**

Create `supabase/functions/batch-generate-meal-plans/index.ts` with this content:

```typescript
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { createLogger } from '../_shared/logger.ts'

const BATCH_SIZE = 500;

Deno.serve(async (req: Request): Promise<Response> => {
  const logger = createLogger('batch-generate-meal-plans');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info('⚡ ENTRY | method: ' + req.method);

  const secret = Deno.env.get('INTERNAL_SECRET');
  const authHeader = req.headers.get('Authorization');
  if (!secret || authHeader !== `Bearer ${secret}`) {
    logger.warn('EARLY RETURN | reason: unauthorized');
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const body = await req.json().catch(() => ({}));
  const offset: number = typeof body.offset === 'number' ? body.offset : 0;

  logger.debug('[STEP 1] Computing next Monday start date');
  const nextMonday = getNextMonday();

  logger.debug('[STEP 2] Fetching user batch | offset: ' + offset + ' | batch_size: ' + BATCH_SIZE);
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { data: users, error: usersError } = await supabase
    .from('user_profile')
    .select('id')
    .range(offset, offset + BATCH_SIZE - 1);

  if (usersError) {
    logger.error('💥 Failed to fetch users', { message: usersError.message });
    return new Response(JSON.stringify({ error: usersError.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  logger.info('[STEP 3] Processing ' + users.length + ' users | start_date: ' + nextMonday);

  let success = 0;
  let skipped = 0;
  let failed = 0;
  const errors: { userId: string; error: string }[] = [];

  for (const user of users) {
    logger.debug('[STEP 3] generate_meal_plan_internal | userId: ' + user.id);
    const { error } = await supabase.rpc('generate_meal_plan_internal', {
      p_user_id: user.id,
      p_start_date: nextMonday,
    });
    if (error) {
      if (error.message.includes('insufficient_recipes')) {
        skipped++;
        logger.warn('Skipped | userId: ' + user.id + ' | reason: insufficient_recipes');
      } else {
        failed++;
        errors.push({ userId: user.id, error: error.message });
        logger.warn('Failed | userId: ' + user.id + ' | error: ' + error.message);
      }
    } else {
      success++;
    }
  }

  logger.info(
    '[STEP 4] Batch complete | success: ' + success +
    ' | skipped: ' + skipped +
    ' | failed: ' + failed
  );

  // Self-chain if there may be more users (batch was full)
  if (users.length === BATCH_SIZE) {
    const nextOffset = offset + BATCH_SIZE;
    logger.info('[STEP 5] Self-chaining | next offset: ' + nextOffset);
    fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/batch-generate-meal-plans`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${secret}`,
      },
      body: JSON.stringify({ offset: nextOffset }),
    }).catch((e: Error) =>
      logger.error('💥 Self-chain request failed', { message: e.message })
    );
  }

  logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
  return new Response(
    JSON.stringify({ offset, success, skipped, failed, errors: errors.slice(0, 20) }),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
  );
});

function getNextMonday(): string {
  const today = new Date();
  const dayOfWeek = today.getUTCDay(); // 0 = Sunday
  const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek;
  const nextMonday = new Date(today);
  nextMonday.setUTCDate(today.getUTCDate() + daysUntilMonday);
  return nextMonday.toISOString().split('T')[0];
}
```

- [ ] **Step 2: Deploy the edge function**

```bash
supabase functions deploy batch-generate-meal-plans --project-ref njzqcftjzskwcpforwzf
```

Expected output: `Deployed Function batch-generate-meal-plans`

- [ ] **Step 3: Verify the function is live**

Check it appears in the function list via MCP `list_edge_functions` on project `njzqcftjzskwcpforwzf`. Expected: `batch-generate-meal-plans` with `status: ACTIVE`.

- [ ] **Step 4: Test the function manually with a small batch (offset 0, limit 1 user)**

Temporarily call with curl (replace `<INTERNAL_SECRET>` and `<PROJECT_REF>`):

```bash
curl -X POST \
  https://<PROJECT_REF>.supabase.co/functions/v1/batch-generate-meal-plans \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <INTERNAL_SECRET>" \
  -d '{"offset": 0}'
```

Expected response (shape):
```json
{
  "offset": 0,
  "success": 500,
  "skipped": 0,
  "failed": 0,
  "errors": []
}
```

> Note: `success + skipped + failed` must equal the number of users in the batch. Any `failed > 0` with unexpected errors should be investigated before proceeding.

- [ ] **Step 5: Test unauthorized rejection**

```bash
curl -X POST \
  https://<PROJECT_REF>.supabase.co/functions/v1/batch-generate-meal-plans \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer wrong-secret" \
  -d '{}'
```

Expected: `401 Unauthorized`

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/batch-generate-meal-plans/index.ts
git commit -m "feat(edge): add batch-generate-meal-plans self-chaining edge function"
```

---

## Task 3: Register the pg_cron job

**Files:**
- Apply via: Supabase MCP `execute_sql` on project `njzqcftjzskwcpforwzf`

- [ ] **Step 1: Register the cron job**

Run via MCP execute_sql:

```sql
SELECT cron.schedule(
  'batch-generate-meal-plans-weekly',
  '0 23 * * 0',
  $$
  SELECT net.http_post(
    url     := (SELECT 'https://' || current_setting('app.supabase_project_ref', true) || '.supabase.co/functions/v1/batch-generate-meal-plans'),
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || current_setting('app.cron_secret', true)
    ),
    body    := '{}'::jsonb
  ) AS request_id;
  $$
);
```

- [ ] **Step 2: Verify the job is registered**

```sql
SELECT jobid, jobname, schedule, active FROM cron.job ORDER BY jobid;
```

Expected:
```
jobid | jobname                              | schedule    | active
1     | batch-generate-meal-plans-weekly     | 0 23 * * 0  | true
```

- [ ] **Step 3: Verify `app.cron_secret` is set**

```sql
SELECT current_setting('app.cron_secret', true) IS NOT NULL AS secret_present;
```

Expected: `secret_present = true`. If false, the secret was never configured — set it:

```sql
ALTER DATABASE postgres SET app.cron_secret = '<your-INTERNAL_SECRET-value>';
```

Then reload config:
```sql
SELECT pg_reload_conf();
```

- [ ] **Step 4: Confirm `app.supabase_project_ref` is set**

```sql
SELECT current_setting('app.supabase_project_ref', true) AS project_ref;
```

Expected: `njzqcftjzskwcpforwzf`. If not set:

```sql
ALTER DATABASE postgres SET app.supabase_project_ref = 'njzqcftjzskwcpforwzf';
SELECT pg_reload_conf();
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(cron): schedule weekly batch meal plan generation every Sunday 23:00 UTC"
```

---

## Verification Checklist

After all tasks are complete:

- [ ] `SELECT proname FROM pg_proc WHERE proname = 'generate_meal_plan_internal';` returns 1 row
- [ ] `SELECT jobname, schedule, active FROM cron.job;` shows the Sunday 11pm job as active
- [ ] Manual curl to the edge function returns `{ success: N, failed: 0 }`
- [ ] Calling the function twice for the same user + start_date creates only 1 meal plan (idempotency)
- [ ] Calling with wrong `Authorization` header returns 401
