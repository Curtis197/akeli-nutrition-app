// Traduit du contenu culinaire via Gemini (langues africaines)
// Appel interne uniquement — pas exposé directement à l'app
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";

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

serve(async (req) => {
  try {
    const body = await req.json();
    const { content, source_language, target_language } = body;

    if (!content || !source_language || !target_language) {
      return err("content, source_language, and target_language are required");
    }

    const sourceName = LANGUAGE_NAMES[source_language] ?? source_language;
    const targetName = LANGUAGE_NAMES[target_language] ?? target_language;

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

    return ok({
      original: content,
      translation,
      source_language,
      target_language,
    });
  } catch (e) {
    return serverError(e);
  }
});
