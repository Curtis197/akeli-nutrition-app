# AKELI - Row Level Security (RLS) Policy Registry

> **Source of truth** for ALL RLS policies in the Akeli database.
> Every policy is listed here with its table, operation, condition, and migration source.
> 
> **Last updated**: 2026-04-13
> **Total tables with RLS**: 50+
> **Total policies**: 80+

---

## 📋 How to Read This Document

| Column | Meaning |
|--------|---------|
| Table | Database table name |
| Policy Name | Name of the RLS policy |
| Operation | SELECT, INSERT, UPDATE, DELETE, or ALL |
| Condition | The SQL expression that must evaluate to true |
| Migration | Source migration file |
| Notes | Additional context (which Edge Function requires it, etc.) |

---

## 🔓 PUBLIC READ TABLES (No Auth Required)

These tables are fully readable by anyone (authenticated or not):

| Table | Policy Name | Operation | Condition | Migration |
|-------|------------|-----------|-----------|-----------|
| `food_region` | public reads food_region | SELECT | `true` | 20260301000001 |
| `ingredient_category` | public reads ingredient_category | SELECT | `true` | 20260301000001 |
| `measurement_unit` | public reads measurement_unit | SELECT | `true` | 20260301000001 |
| `tag` | public reads tag | SELECT | `true` | 20260301000001 |
| `ingredient` | public reads ingredient | SELECT | `true` | 20260301000001 |
| `recipe_macro` | public reads recipe_macro | SELECT | `true` | 20260301000001 |
| `recipe_ingredient` | public reads recipe_ingredient | SELECT | `true` | 20260301000001 |
| `recipe_tag` | public reads recipe_tag | SELECT | `true` | 20260301000001 |
| `recipe_image` | public reads recipe_image | SELECT | `true` | 20260301000001 |
| `recipe_vector` | public reads recipe_vector | SELECT | `true` | 20260301000001 |
| `creator` | public reads creator | SELECT | `true` | 20260301000001 |
| `recipe_comment` | public reads recipe_comment | SELECT | `true` | 20260301000001 |

---

## 👤 USER PROFILE & AUTH

### `user_profile`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| user reads own profile | SELECT | `auth.uid() = id` | 20260301000001 | Full profile read |
| user updates own profile | UPDATE | `auth.uid() = id` | 20260301000001 | Profile edits |
| public reads minimal profile | SELECT | `true` | 20260301000001 | Community features (username, avatar only) |

### `user_health_profile`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only user_health_profile | ALL | `auth.uid() = user_id` | 20260301000001 | SELECT, INSERT, UPDATE, DELETE |

### `user_goal`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only user_goal | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `user_dietary_restriction`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only user_dietary_restriction | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `user_cuisine_preference`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only user_cuisine_preference | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `weight_log`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only weight_log | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `user_vector`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only user_vector | ALL | `auth.uid() = user_id` | 20260301000001 | Computed by Python service |

---

## 👨‍🍳 CREATOR

### `creator`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| public reads creator | SELECT | `true` | 20260301000001 | Public profiles |
| owner manages creator | ALL | `auth.uid() = user_id` | 20260301000001 | Creator profile management |
| service updates creator | UPDATE | `auth.role() = 'service_role'` | 20260302000002 | stripe-webhook sets `stripe_charges_enabled` |

### `creator_balance`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| creator reads own creator_balance | SELECT | `creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())` | 20260301000001 | Dashboard earnings |

### `creator_revenue_log`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| creator reads own creator_revenue_log | SELECT | `creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())` | 20260301000001 | Revenue history |

### `creator_payout`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| creator reads own payouts | SELECT | `creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())` | 20260302000001 | Payout history |
| service inserts creator_payout | INSERT | `auth.role() = 'service_role'` | 20260302000001 | stripe-webhook creates payouts |

### `payout`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| creator reads own payout | SELECT | `creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())` | 20260301000001 | Legacy payout table |

---

## 🍳 RECIPES

### `recipe`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| public reads published recipe | SELECT | `is_published = true` | 20260301000001 | Feed, search, detail page |
| creator manages own recipe | ALL | `creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())` | 20260301000001 | Create, edit, delete, unpublish |

