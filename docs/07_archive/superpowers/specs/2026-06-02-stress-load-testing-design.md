---
name: stress-load-testing
description: Full stress and load testing system for Akeli — k6 Cloud, staging Supabase, three phases (pre-launch sweep, bottleneck deep-dive, CI/CD gate), six scenarios covering all 24 edge functions
metadata:
  type: spec
---

# Stress & Load Testing — Design Spec

**Date:** 2026-06-02

---

## Context

Akeli is preparing for a large public launch (5 000+ concurrent users). The backend consists of 24 Deno edge functions, complex Supabase RPCs (notably `generate_meal_plan`), PostgREST queries behind RLS policies, and Supabase Realtime for group chat. No load testing infrastructure currently exists. This spec defines a three-phase system that covers pre-launch ceiling discovery, targeted bottleneck profiling, and an automated CI/CD gate on every PR.

---

## Goals

1. **Find the ceiling** before launch — identify at what VU count the system starts failing and which endpoint breaks first.
2. **Profile known heavy endpoints** — measure `generate-meal-plan`, `batch-generate-meal-plans`, `ai-assistant-chat`, and `analyze-meal-photo` under sustained load.
3. **Gate every PR** — a lightweight smoke test blocks merges if any endpoint regresses.

---

## Architecture

```
k6 scripts (JavaScript)
    │
    ▼
k6 Cloud (distributed VU execution, 5 000+ VUs, multi-region)
    │
    ▼
Supabase staging project (isolated, seeded, disposable)
    │
    ├── Edge functions (24 Deno functions)
    ├── PostgREST (direct DB queries via RLS)
    └── Realtime (group chat WebSocket)

GitHub Actions
    └── Smoke gate: k6 OSS (no cloud), 10 VU, every PR
```

### Three phases

| Phase | Type | VU | Trigger | Tool |
|-------|------|----|---------|------|
| 1 — Pre-launch sweep | Stress ramp — find ceiling | 10 → 5 000 | Manual, before launch | k6 Cloud |
| 2 — Bottleneck deep-dive | Sustained load on Tier 1 endpoints | 500–2 000 | Manual, after Phase 1 findings | k6 Cloud |
| 3 — CI/CD gate | Smoke test | 10 | Every PR, every deploy | k6 OSS (GH Actions) |

### Folder layout

```
load-tests/
  k6/
    scenarios/
      generate-meal-plan.js
      batch-generate-meal-plans.js
      ai-features.js
      social-feed.js
      community.js
      smoke-sweep.js
    lib/
      auth.js        ← JWT pool loader
      config.js      ← base URL, shared thresholds
    seed/
      01_recipes.sql
      02_users.sql
      03_groups.sql
      04_fan_subscriptions.sql
      05_allergens.sql
      create-jwt-pool.ts
    smoke.js         ← Phase 3 entry (10 VU)
    load.js          ← Phase 2 entry (500–2 000 VU)
    stress.js        ← Phase 1 entry (5 000 VU ramp)
  .github/workflows/
    load-test-smoke.yml
    load-test-full.yml
```

---

## Endpoint Tiering

### Tier 1 — Heavy compute, test to destruction

| Endpoint | Why it's heavy |
|----------|---------------|
| `generate-meal-plan` | Complex RPC, inserts 21+ rows, creates batch sessions + shopping list, cosine vector search |
| `batch-generate-meal-plans` | Calls `generate-meal-plan` for every user simultaneously |
| `ai-assistant-chat` | Streams from Claude API, session state, unbounded latency |
| `analyze-meal-photo` | Vision AI call + DB write, high per-request cost |
| `compute-group-vectors` | Vector aggregation across all group members |

### Tier 2 — High frequency, test for throughput

| Endpoint | Expected call pattern |
|----------|-----------------------|
| `log-meal-consumption` | Every meal log action |
| `rate-meal-consumption` | After every meal rating |
| `toggle-recipe-like` / `toggle-recipe-save` | Social feed interactions |
| `notify-group-message` | Every group chat message |
| PostgREST recipe feed | Every feed scroll / page load |

### Tier 3 — Background / low frequency, smoke only

`send-meal-reminders`, `compute-monthly-revenue`, `stripe-webhook`, `translate-content`, `send-push-notification`, `validate-store-purchase`, `create-checkout-session`, `get-creator-dashboard`, `complete-onboarding`, `submit-allergen-suggestion`, `invite-to-group`, `activate-fan-mode`, `cancel-fan-mode`, `process-fan-mode-transitions`

---

## Six Test Scenarios

