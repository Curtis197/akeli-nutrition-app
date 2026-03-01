// Cron — 1er de chaque mois à 01:00 UTC (après process-fan-mode-transitions)
// Calcule les revenus de tous les créateurs pour le mois écoulé
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient } from "../_shared/supabase.ts";

serve(async (_req) => {
  try {
    const admin = serviceClient();

    // Mois écoulé (ex: si on est le 1er mars 2026 → calcule février 2026)
    const prevDate = new Date();
    prevDate.setMonth(prevDate.getMonth() - 1);
    const monthKey = prevDate.toISOString().slice(0, 7); // ex: '2026-02'

    console.log(`[compute-monthly-revenue] Computing revenue for ${monthKey}`);

    // 1. Récupérer tous les créateurs actifs (qui ont des recettes publiées)
    const { data: creators, error: creatorsError } = await admin
      .from("creator")
      .select("id")
      .gt("recipe_count", 0);

    if (creatorsError) throw creatorsError;
    if (!creators?.length) return ok({ month_key: monthKey, creators_processed: 0 });

    let processedCount = 0;

    for (const { id: creator_id } of creators) {
      // Fan revenue: nombre de fans actifs ce mois × 1€
      const { count: fanCount } = await admin
        .from("fan_subscription")
        .select("id", { count: "exact" })
        .eq("creator_id", creator_id)
        .eq("status", "active")
        .lte("effective_from", `${monthKey}-01`);

      // Consumption revenue: floor(consommations du mois / 90) × 1€
      const { count: consumptionCount } = await admin
        .from("meal_consumption")
        .select("id", { count: "exact" })
        .eq("creator_id", creator_id)
        .eq("month_key", monthKey);

      const fans = fanCount ?? 0;
      const consumptions = consumptionCount ?? 0;
      const fanRevenue = fans * 1.0;
      const consumptionRevenue = Math.floor(consumptions / 90) * 1.0;
      const totalRevenue = fanRevenue + consumptionRevenue;

      // 2. Insérer dans creator_revenue_log (ignore si déjà calculé)
      const { error: logError } = await admin
        .from("creator_revenue_log")
        .upsert({
          creator_id,
          month_key: monthKey,
          fan_revenue: fanRevenue,
          consumption_revenue: consumptionRevenue,
          fan_count: fans,
          consumption_count: consumptions,
        }, { onConflict: "creator_id,month_key", ignoreDuplicates: true });

      if (logError) {
        console.error(`[compute-monthly-revenue] Log error for ${creator_id}:`, logError);
        continue;
      }

      // 3. Mettre à jour creator_balance si revenue > 0
      if (totalRevenue > 0) {
        await admin.rpc("increment_creator_balance", {
          p_creator_id: creator_id,
          p_amount: totalRevenue,
        }).catch(() => {
          // Fallback si la fonction RPC n'existe pas encore — update direct
          admin
            .from("creator_balance")
            .upsert({
              creator_id,
              balance: totalRevenue,
              total_earned: totalRevenue,
            });
        });
      }

      processedCount++;
    }

    console.log(
      `[compute-monthly-revenue] Processed ${processedCount}/${creators.length} creators for ${monthKey}`,
    );

    return ok({ month_key: monthKey, creators_processed: processedCount });
  } catch (e) {
    return serverError(e);
  }
});
