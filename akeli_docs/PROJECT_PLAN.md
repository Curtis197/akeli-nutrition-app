# AKELI - Project Plan & Master Index

> **Complete map of the Akeli Nutrition App project.**
> Every component, table, function, page, and feature is indexed here with its role, purpose, and relationships.
>
> **Last updated**: 2026-04-13  
> **Version**: 1.0.0  
> **Maintainer**: Akeli Dev Team

---

## 📖 How to Read This Document

Each entry follows this format:

```
[Component Name]
├── Role: What it does in the system
├── Purpose: Why it exists, the problem it solves
├── Usage: How it's used, who calls it
├── Location: Where to find the code
├── Dependencies: What it relies on
└── Notes: Important caveats, performance considerations, bugs
```

---

## 🗂️ TABLE OF CONTENTS

### 1. [Project Overview](#1-project-overview)
### 2. [Architecture](#2-architecture)
### 3. [Database Tables](#3-database-tables)
### 4. [SQL Functions (RPC)](#4-sql-functions-rpc)
### 5. [Edge Functions](#5-edge-functions)
### 6. [Flutter App Structure](#6-flutter-app-structure)
### 7. [Features](#7-features)
### 8. [External Services](#8-external-services)
### 9. [Performance & Caching](#9-performance--caching)
### 10. [Security & RLS](#10-security--rls)
### 11. [Monitoring & Logging](#11-monitoring--logging)
### 12. [Development & Deployment](#12-development--deployment)

---

## 1. PROJECT OVERVIEW

### Akeli Nutrition App
- **Role**: African cuisine nutrition and meal planning platform
- **Purpose**: Connect users with authentic African recipes, personalized meal plans, and creator-driven nutrition guidance
- **Target Users**: Health-conscious individuals interested in African cuisine, meal planners, nutrition seekers
- **Business Model**: 
  - User subscription: 3€/month (Google Play / App Store)
  - Creator monetization: Fan mode (1€/fan/month) + Consumption (90 meals = 1€)
- **Platforms**: Android, iOS, Web, Windows (Flutter)

### Key Differentiators
1. **African cuisine focus** - West African, Central African, Caribbean, etc.
2. **Vector-based recommendations** - pgvector cosine similarity for personalized feeds
3. **Creator economy** - Fan mode, revenue sharing, dashboards
4. **AI assistant** - Nutrition guidance via GPT-4o-mini
5. **Multi-lingual** - French, English, Spanish, Portuguese, Wolof, Bambara, Lingala, Arabic

---

## 2. ARCHITECTURE

### Client-Side (Flutter)
- **Role**: User interface, local state management, simple data fetching
- **Purpose**: Deliver smooth, responsive UX
- **Tech Stack**: Flutter, Riverpod (state), GoRouter (routing), logger (logging)
- **Responsibilities**:
  - Display data from backend
  - Handle user input (forms, taps, gestures)
  - Manage local UI state (loading, error, selection)
  - Simple single-table fetches
  - Local caching of static reference data
- **Does NOT do**: Complex joins, aggregations, pagination logic, external API calls

### Backend (Supabase)
- **Role**: All complex data operations, business logic, external integrations
- **Purpose**: Handle computation-heavy tasks, secure data, external APIs
- **Tech Stack**: PostgreSQL, pgvector, Deno Edge Functions, SQL RPC functions
- **Responsibilities**:
  - JOINs across multiple tables
  - Aggregations (COUNT, SUM, AVG, GROUP BY)
  - Pagination (LIMIT/OFFSET or cursor-based)
  - Full-text search and vector similarity
  - External API calls (Stripe, OpenAI, FCM, Google Play, App Store)
  - Business logic (revenue computation, Fan mode limits, rate limiting)
  - Caching expensive computations
- **Client never calls these directly** - all complex ops go through RPC or Edge Functions

### External Services
- **Python Service (Railway)**: Vector computation for user profiles
- **OpenAI (GPT-4o-mini)**: AI nutrition assistant
- **Gemini 1.5 flash**: African language translation
- **Firebase Cloud Messaging**: Push notifications
- **Google Play / App Store**: User subscription billing
- **Stripe Connect**: Creator payouts

---

## 3. DATABASE TABLES

### Identity & Auth

#### `user_profile`
- **Role**: Core user identity, extends Supabase auth.users
- **Purpose**: Store user preferences, role, locale, creator status
- **Key columns**: `id` (FK to auth.users), `username`, `locale`, `is_creator`, `onboarding_done`, `role`
- **Used by**: ALL features - every user action references this
- **RLS**: Owner reads/updates own; public reads minimal (username, avatar)
- **Triggers**: Auto-created on auth.users insert via `handle_new_user()`
- **Notes**: `role` is 'user' or 'admin' only

#### `user_health_profile`
- **Role**: User's physical health data
- **Purpose**: Calculate calorie needs, personalize meal plans
- **Key columns**: `user_id`, `sex`, `birth_date`, `height_cm`, `weight_kg`, `target_weight_kg`, `activity_level`
- **Used by**: `complete-onboarding` EF, meal plan generation, AI assistant
- **RLS**: Owner only (all operations)
- **Notes**: Sensitive health data - never log actual values

#### `user_goal`
- **Role**: User's nutrition goal
- **Purpose**: Guide meal plan generation and recipe recommendations
- **Key columns**: `user_id`, `goal_type` (weight_loss, muscle_gain, maintenance, health, performance), `is_active`
- **Used by**: AI assistant context, meal plan generation, recommendations
- **RLS**: Owner only

#### `user_dietary_restriction`
- **Role**: User's dietary constraints
- **Purpose**: Filter recipes and meal plans to match restrictions
- **Key columns**: `user_id`, `restriction` (vegetarian, vegan, halal, gluten_free, etc.)
- **Used by**: Recommendations, meal plan generation, AI assistant
- **RLS**: Owner only

#### `user_cuisine_preference`
- **Role**: User's preferred culinary regions
- **Purpose**: Weight recipe recommendations by cultural preference
- **Key columns**: `user_id`, `region` (FK to food_region), `preference_score` (0-1)
- **Used by**: `recommend_recipes` RPC (vector similarity weighting)
- **RLS**: Owner only

