import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("toggle-recipe-save");
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
    logger.debug("[STEP 1] Parsed | recipe_id: " + recipe_id);
    if (!recipe_id) {
      logger.warn("EARLY RETURN | reason: missing recipe_id");
      return err("recipe_id is required");
    }

    logger.debug("[STEP 2] Check existing save | recipe_id: " + recipe_id);
    logRLSCheck(logger, "recipe_save", "SELECT", user.id);
    const { data: existing, error: checkError } = await client
      .from("recipe_save")
      .select("user_id")
      .eq("user_id", user.id)
      .eq("recipe_id", recipe_id)
      .maybeSingle();
    logQueryResult(logger, "recipe_save", "SELECT", existing ? 1 : 0, checkError ?? undefined);
    if (checkError) throw checkError;

    if (existing) {
      logger.debug("[STEP 3a] Unsave | recipe_id: " + recipe_id);
      logRLSCheck(logger, "recipe_save", "DELETE", user.id);
      const { error: deleteError } = await client
        .from("recipe_save")
        .delete()
        .eq("user_id", user.id)
        .eq("recipe_id", recipe_id);
      logQueryResult(logger, "recipe_save", "DELETE", deleteError ? 0 : 1, deleteError ?? undefined);
      if (deleteError) throw deleteError;
      logger.info("✅ EXIT | status: 200 | action: unsaved | recipe_id: " + recipe_id + " | duration: " + (Date.now() - start) + "ms");
      return ok({ saved: false });
    } else {
      logger.debug("[STEP 3b] Save | recipe_id: " + recipe_id);
      logRLSCheck(logger, "recipe_save", "INSERT", user.id);
      const { error: insertError } = await client
        .from("recipe_save")
        .insert({ user_id: user.id, recipe_id });
      logQueryResult(logger, "recipe_save", "INSERT", insertError ? 0 : 1, insertError ?? undefined);
      if (insertError) throw insertError;
      logger.info("✅ EXIT | status: 200 | action: saved | recipe_id: " + recipe_id + " | duration: " + (Date.now() - start) + "ms");
      return ok({ saved: true });
    }
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
