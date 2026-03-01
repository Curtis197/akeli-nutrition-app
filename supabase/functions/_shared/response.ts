import { corsHeaders } from "./cors.ts";

export function ok(data: unknown, status = 200): Response {
  return new Response(JSON.stringify({ data, error: null }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function err(message: string, status = 400): Response {
  return new Response(JSON.stringify({ data: null, error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function unauthorized(): Response {
  return err("Unauthorized", 401);
}

export function serverError(e: unknown): Response {
  const message = e instanceof Error ? e.message : "Internal server error";
  console.error("[ERROR]", message);
  return err(message, 500);
}
