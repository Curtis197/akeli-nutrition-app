# Architecture Analysis — MVP Backend

> **Purpose:** Document the current dual-backend architecture, identify why it creates problems, and establish the rationale for V1 consolidation.

---

## Current Architecture Overview

```
Mobile App (Flutter)
│
├── Firebase Auth ──────────────────────────► Google/Apple/Email sign-in
│     │
│     └── JWT token ──────────────────────► Used to call Supabase edge functions
│
├── Cloud Firestore ─────────────────────► (limited use — mostly Firebase Auth user doc)
│
├── Firebase Storage ────────────────────► Image/media uploads
│
└── Supabase
      ├── PostgreSQL (81 tables) ──────► Primary data store
      ├── Edge Functions (25) ─────────► Business logic / AI calls
      └── Realtime Client ─────────────► Real-time subscriptions
```

### Initialization (lib/main.dart)
```dart
await initFirebase();           // Firebase initialized
await SupaFlow.initialize();    // Supabase initialized
```

Both backends initialize on every app start. There is no fallback — if either fails, the app breaks.

---

## The Dual-Auth Problem

### What was intended
FlutterFlow's default template uses Firebase Auth. Supabase was added for its PostgreSQL database and edge functions. The intent was: Firebase handles identity, Supabase handles data.

### What actually happens

1. User authenticates via Firebase Auth (`lib/auth/firebase_auth/`)
2. A Firebase JWT token is extracted (`lib/auth/firebase_auth/auth_util.dart` lines 40–44)
3. That Firebase JWT is passed as a Bearer token to Supabase edge function calls
4. Supabase edge functions validate the token — but Supabase expects **its own JWT**, not Firebase's

This creates a fragile bridge. If Firebase and Supabase JWT secrets fall out of sync, all edge function calls fail silently or return auth errors.

### Auth files (Firebase only)
```
lib/auth/
├── auth_manager.dart
├── base_auth_user_provider.dart
└── firebase_auth/
    ├── auth_util.dart          # Firebase JWT extraction
    ├── email_auth.dart
    ├── google_auth.dart
    ├── apple_auth.dart
    ├── github_auth.dart
    ├── anonymous_auth.dart
    └── firebase_auth_manager.dart
```

There is **no Supabase Auth integration** in the auth layer. Supabase Auth is initialized but unused.

### Auth stream architecture
```dart
// lib/main.dart
afroHealthFirebaseUserStream()   // Firebase auth stream
jwtTokenStream.listen((_) {})   // Empty listener — does nothing
```

The JWT stream listener is present but empty — it was started and abandoned.

---

## Environment Configuration Issues

**File:** `assets/environment_values/environment.json` (loaded in `lib/environment_values.dart`)

The environment file has **three sets** of API credentials with no documented distinction:

```json
{
  "apiUrl":  "...",    "ApiKey":  "...",
  "apiUrl1": "...",    "ApiKey1": "...",
  "apiUrl2": "...",    "ApiKey2": "...",
  "GeminiApiKey": "..."
}
```

Likely mapping (unconfirmed):
- `apiUrl` / `ApiKey` — Primary Supabase project
- `apiUrl1` / `ApiKey1` — Secondary/test Supabase project or different environment
- `apiUrl2` / `ApiKey2` — Third endpoint (possibly the AI backend)

**Problem:** No documentation exists. Rotating one key requires knowing which services use which key.

---

## Edge Function Catalogue (25 calls)

All defined in `lib/backend/api_requests/api_calls.dart`.

### Conversation & Chat

| Class | Endpoint | Purpose | Issues |
|-------|----------|---------|--------|
| `SearchAPrivateConversationCall` | L68 | Find private conversation by participants | Duplicate of SearchAConversation? |
| `SearchAConversationCall` | L911 | Search conversations | Overlaps with above |
| `SearchAGroupByNameCall` | L130 | Search groups by name | May overlap with SearchAGroup |
| `SearchAGroupCall` | L188 | Search groups | May overlap with above |
| `FindOrCreateTheConversationCall` | L960 | Find or create conversation | — |
| `CheckIfAUserIsInAGroupCall` | L1009 | Group membership check | — |
| `ChatNotiificationCall` | L1225 | Send chat notification | **Typo in class name** |
| `RequestBodyCall` | L1270 | Conversation request | — |
| `ConversationRequestCall` | L1308 | Conversation request | Overlaps with above? |
| `ConversationAcceptedCall` | L1354 | Accept conversation | — |

### Meals & Nutrition

| Class | Endpoint | Purpose | Issues |
|-------|----------|---------|--------|
| `AddANewMealCall` | L283 | Add meal to plan | — |
| `CustomMealCall` | L388 | Create custom meal | Dead param: `imagetest` |
| `MealIngredientsScaleCall` | L486 | Scale meal ingredients | **Test endpoint: `receipe_scaling_test`** |
| `CustomSnackCall` | L757 | Add custom snack | — |
| `MealPlanScaleCall` | L806 | Scale entire meal plan | — |
| `MealPlanShoppingListCall` | L851 | Generate shopping list from meal plan | — |
| `PersonalMealPlanCall` | L686 | Generate personalized meal plan | Duplicate of below? |
| `PersonalMealPlanNoMealCall` | L1537 | Generate meal plan (no base meal) | Near-duplicate of above |

### Diet & Nutrition Analysis

| Class | Endpoint | Purpose | Issues |
|-------|----------|---------|--------|
| `DietPlanCall` | L619 | Generate diet plan | — |
| `ShoppingListCall` | L553 | Generate shopping list | **Test endpoint: `shopping_list_test`**, dead params |

### Recipe

