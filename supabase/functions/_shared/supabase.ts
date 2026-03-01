import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Client authentifié par le JWT de l'utilisateur (RLS actif)
export function userClient(authHeader: string) {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
}

// Client service — bypass RLS, réservé aux cron + webhooks internes
export function serviceClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
    auth: { persistSession: false },
  });
}

// Vérifie le JWT et retourne l'utilisateur, ou null si invalide
export async function getAuthUser(req: Request) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return { user: null, client: null };

  const client = userClient(authHeader);
  const { data: { user }, error } = await client.auth.getUser();
  if (error || !user) return { user: null, client: null };

  return { user, client };
}
