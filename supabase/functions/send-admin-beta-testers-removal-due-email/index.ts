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

type TesterInput = { id?: unknown; email?: unknown; platform?: unknown; confirmedAt?: unknown };

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

    const { testers } = await req.json();

    if (!Array.isArray(testers) || testers.length === 0) {
      return new Response(JSON.stringify({ data: null, error: 'Missing or empty field: testers' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const rows: { email: string; platform: string; confirmedAt: string }[] = [];
    for (const t of testers as TesterInput[]) {
      if (typeof t.email !== 'string' || (t.platform !== 'ios' && t.platform !== 'android') || typeof t.confirmedAt !== 'string') {
        return new Response(JSON.stringify({ data: null, error: 'Each tester needs email, platform and confirmedAt' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
      rows.push({ email: t.email, platform: t.platform, confirmedAt: t.confirmedAt });
    }

    const resendApiKey = Deno.env.get('RESEND_API_KEY');
    if (!resendApiKey) {
      console.warn('[send-admin-beta-testers-removal-due-email] RESEND_API_KEY missing, skipping send');
      return new Response(JSON.stringify({ data: { sent: false, warning: 'Resend API key missing' }, error: null }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const resend = new Resend(resendApiKey);

    const tableRows = rows
      .map(
        (r) =>
          `<tr><td style="padding:4px 12px 4px 0;color:#888">${escapeHtml(r.email)}</td><td>${
            r.platform === 'ios' ? 'iPhone' : 'Android'
          }</td><td>${escapeHtml(r.confirmedAt)}</td></tr>`
      )
      .join('');

    const html = `
      <h2>${rows.length} beta tester(s) due for removal</h2>
      <p>These testers passed their 7-day window. Remove them from the TestFlight/Play tester list, then mark them removed in the dashboard.</p>
      <table><tr><th align="left">Email</th><th align="left">Platform</th><th align="left">Confirmed</th></tr>${tableRows}</table>
      <p style="margin-top:24px"><a href="${BETA_TESTERS_URL}" style="background:#e85d26;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block;font-weight:bold">Open dashboard</a></p>
    `;

    const { data: resendData, error: resendError } = await resend.emails.send({
      from: 'Akeli <no-reply@a-keli.com>',
      to: ADMIN_EMAIL,
      subject: `⏰ ${rows.length} beta tester(s) due for removal`,
      html,
    });

    if (resendError) {
      console.error('[send-admin-beta-testers-removal-due-email] resend rejected the send:', resendError);
      return new Response(JSON.stringify({ data: { sent: false }, error: resendError.message ?? 'Resend rejected the send' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('[send-admin-beta-testers-removal-due-email] sent', { count: rows.length, resendId: resendData?.id, at: new Date().toISOString() });

    return new Response(JSON.stringify({ data: { sent: true, resendId: resendData?.id }, error: null }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('[send-admin-beta-testers-removal-due-email] error:', err);
    return new Response(JSON.stringify({ data: null, error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