| # | Scenario | Endpoints covered | Phase |
|---|----------|-------------------|-------|
| S1 | Meal plan generation ramp | `generate-meal-plan` full RPC chain | 1 + 2 |
| S2 | Batch generation spike | `batch-generate-meal-plans` | 1 + 2 |
| S3 | AI feature endurance | `ai-assistant-chat`, `analyze-meal-photo` | 2 |
| S4 | Social feed throughput | `toggle-recipe-like`, `toggle-recipe-save`, PostgREST feed | 1 + 2 |
| S5 | Community load | `notify-group-message`, Realtime WebSocket, `invite-to-group` | 2 |
| S6 | Smoke sweep | All 24 edge functions, 1 request each | 3 (CI) |

---

## Test Data Strategy

### Staging project setup

A dedicated Supabase project (separate from production) with the same schema applied via `supabase db push`. Torn down and re-seeded before each major test run to eliminate data pollution.

### Seed data

| Entity | Count | Purpose |
|--------|-------|---------|
| Synthetic users | 500 | Each with health profile, user vector, calorie goals |
| Published recipes | 100+ per meal type (400+ total) | Prevents `insufficient_recipes` errors during load |
| `recipe_macro` rows | One per recipe | Required for meal generator serving computation |
| `recipe_ingredient` rows | 5–8 per recipe | Required for `meal_ingredient` population |
| Fan subscriptions | 50 users → test creator | Tests 90% fan rule under load |
| Community groups | 20 groups, 25 members each | Tests group chat and vector computation |
| Allergen data | 10 common allergens | Tests allergen workflow |

### Auth strategy

500 Supabase Auth accounts pre-created by the seed script. A Deno setup script (`create-jwt-pool.ts`) logs each one in and writes JWTs to `jwt-pool.json`. Each virtual user picks an account from the pool by index (`vuIndex % pool.length`). No auth calls during test runs. JWTs are rotated before each run. Credentials stored as GitHub secrets, never committed to git.

### Reset command

```bash
supabase db reset --project-ref <staging-ref>
supabase db push --project-ref <staging-ref>
deno run --allow-net --allow-write load-tests/k6/seed/create-jwt-pool.ts
```

---

## Thresholds & Success Criteria

### Metric definitions

- **p95 latency** — 95% of requests completed within this time. Standard measure because averages hide spikes.
- **error rate** — percentage of requests that returned non-2xx or timed out.
- **throughput** — requests per second sustained at peak VU (reported, not thresholded).

### Per-scenario thresholds

| Scenario | Endpoint | p95 latency | Error rate |
|----------|----------|-------------|------------|
| S1 | `generate-meal-plan` | < 10s | < 1% |
| S2 | `batch-generate-meal-plans` | < 60s | < 2% |
| S3 | `ai-assistant-chat` | < 20s | < 2% |
| S3 | `analyze-meal-photo` | < 25s | < 2% |
| S4 | `toggle-recipe-like` | < 300ms | < 0.5% |
| S4 | `toggle-recipe-save` | < 300ms | < 0.5% |
| S4 | PostgREST recipe feed | < 500ms | < 0.5% |
| S5 | `notify-group-message` | < 1s | < 1% |
| S5 | Realtime WebSocket msg delivery | < 500ms | < 1% |
| S6 | Smoke (all endpoints) | < 5s | 0% |

### Phase 1 stress ramp — special rule

The ramp test does not have a pass/fail threshold. Its purpose is to find the breaking point. Output is a report answering:

- At what VU count did error rate first exceed 5%?
- Which endpoint degraded first?
- What was p95 latency at 500 / 1 000 / 2 000 / 5 000 VU?

This report directly informs Phase 2 target selection.

---

## k6 Script Structure

### Shared config (`lib/config.js`)

```javascript
export const BASE_URL = __ENV.SUPABASE_URL + '/functions/v1';
export const ANON_KEY  = __ENV.SUPABASE_ANON_KEY;

export const thresholds = {
  'http_req_duration{scenario:generate_meal_plan}': ['p(95)<10000'],
  'http_req_failed{scenario:generate_meal_plan}':   ['rate<0.01'],
};
```

### Shared auth (`lib/auth.js`)

```javascript
import { SharedArray } from 'k6/data';

export const jwtPool = new SharedArray('jwts', () =>
  JSON.parse(open('../seed/jwt-pool.json'))
);

export function pickJwt(vuIndex) {
  return jwtPool[vuIndex % jwtPool.length];
}
```

### Example scenario (`scenarios/generate-meal-plan.js`)

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { pickJwt } from '../lib/auth.js';
import { BASE_URL } from '../lib/config.js';

export default function () {
  const jwt = pickJwt(__VU);

  const res = http.post(
    `${BASE_URL}/generate-meal-plan`,
    JSON.stringify({ days: 7, meals_per_day: 3 }),
    {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Content-Type': 'application/json',
      },
      tags: { scenario: 'generate_meal_plan' },
      timeout: '30s',
    }
  );

  check(res, {
    'status 200':                    r => r.status === 200,
    'has meal_plan_id':              r => JSON.parse(r.body)?.meal_plan_id != null,
    'no insufficient_recipes error': r => !r.body.includes('insufficient_recipes'),
  });

  sleep(1);
}
```

### Stress entry point (`stress.js`) — Phase 1

```javascript
import { options as baseThresholds } from './lib/config.js';

