create extension if not exists "pg_cron" with schema "pg_catalog";

create extension if not exists "http" with schema "extensions";

create extension if not exists "pgtap" with schema "extensions";

drop trigger if exists "on_blog_post_published_newsletter" on "public"."blog_post";

drop trigger if exists "on_recipe_published_newsletter" on "public"."recipe";

alter table "public"."blog_post_like" drop constraint "blog_post_like_post_id_user_id_key";

alter table "public"."blog_post_like" drop constraint "blog_post_like_post_id_visitor_id_key";

alter table "public"."creator_monthly_payouts" drop constraint "creator_monthly_payouts_status_check";

drop view if exists "public"."creator_dashboard_stats";

drop view if exists "public"."creator_public_profile";

drop view if exists "public"."recipe_performance_summary";

drop index if exists "public"."blog_post_like_post_id_user_id_key";

drop index if exists "public"."blog_post_like_post_id_visitor_id_key";

alter table "public"."blog_post" add column "category" text;

alter table "public"."blog_post" add column "draft_data" jsonb;

alter table "public"."blog_post" add column "recipe_embeds" uuid[] default '{}'::uuid[];

alter table "public"."blog_post" add column "scheduled_publish_at" timestamp with time zone;

alter table "public"."blog_post" add column "tags" text[] default '{}'::text[];

alter table "public"."blog_post" add column "view_count" integer default 0;

alter table "public"."blog_post_translation" add column "excerpt" text;

alter table "public"."blog_post_translation" add column "reading_time_min" integer;

alter table "public"."blog_post_translation" add column "seo_description" text;

alter table "public"."blog_post_translation" add column "seo_title" text;

alter table "public"."creator_monthly_payouts" drop column "paid_at";

alter table "public"."creator_monthly_payouts" drop column "total_earnings_cents";

alter table "public"."creator_monthly_payouts" alter column "creator_id" set not null;

alter table "public"."creator_monthly_payouts" alter column "period_month" set not null;

alter table "public"."creator_monthly_payouts" alter column "status" set default 'pending'::character varying;

alter table "public"."creator_monthly_payouts" alter column "status" set data type character varying(20) using "status"::character varying(20);

CREATE UNIQUE INDEX blog_post_like_post_id_user_id_key ON public.blog_post_like USING btree (post_id, user_id) WHERE (user_id IS NOT NULL);

CREATE UNIQUE INDEX blog_post_like_post_id_visitor_id_key ON public.blog_post_like USING btree (post_id, visitor_id) WHERE (visitor_id IS NOT NULL);

alter table "public"."blog_post" add constraint "blog_post_category_check" CHECK ((category = ANY (ARRAY['recette'::text, 'culture'::text, 'technique'::text, 'ingredients'::text, 'parcours'::text, 'actualite'::text]))) not valid;

alter table "public"."blog_post" validate constraint "blog_post_category_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.can_read_blog_post(p_post_creator_id uuid, p_visibility text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    p_visibility = 'public'
    OR p_post_creator_id IN (SELECT id FROM public.creator WHERE user_id = auth.uid())
    OR (p_visibility = 'followers' AND p_post_creator_id IN (
          SELECT creator_id FROM public.creator_follow WHERE user_id = auth.uid() AND active = true))
    OR (p_visibility = 'fans' AND p_post_creator_id IN (
          SELECT creator_id FROM public.fan_subscription WHERE user_id = auth.uid() AND status = 'active'));
$function$
;

