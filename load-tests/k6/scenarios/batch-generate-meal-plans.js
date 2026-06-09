// batch-generate-meal-plans.js
// This function is an internal cron endpoint — it authenticates via INTERNAL_SECRET,
// NOT a user JWT. Set K6_INTERNAL_SECRET in the environment to match the staging secret.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../lib/config.js';

export function batchGenerateMealPlans() {
  const secret = __ENV.K6_INTERNAL_SECRET;
  if (!secret) {
    throw new Error('K6_INTERNAL_SECRET env var is required for batch-generate-meal-plans scenario');
  }

  const res = http.post(
    `${BASE_URL}/batch-generate-meal-plans`,
    JSON.stringify({ offset: 0 }),
    {
      headers: {
        'Authorization': `Bearer ${secret}`,
        'Content-Type': 'application/json',
      },
      tags: { scenario: 'batch_generate_meal_plans' },
      timeout: '90s',
    }
  );

  check(res, {
    'not 401':    r => r.status !== 401,
    'not 500':    r => r.status !== 500,
    'status 200': r => r.status === 200,
  });

  // Long sleep — this is a heavy batch job; realistic call rate is very low
  sleep(5);
}
