// Valide un achat in-app (Google Play ou App Store) et met à jour la table subscription
// Appelé par le client Flutter après un achat réussi via in_app_purchase
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const APPLE_SHARED_SECRET = Deno.env.get("APPLE_SHARED_SECRET")!;
const GOOGLE_SERVICE_ACCOUNT_JSON = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON")!;
const ANDROID_PACKAGE_NAME = Deno.env.get("ANDROID_PACKAGE_NAME") ?? "app.akeli.nutrition";

// ---------------------------------------------------------------------------
// Apple App Store receipt validation (legacy API — compatible iOS 14+)
// ---------------------------------------------------------------------------

async function validateApple(
  receiptData: string,
  logger: ReturnType<typeof createLogger>,
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
    if (data.status !== 0) {
      logger.warn("[validateApple] Non-zero status | status: " + data.status);
      return { valid: false, expiresAt: null };
    }

    const latestInfo = (data.latest_receipt_info ?? []) as Array<Record<string, string>>;
    if (latestInfo.length === 0) {
      logger.warn("[validateApple] No latest_receipt_info entries");
      return { valid: false, expiresAt: null };
    }

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

async function getGoogleAccessToken(logger: ReturnType<typeof createLogger>): Promise<string> {
  logger.debug("[getGoogleAccessToken] Requesting Google OAuth token");
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
  logger.debug("[getGoogleAccessToken] Token acquired");
  return tokenData.access_token;
}

async function validateAndroid(
  productId: string,
  purchaseToken: string,
  logger: ReturnType<typeof createLogger>,
): Promise<{ valid: boolean; expiresAt: string | null }> {
  try {
    const accessToken = await getGoogleAccessToken(logger);

    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${ANDROID_PACKAGE_NAME}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`;

    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!res.ok) {
      logger.warn("[validateAndroid] Google Play API non-ok response | status: " + res.status);
      return { valid: false, expiresAt: null };
    }

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
    logger.error("[validateAndroid] Android validation error", { message: e.message, stack: e.stack });
    return { valid: false, expiresAt: null };
  }
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("validate-store-purchase");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user } = await getAuthUser(req);
    if (!user) return unauthorized();

    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 1] Parsing request body");
    const body = await req.json();
    const { platform, purchase_token, product_id } = body as {
      platform: "android" | "ios";
      purchase_token: string;
      product_id: string;
    };
    logger.debug("[STEP 1] Body parsed", {
      platform,
      product_id,
      has_purchase_token: !!purchase_token,
    });

    logger.debug("[STEP 2] Validating params");
    if (!platform || !purchase_token || !product_id) {
      logger.warn("EARLY RETURN | reason: missing platform, purchase_token, or product_id");
      return err("platform, purchase_token and product_id are required");
    }

    let valid = false;
    let expiresAt: string | null = null;

    logger.debug("[STEP 3] Validating purchase | platform: " + platform + " | product_id: " + product_id);
    if (platform === "android") {
      ({ valid, expiresAt } = await validateAndroid(product_id, purchase_token, logger));
    } else if (platform === "ios") {
      ({ valid, expiresAt } = await validateApple(purchase_token, logger));
    } else {
      logger.warn("EARLY RETURN | reason: invalid platform value: " + platform);
      return err("platform must be 'android' or 'ios'");
    }

    logger.info("Purchase validation result | platform: " + platform + " | valid: " + valid);

    if (!valid) {
      logger.warn("EARLY RETURN | reason: purchase validation failed | platform: " + platform);
      return err("Purchase could not be validated. Please contact support.", 402);
    }

    // Update subscription record — this is what activate-fan-mode checks
    logger.debug("[STEP 4] Upsert subscription");
    logRLSCheck(logger, "subscription", "UPSERT", user.id);
    const { error: subError } = await (serviceClient().from("subscription").upsert({
      user_id: user.id,
      status: "active",
      current_period_start: new Date().toISOString(),
      current_period_end: expiresAt,
    }, { onConflict: "user_id" }));
    logQueryResult(logger, "subscription", "UPSERT", subError ? 0 : 1, subError ?? undefined);

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ validated: true, expires_at: expiresAt });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
