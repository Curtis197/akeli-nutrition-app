-- Migration: Make the 90% fan-mode quota on generate_beauty_plan actually
-- gate and increment instead of being dead code.
-- File: supabase/migrations/20260722100200_beauty_plan_fan_mode_quota_fix.sql
--
-- Fixes: 20260721000022_beauty_plan_fan_mode_quota.sql declared
-- v_fan_count/v_other_count but never incremented them anywhere, and
-- computed v_max_other_slots only AFTER every slot for the whole plan had
-- already been inserted -- making the "90% Fan Creator slot quota" claimed
-- in that migration's own description pure dead code.
--
-- Mirrors the pattern already used correctly by Nutrition mode's
-- generate_meal_plan (supabase/migrations/20260717061116_fix_generate_meal_plan_kcal_column_name.sql):
-- v_max_other_slots is computed BEFORE the insertion loop, and every
-- candidate row is gated with
--   (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR <row's creator> = v_fan_creator_id)
-- before being inserted, incrementing v_fan_count/v_other_count as it goes.
--
-- Difference from Nutrition: recommend_recipes() (owned by Area A) is a
-- set-returning function that does not return creator_id, so each
-- candidate row's creator_id is looked up via a small supplementary query
-- (v_row_creator_id) rather than being available directly on the row, as
-- it is in Nutrition's single-row-per-slot SELECT.
--
-- v_estimated_total_slots is a deterministic UPPER-BOUND estimate computed
-- before the loop (2 daily slots/day + 2 slots per 2x_week occurrence + 2
-- slots per 1x_week occurrence + 3 slots for the two 2x_month anchor days
-- and the one 1x_month anchor day), since -- unlike Nutrition's fixed
-- slots-per-day count -- Beauty's daily/weekly/monthly recipe pools can
-- return fewer rows than requested. This keeps v_max_other_slots a safe,
-- deterministic ceiling computed ahead of time rather than recomputed
-- after the fact.

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
    v_row_creator_id UUID;
    v_estimated_total_slots INT;
    v_2x_week_days INT;
    v_1x_week_days INT;
BEGIN
    -- Look up active Fan Subscription
    SELECT fs.creator_id INTO v_fan_creator_id
    FROM fan_subscription fs
    WHERE fs.user_id = p_user_id AND fs.status = 'active'
    LIMIT 1;

    -- Count how many 2x_week (Wed/Sat) and 1x_week (Sun) anchor days fall
    -- within this plan's date range, so the fan-mode quota can be
    -- estimated BEFORE any slot is inserted (previously computed only
    -- after all slots already existed, making the quota dead code).
    SELECT count(*) INTO v_2x_week_days
    FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
    WHERE EXTRACT(ISODOW FROM d) IN (3, 6);

    SELECT count(*) INTO v_1x_week_days
    FROM generate_series(p_start_date, v_end_date, INTERVAL '1 day') AS d
    WHERE EXTRACT(ISODOW FROM d) = 7;

    v_estimated_total_slots := (p_days * 2) + (v_2x_week_days * 2) + (v_1x_week_days * 2) + 3;
    v_max_other_slots := FLOOR(v_estimated_total_slots * 0.10);

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
            SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
            IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                VALUES (
                    v_plan_id, v_day_num, v_week_num, v_dow,
                    COALESCE(v_rec.beauty_type, 'both'),
                    COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                    v_rec.recipe_id,
                    'daily'
                );
                IF v_fan_creator_id IS NOT NULL THEN
                    IF v_row_creator_id = v_fan_creator_id THEN
                        v_fan_count := v_fan_count + 1;
                    ELSE
                        v_other_count := v_other_count + 1;
                    END IF;
                END IF;
            END IF;
        END LOOP;

        -- Midweek treatment (Wednesdays & Saturdays)
        IF v_dow IN (3, 6) THEN
            v_found := FALSE;
            FOR v_rec IN
                SELECT recipe_id, beauty_type, beauty_sub_type
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '2x_week'::TEXT)
            LOOP
                v_found := TRUE;
                SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                    INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                    VALUES (
                        v_plan_id, v_day_num, v_week_num, v_dow,
                        COALESCE(v_rec.beauty_type, 'both'),
                        COALESCE(v_rec.beauty_sub_type, 'treatment'),
                        v_rec.recipe_id,
                        '2x_week'
                    );
                    IF v_fan_creator_id IS NOT NULL THEN
                        IF v_row_creator_id = v_fan_creator_id THEN
                            v_fan_count := v_fan_count + 1;
                        ELSE
                            v_other_count := v_other_count + 1;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
            IF NOT v_found THEN
                FOR v_rec IN
                    SELECT recipe_id, beauty_type, beauty_sub_type
                    FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
                LOOP
                    SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                    IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                        INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                        VALUES (
                            v_plan_id, v_day_num, v_week_num, v_dow,
                            COALESCE(v_rec.beauty_type, 'both'),
                            'midweek_treatment',
                            v_rec.recipe_id,
                            '2x_week'
                        );
                        IF v_fan_creator_id IS NOT NULL THEN
                            IF v_row_creator_id = v_fan_creator_id THEN
                                v_fan_count := v_fan_count + 1;
                            ELSE
                                v_other_count := v_other_count + 1;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;

        -- Sunday Wash Day Mask
        IF v_dow = 7 THEN
            FOR v_rec IN
                SELECT recipe_id, beauty_type, beauty_sub_type
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 2, p_mode => 'beauty'::TEXT, p_frequency => '1x_week'::TEXT)
            LOOP
                SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                    INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                    VALUES (
                        v_plan_id, v_day_num, v_week_num, v_dow,
                        COALESCE(v_rec.beauty_type, 'both'),
                        COALESCE(v_rec.beauty_sub_type, 'wash_day_mask'),
                        v_rec.recipe_id,
                        '1x_week'
                    );
                    IF v_fan_creator_id IS NOT NULL THEN
                        IF v_row_creator_id = v_fan_creator_id THEN
                            v_fan_count := v_fan_count + 1;
                        ELSE
                            v_other_count := v_other_count + 1;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END IF;

        -- Bi-weekly Clarifying & Protein Care (Day 14 & 28)
        IF v_day_num IN (14, 28) THEN
            FOR v_rec IN
                SELECT recipe_id, beauty_type, beauty_sub_type
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
            LOOP
                SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                    INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                    VALUES (
                        v_plan_id, v_day_num, v_week_num, v_dow,
                        COALESCE(v_rec.beauty_type, 'both'),
                        'protein_clarifying_care',
                        v_rec.recipe_id,
                        '2x_month'
                    );
                    IF v_fan_creator_id IS NOT NULL THEN
                        IF v_row_creator_id = v_fan_creator_id THEN
                            v_fan_count := v_fan_count + 1;
                        ELSE
                            v_other_count := v_other_count + 1;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END IF;

        -- Monthly Detox Check-in (Day 28)
        IF v_day_num = 28 THEN
            FOR v_rec IN
                SELECT recipe_id, beauty_type, beauty_sub_type
                FROM recommend_recipes(p_user_id => p_user_id, p_limit => 1, p_mode => 'beauty'::TEXT)
            LOOP
                SELECT r.creator_id INTO v_row_creator_id FROM recipe r WHERE r.id = v_rec.recipe_id;
                IF v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR v_row_creator_id = v_fan_creator_id THEN
                    INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
                    VALUES (
                        v_plan_id, v_day_num, v_week_num, v_dow,
                        COALESCE(v_rec.beauty_type, 'both'),
                        'monthly_detox_checkin',
                        v_rec.recipe_id,
                        '1x_month'
                    );
                    IF v_fan_creator_id IS NOT NULL THEN
                        IF v_row_creator_id = v_fan_creator_id THEN
                            v_fan_count := v_fan_count + 1;
                        ELSE
                            v_other_count := v_other_count + 1;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END IF;

        v_day_num := v_day_num + 1;
        v_curr_date := v_curr_date + INTERVAL '1 day';
    END LOOP;

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
