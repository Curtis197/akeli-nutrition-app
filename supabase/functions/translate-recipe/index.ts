import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    );

    const { recipe_id, target_language } = await req.json();

    if (!recipe_id || !target_language) {
      throw new Error('Missing required parameters: recipe_id and target_language');
    }

    // Validate language code
    const validLanguages = ['fr', 'en', 'es', 'pt', 'wo', 'bm', 'ln'];
    if (!validLanguages.includes(target_language)) {
      throw new Error(`Invalid language code. Must be one of: ${validLanguages.join(', ')}`);
    }

    // Fetch the original recipe
    const { data: recipe, error: recipeError } = await supabaseClient
      .from('recipe')
      .select('*')
      .eq('id', recipe_id)
      .single();

    if (recipeError || !recipe) {
      throw new Error('Recipe not found');
    }

    // Check if translation already exists
    const { data: existingTranslation } = await supabaseClient
      .from('recipe_translation')
      .select('*')
      .eq('recipe_id', recipe_id)
      .eq('language_code', target_language)
      .single();

    if (existingTranslation) {
      return new Response(
        JSON.stringify({
          success: true,
          data: existingTranslation,
          message: 'Translation already exists',
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Use OpenAI or other translation service for AI-powered translation
    const openAIApiKey = Deno.env.get('OPENAI_API_KEY');
    
    let translatedTitle = recipe.title;
    let translatedDescription = recipe.description;
    let translatedInstructions = recipe.instructions;

    if (openAIApiKey && target_language !== recipe.language) {
      // Call OpenAI for translation
      const translationPromises = [
        translateWithAI(recipe.title, target_language, openAIApiKey),
        recipe.description ? translateWithAI(recipe.description, target_language, openAIApiKey) : Promise.resolve(null),
        translateWithAI(recipe.instructions, target_language, openAIApiKey),
      ];

      const [titleResult, descResult, instructionsResult] = await Promise.all(translationPromises);

      translatedTitle = titleResult;
      translatedDescription = descResult;
      translatedInstructions = instructionsResult;
    } else {
      // Fallback: simple placeholder (in production, always use AI or professional translation)
      // For now, we'll just mark as machine translated with original text
      console.log('No OpenAI key available, using fallback');
    }

    // Save the translation to database
    const { data: savedTranslation, error: saveError } = await supabaseClient
      .from('recipe_translation')
      .insert({
        recipe_id,
        language_code: target_language,
        title: translatedTitle,
        description: translatedDescription,
        instructions: translatedInstructions,
        is_machine_translated: !!openAIApiKey,
      })
      .select()
      .single();

    if (saveError) {
      throw new Error(`Failed to save translation: ${saveError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: savedTranslation,
        message: 'Translation created successfully',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in translate-recipe:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});

async function translateWithAI(
  text: string, 
  targetLanguage: string, 
  apiKey: string
): Promise<string> {
  const languageNames: Record<string, string> = {
    'fr': 'French',
    'en': 'English',
    'es': 'Spanish',
    'pt': 'Portuguese',
    'wo': 'Wolof',
    'bm': 'Bambara',
    'ln': 'Lingala',
  };

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: `You are a professional translator. Translate the following culinary text to ${languageNames[targetLanguage] || targetLanguage}. Maintain the formatting, measurements, and technical terms. Return only the translation, no explanations.`,
        },
        {
          role: 'user',
          content: text,
        },
      ],
      temperature: 0.3,
      max_tokens: 2000,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.statusText}`);
  }

  const data = await response.json();
  return data.choices[0].message.content.trim();
}
