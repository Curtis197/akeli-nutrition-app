// social-feed.js
// Uses TEST_RECIPE_ID env var (set by seed — known UUID from 01_recipes.sql).
// Falls back to a constant that matches the seed's deterministic first recipe UUID.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { pickJwt } from '../lib/auth.js';
import { BASE_URL } from '../lib/config.js';

const TEST_RECIPE_ID = __ENV.TEST_RECIPE_ID || '00000000-0000-0000-0000-000000000001';

export function toggleRecipeLike() {
  const jwt = pickJwt(__VU);

  const res = http.post(
    `${BASE_URL}/toggle-recipe-like`,
    JSON.stringify({ recipe_id: TEST_RECIPE_ID }),
    {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Content-Type': 'application/json',
      },
      tags: { scenario: 'toggle_recipe_like' },
      timeout: '10s',
    }
  );

  check(res, {
    'not 500': r => r.status !== 500,
    'status 200': r => r.status === 200,
  });

  sleep(0.5);
}

export function toggleRecipeSave() {
  const jwt = pickJwt(__VU);

  const res = http.post(
    `${BASE_URL}/toggle-recipe-save`,
    JSON.stringify({ recipe_id: TEST_RECIPE_ID }),
    {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Content-Type': 'application/json',
      },
      tags: { scenario: 'toggle_recipe_save' },
      timeout: '10s',
    }
  );

  check(res, {
    'not 500': r => r.status !== 500,
    'status 200': r => r.status === 200,
  });

  sleep(0.5);
}

export function postgrestRecipeFeed() {
  const jwt = pickJwt(__VU);
  const supabaseUrl = __ENV.SUPABASE_URL;
  const anonKey = __ENV.SUPABASE_ANON_KEY;

  const res = http.get(
    `${supabaseUrl}/rest/v1/recipe?select=id,title,meal_types,is_published&is_published=eq.true&limit=10`,
    {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'apikey': anonKey,
        'Content-Type': 'application/json',
      },
      tags: { scenario: 'postgrest_recipe_feed' },
      timeout: '10s',
    }
  );

  check(res, {
    'status 200':  r => r.status === 200,
    'has recipes': r => JSON.parse(r.body)?.length > 0,
  });

  sleep(1);
}
