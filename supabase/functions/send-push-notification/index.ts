// Appel interne uniquement (service key)
// Envoi de push notification FCM + insert dans notification table
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;
const FCM_URL = "https://fcm.googleapis.com/fcm/send";

serve(async (req) => {
  const logger = createLogger("send-push-notification");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();

  try {
    logger.info("⚡ ENTRY | method: " + req.method);

    logger.debug("[STEP 1] Verify internal secret");
    if (!verifyInternalSecret(req)) {
      logger.warn("EARLY RETURN | reason: invalid internal secret");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    logger.debug("[STEP 2] Parse body");
    const body = await req.json();
    const { user_id, title, body: notifBody, data = {}, type = "system" } = body;
    logger.debug("[STEP 2] Body parsed", { user_id, title, type });

    if (!user_id || !title) {
      logger.warn("EARLY RETURN | reason: missing user_id or title");
      return err("user_id and title are required");
    }

    const admin = serviceClient();

    logger.debug("[STEP 3] Get push token");
    logRLSCheck(logger, "push_token", "SELECT", user_id);
    const { data: pushToken, error: pushTokenError } = await admin
      .from("push_token")
      .select("token, platform")
      .eq("user_id", user_id)
      .order("updated_at", { ascending: false })
      .limit(1)
      .single();
    logQueryResult(logger, "push_token", "SELECT", pushToken?.token ? 1 : 0, pushTokenError ?? undefined);

    logger.debug("[STEP 4] Insert notification record");
    logRLSCheck(logger, "notification", "INSERT", user_id);
    const { error: notifInsertError } = await admin.from("notification").insert({
      user_id,
      type,
      title,
      body: notifBody,
      data,
    });
    logQueryResult(logger, "notification", "INSERT", notifInsertError ? 0 : 1, notifInsertError ?? undefined);

    if (pushToken?.token) {
      logger.debug("[STEP 5] Sending FCM push | platform: " + (pushToken?.platform ?? "unknown"));
      const fcmPayload = {
        to: pushToken.token,
        notification: { title, body: notifBody },
        data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
        priority: "high",
      };

      const fcmRes = await fetch(FCM_URL, {
        method: "POST",
        headers: {
          "Authorization": `key=${FCM_SERVER_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      });

      if (!fcmRes.ok) {
        logger.error("FCM send failed", { status: fcmRes.status });
      }
    } else {
      logger.debug("[STEP 5] No push token found, skipping FCM");
    }

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ sent: !!pushToken?.token, notification_inserted: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
