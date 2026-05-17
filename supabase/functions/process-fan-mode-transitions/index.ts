// Cron — 1er de chaque mois à 00:05 UTC
// Traite toutes les transitions Mode Fan en attente
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";

serve(async (req) => {
  try {
    if (!verifyInternalSecret(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();

    const today = new Date().toISOString().split("T")[0];

    const { data: toActivate, error: activateError } = await admin
      .from("fan_subscription")
      .update({ status: "active" })
      .eq("status", "pending")
      .lte("effective_from", today)
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
