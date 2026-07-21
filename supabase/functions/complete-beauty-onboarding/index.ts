import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";

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

    // Execute complete_beauty_onboarding RPC via Edge Function wrapper
    logger.debug("[STEP 1] Executing complete_beauty_onboarding RPC");
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

    if (rpcError) {
      logger.error("💥 RPC complete_beauty_onboarding failed", rpcError);
      throw rpcError;
    }

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ message: "Beauty onboarding completed successfully", user_id: user.id });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: (e as Error).message });
    return serverError(e);
  }
});
