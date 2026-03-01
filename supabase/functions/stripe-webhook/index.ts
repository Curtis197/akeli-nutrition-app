// Webhook Stripe — vérifie la signature Stripe, pas de JWT Supabase
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { serviceClient } from "../_shared/supabase.ts";

const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

async function verifyStripeSignature(
  payload: string,
  signature: string,
  secret: string,
): Promise<boolean> {
  const parts = signature.split(",").reduce((acc: Record<string, string>, part) => {
    const [k, v] = part.split("=");
    acc[k] = v;
    return acc;
  }, {});

  const timestamp = parts["t"];
  const sig = parts["v1"];
  if (!timestamp || !sig) return false;

  const signedPayload = `${timestamp}.${payload}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const expected = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(signedPayload));
  const expectedHex = Array.from(new Uint8Array(expected))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return expectedHex === sig;
}

serve(async (req) => {
  try {
    const payload = await req.text();
    const signature = req.headers.get("stripe-signature") ?? "";

    const valid = await verifyStripeSignature(payload, signature, STRIPE_WEBHOOK_SECRET);
    if (!valid) return err("Invalid Stripe signature", 401);

    const event = JSON.parse(payload);
    const admin = serviceClient();

    const stripeObject = event.data?.object;
    const stripeCustomerId = stripeObject?.customer;
    const stripeSubId = stripeObject?.id ?? stripeObject?.subscription;

    // Trouver l'utilisateur via stripe_customer_id
    let userId: string | null = null;
    if (stripeCustomerId) {
      const { data: sub } = await admin
        .from("subscription")
        .select("user_id")
        .eq("stripe_customer_id", stripeCustomerId)
        .single();
      userId = sub?.user_id ?? null;
    }

    switch (event.type) {
      case "customer.subscription.created":
      case "customer.subscription.updated": {
        const status = stripeObject?.status === "active"
          ? "active"
          : stripeObject?.status === "trialing"
          ? "trialing"
          : stripeObject?.status === "past_due"
          ? "past_due"
          : "cancelled";

        if (userId) {
          await admin.from("subscription").upsert({
            user_id: userId,
            stripe_customer_id: stripeCustomerId,
            stripe_subscription_id: stripeSubId,
            status,
            current_period_start: stripeObject?.current_period_start
              ? new Date(stripeObject.current_period_start * 1000).toISOString()
              : null,
            current_period_end: stripeObject?.current_period_end
              ? new Date(stripeObject.current_period_end * 1000).toISOString()
              : null,
          }, { onConflict: "user_id" });
        }
        break;
      }

      case "customer.subscription.deleted": {
        if (userId) {
          await admin
            .from("subscription")
            .update({ status: "cancelled", cancelled_at: new Date().toISOString() })
            .eq("user_id", userId);

          // Annuler le Mode Fan si actif
          await admin
            .from("fan_subscription")
            .update({
              status: "cancelled",
              effective_until: new Date().toISOString().split("T")[0],
            })
            .eq("user_id", userId)
            .in("status", ["active", "pending"]);
        }
        break;
      }

      case "invoice.payment_failed": {
        if (userId) {
          await admin
            .from("subscription")
            .update({ status: "past_due" })
            .eq("user_id", userId);
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
