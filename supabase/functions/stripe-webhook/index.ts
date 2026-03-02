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

const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

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

  return expectedHex === sig;
}

serve(async (req) => {
  try {
    const payload = await req.text();
    const signature = req.headers.get("stripe-signature") ?? "";

    const valid = await verifyStripeSignature(
      payload,
      signature,
      STRIPE_WEBHOOK_SECRET,
    );
    if (!valid) return err("Invalid Stripe signature", 401);

    const event = JSON.parse(payload);
    const admin = serviceClient();

    switch (event.type) {
      // Creator payout succeeded
      case "payment_intent.succeeded": {
        const creatorId = event.data?.object?.metadata?.creator_id;
        if (creatorId) {
          await admin.from("creator_payout").insert({
            creator_id: creatorId,
            stripe_payment_intent_id: event.data.object.id,
            amount_cents: event.data.object.amount,
            currency: event.data.object.currency,
            status: "succeeded",
            paid_at: new Date().toISOString(),
          });
        }
        break;
      }

      // Creator payout failed
      case "payment_intent.payment_failed": {
        const creatorId = event.data?.object?.metadata?.creator_id;
        if (creatorId) {
          await admin.from("creator_payout").insert({
            creator_id: creatorId,
            stripe_payment_intent_id: event.data.object.id,
            amount_cents: event.data.object.amount,
            currency: event.data.object.currency,
            status: "failed",
          });
        }
        break;
      }

      // Stripe Connect transfer confirmed
      case "transfer.created": {
        const transferId = event.data?.object?.id;
        const destination = event.data?.object?.destination;
        console.log(
          `[stripe-webhook] Transfer ${transferId} to ${destination} created`,
        );
        break;
      }

      // Creator Stripe Connect account updated (e.g. KYC verified)
      case "account.updated": {
        const accountId = event.data?.object?.id;
        const chargesEnabled = event.data?.object?.charges_enabled;
        if (accountId) {
          await admin
            .from("creator")
            .update({ stripe_charges_enabled: chargesEnabled })
            .eq("stripe_account_id", accountId);
        }
        break;
      }

      default:
        console.log(`[stripe-webhook] Unhandled event: ${event.type}`);
    }

    return ok({ received: true, event_type: event.type });
  } catch (e) {
    return serverError(e);
  }
});
