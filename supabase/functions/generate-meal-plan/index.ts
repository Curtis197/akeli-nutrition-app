import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("generate-meal-plan");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn("EARLY RETURN | reason: unauthorized");
      return unauthorized();
    }
    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 1] Parse body");
    const body = await req.json();
    const {
      start_date = new Date().toISOString().split("T")[0],
      days = 7,
      meals_per_day = ["breakfast", "lunch", "dinner"],
    } = body;
    logger.debug("[STEP 1] Body parsed", { start_date, days, meals_per_day_count: meals_per_day.length });

    if (days < 1 || days > 14) {
      logger.warn("EARLY RETURN | reason: days out of range | days: " + days);
      return err("days must be between 1 and 14");
    }

    // La sélection vectorielle est gérée par pgvector (ADR-001)
    // Appel à la fonction SQL PostgreSQL via .rpc()
    logger.debug("[STEP 2] RPC call | fn: generate_meal_plan");
    logRLSCheck(logger, "generate_meal_plan", "RPC", user.id);
    const { data, error } = await client.rpc("generate_meal_plan", {
      p_user_id: user.id,
      p_days: days,
      p_meals_per_day: meals_per_day.length,
      p_start_date: start_date,
    });
    logQueryResult(logger, "generate_meal_plan", "RPC", data?.length ?? 0, error ?? undefined);

    if (error) throw error;

    logger.debug("RPC result | plan_entries: " + (data?.length ?? 0) + " | meal_plan_id: " + (data?.[0]?.meal_plan_id ?? null));

    // Structurer la réponse par jour
    const planByDay: Record<string, unknown[]> = {};
    for (const entry of data ?? []) {
      const date = entry.scheduled_date;
      if (!planByDay[date]) planByDay[date] = [];
      planByDay[date].push(entry);
    }

    logger.info("✅ EXIT | status: 200 | days: " + days + " | duration: " + (Date.now() - start) + "ms");
    return ok({
      meal_plan_id: data?.[0]?.meal_plan_id ?? null,
      start_date,
      days,
      plan: planByDay,
    });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
