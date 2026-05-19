import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("toggle-recipe-like");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn("EARLY RETURN | reason: auth failed");
      return unauthorized();
    }

    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    logger.debug("[STEP 1] Parse body");
    const { recipe_id } = await req.json();
    logger.debug("[STEP 1] Parsed body | recipe_id: " + recipe_id);
    if (!recipe_id) {
      logger.warn("EARLY RETURN | reason: missing recipe_id");
      return err("recipe_id is required");
    }

    logger.debug("[STEP 2] Check existing like | recipe_id: " + recipe_id);
    logRLSCheck(logger, "recipe_like", "SELECT", user.id);
    const { data: existing, error: checkError } = await client
      .from("recipe_like")
      .select("user_id")
      .eq("user_id", user.id)
      .eq("recipe_id", recipe_id)
      .maybeSingle();
    logQueryResult(logger, "recipe_like", "SELECT", existing ? 1 : 0, checkError ?? undefined);
    logger.info("Like check | recipe_id: " + recipe_id + " | already_liked: " + !!existing);

    if (existing) {
      // Unlike
      logger.debug("[STEP 3a] Unlike path | recipe_id: " + recipe_id);
      logRLSCheck(logger, "recipe_like", "DELETE", user.id);
      const { error: deleteError } = await client
        .from("recipe_like")
        .delete()
        .eq("user_id", user.id)
        .eq("recipe_id", recipe_id);
      logQueryResult(logger, "recipe_like", "DELETE", deleteError ? 0 : 1, deleteError ?? undefined);
      logger.info("✅ EXIT | status: 200 | action: unliked | duration: " + (Date.now() - start) + "ms");
      return ok({ liked: false });
    } else {
      // Like
      logger.debug("[STEP 3b] Like path | recipe_id: " + recipe_id);
      logRLSCheck(logger, "recipe_like", "INSERT", user.id);
      const { error: insertError } = await client
        .from("recipe_like")
        .insert({ user_id: user.id, recipe_id });
      logQueryResult(logger, "recipe_like", "INSERT", insertError ? 0 : 1, insertError ?? undefined);
      logger.info("✅ EXIT | status: 200 | action: liked | duration: " + (Date.now() - start) + "ms");
      return ok({ liked: true });
    }
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
