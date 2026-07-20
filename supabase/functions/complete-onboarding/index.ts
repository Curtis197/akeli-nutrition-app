import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const PYTHON_SERVICE_URL = Deno.env.get("PYTHON_SERVICE_URL")!;

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger("complete-onboarding");
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

    logger.debug("[STEP 1] Parsing request body");
    const body = await req.json();
    const {
      first_name,
      last_name,
      sex,
      birth_date,
      height_cm,
      weight_kg,
      target_weight_kg,
      target_date,
      activity_level,
      goals,
      weight_goal,
      muscle_goal,
      cooking_time,
      batch_cooking_enabled,
      batch_cooking_max_portions,
      dietary_restrictions,
      cuisine_preferences,
      selectedAllergenIds,
      consent_privacy_at,
      consent_cgu_at,
      hair_type,
      porosity,
      skin_type,
      sensitive_scalp,
      beauty_goals,
      preferred_actives,
    } = body;

    logger.debug("[STEP 2] Validating params", {
      sex: !!sex,
      birth_date: !!birth_date,
      height_cm: !!height_cm,
      weight_kg: !!weight_kg,
      activity_level: !!activity_level,
    });

    // Validation basique
    if (!sex || !birth_date || !height_cm || !weight_kg || !activity_level) {
      logger.warn("EARLY RETURN | reason: missing required health profile fields");
      return err("Missing required health profile fields");
    }

    if (!consent_privacy_at || !consent_cgu_at) {
      logger.warn("EARLY RETURN | reason: missing consent timestamps");
      return err("User consent timestamps are required");
    }

    const admin = serviceClient();

    // 3. Upsert user_health_profile
    logger.debug("[STEP 3] Upsert user_health_profile");
    logRLSCheck(logger, "user_health_profile", "UPSERT", user.id);
    const { error: healthError } = await admin
      .from("user_health_profile")
      .upsert({
        user_id: user.id,
        sex,
        birth_date,
        height_cm,
        weight_kg,
        target_weight_kg,
        target_date,
        activity_level,
        ...(weight_goal !== undefined && { weight_goal }),
        ...(muscle_goal !== undefined && { muscle_goal }),
        ...(cooking_time !== undefined && { cooking_time }),
        ...(hair_type !== undefined && { hair_type }),
        ...(porosity !== undefined && { porosity }),
        ...(skin_type !== undefined && { skin_type }),
        ...(sensitive_scalp !== undefined && { sensitive_scalp }),
        ...(beauty_goals !== undefined && { beauty_goals }),
        ...(preferred_actives !== undefined && { preferred_actives }),
      }, { onConflict: "user_id" });
    logQueryResult(logger, "user_health_profile", "UPSERT", healthError ? 0 : 1, healthError ?? undefined);
    if (healthError) throw healthError;

    // 4. Remplacer les goal_type rows (uniquement si fournis).
    // NutritionPlanPage écrit une row séparée avec goal_type=NULL et les macros numériques —
    // on ne supprime QUE les rows où goal_type IS NOT NULL pour ne pas perdre les macros.
    logger.debug("[STEP 4] Replace user_goal (goal_type rows only)");
    if (goals?.length) {
      logRLSCheck(logger, "user_goal", "DELETE", user.id);
      const { error: goalDeleteError } = await admin
        .from("user_goal")
        .delete()
        .eq("user_id", user.id)
        .not("goal_type", "is", null);
      logQueryResult(logger, "user_goal", "DELETE", 0, goalDeleteError ?? undefined);

      logRLSCheck(logger, "user_goal", "INSERT", user.id);
      const { error: goalInsertError } = await admin.from("user_goal").insert(
        goals.map((goal_type: string) => ({ user_id: user.id, goal_type, is_active: true })),
      );
      logQueryResult(logger, "user_goal", "INSERT", goalInsertError ? 0 : goals.length, goalInsertError ?? undefined);
    } else {
      logger.debug("[STEP 4] Skipping user_goal replace — no goals in body");
    }

    // 5. Remplacer les restrictions alimentaires
    logger.debug("[STEP 5] Replace user_dietary_restriction");
    logRLSCheck(logger, "user_dietary_restriction", "DELETE", user.id);
    const { error: restrictionDeleteError } = await admin.from("user_dietary_restriction").delete().eq("user_id", user.id);
    logQueryResult(logger, "user_dietary_restriction", "DELETE", 0, restrictionDeleteError ?? undefined);

    if (dietary_restrictions?.length) {
      logRLSCheck(logger, "user_dietary_restriction", "INSERT", user.id);
      const { error: restrictionInsertError } = await admin.from("user_dietary_restriction").insert(
        dietary_restrictions.map((restriction: string) => ({ user_id: user.id, restriction })),
      );
      logQueryResult(logger, "user_dietary_restriction", "INSERT", restrictionInsertError ? 0 : dietary_restrictions.length, restrictionInsertError ?? undefined);
    }

    logger.debug("[STEP 5b] Replace user_allergy");
    logRLSCheck(logger, "user_allergy", "DELETE", user.id);
    const { error: allergyDeleteError } = await admin.from("user_allergy").delete().eq("user_id", user.id);
    logQueryResult(logger, "user_allergy", "DELETE", 0, allergyDeleteError ?? undefined);

    if (selectedAllergenIds?.length) {
      logRLSCheck(logger, "user_allergy", "INSERT", user.id);
      const { error: allergyInsertError } = await admin.from("user_allergy").insert(
        selectedAllergenIds.map((allergen_id: string) => ({ user_id: user.id, allergen_id })),
      );
      logQueryResult(logger, "user_allergy", "INSERT", allergyInsertError ? 0 : selectedAllergenIds.length, allergyInsertError ?? undefined);
    }

    // 6. Remplacer les préférences culinaires
    // cuisine_preferences est une liste de codes region (strings)
    logger.debug("[STEP 6] Replace user_cuisine_preference");
    logRLSCheck(logger, "user_cuisine_preference", "DELETE", user.id);
    const { error: cuisineDeleteError } = await admin.from("user_cuisine_preference").delete().eq("user_id", user.id);
    logQueryResult(logger, "user_cuisine_preference", "DELETE", 0, cuisineDeleteError ?? undefined);

    if (cuisine_preferences?.length) {
      logRLSCheck(logger, "user_cuisine_preference", "INSERT", user.id);
      const { error: cuisineInsertError } = await admin.from("user_cuisine_preference").insert(
        (cuisine_preferences as string[]).map((region) => ({
          user_id: user.id,
          region,
          preference_score: 1.0,
        })),
      );
      logQueryResult(logger, "user_cuisine_preference", "INSERT", cuisineInsertError ? 0 : cuisine_preferences.length, cuisineInsertError ?? undefined);
    }

    // 7. Mettre à jour le profil utilisateur (first_name, last_name + onboarding terminé)
    logger.debug("[STEP 7] Update user_profile onboarding_done");
    logRLSCheck(logger, "user_profile", "UPDATE", user.id);
    const { error: profileUpdateError } = await admin
      .from("user_profile")
      .update({
        first_name,
        last_name,
        onboarding_done: true,
        consent_privacy_at,
        consent_cgu_at,
        ...(batch_cooking_enabled !== undefined && { batch_cooking_enabled }),
        ...(batch_cooking_max_portions !== undefined && { batch_cooking_max_portions }),
      })
      .eq("id", user.id);
    logQueryResult(logger, "user_profile", "UPDATE", profileUpdateError ? 0 : 1, profileUpdateError ?? undefined);

    // 8. Déclencher le calcul du premier user_vector (non bloquant)
    // Exception runtime ADR-001 : appelé une seule fois à l'onboarding
    logger.debug("[STEP 8] FIRE compute-user-vector (non-blocking)");
    fetch(`${PYTHON_SERVICE_URL}/compute-user-vector`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ user_id: user.id }),
    }).catch((e) => logger.warn("[STEP 8] Python vector error: " + e.message));

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ message: "Onboarding completed", user_id: user.id });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
