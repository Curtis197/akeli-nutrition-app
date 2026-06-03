-- supabase/migrations/20260603000003_ingredient_rounding_schema.sql
-- Unit-level default rounding steps.
CREATE TABLE public.unit_rounding_config (
  unit          text PRIMARY KEY,
  rounding_step numeric NOT NULL
);

INSERT INTO public.unit_rounding_config (unit, rounding_step) VALUES
  ('unit',  0.5),
  ('piece', 0.5),
  ('tsp',   0.25),
  ('tbsp',  0.5),
  ('clove', 1),
  ('bunch', 1),
  ('can',   1),
  ('pot',   1),
  ('pinch', 0.5),
  ('g',     5),
  ('ml',    5),
  ('kg',    0.1),
  ('l',     0.1);

-- Per-(ingredient, unit) overrides. NULL rounding_step = no rounding.
CREATE TABLE public.ingredient_rounding_rule (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id   uuid NOT NULL REFERENCES public.ingredient(id) ON DELETE CASCADE,
  unit            text NOT NULL,
  rounding_step   numeric,
  UNIQUE (ingredient_id, unit)
);

-- Round qty to the nearest multiple of step.
-- GREATEST(step, ...) prevents non-zero quantities from rounding to 0.
CREATE OR REPLACE FUNCTION public.round_to_step(qty numeric, step numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN step IS NULL OR step = 0 THEN qty
    WHEN qty = 0                  THEN 0
    ELSE GREATEST(step, ROUND(qty / step) * step)
  END;
$$;