### `recipe_step` (CURRENT - 20260314000001)
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| recipe_step_select_published | SELECT | `EXISTS (SELECT 1 FROM recipe r WHERE r.id = recipe_step.recipe_id AND r.status = 'published')` | 20260314000001 | ⚠️ **POTENTIAL BUG**: references `r.status` but `recipe` table has `is_published` boolean, not `status` column |
| recipe_step_mutate_creator | ALL | `EXISTS (SELECT 1 FROM recipe r WHERE r.id = recipe_step.recipe_id AND r.creator_id = auth.uid())` | 20260314000001 | ⚠️ **POTENTIAL BUG**: same issue - `r.creator_id = auth.uid()` should be via creator table |

**⚠️ CRITICAL NOTE on `recipe_step` policies**: The `recipe_step_mutate_creator` policy checks `r.creator_id = auth.uid()`, but `creator_id` on `recipe` is a UUID referencing the `creator` table, NOT the `user_profile` table. The correct check should be:
```sql
EXISTS (
  SELECT 1 FROM recipe r
  JOIN creator c ON r.creator_id = c.id
  WHERE r.id = recipe_step.recipe_id
    AND c.user_id = auth.uid()
)
```
This needs to be verified and fixed.

### `recipe_step` (OBSOLETE - 20260302000003)
*Superseded by 20260314000001. Policies from this migration are no longer active.*
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| public reads recipe_step | SELECT | `true` | 20260302000003 | OBSOLETE |
| creator manages recipe_step | ALL | via creator.user_id | 20260302000003 | OBSOLETE |

### `recipe_macro`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| public reads recipe_macro | SELECT | `true` | 20260301000001 | Nutrition data visible for all recipes |
| creator manages recipe_macro | ALL | via recipe → creator.user_id | 20260301000001 | Edit own recipe macros |

### `recipe_like`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner manages recipe_like | ALL | `auth.uid() = user_id` | 20260301000001 | Like/unlike |
| public count reads recipe_like | SELECT | `true` | 20260301000001 | Like count display |

### `recipe_save`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| recipe_save_owner | ALL | `user_id = auth.uid()` | 20260314000001 | Bookmark/unbookmark |

### `recipe_comment`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| public reads recipe_comment | SELECT | `true` | 20260301000001 | Comments visible on all recipes |
| owner manages recipe_comment | ALL | `auth.uid() = user_id` | 20260301000001 | Write/edit/delete own comments |

### `recipe_impression`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| recipe_impression_insert_auth | INSERT | `user_id = auth.uid()` | 20260314000001 | Track card views |
| recipe_impression_select_creator | SELECT | via recipe.creator_id = auth.uid() | 20260314000001 | Creator analytics |

### `recipe_open`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| recipe_open_insert_auth | INSERT | `user_id = auth.uid()` | 20260314000001 | Track recipe opens |
| recipe_open_update_owner | UPDATE | `user_id = auth.uid()` | 20260314000001 | Update closed_at, session_duration |
| recipe_open_select_creator | SELECT | via recipe.creator_id = auth.uid() | 20260314000001 | Creator analytics |

---

## 📅 MEAL PLANNING

### `meal_plan`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only meal_plan | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `meal_plan_entry`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only via plan meal_plan_entry | ALL | `meal_plan_id IN (SELECT id FROM meal_plan WHERE user_id = auth.uid())` | 20260301000001 | Via parent meal_plan |

### `meal_consumption`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner reads own meal_consumption | SELECT | `auth.uid() = user_id` | 20260301000001 | Consumption history |
| system inserts meal_consumption | INSERT | `auth.uid() = user_id` | 20260301000001 | User marks meals as consumed |

### `shopping_list`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only shopping_list | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `shopping_list_item`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner via list shopping_list_item | ALL | `shopping_list_id IN (SELECT id FROM shopping_list WHERE user_id = auth.uid())` | 20260301000001 | Via parent shopping_list |

### `meal_reminder`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only meal_reminder | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `daily_nutrition_log`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only daily_nutrition_log | ALL | `auth.uid() = user_id` | 20260301000001 | |

---

## 🌟 FAN MODE

### `fan_subscription`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner reads own fan_subscription | SELECT | `auth.uid() = user_id` | 20260301000001 | User sees own subscriptions |
| creator reads own fans fan_subscription | SELECT | `creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())` | 20260301000001 | Creator sees who fans them |
| owner manages fan_subscription | INSERT | `auth.uid() = user_id` | 20260301000001 | Activate new fan |
| owner updates fan_subscription | UPDATE | `auth.uid() = user_id` | 20260302000002 | **ADDED BY FIX** - activate-fan-mode, cancel-fan-mode need this |

