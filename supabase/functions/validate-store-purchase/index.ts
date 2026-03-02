// Valide un achat in-app (Google Play ou App Store) et met à jour la table subscription
// Appelé par le client Flutter après un achat réussi via in_app_purchase
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";

const APPLE_SHARED_SECRET = Deno.env.get("APPLE_SHARED_SECRET")!;
const GOOGLE_SERVICE_ACCOUNT_JSON = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON")!;
const ANDROID_PACKAGE_NAME = Deno.env.get("ANDROID_PACKAGE_NAME") ?? "app.akeli.nutrition";

// ---------------------------------------------------------------------------
// Apple App Store receipt validation (legacy API — compatible iOS 14+)
// ---------------------------------------------------------------------------

async function validateApple(
  receiptData: string,
): Promise<{ valid: boolean; expiresAt: string | null }> {
  const body = JSON.stringify({
    "receipt-data": receiptData,
    password: APPLE_SHARED_SECRET,
    "exclude-old-transactions": true,
  });

  // Try production first; fall back to sandbox if receipt is a sandbox receipt
  for (const url of [
    "https://buy.itunes.apple.com/verifyReceipt",
    "https://sandbox.itunes.apple.com/verifyReceipt",
  ]) {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
    });
    const data = await res.json();

    if (data.status === 21007) continue; // sandbox receipt, retry with sandbox URL
    if (data.status !== 0) return { valid: false, expiresAt: null };

    const latestInfo = (data.latest_receipt_info ?? []) as Array<Record<string, string>>;
    if (latestInfo.length === 0) return { valid: false, expiresAt: null };

    // Sort descending by expiry date, take the most recent
    latestInfo.sort(
      (a, b) => parseInt(b.expires_date_ms) - parseInt(a.expires_date_ms),
    );
    const latest = latestInfo[0];
    const expiresMs = parseInt(latest.expires_date_ms ?? "0");

    return {
      valid: expiresMs > Date.now(),
      expiresAt: expiresMs ? new Date(expiresMs).toISOString() : null,
    };
  }

  return { valid: false, expiresAt: null };
}

// ---------------------------------------------------------------------------
// Google Play subscription validation
// ---------------------------------------------------------------------------

async function getGoogleAccessToken(): Promise<string> {
  const sa = JSON.parse(GOOGLE_SERVICE_ACCOUNT_JSON);
  const now = Math.floor(Date.now() / 1000);

  // Build JWT header + payload
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const claimSet = btoa(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  // Import RSA private key for signing
  const pemBody = sa.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sigBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(`${header}.${claimSet}`),
  );
  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const jwt = `${header}.${claimSet}.${sig}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) throw new Error("Failed to get Google access token");
  return tokenData.access_token;
}

async function validateAndroid(
  productId: string,
  purchaseToken: string,
): Promise<{ valid: boolean; expiresAt: string | null }> {
  try {
    const accessToken = await getGoogleAccessToken();

    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${ANDROID_PACKAGE_NAME}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`;

    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!res.ok) return { valid: false, expiresAt: null };

    const data = await res.json();
    const expiresMs = parseInt(data.expiryTimeMillis ?? "0");

    // cancelReason is set when subscription is cancelled
    const isCancelled = data.cancelReason !== undefined;
    const valid = expiresMs > Date.now() && !isCancelled;

    return {
      valid,
      expiresAt: expiresMs ? new Date(expiresMs).toISOString() : null,
    };
  } catch (e) {
    console.error("[validate-store-purchase] Android validation error:", e);
    return { valid: false, expiresAt: null };
  }
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user } = await getAuthUser(req);
    if (!user) return unauthorized();

    const body = await req.json();
    const { platform, purchase_token, product_id } = body as {
      platform: "android" | "ios";
      purchase_token: string;
      product_id: string;
    };

    if (!platform || !purchase_token || !product_id) {
      return err("platform, purchase_token and product_id are required");
    }

    let valid = false;
    let expiresAt: string | null = null;

    if (platform === "android") {
      ({ valid, expiresAt } = await validateAndroid(product_id, purchase_token));
    } else if (platform === "ios") {
      ({ valid, expiresAt } = await validateApple(purchase_token));
    } else {
      return err("platform must be 'android' or 'ios'");
    }

    if (!valid) {
      return err("Purchase could not be validated. Please contact support.", 402);
    }

    // Update subscription record — this is what activate-fan-mode checks
    const admin = serviceClient();
    await admin.from("subscription").upsert({
      user_id: user.id,
      store_platform: platform,
      store_product_id: product_id,
      store_purchase_token: purchase_token,
      status: "active",
      current_period_start: new Date().toISOString(),
      current_period_end: expiresAt,
    }, { onConflict: "user_id" });

    return ok({ validated: true, expires_at: expiresAt });
  } catch (e) {
    return serverError(e);
  }
});
