import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const { recipe_id } = await req.json();
    if (!recipe_id) return err("recipe_id is required");

    // Vérifier si le like existe déjà
    const { data: existing } = await client
      .from("recipe_like")
      .select("user_id")
      .eq("user_id", user.id)
      .eq("recipe_id", recipe_id)
      .maybeSingle();

    if (existing) {
      // Unlike
      await client
        .from("recipe_like")
        .delete()
        .eq("user_id", user.id)
        .eq("recipe_id", recipe_id);
      return ok({ liked: false });
    } else {
      // Like
      await client
        .from("recipe_like")
        .insert({ user_id: user.id, recipe_id });
      return ok({ liked: true });
    }
  } catch (e) {
    return serverError(e);
  }
});
