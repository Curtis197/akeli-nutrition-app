# Beauty Mode Database Schema Documentation

## Overview
This document describes the complete database schema for AKELI's Beauty mode, which implements a **usage-based remuneration model** (1€/n_cares) different from Nutrition's fixed model (1/90€ per meal), and includes **Fan Mode** exclusive features.

---

## 📊 Tables Summary

| Table | Purpose | Key Difference from Nutrition |
|-------|---------|-------------------------------|
| `beauty_plans` | Subscription/program templates | Dynamic care count vs fixed 90 meals |
| `beauty_entries` | Individual care sessions | Variable pricing per care |
| `beauty_logs` | User tracking & completion | Triggers creator payment on completion |
| `beauty_analytics` | Creator performance metrics | Includes fan mode revenue streams |
| `beauty_recipes` | DIY formulations & remedies | Premium recipe sales |
| `fan_subscriptions` | Exclusive creator support | **New**: Monthly recurring revenue |
| `creator_payouts` | Unified remuneration tracking | Multi-mode earnings breakdown |

---

## 💰 Remuneration Models Comparison

### Nutrition Mode (Fixed)
```
Total Budget: 90€ per month
Per Meal: 1/90€ = ~0.011€
Calculation: Fixed regardless of user completions
```

### Beauty Mode (Usage-Based)
```
Base Price: 1€ minimum per care entry
Creator Earnings: SUM(1€ / n_cares_in_plan) × completions
Example: 30-care plan → 1€/30 = 0.033€ per completion
User completes 25 cares → Creator earns 25 × 0.033€ = 0.83€
```

### Fan Mode (Recurring)
```
Tiers: Supporter (5€), VIP (15€), Ultra Fan (50€)
Revenue Split: 80% creator / 20% platform
Monthly recurring based on active subscriptions
```

---

## 🔑 Key Tables Explained

### 1. beauty_plans
**Purpose**: Templates for beauty care programs (like meal plans but flexible)

**Key Fields**:
- `base_price_cents`: Minimum 100¢ (1€) - sets total plan value
- `total_cares`: Number of care sessions (user-defined, not fixed)
- `is_premium`: Fan mode exclusive flag
- `cultural_origin`: Array for cultural tagging (e.g., ['west_african', 'yoruba'])

**Business Logic**:
```sql
-- Creator sets 15€ plan with 30 cares
-- Each care completion = 15€ / 30 = 0.50€ for creator
INSERT INTO beauty_plans (
  base_price_cents, -- 1500
  total_cares,      -- 30
  ...
) VALUES (...);
```

### 2. beauty_entries
**Purpose**: Individual care steps within a plan

**Remuneration Field**:
- `price_cents`: Derived from plan (base_price / total_cares)
- `is_bonus`: Fan mode exclusive content (extra earnings)

**Care Types**:
- cleansing, treatment, mask, oil_application, massage, styling, protection

### 3. beauty_logs ⭐ (Critical for Payments)
**Purpose**: Tracks user completion → triggers creator payment

**Payment Workflow**:
```sql
-- When user marks care as "completed":
UPDATE beauty_logs 
SET status = 'completed', 
    completed_date = NOW()
WHERE id = ...;

-- Trigger automatically:
-- 1. Sets remuneration_credits_cents = entry.price_cents
-- 2. Sets remuneration_status = 'pending'
-- 3. Creator can request payout when threshold reached
```

**Tracking Features**:
- Mood before/after (wellness impact)
- Skin/hair condition JSONB (progress metrics)
- Before/after photos (visual progress)

### 4. beauty_analytics
**Purpose**: Aggregated creator dashboard data

**Fan Mode Metrics**:
- `fan_mode_subscribers`: Count of active fans
- `fan_mode_exclusive_content_views`: Engagement tracking
- `fan_mode_bonus_earnings_cents`: Extra revenue from bonus content

**Payout Tracking**:
- `pending_payout_cents`: Available to withdraw
- `paid_out_cents`: Historical earnings

