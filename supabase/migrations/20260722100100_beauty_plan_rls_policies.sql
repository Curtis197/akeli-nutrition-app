-- Migration: Enable RLS on beauty_plan and beauty_plan_slot
-- File: supabase/migrations/20260722100100_beauty_plan_rls_policies.sql
-- Fixes: beauty_plan / beauty_plan_slot were created in
-- 20260721000002_beauty_plan_schema_and_generator.sql with zero RLS
-- policies. Any authenticated user could read/update/delete any other
-- user's beauty plan or slots via the Supabase client SDK. Mirrors the
-- idiom used by beauty_log's RLS policies in
-- 20260721000007_beauty_log_evolution_tracking.sql.

ALTER TABLE beauty_plan ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own beauty plans"
    ON beauty_plan FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own beauty plans"
    ON beauty_plan FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own beauty plans"
    ON beauty_plan FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own beauty plans"
    ON beauty_plan FOR DELETE
    USING (auth.uid() = user_id);

ALTER TABLE beauty_plan_slot ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own beauty plan slots"
    ON beauty_plan_slot FOR SELECT
    USING (plan_id IN (SELECT id FROM beauty_plan WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own beauty plan slots"
    ON beauty_plan_slot FOR INSERT
    WITH CHECK (plan_id IN (SELECT id FROM beauty_plan WHERE user_id = auth.uid()));

CREATE POLICY "Users can update own beauty plan slots"
    ON beauty_plan_slot FOR UPDATE
    USING (plan_id IN (SELECT id FROM beauty_plan WHERE user_id = auth.uid()));

CREATE POLICY "Users can delete own beauty plan slots"
    ON beauty_plan_slot FOR DELETE
    USING (plan_id IN (SELECT id FROM beauty_plan WHERE user_id = auth.uid()));
