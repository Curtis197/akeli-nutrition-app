# AKELI - Edge Functions Documentation

> **Source of truth** for ALL Supabase Edge Functions in the Akeli backend.
> 
> **Last updated**: 2026-04-13  
> **Total functions**: 16  
> **Shared library**: `_shared/` folder

---

## 📋 Function Registry

### User-Facing Functions (verify_jwt = true)
| Function | Purpose | Tables | External APIs | config.toml |
|----------|---------|--------|---------------|-------------|
| `activate-fan-mode` | Subscribe user to creator's Fan mode | subscription, creator, fan_subscription, fan_subscription_history | None | verify_jwt: true |
| `cancel-fan-mode` | Cancel Fan subscription | fan_subscription, fan_subscription_history | None | verify_jwt: true |
| `ai-assistant-chat` | AI nutrition assistant (Fast/Smart path) | ai_conversation, ai_message, user_health_profile, user_goal, meal_plan, daily_nutrition_log, recipe_like, shopping_list | OpenAI GPT-4o-mini | verify_jwt: true |
| `complete-onboarding` | Complete user onboarding flow | user_health_profile, user_goal, user_dietary_restriction, user_cuisine_preference, user_profile | Python Service (Railway) | verify_jwt: true |
| `create-checkout-session` | Stripe Checkout for creator payouts (web only) | creator, user_profile | Stripe API | verify_jwt: true |
| `generate-meal-plan` | Vectorized meal plan generation | meal_plan, meal_plan_entry (via RPC) | None | verify_jwt: true |
| `get-creator-dashboard` | Creator earnings dashboard | creator, creator_balance, creator_revenue_log, meal_consumption | None | verify_jwt: true |
| `log-meal-consumption` | Mark meal as consumed, enforce Fan limits | meal_plan_entry, recipe, meal_consumption, fan_subscription, fan_external_recipe_counter | None | verify_jwt: true |
| `toggle-recipe-like` | Toggle like/unlike on recipe | recipe_like | None | verify_jwt: true |
| `validate-store-purchase` | Validate Google Play / App Store purchase | subscription | Apple App Store, Google Play | verify_jwt: true |

### Internal/Cron Functions (verify_jwt = false)
| Function | Schedule | Purpose | Tables | External APIs | config.toml |
|----------|----------|---------|--------|---------------|-------------|
| `compute-monthly-revenue` | 1st of month 01:00 UTC | Compute creator revenue for previous month | creator, fan_subscription, meal_consumption, creator_revenue_log, creator_balance | None | verify_jwt: false |
| `process-fan-mode-transitions` | 1st of month 00:05 UTC | Activate/cancel Fan subscriptions | fan_subscription, fan_external_recipe_counter | None | verify_jwt: false |
| `send-meal-reminders` | Hourly (0 * * * *) | Send push notifications for meal reminders | meal_reminder | Internal call | verify_jwt: false |
| `send-push-notification` | Internal only | Send FCM push + insert notification | push_token, notification | Firebase Cloud Messaging | verify_jwt: false |
| `stripe-webhook` | Webhook | Handle Stripe events for creator payouts | creator_payout, creator | Stripe (HMAC verify) | verify_jwt: false |
| `translate-content` | Internal only | Translate content via Gemini (African languages) | None | Gemini API | verify_jwt: false |

---

## 🔧 Shared Library (`_shared/`)

### `cors.ts`
- **Purpose**: CORS headers for all edge functions
- **Functions**: `corsHeaders`, `handleCors()`
- **Usage**: Every edge function must call `handleCors()` for OPTIONS preflight

### `response.ts`
- **Purpose**: Consistent response helpers
- **Functions**: `ok(data)`, `err(message)`, `unauthorized()`, `serverError(e)`
- **Response format**: `{ success: boolean, data?: any, error?: string }`

### `supabase.ts`
- **Purpose**: Supabase client creation with auth handling
- **Functions**:
  - `userClient(authHeader)`: Creates client with JWT (RLS enforced)
  - `serviceClient()`: Creates client with service role key (RLS bypassed)
  - `getAuthUser(req)`: Extracts and verifies user from JWT
- **Usage**: User-facing functions use `userClient()`, cron/webhook use `serviceClient()`

### `logger.ts`
- **Purpose**: Structured logging with emoji indicators
- **Functions**: `createLogger(functionName)` with `debug`, `info`, `warn`, `error`
- **Features**:
  - Request correlation (requestId)
  - User correlation (userId)
  - PII masking (email, tokens)
  - RLS/DB query helpers
- **Usage**: EVERY edge function must use this logger

---

## 📝 Function Details

### `activate-fan-mode`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | Subscribe user to a creator's Fan mode |

**Request**:
```json
POST /functions/v1/activate-fan-mode
{
  "creator_id": "uuid"
}
```

