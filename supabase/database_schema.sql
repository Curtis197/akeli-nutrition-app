-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.ai_conversation (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ai_conversation_pkey PRIMARY KEY (id),
  CONSTRAINT ai_conversation_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.ai_message (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid,
  role text NOT NULL CHECK (role = ANY (ARRAY['user'::text, 'assistant'::text])),
  content text NOT NULL,
  tokens_used integer,
  sent_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ai_message_pkey PRIMARY KEY (id),
  CONSTRAINT ai_message_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.ai_conversation(id)
);
CREATE TABLE public.chat_message (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid,
  group_id uuid,
  sender_id uuid,
  content text NOT NULL,
  message_type text DEFAULT 'text'::text CHECK (message_type = ANY (ARRAY['text'::text, 'image'::text, 'recipe_share'::text])),
  recipe_id uuid,
  sent_at timestamp with time zone DEFAULT now(),
  CONSTRAINT chat_message_pkey PRIMARY KEY (id),
  CONSTRAINT chat_message_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversation(id),
  CONSTRAINT chat_message_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.user_profile(id),
  CONSTRAINT chat_message_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.community_group (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  cover_url text,
  creator_id uuid,
  is_public boolean DEFAULT true,
  member_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT community_group_pkey PRIMARY KEY (id),
  CONSTRAINT community_group_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.conversation (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  type text DEFAULT 'private'::text CHECK (type = ANY (ARRAY['private'::text, 'creator_group'::text, 'support'::text])),
  name text,
  created_by uuid,
  is_support_open boolean DEFAULT false,
  community_group_id uuid,
  CONSTRAINT conversation_pkey PRIMARY KEY (id),
  CONSTRAINT conversation_community_group_id_fkey FOREIGN KEY (community_group_id) REFERENCES public.community_group(id),
  CONSTRAINT conversation_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.user_profile(id)
);
CREATE TABLE public.conversation_participant (
  conversation_id uuid NOT NULL,
  user_id uuid NOT NULL,
  joined_at timestamp with time zone DEFAULT now(),
  last_read_at timestamp with time zone,
  CONSTRAINT conversation_participant_pkey PRIMARY KEY (conversation_id, user_id),
  CONSTRAINT conversation_participant_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversation(id),
  CONSTRAINT conversation_participant_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.conversation_request (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  requester_id uuid,
  recipient_id uuid,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text])),
  message text,
  created_at timestamp with time zone DEFAULT now(),
  responded_at timestamp with time zone,
  CONSTRAINT conversation_request_pkey PRIMARY KEY (id),
  CONSTRAINT conversation_request_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.user_profile(id),
  CONSTRAINT conversation_request_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.creator (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE,
  display_name text NOT NULL,
  bio text,
  profile_image_url text,
  specialties ARRAY,
  recipe_count integer DEFAULT 0,
  fan_count integer DEFAULT 0,
  total_revenue numeric DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  username text UNIQUE CHECK (username ~ '^[a-z0-9_-]{3,30}$'::text),
  instagram_handle text,
  tiktok_handle text,
  youtube_handle text,
  website_url text,
  specialty_codes ARRAY,
  language_codes ARRAY,
  heritage_region text,
  CONSTRAINT creator_pkey PRIMARY KEY (id),
  CONSTRAINT creator_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.creator_balance (
  creator_id uuid NOT NULL,
  available_balance numeric DEFAULT 0,
  pending_balance numeric DEFAULT 0,
  lifetime_earnings numeric DEFAULT 0,
  last_payout_at timestamp with time zone,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT creator_balance_pkey PRIMARY KEY (creator_id),
  CONSTRAINT creator_balance_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.creator(id)
);
CREATE TABLE public.creator_revenue_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  creator_id uuid,
  recipe_id uuid,
  revenue_type text NOT NULL CHECK (revenue_type = ANY (ARRAY['consumption'::text, 'fan_mode'::text])),
  amount numeric NOT NULL,
  logged_at date DEFAULT CURRENT_DATE,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT creator_revenue_log_pkey PRIMARY KEY (id),
  CONSTRAINT creator_revenue_log_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.creator(id),
  CONSTRAINT creator_revenue_log_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.daily_nutrition_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  date date NOT NULL,
  total_calories numeric,
  total_protein_g numeric,
  total_carbs_g numeric,
  total_fat_g numeric,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT daily_nutrition_log_pkey PRIMARY KEY (id),
  CONSTRAINT daily_nutrition_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.fan_external_recipe_counter (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  subscription_id uuid,
  external_recipe_url text NOT NULL,
  consumption_count integer DEFAULT 0,
  last_consumed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fan_external_recipe_counter_pkey PRIMARY KEY (id),
  CONSTRAINT fan_external_recipe_counter_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.fan_subscription(id)
);
CREATE TABLE public.fan_subscription (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  creator_id uuid,
  status text DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'cancelled'::text])),
  subscribed_at timestamp with time zone DEFAULT now(),
  cancelled_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fan_subscription_pkey PRIMARY KEY (id),
  CONSTRAINT fan_subscription_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id),
  CONSTRAINT fan_subscription_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.creator(id)
);
CREATE TABLE public.fan_subscription_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  subscription_id uuid,
  status text NOT NULL,
  changed_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fan_subscription_history_pkey PRIMARY KEY (id),
  CONSTRAINT fan_subscription_history_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.fan_subscription(id)
);
CREATE TABLE public.food_region (
  code text NOT NULL,
  name_fr text NOT NULL,
  name_en text NOT NULL,
  name_es text,
  name_pt text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT food_region_pkey PRIMARY KEY (code)
);
CREATE TABLE public.group_member (
  group_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role text DEFAULT 'member'::text CHECK (role = ANY (ARRAY['admin'::text, 'member'::text])),
  joined_at timestamp with time zone DEFAULT now(),
  last_read_at timestamp with time zone,
  CONSTRAINT group_member_pkey PRIMARY KEY (group_id, user_id),
  CONSTRAINT group_member_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.community_group(id),
  CONSTRAINT group_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.ingredient (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_fr text,
  name_en text,
  name_es text,
  name_pt text,
  category text,
  calories_per_100g numeric,
  protein_per_100g numeric,
  carbs_per_100g numeric,
  fat_per_100g numeric,
  created_at timestamp with time zone DEFAULT now(),
  status text DEFAULT 'validated'::text CHECK (status = ANY (ARRAY['pending'::text, 'validated'::text])),
  CONSTRAINT ingredient_pkey PRIMARY KEY (id),
  CONSTRAINT ingredient_category_fkey FOREIGN KEY (category) REFERENCES public.ingredient_category(code)
);
CREATE TABLE public.ingredient_category (
  code text NOT NULL,
  name_fr text NOT NULL,
  name_en text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ingredient_category_pkey PRIMARY KEY (code)
);
CREATE TABLE public.ingredient_submission (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  submitted_by uuid,
  name text NOT NULL,
  name_fr text,
  name_en text,
  category_hint text,
  notes text,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'validated'::text, 'rejected'::text, 'duplicate'::text])),
  ingredient_id uuid,
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ingredient_submission_pkey PRIMARY KEY (id),
  CONSTRAINT ingredient_submission_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public.user_profile(id),
  CONSTRAINT ingredient_submission_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id)
);
CREATE TABLE public.meal_consumption (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  recipe_id uuid,
  meal_plan_entry_id uuid,
  consumed_at timestamp with time zone DEFAULT now(),
  servings integer DEFAULT 1,
  rating integer CHECK (rating >= 1 AND rating <= 5),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT meal_consumption_pkey PRIMARY KEY (id),
  CONSTRAINT meal_consumption_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id),
  CONSTRAINT meal_consumption_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id),
  CONSTRAINT meal_consumption_meal_plan_entry_id_fkey FOREIGN KEY (meal_plan_entry_id) REFERENCES public.meal_plan_entry(id)
);
CREATE TABLE public.meal_plan (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  name text,
  start_date date NOT NULL,
  end_date date NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT meal_plan_pkey PRIMARY KEY (id),
  CONSTRAINT meal_plan_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.meal_plan_entry (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  meal_plan_id uuid,
  recipe_id uuid,
  date date NOT NULL,
  meal_type text CHECK (meal_type = ANY (ARRAY['breakfast'::text, 'lunch'::text, 'dinner'::text, 'snack'::text])),
  servings integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT meal_plan_entry_pkey PRIMARY KEY (id),
  CONSTRAINT meal_plan_entry_meal_plan_id_fkey FOREIGN KEY (meal_plan_id) REFERENCES public.meal_plan(id),
  CONSTRAINT meal_plan_entry_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.meal_reminder (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  meal_type text CHECK (meal_type = ANY (ARRAY['breakfast'::text, 'lunch'::text, 'dinner'::text, 'snack'::text])),
  reminder_time time without time zone NOT NULL,
  is_enabled boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT meal_reminder_pkey PRIMARY KEY (id),
  CONSTRAINT meal_reminder_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.measurement_unit (
  code text NOT NULL,
  name_fr text NOT NULL,
  name_en text NOT NULL,
  name_es text,
  name_pt text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT measurement_unit_pkey PRIMARY KEY (code)
);
CREATE TABLE public.notification (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notification_pkey PRIMARY KEY (id),
  CONSTRAINT notification_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.payout (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  creator_id uuid,
  amount numeric NOT NULL,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'processing'::text, 'completed'::text, 'failed'::text])),
  stripe_payout_id text,
  requested_at timestamp with time zone DEFAULT now(),
  completed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT payout_pkey PRIMARY KEY (id),
  CONSTRAINT payout_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.creator(id)
);
CREATE TABLE public.push_token (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  token text NOT NULL UNIQUE,
  platform text CHECK (platform = ANY (ARRAY['ios'::text, 'android'::text])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT push_token_pkey PRIMARY KEY (id),
  CONSTRAINT push_token_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.recipe (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  creator_id uuid,
  title text NOT NULL,
  description text,
  region text,
  difficulty text CHECK (difficulty = ANY (ARRAY['easy'::text, 'medium'::text, 'hard'::text])),
  prep_time_min integer,
  cook_time_min integer,
  servings integer DEFAULT 1,
  is_published boolean DEFAULT false,
  language text DEFAULT 'fr'::text,
  cover_image_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  slug text UNIQUE,
  draft_data jsonb,
  is_pork_free boolean DEFAULT false,
  CONSTRAINT recipe_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.creator(id),
  CONSTRAINT recipe_region_fkey FOREIGN KEY (region) REFERENCES public.food_region(code)
);
CREATE TABLE public.recipe_comment (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid,
  user_id uuid,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_comment_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_comment_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id),
  CONSTRAINT recipe_comment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.recipe_image (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid,
  url text NOT NULL,
  sort_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_image_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_image_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.recipe_impression (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid NOT NULL,
  user_id uuid,
  source text NOT NULL CHECK (source = ANY (ARRAY['feed'::text, 'search'::text, 'meal_planner'::text])),
  seen_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_impression_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_impression_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id),
  CONSTRAINT recipe_impression_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.recipe_ingredient (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid,
  ingredient_id uuid,
  quantity numeric NOT NULL,
  unit text,
  is_optional boolean DEFAULT false,
  sort_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_ingredient_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_ingredient_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id),
  CONSTRAINT recipe_ingredient_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id),
  CONSTRAINT recipe_ingredient_unit_fkey FOREIGN KEY (unit) REFERENCES public.measurement_unit(code)
);
CREATE TABLE public.recipe_like (
  user_id uuid NOT NULL,
  recipe_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_like_pkey PRIMARY KEY (user_id, recipe_id),
  CONSTRAINT recipe_like_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id),
  CONSTRAINT recipe_like_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.recipe_macro (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid UNIQUE,
  calories numeric,
  protein_g numeric,
  carbs_g numeric,
  fat_g numeric,
  fiber_g numeric,
  sodium_mg numeric,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_macro_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_macro_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.recipe_open (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid NOT NULL,
  user_id uuid,
  source text NOT NULL CHECK (source = ANY (ARRAY['feed'::text, 'search'::text, 'meal_planner'::text])),
  opened_at timestamp with time zone DEFAULT now(),
  closed_at timestamp with time zone,
  session_duration_seconds integer,
  CONSTRAINT recipe_open_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_open_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id),
  CONSTRAINT recipe_open_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.recipe_save (
  user_id uuid NOT NULL,
  recipe_id uuid NOT NULL,
  saved_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_save_pkey PRIMARY KEY (user_id, recipe_id),
  CONSTRAINT recipe_save_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id),
  CONSTRAINT recipe_save_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.recipe_step (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid NOT NULL,
  step_number integer NOT NULL,
  title text,
  content text NOT NULL,
  image_url text,
  timer_seconds integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_step_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_step_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.recipe_tag (
  recipe_id uuid NOT NULL,
  tag_id uuid NOT NULL,
  CONSTRAINT recipe_tag_pkey PRIMARY KEY (recipe_id, tag_id),
  CONSTRAINT recipe_tag_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id),
  CONSTRAINT recipe_tag_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tag(id)
);
CREATE TABLE public.recipe_translation (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipe_id uuid,
  locale text NOT NULL CHECK (locale = ANY (ARRAY['fr'::text, 'en'::text, 'es'::text, 'pt'::text, 'wo'::text, 'bm'::text, 'ln'::text, 'ar'::text])),
  title text NOT NULL,
  description text,
  instructions text NOT NULL,
  is_auto boolean DEFAULT true,
  generated_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_translation_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_translation_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.recipe_vector (
  recipe_id uuid NOT NULL,
  vector USER-DEFINED NOT NULL,
  last_computed timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT recipe_vector_pkey PRIMARY KEY (recipe_id),
  CONSTRAINT recipe_vector_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(id)
);
CREATE TABLE public.referral (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  referrer_id uuid,
  referred_id uuid UNIQUE,
  referral_code text NOT NULL,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'converted'::text])),
  converted_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT referral_pkey PRIMARY KEY (id),
  CONSTRAINT referral_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES public.user_profile(id),
  CONSTRAINT referral_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.shopping_list (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  meal_plan_id uuid,
  name text,
  is_completed boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT shopping_list_pkey PRIMARY KEY (id),
  CONSTRAINT shopping_list_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id),
  CONSTRAINT shopping_list_meal_plan_id_fkey FOREIGN KEY (meal_plan_id) REFERENCES public.meal_plan(id)
);
CREATE TABLE public.shopping_list_item (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  shopping_list_id uuid,
  ingredient_id uuid,
  custom_name text,
  quantity numeric NOT NULL,
  unit text,
  is_checked boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT shopping_list_item_pkey PRIMARY KEY (id),
  CONSTRAINT shopping_list_item_shopping_list_id_fkey FOREIGN KEY (shopping_list_id) REFERENCES public.shopping_list(id),
  CONSTRAINT shopping_list_item_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(id),
  CONSTRAINT shopping_list_item_unit_fkey FOREIGN KEY (unit) REFERENCES public.measurement_unit(code)
);
CREATE TABLE public.specialty (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name_fr text NOT NULL,
  name_en text NOT NULL,
  name_es text,
  name_pt text,
  region text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT specialty_pkey PRIMARY KEY (id),
  CONSTRAINT specialty_region_fkey FOREIGN KEY (region) REFERENCES public.food_region(code)
);
CREATE TABLE public.subscription (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE,
  stripe_customer_id text UNIQUE,
  stripe_subscription_id text UNIQUE,
  status text DEFAULT 'trialing'::text CHECK (status = ANY (ARRAY['active'::text, 'cancelled'::text, 'past_due'::text, 'trialing'::text])),
  current_period_start timestamp with time zone,
  current_period_end timestamp with time zone,
  cancel_at_period_end boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subscription_pkey PRIMARY KEY (id),
  CONSTRAINT subscription_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.support_message (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  email text NOT NULL,
  subject text,
  content text NOT NULL,
  status text DEFAULT 'open'::text CHECK (status = ANY (ARRAY['open'::text, 'in_progress'::text, 'resolved'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT support_message_pkey PRIMARY KEY (id),
  CONSTRAINT support_message_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.tag (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  name_fr text,
  name_en text,
  name_es text,
  name_pt text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tag_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_cuisine_preference (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  region text,
  preference_score numeric DEFAULT 1.0 CHECK (preference_score >= 0::numeric AND preference_score <= 1::numeric),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_cuisine_preference_pkey PRIMARY KEY (id),
  CONSTRAINT user_cuisine_preference_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id),
  CONSTRAINT user_cuisine_preference_region_fkey FOREIGN KEY (region) REFERENCES public.food_region(code)
);
CREATE TABLE public.user_dietary_restriction (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  restriction text CHECK (restriction = ANY (ARRAY['vegetarian'::text, 'vegan'::text, 'pescatarian'::text, 'halal'::text, 'kosher'::text, 'gluten_free'::text, 'lactose_free'::text, 'nut_free'::text, 'low_sodium'::text, 'diabetic_friendly'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_dietary_restriction_pkey PRIMARY KEY (id),
  CONSTRAINT user_dietary_restriction_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.user_goal (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  goal_type text CHECK (goal_type = ANY (ARRAY['weight_loss'::text, 'muscle_gain'::text, 'maintenance'::text, 'health'::text, 'performance'::text])),
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_goal_pkey PRIMARY KEY (id),
  CONSTRAINT user_goal_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.user_health_profile (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE,
  sex text CHECK (sex = ANY (ARRAY['male'::text, 'female'::text, 'other'::text])),
  birth_date date,
  height_cm numeric,
  weight_kg numeric,
  target_weight_kg numeric,
  activity_level text CHECK (activity_level = ANY (ARRAY['sedentary'::text, 'light'::text, 'moderate'::text, 'active'::text, 'very_active'::text])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_health_profile_pkey PRIMARY KEY (id),
  CONSTRAINT user_health_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.user_profile (
  id uuid NOT NULL,
  username text UNIQUE,
  first_name text,
  last_name text,
  avatar_url text,
  locale text DEFAULT 'fr'::text,
  is_creator boolean DEFAULT false,
  onboarding_done boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_profile_pkey PRIMARY KEY (id),
  CONSTRAINT user_profile_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.user_vector (
  user_id uuid NOT NULL,
  vector USER-DEFINED NOT NULL,
  last_computed timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_vector_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_vector_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);
CREATE TABLE public.weight_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  weight_kg numeric NOT NULL,
  logged_at date DEFAULT CURRENT_DATE,
  note text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT weight_log_pkey PRIMARY KEY (id),
  CONSTRAINT weight_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(id)
);