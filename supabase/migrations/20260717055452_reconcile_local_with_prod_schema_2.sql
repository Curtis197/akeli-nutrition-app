drop view if exists "public"."creator_dashboard_stats";

drop view if exists "public"."creator_public_profile";

drop view if exists "public"."recipe_performance_summary";

set check_function_bodies = off;

create or replace view "public"."creator_dashboard_stats" as  SELECT id AS creator_id,
    display_name,
    username,
    recipe_count,
    fan_count,
    total_revenue,
    (recipe_count >= 30) AS is_fan_eligible,
    COALESCE(( SELECT sum(creator_revenue_log.amount) AS sum
           FROM public.creator_revenue_log
          WHERE ((creator_revenue_log.creator_id = c.id) AND (date_trunc('month'::text, (creator_revenue_log.logged_at)::timestamp with time zone) = date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))), (0)::numeric) AS revenue_current_month,
    COALESCE(( SELECT sum(creator_revenue_log.amount) AS sum
           FROM public.creator_revenue_log
          WHERE ((creator_revenue_log.creator_id = c.id) AND (date_trunc('month'::text, (creator_revenue_log.logged_at)::timestamp with time zone) = date_trunc('month'::text, (CURRENT_DATE - '1 mon'::interval))))), (0)::numeric) AS revenue_last_month,
    COALESCE(( SELECT count(mc.id) AS count
           FROM (public.meal_consumption mc
             JOIN public.recipe r ON ((mc.recipe_id = r.id)))
          WHERE ((r.creator_id = c.id) AND (date_trunc('month'::text, mc.consumed_at) = date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))), (0)::bigint) AS consumptions_current_month,
    (30 - (COALESCE(( SELECT count(mc.id) AS count
           FROM (public.meal_consumption mc
             JOIN public.recipe r ON ((mc.recipe_id = r.id)))
          WHERE ((r.creator_id = c.id) AND (date_trunc('month'::text, mc.consumed_at) = date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))), (0)::bigint) % (30)::bigint)) AS consumptions_to_next_euro
   FROM public.creator c;


create or replace view "public"."creator_public_profile" as  SELECT id,
    username,
    display_name,
    bio,
    profile_image_url,
    specialty_codes,
    language_codes,
    instagram_handle,
    tiktok_handle,
    youtube_handle,
    website_url,
    recipe_count,
    fan_count,
    total_revenue,
    created_at,
    (recipe_count >= 30) AS is_fan_eligible
   FROM public.creator c
  WHERE (username IS NOT NULL);


create or replace view "public"."recipe_performance_summary" as  SELECT r.id AS recipe_id,
    r.creator_id,
    r.title,
    r.cover_image_url,
    r.is_published,
    r.created_at AS published_at,
    count(DISTINCT mc.id) AS total_consumptions,
    count(DISTINCT mc.user_id) AS unique_users,
    COALESCE(sum(crl.amount), (0)::numeric) AS total_revenue,
    count(DISTINCT mc.id) FILTER (WHERE (date_trunc('month'::text, mc.consumed_at) = date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))) AS consumptions_this_month,
    COALESCE(sum(crl.amount) FILTER (WHERE (date_trunc('month'::text, (crl.logged_at)::timestamp with time zone) = date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))), (0)::numeric) AS revenue_this_month,
    count(DISTINCT mc.id) FILTER (WHERE (date_trunc('month'::text, mc.consumed_at) = date_trunc('month'::text, (CURRENT_DATE - '1 mon'::interval)))) AS consumptions_last_month
   FROM ((public.recipe r
     LEFT JOIN public.meal_consumption mc ON ((mc.recipe_id = r.id)))
     LEFT JOIN public.creator_revenue_log crl ON ((crl.recipe_id = r.id)))
  GROUP BY r.id, r.creator_id, r.title, r.cover_image_url, r.is_published, r.created_at;


CREATE OR REPLACE FUNCTION public.update_creator_fan_count()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE creator SET fan_count = (
    SELECT COUNT(*) FROM fan_subscription
    WHERE creator_id = NEW.creator_id AND status = 'active'
  ) WHERE id = NEW.creator_id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN 
  NEW.updated_at = now();
  RETURN NEW; 
END;
$function$
;


