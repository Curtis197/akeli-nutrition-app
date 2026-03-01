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

    const body = await req.json();
    const {
      start_date = new Date().toISOString().split("T")[0],
      days = 7,
      meals_per_day = ["breakfast", "lunch", "dinner"],
    } = body;

    if (days < 1 || days > 14) return err("days must be between 1 and 14");

    // La sélection vectorielle est gérée par pgvector (ADR-001)
    // Appel à la fonction SQL PostgreSQL via .rpc()
    const { data, error } = await client.rpc("generate_meal_plan", {
      p_user_id: user.id,
      p_days: days,
      p_meals_per_day: meals_per_day.length,
      p_start_date: start_date,
    });

    if (error) throw error;

    // Structurer la réponse par jour
    const planByDay: Record<string, unknown[]> = {};
    for (const entry of data ?? []) {
      const date = entry.scheduled_date;
      if (!planByDay[date]) planByDay[date] = [];
      planByDay[date].push(entry);
    }

    return ok({
      meal_plan_id: data?.[0]?.meal_plan_id ?? null,
      start_date,
      days,
      plan: planByDay,
    });
  } catch (e) {
    return serverError(e);
  }
});
