-- Migration: 20260722110200_add_beauty_payout_rpc_authorization.sql
-- Finding #3 (Area C, High): no authorization check on
-- get_creator_beauty_payout_breakdown / get_platform_retained_beauty_revenue
-- / get_creator_beauty_revenue_share.
--
-- get_creator_beauty_revenue_share / get_creator_beauty_payout_breakdown:
-- caller must own the creator row being queried (creator.user_id is the
-- FK to the creator's own auth uid — confirmed via
-- supabase/migrations/20260301000001_initial_schema.sql).
--
-- get_platform_retained_beauty_revenue: restricted to service_role only,
-- via REVOKE/GRANT — this codebase's established idiom for
-- service-role-only RPCs (see 20260626000001_fix_generate_meal_plan_from_saved_service_role.sql,
-- 20260705000001_fix_meal_plan_from_saved_service_role.sql). This function's
-- body is intentionally unchanged.
--
-- Note on scope: get_creator_beauty_payout_breakdown's own fan-earnings
-- display math (recomputed live from fan_subscription, separate from
-- calculate_creator_payouts / creator_monthly_payouts) is left untouched.
-- Finding #2 is scoped explicitly to calculate_creator_payouts's ledger
-- write; changing this read-only reporting RPC's math is a different,
-- unassigned finding.

CREATE OR REPLACE FUNCTION get_creator_beauty_revenue_share(
    p_creator_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 month',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    completed_slots_count INT,
    total_revenue_points NUMERIC(10, 6)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
      SELECT 1 FROM creator WHERE id = p_creator_id AND user_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'Unauthorized';
    END IF;

    RETURN QUERY
    SELECT
        COUNT(*)::INT AS completed_slots_count,
        COALESCE(SUM(bps.revenue_value), 0.0)::NUMERIC(10, 6) AS total_revenue_points
    FROM beauty_plan_slot bps
    JOIN recipe r ON bps.recipe_id = r.id
    JOIN beauty_plan bp ON bps.plan_id = bp.id
    WHERE r.creator_id = p_creator_id
      AND bps.is_completed = TRUE
      AND bp.start_date >= p_start_date
      AND bp.end_date <= p_end_date;
END;
$$;

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
    IF NOT EXISTS (
      SELECT 1 FROM creator WHERE id = p_creator_id AND user_id = auth.uid()
    ) THEN
      RAISE EXCEPTION 'Unauthorized';
    END IF;

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

REVOKE ALL ON FUNCTION get_platform_retained_beauty_revenue(DATE, INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_platform_retained_beauty_revenue(DATE, INT) FROM anon;
REVOKE ALL ON FUNCTION get_platform_retained_beauty_revenue(DATE, INT) FROM authenticated;
GRANT EXECUTE ON FUNCTION get_platform_retained_beauty_revenue(DATE, INT) TO service_role;
