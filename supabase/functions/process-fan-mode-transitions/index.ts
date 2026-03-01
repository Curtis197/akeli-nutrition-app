// Cron — 1er de chaque mois à 00:05 UTC
// Traite toutes les transitions Mode Fan en attente
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient } from "../_shared/supabase.ts";

serve(async (_req) => {
  try {
    const admin = serviceClient();
    const today = new Date().toISOString().split("T")[0];
    const monthKey = today.slice(0, 7);

    // 1. Activer les subscriptions pending dont effective_from <= today
    const { data: toActivate, error: activateError } = await admin
      .from("fan_subscription")
      .update({ status: "active" })
      .eq("status", "pending")
      .lte("effective_from", today)
      .select("user_id, creator_id");

    if (activateError) throw activateError;
    console.log(`[process-fan-mode-transitions] Activated: ${toActivate?.length ?? 0}`);

    // 2. Supprimer (ou laisser cancelled) les subscriptions dont effective_until <= today
    const { data: toDeactivate, error: deactivateError } = await admin
      .from("fan_subscription")
      .update({ status: "cancelled" })
      .eq("status", "cancelled")
      .lte("effective_until", today)
      .select("user_id, creator_id");

    if (deactivateError) throw deactivateError;
    console.log(`[process-fan-mode-transitions] Deactivated: ${toDeactivate?.length ?? 0}`);

    // 3. Initialiser les compteurs de recettes externes pour le nouveau mois
    // Pour tous les abonnés Fan actifs
    const { data: activeSubs } = await admin
      .from("fan_subscription")
      .select("user_id")
      .eq("status", "active");

    if (activeSubs?.length) {
      const counters = activeSubs.map(({ user_id }: { user_id: string }) => ({
        user_id,
        month_key: monthKey,
        external_recipe_count: 0,
      }));

      await admin
        .from("fan_external_recipe_counter")
        .upsert(counters, { onConflict: "user_id,month_key", ignoreDuplicates: true });
    }

    return ok({
      activated: toActivate?.length ?? 0,
      deactivated: toDeactivate?.length ?? 0,
      counters_initialized: activeSubs?.length ?? 0,
    });
  } catch (e) {
    return serverError(e);
  }
});
