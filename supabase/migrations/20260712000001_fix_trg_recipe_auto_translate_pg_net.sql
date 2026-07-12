-- Fix trg_recipe_auto_translate: it referenced the pg_net extension via the
-- wrong schema (pg_net.http_post — pg_net's functions actually live in the
-- `net` schema) and a GUC (app.supabase_functions_url) that was never set on
-- this project. Both raised errors on every recipe publish, so translation
-- silently never fired. Match the working pattern already used by the cron
-- jobs (see 20260602000004_register_meal_reminder_cron.sql): net.http_post
-- with a hardcoded project URL.

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

    PERFORM net.http_post(
      url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/translate-recipe',
      headers := jsonb_build_object(
        'Content-Type',      'application/json',
        'x-internal-secret', v_secret
      ),
      body    := jsonb_build_object('recipe_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$;
