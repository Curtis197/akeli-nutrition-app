// Architecture hybride Fast Path / Smart Path
// Ref: V1_AI_ASSISTANT_ARCHITECTURE.md
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const OPENAI_URL = "https://api.openai.com/v1/chat/completions";
const MODEL = "gpt-4o-mini";
const MAX_HISTORY = 5;
const RATE_LIMIT_PER_MINUTE = 30;

// ---- Fast path patterns ----
const FAST_PATTERNS = [
  /^(salut|hey|bonjour|bonsoir|coucou|hello|hi)\b/i,
  /^(merci|thanks|thank you|super|ok|okay|d'acc|nickel|parfait|génial|cool)\b/i,
  /^(oui|non|yes|no|yep|nope)\b/i,
  /^(au revoir|bye|à bientôt|à plus|ciao)\b/i,
];

function isFastPath(message: string): boolean {
  return FAST_PATTERNS.some((p) => p.test(message.trim()));
}

// ---- Prompt système Akeli ----
const SYSTEM_PROMPT = `Tu es Akeli, un assistant nutritionnel bienveillant et expert.
Tu aides les utilisateurs à atteindre leurs objectifs santé à travers des recettes adaptées à leur culture et leurs goûts.
Tu es chaleureux, encourageant et précis. Tu réponds en français par défaut, dans la langue de l'utilisateur sinon.
Tu ne modifies pas les meal plans directement (feature V2) — tu informes et conseilles uniquement.
Sois concis (max 200 mots), naturel et pertinent. Utilise les données fournies dans le contexte.`;

// ---- Appel OpenAI ----
async function callOpenAI(messages: unknown[], maxTokens = 800): Promise<string> {
  const res = await fetch(OPENAI_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: MODEL,
      messages,
      max_tokens: maxTokens,
      temperature: 0.7,
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`OpenAI error: ${errText}`);
  }

  const json = await res.json();
  return json.choices[0].message.content as string;
}

// ---- Analyse d'intention ----
async function analyzeIntention(message: string, userName: string): Promise<{
  needs_data: boolean;
  data_modules: string[];
}> {
  const intentPrompt = `Analyze this user message and determine which data modules are needed.
User: ${userName}
Message: "${message}"

Return JSON only:
{
  "needs_data": boolean,
  "data_modules": [] // subset of: ["user_profile","meal_plan","nutrition_stats","recipes_favorites","shopping_list","habits"]
}`;

  const response = await callOpenAI([
    { role: "system", content: intentPrompt },
  ], 200);

  try {
    const cleaned = response.replace(/```json\n?|\n?```/g, "").trim();
    return JSON.parse(cleaned);
  } catch {
    return { needs_data: false, data_modules: [] };
  }
}

// ---- Fetch des modules de données ----
async function fetchModules(
  modules: string[],
  userId: string,
  // deno-lint-ignore no-explicit-any
  client: any,
): Promise<Record<string, unknown>> {
  const result: Record<string, unknown> = {};
  const today = new Date().toISOString().split("T")[0];

  await Promise.all(modules.map(async (mod) => {
    try {
      switch (mod) {
        case "user_profile": {
          const { data } = await client
            .from("user_health_profile")
            .select("sex, birth_date, weight_kg, target_weight_kg, activity_level")
            .eq("user_id", userId)
            .single();
          const { data: goals } = await client
            .from("user_goal")
            .select("goal_type")
            .eq("user_id", userId)
            .eq("is_active", true);
          result["user_profile"] = { ...data, goals: goals?.map((g: { goal_type: string }) => g.goal_type) };
          break;
        }
        case "meal_plan": {
          const { data: plan } = await client
            .from("meal_plan")
            .select("id")
            .eq("user_id", userId)
            .eq("is_active", true)
            .single();
          if (plan) {
            const { data: entries } = await client
              .from("meal_plan_entry")
              .select("meal_type, scheduled_date, is_consumed, recipe:recipe(title, recipe_macro(calories, protein_g, carbs_g, fat_g))")
              .eq("meal_plan_id", plan.id)
              .eq("scheduled_date", today);
            result["meal_plan"] = { date: today, meals: entries };
          }
          break;
        }
        case "nutrition_stats": {
          const { data } = await client
            .from("daily_nutrition_log")
            .select("calories, protein_g, carbs_g, fat_g, meals_count")
            .eq("user_id", userId)
            .eq("log_date", today)
            .single();
          result["nutrition_stats"] = data;
          break;
        }
        case "recipes_favorites": {
          const { data } = await client
            .from("recipe_like")
            .select("recipe:recipe(id, title, recipe_macro(calories))")
            .eq("user_id", userId)
            .limit(10);
          result["recipes_favorites"] = data?.map((r: { recipe: unknown }) => r.recipe);
          break;
        }
        case "shopping_list": {
          const { data: list } = await client
            .from("shopping_list")
            .select("id, generated_at")
            .eq("user_id", userId)
            .order("generated_at", { ascending: false })
            .limit(1)
            .single();
          if (list) {
            const { data: items } = await client
              .from("shopping_list_item")
              .select("quantity, unit, is_checked, ingredient:ingredient(name_fr)")
              .eq("shopping_list_id", list.id);
            result["shopping_list"] = { ...list, items };
          }
          break;
        }
        case "habits": {
          const { data } = await client
            .from("daily_nutrition_log")
            .select("log_date, meals_count")
            .eq("user_id", userId)
            .order("log_date", { ascending: false })
            .limit(30);
          const tracked = data?.filter((d: { meals_count: number }) => d.meals_count > 0).length ?? 0;
          result["habits"] = {
            days_tracked_last_30: tracked,
            avg_meals_per_day: tracked > 0
              ? (data?.reduce((acc: number, d: { meals_count: number }) => acc + d.meals_count, 0) ?? 0) / tracked
              : 0,
          };
          break;
        }
      }
    } catch {
      // Module optionnel — on continue sans
    }
  }));

  return result;
}

