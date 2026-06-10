import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const SELF_URL = Deno.env.get("SUPABASE_URL")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("remove-group-member");
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
    const { group_id, target_user_id } = body as {
      group_id?: string;
      target_user_id?: string;
    };

    if (!group_id || !target_user_id) {
      logger.warn("EARLY RETURN | reason: missing group_id or target_user_id");
      return err("group_id and target_user_id are required");
    }
    logger.debug("[STEP 2] Parsed | group_id: " + group_id + " | target: " + target_user_id);

    if (target_user_id === user.id) {
      logger.warn("EARLY RETURN | reason: self-removal attempt");
      return err("Cannot remove yourself from the group", 400);
    }

    const admin = serviceClient();

    logger.debug("[STEP 3] Verify caller is admin");
    logRLSCheck(logger, "group_member", "SELECT", user.id);
    const { data: membership, error: memberError } = await admin
      .from("group_member")
      .select("role")
      .eq("group_id", group_id)
      .eq("user_id", user.id)
      .eq("role", "admin")
      .maybeSingle();
    logQueryResult(logger, "group_member", "SELECT", membership ? 1 : 0, memberError ?? undefined);

    if (!membership) {
      logger.warn("EARLY RETURN | reason: caller not an admin | group_id: " + group_id);
      return unauthorized("Vous n'êtes pas administrateur");
    }

    logger.debug("[STEP 4] Verify target is a member");
    logRLSCheck(logger, "group_member", "SELECT", target_user_id);
    const { data: targetMembership, error: targetError } = await admin
      .from("group_member")
      .select("user_id")
      .eq("group_id", group_id)
      .eq("user_id", target_user_id)
      .maybeSingle();
    logQueryResult(logger, "group_member", "SELECT", targetMembership ? 1 : 0, targetError ?? undefined);

    if (!targetMembership) {
      logger.warn("EARLY RETURN | reason: target not a member | target: " + target_user_id);
      return err("User is not a member of this group", 404);
    }

    logger.debug("[STEP 5] Fetch group name");
    logRLSCheck(logger, "community_group", "SELECT", "all");
    const { data: group, error: groupError } = await admin
      .from("community_group")
      .select("name")
      .eq("id", group_id)
      .maybeSingle();
    logQueryResult(logger, "community_group", "SELECT", group ? 1 : 0, groupError ?? undefined);
    const groupName = group?.name ?? "Groupe";

    logger.debug("[STEP 6] Delete from group_member");
    logRLSCheck(logger, "group_member", "DELETE", target_user_id);
    const { error: deleteError } = await admin
      .from("group_member")
      .delete()
      .eq("group_id", group_id)
      .eq("user_id", target_user_id);
    logQueryResult(logger, "group_member", "DELETE", deleteError ? 0 : 1, deleteError ?? undefined);

    if (deleteError) throw deleteError;

    logger.debug("[STEP 7] Lookup conversation for group");
    logRLSCheck(logger, "conversation", "SELECT", "all");
    const { data: conversation, error: convError } = await admin
      .from("conversation")
      .select("id")
      .eq("community_group_id", group_id)
      .maybeSingle();
    logQueryResult(logger, "conversation", "SELECT", conversation ? 1 : 0, convError ?? undefined);

    if (conversation) {
      logger.debug("[STEP 8] Delete from conversation_participant | convId: " + conversation.id);
      logRLSCheck(logger, "conversation_participant", "DELETE", target_user_id);
      const { error: cpError } = await admin
        .from("conversation_participant")
        .delete()
        .eq("conversation_id", conversation.id)
        .eq("user_id", target_user_id);
      logQueryResult(logger, "conversation_participant", "DELETE", cpError ? 0 : 1, cpError ?? undefined);
      if (cpError) throw cpError;
    } else {
      logger.warn("[STEP 8] No conversation found for group | group_id: " + group_id);
    }

    logger.debug("[STEP 9] Send push notification to excluded user");
    const pushRes = await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-internal-secret": INTERNAL_SECRET,
      },
      body: JSON.stringify({
        user_id: target_user_id,
        title: "Vous avez été retiré d'un groupe",
        body: `Vous avez été exclu du groupe : ${groupName}`,
        type: "group_exclusion",
        data: { group_id },
      }),
    });

    if (!pushRes.ok) {
      logger.warn("[STEP 9] Push notification failed | status: " + pushRes.status);
    }

    logger.info(`✅ EXIT | status: 200 | duration: ${Date.now() - start}ms`);
    return ok({ success: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
