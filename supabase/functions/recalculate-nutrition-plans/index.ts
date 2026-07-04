// Cron-only — not callable from Flutter. Secured by x-internal-secret.
// Fires weekly at 23:00 UTC Sunday via pg_cron, two hours before
// batch-generate-meal-plans-weekly, so that week's plan generation reads
// the recalculated calorie_goal.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const logger = createLogger("recalculate-nutrition-plans");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify internal secret");
    if (!verifyInternalSecret(req)) {
      logger.warn("EARLY RETURN | reason: invalid internal secret");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();

    logger.debug("[STEP 2] Calling recalculate_nutrition_plans_from_weight RPC");
    logRLSCheck(logger, "nutrition_plan+user_goal+user_health_profile", "UPDATE", "cron");
    const { data, error } = await admin.rpc("recalculate_nutrition_plans_from_weight");
    logQueryResult(
      logger,
      "nutrition_plan+user_goal+user_health_profile",
      "UPDATE",
      typeof data === "number" ? data : 0,
      error ?? undefined,
    );

    if (error) {
      logger.error("💥 RPC failed", { message: error.message });
      return serverError(error);
    }

    const updated = typeof data === "number" ? data : 0;
    logger.info(`✅ EXIT | updated: ${updated} | duration: ${Date.now() - start}ms`);
    return ok({ updated });
  } catch (e) {
    const caught = e instanceof Error ? e : new Error(String(e));
    logger.error("💥 Unhandled error", { message: caught.message, stack: caught.stack });
    return serverError(caught);
  }
});