### `fan_subscription_history`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner reads own fan_subscription_history | SELECT | `auth.uid() = user_id` | 20260301000001 | History view |
| owner inserts fan_subscription_history | INSERT | `auth.uid() = user_id` | 20260302000002 | **ADDED BY FIX** - Edge Functions log history |

### `fan_external_recipe_counter`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner reads own fan_external_recipe_counter | SELECT | `auth.uid() = user_id` | 20260301000001 | Check remaining allowance |
| owner inserts fan_external_recipe_counter | INSERT | `auth.uid() = user_id` | 20260302000002 | **ADDED BY FIX** - log-meal-consumption needs this |
| owner updates fan_external_recipe_counter | UPDATE | `auth.uid() = user_id` | 20260302000002 | **ADDED BY FIX** - increment counter |

---

## 💬 COMMUNITY & CHAT

### `community_group`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| public reads public groups | SELECT | `is_public = true` | 20260301000001 | Discover groups |
| member reads private groups | SELECT | `id IN (SELECT group_id FROM group_member WHERE user_id = auth.uid())` | 20260301000001 | Private group access |

### `group_member`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| member reads own membership | SELECT | `auth.uid() = user_id` | 20260301000001 | |

### `conversation`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| *(No policies defined)* | | | 20260301000001 | RLS enabled but no policies. Access controlled via `conversation_participant` |

### `conversation_participant`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| participant only conversation_participant | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `chat_message`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| participant reads chat_message | SELECT | conversation_id via participant OR group_id via group_member | 20260301000001 | 1:1 or group chat |
| participant sends chat_message | INSERT | `auth.uid() = sender_id` AND (conversation_id via participant OR group_id via group_member) | 20260301000001 | Must be participant to send |

### `conversation_request`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| participant reads conversation_request | ALL | `auth.uid() = from_user_id OR auth.uid() = to_user_id` | 20260301000001 | Both parties see request |

---

## 🔔 NOTIFICATIONS

### `notification`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only notification | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `push_token`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only push_token | ALL | `auth.uid() = user_id` | 20260301000001 | |

---

## 🤖 AI ASSISTANT

### `ai_conversation`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only ai_conversation | ALL | `auth.uid() = user_id` | 20260301000001 | |

### `ai_message`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner via conversation ai_message | SELECT | `conversation_id IN (SELECT id FROM ai_conversation WHERE user_id = auth.uid())` | 20260301000001 | Via parent conversation |
| owner inserts ai_message | INSERT | `conversation_id IN (SELECT id FROM ai_conversation WHERE user_id = auth.uid())` | 20260301000001 | |

---

## 💳 SUBSCRIPTIONS

### `subscription`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner only subscription | ALL | `auth.uid() = user_id` | 20260301000001 | **MODIFIED BY 20260302000001**: status constraint changed from `('active', 'cancelled', 'past_due', 'trialing')` to `('active', 'cancelled')` |

---

## 📝 SUPPORT & REFERRALS

### `support_message`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner reads own support_message | SELECT | `user_id = auth.uid()` | 20260301000001 | |
| authenticated inserts support_message | INSERT | `auth.uid() IS NOT NULL` | 20260301000001 | Any authenticated user |

### `referral`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| owner reads own referral | ALL | `auth.uid() = referrer_id` | 20260301000001 | Referrer only (referred_id has no policy) |

---

## 📊 SUMMARY BY OPERATION TYPE