#### `weight_log`
- **Role**: User's weight tracking history
- **Purpose**: Track progress toward target weight
- **Key columns**: `user_id`, `weight_kg`, `logged_at`, `note`
- **Used by**: Profile page, progress charts
- **RLS**: Owner only

#### `user_vector`
- **Role**: 50-dimension embedding representing user's taste profile
- **Purpose**: Enable cosine similarity for recipe recommendations
- **Key columns**: `user_id`, `vector` (vector(50)), `last_computed`
- **Used by**: `recommend_recipes` RPC, `generate_meal_plan` RPC
- **Index**: HNSW (m=16, ef_construction=64) for ~3ms cosine similarity
- **Computed by**: Python service on Railway (triggered at onboarding, recalculated nightly)
- **RLS**: Owner only
- **Performance**: Critical for feed performance - never compute on client

---

### Creator

#### `creator`
- **Role**: Creator profile - public face of recipe authors
- **Purpose**: Display creator info, track stats, manage Fan mode eligibility
- **Key columns**: `id`, `user_id`, `display_name`, `bio`, `avatar_url`, `cover_url`, `specialties[]`, `languages[]`, `is_verified`, `recipe_count`, `fan_count`, `is_fan_eligible` (generated: recipe_count >= 30)
- **Used by**: Creator profile page, search, recommendations, Fan mode
- **RLS**: Public reads; owner manages; service updates (stripe_charges_enabled via webhook)
- **Triggers**: `update_creator_recipe_count()` on recipe changes; `update_creator_fan_count()` on fan sub changes
- **Notes**: `is_fan_eligible` is generated column - auto-updates when recipe_count changes

#### `creator_balance`
- **Role**: Creator's current earnings
- **Purpose**: Track available balance, lifetime earnings, payouts
- **Key columns**: `creator_id`, `balance` (available), `total_earned`, `total_paid_out`, `last_updated`
- **Used by**: Creator dashboard, payout processing
- **RLS**: Creator reads own (via creator.user_id)
- **Notes**: Updated by `compute-monthly-revenue` cron

#### `creator_revenue_log`
- **Role**: Monthly revenue history per creator
- **Purpose**: Immutable record of earnings computation
- **Key columns**: `creator_id`, `month_key` (YYYY-MM), `fan_revenue`, `consumption_revenue`, `total_revenue` (generated), `fan_count`, `consumption_count`, `computed_at`
- **Used by**: Creator dashboard, monthly statements
- **RLS**: Creator reads own
- **Notes**: Upserted by `compute-monthly-revenue` cron - never manually modified

#### `creator_payout`
- **Role**: Payout transaction history (Stripe)
- **Purpose**: Track Stripe payouts to creators
- **Key columns**: `creator_id`, `stripe_payment_intent_id`, `amount_cents`, `currency`, `status` (succeeded/failed), `paid_at`
- **Used by**: `stripe-webhook` EF, creator dashboard payout history
- **RLS**: Creator reads own; service_role inserts (webhook)
- **Notes**: Separate from legacy `payout` table

---

### Recipes

#### `recipe`
- **Role**: Core recipe entity
- **Purpose**: Store recipe metadata for display, search, recommendations
- **Key columns**: `id`, `creator_id`, `title`, `description`, `region`, `difficulty`, `prep_time_min`, `cook_time_min`, `servings`, `is_published`, `language`, `cover_image_url`
- **Used by**: Feed, search, detail page, meal plans, AI assistant
- **RLS**: Public reads published only; creator manages own (via creator.user_id)
- **Triggers**: `update_creator_recipe_count()` on publish/unpublish
- **Notes**: `instructions` column DROPPED (replaced by `recipe_step` table)

#### `recipe_step`
- **Role**: Structured preparation steps for a recipe
- **Purpose**: Replace monolithic instructions with ordered, visual steps
- **Key columns**: `id`, `recipe_id`, `step_number`, `title`, `content`, `image_url`, `timer_seconds`
- **Used by**: Recipe detail page (step-by-step display)
- **RLS**: Public reads published recipe steps; creator manages own
- **Index**: `idx_recipe_step_recipe` ON (recipe_id) for ordered fetch
- **⚠️ KNOWN BUG**: Policies reference `r.status` but recipe has `is_published` boolean; creator check uses `r.creator_id = auth.uid()` but creator_id is creator UUID not user UUID
- **Notes**: Unique constraint on (recipe_id, step_number)

