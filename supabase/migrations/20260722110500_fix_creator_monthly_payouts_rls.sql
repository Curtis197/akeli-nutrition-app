-- Migration: 20260722110500_fix_creator_monthly_payouts_rls.sql
-- Finding #6 (Area C, Medium): creator_monthly_payouts' only RLS policy
-- compares auth.uid() = creator_id, but creator_id stores creator.id (a
-- separate table's PK), not the creator's own auth uid. Corrected idiom
-- matches fan_subscription's existing pattern in this codebase.
DROP POLICY IF EXISTS "Creators view own payouts" ON creator_monthly_payouts;

CREATE POLICY "Creators view own payouts" ON creator_monthly_payouts
  FOR SELECT USING (
    creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())
  );
