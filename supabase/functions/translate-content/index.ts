// Traduit du contenu culinaire via Gemini (langues africaines)
// Appel interne uniquement — pas exposé directement à l'app
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { verifyInternalSecret } from "../_shared/supabase.ts";
import { createLogger, logRLSCheck, logQueryResult } from "../_shared/logger.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")!;
const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

const LANGUAGE_NAMES: Record<string, string> = {
  wo: "Wolof",
  bm: "Bambara",
  ln: "Lingala",
  ar: "Arabic",
  fr: "French",
  en: "English",
  es: "Spanish",
  pt: "Portuguese",
};

const MAX_CONTENT_LENGTH = 5000;

serve(async (req) => {
  const logger = createLogger("translate-content");
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
    const { content, source_language, target_language } = body;
    logger.debug("[STEP 2] Body parsed", { source_language, target_language, content_length: content?.length ?? 0 });

    if (!content || !source_language || !target_language) {
      logger.warn("EARLY RETURN | reason: missing required fields | content: " + !!content + " | source_language: " + !!source_language + " | target_language: " + !!target_language);
      return err("content, source_language, and target_language are required");
    }

    if (content.length > MAX_CONTENT_LENGTH) {
      logger.warn("EARLY RETURN | reason: content too long | length: " + content.length + " | max: " + MAX_CONTENT_LENGTH);
      return err(`content must be ${MAX_CONTENT_LENGTH} characters or fewer`);
    }

    const sourceName = LANGUAGE_NAMES[source_language] ?? source_language;
    const targetName = LANGUAGE_NAMES[target_language] ?? target_language;

    logger.debug("[STEP 3] Calling Gemini | " + sourceName + " → " + targetName + " | content_length: " + content.length);

    const prompt = `You are a professional culinary translator specializing in African languages and food culture.
Translate the following culinary content from ${sourceName} to ${targetName}.
Preserve the meaning, cultural context, and food-specific terminology accurately.
Return ONLY the translated text, nothing else.

Content to translate:
${content}`;

    const geminiRes = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 1024 },
      }),
    });

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      throw new Error(`Gemini error: ${errText}`);
    }

    const geminiData = await geminiRes.json();
    const translation = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!translation) throw new Error("Empty translation response from Gemini");

    logger.debug("Gemini response received | translation_length: " + (translation?.length ?? 0));

    logger.info("✅ EXIT | status: 200 | source_language: " + source_language + " | target_language: " + target_language + " | translation_length: " + (translation?.length ?? 0) + " | duration: " + (Date.now() - start) + "ms");
    return ok({
      original: content,
      translation,
      source_language,
      target_language,
    });
  } catch (e) {
    logger.error("💥 Unhandled error", { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
