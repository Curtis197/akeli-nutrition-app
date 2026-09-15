// supabase/functions/visitor-reset-password/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import * as bcrypt from 'https://esm.sh/bcryptjs';
import { Resend } from 'https://esm.sh/resend';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function sha256(input: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(input));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function sendPasswordChangedEmail(email: string, locale: string | null) {
  const resendApiKey = Deno.env.get('RESEND_API_KEY');
  if (!resendApiKey) {
    console.warn('[visitor-reset-password] RESEND_API_KEY missing, skipping confirmation email');
    return;
  }

  const resend = new Resend(resendApiKey);
  const isFr = locale !== 'en';
  const subject = isFr ? 'Votre mot de passe a été modifié' : 'Your password has been changed';

  const html = isFr
    ? `
      <h2>Mot de passe modifié</h2>
      <p>Le mot de passe de votre compte Akeli vient d'être modifié avec succès.</p>
      <p style="color:#888;font-size:12px;margin-top:32px">Si vous n'êtes pas à l'origine de cette modification, contactez-nous immédiatement à contact@a-keli.com.</p>
    `
    : `
      <h2>Password changed</h2>
      <p>The password for your Akeli account was just changed successfully.</p>
      <p style="color:#888;font-size:12px;margin-top:32px">If you didn't make this change, contact us immediately at contact@a-keli.com.</p>
    `;

  const { data, error } = await resend.emails.send({
    from: 'Akeli <no-reply@a-keli.com>',
    to: email,
    subject,
    html,
  });

  if (error) {
    console.error('[visitor-reset-password] failed to send confirmation email:', error);
    return;
  }

  console.log('[visitor-reset-password] confirmation email sent', { resendId: data?.id });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { token, visitor_id, new_password } = await req.json();

    if (!token || !visitor_id || !new_password || new_password.length < 8) {
      return new Response(JSON.stringify({ data: null, error: 'token, visitor_id, and new_password (min 8 chars) required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const token_hash = await sha256(token);

    const [{ data: tokenRow, error: tokenError }, { data: visitor }] = await Promise.all([
      supabase
        .from('visitor_auth_token')
        .select('id, expires_at, used_at')
        .eq('visitor_id', visitor_id)
        .eq('token_hash', token_hash)
        .eq('purpose', 'reset_password')
        .maybeSingle(),
      supabase.from('visitor').select('email, locale').eq('id', visitor_id).maybeSingle(),
    ]);

    if (tokenError || !tokenRow) {
      return new Response(JSON.stringify({ data: null, error: 'Invalid or expired reset token' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (tokenRow.used_at) {
      return new Response(JSON.stringify({ data: null, error: 'Token already used' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (new Date(tokenRow.expires_at) < new Date()) {
      return new Response(JSON.stringify({ data: null, error: 'Token expired' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Hash new password and update
    const password_hash = await bcrypt.hash(new_password, 10);

    const [tokenUpdate, visitorUpdate] = await Promise.all([
      supabase.from('visitor_auth_token').update({ used_at: new Date().toISOString() }).eq('id', tokenRow.id),
      supabase.from('visitor').update({ password_hash }).eq('id', visitor_id),
    ]);

    if (tokenUpdate.error || visitorUpdate.error) {
      throw new Error(`Failed to reset password: ${tokenUpdate.error?.message || visitorUpdate.error?.message}`);
    }

    // Best-effort: the password is already changed, so a failed send here
    // never blocks or rolls back a reset that already succeeded.
    if (visitor?.email) {
      await sendPasswordChangedEmail(visitor.email, visitor.locale ?? null);
    }

    return new Response(JSON.stringify({ data: { reset: true }, error: null }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('[visitor-reset-password] error:', err);
    return new Response(JSON.stringify({ data: null, error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
