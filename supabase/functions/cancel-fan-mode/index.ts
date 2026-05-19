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

  const logger = createLogger("cancel-fan-mode");
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

    // [STEP 1] Trouver le Fan actif ou pending
    logger.debug("[STEP 1] Check active/pending fan subscription");
    logRLSCheck(logger, "fan_subscription", "SELECT", user.id);
    const { data: fanSub, error: fanSubError } = await client
      .from("fan_subscription")
      .select("id, creator_id, status")
      .eq("user_id", user.id)
      .in("status", ["active", "pending"])
      .maybeSingle();
    logQueryResult(logger, "fan_subscription", "SELECT", fanSub ? 1 : 0, fanSubError ?? undefined);
    logger.info("Fan sub check | found: " + !!fanSub);

    if (!fanSub) {
      logger.warn("EARLY RETURN | reason: no active fan subscription found");
      return err("No active fan subscription found", 404);
    }

    const effectiveUntil = firstOfNextMonth();
    const monthKey = effectiveUntil.slice(0, 7);

    // [STEP 2] Annuler (effectif au 1er du mois suivant)
    logger.debug("[STEP 2] Cancel fan subscription | id: " + fanSub.id + " | effective_until: " + effectiveUntil);
    logger.info("Cancelling fan sub | id: " + fanSub.id + " | effective_until: " + effectiveUntil);
    logRLSCheck(logger, "fan_subscription", "UPDATE", user.id);
    const { error: updateError } = await client
      .from("fan_subscription")
      .update({ status: "cancelled", effective_until: effectiveUntil })
      .eq("id", fanSub.id);
    logQueryResult(logger, "fan_subscription", "UPDATE", 0, updateError ?? undefined);

    // [STEP 3] Historique: action "cancelled"
    logger.debug("[STEP 3] Insert cancellation history");
    logRLSCheck(logger, "fan_subscription_history", "INSERT", user.id);
    const { error: historyError } = await client.from("fan_subscription_history").insert({
      user_id: user.id,
      creator_id: fanSub.creator_id,
      action: "cancelled",
      month_key: monthKey,
    });
    logQueryResult(logger, "fan_subscription_history", "INSERT", 0, historyError ?? undefined);

    logger.info("✅ EXIT | status: 200 | effective_until: " + effectiveUntil + " | duration: " + (Date.now() - start) + "ms");
    return ok({ cancelled: true, effective_until: effectiveUntil });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