| Class | Endpoint | Purpose | Issues |
|-------|----------|---------|--------|
| `UpdatedRecipeResearchCall` | L1099 | Search/filter recipes | — |
| `RecommandedReceipeCall` | L1177 | Get recommended recipes | **Double typo in name** |
| `ImageRecognitionCall` | L1404 | Identify food from image | — |

### Community & Referrals

| Class | Endpoint | Purpose | Issues |
|-------|----------|---------|--------|
| `CreateAReferralCall` | L1054 | Create referral | — |

### AI

| Class | Endpoint | Purpose | Issues |
|-------|----------|---------|--------|
| `AIassistantCall` | L1618 | AI chat assistant (Gemini wrapper) | — |

---

## Supabase Database — 81 Tables by Domain

### Users & Identity (9 tables)
- `users` — core user record
- `user_preferences` — app preferences
- `user_health_parameter` — health metrics (weight, height, age, activity)
- `user_allergies` — dietary restrictions
- `user_goal` — user health goals
- `user_track` — general tracking
- `daily_user_track` — daily tracking record
- `weekly_user_track` — weekly tracking record
- `updated_weight` — weight update history

### Meals & Meal Planning (8 tables)
- `meal` — meal definition
- `meal_ingredients` — meal ingredient join
- `meal_consumed` — consumption records
- `meal_notifications` — meal reminders
- `meal_plan` — meal plan definitions
- `round_type` — portion rounding types
- `unit` — measurement units
- `ingredient_category` — ingredient categories

### Recipes (10 tables)
- `receipe` — recipe definition (**typo in name**)
- `receipe_macro` — recipe macros (**typo**)
- `receipe_tags` — recipe tag join (**typo**)
- `receipe_difficulty` — difficulty rating (**typo**)
- `receipe_comments` — comments on recipes (**typo**)
- `receipe_likes` — recipe likes (**typo**)
- `receipe_image` — recipe images (**typo**)
- `temporary_receipe` — draft recipes (**typo**)
- `recomanded_receipe` — recommended recipes (**double typo**)
- `ingredients` — ingredient master list

### Conversations & Chat (8 tables)
- `conversation` — conversation record
- `chat_conversation` — chat-specific conversation
- `chat_message` — individual messages
- `private_conversation` — direct messages
- `conversation_participant` — participant join
- `conversation_demand` — conversation requests
- `conversation_group` — group definitions
- `direct_conversations_with_other_user` — direct message view

### AI (3 tables)
- `ai_chat_message` — AI conversation messages
- `ai_assistant_action` — AI action log
- `ai_plan_feedback` — user feedback on AI plans

### Shopping (4 tables)
- `shopping_list` — shopping list
- `shopping_ingredient` — item on shopping list
- `shopping_list_summary` — list summary view
- `shopping_list_totals` — totals view

### Health Tracking (4 tables)
- `weight_graph_data` — weight over time for graph
- `diet_questionnary` — diet intake questionnaire
- `diet_type` — diet type definitions
- `eating_style` — eating style categories

### Lookup / Reference (7 tables)
- `tags` — recipe/content tags
- `food_region` — African food regions
- `activity_level` — activity level definitions
- `difficulty` — difficulty level definitions
- `ingredients` — master ingredient list
- `ingredient_category` — ingredient categories

### Notifications (6 tables)
- `notifications` — notification records
- `notification_preferences` — user notification settings
- `notification_templates` — notification content templates
- `notification_triggers` — notification trigger conditions
- `chat_notifications` — chat-specific notifications
- `demand_notifications` — friend/group request notifications

### Creator / Community (8 tables)
- `creator` — creator profiles
- `creator_comment` — comments by creators
- `creator_diet_specialty` — creator dietary expertise
- `creator_food_specialty` — creator food expertise
- `creator_image` — creator profile images
- `creator_likes` — creator like counts
- `comment_like` — likes on comments

### Referrals (3 tables)
- `referral` — referral records
- `referral_view` — referral analytics view
- `get_referral_revenue` — revenue from referrals view

### Support (1 table)
- `contact_messages` — support contact form submissions

**Total: 81 tables** — well-structured, but naming (`receipe`, `recomanded`) is inconsistent.

---

## V1 Recommendation: Consolidate to Supabase

### Why drop Firebase (except push notifications)

| Concern | Firebase | Supabase |
|---------|----------|----------|
| Primary database | Underused (Firestore mostly for auth user doc) | Main data store (81 tables) |
| Authentication | Currently sole auth provider | Auth system exists but unused |
| Storage | Used for media | Has storage module available |
| Cost | Separate billing | Single billing |
| Complexity | Requires Firebase SDK + config | Already present |
| Edge functions | None | 25 functions already written |

### Migration plan (high level)
1. Enable Supabase Auth (Email, Google, Apple providers)
2. Migrate Firebase user records to Supabase `users` table
3. Replace `lib/auth/firebase_auth/` with Supabase auth flows
4. Replace Firebase Storage with Supabase Storage for new uploads
5. Remove Firebase SDK entirely from `pubspec.yaml` and `main.dart`
6. Simplify environment config to single `SUPABASE_URL` + `SUPABASE_ANON_KEY`

### What to keep from Firebase (optional)
- **Firebase Cloud Messaging (FCM)** — if push notifications are needed in V1, FCM remains the most reliable cross-platform solution. Supabase does not have built-in push notifications.

---

## Architecture Risks to Carry Into V1

| Risk | Description | V1 Mitigation |
|------|-------------|---------------|
| JWT mismatch | Firebase JWT used for Supabase calls | Move to Supabase Auth |
| Dual billing | Two separate backend bills | Consolidate to Supabase |
| Undocumented API keys | 3 sets of URL+key with no docs | Document, reduce to 1 set |
| Test endpoints in prod | 2 edge functions call test endpoints | Promote to prod or recreate |
| No error handling in init | main() has no try/catch | Add error handling + fallback UI |
