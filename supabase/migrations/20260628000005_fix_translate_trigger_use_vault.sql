-- Fix: trg_recipe_auto_translate was reading the internal secret from
-- current_setting('app.internal_secret') — a DB-level setting that is less
-- secure than Vault because it can be read by any superuser query against
-- pg_settings.  Use the same Vault pattern as the cron functions instead.

CREATE OR REPLACE FUNCTION public.trg_recipe_auto_translate()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_secret text;
BEGIN
  IF OLD.is_published = false AND NEW.is_published = true THEN
    SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets
    WHERE name = 'INTERNAL_SECRET'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_secret IS NULL OR v_secret = '' THEN
      RAISE WARNING 'trg_recipe_auto_translate: INTERNAL_SECRET not in vault — translation skipped for recipe %', NEW.id;
      RETURN NEW;
    END IF;

    PERFORM pg_net.http_post(
      url     := current_setting('app.supabase_functions_url') || '/translate-recipe',
      headers := jsonb_build_object(
        'Content-Type',      'application/json',
        'x-internal-secret', v_secret
      ),
      body    := jsonb_build_object('recipe_id', NEW.id)::text
    );
  END IF;
  RETURN NEW;
END;
$$;
