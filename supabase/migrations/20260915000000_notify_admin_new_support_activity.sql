-- Admin-alert triggers for the support pipeline, mirroring the existing
-- notify_admin_new_ingredient_submission / notify_admin_new_recipe / notify_admin_new_user
-- pattern (vault-stored INTERNAL_SECRET + net.http_post to a Resend-backed edge function).
--
-- Before this migration, neither support_message inserts nor messages sent into a
-- creator's auto-created 'support' conversation notified anyone — admins had to
-- manually poll the admin dashboard's /support page.

create or replace function public.notify_admin_new_support_message()
returns trigger
language plpgsql
security definer
as $$
declare
  v_secret text;
begin
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'INTERNAL_SECRET'
  limit 1;

  if v_secret is null then
    raise warning 'notify_admin_new_support_message: vault secret "INTERNAL_SECRET" missing; skipping admin email';
    return new;
  end if;

  perform net.http_post(
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-admin-new-support-message-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-internal-secret', v_secret
    ),
    body    := jsonb_build_object(
      'email', new.email,
      'subject', new.subject,
      'content', new.content,
      'screenshotUrl', new.screenshot_url
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_admin_new_support_message on public.support_message;
create trigger trg_notify_admin_new_support_message
  after insert on public.support_message
  for each row execute function public.notify_admin_new_support_message();


create or replace function public.notify_admin_new_support_chat_message()
returns trigger
language plpgsql
security definer
as $$
declare
  v_secret text;
  v_conv_type text;
  v_sender_name text;
begin
  select type into v_conv_type from conversation where id = new.conversation_id;

  if v_conv_type is distinct from 'support' then
    return new;
  end if;

  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'INTERNAL_SECRET'
  limit 1;

  if v_secret is null then
    raise warning 'notify_admin_new_support_chat_message: vault secret "INTERNAL_SECRET" missing; skipping admin email';
    return new;
  end if;

  select nullif(trim(coalesce(first_name, '') || ' ' || coalesce(last_name, '')), '')
    into v_sender_name
    from user_profile where id = new.sender_id;

  if v_sender_name is null then
    select username into v_sender_name from user_profile where id = new.sender_id;
  end if;

  perform net.http_post(
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-admin-new-support-chat-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-internal-secret', v_secret
    ),
    body    := jsonb_build_object(
      'conversationId', new.conversation_id,
      'senderName', v_sender_name,
      'content', new.content
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_admin_new_support_chat_message on public.chat_message;
create trigger trg_notify_admin_new_support_chat_message
  after insert on public.chat_message
  for each row execute function public.notify_admin_new_support_chat_message();
