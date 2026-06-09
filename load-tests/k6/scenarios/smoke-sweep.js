// smoke-sweep.js
// Calls each Tier 2 and Tier 3 endpoint once per iteration to verify they
// respond (no 5xx). Tier 1 heavy endpoints (generate-meal-plan, batch-generate,
// ai-assistant-chat, analyze-meal-photo) are intentionally excluded — calling
// them with empty payloads in a CI loop would generate junk DB records and
// consume Claude API credits on every PR. Their health is covered by S1-S3
// in the full load suite.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { pickJwt } from '../lib/auth.js';
import { BASE_URL } from '../lib/config.js';

// Tier 2 + Tier 3 endpoints safe to call with a generic body
const ENDPOINTS = [
  'log-meal-consumption',
  'rate-meal-consumption',
  'toggle-recipe-like',
  'toggle-recipe-save',
  'notify-group-message',
  'get-creator-dashboard',
  'send-push-notification',
  'translate-content',
  'submit-allergen-suggestion',
  'invite-to-group',
  'activate-fan-mode',
  'cancel-fan-mode',
  'complete-onboarding',
];

export function smokeSweep() {
  const jwt = pickJwt(__VU);

  for (const fn of ENDPOINTS) {
    const res = http.post(
      `${BASE_URL}/${fn}`,
      JSON.stringify({}),
      {
        headers: {
          'Authorization': `Bearer ${jwt}`,
          'Content-Type': 'application/json',
        },
        tags: { scenario: 'smoke' },
        timeout: '10s',
      }
    );

    // Missing required params → 400 is expected and fine.
    // A 5xx means the function crashed or has a boot error.
    check(res, {
      [`${fn}: no 5xx`]: r => r.status < 500,
    });
  }

  sleep(1);
}
