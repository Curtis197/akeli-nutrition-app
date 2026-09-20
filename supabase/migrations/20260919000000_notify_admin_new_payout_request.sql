-- Admin alert when a creator requests a manual payout, mirroring the
-- notify_admin_new_support_message template (vault-stored INTERNAL_SECRET +
-- net.http_post to a Resend-backed edge function).
--
-- Fires only for pending rows without Stripe ids: those are creator requests
-- created by the website's /api/payouts/request route. Stripe-originated
-- payout rows and admin-recorded processing/completed rows must not alert.

create or replace function public.notify_admin_new_payout_request()
returns trigger
language plpgsql
security definer
as $$
declare
  v_secret text;
  v_creator_name text;
begin
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'INTERNAL_SECRET'
  limit 1;

  if v_secret is null then
    raise warning 'notify_admin_new_payout_request: vault secret "INTERNAL_SECRET" missing; skipping admin email';
    return new;
  end if;

  select display_name into v_creator_name from public.creator where id = new.creator_id;

  perform net.http_post(
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-admin-new-payout-request-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-internal-secret', v_secret
    ),
    body    := jsonb_build_object(
      'payoutId', new.id,
      'creatorName', v_creator_name,
      'amount', new.amount
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_admin_new_payout_request on public.payout;
create trigger trg_notify_admin_new_payout_request
  after insert on public.payout
  for each row
  when (new.status = 'pending' and new.stripe_payout_id is null and new.stripe_transfer_id is null)
  execute function public.notify_admin_new_payout_request();
