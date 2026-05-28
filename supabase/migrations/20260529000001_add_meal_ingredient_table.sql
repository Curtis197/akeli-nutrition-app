-- =============================================================================
-- Migration: 20260529000001_add_meal_ingredient_table.sql
-- Description: Per-entry ingredient list scaled to user portion size
-- =============================================================================

CREATE TABLE public.meal_ingredient (
  id                  uuid    NOT NULL DEFAULT gen_random_uuid(),
  meal_plan_entry_id  uuid    NOT NULL REFERENCES public.meal_plan_entry(id) ON DELETE CASCADE,
  ingredient_id       uuid    REFERENCES public.ingredient(id),
  ingredient_name     text    NOT NULL,
  quantity            numeric NOT NULL,
  unit                text    NOT NULL,
  CONSTRAINT meal_ingredient_pkey PRIMARY KEY (id)
);

CREATE INDEX idx_meal_ingredient_entry ON public.meal_ingredient(meal_plan_entry_id);

ALTER TABLE public.meal_ingredient ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own meal ingredients"
ON public.meal_ingredient FOR SELECT
USING (
  auth.uid() = (
    SELECT mp.user_id
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mpe.id = meal_plan_entry_id
  )
);

COMMENT ON TABLE public.meal_ingredient IS
  'Pre-computed ingredient quantities scaled to the user portion size (recipe_ingredient.quantity × entry.servings). Populated at plan generation time.';
