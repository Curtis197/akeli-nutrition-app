import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

function firstOfNextMonth(): string {
  const d = new Date();
  d.setMonth(d.getMonth() + 1, 1);
  return d.toISOString().split("T")[0];
}

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("activate-fan-mode");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn("EARLY RETURN | reason: auth failed");
      return unauthorized();
    }

    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 1] Parse body");
    const { creator_id } = await req.json();
    logger.debug("[STEP 1] Parsed body | creator_id: " + creator_id);
    if (!creator_id) {
      logger.warn("EARLY RETURN | reason: missing creator_id");
      return err("creator_id is required");
    }

    // 2. Vérifier que l'utilisateur a un abonnement actif
    logger.debug("[STEP 2] Check subscription | user_id: " + user.id);
    logRLSCheck(logger, "subscription", "SELECT", user.id);
    const { data: sub, error: subError } = await client
      .from("subscription")
      .select("status")
      .eq("user_id", user.id)
      .single();
    logQueryResult(logger, "subscription", "SELECT", sub ? 1 : 0, subError ?? undefined);

    if (!sub || sub.status !== "active") {
      logger.warn("EARLY RETURN | reason: no active subscription | sub_status: " + (sub?.status ?? "none"));
      return err("Active subscription required to activate Fan mode", 403);
    }

    // 3. Vérifier que le créateur est éligible (≥ 30 recettes publiées)
    logger.debug("[STEP 3] Check creator eligibility | creator_id: " + creator_id);
    logRLSCheck(logger, "creator", "SELECT", user.id);
    const { data: creator, error: creatorError } = await client
      .from("creator")
      .select("is_fan_eligible, display_name")
      .eq("id", creator_id)
      .single();
    logQueryResult(logger, "creator", "SELECT", creator ? 1 : 0, creatorError ?? undefined);

    if (!creator) {
      logger.warn("EARLY RETURN | reason: creator not found | creator_id: " + creator_id);
      return err("Creator not found", 404);
    }
    if (!creator.is_fan_eligible) {
      logger.warn("EARLY RETURN | reason: creator not fan-eligible | creator_id: " + creator_id);
      return err("Creator needs at least 30 published recipes to be Fan-eligible", 403);
    }

    // 4. Vérifier qu'il n'y a pas déjà un Fan actif ou pending
    logger.debug("[STEP 4] Check existing fan subscription");
    logRLSCheck(logger, "fan_subscription", "SELECT", user.id);
    const { data: existingSub, error: existingSubError } = await client
      .from("fan_subscription")
      .select("id, creator_id, status")
      .eq("user_id", user.id)
      .in("status", ["active", "pending"])
      .maybeSingle();
    logQueryResult(logger, "fan_subscription", "SELECT", existingSub ? 1 : 0, existingSubError ?? undefined);
    logger.info("Existing fan sub check | has_existing: " + !!existingSub);

    const effectiveFrom = firstOfNextMonth();
    const monthKey = effectiveFrom.slice(0, 7); // ex: '2026-06'

    if (existingSub) {
      if (existingSub.creator_id === creator_id) {
        logger.warn("EARLY RETURN | reason: already a fan of creator_id: " + creator_id);
        return err("Already a fan of this creator");
      }

      // Changer de créateur Fan — annuler l'ancien
      logger.info("Switching fan creator | old: " + existingSub.creator_id + " | new: " + creator_id);

      logRLSCheck(logger, "fan_subscription", "UPDATE", user.id);
      const { error: updateError } = await client
        .from("fan_subscription")
        .update({ status: "cancelled", effective_until: effectiveFrom })
        .eq("id", existingSub.id);
      logQueryResult(logger, "fan_subscription", "UPDATE", 0, updateError ?? undefined);

      // Historique: action "changed" avec le créateur précédent
      logRLSCheck(logger, "fan_subscription_history", "INSERT", user.id);
      const { error: historyChangeError } = await client.from("fan_subscription_history").insert({
        user_id: user.id,
        creator_id: existingSub.creator_id,
        action: "changed",
        previous_creator_id: existingSub.creator_id,
        month_key: monthKey,
      });
      logQueryResult(logger, "fan_subscription_history", "INSERT", 0, historyChangeError ?? undefined);
    }

    // 5. Créer le nouveau fan_subscription (pending → actif le 1er du mois suivant)
    logger.debug("[STEP 5] Insert new fan_subscription | creator_id: " + creator_id + " | effective_from: " + effectiveFrom);
    logRLSCheck(logger, "fan_subscription", "INSERT", user.id);
    const { data: newSub, error: newSubError } = await client
      .from("fan_subscription")
      .insert({
        user_id: user.id,
        creator_id,
        status: "pending",
        effective_from: effectiveFrom,
      })
      .select()
      .single();
    logQueryResult(logger, "fan_subscription", "INSERT", newSub ? 1 : 0, newSubError ?? undefined);

    if (newSubError) throw newSubError;

    // 6. Historique: action "activated"
    logger.debug("[STEP 6] Insert fan_subscription_history | action: activated");
    logRLSCheck(logger, "fan_subscription_history", "INSERT", user.id);
    const { error: historyActivateError } = await client.from("fan_subscription_history").insert({
      user_id: user.id,
      creator_id,
      action: "activated",
      month_key: monthKey,
    });
    logQueryResult(logger, "fan_subscription_history", "INSERT", 0, historyActivateError ?? undefined);

    logger.info("✅ EXIT | status: 200 | fan_sub_id: " + newSub.id + " | effective_from: " + effectiveFrom + " | duration: " + (Date.now() - start) + "ms");
    return ok({
      fan_subscription_id: newSub.id,
      creator_name: creator.display_name,
      effective_from: effectiveFrom,
      status: "pending",
    });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
