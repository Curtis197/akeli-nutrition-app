// Cron — 1er de chaque mois à 00:05 UTC
// Traite toutes les transitions Mode Fan en attente
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient } from "../_shared/supabase.ts";

serve(async (_req) => {
  try {
    const admin = serviceClient();

    // Activer toutes les subscriptions pending (le cron tourne le 1er du mois)
    const { data: toActivate, error: activateError } = await admin
      .from("fan_subscription")
      .update({ status: "active" })
      .eq("status", "pending")
      .select("user_id, creator_id");

    if (activateError) throw activateError;
    console.log(`[process-fan-mode-transitions] Activated: ${toActivate?.length ?? 0}`);

    return ok({
      activated: toActivate?.length ?? 0,
    });
  } catch (e) {
    return serverError(e);
  }
});
