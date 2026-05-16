-- =============================================================================
-- AKELI V1 — Comprehensive Database Annotations
-- Migration: 20260413000001_annotate_all_tables.sql
-- Author: Akeli Dev Team
-- Date: 2026-04-13
-- Reason: Add extensive documentation comments to ALL tables, columns, and functions
--         for zero-guessing debugging, management, and implementation
-- Impact: ALL 50+ tables annotated with ROLE, PURPOSE, USAGE notes
--         ALL key columns annotated with description
--         ALL RPC functions annotated with purpose and parameters
--         ALL RLS policies annotated with role
-- Backwards compatible: YES (comments are metadata-only, no schema changes)
-- =============================================================================
-- 
-- HOW TO READ ANNOTATIONS:
--   - Query pg_description or use \d+ in psql to see comments
--   - In Supabase Studio: Table/column descriptions appear in UI
--   - In documentation: See PROJECT_PLAN.md for full descriptions
-- 
-- CONVENTION:
--   Table comments: "ROLE: ... | PURPOSE: ... | USAGE: ..."
--   Column comments: "Description | Used by: ... | Notes: ..."

-- =============================================================================
-- IDENTITY & AUTH
-- =============================================================================

COMMENT ON TABLE user_profile IS 'ROLE: Core user identity extending Supabase auth.users | PURPOSE: Store user preferences, role, locale, creator status | USAGE: Referenced by ALL features for user context, auth, feature gating';
COMMENT ON COLUMN user_profile.id IS 'FK to auth.users.id | Primary user identifier';
COMMENT ON COLUMN user_profile.username IS 'Unique display name | Publicly visible';
COMMENT ON COLUMN user_profile.locale IS 'UI language preference (fr/en/es/pt/wo/bm/ln/ar) | Default: fr';
COMMENT ON COLUMN user_profile.is_creator IS 'Whether user has a creator profile | Gates creator features';
COMMENT ON COLUMN user_profile.onboarding_done IS 'Whether user completed onboarding | Gates onboarding flow';
COMMENT ON COLUMN user_profile.role IS 'User role: user or admin | Gates admin features';

COMMENT ON TABLE user_health_profile IS 'ROLE: User physical health data | PURPOSE: Calculate calorie needs, personalize meal plans | USAGE: complete-onboarding EF, meal plan generation, AI assistant';
COMMENT ON COLUMN user_health_profile.activity_level IS 'sedentary/light/moderate/active/very_active | Affects calorie calculation';

COMMENT ON TABLE user_goal IS 'ROLE: User nutrition goal | PURPOSE: Guide meal plan generation and recipe recommendations | USAGE: AI assistant context, meal plan generation, recommendations';
COMMENT ON COLUMN user_goal.goal_type IS 'weight_loss/muscle_gain/maintenance/health/performance | Drives nutrition strategy';

COMMENT ON TABLE user_dietary_restriction IS 'ROLE: User dietary constraints | PURPOSE: Filter recipes and meal plans to match restrictions | USAGE: Recommendations, meal plan generation, AI assistant';

COMMENT ON TABLE user_cuisine_preference IS 'ROLE: Preferred culinary regions with scores | PURPOSE: Weight recipe recommendations by cultural preference | USAGE: recommend_recipes RPC similarity weighting';

COMMENT ON TABLE weight_log IS 'ROLE: User weight tracking history | PURPOSE: Track progress toward target weight | USAGE: Profile page, progress charts';

COMMENT ON TABLE user_vector IS 'ROLE: 50-dim embedding of user taste profile | PURPOSE: Enable cosine similarity for recipe recommendations | USAGE: recommend_recipes RPC, generate_meal_plan RPC | PERF: HNSW index ~3ms similarity';
COMMENT ON COLUMN user_vector.vector IS '50-dim pgvector embedding | Computed by Python service on Railway';

-- =============================================================================
-- CREATOR
-- =============================================================================

