// Cron — toutes les heures (0 * * * *)
// Envoie des push notifications pour les rappels repas configurés
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";

const SELF_URL = Deno.env.get("SUPABASE_URL")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;

serve(async (req) => {
  try {
    if (!verifyInternalSecret(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();

    const now = new Date();
    const currentHour = now.getUTCHours();
    const currentMinute = now.getUTCMinutes();
    // 1=Lundi ... 7=Dimanche (matches days_of_week column convention)
    const currentDayOfWeek = now.getUTCDay() === 0 ? 7 : now.getUTCDay();

    const { data: reminders, error } = await admin
      .from("meal_reminder")
      .select("user_id, meal_type, reminder_time, days_of_week")
      .eq("is_active", true);

    if (error) throw error;

    let sent = 0;

    for (const reminder of reminders ?? []) {
      const [rHour, rMinute] = reminder.reminder_time.split(":").map(Number);
      const diffMinutes = Math.abs(rHour * 60 + rMinute - (currentHour * 60 + currentMinute));

      if (diffMinutes > 5) continue;

      const days: number[] = reminder.days_of_week ?? [1, 2, 3, 4, 5, 6, 7];
      if (!days.includes(currentDayOfWeek)) continue;

      const mealLabels: Record<string, string> = {
        breakfast: "Petit-déjeuner",
        lunch: "Déjeuner",
        dinner: "Dîner",
        snack: "Collation",
      };

      await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-internal-secret": INTERNAL_SECRET,
        },
        body: JSON.stringify({
          user_id: reminder.user_id,
          title: `⏰ C'est l'heure du ${mealLabels[reminder.meal_type] ?? reminder.meal_type}`,
          body: "Consultez votre plan repas Akeli",
          type: "meal_reminder",
          data: { meal_type: reminder.meal_type },
        }),
      });

      sent++;
    }

    return ok({ checked: reminders?.length ?? 0, sent });
  } catch (e) {
    return serverError(e);
  }
});
