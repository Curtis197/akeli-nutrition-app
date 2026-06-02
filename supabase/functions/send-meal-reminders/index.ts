// Cron-only — not callable from Flutter. Secured by x-internal-secret.
// Fires daily at 07:00 UTC via pg_cron. Sends one meal reminder per user
// who has at least one meal_plan_entry for today.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;
const PUSH_URL = `${SUPABASE_URL}/functions/v1/send-push-notification`;

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

    const today = new Date().toISOString().slice(0, 10);
    logger.debug("[STEP 2] Querying meal_plan_entry for date: " + today);

    const admin = serviceClient();

    logRLSCheck(logger, "meal_plan_entry", "SELECT", "cron");
    const { data: entries, error: entriesError } = await admin
      .from("meal_plan_entry")
      .select("user_id")
      .eq("planned_date", today);
    logQueryResult(logger, "meal_plan_entry", "SELECT", entries?.length ?? 0, entriesError ?? undefined);

    if (entriesError) {
      logger.error("Failed to query meal_plan_entry", { message: entriesError.message });
      return serverError(entriesError);
    }

    // Deduplicate — one notification per user
    const userIds = [...new Set((entries ?? []).map((e: { user_id: string }) => e.user_id))];
    logger.debug("[STEP 3] Unique users to notify: " + userIds.length);

    let notified = 0;
    let failed = 0;

    for (const userId of userIds) {
      const mealCount = (entries ?? []).filter((e: { user_id: string }) => e.user_id === userId).length;
      const bodyText = mealCount === 1
        ? "Vous avez 1 repas planifié aujourd'hui."
        : `Vous avez ${mealCount} repas planifiés aujourd'hui.`;

      try {
        const res = await fetch(PUSH_URL, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-internal-secret": INTERNAL_SECRET,
          },
          body: JSON.stringify({
            user_id: userId,
            type: "meal_reminder",
            title: "Votre plan repas du jour",
            body: bodyText,
            data: { date: today },
          }),
        });

        if (res.ok) {
          notified++;
        } else {
          logger.warn("Push failed for user | userId: " + userId + " | status: " + res.status);
          failed++;
        }
      } catch (fetchErr) {
        const msg = fetchErr instanceof Error ? fetchErr.message : String(fetchErr);
        logger.error("Push fetch threw for user | userId: " + userId, { message: msg });
        failed++;
      }
    }

    const skipped = 0; // reserved for future opt-out logic
    logger.info(`✅ EXIT | notified: ${notified} | skipped: ${skipped} | failed: ${failed} | duration: ${Date.now() - start}ms`);
    return ok({ notified, skipped, failed });
  } catch (e) {
    const caught = e instanceof Error ? e : new Error(String(e));
    logger.error("💥 Unhandled error", { message: caught.message, stack: caught.stack });
    return serverError(caught);
  }
});
