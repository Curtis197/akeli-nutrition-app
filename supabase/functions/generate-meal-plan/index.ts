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
    } = body;
    const meals_per_day = 3; // kept for RPC signature compat; SQL reads distribution instead
    logger.debug("[STEP 1] Body parsed", { start_date, days });

    if (days < 1 || days > 14) {
      logger.warn("EARLY RETURN | reason: days out of range | days: " + days);
      return err("days must be between 1 and 14");
    }

    logger.debug("[STEP 1.5] Fetch batch cooking preference");
    const { data: profileData, error: profileError } = await client
      .from("user_profile")
      .select("batch_cooking_enabled, batch_cooking_max_portions, use_saved_recipes_only, is_saved_recipe_eligible")
      .eq("id", user.id)
      .single();
    if (profileError) {
      logger.warn("[STEP 1.5] Failed to fetch batch preference (non-fatal) | " + profileError.message);
    }
    const batchEnabled = profileData?.batch_cooking_enabled ?? false;
    const maxPortions = profileData?.batch_cooking_max_portions ?? 4;
    const isSavedEligible = profileData?.is_saved_recipe_eligible ?? false;
    let useSavedRecipes = profileData?.use_saved_recipes_only ?? false;
    logger.debug("[STEP 1.5] batchEnabled: " + batchEnabled + " | maxPortions: " + maxPortions + " | useSavedRecipes: " + useSavedRecipes + " | isSavedEligible: " + isSavedEligible);

    // When batch cooking is on, honour the user's recipe-repetition cap.
    // When off, fall back to the default of 3 (hardcoded legacy behaviour).
    const maxRecipeRepeat = batchEnabled ? maxPortions : 3;

    let data, error;
    
    if (useSavedRecipes && isSavedEligible) {
      logger.debug("[STEP 2a] RPC call | fn: generate_meal_plan_from_saved | maxRecipeRepeat: " + maxRecipeRepeat);
      logRLSCheck(logger, "generate_meal_plan_from_saved", "RPC", user.id);
      const res = await client.rpc("generate_meal_plan_from_saved", {
        p_user_id: user.id,
        p_days: days,
        p_meals_per_day: meals_per_day,
        p_start_date: start_date,
        p_max_recipe_repeat: maxRecipeRepeat,
      });
      data = res.data;
      error = res.error;
      logQueryResult(logger, "generate_meal_plan_from_saved", "RPC", data?.length ?? 0, error ?? undefined);

      if (error) {
        if (error.message === "insufficient_budget") {
          logger.warn("EARLY RETURN | reason: budget too low");
          return err("Votre budget est trop strict pour respecter vos objectifs nutritionnels. Veuillez augmenter votre budget ou assouplir vos préférences.", 422);
        }
        if (error.message === "insufficient_saved_recipes" || (error.code === "P0001" && error.message !== "insufficient_budget")) {
          logger.warn("FALLBACK | reason: insufficient_saved_recipes | meal_type: " + (error.details ?? "unknown"));
          // Toggle preference off and fallback
          await client.from("user_profile").update({ use_saved_recipes_only: false }).eq("id", user.id);
          useSavedRecipes = false;
          error = null; // Clear error to allow fallback
        } else {
          throw error;
        }
      }
    }

    if (!useSavedRecipes || !isSavedEligible) {
      logger.debug("[STEP 2b] RPC call | fn: generate_meal_plan | maxRecipeRepeat: " + maxRecipeRepeat);
      logRLSCheck(logger, "generate_meal_plan", "RPC", user.id);
      const res = await client.rpc("generate_meal_plan", {
        p_user_id: user.id,
        p_days: days,
        p_meals_per_day: meals_per_day,
        p_start_date: start_date,
        p_max_recipe_repeat: maxRecipeRepeat,
      });
      data = res.data;
      error = res.error;
      logQueryResult(logger, "generate_meal_plan", "RPC", data?.length ?? 0, error ?? undefined);
    }

    if (error) {
      if (error.message === "insufficient_budget") {
        logger.warn("EARLY RETURN | reason: budget too low");
        return err("Votre budget est trop strict pour respecter vos objectifs nutritionnels. Veuillez augmenter votre budget ou assouplir vos préférences.", 422);
      }
      // All-or-nothing: not enough recipes for a meal type
      if (error.message === "insufficient_recipes" || error.code === "P0001") {
        const mealType = error.details ?? "unknown";
        logger.warn("EARLY RETURN | reason: insufficient_recipes | meal_type: " + mealType);
        return err("Pas assez de recettes disponibles pour : " + mealType, 422);
      }
      throw error;
    }

    if (!data || data.length === 0) {
      logger.warn("EARLY RETURN | reason: generate_meal_plan returned no entries (insufficient recipes)");
      return err("Pas assez de recettes disponibles pour générer un plan", 422);
    }

    const mealPlanId = data[0].meal_plan_id ?? null;
    logger.debug("[STEP 3] Plan created | meal_plan_id: " + mealPlanId + " | entries: " + data.length);

    if (mealPlanId) {
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
