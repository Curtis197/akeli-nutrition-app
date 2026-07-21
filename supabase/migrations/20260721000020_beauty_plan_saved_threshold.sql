-- Migration: 20260721000020_beauty_plan_saved_threshold.sql
-- Description: Add minimum pool threshold and fallback logic to generate_beauty_plan_from_saved for parity with Nutrition mode

CREATE OR REPLACE FUNCTION generate_beauty_plan_from_saved(
  p_user_id                    UUID,
  p_start_date                 DATE DEFAULT CURRENT_DATE,
  p_days                       INT DEFAULT 30,
  p_min_saved_threshold        INT DEFAULT 3,
  p_fallback_to_recommended    BOOLEAN DEFAULT true
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
    v_saved_pool_count INT;
BEGIN
    -- Check minimum saved beauty recipe pool count for user
    SELECT COUNT(DISTINCT r.id) INTO v_saved_pool_count
    FROM recipe r
    JOIN recipe_save rs ON r.id = rs.recipe_id
    WHERE rs.user_id = p_user_id 
      AND r.is_published = true 
      AND r.mode = 'beauty';

    -- Threshold validation
    IF v_saved_pool_count < p_min_saved_threshold THEN
        IF p_fallback_to_recommended THEN
            RAISE NOTICE 'Pool of saved beauty recipes (%) is below threshold (%). Falling back to standard recommended beauty plan.', v_saved_pool_count, p_min_saved_threshold;
            RETURN generate_beauty_plan(p_user_id, p_start_date, p_days);
        ELSE
            RAISE EXCEPTION 'insufficient_saved_beauty_recipes' 
              USING DETAIL = 'Nombre de recettes beauté enregistrées (' || v_saved_pool_count || ') insuffisant (seuil minimum: ' || p_min_saved_threshold || ').';
        END IF;
    END IF;

    -- Deactivate previous active beauty plans
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

        -- Daily routine slots from saved recipes
        v_found := FALSE;
        FOR v_rec IN 
            SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type 
            FROM recipe r
            JOIN recipe_save rs ON r.id = rs.recipe_id
            WHERE rs.user_id = p_user_id 
              AND r.is_published = true 
              AND r.mode = 'beauty'
            ORDER BY RANDOM()
            LIMIT 2
        LOOP
            v_found := TRUE;
            INSERT INTO beauty_plan_slot (plan_id, day_number, week_number, day_of_week, routine_category, step_stage, recipe_id, frequency_tier)
            VALUES (
                v_plan_id, v_day_num, v_week_num, v_dow,
                COALESCE(v_rec.beauty_type, 'both'),
                COALESCE(v_rec.beauty_sub_type, 'daily_hydration'),
                v_rec.recipe_id,
                'daily'
            );
        END LOOP;

        -- Fallback to recommend_recipes if specific slot query found nothing
        IF NOT v_found THEN
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
        END IF;

        -- Midweek treatment (Wednesdays & Saturdays)
        IF v_dow IN (3, 6) THEN
            FOR v_rec IN 
                SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type 
                FROM recipe r
                JOIN recipe_save rs ON r.id = rs.recipe_id
                WHERE rs.user_id = p_user_id 
                  AND r.is_published = true 
                  AND r.mode = 'beauty'
                ORDER BY RANDOM()
                LIMIT 1
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

        -- Sunday Wash Day Mask
        IF v_dow = 7 THEN
            FOR v_rec IN 
                SELECT r.id AS recipe_id, r.beauty_type, r.beauty_sub_type 
                FROM recipe r
                JOIN recipe_save rs ON r.id = rs.recipe_id
                WHERE rs.user_id = p_user_id 
                  AND r.is_published = true 
                  AND r.mode = 'beauty'
                ORDER BY RANDOM()
                LIMIT 1
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
