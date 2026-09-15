import { Resend } from 'https://esm.sh/resend';
import { createLogger } from '../_shared/logger.ts';
import { getAuthUser, serviceClient } from '../_shared/supabase.ts';
import { ok, unauthorized, serverError } from '../_shared/response.ts';
import { corsHeaders } from '../_shared/cors.ts';

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

async function sendGoodbyeEmail(
  email: string,
  firstName: string | null,
  locale: string | null,
  logger: ReturnType<typeof createLogger>,
) {
  const resendApiKey = Deno.env.get('RESEND_API_KEY');
  if (!resendApiKey) {
    logger.warn('RESEND_API_KEY missing, skipping goodbye email');
    return;
  }

  const resend = new Resend(resendApiKey);
  const isFr = locale !== 'en';
  const greetingName = firstName ? `, ${escapeHtml(firstName)}` : '';
  const subject = isFr ? 'Votre compte Akeli a été supprimé' : 'Your Akeli account has been deleted';

  const html = isFr
    ? `
      <h2>Au revoir${greetingName}</h2>
      <p>Votre compte Akeli et toutes les données associées ont été définitivement supprimés, comme demandé.</p>
      <p style="color:#888;font-size:12px;margin-top:32px">Si vous n'êtes pas à l'origine de cette suppression, contactez-nous immédiatement à contact@a-keli.com.</p>
    `
    : `
      <h2>Goodbye${greetingName}</h2>
      <p>Your Akeli account and all associated data have been permanently deleted, as requested.</p>
      <p style="color:#888;font-size:12px;margin-top:32px">If you didn't request this, contact us immediately at contact@a-keli.com.</p>
    `;

  const { data, error } = await resend.emails.send({
    from: 'Akeli <no-reply@a-keli.com>',
    to: email,
    subject,
    html,
  });

  if (error) {
    logger.error('Failed to send goodbye email', { message: error.message });
    return;
  }

  logger.info('Goodbye email sent', { resendId: data?.id });
}

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

    const admin = serviceClient();

    // Fetch the profile before deleting — user_profile cascades from auth.users
    // on delete, so this data is gone the moment deleteUser() succeeds.
    logger.debug('[STEP 1] Fetching profile for goodbye email | userId: ' + user.id);
    const { data: profile } = await admin
      .from('user_profile')
      .select('first_name, locale')
      .eq('id', user.id)
      .maybeSingle();

    logger.debug('[STEP 2] Deleting user via admin client | userId: ' + user.id);
    const { error } = await admin.auth.admin.deleteUser(user.id);

    if (error) {
      logger.error('❌ Failed to delete user', { message: error.message });
      return serverError(error);
    }

    // Best-effort: the account is already gone, so a failed send here
    // never blocks or rolls back a deletion that already succeeded.
    if (user.email) {
      await sendGoodbyeEmail(user.email, profile?.first_name ?? null, profile?.locale ?? null, logger);
    }

    logger.info('✅ EXIT | status: 200 | duration: ' + (Date.now() - start) + 'ms');
    return ok({ deleted: true });
  } catch (e) {
    logger.error('💥 Unhandled error', { message: (e as Error).message, stack: (e as Error).stack });
    return serverError(e);
  }
});
