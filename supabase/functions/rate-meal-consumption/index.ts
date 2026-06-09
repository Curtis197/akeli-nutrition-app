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
    const { meal_plan_entry_id, rating, rating_taste, rating_ease, rating_satiety, comment } = body;
    logger.debug("[STEP 1] Body parsed", { meal_plan_entry_id, rating, has_comment: !!comment });

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
    if (comment != null && typeof comment !== "string") {
      logger.warn("EARLY RETURN | reason: invalid comment type");
      return err("comment must be a string");
    }

    logger.debug("[STEP 2] Verify meal_plan_entry ownership and consumed state");
    logRLSCheck(logger, "meal_plan_entry", "SELECT", user.id);
    const { data: entry, error: entryError } = await client
      .from("meal_plan_entry")
      .select("id, is_consumed, meal_plan_entry_component(recipe_id)")
      .eq("id", meal_plan_entry_id)
      .maybeSingle();
    logQueryResult(logger, "meal_plan_entry", "SELECT", entry ? 1 : 0, entryError ?? undefined);

    if (entryError || !entry) {
      logger.warn("EARLY RETURN | reason: meal_plan_entry not found | id: " + meal_plan_entry_id + " | error: " + (entryError?.message || ""));
      return err("Meal plan entry not found", 404);
    }
    
    // Extract recipe_id from components
    const recipeId = entry.meal_plan_entry_component?.find((c: any) => c.recipe_id)?.recipe_id;
    if (!recipeId) {
      logger.warn("EARLY RETURN | reason: recipe_id not found in components | id: " + meal_plan_entry_id);
      return err("Recipe not found for this meal plan entry", 404);
    }
    if (!entry.is_consumed) {
      logger.warn("EARLY RETURN | reason: meal_not_consumed | id: " + meal_plan_entry_id);
      return err("meal_not_consumed", 403);
    }

    logger.debug("[STEP 3] Upsert rating and comment into recipe_comment");
    const admin = serviceClient();
    logRLSCheck(logger, "recipe_comment", "UPSERT", user.id);
    const { error: upsertError } = await admin
      .from("recipe_comment")
      .upsert(
        {
          recipe_id: recipeId,
          user_id: user.id,
          rating,
          rating_taste: rating_taste ?? null,
          rating_ease: rating_ease ?? null,
          rating_satiety: rating_satiety ?? null,
          content: comment && comment.trim().length > 0 ? comment.trim() : null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id, recipe_id" }
      );
    logQueryResult(logger, "recipe_comment", "UPSERT", upsertError ? 0 : 1, upsertError ?? undefined);

    if (upsertError) throw upsertError;

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ rated: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
