-- =============================================================================
-- AKELI V1 — Modular Meal & Batch Cooking
-- Migration: 20260516000001_modular_meal_batch_cooking.sql
-- Spec: docs/akeli_session_avril_2026/V1_MODULAR_MEAL_BATCH_CONCILIATION.md
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. cooking_session
-- Une session de cuisson produit N portions d'une recette pour la semaine.
-- Le lien avec les entrées du plan est au niveau composant (cooking_session_id
-- sur meal_plan_entry_component), pas au niveau de meal_plan_entry.
-- ---------------------------------------------------------------------------

CREATE TABLE cooking_session (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  meal_plan_id    uuid REFERENCES meal_plan(id) ON DELETE CASCADE,
  recipe_id       uuid REFERENCES recipe(id) ON DELETE SET NULL,
  planned_date    date NOT NULL,
  total_portions  int NOT NULL CHECK (total_portions > 0),
  portions_used   int NOT NULL DEFAULT 0 CHECK (portions_used >= 0),
  notes           text,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_cooking_session_user      ON cooking_session(user_id);
CREATE INDEX idx_cooking_session_meal_plan ON cooking_session(meal_plan_id);
CREATE INDEX idx_cooking_session_date      ON cooking_session(planned_date);

ALTER TABLE cooking_session ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only cooking_session" ON cooking_session
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_cooking_session_updated_at
  BEFORE UPDATE ON cooking_session
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- 2. meal_plan_entry_component
-- Un repas est composé de N composants (base, starch, side).
-- consumption_weight = 1/N, recalculé automatiquement par trigger.
-- ---------------------------------------------------------------------------

CREATE TABLE meal_plan_entry_component (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_plan_entry_id  uuid REFERENCES meal_plan_entry(id) ON DELETE CASCADE,
  recipe_id           uuid REFERENCES recipe(id) ON DELETE CASCADE,
  role                text NOT NULL CHECK (role IN ('base', 'starch', 'side')),
  consumption_weight  numeric(4,3) NOT NULL DEFAULT 1.0,
  cooking_session_id  uuid REFERENCES cooking_session(id) ON DELETE SET NULL,
  sort_order          int DEFAULT 0,
  created_at          timestamptz DEFAULT now()
);

CREATE INDEX idx_mpec_entry   ON meal_plan_entry_component(meal_plan_entry_id);
CREATE INDEX idx_mpec_recipe  ON meal_plan_entry_component(recipe_id);
CREATE INDEX idx_mpec_session ON meal_plan_entry_component(cooking_session_id);

ALTER TABLE meal_plan_entry_component ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner via entry meal_plan_entry_component" ON meal_plan_entry_component
  FOR SELECT USING (
    meal_plan_entry_id IN (
      SELECT mpe.id FROM meal_plan_entry mpe
      JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
      WHERE mp.user_id = auth.uid()
    )
  );
CREATE POLICY "owner insert meal_plan_entry_component" ON meal_plan_entry_component
  FOR INSERT WITH CHECK (
    meal_plan_entry_id IN (
      SELECT mpe.id FROM meal_plan_entry mpe
      JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
      WHERE mp.user_id = auth.uid()
    )
  );
CREATE POLICY "owner delete meal_plan_entry_component" ON meal_plan_entry_component
  FOR DELETE USING (
    meal_plan_entry_id IN (
      SELECT mpe.id FROM meal_plan_entry mpe
      JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
      WHERE mp.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 3. Trigger : recalcul automatique de consumption_weight = 1/N
-- Déclenché sur chaque INSERT ou DELETE dans meal_plan_entry_component.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION recalculate_consumption_weight()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  _entry_id uuid;
  _count    int;
  _weight   numeric(4,3);
BEGIN
  _entry_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.meal_plan_entry_id
                    ELSE NEW.meal_plan_entry_id END;

  SELECT COUNT(*) INTO _count
  FROM meal_plan_entry_component
  WHERE meal_plan_entry_id = _entry_id;

  IF _count = 0 THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  _weight := ROUND((1.0 / _count)::numeric, 3);

  UPDATE meal_plan_entry_component
  SET consumption_weight = _weight
  WHERE meal_plan_entry_id = _entry_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_consumption_weight
  AFTER INSERT OR DELETE ON meal_plan_entry_component
  FOR EACH ROW EXECUTE FUNCTION recalculate_consumption_weight();

-- ---------------------------------------------------------------------------
-- 4. Migrer les données existantes
-- Chaque entrée avec recipe_id devient un composant base (weight = 1.0).
-- ---------------------------------------------------------------------------

INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
SELECT id, recipe_id, 'base', 1.0
FROM meal_plan_entry
WHERE recipe_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. Supprimer recipe_id de meal_plan_entry
-- Tout passe désormais par meal_plan_entry_component.
-- ---------------------------------------------------------------------------

ALTER TABLE meal_plan_entry DROP COLUMN recipe_id;

-- ---------------------------------------------------------------------------
-- 6. Modifications de meal_consumption
-- consumption_value : fraction du repas (1/N) — sert au calcul des revenus
--                     ET à la pondération des macros dans le trigger nutrition.
-- component_id      : traçabilité du composant consommé.
-- NOTE : compute-monthly-revenue doit être mis à jour pour utiliser
--        SUM(consumption_value) au lieu de COUNT(*).
-- ---------------------------------------------------------------------------

ALTER TABLE meal_consumption
  ADD COLUMN consumption_value numeric(4,3) NOT NULL DEFAULT 1.0,
  ADD COLUMN component_id      uuid REFERENCES meal_plan_entry_component(id) ON DELETE SET NULL;

CREATE INDEX idx_consumption_component ON meal_consumption(component_id);

-- Mettre à jour le trigger nutrition pour pondérer les macros par consumption_value.
-- Sans ça, un repas modulaire (N composants = N lignes) doublerait les macros journalières.
CREATE OR REPLACE FUNCTION update_daily_nutrition_on_consumption()
RETURNS TRIGGER AS $$
DECLARE
  v_log_date date;
  v_macros   record;
BEGIN
  v_log_date := DATE(NEW.consumed_at);

  SELECT
    COALESCE(rm.calories, 0) * NEW.servings * NEW.consumption_value,
    COALESCE(rm.protein_g, 0) * NEW.servings * NEW.consumption_value,
    COALESCE(rm.carbs_g, 0) * NEW.servings * NEW.consumption_value,
    COALESCE(rm.fat_g, 0) * NEW.servings * NEW.consumption_value,
    COALESCE(rm.fiber_g, 0) * NEW.servings * NEW.consumption_value
  INTO v_macros
  FROM recipe_macro rm
  WHERE rm.recipe_id = NEW.recipe_id;

  INSERT INTO daily_nutrition_log (user_id, log_date, calories, protein_g, carbs_g, fat_g, fiber_g, meals_count)
  VALUES (
    NEW.user_id,
    v_log_date,
    COALESCE(v_macros.calories, 0),
    COALESCE(v_macros.protein_g, 0),
    COALESCE(v_macros.carbs_g, 0),
    COALESCE(v_macros.fat_g, 0),
    COALESCE(v_macros.fiber_g, 0),
    -- N composants = 1 repas. On additionne les fractions : SUM(1/N) = 1 repas.
    NEW.consumption_value
  )
  ON CONFLICT (user_id, log_date) DO UPDATE SET
    calories    = daily_nutrition_log.calories    + EXCLUDED.calories,
    protein_g   = daily_nutrition_log.protein_g   + EXCLUDED.protein_g,
    carbs_g     = daily_nutrition_log.carbs_g     + EXCLUDED.carbs_g,
    fat_g       = daily_nutrition_log.fat_g       + EXCLUDED.fat_g,
    fiber_g     = daily_nutrition_log.fiber_g     + EXCLUDED.fiber_g,
    meals_count = daily_nutrition_log.meals_count + EXCLUDED.meals_count,
    updated_at  = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- 7. Ajout sur user_profile
-- ---------------------------------------------------------------------------

ALTER TABLE user_profile
  ADD COLUMN batch_cooking_enabled  boolean NOT NULL DEFAULT false,
  ADD COLUMN modular_meal_enabled   boolean NOT NULL DEFAULT false;

-- ---------------------------------------------------------------------------
-- 8. Ajout sur recipe
-- compatible_starches : uuid[] de recettes starch suggérées par le créateur.
-- ---------------------------------------------------------------------------

ALTER TABLE recipe
  ADD COLUMN compatible_starches uuid[] NOT NULL DEFAULT '{}';

-- ---------------------------------------------------------------------------
-- 9. Réécrire generate_meal_plan
-- Insère dans meal_plan_entry_component au lieu de meal_plan_entry.recipe_id.
-- Schéma de retour inchangé — le recipe_id vient du composant base.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id       uuid,
  p_days          int     DEFAULT 7,
  p_meals_per_day int     DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  meal_plan_id    uuid,
  entry_id        uuid,
  component_id    uuid,
  scheduled_date  date,
  meal_type       text,
  recipe_id       uuid,
  recipe_title    text,
  cover_image_url text,
  calories        numeric,
  protein_g       numeric,
  similarity      float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector     vector(50);
  v_fan_creator_id  uuid;
  v_plan_id         uuid;
  v_meal_types      text[] := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day             int;
  v_meal_type       text;
  v_current_date    date;
  v_recipe          record;
  v_entry_id        uuid;
  v_component_id    uuid;
  v_used_recipe_ids uuid[] := ARRAY[]::uuid[];
BEGIN
  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  -- Désactiver les plans actifs précédents
  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url, rm.calories, rm.protein_g,
               (1 - (rv.vector <=> v_user_vector)) *
               CASE WHEN v_fan_creator_id IS NOT NULL AND r.creator_id = v_fan_creator_id
                 THEN 1.5 ELSE 1.0 END AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND r.id <> ALL(v_used_recipe_ids)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url, rm.calories, rm.protein_g, 0.5::float AS score
        INTO v_recipe
        FROM recipe r
        LEFT JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND r.id <> ALL(v_used_recipe_ids)
        GROUP BY r.id, rm.calories, rm.protein_g
        ORDER BY COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        v_used_recipe_ids := ARRAY[]::uuid[];
        CONTINUE;
      END IF;

      -- Créer l'entrée du plan (sans recipe_id)
      INSERT INTO meal_plan_entry (meal_plan_id, scheduled_date, meal_type)
      VALUES (v_plan_id, v_current_date, v_meal_type)
      RETURNING id INTO v_entry_id;

      -- Créer le composant base
      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;

      RETURN QUERY SELECT
        v_plan_id,
        v_entry_id,
        v_component_id,
        v_current_date,
        v_meal_type,
        v_recipe.id,
        v_recipe.title,
        v_recipe.cover_image_url,
        v_recipe.calories,
        v_recipe.protein_g,
        v_recipe.score;
    END LOOP;
  END LOOP;
END;
$$;

-- ---------------------------------------------------------------------------
-- 10. Mettre à jour generate_shopping_list
-- Joint via les composants au lieu de mpe.recipe_id (supprimé).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_shopping_list(p_meal_plan_id uuid)
RETURNS TABLE (
  shopping_list_id  uuid,
  ingredient_id     uuid,
  ingredient_name   text,
  total_quantity    numeric,
  unit              text,
  category          text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_list_id uuid;
BEGIN
  SELECT mp.user_id INTO v_user_id
  FROM meal_plan mp WHERE mp.id = p_meal_plan_id;

  IF v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM shopping_list WHERE meal_plan_id = p_meal_plan_id;

  INSERT INTO shopping_list (user_id, meal_plan_id)
  VALUES (v_user_id, p_meal_plan_id)
  RETURNING id INTO v_list_id;

  -- Agrégation via les composants (remplace le JOIN direct sur recipe_id).
  -- Exclut les composants déjà couverts par une cooking_session (ingrédients
  -- achetés pour la session batch — pas besoin de les relister).
  INSERT INTO shopping_list_item (shopping_list_id, ingredient_id, quantity, unit)
  SELECT
    v_list_id,
    ri.ingredient_id,
    SUM(ri.quantity * mpe.servings),
    ri.unit
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN recipe_ingredient ri ON ri.recipe_id = mpec.recipe_id
  WHERE mpe.meal_plan_id = p_meal_plan_id
    AND ri.is_optional = false
    AND mpec.cooking_session_id IS NULL
  GROUP BY ri.ingredient_id, ri.unit;

  RETURN QUERY
  SELECT
    sli.shopping_list_id,
    sli.ingredient_id,
    COALESCE(i.name_fr, i.name) AS ingredient_name,
    sli.quantity,
    sli.unit,
    i.category
  FROM shopping_list_item sli
  JOIN ingredient i ON sli.ingredient_id = i.id
  WHERE sli.shopping_list_id = v_list_id
  ORDER BY i.category, i.name;
END;
$$;
