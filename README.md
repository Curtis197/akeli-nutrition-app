# Akeli — African Nutrition & Recipes App

> A Flutter mobile application dedicated to African cuisine, nutrition tracking, meal planning, and creator monetization.

---

## Table of Contents

- [Vision](#vision)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Build Progress](#build-progress)
- [What Has Been Built](#what-has-been-built)
- [Remaining Work](#remaining-work)
- [Project Structure](#project-structure)
- [Setup Guide](#setup-guide)
- [Environment Variables](#environment-variables)

---

## Vision

Akeli is a mobile app that allows users to:
- Discover and save African recipes with full nutritional data
- Track their daily nutrition intake
- Generate AI-powered weekly meal plans
- Follow creators and access exclusive content via a "Fan Mode" subscription (€3/month)
- Get a multilingual AI nutrition assistant (French + African languages)

**Target users:** African diaspora and African continent users interested in healthy eating rooted in their culinary heritage.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x (Dart) — Material 3 |
| State management | Riverpod 2.x (code generation) |
| Navigation | GoRouter 14.x |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| AI Assistant | OpenAI GPT-4o |
| Translation | Google Gemini (African languages) |
| Vectorization | Python FastAPI on Railway |
| Payments | Stripe (subscriptions €3/month) |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Fonts | Outfit (display) + Poppins (body) — Google Fonts |
| Charts | fl_chart |

---

## Architecture

```
User (Flutter app)
      │
      ├── Supabase Auth (email/phone/social)
      ├── Supabase Database (PostgreSQL + RLS)
      ├── Supabase Storage (recipe images, avatars)
      ├── Supabase Edge Functions (Deno/TypeScript)
      │         ├── AI chat (OpenAI)
      │         ├── Meal plan generation
      │         ├── Fan Mode activation/cancellation
      │         ├── Stripe checkout & webhooks
      │         ├── Push notifications (FCM)
      │         ├── CRON jobs (reminders, revenue compute)
      │         └── Content translation (Gemini)
      └── Python Service (Railway)
                └── Recipe vectorization for semantic search
```

**Key design decisions:**
- No Firebase — Supabase handles everything (auth, DB, storage, realtime)
- Feature-first folder structure in Flutter (`lib/features/`)
- Row Level Security (RLS) on all Supabase tables
- Riverpod providers scoped by domain (auth, recipes, nutrition, fan mode...)

---

## Build Progress

### Phase 1 — Database ✅ COMPLETE
- 45 PostgreSQL tables with full RLS policies
- 9 RPC functions for complex queries
- Reference seed data (ingredients, nutritional values, African recipe categories)
- 2 migration files ready to run on Supabase

### Phase 2 — Backend ✅ COMPLETE
- 14 Supabase Edge Functions deployed (TypeScript/Deno)
- Python FastAPI vectorization service (Railway-ready)
- `supabase/config.toml` configured

### Phase 3 — Flutter App ✅ COMPLETE
- 30 Dart files covering all features
- Full navigation with GoRouter + auth guards
- All screens, providers, models, and shared widgets built

### Phase 4 — Configuration & Deployment ⏳ TODO
- Environment variables to fill in
- Supabase migrations to run
- Edge Functions to deploy
- Python service to deploy on Railway
- Stripe products to create
- Android/iOS app identity to configure

---

## What Has Been Built

### Database (`supabase/migrations/`)

| File | Content |
|------|---------|
| `20260301000001_initial_schema.sql` | 45 tables, RLS policies, triggers, indexes |
| `20260301000002_rpc_functions.sql` | 9 RPC functions (nutrition totals, feed ranking, creator stats...) |
| `supabase/seed/01_reference_data.sql` | Ingredients, categories, nutritional reference data |

### Edge Functions (`supabase/functions/`)

| Function | Trigger | Role |
|----------|---------|------|
| `complete-onboarding` | HTTP POST | Save user profile + goals after signup |
| `generate-meal-plan` | HTTP POST | GPT-4o weekly meal plan generation |
| `ai-assistant-chat` | HTTP POST | Nutritional AI chat (OpenAI) |
| `toggle-recipe-like` | HTTP POST | Like/unlike a recipe |
| `log-meal-consumption` | HTTP POST | Log a meal and update nutrition stats |
| `activate-fan-mode` | HTTP POST | Create Stripe subscription + unlock creator content |
| `cancel-fan-mode` | HTTP POST | Cancel subscription + revoke access |
| `process-fan-mode-transitions` | CRON | Nightly check of expired subscriptions |
| `create-checkout-session` | HTTP POST | Generate Stripe checkout URL |
| `stripe-webhook` | HTTP POST | Handle Stripe payment events |
| `get-creator-dashboard` | HTTP GET | Creator revenue + subscriber stats |
| `compute-monthly-revenue` | CRON | Monthly revenue aggregation |
| `send-meal-reminders` | CRON | Daily push notification reminders |
| `send-push-notification` | HTTP POST | Generic FCM push notification sender |
| `translate-content` | HTTP POST | Translate content to African languages (Gemini) |

### Python Service (`python/`)

| File | Role |
|------|------|
| `main.py` | FastAPI app entry point |
| `engine/vectorization.py` | Recipe embedding with OpenAI text-embedding-3-small |
| `engine/database.py` | Supabase connection + pgvector upsert |
| `requirements.txt` | Dependencies |
| `railway.toml` | Railway deployment config |

### Flutter App (`lib/`)

#### Core
| File | Role |
|------|------|
| `main.dart` | App entry, Supabase init, Riverpod root |
| `core/theme.dart` | Material 3 theme (Outfit + Poppins, African color palette) |
| `core/router.dart` | GoRouter with auth guards and redirect logic |
| `core/supabase_client.dart` | Supabase singleton client |

#### Features (Screens)
| Screen | File | Description |
|--------|------|-------------|
| Auth | `features/auth/auth_page.dart` | Login / Sign up |
| Onboarding | `features/auth/onboarding_page.dart` | Goals, dietary preferences, region |
| Feed | `features/recipes/feed_page.dart` | Recipe discovery with search and filters |
| Recipe Detail | `features/recipes/recipe_detail_page.dart` | Full recipe with ingredients, steps, macros |
| Meal Planner | `features/meal_planner/meal_planner_page.dart` | AI-generated weekly meal plan |
| Shopping List | `features/meal_planner/shopping_list_page.dart` | Auto-generated grocery list |
| Nutrition | `features/nutrition/nutrition_page.dart` | Daily macro tracking + fl_chart charts |
| Community | `features/community/community_page.dart` | Creator feed, followers, social |
| Fan Mode | `features/fan_mode/fan_mode_page.dart` | Subscribe to creators (€3/month) |
| Subscription | `features/subscription/subscription_page.dart` | Stripe checkout flow |
| AI Assistant | `features/ai_assistant/ai_chat_page.dart` | GPT-4o nutrition chat |
| Profile | `features/profile/profile_page.dart` | User profile, stats, settings |

#### Providers (State Management)
| Provider | File | Manages |
|----------|------|---------|
| AuthProvider | `providers/auth_provider.dart` | Auth state, login, signup, logout |
| UserProfileProvider | `providers/user_profile_provider.dart` | Profile, goals, preferences |
| RecipeProvider | `providers/recipe_provider.dart` | Recipe list, search, likes |
| MealPlanProvider | `providers/meal_plan_provider.dart` | Meal plans, shopping list |
| NutritionProvider | `providers/nutrition_provider.dart` | Daily logs, macro totals |
| FanModeProvider | `providers/fan_mode_provider.dart` | Subscriptions, creator access |

#### Models
| Model | File |
|-------|------|
| UserProfile | `shared/models/user_profile.dart` |
| Recipe | `shared/models/recipe.dart` |
| MealPlan | `shared/models/meal_plan.dart` |
| Creator | `shared/models/creator.dart` |

#### Shared Widgets
| Widget | File | Description |
|--------|------|-------------|
| MainShell | `shared/widgets/main_shell.dart` | Bottom navigation bar (5 tabs) |
| RecipeCard | `shared/widgets/recipe_card.dart` | Recipe thumbnail with macros |
| MacroCard | `shared/widgets/macro_card.dart` | Protein / Carbs / Fat display card |
| EmptyState | `shared/widgets/empty_state.dart` | Reusable empty list placeholder |

---

## Remaining Work

### Priority 1 — Blocking (must do before any test)

- [ ] **Fill in `.env`** with real Supabase URL and anon key
- [ ] **Add Internet permission** to `android/app/src/main/AndroidManifest.xml`
- [ ] **Fix Android app identity** in `android/app/build.gradle.kts`:
  - `namespace` → `app.akeli.nutrition`
  - `applicationId` → `app.akeli.nutrition`
- [ ] **Add placeholder assets** — `assets/images/` and `assets/icons/` are empty but referenced in `pubspec.yaml`
- [ ] **Add `url_launcher` to `pubspec.yaml`** — needed for Stripe checkout URL opening

### Priority 2 — Supabase Deployment

- [ ] Run migrations on the Supabase project:
  ```bash
  supabase db push
  ```
- [ ] Run seed data:
  ```bash
  supabase db reset --db-url <your-db-url>
  ```
- [ ] Deploy all 14 Edge Functions:
  ```bash
  supabase functions deploy
  ```
- [ ] Set Edge Function secrets:
  ```bash
  supabase secrets set --env-file supabase/functions/.env
  ```
- [ ] Configure Supabase Storage buckets: `recipes`, `avatars`, `creator-content`

### Priority 3 — Python / Railway Deployment

- [ ] Create Railway project linked to GitHub repo
- [ ] Set environment variables in Railway Dashboard (see `python/.env.example`)
- [ ] Note deployed URL and add to `supabase/functions/.env` as `PYTHON_SERVICE_URL`

### Priority 4 — Stripe Configuration

- [ ] Create product "Akeli Premium" at €3/month in Stripe Dashboard
- [ ] Copy `price_xxx` ID into `STRIPE_PRICE_ID` env var
- [ ] Add webhook endpoint pointing to `create-checkout-session` Edge Function URL
- [ ] Copy `whsec_xxx` webhook secret into `STRIPE_WEBHOOK_SECRET`

### Priority 5 — iOS Configuration

- [ ] Set bundle ID in `ios/Runner/Info.plist`: `app.akeli.nutrition`
- [ ] Add camera / photo library permission strings to `Info.plist`
- [ ] Configure signing in Xcode

### Priority 6 — Polish (pre-launch)

- [ ] App icon (all sizes — Android mipmap + iOS AppIcon)
- [ ] Splash screen
- [ ] Deep linking for Stripe return URL
- [ ] Error boundary / crash reporting (Sentry or similar)

---

## Project Structure

```
akeli-nutrition-app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── router.dart
│   │   ├── supabase_client.dart
│   │   └── theme.dart
│   ├── features/
│   │   ├── ai_assistant/
│   │   ├── auth/
│   │   ├── community/
│   │   ├── fan_mode/
│   │   ├── meal_planner/
│   │   ├── nutrition/
│   │   ├── profile/
│   │   ├── recipes/
│   │   └── subscription/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── fan_mode_provider.dart
│   │   ├── meal_plan_provider.dart
│   │   ├── nutrition_provider.dart
│   │   ├── recipe_provider.dart
│   │   └── user_profile_provider.dart
│   └── shared/
│       ├── models/
│       │   ├── creator.dart
│       │   ├── meal_plan.dart
│       │   ├── recipe.dart
│       │   └── user_profile.dart
│       └── widgets/
│           ├── empty_state.dart
│           ├── macro_card.dart
│           ├── main_shell.dart
│           └── recipe_card.dart
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 20260301000001_initial_schema.sql
│   │   └── 20260301000002_rpc_functions.sql
│   ├── seed/
│   │   └── 01_reference_data.sql
│   └── functions/
│       ├── _shared/
│       ├── activate-fan-mode/
│       ├── ai-assistant-chat/
│       ├── cancel-fan-mode/
│       ├── complete-onboarding/
│       ├── compute-monthly-revenue/
│       ├── create-checkout-session/
│       ├── generate-meal-plan/
│       ├── get-creator-dashboard/
│       ├── log-meal-consumption/
│       ├── process-fan-mode-transitions/
│       ├── send-meal-reminders/
│       ├── send-push-notification/
│       ├── stripe-webhook/
│       ├── toggle-recipe-like/
│       └── translate-content/
├── python/
│   ├── main.py
│   ├── engine/
│   │   ├── vectorization.py
│   │   └── database.py
│   ├── requirements.txt
│   └── railway.toml
├── assets/
│   ├── images/         ← to populate
│   └── icons/          ← to populate
├── .env                ← fill with real keys (gitignored)
└── pubspec.yaml
```

---

## Setup Guide

### 1. Clone and install

```bash
git clone <repo-url>
cd akeli-nutrition-app
flutter pub get
```

### 2. Configure environment

```bash
# Flutter env
cp .env .env.local         # already exists, fill in values

# Edge Functions
cp supabase/functions/.env.example supabase/functions/.env

# Python service
cp python/.env.example python/.env
```

Edit each file with your real credentials.

### 3. Supabase setup

```bash
# Install Supabase CLI if needed
npm install -g supabase

# Link to your project
supabase link --project-ref <your-project-ref>

# Push migrations
supabase db push

# Deploy Edge Functions
supabase functions deploy

# Set secrets
supabase secrets set --env-file supabase/functions/.env
```

### 4. Run the app

```bash
flutter run
```

---

## Environment Variables

### Flutter — `.env`

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### Edge Functions — `supabase/functions/.env`

```env
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
FCM_SERVER_KEY=...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRICE_ID=price_...
PYTHON_SERVICE_URL=https://akeli-engine.railway.app
```

### Python service — `python/.env`

```env
DATABASE_URL=postgresql://...
BATCH_SECRET=your-random-secret
PORT=8000
```

---

## Git Branches

| Branch | Purpose |
|--------|---------|
| `main` | Stable, production-ready |
| `claude/akeli-nutrition-v1-eDrPn` | Current development branch (V1 build) |

---

*Last updated: March 2026 — V1 build in progress*
