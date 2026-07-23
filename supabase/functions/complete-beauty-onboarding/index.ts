import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const PYTHON_SERVICE_URL = Deno.env.get("PYTHON_SERVICE_URL");

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("complete-beauty-onboarding");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) {
      logger.warn("EARLY RETURN | reason: unauthorized | no authenticated user");
      return unauthorized();
    }

    logger.setUserId(user.id);
    logger.info("👤 Auth verified | userId: " + user.id);

    const body = await req.json();
    const {
      hair_type,
      porosity,
      skin_type,
      scalp_type,
      beauty_goals = [],
      skin_concerns = [],
      hair_length_cm = 15,
      hair_strength_score = 7,
      hair_thickness_score = 7,
      hair_shedding_rate = "moderate",
      skin_hydration_level = 7,
      skin_clarity_score = 7,
      checkin_notes = "Premier journal de bord initial",
    } = body;

    if (!hair_type || !porosity || !skin_type) {
      logger.warn("EARLY RETURN | reason: missing required beauty profile fields");
      return err("Missing required beauty profile fields (hair_type, porosity, skin_type)");
    }

    const admin = serviceClient();

    // 1. Execute complete_beauty_onboarding RPC
    logger.debug("[STEP 1] Executing complete_beauty_onboarding RPC");
    logRLSCheck(logger, "user_health_profile", "UPSERT", user.id);
    const { error: rpcError } = await admin.rpc("complete_beauty_onboarding", {
      p_user_id: user.id,
      p_hair_type: hair_type,
      p_porosity: porosity,
      p_skin_type: skin_type,
      p_scalp_type: scalp_type ?? "normal",
      p_beauty_goals: beauty_goals,
      p_skin_concerns: skin_concerns,
      p_hair_length_cm: hair_length_cm,
      p_hair_strength_score: hair_strength_score,
      p_hair_thickness_score: hair_thickness_score,
      p_hair_shedding_rate: hair_shedding_rate,
      p_skin_hydration_level: skin_hydration_level,
      p_skin_clarity_score: skin_clarity_score,
      p_checkin_notes: checkin_notes,
    });
    logQueryResult(logger, "user_health_profile", "UPSERT", rpcError ? 0 : 1, rpcError ?? undefined);

    if (rpcError) {
      logger.error("💥 RPC complete_beauty_onboarding failed", rpcError);
      throw rpcError;
    }

    // 2. Trigger Beauty User Vectorization via Python recommendation engine (non-blocking)
    if (PYTHON_SERVICE_URL) {
      logger.debug("[STEP 2] FIRE compute-user-vector (mode: beauty, non-blocking)");
      fetch(`${PYTHON_SERVICE_URL}/compute-user-vector`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ user_id: user.id, mode: "beauty" }),
      }).catch((e) => logger.warn("[STEP 2] Python beauty vectorization trigger error: " + e.message));
    }

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ message: "Beauty onboarding completed successfully with vectorization trigger", user_id: user.id });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: (e as Error).message, stack: (e as Error).stack });
    return serverError(e);
  }
});