#### `recipe_macro`
- **Role**: Nutrition data per recipe
- **Purpose**: Display calorie/macro info, calculate daily nutrition
- **Key columns**: `recipe_id`, `calories`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g`, `sodium_mg`
- **Used by**: Recipe detail, daily nutrition log, meal plan calorie totals
- **RLS**: Public reads all; creator manages own
- **Notes**: One-to-one with recipe (unique constraint on recipe_id)

#### `ingredient`
- **Role**: Ingredient reference data
- **Purpose**: Standardized ingredient catalog with nutrition per 100g
- **Key columns**: `id`, `name`, `name_fr`, `name_en`, `name_es`, `name_pt`, `category`, `calories_per_100g`, `protein_per_100g`, `carbs_per_100g`, `fat_per_100g`
- **Used by**: Recipe ingredients, shopping list, nutrition calculations
- **RLS**: Public reads all

#### `recipe_ingredient`
- **Role**: Recipe's ingredient list
- **Purpose**: Define what goes in each recipe with quantities
- **Key columns**: `recipe_id`, `ingredient_id`, `quantity`, `unit`, `is_optional`, `sort_order`
- **Used by**: Recipe detail, shopping list generation
- **RLS**: Public reads all
- **Index**: `idx_recipe_ingredient_recipe` for recipe fetch

#### `recipe_tag`
- **Role**: Recipe tagging (many-to-many)
- **Purpose**: Categorize recipes by dietary type, occasion, technique
- **Key columns**: `recipe_id`, `tag_id` (composite PK)
- **Used by**: Search filters, recipe discovery
- **RLS**: Public reads all

#### `recipe_image`
- **Role**: Additional recipe images
- **Purpose**: Gallery display beyond cover image
- **Key columns**: `recipe_id`, `url`, `sort_order`
- **Used by**: Recipe detail image gallery
- **RLS**: Public reads all

#### `recipe_like`
- **Role**: User likes on recipes
- **Purpose**: Track user engagement, influence recommendations
- **Key columns**: `user_id`, `recipe_id` (composite PK), `created_at`
- **Used by**: Feed, search (like count), creator dashboard, AI assistant context
- **RLS**: Owner manages own; public reads for count
- **Notes**: Toggle via `toggle-recipe-like` Edge Function

#### `recipe_save`
- **Role**: User bookmarks (saved recipes)
- **Purpose**: Let users save recipes for later
- **Key columns**: `user_id`, `recipe_id` (composite PK), `saved_at`
- **Used by**: User's saved recipes page
- **RLS**: Owner only (all operations)
- **Added**: Migration 20260314000001

#### `recipe_comment`
- **Role**: User comments on recipes
- **Purpose**: Community engagement on recipes
- **Key columns**: `id`, `recipe_id`, `user_id`, `content`, `created_at`, `updated_at`
- **Used by**: Recipe detail comments section
- **RLS**: Public reads all; owner manages own

#### `recipe_impression`
- **Role**: Track when a recipe card is seen (passive signal)
- **Purpose**: Measure recipe visibility, creator analytics
- **Key columns**: `id`, `recipe_id`, `user_id` (nullable for anonymous), `source` (feed/search/meal_planner), `seen_at`
- **Used by**: Creator dashboard analytics, recommendation optimization
- **RLS**: Auth users insert own; creator reads for own recipes
- **Added**: Migration 20260314000001
- **Notes**: Nullable user_id supports anonymous impressions

#### `recipe_open`
- **Role**: Track when a recipe is opened with session duration (intentional signal)
- **Purpose**: Measure recipe engagement, creator analytics
- **Key columns**: `id`, `recipe_id`, `user_id` (nullable), `source`, `opened_at`, `closed_at`, `session_duration_seconds`
- **Used by**: Creator dashboard analytics, engagement metrics
- **RLS**: Auth users insert own; owner updates own; creator reads for own recipes
- **Added**: Migration 20260314000001
- **Notes**: Two-phase: INSERT on open, UPDATE on close with duration

#### `recipe_vector`
- **Role**: 50-dimension embedding representing recipe's culinary profile
- **Purpose**: Enable cosine similarity for recommendations
- **Key columns**: `recipe_id`, `vector` (vector(50)), `last_computed`
- **Used by**: `recommend_recipes` RPC, `generate_meal_plan` RPC
- **Index**: HNSW (m=16, ef_construction=64) for ~3ms similarity
- **Computed**: At recipe publication, recalculated on modification
- **RLS**: Public reads all

#### `recipe_translation`
- **Role**: Translated recipe content
- **Purpose**: Multi-lingual recipe display (title, description, instructions)
- **Key columns**: `recipe_id`, `locale` (fr/en/es/pt/wo/bm/ln/ar), `title`, `description`, `instructions`
- **Used by**: Recipe detail page (locale-aware display)
- **RLS**: Public reads all
- **Translation**: Via `translate-content` Edge Function (Gemini)

---

### Meal Planning

#### `meal_plan`
- **Role**: User's meal plan container
- **Purpose**: Organize meals over a date range
- **Key columns**: `user_id`, `name`, `start_date`, `end_date`, `is_active`
- **Used by**: Meal planner page, shopping list generation
- **RLS**: Owner only
- **Triggers**: Auto-deactivated when new plan generated via `generate_meal_plan` RPC

#### `meal_plan_entry`
- **Role**: Individual meal slot in a plan
- **Purpose**: Map specific recipes to specific dates and meal types
- **Key columns**: `meal_plan_id`, `recipe_id`, `scheduled_date`, `meal_type` (breakfast/lunch/dinner/snack), `servings`, `is_consumed`, `consumed_at`
- **Used by**: Daily meal view, consumption logging
- **RLS**: Owner only (via meal_plan FK)

#### `meal_consumption`
- **Role**: Record of consumed meal - SOURCE OF TRUTH for creator revenue
- **Purpose**: Track what user ate, when, and attribute revenue to creator
- **Key columns**: `user_id`, `recipe_id`, `creator_id`, `meal_plan_entry_id`, `servings`, `consumed_at`, `month_key` (generated YYYY-MM)
- **Used by**: Creator revenue computation, daily nutrition log, Fan mode enforcement
- **Revenue**: 90 consumptions = 1€ for creator
- **RLS**: Owner reads own; system inserts (user marks as consumed)
- **Triggers**: `update_daily_nutrition_on_consumption()` auto-updates daily_nutrition_log
- **Notes**: `month_key` generated column enables efficient monthly aggregation

#### `shopping_list`
- **Role**: User's shopping list container
- **Purpose**: Aggregate ingredients from meal plan for shopping
- **Key columns**: `user_id`, `meal_plan_id`, `generated_at`
- **Used by**: Shopping list page
- **RLS**: Owner only

#### `shopping_list_item`
- **Role**: Individual ingredient in shopping list
- **Purpose**: Aggregated quantities from all recipes in plan
- **Key columns**: `shopping_list_id`, `ingredient_id`, `quantity`, `unit`, `is_checked`
- **Used by**: Shopping list display
- **RLS**: Owner only (via shopping_list FK)

#### `meal_reminder`
- **Role**: User's meal reminder settings
- **Purpose**: Schedule push notifications for meals
- **Key columns**: `user_id`, `meal_type`, `reminder_time`, `days_of_week[]`, `is_active`
- **Used by**: `send-meal-reminders` cron function
- **RLS**: Owner only

#### `daily_nutrition_log`
- **Role**: Daily nutrition summary
- **Purpose**: Track daily calorie/macro totals against goals
- **Key columns**: `user_id`, `log_date`, `calories`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g`, `meals_count`, UNIQUE(user_id, log_date)
- **Used by**: Nutrition dashboard, daily progress display
- **RLS**: Owner only
- **Triggers**: Auto-updated by `update_daily_nutrition_on_consumption()` on meal_consumption insert