### SELECT Policies (Read Access)
| Access Level | Tables |
|-------------|--------|
| Public (anyone) | food_region, ingredient_category, measurement_unit, tag, ingredient, recipe_macro, recipe_ingredient, recipe_tag, recipe_image, recipe_vector, creator, recipe_comment |
| Published only | recipe (is_published = true), recipe_step (via recipe.status = 'published') |
| Owner only | user_profile (full), user_health_profile, user_goal, user_dietary_restriction, user_cuisine_preference, weight_log, user_vector, meal_plan, meal_plan_entry, shopping_list, daily_nutrition_log, meal_reminder, fan_subscription, fan_subscription_history, fan_external_recipe_counter, community_group (public/member), group_member, conversation_participant, notification, push_token, ai_conversation, subscription, support_message, referral, recipe_save |
| Creator analytics | recipe_impression, recipe_open (for creator's own recipes) |
| Creator revenue | creator_revenue_log, creator_balance, creator_payout, payout (for creator's own) |
| Creator fans | fan_subscription (creator sees their fans) |
| Via parent | ai_message (via ai_conversation), shopping_list_item (via shopping_list), meal_plan_entry (via meal_plan), chat_message (via conversation_participant or group_member) |

### INSERT Policies (Write Access)
| Access Level | Tables |
|-------------|--------|
| Owner only | fan_subscription, fan_subscription_history, fan_external_recipe_counter, meal_consumption, recipe_save, recipe_impression, recipe_open, conversation_request, ai_message, support_message, chat_message, creator_payout (service_role only) |

### UPDATE Policies (Modify Access)
| Access Level | Tables |
|-------------|--------|
| Owner only | user_profile, fan_subscription, fan_external_recipe_counter, recipe_open, conversation_participant |
| Service role only | creator (stripe_charges_enabled) |

### DELETE Policies
| Access Level | Tables |
|-------------|--------|
| Owner only | Implicit via ALL policies on owner-only tables |

---

## ⚠️ KNOWN ISSUES & POTENTIAL BUGS

### 1. `recipe_step` policy references non-existent column
**Policy**: `recipe_step_select_published`  
**Issue**: Uses `r.status = 'published'` but `recipe` table has `is_published` boolean, not `status` column  
**Migration**: 20260314000001  
**Impact**: SELECT on recipe_step will always return 0 rows (policy never matches)  
**Fix**: Change to `r.is_published = true`

### 2. `recipe_step` policy incorrect creator_id check
**Policy**: `recipe_step_mutate_creator`  
**Issue**: Uses `r.creator_id = auth.uid()` but `creator_id` is a UUID referencing `creator` table, NOT `user_profile`  
**Migration**: 20260314000001  
**Impact**: Creators cannot manage their own recipe steps (policy never matches)  
**Fix**: Join through creator table:
```sql
EXISTS (
  SELECT 1 FROM recipe r
  JOIN creator c ON r.creator_id = c.id
  WHERE r.id = recipe_step.recipe_id
    AND c.user_id = auth.uid()
)
```

### 3. `conversation` table has no policies
**Issue**: RLS enabled but NO policies defined  
**Migration**: 20260301000001  
**Impact**: No one can read/write conversations directly (access controlled via conversation_participant)  
**Status**: This may be intentional, but needs verification

### 4. `referral` table missing policy for `referred_id`
**Issue**: Only `referrer_id` has a policy. The referred user cannot see their referral record.  
**Migration**: 20260301000001  
**Impact**: Referred user has no access to their referral data  
**Fix**: Add policy: `auth.uid() = referred_id` for SELECT

---

## 📋 POLICIES ADDED BY FIX MIGRATION

The following policies were added by `20260302000002_fix_rls_policies.sql` because Edge Functions were failing:

| Table | Policy | Required By |
|-------|--------|-------------|
| `fan_subscription` | owner updates fan_subscription | activate-fan-mode, cancel-fan-mode |
| `fan_subscription_history` | owner inserts fan_subscription_history | activate-fan-mode, cancel-fan-mode |
| `fan_external_recipe_counter` | owner inserts fan_external_recipe_counter | log-meal-consumption |
| `fan_external_recipe_counter` | owner updates fan_external_recipe_counter | log-meal-consumption |
| `creator` | service updates creator | stripe-webhook |

---

## 🔧 HOW TO ADD/UPDATE RLS POLICIES

When modifying the database schema:

1. **Create a new migration file** in `supabase/migrations/`
2. **Add the policy** with `CREATE POLICY "policy_name" ON table_name FOR operation USING (condition)`
3. **Update this document** (`rls-list.md`) with:
   - Table name
   - Policy name
   - Operation
   - Condition
   - Migration source
   - Notes (which Edge Function requires it, etc.)
4. **Test the policy** with both JWT user and service_role
5. **Verify no conflicts** with existing policies

### Template:
```sql
-- Migration: YYYYMMDDXXXXXX_description.sql

ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

CREATE POLICY "policy_name" ON table_name
  FOR operation  -- SELECT, INSERT, UPDATE, DELETE, or ALL
  USING (condition_for_read)  -- for SELECT/ALL
  WITH CHECK (condition_for_write);  -- for INSERT/UPDATE/ALL
```

---

**Last verified**: 2026-04-13  
**Maintainer**: Akeli Dev Team  
**Next review**: Before each production deployment
