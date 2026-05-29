import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("rate-meal-consumption");
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

    logger.debug("[STEP 1] Parsing request body");
    const body = await req.json();
    const { meal_plan_entry_id, rating, rating_taste, rating_ease, rating_satiety } = body;
    logger.debug("[STEP 1] Body parsed", { meal_plan_entry_id, rating });

    if (!meal_plan_entry_id) {
      logger.warn("EARLY RETURN | reason: meal_plan_entry_id missing");
      return err("meal_plan_entry_id is required");
    }
    if (rating == null || rating < 1 || rating > 5) {
      logger.warn("EARLY RETURN | reason: invalid rating | value: " + rating);
      return err("rating must be an integer between 1 and 5");
    }
    for (const [key, val] of [["rating_taste", rating_taste], ["rating_ease", rating_ease], ["rating_satiety", rating_satiety]] as [string, unknown][]) {
      if (val != null && (typeof val !== "number" || val < 1 || val > 5)) {
        logger.warn("EARLY RETURN | reason: invalid " + key + " | value: " + val);
        return err(key + " must be an integer between 1 and 5 if provided");
      }
    }

    logger.debug("[STEP 2] Verify meal_plan_entry ownership and consumed state");
    logRLSCheck(logger, "meal_plan_entry", "SELECT", user.id);
    const { data: entry, error: entryError } = await client
      .from("meal_plan_entry")
      .select("id, is_consumed")
      .eq("id", meal_plan_entry_id)
      .maybeSingle();
    logQueryResult(logger, "meal_plan_entry", "SELECT", entry ? 1 : 0, entryError ?? undefined);

    if (entryError || !entry) {
      logger.warn("EARLY RETURN | reason: meal_plan_entry not found | id: " + meal_plan_entry_id);
      return err("Meal plan entry not found", 404);
    }
    if (!entry.is_consumed) {
      logger.warn("EARLY RETURN | reason: meal_not_consumed | id: " + meal_plan_entry_id);
      return err("meal_not_consumed", 403);
    }

    logger.debug("[STEP 3] Update meal_consumption rating columns");
    const admin = serviceClient();
    logRLSCheck(logger, "meal_consumption", "UPDATE", user.id);
    const { error: updateError } = await admin
      .from("meal_consumption")
      .update({
        rating,
        rating_taste: rating_taste ?? null,
        rating_ease: rating_ease ?? null,
        rating_satiety: rating_satiety ?? null,
      })
      .eq("meal_plan_entry_id", meal_plan_entry_id);
    logQueryResult(logger, "meal_consumption", "UPDATE", updateError ? 0 : 1, updateError ?? undefined);

    if (updateError) throw updateError;

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ rated: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