// ---- Builder de contexte ----
function buildContext(userName: string, data: Record<string, unknown>): string {
  const parts = [`Utilisateur: ${userName}`];

  if (data.user_profile) {
    const p = data.user_profile as Record<string, unknown>;
    parts.push(`Profil: poids ${p.weight_kg}kg, objectif ${p.target_weight_kg}kg, goals: ${(p.goals as string[])?.join(", ")}`);
  }
  if (data.nutrition_stats) {
    const n = data.nutrition_stats as Record<string, number>;
    parts.push(`Nutrition aujourd'hui: ${n.calories} kcal, ${n.protein_g}g protéines, ${n.carbs_g}g glucides, ${n.fat_g}g lipides`);
  }
  if (data.meal_plan) {
    const mp = data.meal_plan as { meals: Array<{ meal_type: string; is_consumed: boolean; recipe: { title: string; recipe_macro: { calories: number } } }> };
    const meals = mp.meals?.map((m) =>
      `${m.meal_type}: ${m.recipe?.title} (${m.recipe?.recipe_macro?.calories} kcal)${m.is_consumed ? " ✓" : ""}`
    );
    parts.push(`Plan du jour: ${meals?.join(" | ")}`);
  }
  if (data.shopping_list) {
    const sl = data.shopping_list as { items: Array<{ ingredient: { name_fr: string }; is_checked: boolean }> };
    const unchecked = sl.items?.filter((i) => !i.is_checked).length;
    parts.push(`Liste de courses: ${unchecked} articles restants`);
  }

  return parts.join("\n");
}

// ---- Handler principal ----
serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const startMs = Date.now();

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const body = await req.json();
    let { message, conversation_id } = body;

    // Validation
    message = (message ?? "").trim();
    if (!message || message.length === 0) return err("Message cannot be empty");
    if (message.length > 2000) return err("Message too long (max 2000 characters)");
    message = message.replace(/[<>]/g, "").slice(0, 2000);

    // Rate limit: 30 messages / minute
    const oneMinuteAgo = new Date(Date.now() - 60_000).toISOString();
    const { count: recentCount } = await client
      .from("ai_message")
      .select("id", { count: "exact" })
      .eq("conversation_id", conversation_id ?? "00000000-0000-0000-0000-000000000000")
      .gte("sent_at", oneMinuteAgo);

    if ((recentCount ?? 0) >= RATE_LIMIT_PER_MINUTE) {
      return err("Rate limit exceeded. Max 30 messages per minute.", 429);
    }

    // Créer ou charger la conversation
    if (!conversation_id) {
      const { data: conv } = await client
        .from("ai_conversation")
        .insert({ user_id: user.id })
        .select()
        .single();
      conversation_id = conv?.id;
    }

    // Charger le prénom
    const { data: profile } = await client
      .from("user_profile")
      .select("first_name")
      .eq("id", user.id)
      .single();
    const userName = profile?.first_name ?? "toi";

    // Historique de conversation (5 derniers messages)
    const { data: history } = await client
      .from("ai_message")
      .select("role, content")
      .eq("conversation_id", conversation_id)
      .order("sent_at", { ascending: false })
      .limit(MAX_HISTORY);

    const historyMessages = (history ?? []).reverse().map((m: { role: string; content: string }) => ({
      role: m.role,
      content: m.content,
    }));

    let response: string;
    let pathType: "fast" | "smart";
    let tokensUsed = 0;
    let modulesData: Record<string, unknown> = {};

    if (isFastPath(message)) {
      // ---- FAST PATH ----
      pathType = "fast";
      const messages = [
        { role: "system", content: SYSTEM_PROMPT },
        ...historyMessages,
        { role: "user", content: message },
      ];
      response = await callOpenAI(messages, 400);
      tokensUsed = Math.ceil(response.length / 4);
    } else {
      // ---- SMART PATH ----
      pathType = "smart";

      // Phase 1: Analyse d'intention
      const intention = await analyzeIntention(message, userName);

      // Phase 2: Fetch conditionnel des données
      if (intention.needs_data && intention.data_modules.length > 0) {
        modulesData = await fetchModules(intention.data_modules, user.id, client);
      }

      // Phase 3: Construire le contexte
      const contextStr = buildContext(userName, modulesData);

      // Phase 4: Générer la réponse enrichie
      const messages = [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "system", content: `Contexte utilisateur:\n${contextStr}` },
        ...historyMessages,
        { role: "user", content: message },
      ];
      response = await callOpenAI(messages, 800);
      tokensUsed = Math.ceil((contextStr.length + response.length) / 4);
    }

    // Persister les messages
    await client.from("ai_message").insert([
      {
        conversation_id,
        role: "user",
        content: message,
        sent_at: new Date().toISOString(),
      },
      {
        conversation_id,
        role: "assistant",
        content: response,
        tokens_used: tokensUsed,
        sent_at: new Date().toISOString(),
      },
    ]);

    // Mettre à jour updated_at de la conversation
    await client
      .from("ai_conversation")
      .update({ updated_at: new Date().toISOString() })
      .eq("id", conversation_id);

    return ok({
      response,
      conversation_id,
      tokens_used: tokensUsed,
      path_type: pathType,
      processing_time_ms: Date.now() - startMs,
    });
  } catch (e) {
    return serverError(e);
  }
});
