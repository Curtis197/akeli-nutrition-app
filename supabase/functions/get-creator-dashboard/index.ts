import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const url = new URL(req.url);
    const period = url.searchParams.get("period") ?? "last_3_months";

    // Vérifier que l'utilisateur est un créateur
    const { data: profile } = await client
      .from("user_profile")
      .select("is_creator")
      .eq("id", user.id)
      .single();

    if (!profile?.is_creator) return err("Creator account required", 403);

    // Récupérer le creator_id
    const { data: creator } = await client
      .from("creator")
      .select("id, display_name, recipe_count, fan_count, total_revenue")
      .eq("user_id", user.id)
      .single();

    if (!creator) return err("Creator profile not found", 404);

    const isFanEligible = (creator.recipe_count ?? 0) >= 30;

    // Calculer la plage de dates selon le period
    const now = new Date();
    let monthsBack = 3;
    if (period === "last_6_months") monthsBack = 6;
    if (period === "year_to_date") monthsBack = now.getMonth() + 1;

    const startDate = new Date(now);
    startDate.setMonth(startDate.getMonth() - monthsBack);

    // Revenus sur la période (creator_revenue_log: {creator_id, revenue_type, amount, logged_at})
    const { data: revenueLogs } = await client
      .from("creator_revenue_log")
      .select("revenue_type, amount, logged_at")
      .eq("creator_id", creator.id)
      .gte("logged_at", startDate.toISOString())
      .order("logged_at", { ascending: false });

    // Grouper par mois pour le graphique historique
    const byMonth: Record<string, { fan_revenue: number; total_revenue: number }> = {};
    for (const log of revenueLogs ?? []) {
      const mk = (log.logged_at as string).slice(0, 7);
      if (!byMonth[mk]) byMonth[mk] = { fan_revenue: 0, total_revenue: 0 };
      byMonth[mk].total_revenue += log.amount as number;
      if (log.revenue_type === "monthly_fan") byMonth[mk].fan_revenue += log.amount as number;
    }
    const revenueHistory = Object.entries(byMonth)
      .map(([month_key, v]) => ({ month_key, ...v }))
      .sort((a, b) => b.month_key.localeCompare(a.month_key));

    // Solde créateur
    const { data: balance } = await client
      .from("creator_balance")
      .select("available_balance, lifetime_earnings")
      .eq("creator_id", creator.id)
      .maybeSingle();

    return ok({
      creator: {
        id: creator.id,
        display_name: creator.display_name,
        recipe_count: creator.recipe_count,
        fan_count: creator.fan_count,
        is_fan_eligible: isFanEligible,
      },
      balance: balance ?? { available_balance: 0, lifetime_earnings: 0 },
      revenue_history: revenueHistory,
      period,
    });
  } catch (e) {
    return serverError(e);
  }
});
