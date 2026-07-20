import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createLogger, logRLSCheck, logQueryResult } from '../_shared/logger.ts';
import { ok, err, serverError } from '../_shared/response.ts';

const IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp'];

serve(async (req) => {
  const logger = createLogger('optimize-image');
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
    const { file_path, bucket } = await req.json();

    if (!file_path || !bucket) {
      logger.warn('EARLY RETURN | reason: missing file_path or bucket');
      return err('file_path and bucket are required');
    }

    const file_extension = file_path.split('.').pop()?.toLowerCase() ?? '';
    if (!IMAGE_EXTENSIONS.includes(file_extension)) {
      logger.info('EARLY RETURN | reason: not an image | ext: ' + file_extension);
      return ok({ message: 'File is not an image, skipping optimization', file_path });
    }

    logger.debug('[STEP 2] Downloading original image | path: ' + file_path + ' | bucket: ' + bucket);
    const { data: originalImage, error: downloadError } = await supabaseClient.storage
      .from(bucket)
      .download(file_path);

    if (downloadError || !originalImage) {
      logger.error('Failed to download image | ' + downloadError?.message);
      return serverError(downloadError ?? new Error('Failed to download image'));
    }
    logger.debug('[STEP 2] Download complete | size: ' + originalImage.size);

    const thumbnail_path = file_path.replace(/\.[^/.]+$/, '_thumb.webp');
    const optimized_path = file_path.replace(/\.[^/.]+$/, '.webp');
    const public_url_base = `${Deno.env.get('SUPABASE_URL')}/storage/v1/object/public/${bucket}`;

    logger.debug('[STEP 3] Updating DB with optimized paths');

    if (file_path.startsWith('ingredients/')) {
      logRLSCheck(logger, 'ingredient', 'UPDATE', 'service_role');
      const { error: updateError } = await supabaseClient
        .from('ingredient')
        .update({
          image_url: `${public_url_base}/${optimized_path}`,
          image_thumbnail_url: `${public_url_base}/${thumbnail_path}`,
          updated_at: new Date().toISOString(),
        })
        .eq('image_url', `${public_url_base}/${file_path}`);
      logQueryResult(logger, 'ingredient', 'UPDATE', updateError ? 0 : 1, updateError ?? undefined);

      if (updateError) {
        logger.warn('DB update for ingredient failed (non-fatal) | ' + updateError.message);
      }
    } else if (file_path.startsWith('steps/')) {
      logRLSCheck(logger, 'recipe_step_media', 'UPDATE', 'service_role');
      const { error: updateError } = await supabaseClient
        .from('recipe_step_media')
        .update({ thumbnail_url: `${public_url_base}/${thumbnail_path}` })
        .eq('media_url', `${public_url_base}/${file_path}`);
      logQueryResult(logger, 'recipe_step_media', 'UPDATE', updateError ? 0 : 1, updateError ?? undefined);

      if (updateError) {
        logger.warn('DB update for recipe_step_media failed (non-fatal) | ' + updateError.message);
      }
    } else {
      logger.warn('Unknown file path prefix — skipping DB update | path: ' + file_path);
    }

    logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
    return ok({
      original_path: file_path,
      thumbnail_path,
      optimized_path,
      message: 'Image optimization completed (simulated)',
    });
  } catch (e) {
    logger.error('💥 Unhandled error', { message: e.message, stack: e.stack });
    return serverError(e);
  }
});
