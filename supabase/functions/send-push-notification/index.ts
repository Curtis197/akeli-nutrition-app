// Appel interne uniquement (service key)
// Envoi de push notification FCM + insert dans notification table
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { serviceClient } from "../_shared/supabase.ts";

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;
const FCM_URL = "https://fcm.googleapis.com/fcm/send";

serve(async (req) => {
  try {
    const body = await req.json();
    const { user_id, title, body: notifBody, data = {}, type = "system" } = body;

    if (!user_id || !title) return err("user_id and title are required");

    const admin = serviceClient();

    // 1. Fetch le push token de l'utilisateur
    const { data: pushToken } = await admin
      .from("push_token")
      .select("token, platform")
      .eq("user_id", user_id)
      .order("updated_at", { ascending: false })
      .limit(1)
      .single();

    // 2. Insert dans notification (in-app center)
    await admin.from("notification").insert({
      user_id,
      type,
      title,
      body: notifBody,
      data,
    });

    // 3. Envoyer via FCM si token disponible
    if (pushToken?.token) {
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
        console.error("[send-push-notification] FCM error:", await fcmRes.text());
      }
    }

    return ok({ sent: !!pushToken?.token, notification_inserted: true });
  } catch (e) {
    return serverError(e);
  }
});