---

### Fan Mode

#### `fan_subscription`
- **Role**: User's Fan subscription to a creator
- **Purpose**: Support creators directly, unlock exclusive content
- **Key columns**: `user_id`, `creator_id`, `status` (pending/active/cancelled), `effective_from`, `effective_until`
- **Used by**: Fan mode activation, recommendations (×1.5 boost), revenue computation
- **Lifecycle**: activate → pending → active on 1st of next month → cancelled on 1st of month after cancellation
- **Constraint**: UNIQUE(user_id, status) - one Fan per user
- **RLS**: Owner reads own; creator reads own fans; owner inserts; owner updates (fix migration)
- **Triggers**: `update_creator_fan_count()` on status changes

#### `fan_subscription_history`
- **Role**: Immutable history of Fan subscriptions
- **Purpose**: Audit trail for activation/cancellation events
- **Key columns**: `user_id`, `creator_id`, `action` (activated/changed/cancelled), `previous_creator_id`, `month_key`, `created_at`
- **Used by**: Support, revenue auditing
- **RLS**: Owner reads own; owner inserts (fix migration)
- **Notes**: Insert-only, never updated

#### `fan_external_recipe_counter`
- **Role**: Track external (non-Fan-creator) recipes consumed per month
- **Purpose**: Enforce max 9 external recipes/month limit in Fan mode
- **Key columns**: `user_id`, `month_key`, `external_recipe_count` (CHECK <= 9), `updated_at`, UNIQUE(user_id, month_key)
- **Used by**: `log-meal-consumption` EF (enforces limit)
- **RLS**: Owner reads own; owner inserts/updates (fix migration)
- **Notes**: Reset monthly by `process-fan-mode-transitions` cron

---

### Community & Chat

#### `community_group`
- **Role**: Community discussion group
- **Purpose**: Group-based conversations around topics
- **Key columns**: `id`, `name`, `description`, `cover_url`, `creator_id`, `is_public`, `member_count` (denormalized)
- **Used by**: Groups page, group chat
- **RLS**: Public reads public groups; members read private groups
- **Triggers**: `update_group_member_count()` on membership changes

#### `group_member`
- **Role**: Group membership
- **Purpose**: Track who's in which group, roles
- **Key columns**: `group_id`, `user_id`, `role` (admin/member), `joined_at`, `last_read_at` (composite PK)
- **Used by**: Group access control, member lists
- **RLS**: Member reads own membership

#### `conversation`
- **Role**: Private conversation container
- **Purpose**: 1:1 messaging between users
- **Key columns**: `id`, `created_at`
- **Used by**: Chat page, messaging
- **RLS**: No direct policies (access via conversation_participant)
- **Notes**: Minimal table - access controlled by participant membership

#### `conversation_participant`
- **Role**: Conversation membership
- **Purpose**: Define who can see each conversation
- **Key columns**: `conversation_id`, `user_id`, `joined_at`, `last_read_at` (composite PK)
- **Used by**: Chat access control, unread counts
- **RLS**: Participant only (all operations)

#### `chat_message`
- **Role**: Individual chat messages
- **Purpose**: Text, image, recipe-share messages in conversations/groups
- **Key columns**: `conversation_id` OR `group_id` (check constraint), `sender_id`, `content`, `message_type` (text/image/recipe_share), `recipe_id`, `sent_at`
- **Used by**: Chat UI, message history
- **RLS**: Participant reads/sends (via conversation_participant or group_member)
- **Constraint**: CHECK ensures message is in conversation OR group, not both

#### `conversation_request`
- **Role**: Pending conversation invitation
- **Purpose**: Request permission to chat with another user
- **Key columns**: `from_user_id`, `to_user_id`, `status` (pending/accepted/declined), UNIQUE(from_user_id, to_user_id)
- **Used by**: Chat request flow
- **RLS**: Both parties see request

#### `ai_conversation`
- **Role**: AI assistant conversation container
- **Purpose**: Group messages in a single AI chat session
- **Key columns**: `user_id`, `created_at`, `updated_at`
- **Used by**: AI assistant page
- **RLS**: Owner only

#### `ai_message`
- **Role**: Individual messages in AI conversation
- **Purpose**: Store user queries and AI responses
- **Key columns**: `conversation_id`, `role` (user/assistant), `content`, `tokens_used`, `sent_at`
- **Used by**: AI assistant chat history
- **RLS**: Owner via conversation FK (reads/inserts)

---

### Notifications

#### `notification`
- **Role**: In-app notification
- **Purpose**: Notify users of events (reminders, new recipes, fan activations, messages)
- **Key columns**: `user_id`, `type` (meal_reminder/new_recipe/fan_activated/revenue_update/message/group_invite/conversation_request/system), `title`, `body`, `data` (jsonb), `is_read`
- **Used by**: Notification center, push notification fallback
- **RLS**: Owner only

#### `push_token`
- **Role**: FCM push notification token
- **Purpose**: Send push notifications to user's device
- **Key columns**: `user_id`, `token` (unique), `platform` (ios/android)
- **Used by**: `send-push-notification` EF
- **RLS**: Owner only
- **Notes**: Latest token used if user has multiple devices

---

### Commerce

#### `subscription`
- **Role**: User's Akeli premium subscription
- **Purpose**: Gate premium features (Fan mode, AI assistant, meal plans)
- **Key columns**: `user_id`, `status` (active/cancelled), `store_platform` (android/ios), `store_product_id`, `store_purchase_token`, `current_period_start`, `current_period_end`
- **Used by**: `activate-fan-mode` EF, `validate-store-purchase` EF, feature gating
- **RLS**: Owner only
- **⚠️ NOTE**: Originally had Stripe columns (stripe_customer_id, stripe_subscription_id) - DROPPED in migration 20260302000001. Stripe is now exclusively for creator payouts.

