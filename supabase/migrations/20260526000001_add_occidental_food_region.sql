-- Add occidental (Europe + North America) as a food region option for onboarding
INSERT INTO food_region (code, name_fr, name_en, name_es, name_pt)
VALUES ('occidental', 'Occident', 'Occidental', 'Occidental', 'Ocidental')
ON CONFLICT (code) DO NOTHING;
