-- Migration: Monthly Beauty Plan Generator RPC & Slot Schema Upgrade
-- File: supabase/migrations/20260721000008_monthly_beauty_plan_generator.sql

-- 1. Upgrade beauty_plan_slot columns
ALTER TABLE beauty_plan_slot ADD COLUMN IF NOT EXISTS day_number SMALLINT;
ALTER TABLE beauty_plan_slot ADD COLUMN IF NOT EXISTS week_number SMALLINT;
ALTER TABLE beauty_plan_slot ADD COLUMN IF NOT EXISTS frequency_tier VARCHAR(20);

-- Index for querying monthly day slots
CREATE INDEX IF NOT EXISTS idx_beauty_plan_slot_day ON beauty_plan_slot(plan_id, day_number);

-- 2. Monthly Beauty Plan Generator RPC
CREATE OR REPLACE FUNCTION generate_beauty_plan(
    p_user_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_plan_id UUID;
    v_end_date DATE := p_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    v_curr_date DATE;
    v_day_num SMALLINT;
    v_week_num SMALLINT;
    v_dow SMALLINT;
    v_rec RECORD;
BEGIN
    -- Delete existing plan for user in the target month range
    DELETE FROM beauty_plan 
    WHERE user_id = p_user_id AND start_date = p_start_date;

    -- Create monthly beauty plan
    INSERT INTO beauty_plan (user_id, start_date, end_date)
    VALUES (p_user_id, p_start_date, v_end_date)
    RETURNING id INTO v_plan_id;

    -- Iterate through every day of the month (Days 1 to 30)
    v_day_num := 1;
    v_curr_date := p_start_date;
    
    WHILE v_curr_date <= v_end_date LOOP
        v_dow := EXTRACT(ISODOW FROM v_curr_date)::SMALLINT; -- 1 (Mon) to 7 (Sun)
        v_week_num := ((v_day_num - 1) / 7) + 1;

        -- A. DAILY ROUTINES (Every Day)
        FOR v_rec IN 
            SELECT recipe_id, beauty_type, beauty_sub_type 
            FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => 'daily'::TEXT)
        LOOP
            INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
            VALUES (
                v_plan_id, v_day_num, v_week_num, v_dow,
                COALESCE(v_rec.beauty_type, 'both'),
                COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                v_rec.recipe_id,
                'daily'
            );
        END LOOP;

        -- B. 2X / WEEK ROUTINES (Wednesdays = dow 3, Saturdays = dow 6)
        IF v_dow IN (3, 6) THEN
            FOR v_rec IN 
                SELECT recipe_id, beauty_type, beauty_sub_type 
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '2x_week'::TEXT)
            LOOP
                INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                VALUES (
                    v_plan_id, v_day_num, v_week_num, v_dow,
                    COALESCE(v_rec.beauty_type, 'both'),
                    COALESCE(v_rec.beauty_sub_type, 'treatment'),
                    v_rec.recipe_id,
                    '2x_week'
                );
            END LOOP;
        END IF;

        -- C. 1X / WEEK WASH DAY & DEEP MASKS (Sundays = dow 7)
        IF v_dow = 7 THEN
            FOR v_rec IN 
                SELECT recipe_id, beauty_type, beauty_sub_type 
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '1x_week'::TEXT)
            LOOP
                INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                VALUES (
                    v_plan_id, v_day_num, v_week_num, v_dow,
                    COALESCE(v_rec.beauty_type, 'both'),
                    COALESCE(v_rec.beauty_sub_type, 'wash_day_mask'),
                    v_rec.recipe_id,
                    '1x_week'
                );
            END LOOP;
        END IF;

        -- D. 2X / MONTH PROTEIN & CLARIFYING CARE (Day 14 and Day 28)
        IF v_day_num IN (14, 28) THEN
            FOR v_rec IN 
                SELECT recipe_id, beauty_type, beauty_sub_type 
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
            LOOP
                INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                VALUES (
                    v_plan_id, v_day_num, v_week_num, v_dow,
                    COALESCE(v_rec.beauty_type, 'both'),
                    'protein_clarifying_care',
                    v_rec.recipe_id,
                    '2x_month'
                );
            END LOOP;
        END IF;

        -- E. 1X / MONTH DEEP DETOX & PROGRESS CHECK-IN (Day 28)
        IF v_day_num = 28 THEN
            FOR v_rec IN 
                SELECT recipe_id, beauty_type, beauty_sub_type 
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
            LOOP
                INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                VALUES (
                    v_plan_id, v_day_num, v_week_num, v_dow,
                    COALESCE(v_rec.beauty_type, 'both'),
                    'monthly_detox_checkin',
                    v_rec.recipe_id,
                    '1x_month'
                );
            END LOOP;
        END IF;

        v_day_num := v_day_num + 1;
        v_curr_date := v_curr_date + INTERVAL '1 day';
    END LOOP;

    RETURN v_plan_id;
END;
$$;
