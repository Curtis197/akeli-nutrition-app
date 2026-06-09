import http from 'k6/http';
import { check, sleep } from 'k6';
import { pickJwt } from '../lib/auth.js';
import { BASE_URL } from '../lib/config.js';

export function aiAssistantChat() {
  const jwt = pickJwt(__VU);

  const res = http.post(
    `${BASE_URL}/ai-assistant-chat`,
    JSON.stringify({ message: 'Can you suggest a high protein breakfast?', history: [] }),
    {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Content-Type': 'application/json',
      },
      tags: { scenario: 'ai_assistant_chat' },
      timeout: '35s',  // threshold is p95 < 20s; 35s gives buffer before k6 hard-kills the request
    }
  );

  check(res, {
    'not 500':            r => r.status !== 500,
    'status 200':         r => r.status === 200,
    'has response text':  r => !!JSON.parse(r.body)?.text,
  });

  sleep(2);
}

export function analyzeMealPhoto() {
  const jwt = pickJwt(__VU);

  // Use a real publicly-accessible food image; example.com images are not food
  // and may cause the vision model to return an error.
  // Replace with a Supabase Storage public URL from the staging bucket if available.
  const imageUrl = __ENV.TEST_MEAL_PHOTO_URL || 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Good_Food_Display_-_NCI_Visuals_Online.jpg/800px-Good_Food_Display_-_NCI_Visuals_Online.jpg';

  const res = http.post(
    `${BASE_URL}/analyze-meal-photo`,
    JSON.stringify({ image_url: imageUrl }),
    {
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Content-Type': 'application/json',
      },
      tags: { scenario: 'analyze_meal_photo' },
      timeout: '40s',  // threshold is p95 < 25s; 40s gives buffer
    }
  );

  check(res, {
    'not 500':      r => r.status !== 500,
    'status 200':   r => r.status === 200,
    'has analysis': r => !!JSON.parse(r.body)?.analysis,
  });

  sleep(2);
}
