# 00-setup — Setup

Run this first. It creates test users, seeds data, and writes `tests/STATE.env`.
Every subsequent file sources `tests/STATE.env`.

---

## Phase 1: Prerequisites (5 checks)

### SETUP-P1-01: Docker daemon is running

```bash
docker info > /dev/null 2>&1
echo "Exit: $?"
```

EXPECTED: `Exit: 0`
PASS if: exit code is 0
FAIL if: exit code is non-zero (Docker not running)

---

### SETUP-P1-02: Container supabase_db_akeli_landing_page is running

```bash
docker inspect -f '{{.State.Running}}' supabase_db_akeli_landing_page
```

EXPECTED: `true`
PASS if: output is `true`
FAIL if: output is `false` or error

---

### SETUP-P1-03: Edge runtime container is running (start if stopped)

```bash
docker start supabase_edge_runtime_akeli_landing_page 2>/dev/null || true
sleep 3
docker inspect -f '{{.State.Running}}' supabase_edge_runtime_akeli_landing_page
```

EXPECTED: `true`
PASS if: output is `true`
FAIL if: output is `false`

---

### SETUP-P1-04: curl is installed

```bash
curl --version | head -1
```

EXPECTED: line starting with `curl`
PASS if: output contains `curl`
FAIL if: command not found

---

### SETUP-P1-05: jq is installed

```bash
jq --version
```

EXPECTED: line starting with `jq-`
PASS if: output contains `jq-`
FAIL if: command not found

---

### SETUP-P1-06: Local Supabase stack is healthy

```bash
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:54321/health)
echo "Status: $STATUS"
```

EXPECTED: `Status: 200`
PASS if: `$STATUS == "200"`
FAIL if: `$STATUS != "200"` (stack not started — run `supabase start`)

---

## Phase 2: Capture API Keys

### SETUP-P2-01: Write base STATE.env with hardcoded local keys

```bash
cat > tests/STATE.env << 'EOF'
BASE_URL=http://127.0.0.1:54321
ANON_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
SERVICE_KEY=<your-local-supabase-secret-key>
EOF
echo "Written"
```

EXPECTED: `Written`
PASS if: `tests/STATE.env` exists and contains `BASE_URL`
FAIL if: file not created

---

### SETUP-P2-02: Verify keys give a valid REST response

```bash
source tests/STATE.env
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $ANON_KEY" \
  "$BASE_URL/rest/v1/")
echo "Status: $STATUS"
```

EXPECTED: `Status: 200`
PASS if: `$STATUS == "200"`
FAIL if: `$STATUS != "200"` (wrong key or stack not running)

---

## Phase 3: Create Test Users

> Runs `POST /auth/v1/signup` for each test identity. Captures JWT + UUID into STATE.env.

### SETUP-P3-01: Create USER_A (test-user-a@akeli.test)

```bash
source tests/STATE.env
RESP_A=$(curl -s -X POST "$BASE_URL/auth/v1/signup" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user-a@akeli.test","password":"TestAkeli123!"}')
USER_A_ID=$(echo "$RESP_A" | jq -r '.user.id // .id')
USER_A_TOKEN=$(echo "$RESP_A" | jq -r '.access_token // .session.access_token')
echo "USER_A_ID=$USER_A_ID"
echo "USER_A_TOKEN=${USER_A_TOKEN:0:20}..."
```

EXPECTED: Both lines print a non-null value (UUID and JWT prefix)
PASS if: `USER_A_ID` matches UUID pattern and `USER_A_TOKEN` starts with `eyJ`
FAIL if: either is `null` (signup failed — check if user already exists; run 99-teardown.md first)

---

### SETUP-P3-02: Create USER_B (test-user-b@akeli.test)

```bash
source tests/STATE.env
RESP_B=$(curl -s -X POST "$BASE_URL/auth/v1/signup" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user-b@akeli.test","password":"TestAkeli123!"}')
USER_B_ID=$(echo "$RESP_B" | jq -r '.user.id // .id')
USER_B_TOKEN=$(echo "$RESP_B" | jq -r '.access_token // .session.access_token')
echo "USER_B_ID=$USER_B_ID"
echo "USER_B_TOKEN=${USER_B_TOKEN:0:20}..."
```

