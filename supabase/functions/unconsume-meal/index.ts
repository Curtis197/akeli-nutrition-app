// supabase/functions/unconsume-meal/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("unconsume-meal");
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
    const { meal_plan_entry_id } = await req.json();
    if (!meal_plan_entry_id) {
      logger.warn("EARLY RETURN | reason: meal_plan_entry_id missing");
      return err("meal_plan_entry_id is required");
    }
    logger.debug("[STEP 1] meal_plan_entry_id: " + meal_plan_entry_id);

    logger.debug("[STEP 2] Verify entry exists and is consumed");
    logRLSCheck(logger, "meal_plan_entry", "SELECT", user.id);
    const { data: entry, error: entryError } = await client
      .from("meal_plan_entry")
      .select("id, is_consumed, meal_plan_id")
      .eq("id", meal_plan_entry_id)
      .maybeSingle();
    logQueryResult(logger, "meal_plan_entry", "SELECT", entry ? 1 : 0, entryError ?? undefined);

    if (entryError || !entry) {
      logger.warn("EARLY RETURN | reason: entry not found | id: " + meal_plan_entry_id);
      return err("Meal plan entry not found", 404);
    }
    if (!entry.is_consumed) {
      logger.warn("EARLY RETURN | reason: entry not consumed | id: " + meal_plan_entry_id);
      return err("Meal is not consumed", 400);
    }

    logger.debug("[STEP 3] Delete meal_consumption rows for this entry");
    logRLSCheck(logger, "meal_consumption", "DELETE", user.id);
    const { error: deleteError } = await client
      .from("meal_consumption")
      .delete()
      .eq("meal_plan_entry_id", meal_plan_entry_id)
      .eq("user_id", user.id);
    logQueryResult(logger, "meal_consumption", "DELETE", deleteError ? 0 : 1, deleteError ?? undefined);

    if (deleteError) throw deleteError;

    logger.debug("[STEP 4] Reset is_consumed on meal_plan_entry");
    const admin = serviceClient();
    const { error: updateError } = await admin
      .from("meal_plan_entry")
      .update({ is_consumed: false, consumed_at: null })
      .eq("id", meal_plan_entry_id)
      .eq("meal_plan_id", entry.meal_plan_id);
    logQueryResult(logger, "meal_plan_entry", "UPDATE", updateError ? 0 : 1, updateError ?? undefined);

    if (updateError) throw updateError;

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ unconsumed: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
