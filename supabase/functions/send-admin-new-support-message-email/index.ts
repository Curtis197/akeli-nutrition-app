import { Resend } from 'https://esm.sh/resend';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ADMIN_EMAIL = 'curtiscapre@gmail.com';
const SUPPORT_URL = 'https://akeli-admin-dashboard.vercel.app/support';

function escapeHtml(value: unknown): string {
  if (value === null || value === undefined) return '';
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// Only http(s) URLs become links; anything else (javascript:, data:, malformed) is dropped.
function screenshotLink(raw: unknown): string {
  if (typeof raw !== 'string' || !raw) return '';
  try {
    const url = new URL(raw);
    if (url.protocol !== 'https:' && url.protocol !== 'http:') return '';
    return `<a href="${escapeHtml(url.href)}">View screenshot</a>`;
  } catch {
    return '';
  }
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

    const { email, subject, content, screenshotUrl } = await req.json();

    if (!email || typeof email !== 'string') {
      return new Response(JSON.stringify({ data: null, error: 'Missing required field: email' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const resendApiKey = Deno.env.get('RESEND_API_KEY');
    if (!resendApiKey) {
      console.warn('[send-admin-new-support-message-email] RESEND_API_KEY missing, skipping send');
      return new Response(JSON.stringify({ data: { sent: false, warning: 'Resend API key missing' }, error: null }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const resend = new Resend(resendApiKey);
    const rows = [
      ['From', escapeHtml(email)],
      ['Subject', escapeHtml(subject)],
      ['Message', escapeHtml(content)],
      ['Screenshot', screenshotLink(screenshotUrl)],
    ]
      .filter(([, value]) => value)
      .map(([label, value]) => `<tr><td style="padding:4px 12px 4px 0;color:#888">${label}</td><td>${value}</td></tr>`)
      .join('');

    const html = `
      <h2>New support message</h2>
      <p>Someone submitted a support request from the app.</p>
      <table>${rows}</table>
      <p style="margin-top:24px"><a href="${SUPPORT_URL}" style="background:#e85d26;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block;font-weight:bold">View in support inbox</a></p>
    `;

    const { data: resendData, error: resendError } = await resend.emails.send({
      from: 'Akeli <no-reply@a-keli.com>',
      to: ADMIN_EMAIL,
      subject: `📩 New support message${subject ? `: "${subject}"` : ''}`,
      html,
    });

    if (resendError) {
      console.error('[send-admin-new-support-message-email] resend rejected the send:', resendError);
      return new Response(JSON.stringify({ data: { sent: false }, error: resendError.message ?? 'Resend rejected the send' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('[send-admin-new-support-message-email] sent', { email, resendId: resendData?.id, at: new Date().toISOString() });

    return new Response(JSON.stringify({ data: { sent: true, resendId: resendData?.id }, error: null }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('[send-admin-new-support-message-email] error:', err);
    return new Response(JSON.stringify({ data: null, error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