---

### Reference Data

#### `food_region`
- **Role**: Culinary region catalog
- **Purpose**: Categorize recipes and user preferences by region
- **Key columns**: `code` (PK), `name_fr`, `name_en`, `name_es`, `name_pt`
- **Used by**: Recipe region filter, user cuisine preferences, recommendations
- **RLS**: Public reads all
- **Seed**: 13 regions (west_africa, central_africa, east_africa, north_africa, south_africa, caribbean, france, mediterranean, middle_east, south_asia, southeast_asia, latin_america, north_america)

#### `ingredient_category`
- **Role**: Ingredient taxonomy
- **Purpose**: Categorize ingredients for shopping list organization
- **Key columns**: `code` (PK), `name_fr`, `name_en`
- **Used by**: Shopping list grouping, ingredient display
- **RLS**: Public reads all
- **Seed**: 14 categories (protein, vegetable, fruit, grain, legume, dairy, fat_oil, spice_herb, sauce_condiment, nut_seed, seafood, beverage, sweetener, other)

#### `measurement_unit`
- **Role**: Unit of measurement
- **Purpose**: Standardize recipe ingredient quantities
- **Key columns**: `code` (PK), `name_fr`, `name_en`, `name_es`, `name_pt`
- **Used by**: Recipe ingredient display, shopping list
- **RLS**: Public reads all
- **Seed**: 14 units (g, kg, mg, ml, cl, l, tsp, tbsp, cup, piece, slice, bunch, pinch, to_taste)

#### `tag`
- **Role**: Recipe tag catalog
- **Purpose**: Categorize recipes by dietary type, occasion, technique
- **Key columns**: `id`, `name`, `name_fr`, `name_en`, `name_es`, `name_pt`
- **Used by**: Search filters, recipe discovery
- **RLS**: Public reads all
- **Seed**: 21 tags (vegetarian, vegan, halal, gluten_free, lactose_free, low_carb, high_protein, quick, meal_prep, family, budget, festive, street_food, spicy, sweet, savory, fried, grilled, baked, raw, one_pot)

#### `specialty`
- **Role**: Creator specialty
- **Purpose**: Define creator's culinary specialties
- **Key columns**: `id`, `code`, multi-lingual names, `region_id`
- **Used by**: Creator profile display
- **RLS**: Public reads all

---

### Support & Other

#### `support_message`
- **Role**: User support tickets
- **Purpose**: Handle user inquiries
- **Key columns**: `user_id`, `email`, `subject`, `content`, `status` (open/in_progress/resolved)
- **Used by**: Support flow
- **RLS**: Owner reads own; any authenticated user can insert

#### `referral`
- **Role**: User referral tracking
- **Purpose**: Track who referred whom
- **Key columns**: `referrer_id`, `referred_id`, `referral_code`, `status` (pending/converted), `converted_at`
- **Used by**: Referral program, user acquisition tracking
- **RLS**: Referrer reads own
- **⚠️ NOTE**: No policy for referred_id to see their referral record

#### `ingredient_submission`
- **Role**: User-submitted ingredients
- **Purpose**: Allow users to suggest new ingredients
- **Key columns**: (varies)
- **Used by**: Ingredient submission flow
- **RLS**: (Check migration for policies)

#### `payout`
- **Role**: Legacy payout table
- **Purpose**: Historical payout records (superseded by `creator_payout`)
- **Key columns**: `creator_id`, `amount`, `status` (pending/processing/paid/failed), `month_key`, `paid_at`
- **Used by**: Legacy reporting
- **RLS**: Creator reads own
- **⚠️ NOTE**: Superseded by `creator_payout` from migration 20260302000001. Keep for historical data only.

---

## 4. SQL FUNCTIONS (RPC)

### `recommend_recipes(p_user_id, p_limit, p_offset, p_region, p_difficulty, p_max_time)`
- **Role**: Vectorized recipe feed generation
- **Purpose**: Return personalized recipe recommendations using pgvector cosine similarity
- **Returns**: Table with recipe details, creator info, macros, like count, similarity score
- **Algorithm**: 
  1. Fetch user vector from user_vector
  2. Fetch active Fan creator (if exists)
  3. If no user vector → fallback to popularity (cold start)
  4. Otherwise → cosine similarity with ×1.5 Fan boost
  5. Filter by region, difficulty, max_time
  6. Group by recipe, count likes, order by similarity
- **Security**: SECURITY DEFINER (bypasses RLS) - explicitly filters by is_published
- **Performance**: HNSW index ~3ms for 2500+ recipes
- **Called by**: Flutter feed provider
- **Migration**: 20260301000002

### `search_recipes(p_query, p_region, p_difficulty, p_tag_ids, p_max_time, p_order_by, p_limit, p_offset)`
- **Role**: Recipe text search with filters
- **Purpose**: Search recipes by title/description with sorting options
- **Returns**: Table with recipe details, creator info, macros, like count
- **Sorting**: 'recent' (created_at DESC), 'popular' (like_count DESC), 'quick' (total_time ASC)
- **Tag filtering**: Recipe must have ALL requested tags
- **Security**: SECURITY DEFINER - filters by is_published
- **Called by**: Flutter search page
- **Migration**: 20260301000002

### `search_creators(p_query, p_limit, p_offset)`
- **Role**: Creator text search
- **Purpose**: Find creators by display_name
- **Returns**: Table with creator details, stats
- **Sorting**: Fan-eligible first, then by recipe_count DESC
- **Security**: SECURITY DEFINER
- **Called by**: Flutter creator search
- **Migration**: 20260301000002

### `get_creator_public_profile(p_creator_id)`
- **Role**: Full creator profile with Fan status check
- **Purpose**: Display public creator profile + check if current user is their Fan
- **Returns**: Table with creator details + `is_my_fan_creator` boolean
- **Security**: SECURITY DEFINER - checks current user's fan_subscription
- **Called by**: Creator profile page
- **Migration**: 20260301000002

