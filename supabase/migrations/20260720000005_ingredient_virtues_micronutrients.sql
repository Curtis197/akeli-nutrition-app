-- ================================================================
-- AKELI BEAUTY MODE: INGREDIENT VIRTUES, MICRONUTRIENTS & DYNAMIC RECIPE ENGINE
-- ================================================================

-- 1. EXTEND INGREDIENT TABLE WITH BEAUTY VIRTUES AND MICRONUTRIENTS
ALTER TABLE ingredient
  ADD COLUMN IF NOT EXISTS beauty_virtues TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS micronutrients JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS active_key VARCHAR(50) DEFAULT NULL;

COMMENT ON COLUMN ingredient.beauty_virtues IS 'Virtues imparted by this ingredient (growth_retention, anti_breakage, intense_hydration, sebum_balance, scalp_soothing, glow_brightening, protective_care)';
COMMENT ON COLUMN ingredient.micronutrients IS 'Key micronutrients, minerals, and fatty acids (vit_a_mg, vit_c_mg, vit_e_mg, zinc_mg, lauric_acid_pct, ricinoleic_acid_pct)';
COMMENT ON COLUMN ingredient.active_key IS 'Standardized bio-active key mapping to vector space (shea_butter, chebe, aloe_vera, black_seed, argan, ricin, hibiscus, clay, jojoba)';

-- 2. SEED BIO-ACTIVES, VIRTUES & MICRONUTRIENTS FOR TOP INGREDIENTS
INSERT INTO ingredient (name, mode, active_key, beauty_virtues, micronutrients)
VALUES
(
  'Beurre de Karité Brut', 'beauty', 'shea_butter',
  ARRAY['anti_breakage', 'intense_hydration'],
  '{"vit_e_mg": 2.5, "cinnamates_pct": 5.0, "stearic_acid_pct": 40.0, "oleic_acid_pct": 45.0}'::jsonb
),
(
  'Poudre de Chébé Traditionnelle', 'beauty', 'chebe',
  ARRAY['growth_retention', 'anti_breakage'],
  '{"alkaloids_pct": 3.2, "tannins_pct": 4.5}'::jsonb
),
(
  'Gel d''Aloé Véra Pur', 'beauty', 'aloe_vera',
  ARRAY['intense_hydration', 'glow_brightening', 'scalp_soothing'],
  '{"vit_c_mg": 12.0, "vit_e_mg": 0.8, "zinc_mg": 0.4, "acemannan_pct": 15.0}'::jsonb
),
(
  'Huile de Nigelle (Cumin Noir)', 'beauty', 'black_seed',
  ARRAY['sebum_balance', 'scalp_soothing'],
  '{"thymoquinone_pct": 1.5, "omega_6_pct": 55.0, "omega_9_pct": 22.0}'::jsonb
),
(
  'Huile d''Argan Pressée à Froid', 'beauty', 'argan',
  ARRAY['intense_hydration', 'anti_breakage'],
  '{"vit_e_mg": 60.0, "squalene_mg": 300.0}'::jsonb
),
(
  'Huile de Ricin Noire', 'beauty', 'ricin',
  ARRAY['growth_retention', 'anti_breakage'],
  '{"ricinoleic_acid_pct": 85.0, "vit_e_mg": 1.2}'::jsonb
),
(
  'Fleurs d''Hibiscus Séchées (Karkadé)', 'beauty', 'hibiscus',
  ARRAY['glow_brightening', 'growth_retention'],
  '{"vit_c_mg": 45.0, "anthocyanins_pct": 8.0, "aha_pct": 3.5}'::jsonb
),
(
  'Argile Verte Surfine', 'beauty', 'clay',
  ARRAY['sebum_balance', 'scalp_soothing'],
  '{"silica_pct": 48.0, "zinc_pct": 0.5, "iron_pct": 4.2}'::jsonb
),
(
  'Huile de Jojoba Végétale', 'beauty', 'jojoba',
  ARRAY['sebum_balance', 'protective_care'],
  '{"wax_esters_pct": 97.0, "vit_e_mg": 1.5}'::jsonb
)
ON CONFLICT DO NOTHING;

-- 3. STORED FUNCTION: COMPUTE RECIPE VIRTUES FROM INGREDIENTS
CREATE OR REPLACE FUNCTION compute_recipe_virtues(p_recipe_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_virtues text[];
BEGIN
  SELECT ARRAY(
    SELECT DISTINCT unnest(i.beauty_virtues)
    FROM recipe_ingredient ri
    JOIN ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = p_recipe_id
      AND i.beauty_virtues IS NOT NULL
  ) INTO v_virtues;

  IF array_length(v_virtues, 1) > 0 THEN
    UPDATE recipe
    SET virtues = v_virtues
    WHERE id = p_recipe_id;
  END IF;

  RETURN v_virtues;
END;
$$;

-- 4. TRIGGER: AUTO UPDATE RECIPE VIRTUES ON RECIPE INGREDIENT CHANGE
CREATE OR REPLACE FUNCTION trg_fn_update_recipe_virtues()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM compute_recipe_virtues(OLD.recipe_id);
    RETURN OLD;
  ELSE
    PERFORM compute_recipe_virtues(NEW.recipe_id);
    RETURN NEW;
  END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_recipe_ingredient_virtues ON recipe_ingredient;
CREATE TRIGGER trg_recipe_ingredient_virtues
  AFTER INSERT OR UPDATE OR DELETE ON recipe_ingredient
  FOR EACH ROW
  EXECUTE FUNCTION trg_fn_update_recipe_virtues();
