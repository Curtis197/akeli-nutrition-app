-- ================================================================
-- AKELI BEAUTY MODE: FIXED SUBSCRIPTION & FAN ALLOCATION
-- ================================================================
-- Business Rules:
-- 1. Standard Beauty Plan: 3€/month fixed.
--    - 1€ goes to Creator Pool (distributed by token/usage).
--    - 2€ stays with Platform.
-- 2. Fan Mode: 3€/month fixed.
--    - 1€ goes DIRECTLY to specific chosen creator.
--    - 2€ stays with Platform.
-- 3. Trigger: Remuneration is calculated monthly based on active subs/allocations.
--    - Usage logging (toggle) tracks engagement for Token calculation but does not charge per care.
-- ================================================================

-- 1. DROP OLD TABLES IF EXISTS (Cleanup from previous iteration)
DROP TABLE IF EXISTS beauty_logs CASCADE;
DROP TABLE IF EXISTS beauty_entries CASCADE;
DROP TABLE IF EXISTS fan_allocations CASCADE;
DROP TABLE IF EXISTS creator_pool_entries CASCADE;

-- 2. CORE TABLES

-- Beauty Plans (Static: 3€)
CREATE TABLE beauty_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL, -- 'Standard Beauty', 'Fan Mode'
    price_cents INT NOT NULL DEFAULT 300, -- 3.00€
    platform_fee_cents INT NOT NULL DEFAULT 200, -- 2.00€
    creator_share_cents INT NOT NULL DEFAULT 100, -- 1.00€
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Subscriptions
CREATE TABLE user_beauty_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES beauty_plans(id),
    status TEXT CHECK (status IN ('active', 'cancelled', 'expired')),
    current_period_start DATE,
    current_period_end DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fan Allocations (Specific to Fan Mode: User -> Creator Direct 1€)
CREATE TABLE fan_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- The chosen creator
    subscription_id UUID REFERENCES user_beauty_subscriptions(id),
    amount_cents INT NOT NULL DEFAULT 100, -- Fixed 1.00€
    is_active BOOLEAN DEFAULT TRUE,
    allocated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, subscription_id) -- One allocation per sub
);

-- Creator Pool Entries (For Standard Mode: Usage-based token tracking)
-- Users log care -> get tokens -> creators share the 1€ pool based on % of total tokens
CREATE TABLE beauty_care_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Creator of the routine
    routine_id UUID, -- Reference to specific routine definition
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    tokens_earned INT DEFAULT 1, -- 1 care = 1 token for pool calculation
    is_synced BOOLEAN DEFAULT FALSE
);

-- Monthly Payouts (Calculated Snapshot)
CREATE TABLE creator_monthly_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    period_month DATE, -- e.g., 2024-02-01
    pool_earnings_cents INT DEFAULT 0, -- From Standard Mode (Token share)
    fan_earnings_cents INT DEFAULT 0, -- From Fan Mode (Direct 1€ x N fans)
    total_earnings_cents INT GENERATED ALWAYS AS (pool_earnings_cents + fan_earnings_cents) STORED,
    status TEXT CHECK (status IN ('pending', 'paid', 'failed')) DEFAULT 'pending',
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(creator_id, period_month)
);

-- 3. INDEXES FOR PERFORMANCE
CREATE INDEX idx_beauty_subs_user ON user_beauty_subscriptions(user_id);
CREATE INDEX idx_fan_alloc_creator ON fan_allocations(creator_id);
CREATE INDEX idx_care_logs_creator ON beauty_care_logs(creator_id);
CREATE INDEX idx_care_logs_date ON beauty_care_logs(completed_at);

-- 4. ROW LEVEL SECURITY (RLS)
ALTER TABLE beauty_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_beauty_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE beauty_care_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_monthly_payouts ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public view plans" ON beauty_plans FOR SELECT USING (TRUE);

CREATE POLICY "Users view own subs" ON user_beauty_subscriptions 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users view own allocations" ON fan_allocations 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Creators view own allocations" ON fan_allocations 
    FOR SELECT USING (auth.uid() = creator_id);

CREATE POLICY "Users log own care" ON beauty_care_logs 
    FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Creators view logs for their content" ON beauty_care_logs 
    FOR SELECT USING (auth.uid() = creator_id);

CREATE POLICY "Creators view own payouts" ON creator_monthly_payouts 
    FOR SELECT USING (auth.uid() = creator_id);

-- 5. AUTOMATED LOGIC (TRIGGERS & FUNCTIONS)

-- Function: Calculate Monthly Payouts
-- Runs on demand (e.g., end of month cron job or admin trigger)
CREATE OR REPLACE FUNCTION calculate_creator_payouts(target_month DATE)
RETURNS VOID AS $$
DECLARE
    rec RECORD;
    total_pool_tokens INT;
    creator_tokens INT;
    pool_share_cents INT;
    fan_count INT;
BEGIN
    -- 1. Calculate Total Tokens in Standard Pool for the month
    SELECT COUNT(*) INTO total_pool_tokens
    FROM beauty_care_logs
    WHERE DATE_TRUNC('month', completed_at) = target_month;

    -- 2. Process each creator
    FOR rec IN SELECT DISTINCT creator_id FROM beauty_care_logs WHERE DATE_TRUNC('month', completed_at) = target_month
    LOOP
        -- A. Standard Pool Share
        SELECT COUNT(*) INTO creator_tokens
        FROM beauty_care_logs
        WHERE creator_id = rec.creator_id AND DATE_TRUNC('month', completed_at) = target_month;

        IF total_pool_tokens > 0 THEN
            pool_share_cents := FLOOR((creator_tokens::FLOAT / total_pool_tokens::FLOAT) * 100); -- Simplified: 1€ total pool scaled
            -- Note: In prod, multiply by actual total pool money (Count of Standard Subs * 100)
        ELSE
            pool_share_cents := 0;
        END IF;

        -- B. Fan Mode Direct Earnings (1€ per active fan allocation)
        SELECT COUNT(*) INTO fan_count
        FROM fan_allocations
        WHERE creator_id = rec.creator_id
        AND is_active = TRUE
        AND DATE_TRUNC('month', allocated_at) <= target_month; -- Active during month
        
        -- Insert/Upsert Payout
        INSERT INTO creator_monthly_payouts (creator_id, period_month, pool_earnings_cents, fan_earnings_cents, status)
        VALUES (rec.creator_id, target_month, pool_share_cents, (fan_count * 100), 'pending')
        ON CONFLICT (creator_id, period_month) DO UPDATE
        SET 
            pool_earnings_cents = EXCLUDED.pool_earnings_cents,
            fan_earnings_cents = EXCLUDED.fan_earnings_cents,
            total_earnings_cents = EXCLUDED.pool_earnings_cents + EXCLUDED.fan_earnings_cents,
            status = 'pending';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function: Log Care (Called by Flutter Toggle)
-- Creates the log entry which counts towards the token pool
CREATE OR REPLACE FUNCTION log_beauty_care(routine_creator_id UUID, routine_ref_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO beauty_care_logs (user_id, creator_id, routine_id, completed_at, tokens_earned, is_synced)
    VALUES (auth.uid(), routine_creator_id, routine_ref_id, NOW(), 1, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. SEED DATA
INSERT INTO beauty_plans (id, name, price_cents, platform_fee_cents, creator_share_cents)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Standard Beauty Plan', 300, 200, 100),
    ('00000000-0000-0000-0000-000000000002', 'Fan Mode Plan', 300, 200, 100);
