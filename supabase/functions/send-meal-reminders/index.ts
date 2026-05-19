// Cron — toutes les heures (0 * * * *)
// Envoie des push notifications pour les rappels repas configurés
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const SELF_URL = Deno.env.get("SUPABASE_URL")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;

serve(async (req) => {
  const logger = createLogger("send-meal-reminders");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify internal secret");
    if (!verifyInternalSecret(req)) {
      logger.warn("EARLY RETURN | reason: invalid internal secret");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();

    const now = new Date();
    const currentHour = now.getUTCHours();
    const currentMinute = now.getUTCMinutes();
    // 1=Lundi ... 7=Dimanche (matches days_of_week column convention)
    const currentDayOfWeek = now.getUTCDay() === 0 ? 7 : now.getUTCDay();

    logger.debug("[STEP 2] Query meal reminders");
    logRLSCheck(logger, "meal_reminder", "SELECT", "cron");
    const { data: reminders, error } = await admin
      .from("meal_reminder")
      .select("user_id, meal_type, reminder_time, days_of_week")
      .eq("is_active", true);
    logQueryResult(logger, "meal_reminder", "SELECT", reminders?.length ?? 0, error ?? undefined);

    logger.debug("[STEP 2] Fetched active reminders | count: " + (reminders?.length ?? 0) + " | currentHour: " + currentHour);

    if (error) throw error;

    let sent = 0;

    logger.debug("[STEP 3] Processing reminders for hour: " + currentHour + ":" + currentMinute);

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

      const pushRes = await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
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

      if (pushRes.ok) {
        sent++;
      } else {
        logger.warn('Push notification failed | user_id: ' + reminder.user_id + ' | meal_type: ' + reminder.meal_type + ' | status: ' + pushRes.status);
      }
    }

    logger.info("✅ EXIT | status: 200 | sent: " + sent + " | duration: " + (Date.now() - start) + "ms");
    return ok({ checked: reminders?.length ?? 0, sent });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
