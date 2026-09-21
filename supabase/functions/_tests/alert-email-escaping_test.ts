// Verifies that the Resend-backed email functions HTML-escape every user-supplied value.
//
// Each function file is loaded with Deno.serve stubbed (to capture its handler) and fetch stubbed
// (to capture what would be sent to Resend), then called with markup-laden input.
//
// Run from the repo root:
//   deno test --allow-env --allow-net --allow-read supabase/functions/_tests/alert-email-escaping_test.ts
//
// The leading underscore keeps this folder out of `supabase functions deploy`.
import { assert, assertEquals, assertStringIncludes } from 'jsr:@std/assert@1';

const SECRET = 'test-internal-secret';
Deno.env.set('INTERNAL_SECRET', SECRET);
Deno.env.set('RESEND_API_KEY', 're_test_key');

type Handler = (req: Request) => Promise<Response>;

async function loadHandler(fn: string): Promise<Handler> {
  let handler: Handler | undefined;
  const realServe = Deno.serve;
  Object.defineProperty(Deno, 'serve', {
    value: (h: Handler) => {
      handler = h;
      return {};
    },
    configurable: true,
    writable: true,
  });
  try {
    await import(new URL(`../${fn}/index.ts`, import.meta.url).href + `?t=${crypto.randomUUID()}`);
  } finally {
    Object.defineProperty(Deno, 'serve', { value: realServe, configurable: true, writable: true });
  }
  assert(handler, `${fn} did not register a Deno.serve handler`);
  return handler;
}

async function sendAndCapture(fn: string, payload: Record<string, unknown>): Promise<{ html: string; subject: string }> {
  const handler = await loadHandler(fn);
  let sent: { html?: string; subject?: string } | undefined;
  const realFetch = globalThis.fetch;
  globalThis.fetch = ((_input: unknown, init?: RequestInit) => {
    sent = JSON.parse(String(init?.body));
    return Promise.resolve(
      new Response(JSON.stringify({ id: 'test-message-id' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    );
  }) as typeof fetch;
  try {
    const res = await handler(
      new Request('http://localhost/', {
        method: 'POST',
        headers: { 'x-internal-secret': SECRET, 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      }),
    );
    assertEquals(res.status, 200, `${fn} should succeed`);
  } finally {
    globalThis.fetch = realFetch;
  }
  assert(sent?.html, `${fn} did not send any html`);
  return { html: sent.html, subject: sent.subject ?? '' };
}

const SCRIPT = '<script>alert(1)</script>';
const IMG = '<img src=x onerror=alert(1)>';
const BOLD = '<b>bold</b>';
const ESCAPED_SCRIPT = '&lt;script&gt;alert(1)&lt;/script&gt;';

function assertNoInjectedMarkup(html: string) {
  assert(!html.includes('<script'), 'raw <script> reached the html');
  assert(!html.includes('<img'), 'raw <img> reached the html');
  assert(!html.includes('<b>bold'), 'raw <b> reached the html');
  assert(!html.includes('onerror=alert(1)>'), 'raw event-handler markup reached the html');
}

Deno.test('send-admin-new-submission-email escapes every submitted field', async () => {
  const { html } = await sendAndCapture('send-admin-new-submission-email', {
    name: SCRIPT,
    nameFr: `"Tomate" & ${BOLD}`,
    nameEn: IMG,
    categoryHint: BOLD,
    notes: IMG,
    submitterName: BOLD,
  });
  assertNoInjectedMarkup(html);
  assertStringIncludes(html, ESCAPED_SCRIPT);
  assertStringIncludes(html, '&quot;Tomate&quot; &amp;');
  assertStringIncludes(html, '<h2>New ingredient submission</h2>');
});

Deno.test('send-admin-new-recipe-email escapes title, mode and creator', async () => {
  const { html } = await sendAndCapture('send-admin-new-recipe-email', {
    recipeId: '3f0c5c6e-1111-4222-8333-444455556666',
    title: SCRIPT,
    mode: IMG,
    isPublished: true,
    creatorName: BOLD,
  });
  assertNoInjectedMarkup(html);
  assertStringIncludes(html, ESCAPED_SCRIPT);
  assertStringIncludes(html, 'https://akeli-admin-dashboard.vercel.app/recipes/3f0c5c6e-1111-4222-8333-444455556666');
});

Deno.test('send-admin-new-user-email escapes name, email and locale', async () => {
  const { html } = await sendAndCapture('send-admin-new-user-email', {
    userId: '3f0c5c6e-1111-4222-8333-444455556666',
    email: `${SCRIPT}@example.com`,
    firstName: BOLD,
    lastName: IMG,
    locale: BOLD,
  });
  assertNoInjectedMarkup(html);
  assertStringIncludes(html, '&lt;script&gt;');
  assertStringIncludes(html, 'https://akeli-admin-dashboard.vercel.app/users/3f0c5c6e-1111-4222-8333-444455556666');
});

Deno.test('send-admin-new-support-message-email escapes text and neutralises the screenshot link', async () => {
  const text = await sendAndCapture('send-admin-new-support-message-email', {
    email: `${SCRIPT}@example.com`,
    subject: IMG,
    content: `${BOLD} ${SCRIPT}`,
  });
  assertNoInjectedMarkup(text.html);
  assertStringIncludes(text.html, ESCAPED_SCRIPT);

  const jsLink = await sendAndCapture('send-admin-new-support-message-email', {
    email: 'a@example.com',
    content: 'hi',
    screenshotUrl: 'javascript:alert(1)',
  });
  assert(!jsLink.html.includes('javascript:'), 'a javascript: URL must never become a link');

  const breakout = await sendAndCapture('send-admin-new-support-message-email', {
    email: 'a@example.com',
    content: 'hi',
    screenshotUrl: `https://cdn.example.com/a.png"><script>alert(1)</script>`,
  });
  assert(!breakout.html.includes('<script'), 'a quote in the URL must not break out of the href');

  const legit = await sendAndCapture('send-admin-new-support-message-email', {
    email: 'a@example.com',
    content: 'hi',
    screenshotUrl: 'https://cdn.example.com/shots/a.png',
  });
  assertStringIncludes(legit.html, '<a href="https://cdn.example.com/shots/a.png">View screenshot</a>');
});

Deno.test('send-ingredient-approved-email escapes name and ingredient in both languages', async () => {
  for (const locale of ['fr', 'en']) {
    const { html } = await sendAndCapture('send-ingredient-approved-email', {
      email: 'creator@example.com',
      locale,
      firstName: BOLD,
      ingredientName: `${SCRIPT} Sel & poivre`,
    });
    assertNoInjectedMarkup(html);
    assertStringIncludes(html, `${ESCAPED_SCRIPT} Sel &amp; poivre`);
    assertStringIncludes(html, '<strong>');
  }
});

Deno.test('send-ingredient-rejected-email escapes name, ingredient and reason in both languages', async () => {
  for (const locale of ['fr', 'en']) {
    const { html } = await sendAndCapture('send-ingredient-rejected-email', {
      email: 'creator@example.com',
      locale,
      firstName: BOLD,
      ingredientName: SCRIPT,
      reason: `${IMG} déjà présent & "doublon"`,
    });
    assertNoInjectedMarkup(html);
    assertStringIncludes(html, ESCAPED_SCRIPT);
    assertStringIncludes(html, 'déjà présent &amp; &quot;doublon&quot;');
  }
});
