-- Enable RLS on rounding config tables.
-- Clients may read; only service_role may write (managed via admin tooling).
ALTER TABLE public.unit_rounding_config       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredient_rounding_rule   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated reads unit_rounding_config"
  ON public.unit_rounding_config FOR SELECT
  USING (auth.role() IN ('authenticated', 'anon'));

CREATE POLICY "authenticated reads ingredient_rounding_rule"
  ON public.ingredient_rounding_rule FOR SELECT
  USING (auth.role() = 'authenticated');
