-- Migration: 20260722110100_fix_beauty_payout_fan_double_counting.sql
-- Finding #2 (Area C, Critical): calculate_creator_payouts's
-- fan_earnings_cents computation double-counts the same fan_subscription
-- rows already recognized as revenue by
-- supabase/functions/compute-monthly-revenue (which writes them into
-- creator_balance.balance). Beauty-side pool_earnings_cents (plan-slot
-- completion revenue) is NOT double-counted anywhere and is preserved.
--
-- Prerequisite schema fix (required for this function to run at all —
-- see this plan's Global Constraints): creator_monthly_payouts was first
-- created by 20260521000003 with creator_id UUID REFERENCES auth.users(id)
-- and no updated_at column. 20260721000013's own
-- `CREATE TABLE IF NOT EXISTS creator_monthly_payouts` never actually
-- applied (the table already existed), so its corrected creator_id shape
-- and updated_at column were silently never created, even though
-- calculate_creator_payouts's ON CONFLICT ... DO UPDATE SET
-- updated_at = NOW() and its INSERT of recipe.creator_id (== creator.id,
-- NOT auth.users.id) values both assume that shape. Both statements below
-- are idempotent. The constraint name is looked up dynamically rather
-- than guessed, so this is safe regardless of what Postgres auto-named it.

ALTER TABLE creator_monthly_payouts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

DO $$
DECLARE
  v_conname text;
BEGIN
  SELECT con.conname INTO v_conname
  FROM pg_constraint con
  JOIN pg_class rel ON rel.oid = con.conrelid
  JOIN pg_attribute att ON att.attrelid = con.conrelid AND att.attnum = ANY(con.conkey)
  WHERE rel.relname = 'creator_monthly_payouts'
    AND con.contype = 'f'
    AND att.attname = 'creator_id'
  LIMIT 1;

  IF v_conname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE creator_monthly_payouts DROP CONSTRAINT %I', v_conname);
  END IF;
END;
$$;

ALTER TABLE creator_monthly_payouts
  ADD CONSTRAINT creator_monthly_payouts_creator_id_fkey
  FOREIGN KEY (creator_id) REFERENCES creator(id) ON DELETE CASCADE;

-- Replacement calculate_creator_payouts: pool_earnings_cents only.
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
        -- Calculate Creator's total weighted revenue points (each point = 1.00€ share)
        SELECT COALESCE(SUM(bps.revenue_value), 0.0) INTO v_creator_points
        FROM beauty_plan_slot bps
        JOIN recipe r ON bps.recipe_id = r.id
        WHERE r.creator_id = v_rec.creator_id
          AND bps.is_completed = TRUE
          AND DATE_TRUNC('month', COALESCE(bps.completed_at, bps.created_at)) = DATE_TRUNC('month', target_month);

        v_pool_share_cents := ROUND(v_creator_points * plan_revenue_cents)::INT;

        -- NOTE: fan-mode revenue is intentionally NOT computed here.
        -- supabase/functions/compute-monthly-revenue already recognizes
        -- every active fan_subscription row as revenue into
        -- creator_balance.balance; computing it again here would
        -- double-count the same subscription.

        INSERT INTO creator_monthly_payouts (creator_id, period_month, pool_earnings_cents, status)
        VALUES (v_rec.creator_id, DATE_TRUNC('month', target_month)::DATE, v_pool_share_cents, 'pending')
        ON CONFLICT (creator_id, period_month) DO UPDATE
        SET
            pool_earnings_cents = EXCLUDED.pool_earnings_cents,
            updated_at = NOW();
    END LOOP;
END;
$$;
