import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("submit-allergen-suggestion");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn('EARLY RETURN | reason: unauthorized | no authenticated user');
      return unauthorized();
    }

    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    const body = await req.json();
    const { label } = body;

    if (!label || typeof label !== 'string' || label.trim().length === 0) {
      logger.warn("EARLY RETURN | reason: missing or invalid label");
      return err("Allergen label is required");
    }

    const admin = serviceClient();

    logger.debug("[STEP 1] Insert allergen_suggestion");
    logRLSCheck(logger, "allergen_suggestion", "INSERT", user.id);
    const { error: insertError } = await admin
      .from("allergen_suggestion")
      .insert({
        user_id: user.id,
        label: label.trim(),
        status: "pending",
      });

    logQueryResult(logger, "allergen_suggestion", "INSERT", insertError ? 0 : 1, insertError ?? undefined);
    if (insertError) throw insertError;

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ success: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
