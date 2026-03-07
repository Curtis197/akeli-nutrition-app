import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser, serviceClient } from "../_shared/supabase.ts";

const PYTHON_SERVICE_URL = Deno.env.get("PYTHON_SERVICE_URL")!;

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const body = await req.json();
    const {
      sex,
      birth_date,
      height_cm,
      weight_kg,
      target_weight_kg,
      activity_level,
      goals,
      dietary_restrictions,
      cuisine_preferences,
    } = body;

    // Validation basique
    if (!sex || !birth_date || !height_cm || !weight_kg || !activity_level) {
      return err("Missing required health profile fields");
    }

    const admin = serviceClient();

    // 1. Upsert user_health_profile
    const { error: healthError } = await admin
      .from("user_health_profile")
      .upsert({
        user_id: user.id,
        sex,
        birth_date,
        height_cm,
        weight_kg,
        target_weight_kg,
        activity_level,
      });
    if (healthError) throw healthError;

    // 2. Remplacer les goals
    await admin.from("user_goal").delete().eq("user_id", user.id);
    if (goals?.length) {
      await admin.from("user_goal").insert(
        goals.map((goal_type: string) => ({ user_id: user.id, goal_type, is_active: true })),
      );
    }

    // 3. Remplacer les restrictions alimentaires
    await admin.from("user_dietary_restriction").delete().eq("user_id", user.id);
    if (dietary_restrictions?.length) {
      await admin.from("user_dietary_restriction").insert(
        dietary_restrictions.map((restriction: string) => ({ user_id: user.id, restriction })),
      );
    }

    // 4. Remplacer les préférences culinaires
    // cuisine_preferences est une liste de codes region (strings)
    await admin.from("user_cuisine_preference").delete().eq("user_id", user.id);
    if (cuisine_preferences?.length) {
      await admin.from("user_cuisine_preference").insert(
        (cuisine_preferences as string[]).map((region) => ({
          user_id: user.id,
          region,
          preference_score: 1.0,
        })),
      );
    }

    // 5. Mettre à jour le profil utilisateur (display_name + onboarding terminé)
    await admin
      .from("user_profile")
      .update({
        display_name: body.display_name ?? null,
        onboarding_done: true,
      })
      .eq("id", user.id);

    // 6. Déclencher le calcul du premier user_vector (non bloquant)
    // Exception runtime ADR-001 : appelé une seule fois à l'onboarding
    fetch(`${PYTHON_SERVICE_URL}/compute-user-vector`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ user_id: user.id }),
    }).catch((e) => console.error("[complete-onboarding] Python vector error:", e));

    return ok({ message: "Onboarding completed", user_id: user.id });
  } catch (e) {
    return serverError(e);
  }
});
