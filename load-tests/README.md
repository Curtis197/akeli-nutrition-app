# Stress & Load Testing Infrastructure

k6-based load testing for the Akeli backend. Three phases: pre-launch stress sweep, bottleneck deep-dive, and CI/CD smoke gate. See the design spec for full context: `docs/superpowers/specs/2026-06-02-stress-load-testing-design.md`.

---

## Prerequisites

- [k6](https://k6.io/docs/get-started/installation/) installed locally (or use GitHub Actions)
- [Deno](https://deno.land/) for the JWT pool seed script
- A dedicated Supabase **staging** project (never run load tests against production)
- A [Grafana k6 Cloud](https://app.k6.io) account for Phase 1 and Phase 2

## Required Secrets

Set these as GitHub Actions secrets (`Settings → Secrets → Actions`) and as local env vars for manual runs:

| Secret | Purpose |
|--------|---------|
| `STAGING_SUPABASE_URL` | Staging project URL (`https://xxxx.supabase.co`) |
| `STAGING_SUPABASE_ANON_KEY` | Staging anon key |
| `STAGING_SUPABASE_SERVICE_ROLE_KEY` | Service role key — used only by `create-jwt-pool.ts` to create auth users |
| `STAGING_DB_URL` | Direct Postgres connection string for seeding |
| `K6_CLOUD_TOKEN` | From Grafana k6 Cloud → Account → API tokens |
| `K6_INTERNAL_SECRET` | Must match `INTERNAL_SECRET` set on the staging edge function environment |

---

## Setup: Seed the Staging DB

Run once before any test (and before each Phase 1 or Phase 2 run to reset state):

```bash
# 1. Reset schema (apply all migrations fresh)
supabase db reset --project-ref <staging-ref>
supabase db push --project-ref <staging-ref>

# 2. Create 500 auth users + export jwt-pool.json
#    (Uses service_role key — creates real Supabase Auth accounts)
cd load-tests/k6/seed
deno run --allow-net --allow-env --allow-write create-jwt-pool.ts

# 3. Seed public schema tables (requires auth users to exist first)
psql $STAGING_DB_URL -f 01_recipes.sql
psql $STAGING_DB_URL -f 02_users.sql
psql $STAGING_DB_URL -f 03_groups.sql
psql $STAGING_DB_URL -f 04_fan_subscriptions.sql
psql $STAGING_DB_URL -f 05_allergens.sql
```

**Seed contents:**
- 400 published recipes (100 per meal type) with `recipe_macro` and `recipe_vector` rows
- 500 synthetic auth users with `user_profile`, `user_health_profile`, `user_goal`, `user_vector`
- 20 community groups with 25 members each
- 50 fan subscriptions to a test creator
- 10 allergens

---

## Running Tests

### Phase 3 — Smoke gate (10 VU, 2 min, local k6)

Runs automatically on every PR. To run manually:

```bash
k6 run \
  -e SUPABASE_URL=$STAGING_SUPABASE_URL \
  -e SUPABASE_ANON_KEY=$STAGING_SUPABASE_ANON_KEY \
  load-tests/k6/smoke.js
```

### Phase 2 — Load deep-dive (k6 Cloud)

```bash
k6 cloud \
  -e SUPABASE_URL=$STAGING_SUPABASE_URL \
  -e SUPABASE_ANON_KEY=$STAGING_SUPABASE_ANON_KEY \
  -e K6_INTERNAL_SECRET=$K6_INTERNAL_SECRET \
  load-tests/k6/load.js
```

### Phase 1 — Stress ramp to ceiling (k6 Cloud)

```bash
k6 cloud \
  -e SUPABASE_URL=$STAGING_SUPABASE_URL \
  -e SUPABASE_ANON_KEY=$STAGING_SUPABASE_ANON_KEY \
  load-tests/k6/stress.js
```

Or trigger via GitHub Actions → **Load Test — Full (k6 Cloud)** → choose phase.

---

## Optional env vars for scenario scripts

| Var | Default | Purpose |
|-----|---------|---------|
| `TEST_RECIPE_ID` | `00000000-0000-0000-0000-000000000001` | Known recipe UUID from seed |
| `TEST_GROUP_ID` | `00000000-0000-0000-0000-000000000010` | Known group UUID from seed |
| `TEST_MEAL_PHOTO_URL` | Wikimedia food image | Image URL for `analyze-meal-photo` scenario |

---

## Known Limitations

- **Realtime WebSocket** — group chat WebSocket latency is not yet tested. k6 supports WebSockets via `k6/experimental/websockets` but requires Supabase Realtime channel URL configuration. Left as a TODO.
- **Auth user creation** — `create-jwt-pool.ts` creates Supabase Auth users via the Admin API. On a fresh staging project this takes ~3–5 minutes for 500 users. On re-runs, existing users return HTTP 422 (ignored) and sign-in proceeds.
- **AI cost** — Phase 2 AI scenarios hit real Claude and vision APIs. At 100 AI VUs × 10 minutes this generates roughly 3 000 Claude API calls. Monitor staging API usage accordingly.
