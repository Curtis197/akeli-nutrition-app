-- Beauty Mode Database Schema
-- Handles dynamic care plans, usage-based remuneration, and fan mode features

-- ============================================
-- 1. BEAUTY PLANS (Subscription/Program templates)
-- ============================================
CREATE TABLE beauty_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES auth.users(id) NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('hair', 'skin', 'nails', 'body', 'wellness')),
    sub_category TEXT, -- e.g., 'natural_hair', 'acne_prone', 'sensitive_skin'
    
    -- Remuneration config
    base_price_cents INTEGER DEFAULT 100 CHECK (base_price_cents >= 0), -- 1€ = 100 cents minimum
    currency TEXT DEFAULT 'EUR',
    
    -- Plan structure
    total_cares INTEGER, -- Total number of care sessions in plan
    duration_days INTEGER, -- Plan duration
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    
    -- Cultural metadata
    cultural_origin TEXT[], -- e.g., ['west_african', 'caribbean']
    traditional_ingredients TEXT[], -- e.g., ['shea_butter', 'black_soap', 'argan_oil']
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_premium BOOLEAN DEFAULT false, -- Fan mode exclusive
    
    -- Metrics
    subscriber_count INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    total_ratings INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    
    CONSTRAINT valid_price CHECK (base_price_cents >= 100),
    CONSTRAINT valid_duration CHECK (duration_days > 0 AND duration_days <= 365)
);

-- Indexes for performance
CREATE INDEX idx_beauty_plans_creator ON beauty_plans(creator_id);
CREATE INDEX idx_beauty_plans_category ON beauty_plans(category);
CREATE INDEX idx_beauty_plans_cultural ON beauty_plans USING GIN(cultural_origin);
CREATE INDEX idx_beauty_plans_featured ON beauty_plans(is_featured) WHERE is_featured = true;
CREATE INDEX idx_beauty_plans_premium ON beauty_plans(is_premium) WHERE is_premium = true;

-- ============================================
-- 2. BEAUTY ENTRIES (Individual care items within a plan)
-- ============================================
CREATE TABLE beauty_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID REFERENCES beauty_plans(id) ON DELETE CASCADE NOT NULL,
    creator_id UUID REFERENCES auth.users(id) NOT NULL,
    
    -- Care details
    title TEXT NOT NULL,
    description TEXT,
    care_type TEXT NOT NULL CHECK (care_type IN ('cleansing', 'treatment', 'mask', 'oil_application', 'massage', 'styling', 'protection')),
    
    -- Step configuration
    step_number INTEGER NOT NULL CHECK (step_number > 0),
    duration_minutes INTEGER DEFAULT 15 CHECK (duration_minutes > 0),
    frequency TEXT CHECK (frequency IN ('daily', 'weekly', 'bi_weekly', 'monthly', 'as_needed')),
    
    -- Ingredients & products
    ingredients JSONB, -- [{name, quantity, unit, traditional_use}]
    required_products JSONB, -- [{product_name, brand, alternative}]
    
    -- Instructions
    instructions TEXT[], -- Step-by-step array
    video_url TEXT,
    image_urls TEXT[],
    
    -- Cultural context
    cultural_significance TEXT,
    traditional_tips TEXT[],
    
    -- Remuneration tracking
    price_cents INTEGER DEFAULT 100 CHECK (price_cents >= 100), -- 1€/n_cares calculation base
    is_bonus BOOLEAN DEFAULT false, -- Bonus content for fan mode
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_step_per_plan UNIQUE(plan_id, step_number)
);

-- Indexes
CREATE INDEX idx_beauty_entries_plan ON beauty_entries(plan_id);
CREATE INDEX idx_beauty_entries_creator ON beauty_entries(creator_id);
CREATE INDEX idx_beauty_entries_type ON beauty_entries(care_type);
CREATE INDEX idx_beauty_entries_frequency ON beauty_entries(frequency);

