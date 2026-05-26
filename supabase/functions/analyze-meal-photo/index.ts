import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { handleCors } from '../_shared/cors.ts';
import { ok, err, unauthorized, serverError } from '../_shared/response.ts';
import { getAuthUser } from '../_shared/supabase.ts';
import { createLogger } from '../_shared/logger.ts';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!;
const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

const SYSTEM_PROMPT =
  `Tu es un expert en nutrition africaine et internationale.
Analyse le repas décrit ou photographié et retourne UNIQUEMENT un objet JSON valide.
Utilise des noms de repas en français.
Estime les valeurs pour UNE portion standard si la quantité n'est pas précisée.

Format attendu:
{
  "meal_name": string,
  "calories": number,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number,
  "confidence": "high" | "medium" | "low"
}

"confidence" = "high" si le repas est clairement identifiable, "medium" si tu estimes, "low" si incertain.
Retourne uniquement le JSON, sans markdown ni commentaires.`;

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const logger = createLogger('analyze-meal-photo');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info('⚡ ENTRY | method: ' + req.method);

  try {
    const { user } = await getAuthUser(req);
    if (!user) {
      logger.warn('EARLY RETURN | reason: unauthorized');
      return unauthorized();
    }
    logger.setUserId(user.id);
    logger.info('👤 Auth verified | userId: ' + user.id);

    logger.debug('[STEP 1] Parse request body');
    const body = await req.json();
    const { description, image_base64, image_mime_type } = body;

    if (!description && !image_base64) {
      logger.warn('EARLY RETURN | reason: missing description and image');
      return err('description or image required');
    }

    logger.debug('[STEP 2] Build Gemini parts | hasDescription: ' + !!description + ' | hasImage: ' + !!image_base64 + ' | mimeType: ' + (image_mime_type ?? 'none'));

    const parts: unknown[] = [];
    if (image_base64 && image_mime_type) {
      parts.push({ inlineData: { mimeType: image_mime_type, data: image_base64 } });
    }
    if (description) {
      parts.push({ text: description });
    }
    parts.push({ text: SYSTEM_PROMPT });

    logger.debug('[STEP 3] Calling Gemini 1.5 Flash');
    const geminiRes = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts }],
        generationConfig: { responseMimeType: 'application/json' },
      }),
    });

    if (!geminiRes.ok) {
      const errorText = await geminiRes.text();
      logger.error('Gemini API error | status: ' + geminiRes.status, { body: errorText.slice(0, 200) });
      return serverError(new Error('Gemini API request failed'));
    }

    const geminiData = await geminiRes.json();
    const textResult = geminiData.candidates?.[0]?.content?.parts?.[0]?.text as string | undefined;

    if (!textResult) {
      logger.warn('EARLY RETURN | reason: Gemini returned empty candidate');
      return err('AI analysis failed — invalid response', 422);
    }

    logger.debug('[STEP 4] Parse Gemini JSON response');
    let parsedResult: Record<string, unknown>;
    try {
      parsedResult = JSON.parse(textResult.trim());
    } catch {
      logger.warn('EARLY RETURN | reason: Gemini response not valid JSON | raw: ' + textResult.slice(0, 100));
      return err('AI analysis failed — invalid response', 422);
    }

    logger.info('✅ EXIT | status: 200 | confidence: ' + parsedResult.confidence + ' | duration: ' + (Date.now() - start) + 'ms');
    return ok(parsedResult);

  } catch (e) {
    logger.error('💥 Unhandled error', { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
