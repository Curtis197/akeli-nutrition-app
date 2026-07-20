import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';
import { ok, err, serverError } from '../_shared/response.ts';

serve(async (req) => {
  const logger = createLogger('process-media-upload');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info('⚡ ENTRY | method: ' + req.method);

  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    logger.debug('[STEP 1] Parsing request body');
    const { step_id, ingredient_id, media_type, file_name, content_type } = await req.json();

    if (!media_type || !file_name) {
      logger.warn('EARLY RETURN | reason: missing media_type or file_name');
      return err('media_type and file_name are required');
    }

    if (!step_id && !ingredient_id) {
      logger.warn('EARLY RETURN | reason: missing step_id and ingredient_id');
      return err('Either step_id or ingredient_id must be provided');
    }

    logger.debug('[STEP 2] Determining bucket | step_id: ' + (step_id ?? 'none') + ' | ingredient_id: ' + (ingredient_id ?? 'none'));

    let bucket: string;
    let folder: string;

    if (ingredient_id) {
      if (media_type !== 'image') {
        logger.warn('EARLY RETURN | reason: non-image media for ingredient');
        return err('Only images are supported for ingredients');
      }
      bucket = 'ingredient-images';
      folder = 'ingredients';
    } else {
      if (!['image', 'video'].includes(media_type)) {
        logger.warn('EARLY RETURN | reason: invalid media_type | value: ' + media_type);
        return err("media_type must be 'image' or 'video'");
      }
      bucket = 'recipe-step-media';
      folder = 'steps';
    }

    const file_extension = file_name.split('.').pop() || 'jpg';
    const unique_id = crypto.randomUUID();
    const file_path = `${folder}/${unique_id}.${file_extension}`;
    logger.debug('[STEP 3] Generated file_path: ' + file_path);

    logger.debug('[STEP 4] Creating signed upload URL');
    const { data: signData, error: signError } = await supabaseClient.storage
      .from(bucket)
      .createSignedUploadUrl(file_path, 300);

    if (signError || !signData) {
      logger.error('Failed to create signed URL | ' + signError?.message);
      return serverError(signError ?? new Error('Failed to create upload URL'));
    }

    const publicUrl = `${Deno.env.get('SUPABASE_URL')}/storage/v1/object/public/${bucket}/${file_path}`;
    let mediaId: string | null = null;

    if (step_id) {
      logger.debug('[STEP 5] Fetching existing media order for step_id: ' + step_id);
      logRLSCheck(logger, 'recipe_step_media', 'SELECT', 'service_role');
      const { data: existingMedia, error: orderError } = await supabaseClient
        .from('recipe_step_media')
        .select('display_order')
        .eq('step_id', step_id)
        .order('display_order', { ascending: false })
        .limit(1);
      logQueryResult(logger, 'recipe_step_media', 'SELECT', existingMedia?.length ?? 0, orderError ?? undefined);

      const next_order = existingMedia && existingMedia.length > 0
        ? existingMedia[0].display_order + 1
        : 0;

      mediaId = crypto.randomUUID();
      const mediaRecord = {
        id: mediaId,
        step_id,
        media_type,
        media_url: publicUrl,
        thumbnail_url: null,
        display_order: next_order,
        is_primary: next_order === 0,
      };

      logger.debug('[STEP 6] Inserting recipe_step_media record');
      logRLSCheck(logger, 'recipe_step_media', 'INSERT', 'service_role');
      const { error: dbError } = await supabaseClient
        .from('recipe_step_media')
        .insert(mediaRecord);
      logQueryResult(logger, 'recipe_step_media', 'INSERT', dbError ? 0 : 1, dbError ?? undefined);

      if (dbError) {
        logger.error('Failed to insert media record | ' + dbError.message);
        return serverError(dbError);
      }
    }

    logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
    return ok({
      upload_url: signData.signedUrl,
      file_path,
      media_id: mediaId,
      media_url: step_id ? publicUrl : null,
    });
  } catch (e) {
    logger.error('💥 Unhandled error', { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
