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

  const logger = createLogger("invite-to-group");
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
    const { group_id, user_ids } = body as {
      group_id?: string;
      user_ids?: string[];
    };

    if (!group_id || !user_ids || !Array.isArray(user_ids) || user_ids.length === 0) {
      logger.warn("EARLY RETURN | reason: missing group_id or empty user_ids");
      return err("group_id and a non-empty user_ids array are required");
    }
    if (user_ids.length > 20) {
      logger.warn("EARLY RETURN | reason: too many user_ids");
      return err("Maximum 20 users can be invited at once");
    }
    logger.debug("[STEP 2] Parsed | group_id: " + group_id + " | count: " + user_ids.length);

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

    logger.debug("[STEP 4] Fetch caller name and group name");
    logRLSCheck(logger, "user_profile", "SELECT", user.id);
    const { data: callerProfile, error: callerError } = await admin
      .from("user_profile")
      .select("first_name")
      .eq("id", user.id)
      .maybeSingle();
    logQueryResult(logger, "user_profile", "SELECT", callerProfile ? 1 : 0, callerError ?? undefined);
    const inviterName = callerProfile?.first_name ?? "Quelqu'un";

    logRLSCheck(logger, "community_group", "SELECT", "all");
    const { data: group, error: groupError } = await admin
      .from("community_group")
      .select("name")
      .eq("id", group_id)
      .maybeSingle();
    logQueryResult(logger, "community_group", "SELECT", group ? 1 : 0, groupError ?? undefined);
    const groupName = group?.name ?? "Groupe";

    logger.debug("[STEP 5] Bulk insert invites");
    logRLSCheck(logger, "group_invite", "INSERT", "multiple");
    
    const invitesToInsert = user_ids.map(invitee_id => ({
      group_id,
      inviter_id: user.id,
      invitee_id,
      status: "pending"
    }));

    // ON CONFLICT (group_id, invitee_id) DO NOTHING
    const { data: insertedInvites, error: insertError } = await admin
      .from("group_invite")
      .upsert(invitesToInsert, { onConflict: "group_id, invitee_id", ignoreDuplicates: true })
      .select("id, invitee_id");
      
    logQueryResult(logger, "group_invite", "INSERT", insertedInvites?.length ?? 0, insertError ?? undefined);

    if (insertError) {
      throw insertError; // Throw so catch handles it
    }

    const actuallyInvited = insertedInvites || [];
    const skippedCount = user_ids.length - actuallyInvited.length;

    if (actuallyInvited.length === 0) {
      logger.info(`✅ EXIT | all skipped (already pending/accepted) | duration: ${Date.now() - start}ms`);
      return ok({ invited: 0, skipped: skippedCount, failed: 0 });
    }

    logger.debug("[STEP 6] Fan-out push notifications to " + actuallyInvited.length + " users");
    
    let failedCount = 0;

    for (const invite of actuallyInvited) {
      logger.debug("[STEP 6] Notifying user: " + invite.invitee_id);
      const pushRes = await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-internal-secret": INTERNAL_SECRET,
        },
        body: JSON.stringify({
          user_id: invite.invitee_id,
          title: `${inviterName} vous invite`,
          body: `Rejoignez le groupe : ${groupName}`,
          type: "group_invite",
          data: { group_id, invite_id: invite.id },
        }),
      });

      if (!pushRes.ok) {
        failedCount++;
        logger.warn("[STEP 6] Push failed | user: " + invite.invitee_id + " | status: " + pushRes.status);
      }
    }

    const finalInvited = actuallyInvited.length;
    logger.info(`✅ EXIT | status: 200 | invited: ${finalInvited} | skipped: ${skippedCount} | failed: ${failedCount} | duration: ${Date.now() - start}ms`);
    return ok({ invited: finalInvited, skipped: skippedCount, failed: failedCount });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