### 5. beauty_recipes
**Purpose**: Traditional DIY formulations (monetizable)

**Monetization**:
- `is_premium`: Paid recipes (one-time purchase)
- `price_cents`: Recipe price (e.g., 299¢ = 2.99€)
- `times_made`: Community adoption metric

**Cultural Preservation**:
- `elder_wisdom_notes`: Traditional knowledge field
- `traditional_use_history`: Historical context

### 6. fan_subscriptions 🌟 (New Revenue Stream)
**Purpose**: Monthly recurring support for creators

**Tiers**:
```sql
'supporter' -- Min 5€/month
'vip'       -- Mid tier (10-20€)
'ultra_fan' -- Premium (50€+)
```

**Benefits Tracking**:
- `exclusive_content_unlocks`: Paywall bypass count
- `direct_messages_count`: Creator access metric

### 7. creator_payouts
**Purpose**: Unified earnings across all modes

**Earnings Breakdown**:
```sql
nutrition_meal_earnings_cents  -- Fixed 1/90€ model
beauty_care_earnings_cents     -- Usage-based 1€/n_cares
fan_mode_earnings_cents        -- Recurring subscriptions
recipe_sales_earnings_cents    -- One-time recipe purchases
bonus_earnings_cents           -- Platform bonuses/promotions
```

**Payout Methods**:
- bank_transfer, paypal, stripe, mobile_money (Africa-focused)

---

## ⚙️ Automated Functions & Triggers

### 1. update_plan_subscriber_count()
**Trigger**: After INSERT/DELETE on `beauty_logs`
**Purpose**: Auto-update plan popularity metrics

### 2. calculate_beauty_earnings()
**Usage**: Creator dashboard query
**Returns**: Total cares, revenue, and net earnings (after 20% platform fee)

```sql
SELECT * FROM calculate_beauty_earnings(
  'creator-uuid', 
  '2024-01-01', 
  '2024-01-31'
);
```

### 3. process_beauty_remuneration() ⭐
**Trigger**: Before UPDATE on `beauty_logs`
**Logic**: When status changes to 'completed':
1. Fetches entry price
2. Sets `remuneration_credits_cents`
3. Marks as 'pending' payout

**Code**:
```sql
IF NEW.status = 'completed' AND OLD.status != 'completed' 
   AND NEW.remuneration_credits_cents = 0 THEN
    SELECT price_cents INTO v_entry_price
    FROM beauty_entries WHERE id = NEW.entry_id;
    
    NEW.remuneration_credits_cents := v_entry_price;
    NEW.remuneration_status := 'pending';
END IF;
```

---

## 🔒 Row Level Security (RLS) Policies

### Data Access Rules:
| Table | User Can... | Creator Can... |
|-------|-------------|----------------|
| `beauty_plans` | View active plans | Full CRUD on own |
| `beauty_entries` | View active entries | Full CRUD on own |
| `beauty_logs` | View/update own logs | View logs for their plans |
| `beauty_analytics` | ❌ No access | View own analytics |
| `beauty_recipes` | View active recipes | Full CRUD on own |
| `fan_subscriptions` | View own subs | View their subscribers |
| `creator_payouts` | ❌ No access | View own payouts |

**Security Features**:
- All tables have RLS enabled
- Encrypted payment info in `payout_account_info` (JSONB)
- User data isolation enforced at database level

---

## 📈 Sample Queries

### Creator Dashboard: Monthly Earnings
```sql
SELECT 
  SUM(nutrition_meal_earnings_cents) as nutrition_revenue,
  SUM(beauty_care_earnings_cents) as beauty_revenue,
  SUM(fan_mode_earnings_cents) as fan_revenue,
  SUM(net_earnings_cents) as total_net
FROM creator_payouts
WHERE creator_id = auth.uid()
  AND period_start >= DATE_TRUNC('month', NOW());
```