CREATE OR REPLACE FUNCTION public.get_blog_post_for_reader(p_creator_id uuid, p_slug text)
 RETURNS TABLE(id uuid, slug text, cover_image_url text, category text, tags text[], visibility text, published_at timestamp with time zone, view_count integer, recipe_embeds uuid[], creator_id uuid, creator_display_name text, can_read boolean, title text, content_json jsonb, excerpt text, seo_title text, seo_description text, reading_time_min integer, locale text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  WITH post AS (
    SELECT bp.*, c.display_name AS creator_display_name
    FROM public.blog_post bp
    JOIN public.creator c ON c.id = bp.creator_id
    WHERE bp.creator_id = p_creator_id
      AND bp.slug = p_slug
      AND bp.is_published = true
  ),
  access AS (
    SELECT public.can_read_blog_post(post.creator_id, post.visibility) AS can_read
    FROM post
  )
  SELECT
    post.id,
    post.slug,
    post.cover_image_url,
    post.category,
    post.tags,
    post.visibility,
    post.published_at,
    post.view_count,
    post.recipe_embeds,
    post.creator_id,
    post.creator_display_name,
    access.can_read,
    bpt.title,
    CASE WHEN access.can_read THEN bpt.content_json ELSE NULL END AS content_json,
    bpt.excerpt,
    bpt.seo_title,
    bpt.seo_description,
    bpt.reading_time_min,
    bpt.locale
  FROM post
  CROSS JOIN access
  JOIN LATERAL (
    SELECT * FROM public.blog_post_translation t
    WHERE t.post_id = post.id
    ORDER BY t.locale
    LIMIT 1
  ) bpt ON true;
$function$
;

CREATE OR REPLACE FUNCTION public.get_creator_blog_feed(p_creator_id uuid)
 RETURNS TABLE(id uuid, slug text, cover_image_url text, category text, published_at timestamp with time zone, visibility text, can_read boolean, title text, excerpt text, reading_time_min integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    bp.id,
    bp.slug,
    bp.cover_image_url,
    bp.category,
    bp.published_at,
    bp.visibility,
    access.can_read,
    bpt.title,
    CASE WHEN access.can_read THEN bpt.excerpt ELSE NULL END AS excerpt,
    CASE WHEN access.can_read THEN bpt.reading_time_min ELSE NULL END AS reading_time_min
  FROM public.blog_post bp
  JOIN LATERAL (
    SELECT * FROM public.blog_post_translation t
    WHERE t.post_id = bp.id
    ORDER BY t.locale
    LIMIT 1
  ) bpt ON true
  CROSS JOIN LATERAL (SELECT public.can_read_blog_post(bp.creator_id, bp.visibility) AS can_read) access
  WHERE bp.creator_id = p_creator_id
    AND bp.is_published = true
  ORDER BY bp.published_at DESC;
$function$
;

CREATE OR REPLACE FUNCTION public.increment_post_view(p_post_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.blog_post SET view_count = view_count + 1 WHERE id = p_post_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public._decrement_group_member_count()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE community_group SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.group_id;
  RETURN OLD;
END;
$function$
;

CREATE OR REPLACE FUNCTION public._get_user_conversation_ids(uid uuid)
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT conversation_id FROM conversation_participant WHERE user_id = uid;
$function$
;

CREATE OR REPLACE FUNCTION public._get_user_group_ids(uid uuid)
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
 SET row_security TO 'off'
AS $function$
  SELECT group_id FROM group_member WHERE user_id = uid;
$function$
;

CREATE OR REPLACE FUNCTION public._increment_group_member_count()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE community_group SET member_count = member_count + 1 WHERE id = NEW.group_id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.accept_group_invite(p_invite_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_invite RECORD;
  v_conversation_id uuid;
BEGIN
  SELECT * INTO v_invite
  FROM group_invite
  WHERE id = p_invite_id AND invitee_id = auth.uid() AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invite not found, already processed, or permission denied';
  END IF;

  UPDATE group_invite SET status = 'accepted' WHERE id = p_invite_id;

  INSERT INTO group_member(group_id, user_id, role)
  VALUES (v_invite.group_id, auth.uid(), 'member')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  SELECT id INTO v_conversation_id
  FROM conversation
  WHERE community_group_id = v_invite.group_id;

  IF v_conversation_id IS NOT NULL THEN
    INSERT INTO conversation_participant(conversation_id, user_id)
    VALUES (v_conversation_id, auth.uid())
    ON CONFLICT (conversation_id, user_id) DO NOTHING;
  END IF;

  RETURN v_invite.group_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_nutrition_targets(p_weight_kg numeric, p_height_cm numeric, p_age integer, p_sex text, p_activity_level text, p_primary_goal text, p_target_weight_kg numeric DEFAULT NULL::numeric, p_remaining_weeks integer DEFAULT NULL::integer, p_muscle_goal text DEFAULT NULL::text)
 RETURNS TABLE(bmr numeric, tdee numeric, calorie_goal integer, protein_g numeric, carb_g numeric, fat_g numeric, effective_pace_kg_week numeric, estimated_weeks_to_target numeric)
 LANGUAGE sql
 IMMUTABLE
AS $function$
WITH base AS (
  SELECT (10*p_weight_kg + 6.25*p_height_cm - 5*p_age
          + CASE WHEN p_sex = 'male' THEN 5 ELSE -161 END)::numeric AS bmr_c
  WHERE p_weight_kg BETWEEN 30 AND 300
    AND p_height_cm BETWEEN 120 AND 230
    AND p_age BETWEEN 18 AND 100
    AND p_sex IS NOT NULL
),
with_tdee AS (
  SELECT bmr_c,
         bmr_c * CASE p_activity_level
           WHEN 'sedentary'   THEN 1.2
           WHEN 'light'       THEN 1.375
           WHEN 'moderate'    THEN 1.55
           WHEN 'active'      THEN 1.725
           WHEN 'very_active' THEN 1.9
           ELSE 1.2
         END AS tdee_c
  FROM base
),
with_goal AS (
  SELECT *,
         CASE WHEN p_primary_goal IN ('weight_loss','muscle_gain')
              THEN p_primary_goal ELSE 'maintenance' END AS goal_c,
         (p_target_weight_kg - p_weight_kg) AS delta_c
  FROM with_tdee
),
with_pace AS (
  SELECT *,
         CASE
           WHEN goal_c = 'maintenance' THEN 0
           WHEN goal_c = 'weight_loss' THEN CASE
             WHEN p_target_weight_kg IS NOT NULL AND delta_c >= 0 THEN 0
             WHEN p_target_weight_kg IS NULL OR p_remaining_weeks IS NULL THEN 0.5
             ELSE LEAST(ABS(delta_c) / GREATEST(p_remaining_weeks, 1), 1.0)
           END
           ELSE CASE
             WHEN p_target_weight_kg IS NOT NULL AND delta_c <= 0 THEN 0
             WHEN p_target_weight_kg IS NULL OR p_remaining_weeks IS NULL THEN 0.25
             ELSE LEAST(ABS(delta_c) / GREATEST(p_remaining_weeks, 1), 0.5)
           END
         END AS pace_c
  FROM with_goal
),
with_cal AS (
  SELECT *,
         CASE goal_c
           WHEN 'weight_loss' THEN ROUND(GREATEST(tdee_c - pace_c*1100, bmr_c))::int
           WHEN 'muscle_gain' THEN ROUND(tdee_c + LEAST(pace_c*1100, 0.20*tdee_c))::int
           ELSE ROUND(tdee_c)::int
         END AS cal_c
  FROM with_pace
),
with_eff AS (
  SELECT *,
         CASE goal_c
           WHEN 'weight_loss' THEN (tdee_c - cal_c) / 1100.0
           WHEN 'muscle_gain' THEN (cal_c - tdee_c) / 1100.0
           ELSE 0
         END AS eff_c
  FROM with_cal
),
with_macros AS (
  -- Protein g/kg + fat % driven by p_muscle_goal, independent of goal_c
  -- (calorie direction). Reference weight for the g/kg dose still follows
  -- weight direction: dose against LEAST(current, target) only when
  -- goal_c = 'weight_loss' (standard practice — avoids inflated protein
  -- targets for heavier users cutting toward a lower goal weight).
  SELECT *,
         LEAST(
           (CASE WHEN goal_c = 'weight_loss'
                 THEN LEAST(p_weight_kg, COALESCE(p_target_weight_kg, p_weight_kg))
                 ELSE p_weight_kg
            END)
           * (CASE p_muscle_goal
                WHEN 'gain' THEN 2.2
                WHEN 'loss' THEN 1.2
                ELSE 1.6
              END),
           0.35 * cal_c / 4.0
         ) AS protein_c,
         (CASE p_muscle_goal
            WHEN 'gain' THEN 0.20
            WHEN 'loss' THEN 0.30
            ELSE 0.25
          END) * cal_c / 9.0 AS fat_c
  FROM with_eff
)
SELECT
  bmr_c,
  tdee_c,
  cal_c,
  ROUND(protein_c, 1),
  ROUND((cal_c - protein_c*4 - fat_c*9) / 4.0, 1),
  ROUND(fat_c, 1),
  ROUND(eff_c, 2),
  CASE
    WHEN goal_c = 'maintenance' OR p_target_weight_kg IS NULL OR pace_c = 0 OR eff_c <= 0 THEN NULL
    ELSE ROUND(ABS(delta_c) / eff_c, 1)
  END
FROM with_macros
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_recipe_macros(p_recipe_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_servings int;
  v_result   json;
BEGIN
  SELECT servings INTO v_servings FROM recipe WHERE id = p_recipe_id;
  IF v_servings IS NULL OR v_servings = 0 THEN
    v_servings := 1;
  END IF;

  SELECT json_build_object(
    'calories',                ROUND((SUM(sub.qty_grams / 100.0 * i.calories_per_100g) / v_servings)::numeric, 1),
    'protein_g',               ROUND((SUM(sub.qty_grams / 100.0 * i.protein_per_100g)  / v_servings)::numeric, 1),
    'carbs_g',                 ROUND((SUM(sub.qty_grams / 100.0 * i.carbs_per_100g)    / v_servings)::numeric, 1),
    'fat_g',                   ROUND((SUM(sub.qty_grams / 100.0 * i.fat_per_100g)      / v_servings)::numeric, 1),
    'ingredients_with_macros', COUNT(CASE WHEN i.calories_per_100g IS NOT NULL THEN 1 END),
    'ingredients_total',       COUNT(sub.id),
    'macros_complete',         BOOL_AND(i.calories_per_100g IS NOT NULL)
  )
  INTO v_result
  FROM (
    SELECT
      ri.id,
      ri.ingredient_id,
      ri.quantity * COALESCE(
        (SELECT uc.grams_equivalent FROM unit_conversion uc
         WHERE uc.unit = ri.unit AND uc.ingredient_id = ri.ingredient_id),
        (SELECT uc.grams_equivalent FROM unit_conversion uc
         WHERE uc.unit = ri.unit AND uc.ingredient_id IS NULL),
        1.0
      ) AS qty_grams
    FROM recipe_ingredient ri
    WHERE ri.recipe_id = p_recipe_id
      AND ri.is_section_header = false
  ) sub
  JOIN ingredient i ON i.id = sub.ingredient_id;

  RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_and_record_cleaner_call(p_creator_id uuid, p_limit integer DEFAULT 200, p_window_hours integer DEFAULT 24)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_count int;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.recipe_cleaner_call
  WHERE creator_id = p_creator_id
    AND called_at  > now() - (p_window_hours || ' hours')::interval;

  IF v_count >= p_limit THEN
    RETURN false;
  END IF;

  INSERT INTO public.recipe_cleaner_call (creator_id) VALUES (p_creator_id);
  RETURN true;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_visitor_email_not_akeli()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = NEW.email) THEN
    RAISE EXCEPTION 'email_belongs_to_akeli_user';
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.convert_ingredient_unit(p_ingredient_id uuid, p_quantity numeric, p_from_system text, p_to_system text)
 RETURNS TABLE(converted_quantity numeric, target_unit text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_metric_unit TEXT;
    v_us_unit TEXT;
    v_factor NUMERIC;
BEGIN
    -- Look up the rules for the specific ingredient
    SELECT default_metric_unit, default_us_unit, us_to_metric_factor
    INTO v_metric_unit, v_us_unit, v_factor
    FROM public.ingredient
    WHERE id = p_ingredient_id;

    -- If the ingredient hasn't been configured yet, fail gracefully
    IF v_factor IS NULL THEN
        RETURN QUERY SELECT p_quantity, 'unknown';
        RETURN;
    END IF;

    -- Do the conversion math
    IF p_from_system = 'us' AND p_to_system = 'metric' THEN
        RETURN QUERY SELECT ROUND(p_quantity * v_factor, 1), v_metric_unit;
    ELSIF p_from_system = 'metric' AND p_to_system = 'us' THEN
        RETURN QUERY SELECT ROUND(p_quantity / v_factor, 2), v_us_unit;
    ELSE
        -- No conversion needed, just return original system
        IF p_from_system = 'us' THEN
            RETURN QUERY SELECT p_quantity, v_us_unit;
        ELSE
            RETURN QUERY SELECT p_quantity, v_metric_unit;
        END IF;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_batch_sessions(p_meal_plan_id uuid, p_user_id uuid, p_max_portions integer DEFAULT 7)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_rec            RECORD;
  v_total_weight_g numeric;
  v_scale_factor   numeric(8,4);
  v_session_id     uuid;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.meal_plan
    WHERE id = p_meal_plan_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM public.cooking_session
  WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;

  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)              AS appearance_count,
      SUM(mpe.servings)     AS total_grams,
      MIN(mpe.scheduled_date) AS first_date
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2 AND COUNT(*) <= p_max_portions
  LOOP
    SELECT rm.total_weight_g INTO v_total_weight_g
    FROM public.recipe_macro rm WHERE rm.recipe_id = v_rec.recipe_id;

    v_scale_factor := ROUND(
      (v_rec.total_grams / GREATEST(COALESCE(v_total_weight_g, 1), 1))::numeric,
      4
    );

    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used, scale_factor
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, v_rec.appearance_count::int, 0, v_scale_factor
    )
    RETURNING id INTO v_session_id;

    INSERT INTO public.cooking_session_ingredient
      (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
    SELECT
      v_session_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_scale_factor,
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM public.recipe_ingredient ri
    JOIN public.ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_rec.recipe_id
      AND ri.is_optional = false;

    UPDATE public.meal_plan_entry_component mpec
    SET cooking_session_id = v_session_id
    FROM public.meal_plan_entry mpe
    WHERE mpec.meal_plan_entry_id = mpe.id
      AND mpe.meal_plan_id = p_meal_plan_id
      AND mpec.recipe_id = v_rec.recipe_id;

  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_batch_sessions_internal(p_meal_plan_id uuid, p_user_id uuid, p_max_portions integer DEFAULT 7)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_rec            RECORD;
  v_total_weight_g numeric;
  v_scale_factor   numeric(8,4);
  v_session_id     uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.meal_plan
    WHERE id = p_meal_plan_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'create_batch_sessions_internal: plan % not owned by user %',
      p_meal_plan_id, p_user_id;
  END IF;

  DELETE FROM public.cooking_session
  WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;

  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)              AS appearance_count,
      SUM(mpe.servings)     AS total_grams,
      MIN(mpe.scheduled_date) AS first_date
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2 AND COUNT(*) <= p_max_portions
  LOOP
    SELECT rm.total_weight_g INTO v_total_weight_g
    FROM public.recipe_macro rm WHERE rm.recipe_id = v_rec.recipe_id;

    v_scale_factor := ROUND(
      (v_rec.total_grams / GREATEST(COALESCE(v_total_weight_g, 1), 1))::numeric,
      4
    );

    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used, scale_factor
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, v_rec.appearance_count::int, 0, v_scale_factor
    )
    RETURNING id INTO v_session_id;

    INSERT INTO public.cooking_session_ingredient
      (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
    SELECT
      v_session_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_scale_factor,
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM public.recipe_ingredient ri
    JOIN public.ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_rec.recipe_id
      AND ri.is_optional = false;

    UPDATE public.meal_plan_entry_component mpec
    SET cooking_session_id = v_session_id
    FROM public.meal_plan_entry mpe
    WHERE mpec.meal_plan_entry_id = mpe.id
      AND mpe.meal_plan_id = p_meal_plan_id
      AND mpec.recipe_id = v_rec.recipe_id;

  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_creator_support_conversation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_conversation_id uuid;
BEGIN
  INSERT INTO conversation (type, name, created_by, is_support_open)
  VALUES ('support', 'Support Akeli', NEW.user_id, true)
  RETURNING id INTO v_conversation_id;

  INSERT INTO conversation_participant (conversation_id, user_id)
  VALUES (v_conversation_id, NEW.user_id);

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_group_conversation(p_name text, p_is_public boolean)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id uuid;
  v_group_id uuid;
  v_conv_id uuid;
BEGIN
  -- Get the authenticated user's ID
  v_user_id := auth.uid();

  -- Verify the user is a creator
  IF NOT EXISTS (SELECT 1 FROM creator WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'User is not a creator';
  END IF;

  -- Create the community group
  INSERT INTO community_group (name, is_public, creator_id)
  VALUES (p_name, p_is_public, v_user_id)
  RETURNING id INTO v_group_id;

  -- Create the conversation
  INSERT INTO conversation (type, name, created_by, community_group_id)
  VALUES ('creator_group', p_name, v_user_id, v_group_id)
  RETURNING id INTO v_conv_id;

  -- Add creator as participant
  INSERT INTO conversation_participant (conversation_id, user_id)
  VALUES (v_conv_id, v_user_id);

  RETURN v_conv_id;
END;
$function$
;

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


CREATE OR REPLACE FUNCTION public.deactivate_other_nutrition_plans()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.is_active = true THEN
        UPDATE public.nutrition_plan
        SET is_active = false
        WHERE user_id = NEW.user_id AND id != NEW.id AND is_active = true;
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.evaluate_saved_recipe_eligibility(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_breakfast_count int;
  v_lunch_count int;
  v_dinner_count int;
  v_was_eligible boolean;
  v_now_eligible boolean;
  v_variety_days int;
  v_target_count int;
BEGIN
  SELECT is_saved_recipe_eligible, COALESCE(meal_variety_days, 7)
  INTO v_was_eligible, v_variety_days
  FROM user_profile WHERE id = p_user_id;

  v_target_count := CASE WHEN v_variety_days = 0 THEN 7 ELSE v_variety_days * 2 END;

  SELECT count(*) INTO v_breakfast_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'breakfast' = ANY(r.meal_types);

  SELECT count(*) INTO v_lunch_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'lunch' = ANY(r.meal_types);

  SELECT count(*) INTO v_dinner_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'dinner' = ANY(r.meal_types);

  IF v_breakfast_count >= v_target_count AND v_lunch_count >= v_target_count AND v_dinner_count >= v_target_count THEN
    v_now_eligible := true;
  ELSE
    v_now_eligible := false;
  END IF;

  IF v_now_eligible != COALESCE(v_was_eligible, false) THEN
    IF v_now_eligible = false THEN
      UPDATE user_profile
      SET is_saved_recipe_eligible = false, use_saved_recipes_only = false
      WHERE id = p_user_id;
    ELSE
      UPDATE user_profile
      SET is_saved_recipe_eligible = true
      WHERE id = p_user_id;
    END IF;
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.finalize_pending_unpublish()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_count integer;
BEGIN
  UPDATE recipe
  SET is_published = false,
      unpublish_requested_at = NULL
  WHERE unpublish_requested_at IS NOT NULL;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_notify_chat_message()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sender_name  text;
  v_recipient    RECORD;
  v_is_group     boolean;
  v_prefs        jsonb;
BEGIN
  IF NEW.conversation_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT (community_group_id IS NOT NULL)
    INTO v_is_group
    FROM conversation
   WHERE id = NEW.conversation_id;

  IF v_is_group THEN
    RETURN NEW;
  END IF;

  SELECT NULLIF(TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')), '')
    INTO v_sender_name
    FROM user_profile WHERE id = NEW.sender_id;

  IF v_sender_name IS NULL THEN
    SELECT username INTO v_sender_name
      FROM user_profile WHERE id = NEW.sender_id;
  END IF;

  FOR v_recipient IN
    SELECT user_id
      FROM conversation_participant
     WHERE conversation_id = NEW.conversation_id
       AND user_id != NEW.sender_id
  LOOP
    -- Check user preferences
    SELECT notification_prefs INTO v_prefs FROM user_profile WHERE id = v_recipient.user_id;

    IF COALESCE((v_prefs->>'chat')::boolean, true) THEN
      INSERT INTO notification (user_id, type, title, body, data)
      VALUES (
        v_recipient.user_id,
        'message',
        COALESCE(v_sender_name, 'Nouveau message'),
        LEFT(NEW.content, 100),
        jsonb_build_object(
          'conversation_id', NEW.conversation_id,
          'sender_id',       NEW.sender_id
        )
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fn_notify_conversation_request()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_requester_name text;
  v_prefs          jsonb;
BEGIN
  -- Check user preferences
  SELECT notification_prefs INTO v_prefs FROM user_profile WHERE id = NEW.recipient_id;

  IF COALESCE((v_prefs->>'dm_requests')::boolean, true) THEN
    SELECT NULLIF(TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')), '')
      INTO v_requester_name
      FROM user_profile WHERE id = NEW.requester_id;

    IF v_requester_name IS NULL THEN
      SELECT username INTO v_requester_name
        FROM user_profile WHERE id = NEW.requester_id;
    END IF;

    INSERT INTO notification (user_id, type, title, body, data)
    VALUES (
      NEW.recipient_id,
      'conversation_request',
      COALESCE(v_requester_name, 'Quelqu''un') || ' veut discuter',
      'Acceptez ou refusez la demande de conversation.',
      jsonb_build_object(
        'request_id',   NEW.id,
        'requester_id', NEW.requester_id
      )
    );
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_creators_exploration(p_user_id uuid, p_limit integer DEFAULT 4, p_exclude uuid[] DEFAULT '{}'::uuid[])
 RETURNS TABLE(creator_id uuid, score numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_vector vector(50);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH candidates AS (
    SELECT
      c.id                                          AS creator_id,
      (1 - (cv.vector <=> v_user_vector))::numeric  AS score
    FROM creator c
    JOIN creator_vector cv ON cv.creator_id = c.id
    WHERE c.recipe_count >= 3
      AND c.average_rating >= 3.5
      AND c.id <> ALL(p_exclude)
  )
  SELECT cand.creator_id, cand.score
  FROM candidates cand
  WHERE cand.score < 0.50
  ORDER BY random()
  LIMIT LEAST(p_limit, 50);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_creators_fresh(p_user_id uuid, p_limit integer DEFAULT 2, p_exclude uuid[] DEFAULT '{}'::uuid[])
 RETURNS TABLE(creator_id uuid, score numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT
    c.id AS creator_id,
    -- Decay score: 1.0 = just created, ~0.0 = 60 days old
    (1.0 - EXTRACT(EPOCH FROM (now() - c.created_at)) / (60.0 * 24 * 3600))::numeric AS score
  FROM creator c
  WHERE
    c.id <> ALL(p_exclude)
    AND (
      c.created_at >= now() - interval '60 days'
      OR EXISTS (
        SELECT 1 FROM recipe r
        WHERE r.creator_id = c.id
          AND r.is_published = true
          AND r.created_at >= now() - interval '30 days'
      )
    )
    AND NOT EXISTS (
      SELECT 1 FROM fan_subscription fs
      WHERE fs.creator_id = c.id
        AND fs.user_id = p_user_id
        AND fs.status = 'active'
    )
  ORDER BY c.created_at DESC
  LIMIT LEAST(p_limit, 20);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_creators_personalized(p_user_id uuid, p_limit integer DEFAULT 14, p_exclude uuid[] DEFAULT '{}'::uuid[])
 RETURNS TABLE(creator_id uuid, score numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_user_vector vector(50);
  v_max_fans    int;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    SELECT MAX(fan_count) INTO v_max_fans FROM creator;
    RETURN QUERY
    SELECT
      c.id AS creator_id,
      CASE WHEN v_max_fans > 0
        THEN (c.fan_count::numeric / v_max_fans)
        ELSE 0::numeric
      END AS score
    FROM creator c
    WHERE c.recipe_count >= 3
      AND c.id <> ALL(p_exclude)
    ORDER BY c.fan_count DESC
    LIMIT LEAST(p_limit, 100);
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    c.id                                          AS creator_id,
    (1 - (cv.vector <=> v_user_vector))::numeric  AS score
  FROM creator c
  JOIN creator_vector cv ON cv.creator_id = c.id
  WHERE c.recipe_count >= 3
    AND c.id <> ALL(p_exclude)
  ORDER BY (cv.vector <=> v_user_vector) ASC
  LIMIT LEAST(p_limit, 100);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_feed_exploration(p_user_id uuid, p_limit integer DEFAULT 40, p_exclude uuid[] DEFAULT '{}'::uuid[])
 RETURNS TABLE(recipe_id uuid, score numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_vector vector(50);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  IF v_user_vector IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  ),
  candidates AS (
    SELECT
      r.id                                         AS recipe_id,
      (1 - (rv.vector <=> v_user_vector))::numeric AS score
    FROM recipe r
    JOIN recipe_vector rv ON rv.recipe_id = r.id
    WHERE r.is_published = true
      AND r.is_private = false
      AND r.id <> ALL(p_exclude)
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  )
  SELECT c.recipe_id, c.score
  FROM candidates c
  WHERE c.score < 0.50
    AND EXISTS (
      SELECT 1 FROM recipe_performance_metrics rpm
      WHERE rpm.recipe_id = c.recipe_id
        AND rpm.adherence_rate > 0.70
    )
  ORDER BY random()
  LIMIT LEAST(p_limit, 80);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_feed_fresh(p_user_id uuid, p_limit integer DEFAULT 20, p_exclude uuid[] DEFAULT '{}'::uuid[])
 RETURNS TABLE(recipe_id uuid, score numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  )
  SELECT
    r.id                                                                        AS recipe_id,
    (1.0 - EXTRACT(EPOCH FROM (now() - r.created_at)) / 604800.0)::numeric     AS score
  FROM recipe r
  WHERE r.is_published = true
    AND r.is_private = false
    AND r.id <> ALL(p_exclude)
    AND r.created_at >= now() - interval '7 days'
    AND NOT EXISTS (
      SELECT 1 FROM fan_subscription fs
      WHERE fs.user_id = p_user_id
        AND fs.status = 'active'
        AND fs.creator_id = r.creator_id
    )
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  ORDER BY r.created_at DESC
  LIMIT LEAST(p_limit, 40);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_initial_meal_plan(p_user_id uuid, p_meals_per_day integer DEFAULT 3, p_max_recipe_repeat integer DEFAULT 2)
 RETURNS TABLE(meal_plan_id uuid, entry_id uuid, component_id uuid, scheduled_date date, meal_type text, recipe_id uuid, recipe_title text, cover_image_url text, calories numeric, protein_g numeric, score double precision)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_days_until_sunday integer;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  v_days_until_sunday := (7 - EXTRACT(dow FROM CURRENT_DATE)::integer) % 7 + 1;

  RETURN QUERY SELECT * FROM public.generate_meal_plan(
    p_user_id, v_days_until_sunday, p_meals_per_day, CURRENT_DATE, p_max_recipe_repeat
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_initial_meal_plan_internal(p_user_id uuid, p_meals_per_day integer DEFAULT 3, p_max_recipe_repeat integer DEFAULT 2)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_days_until_sunday integer;
BEGIN
  -- (7 - dow) % 7 + 1 → Sun=1, Mon=7, Tue=6, Wed=5, Thu=4, Fri=3, Sat=2
  v_days_until_sunday :=
    (7 - EXTRACT(dow FROM CURRENT_DATE)::integer) % 7 + 1;

  PERFORM public.generate_meal_plan_internal(
    p_user_id,
    v_days_until_sunday,
    p_meals_per_day,
    CURRENT_DATE
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_meal_plan(p_user_id uuid, p_days integer, p_meals_per_day integer, p_start_date date, p_max_recipe_repeat integer DEFAULT 3)
 RETURNS TABLE(meal_plan_id uuid, entry_id uuid, component_id uuid, scheduled_date date, meal_type text, recipe_id uuid, recipe_title text, cover_image_url text, calories numeric, protein_g numeric, score double precision)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_vector            vector(50);
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_existing_plan_id       uuid;
  v_slots                  JSONB[];
  v_slot_rec               JSONB;
  v_slot_nickname          text;
  v_slot_sort_order        integer;
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_recent_recipe_ids      uuid[] := ARRAY[]::uuid[];
  v_variety_days           int    := 7;
  v_random_order           boolean := false;
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_protein_goal           numeric;
  v_fat_goal               numeric;
  v_target_meal_cal        numeric;
  v_target_protein_density numeric;
  v_target_fat_density     numeric;
  v_grams                  integer;
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
  v_entry                  record;
  v_weekly_budget          numeric(10,2);
  v_country_code           text;
  v_target_meal_cost       numeric(10,2);
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT array_agg(
    jsonb_build_object(
      'meal_type',      md.meal_type,
      'calorie_target', COALESCE(md.calorie_target, 0),
      'protein_pct',    COALESCE(md.protein_pct, 25.0),
      'fat_pct',        COALESCE(md.fat_pct, 25.0),
      'nickname',       md.nickname,
      'sort_order',     md.sort_order
    ) ORDER BY md.sort_order
  ) INTO v_slots
  FROM meal_distribution md
  JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
  WHERE np.user_id = p_user_id AND np.is_active = true;

  IF v_slots IS NULL THEN
    v_slots := ARRAY[
      jsonb_build_object('meal_type','breakfast','calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',0),
      jsonb_build_object('meal_type','lunch',    'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',1),
      jsonb_build_object('meal_type','dinner',   'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',2)
    ];
  END IF;

  v_total_slots     := p_days * array_length(v_slots, 1);
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), ARRAY[]::text[]) INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT COALESCE(meal_variety_days, 7), COALESCE(meal_schedule_random, false), COALESCE(weekly_budget, 0), COALESCE(country_code, 'FR')
  INTO v_variety_days, v_random_order, v_weekly_budget, v_country_code
  FROM public.user_profile WHERE id = p_user_id;

  IF v_weekly_budget > 0 THEN
    v_target_meal_cost := v_weekly_budget / NULLIF(v_total_slots, 0);
  END IF;

  SELECT id INTO v_existing_plan_id
  FROM public.meal_plan
  WHERE user_id    =  p_user_id
    AND start_date <= (p_start_date + (p_days - 1))
    AND end_date   >=  p_start_date
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_existing_plan_id IS NOT NULL THEN
    DELETE FROM meal_plan_entry AS e
    WHERE e.meal_plan_id    = v_existing_plan_id
      AND e.scheduled_date >= CURRENT_DATE;

    UPDATE public.meal_plan
    SET end_date = GREATEST(end_date, p_start_date + (p_days - 1))
    WHERE id = v_existing_plan_id;

    v_plan_id := v_existing_plan_id;
  ELSE
    INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
    VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
    RETURNING id INTO v_plan_id;
  END IF;

  SELECT COALESCE(array_agg(mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_used_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  WHERE mpe.meal_plan_id   = v_plan_id
    AND mpe.scheduled_date < CURRENT_DATE
    AND mpec.role = 'base';

  SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_recent_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id         = p_user_id
    AND mpe.scheduled_date >= (p_start_date - v_variety_days)
    AND mpe.scheduled_date <   p_start_date
    AND mpec.role          = 'base';

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;
  CREATE TEMP TABLE temp_dates (
    id             serial,
    scheduled_date date,
    meal_type      text
  ) ON COMMIT DROP;

  CREATE TEMP TABLE temp_meals (
    id                serial,
    meal_type         text,
    recipe_id         uuid,
    recipe_title      text,
    cover_image_url   text,
    calories          numeric,
    protein_g         numeric,
    carbs_g           numeric,
    fat_g             numeric,
    grams             integer,
    slot_nickname     text,
    slot_sort_order   integer,
    total_weight_g    numeric
  ) ON COMMIT DROP;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    IF v_current_date < CURRENT_DATE THEN
      CONTINUE;
    END IF;

    FOREACH v_slot_rec IN ARRAY v_slots LOOP
      v_meal_type       := v_slot_rec->>'meal_type';
      v_slot_nickname   := v_slot_rec->>'nickname';
      v_slot_sort_order := (v_slot_rec->>'sort_order')::integer;

      v_target_meal_cal := (v_slot_rec->>'calorie_target')::numeric;
      IF (v_target_meal_cal IS NULL OR v_target_meal_cal = 0)
         AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / array_length(v_slots, 1);
      END IF;

      IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_protein_density := (v_slot_rec->>'protein_pct')::numeric;
        v_target_fat_density     := (v_slot_rec->>'fat_pct')::numeric;
      ELSE
        v_target_protein_density := 7.5;
        v_target_fat_density     := 3.3;
      END IF;

      -- Pass 1: with blacklist
      v_recipe := NULL;
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
               (
                 0.50 * (1 - (rv.vector <=> v_user_vector))
                        * CASE WHEN v_fan_creator_id IS NOT NULL
                                    AND r.creator_id = v_fan_creator_id
                                THEN 1.5 ELSE 1.0 END
                 + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                         - v_target_protein_density)
                     / NULLIF(v_target_protein_density, 0.001), 1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001), 1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN public.recipe_market_cost rmc 
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.calories_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.cost_per_100g / NULLIF(rm.calories_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        LEFT JOIN public.recipe_market_cost rmc 
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.calories_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.cost_per_100g / NULLIF(rm.calories_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.calories_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      -- Pass 2: fallback — retry without blacklist if pool exhausted
      IF v_recipe.id IS NULL THEN
        IF v_user_vector IS NOT NULL THEN
          SELECT r.id, r.title, r.cover_image_url,
                 rm.calories_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g, r.creator_id,
                 (
                   0.50 * (1 - (rv.vector <=> v_user_vector))
                          * CASE WHEN v_fan_creator_id IS NOT NULL
                                      AND r.creator_id = v_fan_creator_id
                                 THEN 1.5 ELSE 1.0 END
                   + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                           - v_target_protein_density)
                       / NULLIF(v_target_protein_density, 0.001), 1.0))
                   + 0.15 * CASE
                       WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                       WHEN r.preferred_meal_type = 'any'       THEN 0.5
                       ELSE 0.0
                     END
                   + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                           - v_target_fat_density)
                       / NULLIF(v_target_fat_density, 0.001), 1.0))
                 ) AS score
          INTO v_recipe
          FROM recipe r
          JOIN recipe_vector rv ON r.id = rv.recipe_id
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          LEFT JOIN public.recipe_market_cost rmc 
            ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
          WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
            AND v_meal_type = ANY(r.meal_types)
            AND rm.calories_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.calories_per_100g / 100) <= 1500)
            AND NOT (r.allergen_tags && v_user_allergens)
            AND (
              v_weekly_budget = 0 OR
              (
                rmc.recipe_id IS NOT NULL AND
                ((rmc.cost_per_100g / NULLIF(rm.calories_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
              )
            )
          ORDER BY score DESC
          LIMIT 1;
        ELSE
          SELECT r.id, r.title, r.cover_image_url,
                 rm.calories_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g, r.creator_id,
                 (
                   0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 ) AS score
          INTO v_recipe
          FROM recipe r
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
          LEFT JOIN public.recipe_market_cost rmc 
            ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
          WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
            AND v_meal_type = ANY(r.meal_types)
            AND rm.calories_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.calories_per_100g / 100) <= 1500)
            AND NOT (r.allergen_tags && v_user_allergens)
            AND (
              v_weekly_budget = 0 OR
              (
                rmc.recipe_id IS NOT NULL AND
                ((rmc.cost_per_100g / NULLIF(rm.calories_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
              )
            )
          GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                   rm.calories_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                   rm.total_weight_g
          ORDER BY score DESC, COUNT(rl.recipe_id) DESC
          LIMIT 1;
        END IF;
      END IF;

      IF v_recipe.id IS NULL THEN
        IF v_weekly_budget > 0 AND EXISTS (
          SELECT 1
          FROM recipe r
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          WHERE r.is_published = true AND r.unpublish_requested_at IS NULL
            AND v_meal_type = ANY(r.meal_types)
            AND rm.calories_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND NOT (r.allergen_tags && v_user_allergens)
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.calories_per_100g / 100) <= 1500)
        ) THEN
          RAISE EXCEPTION 'insufficient_budget';
        ELSE
          RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
        END IF;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.calories_per_100g > 0 THEN
        v_grams := GREATEST(50, LEAST(1500,
          ROUND(v_target_meal_cal / (v_recipe.calories_per_100g / 100))::integer));
      ELSE
        v_grams := 300;
      END IF;

      INSERT INTO temp_dates (scheduled_date, meal_type)
      VALUES (v_current_date, v_meal_type);

      INSERT INTO temp_meals (
        meal_type, recipe_id, recipe_title, cover_image_url,
        calories, protein_g, carbs_g, fat_g, grams,
        slot_nickname, slot_sort_order, total_weight_g
      )
      VALUES (
        v_meal_type, v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.calories_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.carbs_per_100g   * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.fat_per_100g     * v_grams / 100)::numeric, 1),
        v_grams,
        v_slot_nickname,
        v_slot_sort_order,
        v_recipe.total_weight_g
      );

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

    END LOOP;
  END LOOP;

  -- 5. Pair dates with (potentially shuffled) meals and perform real DB inserts
  FOR v_entry IN (
    WITH shuffled_meals AS (
      SELECT t.*, row_number() OVER (PARTITION BY t.meal_type ORDER BY CASE WHEN v_random_order THEN random() ELSE t.id::double precision END) as rn
      FROM temp_meals t
    ),
    ordered_dates AS (
      SELECT d.*, row_number() OVER (PARTITION BY d.meal_type ORDER BY d.scheduled_date) as rn
      FROM temp_dates d
    )
    SELECT od.scheduled_date, sm.meal_type, sm.recipe_id, sm.recipe_title, sm.cover_image_url,
           sm.calories, sm.protein_g, sm.carbs_g, sm.fat_g, sm.grams,
           sm.slot_nickname, sm.slot_sort_order, sm.total_weight_g
    FROM ordered_dates od
    JOIN shuffled_meals sm ON od.meal_type = sm.meal_type AND od.rn = sm.rn
    ORDER BY od.scheduled_date, sm.slot_sort_order
  ) LOOP

    INSERT INTO meal_plan_entry (
      meal_plan_id, scheduled_date, meal_type, servings,
      calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed,
      nickname, sort_order
    )
    VALUES (
      v_plan_id, v_entry.scheduled_date, v_entry.meal_type, v_entry.grams,
      v_entry.calories, v_entry.protein_g, v_entry.carbs_g, v_entry.fat_g,
      v_entry.slot_nickname, v_entry.slot_sort_order
    )
    RETURNING id INTO v_entry_id;

    INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
    VALUES (v_entry_id, v_entry.recipe_id, 'base', 1.0)
    RETURNING id INTO v_component_id;

    INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
    SELECT
      v_entry_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_entry.grams / NULLIF(v_entry.total_weight_g, 0),
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM recipe_ingredient ri
    JOIN ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_entry.recipe_id
      AND ri.is_optional = false;

    RETURN QUERY SELECT
      v_plan_id, v_entry_id, v_component_id,
      v_entry.scheduled_date, v_entry.meal_type,
      v_entry.recipe_id, v_entry.recipe_title, v_entry.cover_image_url,
      v_entry.calories, v_entry.protein_g,
      NULL::double precision;

  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_meal_plan_from_saved(p_user_id uuid, p_days integer, p_meals_per_day integer, p_start_date date, p_max_recipe_repeat integer DEFAULT 3)
 RETURNS TABLE(meal_plan_id uuid, entry_id uuid, component_id uuid, scheduled_date date, meal_type text, recipe_id uuid, recipe_title text, cover_image_url text, calories numeric, protein_g numeric, score double precision)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_existing_plan_id       uuid;
  v_slots                  JSONB[];
  v_slot_rec               JSONB;
  v_slot_nickname          text;
  v_slot_sort_order        integer;
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_recent_recipe_ids      uuid[] := ARRAY[]::uuid[];
  v_variety_days           int    := 7;
  v_variety_eligible_types text[] := ARRAY[]::text[];
  v_pool_count             int;
  v_type                   text;
  v_recipe_found           boolean := false;
  v_random_order           boolean := false;
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_target_meal_cal        numeric;
  v_grams                  integer;
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
  v_entry                  record;
  v_weekly_budget          numeric(10,2);
  v_country_code           text;
  v_target_meal_cost       numeric(10,2);
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() AND auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT array_agg(
    jsonb_build_object(
      'meal_type',      md.meal_type,
      'calorie_target', COALESCE(md.calorie_target, 0),
      'protein_pct',    COALESCE(md.protein_pct, 25.0),
      'fat_pct',        COALESCE(md.fat_pct, 25.0),
      'nickname',       md.nickname,
      'sort_order',     md.sort_order
    ) ORDER BY md.sort_order
  ) INTO v_slots
  FROM meal_distribution md
  JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
  WHERE np.user_id = p_user_id AND np.is_active = true;

  IF v_slots IS NULL THEN
    v_slots := ARRAY[
      jsonb_build_object('meal_type','breakfast','calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',0),
      jsonb_build_object('meal_type','lunch',    'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',1),
      jsonb_build_object('meal_type','dinner',   'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',2)
    ];
  END IF;

  v_total_slots     := p_days * array_length(v_slots, 1);
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), ARRAY[]::text[]) INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

  SELECT calorie_goal INTO v_calorie_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT COALESCE(meal_variety_days, 7), COALESCE(meal_schedule_random, false), COALESCE(weekly_budget, 0), COALESCE(country_code, 'FR')
  INTO v_variety_days, v_random_order, v_weekly_budget, v_country_code
  FROM public.user_profile WHERE id = p_user_id;

  IF v_weekly_budget > 0 THEN
    v_target_meal_cost := v_weekly_budget / NULLIF(v_total_slots, 0);
  END IF;

  SELECT id INTO v_existing_plan_id
  FROM public.meal_plan
  WHERE user_id    =  p_user_id
    AND start_date <= (p_start_date + (p_days - 1))
    AND end_date   >=  p_start_date
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_existing_plan_id IS NOT NULL THEN
    DELETE FROM meal_plan_entry AS e
    WHERE e.meal_plan_id    = v_existing_plan_id
      AND e.scheduled_date >= p_start_date;

    UPDATE public.meal_plan
    SET end_date = GREATEST(end_date, p_start_date + (p_days - 1))
    WHERE id = v_existing_plan_id;

    v_plan_id := v_existing_plan_id;
  ELSE
    INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
    VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
    RETURNING id INTO v_plan_id;
  END IF;

  SELECT COALESCE(array_agg(mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_used_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  WHERE mpe.meal_plan_id   = v_plan_id
    AND mpe.scheduled_date < p_start_date
    AND mpec.role = 'base';

  SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_recent_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id         = p_user_id
    AND mpe.scheduled_date >= (p_start_date - v_variety_days)
    AND mpe.scheduled_date <   p_start_date
    AND mpec.role          = 'base';

  -- Part 1: pool-size precheck — only apply the recency blacklist for a meal
  -- type if the saved pool for that type is at least as large as the variety
  -- window. Otherwise Pass 1 could never succeed anyway, so skip straight to
  -- the no-blacklist query below instead of burning a doomed query per slot.
  FOR v_type IN SELECT DISTINCT (s->>'meal_type') FROM unnest(v_slots) AS s LOOP
    SELECT count(DISTINCT r.id) INTO v_pool_count
    FROM recipe r
    INNER JOIN recipe_save rs ON r.id = rs.recipe_id
    WHERE rs.user_id = p_user_id
      AND r.is_published = true
      AND v_type = ANY(r.meal_types)
      AND NOT (r.allergen_tags && v_user_allergens);

    IF v_variety_days = 0 OR v_pool_count >= v_variety_days THEN
      v_variety_eligible_types := v_variety_eligible_types || v_type;
    END IF;
  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;
  CREATE TEMP TABLE temp_dates (
    id             serial,
    scheduled_date date,
    meal_type      text
  ) ON COMMIT DROP;

  CREATE TEMP TABLE temp_meals (
    id                serial,
    meal_type         text,
    recipe_id         uuid,
    recipe_title      text,
    cover_image_url   text,
    calories          numeric,
    protein_g         numeric,
    carbs_g           numeric,
    fat_g             numeric,
    grams             integer,
    slot_nickname     text,
    slot_sort_order   integer,
    total_weight_g    numeric,
    score             double precision
  ) ON COMMIT DROP;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_slot_rec IN ARRAY v_slots LOOP
      v_meal_type       := v_slot_rec->>'meal_type';
      v_slot_nickname   := v_slot_rec->>'nickname';
      v_slot_sort_order := (v_slot_rec->>'sort_order')::integer;

      v_target_meal_cal := (v_slot_rec->>'calorie_target')::numeric;
      IF (v_target_meal_cal IS NULL OR v_target_meal_cal = 0)
         AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / array_length(v_slots, 1);
      END IF;

      -- Pass 1: with blacklist — only attempted when the pool-size precheck
      -- flagged this meal type as able to sustain the variety window.
      v_recipe := NULL;
      v_recipe_found := false;
      IF v_meal_type = ANY(v_variety_eligible_types) THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        INNER JOIN recipe_save rs ON r.id = rs.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN public.recipe_market_cost rmc
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE rs.user_id = p_user_id
          AND r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.cost_per_100g / NULLIF(rm.kcal_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        ORDER BY score DESC, random()
        LIMIT 1;

        IF FOUND THEN
          v_recipe_found := true;
        END IF;
      END IF;

      -- Pass 2: fallback — no blacklist. Runs whenever Pass 1 was skipped
      -- (pool too small) or ran but found nothing.
      IF NOT v_recipe_found THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        INNER JOIN recipe_save rs ON r.id = rs.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN public.recipe_market_cost rmc
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE rs.user_id = p_user_id
          AND r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.cost_per_100g / NULLIF(rm.kcal_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        ORDER BY score DESC, random()
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        IF v_weekly_budget > 0 AND EXISTS (
          SELECT 1
          FROM recipe r
          INNER JOIN recipe_save rs ON r.id = rs.recipe_id
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          WHERE rs.user_id = p_user_id
            AND r.is_published = true
            AND v_meal_type = ANY(r.meal_types)
            AND rm.kcal_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND NOT (r.allergen_tags && v_user_allergens)
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
        ) THEN
          RAISE EXCEPTION 'insufficient_budget';
        ELSE
          RAISE EXCEPTION 'insufficient_saved_recipes' USING DETAIL = v_meal_type;
        END IF;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.kcal_per_100g > 0 THEN
        v_grams := GREATEST(50, LEAST(1500,
          ROUND(v_target_meal_cal / (v_recipe.kcal_per_100g / 100))::integer));
      ELSE
        v_grams := 300;
      END IF;

      INSERT INTO temp_dates (scheduled_date, meal_type)
      VALUES (v_current_date, v_meal_type);

      INSERT INTO temp_meals (
        meal_type, recipe_id, recipe_title, cover_image_url,
        calories, protein_g, carbs_g, fat_g, grams,
        slot_nickname, slot_sort_order, total_weight_g, score
      )
      VALUES (
        v_meal_type, v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.carbs_per_100g   * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.fat_per_100g     * v_grams / 100)::numeric, 1),
        v_grams,
        v_slot_nickname,
        v_slot_sort_order,
        v_recipe.total_weight_g,
        v_recipe.score
      );

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

    END LOOP;
  END LOOP;

  FOR v_entry IN (
    WITH shuffled_meals AS (
      SELECT t.*, row_number() OVER (PARTITION BY t.meal_type ORDER BY CASE WHEN v_random_order THEN random() ELSE t.id::double precision END) as rn
      FROM temp_meals t
    ),
    ordered_dates AS (
      SELECT d.*, row_number() OVER (PARTITION BY d.meal_type ORDER BY d.scheduled_date) as rn
      FROM temp_dates d
    )
    SELECT od.scheduled_date, sm.meal_type, sm.recipe_id, sm.recipe_title, sm.cover_image_url,
           sm.calories, sm.protein_g, sm.carbs_g, sm.fat_g, sm.grams,
           sm.slot_nickname, sm.slot_sort_order, sm.total_weight_g, sm.score
    FROM ordered_dates od
    JOIN shuffled_meals sm ON od.meal_type = sm.meal_type AND od.rn = sm.rn
    ORDER BY od.scheduled_date, sm.slot_sort_order
  ) LOOP

    INSERT INTO meal_plan_entry (
      meal_plan_id, scheduled_date, meal_type, servings,
      calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed,
      nickname, sort_order
    )
    VALUES (
      v_plan_id, v_entry.scheduled_date, v_entry.meal_type, v_entry.grams,
      v_entry.calories, v_entry.protein_g, v_entry.carbs_g, v_entry.fat_g,
      v_entry.slot_nickname, v_entry.slot_sort_order
    )
    RETURNING id INTO v_entry_id;

    INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
    VALUES (v_entry_id, v_entry.recipe_id, 'base', 1.0)
    RETURNING id INTO v_component_id;

    INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
    SELECT
      v_entry_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_entry.grams / NULLIF(v_entry.total_weight_g, 0),
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM recipe_ingredient ri
    JOIN ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_entry.recipe_id
      AND ri.is_optional = false;

    RETURN QUERY SELECT
      v_plan_id, v_entry_id, v_component_id,
      v_entry.scheduled_date, v_entry.meal_type,
      v_entry.recipe_id, v_entry.recipe_title, v_entry.cover_image_url,
      v_entry.calories, v_entry.protein_g,
      v_entry.score::double precision;

  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;

  PERFORM public.create_batch_sessions_internal(v_plan_id, p_user_id, 7);
  PERFORM public.generate_shopping_list_internal(v_plan_id, p_user_id);

END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_meal_plan_internal(p_user_id uuid, p_days integer DEFAULT 7, p_meals_per_day integer DEFAULT 3, p_start_date date DEFAULT CURRENT_DATE)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_vector            vector(50);
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_meal_types             text[] := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_recent_recipe_ids      uuid[] := ARRAY[]::uuid[];
  v_variety_days           int    := 7;
  v_random_order           boolean := false;
  v_calorie_goal           numeric;
  v_protein_goal           numeric;
  v_fat_goal               numeric;
  v_target_meal_cal        numeric;
  v_target_protein_density numeric;
  v_target_fat_density     numeric;
  v_servings               numeric(4,1);
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
  v_entry                  record;
  v_weekly_budget          numeric(10,2);
  v_country_code           text;
  v_target_meal_cost       numeric(10,2);
BEGIN
  IF EXISTS (
    SELECT 1 FROM meal_plan
    WHERE user_id = p_user_id
      AND start_date = p_start_date
      AND is_active = true
  ) THEN
    RETURN;
  END IF;

  v_total_slots     := p_days * p_meals_per_day;
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT COALESCE(meal_variety_days, 7), COALESCE(meal_schedule_random, false), COALESCE(weekly_budget, 0), COALESCE(country_code, 'FR')
  INTO v_variety_days, v_random_order, v_weekly_budget, v_country_code
  FROM public.user_profile WHERE id = p_user_id;

  IF v_weekly_budget > 0 THEN
    v_target_meal_cost := v_weekly_budget / NULLIF(v_total_slots, 0);
  END IF;

  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND p_meals_per_day > 0 THEN
    v_target_protein_density :=
      COALESCE(v_protein_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
    v_target_fat_density :=
      COALESCE(v_fat_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
  ELSE
    v_target_protein_density := 7.5;
    v_target_fat_density     := 3.3;
  END IF;

  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_recent_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id         = p_user_id
    AND mpe.scheduled_date >= (p_start_date - v_variety_days)
    AND mpe.scheduled_date <   p_start_date
    AND mpec.role          = 'base';

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;
  CREATE TEMP TABLE temp_dates (
    id             serial,
    scheduled_date date,
    meal_type      text
  ) ON COMMIT DROP;

  CREATE TEMP TABLE temp_meals (
    id                serial,
    meal_type         text,
    recipe_id         uuid,
    recipe_title      text,
    cover_image_url   text,
    calories          numeric,
    protein_g         numeric,
    carbs_g           numeric,
    fat_g             numeric,
    servings          numeric(4,1)
  ) ON COMMIT DROP;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      v_target_meal_cal := NULL;
      SELECT md.calorie_target INTO v_target_meal_cal
      FROM meal_distribution md
      JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
      WHERE np.user_id = p_user_id
        AND np.is_active = true
        AND md.meal_type = v_meal_type
      LIMIT 1;

      IF v_target_meal_cal IS NULL AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / p_meals_per_day;
      END IF;

      -- Pass 1: with blacklist
      v_recipe := NULL;
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (
                 0.50 * (1 - (rv.vector <=> v_user_vector))
                        * CASE WHEN v_fan_creator_id IS NOT NULL
                                    AND r.creator_id = v_fan_creator_id
                                THEN 1.5 ELSE 1.0 END
                 + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                         - v_target_protein_density)
                     / NULLIF(v_target_protein_density, 0.001), 1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001), 1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN public.recipe_market_cost rmc 
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.total_recipe_cost / NULLIF(rm.calories, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        LEFT JOIN public.recipe_market_cost rmc 
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.total_recipe_cost / NULLIF(rm.calories, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      -- Pass 2: fallback — retry without blacklist if pool exhausted
      IF v_recipe.id IS NULL THEN
        IF v_user_vector IS NOT NULL THEN
          SELECT r.id, r.title, r.cover_image_url,
                 rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
                 r.creator_id,
                 (
                   0.50 * (1 - (rv.vector <=> v_user_vector))
                          * CASE WHEN v_fan_creator_id IS NOT NULL
                                      AND r.creator_id = v_fan_creator_id
                                 THEN 1.5 ELSE 1.0 END
                   + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                           - v_target_protein_density)
                       / NULLIF(v_target_protein_density, 0.001), 1.0))
                   + 0.15 * CASE
                       WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                       WHEN r.preferred_meal_type = 'any'       THEN 0.5
                       ELSE 0.0
                     END
                   + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                           - v_target_fat_density)
                       / NULLIF(v_target_fat_density, 0.001), 1.0))
                 ) AS score
          INTO v_recipe
          FROM recipe r
          JOIN recipe_vector rv ON r.id = rv.recipe_id
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          LEFT JOIN public.recipe_market_cost rmc 
            ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
          WHERE r.is_published = true
            AND v_meal_type = ANY(r.meal_types)
            AND rm.calories > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
            AND (
              v_weekly_budget = 0 OR
              (
                rmc.recipe_id IS NOT NULL AND
                ((rmc.total_recipe_cost / NULLIF(rm.calories, 0)) * v_target_meal_cal) <= v_target_meal_cost
              )
            )
          ORDER BY score DESC
          LIMIT 1;
        ELSE
          SELECT r.id, r.title, r.cover_image_url,
                 rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
                 r.creator_id,
                 (
                   0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 ) AS score
          INTO v_recipe
          FROM recipe r
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
          LEFT JOIN public.recipe_market_cost rmc 
            ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
          WHERE r.is_published = true
            AND v_meal_type = ANY(r.meal_types)
            AND rm.calories > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
            AND (
              v_weekly_budget = 0 OR
              (
                rmc.recipe_id IS NOT NULL AND
                ((rmc.total_recipe_cost / NULLIF(rm.calories, 0)) * v_target_meal_cal) <= v_target_meal_cost
              )
            )
          GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                   rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g
          ORDER BY score DESC, COUNT(rl.recipe_id) DESC
          LIMIT 1;
        END IF;
      END IF;

      IF v_recipe.id IS NULL THEN
        IF v_weekly_budget > 0 AND EXISTS (
          SELECT 1
          FROM recipe r
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          WHERE r.is_published = true
            AND v_meal_type = ANY(r.meal_types)
            AND rm.calories > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
        ) THEN
          RAISE EXCEPTION 'insufficient_budget';
        ELSE
          RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
        END IF;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.calories > 0 THEN
        v_servings := GREATEST(0.1, LEAST(4.0,
          ROUND((v_target_meal_cal / v_recipe.calories)::numeric, 1)));
      ELSE
        v_servings := 1.0;
      END IF;

      INSERT INTO temp_dates (scheduled_date, meal_type)
      VALUES (v_current_date, v_meal_type);

      INSERT INTO temp_meals (
        meal_type, recipe_id, recipe_title, cover_image_url,
        calories, protein_g, carbs_g, fat_g, servings
      )
      VALUES (
        v_meal_type, v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        ROUND((v_recipe.carbs_g   * v_servings)::numeric, 1),
        ROUND((v_recipe.fat_g     * v_servings)::numeric, 1),
        v_servings
      );

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

    END LOOP;
  END LOOP;

  -- Pair dates with (potentially shuffled) meals and perform real DB inserts
  FOR v_entry IN (
    WITH shuffled_meals AS (
      SELECT t.*, row_number() OVER (PARTITION BY t.meal_type ORDER BY CASE WHEN v_random_order THEN random() ELSE t.id::double precision END) as rn
      FROM temp_meals t
    ),
    ordered_dates AS (
      SELECT d.*, row_number() OVER (PARTITION BY d.meal_type ORDER BY d.scheduled_date) as rn
      FROM temp_dates d
    )
    SELECT od.scheduled_date, sm.meal_type, sm.recipe_id, sm.recipe_title, sm.cover_image_url,
           sm.calories, sm.protein_g, sm.carbs_g, sm.fat_g, sm.servings
    FROM ordered_dates od
    JOIN shuffled_meals sm ON od.meal_type = sm.meal_type AND od.rn = sm.rn
    ORDER BY od.scheduled_date
  ) LOOP

    INSERT INTO meal_plan_entry (
      meal_plan_id, scheduled_date, meal_type, servings,
      calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed
    )
    VALUES (
      v_plan_id, v_entry.scheduled_date, v_entry.meal_type, v_entry.servings,
      v_entry.calories, v_entry.protein_g, v_entry.carbs_g, v_entry.fat_g
    )
    RETURNING id INTO v_entry_id;

    INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
    VALUES (v_entry_id, v_entry.recipe_id, 'base', 1.0)
    RETURNING id INTO v_component_id;

    INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
    SELECT
      v_entry_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      ROUND((ri.quantity * v_entry.servings)::numeric, 3),
      ri.unit
    FROM recipe_ingredient ri
    JOIN ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_entry.recipe_id
      AND ri.is_optional = false;

  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_recipe_slug()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.slug IS NULL AND NEW.is_published = true THEN
    NEW.slug := lower(
      regexp_replace(
        regexp_replace(
          unaccent(NEW.title),
          '[^a-zA-Z0-9\s-]', '', 'g'
        ),
        '\s+', '-', 'g'
      )
    ) || '-' || substring(NEW.id::text, 1, 6);
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_shopping_list(p_meal_plan_id uuid)
 RETURNS TABLE(shopping_list_id uuid, id uuid, ingredient_id uuid, ingredient_name text, total_quantity numeric, unit text, category text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id uuid;
  v_list_id uuid;
BEGIN
  SELECT mp.user_id INTO v_user_id
  FROM meal_plan mp WHERE mp.id = p_meal_plan_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM shopping_list WHERE meal_plan_id = p_meal_plan_id;

  INSERT INTO shopping_list (user_id, meal_plan_id)
  VALUES (v_user_id, p_meal_plan_id)
  RETURNING shopping_list.id INTO v_list_id;

  WITH aggregated_ingredients AS (
    -- Non-batch entries: use pre-rounded quantities from meal_ingredient
    SELECT
      mi.ingredient_id,
      COALESCE(SUM(mi.quantity), 0) AS quantity,
      mi.unit
    FROM meal_plan_entry mpe
    JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    JOIN meal_ingredient mi ON mi.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.cooking_session_id IS NULL
    GROUP BY mi.ingredient_id, mi.unit

    UNION ALL

    -- Batch entries: use pre-rounded quantities from cooking_session_ingredient
    SELECT
      csi.ingredient_id,
      COALESCE(SUM(csi.quantity_needed), 0) AS quantity,
      csi.unit
    FROM cooking_session_ingredient csi
    JOIN cooking_session cs ON cs.id = csi.cooking_session_id
    WHERE cs.meal_plan_id = p_meal_plan_id
    GROUP BY csi.ingredient_id, csi.unit
  )
  INSERT INTO shopping_list_item (shopping_list_id, ingredient_id, quantity, unit)
  SELECT
    v_list_id,
    ai.ingredient_id,
    COALESCE(SUM(ai.quantity), 0),
    ai.unit
  FROM aggregated_ingredients ai
  GROUP BY ai.ingredient_id, ai.unit;

  RETURN QUERY
  SELECT
    sli.shopping_list_id,
    sli.id,
    sli.ingredient_id,
    COALESCE(i.name_fr, i.name) AS ingredient_name,
    sli.quantity,
    sli.unit,
    i.category
  FROM shopping_list_item sli
  JOIN ingredient i ON sli.ingredient_id = i.id
  WHERE sli.shopping_list_id = v_list_id
  ORDER BY i.category, i.name;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_shopping_list_internal(p_meal_plan_id uuid, p_user_id uuid)
 RETURNS TABLE(shopping_list_id uuid, id uuid, ingredient_id uuid, ingredient_name text, quantity numeric, unit text, category text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_list_id uuid;
BEGIN
  DELETE FROM shopping_list WHERE meal_plan_id = p_meal_plan_id;

  INSERT INTO shopping_list (user_id, meal_plan_id)
  VALUES (p_user_id, p_meal_plan_id)
  RETURNING shopping_list.id INTO v_list_id;

  WITH aggregated_ingredients AS (
    -- Non-batch entries: use pre-rounded quantities from meal_ingredient
    SELECT
      mi.ingredient_id,
      COALESCE(SUM(mi.quantity), 0) AS quantity,
      mi.unit
    FROM meal_plan_entry mpe
    JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    JOIN meal_ingredient mi ON mi.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.cooking_session_id IS NULL
    GROUP BY mi.ingredient_id, mi.unit

    UNION ALL

    -- Batch entries: use pre-rounded quantities from cooking_session_ingredient
    SELECT
      csi.ingredient_id,
      COALESCE(SUM(csi.quantity_needed), 0) AS quantity,
      csi.unit
    FROM cooking_session_ingredient csi
    JOIN cooking_session cs ON cs.id = csi.cooking_session_id
    WHERE cs.meal_plan_id = p_meal_plan_id
    GROUP BY csi.ingredient_id, csi.unit
  )
  INSERT INTO shopping_list_item (shopping_list_id, ingredient_id, quantity, unit)
  SELECT
    v_list_id,
    ai.ingredient_id,
    COALESCE(SUM(ai.quantity), 0),
    ai.unit
  FROM aggregated_ingredients ai
  GROUP BY ai.ingredient_id, ai.unit;

  RETURN QUERY
  SELECT
    sli.shopping_list_id,
    sli.id,
    sli.ingredient_id,
    COALESCE(i.name_fr, i.name) AS ingredient_name,
    sli.quantity,
    sli.unit,
    i.category
  FROM shopping_list_item sli
  JOIN ingredient i ON sli.ingredient_id = i.id
  WHERE sli.shopping_list_id = v_list_id
  ORDER BY i.category, i.name;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_creator_by_username(p_username text)
 RETURNS json
 LANGUAGE sql
 STABLE
AS $function$
  SELECT row_to_json(creator_public_profile)
  FROM creator_public_profile
  WHERE username = p_username
  LIMIT 1;
$function$
;

CREATE OR REPLACE FUNCTION public.get_creator_fan_emails(p_creator_id uuid)
 RETURNS TABLE(email text, locale text, first_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Verified visitor paying fans
  RETURN QUERY
  SELECT v.email, v.locale, v.first_name
  FROM public.visitor_fan_subscription vfs
  JOIN public.visitor v ON v.id = vfs.visitor_id
  WHERE vfs.creator_id = p_creator_id
    AND vfs.status = 'active'
    AND v.email_verified = true;

  -- Registered Akeli paying fans
  RETURN QUERY
  SELECT au.email::text, up.locale, up.first_name
  FROM public.fan_subscription fs
  JOIN public.user_profile up ON up.id = fs.user_id
  JOIN auth.users au ON au.id = fs.user_id
  WHERE fs.creator_id = p_creator_id
    AND fs.status = 'active';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_creator_newsletter_emails(p_creator_id uuid)
 RETURNS TABLE(email text, locale text, first_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Verified visitor followers
  RETURN QUERY
  SELECT v.email, v.locale, v.first_name
  FROM public.visitor_creator_follow vcf
  JOIN public.visitor v ON v.id = vcf.visitor_id
  WHERE vcf.creator_id = p_creator_id
    AND vcf.active = true
    AND v.email_verified = true;

  -- Registered Akeli user followers
  RETURN QUERY
  SELECT au.email::text, up.locale, up.first_name
  FROM public.creator_follow cf
  JOIN public.user_profile up ON up.id = cf.user_id
  JOIN auth.users au ON au.id = cf.user_id
  WHERE cf.creator_id = p_creator_id
    AND cf.active = true;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_group_member_count(p_group_id uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COUNT(*)::int FROM group_member WHERE group_id = p_group_id;
$function$
;

CREATE OR REPLACE FUNCTION public.get_group_vector_avg(p_group_id uuid)
 RETURNS TABLE(avg_vector public.vector, sampled bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  RETURN QUERY
  SELECT AVG(uv.vector)::vector(50) as avg_vector, COUNT(*) as sampled
  FROM user_vector uv
  JOIN group_member gm ON gm.user_id = uv.user_id
  WHERE gm.group_id = p_group_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_ingredient_recipes_in_plan(p_meal_plan_id uuid, p_ingredient_id uuid)
 RETURNS TABLE(recipe_id uuid, title text, cover_image_url text, prep_time_min integer, cook_time_min integer)
 LANGUAGE sql
 STABLE
AS $function$
  WITH plan_recipes AS (
    SELECT mpec.recipe_id FROM meal_plan_entry_component mpec
      JOIN meal_plan_entry mpe ON mpe.id = mpec.meal_plan_entry_id
    WHERE mpe.meal_plan_id = p_meal_plan_id AND mpec.recipe_id IS NOT NULL
    UNION
    SELECT recipe_id FROM cooking_session
    WHERE meal_plan_id = p_meal_plan_id AND recipe_id IS NOT NULL
  )
  SELECT DISTINCT r.id, r.title, r.cover_image_url, r.prep_time_min, r.cook_time_min
  FROM recipe r
  JOIN recipe_ingredient ri ON ri.recipe_id = r.id
  WHERE r.id IN (SELECT recipe_id FROM plan_recipes)
    AND ri.ingredient_id = p_ingredient_id;
$function$
;

CREATE OR REPLACE FUNCTION public.get_journey_stats(p_year integer, p_month integer)
 RETURNS json
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id      UUID    := auth.uid();
  v_start_date   DATE;
  v_today        DATE    := CURRENT_DATE;
  v_month_start  DATE    := make_date(p_year, p_month, 1);
  v_month_end    DATE    := (v_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  -- Summary
  v_total_days         INT;
  v_total_planned_days INT := 0;
  v_days_logged        INT := 0;
  v_meals_consumed     INT := 0;
  v_consistency_pct    INT := 0;

  -- Nutrition targets (for goal hit rates only)
  v_calorie_goal  NUMERIC;
  v_protein_goal  NUMERIC;
  v_carb_goal     NUMERIC;
  v_fat_goal      NUMERIC;
  v_days_with_log INT := 0;

  -- Goal hit rates
  v_calorie_hit_pct INT := 0;
  v_protein_hit_pct INT := 0;
  v_carbs_hit_pct   INT := 0;
  v_fat_hit_pct     INT := 0;

  -- Streak
  v_current_streak  INT := 0;
  v_best_streak     INT := 0;

  -- Weight
  v_weight_start   NUMERIC;
  v_weight_current NUMERIC;
  v_weight_target  NUMERIC;

  -- Calendar
  v_calendar JSON;
BEGIN
  -- 1. Start date
  SELECT created_at::DATE INTO v_start_date
  FROM user_profile WHERE id = v_user_id;
  IF v_start_date IS NULL THEN v_start_date := v_today; END IF;

  -- 2. Summary (plan-adherence based)
  v_total_days := GREATEST(1, v_today - v_start_date + 1);

  SELECT COUNT(DISTINCT mpe.scheduled_date)
  INTO v_total_planned_days
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = v_user_id
    AND mpe.scheduled_date BETWEEN v_start_date AND v_today;

  SELECT COUNT(DISTINCT mpe.scheduled_date)
  INTO v_days_logged
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = v_user_id
    AND mpe.is_consumed = TRUE
    AND mpe.scheduled_date BETWEEN v_start_date AND v_today;

  SELECT COUNT(*)
  INTO v_meals_consumed
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id = v_user_id
    AND mpe.is_consumed = TRUE;

  IF v_total_planned_days > 0 THEN
    v_consistency_pct := ROUND(v_days_logged::NUMERIC / v_total_planned_days * 100);
  END IF;

  -- 3. Active nutrition targets
  SELECT calorie_goal, protein_goal_g, carb_goal_g, fat_goal_g
  INTO v_calorie_goal, v_protein_goal, v_carb_goal, v_fat_goal
  FROM nutrition_plan
  WHERE user_id = v_user_id AND is_active = TRUE
  ORDER BY created_at DESC
  LIMIT 1;

  -- 4. Goal hit rates (calorie/macro, from daily_nutrition_log)
  SELECT COUNT(*) INTO v_days_with_log
  FROM daily_nutrition_log
  WHERE user_id = v_user_id
    AND log_date BETWEEN v_start_date AND v_today
    AND calories > 0;

  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND v_days_with_log > 0 THEN
    SELECT
      ROUND(100.0 * SUM(CASE WHEN ABS(calories - v_calorie_goal) / v_calorie_goal <= 0.10 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_protein_goal > 0 AND ABS(protein_g - v_protein_goal) / v_protein_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_carb_goal > 0 AND ABS(carbs_g - v_carb_goal) / v_carb_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*)),
      ROUND(100.0 * SUM(CASE WHEN v_fat_goal > 0 AND ABS(fat_g - v_fat_goal) / v_fat_goal <= 0.15 THEN 1 ELSE 0 END) / COUNT(*))
    INTO v_calorie_hit_pct, v_protein_hit_pct, v_carbs_hit_pct, v_fat_hit_pct
    FROM daily_nutrition_log
    WHERE user_id = v_user_id
      AND log_date BETWEEN v_start_date AND v_today
      AND calories > 0;
  END IF;

  -- 5. Streak (plan-adherence: full completion per day)
  WITH plan_by_day AS (
    SELECT
      mpe.scheduled_date                                           AS d,
      COUNT(*)::INT                                                AS planned,
      SUM(CASE WHEN mpe.is_consumed THEN 1 ELSE 0 END)::INT       AS consumed
    FROM meal_plan_entry mpe
    JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mp.user_id = v_user_id
    GROUP BY mpe.scheduled_date
  ),
  all_days AS (
    SELECT generate_series(v_start_date, v_today, '1 day')::DATE AS d
  ),
  day_status AS (
    SELECT
      ad.d,
      COALESCE(pbd.planned > 0 AND pbd.consumed = pbd.planned, FALSE) AS is_hit
    FROM all_days ad
    LEFT JOIN plan_by_day pbd ON pbd.d = ad.d
  ),
  grp_assigned AS (
    SELECT d, is_hit,
      d - ROW_NUMBER() OVER (PARTITION BY is_hit ORDER BY d)::INT AS grp
    FROM day_status
  ),
  streak_lengths AS (
    SELECT MIN(d) AS s_start, MAX(d) AS s_end, COUNT(*) AS len
    FROM grp_assigned
    WHERE is_hit
    GROUP BY grp
  )
  SELECT
    COALESCE(MAX(len), 0),
    COALESCE(
      (SELECT len FROM streak_lengths WHERE s_end >= v_today - 1 ORDER BY s_end DESC LIMIT 1),
      0
    )
  INTO v_best_streak, v_current_streak
  FROM streak_lengths;

  -- 6. Weight
  SELECT starting_weight_kg, target_weight_kg, weight_kg
  INTO v_weight_start, v_weight_target, v_weight_current
  FROM user_health_profile WHERE user_id = v_user_id;

  SELECT weight_kg INTO v_weight_current
  FROM weight_log WHERE user_id = v_user_id ORDER BY logged_at DESC LIMIT 1;

  IF v_weight_start IS NULL THEN v_weight_start := v_weight_current; END IF;

  -- 7. Calendar (meal-plan adherence per day)
  SELECT json_agg(
    json_build_object(
      'date',     d.day::TEXT,
      'planned',  COALESCE(mc.planned,  0),
      'consumed', COALESCE(mc.consumed, 0)
    )
    ORDER BY d.day
  ) INTO v_calendar
  FROM generate_series(v_month_start, v_month_end, '1 day'::INTERVAL) AS d(day)
  LEFT JOIN (
    SELECT
      mpe.scheduled_date,
      COUNT(*)                                               AS planned,
      SUM(CASE WHEN mpe.is_consumed THEN 1 ELSE 0 END)::INT AS consumed
    FROM meal_plan_entry mpe
    JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mp.user_id = v_user_id
      AND mpe.scheduled_date BETWEEN v_month_start AND v_month_end
    GROUP BY mpe.scheduled_date
  ) mc ON mc.scheduled_date = d.day::DATE;

  -- 8. Return
  RETURN json_build_object(
    'summary', json_build_object(
      'total_days',         v_total_days,
      'total_planned_days', v_total_planned_days,
      'days_logged',        v_days_logged,
      'meals_consumed',     v_meals_consumed,
      'consistency_pct',    v_consistency_pct
    ),
    'streak', json_build_object(
      'current', v_current_streak,
      'best',    v_best_streak
    ),
    'goals', json_build_object(
      'weight_start_kg',   v_weight_start,
      'weight_current_kg', v_weight_current,
      'weight_target_kg',  v_weight_target,
      'calorie_hit_pct',   v_calorie_hit_pct,
      'protein_hit_pct',   v_protein_hit_pct,
      'carbs_hit_pct',     v_carbs_hit_pct,
      'fat_hit_pct',       v_fat_hit_pct
    ),
    'calendar', COALESCE(v_calendar, '[]'::JSON)
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_recipes_by_ingredients(p_ingredient_ids uuid[])
 RETURNS TABLE(recipe_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
    WITH recipe_counts AS (
        SELECT 
            ri.recipe_id, 
            COUNT(ri.ingredient_id) as total_cnt
        FROM public.recipe_ingredient ri
        GROUP BY ri.recipe_id
    ),
    matched_counts AS (
        SELECT 
            ri.recipe_id, 
            COUNT(ri.ingredient_id) as match_cnt
        FROM public.recipe_ingredient ri
        WHERE ri.ingredient_id = ANY(p_ingredient_ids)
        GROUP BY ri.recipe_id
    )
    SELECT 
        mc.recipe_id
    FROM matched_counts mc
    JOIN recipe_counts rc ON mc.recipe_id = rc.recipe_id
    ORDER BY mc.match_cnt DESC, (mc.match_cnt::numeric / rc.total_cnt::numeric) DESC;
$function$
;

CREATE OR REPLACE FUNCTION public.get_saved_recipe_eligibility_progress(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_breakfast_count int;
  v_lunch_count int;
  v_dinner_count int;
  v_is_eligible boolean;
  v_variety_days int;
  v_target_count int;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT is_saved_recipe_eligible, COALESCE(meal_variety_days, 7)
  INTO v_is_eligible, v_variety_days
  FROM user_profile WHERE id = p_user_id;

  v_target_count := CASE WHEN v_variety_days = 0 THEN 7 ELSE v_variety_days * 2 END;

  SELECT count(*) INTO v_breakfast_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'breakfast' = ANY(r.meal_types);

  SELECT count(*) INTO v_lunch_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'lunch' = ANY(r.meal_types);

  SELECT count(*) INTO v_dinner_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'dinner' = ANY(r.meal_types);

  RETURN json_build_object(
    'is_eligible', COALESCE(v_is_eligible, false),
    'progress', json_build_array(
      json_build_object('meal_type', 'breakfast', 'saved_count', v_breakfast_count, 'target_count', v_target_count),
      json_build_object('meal_type', 'lunch', 'saved_count', v_lunch_count, 'target_count', v_target_count),
      json_build_object('meal_type', 'dinner', 'saved_count', v_dinner_count, 'target_count', v_target_count)
    )
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Create user_profile (id = auth user id)
  INSERT INTO public.user_profile (
    id,
    first_name,
    last_name,
    is_creator,
    onboarding_done,
    locale,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    false,
    false,
    COALESCE(NEW.raw_user_meta_data->>'locale', 'fr'),
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.ingredient_quantity_to_grams(p_quantity numeric, p_unit text, p_avg_weight numeric DEFAULT NULL::numeric)
 RETURNS numeric
 LANGUAGE sql
 IMMUTABLE
AS $function$
  SELECT CASE lower(trim(p_unit))
    WHEN 'g'     THEN p_quantity
    WHEN 'kg'    THEN p_quantity * 1000
    WHEN 'ml'    THEN p_quantity           -- 1 ml ≈ 1 g (water-based approx)
    WHEN 'l'     THEN p_quantity * 1000
    WHEN 'cl'    THEN p_quantity * 10
    WHEN 'tsp'   THEN p_quantity * 5
    WHEN 'tbsp'  THEN p_quantity * 15
    WHEN 'pinch' THEN p_quantity * 0.5
    -- count-based: use avg_weight if available
    WHEN 'unit'  THEN CASE WHEN p_avg_weight IS NOT NULL THEN p_quantity * p_avg_weight ELSE NULL END
    WHEN 'piece' THEN CASE WHEN p_avg_weight IS NOT NULL THEN p_quantity * p_avg_weight ELSE NULL END
    WHEN 'clove' THEN CASE WHEN p_avg_weight IS NOT NULL THEN p_quantity * p_avg_weight ELSE NULL END
    WHEN 'bunch' THEN CASE WHEN p_avg_weight IS NOT NULL THEN p_quantity * p_avg_weight ELSE NULL END
    WHEN 'can'   THEN CASE WHEN p_avg_weight IS NOT NULL THEN p_quantity * p_avg_weight ELSE NULL END
    WHEN 'pot'   THEN CASE WHEN p_avg_weight IS NOT NULL THEN p_quantity * p_avg_weight ELSE NULL END
    ELSE NULL
  END
$function$
;

CREATE OR REPLACE FUNCTION public.normalize_recipe_ingredients_to_metric(p_recipe_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    r RECORD;
    v_target_ingredient_id UUID;
BEGIN
    FOR r IN 
        SELECT 
            ri.id as recipe_ingredient_id,
            ri.ingredient_id,
            ri.quantity,
            ri.unit as current_unit,
            i.default_us_unit,
            i.default_metric_unit,
            i.us_to_metric_factor
        FROM public.recipe_ingredient ri
        JOIN public.ingredient i ON ri.ingredient_id = i.id
        WHERE ri.recipe_id = p_recipe_id
    LOOP
        -- Determine if this ingredient needs to be swapped for its international counterpart
        v_target_ingredient_id := r.ingredient_id;
        IF r.ingredient_id = '5df7820c-fafa-4f92-9def-c4fa4bd1c291' THEN -- Wheat Flour (Ounces)
            v_target_ingredient_id := '0bb80446-58e5-43b2-92a0-dba5a0e2914c'; -- Farine de blé
        ELSIF r.ingredient_id = '18e234c6-7b19-4d44-b090-be582bf3bd2b' THEN -- Cornmeal (Ounces)
            v_target_ingredient_id := '16496886-5655-4372-a41a-56198d46e62b'; -- Farine de maïs
        ELSIF r.ingredient_id = 'b6cfd0a8-24d4-4325-9879-8587785ee402' THEN -- Cassava Flour (Ounces)
            v_target_ingredient_id := '10e1c90f-d3f6-4671-8d9e-66de83de5a4f'; -- Farine de manioc
        ELSIF r.ingredient_id = 'a5f80293-4f90-4bf2-9905-057877db9999' THEN -- Teff Flour (Ounces)
            v_target_ingredient_id := '447e1f54-7513-41d9-89e3-319caee3b21a'; -- Farine de teff
        ELSIF r.ingredient_id = 'ebc37455-bfad-471e-9197-3d4544cd8d04' THEN -- Sugar (Ounces)
            v_target_ingredient_id := 'f311de50-07dd-4954-bda3-d04b08c8bddc'; -- Sucre
        END IF;

        -- Convert quantity and update unit to Metric, and swap ingredient_id
        IF r.current_unit = r.default_us_unit AND r.us_to_metric_factor IS NOT NULL THEN
            UPDATE public.recipe_ingredient
            SET 
                quantity = ROUND(r.quantity * r.us_to_metric_factor, 1),
                unit = r.default_metric_unit,
                ingredient_id = v_target_ingredient_id
            WHERE id = r.recipe_ingredient_id;
        ELSIF v_target_ingredient_id != r.ingredient_id THEN
            -- Just swap the ID if it was already metric but used the Ounces ID
            UPDATE public.recipe_ingredient
            SET ingredient_id = v_target_ingredient_id
            WHERE id = r.recipe_ingredient_id;
        END IF;
    END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_creator_newsletter()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  v_key text;
BEGIN
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'newsletter_service_key'
  LIMIT 1;

  IF v_key IS NULL THEN
    RAISE WARNING 'notify_creator_newsletter: vault secret "newsletter_service_key" missing; skipping newsletter dispatch';
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/send-creator-newsletter',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body    := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(NEW),
      'old_record', to_jsonb(OLD)
    ),
    timeout_milliseconds := 5000
  );

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.recalculate_nutrition_plans_from_weight()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_updated_count integer;
BEGIN
  WITH smoothed_weight AS (
    SELECT
      wl.user_id,
      COALESCE(
        AVG(wl.weight_kg) FILTER (WHERE wl.logged_at >= CURRENT_DATE - INTERVAL '7 days'),
        (ARRAY_AGG(wl.weight_kg ORDER BY wl.logged_at DESC, wl.created_at DESC))[1]
      ) AS weight_kg
    FROM weight_log wl
    WHERE wl.logged_at >= CURRENT_DATE - INTERVAL '14 days'
    GROUP BY wl.user_id
  ),
  latest_goal AS (
    SELECT DISTINCT ON (ug.user_id)
      ug.user_id, ug.id AS goal_id, ug.goal_type
    FROM user_goal ug
    WHERE ug.is_active = true
    ORDER BY ug.user_id, ug.created_at DESC
  ),
  candidates AS (
    SELECT
      np.id AS plan_id,
      lg.goal_id,
      hp.user_id,
      sw.weight_kg,
      hp.height_cm,
      DATE_PART('year', AGE(CURRENT_DATE, hp.birth_date))::int AS age,
      hp.sex,
      hp.activity_level,
      lg.goal_type,
      hp.target_weight_kg,
      hp.muscle_goal,
      CASE WHEN hp.target_date IS NULL THEN NULL
           ELSE GREATEST(4, CEIL((hp.target_date - CURRENT_DATE) / 7.0))::int
      END AS remaining_weeks
    FROM user_health_profile hp
    JOIN smoothed_weight sw ON sw.user_id = hp.user_id
    JOIN nutrition_plan np  ON np.user_id = hp.user_id AND np.is_active = true
    JOIN latest_goal lg     ON lg.user_id = hp.user_id
    WHERE hp.height_cm IS NOT NULL
      AND hp.birth_date IS NOT NULL
      AND hp.sex IS NOT NULL
  ),
  computed AS (
    -- LATERAL: zero rows from the calculator (invalid inputs) drops the user.
    SELECT c.*, t.*
    FROM candidates c
    CROSS JOIN LATERAL public.calculate_nutrition_targets(
      c.weight_kg, c.height_cm, c.age, c.sex, c.activity_level,
      c.goal_type, c.target_weight_kg, c.remaining_weeks, c.muscle_goal
    ) t
  ),
  updated_plans AS (
    UPDATE nutrition_plan np
    SET calorie_goal   = f.calorie_goal,
        bmr            = f.bmr,
        tdee           = f.tdee,
        protein_goal_g = f.protein_g,
        carb_goal_g    = f.carb_g,
        fat_goal_g     = f.fat_g
    FROM computed f
    WHERE np.id = f.plan_id
    RETURNING np.id AS plan_id, f.goal_id, f.user_id, f.weight_kg,
              f.calorie_goal, f.protein_g, f.carb_g, f.fat_g
  ),
  updated_goals AS (
    UPDATE user_goal ug
    SET calorie_goal = up.calorie_goal,
        protein_goal = up.protein_g,
        carbs_goal   = up.carb_g,
        fat_goal     = up.fat_g
    FROM updated_plans up
    WHERE ug.id = up.goal_id
    RETURNING ug.id AS goal_id, up.user_id, up.weight_kg
  ),
  updated_profiles AS (
    UPDATE user_health_profile hp
    SET weight_kg = ug2.weight_kg
    FROM updated_goals ug2
    WHERE hp.user_id = ug2.user_id
    RETURNING hp.user_id
  )
  SELECT COUNT(*) INTO v_updated_count FROM updated_profiles;

  RETURN COALESCE(v_updated_count, 0);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.recalculate_recipe_costs(p_country_code text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Clear old costs for this country
  DELETE FROM public.recipe_market_cost WHERE country_code = p_country_code;

  -- Calculate and insert new costs
  INSERT INTO public.recipe_market_cost (recipe_id, country_code, cost_per_100g, total_recipe_cost, updated_at)
  SELECT 
    ri.recipe_id,
    p_country_code,
    -- Cost per 100g of the final cooked dish:
    -- Sum of (ingredient price * portion in grams) / (total recipe weight / 100g)
    SUM(imp.price_per_100g * (COALESCE(ingredient_quantity_to_grams(ri.quantity, ri.unit, i.avg_weight_g), 0) / 100.0)) / NULLIF(rmac.total_weight_g / 100.0, 0),
    -- Total cost to make the whole recipe:
    SUM(imp.price_per_100g * (COALESCE(ingredient_quantity_to_grams(ri.quantity, ri.unit, i.avg_weight_g), 0) / 100.0)),
    NOW()
  FROM public.recipe_ingredient ri
  JOIN public.recipe_macro rmac ON rmac.recipe_id = ri.recipe_id
  JOIN public.ingredient i ON i.id = ri.ingredient_id
  JOIN public.ingredient_market_price imp 
    ON imp.ingredient_id = ri.ingredient_id 
    AND imp.country_code = p_country_code
  WHERE ri.is_optional = false
  GROUP BY ri.recipe_id, rmac.total_weight_g;
END;
$function$
;

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


CREATE OR REPLACE FUNCTION public.refresh_all_recipe_macros()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_count int := 0;
  v_recipe_id uuid;
BEGIN
  FOR v_recipe_id IN SELECT id FROM recipe LOOP
    PERFORM refresh_recipe_macros(v_recipe_id);
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_recipe_allergen_tags()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  affected_ingredient_id uuid;
BEGIN
  affected_ingredient_id := COALESCE(NEW.ingredient_id, OLD.ingredient_id);

  UPDATE recipe r
  SET allergen_tags = (
    SELECT COALESCE(array_agg(DISTINCT a.slug), '{}')
    FROM recipe_ingredient ri
    JOIN ingredient_allergen ia ON ia.ingredient_id = ri.ingredient_id
    JOIN allergen a ON a.id = ia.allergen_id
    WHERE ri.recipe_id = r.id
  )
  WHERE r.id IN (
    SELECT DISTINCT ri.recipe_id
    FROM recipe_ingredient ri
    WHERE ri.ingredient_id = affected_ingredient_id
  );

  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_recipe_macros(p_recipe_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_macros json;
BEGIN
  v_macros := calculate_recipe_macros(p_recipe_id);

  INSERT INTO recipe_macro (id, recipe_id, calories, protein_g, carbs_g, fat_g, updated_at)
  VALUES (gen_random_uuid(), p_recipe_id,
    (v_macros->>'calories')::numeric,
    (v_macros->>'protein_g')::numeric,
    (v_macros->>'carbs_g')::numeric,
    (v_macros->>'fat_g')::numeric,
    now()
  )
  ON CONFLICT (recipe_id) DO UPDATE
  SET calories = EXCLUDED.calories,
      protein_g = EXCLUDED.protein_g,
      carbs_g = EXCLUDED.carbs_g,
      fat_g = EXCLUDED.fat_g,
      updated_at = now();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_recipe_per_100g(p_recipe_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_total_weight  numeric := 0;
  v_total_cal     numeric := 0;
  v_total_protein numeric := 0;
  v_total_carbs   numeric := 0;
  v_total_fat     numeric := 0;
  v_row           record;
  v_weight_g      numeric;
BEGIN
  -- Accumulate weight and macros across all ingredients
  FOR v_row IN
    SELECT
      ri.quantity,
      ri.unit,
      ing.avg_weight_g,
      ing.calories_per_100g,
      ing.protein_per_100g,
      ing.carbs_per_100g,
      ing.fat_per_100g
    FROM recipe_ingredient ri
    JOIN ingredient ing ON ing.id = ri.ingredient_id
    WHERE ri.recipe_id = p_recipe_id
  LOOP
    v_weight_g := ingredient_quantity_to_grams(v_row.quantity, v_row.unit, v_row.avg_weight_g);
    IF v_weight_g IS NOT NULL AND v_weight_g > 0 THEN
      v_total_weight  := v_total_weight  + v_weight_g;
      IF v_row.calories_per_100g IS NOT NULL THEN
        v_total_cal     := v_total_cal     + (v_weight_g * v_row.calories_per_100g / 100);
      END IF;
      IF v_row.protein_per_100g IS NOT NULL THEN
        v_total_protein := v_total_protein + (v_weight_g * v_row.protein_per_100g  / 100);
      END IF;
      IF v_row.carbs_per_100g IS NOT NULL THEN
        v_total_carbs   := v_total_carbs   + (v_weight_g * v_row.carbs_per_100g    / 100);
      END IF;
      IF v_row.fat_per_100g IS NOT NULL THEN
        v_total_fat     := v_total_fat     + (v_weight_g * v_row.fat_per_100g      / 100);
      END IF;
    END IF;
  END LOOP;

  -- Upsert into recipe_macro
  IF v_total_weight > 0 THEN
    INSERT INTO recipe_macro (recipe_id, total_weight_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g)
    VALUES (
      p_recipe_id,
      v_total_weight,
      ROUND(v_total_cal     / v_total_weight * 100, 2),
      ROUND(v_total_protein / v_total_weight * 100, 2),
      ROUND(v_total_carbs   / v_total_weight * 100, 2),
      ROUND(v_total_fat     / v_total_weight * 100, 2)
    )
    ON CONFLICT (recipe_id) DO UPDATE SET
      total_weight_g    = EXCLUDED.total_weight_g,
      calories_per_100g = EXCLUDED.calories_per_100g,
      protein_per_100g  = EXCLUDED.protein_per_100g,
      carbs_per_100g    = EXCLUDED.carbs_per_100g,
      fat_per_100g      = EXCLUDED.fat_per_100g;
  ELSE
    -- No computable weight — clear stale per-100g values
    UPDATE recipe_macro SET
      total_weight_g    = NULL,
      calories_per_100g = NULL,
      protein_per_100g  = NULL,
      carbs_per_100g    = NULL,
      fat_per_100g      = NULL
    WHERE recipe_id = p_recipe_id;
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.replace_recipe_steps(p_recipe_id uuid, p_steps jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_count integer;
  v_role  text := COALESCE(auth.jwt() ->> 'role', 'none'); -- 'none' = direct DB connection (psql, cron, tests)
BEGIN
  IF v_role NOT IN ('service_role', 'none') THEN
    IF NOT EXISTS (
      SELECT 1 FROM recipe r
      JOIN creator c ON c.id = r.creator_id
      WHERE r.id = p_recipe_id AND c.user_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'replace_recipe_steps: caller does not own recipe %', p_recipe_id
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  IF p_steps IS NULL OR jsonb_typeof(p_steps) <> 'array' OR jsonb_array_length(p_steps) = 0 THEN
    RAISE EXCEPTION 'replace_recipe_steps: p_steps must be a non-empty JSON array';
  END IF;

  DELETE FROM public.recipe_step WHERE recipe_id = p_recipe_id;

  INSERT INTO public.recipe_step
    (recipe_id, step_number, sort_order, title, content, image_url, timer_seconds, is_section_header, ingredient_ids)
  SELECT
    p_recipe_id,
    (s->>'step_number')::int,
    (s->>'sort_order')::int,
    NULLIF(s->>'title', ''),
    NULLIF(s->>'content', ''),
    NULLIF(s->>'image_url', ''),
    NULLIF(s->>'timer_seconds', '')::int,
    COALESCE((s->>'is_section_header')::boolean, false),
    COALESCE(
      (SELECT array_agg(x::uuid) FROM jsonb_array_elements_text(s->'ingredient_ids') AS x),
      '{}'::uuid[]
    )
  FROM jsonb_array_elements(p_steps) AS s;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.respond_conversation_request(p_request_id uuid, p_action text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_request         record;
  v_conversation_id uuid;
BEGIN
  IF p_action NOT IN ('accepted', 'rejected') THEN
    RAISE EXCEPTION 'Invalid action: %', p_action;
  END IF;

  SELECT * INTO v_request
  FROM conversation_request
  WHERE id = p_request_id
    AND recipient_id = auth.uid()
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found or not authorized';
  END IF;

  UPDATE conversation_request
  SET status = p_action, responded_at = now()
  WHERE id = p_request_id;

  IF p_action = 'accepted' THEN
    INSERT INTO conversation (type, created_by)
    VALUES ('private', auth.uid())
    RETURNING id INTO v_conversation_id;

    INSERT INTO conversation_participant (conversation_id, user_id)
    VALUES
      (v_conversation_id, v_request.requester_id),
      (v_conversation_id, v_request.recipient_id);

    RETURN jsonb_build_object('conversation_id', v_conversation_id);
  END IF;

  RETURN jsonb_build_object('status', p_action);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.round_to_step(qty numeric, step numeric)
 RETURNS numeric
 LANGUAGE sql
 IMMUTABLE
AS $function$
  SELECT CASE
    WHEN step IS NULL OR step = 0 THEN qty
    WHEN qty = 0                  THEN 0
    ELSE GREATEST(step, ROUND(qty / step) * step)
  END;
$function$
;

CREATE OR REPLACE FUNCTION public.search_allergens(p_query text)
 RETURNS TABLE(id uuid, slug text, label_fr text, label_en text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  SELECT id, slug, label_fr, label_en
  FROM allergen
  WHERE is_active = true
    AND (label_fr ILIKE '%' || p_query || '%' OR label_en ILIKE '%' || p_query || '%')
  ORDER BY label_fr
  LIMIT 10;
$function$
;

CREATE OR REPLACE FUNCTION public.search_recipes(p_query text DEFAULT NULL::text, p_region text DEFAULT NULL::text, p_difficulty text DEFAULT NULL::text, p_tag_ids uuid[] DEFAULT NULL::uuid[], p_max_time integer DEFAULT NULL::integer, p_order_by text DEFAULT 'recent'::text, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
 RETURNS TABLE(id uuid, title text, description text, cover_image_url text, region text, difficulty text, prep_time_min integer, cook_time_min integer, servings integer, creator_id uuid, creator_name text, creator_avatar text, calories numeric, like_count bigint, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = auth.uid()
  )
  SELECT
    r.id, r.title, r.description, r.cover_image_url, r.region, r.difficulty, r.prep_time_min, r.cook_time_min, r.servings, r.creator_id, c.display_name, c.avatar_url, rm.calories, COUNT(rl.recipe_id)::bigint AS like_count, r.created_at
  FROM recipe r
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  WHERE r.is_published = true
    AND (p_query IS NULL OR (r.title ILIKE '%' || p_query || '%' OR r.description ILIKE '%' || p_query || '%'))
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    AND (p_tag_ids IS NULL OR (
      SELECT COUNT(*) FROM recipe_tag rt
      WHERE rt.recipe_id = r.id AND rt.tag_id = ANY(p_tag_ids)
    ) = array_length(p_tag_ids, 1))
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories
  ORDER BY
    CASE WHEN p_order_by = 'popular' THEN COUNT(rl.recipe_id) END DESC,
    CASE WHEN p_order_by = 'quick'   THEN COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0) END ASC,
    CASE WHEN p_order_by = 'recent' OR p_order_by IS NULL THEN r.created_at END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_meal_consumption_scheduled_date()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.meal_plan_entry_id IS NOT NULL THEN
    SELECT scheduled_date INTO NEW.scheduled_date
    FROM meal_plan_entry
    WHERE id = NEW.meal_plan_entry_id;
  END IF;

  IF NEW.scheduled_date IS NULL THEN
    NEW.scheduled_date := DATE(NEW.consumed_at);
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_nutrition_plan_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_recipe_development_version()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  SELECT COALESCE(MAX(version), 0) + 1
  INTO NEW.version
  FROM public.recipe_development
  WHERE recipe_id = NEW.recipe_id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.swap_meal_plan_entry(p_entry_id uuid, p_new_recipe_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id              uuid;
  v_plan_id              uuid;
  v_meals_per_day        int;
  v_entry_meal_type      text;
  v_entry_date           date;
  v_calorie_goal         numeric;
  v_target_meal_calories numeric;
  v_min_g                integer := 50;
  v_max_g                integer := 1500;
  v_kcal_per_100g        numeric;
  v_protein_per_100g     numeric;
  v_carbs_per_100g       numeric;
  v_fat_per_100g         numeric;
  v_total_weight_g       numeric;
  v_grams                integer := 300;
BEGIN
  SELECT mp.user_id, mp.id, mpe.scheduled_date, mpe.meal_type
  INTO   v_user_id, v_plan_id, v_entry_date, v_entry_meal_type
  FROM   meal_plan_entry mpe JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE  mpe.id = p_entry_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized or entry not found';
  END IF;

  SELECT COUNT(*) INTO v_meals_per_day FROM meal_plan_entry
  WHERE meal_plan_id = v_plan_id AND scheduled_date = v_entry_date;
  IF v_meals_per_day = 0 THEN v_meals_per_day := 3; END IF;

  SELECT calorie_goal INTO v_calorie_goal FROM user_goal
  WHERE user_id = v_user_id AND is_active = true ORDER BY created_at DESC LIMIT 1;

  SELECT rm.calories_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g, rm.total_weight_g
  INTO   v_kcal_per_100g, v_protein_per_100g, v_carbs_per_100g, v_fat_per_100g, v_total_weight_g
  FROM   recipe_macro rm WHERE rm.recipe_id = p_new_recipe_id;

  SELECT md.calorie_target, COALESCE(md.min_portion_g, 50), COALESCE(md.max_portion_g, 1500)
  INTO   v_target_meal_calories, v_min_g, v_max_g
  FROM   meal_distribution md JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
  WHERE  np.user_id = v_user_id AND np.is_active = true AND md.meal_type = v_entry_meal_type LIMIT 1;

  IF v_target_meal_calories IS NULL AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
    v_target_meal_calories := v_calorie_goal / v_meals_per_day;
  END IF;

  IF v_target_meal_calories IS NOT NULL AND v_kcal_per_100g > 0 THEN
    v_grams := GREATEST(v_min_g, LEAST(v_max_g,
      ROUND(v_target_meal_calories / (v_kcal_per_100g / 100))::integer));
  END IF;

  UPDATE meal_plan_entry SET
    servings           = v_grams,
    calories_computed  = ROUND((COALESCE(v_kcal_per_100g,    0) * v_grams / 100)::numeric, 1),
    protein_g_computed = ROUND((COALESCE(v_protein_per_100g, 0) * v_grams / 100)::numeric, 1),
    carbs_g_computed   = ROUND((COALESCE(v_carbs_per_100g,   0) * v_grams / 100)::numeric, 1),
    fat_g_computed     = ROUND((COALESCE(v_fat_per_100g,     0) * v_grams / 100)::numeric, 1)
  WHERE id = p_entry_id;

  DELETE FROM meal_plan_entry_component WHERE meal_plan_entry_id = p_entry_id;
  INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
  VALUES (p_entry_id, p_new_recipe_id, 'base', 1.0);

  DELETE FROM meal_ingredient WHERE meal_plan_entry_id = p_entry_id;
  INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
  SELECT p_entry_id, ri.ingredient_id, COALESCE(i.name_fr, i.name),
    round_to_step(ri.quantity * v_grams / NULLIF(v_total_weight_g, 0),
      COALESCE((SELECT rounding_step FROM ingredient_rounding_rule WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
               (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit))),
    ri.unit
  FROM recipe_ingredient ri JOIN ingredient i ON i.id = ri.ingredient_id
  WHERE ri.recipe_id = p_new_recipe_id AND ri.is_optional = false AND ri.ingredient_id IS NOT NULL;

  PERFORM generate_shopping_list(v_plan_id);
  PERFORM create_batch_sessions(v_plan_id, v_user_id, 7);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.swap_meal_plan_entry_custom(p_entry_id uuid, p_meal_name text, p_calories numeric, p_protein_g numeric DEFAULT NULL::numeric, p_carbs_g numeric DEFAULT NULL::numeric, p_fat_g numeric DEFAULT NULL::numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id  uuid;
  v_plan_id  uuid;
BEGIN
  -- 1. Ownership check
  SELECT mp.user_id, mp.id
    INTO v_user_id, v_plan_id
  FROM meal_plan_entry mpe
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mpe.id = p_entry_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized or entry not found';
  END IF;

  -- 2. Remove existing recipe-backed components and their ingredient rows
  DELETE FROM meal_plan_entry_component
  WHERE meal_plan_entry_id = p_entry_id;

  DELETE FROM meal_ingredient
  WHERE meal_plan_entry_id = p_entry_id;

  -- 3. Write custom macro overrides onto the entry
  UPDATE meal_plan_entry SET
    is_custom_meal   = true,
    custom_meal_name = p_meal_name,
    custom_calories  = p_calories,
    custom_protein_g = p_protein_g,
    custom_carbs_g   = p_carbs_g,
    custom_fat_g     = p_fat_g
  WHERE id = p_entry_id;

  -- 4. Re-sync nutrition log if this entry was already consumed.
  --    sync_daily_nutrition_for_date fires on meal_consumption UPDATE and
  --    re-reads custom_calories/macros via COALESCE. The no-op value
  --    assignment is intentional — it triggers the trigger without changing data.
  UPDATE meal_consumption
  SET consumption_value = consumption_value
  WHERE meal_plan_entry_id = p_entry_id;

  -- 5. Regenerate shopping list (custom meals have no ingredients to include)
  PERFORM generate_shopping_list(v_plan_id);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_calorie_target_on_dist_change()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_calorie_goal integer;
BEGIN
    SELECT calorie_goal INTO v_calorie_goal
    FROM public.nutrition_plan
    WHERE id = NEW.nutrition_plan_id;

    IF v_calorie_goal IS NOT NULL THEN
        NEW.calorie_target := (v_calorie_goal * NEW.calorie_pct / 100.0);
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_calorie_target_on_plan_update()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.calorie_goal IS DISTINCT FROM OLD.calorie_goal THEN
        UPDATE public.meal_distribution
        SET calorie_target = (NEW.calorie_goal * calorie_pct / 100.0)
        WHERE nutrition_plan_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_daily_nutrition_for_date()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_date   date;
  v_user   uuid;
BEGIN
  v_date := CASE WHEN TG_OP = 'DELETE' THEN OLD.scheduled_date ELSE NEW.scheduled_date END;
  v_user := CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id        ELSE NEW.user_id        END;

  -- Full recompute from all remaining meal_consumption rows for this user+date.
  INSERT INTO daily_nutrition_log (user_id, log_date, calories, protein_g, carbs_g, fat_g, fiber_g, meals_count)
  SELECT
    mc.user_id,
    v_date,
    SUM(COALESCE(mpe.custom_calories,  mpe.calories_computed,  COALESCE(rm.calories,  0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.custom_protein_g, mpe.protein_g_computed, COALESCE(rm.protein_g, 0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.custom_carbs_g,   mpe.carbs_g_computed,   COALESCE(rm.carbs_g,   0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(mpe.custom_fat_g,     mpe.fat_g_computed,     COALESCE(rm.fat_g,     0) * mc.servings) * mc.consumption_value),
    SUM(COALESCE(rm.fiber_g, 0) * mc.servings * mc.consumption_value),
    SUM(mc.consumption_value)
  FROM meal_consumption mc
  LEFT JOIN meal_plan_entry mpe ON mpe.id = mc.meal_plan_entry_id
  LEFT JOIN recipe_macro    rm  ON rm.recipe_id = mc.recipe_id
  WHERE mc.user_id       = v_user
    AND mc.scheduled_date = v_date
  GROUP BY mc.user_id
  ON CONFLICT (user_id, log_date) DO UPDATE SET
    calories    = EXCLUDED.calories,
    protein_g   = EXCLUDED.protein_g,
    carbs_g     = EXCLUDED.carbs_g,
    fat_g       = EXCLUDED.fat_g,
    fiber_g     = EXCLUDED.fiber_g,
    meals_count = EXCLUDED.meals_count,
    updated_at  = now();

  -- If no meal_consumption rows remain for this user+date (e.g. last row was
  -- deleted), the SELECT above returns nothing and the upsert never fires.
  -- Explicitly zero out the log so stale values don't persist.
  INSERT INTO daily_nutrition_log (user_id, log_date, calories, protein_g, carbs_g, fat_g, fiber_g, meals_count)
  SELECT v_user, v_date, 0, 0, 0, 0, 0, 0
  WHERE NOT EXISTS (
    SELECT 1 FROM meal_consumption
    WHERE user_id       = v_user
      AND scheduled_date = v_date
  )
  ON CONFLICT (user_id, log_date) DO UPDATE SET
    calories    = 0,
    protein_g   = 0,
    carbs_g     = 0,
    fat_g       = 0,
    fiber_g     = 0,
    meals_count = 0,
    updated_at  = now();

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_conversion(p_ingredient_id uuid, p_quantity numeric, p_from_system text, p_to_system text)
 RETURNS TABLE(converted_quantity numeric, target_unit text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_metric_unit TEXT;
    v_us_unit TEXT;
    v_factor NUMERIC;
BEGIN
    -- Look up the rules for the specific ingredient
    SELECT default_metric_unit, default_us_unit, us_to_metric_factor
    INTO v_metric_unit, v_us_unit, v_factor
    FROM public.test_ingredient
    WHERE id = p_ingredient_id;

    -- Do the conversion math
    IF p_from_system = 'us' AND p_to_system = 'metric' THEN
        RETURN QUERY SELECT ROUND(p_quantity * v_factor, 1), v_metric_unit;
    ELSIF p_from_system = 'metric' AND p_to_system = 'us' THEN
        RETURN QUERY SELECT ROUND(p_quantity / v_factor, 2), v_us_unit;
    ELSE
        -- No conversion needed, just return original system
        IF p_from_system = 'us' THEN
            RETURN QUERY SELECT p_quantity, v_us_unit;
        ELSE
            RETURN QUERY SELECT p_quantity, v_metric_unit;
        END IF;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_evaluate_saved_recipe_eligibility()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.evaluate_saved_recipe_eligibility(OLD.user_id);
    RETURN OLD;
  ELSIF TG_OP = 'INSERT' THEN
    PERFORM public.evaluate_saved_recipe_eligibility(NEW.user_id);
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_evaluate_saved_recipe_eligibility_on_variety_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public.evaluate_saved_recipe_eligibility(NEW.id);
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_guard_use_saved_recipes_only()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.use_saved_recipes_only = true AND COALESCE(NEW.is_saved_recipe_eligible, false) = false THEN
    NEW.use_saved_recipes_only := false;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_ingredient_refresh_recipes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Only refresh if nutritional columns or avg_weight_g changed
  IF (NEW.calories_per_100g IS DISTINCT FROM OLD.calories_per_100g
   OR NEW.protein_per_100g  IS DISTINCT FROM OLD.protein_per_100g
   OR NEW.carbs_per_100g    IS DISTINCT FROM OLD.carbs_per_100g
   OR NEW.fat_per_100g      IS DISTINCT FROM OLD.fat_per_100g
   OR NEW.avg_weight_g      IS DISTINCT FROM OLD.avg_weight_g) THEN
    PERFORM refresh_recipe_per_100g(recipe_id)
    FROM recipe_ingredient
    WHERE ingredient_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_meal_entry_portions_used()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.is_consumed = OLD.is_consumed THEN
    RETURN NEW;
  END IF;

  IF NEW.is_consumed = TRUE THEN
    UPDATE cooking_session cs
    SET portions_used = cs.portions_used + 1
    FROM meal_plan_entry_component mec
    WHERE mec.meal_plan_entry_id = NEW.id
      AND mec.cooking_session_id IS NOT NULL
      AND mec.cooking_session_id = cs.id;
  ELSE
    UPDATE cooking_session cs
    SET portions_used = GREATEST(0, cs.portions_used - 1)
    FROM meal_plan_entry_component mec
    WHERE mec.meal_plan_entry_id = NEW.id
      AND mec.cooking_session_id IS NOT NULL
      AND mec.cooking_session_id = cs.id;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_recipe_comment_stats()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_recipe_id uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_recipe_id := OLD.recipe_id;
  ELSE
    v_recipe_id := NEW.recipe_id;
  END IF;

  IF v_recipe_id IS NOT NULL THEN
    UPDATE public.recipe
    SET comment_count = (
      SELECT COUNT(*)
      FROM public.recipe_comment
      WHERE recipe_id = v_recipe_id
    )
    WHERE id = v_recipe_id;
  END IF;

  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_recipe_create_macro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  INSERT INTO recipe_macro (recipe_id)
  VALUES (NEW.id)
  ON CONFLICT (recipe_id) DO NOTHING;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_recipe_ingredient_per_100g()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM refresh_recipe_per_100g(OLD.recipe_id);
  ELSE
    PERFORM refresh_recipe_per_100g(NEW.recipe_id);
  END IF;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_recipe_like_count()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.recipe
    SET like_count = like_count + 1
    WHERE id = NEW.recipe_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.recipe
    SET like_count = GREATEST(like_count - 1, 0)
    WHERE id = OLD.recipe_id;
  END IF;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_recipe_rating_stats()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_recipe_id uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_recipe_id := OLD.recipe_id;
  ELSE
    v_recipe_id := NEW.recipe_id;
  END IF;

  IF v_recipe_id IS NULL THEN
    RETURN NULL;
  END IF;

  UPDATE public.recipe
  SET
    average_rating = COALESCE(
      (SELECT ROUND(AVG(rc.rating)::numeric, 2)
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating IS NOT NULL),
      0
    ),
    rating_count = COALESCE(
      (SELECT COUNT(*)::integer
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating IS NOT NULL),
      0
    ),
    average_rating_taste = COALESCE(
      (SELECT ROUND(AVG(rc.rating_taste)::numeric, 2)
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating_taste IS NOT NULL),
      0
    ),
    average_rating_ease = COALESCE(
      (SELECT ROUND(AVG(rc.rating_ease)::numeric, 2)
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating_ease IS NOT NULL),
      0
    ),
    average_rating_satiety = COALESCE(
      (SELECT ROUND(AVG(rc.rating_satiety)::numeric, 2)
       FROM public.recipe_comment rc
       WHERE rc.recipe_id = v_recipe_id
         AND rc.rating_satiety IS NOT NULL),
      0
    )
  WHERE id = v_recipe_id;

  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_fn_recipe_save_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE recipe SET save_count = save_count + 1 WHERE id = NEW.recipe_id;
    RETURN NEW;
  ELSE
    UPDATE recipe SET save_count = GREATEST(save_count - 1, 0) WHERE id = OLD.recipe_id;
    RETURN OLD;
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_recipe_auto_translate()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.trigger_sync_creator_to_v0()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  PERFORM net.http_post(
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/sync-creator-to-v0',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qenFjZnRqenNrd2NwZm9yd3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0ODQzMzcsImV4cCI6MjA4ODA2MDMzN30.hnbx0os7WVRZpDP9_EmxMqFH3cN0aypQg1SvBgWtEmk'
    ),
    body    := jsonb_build_object('creator_id', NEW.id)
  );

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trigger_sync_recipe_to_v0()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  _event    text;
  _recipe_id uuid;
  _payload  jsonb;
BEGIN
  -- Determine event type and recipe_id
  IF TG_OP = 'DELETE' THEN
    _event     := 'DELETE';
    _recipe_id := OLD.id;
    _payload   := jsonb_build_object('event', _event, 'recipe_id', _recipe_id);

  ELSIF TG_OP = 'INSERT' THEN
    -- Only fire for newly published recipes
    IF NEW.is_published IS NOT TRUE THEN
      RETURN NEW;
    END IF;
    _event     := 'PUBLISH';
    _recipe_id := NEW.id;
    _payload   := jsonb_build_object('event', _event, 'recipe_id', _recipe_id);

  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.is_published = TRUE AND NEW.is_published = FALSE THEN
      -- Recipe was unpublished
      _event := 'UNPUBLISH';
    ELSIF NEW.is_published = TRUE THEN
      -- Published recipe was updated (or newly published via update)
      _event := 'UPDATE';
    ELSE
      -- Draft updated — not relevant for V0
      RETURN NEW;
    END IF;
    _recipe_id := NEW.id;
    _payload   := jsonb_build_object('event', _event, 'recipe_id', _recipe_id);
  END IF;

  -- Fire async HTTP POST to edge function (non-blocking)
  PERFORM net.http_post(
    url     := 'https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/sync-recipe-to-v0',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qenFjZnRqenNrd2NwZm9yd3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0ODQzMzcsImV4cCI6MjA4ODA2MDMzN30.hnbx0os7WVRZpDP9_EmxMqFH3cN0aypQg1SvBgWtEmk'
    ),
    body    := _payload
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_blog_comment_count()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.parent_id IS NULL THEN
    UPDATE public.blog_post SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NULL THEN
    UPDATE public.blog_post SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_blog_like_count()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.blog_post SET like_count = like_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.blog_post SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_creator_recipe_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    -- Recalculer le créateur de la recette supprimée
    IF OLD.creator_id IS NOT NULL THEN
      UPDATE creator SET recipe_count = (
        SELECT COUNT(*) FROM recipe
        WHERE creator_id = OLD.creator_id AND is_published = true
      ) WHERE id = OLD.creator_id;
    END IF;
    RETURN OLD;

  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.creator_id IS DISTINCT FROM NEW.creator_id THEN
      IF OLD.creator_id IS NOT NULL THEN
        UPDATE creator SET recipe_count = (
          SELECT COUNT(*) FROM recipe
          WHERE creator_id = OLD.creator_id AND is_published = true
        ) WHERE id = OLD.creator_id;
      END IF;
      IF NEW.creator_id IS NOT NULL THEN
        UPDATE creator SET recipe_count = (
          SELECT COUNT(*) FROM recipe
          WHERE creator_id = NEW.creator_id AND is_published = true
        ) WHERE id = NEW.creator_id;
      END IF;
    ELSIF OLD.is_published IS DISTINCT FROM NEW.is_published THEN
      IF NEW.creator_id IS NOT NULL THEN
        UPDATE creator SET recipe_count = (
          SELECT COUNT(*) FROM recipe
          WHERE creator_id = NEW.creator_id AND is_published = true
        ) WHERE id = NEW.creator_id;
      END IF;
    END IF;
    RETURN NEW;

  ELSIF TG_OP = 'INSERT' THEN
    IF NEW.is_published = true AND NEW.creator_id IS NOT NULL THEN
      UPDATE creator SET recipe_count = (
        SELECT COUNT(*) FROM recipe
        WHERE creator_id = NEW.creator_id AND is_published = true
      ) WHERE id = NEW.creator_id;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NULL;
END;
$function$
;

CREATE TRIGGER on_blog_post_published_newsletter AFTER UPDATE ON public.blog_post FOR EACH ROW WHEN (((old.is_published IS DISTINCT FROM new.is_published) AND (new.is_published = true))) EXECUTE FUNCTION public.notify_creator_newsletter();

CREATE TRIGGER on_recipe_published_newsletter AFTER UPDATE ON public.recipe FOR EACH ROW WHEN (((NOT (old.is_published AND old.show_on_website)) AND (new.is_published AND new.show_on_website))) EXECUTE FUNCTION public.notify_creator_newsletter();


  create policy "Anyone can read avatars"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'avatars'::text));



  create policy "Anyone can read recipe images"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'recipe-images'::text));



  create policy "Anyone reads post images"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'post-images'::text));



  create policy "Authenticated users can upload avatars"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'avatars'::text));



  create policy "Authenticated users can upload recipe images"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'recipe-images'::text));



  create policy "Creators delete their own post images"
  on "storage"."objects"
  as permissive
  for delete
  to public
using (((bucket_id = 'post-images'::text) AND (((storage.foldername(name))[1])::uuid IN ( SELECT bp.id
   FROM (public.blog_post bp
     JOIN public.creator c ON ((c.id = bp.creator_id)))
  WHERE (c.user_id = auth.uid())))));



  create policy "Creators update their own post images"
  on "storage"."objects"
  as permissive
  for update
  to public
using (((bucket_id = 'post-images'::text) AND (((storage.foldername(name))[1])::uuid IN ( SELECT bp.id
   FROM (public.blog_post bp
     JOIN public.creator c ON ((c.id = bp.creator_id)))
  WHERE (c.user_id = auth.uid())))));



  create policy "Creators upload their own post images"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'post-images'::text) AND (((storage.foldername(name))[1])::uuid IN ( SELECT bp.id
   FROM (public.blog_post bp
     JOIN public.creator c ON ((c.id = bp.creator_id)))
  WHERE (c.user_id = auth.uid())))));



  create policy "Public read ingredient images"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'ingredient-images'::text));



  create policy "Service role can upload ingredient images"
  on "storage"."objects"
  as permissive
  for insert
  to service_role
with check ((bucket_id = 'ingredient-images'::text));



  create policy "Users can delete their own recipe images"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using ((bucket_id = 'recipe-images'::text));



  create policy "Users can update their own avatar"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using ((bucket_id = 'avatars'::text));



  create policy "Users can update their own recipe images"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using ((bucket_id = 'recipe-images'::text));