### `generate_meal_plan(p_user_id, p_days, p_meals_per_day, p_start_date)`
- **Role**: Vectorized meal plan generation
- **Purpose**: Generate optimal meal plan using cosine similarity, avoid duplicates
- **Returns**: Table with meal_plan_id, entry_id, scheduled_date, meal_type, recipe details, similarity
- **Algorithm**:
  1. Fetch user vector, active Fan creator
  2. Deactivate previous active plans
  3. Create new meal_plan
  4. Loop: days × meals_per_day
  5. For each slot: select best unused recipe by similarity (or popularity if no vector)
  6. Insert meal_plan_entry, track used recipe_ids
  7. Return full plan
- **Security**: SECURITY DEFINER - filters by is_published
- **Called by**: `generate-meal-plan` Edge Function
- **Migration**: 20260301000002

### `generate_shopping_list(p_meal_plan_id)`
- **Role**: Aggregate shopping list from meal plan
- **Purpose**: Sum ingredient quantities across all recipes in plan
- **Returns**: Table with ingredient details, total quantities, category
- **Algorithm**:
  1. Verify plan belongs to current user
  2. Delete old shopping list for this plan
  3. Create new shopping_list
  4. Aggregate ingredients from all meal_plan_entry recipes (quantity × servings)
  5. Group by ingredient, exclude optional
  6. Return organized by category
- **Security**: SECURITY DEFINER - verifies ownership
- **Called by**: Flutter shopping list page
- **Migration**: 20260301000002

### `find_or_create_conversation(p_other_user_id)`
- **Role**: Private conversation finder/creator
- **Purpose**: Find existing or create new 1:1 conversation
- **Returns**: conversation_id (uuid)
- **Algorithm**:
  1. Find conversation where both users are participants
  2. If found → return id
  3. If not → create conversation, insert participants
- **Security**: SECURITY DEFINER
- **Called by**: Chat page
- **Migration**: 20260301000002

### `respond_conversation_request(p_request_id, p_action)`
- **Role**: Accept/decline conversation request
- **Purpose**: Handle chat permission flow
- **Returns**: JSON with conversation_id (if accepted) or status
- **Algorithm**:
  1. Verify request exists and belongs to current user
  2. Update request status
  3. If accepted → create conversation, insert participants
- **Security**: SECURITY DEFINER
- **Called by**: Chat request flow
- **Migration**: 20260301000002

### `join_group(p_group_id)`
- **Role**: Join public community group
- **Purpose**: Add user to group membership
- **Returns**: JSON with group_id and status
- **Algorithm**:
  1. Verify group exists
  2. If private → error (need invitation)
  3. Insert group_member (ON CONFLICT DO NOTHING)
- **Security**: SECURITY DEFINER
- **Called by**: Groups page
- **Migration**: 20260301000002

---

## 5. EDGE FUNCTIONS

### User-Facing (verify_jwt = true)

#### `activate-fan-mode`
- **Role**: Subscribe user to creator's Fan mode
- **Purpose**: Enable premium creator support
- **Tables**: subscription, creator, fan_subscription, fan_subscription_history
- **Flow**: Verify subscription → verify creator eligibility (>=30 recipes) → verify no existing Fan → insert pending subscription → set effective_from to 1st of next month
- **Migration**: N/A (Edge Function only)

#### `cancel-fan-mode`
- **Role**: Cancel current Fan subscription
- **Purpose**: End creator support
- **Tables**: fan_subscription, fan_subscription_history
- **Flow**: Verify active/pending Fan → update to cancelled → set effective_until to 1st of next month

#### `ai-assistant-chat`
- **Role**: AI nutrition assistant
- **Purpose**: Answer nutrition questions with user context
- **Tables**: ai_conversation, ai_message, user_health_profile, user_goal, meal_plan, daily_nutrition_log, recipe_like, shopping_list
- **External**: OpenAI GPT-4o-mini
- **Architecture**: Fast path (pattern matching) + Smart path (intent analysis + context enrichment)
- **Rate limit**: 30 msg/min

#### `complete-onboarding`
- **Role**: Complete user onboarding
- **Purpose**: Save health profile, goals, preferences, mark onboarding done
- **Tables**: user_health_profile, user_goal, user_dietary_restriction, user_cuisine_preference, user_profile
- **External**: Python Service (Railway) for vector computation
- **Flow**: Validate → insert profiles → trigger vector computation (non-blocking)

#### `create-checkout-session`
- **Role**: Stripe Checkout for creator payouts (web only)
- **Purpose**: Admin-only checkout for paying creators
- **Tables**: creator, user_profile
- **External**: Stripe API
- **⚠️ NOTE**: NOT for user subscriptions - users pay via Google Play/App Store

#### `generate-meal-plan`
- **Role**: Orchestrate meal plan generation
- **Purpose**: Call RPC, return structured plan
- **Tables**: meal_plan, meal_plan_entry (via `generate_meal_plan` RPC)

#### `get-creator-dashboard`
- **Role**: Creator earnings dashboard
- **Purpose**: Display revenue history, balance, projections
- **Tables**: creator, creator_balance, creator_revenue_log, meal_consumption
- **Revenue model**: Fan = 1€/fan/month; Consumption = floor(consumptions/90) × 1€

#### `log-meal-consumption`
- **Role**: Mark meal as consumed, enforce Fan limits
- **Purpose**: Track consumption, attribute revenue
- **Tables**: meal_plan_entry, recipe, meal_consumption, fan_subscription, fan_external_recipe_counter
- **Fan enforcement**: Max 9 external recipes/month

#### `toggle-recipe-like`
- **Role**: Toggle recipe like/unlike
- **Purpose**: User engagement tracking
- **Tables**: recipe_like
- **Flow**: Check existing → INSERT or DELETE

#### `validate-store-purchase`
- **Role**: Validate Google Play / App Store purchase
- **Purpose**: Activate user subscription
- **Tables**: subscription
- **External**: Apple App Store, Google Play API

### Internal/Cron (verify_jwt = false)

#### `compute-monthly-revenue`
- **Schedule**: 1st of month 01:00 UTC
- **Role**: Compute creator revenue for previous month
- **Tables**: creator, fan_subscription, meal_consumption, creator_revenue_log, creator_balance