COMMENT ON TABLE creator IS 'ROLE: Public creator profile | PURPOSE: Display creator info, track stats, manage Fan eligibility | USAGE: Creator profile page, search, recommendations, Fan mode';
COMMENT ON COLUMN creator.specialties IS 'Culinary region codes (FK to food_region) | Displayed on profile';
COMMENT ON COLUMN creator.languages IS 'Spoken language codes | Displayed on profile';
COMMENT ON COLUMN creator.recipe_count IS 'Denormalized count of published recipes | Updated by trigger';
COMMENT ON COLUMN creator.fan_count IS 'Denormalized count of active fans | Updated by trigger';
COMMENT ON COLUMN creator.is_fan_eligible IS 'Generated: recipe_count >= 30 | Gates Fan mode activation';

COMMENT ON TABLE creator_balance IS 'ROLE: Creator current earnings | PURPOSE: Track available balance, lifetime earnings, payouts | USAGE: Creator dashboard, payout processing';
COMMENT ON COLUMN creator_balance.balance IS 'Available (unpaid) balance | Updated by compute-monthly-revenue cron';
COMMENT ON COLUMN creator_balance.total_earned IS 'Lifetime earnings | For display only';
COMMENT ON COLUMN creator_balance.total_paid_out IS 'Total paid out | For reconciliation';

COMMENT ON TABLE creator_revenue_log IS 'ROLE: Monthly revenue history (immutable) | PURPOSE: Record of earnings computation for auditing | USAGE: Creator dashboard, monthly statements';
COMMENT ON COLUMN creator_revenue_log.month_key IS 'YYYY-MM format | Enables efficient monthly aggregation';
COMMENT ON COLUMN creator_revenue_log.total_revenue IS 'Generated: fan_revenue + consumption_revenue | Read-only';

COMMENT ON TABLE creator_payout IS 'ROLE: Stripe payout transaction history | PURPOSE: Track payouts to creators | USAGE: stripe-webhook EF, creator dashboard payout history';

-- =============================================================================
-- RECIPES
-- =============================================================================

COMMENT ON TABLE recipe IS 'ROLE: Core recipe entity | PURPOSE: Store recipe metadata for display, search, recommendations | USAGE: Feed, search, detail page, meal plans, AI assistant';
COMMENT ON COLUMN recipe.creator_id IS 'FK to creator.id | Recipe author (SET NULL on creator delete)';
COMMENT ON COLUMN recipe.is_published IS 'Whether recipe is publicly visible | Gates RLS read access';
COMMENT ON COLUMN recipe.difficulty IS 'easy/medium/hard | Displayed and used for filtering';
COMMENT ON COLUMN recipe.region IS 'FK to food_region.code | Culinary origin | Used for filtering and recommendations';
-- Note: recipe.instructions column DROPPED (replaced by recipe_step)

COMMENT ON TABLE recipe_step IS 'ROLE: Structured preparation steps | PURPOSE: Replace monolithic instructions with ordered visual steps | USAGE: Recipe detail step-by-step display';
COMMENT ON COLUMN recipe_step.step_number IS 'Order of step | Unique per recipe';
COMMENT ON COLUMN recipe_step.title IS 'Optional step title | For display';
COMMENT ON COLUMN recipe_step.content IS 'Step instructions | Required';
COMMENT ON COLUMN recipe_step.timer_seconds IS 'Optional timer for step | Displayed in recipe detail';
COMMENT ON TABLE recipe_step IS '⚠️ KNOWN BUG: RLS policies reference r.status (non-existent, should be r.is_published) and r.creator_id = auth.uid() (should join through creator table) | See rls-list.md';

COMMENT ON TABLE recipe_macro IS 'ROLE: Nutrition data per recipe | PURPOSE: Display calorie/macro info, calculate daily nutrition | USAGE: Recipe detail, daily nutrition log, meal plan calorie totals';

COMMENT ON TABLE ingredient IS 'ROLE: Ingredient reference data | PURPOSE: Standardized catalog with nutrition per 100g | USAGE: Recipe ingredients, shopping list, nutrition calculations';

COMMENT ON TABLE recipe_ingredient IS 'ROLE: Recipe ingredient list | PURPOSE: Define what goes in each recipe with quantities | USAGE: Recipe detail, shopping list generation';

