-- =============================================================================
-- Migration: 20260525000003_nutrition_plan.sql
-- Description: Create nutrition_plan and meal_distribution tables with triggers
-- =============================================================================

-- 1. Create nutrition_plan table
CREATE TABLE public.nutrition_plan (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.user_profile(id) ON DELETE CASCADE,
    calorie_goal integer NOT NULL,
    protein_goal_g numeric NOT NULL,
    carb_goal_g numeric NOT NULL,
    fat_goal_g numeric NOT NULL,
    bmr numeric,
    tdee numeric,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT nutrition_plan_pkey PRIMARY KEY (id)
);

-- 2. Create meal_distribution table
CREATE TABLE public.meal_distribution (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nutrition_plan_id uuid NOT NULL REFERENCES public.nutrition_plan(id) ON DELETE CASCADE,
    meal_type text NOT NULL,
    sort_order integer NOT NULL,
    calorie_pct numeric NOT NULL,
    calorie_target numeric NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT meal_distribution_pkey PRIMARY KEY (id)
);

-- 3. RLS Policies
ALTER TABLE public.nutrition_plan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_distribution ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own nutrition plans"
ON public.nutrition_plan FOR ALL
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own meal distributions"
ON public.meal_distribution FOR ALL
USING (auth.uid() = (SELECT user_id FROM public.nutrition_plan WHERE id = nutrition_plan_id));

-- 4. Triggers

-- A. trg_one_active_nutrition_plan
-- Deactivates previous active plans on insert or update if new plan is_active = true
CREATE OR REPLACE FUNCTION deactivate_other_nutrition_plans()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_active = true THEN
        UPDATE public.nutrition_plan
        SET is_active = false
        WHERE user_id = NEW.user_id AND id != NEW.id AND is_active = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_one_active_nutrition_plan
BEFORE INSERT OR UPDATE OF is_active ON public.nutrition_plan
FOR EACH ROW
EXECUTE FUNCTION deactivate_other_nutrition_plans();

-- B. trg_sync_calorie_target_on_plan
-- Updates calorie_target for all child meal_distributions when nutrition_plan.calorie_goal changes
CREATE OR REPLACE FUNCTION sync_calorie_target_on_plan_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.calorie_goal IS DISTINCT FROM OLD.calorie_goal THEN
        UPDATE public.meal_distribution
        SET calorie_target = (NEW.calorie_goal * calorie_pct / 100.0)
        WHERE nutrition_plan_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_calorie_target_on_plan
AFTER UPDATE OF calorie_goal ON public.nutrition_plan
FOR EACH ROW
EXECUTE FUNCTION sync_calorie_target_on_plan_update();

-- C. trg_sync_calorie_target_on_dist
-- Computes calorie_target based on parent's calorie_goal when meal_distribution is created or calorie_pct changes
CREATE OR REPLACE FUNCTION sync_calorie_target_on_dist_change()
RETURNS TRIGGER AS $$
DECLARE
    v_calorie_goal integer;
BEGIN
    SELECT calorie_goal INTO v_calorie_goal
    FROM public.nutrition_plan
    WHERE id = NEW.nutrition_plan_id;

    IF v_calorie_goal IS NOT NULL THEN
        NEW.calorie_target := (v_calorie_goal * NEW.calorie_pct / 100.0);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_calorie_target_on_dist
BEFORE INSERT OR UPDATE OF calorie_pct ON public.meal_distribution
FOR EACH ROW
EXECUTE FUNCTION sync_calorie_target_on_dist_change();

-- D. Updated_at trigger for nutrition_plan
CREATE OR REPLACE FUNCTION public.set_nutrition_plan_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_updated_at_nutrition_plan
BEFORE UPDATE ON public.nutrition_plan
FOR EACH ROW
EXECUTE FUNCTION public.set_nutrition_plan_updated_at();
