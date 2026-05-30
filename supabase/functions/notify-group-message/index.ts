// Called by Flutter after sending a group message.
// Fans out push + in-app notifications to all group members except the sender.
// send-push-notification already inserts a notification row for each call,
// so we do NOT also write to the notification table here.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const SELF_URL = Deno.env.get("SUPABASE_URL")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;

serve(async (req) => {
  const logger = createLogger("notify-group-message");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify JWT");
    const { user } = await getAuthUser(req);
    if (!user) {
      logger.warn("EARLY RETURN | reason: unauthenticated");
      return unauthorized("Authentication required");
    }
    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 2] Parse body");
    const body = await req.json();
    const { group_id, message_preview } = body as {
      group_id?: string;
      message_preview?: string;
    };

    if (!group_id || !message_preview) {
      logger.warn("EARLY RETURN | reason: missing group_id or message_preview");
      return err("group_id and message_preview are required");
    }
    logger.debug("[STEP 2] Parsed | group_id: " + group_id);

    const admin = serviceClient();

    logger.debug("[STEP 3] Verify sender is a group member");
    logRLSCheck(logger, "group_member", "SELECT", user.id);
    const { data: membership, error: memberError } = await admin
      .from("group_member")
      .select("user_id")
      .eq("group_id", group_id)
      .eq("user_id", user.id)
      .maybeSingle();
    logQueryResult(logger, "group_member", "SELECT", membership ? 1 : 0, memberError ?? undefined);

    if (!membership) {
      logger.warn("EARLY RETURN | reason: sender not a group member | group_id: " + group_id);
      return unauthorized("Not a member of this group");
    }

    logger.debug("[STEP 4] Fetch sender display_name");
    logRLSCheck(logger, "user_profile", "SELECT", user.id);
    const { data: senderProfile } = await admin
      .from("user_profile")
      .select("display_name")
      .eq("id", user.id)
      .maybeSingle();
    const senderName = senderProfile?.display_name ?? "Quelqu'un";

    logger.debug("[STEP 5] Fetch group name");
    logRLSCheck(logger, "community_group", "SELECT", "all");
    const { data: group } = await admin
      .from("community_group")
      .select("name")
      .eq("id", group_id)
      .maybeSingle();
    const groupName = group?.name ?? "Groupe";

    logger.debug("[STEP 6] Fetch group members excluding sender");
    logRLSCheck(logger, "group_member", "SELECT", "all");
    const { data: members, error: membersError } = await admin
      .from("group_member")
      .select("user_id")
      .eq("group_id", group_id)
      .neq("user_id", user.id);
    logQueryResult(logger, "group_member", "SELECT", members?.length ?? 0, membersError ?? undefined);

    if (!members || members.length === 0) {
      logger.info("✅ EXIT | no other members to notify | duration: " + (Date.now() - start) + "ms");
      return ok({ sent: 0, failed: 0 });
    }

    logger.debug("[STEP 7] Fan-out push to " + members.length + " members");

    let sent = 0;
    let failed = 0;

    for (const member of members) {
      logger.debug("[STEP 7] Notifying member: " + member.user_id);
      const pushRes = await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-internal-secret": INTERNAL_SECRET,
        },
        body: JSON.stringify({
          user_id: member.user_id,
          title: senderName + " (" + groupName + ")",
          body: message_preview,
          type: "message",
          data: { group_id, sender_id: user.id },
        }),
      });

      if (pushRes.ok) {
        sent++;
      } else {
        failed++;
        logger.warn("[STEP 7] Push failed | member: " + member.user_id + " | status: " + pushRes.status);
      }
    }

    logger.info("✅ EXIT | status: 200 | sent: " + sent + " | failed: " + failed + " | duration: " + (Date.now() - start) + "ms");
    return ok({ sent, failed });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