**Business Logic**:
1. Verify user has active subscription (Akeli premium)
2. Verify creator exists and is Fan-eligible (>= 30 recipes)
3. Verify user doesn't already have an active Fan
4. Create `fan_subscription` with status = 'pending'
5. Set `effective_from` to 1st of next month
6. Insert `fan_subscription_history` record
7. Return success with pending status

**Response**:
```json
{
  "success": true,
  "data": {
    "status": "pending",
    "effective_from": "2026-05-01"
  }
}
```

**Error Cases**:
- 401: No valid JWT
- 400: No active subscription, creator not eligible, already a Fan
- 500: Database error, RLS violation

---

### `cancel-fan-mode`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | Cancel current Fan subscription |

**Request**:
```json
POST /functions/v1/cancel-fan-mode
```

**Business Logic**:
1. Verify user has active/pending Fan
2. Update `fan_subscription` status to 'cancelled'
3. Set `effective_until` to 1st of next month
4. Insert `fan_subscription_history` record
5. Return success

**Response**:
```json
{
  "success": true,
  "data": {
    "status": "cancelled",
    "effective_until": "2026-06-01"
  }
}
```

---

### `ai-assistant-chat`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | AI nutrition assistant with hybrid Fast/Smart path |

**Architecture**:
- **Fast Path**: Pattern matching for simple greetings/courtesies (no API call)
- **Smart Path**: Intent analysis → fetch user data modules → build context → call GPT-4o-mini

**Rate Limit**: 30 messages/minute per user

**Data Modules Fetched (Smart Path)**:
- `user_health_profile`: Height, weight, activity level
- `user_goal`: Current goal type
- `meal_plan`: Today's planned meals
- `nutrition_stats`: Today's consumed calories
- `recipe_like`: User's liked recipes
- `shopping_list`: Current shopping list

**Response**:
```json
{
  "success": true,
  "data": {
    "message": "AI response text",
    "path": "fast|smart",
    "tokens_used": 123,
    "intent": "meal_plan_question"
  }
}
```

---

### `complete-onboarding`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | Complete user onboarding with health, goals, preferences |

**Request**:
```json
POST /functions/v1/complete-onboarding
{
  "health_profile": {
    "sex": "male|female|other",
    "birth_date": "1990-01-01",
    "height_cm": 175.0,
    "weight_kg": 70.0,
    "target_weight_kg": 65.0,
    "activity_level": "sedentary|light|moderate|active|very_active"
  },
  "goal_type": "weight_loss|muscle_gain|maintenance|health|performance",
  "dietary_restrictions": ["vegetarian", "gluten_free"],
  "cuisine_preferences": [
    { "region": "west_africa", "preference_score": 0.9 }
  ]
}
```

**Business Logic**:
1. Validate all input fields
2. Insert `user_health_profile` (upsert if exists)
3. Insert `user_goal`
4. Insert `user_dietary_restriction` (multiple, ON CONFLICT DO NOTHING)
5. Insert `user_cuisine_preference` (multiple)
6. Update `user_profile.onboarding_done = true`
7. Trigger Python vector computation (non-blocking, via HTTP call to Railway)
8. Return success

**Response**:
```json
{
  "success": true,
  "data": {
    "profile_updated": true,
    "vector_computation_triggered": true
  }
}
```

---

### `create-checkout-session`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | Create Stripe Checkout for creator payouts (web only, NOT in-app) |

**Note**: This is ADMIN-ONLY. Users subscribe via Google Play / App Store (see `validate-store-purchase`). Stripe is exclusively for creator payouts.

**Business Logic**:
1. Verify user is admin
2. Verify creator has Stripe account connected
3. Create Stripe Checkout session with Connect transfer
4. Return checkout URL

---

### `generate-meal-plan`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | Generate vectorized meal plan using pgvector cosine similarity |

**Delegates to**: `generate_meal_plan()` RPC function

**Business Logic**:
1. Fetch user vector from `user_vector`
2. Fetch active Fan creator (if any) for boost
3. Call `generate_meal_plan` RPC
4. RPC: Deactivates previous active plans
5. RPC: Creates new meal_plan + meal_plan_entry rows
6. RPC: Selects best recipes via cosine similarity, avoids duplicates
7. Returns plan structured by day + meal type

---

### `get-creator-dashboard`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | GET |
| **Purpose** | Creator earnings dashboard |

**Returns**:
- Revenue history (from `creator_revenue_log`)
- Current balance (from `creator_balance`)
- Current month consumptions (from `meal_consumption`)
- Projection: floor(consumptions / 90) × 1 EUR
- Fan count (active subscriptions)
- Fan revenue: active_fans × 1 EUR

**Revenue Model**:
- Fan mode: 1 EUR per active fan per month
- Consumption: floor(consumptions / 90) × 1 EUR
- Example: 450 consumptions = floor(450/90) × 1€ = 5€

