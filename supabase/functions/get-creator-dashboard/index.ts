import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("get-creator-dashboard");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn("EARLY RETURN | reason: unauthorized");
      return unauthorized();
    }
    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 1] Parse query params");
    const url = new URL(req.url);
    const period = url.searchParams.get("period") ?? "last_3_months";
    logger.debug("[STEP 1] Query params", { period });

    // Vérifier que l'utilisateur est un créateur
    logger.debug("[STEP 2] Check creator flag");
    logRLSCheck(logger, "user_profile", "SELECT", user.id);
    const { data: profile, error: profileError } = await client
      .from("user_profile")
      .select("is_creator")
      .eq("id", user.id)
      .single();
    logQueryResult(logger, "user_profile", "SELECT", profile ? 1 : 0, profileError ?? undefined);

    if (!profile?.is_creator) {
      logger.warn("EARLY RETURN | reason: not a creator | userId: " + user.id);
      return err("Creator account required", 403);
    }

    // Récupérer le creator_id
    logger.debug("[STEP 3] Get creator data");
    logRLSCheck(logger, "creator", "SELECT", user.id);
    const { data: creator, error: creatorError } = await client
      .from("creator")
      .select("id, display_name, recipe_count, fan_count, total_revenue")
      .eq("user_id", user.id)
      .single();
    logQueryResult(logger, "creator", "SELECT", creator ? 1 : 0, creatorError ?? undefined);

    if (!creator) {
      logger.warn("EARLY RETURN | reason: creator profile not found | userId: " + user.id);
      return err("Creator profile not found", 404);
    }

    const isFanEligible = (creator.recipe_count ?? 0) >= 30;
    logger.debug("Creator | id: " + creator.id + " | recipe_count: " + creator.recipe_count + " | is_fan_eligible: " + isFanEligible);

    // Calculer la plage de mois selon le period
    const now = new Date();
    let monthsBack = 3;
    if (period === "last_6_months") monthsBack = 6;
    if (period === "year_to_date") monthsBack = now.getMonth() + 1;

    const startDate = new Date(now);
    startDate.setMonth(startDate.getMonth() - monthsBack);
    const startMonthKey = startDate.toISOString().slice(0, 7);

    // Revenus sur la période (colonnes réelles: month_key, fan_revenue, total_revenue)
    logger.debug("[STEP 4] Query revenue logs");
    logRLSCheck(logger, "creator_revenue_log", "SELECT", user.id);
    const { data: revenueLogs, error: revenueError } = await client
      .from("creator_revenue_log")
      .select("month_key, fan_revenue, total_revenue")
      .eq("creator_id", creator.id)
      .gte("month_key", startMonthKey)
      .order("month_key", { ascending: false });
    logQueryResult(logger, "creator_revenue_log", "SELECT", revenueLogs?.length ?? 0, revenueError ?? undefined);

    // Grouper par mois pour le graphique historique
    const byMonth: Record<string, { fan_revenue: number; total_revenue: number }> = {};
    for (const log of revenueLogs ?? []) {
      const mk = log.month_key as string;
      if (!byMonth[mk]) byMonth[mk] = { fan_revenue: 0, total_revenue: 0 };
      byMonth[mk].total_revenue += (log.total_revenue as number) ?? 0;
      byMonth[mk].fan_revenue += (log.fan_revenue as number) ?? 0;
    }
    const revenueHistory = Object.entries(byMonth)
      .map(([month_key, v]) => ({ month_key, ...v }))
      .sort((a, b) => b.month_key.localeCompare(a.month_key));

    // Solde créateur (colonnes réelles: balance, total_earned)
    logger.debug("[STEP 5] Query creator balance");
    logRLSCheck(logger, "creator_balance", "SELECT", user.id);
    const { data: balance, error: balanceError } = await client
      .from("creator_balance")
      .select("balance, total_earned")
      .eq("creator_id", creator.id)
      .maybeSingle();
    logQueryResult(logger, "creator_balance", "SELECT", balance ? 1 : 0, balanceError ?? undefined);

    logger.info("✅ EXIT | status: 200 | period: " + period + " | revenue_logs: " + (revenueLogs?.length ?? 0) + " | duration: " + (Date.now() - start) + "ms");
    return ok({
      creator: {
        id: creator.id,
        display_name: creator.display_name,
        recipe_count: creator.recipe_count,
        fan_count: creator.fan_count,
        is_fan_eligible: isFanEligible,
      },
      balance: balance ?? { balance: 0, total_earned: 0 },
      revenue_history: revenueHistory,
      period,
    });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
