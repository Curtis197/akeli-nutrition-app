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
      .select("id, display_name, recipe_count, fan_count, is_fan_eligible")
      .eq("user_id", user.id)
      .single();

    if (!creator) return err("Creator profile not found", 404);

    // Calculer la plage de dates selon le period
    const now = new Date();
    let monthsBack = 3;
    if (period === "last_6_months") monthsBack = 6;
    if (period === "year_to_date") monthsBack = now.getMonth() + 1;

    const startDate = new Date(now);
    startDate.setMonth(startDate.getMonth() - monthsBack);
    const startMonthKey = startDate.toISOString().slice(0, 7);

    // Revenus sur la période
    const { data: revenueLogs } = await client
      .from("creator_revenue_log")
      .select("month_key, fan_revenue, consumption_revenue, total_revenue, fan_count, consumption_count")
      .eq("creator_id", creator.id)
      .gte("month_key", startMonthKey)
      .order("month_key", { ascending: false });

    // Solde créateur
    const { data: balance } = await client
      .from("creator_balance")
      .select("balance, total_earned, total_paid_out")
      .eq("creator_id", creator.id)
      .single();

    // Consommations du mois en cours (live counter)
    const currentMonthKey = now.toISOString().slice(0, 7);
    const { count: currentConsumptions } = await client
      .from("meal_consumption")
      .select("id", { count: "exact" })
      .eq("creator_id", creator.id)
      .eq("month_key", currentMonthKey);

    const nextConsumptionRevenue = Math.floor((currentConsumptions ?? 0) / 90);
    const consumptionsUntilNextEuro = 90 - ((currentConsumptions ?? 0) % 90);

    return ok({
      creator: {
        id: creator.id,
        display_name: creator.display_name,
        recipe_count: creator.recipe_count,
        fan_count: creator.fan_count,
        is_fan_eligible: creator.is_fan_eligible,
      },
      balance: balance ?? { balance: 0, total_earned: 0, total_paid_out: 0 },
      revenue_history: revenueLogs ?? [],
      current_month: {
        month_key: currentMonthKey,
        consumptions: currentConsumptions ?? 0,
        consumptions_until_next_euro: consumptionsUntilNextEuro,
        projected_consumption_revenue: nextConsumptionRevenue,
      },
      period,
    });
  } catch (e) {
    return serverError(e);
  }
});
