-- Align live DB column names with schema files and RPC code.
-- The live DB had `date` (renamed from original `scheduled_date`) and integer servings.
ALTER TABLE public.meal_plan_entry RENAME COLUMN date TO scheduled_date;
ALTER TABLE public.meal_plan_entry ALTER COLUMN servings TYPE numeric(4,1) USING servings::numeric(4,1);
