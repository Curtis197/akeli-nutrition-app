-- Migration: Proportional Beauty Creator Payout Functions (entry.revenue_value)
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

-- 2. Calculate Creator Payouts based on beauty_plan_slot.revenue_value
CREATE OR REPLACE FUNCTION calculate_creator_payouts(
    target_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE)::DATE,
    pool_total_cents INT DEFAULT 10000
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_pool_points NUMERIC(12, 6);
    v_rec RECORD;
    v_creator_points NUMERIC(12, 6);
    v_pool_share_cents INT;
    v_fan_count INT;
BEGIN
    -- 1. Calculate Total Weighted Revenue Value Points for completed slots in target month
    SELECT COALESCE(SUM(bps.revenue_value), 0.0) INTO v_total_pool_points
    FROM beauty_plan_slot bps
    WHERE bps.is_completed = TRUE
      AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', target_month);

    -- 2. Iterate through all creators with completed beauty plan slots in target month
    FOR v_rec IN 
        SELECT DISTINCT r.creator_id
        FROM beauty_plan_slot bps
        JOIN recipe r ON bps.recipe_id = r.id
        WHERE bps.is_completed = TRUE
          AND r.creator_id IS NOT NULL
          AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', target_month)
    LOOP
        -- A. Calculate Creator's total weighted revenue points
        SELECT COALESCE(SUM(bps.revenue_value), 0.0) INTO v_creator_points
        FROM beauty_plan_slot bps
        JOIN recipe r ON bps.recipe_id = r.id
        WHERE r.creator_id = v_rec.creator_id
          AND bps.is_completed = TRUE
          AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', target_month);

        IF v_total_pool_points > 0 THEN
            v_pool_share_cents := ROUND((v_creator_points / v_total_pool_points) * pool_total_cents)::INT;
        ELSE
            v_pool_share_cents := 0;
        END IF;

        -- B. Fan Mode Direct Earnings (1€ = 100 cents per active fan subscription)
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
    p_pool_total_cents INT DEFAULT 10000
)
RETURNS TABLE (
    out_creator_id UUID,
    out_period_month DATE,
    completed_slots_count INT,
    creator_revenue_points NUMERIC(10, 6),
    total_pool_revenue_points NUMERIC(10, 6),
    pool_share_percentage NUMERIC(6, 2),
    pool_earnings_cents INT,
    fan_earnings_cents INT,
    total_payout_cents INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_pool_points NUMERIC(12, 6);
    v_creator_points NUMERIC(12, 6);
    v_completed_count INT;
    v_fan_count INT;
    v_pool_share_cents INT;
    v_fan_cents INT;
    v_share_pct NUMERIC(6, 2);
BEGIN
    SELECT COALESCE(SUM(bps.revenue_value), 0.0) INTO v_total_pool_points
    FROM beauty_plan_slot bps
    WHERE bps.is_completed = TRUE
      AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', p_target_month);

    SELECT 
        COUNT(*)::INT,
        COALESCE(SUM(bps.revenue_value), 0.0)
    INTO v_completed_count, v_creator_points
    FROM beauty_plan_slot bps
    JOIN recipe r ON bps.recipe_id = r.id
    WHERE r.creator_id = p_creator_id
      AND bps.is_completed = TRUE
      AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', p_target_month);

    SELECT COUNT(*)::INT INTO v_fan_count
    FROM fan_subscription fs
    WHERE fs.creator_id = p_creator_id
      AND fs.status = 'active'
      AND DATE_TRUNC('month', COALESCE(fs.subscribed_at, fs.created_at)) <= DATE_TRUNC('month', p_target_month);

    IF v_total_pool_points > 0 THEN
        v_share_pct := ROUND((v_creator_points / v_total_pool_points) * 100, 2);
        v_pool_share_cents := ROUND((v_creator_points / v_total_pool_points) * p_pool_total_cents)::INT;
    ELSE
        v_share_pct := 0.00;
        v_pool_share_cents := 0;
    END IF;

    v_fan_cents := v_fan_count * 100;

    RETURN QUERY
    SELECT 
        p_creator_id,
        DATE_TRUNC('month', p_target_month)::DATE,
        v_completed_count,
        v_creator_points::NUMERIC(10, 6),
        v_total_pool_points::NUMERIC(10, 6),
        v_share_pct,
        v_pool_share_cents,
        v_fan_cents,
        (v_pool_share_cents + v_fan_cents);
END;
$$;
