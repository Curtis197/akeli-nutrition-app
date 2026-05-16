import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const { meal_plan_entry_id, servings = 1 } = await req.json();
    if (!meal_plan_entry_id) return err("meal_plan_entry_id is required");

    // 1. Vérifier l'entrée et son état de consommation
    const { data: entry, error: entryError } = await client
      .from("meal_plan_entry")
      .select("is_consumed, meal_plan_id")
      .eq("id", meal_plan_entry_id)
      .single();

    if (entryError || !entry) return err("Meal plan entry not found", 404);
    if (entry.is_consumed) return err("Meal already consumed");

    // 2. Récupérer tous les composants du repas avec leurs recettes
    const { data: components, error: compError } = await client
      .from("meal_plan_entry_component")
      .select("id, recipe_id, consumption_weight")
      .eq("meal_plan_entry_id", meal_plan_entry_id);

    if (compError || !components || components.length === 0) {
      return err("No components found for this meal plan entry", 404);
    }

    // 3. Vérifier le Mode Fan sur le composant base (premier composant).
    //    Un seul check par repas — le composant base détermine le créateur principal.
    const baseComponent = components[0];
    const { data: baseRecipe } = await client
      .from("recipe")
      .select("creator_id")
      .eq("id", baseComponent.recipe_id)
      .single();

    const baseCreatorId = baseRecipe?.creator_id ?? null;

    if (baseCreatorId) {
      const { data: fanSub } = await client
        .from("fan_subscription")
        .select("creator_id")
        .eq("user_id", user.id)
        .eq("status", "active")
        .maybeSingle();

      if (fanSub && fanSub.creator_id !== baseCreatorId) {
        const monthKey = new Date().toISOString().slice(0, 7);
        const { data: counter } = await client
          .from("fan_external_recipe_counter")
          .select("external_recipe_count")
          .eq("user_id", user.id)
          .eq("month_key", monthKey)
          .maybeSingle();

        if ((counter?.external_recipe_count ?? 0) >= 9) {
          return err(
            "Fan mode limit reached: max 9 external recipes per month",
            403,
          );
        }

        const admin = serviceClient();
        await admin
          .from("fan_external_recipe_counter")
          .upsert(
            {
              user_id: user.id,
              month_key: monthKey,
              external_recipe_count: (counter?.external_recipe_count ?? 0) + 1,
            },
            { onConflict: "user_id,month_key" },
          );
      }
    }

    // 4. Récupérer le creator_id de chaque recette distincte
    const recipeIds = [...new Set(components.map((c) => c.recipe_id))];
    const { data: recipes } = await client
      .from("recipe")
      .select("id, creator_id")
      .in("id", recipeIds);

    const creatorById = Object.fromEntries(
      (recipes ?? []).map((r) => [r.id, r.creator_id]),
    );

    // 5. Insérer N lignes dans meal_consumption — une par composant.
    //    consumption_value = 1/N, utilisé par le trigger nutrition et les revenus créateurs.
    const consumptionRows = components.map((comp) => ({
      user_id: user.id,
      recipe_id: comp.recipe_id,
      creator_id: creatorById[comp.recipe_id] ?? null,
      meal_plan_entry_id,
      component_id: comp.id,
      servings,
      consumption_value: comp.consumption_weight,
    }));

    const { error: consumptionError } = await client
      .from("meal_consumption")
      .insert(consumptionRows);

    if (consumptionError) throw consumptionError;

    // 6. Marquer l'entrée comme consommée
    await client
      .from("meal_plan_entry")
      .update({ is_consumed: true, consumed_at: new Date().toISOString() })
      .eq("id", meal_plan_entry_id);

    return ok({ consumed: true, components_logged: components.length });
  } catch (e) {
    return serverError(e);
  }
});
