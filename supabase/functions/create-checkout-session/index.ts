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
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

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

  const logger = createLogger("create-checkout-session");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user } = await getAuthUser(req);
    if (!user) return unauthorized();

    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    // [STEP 1] Check creator flag
    logger.debug("[STEP 1] Check user_profile.is_creator");
    const admin = serviceClient();
    logRLSCheck(logger, "user_profile", "SELECT", user.id);
    const { data: profile, error: profileError } = await admin
      .from("user_profile")
      .select("is_creator")
      .eq("id", user.id)
      .single();
    logQueryResult(logger, "user_profile", "SELECT", profile ? 1 : 0, profileError ?? undefined);

    if (!profile?.is_creator) {
      logger.warn("EARLY RETURN | reason: user is not a creator | userId: " + user.id);
      return err("Only admins can initiate creator payouts", 403);
    }

    // [STEP 2] Parse body
    logger.debug("[STEP 2] Parsing request body");
    const { creator_id, amount_cents, success_url, cancel_url } =
      await req.json();
    logger.debug("[STEP 2] Body parsed", {
      creator_id,
      amount_cents,
      has_success_url: !!success_url,
      has_cancel_url: !!cancel_url,
    });

    // [STEP 3] Validate required fields
    logger.debug("[STEP 3] Validating required fields");
    if (!creator_id || !amount_cents || !success_url || !cancel_url) {
      logger.warn("EARLY RETURN | reason: missing required fields");
      return err(
        "creator_id, amount_cents, success_url and cancel_url are required",
      );
    }

    // [STEP 4] Verify the authenticated user owns the creator account being paid out
    logger.debug("[STEP 4] Verify creator ownership");
    logRLSCheck(logger, "creator", "SELECT", user.id);
    const { data: userCreator, error: userCreatorError } = await admin
      .from("creator")
      .select("id")
      .eq("user_id", user.id)
      .single();
    logQueryResult(logger, "creator", "SELECT", userCreator ? 1 : 0, userCreatorError ?? undefined);

    if (!userCreator) {
      logger.warn("EARLY RETURN | reason: creator profile not found | userId: " + user.id);
      return err("Creator profile not found", 404);
    }
    if (userCreator.id !== creator_id) {
      logger.warn("EARLY RETURN | reason: creator_id ownership mismatch | userId: " + user.id + " | creator_id: " + creator_id);
      return err("You can only request payouts for your own account", 403);
    }

    // [STEP 5] Verify amount is within available balance
    logger.debug("[STEP 5] Verify creator_balance");
    logRLSCheck(logger, "creator_balance", "SELECT", user.id);
    const { data: balance, error: balanceError } = await admin
      .from("creator_balance")
      .select("balance")
      .eq("creator_id", creator_id)
      .maybeSingle();
    logQueryResult(logger, "creator_balance", "SELECT", balance ? 1 : 0, balanceError ?? undefined);

    const availableCents = Math.floor((balance?.balance ?? 0) * 100);
    logger.info("Balance check | available: " + availableCents + " | requested: " + amount_cents);

    if (amount_cents > availableCents) {
      logger.warn("EARLY RETURN | reason: amount exceeds balance | amount_cents: " + amount_cents + " | available: " + availableCents);
      return err(`Amount exceeds available balance (max: ${availableCents} cents)`, 400);
    }

    // [STEP 6] Retrieve the creator's Stripe Connect account ID
    logger.debug("[STEP 6] Get creator Stripe info");
    logRLSCheck(logger, "creator", "SELECT", user.id);
    const { data: creator, error: creatorError } = await admin
      .from("creator")
      .select("stripe_account_id, display_name")
      .eq("id", creator_id)
      .single();
    logQueryResult(logger, "creator", "SELECT", creator ? 1 : 0, creatorError ?? undefined);

    if (!creator) {
      logger.warn("EARLY RETURN | reason: creator not found | creator_id: " + creator_id);
      return err("Creator not found", 404);
    }
    if (!creator.stripe_account_id) {
      logger.warn("EARLY RETURN | reason: creator has no stripe_account_id | creator_id: " + creator_id);
      return err(
        "Creator has no Stripe account configured. Ask them to onboard first.",
        400,
      );
    }

    // [STEP 7] Create a Stripe Checkout session — payment mode (one-time payout)
    logger.debug("[STEP 7] Creating Stripe checkout session | creator_id: " + creator_id + " | amount_cents: " + amount_cents);
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
      logger.error("[STEP 7] Stripe session creation failed | status: " + sessionRes.status, { errBody });
      throw new Error(`Stripe session error: ${errBody}`);
    }

    const session = await sessionRes.json();
    logger.info("[STEP 7] Stripe session created | session_id: " + session.id);

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ checkout_url: session.url, session_id: session.id });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