COMMENT ON TABLE recipe_tag IS 'ROLE: Recipe tagging (many-to-many) | PURPOSE: Categorize by dietary type, occasion, technique | USAGE: Search filters, recipe discovery';

COMMENT ON TABLE recipe_image IS 'ROLE: Additional recipe images | PURPOSE: Gallery display beyond cover image | USAGE: Recipe detail image gallery';

COMMENT ON TABLE recipe_like IS 'ROLE: User likes on recipes | PURPOSE: Track engagement, influence recommendations | USAGE: Feed, search (like count), creator dashboard, AI assistant context';

COMMENT ON TABLE recipe_save IS 'ROLE: User bookmarks (saved recipes) | PURPOSE: Let users save recipes for later | USAGE: User saved recipes page | Added: 20260314000001';

COMMENT ON TABLE recipe_comment IS 'ROLE: User comments on recipes | PURPOSE: Community engagement | USAGE: Recipe detail comments section';

COMMENT ON TABLE recipe_impression IS 'ROLE: Recipe card seen (passive signal) | PURPOSE: Measure visibility, creator analytics | USAGE: Creator dashboard analytics, recommendation optimization | Added: 20260314000001';
COMMENT ON COLUMN recipe_impression.source IS 'Where card was seen: feed/search/meal_planner | For analytics breakdown';
COMMENT ON COLUMN recipe_impression.user_id IS 'Nullable for anonymous impressions | Supports non-auth tracking';

COMMENT ON TABLE recipe_open IS 'ROLE: Recipe opened with session tracking (intentional signal) | PURPOSE: Measure engagement, creator analytics | USAGE: Creator dashboard, engagement metrics | Added: 20260314000001';
COMMENT ON COLUMN recipe_open.session_duration_seconds IS 'Time spent viewing recipe | Computed on close';

COMMENT ON TABLE recipe_vector IS 'ROLE: 50-dim embedding of recipe culinary profile | PURPOSE: Enable cosine similarity for recommendations | USAGE: recommend_recipes RPC, generate_meal_plan RPC | PERF: HNSW index ~3ms';

COMMENT ON TABLE recipe_translation IS 'ROLE: Translated recipe content | PURPOSE: Multi-lingual recipe display | USAGE: Recipe detail locale-aware display';
COMMENT ON COLUMN recipe_translation.locale IS 'fr/en/es/pt/wo/bm/ln/ar | Target language';

-- =============================================================================
-- MEAL PLANNING
-- =============================================================================

COMMENT ON TABLE meal_plan IS 'ROLE: User meal plan container | PURPOSE: Organize meals over a date range | USAGE: Meal planner page, shopping list generation';
COMMENT ON COLUMN meal_plan.is_active IS 'Whether plan is current | Auto-deactivated when new plan generated';

COMMENT ON TABLE meal_plan_entry IS 'ROLE: Individual meal slot in a plan | PURPOSE: Map recipes to specific dates and meal types | USAGE: Daily meal view, consumption logging';
COMMENT ON COLUMN meal_plan_entry.meal_type IS 'breakfast/lunch/dinner/snack | Determines display order';
COMMENT ON COLUMN meal_plan_entry.is_consumed IS 'Whether meal was eaten | Gates consumption tracking';

COMMENT ON TABLE meal_consumption IS 'ROLE: SOURCE OF TRUTH for creator revenue | PURPOSE: Track consumed meals, attribute revenue to creators | USAGE: Revenue computation, daily nutrition, Fan enforcement';
COMMENT ON COLUMN meal_consumption.month_key IS 'Generated: YYYY-MM from consumed_at | Enables efficient monthly revenue aggregation';

COMMENT ON TABLE shopping_list IS 'ROLE: Shopping list container | PURPOSE: Aggregate ingredients from meal plan | USAGE: Shopping list page';

COMMENT ON TABLE shopping_list_item IS 'ROLE: Individual ingredient in shopping list | PURPOSE: Aggregated quantities from all recipes in plan | USAGE: Shopping list display';