EXPECTED: Both lines print a non-null value
PASS if: `USER_B_ID` matches UUID pattern and `USER_B_TOKEN` starts with `eyJ`
FAIL if: either is `null`

---

### SETUP-P3-03: Append user IDs and tokens to STATE.env

```bash
source tests/STATE.env
cat >> tests/STATE.env << EOF
USER_A_ID=$USER_A_ID
USER_A_TOKEN=$USER_A_TOKEN
USER_B_ID=$USER_B_ID
USER_B_TOKEN=$USER_B_TOKEN
EOF
echo "Appended"
```

EXPECTED: `Appended`
PASS if: `grep USER_A_ID tests/STATE.env` returns the UUID

---

## Phase 4: Seed Test Data

> Runs a single psql block via docker exec. Inserts in FK-safe order. Captures IDs and appends to STATE.env.

### SETUP-P4-01: Run seed SQL

```bash
source tests/STATE.env
docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -v ON_ERROR_STOP=1 << SQL

-- user_profile for USER_A
INSERT INTO public.user_profile (id, first_name, last_name, username)
VALUES ('$USER_A_ID', 'Test', 'UserA', 'test_user_a')
ON CONFLICT (id) DO NOTHING;

-- user_profile for USER_B
INSERT INTO public.user_profile (id, first_name, last_name, username)
VALUES ('$USER_B_ID', 'Test', 'UserB', 'test_user_b')
ON CONFLICT (id) DO NOTHING;

-- user_health_profile for USER_A
INSERT INTO public.user_health_profile (user_id, sex, birth_date, height_cm, weight_kg, activity_level)
VALUES ('$USER_A_ID', 'M', '1990-01-01', 180, 80, 'moderate')
ON CONFLICT (user_id) DO NOTHING;

-- creator for USER_B
INSERT INTO public.creator (user_id, display_name, is_fan_eligible)
VALUES ('$USER_B_ID', 'Test Creator B', true)
ON CONFLICT (user_id) DO NOTHING;

SQL
echo "Exit: $?"
```

EXPECTED: `Exit: 0`
PASS if: exit code is 0
FAIL if: any SQL error (check ON_ERROR_STOP output)

---

### SETUP-P4-02: Capture CREATOR_B_ID and append to STATE.env

```bash
source tests/STATE.env
CREATOR_B_ID=$(docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -tAq \
  -c "SELECT id FROM public.creator WHERE user_id = '$USER_B_ID' LIMIT 1;")
echo "CREATOR_B_ID=$CREATOR_B_ID"
echo "CREATOR_B_ID=$CREATOR_B_ID" >> tests/STATE.env
```

EXPECTED: UUID printed and appended
PASS if: `CREATOR_B_ID` matches UUID pattern
FAIL if: empty (creator insert failed in P4-01)

---

### SETUP-P4-03: Insert ingredients and capture IDs

```bash
source tests/STATE.env
docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -v ON_ERROR_STOP=1 << SQL
INSERT INTO public.ingredient (name, name_fr, name_en, category)
VALUES
  ('test-ingredient-1', 'Ingrédient test 1', 'Test Ingredient 1', 'vegetable'),
  ('test-ingredient-2', 'Ingrédient test 2', 'Test Ingredient 2', 'protein'),
  ('test-ingredient-3', 'Ingrédient test 3', 'Test Ingredient 3', 'grain')
ON CONFLICT (name) DO NOTHING;
SQL
echo "Exit: $?"
```

EXPECTED: `Exit: 0`

---

### SETUP-P4-04: Capture ING_1, ING_2, ING_3 and append to STATE.env

```bash
source tests/STATE.env
ING_IDS=$(docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -tAq \
  -c "SELECT id FROM public.ingredient WHERE name LIKE 'test-%' ORDER BY name LIMIT 3;")
ING_1=$(echo "$ING_IDS" | sed -n '1p')
ING_2=$(echo "$ING_IDS" | sed -n '2p')
ING_3=$(echo "$ING_IDS" | sed -n '3p')
echo "ING_1=$ING_1"
echo "ING_2=$ING_2"
echo "ING_3=$ING_3"
cat >> tests/STATE.env << EOF
ING_1=$ING_1
ING_2=$ING_2
ING_3=$ING_3
EOF
```

