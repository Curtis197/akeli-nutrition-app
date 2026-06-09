// create-jwt-pool.ts
// Creates 500 Supabase Auth users via the Admin API (service_role key required),
// signs each one in, and writes jwt-pool.json for k6 to consume.
//
// Run BEFORE 02_users.sql:
//   deno run --allow-net --allow-env --allow-write create-jwt-pool.ts
//
// Required env vars:
//   STAGING_SUPABASE_URL      — e.g. https://xxxx.supabase.co
//   STAGING_SUPABASE_SERVICE_ROLE_KEY

import "https://deno.land/x/dotenv@v3.2.2/load.ts";

const supabaseUrl = Deno.env.get('STAGING_SUPABASE_URL') ?? Deno.env.get('SUPABASE_URL');
const serviceRoleKey = Deno.env.get('STAGING_SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Missing STAGING_SUPABASE_URL or STAGING_SUPABASE_SERVICE_ROLE_KEY');
  Deno.exit(1);
}

const adminUrl = `${supabaseUrl}/auth/v1/admin/users`;
const signInUrl = `${supabaseUrl}/auth/v1/token?grant_type=password`;
const NUM_USERS = 500;
const BATCH_SIZE = 20; // parallel sign-in batch size

async function createUser(i: number): Promise<void> {
  const email = `testuser${i}@akeli.local`;
  const password = 'Akeli_Load_2026!';

  const res = await fetch(adminUrl, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${serviceRoleKey}`,
      'apikey': serviceRoleKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password, email_confirm: true }),
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    // 422 = user already exists — acceptable on re-runs
    if (res.status !== 422) {
      console.warn(`Create ${email}: ${res.status} — ${JSON.stringify(body)}`);
    }
  }
}

async function signIn(i: number): Promise<string | null> {
  const email = `testuser${i}@akeli.local`;
  const password = 'Akeli_Load_2026!';

  const res = await fetch(signInUrl, {
    method: 'POST',
    headers: {
      'apikey': serviceRoleKey!,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    console.warn(`Sign-in ${email}: ${res.status} — ${JSON.stringify(body)}`);
    return null;
  }

  const data = await res.json();
  return data.access_token ?? null;
}

async function runBatch<T>(
  items: number[],
  fn: (i: number) => Promise<T>,
): Promise<T[]> {
  const results: T[] = [];
  for (let offset = 0; offset < items.length; offset += BATCH_SIZE) {
    const batch = items.slice(offset, offset + BATCH_SIZE);
    const batchResults = await Promise.all(batch.map(fn));
    results.push(...batchResults);
    if (offset % 100 === 0) {
      console.log(`Progress: ${Math.min(offset + BATCH_SIZE, items.length)} / ${items.length}`);
    }
  }
  return results;
}

const indices = Array.from({ length: NUM_USERS }, (_, i) => i + 1);

console.log(`[1/2] Creating ${NUM_USERS} auth users (batches of ${BATCH_SIZE})...`);
await runBatch(indices, createUser);

console.log(`[2/2] Signing in to collect JWTs...`);
const tokens = await runBatch(indices, signIn);
const pool = tokens.filter((t): t is string => t !== null);

console.log(`\nSuccessfully collected ${pool.length} / ${NUM_USERS} JWTs.`);

const outPath = new URL('./jwt-pool.json', import.meta.url).pathname;
await Deno.writeTextFile(outPath, JSON.stringify(pool, null, 2));
console.log(`Saved to ${outPath}`);

if (pool.length < NUM_USERS * 0.95) {
  console.error(`ERROR: Only ${pool.length} JWTs collected — expected at least ${Math.floor(NUM_USERS * 0.95)}.`);
  console.error('Check that STAGING_SUPABASE_SERVICE_ROLE_KEY is correct and that Auth is enabled on the staging project.');
  Deno.exit(1);
}
