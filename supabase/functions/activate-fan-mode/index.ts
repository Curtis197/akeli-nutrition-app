import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

function firstOfNextMonth(): string {
  const d = new Date();
  d.setMonth(d.getMonth() + 1, 1);
  return d.toISOString().split("T")[0];
}

function currentMonthKey(): string {
  return new Date().toISOString().slice(0, 7);
}

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const { creator_id } = await req.json();
    if (!creator_id) return err("creator_id is required");

    // 1. Vérifier que l'utilisateur a un abonnement actif
    const { data: sub } = await client
      .from("subscription")
      .select("status")
      .eq("user_id", user.id)
      .single();

    if (!sub || sub.status !== "active") {
      return err("Active subscription required to activate Fan mode", 403);
    }

    // 2. Vérifier que le créateur est éligible (≥ 30 recettes publiées)
    const { data: creator } = await client
      .from("creator")
      .select("is_fan_eligible, display_name")
      .eq("id", creator_id)
      .single();

    if (!creator) return err("Creator not found", 404);
    if (!creator.is_fan_eligible) {
      return err("Creator needs at least 30 published recipes to be Fan-eligible", 403);
    }

    // 3. Vérifier qu'il n'y a pas déjà un Fan actif ou pending
    const { data: existingSub } = await client
      .from("fan_subscription")
      .select("id, creator_id, status")
      .eq("user_id", user.id)
      .in("status", ["active", "pending"])
      .maybeSingle();

    const effectiveFrom = firstOfNextMonth();
    const monthKey = currentMonthKey();

    if (existingSub) {
      if (existingSub.creator_id === creator_id) {
        return err("Already a fan of this creator");
      }

      // Changer de créateur Fan — annuler l'ancien
      await client
        .from("fan_subscription")
        .update({ status: "cancelled", effective_until: effectiveFrom })
        .eq("id", existingSub.id);

      // Historique
      await client.from("fan_subscription_history").insert({
        user_id: user.id,
        creator_id: existingSub.creator_id,
        action: "changed",
        previous_creator_id: existingSub.creator_id,
        month_key: monthKey,
      });
    }

    // 4. Créer le nouveau fan_subscription (pending → actif le 1er du mois suivant)
    const { data: newSub, error: subError } = await client
      .from("fan_subscription")
      .insert({
        user_id: user.id,
        creator_id,
        status: "pending",
        effective_from: effectiveFrom,
      })
      .select()
      .single();

    if (subError) throw subError;

    // 5. Historique
    await client.from("fan_subscription_history").insert({
      user_id: user.id,
      creator_id,
      action: "activated",
      previous_creator_id: existingSub?.creator_id ?? null,
      month_key: monthKey,
    });

    return ok({
      fan_subscription_id: newSub.id,
      creator_name: creator.display_name,
      effective_from: effectiveFrom,
      status: "pending",
    });
  } catch (e) {
    return serverError(e);
  }
});
