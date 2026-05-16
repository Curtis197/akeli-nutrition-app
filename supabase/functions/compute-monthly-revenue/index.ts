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
    const monthStart = `${monthKey}-01`;
    const monthEnd = new Date(prevDate.getFullYear(), prevDate.getMonth() + 1, 1)
      .toISOString()
      .split("T")[0];

    console.log(`[compute-monthly-revenue] Computing revenue for ${monthKey}`);

    // 1. Récupérer tous les créateurs actifs (qui ont des recettes publiées)
    const { data: creators, error: creatorsError } = await admin
      .from("creator")
      .select("id")
      .gt("recipe_count", 0);

    if (creatorsError) throw creatorsError;
    if (!creators?.length) return ok({ month_key: monthKey, creators_processed: 0 });

    // 2. Éviter de recalculer si déjà fait ce mois-ci
    const { data: alreadyLogged } = await admin
      .from("creator_revenue_log")
      .select("creator_id")
      .eq("revenue_type", "monthly_fan")
      .gte("logged_at", monthStart)
      .lt("logged_at", monthEnd);

    const alreadyDone = new Set((alreadyLogged ?? []).map((r) => r.creator_id));

    let processedCount = 0;

    for (const { id: creator_id } of creators) {
      if (alreadyDone.has(creator_id)) continue;

      // Fan revenue: nombre de fans actifs ce mois × 1€
      const { count: fanCount } = await admin
        .from("fan_subscription")
        .select("id", { count: "exact" })
        .eq("creator_id", creator_id)
        .eq("status", "active");

      const fans = fanCount ?? 0;
      const fanRevenue = fans * 1.0;

      // Insérer dans creator_revenue_log
      if (fanRevenue > 0) {
        await admin.from("creator_revenue_log").insert({
          creator_id,
          revenue_type: "monthly_fan",
          amount: fanRevenue,
          logged_at: new Date().toISOString(),
        });
      }

      // Mettre à jour creator_balance
      if (fanRevenue > 0) {
        const { data: existing } = await admin
          .from("creator_balance")
          .select("available_balance, lifetime_earnings")
          .eq("creator_id", creator_id)
          .maybeSingle();

        await admin.from("creator_balance").upsert({
          creator_id,
          available_balance: (existing?.available_balance ?? 0) + fanRevenue,
          lifetime_earnings: (existing?.lifetime_earnings ?? 0) + fanRevenue,
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