EXPECTED: Three UUIDs printed
PASS if: all three match UUID pattern

---

### SETUP-P4-05: Insert recipes (4 total) and capture IDs

```bash
source tests/STATE.env
docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -v ON_ERROR_STOP=1 << SQL
INSERT INTO public.recipe (creator_id, title, description, is_published, is_private, language, compatible_starches, owner_user_id)
VALUES
  ('$CREATOR_B_ID', 'test-recipe-pub-1', 'Test published public recipe 1', true, false, 'fr', '{}', '$USER_B_ID'),
  ('$CREATOR_B_ID', 'test-recipe-pub-2', 'Test published public recipe 2', true, false, 'fr', '{}', '$USER_B_ID'),
  ('$CREATOR_B_ID', 'test-recipe-priv', 'Test published private recipe', true, true, 'fr', '{}', '$USER_B_ID'),
  ('$CREATOR_B_ID', 'test-recipe-draft', 'Test draft unpublished recipe', false, false, 'fr', '{}', '$USER_B_ID')
ON CONFLICT DO NOTHING;
SQL
echo "Exit: $?"
```

EXPECTED: `Exit: 0`

---

### SETUP-P4-06: Capture recipe IDs and append to STATE.env

```bash
source tests/STATE.env
RECIPE_PUB_1=$(docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -tAq \
  -c "SELECT id FROM public.recipe WHERE creator_id='$CREATOR_B_ID' AND title='test-recipe-pub-1' LIMIT 1;")
RECIPE_PUB_2=$(docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -tAq \
  -c "SELECT id FROM public.recipe WHERE creator_id='$CREATOR_B_ID' AND title='test-recipe-pub-2' LIMIT 1;")
RECIPE_PRIV=$(docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -tAq \
  -c "SELECT id FROM public.recipe WHERE creator_id='$CREATOR_B_ID' AND title='test-recipe-priv' LIMIT 1;")
RECIPE_DRAFT=$(docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -tAq \
  -c "SELECT id FROM public.recipe WHERE creator_id='$CREATOR_B_ID' AND title='test-recipe-draft' LIMIT 1;")
echo "RECIPE_PUB_1=$RECIPE_PUB_1"
echo "RECIPE_PUB_2=$RECIPE_PUB_2"
echo "RECIPE_PRIV=$RECIPE_PRIV"
echo "RECIPE_DRAFT=$RECIPE_DRAFT"
cat >> tests/STATE.env << EOF
RECIPE_PUB_1=$RECIPE_PUB_1
RECIPE_PUB_2=$RECIPE_PUB_2
RECIPE_PRIV=$RECIPE_PRIV
RECIPE_DRAFT=$RECIPE_DRAFT
EOF
```

EXPECTED: Four UUIDs printed
PASS if: all four match UUID pattern

---

### SETUP-P4-07: Insert recipe_ingredient, recipe_step, meal_plan, fan_subscription

```bash
source tests/STATE.env
docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -v ON_ERROR_STOP=1 << SQL

-- recipe_ingredient (link published recipes to 2 ingredients each)
INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, sort_order)
VALUES
  ('$RECIPE_PUB_1', '$ING_1', 200, 'g', 1),
  ('$RECIPE_PUB_1', '$ING_2', 100, 'g', 2),
  ('$RECIPE_PUB_2', '$ING_1', 150, 'g', 1),
  ('$RECIPE_PUB_2', '$ING_3', 50, 'g', 2)
ON CONFLICT DO NOTHING;

-- recipe_step for published recipes only
INSERT INTO public.recipe_step (recipe_id, step_number, instruction_text)
VALUES
  ('$RECIPE_PUB_1', 1, 'Test step 1 for recipe pub 1'),
  ('$RECIPE_PUB_1', 2, 'Test step 2 for recipe pub 1'),
  ('$RECIPE_PUB_2', 1, 'Test step 1 for recipe pub 2')
ON CONFLICT DO NOTHING;

-- meal_plan for USER_A
INSERT INTO public.meal_plan (user_id, name, start_date, end_date, is_active)
VALUES ('$USER_A_ID', 'test-meal-plan', CURRENT_DATE, CURRENT_DATE + 6, true)
ON CONFLICT DO NOTHING;

-- fan_subscription: USER_A subscribes to CREATOR_B
INSERT INTO public.fan_subscription (user_id, creator_id, status)
VALUES ('$USER_A_ID', '$CREATOR_B_ID', 'active')
ON CONFLICT DO NOTHING;

SQL
echo "Exit: $?"
```

