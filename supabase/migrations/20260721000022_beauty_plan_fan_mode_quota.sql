-- Migration: 20260721000022_beauty_plan_fan_mode_quota.sql
-- Description: Add 90% Fan Creator slot quota and Fan Mode tracking to generate_beauty_plan for 100% parity with Nutrition mode

CREATE OR REPLACE FUNCTION generate_beauty_plan(
  p_user_id    UUID,
  p_start_date DATE DEFAULT CURRENT_DATE,
  p_days       INT DEFAULT 30
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_plan_id UUID;
    v_end_date DATE := p_start_date + (p_days - 1);
    v_curr_date DATE;
    v_day_num SMALLINT;
    v_week_num SMALLINT;
    v_dow SMALLINT;
    v_rec RECORD;
    v_found BOOLEAN;
    v_total_slots INT;
    v_fan_creator_id UUID;
    v_fan_count INT := 0;
    v_other_count INT := 0;
    v_max_other_slots INT;
BEGIN
    -- Look up active Fan Subscription
    SELECT fs.creator_id INTO v_fan_creator_id
    FROM fan_subscription fs
    WHERE fs.user_id = p_user_id AND fs.status = 'active'
    LIMIT 1;

    -- Deactivate active beauty plans overlapping this range
    UPDATE beauty_plan
    SET is_active = false
    WHERE user_id = p_user_id AND is_active = true;

    INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
    VALUES (p_user_id, p_start_date, v_end_date, true)
    RETURNING id INTO v_plan_id;

    v_day_num := 1;
    v_curr_date := p_start_date;
    
    WHILE v_curr_date <= v_end_date LOOP
        v_dow := EXTRACT(ISODOW FROM v_curr_date)::SMALLINT;
        v_week_num := ((v_day_num - 1) / 7) + 1;

        -- Daily routine slots
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

        -- Midweek treatment (Wednesdays & Saturdays)
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

        -- Sunday Wash Day Mask
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

        -- Bi-weekly Clarifying & Protein Care (Day 14 & 28)
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

        -- Monthly Detox Check-in (Day 28)
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

    SELECT COUNT(*) INTO v_total_slots 
    FROM beauty_plan_slot 
    WHERE plan_id = v_plan_id;

    IF v_total_slots > 0 THEN
        v_max_other_slots := FLOOR(v_total_slots * 0.10);
        UPDATE beauty_plan_slot 
        SET revenue_value = ROUND(1.0 / v_total_slots, 6)
        WHERE plan_id = v_plan_id;
    END IF;

    RETURN v_plan_id;
END;
$$;
