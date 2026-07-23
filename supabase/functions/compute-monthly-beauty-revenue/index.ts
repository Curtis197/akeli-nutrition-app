// Cron — 1er de chaque mois à 02:00 UTC (une heure après compute-monthly-revenue)
// Calcule les paiements créateurs beauté (pool plan-slot-completion uniquement,
// le fan-mode est déjà comptabilisé par compute-monthly-revenue) du mois écoulé.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const logger = createLogger("compute-monthly-beauty-revenue");
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

    // Mois écoulé (ex: si on est le 1er mars 2026 → calcule février 2026)
    const prevDate = new Date();
    prevDate.setMonth(prevDate.getMonth() - 1);
    const monthKey = prevDate.toISOString().slice(0, 7); // ex: '2026-02'
    const targetMonth = monthKey + "-01";

    logger.debug("[STEP 2] Computing beauty creator pool payouts for month: " + targetMonth);

    logRLSCheck(logger, "creator_monthly_payouts", "INSERT", "cron");
    const { error: payoutError } = await admin.rpc("calculate_creator_payouts", {
      target_month: targetMonth,
    });
    logQueryResult(logger, "creator_monthly_payouts", "INSERT", payoutError ? 0 : 1, payoutError ?? undefined);

    if (payoutError) throw payoutError;

    logger.info("✅ EXIT | status: 200 | month: " + targetMonth + " | duration: " + (Date.now() - start) + "ms");
    return ok({ month_key: monthKey, status: "beauty_payouts_computed" });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