-- ============================================
-- 3. BEAUTY LOGS (User tracking of care completion)
-- ============================================
CREATE TABLE beauty_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plan_id UUID REFERENCES beauty_plans(id) ON DELETE SET NULL,
    entry_id UUID REFERENCES beauty_entries(id) ON DELETE SET NULL,
    
    -- Session details
    scheduled_date DATE NOT NULL,
    completed_date TIMESTAMPTZ,
    status TEXT NOT NULL CHECK (status IN ('scheduled', 'in_progress', 'completed', 'skipped', 'missed')) DEFAULT 'scheduled',
    
    -- Duration tracking
    planned_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    
    -- User feedback
    mood_before TEXT, -- e.g., 'stressed', 'tired', 'neutral'
    mood_after TEXT, -- e.g., 'relaxed', 'energized', 'calm'
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    notes TEXT,
    
    -- Skin/Hair condition (optional tracking)
    skin_condition_before JSONB, -- {hydration, brightness, texture, issues[]}
    skin_condition_after JSONB,
    hair_condition_before JSONB, -- {moisture, shine, strength, breakage}
    hair_condition_after JSONB,
    
    -- Photos (progress tracking)
    before_photo_urls TEXT[],
    after_photo_urls TEXT[],
    
    -- Creator remuneration trigger
    remuneration_credits_cents INTEGER DEFAULT 0, -- Amount earned by creator for this session
    remuneration_status TEXT CHECK (remuneration_status IN ('pending', 'processed', 'paid')) DEFAULT 'pending',
    processed_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_completion CHECK (completed_date IS NULL OR completed_date >= scheduled_date)
);

-- Indexes for user dashboards and creator analytics
CREATE INDEX idx_beauty_logs_user ON beauty_logs(user_id);
CREATE INDEX idx_beauty_logs_plan ON beauty_logs(plan_id);
CREATE INDEX idx_beauty_logs_entry ON beauty_logs(entry_id);
CREATE INDEX idx_beauty_logs_status ON beauty_logs(status);
CREATE INDEX idx_beauty_logs_scheduled ON beauty_logs(scheduled_date);
CREATE INDEX idx_beauty_logs_completed ON beauty_logs(completed_date);
CREATE INDEX idx_beauty_logs_remuneration ON beauty_logs(remuneration_status) WHERE remuneration_status = 'pending';

-- Composite index for user's daily logs
CREATE INDEX idx_beauty_logs_user_date ON beauty_logs(user_id, scheduled_date);

-- ============================================
-- 4. BEAUTY ANALYTICS (Aggregated metrics for creators)
-- ============================================
CREATE TABLE beauty_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plan_id UUID REFERENCES beauty_plans(id) ON DELETE CASCADE,
    
    -- Period
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Engagement metrics
    total_subscribers INTEGER DEFAULT 0,
    active_subscribers INTEGER DEFAULT 0, -- Completed at least 1 care in period
    new_subscribers INTEGER DEFAULT 0,
    churned_subscribers INTEGER DEFAULT 0,
    
    -- Completion metrics
    total_cares_scheduled INTEGER DEFAULT 0,
    total_cares_completed INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0,
    average_session_duration_minutes DECIMAL(8,2) DEFAULT 0,
    
    -- Satisfaction metrics
    average_satisfaction_rating DECIMAL(3,2) DEFAULT 0,
    total_ratings INTEGER DEFAULT 0,
    net_promoter_score INTEGER DEFAULT 0,
    
    -- Remuneration metrics
    total_revenue_cents INTEGER DEFAULT 0,
    platform_fee_cents INTEGER DEFAULT 0,
    creator_earnings_cents INTEGER DEFAULT 0,
    pending_payout_cents INTEGER DEFAULT 0,
    paid_out_cents INTEGER DEFAULT 0,
    
    -- Fan mode specific
    fan_mode_subscribers INTEGER DEFAULT 0,
    fan_mode_exclusive_content_views INTEGER DEFAULT 0,
    fan_mode_bonus_earnings_cents INTEGER DEFAULT 0,
    
    -- Top performing entries
    top_entry_id UUID REFERENCES beauty_entries(id),
    top_entry_completions INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_period CHECK (period_end >= period_start),
    CONSTRAINT unique_creator_plan_period UNIQUE(creator_id, plan_id, period_start, period_end)
);

-- Indexes
CREATE INDEX idx_beauty_analytics_creator ON beauty_analytics(creator_id);
CREATE INDEX idx_beauty_analytics_plan ON beauty_analytics(plan_id);
CREATE INDEX idx_beauty_analytics_period ON beauty_analytics(period_start, period_end);
CREATE INDEX idx_beauty_analytics_payout ON beauty_analytics(creator_id, pending_payout_cents) WHERE pending_payout_cents > 0;

