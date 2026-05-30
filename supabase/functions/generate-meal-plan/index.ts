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
      meals_per_day = 3,
    } = body;
    logger.debug("[STEP 1] Body parsed", { start_date, days, meals_per_day });

    if (days < 1 || days > 14) {
      logger.warn("EARLY RETURN | reason: days out of range | days: " + days);
      return err("days must be between 1 and 14");
    }

    logger.debug("[STEP 2] RPC call | fn: generate_meal_plan");
    logRLSCheck(logger, "generate_meal_plan", "RPC", user.id);
    const { data, error } = await client.rpc("generate_meal_plan", {
      p_user_id: user.id,
      p_days: days,
      p_meals_per_day: meals_per_day,
      p_start_date: start_date,
    });
    logQueryResult(logger, "generate_meal_plan", "RPC", data?.length ?? 0, error ?? undefined);

    if (error) {
      // All-or-nothing: not enough recipes for a meal type
      if (error.message === "insufficient_recipes" || error.code === "P0001") {
        const mealType = error.details ?? "unknown";
        logger.warn("EARLY RETURN | reason: insufficient_recipes | meal_type: " + mealType);
        return err("Pas assez de recettes disponibles pour : " + mealType, 422);
      }
      throw error;
    }

    const mealPlanId = data?.[0]?.meal_plan_id ?? null;
    logger.debug("[STEP 3] Plan created | meal_plan_id: " + mealPlanId + " | entries: " + (data?.length ?? 0));

    if (mealPlanId) {
      logger.debug("[STEP 3.5] Fetch batch cooking preference");
      const { data: profileData, error: profileError } = await client
        .from("user_profile")
        .select("batch_cooking_enabled, batch_cooking_max_portions")
        .eq("id", user.id)
        .single();

      if (profileError) {
        logger.warn("[STEP 3.5] Failed to fetch batch preference (non-fatal) | " + profileError.message);
      }

      const batchEnabled = profileData?.batch_cooking_enabled ?? false;
      const maxPortions = profileData?.batch_cooking_max_portions ?? 7;
      logger.debug("[STEP 3.5] batchEnabled: " + batchEnabled + " | maxPortions: " + maxPortions);

      if (batchEnabled) {
        logger.debug("[STEP 4] RPC call | fn: create_batch_sessions | maxPortions: " + maxPortions);
        logRLSCheck(logger, "create_batch_sessions", "RPC", user.id);
        const { error: batchError } = await client.rpc("create_batch_sessions", {
          p_meal_plan_id: mealPlanId,
          p_user_id: user.id,
          p_max_portions: maxPortions,
        });
        logQueryResult(logger, "create_batch_sessions", "RPC", 0, batchError ?? undefined);
        if (batchError) {
          logger.warn("create_batch_sessions failed (non-fatal) | " + batchError.message);
        }
      } else {
        logger.debug("[STEP 4] Skipping create_batch_sessions | batch cooking disabled for user");
      }
    }

    logger.info("✅ EXIT | status: 200 | entries: " + (data?.length ?? 0) + " | duration: " + (Date.now() - start) + "ms");
    return ok({
      meal_plan_id: mealPlanId,
      start_date,
      days,
      meals_per_day,
    });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
