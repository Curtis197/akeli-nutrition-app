import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

function firstOfNextMonth(): string {
  const d = new Date();
  d.setMonth(d.getMonth() + 1, 1);
  return d.toISOString().split("T")[0];
}

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    // Trouver le Fan actif ou pending
    const { data: fanSub } = await client
      .from("fan_subscription")
      .select("id, creator_id, status")
      .eq("user_id", user.id)
      .in("status", ["active", "pending"])
      .maybeSingle();

    if (!fanSub) return err("No active fan subscription found", 404);

    const effectiveUntil = firstOfNextMonth();
    const monthKey = new Date().toISOString().slice(0, 7);

    // Annuler (effectif au 1er du mois suivant)
    await client
      .from("fan_subscription")
      .update({ status: "cancelled", effective_until: effectiveUntil })
      .eq("id", fanSub.id);

    // Historique
    await client.from("fan_subscription_history").insert({
      user_id: user.id,
      creator_id: fanSub.creator_id,
      action: "cancelled",
      previous_creator_id: fanSub.creator_id,
      month_key: monthKey,
    });

    return ok({ cancelled: true, effective_until: effectiveUntil });
  } catch (e) {
    return serverError(e);
  }
});