-- ============================================
-- 5. BEAUTY RECIPES (DIY formulations & traditional remedies)
-- ============================================
CREATE TABLE beauty_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES auth.users(id) NOT NULL,
    plan_id UUID REFERENCES beauty_plans(id) ON DELETE SET NULL,
    
    -- Recipe details
    title TEXT NOT NULL,
    description TEXT,
    recipe_type TEXT NOT NULL CHECK (recipe_type IN ('mask', 'scrub', 'oil_blend', 'toner', 'cream', 'serum', 'balm')),
    
    -- Target concerns
    target_concerns TEXT[], -- e.g., ['dryness', 'acne', 'hyperpigmentation', 'breakage']
    skin_types TEXT[], -- e.g., ['oily', 'dry', 'combination', 'sensitive']
    hair_types TEXT[], -- e.g., ['4c', '3b', 'wavy', 'straight']
    
    -- Ingredients
    ingredients JSONB NOT NULL, -- [{name, quantity, unit, preparation_notes, sourcing_tips}]
    
    -- Instructions
    preparation_steps TEXT[] NOT NULL,
    application_instructions TEXT,
    duration_minutes INTEGER,
    frequency_recommendation TEXT,
    
    -- Traditional knowledge
    cultural_origin TEXT,
    traditional_use_history TEXT,
    elder_wisdom_notes TEXT,
    
    -- Safety & storage
    contraindications TEXT[],
    shelf_life_days INTEGER,
    storage_instructions TEXT,
    
    -- Media
    image_urls TEXT[],
    video_url TEXT,
    
    -- Community engagement
    times_saved INTEGER DEFAULT 0,
    times_made INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    total_ratings INTEGER DEFAULT 0,
    
    -- Monetization (optional premium recipes)
    is_premium BOOLEAN DEFAULT false,
    price_cents INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false, -- Verified by AKELI team
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_shelf_life CHECK (shelf_life_days IS NULL OR shelf_life_days > 0)
);

-- Indexes
CREATE INDEX idx_beauty_recipes_creator ON beauty_recipes(creator_id);
CREATE INDEX idx_beauty_recipes_plan ON beauty_recipes(plan_id);
CREATE INDEX idx_beauty_recipes_type ON beauty_recipes(recipe_type);
CREATE INDEX idx_beauty_recipes_concerns ON beauty_recipes USING GIN(target_concerns);
CREATE INDEX idx_beauty_recipes_premium ON beauty_recipes(is_premium) WHERE is_premium = true;

-- ============================================
-- 6. FAN MODE SUBSCRIPTIONS (Exclusive creator support)
-- ============================================
CREATE TABLE fan_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Subscription tier
    tier TEXT NOT NULL CHECK (tier IN ('supporter', 'vip', 'ultra_fan')),
    tier_benefits JSONB, -- Custom benefits per tier
    
    -- Payment
    monthly_price_cents INTEGER NOT NULL CHECK (monthly_price_cents >= 500), -- Min 5€
    currency TEXT DEFAULT 'EUR',
    
    -- Status
    status TEXT NOT NULL CHECK (status IN ('active', 'cancelled', 'expired', 'paused')) DEFAULT 'active',
    current_period_start DATE NOT NULL,
    current_period_end DATE NOT NULL,
    cancelled_at TIMESTAMPTZ,
    cancel_reason TEXT,
    
    -- Engagement tracking
    exclusive_content_unlocks INTEGER DEFAULT 0,
    bonus_content_views INTEGER DEFAULT 0,
    direct_messages_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_user_creator UNIQUE(user_id, creator_id),
    CONSTRAINT valid_subscription_period CHECK (current_period_end >= current_period_start)
);

-- Indexes
CREATE INDEX idx_fan_subscriptions_user ON fan_subscriptions(user_id);
CREATE INDEX idx_fan_subscriptions_creator ON fan_subscriptions(creator_id);
CREATE INDEX idx_fan_subscriptions_status ON fan_subscriptions(status);
CREATE INDEX idx_fan_subscriptions_tier ON fan_subscriptions(tier);

-- ============================================
-- 7. CREATOR PAYOUTS (Remuneration tracking)
-- ============================================
CREATE TABLE creator_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES auth.users(id) NOT NULL,
    
    -- Period
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Earnings breakdown
    nutrition_meal_earnings_cents INTEGER DEFAULT 0, -- 1/90€ per meal
    beauty_care_earnings_cents INTEGER DEFAULT 0, -- 1€/n_cares
    fan_mode_earnings_cents INTEGER DEFAULT 0,
    recipe_sales_earnings_cents INTEGER DEFAULT 0,
    bonus_earnings_cents INTEGER DEFAULT 0,
    
    -- Totals
    gross_earnings_cents INTEGER NOT NULL,
    platform_fee_cents INTEGER NOT NULL,
    net_earnings_cents INTEGER NOT NULL,
    
    -- Payment details
    payout_method TEXT CHECK (payout_method IN ('bank_transfer', 'paypal', 'stripe', 'mobile_money')),
    payout_account_info JSONB, -- Encrypted payment details
    payout_status TEXT CHECK (payout_status IN ('pending', 'processing', 'paid', 'failed')) DEFAULT 'pending',
    payout_date TIMESTAMPTZ,
    payout_reference TEXT,
    
    -- Notes
    admin_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    requested_at TIMESTAMPTZ,
    
    CONSTRAINT valid_period CHECK (period_end >= period_start),
    CONSTRAINT valid_earnings CHECK (net_earnings_cents = gross_earnings_cents - platform_fee_cents)
);