---

### `log-meal-consumption`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | Mark meal plan entry as consumed, enforce Fan mode limits |

**Request**:
```json
POST /functions/v1/log-meal-consumption
{
  "meal_plan_entry_id": "uuid"
}
```

**Business Logic**:
1. Verify meal_plan_entry exists and belongs to user
2. Verify not already consumed
3. If user has active Fan:
   - Check `fan_external_recipe_counter` for current month
   - If external recipes >= 9, reject (max 9 external/month)
   - If recipe is from Fan creator, don't count
   - If recipe is external, increment counter
4. Update `meal_plan_entry.is_consumed = true`
5. Insert `meal_consumption` record
6. Return success

**Error Cases**:
- 400: Already consumed, external limit reached
- 404: Meal plan entry not found
- 500: Database error, RLS violation

---

### `toggle-recipe-like`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | Toggle like/unlike on a recipe |

**Request**:
```json
POST /functions/v1/toggle-recipe-like
{
  "recipe_id": "uuid"
}
```

**Business Logic**:
1. Check if `recipe_like` exists for (user_id, recipe_id)
2. If exists: DELETE (unlike)
3. If not exists: INSERT (like)
4. Return current like status

**Response**:
```json
{
  "success": true,
  "data": {
    "liked": true,
    "like_count": 42
  }
}
```

---

### `validate-store-purchase`
| Property | Value |
|----------|-------|
| **Auth** | JWT required (verify_jwt: true) |
| **Method** | POST |
| **Purpose** | Validate in-app purchase from Google Play or App Store |

**Platforms**:
- **iOS**: Legacy receipt validation (production + sandbox fallback)
- **Android**: OAuth2 JWT signing + Android Publisher API

**Business Logic**:
1. Determine platform (android/ios)
2. Validate receipt with respective store API
3. If valid: Update `subscription` table with store data
4. Set status = 'active', store tokens, expiry dates
5. If invalid: Return error with reason

**Env Vars Required**:
- `APPLE_SHARED_SECRET`
- `GOOGLE_SERVICE_ACCOUNT_JSON`
- `ANDROID_PACKAGE_NAME`

---

### `compute-monthly-revenue` (Cron)
| Property | Value |
|----------|-------|
| **Auth** | None (internal cron, verify_jwt: false) |
| **Schedule** | 1st of month 01:00 UTC |
| **Purpose** | Compute all creators' revenue for previous month |

**Business Logic**:
1. Identify previous month (e.g., if March, compute for February)
2. For each creator:
   a. Count active fans in previous month → fan_revenue = fans × 1€
   b. Count meal_consumptions in previous month → consumption_revenue = floor(consumptions / 90) × 1€
   c. Total = fan_revenue + consumption_revenue
   d. Upsert to `creator_revenue_log`
   e. Increment `creator_balance.balance` via RPC
3. Return summary of computed revenues

---

### `process-fan-mode-transitions` (Cron)
| Property | Value |
|----------|-------|
| **Auth** | None (internal cron, verify_jwt: false) |
| **Schedule** | 1st of month 00:05 UTC |
| **Purpose** | Activate pending Fan subs, cancel expired ones |

**Business Logic**:
1. Find `fan_subscription` where `effective_from <= today` and status = 'pending'
   → Update status to 'active'
2. Find `fan_subscription` where `effective_until <= today` and status = 'active'
   → Update status to 'cancelled'
3. Initialize `fan_external_recipe_counter` for new month (for active fans)
4. Insert history records for all transitions

---

### `send-meal-reminders` (Cron)
| Property | Value |
|----------|-------|
| **Auth** | None (internal cron, verify_jwt: false) |
| **Schedule** | Hourly (0 * * * *) |
| **Purpose** | Send push notifications for meal reminders |

**Business Logic**:
1. Query `meal_reminder` where:
   - `is_active = true`
   - `reminder_time` matches current UTC time ± 5 min
   - Current day of week is in `days_of_week` array
2. For each matching reminder:
   - Call `send-push-notification` function internally
3. Return count of sent reminders

---

### `send-push-notification` (Internal)
| Property | Value |
|----------|-------|
| **Auth** | None (internal only, verify_jwt: false) |
| **Purpose** | Send FCM push notification |

**Request** (internal):
```json
{
  "user_id": "uuid",
  "title": "Reminder",
  "body": "It's time for lunch!",
  "data": { "type": "meal_reminder" }
}
```

**Business Logic**:
1. Fetch user's latest `push_token`
2. Send FCM push notification
3. Insert record into `notification` table
4. Return success/failure

---

### `stripe-webhook` (Webhook)
| Property | Value |
|----------|-------|
| **Auth** | None (webhook, verify_jwt: false) |
| **Purpose** | Handle Stripe events for creator payouts |

