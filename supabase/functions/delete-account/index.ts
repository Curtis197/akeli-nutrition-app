import { createLogger } from '../_shared/logger.ts';
import { getAuthUser, serviceClient } from '../_shared/supabase.ts';
import { ok, unauthorized, serverError } from '../_shared/response.ts';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const logger = createLogger('delete-account');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  const start = Date.now();
  logger.info('⚡ ENTRY | method: ' + req.method);

  try {
    const { user } = await getAuthUser(req);
    if (!user) {
      logger.warn('EARLY RETURN | reason: unauthenticated');
      return unauthorized();
    }

    logger.setUserId(user.id);
    logger.info('👤 Auth verified | userId: ' + user.id);

    logger.debug('[STEP 1] Deleting user via admin client | userId: ' + user.id);
    const admin = serviceClient();
    const { error } = await admin.auth.admin.deleteUser(user.id);

    if (error) {
      logger.error('❌ Failed to delete user', { message: error.message });
      return serverError(error);
    }

    logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
    return ok({ deleted: true });
  } catch (e) {
    logger.error('💥 Unhandled error', { message: (e as Error).message, stack: (e as Error).stack });
    return serverError(e);
  }
});
