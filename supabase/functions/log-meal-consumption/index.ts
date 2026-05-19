import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("log-meal-consumption");
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
    const { meal_plan_entry_id, servings = 1 } = await req.json();
    logger.debug("[STEP 1] Body parsed", { meal_plan_entry_id, servings });

    if (!meal_plan_entry_id) {
      logger.warn("EARLY RETURN | reason: meal_plan_entry_id missing");
      return err("meal_plan_entry_id is required");
    }

    // 1. Vérifier l'entrée et son état de consommation
    logger.debug("[STEP 2] Check meal entry");
    logRLSCheck(logger, "meal_plan_entry", "SELECT", user.id);
    const { data: entry, error: entryError } = await client
      .from("meal_plan_entry")
      .select("is_consumed, meal_plan_id")
      .eq("id", meal_plan_entry_id)
      .single();
    logQueryResult(logger, "meal_plan_entry", "SELECT", entry ? 1 : 0, entryError ?? undefined);

    if (entryError || !entry) {
      logger.warn("EARLY RETURN | reason: meal plan entry not found | id: " + meal_plan_entry_id);
      return err("Meal plan entry not found", 404);
    }
    if (entry.is_consumed) {
      logger.warn("EARLY RETURN | reason: meal already consumed | id: " + meal_plan_entry_id);
      return err("Meal already consumed");
    }

    // 2. Récupérer tous les composants du repas avec leurs recettes
    logger.debug("[STEP 3] Get components");
    logRLSCheck(logger, "meal_plan_entry_component", "SELECT", user.id);
    const { data: components, error: compError } = await client
      .from("meal_plan_entry_component")
      .select("id, recipe_id, consumption_weight")
      .eq("meal_plan_entry_id", meal_plan_entry_id);
    logQueryResult(logger, "meal_plan_entry_component", "SELECT", components?.length ?? 0, compError ?? undefined);

    if (compError || !components || components.length === 0) {
      logger.warn("EARLY RETURN | reason: no components found | meal_plan_entry_id: " + meal_plan_entry_id);
      return err("No components found for this meal plan entry", 404);
    }

    // 3. Vérifier le Mode Fan sur le composant base (premier composant).
    //    Un seul check par repas — le composant base détermine le créateur principal.
    const baseComponent = components[0];
    logger.debug("[STEP 4] Fan mode check | base_component_id: " + baseComponent.id);

    logRLSCheck(logger, "recipe", "SELECT", user.id);
    const { data: baseRecipe, error: baseRecipeError } = await client
      .from("recipe")
      .select("creator_id")
      .eq("id", baseComponent.recipe_id)
      .single();
    logQueryResult(logger, "recipe", "SELECT", baseRecipe ? 1 : 0, baseRecipeError ?? undefined);

    const baseCreatorId = baseRecipe?.creator_id ?? null;

    if (baseCreatorId) {
      logRLSCheck(logger, "fan_subscription", "SELECT", user.id);
      const { data: fanSub, error: fanSubError } = await client
        .from("fan_subscription")
        .select("creator_id")
        .eq("user_id", user.id)
        .eq("status", "active")
        .maybeSingle();
      logQueryResult(logger, "fan_subscription", "SELECT", fanSub ? 1 : 0, fanSubError ?? undefined);

      if (fanSub && fanSub.creator_id !== baseCreatorId) {
        const monthKey = new Date().toISOString().slice(0, 7);

        logRLSCheck(logger, "fan_external_recipe_counter", "SELECT", user.id);
        const { data: counter, error: counterError } = await client
          .from("fan_external_recipe_counter")
          .select("external_recipe_count")
          .eq("user_id", user.id)
          .eq("month_key", monthKey)
          .maybeSingle();
        logQueryResult(logger, "fan_external_recipe_counter", "SELECT", counter ? 1 : 0, counterError ?? undefined);

        if ((counter?.external_recipe_count ?? 0) >= 9) {
          logger.warn("EARLY RETURN | reason: fan mode limit reached | count: " + (counter?.external_recipe_count ?? 0));
          return err(
            "Fan mode limit reached: max 9 external recipes per month",
            403,
          );
        }

        const admin = serviceClient();
        logRLSCheck(logger, "fan_external_recipe_counter", "UPSERT", user.id);
        const { error: upsertError } = await admin
          .from("fan_external_recipe_counter")
          .upsert(
            {
              user_id: user.id,
              month_key: monthKey,
              external_recipe_count: (counter?.external_recipe_count ?? 0) + 1,
            },
            { onConflict: "user_id,month_key" },
          );
        logQueryResult(logger, "fan_external_recipe_counter", "UPSERT", upsertError ? 0 : 1, upsertError ?? undefined);
      }
    }

    // 4. Récupérer le creator_id de chaque recette distincte
    logger.debug("[STEP 5] Get recipe creators");
    const recipeIds = [...new Set(components.map((c) => c.recipe_id))];
    logRLSCheck(logger, "recipe", "SELECT", user.id);
    const { data: recipes, error: recipesError } = await client
      .from("recipe")
      .select("id, creator_id")
      .in("id", recipeIds);
    logQueryResult(logger, "recipe", "SELECT", recipes?.length ?? 0, recipesError ?? undefined);

    const creatorById = Object.fromEntries(
      (recipes ?? []).map((r) => [r.id, r.creator_id]),
    );

    // 5. Insérer N lignes dans meal_consumption — une par composant.
    //    consumption_value = 1/N, utilisé par le trigger nutrition et les revenus créateurs.
    logger.debug("[STEP 6] Insert consumption rows | count: " + components.length);
    const consumptionRows = components.map((comp) => ({
      user_id: user.id,
      recipe_id: comp.recipe_id,
      creator_id: creatorById[comp.recipe_id] ?? null,
      meal_plan_entry_id,
      component_id: comp.id,
      servings,
      consumption_value: comp.consumption_weight,
    }));

    logRLSCheck(logger, "meal_consumption", "INSERT", user.id);
    const { error: consumptionError } = await client
      .from("meal_consumption")
      .insert(consumptionRows);
    logQueryResult(logger, "meal_consumption", "INSERT", consumptionError ? 0 : consumptionRows.length, consumptionError ?? undefined);

    if (consumptionError) throw consumptionError;

    // 6. Marquer l'entrée comme consommée
    logger.debug("[STEP 7] Mark entry consumed");
    logRLSCheck(logger, "meal_plan_entry", "UPDATE", user.id);
    const { error: updateError } = await client
      .from("meal_plan_entry")
      .update({ is_consumed: true, consumed_at: new Date().toISOString() })
      .eq("id", meal_plan_entry_id);
    logQueryResult(logger, "meal_plan_entry", "UPDATE", updateError ? 0 : 1, updateError ?? undefined);

    logger.info("✅ EXIT | status: 200 | components_logged: " + components.length + " | duration: " + (Date.now() - start) + "ms");
    return ok({ consumed: true, components_logged: components.length });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