### User Progress: This Month's Completions
```sql
SELECT 
  COUNT(*) FILTER (WHERE status = 'completed') as completed_cares,
  COUNT(*) FILTER (WHERE status = 'scheduled') as upcoming_cares,
  AVG(satisfaction_rating) as avg_satisfaction
FROM beauty_logs
WHERE user_id = auth.uid()
  AND scheduled_date >= DATE_TRUNC('month', NOW());
```

### Fan Mode: Top Creators by Subscribers
```sql
SELECT 
  creator_id,
  COUNT(*) as subscriber_count,
  SUM(monthly_price_cents) as monthly_revenue
FROM fan_subscriptions
WHERE status = 'active'
GROUP BY creator_id
ORDER BY subscriber_count DESC
LIMIT 10;
```

---

## 🚀 Deployment Steps

### 1. Run Migration
```bash
# In Supabase Dashboard → SQL Editor
# Copy contents of: supabase/migrations/20240102000001_create_beauty_mode_schema.sql
# Click "Run"
```

### 2. Verify Tables Created
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'beauty_%';
```

### 3. Test Sample Data
```sql
-- Should return 1 row
SELECT * FROM beauty_plans LIMIT 1;

-- Should return 1 row
SELECT * FROM beauty_entries LIMIT 1;
```

### 4. Configure Storage Buckets (Optional)
For before/after photos:
```sql
-- Create bucket via Supabase Dashboard → Storage
-- Name: beauty-progress-photos
-- Public: false (user-specific access)
```

---

## 📱 Flutter Integration Points

### Drift Tables to Create:
```dart
// lib/features/beauty/data/database/beauty_database.dart
class BeautyPlans extends Table { ... }
class BeautyEntries extends Table { ... }
class BeautyLogs extends Table { ... }
class BeautyAnalytics extends Table { ... }
class BeautyRecipes extends Table { ... }
class FanSubscriptions extends Table { ... }
class CreatorPayouts extends Table { ... }
```

### Services to Implement:
1. `BeautyPlanService` - Fetch/create plans
2. `BeautyLogService` - Track completions (triggers payment)
3. `FanSubscriptionService` - Manage subscriptions
4. `CreatorPayoutService` - Request withdrawals

### State Providers (Riverpod):
```dart
final currentBeautyPlanProvider = StateProvider<BeautyPlan?>();
final beautyLogsProvider = StreamProvider<List<BeautyLog>>();
final fanSubscriptionProvider = FutureProvider<FanSubscription?>();
final creatorEarningsProvider = FutureProvider<CreatorEarnings>();
```

---

## ✅ Checklist for V1 Launch

- [ ] Run SQL migration in Supabase
- [ ] Create Drift tables in Flutter
- [ ] Implement BeautyLogService with completion tracking
- [ ] Build Creator Dashboard UI (analytics + payouts)
- [ ] Add Fan Mode subscription flow (Stripe integration)
- [ ] Test remuneration trigger (complete care → check pending payout)
- [ ] Set up storage bucket for progress photos
- [ ] Configure RLS policies (test with different user roles)
- [ ] Add mobile money payout option (Africa-focused)
- [ ] Create sample beauty plans with creators

---

## 🎯 Success Metrics

| Metric | Target (Month 1) | Measurement |
|--------|------------------|-------------|
| Beauty plans created | 50+ | COUNT(beauty_plans) |
| Care completions/day | 500+ | COUNT(beauty_logs WHERE status='completed') |
| Fan mode adoption | 10% of users | COUNT(fan_subscriptions) / total_users |
| Creator retention | 80% | Creators with >10 completions |
| Average creator earnings | 50€/month | AVG(creator_payouts.net_earnings_cents) |

---

## 📞 Support & Questions

For schema modifications or clarification:
- Review `/workspace/supabase/migrations/20240102000001_create_beauty_mode_schema.sql`
- Check RLS policies before deploying to production
- Test remuneration logic with sample data before launch
