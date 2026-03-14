-- =============================================================================
-- AKELI V1 — Initial Database Schema
-- Migration: 20260301000001_initial_schema.sql
-- Backend: Supabase / PostgreSQL + pgvector
-- Auteur: Curtis — Fondateur Akeli
-- Date: Mars 2026
-- =============================================================================
-- Conventions:
--   - id uuid DEFAULT gen_random_uuid() PRIMARY KEY sur toutes les tables
--   - created_at timestamptz DEFAULT now() sur toutes les tables
--   - updated_at timestamptz DEFAULT now() avec trigger auto-update
--   - RLS activé sur toutes les tables sans exception
--   - snake_case strict, singulier pour les entités, pluriel pour les jointures
-- =============================================================================

-- ---------------------------------------------------------------------------
-- EXTENSIONS
-- ---------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- ---------------------------------------------------------------------------
-- SECTION 0 — FONCTION UTILITAIRE : auto-update de updated_at
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- SECTION 14 — RÉFÉRENTIELS (créés en premier car référencés par d'autres tables)
-- ---------------------------------------------------------------------------

-- food_region -----------------------------------------------------------
CREATE TABLE food_region (
  code        text PRIMARY KEY,    -- ex: 'west_africa', 'north_africa'
  name_fr     text NOT NULL,
  name_en     text NOT NULL,
  name_es     text,
  name_pt     text,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE food_region ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads food_region" ON food_region FOR SELECT USING (true);

-- ingredient_category ---------------------------------------------------
CREATE TABLE ingredient_category (
  code        text PRIMARY KEY,    -- ex: 'protein', 'vegetable', 'grain'
  name_fr     text NOT NULL,
  name_en     text NOT NULL,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE ingredient_category ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads ingredient_category" ON ingredient_category FOR SELECT USING (true);

-- measurement_unit ------------------------------------------------------
CREATE TABLE measurement_unit (
  code        text PRIMARY KEY,    -- ex: 'g', 'ml', 'tbsp', 'cup', 'piece'
  name_fr     text NOT NULL,
  name_en     text NOT NULL,
  name_es     text,
  name_pt     text,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE measurement_unit ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads measurement_unit" ON measurement_unit FOR SELECT USING (true);

-- tag -------------------------------------------------------------------
CREATE TABLE tag (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL UNIQUE,
  name_fr     text,
  name_en     text,
  name_es     text,
  name_pt     text,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE tag ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads tag" ON tag FOR SELECT USING (true);

-- ---------------------------------------------------------------------------
-- SECTION 1 — IDENTITÉ & AUTH
-- ---------------------------------------------------------------------------

-- user_profile — étend auth.users, créée via trigger à l'inscription
CREATE TABLE user_profile (
  id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username        text UNIQUE,
  first_name      text,
  last_name       text,
  avatar_url      text,
  locale          text DEFAULT 'fr',  -- fr | en | es | pt | wo | bm | ln
  is_creator      boolean DEFAULT false,
  onboarding_done boolean DEFAULT false,
  role            text DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

ALTER TABLE user_profile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user reads own profile" ON user_profile
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "user updates own profile" ON user_profile
  FOR UPDATE USING (auth.uid() = id);
-- Vue publique minimale pour les features communauté
CREATE POLICY "public reads minimal profile" ON user_profile
  FOR SELECT USING (true);

CREATE TRIGGER trg_user_profile_updated_at
  BEFORE UPDATE ON user_profile
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- SECTION 7 — CRÉATEURS (avant recipe car recipe référence creator)
-- ---------------------------------------------------------------------------

CREATE TABLE creator (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid UNIQUE REFERENCES user_profile(id) ON DELETE CASCADE,
  display_name    text NOT NULL,
  bio             text,
  avatar_url      text,
  cover_url       text,
  specialties     text[],              -- régions culinaires
  languages       text[],              -- langues parlées
  is_verified     boolean DEFAULT false,
  recipe_count    int DEFAULT 0,       -- dénormalisé, mis à jour par trigger
  fan_count       int DEFAULT 0,       -- dénormalisé, mis à jour par trigger
  is_fan_eligible boolean GENERATED ALWAYS AS (recipe_count >= 30) STORED,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_creator_user ON creator(user_id);
CREATE INDEX idx_creator_eligible ON creator(is_fan_eligible);

ALTER TABLE creator ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads creator" ON creator FOR SELECT USING (true);
CREATE POLICY "owner manages creator" ON creator
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_creator_updated_at
  BEFORE UPDATE ON creator
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- SECTION 2 — PROFIL UTILISATEUR & SANTÉ
-- ---------------------------------------------------------------------------

-- user_health_profile ---------------------------------------------------
CREATE TABLE user_health_profile (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid UNIQUE REFERENCES user_profile(id) ON DELETE CASCADE,
  sex               text CHECK (sex IN ('male', 'female', 'other')),
  birth_date        date,
  height_cm         numeric(5,1),
  weight_kg         numeric(5,1),
  target_weight_kg  numeric(5,1),
  activity_level    text CHECK (activity_level IN (
    'sedentary', 'light', 'moderate', 'active', 'very_active'
  )),
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);

ALTER TABLE user_health_profile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only user_health_profile" ON user_health_profile
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_user_health_profile_updated_at
  BEFORE UPDATE ON user_health_profile
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- user_goal -------------------------------------------------------------
CREATE TABLE user_goal (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  goal_type   text CHECK (goal_type IN (
    'weight_loss', 'muscle_gain', 'maintenance', 'health', 'performance'
  )),
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE user_goal ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only user_goal" ON user_goal
  USING (auth.uid() = user_id);

-- user_dietary_restriction ----------------------------------------------
CREATE TABLE user_dietary_restriction (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  restriction text CHECK (restriction IN (
    'vegetarian', 'vegan', 'pescatarian',
    'halal', 'kosher',
    'gluten_free', 'lactose_free', 'nut_free',
    'low_sodium', 'diabetic_friendly'
  )),
  created_at  timestamptz DEFAULT now(),
  UNIQUE (user_id, restriction)
);

ALTER TABLE user_dietary_restriction ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only user_dietary_restriction" ON user_dietary_restriction
  USING (auth.uid() = user_id);

-- user_cuisine_preference -----------------------------------------------
CREATE TABLE user_cuisine_preference (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  region           text REFERENCES food_region(code),
  preference_score numeric(3,2) DEFAULT 1.0 CHECK (preference_score BETWEEN 0 AND 1),
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now(),
  UNIQUE (user_id, region)
);

ALTER TABLE user_cuisine_preference ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only user_cuisine_preference" ON user_cuisine_preference
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_user_cuisine_preference_updated_at
  BEFORE UPDATE ON user_cuisine_preference
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- weight_log ------------------------------------------------------------
CREATE TABLE weight_log (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  weight_kg   numeric(5,1) NOT NULL,
  logged_at   date DEFAULT CURRENT_DATE,
  note        text,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE weight_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only weight_log" ON weight_log
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- SECTION 3 — RECETTES
-- ---------------------------------------------------------------------------

-- recipe ----------------------------------------------------------------
CREATE TABLE recipe (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id      uuid REFERENCES creator(id) ON DELETE SET NULL,
  title           text NOT NULL,
  description     text,
  instructions    text NOT NULL,
  region          text REFERENCES food_region(code),
  difficulty      text CHECK (difficulty IN ('easy', 'medium', 'hard')),
  prep_time_min   int,
  cook_time_min   int,
  servings        int DEFAULT 1,
  is_published    boolean DEFAULT false,
  language        text DEFAULT 'fr',
  cover_image_url text,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_recipe_creator ON recipe(creator_id);
CREATE INDEX idx_recipe_region ON recipe(region);
CREATE INDEX idx_recipe_published ON recipe(is_published);

ALTER TABLE recipe ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads published recipe" ON recipe
  FOR SELECT USING (is_published = true);
CREATE POLICY "creator manages own recipe" ON recipe
  USING (
    creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())
  );

CREATE TRIGGER trg_recipe_updated_at
  BEFORE UPDATE ON recipe
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- recipe_macro ----------------------------------------------------------
CREATE TABLE recipe_macro (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid UNIQUE REFERENCES recipe(id) ON DELETE CASCADE,
  calories    numeric(7,1),
  protein_g   numeric(6,1),
  carbs_g     numeric(6,1),
  fat_g       numeric(6,1),
  fiber_g     numeric(6,1),
  sodium_mg   numeric(7,1),
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE recipe_macro ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_macro" ON recipe_macro FOR SELECT USING (true);
CREATE POLICY "creator manages recipe_macro" ON recipe_macro
  USING (
    recipe_id IN (
      SELECT r.id FROM recipe r
      JOIN creator c ON r.creator_id = c.id
      WHERE c.user_id = auth.uid()
    )
  );

CREATE TRIGGER trg_recipe_macro_updated_at
  BEFORE UPDATE ON recipe_macro
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ingredient ------------------------------------------------------------
CREATE TABLE ingredient (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                text NOT NULL,
  name_fr             text,
  name_en             text,
  name_es             text,
  name_pt             text,
  category            text REFERENCES ingredient_category(code),
  calories_per_100g   numeric(6,1),
  protein_per_100g    numeric(5,1),
  carbs_per_100g      numeric(5,1),
  fat_per_100g        numeric(5,1),
  created_at          timestamptz DEFAULT now()
);

ALTER TABLE ingredient ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads ingredient" ON ingredient FOR SELECT USING (true);

-- recipe_ingredient -----------------------------------------------------
CREATE TABLE recipe_ingredient (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id     uuid REFERENCES recipe(id) ON DELETE CASCADE,
  ingredient_id uuid REFERENCES ingredient(id),
  quantity      numeric(8,2) NOT NULL,
  unit          text REFERENCES measurement_unit(code),
  is_optional   boolean DEFAULT false,
  sort_order    int DEFAULT 0,
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX idx_recipe_ingredient_recipe ON recipe_ingredient(recipe_id);

ALTER TABLE recipe_ingredient ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_ingredient" ON recipe_ingredient FOR SELECT USING (true);

-- recipe_tag ------------------------------------------------------------
CREATE TABLE recipe_tag (
  recipe_id   uuid REFERENCES recipe(id) ON DELETE CASCADE,
  tag_id      uuid REFERENCES tag(id) ON DELETE CASCADE,
  PRIMARY KEY (recipe_id, tag_id)
);

ALTER TABLE recipe_tag ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_tag" ON recipe_tag FOR SELECT USING (true);

-- recipe_image ----------------------------------------------------------
CREATE TABLE recipe_image (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid REFERENCES recipe(id) ON DELETE CASCADE,
  url         text NOT NULL,
  sort_order  int DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE recipe_image ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_image" ON recipe_image FOR SELECT USING (true);

-- recipe_like -----------------------------------------------------------
CREATE TABLE recipe_like (
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  recipe_id   uuid REFERENCES recipe(id) ON DELETE CASCADE,
  created_at  timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, recipe_id)
);

ALTER TABLE recipe_like ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner manages recipe_like" ON recipe_like
  USING (auth.uid() = user_id);
CREATE POLICY "public count reads recipe_like" ON recipe_like
  FOR SELECT USING (true);

-- recipe_comment --------------------------------------------------------
CREATE TABLE recipe_comment (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid REFERENCES recipe(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  content     text NOT NULL,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE recipe_comment ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_comment" ON recipe_comment FOR SELECT USING (true);
CREATE POLICY "owner manages recipe_comment" ON recipe_comment
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_recipe_comment_updated_at
  BEFORE UPDATE ON recipe_comment
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- SECTION 4 — VECTORISATION
-- ---------------------------------------------------------------------------

-- user_vector -----------------------------------------------------------
-- Vecteur 50 dimensions représentant le profil utilisateur.
-- Recalculé chaque nuit par le Python batch service (Railway).
CREATE TABLE user_vector (
  user_id       uuid PRIMARY KEY REFERENCES user_profile(id) ON DELETE CASCADE,
  vector        vector(50) NOT NULL,
  last_computed timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

-- Index HNSW pour cosine similarity rapide (~3ms pour 2500+ recettes)
CREATE INDEX idx_user_vector_hnsw ON user_vector
  USING hnsw (vector vector_cosine_ops) WITH (m = 16, ef_construction = 64);

ALTER TABLE user_vector ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only user_vector" ON user_vector
  USING (auth.uid() = user_id);

-- recipe_vector ---------------------------------------------------------
-- Vecteur 50 dimensions représentant le profil nutritionnel/culinaire d'une recette.
-- Calculé à la publication, recalculé si la recette est modifiée.
CREATE TABLE recipe_vector (
  recipe_id     uuid PRIMARY KEY REFERENCES recipe(id) ON DELETE CASCADE,
  vector        vector(50) NOT NULL,
  last_computed timestamptz DEFAULT now()
);

-- Index HNSW pour cosine similarity rapide
CREATE INDEX idx_recipe_vector_hnsw ON recipe_vector
  USING hnsw (vector vector_cosine_ops) WITH (m = 16, ef_construction = 64);

ALTER TABLE recipe_vector ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads recipe_vector" ON recipe_vector FOR SELECT USING (true);

-- ---------------------------------------------------------------------------
-- SECTION 5 — MEAL PLANNING
-- ---------------------------------------------------------------------------

-- meal_plan -------------------------------------------------------------
CREATE TABLE meal_plan (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  name        text,
  start_date  date NOT NULL,
  end_date    date NOT NULL,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

CREATE INDEX idx_meal_plan_user ON meal_plan(user_id);
CREATE INDEX idx_meal_plan_active ON meal_plan(user_id, is_active);

ALTER TABLE meal_plan ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only meal_plan" ON meal_plan
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_meal_plan_updated_at
  BEFORE UPDATE ON meal_plan
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- meal_plan_entry -------------------------------------------------------
CREATE TABLE meal_plan_entry (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_plan_id    uuid REFERENCES meal_plan(id) ON DELETE CASCADE,
  recipe_id       uuid REFERENCES recipe(id) ON DELETE SET NULL,
  scheduled_date  date NOT NULL,
  meal_type       text CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  servings        numeric(4,1) DEFAULT 1,
  is_consumed     boolean DEFAULT false,
  consumed_at     timestamptz,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_meal_plan_entry_plan ON meal_plan_entry(meal_plan_id);
CREATE INDEX idx_meal_plan_entry_date ON meal_plan_entry(scheduled_date);

ALTER TABLE meal_plan_entry ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only via plan meal_plan_entry" ON meal_plan_entry
  USING (
    meal_plan_id IN (SELECT id FROM meal_plan WHERE user_id = auth.uid())
  );

-- meal_consumption ------------------------------------------------------
-- Source de vérité pour les revenus créateurs (90 consommations = 1€)
CREATE TABLE meal_consumption (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  recipe_id          uuid REFERENCES recipe(id) ON DELETE SET NULL,
  creator_id         uuid REFERENCES creator(id) ON DELETE SET NULL,
  meal_plan_entry_id uuid REFERENCES meal_plan_entry(id) ON DELETE SET NULL,
  servings           numeric(4,1) DEFAULT 1,
  consumed_at        timestamptz DEFAULT now(),
  month_key          text GENERATED ALWAYS AS (
    to_char(consumed_at, 'YYYY-MM')
  ) STORED  -- ex: '2026-03' — facilite les agrégations mensuelles
);

CREATE INDEX idx_consumption_user ON meal_consumption(user_id);
CREATE INDEX idx_consumption_creator ON meal_consumption(creator_id);
CREATE INDEX idx_consumption_month ON meal_consumption(month_key);
CREATE INDEX idx_consumption_user_month ON meal_consumption(user_id, month_key);

ALTER TABLE meal_consumption ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads own meal_consumption" ON meal_consumption
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "system inserts meal_consumption" ON meal_consumption
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- shopping_list ---------------------------------------------------------
CREATE TABLE shopping_list (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  meal_plan_id uuid REFERENCES meal_plan(id) ON DELETE CASCADE,
  generated_at timestamptz DEFAULT now()
);

ALTER TABLE shopping_list ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only shopping_list" ON shopping_list
  USING (auth.uid() = user_id);

-- shopping_list_item ----------------------------------------------------
CREATE TABLE shopping_list_item (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shopping_list_id uuid REFERENCES shopping_list(id) ON DELETE CASCADE,
  ingredient_id    uuid REFERENCES ingredient(id),
  quantity         numeric(8,2),
  unit             text REFERENCES measurement_unit(code),
  is_checked       boolean DEFAULT false,
  created_at       timestamptz DEFAULT now()
);

ALTER TABLE shopping_list_item ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner via list shopping_list_item" ON shopping_list_item
  USING (
    shopping_list_id IN (SELECT id FROM shopping_list WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- SECTION 6 — NUTRITION & SUIVI
-- ---------------------------------------------------------------------------

-- daily_nutrition_log ---------------------------------------------------
-- Résumé nutritionnel journalier calculé depuis meal_consumption
CREATE TABLE daily_nutrition_log (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  log_date    date NOT NULL,
  calories    numeric(7,1) DEFAULT 0,
  protein_g   numeric(6,1) DEFAULT 0,
  carbs_g     numeric(6,1) DEFAULT 0,
  fat_g       numeric(6,1) DEFAULT 0,
  fiber_g     numeric(6,1) DEFAULT 0,
  meals_count int DEFAULT 0,
  updated_at  timestamptz DEFAULT now(),
  UNIQUE (user_id, log_date)
);

CREATE INDEX idx_daily_nutrition_user_date ON daily_nutrition_log(user_id, log_date);

ALTER TABLE daily_nutrition_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only daily_nutrition_log" ON daily_nutrition_log
  USING (auth.uid() = user_id);

-- meal_reminder ---------------------------------------------------------
CREATE TABLE meal_reminder (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  meal_type     text CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  reminder_time time NOT NULL,
  days_of_week  int[] DEFAULT '{1,2,3,4,5,6,7}',  -- 1=Lundi ... 7=Dimanche
  is_active     boolean DEFAULT true,
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE meal_reminder ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only meal_reminder" ON meal_reminder
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- SECTION 8 — MODE FAN
-- ---------------------------------------------------------------------------

-- fan_subscription ------------------------------------------------------
CREATE TABLE fan_subscription (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  creator_id      uuid REFERENCES creator(id) ON DELETE CASCADE,
  status          text CHECK (status IN ('pending', 'active', 'cancelled')) DEFAULT 'pending',
  -- pending → actif au 1er du mois suivant
  -- active  → allocation 1€ en cours
  -- cancelled → désactivé au 1er du mois suivant
  effective_from  date,           -- 1er du mois d'activation
  effective_until date,           -- 1er du mois de fin (null si toujours actif)
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (user_id, status)        -- un seul Fan actif ou pending par utilisateur
);

CREATE INDEX idx_fan_sub_user ON fan_subscription(user_id);
CREATE INDEX idx_fan_sub_creator ON fan_subscription(creator_id);
CREATE INDEX idx_fan_sub_status ON fan_subscription(status);

ALTER TABLE fan_subscription ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads own fan_subscription" ON fan_subscription
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "creator reads own fans fan_subscription" ON fan_subscription
  FOR SELECT USING (
    creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())
  );
CREATE POLICY "owner manages fan_subscription" ON fan_subscription
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE TRIGGER trg_fan_subscription_updated_at
  BEFORE UPDATE ON fan_subscription
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- fan_subscription_history ----------------------------------------------
-- Historique complet — immuable, insert only
CREATE TABLE fan_subscription_history (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  creator_id          uuid REFERENCES creator(id) ON DELETE CASCADE,
  action              text CHECK (action IN ('activated', 'changed', 'cancelled')),
  previous_creator_id uuid REFERENCES creator(id) ON DELETE SET NULL,
  month_key           text NOT NULL,   -- ex: '2026-03'
  created_at          timestamptz DEFAULT now()
);

CREATE INDEX idx_fan_history_user ON fan_subscription_history(user_id);
CREATE INDEX idx_fan_history_creator ON fan_subscription_history(creator_id);

ALTER TABLE fan_subscription_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads own fan_subscription_history" ON fan_subscription_history
  FOR SELECT USING (auth.uid() = user_id);

-- fan_external_recipe_counter -------------------------------------------
-- Compteur mensuel de recettes externes consommées en Mode Fan
-- Bloqué à 9 — la 10ème est refusée par l'application
CREATE TABLE fan_external_recipe_counter (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  month_key             text NOT NULL,
  external_recipe_count int DEFAULT 0 CHECK (external_recipe_count <= 9),
  updated_at            timestamptz DEFAULT now(),
  UNIQUE (user_id, month_key)
);

ALTER TABLE fan_external_recipe_counter ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads own fan_external_recipe_counter" ON fan_external_recipe_counter
  FOR SELECT USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- SECTION 9 — REVENUS
-- ---------------------------------------------------------------------------

-- creator_revenue_log ---------------------------------------------------
-- Journal mensuel des revenus par créateur — immuable après calcul
CREATE TABLE creator_revenue_log (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id          uuid REFERENCES creator(id) ON DELETE CASCADE,
  month_key           text NOT NULL,                  -- ex: '2026-03'
  fan_revenue         numeric(10,2) DEFAULT 0,        -- nb fans actifs × 1€
  consumption_revenue numeric(10,2) DEFAULT 0,        -- floor(consommations / 90) × 1€
  total_revenue       numeric(10,2) GENERATED ALWAYS AS (fan_revenue + consumption_revenue) STORED,
  fan_count           int DEFAULT 0,
  consumption_count   int DEFAULT 0,
  computed_at         timestamptz DEFAULT now(),
  UNIQUE (creator_id, month_key)
);

CREATE INDEX idx_revenue_log_creator ON creator_revenue_log(creator_id);
CREATE INDEX idx_revenue_log_month ON creator_revenue_log(month_key);

ALTER TABLE creator_revenue_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "creator reads own creator_revenue_log" ON creator_revenue_log
  FOR SELECT USING (
    creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())
  );

-- creator_balance -------------------------------------------------------
-- Solde courant — mis à jour à chaque calcul mensuel
CREATE TABLE creator_balance (
  creator_id    uuid PRIMARY KEY REFERENCES creator(id) ON DELETE CASCADE,
  balance       numeric(10,2) DEFAULT 0,   -- cumulé non versé
  total_earned  numeric(10,2) DEFAULT 0,   -- total depuis création
  total_paid_out numeric(10,2) DEFAULT 0,  -- total versé
  last_updated  timestamptz DEFAULT now()
);

ALTER TABLE creator_balance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "creator reads own creator_balance" ON creator_balance
  FOR SELECT USING (
    creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())
  );

-- payout ----------------------------------------------------------------
CREATE TABLE payout (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id  uuid REFERENCES creator(id) ON DELETE CASCADE,
  amount      numeric(10,2) NOT NULL,
  status      text CHECK (status IN ('pending', 'processing', 'paid', 'failed')),
  month_key   text,
  paid_at     timestamptz,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE payout ENABLE ROW LEVEL SECURITY;
CREATE POLICY "creator reads own payout" ON payout
  FOR SELECT USING (
    creator_id IN (SELECT id FROM creator WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- SECTION 10 — ABONNEMENTS & PAIEMENTS
-- ---------------------------------------------------------------------------

-- subscription ----------------------------------------------------------
-- Abonnement Akeli de l'utilisateur à 3€/mois
CREATE TABLE subscription (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 uuid UNIQUE REFERENCES user_profile(id) ON DELETE CASCADE,
  status                  text CHECK (status IN ('active', 'cancelled', 'past_due', 'trialing')),
  stripe_customer_id      text UNIQUE,
  stripe_subscription_id  text UNIQUE,
  current_period_start    timestamptz,
  current_period_end      timestamptz,
  cancelled_at            timestamptz,
  created_at              timestamptz DEFAULT now(),
  updated_at              timestamptz DEFAULT now()
);

ALTER TABLE subscription ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only subscription" ON subscription
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_subscription_updated_at
  BEFORE UPDATE ON subscription
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- SECTION 11 — COMMUNAUTÉ & CHAT
-- ---------------------------------------------------------------------------

-- community_group -------------------------------------------------------
CREATE TABLE community_group (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL,
  description  text,
  cover_url    text,
  creator_id   uuid REFERENCES user_profile(id) ON DELETE SET NULL,
  is_public    boolean DEFAULT true,
  member_count int DEFAULT 0,  -- dénormalisé
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
);

ALTER TABLE community_group ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads public groups" ON community_group
  FOR SELECT USING (is_public = true);
CREATE POLICY "member reads private groups" ON community_group
  FOR SELECT USING (
    id IN (SELECT group_id FROM group_member WHERE user_id = auth.uid())
  );

CREATE TRIGGER trg_community_group_updated_at
  BEFORE UPDATE ON community_group
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- group_member ----------------------------------------------------------
CREATE TABLE group_member (
  group_id    uuid REFERENCES community_group(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  role        text CHECK (role IN ('admin', 'member')) DEFAULT 'member',
  joined_at   timestamptz DEFAULT now(),
  last_read_at timestamptz,
  PRIMARY KEY (group_id, user_id)
);

ALTER TABLE group_member ENABLE ROW LEVEL SECURITY;
CREATE POLICY "member reads own membership" ON group_member
  FOR SELECT USING (auth.uid() = user_id);

-- conversation ----------------------------------------------------------
CREATE TABLE conversation (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE conversation ENABLE ROW LEVEL SECURITY;

-- conversation_participant ----------------------------------------------
CREATE TABLE conversation_participant (
  conversation_id uuid REFERENCES conversation(id) ON DELETE CASCADE,
  user_id         uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  joined_at       timestamptz DEFAULT now(),
  last_read_at    timestamptz,
  PRIMARY KEY (conversation_id, user_id)
);

ALTER TABLE conversation_participant ENABLE ROW LEVEL SECURITY;
CREATE POLICY "participant only conversation_participant" ON conversation_participant
  USING (auth.uid() = user_id);

-- chat_message ----------------------------------------------------------
CREATE TABLE chat_message (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES conversation(id) ON DELETE CASCADE,
  group_id        uuid REFERENCES community_group(id) ON DELETE CASCADE,
  sender_id       uuid REFERENCES user_profile(id) ON DELETE SET NULL,
  content         text NOT NULL,
  message_type    text CHECK (message_type IN ('text', 'image', 'recipe_share')) DEFAULT 'text',
  recipe_id       uuid REFERENCES recipe(id) ON DELETE SET NULL,
  sent_at         timestamptz DEFAULT now(),
  CONSTRAINT check_chat_target CHECK (
    (conversation_id IS NOT NULL AND group_id IS NULL) OR
    (conversation_id IS NULL AND group_id IS NOT NULL)
  )
);

CREATE INDEX idx_chat_message_conversation ON chat_message(conversation_id, sent_at DESC);
CREATE INDEX idx_chat_message_group ON chat_message(group_id, sent_at DESC);

ALTER TABLE chat_message ENABLE ROW LEVEL SECURITY;
CREATE POLICY "participant reads chat_message" ON chat_message
  FOR SELECT USING (
    conversation_id IN (
      SELECT conversation_id FROM conversation_participant WHERE user_id = auth.uid()
    ) OR
    group_id IN (
      SELECT group_id FROM group_member WHERE user_id = auth.uid()
    )
  );
CREATE POLICY "participant sends chat_message" ON chat_message
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND (
      conversation_id IN (
        SELECT conversation_id FROM conversation_participant WHERE user_id = auth.uid()
      ) OR
      group_id IN (
        SELECT group_id FROM group_member WHERE user_id = auth.uid()
      )
    )
  );

-- conversation_request --------------------------------------------------
CREATE TABLE conversation_request (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  to_user_id   uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  status       text CHECK (status IN ('pending', 'accepted', 'declined')) DEFAULT 'pending',
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now(),
  UNIQUE (from_user_id, to_user_id)
);

ALTER TABLE conversation_request ENABLE ROW LEVEL SECURITY;
CREATE POLICY "participant reads conversation_request" ON conversation_request
  USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);

CREATE TRIGGER trg_conversation_request_updated_at
  BEFORE UPDATE ON conversation_request
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- SECTION 12 — NOTIFICATIONS
-- ---------------------------------------------------------------------------

-- notification ----------------------------------------------------------
CREATE TABLE notification (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  type        text CHECK (type IN (
    'meal_reminder', 'new_recipe', 'fan_activated', 'revenue_update',
    'message', 'group_invite', 'conversation_request', 'system'
  )),
  title       text NOT NULL,
  body        text,
  data        jsonb,   -- payload contextuel
  is_read     boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX idx_notification_user ON notification(user_id, created_at DESC);

ALTER TABLE notification ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only notification" ON notification
  USING (auth.uid() = user_id);

-- push_token ------------------------------------------------------------
-- Tokens FCM pour les push notifications
CREATE TABLE push_token (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  token       text NOT NULL UNIQUE,
  platform    text CHECK (platform IN ('ios', 'android')),
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE push_token ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only push_token" ON push_token
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_push_token_updated_at
  BEFORE UPDATE ON push_token
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- SECTION 13 — PARRAINAGE
-- ---------------------------------------------------------------------------

CREATE TABLE referral (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id   uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  referred_id   uuid UNIQUE REFERENCES user_profile(id) ON DELETE CASCADE,
  referral_code text NOT NULL,
  status        text CHECK (status IN ('pending', 'converted')) DEFAULT 'pending',
  converted_at  timestamptz,
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX idx_referral_referrer ON referral(referrer_id);
CREATE INDEX idx_referral_code ON referral(referral_code);

ALTER TABLE referral ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads own referral" ON referral
  USING (auth.uid() = referrer_id);

-- ---------------------------------------------------------------------------
-- SECTION 15 — SUPPORT
-- ---------------------------------------------------------------------------

CREATE TABLE support_message (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE SET NULL,
  email       text NOT NULL,
  subject     text,
  content     text NOT NULL,
  status      text CHECK (status IN ('open', 'in_progress', 'resolved')) DEFAULT 'open',
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE support_message ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads own support_message" ON support_message
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "authenticated inserts support_message" ON support_message
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ---------------------------------------------------------------------------
-- AI ASSISTANT
-- ---------------------------------------------------------------------------

-- ai_conversation -------------------------------------------------------
CREATE TABLE ai_conversation (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE ai_conversation ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only ai_conversation" ON ai_conversation
  USING (auth.uid() = user_id);

CREATE TRIGGER trg_ai_conversation_updated_at
  BEFORE UPDATE ON ai_conversation
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ai_message ------------------------------------------------------------
CREATE TABLE ai_message (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES ai_conversation(id) ON DELETE CASCADE,
  role            text CHECK (role IN ('user', 'assistant')) NOT NULL,
  content         text NOT NULL,
  tokens_used     int,
  sent_at         timestamptz DEFAULT now()
);

CREATE INDEX idx_ai_message_conv ON ai_message(conversation_id, sent_at DESC);

ALTER TABLE ai_message ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner via conversation ai_message" ON ai_message
  FOR SELECT USING (
    conversation_id IN (SELECT id FROM ai_conversation WHERE user_id = auth.uid())
  );
CREATE POLICY "owner inserts ai_message" ON ai_message
  FOR INSERT WITH CHECK (
    conversation_id IN (SELECT id FROM ai_conversation WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- TRIGGERS MÉTIER
-- ---------------------------------------------------------------------------

-- Création automatique du user_profile à l'inscription Supabase Auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profile (id)
  VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Mise à jour du recipe_count du créateur (dénormalisé)
CREATE OR REPLACE FUNCTION update_creator_recipe_count()
RETURNS TRIGGER AS $$
DECLARE
  target_creator_id uuid;
BEGIN
  -- Utiliser NEW si INSERT/UPDATE, OLD si DELETE
  target_creator_id := COALESCE(NEW.creator_id, OLD.creator_id);

  IF target_creator_id IS NOT NULL THEN
    UPDATE creator SET recipe_count = (
      SELECT COUNT(*) FROM recipe
      WHERE creator_id = target_creator_id AND is_published = true
    ) WHERE id = target_creator_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recipe_count
  AFTER INSERT OR UPDATE OR DELETE ON recipe
  FOR EACH ROW EXECUTE FUNCTION update_creator_recipe_count();

-- Mise à jour du fan_count du créateur (dénormalisé)
CREATE OR REPLACE FUNCTION update_creator_fan_count()
RETURNS TRIGGER AS $$
DECLARE
  target_creator_id uuid;
BEGIN
  target_creator_id := COALESCE(NEW.creator_id, OLD.creator_id);

  IF target_creator_id IS NOT NULL THEN
    UPDATE creator SET fan_count = (
      SELECT COUNT(*) FROM fan_subscription
      WHERE creator_id = target_creator_id AND status = 'active'
    ) WHERE id = target_creator_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_fan_count
  AFTER INSERT OR UPDATE OR DELETE ON fan_subscription
  FOR EACH ROW EXECUTE FUNCTION update_creator_fan_count();

-- Mise à jour du member_count du groupe (dénormalisé)
CREATE OR REPLACE FUNCTION update_group_member_count()
RETURNS TRIGGER AS $$
DECLARE
  target_group_id uuid;
BEGIN
  target_group_id := COALESCE(NEW.group_id, OLD.group_id);

  UPDATE community_group SET member_count = (
    SELECT COUNT(*) FROM group_member WHERE group_id = target_group_id
  ) WHERE id = target_group_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_group_member_count
  AFTER INSERT OR DELETE ON group_member
  FOR EACH ROW EXECUTE FUNCTION update_group_member_count();

-- Mise à jour automatique daily_nutrition_log lors d'une consommation
CREATE OR REPLACE FUNCTION update_daily_nutrition_on_consumption()
RETURNS TRIGGER AS $$
DECLARE
  v_log_date date;
  v_macros   record;
BEGIN
  v_log_date := DATE(NEW.consumed_at);

  -- Récupérer les macros de la recette, pondérées par les portions
  SELECT
    COALESCE(rm.calories, 0) * NEW.servings,
    COALESCE(rm.protein_g, 0) * NEW.servings,
    COALESCE(rm.carbs_g, 0) * NEW.servings,
    COALESCE(rm.fat_g, 0) * NEW.servings,
    COALESCE(rm.fiber_g, 0) * NEW.servings
  INTO v_macros
  FROM recipe_macro rm
  WHERE rm.recipe_id = NEW.recipe_id;

  -- Upsert du log journalier
  INSERT INTO daily_nutrition_log (user_id, log_date, calories, protein_g, carbs_g, fat_g, fiber_g, meals_count)
  VALUES (
    NEW.user_id,
    v_log_date,
    COALESCE(v_macros.calories, 0),
    COALESCE(v_macros.protein_g, 0),
    COALESCE(v_macros.carbs_g, 0),
    COALESCE(v_macros.fat_g, 0),
    COALESCE(v_macros.fiber_g, 0),
    1
  )
  ON CONFLICT (user_id, log_date) DO UPDATE SET
    calories    = daily_nutrition_log.calories    + EXCLUDED.calories,
    protein_g   = daily_nutrition_log.protein_g   + EXCLUDED.protein_g,
    carbs_g     = daily_nutrition_log.carbs_g     + EXCLUDED.carbs_g,
    fat_g       = daily_nutrition_log.fat_g       + EXCLUDED.fat_g,
    fiber_g     = daily_nutrition_log.fiber_g     + EXCLUDED.fiber_g,
    meals_count = daily_nutrition_log.meals_count + 1,
    updated_at  = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_nutrition_on_consumption
  AFTER INSERT ON meal_consumption
  FOR EACH ROW EXECUTE FUNCTION update_daily_nutrition_on_consumption();
