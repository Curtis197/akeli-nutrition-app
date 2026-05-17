-- =============================================================================
-- AKELI V1 — Migration: Subscription INSERT Guard
-- Migration: 20260517000002_subscription_insert_guard.sql
-- Fixes AUTH-02: users could self-insert an active subscription row, bypassing
-- validate-store-purchase. Restricts INSERT/UPDATE to service_role only.
-- Note: validate-store-purchase uses serviceClient() which bypasses RLS,
-- so restricting INSERT to service_role does not break any existing functionality.
-- =============================================================================

-- Drop the existing catch-all "FOR ALL" policy (covers SELECT, INSERT, UPDATE, DELETE)
DROP POLICY IF EXISTS "owner only subscription" ON subscription;

-- Users can read their own subscription (needed by activate-fan-mode)
CREATE POLICY "owner reads subscription" ON subscription
  FOR SELECT USING (auth.uid() = user_id);

-- Only service_role can insert new subscriptions (validate-store-purchase uses serviceClient)
CREATE POLICY "service inserts subscription" ON subscription
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Only service_role can update subscriptions
CREATE POLICY "service updates subscription" ON subscription
  FOR UPDATE WITH CHECK (auth.role() = 'service_role');
