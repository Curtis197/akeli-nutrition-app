# AKELI - Supabase Backend

> **This folder is the SINGLE SOURCE OF TRUTH for the entire Akeli backend.**
> 
> **Every backend change MUST update the documentation in this folder.**
> See `SUPABASE_DOCUMENTATION_STANDARDS.md` for the rules.

---

## 📁 Folder Structure

```
supabase/
├── config.toml                           # Edge function JWT verification config
├── database_schema.sql                   # Complete schema snapshot (current state)
├── rls-list.md                           # RLS policy registry (ALL policies listed)
├── SUPABASE_DOCUMENTATION_STANDARDS.md   # Documentation rules and process
├── EDGE_FUNCTIONS.md                     # Edge function registry and details
│
├── migrations/                           # Migration files (APPEND ONLY)
│   ├── 20260301000001_initial_schema.sql      # Base schema (49+ tables, RLS, triggers)
│   ├── 20260301000002_rpc_functions.sql       # 9 RPC functions (recommendations, search, meal plan)
│   ├── 20260302000001_store_payment_arch.sql  # Store payments (Google Play / App Store)
│   ├── 20260302000002_fix_rls_policies.sql    # Fix missing RLS policies (5 policies added)
│   ├── 20260302000003_add_recipe_steps.sql    # recipe_step table (OBSOLETE, superseded)
│   └── 20260314000001_recipe_tracking_schema.sql # Recipe tracking (recipe_step, save, impression, open)
│
├── seed/
│   └── 01_reference_data.sql             # Reference data (regions, categories, units, tags)
│
├── functions/                            # Supabase Edge Functions (16 total)
│   ├── .env.example                      # Required environment variables
│   ├── _shared/                          # Shared library (logger, cors, response, supabase)
│   ├── _examples/                        # Templates and examples
│   ├── activate-fan-mode/                # Subscribe to creator's Fan mode
│   ├── cancel-fan-mode/                  # Cancel Fan subscription
│   ├── ai-assistant-chat/                # AI nutrition assistant (GPT-4o-mini)
│   ├── complete-onboarding/              # Complete user onboarding
│   ├── create-checkout-session/          # Stripe Checkout (creator payouts, web only)
│   ├── compute-monthly-revenue/          # Cron: Monthly creator revenue computation
│   ├── generate-meal-plan/               # Vectorized meal plan generation
│   ├── get-creator-dashboard/            # Creator earnings dashboard
│   ├── log-meal-consumption/             # Mark meal consumed, enforce Fan limits
│   ├── process-fan-mode-transitions/     # Cron: Activate/cancel Fan subs
│   ├── send-meal-reminders/              # Cron: Push notifications for reminders
│   ├── send-push-notification/           # Internal: FCM push notifications
│   ├── stripe-webhook/                   # Webhook: Stripe events for payouts
│   ├── toggle-recipe-like/               # Toggle recipe like/unlike
│   ├── translate-content/                # Internal: Gemini translation (African languages)
│   └── validate-store-purchase/          # Validate Google Play / App Store purchase
│
└── .temp/                                # CLI cache (gitignored)
    └── cli-latest
```

---

## 📊 Database Overview

### Tables: 50+
| Category | Tables |
|----------|--------|
| Identity | user_profile, user_health_profile, user_goal, user_dietary_restriction, user_cuisine_preference, weight_log, user_vector |
| Creator | creator, creator_balance, creator_revenue_log, creator_payout |
| Recipes | recipe, recipe_step, recipe_macro, ingredient, recipe_ingredient, recipe_tag, recipe_image, recipe_like, recipe_save, recipe_comment, recipe_impression, recipe_open, recipe_vector, recipe_translation |
| Meal Planning | meal_plan, meal_plan_entry, meal_consumption, shopping_list, shopping_list_item, meal_reminder, daily_nutrition_log |
| Fan Mode | fan_subscription, fan_subscription_history, fan_external_recipe_counter |
| Community | community_group, conversation, conversation_participant, conversation_request, chat_message, group_member |
| AI | ai_conversation, ai_message |
| Notifications | notification, push_token |
| Commerce | subscription |
| Reference | food_region, ingredient_category, measurement_unit, tag, specialty |
| Other | support_message, referral, ingredient_submission, payout |

### RLS Policies: 80+
- See `rls-list.md` for the complete registry
- All tables have RLS enabled
- Policies cover: owner access, public read, creator access, service_role access

### RPC Functions: 9
- See `20260301000002_rpc_functions.sql` for definitions
- Callable via `.rpc()` from Flutter or Edge Functions
- Include: recommend_recipes, search_recipes, search_creators, get_creator_public_profile, generate_meal_plan, generate_shopping_list, find_or_create_conversation, respond_conversation_request, join_group

