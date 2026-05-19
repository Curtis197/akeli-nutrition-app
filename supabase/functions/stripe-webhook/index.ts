// Webhook Stripe — événements liés aux PAIEMENTS CRÉATEURS (website uniquement)
// ⚠️  Les abonnements utilisateurs sont gérés par Google Play / App Store
//     Ce webhook traite uniquement les événements Stripe liés aux paiements
//     et reversements vers les créateurs (Stripe Connect).
//
// Événements traités :
//   - payment_intent.succeeded    → marquer un paiement créateur comme effectué
//   - payment_intent.failed       → enregistrer l'échec
//   - transfer.created            → confirmer le transfert vers le créateur
//   - account.updated             → mise à jour du compte Stripe Connect du créateur
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

function timingSafeEqual(a: string, b: string): boolean {
  const aBytes = new TextEncoder().encode(a);
  const bBytes = new TextEncoder().encode(b);
  if (aBytes.length !== bBytes.length) return false;
  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) diff |= aBytes[i] ^ bBytes[i];
  return diff === 0;
}

async function verifyStripeSignature(
  payload: string,
  signature: string,
  secret: string,
): Promise<boolean> {
  const parts = signature.split(",").reduce(
    (acc: Record<string, string>, part) => {
      const [k, v] = part.split("=");
      acc[k] = v;
      return acc;
    },
    {},
  );

  const timestamp = parts["t"];
  const sig = parts["v1"];
  if (!timestamp || !sig) return false;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const expected = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${payload}`),
  );
  const expectedHex = Array.from(new Uint8Array(expected))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return timingSafeEqual(expectedHex, sig);
}

serve(async (req) => {
  const logger = createLogger("stripe-webhook");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Reading payload and signature");
    const payload = await req.text();
    const signature = req.headers.get("stripe-signature") ?? "";

    logger.debug("[STEP 2] Verifying Stripe signature");
    const valid = await verifyStripeSignature(
      payload,
      signature,
      STRIPE_WEBHOOK_SECRET,
    );
    if (!valid) {
      logger.warn("EARLY RETURN | reason: invalid Stripe signature");
      return err("Invalid Stripe signature", 401);
    }
    logger.debug("[STEP 2] Stripe signature verified");

    logger.debug("[STEP 3] Parsing event");
    const event = JSON.parse(payload);
    logger.info("[STEP 3] Parsed event | type: " + event.type);

    const admin = serviceClient();

    switch (event.type) {
      // Creator payout succeeded
      case "payment_intent.succeeded": {
        const creatorId = event.data?.object?.metadata?.creator_id;
        if (!creatorId) {
          logger.warn('payment_intent.succeeded | no creator_id in metadata | payment_intent: ' + event.data?.object?.id);
          break;
        }
        logger.info("payment_intent.succeeded | creator_id: " + creatorId + " | stripe_payment_intent_id: " + event.data.object.id + " | amount: " + event.data.object.amount + " | status: succeeded");
        logRLSCheck(logger, "creator_payout", "INSERT", creatorId);
        const { error: payoutError } = await admin.from("creator_payout").insert({
          creator_id: creatorId,
          stripe_payment_intent_id: event.data.object.id as string,
          amount_cents: event.data.object.amount as number,
          currency: (event.data.object.currency as string) ?? "eur",
          status: "succeeded",
          paid_at: new Date().toISOString(),
        });
        logQueryResult(logger, "creator_payout", "INSERT", payoutError ? 0 : 1, payoutError ?? undefined);
        break;
      }

      // Creator payout failed
      case "payment_intent.payment_failed": {
        const creatorId = event.data?.object?.metadata?.creator_id;
        if (!creatorId) {
          logger.warn('payment_intent.payment_failed | no creator_id in metadata | payment_intent: ' + event.data?.object?.id);
          break;
        }
        logger.info("payment_intent.payment_failed | creator_id: " + creatorId + " | stripe_payment_intent_id: " + event.data.object.id + " | amount: " + event.data.object.amount + " | status: failed");
        logRLSCheck(logger, "creator_payout", "INSERT", creatorId);
        const { error: payoutError } = await admin.from("creator_payout").insert({
          creator_id: creatorId,
          stripe_payment_intent_id: event.data.object.id as string,
          amount_cents: event.data.object.amount as number,
          currency: (event.data.object.currency as string) ?? "eur",
          status: "failed",
        });
        logQueryResult(logger, "creator_payout", "INSERT", payoutError ? 0 : 1, payoutError ?? undefined);
        break;
      }

      // Stripe Connect transfer confirmed
      case "transfer.created": {
        const transferId = event.data?.object?.id;
        const destination = event.data?.object?.destination;
        logger.info("transfer.created | transferId: " + transferId + " | destination: " + destination);
        break;
      }

      // Creator Stripe Connect account updated (e.g. KYC verified) — logged only
      case "account.updated": {
        const accountId = event.data?.object?.id;
        logger.info("account.updated | accountId: " + accountId);
        break;
      }

      default:
        logger.info("Unhandled event type: " + event.type);
    }

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ received: true, event_type: event.type });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
