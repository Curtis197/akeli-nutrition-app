// Appel interne uniquement (service key)
// Envoi de push notification FCM + insert dans notification table
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";
import { sendFcmV1 } from "../_shared/fcm.ts";

serve(async (req) => {
  const logger = createLogger("send-push-notification");
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

    logger.debug("[STEP 2] Parse body");
    const body = await req.json();
    const { user_id, title, body: notifBody, data = {}, type = "system" } = body;
    logger.debug("[STEP 2] Body parsed", { user_id, title, type });

    if (!user_id || !title) {
      logger.warn("EARLY RETURN | reason: missing user_id or title");
      return err("user_id and title are required");
    }

    const admin = serviceClient();

    const { data: userProfile, error: profileError } = await admin
      .from("user_profile")
      .select("notification_prefs")
      .eq("id", user_id)
      .single();
    if (profileError) {
      logger.warn("[STEP 2b] Failed to fetch user prefs — defaulting push to enabled | " + profileError.message);
    }
    const prefs = userProfile?.notification_prefs || {};
    const pushEnabled = prefs.push ?? true;

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
    const notificationInserted = !notifInsertError;
    logQueryResult(logger, "notification", "INSERT", notificationInserted ? 1 : 0, notifInsertError ?? undefined);

    logger.debug("[STEP 4b] Fetch unread count for badge");
    logRLSCheck(logger, "notification", "SELECT", user_id);
    const { count: unreadCount, error: unreadCountError } = await admin
      .from("notification")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user_id)
      .eq("is_read", false);
    logQueryResult(logger, "notification", "SELECT", unreadCount ?? 0, unreadCountError ?? undefined);
    const badgeCount = unreadCount ?? 1;

    if (!pushEnabled) {
      logger.info("✅ EXIT | FCM skipped (user opted out) | duration: " + (Date.now() - start) + "ms");
      return ok({ sent: false, notification_inserted: notificationInserted, reason: "user_opted_out" });
    }

    if (pushToken?.token) {
      logger.debug("[STEP 5] Sending FCM v1 push | platform: " + (pushToken.platform ?? "unknown") + " | badge: " + badgeCount);

      const fcmResult = await sendFcmV1(
        pushToken.token,
        title,
        notifBody ?? "",
        Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
        badgeCount,
        logger,
      );

      if (!fcmResult.ok) {
        logger.warn("FCM send failed | status: " + fcmResult.status + " | notification_inserted: true");

        // FCM 404 means the token is stale — clean it up
        if (fcmResult.status === 404) {
          logger.debug("[STEP 5b] Deleting stale push token");
          logRLSCheck(logger, "push_token", "DELETE", user_id);
          const { error: deleteError } = await admin
            .from("push_token")
            .delete()
            .eq("token", pushToken.token);
          logQueryResult(logger, "push_token", "DELETE", deleteError ? 0 : 1, deleteError ?? undefined);
        }
      }
    } else {
      logger.debug("[STEP 5] No push token found, skipping FCM");
    }

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ sent: !!pushToken?.token, notification_inserted: notificationInserted });
  } catch (e) {
    const caught = e instanceof Error ? e : new Error(String(e));
    logger.error("💥 Unhandled error", { message: caught.message, stack: caught.stack });
    return serverError(e);
  }
});
