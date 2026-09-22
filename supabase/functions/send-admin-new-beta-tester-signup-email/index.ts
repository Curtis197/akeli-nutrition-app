import { Resend } from 'https://esm.sh/resend';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ADMIN_EMAIL = 'curtiscapre@gmail.com';
const BETA_TESTERS_URL = 'https://akeli-admin-dashboard.vercel.app/beta-testers';

function escapeHtml(value: string): string {
  return value
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

    const { testerId, email, platform } = await req.json();

    if (!testerId || typeof testerId !== 'string') {
      return new Response(JSON.stringify({ data: null, error: 'Missing required field: testerId' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!email || typeof email !== 'string') {
      return new Response(JSON.stringify({ data: null, error: 'Missing required field: email' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (platform !== 'ios' && platform !== 'android') {
      return new Response(JSON.stringify({ data: null, error: 'Missing or invalid field: platform' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const resendApiKey = Deno.env.get('RESEND_API_KEY');
    if (!resendApiKey) {
      console.warn('[send-admin-new-beta-tester-signup-email] RESEND_API_KEY missing, skipping send');
      return new Response(JSON.stringify({ data: { sent: false, warning: 'Resend API key missing' }, error: null }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const resend = new Resend(resendApiKey);
    const safeEmail = escapeHtml(email);
    const platformLabel = platform === 'ios' ? 'iPhone' : 'Android';

    const rows = [
      ['Email', safeEmail],
      ['Platform', platformLabel],
      ['Signed up', new Date().toUTCString()],
    ]
      .map(([label, value]) => `<tr><td style="padding:4px 12px 4px 0;color:#888">${label}</td><td>${value}</td></tr>`)
      .join('');

    const html = `
      <h2>New beta signup</h2>
      <p>Someone signed up for the beta test.</p>
      <table>${rows}</table>
      <p style="margin-top:24px"><a href="${BETA_TESTERS_URL}" style="background:#e85d26;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block;font-weight:bold">Review in dashboard</a></p>
    `;

    const { data: resendData, error: resendError } = await resend.emails.send({
      from: 'Akeli <no-reply@a-keli.com>',
      to: ADMIN_EMAIL,
      subject: `🧪 New beta signup: ${email} (${platformLabel})`,
      html,
    });

    if (resendError) {
      console.error('[send-admin-new-beta-tester-signup-email] resend rejected the send:', resendError);
      return new Response(JSON.stringify({ data: { sent: false }, error: resendError.message ?? 'Resend rejected the send' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('[send-admin-new-beta-tester-signup-email] sent', { testerId, resendId: resendData?.id, at: new Date().toISOString() });

    return new Response(JSON.stringify({ data: { sent: true, resendId: resendData?.id }, error: null }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('[send-admin-new-beta-tester-signup-email] error:', err);
    return new Response(JSON.stringify({ data: null, error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
