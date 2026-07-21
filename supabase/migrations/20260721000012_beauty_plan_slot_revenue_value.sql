-- Migration: Proportional Creator Revenue Value for Beauty Plan Slots
-- File: supabase/migrations/20260721000012_beauty_plan_slot_revenue_value.sql

-- 1. Add revenue_value column to beauty_plan_slot
ALTER TABLE beauty_plan_slot ADD COLUMN IF NOT EXISTS revenue_value NUMERIC(10, 6) DEFAULT 0.0;

-- 2. Upgrade generate_beauty_plan RPC to set revenue_value = 1 / total_slots
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
    v_found BOOLEAN;
    v_total_slots INT;
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
            v_found := FALSE;
            FOR v_rec IN 
                SELECT recipe_id, beauty_type, beauty_sub_type 
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '2x_week'::TEXT)
            LOOP
                v_found := TRUE;
                INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                VALUES (
                    v_plan_id, v_day_num, v_week_num, v_dow,
                    COALESCE(v_rec.beauty_type, 'both'),
                    COALESCE(v_rec.beauty_sub_type, 'treatment'),
                    v_rec.recipe_id,
                    '2x_week'
                );
            END LOOP;
            IF NOT v_found THEN
                FOR v_rec IN 
                    SELECT recipe_id, beauty_type, beauty_sub_type 
                    FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
                LOOP
                    INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                    VALUES (
                        v_plan_id, v_day_num, v_week_num, v_dow,
                        COALESCE(v_rec.beauty_type, 'both'),
                        'midweek_treatment',
                        v_rec.recipe_id,
                        '2x_week'
                    );
                END LOOP;
            END IF;
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

    -- Calculate total slots N and update each slot with revenue_value = 1 / N
    SELECT COUNT(*) INTO v_total_slots 
    FROM beauty_plan_slot 
    WHERE plan_id = v_plan_id;

    IF v_total_slots > 0 THEN
        UPDATE beauty_plan_slot 
        SET revenue_value = ROUND(1.0 / v_total_slots, 6)
        WHERE plan_id = v_plan_id;
    END IF;

    RETURN v_plan_id;
END;
$$;

-- 3. Creator Revenue Share Calculation RPC
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

-- 4. Backfill existing plan slots
DO $$
DECLARE
    v_p RECORD;
    v_count INT;
BEGIN
    FOR v_p IN SELECT id FROM beauty_plan LOOP
        SELECT COUNT(*) INTO v_count FROM beauty_plan_slot WHERE plan_id = v_p.id;
        IF v_count > 0 THEN
            UPDATE beauty_plan_slot 
            SET revenue_value = ROUND(1.0 / v_count, 6)
            WHERE plan_id = v_p.id;
        END IF;
    END LOOP;
END $$;