#### `process-fan-mode-transitions`
- **Schedule**: 1st of month 00:05 UTC
- **Role**: Activate pending Fan subs, cancel expired ones
- **Tables**: fan_subscription, fan_external_recipe_counter

#### `send-meal-reminders`
- **Schedule**: Hourly (0 * * * *)
- **Role**: Send push notifications for meal reminders
- **Tables**: meal_reminder
- **Internal call**: `send-push-notification`

#### `send-push-notification`
- **Role**: Send FCM push + insert notification
- **Purpose**: Deliver push notifications
- **Tables**: push_token, notification
- **External**: Firebase Cloud Messaging

#### `stripe-webhook`
- **Role**: Handle Stripe events for creator payouts
- **Tables**: creator_payout, creator
- **External**: Stripe (HMAC signature verification)
- **Events**: payment_intent.succeeded/failed, transfer.created, account.updated

#### `translate-content`
- **Role**: Translate culinary content
- **Purpose**: Multi-lingual recipe support
- **External**: Gemini 1.5 flash (African languages: Wolof, Bambara, Lingala, Arabic)

---

## 6. FLUTTER APP STRUCTURE

### Core
| Component | Role | Purpose | Location |
|-----------|------|---------|----------|
| `main.dart` | Entry point | App initialization, provider scope | `lib/main.dart` |
| `router.dart` | Navigation | GoRouter configuration, auth guards, redirects | `lib/core/router.dart` |
| `theme.dart` | Styling | App theme, colors, typography | `lib/core/theme.dart` |
| `logger.dart` | Logging | Centralized logger, helpers, RLS debug tools | `lib/core/logger.dart` |

### Providers
| Provider | Role | Purpose | Location |
|----------|------|---------|----------|
| `auth_provider.dart` | Auth state | Sign-in, sign-up, sign-out, session management | `lib/providers/auth_provider.dart` |
| `recipe_provider.dart` | Recipe feed | Fetch recipes, like toggle, search | `lib/providers/recipe_provider.dart` |
| `meal_plan_provider.dart` | Meal plan | Generate, view, manage meal plans | `lib/providers/meal_plan_provider.dart` |
| `nutrition_provider.dart` | Nutrition | Daily nutrition tracking | `lib/providers/nutrition_provider.dart` |
| `fan_mode_provider.dart` | Fan mode | Activate, cancel, check Fan status | `lib/providers/fan_mode_provider.dart` |
| `user_profile_provider.dart` | User profile | Load and update user profile | `lib/providers/user_profile_provider.dart` |

### Features (lib/features/)
| Feature | Role | Key Pages | Location |
|---------|------|-----------|----------|
| `auth` | Authentication | Login, signup, password reset | `lib/features/auth/` |
| `home` | Home feed | Recipe feed, navigation | `lib/features/home/` |
| `recipes` | Recipe browsing | Recipe list, detail, search | `lib/features/recipes/` |
| `meal_planner` | Meal planning | Plan view, generation, shopping list | `lib/features/meal_planner/` |
| `nutrition` | Nutrition tracking | Daily log, progress, goals | `lib/features/nutrition/` |
| `profile` | User profile | Settings, preferences, stats | `lib/features/profile/` |
| `ai_assistant` | AI chat | Nutrition assistant interface | `lib/features/ai_assistant/` |
| `community` | Community | Groups, conversations | `lib/features/community/` |
| `fan_mode` | Fan mode | Fan subscription management | `lib/features/fan_mode/` |
| `diet_plan` | Diet plans | Pre-built diet plans | `lib/features/diet_plan/` |
| `notifications` | Notifications | Notification center | `lib/features/notifications/` |
| `subscription` | Subscriptions | Premium management | `lib/features/subscription/` |

### Shared
| Component | Role | Location |
|-----------|------|----------|
| Models | Data classes (Recipe, UserProfile, Creator, MealPlan) | `lib/shared/models/` |
| Widgets | Reusable UI components | `lib/shared/widgets/` |
| Mock data | Development mock data | `lib/shared/mock_data.dart` |

---

## 7. FEATURES

### Core Features
| Feature | Status | Backend | Frontend | Notes |
|---------|--------|---------|----------|-------|
| User authentication | Mock | Supabase Auth ready | Auth pages built | Wire up Supabase |
| Recipe feed | Mock | `recommend_recipes` RPC ready | Feed UI built | Wire up RPC |
| Recipe search | Mock | `search_recipes` RPC ready | Search UI built | Wire up RPC |
| Recipe detail | Mock | Published recipes | Detail page built | Wire up |
| Recipe like/unlike | Mock | `toggle-recipe-like` EF ready | Like button built | Wire up |
| Recipe save/bookmark | Ready | `recipe_save` table exists | Needs UI | Added in tracking migration |
| Meal plan generation | Mock | `generate_meal_plan` RPC ready | Planner UI built | Wire up RPC |
| Meal consumption | Mock | `log-meal-consumption` EF ready | Needs UI | Wire up |
| Shopping list | Mock | `generate_shopping_list` RPC ready | Needs UI | Wire up |
| Nutrition tracking | Mock | Daily log auto-updated | Needs UI | Wire up |
| Fan mode | Mock | All EFs ready | Needs UI | Wire up |
| Creator dashboard | Mock | `get-creator-dashboard` EF ready | Needs UI | Wire up |
| AI assistant | Mock | `ai-assistant-chat` EF ready | Needs UI | Wire up |
| Community groups | Not built | Tables exist | Needs UI | Schema ready |
| Chat/messaging | Not built | Tables + RPCs exist | Needs UI | Schema ready |
| Push notifications | Not built | `send-push-notification` EF ready | Needs integration | Wire up FCM |
| Store subscription | Not built | `validate-store-purchase` EF ready | Needs integration | Wire up IAP |

---

## 8. EXTERNAL SERVICES

