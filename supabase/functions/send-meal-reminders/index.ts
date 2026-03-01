// Cron — toutes les heures (0 * * * *)
// Envoie des push notifications pour les rappels repas configurés
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient } from "../_shared/supabase.ts";

const SELF_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (_req) => {
  try {
    const admin = serviceClient();

    const now = new Date();
    const currentHour = now.getUTCHours();
    const currentMinute = now.getUTCMinutes();
    const currentDay = now.getUTCDay() === 0 ? 7 : now.getUTCDay(); // 1=Lun ... 7=Dim

    // Fetch les rappels actifs dont l'heure correspond (±5 minutes)
    const { data: reminders, error } = await admin
      .from("meal_reminder")
      .select("user_id, meal_type, reminder_time")
      .eq("is_active", true)
      .contains("days_of_week", [currentDay]);

    if (error) throw error;

    let sent = 0;

    for (const reminder of reminders ?? []) {
      const [rHour, rMinute] = reminder.reminder_time.split(":").map(Number);
      const diffMinutes = Math.abs(rHour * 60 + rMinute - (currentHour * 60 + currentMinute));

      if (diffMinutes > 5) continue;

      const mealLabels: Record<string, string> = {
        breakfast: "Petit-déjeuner",
        lunch: "Déjeuner",
        dinner: "Dîner",
        snack: "Collation",
      };

      // Appel interne à send-push-notification
      await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${SERVICE_KEY}`,
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