**Events Handled**:
- `payment_intent.succeeded`: Mark payout as succeeded
- `payment_intent.failed`: Mark payout as failed
- `transfer.created`: Log transfer to creator revenue
- `account.updated`: Update creator KYC status

**Security**: Verifies HMAC signature with `STRIPE_WEBHOOK_SECRET`

---

### `translate-content` (Internal)
| Property | Value |
|----------|-------|
| **Auth** | None (internal, verify_jwt: false) |
| **Purpose** | Translate culinary content via Gemini |

**Languages Supported**:
- French (fr)
- English (en)
- Spanish (es)
- Portuguese (pt)
- Wolof (wo)
- Bambara (bm)
- Lingala (ln)
- Arabic (ar)

**API**: Gemini 1.5 flash (not OpenAI, for African language support)

---

## 🔐 Environment Variables

See `.env.example` in `supabase/functions/` for the complete list:

| Variable | Required By | Purpose |
|----------|-------------|---------|
| `SUPABASE_URL` | ALL | Supabase project URL |
| `SUPABASE_ANON_KEY` | ALL | Anon key for userClient |
| `SUPABASE_SERVICE_ROLE_KEY` | ALL | Service key for serviceClient |
| `OPENAI_API_KEY` | ai-assistant-chat | GPT-4o-mini for AI assistant |
| `GEMINI_API_KEY` | translate-content | Gemini for African language translation |
| `FCM_SERVER_KEY` | send-push-notification | Firebase Cloud Messaging |
| `APPLE_SHARED_SECRET` | validate-store-purchase | App Store receipt validation |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | validate-store-purchase | Google Play subscription validation |
| `ANDROID_PACKAGE_NAME` | validate-store-purchase | Android app package identifier |
| `STRIPE_SECRET_KEY` | create-checkout-session | Creator payouts (web only) |
| `STRIPE_WEBHOOK_SECRET` | stripe-webhook | Webhook signature verification |
| `PYTHON_SERVICE_URL` | complete-onboarding | Vector computation service on Railway |

---

## 🚨 KNOWN ISSUES

### None Currently Identified

All functions follow consistent patterns with:
- Proper JWT verification (where required)
- Comprehensive error handling
- Structured logging
- RLS compliance (via userClient)
- CORS support (via handleCors)

---

## 📋 ADDING A NEW EDGE FUNCTION

1. **Create folder**: `supabase/functions/function-name/`
2. **Create file**: `index.ts` with header comment (see template below)
3. **Add to config.toml**: Set `verify_jwt = true` (user-facing) or `false` (internal)
4. **Update this document**: Add function to registry and details section
5. **Update `.env.example`**: If new env vars needed
6. **Test locally**: `supabase functions serve --env-file .env`
7. **Deploy**: `supabase functions deploy function-name`

### Template:
```typescript
// =============================================================================
// AKELI Edge Function: function-name
// Path: supabase/functions/function-name/index.ts
// Author: [Your Name]
// Date: YYYY-MM-DD
// 
// Purpose: What this function does
// Auth: verify_jwt = true/false (see config.toml)
// 
// Request: POST/GET with body { ... }
// Response: { success: true, data: ... } or { error: "message" }
// 
// Tables: table1, table2 (read/write)
// RLS: userClient (RLS enforced) or serviceClient (RLS bypassed)
// 
// External APIs: Stripe, OpenAI, FCM, etc. (if any)
// 
// Error handling: What errors are caught and how they're handled
// =============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createLogger } from '../_shared/logger.ts';
import { handleCors, corsHeaders } from '../_shared/cors.ts';
import { userClient, serviceClient } from '../_shared/supabase.ts';
import { ok, err, unauthorized, serverError } from '../_shared/response.ts';

serve(async (req: Request) => {
  const logger = createLogger('function-name');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  
  logger.info(`⚡ Function: function-name invoked [${requestId}] | method: ${req.method}`);
  
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return handleCors();
  }
  
  try {
    // Auth verification (if required)
    const supabase = userClient(req);
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      logger.error(`❌ Function: Auth failed [${requestId}]`, { error: authError?.message });
      return unauthorized();
    }
    logger.setUserId(user.id);
    logger.info(`👤 Function: User authenticated [${requestId}]`);
    
    // Parse request body
    const body = await req.json();
    logger.debug(`📝 Function: Request body parsed [${requestId}]`, { keys: Object.keys(body) });
    
    // === BUSINESS LOGIC HERE ===
    
    logger.info(`✅ Function: function-name completed successfully [${requestId}]`);
    return ok({ result: 'success' });
  } catch (error) {
    logger.error(`💥 Function: Unhandled error [${requestId}]`, { error: error.message });
    return serverError(error);
  }
});
```

---

**Last verified**: 2026-04-13  
**Maintainer**: Akeli Dev Team  
**Next review**: After every new function or modification
