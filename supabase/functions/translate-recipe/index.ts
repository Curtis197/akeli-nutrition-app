import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { verifyInternalSecret, serviceClient } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

function roundTo(val: number, step: number): number {
  return Math.round(val / step) * step;
}

function convertToImperial(qty: number, unit: string): { quantity: number; unit: string } {
  const u = unit.toLowerCase().trim();
  switch (u) {
    case "g":
      if (qty < 500) {
        return { quantity: roundTo(qty / 28.3495, 0.25), unit: "oz" };
      } else {
        return { quantity: roundTo(qty / 453.592, 0.25), unit: "lb" };
      }
    case "kg":
      return { quantity: roundTo(qty * 2.20462, 0.25), unit: "lb" };
    case "ml":
      if (qty < 15) {
        return { quantity: roundTo(qty / 5.0, 0.25), unit: "tsp" };
      } else if (qty < 60) {
        return { quantity: roundTo(qty / 15.0, 0.5), unit: "tbsp" };
      } else {
        return { quantity: roundTo(qty / 29.5735, 0.5), unit: "fl_oz" };
      }
    case "l":
      if (qty > 0.5) {
        return { quantity: roundTo(qty * 4.227, 0.25), unit: "cup" };
      } else {
        return { quantity: roundTo(qty * 33.814, 0.5), unit: "fl_oz" };
      }
    default:
      return { quantity: qty, unit };
  }
}