-- Indexes
CREATE INDEX idx_creator_payouts_creator ON creator_payouts(creator_id);
CREATE INDEX idx_creator_payouts_status ON creator_payouts(payout_status);
CREATE INDEX idx_creator_payouts_period ON creator_payouts(period_start, period_end);
CREATE INDEX idx_creator_payouts_pending ON creator_payouts(payout_status) WHERE payout_status = 'pending';

-- ============================================
-- 8. TRIGGERS & FUNCTIONS
-- ============================================

-- Function: Update beauty_plans subscriber count
CREATE OR REPLACE FUNCTION update_plan_subscriber_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE beauty_plans 
        SET subscriber_count = subscriber_count + 1,
            updated_at = NOW()
        WHERE id = NEW.plan_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE beauty_plans 
        SET subscriber_count = GREATEST(0, subscriber_count - 1),
            updated_at = NOW()
        WHERE id = OLD.plan_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_plan_subscribers
AFTER INSERT OR DELETE ON beauty_logs
FOR EACH ROW
EXECUTE FUNCTION update_plan_subscriber_count();

-- Function: Calculate creator earnings from beauty logs
CREATE OR REPLACE FUNCTION calculate_beauty_earnings(p_creator_id UUID, p_period_start DATE, p_period_end DATE)
RETURNS TABLE (
    total_cares INTEGER,
    total_revenue_cents INTEGER,
    creator_earnings_cents INTEGER
) AS $$
DECLARE
    v_total_cares INTEGER;
    v_avg_price_cents NUMERIC;
BEGIN
    -- Count completed cares in period
    SELECT COUNT(*), AVG(remuneration_credits_cents)
    INTO v_total_cares, v_avg_price_cents
    FROM beauty_logs
    WHERE status = 'completed'
      AND creator_id = p_creator_id
      AND completed_date BETWEEN p_period_start AND p_period_end;
    
    total_cares := COALESCE(v_total_cares, 0);
    
    -- Revenue = sum of all care credits
    SELECT COALESCE(SUM(remuneration_credits_cents), 0)
    INTO total_revenue_cents
    FROM beauty_logs
    WHERE status = 'completed'
      AND creator_id = p_creator_id
      AND completed_date BETWEEN p_period_start AND p_period_end;
    
    -- Creator earnings (after platform fee, e.g., 20%)
    creator_earnings_cents := (total_revenue_cents * 0.8)::INTEGER;
    
    RETURN QUERY SELECT total_cares, total_revenue_cents, creator_earnings_cents;
END;
$$ LANGUAGE plpgsql;

-- Function: Auto-process remuneration for completed logs
CREATE OR REPLACE FUNCTION process_beauty_remuneration()
RETURNS TRIGGER AS $$
DECLARE
    v_entry_price INTEGER;
    v_creator_id UUID;
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.remuneration_credits_cents = 0 THEN
        -- Get entry price or default
        SELECT price_cents, creator_id INTO v_entry_price, v_creator_id
        FROM beauty_entries
        WHERE id = NEW.entry_id;
        
        IF v_entry_price IS NULL THEN
            v_entry_price := 100; -- Default 1€
        END IF;
        
        -- Set remuneration credits
        NEW.remuneration_credits_cents := v_entry_price;
        NEW.remuneration_status := 'pending';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_process_beauty_remuneration
BEFORE UPDATE ON beauty_logs
FOR EACH ROW
EXECUTE FUNCTION process_beauty_remuneration();

-- ============================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

ALTER TABLE beauty_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE beauty_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE beauty_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE beauty_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE beauty_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_payouts ENABLE ROW LEVEL SECURITY;

-- Beauty Plans: Public read, creator write
CREATE POLICY "Anyone can view active beauty plans"
ON beauty_plans FOR SELECT
USING (is_active = true);