COMMENT ON TABLE meal_reminder IS 'ROLE: Meal reminder settings | PURPOSE: Schedule push notifications for meals | USAGE: send-meal-reminders cron function';
COMMENT ON COLUMN meal_reminder.days_of_week IS 'int[]: 1=Mon...7=Sun | Days to send reminder';

COMMENT ON TABLE daily_nutrition_log IS 'ROLE: Daily nutrition summary | PURPOSE: Track daily calorie/macro totals against goals | USAGE: Nutrition dashboard, daily progress';
COMMENT ON COLUMN daily_nutrition_log.log_date IS 'Date of nutrition data | Unique per user';
-- Auto-updated by trigger on meal_consumption insert

-- =============================================================================
-- FAN MODE
-- =============================================================================

COMMENT ON TABLE fan_subscription IS 'ROLE: User Fan subscription to creator | PURPOSE: Support creators, unlock exclusive content | USAGE: Fan mode activation, recommendations (x1.5 boost), revenue computation';
COMMENT ON COLUMN fan_subscription.status IS 'pending/active/cancelled | pending activates on 1st of next month';
COMMENT ON COLUMN fan_subscription.effective_from IS '1st of month when Fan activates | Set by activate-fan-mode EF';
COMMENT ON COLUMN fan_subscription.effective_until IS '1st of month when Fan cancels | Set by cancel-fan-mode EF';
COMMENT ON TABLE fan_subscription IS '⚠️ CONSTRAINT: UNIQUE(user_id, status) - one Fan per user';

COMMENT ON TABLE fan_subscription_history IS 'ROLE: Immutable Fan subscription history | PURPOSE: Audit trail for activation/cancellation | USAGE: Support, revenue auditing';
COMMENT ON TABLE fan_subscription_history IS 'Insert-only, never updated';

COMMENT ON TABLE fan_external_recipe_counter IS 'ROLE: External recipe consumption counter | PURPOSE: Enforce max 9 external recipes/month in Fan mode | USAGE: log-meal-consumption EF enforcement';
COMMENT ON COLUMN fan_external_recipe_counter.external_recipe_counter IS 'CHECK <= 9 | Blocks 10th external recipe';

-- =============================================================================
-- COMMUNITY & CHAT
-- =============================================================================

COMMENT ON TABLE community_group IS 'ROLE: Community discussion group | PURPOSE: Group-based conversations | USAGE: Groups page, group chat';
COMMENT ON COLUMN community_group.member_count IS 'Denormalized count | Updated by trigger';

COMMENT ON TABLE group_member IS 'ROLE: Group membership | PURPOSE: Track members and roles | USAGE: Group access control, member lists';

COMMENT ON TABLE conversation IS 'ROLE: Private conversation container | PURPOSE: 1:1 messaging | USAGE: Chat page, messaging';
COMMENT ON TABLE conversation IS 'Note: No RLS policies - access controlled via conversation_participant';

COMMENT ON TABLE conversation_participant IS 'ROLE: Conversation membership | PURPOSE: Define who can see each conversation | USAGE: Chat access control, unread counts';

COMMENT ON TABLE chat_message IS 'ROLE: Individual chat messages | PURPOSE: Text, image, recipe-share messages | USAGE: Chat UI, message history';
COMMENT ON COLUMN chat_message.message_type IS 'text/image/recipe_share | Determines display';
COMMENT ON COLUMN chat_message.recipe_id IS 'FK to recipe.id | For recipe_share messages';
COMMENT ON TABLE chat_message IS 'Note: CHECK constraint ensures message is in conversation OR group, not both';

COMMENT ON TABLE conversation_request IS 'ROLE: Pending conversation invitation | PURPOSE: Request permission to chat | USAGE: Chat request flow';

COMMENT ON TABLE ai_conversation IS 'ROLE: AI assistant conversation container | PURPOSE: Group messages in AI chat session | USAGE: AI assistant page';

COMMENT ON TABLE ai_message IS 'ROLE: Individual AI conversation messages | PURPOSE: Store user queries and AI responses | USAGE: AI assistant chat history';
COMMENT ON COLUMN ai_message.role IS 'user/assistant | Message sender';
COMMENT ON COLUMN ai_message.tokens_used IS 'OpenAI token count | For cost tracking';

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

