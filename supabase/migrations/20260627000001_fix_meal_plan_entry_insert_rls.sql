-- The existing policy "owner only via plan meal_plan_entry" only has a USING
-- clause, which covers SELECT/UPDATE/DELETE but not INSERT. Direct client
-- inserts (e.g. adding a snack from the Flutter app) were blocked.
-- This migration adds an explicit INSERT policy with the same ownership check.

CREATE POLICY "owner insert meal_plan_entry" ON meal_plan_entry
  FOR INSERT
  WITH CHECK (
    meal_plan_id IN (SELECT id FROM meal_plan WHERE user_id = auth.uid())
  );
