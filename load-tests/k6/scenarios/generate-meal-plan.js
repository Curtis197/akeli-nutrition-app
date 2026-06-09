import http from 'k6/http';
import { check, sleep } from 'k6';
import { pickJwt } from '../lib/auth.js';
import { BASE_URL } from '../lib/config.js';

export function generateMealPlan() {
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
