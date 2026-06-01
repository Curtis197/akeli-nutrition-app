-- Align live DB column names with schema files and RPC code.
-- The live DB had `date` (renamed from original `scheduled_date`) and integer servings.
DO $$
BEGIN
  IF EXISTS(SELECT *
    FROM information_schema.columns
    WHERE table_name='meal_plan_entry' and column_name='date')
  THEN
      ALTER TABLE public.meal_plan_entry RENAME COLUMN date TO scheduled_date;
  END IF;
END $$;
ALTER TABLE public.meal_plan_entry ALTER COLUMN servings TYPE numeric(4,1) USING servings::numeric(4,1);