async function translateText(content: string, sourceLang: string, targetLang: string): Promise<string> {
  if (!content || content.trim() === "") return "";
  
  const functionsUrl = Deno.env.get("SUPABASE_URL") + "/functions/v1";
  const internalSecret = Deno.env.get("INTERNAL_SECRET")!;
  
  const res = await fetch(`${functionsUrl}/translate-content`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-internal-secret": internalSecret,
    },
    body: JSON.stringify({
      content,
      source_language: sourceLang,
      target_language: targetLang,
    }),
  });
  
  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Failed to translate content via translate-content function: ${errText}`);
  }
  
  const json = await res.json();
  if (json.error) {
    throw new Error(`translate-content returned error: ${json.error}`);
  }
  return json.data.translation;
}

serve(async (req) => {
  const logger = createLogger("translate-recipe");
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info("⚡ ENTRY | method: " + req.method);

  try {
    logger.debug("[STEP 1] Verify internal secret");
    if (!verifyInternalSecret(req)) {
      logger.warn("EARLY RETURN | reason: invalid internal secret");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    logger.debug("[STEP 2] Parse body");
    const body = await req.json();
    const { recipe_id } = body;
    logger.debug("[STEP 2] Body parsed", { recipe_id });

    if (!recipe_id) {
      logger.warn("EARLY RETURN | reason: missing recipe_id");
      return err("recipe_id is required");
    }

    const client = serviceClient();

    // 1. Fetch recipe: title, description, recipe_step[], recipe_ingredient[]
    logger.debug("[STEP 3] Fetching recipe data");
    logRLSCheck(logger, "recipe", "SELECT", "service_role");
    const { data: recipe, error: recipeError } = await client
      .from("recipe")
      .select(`
        id,
        title,
        description,
        steps:recipe_step(id, content, title),
        ingredients:recipe_ingredient(id, quantity, unit, is_section_header, title)
      `)
      .eq("id", recipe_id)
      .maybeSingle();

    logQueryResult(logger, "recipe", "SELECT", recipe ? 1 : 0, recipeError ?? undefined);

    if (recipeError) throw recipeError;
    if (!recipe) {
      logger.warn("EARLY RETURN | reason: recipe not found");
      return err("Recipe not found");
    }

    // 2. Translate recipe title + description to 'en' and save for 'en' and 'en-US'
    logger.debug("[STEP 4] Translating recipe metadata to 'en'");
    let translatedTitle = recipe.title;
    let translatedDescription = recipe.description;

    try {
      if (recipe.title) {
        translatedTitle = await translateText(recipe.title, "fr", "en");
      }
      if (recipe.description) {
        translatedDescription = await translateText(recipe.description, "fr", "en");
      }

      for (const targetLocale of ["en", "en-US"]) {
        logRLSCheck(logger, "recipe_translation", "SELECT", "service_role");
        const { data: existingTrans, error: checkError } = await client
          .from("recipe_translation")
          .select("id")
          .eq("recipe_id", recipe_id)
          .eq("locale", targetLocale)
          .maybeSingle();
        
        logQueryResult(logger, "recipe_translation", "SELECT", existingTrans ? 1 : 0, checkError ?? undefined);

        if (existingTrans) {
          logger.debug(`Updating existing recipe translation for ${targetLocale}`);
          logRLSCheck(logger, "recipe_translation", "UPDATE", "service_role");
          const { error: updateError } = await client
            .from("recipe_translation")
            .update({
              title: translatedTitle,
              description: translatedDescription,
              updated_at: new Date().toISOString(),
            })
            .eq("id", existingTrans.id);
          logQueryResult(logger, "recipe_translation", "UPDATE", updateError ? 0 : 1, updateError ?? undefined);
          if (updateError) throw updateError;
        } else {
          logger.debug(`Inserting new recipe translation for ${targetLocale}`);
          logRLSCheck(logger, "recipe_translation", "INSERT", "service_role");
          const { error: insertError } = await client
            .from("recipe_translation")
            .insert({
              recipe_id,
              locale: targetLocale,
              title: translatedTitle,
              description: translatedDescription,
              is_auto: true,
            });
          logQueryResult(logger, "recipe_translation", "INSERT", insertError ? 0 : 1, insertError ?? undefined);
          if (insertError) throw insertError;
        }
      }
    } catch (e) {
      logger.error("Error during step 4 (metadata translation)", { message: e.message, stack: e.stack });
    }

    // 3. For each step with locale 'en' and 'en-US': translate content
    logger.debug("[STEP 5] Translating step contents to 'en' and 'en-US'");
    if (recipe.steps && recipe.steps.length > 0) {
      for (const step of recipe.steps) {
        try {
          const transContent = step.content ? await translateText(step.content, "fr", "en") : "";
          const transTitle = step.title ? await translateText(step.title, "fr", "en") : null;

          for (const targetLocale of ["en", "en-US"]) {
            logRLSCheck(logger, "recipe_step_translation", "SELECT", "service_role");
            const { data: existingStepTrans, error: checkError } = await client
              .from("recipe_step_translation")
              .select("id")
              .eq("step_id", step.id)
              .eq("locale", targetLocale)
              .maybeSingle();
            
            logQueryResult(logger, "recipe_step_translation", "SELECT", existingStepTrans ? 1 : 0, checkError ?? undefined);

            if (existingStepTrans) {
              logRLSCheck(logger, "recipe_step_translation", "UPDATE", "service_role");
              const { error: updateError } = await client
                .from("recipe_step_translation")
                .update({
                  content: transContent,
                  title: transTitle,
                  updated_at: new Date().toISOString(),
                })
                .eq("id", existingStepTrans.id);
              logQueryResult(logger, "recipe_step_translation", "UPDATE", updateError ? 0 : 1, updateError ?? undefined);
            } else {
              logRLSCheck(logger, "recipe_step_translation", "INSERT", "service_role");
              const { error: insertError } = await client
                .from("recipe_step_translation")
                .insert({
                  step_id: step.id,
                  locale: targetLocale,
                  content: transContent,
                  title: transTitle,
                });
              logQueryResult(logger, "recipe_step_translation", "INSERT", insertError ? 0 : 1, insertError ?? undefined);
            }
          }
        } catch (e) {
          logger.error(`Error during step 5 for step ${step.id}`, { message: e.message, stack: e.stack });
        }
      }
    }

    // 4. For each ingredient row:
    logger.debug("[STEP 6] Processing ingredient translations/conversions for 'en-US'");
    if (recipe.ingredients && recipe.ingredients.length > 0) {
      for (const ing of recipe.ingredients) {
        try {
          logRLSCheck(logger, "recipe_ingredient_translation", "SELECT", "service_role");
          const { data: existingIngTrans, error: checkError } = await client
            .from("recipe_ingredient_translation")
            .select("id, title")
            .eq("recipe_ingredient_id", ing.id)
            .eq("locale", "en-US")
            .maybeSingle();

          logQueryResult(logger, "recipe_ingredient_translation", "SELECT", existingIngTrans ? 1 : 0, checkError ?? undefined);

          if (ing.is_section_header) {
            const transTitle = ing.title ? await translateText(ing.title, "fr", "en") : null;
            if (existingIngTrans) {
              logRLSCheck(logger, "recipe_ingredient_translation", "UPDATE", "service_role");
              const { error: updateError } = await client
                .from("recipe_ingredient_translation")
                .update({
                  title: transTitle,
                  quantity: null,
                  unit: null,
                  updated_at: new Date().toISOString(),
                })
                .eq("id", existingIngTrans.id);
              logQueryResult(logger, "recipe_ingredient_translation", "UPDATE", updateError ? 0 : 1, updateError ?? undefined);
            } else {
              logRLSCheck(logger, "recipe_ingredient_translation", "INSERT", "service_role");
              const { error: insertError } = await client
                .from("recipe_ingredient_translation")
                .insert({
                  recipe_ingredient_id: ing.id,
                  locale: "en-US",
                  title: transTitle,
                  quantity: null,
                  unit: null,
                });
              logQueryResult(logger, "recipe_ingredient_translation", "INSERT", insertError ? 0 : 1, insertError ?? undefined);
            }
          } else {
            // For non-section header ingredients, if a row already exists, skip it (preserves creator authored en-US values)
            if (!existingIngTrans) {
              const qtyNum = ing.quantity !== null ? Number(ing.quantity) : 0;
              const converted = convertToImperial(qtyNum, ing.unit || "");
              
              logRLSCheck(logger, "recipe_ingredient_translation", "INSERT", "service_role");
              const { error: insertError } = await client
                .from("recipe_ingredient_translation")
                .insert({
                  recipe_ingredient_id: ing.id,
                  locale: "en-US",
                  title: null,
                  quantity: converted.quantity,
                  unit: converted.unit,
                });
              logQueryResult(logger, "recipe_ingredient_translation", "INSERT", insertError ? 0 : 1, insertError ?? undefined);
            } else {
              logger.info(`Preserved existing en-US translation/conversion for ingredient: ${ing.id}`);
            }
          }
        } catch (e) {
          logger.error(`Error during step 6 for ingredient ${ing.id}`, { message: e.message, stack: e.stack });
        }
      }
    }

    logger.info("✅ EXIT | status: 200 | duration: " + (Date.now() - start) + "ms");
    return ok({ success: true });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
