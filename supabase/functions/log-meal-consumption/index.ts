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

    // 1. Fetch l'entrée du plan
    const { data: entry, error: entryError } = await client
      .from("meal_plan_entry")
      .select("recipe_id, is_consumed, meal_plan_id")
      .eq("id", meal_plan_entry_id)
      .single();

    if (entryError || !entry) return err("Meal plan entry not found", 404);
    if (entry.is_consumed) return err("Meal already consumed");

    // 2. Fetch la recette pour obtenir le creator_id
    const { data: recipe } = await client
      .from("recipe")
      .select("creator_id")
      .eq("id", entry.recipe_id)
      .single();

    const creator_id = recipe?.creator_id ?? null;

    // 3. Vérifier le Mode Fan si actif et recette d'un autre créateur
    if (creator_id) {
      const { data: fanSub } = await client
        .from("fan_subscription")
        .select("creator_id")
        .eq("user_id", user.id)
        .eq("status", "active")
        .maybeSingle();

      if (fanSub && fanSub.creator_id !== creator_id) {
        // Recette externe en mode Fan — vérifier le compteur
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

        // Incrémenter le compteur
        const admin = serviceClient();
        await admin
          .from("fan_external_recipe_counter")
          .upsert({
            user_id: user.id,
            month_key: monthKey,
            external_recipe_count: (counter?.external_recipe_count ?? 0) + 1,
          });
      }
    }

    // 4. Insérer dans meal_consumption (trigger PostgreSQL met à jour daily_nutrition_log)
    const { error: consumptionError } = await client
      .from("meal_consumption")
      .insert({
        user_id: user.id,
        recipe_id: entry.recipe_id,
        creator_id,
        meal_plan_entry_id,
        servings,
      });

    if (consumptionError) throw consumptionError;

    // 5. Marquer l'entrée comme consommée
    await client
      .from("meal_plan_entry")
      .update({ is_consumed: true, consumed_at: new Date().toISOString() })
      .eq("id", meal_plan_entry_id);

    return ok({ consumed: true, recipe_id: entry.recipe_id });
  } catch (e) {
    return serverError(e);
  }
});
