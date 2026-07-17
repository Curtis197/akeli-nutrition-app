-- Reconciles the local dev schema with the ACTUAL live schema on prod (project
-- njzqcftjzskwcpforwzf). Generated 2026-07-17 via
--   supabase db diff --linked --schema public -f reconcile_local_with_prod_schema
-- comparing a fresh shadow DB (built by replaying every migration in this
-- directory) against prod directly.
--
-- Local dev has drifted from prod for a long time: this repo contains many
-- migrations named "local_only_stub" / "remote_applied" in prod's tracking
-- table (schema_migrations.statements is NULL for all of them — inserted via
-- `supabase migration repair`, not by actually running SQL), which are almost
-- certainly artifacts of past manual/dashboard changes on prod that were never
-- captured as migration files. This migration is NOT an attempt to reconstruct
-- that lost history — it is a snapshot reconciliation: "make a fresh local DB's
-- schema match what prod actually has right now," full stop.
--
-- Confirmed 100% no-op on prod (it already has this exact schema by
-- definition — this is LOCAL-ONLY tooling, never apply to prod).
--
-- Known concrete drift this closes (non-exhaustive): recipe_macro had
-- kcal_per_100g (generated) locally instead of prod's real calories_per_100g
-- column, which blocked generate_feed_personalized from running locally at
-- all (see supabase/tests/deferred_unpublish_test.sql and memory
-- local-prod-schema-drift.md). Also reconciles an entire creator-monetization
-- schema evolution (creator_payout table dropped in favor of columns on
-- payout/creator_balance/creator_revenue_log) and an ingredient-catalog
-- enrichment (descriptions, tags, image_url, US/metric unit defaults) that
-- happened on prod with no corresponding migration files anywhere in this repo.
--
-- One hand-fix applied below: migra's default drop order for
-- creator_revenue_log fails because total_revenue (generated) depends on
-- consumption_revenue — reordered to drop the dependent column first.
--
-- NOT addressed here (deliberately, needs a human decision first): prod's
-- migration bookkeeping table (supabase_migrations.schema_migrations) has
-- ~14 entries whose registered version number doesn't match any local
-- filename's embedded timestamp — 4 from this session (caused by using the
-- Supabase MCP apply_migration tool, which registers its own call-time
-- timestamp as the version instead of parsing one from the migration name)
-- plus 5 that predate this session. `supabase db pull`/`db push` will refuse
-- to run against this project until that's reconciled via `supabase
-- migration repair`. Not done here because marking the wrong version
-- "reverted" could make a future `db push` try to replay already-live DDL
-- against prod — see the deferred-unpublish SDD ledger for the exact
-- version/name pairs and the open question about the 5 pre-session ones.

create extension if not exists "pg_trgm" with schema "public";

create extension if not exists "unaccent" with schema "public";

drop trigger if exists "trg_ai_conversation_updated_at" on "public"."ai_conversation";

drop trigger if exists "trg_community_group_updated_at" on "public"."community_group";

drop trigger if exists "trg_conversation_request_updated_at" on "public"."conversation_request";

drop trigger if exists "trg_creator_updated_at" on "public"."creator";

drop trigger if exists "trg_fan_subscription_updated_at" on "public"."fan_subscription";

drop trigger if exists "trg_group_member_count" on "public"."group_member";

drop trigger if exists "trg_meal_plan_updated_at" on "public"."meal_plan";

drop trigger if exists "trg_push_token_updated_at" on "public"."push_token";

drop trigger if exists "trg_recipe_updated_at" on "public"."recipe";

drop trigger if exists "trg_recipe_comment_updated_at" on "public"."recipe_comment";

drop trigger if exists "trg_recipe_macro_updated_at" on "public"."recipe_macro";

drop trigger if exists "trg_subscription_updated_at" on "public"."subscription";

drop trigger if exists "trg_user_cuisine_preference_updated_at" on "public"."user_cuisine_preference";

drop trigger if exists "trg_user_health_profile_updated_at" on "public"."user_health_profile";

drop trigger if exists "trg_user_profile_updated_at" on "public"."user_profile";

drop trigger if exists "trg_fan_count" on "public"."fan_subscription";

drop policy "owner only ai_conversation" on "public"."ai_conversation";

drop policy "owner inserts ai_message" on "public"."ai_message";

drop policy "owner via conversation ai_message" on "public"."ai_message";

drop policy "participant reads chat_message" on "public"."chat_message";

drop policy "participant sends chat_message" on "public"."chat_message";

drop policy "participant only conversation_participant" on "public"."conversation_participant";

drop policy "owner manages creator" on "public"."creator";

drop policy "public reads creator" on "public"."creator";

drop policy "service updates creator" on "public"."creator";

drop policy "creator reads own creator_balance" on "public"."creator_balance";

drop policy "creator reads own payouts" on "public"."creator_payout";

drop policy "service inserts creator_payout" on "public"."creator_payout";

drop policy "creator reads own creator_revenue_log" on "public"."creator_revenue_log";

drop policy "owner only daily_nutrition_log" on "public"."daily_nutrition_log";

drop policy "owner inserts fan_external_recipe_counter" on "public"."fan_external_recipe_counter";

drop policy "owner updates fan_external_recipe_counter" on "public"."fan_external_recipe_counter";

drop policy "creator reads own fans fan_subscription" on "public"."fan_subscription";

drop policy "owner manages fan_subscription" on "public"."fan_subscription";

drop policy "owner reads own fan_subscription" on "public"."fan_subscription";

drop policy "owner updates fan_subscription" on "public"."fan_subscription";

drop policy "owner inserts fan_subscription_history" on "public"."fan_subscription_history";

drop policy "owner reads own fan_subscription_history" on "public"."fan_subscription_history";

drop policy "public reads food_region" on "public"."food_region";

drop policy "public reads ingredient" on "public"."ingredient";

drop policy "public reads ingredient_category" on "public"."ingredient_category";

drop policy "owner reads own meal_consumption" on "public"."meal_consumption";

drop policy "system inserts meal_consumption" on "public"."meal_consumption";

drop policy "owner only meal_plan" on "public"."meal_plan";

drop policy "owner only via plan meal_plan_entry" on "public"."meal_plan_entry";

drop policy "owner only meal_reminder" on "public"."meal_reminder";

drop policy "public reads measurement_unit" on "public"."measurement_unit";

drop policy "owner only notification" on "public"."notification";

drop policy "creator reads own payout" on "public"."payout";

drop policy "owner only push_token" on "public"."push_token";

drop policy "creator manages own recipe" on "public"."recipe";

drop policy "public reads published recipe" on "public"."recipe";

drop policy "owner manages recipe_comment" on "public"."recipe_comment";

drop policy "public reads recipe_comment" on "public"."recipe_comment";

drop policy "public reads recipe_image" on "public"."recipe_image";

drop policy "recipe_impression_insert_auth" on "public"."recipe_impression";

drop policy "recipe_impression_select_creator" on "public"."recipe_impression";

drop policy "public reads recipe_ingredient" on "public"."recipe_ingredient";

drop policy "owner manages recipe_like" on "public"."recipe_like";

drop policy "public count reads recipe_like" on "public"."recipe_like";

drop policy "creator manages recipe_macro" on "public"."recipe_macro";

drop policy "public reads recipe_macro" on "public"."recipe_macro";

drop policy "recipe_open_insert_auth" on "public"."recipe_open";

drop policy "recipe_open_select_creator" on "public"."recipe_open";

drop policy "recipe_open_update_owner" on "public"."recipe_open";

drop policy "recipe_save_owner" on "public"."recipe_save";

drop policy "public reads recipe_tag" on "public"."recipe_tag";

drop policy "public reads recipe_vector" on "public"."recipe_vector";

drop policy "owner reads own referral" on "public"."referral";

drop policy "owner only shopping_list" on "public"."shopping_list";

drop policy "owner reads own support_message" on "public"."support_message";

drop policy "public reads tag" on "public"."tag";

drop policy "owner only user_cuisine_preference" on "public"."user_cuisine_preference";

drop policy "owner only user_dietary_restriction" on "public"."user_dietary_restriction";

drop policy "owner only user_goal" on "public"."user_goal";

drop policy "owner only user_health_profile" on "public"."user_health_profile";

drop policy "owner only user_vector" on "public"."user_vector";

drop policy "owner only weight_log" on "public"."weight_log";

revoke delete on table "public"."creator_payout" from "anon";

revoke insert on table "public"."creator_payout" from "anon";

revoke references on table "public"."creator_payout" from "anon";

revoke select on table "public"."creator_payout" from "anon";

revoke trigger on table "public"."creator_payout" from "anon";

revoke truncate on table "public"."creator_payout" from "anon";

revoke update on table "public"."creator_payout" from "anon";

revoke delete on table "public"."creator_payout" from "authenticated";

revoke insert on table "public"."creator_payout" from "authenticated";

revoke references on table "public"."creator_payout" from "authenticated";

revoke select on table "public"."creator_payout" from "authenticated";

revoke trigger on table "public"."creator_payout" from "authenticated";

revoke truncate on table "public"."creator_payout" from "authenticated";

revoke update on table "public"."creator_payout" from "authenticated";

revoke delete on table "public"."creator_payout" from "service_role";

revoke insert on table "public"."creator_payout" from "service_role";

revoke references on table "public"."creator_payout" from "service_role";

revoke select on table "public"."creator_payout" from "service_role";

revoke trigger on table "public"."creator_payout" from "service_role";

revoke truncate on table "public"."creator_payout" from "service_role";

revoke update on table "public"."creator_payout" from "service_role";

alter table "public"."chat_message" drop constraint "chat_message_group_id_fkey";

alter table "public"."chat_message" drop constraint "check_chat_target";

alter table "public"."conversation_request" drop constraint "conversation_request_from_user_id_fkey";

alter table "public"."conversation_request" drop constraint "conversation_request_from_user_id_to_user_id_key";

alter table "public"."conversation_request" drop constraint "conversation_request_to_user_id_fkey";

alter table "public"."creator" drop constraint "creator_stripe_account_id_key";

alter table "public"."creator_payout" drop constraint "creator_payout_creator_id_fkey";

alter table "public"."creator_payout" drop constraint "creator_payout_status_check";

alter table "public"."creator_payout" drop constraint "creator_payout_stripe_payment_intent_id_key";

alter table "public"."creator_revenue_log" drop constraint "creator_revenue_log_creator_id_month_key_key";

alter table "public"."daily_nutrition_log" drop constraint "daily_nutrition_log_user_id_log_date_key";

alter table "public"."fan_external_recipe_counter" drop constraint "fan_external_recipe_counter_external_recipe_count_check";

alter table "public"."fan_subscription" drop constraint "fan_subscription_user_id_status_key";

alter table "public"."fan_subscription_history" drop constraint "fan_subscription_history_action_check";

alter table "public"."fan_subscription_history" drop constraint "fan_subscription_history_creator_id_fkey";

alter table "public"."fan_subscription_history" drop constraint "fan_subscription_history_previous_creator_id_fkey";

alter table "public"."fan_subscription_history" drop constraint "fan_subscription_history_user_id_fkey";

alter table "public"."notification" drop constraint "notification_type_check";

alter table "public"."recipe_step" drop constraint "uq_recipe_step_order";

alter table "public"."subscription" drop constraint "subscription_store_platform_check";

alter table "public"."user_profile" drop constraint "user_profile_role_check";

alter table "public"."conversation_request" drop constraint "conversation_request_status_check";

alter table "public"."fan_subscription" drop constraint "fan_subscription_status_check";

alter table "public"."meal_consumption" drop constraint "meal_consumption_recipe_id_fkey";

alter table "public"."payout" drop constraint "payout_status_check";

alter table "public"."recipe" drop constraint "recipe_parent_recipe_id_fkey";

alter table "public"."subscription" drop constraint "subscription_status_check";

drop function if exists "public"."find_or_create_conversation"(p_other_user_id uuid);

drop function if exists "public"."get_creator_public_profile"(p_creator_id uuid);

drop function if exists "public"."join_group"(p_group_id uuid);

drop function if exists "public"."search_creators"(p_query text, p_limit integer, p_offset integer);

drop function if exists "public"."update_group_member_count"();

alter table "public"."creator_payout" drop constraint "creator_payout_pkey";

drop index if exists "public"."conversation_request_from_user_id_to_user_id_key";

drop index if exists "public"."creator_payout_pkey";

drop index if exists "public"."creator_payout_stripe_payment_intent_id_key";

drop index if exists "public"."creator_revenue_log_creator_id_month_key_key";

drop index if exists "public"."creator_stripe_account_id_key";

drop index if exists "public"."daily_nutrition_log_user_id_log_date_key";

drop index if exists "public"."fan_subscription_user_id_status_key";

drop index if exists "public"."idx_consumption_creator";

drop index if exists "public"."idx_consumption_month";

drop index if exists "public"."idx_consumption_user";

drop index if exists "public"."idx_consumption_user_month";

drop index if exists "public"."idx_creator_eligible";

drop index if exists "public"."idx_creator_payout_creator";

drop index if exists "public"."idx_creator_payout_status";

drop index if exists "public"."idx_daily_nutrition_user_date";

drop index if exists "public"."idx_fan_history_creator";

drop index if exists "public"."idx_fan_history_user";

drop index if exists "public"."idx_fan_sub_creator";

drop index if exists "public"."idx_fan_sub_status";

drop index if exists "public"."idx_fan_sub_user";

drop index if exists "public"."idx_meal_plan_active";

drop index if exists "public"."idx_recipe_vector_hnsw";

drop index if exists "public"."idx_revenue_log_month";

drop index if exists "public"."idx_user_vector_hnsw";

drop index if exists "public"."uq_recipe_step_order";

drop index if exists "public"."idx_notification_user";

drop table "public"."creator_payout";


  create table "public"."batch_run_failure" (
    "id" uuid not null default gen_random_uuid(),
    "batch_run_id" uuid not null,
    "phase" text not null,
    "entity_id" uuid not null,
    "error_message" text not null,
    "created_at" timestamp with time zone not null default now()
      );



  create table "public"."batch_run_log" (
    "id" uuid not null default gen_random_uuid(),
    "started_at" timestamp with time zone not null,
    "finished_at" timestamp with time zone,
    "user_vectors_updated" integer not null default 0,
    "user_vectors_attempted" integer not null default 0,
    "recipe_vectors_updated" integer not null default 0,
    "recipe_vectors_attempted" integer not null default 0,
    "creator_vectors_updated" integer not null default 0,
    "creator_vectors_attempted" integer not null default 0,
    "weight_impact_updated" integer not null default 0,
    "weight_impact_attempted" integer not null default 0,
    "status" text not null default 'running'::text
      );



  create table "public"."blog_comment" (
    "id" uuid not null default gen_random_uuid(),
    "post_id" uuid,
    "parent_id" uuid,
    "user_id" uuid,
    "visitor_id" uuid,
    "content" text not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."blog_comment" enable row level security;


  create table "public"."blog_post" (
    "id" uuid not null default gen_random_uuid(),
    "creator_id" uuid,
    "slug" text,
    "visibility" text default 'public'::text,
    "cover_image_url" text,
    "is_published" boolean default false,
    "published_at" timestamp with time zone,
    "like_count" integer default 0,
    "comment_count" integer default 0,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."blog_post" enable row level security;


  create table "public"."blog_post_like" (
    "id" uuid not null default gen_random_uuid(),
    "post_id" uuid,
    "user_id" uuid,
    "visitor_id" uuid,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."blog_post_like" enable row level security;


  create table "public"."blog_post_translation" (
    "id" uuid not null default gen_random_uuid(),
    "post_id" uuid,
    "locale" text not null,
    "title" text not null,
    "content_json" jsonb not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."blog_post_translation" enable row level security;


  create table "public"."creator_follow" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid,
    "creator_id" uuid,
    "active" boolean default true,
    "subscribed_at" timestamp with time zone default now(),
    "unsubscribed_at" timestamp with time zone
      );


alter table "public"."creator_follow" enable row level security;


  create table "public"."creator_payout_identity" (
    "creator_id" uuid not null,
    "legal_full_name" text not null,
    "country" text not null,
    "id_document_number" text not null,
    "payout_method" text not null,
    "mobile_money_provider" text,
    "mobile_money_number" text,
    "bank_name" text,
    "bank_account_number" text,
    "status" text not null default 'submitted'::text,
    "verified_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."creator_payout_identity" enable row level security;


  create table "public"."creator_stripe_account" (
    "id" uuid not null default gen_random_uuid(),
    "creator_id" uuid not null,
    "stripe_account_id" text not null,
    "onboarding_complete" boolean default false,
    "charges_enabled" boolean default false,
    "payouts_enabled" boolean default false,
    "country" text default 'FR'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."creator_stripe_account" enable row level security;


  create table "public"."ingredient_submission" (
    "id" uuid not null default gen_random_uuid(),
    "submitted_by" uuid,
    "name" text not null,
    "name_fr" text,
    "name_en" text,
    "category_hint" text,
    "notes" text,
    "status" text default 'pending'::text,
    "ingredient_id" uuid,
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."ingredient_submission" enable row level security;


  create table "public"."landing_event" (
    "id" uuid not null default gen_random_uuid(),
    "session_id" text not null,
    "event" text not null,
    "step" integer,
    "locale" text,
    "metadata" jsonb,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."landing_event" enable row level security;


  create table "public"."onboarding_lead" (
    "id" uuid not null default gen_random_uuid(),
    "email" text not null,
    "region" text,
    "calorie_goal" integer not null,
    "protein_g" numeric not null,
    "carb_g" numeric not null,
    "fat_g" numeric not null,
    "created_at" timestamp with time zone default now(),
    "target_weight_kg" numeric,
    "remaining_weeks" integer,
    "session_id" text
      );


alter table "public"."onboarding_lead" enable row level security;


  create table "public"."recipe_cleaner_call" (
    "id" uuid not null default gen_random_uuid(),
    "creator_id" uuid not null,
    "called_at" timestamp with time zone not null default now()
      );


alter table "public"."recipe_cleaner_call" enable row level security;


  create table "public"."recipe_development" (
    "id" uuid not null default gen_random_uuid(),
    "recipe_id" uuid not null,
    "improvement_date" timestamp with time zone not null default now(),
    "version" integer not null default 1,
    "inspiration_source" text,
    "inspiration_notes" text,
    "discussion_summary" text,
    "conversation_log" jsonb,
    "changes_made" jsonb,
    "change_summary" text,
    "macros_before" jsonb,
    "macros_after" jsonb,
    "outcome_rating" integer,
    "outcome_notes" text,
    "status" text not null default 'draft'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."recipe_development" enable row level security;


  create table "public"."recipe_step_translation" (
    "id" uuid not null default gen_random_uuid(),
    "step_id" uuid not null,
    "locale" text not null,
    "content" text,
    "title" text,
    "is_auto" boolean not null default true,
    "generated_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );



  create table "public"."recipe_translation" (
    "id" uuid not null default gen_random_uuid(),
    "recipe_id" uuid,
    "locale" text not null,
    "title" text not null,
    "description" text,
    "is_auto" boolean default true,
    "generated_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."recipe_translation" enable row level security;


  create table "public"."recipe_weight_impact" (
    "user_id" uuid not null,
    "recipe_id" uuid not null,
    "meal_type" text not null,
    "avg_delta_kg" double precision not null,
    "sample_count" integer not null,
    "computed_at" timestamp with time zone not null default now()
      );


alter table "public"."recipe_weight_impact" enable row level security;


  create table "public"."report" (
    "id" uuid not null default gen_random_uuid(),
    "reporter_id" uuid,
    "target_type" text not null,
    "target_id" uuid not null,
    "reason" text not null,
    "details" text,
    "status" text not null default 'pending'::text,
    "reviewed_by" uuid,
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."report" enable row level security;


  create table "public"."specialty" (
    "id" uuid not null default gen_random_uuid(),
    "code" text not null,
    "name_fr" text not null,
    "name_en" text not null,
    "name_es" text,
    "name_pt" text,
    "region" text,
    "created_at" timestamp with time zone default now(),
    "name_ar" text
      );


alter table "public"."specialty" enable row level security;


  create table "public"."sync_log" (
    "id" uuid not null default gen_random_uuid(),
    "sync_type" text not null,
    "last_synced_date" date,
    "last_run_at" timestamp with time zone default now(),
    "last_run_status" text,
    "rows_synced" integer default 0,
    "rows_skipped" integer default 0,
    "rows_errored" integer default 0,
    "error_detail" text,
    "user_cache" jsonb default '{}'::jsonb,
    "user_cache_built_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."sync_log" enable row level security;


  create table "public"."test_ingredient" (
    "id" uuid not null default gen_random_uuid(),
    "name" text,
    "default_metric_unit" text,
    "default_us_unit" text,
    "us_to_metric_factor" numeric
      );



  create table "public"."unit_conversion" (
    "id" uuid not null default gen_random_uuid(),
    "unit" text not null,
    "ingredient_id" uuid,
    "grams_equivalent" numeric not null,
    "notes" text,
    "created_at" timestamp with time zone default now()
      );



  create table "public"."visitor" (
    "id" uuid not null default gen_random_uuid(),
    "email" text not null,
    "email_verified" boolean default false,
    "password_hash" text not null,
    "locale" text default 'fr'::text,
    "first_name" text,
    "avatar_url" text,
    "stripe_customer_id" text,
    "akeli_user_id" uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."visitor" enable row level security;


  create table "public"."visitor_auth_token" (
    "id" uuid not null default gen_random_uuid(),
    "visitor_id" uuid,
    "token_hash" text not null,
    "purpose" text not null,
    "expires_at" timestamp with time zone not null,
    "used_at" timestamp with time zone,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."visitor_auth_token" enable row level security;


  create table "public"."visitor_creator_follow" (
    "id" uuid not null default gen_random_uuid(),
    "visitor_id" uuid,
    "creator_id" uuid,
    "active" boolean default true,
    "subscribed_at" timestamp with time zone default now(),
    "unsubscribed_at" timestamp with time zone
      );


alter table "public"."visitor_creator_follow" enable row level security;


  create table "public"."visitor_fan_subscription" (
    "id" uuid not null default gen_random_uuid(),
    "visitor_id" uuid,
    "creator_id" uuid,
    "status" text default 'active'::text,
    "stripe_subscription_id" text,
    "stripe_price_id" text,
    "amount_cents" integer,
    "current_period_end" timestamp with time zone,
    "subscribed_at" timestamp with time zone default now(),
    "cancelled_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."visitor_fan_subscription" enable row level security;

alter table "public"."conversation" add column "closed_at" timestamp with time zone;

alter table "public"."conversation" add column "community_group_id" uuid;

alter table "public"."conversation" add column "created_by" uuid;

alter table "public"."conversation" add column "is_support_open" boolean default false;

alter table "public"."conversation" add column "name" text;

alter table "public"."conversation" add column "type" text default 'private'::text;

alter table "public"."conversation" add column "updated_at" timestamp with time zone default now();

alter table "public"."conversation_request" drop column "updated_at";

alter table "public"."conversation_request" add column "message" text;

alter table "public"."conversation_request" add column "responded_at" timestamp with time zone;

alter table "public"."creator" drop column "avatar_url";

alter table "public"."creator" drop column "cover_url";

alter table "public"."creator" drop column "is_fan_eligible";

alter table "public"."creator" drop column "languages";

alter table "public"."creator" drop column "stripe_charges_enabled";

alter table "public"."creator" add column "heritage_region" text;

alter table "public"."creator" add column "instagram_handle" text;

alter table "public"."creator" add column "language_codes" text[];

alter table "public"."creator" add column "profile_image_url" text;

alter table "public"."creator" add column "specialty_codes" text[];

alter table "public"."creator" add column "stripe_onboarding_complete" boolean default false;

alter table "public"."creator" add column "tiktok_handle" text;

alter table "public"."creator" add column "total_revenue" numeric(10,2) default 0;

alter table "public"."creator" add column "username" text;

alter table "public"."creator" add column "website_url" text;

alter table "public"."creator" add column "youtube_handle" text;

alter table "public"."creator" alter column "is_verified" set not null;

alter table "public"."creator_balance" drop column "balance";

alter table "public"."creator_balance" drop column "last_updated";

alter table "public"."creator_balance" drop column "total_earned";

alter table "public"."creator_balance" drop column "total_paid_out";

alter table "public"."creator_balance" add column "available_balance" numeric(10,2) default 0;

alter table "public"."creator_balance" add column "last_payout_at" timestamp with time zone;

alter table "public"."creator_balance" add column "lifetime_earnings" numeric(10,2) default 0;

alter table "public"."creator_balance" add column "pending_balance" numeric(10,2) default 0;

alter table "public"."creator_balance" add column "updated_at" timestamp with time zone default now();

-- total_revenue is a generated column dependent on consumption_revenue
-- (migra's default drop order fails on that dependency) — drop it first.
alter table "public"."creator_revenue_log" drop column "total_revenue";

alter table "public"."creator_revenue_log" drop column "computed_at";

alter table "public"."creator_revenue_log" drop column "consumption_count";

alter table "public"."creator_revenue_log" drop column "consumption_revenue";

alter table "public"."creator_revenue_log" drop column "fan_count";

alter table "public"."creator_revenue_log" drop column "fan_revenue";

alter table "public"."creator_revenue_log" drop column "month_key";

alter table "public"."creator_revenue_log" add column "amount" numeric(10,2) not null;

alter table "public"."creator_revenue_log" add column "created_at" timestamp with time zone default now();

alter table "public"."creator_revenue_log" add column "logged_at" date default CURRENT_DATE;

alter table "public"."creator_revenue_log" add column "recipe_id" uuid;

alter table "public"."creator_revenue_log" add column "revenue_type" text not null;

alter table "public"."daily_nutrition_log" alter column "calories" drop default;

alter table "public"."daily_nutrition_log" alter column "carbs_g" drop default;

alter table "public"."daily_nutrition_log" alter column "fat_g" drop default;

alter table "public"."daily_nutrition_log" alter column "protein_g" drop default;

alter table "public"."fan_external_recipe_counter" add column "created_at" timestamp with time zone default now();

alter table "public"."fan_external_recipe_counter" alter column "external_recipe_count" set not null;

alter table "public"."fan_external_recipe_counter" alter column "user_id" set not null;

alter table "public"."fan_subscription" drop column "effective_from";

alter table "public"."fan_subscription" drop column "effective_until";

alter table "public"."fan_subscription" drop column "updated_at";

alter table "public"."fan_subscription" add column "cancelled_at" timestamp with time zone;

alter table "public"."fan_subscription" add column "subscribed_at" timestamp with time zone default now();

alter table "public"."fan_subscription" alter column "status" set default 'active'::text;

alter table "public"."fan_subscription_history" drop column "action";

alter table "public"."fan_subscription_history" drop column "created_at";

alter table "public"."fan_subscription_history" drop column "creator_id";

alter table "public"."fan_subscription_history" drop column "month_key";

alter table "public"."fan_subscription_history" drop column "previous_creator_id";

alter table "public"."fan_subscription_history" drop column "user_id";

alter table "public"."fan_subscription_history" add column "changed_at" timestamp with time zone default now();

alter table "public"."fan_subscription_history" add column "status" text not null;

alter table "public"."fan_subscription_history" add column "subscription_id" uuid;

alter table "public"."food_region" add column "name_ar" text;

alter table "public"."ingredient" drop column "fiber_per_100g";

alter table "public"."ingredient" drop column "market_notes";

alter table "public"."ingredient" drop column "substitution";

alter table "public"."ingredient" add column "default_metric_unit" text;

alter table "public"."ingredient" add column "default_us_unit" text;

alter table "public"."ingredient" add column "description_ar" text;

alter table "public"."ingredient" add column "description_en" text;

alter table "public"."ingredient" add column "description_es" text;

alter table "public"."ingredient" add column "description_fr" text;

alter table "public"."ingredient" add column "description_pt" text;

alter table "public"."ingredient" add column "hide_in_metric" boolean default false;

alter table "public"."ingredient" add column "image_url" text;

alter table "public"."ingredient" add column "name_ar" text;

alter table "public"."ingredient" add column "status" text default 'validated'::text;

alter table "public"."ingredient" add column "tags" text[] default '{}'::text[];

alter table "public"."ingredient" add column "us_to_metric_factor" numeric;

alter table "public"."ingredient" alter column "avg_weight_g" set data type numeric(7,1) using "avg_weight_g"::numeric(7,1);

alter table "public"."ingredient_category" add column "name_ar" text;

alter table "public"."ingredient_rounding_rule" enable row level security;

alter table "public"."meal_consumption" drop column "month_key";

alter table "public"."meal_consumption" add column "consumed_date" date generated always as (((consumed_at AT TIME ZONE 'UTC'::text))::date) stored;

alter table "public"."meal_consumption" add column "created_at" timestamp with time zone default now();

alter table "public"."meal_consumption" alter column "servings" set data type integer using "servings"::integer;

alter table "public"."meal_plan_entry" alter column "is_consumed" set not null;

alter table "public"."meal_reminder" drop column "days_of_week";

alter table "public"."meal_reminder" drop column "is_active";

alter table "public"."meal_reminder" add column "is_enabled" boolean default true;

alter table "public"."measurement_unit" add column "name_ar" text;

alter table "public"."notification" alter column "body" set not null;

alter table "public"."notification" alter column "type" set not null;

alter table "public"."payout" drop column "month_key";

alter table "public"."payout" drop column "paid_at";

alter table "public"."payout" add column "completed_at" timestamp with time zone;

alter table "public"."payout" add column "requested_at" timestamp with time zone default now();

alter table "public"."payout" add column "stripe_payout_id" text;

alter table "public"."payout" add column "stripe_transfer_id" text;

alter table "public"."payout" alter column "status" set default 'pending'::text;

alter table "public"."recipe" drop column "video_url";

alter table "public"."recipe" add column "show_on_website" boolean not null default false;

alter table "public"."recipe_ingredient" add column "is_section_header" boolean not null default false;

alter table "public"."recipe_ingredient" add column "swappable_ingredient_ids" uuid[] default '{}'::uuid[];

alter table "public"."recipe_ingredient" add column "title" text;

alter table "public"."recipe_ingredient" alter column "quantity" drop not null;

alter table "public"."recipe_ingredient_translation" alter column "generated_at" set default now();

alter table "public"."recipe_ingredient_translation" alter column "generated_at" set not null;

alter table "public"."recipe_ingredient_translation" alter column "is_auto" set default true;

alter table "public"."recipe_ingredient_translation" alter column "is_auto" set not null;

alter table "public"."recipe_ingredient_translation" alter column "recipe_ingredient_id" set not null;

alter table "public"."recipe_ingredient_translation" alter column "updated_at" set not null;

alter table "public"."recipe_macro" drop column "kcal_per_100g";

alter table "public"."recipe_macro" add column "calories_per_100g" numeric(8,2);

alter table "public"."recipe_macro" alter column "carbs_per_100g" drop expression;

alter table "public"."recipe_macro" alter column "carbs_per_100g" set data type numeric(8,2) using "carbs_per_100g"::numeric(8,2);

alter table "public"."recipe_macro" alter column "fat_per_100g" drop expression;

alter table "public"."recipe_macro" alter column "fat_per_100g" set data type numeric(8,2) using "fat_per_100g"::numeric(8,2);

alter table "public"."recipe_macro" alter column "protein_per_100g" drop expression;

alter table "public"."recipe_macro" alter column "protein_per_100g" set data type numeric(8,2) using "protein_per_100g"::numeric(8,2);

alter table "public"."recipe_macro" alter column "total_weight_g" set data type numeric(10,2) using "total_weight_g"::numeric(10,2);

alter table "public"."recipe_step" drop column "video_url";

alter table "public"."recipe_step" alter column "content" drop not null;

alter table "public"."recipe_step" alter column "ingredient_ids" set default '{}'::uuid[];

alter table "public"."recipe_vector" add column "updated_at" timestamp with time zone default now();

alter table "public"."shopping_list" drop column "generated_at";

alter table "public"."shopping_list" add column "created_at" timestamp with time zone default now();

alter table "public"."shopping_list" add column "is_completed" boolean default false;

alter table "public"."shopping_list" add column "name" text;

alter table "public"."shopping_list" add column "updated_at" timestamp with time zone default now();

alter table "public"."shopping_list_item" add column "custom_name" text;

alter table "public"."shopping_list_item" alter column "quantity" set not null;

alter table "public"."subscription" drop column "cancelled_at";

alter table "public"."subscription" drop column "store_platform";

alter table "public"."subscription" drop column "store_product_id";

alter table "public"."subscription" drop column "store_purchase_token";

alter table "public"."subscription" add column "cancel_at_period_end" boolean default false;

alter table "public"."subscription" add column "stripe_customer_id" text;

alter table "public"."subscription" add column "stripe_subscription_id" text;

alter table "public"."subscription" alter column "status" set default 'trialing'::text;

alter table "public"."tag" add column "name_ar" text;

alter table "public"."unit_rounding_config" enable row level security;

alter table "public"."user_profile" drop column "role";

CREATE UNIQUE INDEX batch_run_failure_pkey ON public.batch_run_failure USING btree (id);

CREATE UNIQUE INDEX batch_run_log_pkey ON public.batch_run_log USING btree (id);

CREATE UNIQUE INDEX blog_comment_pkey ON public.blog_comment USING btree (id);

CREATE UNIQUE INDEX blog_post_like_pkey ON public.blog_post_like USING btree (id);

CREATE UNIQUE INDEX blog_post_like_post_id_user_id_key ON public.blog_post_like USING btree (post_id, user_id) NULLS NOT DISTINCT;

CREATE UNIQUE INDEX blog_post_like_post_id_visitor_id_key ON public.blog_post_like USING btree (post_id, visitor_id) NULLS NOT DISTINCT;

CREATE UNIQUE INDEX blog_post_pkey ON public.blog_post USING btree (id);

CREATE UNIQUE INDEX blog_post_slug_key ON public.blog_post USING btree (slug);

CREATE UNIQUE INDEX blog_post_translation_pkey ON public.blog_post_translation USING btree (id);

CREATE UNIQUE INDEX blog_post_translation_post_id_locale_key ON public.blog_post_translation USING btree (post_id, locale);

CREATE UNIQUE INDEX cooking_session_meal_plan_recipe_key ON public.cooking_session USING btree (meal_plan_id, recipe_id);

CREATE UNIQUE INDEX creator_follow_pkey ON public.creator_follow USING btree (id);

CREATE UNIQUE INDEX creator_follow_user_id_creator_id_key ON public.creator_follow USING btree (user_id, creator_id);

CREATE UNIQUE INDEX creator_payout_identity_pkey ON public.creator_payout_identity USING btree (creator_id);

CREATE UNIQUE INDEX creator_stripe_account_pkey ON public.creator_stripe_account USING btree (id);

CREATE UNIQUE INDEX creator_stripe_account_stripe_account_id_key ON public.creator_stripe_account USING btree (stripe_account_id);

CREATE UNIQUE INDEX creator_username_key ON public.creator USING btree (username);

CREATE UNIQUE INDEX daily_nutrition_log_user_id_date_key ON public.daily_nutrition_log USING btree (user_id, log_date);

CREATE UNIQUE INDEX fan_subscription_user_id_creator_id_key ON public.fan_subscription USING btree (user_id, creator_id);

CREATE INDEX idx_conversation_community_group_id ON public.conversation USING btree (community_group_id);

CREATE INDEX idx_conversation_created_by ON public.conversation USING btree (created_by);

CREATE INDEX idx_creator_revenue_log_recipe_id ON public.creator_revenue_log USING btree (recipe_id);

CREATE UNIQUE INDEX idx_creator_stripe_account_creator_id ON public.creator_stripe_account USING btree (creator_id);

CREATE INDEX idx_creator_stripe_account_id ON public.creator USING btree (stripe_account_id);

CREATE INDEX idx_creator_stripe_account_stripe_id ON public.creator_stripe_account USING btree (stripe_account_id);

CREATE UNIQUE INDEX idx_creator_username ON public.creator USING btree (username) WHERE (username IS NOT NULL);

CREATE INDEX idx_fan_subscription_creator ON public.fan_subscription USING btree (creator_id);

CREATE INDEX idx_fan_subscription_history_subscription_id ON public.fan_subscription_history USING btree (subscription_id);

CREATE INDEX idx_ingredient_submission_ingredient_id ON public.ingredient_submission USING btree (ingredient_id);

CREATE INDEX idx_ingredient_submission_status ON public.ingredient_submission USING btree (status);

CREATE INDEX idx_ingredient_submission_user ON public.ingredient_submission USING btree (submitted_by);

CREATE INDEX idx_meal_consumption_recipe ON public.meal_consumption USING btree (recipe_id);

CREATE UNIQUE INDEX idx_meal_consumption_unique ON public.meal_consumption USING btree (user_id, recipe_id, consumed_date);

CREATE INDEX idx_meal_consumption_user ON public.meal_consumption USING btree (user_id);

CREATE INDEX idx_payout_creator ON public.payout USING btree (creator_id);

CREATE INDEX idx_recipe_development_date ON public.recipe_development USING btree (improvement_date DESC);

CREATE INDEX idx_recipe_development_recipe_id ON public.recipe_development USING btree (recipe_id);

CREATE INDEX idx_recipe_ingredient_translation_unit ON public.recipe_ingredient_translation USING btree (unit);

CREATE UNIQUE INDEX idx_recipe_slug ON public.recipe USING btree (slug) WHERE (slug IS NOT NULL);

CREATE INDEX idx_recipe_translation_locale ON public.recipe_translation USING btree (locale);

CREATE INDEX idx_recipe_translation_recipe ON public.recipe_translation USING btree (recipe_id);

CREATE INDEX idx_recipe_vector_ivfflat ON public.recipe_vector USING ivfflat (vector public.vector_cosine_ops) WITH (lists='100');

CREATE INDEX idx_recipe_weight_impact_user_meal_delta ON public.recipe_weight_impact USING btree (user_id, meal_type, avg_delta_kg);

CREATE INDEX idx_revenue_log_date ON public.creator_revenue_log USING btree (logged_at);

CREATE INDEX idx_specialty_region ON public.specialty USING btree (region);

CREATE UNIQUE INDEX idx_sync_log_type ON public.sync_log USING btree (sync_type);

CREATE INDEX idx_user_vector_ivfflat ON public.user_vector USING ivfflat (vector public.vector_cosine_ops) WITH (lists='100');

CREATE UNIQUE INDEX ingredient_submission_pkey ON public.ingredient_submission USING btree (id);

CREATE INDEX landing_event_event_idx ON public.landing_event USING btree (event, created_at);

CREATE UNIQUE INDEX landing_event_pkey ON public.landing_event USING btree (id);

CREATE INDEX landing_event_session_id_idx ON public.landing_event USING btree (session_id);

CREATE UNIQUE INDEX meal_reminder_user_id_meal_type_key ON public.meal_reminder USING btree (user_id, meal_type);

CREATE UNIQUE INDEX onboarding_lead_pkey ON public.onboarding_lead USING btree (id);

CREATE INDEX recipe_cleaner_call_creator_at ON public.recipe_cleaner_call USING btree (creator_id, called_at DESC);

CREATE UNIQUE INDEX recipe_cleaner_call_pkey ON public.recipe_cleaner_call USING btree (id);

CREATE UNIQUE INDEX recipe_development_pkey ON public.recipe_development USING btree (id);

CREATE UNIQUE INDEX recipe_ingredient_translation_unique ON public.recipe_ingredient_translation USING btree (recipe_ingredient_id, locale);

CREATE UNIQUE INDEX recipe_slug_key ON public.recipe USING btree (slug);

CREATE UNIQUE INDEX recipe_step_translation_pkey ON public.recipe_step_translation USING btree (id);

CREATE UNIQUE INDEX recipe_step_translation_step_locale_unique ON public.recipe_step_translation USING btree (step_id, locale);

CREATE UNIQUE INDEX recipe_translation_pkey ON public.recipe_translation USING btree (id);

CREATE UNIQUE INDEX recipe_translation_recipe_id_locale_key ON public.recipe_translation USING btree (recipe_id, locale);

CREATE UNIQUE INDEX recipe_translation_recipe_locale_unique ON public.recipe_translation USING btree (recipe_id, locale);

CREATE UNIQUE INDEX recipe_weight_impact_pkey ON public.recipe_weight_impact USING btree (user_id, recipe_id, meal_type);

CREATE UNIQUE INDEX report_pkey ON public.report USING btree (id);

CREATE UNIQUE INDEX shopping_list_meal_plan_id_key ON public.shopping_list USING btree (meal_plan_id);

CREATE UNIQUE INDEX specialty_code_key ON public.specialty USING btree (code);

CREATE UNIQUE INDEX specialty_pkey ON public.specialty USING btree (id);

CREATE UNIQUE INDEX subscription_stripe_customer_id_key ON public.subscription USING btree (stripe_customer_id);

CREATE UNIQUE INDEX subscription_stripe_subscription_id_key ON public.subscription USING btree (stripe_subscription_id);

CREATE UNIQUE INDEX sync_log_pkey ON public.sync_log USING btree (id);

CREATE UNIQUE INDEX test_ingredient_pkey ON public.test_ingredient USING btree (id);

CREATE UNIQUE INDEX unit_conversion_pkey ON public.unit_conversion USING btree (id);

CREATE UNIQUE INDEX unit_conversion_unit_ingredient_id_key ON public.unit_conversion USING btree (unit, ingredient_id);

CREATE UNIQUE INDEX visitor_auth_token_pkey ON public.visitor_auth_token USING btree (id);

CREATE UNIQUE INDEX visitor_creator_follow_pkey ON public.visitor_creator_follow USING btree (id);

CREATE UNIQUE INDEX visitor_creator_follow_visitor_id_creator_id_key ON public.visitor_creator_follow USING btree (visitor_id, creator_id);

CREATE UNIQUE INDEX visitor_email_key ON public.visitor USING btree (email);

CREATE UNIQUE INDEX visitor_fan_subscription_pkey ON public.visitor_fan_subscription USING btree (id);

CREATE UNIQUE INDEX visitor_fan_subscription_visitor_id_creator_id_key ON public.visitor_fan_subscription USING btree (visitor_id, creator_id);

CREATE UNIQUE INDEX visitor_pkey ON public.visitor USING btree (id);

CREATE INDEX idx_notification_user ON public.notification USING btree (user_id, is_read);

alter table "public"."batch_run_failure" add constraint "batch_run_failure_pkey" PRIMARY KEY using index "batch_run_failure_pkey";

alter table "public"."batch_run_log" add constraint "batch_run_log_pkey" PRIMARY KEY using index "batch_run_log_pkey";

alter table "public"."blog_comment" add constraint "blog_comment_pkey" PRIMARY KEY using index "blog_comment_pkey";

alter table "public"."blog_post" add constraint "blog_post_pkey" PRIMARY KEY using index "blog_post_pkey";

alter table "public"."blog_post_like" add constraint "blog_post_like_pkey" PRIMARY KEY using index "blog_post_like_pkey";

alter table "public"."blog_post_translation" add constraint "blog_post_translation_pkey" PRIMARY KEY using index "blog_post_translation_pkey";

alter table "public"."creator_follow" add constraint "creator_follow_pkey" PRIMARY KEY using index "creator_follow_pkey";

alter table "public"."creator_payout_identity" add constraint "creator_payout_identity_pkey" PRIMARY KEY using index "creator_payout_identity_pkey";

alter table "public"."creator_stripe_account" add constraint "creator_stripe_account_pkey" PRIMARY KEY using index "creator_stripe_account_pkey";

alter table "public"."ingredient_submission" add constraint "ingredient_submission_pkey" PRIMARY KEY using index "ingredient_submission_pkey";

alter table "public"."landing_event" add constraint "landing_event_pkey" PRIMARY KEY using index "landing_event_pkey";

alter table "public"."onboarding_lead" add constraint "onboarding_lead_pkey" PRIMARY KEY using index "onboarding_lead_pkey";

alter table "public"."recipe_cleaner_call" add constraint "recipe_cleaner_call_pkey" PRIMARY KEY using index "recipe_cleaner_call_pkey";

alter table "public"."recipe_development" add constraint "recipe_development_pkey" PRIMARY KEY using index "recipe_development_pkey";

alter table "public"."recipe_step_translation" add constraint "recipe_step_translation_pkey" PRIMARY KEY using index "recipe_step_translation_pkey";

alter table "public"."recipe_translation" add constraint "recipe_translation_pkey" PRIMARY KEY using index "recipe_translation_pkey";

alter table "public"."recipe_weight_impact" add constraint "recipe_weight_impact_pkey" PRIMARY KEY using index "recipe_weight_impact_pkey";

alter table "public"."report" add constraint "report_pkey" PRIMARY KEY using index "report_pkey";

alter table "public"."specialty" add constraint "specialty_pkey" PRIMARY KEY using index "specialty_pkey";

alter table "public"."sync_log" add constraint "sync_log_pkey" PRIMARY KEY using index "sync_log_pkey";

alter table "public"."test_ingredient" add constraint "test_ingredient_pkey" PRIMARY KEY using index "test_ingredient_pkey";

alter table "public"."unit_conversion" add constraint "unit_conversion_pkey" PRIMARY KEY using index "unit_conversion_pkey";

alter table "public"."visitor" add constraint "visitor_pkey" PRIMARY KEY using index "visitor_pkey";

alter table "public"."visitor_auth_token" add constraint "visitor_auth_token_pkey" PRIMARY KEY using index "visitor_auth_token_pkey";

alter table "public"."visitor_creator_follow" add constraint "visitor_creator_follow_pkey" PRIMARY KEY using index "visitor_creator_follow_pkey";

alter table "public"."visitor_fan_subscription" add constraint "visitor_fan_subscription_pkey" PRIMARY KEY using index "visitor_fan_subscription_pkey";

alter table "public"."batch_run_failure" add constraint "batch_run_failure_batch_run_id_fkey" FOREIGN KEY (batch_run_id) REFERENCES public.batch_run_log(id) ON DELETE CASCADE not valid;

alter table "public"."batch_run_failure" validate constraint "batch_run_failure_batch_run_id_fkey";

alter table "public"."batch_run_failure" add constraint "batch_run_failure_phase_check" CHECK ((phase = ANY (ARRAY['user_vector'::text, 'recipe_vector'::text, 'creator_vector'::text, 'weight_impact'::text]))) not valid;

alter table "public"."batch_run_failure" validate constraint "batch_run_failure_phase_check";

alter table "public"."batch_run_log" add constraint "batch_run_log_status_check" CHECK ((status = ANY (ARRAY['running'::text, 'completed'::text, 'failed'::text]))) not valid;

alter table "public"."batch_run_log" validate constraint "batch_run_log_status_check";

alter table "public"."blog_comment" add constraint "blog_comment_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES public.blog_comment(id) ON DELETE CASCADE not valid;

alter table "public"."blog_comment" validate constraint "blog_comment_parent_id_fkey";

alter table "public"."blog_comment" add constraint "blog_comment_post_id_fkey" FOREIGN KEY (post_id) REFERENCES public.blog_post(id) ON DELETE CASCADE not valid;

alter table "public"."blog_comment" validate constraint "blog_comment_post_id_fkey";

alter table "public"."blog_comment" add constraint "blog_comment_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.user_profile(id) ON DELETE CASCADE not valid;

alter table "public"."blog_comment" validate constraint "blog_comment_user_id_fkey";

alter table "public"."blog_comment" add constraint "blog_comment_visitor_id_fkey" FOREIGN KEY (visitor_id) REFERENCES public.visitor(id) ON DELETE CASCADE not valid;

alter table "public"."blog_comment" validate constraint "blog_comment_visitor_id_fkey";

alter table "public"."blog_comment" add constraint "chk_comment_single_identity" CHECK ((((user_id IS NOT NULL) AND (visitor_id IS NULL)) OR ((user_id IS NULL) AND (visitor_id IS NOT NULL)))) not valid;

alter table "public"."blog_comment" validate constraint "chk_comment_single_identity";

alter table "public"."blog_post" add constraint "blog_post_creator_id_fkey" FOREIGN KEY (creator_id) REFERENCES public.creator(id) ON DELETE CASCADE not valid;

alter table "public"."blog_post" validate constraint "blog_post_creator_id_fkey";

alter table "public"."blog_post" add constraint "blog_post_slug_key" UNIQUE using index "blog_post_slug_key";

alter table "public"."blog_post" add constraint "blog_post_visibility_check" CHECK ((visibility = ANY (ARRAY['public'::text, 'followers'::text, 'fans'::text]))) not valid;

alter table "public"."blog_post" validate constraint "blog_post_visibility_check";

alter table "public"."blog_post_like" add constraint "blog_post_like_post_id_fkey" FOREIGN KEY (post_id) REFERENCES public.blog_post(id) ON DELETE CASCADE not valid;

alter table "public"."blog_post_like" validate constraint "blog_post_like_post_id_fkey";

alter table "public"."blog_post_like" add constraint "blog_post_like_post_id_user_id_key" UNIQUE using index "blog_post_like_post_id_user_id_key";

alter table "public"."blog_post_like" add constraint "blog_post_like_post_id_visitor_id_key" UNIQUE using index "blog_post_like_post_id_visitor_id_key";

alter table "public"."blog_post_like" add constraint "blog_post_like_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.user_profile(id) ON DELETE CASCADE not valid;

alter table "public"."blog_post_like" validate constraint "blog_post_like_user_id_fkey";

alter table "public"."blog_post_like" add constraint "blog_post_like_visitor_id_fkey" FOREIGN KEY (visitor_id) REFERENCES public.visitor(id) ON DELETE CASCADE not valid;

alter table "public"."blog_post_like" validate constraint "blog_post_like_visitor_id_fkey";

alter table "public"."blog_post_like" add constraint "chk_like_single_identity" CHECK ((((user_id IS NOT NULL) AND (visitor_id IS NULL)) OR ((user_id IS NULL) AND (visitor_id IS NOT NULL)))) not valid;

alter table "public"."blog_post_like" validate constraint "chk_like_single_identity";

alter table "public"."blog_post_translation" add constraint "blog_post_translation_post_id_fkey" FOREIGN KEY (post_id) REFERENCES public.blog_post(id) ON DELETE CASCADE not valid;

alter table "public"."blog_post_translation" validate constraint "blog_post_translation_post_id_fkey";

alter table "public"."blog_post_translation" add constraint "blog_post_translation_post_id_locale_key" UNIQUE using index "blog_post_translation_post_id_locale_key";

alter table "public"."chat_message" add constraint "check_target" CHECK ((((conversation_id IS NOT NULL) AND (group_id IS NULL)) OR ((conversation_id IS NULL) AND (group_id IS NOT NULL)))) not valid;

alter table "public"."chat_message" validate constraint "check_target";

alter table "public"."conversation" add constraint "conversation_community_group_id_fkey" FOREIGN KEY (community_group_id) REFERENCES public.community_group(id) ON DELETE SET NULL not valid;

alter table "public"."conversation" validate constraint "conversation_community_group_id_fkey";

alter table "public"."conversation" add constraint "conversation_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.user_profile(id) ON DELETE SET NULL not valid;

alter table "public"."conversation" validate constraint "conversation_created_by_fkey";

alter table "public"."conversation" add constraint "conversation_type_check" CHECK ((type = ANY (ARRAY['private'::text, 'creator_group'::text, 'support'::text]))) not valid;

alter table "public"."conversation" validate constraint "conversation_type_check";

alter table "public"."conversation_request" add constraint "conversation_request_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES public.user_profile(id) ON DELETE CASCADE not valid;

alter table "public"."conversation_request" validate constraint "conversation_request_recipient_id_fkey";

alter table "public"."conversation_request" add constraint "conversation_request_requester_id_fkey" FOREIGN KEY (requester_id) REFERENCES public.user_profile(id) ON DELETE CASCADE not valid;

alter table "public"."conversation_request" validate constraint "conversation_request_requester_id_fkey";

alter table "public"."cooking_session" add constraint "cooking_session_meal_plan_recipe_key" UNIQUE using index "cooking_session_meal_plan_recipe_key";

alter table "public"."creator" add constraint "creator_username_format" CHECK ((username ~ '^[a-z0-9_-]{3,30}$'::text)) not valid;

alter table "public"."creator" validate constraint "creator_username_format";

alter table "public"."creator" add constraint "creator_username_key" UNIQUE using index "creator_username_key";

alter table "public"."creator_follow" add constraint "creator_follow_creator_id_fkey" FOREIGN KEY (creator_id) REFERENCES public.creator(id) ON DELETE CASCADE not valid;

alter table "public"."creator_follow" validate constraint "creator_follow_creator_id_fkey";

alter table "public"."creator_follow" add constraint "creator_follow_user_id_creator_id_key" UNIQUE using index "creator_follow_user_id_creator_id_key";

alter table "public"."creator_follow" add constraint "creator_follow_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.user_profile(id) ON DELETE CASCADE not valid;

alter table "public"."creator_follow" validate constraint "creator_follow_user_id_fkey";

alter table "public"."creator_payout_identity" add constraint "creator_payout_identity_creator_id_fkey" FOREIGN KEY (creator_id) REFERENCES public.creator(id) ON DELETE CASCADE not valid;

alter table "public"."creator_payout_identity" validate constraint "creator_payout_identity_creator_id_fkey";

alter table "public"."creator_payout_identity" add constraint "creator_payout_identity_payout_method_check" CHECK ((payout_method = ANY (ARRAY['mobile_money'::text, 'bank_transfer'::text]))) not valid;

alter table "public"."creator_payout_identity" validate constraint "creator_payout_identity_payout_method_check";

alter table "public"."creator_payout_identity" add constraint "creator_payout_identity_status_check" CHECK ((status = ANY (ARRAY['submitted'::text, 'verified'::text]))) not valid;

alter table "public"."creator_payout_identity" validate constraint "creator_payout_identity_status_check";

alter table "public"."creator_payout_identity" add constraint "payout_method_fields_chk" CHECK ((((payout_method = 'mobile_money'::text) AND (mobile_money_number IS NOT NULL)) OR ((payout_method = 'bank_transfer'::text) AND (bank_name IS NOT NULL) AND (bank_account_number IS NOT NULL)))) not valid;

alter table "public"."creator_payout_identity" validate constraint "payout_method_fields_chk";

alter table "public"."creator_revenue_log" add constraint "creator_revenue_log_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) ON DELETE SET NULL not valid;

alter table "public"."creator_revenue_log" validate constraint "creator_revenue_log_recipe_id_fkey";

alter table "public"."creator_revenue_log" add constraint "creator_revenue_log_revenue_type_check" CHECK ((revenue_type = ANY (ARRAY['consumption'::text, 'fan_mode'::text]))) not valid;

alter table "public"."creator_revenue_log" validate constraint "creator_revenue_log_revenue_type_check";

alter table "public"."creator_stripe_account" add constraint "creator_stripe_account_creator_id_fkey" FOREIGN KEY (creator_id) REFERENCES public.creator(id) ON DELETE CASCADE not valid;

alter table "public"."creator_stripe_account" validate constraint "creator_stripe_account_creator_id_fkey";

alter table "public"."creator_stripe_account" add constraint "creator_stripe_account_stripe_account_id_key" UNIQUE using index "creator_stripe_account_stripe_account_id_key";

alter table "public"."daily_nutrition_log" add constraint "daily_nutrition_log_user_id_date_key" UNIQUE using index "daily_nutrition_log_user_id_date_key";

alter table "public"."fan_subscription" add constraint "fan_subscription_user_id_creator_id_key" UNIQUE using index "fan_subscription_user_id_creator_id_key";

alter table "public"."fan_subscription_history" add constraint "fan_subscription_history_subscription_id_fkey" FOREIGN KEY (subscription_id) REFERENCES public.fan_subscription(id) ON DELETE CASCADE not valid;

alter table "public"."fan_subscription_history" validate constraint "fan_subscription_history_subscription_id_fkey";

alter table "public"."ingredient" add constraint "ingredient_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'validated'::text]))) not valid;

alter table "public"."ingredient" validate constraint "ingredient_status_check";

alter table "public"."ingredient_submission" add constraint "ingredient_submission_ingredient_id_fkey" FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id) ON DELETE SET NULL not valid;

alter table "public"."ingredient_submission" validate constraint "ingredient_submission_ingredient_id_fkey";

alter table "public"."ingredient_submission" add constraint "ingredient_submission_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'validated'::text, 'rejected'::text, 'duplicate'::text]))) not valid;

alter table "public"."ingredient_submission" validate constraint "ingredient_submission_status_check";

alter table "public"."ingredient_submission" add constraint "ingredient_submission_submitted_by_fkey" FOREIGN KEY (submitted_by) REFERENCES public.user_profile(id) ON DELETE SET NULL not valid;

alter table "public"."ingredient_submission" validate constraint "ingredient_submission_submitted_by_fkey";

alter table "public"."meal_reminder" add constraint "meal_reminder_user_id_meal_type_key" UNIQUE using index "meal_reminder_user_id_meal_type_key";

alter table "public"."onboarding_lead" add constraint "onboarding_lead_region_fkey" FOREIGN KEY (region) REFERENCES public.food_region(code) not valid;

alter table "public"."onboarding_lead" validate constraint "onboarding_lead_region_fkey";

alter table "public"."recipe" add constraint "recipe_slug_key" UNIQUE using index "recipe_slug_key";

alter table "public"."recipe_development" add constraint "recipe_development_outcome_rating_check" CHECK (((outcome_rating >= 1) AND (outcome_rating <= 5))) not valid;

alter table "public"."recipe_development" validate constraint "recipe_development_outcome_rating_check";

alter table "public"."recipe_development" add constraint "recipe_development_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) ON DELETE CASCADE not valid;

alter table "public"."recipe_development" validate constraint "recipe_development_recipe_id_fkey";

alter table "public"."recipe_development" add constraint "recipe_development_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'applied'::text, 'rejected'::text, 'pending_test'::text]))) not valid;

alter table "public"."recipe_development" validate constraint "recipe_development_status_check";

alter table "public"."recipe_ingredient" add constraint "chk_recipe_ingredient_section_header" CHECK ((((is_section_header = true) AND (title IS NOT NULL) AND (ingredient_id IS NULL)) OR ((is_section_header = false) AND (ingredient_id IS NOT NULL) AND (quantity IS NOT NULL)))) not valid;

alter table "public"."recipe_ingredient" validate constraint "chk_recipe_ingredient_section_header";

alter table "public"."recipe_ingredient_translation" add constraint "recipe_ingredient_translation_unique" UNIQUE using index "recipe_ingredient_translation_unique";

alter table "public"."recipe_ingredient_translation" add constraint "recipe_ingredient_translation_unit_fkey" FOREIGN KEY (unit) REFERENCES public.measurement_unit(code) not valid;

alter table "public"."recipe_ingredient_translation" validate constraint "recipe_ingredient_translation_unit_fkey";

alter table "public"."recipe_step" add constraint "chk_recipe_step_section_header" CHECK ((((is_section_header = true) AND (title IS NOT NULL) AND (content IS NULL)) OR ((is_section_header = false) AND (content IS NOT NULL)))) not valid;

alter table "public"."recipe_step" validate constraint "chk_recipe_step_section_header";

alter table "public"."recipe_step" add constraint "chk_regular_step_no_title" CHECK (((is_section_header = true) OR (title IS NULL))) not valid;

alter table "public"."recipe_step" validate constraint "chk_regular_step_no_title";

alter table "public"."recipe_step_translation" add constraint "recipe_step_translation_locale_check" CHECK ((locale = ANY (ARRAY['fr'::text, 'en'::text, 'es'::text, 'pt'::text, 'wo'::text, 'bm'::text, 'ln'::text, 'ar'::text, 'en-US'::text]))) not valid;

alter table "public"."recipe_step_translation" validate constraint "recipe_step_translation_locale_check";

alter table "public"."recipe_step_translation" add constraint "recipe_step_translation_step_id_fkey" FOREIGN KEY (step_id) REFERENCES public.recipe_step(id) ON DELETE CASCADE not valid;

alter table "public"."recipe_step_translation" validate constraint "recipe_step_translation_step_id_fkey";

alter table "public"."recipe_step_translation" add constraint "recipe_step_translation_step_locale_unique" UNIQUE using index "recipe_step_translation_step_locale_unique";

alter table "public"."recipe_translation" add constraint "recipe_translation_locale_check" CHECK ((locale = ANY (ARRAY['fr'::text, 'en'::text, 'es'::text, 'pt'::text, 'wo'::text, 'bm'::text, 'ln'::text, 'ar'::text, 'en-US'::text]))) not valid;

alter table "public"."recipe_translation" validate constraint "recipe_translation_locale_check";

alter table "public"."recipe_translation" add constraint "recipe_translation_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) ON DELETE CASCADE not valid;

alter table "public"."recipe_translation" validate constraint "recipe_translation_recipe_id_fkey";

alter table "public"."recipe_translation" add constraint "recipe_translation_recipe_id_locale_key" UNIQUE using index "recipe_translation_recipe_id_locale_key";

alter table "public"."recipe_translation" add constraint "recipe_translation_recipe_locale_unique" UNIQUE using index "recipe_translation_recipe_locale_unique";

alter table "public"."recipe_weight_impact" add constraint "recipe_weight_impact_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) ON DELETE CASCADE not valid;

alter table "public"."recipe_weight_impact" validate constraint "recipe_weight_impact_recipe_id_fkey";

alter table "public"."recipe_weight_impact" add constraint "recipe_weight_impact_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."recipe_weight_impact" validate constraint "recipe_weight_impact_user_id_fkey";

alter table "public"."report" add constraint "report_reporter_id_fkey" FOREIGN KEY (reporter_id) REFERENCES public.user_profile(id) ON DELETE SET NULL not valid;

alter table "public"."report" validate constraint "report_reporter_id_fkey";

alter table "public"."report" add constraint "report_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES public.user_profile(id) not valid;

alter table "public"."report" validate constraint "report_reviewed_by_fkey";

alter table "public"."report" add constraint "report_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'dismissed'::text, 'actioned'::text]))) not valid;

alter table "public"."report" validate constraint "report_status_check";

alter table "public"."report" add constraint "report_target_type_check" CHECK ((target_type = ANY (ARRAY['recipe'::text, 'recipe_comment'::text, 'blog_post'::text, 'blog_comment'::text, 'user_profile'::text, 'community_group'::text]))) not valid;

alter table "public"."report" validate constraint "report_target_type_check";

alter table "public"."shopping_list" add constraint "shopping_list_meal_plan_id_key" UNIQUE using index "shopping_list_meal_plan_id_key";

alter table "public"."specialty" add constraint "specialty_code_key" UNIQUE using index "specialty_code_key";

alter table "public"."specialty" add constraint "specialty_region_fkey" FOREIGN KEY (region) REFERENCES public.food_region(code) not valid;

alter table "public"."specialty" validate constraint "specialty_region_fkey";

alter table "public"."subscription" add constraint "subscription_stripe_customer_id_key" UNIQUE using index "subscription_stripe_customer_id_key";

alter table "public"."subscription" add constraint "subscription_stripe_subscription_id_key" UNIQUE using index "subscription_stripe_subscription_id_key";

alter table "public"."sync_log" add constraint "sync_log_last_run_status_check" CHECK ((last_run_status = ANY (ARRAY['success'::text, 'error'::text, 'partial'::text]))) not valid;

alter table "public"."sync_log" validate constraint "sync_log_last_run_status_check";

alter table "public"."unit_conversion" add constraint "unit_conversion_ingredient_id_fkey" FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id) ON DELETE CASCADE not valid;

alter table "public"."unit_conversion" validate constraint "unit_conversion_ingredient_id_fkey";

alter table "public"."unit_conversion" add constraint "unit_conversion_unit_ingredient_id_key" UNIQUE using index "unit_conversion_unit_ingredient_id_key";

alter table "public"."visitor" add constraint "visitor_akeli_user_id_fkey" FOREIGN KEY (akeli_user_id) REFERENCES public.user_profile(id) ON DELETE SET NULL not valid;

alter table "public"."visitor" validate constraint "visitor_akeli_user_id_fkey";

alter table "public"."visitor" add constraint "visitor_email_key" UNIQUE using index "visitor_email_key";

alter table "public"."visitor_auth_token" add constraint "visitor_auth_token_purpose_check" CHECK ((purpose = ANY (ARRAY['reset_password'::text, 'verify_email'::text]))) not valid;

alter table "public"."visitor_auth_token" validate constraint "visitor_auth_token_purpose_check";

alter table "public"."visitor_auth_token" add constraint "visitor_auth_token_visitor_id_fkey" FOREIGN KEY (visitor_id) REFERENCES public.visitor(id) ON DELETE CASCADE not valid;

alter table "public"."visitor_auth_token" validate constraint "visitor_auth_token_visitor_id_fkey";

alter table "public"."visitor_creator_follow" add constraint "visitor_creator_follow_creator_id_fkey" FOREIGN KEY (creator_id) REFERENCES public.creator(id) ON DELETE CASCADE not valid;

alter table "public"."visitor_creator_follow" validate constraint "visitor_creator_follow_creator_id_fkey";

alter table "public"."visitor_creator_follow" add constraint "visitor_creator_follow_visitor_id_creator_id_key" UNIQUE using index "visitor_creator_follow_visitor_id_creator_id_key";

alter table "public"."visitor_creator_follow" add constraint "visitor_creator_follow_visitor_id_fkey" FOREIGN KEY (visitor_id) REFERENCES public.visitor(id) ON DELETE CASCADE not valid;

alter table "public"."visitor_creator_follow" validate constraint "visitor_creator_follow_visitor_id_fkey";

alter table "public"."visitor_fan_subscription" add constraint "visitor_fan_subscription_creator_id_fkey" FOREIGN KEY (creator_id) REFERENCES public.creator(id) ON DELETE CASCADE not valid;

alter table "public"."visitor_fan_subscription" validate constraint "visitor_fan_subscription_creator_id_fkey";

alter table "public"."visitor_fan_subscription" add constraint "visitor_fan_subscription_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'cancelled'::text, 'past_due'::text]))) not valid;

alter table "public"."visitor_fan_subscription" validate constraint "visitor_fan_subscription_status_check";

alter table "public"."visitor_fan_subscription" add constraint "visitor_fan_subscription_visitor_id_creator_id_key" UNIQUE using index "visitor_fan_subscription_visitor_id_creator_id_key";

alter table "public"."visitor_fan_subscription" add constraint "visitor_fan_subscription_visitor_id_fkey" FOREIGN KEY (visitor_id) REFERENCES public.visitor(id) ON DELETE CASCADE not valid;

alter table "public"."visitor_fan_subscription" validate constraint "visitor_fan_subscription_visitor_id_fkey";

alter table "public"."conversation_request" add constraint "conversation_request_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text]))) not valid;

alter table "public"."conversation_request" validate constraint "conversation_request_status_check";

alter table "public"."fan_subscription" add constraint "fan_subscription_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'cancelled'::text]))) not valid;

alter table "public"."fan_subscription" validate constraint "fan_subscription_status_check";

alter table "public"."meal_consumption" add constraint "meal_consumption_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES public.recipe(id) ON DELETE CASCADE not valid;

alter table "public"."meal_consumption" validate constraint "meal_consumption_recipe_id_fkey";

alter table "public"."payout" add constraint "payout_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'processing'::text, 'completed'::text, 'failed'::text]))) not valid;

alter table "public"."payout" validate constraint "payout_status_check";

alter table "public"."recipe" add constraint "recipe_parent_recipe_id_fkey" FOREIGN KEY (parent_recipe_id) REFERENCES public.recipe(id) not valid;

alter table "public"."recipe" validate constraint "recipe_parent_recipe_id_fkey";

alter table "public"."subscription" add constraint "subscription_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'cancelled'::text, 'past_due'::text, 'trialing'::text]))) not valid;

alter table "public"."subscription" validate constraint "subscription_status_check";

set check_function_bodies = off;

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

CREATE OR REPLACE FUNCTION public.get_recipes_feeed()
 RETURNS SETOF public.recipe
 LANGUAGE sql
 SECURITY DEFINER
AS $function$SELECT * FROM recipe;$function$
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

create or replace view "public"."total_notifications" as  SELECT user_id,
    count(*) FILTER (WHERE (is_read = false)) AS total_notification,
    count(*) FILTER (WHERE ((type = 'chat'::text) AND (is_read = false))) AS chat_count,
    count(*) FILTER (WHERE ((type = 'demand'::text) AND (is_read = false))) AS demand_count,
    count(*) FILTER (WHERE ((type = 'meal'::text) AND (is_read = false))) AS meal_count
   FROM public.notification
  GROUP BY user_id
 HAVING (count(*) FILTER (WHERE (is_read = false)) > 0);


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

CREATE OR REPLACE FUNCTION public.generate_groups_personalized(p_user_id uuid, p_limit integer DEFAULT 20, p_exclude uuid[] DEFAULT '{}'::uuid[])
 RETURNS TABLE(group_id uuid, score numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
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
    RETURN QUERY
    SELECT cg.id AS group_id, 0::numeric AS score
    FROM community_group cg
    LEFT JOIN user_profile up ON up.id = p_user_id
    WHERE cg.is_public = true
      AND cg.id <> ALL(p_exclude)
      AND (
        cg.language = up.locale
        OR cg.region_code IN (
          SELECT ucp.region FROM user_cuisine_preference ucp
          WHERE ucp.user_id = p_user_id
        )
      )
    ORDER BY cg.member_count DESC
    LIMIT LEAST(p_limit, 100);
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    cg.id                                           AS group_id,
    (1 - (gv.vector <=> v_user_vector))::numeric    AS score
  FROM community_group cg
  JOIN group_vector gv ON gv.group_id = cg.id
  WHERE cg.is_public = true
    AND cg.id <> ALL(p_exclude)
  ORDER BY (gv.vector <=> v_user_vector) ASC
  LIMIT LEAST(p_limit, 100);
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

CREATE OR REPLACE FUNCTION public.recommend_recipes(p_user_id uuid, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0, p_region text DEFAULT NULL::text, p_difficulty text DEFAULT NULL::text, p_max_time integer DEFAULT NULL::integer)
 RETURNS TABLE(id uuid, title text, description text, cover_image_url text, region text, difficulty text, prep_time_min integer, cook_time_min integer, servings integer, creator_id uuid, creator_name text, creator_avatar text, calories numeric, protein_g numeric, like_count bigint, similarity double precision)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_vector vector(50);
  v_fan_creator_id uuid;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv
  WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  IF v_user_vector IS NULL THEN
    RETURN QUERY
    WITH user_allergens AS (
      SELECT COALESCE(array_agg(a.slug), '{}') AS tags
      FROM user_allergy ua
      JOIN allergen a ON a.id = ua.allergen_id
      WHERE ua.user_id = p_user_id
    )
    SELECT
      r.id, r.title, r.description, r.cover_image_url, r.region, r.difficulty, r.prep_time_min, r.cook_time_min, r.servings, r.creator_id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, COUNT(rl.recipe_id)::bigint AS like_count, 0.5::float AS similarity
    FROM recipe r
    LEFT JOIN creator c ON r.creator_id = c.id
    LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
    LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
    WHERE r.is_published = true
      AND (p_region IS NULL OR r.region = p_region)
      AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
      AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
      AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
    GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g
    ORDER BY like_count DESC
    LIMIT p_limit
    OFFSET p_offset;
    RETURN;
  END IF;

  RETURN QUERY
  WITH user_allergens AS (
    SELECT COALESCE(array_agg(a.slug), '{}') AS tags
    FROM user_allergy ua
    JOIN allergen a ON a.id = ua.allergen_id
    WHERE ua.user_id = p_user_id
  )
  SELECT
    r.id, r.title, r.description, r.cover_image_url, r.region, r.difficulty, r.prep_time_min, r.cook_time_min, r.servings, r.creator_id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, COUNT(rl.recipe_id)::bigint AS like_count,
    (1 - (rv.vector <=> v_user_vector)) *
      CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
        THEN 1.5 ELSE 1.0 END AS similarity
  FROM recipe r
  JOIN recipe_vector rv ON r.id = rv.recipe_id
  LEFT JOIN creator c ON r.creator_id = c.id
  LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
  LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
  WHERE r.is_published = true
    AND (p_region IS NULL OR r.region = p_region)
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
    AND (p_max_time IS NULL OR (COALESCE(r.prep_time_min, 0) + COALESCE(r.cook_time_min, 0)) <= p_max_time)
    AND NOT (r.allergen_tags && (SELECT tags FROM user_allergens))
  GROUP BY r.id, c.display_name, c.avatar_url, rm.calories, rm.protein_g, rv.vector, v_fan_creator_id
  ORDER BY similarity DESC
  LIMIT p_limit
  OFFSET p_offset;
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

grant delete on table "public"."batch_run_failure" to "anon";

grant insert on table "public"."batch_run_failure" to "anon";

grant references on table "public"."batch_run_failure" to "anon";

grant select on table "public"."batch_run_failure" to "anon";

grant trigger on table "public"."batch_run_failure" to "anon";

grant truncate on table "public"."batch_run_failure" to "anon";

grant update on table "public"."batch_run_failure" to "anon";

grant delete on table "public"."batch_run_failure" to "authenticated";

grant insert on table "public"."batch_run_failure" to "authenticated";

grant references on table "public"."batch_run_failure" to "authenticated";

grant select on table "public"."batch_run_failure" to "authenticated";

grant trigger on table "public"."batch_run_failure" to "authenticated";

grant truncate on table "public"."batch_run_failure" to "authenticated";

grant update on table "public"."batch_run_failure" to "authenticated";

grant delete on table "public"."batch_run_failure" to "service_role";

grant insert on table "public"."batch_run_failure" to "service_role";

grant references on table "public"."batch_run_failure" to "service_role";

grant select on table "public"."batch_run_failure" to "service_role";

grant trigger on table "public"."batch_run_failure" to "service_role";

grant truncate on table "public"."batch_run_failure" to "service_role";

grant update on table "public"."batch_run_failure" to "service_role";

grant delete on table "public"."batch_run_log" to "anon";

grant insert on table "public"."batch_run_log" to "anon";

grant references on table "public"."batch_run_log" to "anon";

grant select on table "public"."batch_run_log" to "anon";

grant trigger on table "public"."batch_run_log" to "anon";

grant truncate on table "public"."batch_run_log" to "anon";

grant update on table "public"."batch_run_log" to "anon";

grant delete on table "public"."batch_run_log" to "authenticated";

grant insert on table "public"."batch_run_log" to "authenticated";

grant references on table "public"."batch_run_log" to "authenticated";

grant select on table "public"."batch_run_log" to "authenticated";

grant trigger on table "public"."batch_run_log" to "authenticated";

grant truncate on table "public"."batch_run_log" to "authenticated";

grant update on table "public"."batch_run_log" to "authenticated";

grant delete on table "public"."batch_run_log" to "service_role";

grant insert on table "public"."batch_run_log" to "service_role";

grant references on table "public"."batch_run_log" to "service_role";

grant select on table "public"."batch_run_log" to "service_role";

grant trigger on table "public"."batch_run_log" to "service_role";

grant truncate on table "public"."batch_run_log" to "service_role";

grant update on table "public"."batch_run_log" to "service_role";

grant delete on table "public"."blog_comment" to "anon";

grant insert on table "public"."blog_comment" to "anon";

grant references on table "public"."blog_comment" to "anon";

grant select on table "public"."blog_comment" to "anon";

grant trigger on table "public"."blog_comment" to "anon";

grant truncate on table "public"."blog_comment" to "anon";

grant update on table "public"."blog_comment" to "anon";

grant delete on table "public"."blog_comment" to "authenticated";

grant insert on table "public"."blog_comment" to "authenticated";

grant references on table "public"."blog_comment" to "authenticated";

grant select on table "public"."blog_comment" to "authenticated";

grant trigger on table "public"."blog_comment" to "authenticated";

grant truncate on table "public"."blog_comment" to "authenticated";

grant update on table "public"."blog_comment" to "authenticated";

grant delete on table "public"."blog_comment" to "service_role";

grant insert on table "public"."blog_comment" to "service_role";

grant references on table "public"."blog_comment" to "service_role";

grant select on table "public"."blog_comment" to "service_role";

grant trigger on table "public"."blog_comment" to "service_role";

grant truncate on table "public"."blog_comment" to "service_role";

grant update on table "public"."blog_comment" to "service_role";

grant delete on table "public"."blog_post" to "anon";

grant insert on table "public"."blog_post" to "anon";

grant references on table "public"."blog_post" to "anon";

grant select on table "public"."blog_post" to "anon";

grant trigger on table "public"."blog_post" to "anon";

grant truncate on table "public"."blog_post" to "anon";

grant update on table "public"."blog_post" to "anon";

grant delete on table "public"."blog_post" to "authenticated";

grant insert on table "public"."blog_post" to "authenticated";

grant references on table "public"."blog_post" to "authenticated";

grant select on table "public"."blog_post" to "authenticated";

grant trigger on table "public"."blog_post" to "authenticated";

grant truncate on table "public"."blog_post" to "authenticated";

grant update on table "public"."blog_post" to "authenticated";

grant delete on table "public"."blog_post" to "service_role";

grant insert on table "public"."blog_post" to "service_role";

grant references on table "public"."blog_post" to "service_role";

grant select on table "public"."blog_post" to "service_role";

grant trigger on table "public"."blog_post" to "service_role";

grant truncate on table "public"."blog_post" to "service_role";

grant update on table "public"."blog_post" to "service_role";

grant delete on table "public"."blog_post_like" to "anon";

grant insert on table "public"."blog_post_like" to "anon";

grant references on table "public"."blog_post_like" to "anon";

grant select on table "public"."blog_post_like" to "anon";

grant trigger on table "public"."blog_post_like" to "anon";

grant truncate on table "public"."blog_post_like" to "anon";

grant update on table "public"."blog_post_like" to "anon";

grant delete on table "public"."blog_post_like" to "authenticated";

grant insert on table "public"."blog_post_like" to "authenticated";

grant references on table "public"."blog_post_like" to "authenticated";

grant select on table "public"."blog_post_like" to "authenticated";

grant trigger on table "public"."blog_post_like" to "authenticated";

grant truncate on table "public"."blog_post_like" to "authenticated";

grant update on table "public"."blog_post_like" to "authenticated";

grant delete on table "public"."blog_post_like" to "service_role";

grant insert on table "public"."blog_post_like" to "service_role";

grant references on table "public"."blog_post_like" to "service_role";

grant select on table "public"."blog_post_like" to "service_role";

grant trigger on table "public"."blog_post_like" to "service_role";

grant truncate on table "public"."blog_post_like" to "service_role";

grant update on table "public"."blog_post_like" to "service_role";

grant delete on table "public"."blog_post_translation" to "anon";

grant insert on table "public"."blog_post_translation" to "anon";

grant references on table "public"."blog_post_translation" to "anon";

grant select on table "public"."blog_post_translation" to "anon";

grant trigger on table "public"."blog_post_translation" to "anon";

grant truncate on table "public"."blog_post_translation" to "anon";

grant update on table "public"."blog_post_translation" to "anon";

grant delete on table "public"."blog_post_translation" to "authenticated";

grant insert on table "public"."blog_post_translation" to "authenticated";

grant references on table "public"."blog_post_translation" to "authenticated";

grant select on table "public"."blog_post_translation" to "authenticated";

grant trigger on table "public"."blog_post_translation" to "authenticated";

grant truncate on table "public"."blog_post_translation" to "authenticated";

grant update on table "public"."blog_post_translation" to "authenticated";

grant delete on table "public"."blog_post_translation" to "service_role";

grant insert on table "public"."blog_post_translation" to "service_role";

grant references on table "public"."blog_post_translation" to "service_role";

grant select on table "public"."blog_post_translation" to "service_role";

grant trigger on table "public"."blog_post_translation" to "service_role";

grant truncate on table "public"."blog_post_translation" to "service_role";

grant update on table "public"."blog_post_translation" to "service_role";

grant delete on table "public"."creator_follow" to "anon";

grant insert on table "public"."creator_follow" to "anon";

grant references on table "public"."creator_follow" to "anon";

grant select on table "public"."creator_follow" to "anon";

grant trigger on table "public"."creator_follow" to "anon";

grant truncate on table "public"."creator_follow" to "anon";

grant update on table "public"."creator_follow" to "anon";

grant delete on table "public"."creator_follow" to "authenticated";

grant insert on table "public"."creator_follow" to "authenticated";

grant references on table "public"."creator_follow" to "authenticated";

grant select on table "public"."creator_follow" to "authenticated";

grant trigger on table "public"."creator_follow" to "authenticated";

grant truncate on table "public"."creator_follow" to "authenticated";

grant update on table "public"."creator_follow" to "authenticated";

grant delete on table "public"."creator_follow" to "service_role";

grant insert on table "public"."creator_follow" to "service_role";

grant references on table "public"."creator_follow" to "service_role";

grant select on table "public"."creator_follow" to "service_role";

grant trigger on table "public"."creator_follow" to "service_role";

grant truncate on table "public"."creator_follow" to "service_role";

grant update on table "public"."creator_follow" to "service_role";

grant delete on table "public"."creator_payout_identity" to "anon";

grant insert on table "public"."creator_payout_identity" to "anon";

grant references on table "public"."creator_payout_identity" to "anon";

grant select on table "public"."creator_payout_identity" to "anon";

grant trigger on table "public"."creator_payout_identity" to "anon";

grant truncate on table "public"."creator_payout_identity" to "anon";

grant update on table "public"."creator_payout_identity" to "anon";

grant delete on table "public"."creator_payout_identity" to "authenticated";

grant insert on table "public"."creator_payout_identity" to "authenticated";

grant references on table "public"."creator_payout_identity" to "authenticated";

grant select on table "public"."creator_payout_identity" to "authenticated";

grant trigger on table "public"."creator_payout_identity" to "authenticated";

grant truncate on table "public"."creator_payout_identity" to "authenticated";

grant update on table "public"."creator_payout_identity" to "authenticated";

grant delete on table "public"."creator_payout_identity" to "service_role";

grant insert on table "public"."creator_payout_identity" to "service_role";

grant references on table "public"."creator_payout_identity" to "service_role";

grant select on table "public"."creator_payout_identity" to "service_role";

grant trigger on table "public"."creator_payout_identity" to "service_role";

grant truncate on table "public"."creator_payout_identity" to "service_role";

grant update on table "public"."creator_payout_identity" to "service_role";

grant delete on table "public"."creator_stripe_account" to "anon";

grant insert on table "public"."creator_stripe_account" to "anon";

grant references on table "public"."creator_stripe_account" to "anon";

grant select on table "public"."creator_stripe_account" to "anon";

grant trigger on table "public"."creator_stripe_account" to "anon";

grant truncate on table "public"."creator_stripe_account" to "anon";

grant update on table "public"."creator_stripe_account" to "anon";

grant delete on table "public"."creator_stripe_account" to "authenticated";

grant insert on table "public"."creator_stripe_account" to "authenticated";

grant references on table "public"."creator_stripe_account" to "authenticated";

grant select on table "public"."creator_stripe_account" to "authenticated";

grant trigger on table "public"."creator_stripe_account" to "authenticated";

grant truncate on table "public"."creator_stripe_account" to "authenticated";

grant update on table "public"."creator_stripe_account" to "authenticated";

grant delete on table "public"."creator_stripe_account" to "service_role";

grant insert on table "public"."creator_stripe_account" to "service_role";

grant references on table "public"."creator_stripe_account" to "service_role";

grant select on table "public"."creator_stripe_account" to "service_role";

grant trigger on table "public"."creator_stripe_account" to "service_role";

grant truncate on table "public"."creator_stripe_account" to "service_role";

grant update on table "public"."creator_stripe_account" to "service_role";

grant delete on table "public"."ingredient_submission" to "anon";

grant insert on table "public"."ingredient_submission" to "anon";

grant references on table "public"."ingredient_submission" to "anon";

grant select on table "public"."ingredient_submission" to "anon";

grant trigger on table "public"."ingredient_submission" to "anon";

grant truncate on table "public"."ingredient_submission" to "anon";

grant update on table "public"."ingredient_submission" to "anon";

grant delete on table "public"."ingredient_submission" to "authenticated";

grant insert on table "public"."ingredient_submission" to "authenticated";

grant references on table "public"."ingredient_submission" to "authenticated";

grant select on table "public"."ingredient_submission" to "authenticated";

grant trigger on table "public"."ingredient_submission" to "authenticated";

grant truncate on table "public"."ingredient_submission" to "authenticated";

grant update on table "public"."ingredient_submission" to "authenticated";

grant delete on table "public"."ingredient_submission" to "service_role";

grant insert on table "public"."ingredient_submission" to "service_role";

grant references on table "public"."ingredient_submission" to "service_role";

grant select on table "public"."ingredient_submission" to "service_role";

grant trigger on table "public"."ingredient_submission" to "service_role";

grant truncate on table "public"."ingredient_submission" to "service_role";

grant update on table "public"."ingredient_submission" to "service_role";

grant delete on table "public"."landing_event" to "anon";

grant insert on table "public"."landing_event" to "anon";

grant references on table "public"."landing_event" to "anon";

grant select on table "public"."landing_event" to "anon";

grant trigger on table "public"."landing_event" to "anon";

grant truncate on table "public"."landing_event" to "anon";

grant update on table "public"."landing_event" to "anon";

grant delete on table "public"."landing_event" to "authenticated";

grant insert on table "public"."landing_event" to "authenticated";

grant references on table "public"."landing_event" to "authenticated";

grant select on table "public"."landing_event" to "authenticated";

grant trigger on table "public"."landing_event" to "authenticated";

grant truncate on table "public"."landing_event" to "authenticated";

grant update on table "public"."landing_event" to "authenticated";

grant delete on table "public"."landing_event" to "service_role";

grant insert on table "public"."landing_event" to "service_role";

grant references on table "public"."landing_event" to "service_role";

grant select on table "public"."landing_event" to "service_role";

grant trigger on table "public"."landing_event" to "service_role";

grant truncate on table "public"."landing_event" to "service_role";

grant update on table "public"."landing_event" to "service_role";

grant delete on table "public"."onboarding_lead" to "anon";

grant insert on table "public"."onboarding_lead" to "anon";

grant references on table "public"."onboarding_lead" to "anon";

grant select on table "public"."onboarding_lead" to "anon";

grant trigger on table "public"."onboarding_lead" to "anon";

grant truncate on table "public"."onboarding_lead" to "anon";

grant update on table "public"."onboarding_lead" to "anon";

grant delete on table "public"."onboarding_lead" to "authenticated";

grant insert on table "public"."onboarding_lead" to "authenticated";

grant references on table "public"."onboarding_lead" to "authenticated";

grant select on table "public"."onboarding_lead" to "authenticated";

grant trigger on table "public"."onboarding_lead" to "authenticated";

grant truncate on table "public"."onboarding_lead" to "authenticated";

grant update on table "public"."onboarding_lead" to "authenticated";

grant delete on table "public"."onboarding_lead" to "service_role";

grant insert on table "public"."onboarding_lead" to "service_role";

grant references on table "public"."onboarding_lead" to "service_role";

grant select on table "public"."onboarding_lead" to "service_role";

grant trigger on table "public"."onboarding_lead" to "service_role";

grant truncate on table "public"."onboarding_lead" to "service_role";

grant update on table "public"."onboarding_lead" to "service_role";

grant delete on table "public"."recipe_cleaner_call" to "anon";

grant insert on table "public"."recipe_cleaner_call" to "anon";

grant references on table "public"."recipe_cleaner_call" to "anon";

grant select on table "public"."recipe_cleaner_call" to "anon";

grant trigger on table "public"."recipe_cleaner_call" to "anon";

grant truncate on table "public"."recipe_cleaner_call" to "anon";

grant update on table "public"."recipe_cleaner_call" to "anon";

grant delete on table "public"."recipe_cleaner_call" to "authenticated";

grant insert on table "public"."recipe_cleaner_call" to "authenticated";

grant references on table "public"."recipe_cleaner_call" to "authenticated";

grant select on table "public"."recipe_cleaner_call" to "authenticated";

grant trigger on table "public"."recipe_cleaner_call" to "authenticated";

grant truncate on table "public"."recipe_cleaner_call" to "authenticated";

grant update on table "public"."recipe_cleaner_call" to "authenticated";

grant delete on table "public"."recipe_cleaner_call" to "service_role";

grant insert on table "public"."recipe_cleaner_call" to "service_role";

grant references on table "public"."recipe_cleaner_call" to "service_role";

grant select on table "public"."recipe_cleaner_call" to "service_role";

grant trigger on table "public"."recipe_cleaner_call" to "service_role";

grant truncate on table "public"."recipe_cleaner_call" to "service_role";

grant update on table "public"."recipe_cleaner_call" to "service_role";

grant delete on table "public"."recipe_development" to "anon";

grant insert on table "public"."recipe_development" to "anon";

grant references on table "public"."recipe_development" to "anon";

grant select on table "public"."recipe_development" to "anon";

grant trigger on table "public"."recipe_development" to "anon";

grant truncate on table "public"."recipe_development" to "anon";

grant update on table "public"."recipe_development" to "anon";

grant delete on table "public"."recipe_development" to "authenticated";

grant insert on table "public"."recipe_development" to "authenticated";

grant references on table "public"."recipe_development" to "authenticated";

grant select on table "public"."recipe_development" to "authenticated";

grant trigger on table "public"."recipe_development" to "authenticated";

grant truncate on table "public"."recipe_development" to "authenticated";

grant update on table "public"."recipe_development" to "authenticated";

grant delete on table "public"."recipe_development" to "service_role";

grant insert on table "public"."recipe_development" to "service_role";

grant references on table "public"."recipe_development" to "service_role";

grant select on table "public"."recipe_development" to "service_role";

grant trigger on table "public"."recipe_development" to "service_role";

grant truncate on table "public"."recipe_development" to "service_role";

grant update on table "public"."recipe_development" to "service_role";

grant delete on table "public"."recipe_step_translation" to "anon";

grant insert on table "public"."recipe_step_translation" to "anon";

grant references on table "public"."recipe_step_translation" to "anon";

grant select on table "public"."recipe_step_translation" to "anon";

grant trigger on table "public"."recipe_step_translation" to "anon";

grant truncate on table "public"."recipe_step_translation" to "anon";

grant update on table "public"."recipe_step_translation" to "anon";

grant delete on table "public"."recipe_step_translation" to "authenticated";

grant insert on table "public"."recipe_step_translation" to "authenticated";

grant references on table "public"."recipe_step_translation" to "authenticated";

grant select on table "public"."recipe_step_translation" to "authenticated";

grant trigger on table "public"."recipe_step_translation" to "authenticated";

grant truncate on table "public"."recipe_step_translation" to "authenticated";

grant update on table "public"."recipe_step_translation" to "authenticated";

grant delete on table "public"."recipe_step_translation" to "service_role";

grant insert on table "public"."recipe_step_translation" to "service_role";

grant references on table "public"."recipe_step_translation" to "service_role";

grant select on table "public"."recipe_step_translation" to "service_role";

grant trigger on table "public"."recipe_step_translation" to "service_role";

grant truncate on table "public"."recipe_step_translation" to "service_role";

grant update on table "public"."recipe_step_translation" to "service_role";

grant delete on table "public"."recipe_translation" to "anon";

grant insert on table "public"."recipe_translation" to "anon";

grant references on table "public"."recipe_translation" to "anon";

grant select on table "public"."recipe_translation" to "anon";

grant trigger on table "public"."recipe_translation" to "anon";

grant truncate on table "public"."recipe_translation" to "anon";

grant update on table "public"."recipe_translation" to "anon";

grant delete on table "public"."recipe_translation" to "authenticated";

grant insert on table "public"."recipe_translation" to "authenticated";

grant references on table "public"."recipe_translation" to "authenticated";

grant select on table "public"."recipe_translation" to "authenticated";

grant trigger on table "public"."recipe_translation" to "authenticated";

grant truncate on table "public"."recipe_translation" to "authenticated";

grant update on table "public"."recipe_translation" to "authenticated";

grant delete on table "public"."recipe_translation" to "service_role";

grant insert on table "public"."recipe_translation" to "service_role";

grant references on table "public"."recipe_translation" to "service_role";

grant select on table "public"."recipe_translation" to "service_role";

grant trigger on table "public"."recipe_translation" to "service_role";

grant truncate on table "public"."recipe_translation" to "service_role";

grant update on table "public"."recipe_translation" to "service_role";

grant delete on table "public"."recipe_weight_impact" to "anon";

grant insert on table "public"."recipe_weight_impact" to "anon";

grant references on table "public"."recipe_weight_impact" to "anon";

grant select on table "public"."recipe_weight_impact" to "anon";

grant trigger on table "public"."recipe_weight_impact" to "anon";

grant truncate on table "public"."recipe_weight_impact" to "anon";

grant update on table "public"."recipe_weight_impact" to "anon";

grant delete on table "public"."recipe_weight_impact" to "authenticated";

grant insert on table "public"."recipe_weight_impact" to "authenticated";

grant references on table "public"."recipe_weight_impact" to "authenticated";

grant select on table "public"."recipe_weight_impact" to "authenticated";

grant trigger on table "public"."recipe_weight_impact" to "authenticated";

grant truncate on table "public"."recipe_weight_impact" to "authenticated";

grant update on table "public"."recipe_weight_impact" to "authenticated";

grant delete on table "public"."recipe_weight_impact" to "service_role";

grant insert on table "public"."recipe_weight_impact" to "service_role";

grant references on table "public"."recipe_weight_impact" to "service_role";

grant select on table "public"."recipe_weight_impact" to "service_role";

grant trigger on table "public"."recipe_weight_impact" to "service_role";

grant truncate on table "public"."recipe_weight_impact" to "service_role";

grant update on table "public"."recipe_weight_impact" to "service_role";

grant delete on table "public"."report" to "anon";

grant insert on table "public"."report" to "anon";

grant references on table "public"."report" to "anon";

grant select on table "public"."report" to "anon";

grant trigger on table "public"."report" to "anon";

grant truncate on table "public"."report" to "anon";

grant update on table "public"."report" to "anon";

grant delete on table "public"."report" to "authenticated";

grant insert on table "public"."report" to "authenticated";

grant references on table "public"."report" to "authenticated";

grant select on table "public"."report" to "authenticated";

grant trigger on table "public"."report" to "authenticated";

grant truncate on table "public"."report" to "authenticated";

grant update on table "public"."report" to "authenticated";

grant delete on table "public"."report" to "service_role";

grant insert on table "public"."report" to "service_role";

grant references on table "public"."report" to "service_role";

grant select on table "public"."report" to "service_role";

grant trigger on table "public"."report" to "service_role";

grant truncate on table "public"."report" to "service_role";

grant update on table "public"."report" to "service_role";

grant delete on table "public"."specialty" to "anon";

grant insert on table "public"."specialty" to "anon";

grant references on table "public"."specialty" to "anon";

grant select on table "public"."specialty" to "anon";

grant trigger on table "public"."specialty" to "anon";

grant truncate on table "public"."specialty" to "anon";

grant update on table "public"."specialty" to "anon";

grant delete on table "public"."specialty" to "authenticated";

grant insert on table "public"."specialty" to "authenticated";

grant references on table "public"."specialty" to "authenticated";

grant select on table "public"."specialty" to "authenticated";

grant trigger on table "public"."specialty" to "authenticated";

grant truncate on table "public"."specialty" to "authenticated";

grant update on table "public"."specialty" to "authenticated";

grant delete on table "public"."specialty" to "service_role";

grant insert on table "public"."specialty" to "service_role";

grant references on table "public"."specialty" to "service_role";

grant select on table "public"."specialty" to "service_role";

grant trigger on table "public"."specialty" to "service_role";

grant truncate on table "public"."specialty" to "service_role";

grant update on table "public"."specialty" to "service_role";

grant delete on table "public"."sync_log" to "anon";

grant insert on table "public"."sync_log" to "anon";

grant references on table "public"."sync_log" to "anon";

grant select on table "public"."sync_log" to "anon";

grant trigger on table "public"."sync_log" to "anon";

grant truncate on table "public"."sync_log" to "anon";

grant update on table "public"."sync_log" to "anon";

grant delete on table "public"."sync_log" to "authenticated";

grant insert on table "public"."sync_log" to "authenticated";

grant references on table "public"."sync_log" to "authenticated";

grant select on table "public"."sync_log" to "authenticated";

grant trigger on table "public"."sync_log" to "authenticated";

grant truncate on table "public"."sync_log" to "authenticated";

grant update on table "public"."sync_log" to "authenticated";

grant delete on table "public"."sync_log" to "service_role";

grant insert on table "public"."sync_log" to "service_role";

grant references on table "public"."sync_log" to "service_role";

grant select on table "public"."sync_log" to "service_role";

grant trigger on table "public"."sync_log" to "service_role";

grant truncate on table "public"."sync_log" to "service_role";

grant update on table "public"."sync_log" to "service_role";

grant delete on table "public"."test_ingredient" to "anon";

grant insert on table "public"."test_ingredient" to "anon";

grant references on table "public"."test_ingredient" to "anon";

grant select on table "public"."test_ingredient" to "anon";

grant trigger on table "public"."test_ingredient" to "anon";

grant truncate on table "public"."test_ingredient" to "anon";

grant update on table "public"."test_ingredient" to "anon";

grant delete on table "public"."test_ingredient" to "authenticated";

grant insert on table "public"."test_ingredient" to "authenticated";

grant references on table "public"."test_ingredient" to "authenticated";

grant select on table "public"."test_ingredient" to "authenticated";

grant trigger on table "public"."test_ingredient" to "authenticated";

grant truncate on table "public"."test_ingredient" to "authenticated";

grant update on table "public"."test_ingredient" to "authenticated";

grant delete on table "public"."test_ingredient" to "service_role";

grant insert on table "public"."test_ingredient" to "service_role";

grant references on table "public"."test_ingredient" to "service_role";

grant select on table "public"."test_ingredient" to "service_role";

grant trigger on table "public"."test_ingredient" to "service_role";

grant truncate on table "public"."test_ingredient" to "service_role";

grant update on table "public"."test_ingredient" to "service_role";

grant delete on table "public"."unit_conversion" to "anon";

grant insert on table "public"."unit_conversion" to "anon";

grant references on table "public"."unit_conversion" to "anon";

grant select on table "public"."unit_conversion" to "anon";

grant trigger on table "public"."unit_conversion" to "anon";

grant truncate on table "public"."unit_conversion" to "anon";

grant update on table "public"."unit_conversion" to "anon";

grant delete on table "public"."unit_conversion" to "authenticated";

grant insert on table "public"."unit_conversion" to "authenticated";

grant references on table "public"."unit_conversion" to "authenticated";

grant select on table "public"."unit_conversion" to "authenticated";

grant trigger on table "public"."unit_conversion" to "authenticated";

grant truncate on table "public"."unit_conversion" to "authenticated";

grant update on table "public"."unit_conversion" to "authenticated";

grant delete on table "public"."unit_conversion" to "service_role";

grant insert on table "public"."unit_conversion" to "service_role";

grant references on table "public"."unit_conversion" to "service_role";

grant select on table "public"."unit_conversion" to "service_role";

grant trigger on table "public"."unit_conversion" to "service_role";

grant truncate on table "public"."unit_conversion" to "service_role";

grant update on table "public"."unit_conversion" to "service_role";

grant delete on table "public"."visitor" to "anon";

grant insert on table "public"."visitor" to "anon";

grant references on table "public"."visitor" to "anon";

grant select on table "public"."visitor" to "anon";

grant trigger on table "public"."visitor" to "anon";

grant truncate on table "public"."visitor" to "anon";

grant update on table "public"."visitor" to "anon";

grant delete on table "public"."visitor" to "authenticated";

grant insert on table "public"."visitor" to "authenticated";

grant references on table "public"."visitor" to "authenticated";

grant select on table "public"."visitor" to "authenticated";

grant trigger on table "public"."visitor" to "authenticated";

grant truncate on table "public"."visitor" to "authenticated";

grant update on table "public"."visitor" to "authenticated";

grant delete on table "public"."visitor" to "service_role";

grant insert on table "public"."visitor" to "service_role";

grant references on table "public"."visitor" to "service_role";

grant select on table "public"."visitor" to "service_role";

grant trigger on table "public"."visitor" to "service_role";

grant truncate on table "public"."visitor" to "service_role";

grant update on table "public"."visitor" to "service_role";

grant delete on table "public"."visitor_auth_token" to "anon";

grant insert on table "public"."visitor_auth_token" to "anon";

grant references on table "public"."visitor_auth_token" to "anon";

grant select on table "public"."visitor_auth_token" to "anon";

grant trigger on table "public"."visitor_auth_token" to "anon";

grant truncate on table "public"."visitor_auth_token" to "anon";

grant update on table "public"."visitor_auth_token" to "anon";

grant delete on table "public"."visitor_auth_token" to "authenticated";

grant insert on table "public"."visitor_auth_token" to "authenticated";

grant references on table "public"."visitor_auth_token" to "authenticated";

grant select on table "public"."visitor_auth_token" to "authenticated";

grant trigger on table "public"."visitor_auth_token" to "authenticated";

grant truncate on table "public"."visitor_auth_token" to "authenticated";

grant update on table "public"."visitor_auth_token" to "authenticated";

grant delete on table "public"."visitor_auth_token" to "service_role";

grant insert on table "public"."visitor_auth_token" to "service_role";

grant references on table "public"."visitor_auth_token" to "service_role";

grant select on table "public"."visitor_auth_token" to "service_role";

grant trigger on table "public"."visitor_auth_token" to "service_role";

grant truncate on table "public"."visitor_auth_token" to "service_role";

grant update on table "public"."visitor_auth_token" to "service_role";

grant delete on table "public"."visitor_creator_follow" to "anon";

grant insert on table "public"."visitor_creator_follow" to "anon";

grant references on table "public"."visitor_creator_follow" to "anon";

grant select on table "public"."visitor_creator_follow" to "anon";

grant trigger on table "public"."visitor_creator_follow" to "anon";

grant truncate on table "public"."visitor_creator_follow" to "anon";

grant update on table "public"."visitor_creator_follow" to "anon";

grant delete on table "public"."visitor_creator_follow" to "authenticated";

grant insert on table "public"."visitor_creator_follow" to "authenticated";

grant references on table "public"."visitor_creator_follow" to "authenticated";

grant select on table "public"."visitor_creator_follow" to "authenticated";

grant trigger on table "public"."visitor_creator_follow" to "authenticated";

grant truncate on table "public"."visitor_creator_follow" to "authenticated";

grant update on table "public"."visitor_creator_follow" to "authenticated";

grant delete on table "public"."visitor_creator_follow" to "service_role";

grant insert on table "public"."visitor_creator_follow" to "service_role";

grant references on table "public"."visitor_creator_follow" to "service_role";

grant select on table "public"."visitor_creator_follow" to "service_role";

grant trigger on table "public"."visitor_creator_follow" to "service_role";

grant truncate on table "public"."visitor_creator_follow" to "service_role";

grant update on table "public"."visitor_creator_follow" to "service_role";

grant delete on table "public"."visitor_fan_subscription" to "anon";

grant insert on table "public"."visitor_fan_subscription" to "anon";

grant references on table "public"."visitor_fan_subscription" to "anon";

grant select on table "public"."visitor_fan_subscription" to "anon";

grant trigger on table "public"."visitor_fan_subscription" to "anon";

grant truncate on table "public"."visitor_fan_subscription" to "anon";

grant update on table "public"."visitor_fan_subscription" to "anon";

grant delete on table "public"."visitor_fan_subscription" to "authenticated";

grant insert on table "public"."visitor_fan_subscription" to "authenticated";

grant references on table "public"."visitor_fan_subscription" to "authenticated";

grant select on table "public"."visitor_fan_subscription" to "authenticated";

grant trigger on table "public"."visitor_fan_subscription" to "authenticated";

grant truncate on table "public"."visitor_fan_subscription" to "authenticated";

grant update on table "public"."visitor_fan_subscription" to "authenticated";

grant delete on table "public"."visitor_fan_subscription" to "service_role";

grant insert on table "public"."visitor_fan_subscription" to "service_role";

grant references on table "public"."visitor_fan_subscription" to "service_role";

grant select on table "public"."visitor_fan_subscription" to "service_role";

grant trigger on table "public"."visitor_fan_subscription" to "service_role";

grant truncate on table "public"."visitor_fan_subscription" to "service_role";

grant update on table "public"."visitor_fan_subscription" to "service_role";


  create policy "owner only"
  on "public"."ai_conversation"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner via conversation"
  on "public"."ai_message"
  as permissive
  for select
  to public
using ((conversation_id IN ( SELECT ai_conversation.id
   FROM public.ai_conversation
  WHERE (ai_conversation.user_id = auth.uid()))));



  create policy "Akeli users manage own comments"
  on "public"."blog_comment"
  as permissive
  for all
  to public
using ((user_id = auth.uid()));



  create policy "Anyone reads comments on public posts"
  on "public"."blog_comment"
  as permissive
  for select
  to public
using ((post_id IN ( SELECT blog_post.id
   FROM public.blog_post
  WHERE ((blog_post.is_published = true) AND (blog_post.visibility = 'public'::text)))));



  create policy "Anyone reads published public posts"
  on "public"."blog_post"
  as permissive
  for select
  to public
using (((is_published = true) AND (visibility = 'public'::text)));



  create policy "Creators manage own posts"
  on "public"."blog_post"
  as permissive
  for all
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))));



  create policy "Akeli users manage own likes"
  on "public"."blog_post_like"
  as permissive
  for all
  to public
using ((user_id = auth.uid()));



  create policy "Creators manage own translations"
  on "public"."blog_post_translation"
  as permissive
  for all
  to public
using ((post_id IN ( SELECT bp.id
   FROM (public.blog_post bp
     JOIN public.creator c ON ((c.id = bp.creator_id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "Public reads published public translations"
  on "public"."blog_post_translation"
  as permissive
  for select
  to public
using ((post_id IN ( SELECT blog_post.id
   FROM public.blog_post
  WHERE ((blog_post.is_published = true) AND (blog_post.visibility = 'public'::text)))));



  create policy "participant can send message"
  on "public"."chat_message"
  as permissive
  for insert
  to public
with check (((sender_id = auth.uid()) AND (conversation_id IN ( SELECT conversation_participant.conversation_id
   FROM public.conversation_participant
  WHERE (conversation_participant.user_id = auth.uid())))));



  create policy "participant reads"
  on "public"."chat_message"
  as permissive
  for select
  to public
using (((conversation_id IN ( SELECT conversation_participant.conversation_id
   FROM public.conversation_participant
  WHERE (conversation_participant.user_id = auth.uid()))) OR (group_id IN ( SELECT group_member.group_id
   FROM public.group_member
  WHERE (group_member.user_id = auth.uid())))));



  create policy "conversation creator can update"
  on "public"."conversation"
  as permissive
  for update
  to public
using ((created_by = auth.uid()))
with check ((created_by = auth.uid()));



  create policy "creators create conversations"
  on "public"."conversation"
  as permissive
  for insert
  to public
with check ((auth.uid() IN ( SELECT creator.user_id
   FROM public.creator)));



  create policy "participants can close private conversation"
  on "public"."conversation"
  as permissive
  for update
  to public
using (((type = 'private'::text) AND (id IN ( SELECT conversation_participant.conversation_id
   FROM public.conversation_participant
  WHERE (conversation_participant.user_id = auth.uid())))))
with check (((type = 'private'::text) AND (id IN ( SELECT conversation_participant.conversation_id
   FROM public.conversation_participant
  WHERE (conversation_participant.user_id = auth.uid())))));



  create policy "participant manages"
  on "public"."conversation_participant"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "requester or recipient"
  on "public"."conversation_request"
  as permissive
  for select
  to public
using (((auth.uid() = requester_id) OR (auth.uid() = recipient_id)));



  create policy "owner manages"
  on "public"."creator"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "public reads"
  on "public"."creator"
  as permissive
  for select
  to public
using (true);



  create policy "creator reads own"
  on "public"."creator_balance"
  as permissive
  for select
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))));



  create policy "Users manage own follows"
  on "public"."creator_follow"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "creator inserts own"
  on "public"."creator_payout_identity"
  as permissive
  for insert
  to public
with check (((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))) AND (status = 'submitted'::text) AND (verified_at IS NULL)));



  create policy "creator reads own"
  on "public"."creator_payout_identity"
  as permissive
  for select
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))));



  create policy "creator updates own"
  on "public"."creator_payout_identity"
  as permissive
  for update
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))))
with check (((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))) AND (status = 'submitted'::text) AND (verified_at IS NULL)));



  create policy "creator reads own"
  on "public"."creator_revenue_log"
  as permissive
  for select
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))));



  create policy "creator_can_read_own_stripe_account"
  on "public"."creator_stripe_account"
  as permissive
  for select
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))));



  create policy "owner only"
  on "public"."daily_nutrition_log"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "creator reads own fans"
  on "public"."fan_subscription"
  as permissive
  for select
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))));



  create policy "owner manages"
  on "public"."fan_subscription"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "via subscription"
  on "public"."fan_subscription_history"
  as permissive
  for select
  to public
using ((subscription_id IN ( SELECT fan_subscription.id
   FROM public.fan_subscription
  WHERE (fan_subscription.user_id = auth.uid()))));



  create policy "public reads"
  on "public"."food_region"
  as permissive
  for select
  to public
using (true);



  create policy "creator reads own pending"
  on "public"."ingredient"
  as permissive
  for select
  to public
using (((status = 'pending'::text) AND (id IN ( SELECT ingredient_submission.ingredient_id
   FROM public.ingredient_submission
  WHERE (ingredient_submission.submitted_by = auth.uid())))));



  create policy "public reads validated"
  on "public"."ingredient"
  as permissive
  for select
  to public
using ((status = 'validated'::text));



  create policy "public reads"
  on "public"."ingredient_category"
  as permissive
  for select
  to public
using (true);



  create policy "authenticated reads ingredient_rounding_rule"
  on "public"."ingredient_rounding_rule"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "creator submits"
  on "public"."ingredient_submission"
  as permissive
  for insert
  to public
with check (((auth.uid() = submitted_by) AND (auth.uid() IN ( SELECT creator.user_id
   FROM public.creator))));



  create policy "submitter reads own"
  on "public"."ingredient_submission"
  as permissive
  for select
  to public
using ((auth.uid() = submitted_by));



  create policy "service_role_access"
  on "public"."landing_event"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "creators can view consumptions for their recipes"
  on "public"."meal_consumption"
  as permissive
  for select
  to public
using ((recipe_id IN ( SELECT recipe.id
   FROM public.recipe
  WHERE (recipe.creator_id IN ( SELECT creator.id
           FROM public.creator
          WHERE (creator.user_id = auth.uid()))))));



  create policy "owner only"
  on "public"."meal_consumption"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner only"
  on "public"."meal_plan"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner via meal_plan"
  on "public"."meal_plan_entry"
  as permissive
  for select
  to public
using ((meal_plan_id IN ( SELECT meal_plan.id
   FROM public.meal_plan
  WHERE (meal_plan.user_id = auth.uid()))));



  create policy "owner only"
  on "public"."meal_reminder"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "public reads"
  on "public"."measurement_unit"
  as permissive
  for select
  to public
using (true);



  create policy "owner only"
  on "public"."notification"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "service_role_access"
  on "public"."onboarding_lead"
  as permissive
  for all
  to service_role
using (true)
with check (true);



  create policy "creator reads own"
  on "public"."payout"
  as permissive
  for select
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))));



  create policy "owner only"
  on "public"."push_token"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "creator manages own"
  on "public"."recipe"
  as permissive
  for all
  to public
using ((creator_id IN ( SELECT creator.id
   FROM public.creator
  WHERE (creator.user_id = auth.uid()))));



  create policy "public can read published recipes"
  on "public"."recipe"
  as permissive
  for select
  to public
using ((is_published = true));



  create policy "public reads published"
  on "public"."recipe"
  as permissive
  for select
  to public
using ((is_published = true));



  create policy "creators_read_own_calls"
  on "public"."recipe_cleaner_call"
  as permissive
  for select
  to public
using ((auth.uid() IN ( SELECT creator.user_id
   FROM public.creator
  WHERE (creator.id = recipe_cleaner_call.creator_id))));



  create policy "owner manages"
  on "public"."recipe_comment"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "public reads"
  on "public"."recipe_comment"
  as permissive
  for select
  to public
using (true);



  create policy "creator_insert_own_recipe_development"
  on "public"."recipe_development"
  as permissive
  for insert
  to public
with check ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((c.id = r.creator_id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "creator_read_own_recipe_development"
  on "public"."recipe_development"
  as permissive
  for select
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((c.id = r.creator_id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "creator_update_own_recipe_development"
  on "public"."recipe_development"
  as permissive
  for update
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((c.id = r.creator_id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "public reads"
  on "public"."recipe_image"
  as permissive
  for select
  to public
using (true);



  create policy "recipe owner manages images"
  on "public"."recipe_image"
  as permissive
  for all
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))))
with check ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "authenticated insert impression"
  on "public"."recipe_impression"
  as permissive
  for insert
  to public
with check (((auth.uid() = user_id) OR (user_id IS NULL)));



  create policy "creator reads own impressions"
  on "public"."recipe_impression"
  as permissive
  for select
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "creator manages own ingredients"
  on "public"."recipe_ingredient"
  as permissive
  for all
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "public reads"
  on "public"."recipe_ingredient"
  as permissive
  for select
  to public
using (true);



  create policy "owner manages"
  on "public"."recipe_like"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "public count reads"
  on "public"."recipe_like"
  as permissive
  for select
  to public
using (true);



  create policy "creator manages"
  on "public"."recipe_macro"
  as permissive
  for all
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "public reads"
  on "public"."recipe_macro"
  as permissive
  for select
  to public
using (true);



  create policy "authenticated insert open"
  on "public"."recipe_open"
  as permissive
  for insert
  to public
with check (((auth.uid() = user_id) OR (user_id IS NULL)));



  create policy "creator reads own opens"
  on "public"."recipe_open"
  as permissive
  for select
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "owner update open"
  on "public"."recipe_open"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "owner only"
  on "public"."recipe_save"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "creator manages own steps"
  on "public"."recipe_step"
  as permissive
  for all
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "public reads published steps"
  on "public"."recipe_step"
  as permissive
  for select
  to public
using ((recipe_id IN ( SELECT recipe.id
   FROM public.recipe
  WHERE (recipe.is_published = true))));



  create policy "public reads"
  on "public"."recipe_tag"
  as permissive
  for select
  to public
using (true);



  create policy "recipe owner manages tags"
  on "public"."recipe_tag"
  as permissive
  for all
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))))
with check ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "creator manages own"
  on "public"."recipe_translation"
  as permissive
  for all
  to public
using ((recipe_id IN ( SELECT r.id
   FROM (public.recipe r
     JOIN public.creator c ON ((r.creator_id = c.id)))
  WHERE (c.user_id = auth.uid()))));



  create policy "public reads"
  on "public"."recipe_translation"
  as permissive
  for select
  to public
using (true);



  create policy "public reads"
  on "public"."recipe_vector"
  as permissive
  for select
  to public
using (true);



  create policy "Users read own recipe_weight_impact"
  on "public"."recipe_weight_impact"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "owner reads own"
  on "public"."referral"
  as permissive
  for all
  to public
using ((auth.uid() = referrer_id));



  create policy "users can create their own reports"
  on "public"."report"
  as permissive
  for insert
  to public
with check ((reporter_id = auth.uid()));



  create policy "users can view their own reports"
  on "public"."report"
  as permissive
  for select
  to public
using ((reporter_id = auth.uid()));



  create policy "owner only"
  on "public"."shopping_list"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner via shopping_list"
  on "public"."shopping_list_item"
  as permissive
  for select
  to public
using ((shopping_list_id IN ( SELECT shopping_list.id
   FROM public.shopping_list
  WHERE (shopping_list.user_id = auth.uid()))));



  create policy "public reads"
  on "public"."specialty"
  as permissive
  for select
  to public
using (true);



  create policy "owner only"
  on "public"."subscription"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner reads own"
  on "public"."support_message"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "public reads"
  on "public"."tag"
  as permissive
  for select
  to public
using (true);



  create policy "authenticated reads unit_rounding_config"
  on "public"."unit_rounding_config"
  as permissive
  for select
  to public
using ((auth.role() = ANY (ARRAY['authenticated'::text, 'anon'::text])));



  create policy "owner only"
  on "public"."user_cuisine_preference"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner only"
  on "public"."user_dietary_restriction"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner only"
  on "public"."user_goal"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner only"
  on "public"."user_health_profile"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner only"
  on "public"."user_vector"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));



  create policy "owner only"
  on "public"."weight_log"
  as permissive
  for all
  to public
using ((auth.uid() = user_id));


CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.ai_conversation FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_blog_comment_count AFTER INSERT OR DELETE ON public.blog_comment FOR EACH ROW EXECUTE FUNCTION public.update_blog_comment_count();

CREATE TRIGGER trg_blog_comment_updated_at BEFORE UPDATE ON public.blog_comment FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_blog_post_published_newsletter AFTER UPDATE ON public.blog_post FOR EACH ROW EXECUTE FUNCTION public.notify_creator_newsletter();

CREATE TRIGGER trg_blog_post_updated_at BEFORE UPDATE ON public.blog_post FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_blog_like_count AFTER INSERT OR DELETE ON public.blog_post_like FOR EACH ROW EXECUTE FUNCTION public.update_blog_like_count();

CREATE TRIGGER trg_blog_post_translation_updated_at BEFORE UPDATE ON public.blog_post_translation FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.community_group FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.conversation FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_creator_support_conversation AFTER INSERT ON public.creator FOR EACH ROW EXECUTE FUNCTION public.create_creator_support_conversation();

CREATE TRIGGER trg_sync_creator_to_v0 AFTER INSERT OR UPDATE ON public.creator FOR EACH ROW EXECUTE FUNCTION public.trigger_sync_creator_to_v0();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.creator FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.creator_balance FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_creator_payout_identity_updated_at BEFORE UPDATE ON public.creator_payout_identity FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_ingredient_refresh_recipes AFTER UPDATE ON public.ingredient FOR EACH ROW EXECUTE FUNCTION public.trg_fn_ingredient_refresh_recipes();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.meal_plan FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_meal_entry_portions_used AFTER UPDATE OF is_consumed ON public.meal_plan_entry FOR EACH ROW EXECUTE FUNCTION public.trg_fn_meal_entry_portions_used();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.push_token FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER on_recipe_published_newsletter AFTER UPDATE ON public.recipe FOR EACH ROW EXECUTE FUNCTION public.notify_creator_newsletter();

CREATE TRIGGER translate_recipe AFTER INSERT OR UPDATE ON public.recipe FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://njzqcftjzskwcpforwzf.supabase.co/functions/v1/translate-recipe', 'POST', '{"Content-type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qenFjZnRqenNrd2NwZm9yd3pmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjQ4NDMzNywiZXhwIjoyMDg4MDYwMzM3fQ.zUzuJ9yE0OiICESauNb7p_4nSTGlbFykeROoYpsIdD4"}', '{}', '5000');

CREATE TRIGGER trg_recipe_create_macro AFTER INSERT ON public.recipe FOR EACH ROW EXECUTE FUNCTION public.trg_fn_recipe_create_macro();

CREATE TRIGGER trg_recipe_slug BEFORE INSERT OR UPDATE ON public.recipe FOR EACH ROW EXECUTE FUNCTION public.generate_recipe_slug();

CREATE TRIGGER trg_sync_recipe_to_v0 AFTER INSERT OR DELETE OR UPDATE ON public.recipe FOR EACH ROW EXECUTE FUNCTION public.trigger_sync_recipe_to_v0();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.recipe FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.recipe_comment FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_recipe_development_version BEFORE INSERT ON public.recipe_development FOR EACH ROW EXECUTE FUNCTION public.set_recipe_development_version();

CREATE TRIGGER trg_recipe_ingredient_per_100g AFTER INSERT OR DELETE OR UPDATE ON public.recipe_ingredient FOR EACH ROW EXECUTE FUNCTION public.trg_fn_recipe_ingredient_per_100g();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.recipe_macro FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.recipe_vector FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.shopping_list FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.subscription FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.user_cuisine_preference FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.user_health_profile FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.user_profile FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_updated_at BEFORE UPDATE ON public.user_vector FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_visitor_check_email BEFORE INSERT ON public.visitor FOR EACH ROW EXECUTE FUNCTION public.check_visitor_email_not_akeli();

CREATE TRIGGER trg_visitor_updated_at BEFORE UPDATE ON public.visitor FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_visitor_fan_sub_updated_at BEFORE UPDATE ON public.visitor_fan_subscription FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_fan_count AFTER INSERT OR UPDATE ON public.fan_subscription FOR EACH ROW EXECUTE FUNCTION public.update_creator_fan_count();


