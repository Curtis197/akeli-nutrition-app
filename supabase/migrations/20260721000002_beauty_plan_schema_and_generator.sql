-- ================================================================
-- AKELI BEAUTY MODE: BEAUTY PLAN TABLES & GENERATOR RPC
-- ================================================================

-- 1. BEAUTY PLAN TABLE
CREATE TABLE IF NOT EXISTS beauty_plan (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profile(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BEAUTY PLAN SLOT TABLE
CREATE TABLE IF NOT EXISTS beauty_plan_slot (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES beauty_plan(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    routine_category VARCHAR(20) NOT NULL CHECK (routine_category IN ('hair', 'skin', 'both')),
    step_stage VARCHAR(50) NOT NULL,
    recipe_id UUID NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES FOR FAST QUERYING
CREATE INDEX IF NOT EXISTS idx_beauty_plan_user ON beauty_plan(user_id, start_date);
CREATE INDEX IF NOT EXISTS idx_beauty_plan_slot_plan ON beauty_plan_slot(plan_id, day_of_week);

-- 3. BEAUTY PLAN GENERATOR RPC
CREATE OR REPLACE FUNCTION generate_beauty_plan(
    p_user_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_plan_id UUID;
    v_end_date DATE := p_start_date + INTERVAL '6 days';
    v_day SMALLINT;
    v_rec RECORD;
BEGIN
    -- Delete existing plan for the user in the target week if exists
    DELETE FROM beauty_plan 
    WHERE user_id = p_user_id AND start_date = p_start_date;

    -- Create new beauty plan
    INSERT INTO beauty_plan (user_id, start_date, end_date)
    VALUES (p_user_id, p_start_date, v_end_date)
    RETURNING id INTO v_plan_id;

    -- A. SCHEDULE DAILY REMEDIES (Days 1 to 7)
    FOR v_rec IN 
        SELECT recipe_id, beauty_type, beauty_sub_type 
        FROM recommend_recipes(p_user_id => p_user_id, p_limit => 5, p_mode => 'beauty', p_frequency => 'daily')
    LOOP
        FOR v_day IN 1..7 LOOP
            INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id)
            VALUES (
                v_plan_id, 
                v_day, 
                COALESCE(v_rec.beauty_type, 'both'), 
                COALESCE(v_rec.beauty_sub_type, 'daily_hydration'), 
                v_rec.recipe_id
            );
        END LOOP;
    END LOOP;

    -- B. SCHEDULE 2X / WEEK REMEDIES (Wednesday = Day 3, Saturday = Day 6)
    FOR v_rec IN 
        SELECT recipe_id, beauty_type, beauty_sub_type 
        FROM recommend_recipes(p_user_id => p_user_id, p_limit => 3, p_mode => 'beauty', p_frequency => '2x_week')
    LOOP
        INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id)
        VALUES 
            (v_plan_id, 3, COALESCE(v_rec.beauty_type, 'both'), COALESCE(v_rec.beauty_sub_type, 'treatment'), v_rec.recipe_id),
            (v_plan_id, 6, COALESCE(v_rec.beauty_type, 'both'), COALESCE(v_rec.beauty_sub_type, 'treatment'), v_rec.recipe_id);
    END LOOP;

    -- C. SCHEDULE 1X / WEEK REMEDIES (Sunday Wash Day & Deep Mask = Day 7)
    FOR v_rec IN 
        SELECT recipe_id, beauty_type, beauty_sub_type 
        FROM recommend_recipes(p_user_id => p_user_id, p_limit => 3, p_mode => 'beauty', p_frequency => '1x_week')
    LOOP
        INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id)
        VALUES (
            v_plan_id, 
            7, 
            COALESCE(v_rec.beauty_type, 'both'), 
            COALESCE(v_rec.beauty_sub_type, 'deep_treatment'), 
            v_rec.recipe_id
        );
    END LOOP;

    RETURN v_plan_id;
END;
$$;
