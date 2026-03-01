// Crée une session Stripe Checkout pour l'abonnement 3€/mois
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY")!;
const STRIPE_PRICE_ID = Deno.env.get("STRIPE_PRICE_ID")!;  // Price ID du plan 3€/mois
const STRIPE_API = "https://api.stripe.com/v1";

async function stripePost(path: string, params: Record<string, string>): Promise<Response> {
  const body = new URLSearchParams(params).toString();
  return fetch(`${STRIPE_API}${path}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });
}

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const { success_url, cancel_url } = await req.json();
    if (!success_url || !cancel_url) return err("success_url and cancel_url are required");

    // Récupérer ou créer le Stripe customer
    let { data: existingSub } = await client
      .from("subscription")
      .select("stripe_customer_id, status")
      .eq("user_id", user.id)
      .single();

    let stripeCustomerId = existingSub?.stripe_customer_id;

    // Si l'abonnement est déjà actif
    if (existingSub?.status === "active") {
      return err("Subscription already active", 400);
    }

    // Créer le customer Stripe si nécessaire
    if (!stripeCustomerId) {
      const { data: profile } = await client
        .from("user_profile")
        .select("first_name, last_name")
        .eq("id", user.id)
        .single();

      const customerRes = await stripePost("/customers", {
        email: user.email ?? "",
        name: `${profile?.first_name ?? ""} ${profile?.last_name ?? ""}`.trim(),
        metadata: `user_id=${user.id}`,
      });

      if (!customerRes.ok) throw new Error("Failed to create Stripe customer");
      const customer = await customerRes.json();
      stripeCustomerId = customer.id;

      // Sauvegarder le customer_id en base
      await client.from("subscription").upsert({
        user_id: user.id,
        stripe_customer_id: stripeCustomerId,
        status: "trialing",
      }, { onConflict: "user_id" });
    }

    // Créer la session Checkout
    const sessionRes = await stripePost("/checkout/sessions", {
      customer: stripeCustomerId,
      mode: "subscription",
      "line_items[0][price]": STRIPE_PRICE_ID,
      "line_items[0][quantity]": "1",
      success_url,
      cancel_url,
      "metadata[user_id]": user.id,
      "subscription_data[trial_period_days]": "0",
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
