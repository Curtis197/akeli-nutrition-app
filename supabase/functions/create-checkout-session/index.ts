// Crée une session Stripe Checkout pour le PAIEMENT DES CRÉATEURS (website uniquement)
// ⚠️  Les abonnements utilisateurs sont gérés via les stores (Google Play / App Store)
//     Ce endpoint est appelé depuis le site web Akeli pour initier le paiement
//     d'un créateur éligible (via Stripe Connect ou transfert Stripe).
//
// Flow :
//   1. Admin/website déclenche un paiement créateur (mensuel)
//   2. Ce endpoint crée une Stripe Checkout session de type "payment" vers le créateur
//   3. Le créateur reçoit les fonds via son compte Stripe Connect
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const STRIPE_API = "https://api.stripe.com/v1";

async function stripePost(
  path: string,
  params: Record<string, string>,
): Promise<Response> {
  return fetch(`${STRIPE_API}${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams(params).toString(),
  });
}

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user } = await getAuthUser(req);
    if (!user) return unauthorized();

    // Only Akeli admins can trigger creator payouts
    const admin = serviceClient();
    const { data: profile } = await admin
      .from("user_profile")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profile?.role !== "admin") {
      return err("Only admins can initiate creator payouts", 403);
    }

    const { creator_id, amount_cents, success_url, cancel_url } =
      await req.json();

    if (!creator_id || !amount_cents || !success_url || !cancel_url) {
      return err(
        "creator_id, amount_cents, success_url and cancel_url are required",
      );
    }

    // Retrieve the creator's Stripe Connect account ID
    const { data: creator } = await admin
      .from("creator")
      .select("stripe_account_id, display_name")
      .eq("id", creator_id)
      .single();

    if (!creator) return err("Creator not found", 404);
    if (!creator.stripe_account_id) {
      return err(
        "Creator has no Stripe account configured. Ask them to onboard first.",
        400,
      );
    }

    // Create a Stripe Checkout session — payment mode (one-time payout)
    const sessionRes = await stripePost("/checkout/sessions", {
      mode: "payment",
      "line_items[0][price_data][currency]": "eur",
      "line_items[0][price_data][product_data][name]":
        `Paiement créateur — ${creator.display_name}`,
      "line_items[0][price_data][unit_amount]": String(amount_cents),
      "line_items[0][quantity]": "1",
      // Transfer funds to the creator's Stripe Connect account
      "payment_intent_data[transfer_data][destination]":
        creator.stripe_account_id,
      "metadata[creator_id]": creator_id,
      success_url,
      cancel_url,
    });

    if (!sessionRes.ok) {
      const errBody = await sessionRes.text();
      throw new Error(`Stripe session error: ${errBody}`);
    }

    const session = await sessionRes.json();
    return ok({ checkout_url: session.url, session_id: session.id });
  } catch (e) {
    return serverError(e);
  }
});
