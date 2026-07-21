-- Migration: Proportional Beauty Creator Payout Functions (entry.revenue_value direct 1.00€ share)
-- File: supabase/migrations/20260721000013_beauty_payouts_revenue_value.sql

-- 1. Ensure creator_monthly_payouts table exists
CREATE TABLE IF NOT EXISTS creator_monthly_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES user_profile(id) ON DELETE CASCADE,
    period_month DATE NOT NULL,
    pool_earnings_cents INT DEFAULT 0,
    fan_earnings_cents INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (creator_id, period_month)
);

-- Index for querying creator payouts
CREATE INDEX IF NOT EXISTS idx_creator_monthly_payouts_month ON creator_monthly_payouts(period_month);

-- 2. Calculate Creator Payouts: 1.00€ (100 cents) pool per plan divided by N entries.
-- Completed entries pay creator (entry.revenue_value * 100 cents). Unchecked entries go to platform.
CREATE OR REPLACE FUNCTION calculate_creator_payouts(
    target_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE,
    plan_revenue_cents INT DEFAULT 100
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_rec RECORD;
    v_creator_points NUMERIC(12, 6);
    v_pool_share_cents INT;
    v_fan_count INT;
BEGIN
    -- Iterate through all creators with completed beauty plan slots in target month
    FOR v_rec IN 
        SELECT DISTINCT r.creator_id
        FROM beauty_plan_slot bps
        JOIN recipe r ON bps.recipe_id = r.id
        WHERE bps.is_completed = TRUE
          AND r.creator_id IS NOT NULL
          AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', target_month)
    LOOP
        -- A. Calculate Creator's total weighted revenue points (each point = 1.00€ share)
        SELECT COALESCE(SUM(bps.revenue_value), 0.0) INTO v_creator_points
        FROM beauty_plan_slot bps
        JOIN recipe r ON bps.recipe_id = r.id
        WHERE r.creator_id = v_rec.creator_id
          AND bps.is_completed = TRUE
          AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', target_month);

        -- Direct payout: revenue_value * 100 cents (1.00€ per full plan)
        v_pool_share_cents := ROUND(v_creator_points * plan_revenue_cents)::INT;

        -- B. Fan Mode Direct Earnings (1.00€ = 100 cents per active fan subscription)
        SELECT COUNT(*) INTO v_fan_count
        FROM fan_subscription fs
        WHERE fs.creator_id = v_rec.creator_id
          AND fs.status = 'active'
          AND DATE_TRUNC('month', COALESCE(fs.subscribed_at, fs.created_at)) <= DATE_TRUNC('month', target_month);

        -- Upsert Payout record
        INSERT INTO creator_monthly_payouts (creator_id, period_month, pool_earnings_cents, fan_earnings_cents, status)
        VALUES (v_rec.creator_id, DATE_TRUNC('month', target_month)::DATE, v_pool_share_cents, (v_fan_count * 100), 'pending')
        ON CONFLICT (creator_id, period_month) DO UPDATE
        SET
            pool_earnings_cents = EXCLUDED.pool_earnings_cents,
            fan_earnings_cents = EXCLUDED.fan_earnings_cents,
            updated_at = NOW();
    END LOOP;
END;
$$;

-- 3. Detailed Creator Beauty Payout Breakdown RPC
CREATE OR REPLACE FUNCTION get_creator_beauty_payout_breakdown(
    p_creator_id UUID,
    p_target_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE,
    p_plan_revenue_cents INT DEFAULT 100
)
RETURNS TABLE (
    out_creator_id UUID,
    out_period_month DATE,
    completed_slots_count INT,
    creator_revenue_points NUMERIC(10, 6),
    creator_earned_euros NUMERIC(10, 4),
    pool_earnings_cents INT,
    fan_earnings_cents INT,
    total_payout_cents INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_creator_points NUMERIC(12, 6);
    v_completed_count INT;
    v_fan_count INT;
    v_pool_share_cents INT;
    v_fan_cents INT;
BEGIN
    -- Creator points in month
    SELECT 
        COUNT(*)::INT,
        COALESCE(SUM(bps.revenue_value), 0.0)
    INTO v_completed_count, v_creator_points
    FROM beauty_plan_slot bps
    JOIN recipe r ON bps.recipe_id = r.id
    WHERE r.creator_id = p_creator_id
      AND bps.is_completed = TRUE
      AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', p_target_month);

    -- Fan count
    SELECT COUNT(*)::INT INTO v_fan_count
    FROM fan_subscription fs
    WHERE fs.creator_id = p_creator_id
      AND fs.status = 'active'
      AND DATE_TRUNC('month', COALESCE(fs.subscribed_at, fs.created_at)) <= DATE_TRUNC('month', p_target_month);

    v_pool_share_cents := ROUND(v_creator_points * p_plan_revenue_cents)::INT;
    v_fan_cents := v_fan_count * 100;

    RETURN QUERY
    SELECT 
        p_creator_id,
        DATE_TRUNC('month', p_target_month)::DATE,
        v_completed_count,
        v_creator_points::NUMERIC(10, 6),
        (v_creator_points * (p_plan_revenue_cents / 100.0))::NUMERIC(10, 4),
        v_pool_share_cents,
        v_fan_cents,
        (v_pool_share_cents + v_fan_cents);
END;
$$;

-- 4. Platform Retained Revenue Breakdown RPC (Unchecked slots go to platform)
CREATE OR REPLACE FUNCTION get_platform_retained_beauty_revenue(
    p_target_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE,
    p_plan_revenue_cents INT DEFAULT 100
)
RETURNS TABLE (
    period_month DATE,
    total_plans_count INT,
    total_slots_count INT,
    completed_slots_count INT,
    unchecked_slots_count INT,
    creator_payout_cents INT,
    platform_retained_cents INT,
    platform_retained_euros NUMERIC(10, 2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_plans_count INT;
    v_total_slots INT;
    v_completed_slots INT;
    v_unchecked_slots INT;
    v_creator_points NUMERIC(12, 6);
    v_creator_payout_cents INT;
    v_total_pool_cents INT;
    v_retained_cents INT;
BEGIN
    SELECT COUNT(*)::INT INTO v_plans_count
    FROM beauty_plan bp
    WHERE DATE_TRUNC('month', bp.start_date) = DATE_TRUNC('month', p_target_month);

    SELECT 
        COUNT(*)::INT,
        COUNT(*) FILTER (WHERE bps.is_completed = TRUE)::INT,
        COUNT(*) FILTER (WHERE bps.is_completed = FALSE OR bps.is_completed IS NULL)::INT,
        COALESCE(SUM(bps.revenue_value) FILTER (WHERE bps.is_completed = TRUE), 0.0)
    INTO v_total_slots, v_completed_slots, v_unchecked_slots, v_creator_points
    FROM beauty_plan_slot bps
    JOIN beauty_plan bp ON bps.plan_id = bp.id
    WHERE DATE_TRUNC('month', bp.start_date) = DATE_TRUNC('month', p_target_month);

    v_total_pool_cents := v_plans_count * p_plan_revenue_cents;
    v_creator_payout_cents := ROUND(v_creator_points * p_plan_revenue_cents)::INT;
    v_retained_cents := v_total_pool_cents - v_creator_payout_cents;

    RETURN QUERY
    SELECT 
        DATE_TRUNC('month', p_target_month)::DATE,
        v_plans_count,
        v_total_slots,
        v_completed_slots,
        v_unchecked_slots,
        v_creator_payout_cents,
        v_retained_cents,
        (v_retained_cents / 100.0)::NUMERIC(10, 2);
END;
$$;