EXPECTED: `Exit: 0`

---

### SETUP-P4-08: Capture MEAL_PLAN_ID and append to STATE.env

```bash
source tests/STATE.env
MEAL_PLAN_ID=$(docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres -tAq \
  -c "SELECT id FROM public.meal_plan WHERE user_id='$USER_A_ID' AND name='test-meal-plan' LIMIT 1;")
echo "MEAL_PLAN_ID=$MEAL_PLAN_ID"
echo "MEAL_PLAN_ID=$MEAL_PLAN_ID" >> tests/STATE.env
```

EXPECTED: UUID printed
PASS if: `MEAL_PLAN_ID` matches UUID pattern

---

## Phase 5: Verify Seed

### SETUP-P5-01: Count rows per seeded table

```bash
source tests/STATE.env
docker exec supabase_db_akeli_landing_page psql -U postgres -d postgres << SQL
SELECT
  (SELECT COUNT(*) FROM public.user_profile WHERE id IN ('$USER_A_ID','$USER_B_ID')) AS user_profiles,
  (SELECT COUNT(*) FROM public.user_health_profile WHERE user_id = '$USER_A_ID') AS health_profiles,
  (SELECT COUNT(*) FROM public.creator WHERE user_id = '$USER_B_ID') AS creators,
  (SELECT COUNT(*) FROM public.ingredient WHERE name LIKE 'test-%') AS ingredients,
  (SELECT COUNT(*) FROM public.recipe WHERE creator_id = '$CREATOR_B_ID') AS recipes,
  (SELECT COUNT(*) FROM public.recipe_ingredient WHERE recipe_id IN ('$RECIPE_PUB_1','$RECIPE_PUB_2')) AS recipe_ingredients,
  (SELECT COUNT(*) FROM public.recipe_step WHERE recipe_id IN ('$RECIPE_PUB_1','$RECIPE_PUB_2')) AS recipe_steps,
  (SELECT COUNT(*) FROM public.meal_plan WHERE user_id = '$USER_A_ID') AS meal_plans,
  (SELECT COUNT(*) FROM public.fan_subscription WHERE user_id = '$USER_A_ID') AS fan_subscriptions;
SQL
```

EXPECTED:
```
 user_profiles | health_profiles | creators | ingredients | recipes | recipe_ingredients | recipe_steps | meal_plans | fan_subscriptions
---------------+-----------------+----------+-------------+---------+--------------------+--------------+------------+-------------------
             2 |               1 |        1 |           3 |       4 |                  4 |            3 |          1 |                 1
```

PASS if: all counts match expected values
FAIL if: any count is 0 or wrong (re-run Phase 4 for the failing table)

---

## Summary

| Step | Description | Status |
|------|-------------|--------|
| SETUP-P1-01 | Docker running | |
| SETUP-P1-02 | DB container running | |
| SETUP-P1-03 | Edge runtime running | |
| SETUP-P1-04 | curl installed | |
| SETUP-P1-05 | jq installed | |
| SETUP-P1-06 | Stack healthy | |
| SETUP-P2-01 | STATE.env created | |
| SETUP-P2-02 | Keys valid | |
| SETUP-P3-01 | USER_A created | |
| SETUP-P3-02 | USER_B created | |
| SETUP-P3-03 | IDs appended to STATE.env | |
| SETUP-P4-01 | Profiles seeded | |
| SETUP-P4-02 | CREATOR_B_ID captured | |
| SETUP-P4-03 | Ingredients seeded | |
| SETUP-P4-04 | ING_1/2/3 captured | |
| SETUP-P4-05 | Recipes seeded | |
| SETUP-P4-06 | Recipe IDs captured | |
| SETUP-P4-07 | Linking rows seeded | |
| SETUP-P4-08 | MEAL_PLAN_ID captured | |
| SETUP-P5-01 | Seed verified | |
