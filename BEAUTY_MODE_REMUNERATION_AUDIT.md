# Beauty Mode Remuneration & Database Audit

## ✅ Business Logic Verification

### 1. Fixed Subscription Model (Confirmed)
- **Price**: 3€/month fixed for ALL beauty users
- **Split**: 
  - 2€ → Platform
  - 1€ → Creator Economy (split between Pool & Direct)

### 2. Two Creator Revenue Streams

#### A. Standard Mode (Tokenized Pool)
- **Mechanism**: All standard subs contribute 1€ to a global pool
- **Distribution**: Creators share pool based on usage tokens
- **Formula**: `Creator Earnings = (Creator Tokens / Total Tokens) × Total Pool`
- **User Action**: Toggle care completion → Earns 1 token for their creator
- **Cost to User**: Fixed 3€ (no per-care charge)

#### B. Fan Mode (Direct Allocation)
- **Mechanism**: User selects ONE creator to support directly
- **Distribution**: 1€ goes 100% to chosen creator
- **Formula**: `Creator Earnings = Count(Active Fans) × 1€`
- **User Action**: Select creator in Fan Mode UI
- **Cost to User**: Fixed 3€ (same price, different allocation)

---

## 🗄️ Database Implementation Status

### New Migration File Created
**Path**: `/workspace/supabase/migrations/20240103000001_fix_beauty_remuneration_and_fan_mode.sql`

### Tables Created:
| Table | Purpose | Key Fields |
|-------|---------|------------|
| `beauty_plans` | Static plan definitions (3€) | `price_cents=300`, `creator_share_cents=100` |
| `user_beauty_subscriptions` | Track user active subs | `status`, `period_start/end` |
| `fan_allocations` | **Fan Mode Direct 1€** | `user_id`, `creator_id`, `amount_cents=100` |
| `beauty_care_logs` | **Standard Mode Tokens** | `creator_id`, `tokens_earned=1`, `completed_at` |
| `creator_monthly_payouts` | Calculated earnings snapshot | `pool_earnings`, `fan_earnings`, `total` |

### SQL Functions Implemented:

#### 1. `log_beauty_care(routine_creator_id, routine_ref_id)`
- **Purpose**: Called when user toggles "Care Completed" in Flutter app
- **Action**: Inserts row into `beauty_care_logs` with `tokens_earned=1`
- **Security**: `SECURITY DEFINER` (runs as admin to bypass RLS for insert)
- **Usage in Flutter**:
  ```dart
  await supabase.rpc('log_beauty_care', params: {
    'routine_creator_id': creatorId,
    'routine_ref_id': routineId,
  });
  ```

#### 2. `calculate_creator_payouts(target_month)`
- **Purpose**: Monthly cron job to calculate final earnings
- **Logic**:
  1. Counts total tokens in `beauty_care_logs` for the month
  2. Calculates each creator's % share of the pool
  3. Counts active `fan_allocations` for direct 1€ earnings
  4. Upserts result into `creator_monthly_payouts`
- **Trigger**: Run manually or via pg_cron at month-end

---

## 🔄 User Flow: Toggle Care Completion

### Scenario: Standard Mode User
1. User opens Beauty Mode → Views "Morning Routine" by Creator A
2. User completes routine → Toggles switch "Done"
3. Flutter calls `log_beauty_care(creatorId: A, routineId: 123)`
4. SQL inserts: `(user_id, creator_id=A, tokens=1, completed_at=NOW())`
5. **Result**: Creator A gets +1 token towards monthly pool share
6. **No immediate payment**: Accumulates for end-of-month calculation

### Scenario: Fan Mode User
1. User subscribes to Fan Mode → Selects Creator B as favorite
2. System creates `fan_allocations` row: `(user_id, creator_id=B, amount=100)`
3. User completes routines (optional, no financial impact on allocation)
4. **Result**: Creator B gets guaranteed 1€ from this user at month-end
5. **Calculation**: `COUNT(fan_allocations WHERE creator_id=B) × 100 cents`

---

## 🔐 Security & RLS Policies

| Table | Read Policy | Write Policy |
|-------|-------------|--------------|
| `beauty_care_logs` | User sees own; Creator sees their content | User can only log own care |
| `fan_allocations` | User sees own; Creator sees incoming fans | System/Admin manages (via RPC) |
| `creator_monthly_payouts` | Creator sees own only | System/Admin only (calculated) |

---

## 📊 Comparison: Nutrition vs. Beauty Remuneration

| Feature | Nutrition Mode | Beauty Mode (Standard) | Beauty Mode (Fan) |
|---------|---------------|------------------------|-------------------|
| **Sub Price** | 3€ fixed | 3€ fixed | 3€ fixed |
| **Creator Share** | 1/90€ per meal (~0.011€) | Pool Share (% of tokens) | 1€ direct per fan |
| **Trigger** | Meal log completion | Care log completion | Fan selection |
| **Volatility** | Predictable (fixed rate) | Variable (depends on total tokens) | Predictable (1€ × fans) |
| **Max Earnings** | Unlimited (based on logs) | Capped by pool size | Unlimited (based on fans) |

---

## ✅ Implementation Checklist

### Database (Supabase)
- [x] Create migration file `20240103000001_fix_beauty_remuneration_and_fan_mode.sql`
- [ ] **ACTION REQUIRED**: Run SQL in Supabase Dashboard
- [ ] Verify tables created: `beauty_plans`, `fan_allocations`, `beauty_care_logs`
- [ ] Test function: `SELECT log_beauty_care('...', '...');`

### Flutter Integration
- [ ] Create `BeautySubscriptionService` (check sub status, fan allocation)
- [ ] Create `BeautyLogService` (call `log_beauty_care` RPC on toggle)
- [ ] Update UI: Add "Fan Mode" selector (choose creator)
- [ ] Update UI: Show "Care Completed" toggle → triggers RPC
- [ ] Add Creator Dashboard: Show "Pool Earnings" vs "Fan Earnings"

### Testing Scenarios
1. **Standard Flow**: User logs 10 cares → Verify 10 tokens in DB
2. **Fan Flow**: User allocates to Creator X → Verify 1€ in `fan_earnings`
3. **Mixed Flow**: Creator has 5 fans + 100 tokens → Verify correct split
4. **Month-End**: Run `calculate_creator_payouts` → Verify payout row created

---

## 🚀 Next Steps

1. **Run Migration**: Execute SQL file in Supabase
2. **Flutter RPC Wrapper**: Create Dart service to call `log_beauty_care`
3. **UI Toggle**: Connect "Complete Care" button to RPC call
4. **Fan Selector**: Build UI for users to choose creator allocation
5. **Dashboard**: Display earnings breakdown (Pool vs Fan) for creators

**Status**: Database schema ready. Pending Flutter integration and SQL execution.
