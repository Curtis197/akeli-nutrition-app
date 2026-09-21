import { Resend } from 'https://esm.sh/resend';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function escapeHtml(value: unknown): string {
  if (value === null || value === undefined) return '';
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const providedSecret = req.headers.get('x-internal-secret');
    const internalSecret = Deno.env.get('INTERNAL_SECRET');
    if (!internalSecret || providedSecret !== internalSecret) {
      return new Response(JSON.stringify({ data: null, error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { email, locale, firstName, ingredientName, reason } = await req.json();

    if (!email || typeof email !== 'string') {
      return new Response(JSON.stringify({ data: null, error: 'Missing required field: email' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!ingredientName || typeof ingredientName !== 'string') {
      return new Response(JSON.stringify({ data: null, error: 'Missing required field: ingredientName' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!reason || typeof reason !== 'string') {
      return new Response(JSON.stringify({ data: null, error: 'Missing required field: reason' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const resendApiKey = Deno.env.get('RESEND_API_KEY');
    if (!resendApiKey) {
      console.warn('[send-ingredient-rejected-email] RESEND_API_KEY missing, skipping send');
      return new Response(JSON.stringify({ data: { sent: false, warning: 'Resend API key missing' }, error: null }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const resend = new Resend(resendApiKey);
    const isFr = locale !== 'en';
    const greetingName = firstName ? `, ${escapeHtml(firstName)}` : '';
    const safeIngredient = escapeHtml(ingredientName);
    const safeReason = escapeHtml(reason);
    // The subject is plain text, not HTML, so it keeps the raw name.
    const subject = isFr ? `"${ingredientName}" n'a pas été retenu` : `"${ingredientName}" was not approved`;

    const html = isFr
      ? `
        <h2>Bonjour${greetingName},</h2>
        <p>L'ingrédient que vous avez proposé, <strong>${safeIngredient}</strong>, n'a pas été retenu par l'équipe Akeli.</p>
        <p><strong>Raison :</strong> ${safeReason}</p>
        <p>Vous pouvez le soumettre à nouveau une fois corrigé.</p>
        <p style="color:#888;font-size:12px;margin-top:32px">Ouvrez l'application Akeli pour continuer.</p>
      `
      : `
        <h2>Hello${greetingName},</h2>
        <p>The ingredient you submitted, <strong>${safeIngredient}</strong>, was not approved by the Akeli team.</p>
        <p><strong>Reason:</strong> ${safeReason}</p>
        <p>You can submit it again once it's been corrected.</p>
        <p style="color:#888;font-size:12px;margin-top:32px">Open the Akeli app to continue.</p>
      `;

    const { data: resendData, error: resendError } = await resend.emails.send({
      from: 'Akeli <no-reply@a-keli.com>',
      to: email,
      subject,
      html,
    });

    if (resendError) {
      console.error('[send-ingredient-rejected-email] resend rejected the send:', resendError);
      return new Response(JSON.stringify({ data: { sent: false }, error: resendError.message ?? 'Resend rejected the send' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('[send-ingredient-rejected-email] sent', { email, ingredientName, resendId: resendData?.id, at: new Date().toISOString() });

    return new Response(JSON.stringify({ data: { sent: true, resendId: resendData?.id }, error: null }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('[send-ingredient-rejected-email] error:', err);
    return new Response(JSON.stringify({ data: null, error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
