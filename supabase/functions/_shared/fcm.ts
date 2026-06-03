// FCM v1 — OAuth2-signed push via service account (no external deps, uses Web Crypto)
const PROJECT_ID = "afro-health-oyks8y";
const FCM_ENDPOINT = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`;
const TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

function base64urlBuffer(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let str = "";
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

function base64url(input: string): string {
  return base64urlBuffer(new TextEncoder().encode(input).buffer);
}

async function buildJwt(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    sub: sa.client_email,
    aud: TOKEN_ENDPOINT,
    iat: now,
    exp: now + 3600,
    scope: FCM_SCOPE,
  }));

  const pem = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----/g, "")
    .replace(/[\r\n]+/g, "");
  const binaryDer = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signingInput = `${header}.${claims}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64urlBuffer(signature)}`;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const jwt = await buildJwt(sa);
  const res = await fetch(TOKEN_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OAuth2 token exchange failed (${res.status}): ${text}`);
  }
  const json = await res.json() as { access_token?: string };
  if (!json.access_token) {
    throw new Error(`OAuth2 response missing access_token: ${JSON.stringify(json)}`);
  }
  return json.access_token;
}

export interface FcmSendResult {
  ok: boolean;
  /** HTTP status from FCM — 404 means the token is stale */
  status: number;
}

/**
 * Send a push notification via FCM v1.
 * Returns { ok, status } so callers can act on 404 (stale token).
 */
export async function sendFcmV1(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<FcmSendResult> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT env var is not set");

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(raw);
  } catch (e) {
    throw new Error(`FIREBASE_SERVICE_ACCOUNT is not valid JSON: ${(e as Error).message}`);
  }
  const accessToken = await getAccessToken(sa);

  const payload = {
    message: {
      token: fcmToken,
      notification: { title, body },
      data,
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    },
  };

  const res = await fetch(FCM_ENDPOINT, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  return { ok: res.ok, status: res.status };
}
