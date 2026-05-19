// Cron — 1er de chaque mois à 01:00 UTC (après process-fan-mode-transitions)
// Calcule les revenus de tous les créateurs pour le mois écoulé
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const logger = createLogger("compute-monthly-revenue");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();

  try {
    logger.info("⚡ ENTRY | method: " + req.method);

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

    logger.info("[STEP 1] Computing revenue for month: " + monthKey);

    // 1. Récupérer tous les créateurs actifs (qui ont des recettes publiées)
    logger.debug("[STEP 2] Query active creators");
    logRLSCheck(logger, "creator", "SELECT", "cron");
    const { data: creators, error: creatorsError } = await admin
      .from("creator")
      .select("id")
      .gt("recipe_count", 0);
    logQueryResult(logger, "creator", "SELECT", creators?.length ?? 0, creatorsError ?? undefined);

    if (creatorsError) throw creatorsError;
    if (!creators?.length) {
      logger.info("No active creators found, exiting");
      return ok({ month_key: monthKey, creators_processed: 0 });
    }

    // 2. Éviter de recalculer si déjà fait ce mois-ci
    // Uses UNIQUE(creator_id, month_key) constraint on creator_revenue_log
    logger.debug("[STEP 3] Query already-logged creators");
    logRLSCheck(logger, "creator_revenue_log", "SELECT", "cron");
    const { data: alreadyLogged, error: alreadyLoggedError } = await admin
      .from("creator_revenue_log")
      .select("creator_id")
      .eq("month_key", monthKey);
    logQueryResult(logger, "creator_revenue_log", "SELECT", alreadyLogged?.length ?? 0, alreadyLoggedError ?? undefined);

    const alreadyDone = new Set((alreadyLogged ?? []).map((r) => r.creator_id));

    let processedCount = 0;

    logger.debug("[STEP 4] Processing " + creators.length + " creators | already_done: " + alreadyDone.size);

    for (const { id: creator_id } of creators) {
      if (alreadyDone.has(creator_id)) continue;

      // Fan revenue: nombre de fans actifs ce mois × 1€
      const { count: fanCount } = await admin
        .from("fan_subscription")
        .select("id", { count: "exact" })
        .eq("creator_id", creator_id)
        .eq("status", "active");

      const fans = fanCount ?? 0;
      const fanRevenue = fans * 1.0;

      // Insérer dans creator_revenue_log (colonnes réelles du schéma)
      if (fanRevenue > 0) {
        const { error: logError } = await admin.from("creator_revenue_log").insert({
          creator_id,
          month_key: monthKey,
          fan_revenue: fanRevenue,
          fan_count: fans,
        });
        if (logError) {
          // UNIQUE constraint violation = already processed concurrently, skip
          if (logError.code === "23505") {
            logger.info(creator_id + " already processed (race), skipping");
            continue;
          }
          throw logError;
        }
      }

      // Mettre à jour creator_balance (colonnes réelles: balance, total_earned)
      if (fanRevenue > 0) {
        const { data: existing } = await admin
          .from("creator_balance")
          .select("balance, total_earned")
          .eq("creator_id", creator_id)
          .maybeSingle();

        await admin.from("creator_balance").upsert({
          creator_id,
          balance: (existing?.balance ?? 0) + fanRevenue,
          total_earned: (existing?.total_earned ?? 0) + fanRevenue,
          last_updated: new Date().toISOString(),
        });
      }

      processedCount++;
    }

    logger.info("✅ Revenue computed | processed: " + processedCount + "/" + creators.length + " | month: " + monthKey);

    logger.info("✅ EXIT | status: 200 | processed: " + processedCount + " | duration: " + (Date.now() - start) + "ms");
    return ok({ month_key: monthKey, creators_processed: processedCount });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