export const options = {
  scenarios: {
    generate_meal_plan: {
      executor: 'ramping-vus',
      startVUs: 10,
      stages: [
        { duration: '5m',  target: 500  },
        { duration: '10m', target: 2000 },
        { duration: '10m', target: 5000 },
        { duration: '5m',  target: 0   },
      ],
      exec: 'generateMealPlan',
    },
  },
  // No thresholds — finding the ceiling, not passing/failing
};
```

### Smoke entry point (`smoke.js`) — Phase 3

```javascript
export const options = {
  vus: 10,
  duration: '2m',
  thresholds: {
    http_req_duration: ['p(95)<5000'],
    http_req_failed:   ['rate<0.001'],
  },
};
```

---

## GitHub Actions Wiring

### Workflow 1 — Smoke gate (`load-test-smoke.yml`)

Triggers automatically on every PR to `main`. Runs k6 OSS (no cloud required). Posts results as a PR comment. Blocks merge if thresholds are breached.

```yaml
name: Load Test — Smoke

on:
  pull_request:
    branches: [main]

jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install k6
        run: |
          sudo gpg --no-default-keyring \
            --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] \
            https://dl.k6.io/deb stable main" \
            | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update && sudo apt-get install k6

      - name: Run smoke test
        env:
          SUPABASE_URL:      ${{ secrets.STAGING_SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.STAGING_SUPABASE_ANON_KEY }}
        run: k6 run --summary-export=k6-summary.json load-tests/k6/smoke.js

      - name: Post results as PR comment
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const summary = fs.readFileSync('k6-summary.json', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## k6 Smoke Results\n```json\n' + summary + '\n```'
            });
```

### Workflow 2 — Full load run (`load-test-full.yml`)

Triggered manually via `workflow_dispatch`. Accepts a `phase` input to select which test to run. Seeds the staging DB fresh before each run.

```yaml
name: Load Test — Full (k6 Cloud)

on:
  workflow_dispatch:
    inputs:
      phase:
        description: 'Test phase to run'
        required: true
        type: choice
        options: [stress, load, s3-ai, s5-community]

jobs:
  full-load:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: grafana/setup-k6-action@v1

      - name: Seed staging DB
        env:
          STAGING_DB_URL: ${{ secrets.STAGING_DB_URL }}
        run: |
          psql $STAGING_DB_URL -f load-tests/k6/seed/01_recipes.sql
          psql $STAGING_DB_URL -f load-tests/k6/seed/02_users.sql
          psql $STAGING_DB_URL -f load-tests/k6/seed/03_groups.sql
          psql $STAGING_DB_URL -f load-tests/k6/seed/04_fan_subscriptions.sql
          deno run --allow-net --allow-write \
            load-tests/k6/seed/create-jwt-pool.ts

      - name: Run on k6 Cloud
        env:
          K6_CLOUD_TOKEN:    ${{ secrets.K6_CLOUD_TOKEN }}
          SUPABASE_URL:      ${{ secrets.STAGING_SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.STAGING_SUPABASE_ANON_KEY }}
        run: k6 cloud load-tests/k6/${{ inputs.phase }}.js
```

### Required GitHub secrets

| Secret | Value |
|--------|-------|
| `STAGING_SUPABASE_URL` | Staging Supabase project URL |
| `STAGING_SUPABASE_ANON_KEY` | Staging anon key |
| `STAGING_DB_URL` | Staging direct Postgres connection string |
| `K6_CLOUD_TOKEN` | From Grafana k6 Cloud account settings |

---

## End-to-End Flow

```
PR opened
  → smoke.yml triggers automatically
  → k6 runs 10 VU × 2 min against staging
  → results posted as PR comment
  → thresholds breached → PR blocked

Before launch (manual):
  → workflow_dispatch → phase: stress
  → staging seeded fresh
  → k6 Cloud ramps 10 → 5 000 VU
  → Grafana dashboard shows live results
  → breaking point identified → Phase 2 targeted fixes

After fixes (manual):
  → workflow_dispatch → phase: load
  → sustained 500–2 000 VU on weak endpoints
  → thresholds enforced, results archived in k6 Cloud
```

---

## Out of Scope

- Flutter app UI performance (frame rate, widget rebuild counts) — separate concern
- Database query plan analysis (EXPLAIN ANALYZE) — done ad-hoc via Supabase dashboard
- Stripe payment flow load testing — Stripe has its own test environment and rate limits
- CDN / asset delivery testing — no user-uploaded assets served through edge functions