### Triggers: 7+
- `update_updated_at()`: Auto-update `updated_at` on tables with the column
- `handle_new_user()`: Create `user_profile` on auth.users insert
- `update_creator_recipe_count()`: Denormalized recipe count
- `update_creator_fan_count()`: Denormalized fan count
- `update_group_member_count()`: Denormalized member count
- `update_daily_nutrition_on_consumption()`: Auto-update nutrition log on consumption

### Extensions: 2
- `uuid-ossp`: UUID generation
- `vector` (pgvector): 50-dimension vectors for user and recipe embeddings

---

## 🚀 Quick Start

### Local Development

```bash
# Start local Supabase
supabase start

# Apply migrations
supabase db push

# Seed reference data
psql -h localhost -p 54322 -U postgres -d postgres -f supabase/seed/01_reference_data.sql

# Serve edge functions
supabase functions serve --env-file supabase/functions/.env

# Open Studio
supabase status
```

### Deploy to Production

```bash
# Link to project
supabase link --project-ref YOUR_PROJECT_REF

# Push migrations
supabase db push

# Deploy edge functions
cd supabase/functions
for dir in */; do
  if [ "$dir" != "_shared/" ] && [ "$dir" != "_examples/" ]; then
    supabase functions deploy ${dir%/}
  fi
done
```

---

## 🔐 Security

### Row Level Security (RLS)
- **ALL tables have RLS enabled**
- **See `rls-list.md`** for complete policy registry
- **Two client modes**:
  - `userClient(authHeader)`: JWT authenticated, RLS enforced
  - `serviceClient()`: Service role key, RLS bypassed (cron/webhooks only)

### Authentication
- User-facing functions require valid JWT (`verify_jwt = true`)
- Internal functions (cron/webhooks) bypass JWT (`verify_jwt = false`)
- See `config.toml` for per-function configuration

### Known Issues
- **`recipe_step` policies may be broken** - references `r.status` but table has `is_published` boolean
- **`recipe_step` creator check may be broken** - `r.creator_id = auth.uid()` but `creator_id` is creator UUID, not user UUID
- See `rls-list.md` → "Known Issues" section for details

---

## 📈 Architecture Decisions

### Revenue Model
- **Fan mode**: 1 EUR per active fan per month
- **Consumption**: floor(consumptions / 90) × 1 EUR (90 consumptions = 1€)
- **Computed monthly** by `compute-monthly-revenue` cron function

### Subscription Model
- **Users**: Subscribe via Google Play / App Store (NOT Stripe)
- **Creators**: Receive payouts via Stripe Connect
- **Stripe** is exclusively for creator payouts

### Vector Recommendations
- **pgvector** with 50-dimension vectors
- **HNSW index** for ~3ms cosine similarity queries
- **User vectors** computed by Python service on Railway
- **Recipe vectors** computed at publication time
- **Fan mode boost**: ×1.5 similarity for Fan creator's recipes

### AI Assistant
- **Hybrid architecture**: Fast path (pattern matching) + Smart path (GPT-4o-mini with context)
- **Rate limited**: 30 messages/minute per user
- **Context modules**: health profile, goals, meal plan, nutrition stats, liked recipes, shopping list

### Translation
- **Gemini 1.5 flash** (not OpenAI) for African language support
- **Languages**: Wolof, Bambara, Lingala, Arabic + French, English, Spanish, Portuguese

---

## 📚 Documentation

| Document | Purpose | Location |
|----------|---------|----------|
| RLS Policy Registry | ALL RLS policies listed | `rls-list.md` |
| Edge Function Registry | ALL edge functions documented | `EDGE_FUNCTIONS.md` |
| Documentation Standards | Rules for keeping docs updated | `SUPABASE_DOCUMENTATION_STANDARDS.md` |
| Schema Snapshot | Current state of all tables | `database_schema.sql` |
| Migration Files | Schema change history | `migrations/` folder |
| Seed Data | Reference data | `seed/01_reference_data.sql` |

---

## ⚠️ Important Notes

1. **Migrations are APPEND ONLY** - Never modify existing migration files once deployed
2. **RLS policies must be tested** with both JWT user and service_role
3. **Edge functions must use shared helpers** (`_shared/logger.ts`, `_shared/supabase.ts`, etc.)
4. **Environment variables** must be added to `.env.example` before use
5. **Documentation must be updated** with every change (see `SUPABASE_DOCUMENTATION_STANDARDS.md`)
6. **`recipe_step` policies may need fixing** - see known issues in `rls-list.md`

---

**Last updated**: 2026-04-13  
**Maintainer**: Akeli Dev Team  
**Principle**: This folder is the source of truth - always up to date.
