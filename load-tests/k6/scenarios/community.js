// community.js
// Uses TEST_GROUP_ID env var (set by seed — known UUID from 03_groups.sql).
// Falls back to the deterministic first group UUID from the seed.
//
// NOTE: Supabase Realtime WebSocket testing requires the k6 WebSocket extension
// (k6/experimental/websockets) and a valid Realtime channel URL. This is left
// as a TODO — realtime latency should be tested separately using a dedicated
// k6 websocket script once the staging Realtime config is confirmed.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { pickJwt } from '../lib/auth.js';
import { BASE_URL } from '../lib/config.js';

const TEST_GROUP_ID = __ENV.TEST_GROUP_ID || '00000000-0000-0000-0000-000000000010';

export function notifyGroupMessage() {
  const jwt = pickJwt(__VU);

  const res = http.post(
    `${BASE_URL}/notify-group-message`,
    JSON.stringify({
      group_id: TEST_GROUP_ID,
      message: 'Load test message',
    }),
    {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Content-Type': 'application/json',
      },
      tags: { scenario: 'notify_group_message' },
      timeout: '10s',
    }
  );

  check(res, {
    'not 500':    r => r.status !== 500,
    'status 200': r => r.status === 200,
  });

  sleep(1);
}
