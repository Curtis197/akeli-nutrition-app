// Cron — 1er de chaque mois à 00:05 UTC
// Traite toutes les transitions Mode Fan en attente
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const logger = createLogger("process-fan-mode-transitions");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    // [STEP 1] Verify internal secret
    logger.debug("[STEP 1] Verify internal secret");
    if (!verifyInternalSecret(req)) {
      logger.warn("EARLY RETURN | reason: invalid internal secret");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();
    const today = new Date().toISOString().split("T")[0];

    // [STEP 2] Activate pending fan subscriptions
    logger.debug("[STEP 2] Activate pending fan subscriptions | date: " + today);
    logRLSCheck(logger, "fan_subscription", "UPDATE", "cron");
    const { data: toActivate, error: activateError } = await admin
      .from("fan_subscription")
      .update({ status: "active" })
      .eq("status", "pending")
      .lte("effective_from", today)
      .select("user_id, creator_id");
    logQueryResult(logger, "fan_subscription", "UPDATE", toActivate?.length ?? 0, activateError ?? undefined);

    if (activateError) throw activateError;
    logger.info("Fan mode transitions | activated: " + (toActivate?.length ?? 0) + " | date: " + today);

    logger.info("✅ EXIT | status: 200 | activated: " + (toActivate?.length ?? 0) + " | duration: " + (Date.now() - start) + "ms");
    return ok({
      activated: toActivate?.length ?? 0,
    });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