CREATE POLICY "Creators can manage their own plans"
ON beauty_plans FOR ALL
USING (creator_id = auth.uid());

-- Beauty Entries: Public read for active plans, creator write
CREATE POLICY "Anyone can view entries from active plans"
ON beauty_entries FOR SELECT
USING (is_active = true);

CREATE POLICY "Creators can manage their own entries"
ON beauty_entries FOR ALL
USING (creator_id = auth.uid());

-- Beauty Logs: Users can only see their own logs
CREATE POLICY "Users can view their own logs"
ON beauty_logs FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own logs"
ON beauty_logs FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own logs"
ON beauty_logs FOR UPDATE
USING (user_id = auth.uid());

-- Creators can view logs for their plans
CREATE POLICY "Creators can view logs for their plans"
ON beauty_logs FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM beauty_plans 
        WHERE beauty_plans.id = beauty_logs.plan_id 
        AND beauty_plans.creator_id = auth.uid()
    )
);

-- Beauty Analytics: Creators can only see their own
CREATE POLICY "Creators can view their own analytics"
ON beauty_analytics FOR SELECT
USING (creator_id = auth.uid());

-- Beauty Recipes: Public read, creator write
CREATE POLICY "Anyone can view active recipes"
ON beauty_recipes FOR SELECT
USING (is_active = true);

CREATE POLICY "Creators can manage their own recipes"
ON beauty_recipes FOR ALL
USING (creator_id = auth.uid());

-- Fan Subscriptions: Users see their own, creators see their subscribers
CREATE POLICY "Users can view their own subscriptions"
ON fan_subscriptions FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can create their own subscriptions"
ON fan_subscriptions FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Creators can view their subscribers"
ON fan_subscriptions FOR SELECT
USING (creator_id = auth.uid());

-- Creator Payouts: Only creators can see their own
CREATE POLICY "Creators can view their own payouts"
ON creator_payouts FOR SELECT
USING (creator_id = auth.uid());

-- ============================================
-- 10. SAMPLE DATA (For testing)
-- ============================================

-- Sample Beauty Plan: Natural Hair Growth Journey
INSERT INTO beauty_plans (
    creator_id, title, description, category, sub_category,
    base_price_cents, total_cares, duration_days, difficulty_level,
    cultural_origin, traditional_ingredients, is_featured
) VALUES (
    (SELECT id FROM auth.users LIMIT 1),
    'Natural Hair Growth Journey',
    'A 30-day traditional West African hair care routine using shea butter, black soap, and natural oils',
    'hair', 'natural_hair',
    1500, 30, 30, 'beginner',
    ARRAY['west_african', 'yoruba'],
    ARRAY['shea_butter', 'black_soap', 'castor_oil', 'neem_oil'],
    true
);

-- Sample Beauty Entry: Weekly Deep Conditioning
INSERT INTO beauty_entries (
    plan_id, creator_id, title, description, care_type,
    step_number, duration_minutes, frequency,
    ingredients, instructions, cultural_significance, price_cents
) VALUES (
    (SELECT id FROM beauty_plans LIMIT 1),
    (SELECT id FROM auth.users LIMIT 1),
    'Weekly Shea Butter Deep Condition',
    'Intensive moisturizing treatment using raw shea butter',
    'treatment',
    1, 45, 'weekly',
    '[{"name": "Raw Shea Butter", "quantity": 100, "unit": "g", "traditional_use": "Moisturizing and healing"}, {"name": "Coconut Oil", "quantity": 50, "unit": "ml", "traditional_use": "Penetration and shine"}]',
    ARRAY[
        'Melt shea butter and coconut oil together',
        'Apply to damp hair from root to tip',
        'Cover with plastic cap and leave for 30-45 minutes',
        'Rinse with lukewarm water and gentle shampoo'
    ],
    'Shea butter has been used for centuries in West Africa for hair and skin protection',
    150
);

COMMENT ON TABLE beauty_plans IS 'Beauty care plans/subscriptions created by wellness creators';
COMMENT ON TABLE beauty_entries IS 'Individual care sessions within a beauty plan';
COMMENT ON TABLE beauty_logs IS 'User tracking of beauty care completion and progress';
COMMENT ON TABLE beauty_analytics IS 'Aggregated metrics for creator performance and earnings';
COMMENT ON TABLE beauty_recipes IS 'DIY beauty formulations and traditional remedies';
COMMENT ON TABLE fan_subscriptions IS 'Fan mode exclusive creator subscriptions';
COMMENT ON TABLE creator_payouts IS 'Creator remuneration tracking across all modes';