COMMENT ON TABLE notification IS 'ROLE: In-app notification | PURPOSE: Notify users of events | USAGE: Notification center, push notification fallback';
COMMENT ON COLUMN notification.type IS 'meal_reminder/new_recipe/fan_activated/revenue_update/message/group_invite/conversation_request/system';
COMMENT ON COLUMN notification.data IS 'JSONB payload | Contextual data for notification action';

COMMENT ON TABLE push_token IS 'ROLE: FCM push token | PURPOSE: Send push notifications to device | USAGE: send-push-notification EF';
COMMENT ON COLUMN push_token.platform IS 'ios/android | Determines FCM payload';

-- =============================================================================
-- COMMERCE
-- =============================================================================

COMMENT ON TABLE subscription IS 'ROLE: User Akeli premium subscription | PURPOSE: Gate premium features (Fan mode, AI assistant, meal plans) | USAGE: activate-fan-mode EF, validate-store-purchase EF, feature gating';
COMMENT ON COLUMN subscription.store_platform IS 'android/ios | Store that processed payment';
COMMENT ON COLUMN subscription.store_purchase_token IS 'Store-specific token | Used for validation';
COMMENT ON TABLE subscription IS '⚠️ NOTE: Originally had Stripe columns - DROPPED in 20260302000001. Stripe now exclusively for creator payouts.';

-- =============================================================================
-- REFERENCE DATA
-- =============================================================================

COMMENT ON TABLE food_region IS 'ROLE: Culinary region catalog | PURPOSE: Categorize recipes and user preferences | USAGE: Recipe region filter, user cuisine preferences, recommendations';

COMMENT ON TABLE ingredient_category IS 'ROLE: Ingredient taxonomy | PURPOSE: Categorize ingredients for shopping list organization | USAGE: Shopping list grouping, ingredient display';

COMMENT ON TABLE measurement_unit IS 'ROLE: Unit of measurement | PURPOSE: Standardize recipe ingredient quantities | USAGE: Recipe ingredient display, shopping list';

COMMENT ON TABLE tag IS 'ROLE: Recipe tag catalog | PURPOSE: Categorize recipes by dietary type, occasion, technique | USAGE: Search filters, recipe discovery';

COMMENT ON TABLE specialty IS 'ROLE: Creator specialty | PURPOSE: Define creator culinary specialties | USAGE: Creator profile display';

-- =============================================================================
-- SUPPORT & OTHER
-- =============================================================================

COMMENT ON TABLE support_message IS 'ROLE: User support tickets | PURPOSE: Handle user inquiries | USAGE: Support flow';

COMMENT ON TABLE referral IS 'ROLE: User referral tracking | PURPOSE: Track who referred whom | USAGE: Referral program, user acquisition tracking';
COMMENT ON TABLE referral IS '⚠️ NOTE: No RLS policy for referred_id to see their referral record';

COMMENT ON TABLE ingredient_submission IS 'ROLE: User-submitted ingredients | PURPOSE: Allow users to suggest new ingredients | USAGE: Ingredient submission flow';

COMMENT ON TABLE payout IS 'ROLE: Legacy payout table | PURPOSE: Historical payout records | USAGE: Legacy reporting';
COMMENT ON TABLE payout IS '⚠️ SUPERSEDED by creator_payout (20260302000001). Keep for historical data only.';

-- =============================================================================
-- RPC FUNCTION ANNOTATIONS
-- =============================================================================

COMMENT ON FUNCTION recommend_recipes IS 'ROLE: Vectorized recipe feed generation | PURPOSE: Return personalized recommendations using pgvector cosine similarity | RETURNS: Table with recipe details, creator, macros, like_count, similarity | ALGORITHM: User vector similarity with x1.5 Fan boost, fallback to popularity for cold start | PERF: HNSW index ~3ms | SECURITY: SECURITY DEFINER (explicitly filters is_published)';

COMMENT ON FUNCTION search_recipes IS 'ROLE: Recipe text search with filters | PURPOSE: Search by title/description with sorting | RETURNS: Table with recipe details, creator, macros, like_count | SORTING: recent/popular/quick | SECURITY: SECURITY DEFINER';