| Service | Purpose | Used By | Env Var | Cost |
|---------|---------|---------|---------|------|
| Supabase | Database, Auth, Storage, Edge Functions | Everything | SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY | Free tier / Pro |
| OpenAI (GPT-4o-mini) | AI nutrition assistant | `ai-assistant-chat` | OPENAI_API_KEY | Per token |
| Gemini 1.5 flash | African language translation | `translate-content` | GEMINI_API_KEY | Per request |
| Firebase Cloud Messaging | Push notifications | `send-push-notification` | FCM_SERVER_KEY | Free |
| Google Play | User subscriptions (Android) | `validate-store-purchase` | GOOGLE_SERVICE_ACCOUNT_JSON, ANDROID_PACKAGE_NAME | 15-30% |
| App Store | User subscriptions (iOS) | `validate-store-purchase` | APPLE_SHARED_SECRET | 15-30% |
| Stripe Connect | Creator payouts | `create-checkout-session`, `stripe-webhook` | STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET | Per transaction |
| Python Service (Railway) | User vector computation | `complete-onboarding` | PYTHON_SERVICE_URL | Railway hosting |

---

## 9. PERFORMANCE & CACHING

### Indexes
| Table | Index | Purpose | Migration |
|-------|-------|---------|-----------|
| user_vector | HNSW (vector_cosine_ops) | Cosine similarity ~3ms | 20260301000001 |
| recipe_vector | HNSW (vector_cosine_ops) | Cosine similarity ~3ms | 20260301000001 |
| recipe | creator_id, region, is_published | Feed filtering | 20260301000001 |
| meal_plan | user_id, is_active | Plan lookup | 20260301000001 |
| meal_consumption | user_id, creator_id, month_key | Revenue aggregation | 20260301000001 |
| recipe_step | recipe_id | Step ordering | 20260302000003 |
| recipe_save | user_id | Bookmark lookup | 20260314000001 |
| recipe_impression | recipe_id, user_id | Analytics | 20260314000001 |
| recipe_open | recipe_id, user_id | Analytics | 20260314000001 |

### Caching Strategy
| Data | TTL | Location | Invalidation |
|------|-----|----------|-------------|
| Feed recommendations | 5-15 min | Edge Function | Recipe publish/like |
| Creator profiles | 30-60 min | Edge Function | Profile update |
| Recipe detail | 10-30 min | Edge Function | Recipe edit |
| Search results | 5-10 min | Edge Function | Index update |
| Reference data | 24 hours | Flutter client | App update |

---

## 10. SECURITY & RLS

### RLS Summary
- **ALL 50+ tables have RLS enabled**
- **80+ policies** total
- **Two client modes**: userClient (RLS enforced), serviceClient (RLS bypassed)
- **See `rls-list.md`** for complete policy registry
- **Known bugs**: `recipe_step` policies reference non-existent columns

### Security Layers
1. **Supabase Auth**: JWT verification for all user operations
2. **RLS policies**: Row-level access control on every table
3. **Edge Function JWT verification**: `verify_jwt` in config.toml
4. **Service role isolation**: Only cron/webhooks use serviceClient
5. **CORS**: All edge functions handle preflight via `_shared/cors.ts`

---

## 11. MONITORING & LOGGING

### Logging Infrastructure
- **Flutter**: `logger` package with `appLogger` (lib/core/logger.dart)
- **Edge Functions**: `createLogger` with request/user correlation (supabase/functions/_shared/logger.ts)
- **Categories**: Auth (🔐), DB (📡), RLS (🔍), Provider (🔄), Edge (⚡), UI (🎯)
- **Levels**: trace, debug, info, warning, error
- **Security helpers**: maskEmail, maskUuid, maskToken, sanitizeData
- **RLS debug**: RLSDebugHelper for query debugging
- **See**: `LOGGING_INSTRUCTIONS.md`, `LOGGING_QUICK_REFERENCE.md`

### What's Logged
- Every function entry/exit
- Every state change
- Every database query (before/after)
- Every navigation event
- Every user action
- Every error with stack trace
- Every RLS check

### Performance Monitoring
- Query duration logged (warn if > 1000ms)
- API call duration logged (warn if > 5000ms)
- Provider lifecycle tracked
- Edge function request duration tracked

---

## 12. DEVELOPMENT & DEPLOYMENT

### Local Development
```bash
supabase start              # Start local Supabase
supabase db push            # Apply migrations
supabase functions serve    # Serve edge functions
```

### Production Deployment
```bash
supabase link --project-ref REF
supabase db push            # Push migrations
supabase functions deploy   # Deploy all edge functions
```

### Migration Order
1. `20260301000001_initial_schema.sql` - Base schema (49+ tables)
2. `20260301000002_rpc_functions.sql` - 9 RPC functions
3. `20260302000001_store_payment_arch.sql` - Store payments
4. `20260302000002_fix_rls_policies.sql` - Fix missing RLS (5 policies)
5. `20260302000003_add_recipe_steps.sql` - recipe_step (OBSOLETE)
6. `20260314000001_recipe_tracking_schema.sql` - Recipe tracking v2

### Documentation
| Document | Purpose | Location |
|----------|---------|----------|
| PROJECT_PLAN.md (this file) | Master index of everything | `PROJECT_PLAN.md` |
| SUPABASE_DOCUMENTATION_STANDARDS.md | Documentation rules | `supabase/SUPABASE_DOCUMENTATION_STANDARDS.md` |
| rls-list.md | RLS policy registry | `supabase/rls-list.md` |
| EDGE_FUNCTIONS.md | Edge function registry | `supabase/EDGE_FUNCTIONS.md` |
| database_schema.sql | Schema snapshot | `supabase/database_schema.sql` |
| LOGGING_INSTRUCTIONS.md | Logging guidelines | `LOGGING_INSTRUCTIONS.md` |
| LOGGING_QUICK_REFERENCE.md | Quick reference | `LOGGING_QUICK_REFERENCE.md` |
| logging skill | Qwen Code skill | `.qwen/skills/logging.md` |

---

**Last updated**: 2026-04-13  
**Version**: 1.0.0  
**Maintainer**: Akeli Dev Team  
**Next review**: After every major feature addition or architectural change