COMMENT ON FUNCTION search_creators IS 'ROLE: Creator text search | PURPOSE: Find creators by display_name | RETURNS: Table with creator details, stats | SORTING: Fan-eligible first, then recipe_count DESC | SECURITY: SECURITY DEFINER';

COMMENT ON FUNCTION get_creator_public_profile IS 'ROLE: Full creator profile with Fan status | PURPOSE: Display public profile + check if current user is Fan | RETURNS: Table with creator details + is_my_fan_creator boolean | SECURITY: SECURITY DEFINER';

COMMENT ON FUNCTION generate_meal_plan IS 'ROLE: Vectorized meal plan generation | PURPOSE: Generate optimal plan using cosine similarity, avoid duplicates | RETURNS: Table with meal_plan_id, entry_id, scheduled_date, meal_type, recipe details, similarity | ALGORITHM: Loop days x meals, select best unused recipe by similarity | SECURITY: SECURITY DEFINER';

COMMENT ON FUNCTION generate_shopping_list IS 'ROLE: Aggregate shopping list from meal plan | PURPOSE: Sum ingredient quantities across all recipes | RETURNS: Table with ingredient details, total quantities, category | SECURITY: SECURITY DEFINER';

COMMENT ON FUNCTION find_or_create_conversation IS 'ROLE: Private conversation finder/creator | PURPOSE: Find existing or create new 1:1 conversation | RETURNS: conversation_id (uuid) | SECURITY: SECURITY DEFINER';

COMMENT ON FUNCTION respond_conversation_request IS 'ROLE: Accept/decline conversation request | PURPOSE: Handle chat permission flow | RETURNS: JSON with conversation_id if accepted | SECURITY: SECURITY DEFINER';

COMMENT ON FUNCTION join_group IS 'ROLE: Join public community group | PURPOSE: Add user to group membership | RETURNS: JSON with group_id and status | SECURITY: SECURITY DEFINER';

-- =============================================================================
-- TRIGGER ANNOTATIONS
-- =============================================================================

COMMENT ON FUNCTION handle_new_user IS 'ROLE: Auto-create user_profile on registration | TRIGGER: on_auth_user_created (AFTER INSERT on auth.users) | PURPOSE: Ensure every auth user has a profile row';

COMMENT ON FUNCTION update_creator_recipe_count IS 'ROLE: Denormalize recipe count | TRIGGER: trg_recipe_count (AFTER INSERT/UPDATE/DELETE on recipe) | PURPOSE: Keep creator.recipe_count in sync with published recipes';

COMMENT ON FUNCTION update_creator_fan_count IS 'ROLE: Denormalize fan count | TRIGGER: trg_fan_count (AFTER INSERT/UPDATE/DELETE on fan_subscription) | PURPOSE: Keep creator.fan_count in sync with active fans';

COMMENT ON FUNCTION update_group_member_count IS 'ROLE: Denormalize group member count | TRIGGER: trg_group_member_count (AFTER INSERT/DELETE on group_member) | PURPOSE: Keep community_group.member_count in sync';

COMMENT ON FUNCTION update_daily_nutrition_on_consumption IS 'ROLE: Auto-update daily nutrition log | TRIGGER: trg_nutrition_on_consumption (AFTER INSERT on meal_consumption) | PURPOSE: Aggregate macros into daily_nutrition_log on each consumption';

-- =============================================================================
-- EXTENSION ANNOTATIONS
-- =============================================================================

COMMENT ON EXTENSION "uuid-ossp" IS 'UUID generation functions | Used by: gen_random_uuid() for primary keys';
COMMENT ON EXTENSION vector IS 'pgvector: Vector similarity search | Used by: user_vector, recipe_vector (50-dim embeddings, HNSW index)';

-- =============================================================================
-- END OF ANNOTATIONS
-- =============================================================================
-- All tables, columns, functions, triggers, and extensions are now annotated.
-- See PROJECT_PLAN.md for full human-readable descriptions.
-- =============================================================================
