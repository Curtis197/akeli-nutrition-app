# 03 - Architecture Base de DonnÃ©es

---

## ðŸ“‹ Vue d'Ensemble

La V1 nÃ©cessite l'ajout de **7 nouvelles tables principales** et modifications sur **2 tables existantes** pour supporter :
- Vectorisation (users + recherches)
- Clustering niches
- Subscriptions Pro Tier
- Analytics dÃ©mographiques

---

## ðŸ—„ï¸ Nouvelles Tables V1

### 1. `search_queries`

**Objectif** : Tracker toutes les recherches users pour analyse niches et SEO

```sql
CREATE TABLE search_queries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Identifiants
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  
  -- RequÃªte
  query_text text NOT NULL,
  query_embedding vector(1536), -- OpenAI text-embedding-3-small
  
  -- Contexte recherche
  searched_at timestamptz DEFAULT now(),
  user_goal text, -- 'weight_loss', 'muscle_gain', etc (si connu)
  user_location text, -- pays user
  device_type text, -- 'mobile', 'web'
  
  -- RÃ©sultats
  results_count int DEFAULT 0, -- combien recettes retournÃ©es
  clicked_recipe_id uuid REFERENCES receipe(id) ON DELETE SET NULL,
  clicked_at timestamptz,
  
  -- Meta
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX idx_search_queries_user ON search_queries(user_id);
CREATE INDEX idx_search_queries_date ON search_queries(searched_at DESC);
CREATE INDEX idx_search_queries_text ON search_queries USING gin(to_tsvector('french', query_text));

-- Vector index (requires pgvector extension)
CREATE INDEX idx_search_queries_embedding ON search_queries 
  USING ivfflat (query_embedding vector_cosine_ops)
  WITH (lists = 100);

-- Composite index pour analytics
CREATE INDEX idx_search_queries_analytics ON search_queries(searched_at, results_count);
```

**Notes** :
- `query_embedding` : NULL jusqu'Ã  vectorisation (async)
- `clicked_recipe_id` : NULL si user n'a pas cliquÃ©
- Index `ivfflat` pour similaritÃ© vectorielle rapide (pgvector)

---

### 2. `user_embeddings`

**Objectif** : Stocker reprÃ©sentations vectorielles des utilisateurs pour clustering et personalisation

```sql
CREATE TABLE user_embeddings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Embedding
  embedding vector(1536) NOT NULL,
  
  -- Source data snapshot (pour debugging/audit)
  behavior_summary jsonb,
  /* Exemple structure :
  {
    "consumed_cuisines": ["ivorian", "senegalese"],
    "avg_cooking_time": 35,
    "favorite_ingredients": ["chicken", "rice", "vegetables"],
    "goals": ["weight_loss"],
    "activity_level": "moderate",
    "search_patterns": ["quick", "healthy", "high-protein"]
  }
  */
  
  -- Timestamps
  generated_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Vector index
CREATE INDEX idx_user_embeddings_vector ON user_embeddings 
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- Index pour cron job (update users actifs)
CREATE INDEX idx_user_embeddings_updated ON user_embeddings(updated_at);
```

**Notes** :
- Un seul embedding par user (UNIQUE user_id)
- `behavior_summary` JSONB pour flexibilitÃ© (Ã©volution format)
- Re-gÃ©nÃ©rÃ© quotidiennement pour users actifs

---

### 3. `niche_clusters`

**Objectif** : Stocker niches identifiÃ©es algorithmiquement

```sql
CREATE TABLE niche_clusters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- IdentitÃ© niche
  name text NOT NULL, -- "Petit-dÃ©jeuner Ivoirien Rapide"
  description text,
  slug text UNIQUE, -- URL-friendly, ex: "petit-dejeuner-ivoirien-rapide"
  
  -- HiÃ©rarchie
  granularity text NOT NULL CHECK (granularity IN ('large', 'medium', 'precise')),
  parent_cluster_id uuid REFERENCES niche_clusters(id) ON DELETE SET NULL,
  
  -- Cluster data
  search_query_ids uuid[] DEFAULT '{}', -- array IDs queries dans ce cluster
  centroid_embedding vector(1536), -- centre cluster pour similaritÃ©
  cluster_size int DEFAULT 0, -- nombre queries
  
  -- MÃ©triques business
  total_searches_30d int DEFAULT 0,
  total_searches_60d int DEFAULT 0,
  total_searches_90d int DEFAULT 0,
  
  existing_recipes_count int DEFAULT 0,
  avg_recipe_consumption numeric,
  avg_recipe_rating numeric,
  
  -- Scoring
  financial_potential_score numeric, -- â‚¬/mois estimÃ©
  saturation_level text CHECK (saturation_level IN ('low', 'medium', 'high')),
  difficulty_score numeric, -- 0-100, facilitÃ© capturer niche
  
  -- Trend
  growth_rate_30d numeric, -- % croissance volume recherches
  trend_direction text CHECK (trend_direction IN ('growing', 'stable', 'declining')),
  
  -- Profil consommateurs (agrÃ©gÃ©)
  consumer_profile jsonb,
  /* Exemple :
  {
    "gender_split": {"female": 67, "male": 33},
    "age_groups": {"18-24": 23, "25-34": 45, ...},
    "top_goals": ["weight_loss", "maintenance"],
    "top_locations": ["FR", "BE", "GB"]
  }
  */
  
  -- Meta
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  last_calculated_at timestamptz
);

-- Indexes
CREATE INDEX idx_niche_financial ON niche_clusters(financial_potential_score DESC NULLS LAST);
CREATE INDEX idx_niche_granularity ON niche_clusters(granularity);
CREATE INDEX idx_niche_saturation ON niche_clusters(saturation_level);
CREATE INDEX idx_niche_parent ON niche_clusters(parent_cluster_id);
CREATE INDEX idx_niche_searches ON niche_clusters(total_searches_30d DESC);

-- Vector index
CREATE INDEX idx_niche_centroid ON niche_clusters 
  USING ivfflat (centroid_embedding vector_cosine_ops)
  WITH (lists = 50);
```

**Notes** :
- HiÃ©rarchie via `parent_cluster_id` (large â†’ medium â†’ precise)
- `search_query_ids` array pour traÃ§abilitÃ©
- `consumer_profile` JSONB flexible pour analytics

---

### 4. `niche_opportunities`

**Objectif** : DÃ©tailler opportunitÃ©s spÃ©cifiques dans chaque niche

```sql
CREATE TABLE niche_opportunities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  niche_cluster_id uuid NOT NULL REFERENCES niche_clusters(id) ON DELETE CASCADE,
  
  -- OpportunitÃ©
  opportunity_type text NOT NULL CHECK (opportunity_type IN ('gap', 'improve', 'expand')),
  /* 
  - gap: 0 recettes existantes
  - improve: recettes existantes faibles (note <3.5)
  - expand: variante d'une recette populaire
  */
  
  -- Query cible
  target_query text NOT NULL,
  query_embedding vector(1536),
  search_volume_30d int,
  
  -- Concurrence
  competing_recipes uuid[] DEFAULT '{}', -- IDs recettes similaires
  competition_strength text CHECK (competition_strength IN ('none', 'weak', 'medium', 'strong')),
  
  -- Potentiel
  estimated_monthly_revenue numeric, -- â‚¬/mois si recette crÃ©Ã©e
  estimated_consumptions_30d int,
  difficulty_score numeric, -- 0-100 (facilitÃ© rÃ©ussir)
  
  -- Insights IA (optionnel)
  ai_suggestions jsonb,
  /* Exemple :
  {
    "tips": [
      "Emphasize 'quick' in title",
      "Include protein content in description",
      "Target Sunday evening publication"
    ],
    "target_audience": {
      "primary": "women 25-34, weight loss",
      "preferences": ["quick", "healthy", "visual"]
    },
    "keywords": ["rapide", "protÃ©inÃ©", "healthy", "facile"]
  }
  */
  
  -- Meta
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX idx_opp_niche ON niche_opportunities(niche_cluster_id);
CREATE INDEX idx_opp_revenue ON niche_opportunities(estimated_monthly_revenue DESC NULLS LAST);
CREATE INDEX idx_opp_type ON niche_opportunities(opportunity_type);
CREATE INDEX idx_opp_volume ON niche_opportunities(search_volume_30d DESC);

-- Vector index
CREATE INDEX idx_opp_embedding ON niche_opportunities 
  USING ivfflat (query_embedding vector_cosine_ops)
  WITH (lists = 100);
```

**Notes** :
- Une niche peut avoir multiples opportunitÃ©s
- `ai_suggestions` gÃ©nÃ©rÃ© optionnellement (coÃ»t GPT)
- Ordre par `estimated_monthly_revenue` pour prioritÃ©

---

### 5. `creator_subscriptions`

**Objectif** : GÃ©rer abonnements Pro Tier crÃ©ateurs

```sql
CREATE TABLE creator_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid UNIQUE NOT NULL REFERENCES creator_profiles(id) ON DELETE CASCADE,
  
  -- Tier
  tier text NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'pro')),
  
  -- Billing
  price_eur numeric, -- NULL si free, sinon 30 ou 12
  region text CHECK (region IN ('europe', 'africa', 'other')),
  currency text DEFAULT 'EUR',
  
  -- Stripe
  stripe_customer_id text,
  stripe_subscription_id text,
  stripe_price_id text, -- pour gÃ©rer multiples plans
  
  -- Status
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'past_due', 'trialing')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  
  trial_start timestamptz,
  trial_end timestamptz,
  
  cancel_at_period_end boolean DEFAULT false,
  cancelled_at timestamptz,
  cancellation_reason text,
  
  -- Historique
  subscription_started_at timestamptz DEFAULT now(),
  last_payment_at timestamptz,
  next_payment_at timestamptz,
  
  -- Meta
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX idx_subs_creator ON creator_subscriptions(creator_id);
CREATE INDEX idx_subs_stripe ON creator_subscriptions(stripe_subscription_id);
CREATE INDEX idx_subs_status ON creator_subscriptions(status);
CREATE INDEX idx_subs_tier ON creator_subscriptions(tier);
CREATE INDEX idx_subs_period_end ON creator_subscriptions(current_period_end);
```

**Notes** :
- UNIQUE `creator_id` : un crÃ©ateur = un abonnement max
- Status `trialing` pour free trial 14 jours
- `cancel_at_period_end` : annulation sans perte accÃ¨s immÃ©diat

---

### 6. `feature_gates`

**Objectif** : DÃ©finir quelles features requiÃ¨rent Pro Tier et limites free

```sql
CREATE TABLE feature_gates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Feature
  feature_name text UNIQUE NOT NULL,
  feature_label text NOT NULL, -- UI-friendly name
  feature_description text,
  
  -- Access control
  required_tier text NOT NULL DEFAULT 'free' CHECK (required_tier IN ('free', 'pro')),
  
  -- Limits pour free tier (NULL = unlimited)
  free_tier_daily_limit int,
  free_tier_monthly_limit int,
  free_tier_total_limit int,
  
  -- Configuration
  is_enabled boolean DEFAULT true,
  rollout_percentage int DEFAULT 100, -- A/B testing (0-100%)
  
  -- Meta
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX idx_gates_tier ON feature_gates(required_tier);
CREATE INDEX idx_gates_enabled ON feature_gates(is_enabled);

-- Seed data
INSERT INTO feature_gates (feature_name, feature_label, required_tier, free_tier_monthly_limit) VALUES
  ('seo_tool', 'In-App SEO Tool', 'pro', 5),
  ('seo_tool_detailed', 'SEO Tool - Detailed Insights', 'pro', NULL),
  ('niche_finder', 'Niche Finder', 'pro', NULL),
  ('advanced_analytics', 'Advanced Analytics', 'pro', NULL),
  ('consumer_demographics', 'Consumer Demographics', 'pro', NULL),
  ('ai_insights', 'AI-Generated Insights', 'pro', NULL),
  ('recipe_creation', 'Recipe Creation', 'free', NULL),
  ('basic_analytics', 'Basic Analytics', 'free', NULL),
  ('revenue_tracking', 'Revenue Tracking', 'free', NULL);
```

**Notes** :
- Permet flexibilitÃ© limites (daily, monthly, total)
- `rollout_percentage` pour feature flags / A/B tests
- Free tier a accÃ¨s limitÃ© SEO tool (5 recherches/mois)

---

### 7. `consumer_demographics`

**Objectif** : Analytics dÃ©taillÃ©es consommateurs par crÃ©ateur

```sql
CREATE TABLE consumer_demographics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Relations
  creator_id uuid NOT NULL REFERENCES creator_profiles(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- DÃ©mographie
  gender text,
  age_range text, -- '18-24', '25-34', etc
  country text,
  city text,
  
  -- Fitness profile
  fitness_goal text,
  activity_level text,
  dietary_preferences text[],
  
  -- Comportement avec ce crÃ©ateur
  total_consumptions int DEFAULT 0,
  total_plans int DEFAULT 0,
  completion_rate numeric, -- % recettes complÃ©tÃ©es
  
  favorite_recipe_id uuid REFERENCES receipe(id) ON DELETE SET NULL,
  favorite_recipe_type text, -- 'quick', 'traditional', etc
  
  -- Temporal patterns
  preferred_day text, -- 'monday', 'sunday', etc
  preferred_meal text, -- 'breakfast', 'lunch', 'dinner'
  
  -- Engagement
  total_likes int DEFAULT 0,
  total_saves int DEFAULT 0,
  avg_rating numeric,
  
  -- Classification
  is_recurring boolean DEFAULT false, -- consumed >1 recette
  is_loyal boolean DEFAULT false, -- consumed >5 recettes
  
  -- Timestamps
  first_consumption_date timestamptz,
  last_consumption_date timestamptz,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Constraint
  UNIQUE(creator_id, user_id)
);

-- Indexes
CREATE INDEX idx_demographics_creator ON consumer_demographics(creator_id);
CREATE INDEX idx_demographics_user ON consumer_demographics(user_id);
CREATE INDEX idx_demographics_country ON consumer_demographics(country);
CREATE INDEX idx_demographics_goal ON consumer_demographics(fitness_goal);
CREATE INDEX idx_demographics_loyal ON consumer_demographics(is_loyal) WHERE is_loyal = true;
CREATE INDEX idx_demographics_recurring ON consumer_demographics(is_recurring) WHERE is_recurring = true;
```

**Notes** :
- UNIQUE (creator_id, user_id) : une ligne par relation crÃ©ateur-consommateur
- Mise Ã  jour via trigger quand `meal.consumed = true`
- AgrÃ©gation quotidienne via cron job

---

## ðŸ”„ Tables Existantes ModifiÃ©es

### 1. `recipe_performance_metrics`

**Ajouts** : Colonnes search-related et niche affiliation

```sql
-- Nouvelles colonnes
ALTER TABLE recipe_performance_metrics

-- Search & Discovery
ADD COLUMN search_impressions bigint DEFAULT 0,
ADD COLUMN search_clicks bigint DEFAULT 0,
ADD COLUMN click_through_rate numeric,
ADD COLUMN plan_rate numeric, -- clicks â†’ planned

-- Niche affiliation
ADD COLUMN niche_cluster_ids uuid[]; -- array IDs niches auxquelles recette appartient

-- Indexes
CREATE INDEX idx_rpm_search_ctr ON recipe_performance_metrics(click_through_rate DESC NULLS LAST);
CREATE INDEX idx_rpm_niches ON recipe_performance_metrics USING gin(niche_cluster_ids);
```

**Notes** :
- `niche_cluster_ids` array car une recette peut appartenir Ã  multiples niches
- Permet voir performance recette dans contexte niches

---

### 2. `receipe` (table principale recettes)

**Ajouts** : Embedding pour similaritÃ© sÃ©mantique

```sql
-- Nouvelle colonne
ALTER TABLE receipe
ADD COLUMN embedding vector(1536);

-- Index vector
CREATE INDEX idx_receipe_embedding ON receipe 
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 200);
```

**Notes** :
- Embedding gÃ©nÃ©rÃ© Ã  crÃ©ation/modification recette
- Permet search sÃ©mantique et clustering dans niches
- Peut Ãªtre gÃ©nÃ©rÃ© de faÃ§on asynchrone (cron job si NULL)

---

## âš™ï¸ Edge Functions

### 1. `vectorize-search`

**Trigger** : Real-time Ã  chaque recherche user

**Input** :
```typescript
{
  query: string,
  user_id: string,
  context?: {
    hour: number,
    day: string,
    device: string
  }
}
```

**Process** :
```typescript
1. Appeler OpenAI embeddings API
   const embedding = await openai.embeddings.create({
     model: "text-embedding-3-small",
     input: query
   })

2. Chercher recettes similaires (vector similarity)
   SELECT * FROM receipe
   WHERE 1 - (embedding <=> $embedding) > 0.7
   ORDER BY embedding <=> $embedding
   LIMIT 20

3. Stocker recherche
   INSERT INTO search_queries (...)
   VALUES (query, embedding, user_id, results.length, ...)

4. Retourner rÃ©sultats
   return { results, search_id }
```

**Output** : Liste recettes + search_id pour tracking clic

---

### 2. `vectorize-user`

**Trigger** : Cron quotidien (2am)

**Input** : `user_id`

**Process** :
```typescript
1. AgrÃ©ger comportement user 30j :
   - Recettes consommÃ©es (types, cuisines, temps)
   - Recherches effectuÃ©es
   - Likes/saves
   - Objectifs fitness

2. GÃ©nÃ©rer prompt descriptif :
   const prompt = `User profile:
   Gender: ${gender}, Age: ${age}
   Goals: ${goals.join(', ')}
   Consumed cuisines: ${cuisines}
   Frequent searches: ${searches}
   Preferences: ${preferences}
   `

3. Vectoriser :
   const embedding = await openai.embeddings.create({
     model: "text-embedding-3-small",
     input: prompt
   })

4. Upsert :
   INSERT INTO user_embeddings (user_id, embedding, behavior_summary)
   VALUES (...)
   ON CONFLICT (user_id) DO UPDATE SET ...
```

**Output** : Updated embedding dans DB

---

### 3. `calculate-seo-score`

**Trigger** : API call depuis web platform (crÃ©ateur utilise SEO Tool)

**Input** :
```typescript
{
  query: string, // "attiÃ©kÃ© poisson rapide"
  creator_id?: string // optionnel, pour personalisation
}
```

**Process** :
```typescript
1. Vectoriser query
2. Analyser recherches historiques similaires
3. Compter recettes existantes similaires
4. Calculer mÃ©triques :
   - Volume recherches 30j
   - Recettes concurrentes
   - Consommation moyenne
   - Note moyenne
   - Tendance croissance
5. Calculer indice potentiel (formule pondÃ©rÃ©e)
6. GÃ©nÃ©rer insights dÃ©taillÃ©s
```

**Output** :
```typescript
{
  potential_score: number, // 0-100
  search_volume_30d: number,
  existing_recipes: number,
  avg_consumption: number,
  avg_rating: number,
  trend: 'growing' | 'stable' | 'declining',
  growth_rate: number,
  detailed_insights: {
    temporal_distribution: {...},
    consumer_profile: {...},
    competing_recipes: [...],
    suggestions: [...]
  }
}
```

---

### 4. `cluster-niches`

**Trigger** : Cron hebdomadaire (Dimanche 3am)

**Process** :
```typescript
1. Fetch toutes recherches uniques 90j (avec embeddings)

2. Clustering multi-niveaux :
   - Niveau 1 (Large) : K-means K=12
   - Niveau 2 (Medium) : Sub-cluster chaque niveau 1
   - Niveau 3 (Precise) : Sub-cluster chaque niveau 2

3. Pour chaque cluster :
   - Calculer mÃ©triques (volume, recettes existantes)
   - Scorer potentiel financier
   - DÃ©terminer saturation
   - Identifier opportunitÃ©s spÃ©cifiques

4. Update tables :
   - TRUNCATE niche_clusters (ou soft-delete old)
   - INSERT nouveaux clusters
   - INSERT niche_opportunities

5. Notifier crÃ©ateurs Pro :
   - Nouvelles niches Ã©mergentes
   - Changements tendances
```

**Output** : Tables `niche_clusters` et `niche_opportunities` Ã  jour

---

### 5. `check-feature-access`

**Trigger** : API call avant affichage feature Pro

**Input** :
```typescript
{
  creator_id: string,
  feature_name: string,
  increment_usage?: boolean // compte utilisation si true
}
```

**Process** :
```typescript
1. Fetch subscription :
   SELECT tier FROM creator_subscriptions
   WHERE creator_id = $creator_id

2. Fetch feature gate :
   SELECT required_tier, free_tier_monthly_limit
   FROM feature_gates
   WHERE feature_name = $feature_name

3. Check access :
   IF tier >= required_tier :
     return { allowed: true }
   ELSE IF free_tier_monthly_limit :
     count_usage_this_month = ...
     IF count_usage < limit :
       IF increment_usage :
         INSERT feature_usage ...
       return { allowed: true, usage: count, limit: limit }
     ELSE :
       return { allowed: false, reason: 'limit_exceeded' }
   ELSE :
     return { allowed: false, reason: 'requires_pro' }
```

**Output** :
```typescript
{
  allowed: boolean,
  tier: string,
  usage?: number,
  limit?: number,
  reason?: string
}
```

---

## â° Cron Jobs

### 1. Vectoriser Users Actifs

```sql
-- Quotidien 2am
SELECT cron.schedule(
  'vectorize-active-users-daily',
  '0 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://[project-id].supabase.co/functions/v1/vectorize-user',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('user_id', id)
  )
  FROM users
  WHERE last_activity_at > now() - interval '7 days'
  $$
);
```

---

### 2. Recalculer Niches

```sql
-- Hebdomadaire Dimanche 3am
SELECT cron.schedule(
  'recalculate-niches-weekly',
  '0 3 * * 0',
  $$
  SELECT net.http_post(
    url := 'https://[project-id].supabase.co/functions/v1/cluster-niches',
    headers := jsonb_build_object('Content-Type', 'application/json')
  )
  $$
);
```

---

### 3. Update Consumer Demographics

```sql
-- Quotidien 4am
SELECT cron.schedule(
  'update-consumer-demographics-daily',
  '0 4 * * *',
  $$
  -- AgrÃ©gation donnÃ©es consommateurs par crÃ©ateur
  INSERT INTO consumer_demographics (creator_id, user_id, ...)
  SELECT 
    r.creator_id,
    m.user_id,
    u.gender,
    u.age_range,
    COUNT(*) as total_consumptions,
    ...
  FROM meal m
  JOIN receipe r ON r.id = m.receipe_id
  JOIN users u ON u.id = m.user_id
  WHERE m.consumed = true
    AND m.consumed_at > now() - interval '90 days'
  GROUP BY r.creator_id, m.user_id, u.gender, u.age_range
  ON CONFLICT (creator_id, user_id) DO UPDATE SET
    total_consumptions = EXCLUDED.total_consumptions,
    ...
  $$
);
```

---

### 4. Decay MÃ©triques Temporelles

```sql
-- Hebdomadaire Lundi 2am : Reset compteurs 7j
SELECT cron.schedule(
  'reset-weekly-metrics',
  '0 2 * * 1',
  $$
  UPDATE recipe_performance_metrics
  SET 
    meals_planned_last_7d = (
      SELECT COUNT(*) 
      FROM meal 
      WHERE receipe_id = recipe_performance_metrics.recipe_id
        AND meal_date >= CURRENT_DATE - 7
    ),
    meals_cooked_last_7d = (
      SELECT COUNT(*) 
      FROM meal 
      WHERE receipe_id = recipe_performance_metrics.recipe_id
        AND meal_date >= CURRENT_DATE - 7
        AND consumed = true
    )
  $$
);

-- Mensuel 1er du mois 2am : Reset compteurs 30j
SELECT cron.schedule(
  'reset-monthly-metrics',
  '0 2 1 * *',
  $$
  UPDATE recipe_performance_metrics
  SET 
    meals_planned_last_30d = (...),
    meals_cooked_last_30d = (...)
  $$
);

-- Mensuel 1er du mois 3am : Archiver niches obsolÃ¨tes
SELECT cron.schedule(
  'archive-stale-niches',
  '0 3 1 * *',
  $$
  UPDATE niche_clusters
  SET is_active = false
  WHERE total_searches_30d < 5
    AND updated_at < now() - interval '60 days'
  $$
);
```

---

## ðŸ” Row Level Security (RLS)

### Search Queries

```sql
-- Users peuvent voir seulement leurs recherches
CREATE POLICY "Users can view own searches"
  ON search_queries FOR SELECT
  USING (auth.uid() = user_id);

-- Admin/analytics peuvent tout voir (agrÃ©gÃ©)
CREATE POLICY "Admins can view all searches"
  ON search_queries FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');
```

---

### Consumer Demographics

```sql
-- CrÃ©ateurs voient seulement leurs consommateurs
CREATE POLICY "Creators can view own consumers"
  ON consumer_demographics FOR SELECT
  USING (
    creator_id IN (
      SELECT id FROM creator_profiles 
      WHERE user_id = auth.uid()
    )
  );

-- Users ne voient PAS leurs propres donnÃ©es (privacy)
-- Seules donnÃ©es agrÃ©gÃ©es accessibles
```

---

### Niche Clusters

```sql
-- Pro creators peuvent voir toutes niches
CREATE POLICY "Pro creators can view niches"
  ON niche_clusters FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM creator_subscriptions cs
      JOIN creator_profiles cp ON cp.id = cs.creator_id
      WHERE cp.user_id = auth.uid()
        AND cs.tier = 'pro'
        AND cs.status = 'active'
    )
  );

-- Free creators peuvent voir preview (top 5 niches)
CREATE POLICY "Free creators can preview niches"
  ON niche_clusters FOR SELECT
  USING (
    id IN (
      SELECT id FROM niche_clusters
      ORDER BY financial_potential_score DESC
      LIMIT 5
    )
  );
```

---

### Creator Subscriptions

```sql
-- CrÃ©ateurs voient seulement leur subscription
CREATE POLICY "Creators can view own subscription"
  ON creator_subscriptions FOR SELECT
  USING (
    creator_id IN (
      SELECT id FROM creator_profiles
      WHERE user_id = auth.uid()
    )
  );

-- CrÃ©ateurs peuvent update leur subscription (cancel)
CREATE POLICY "Creators can update own subscription"
  ON creator_subscriptions FOR UPDATE
  USING (
    creator_id IN (
      SELECT id FROM creator_profiles
      WHERE user_id = auth.uid()
    )
  );
```

---

## ðŸ“Š Materialized Views (Optimisation)

### View : Niche Leaderboard

```sql
CREATE MATERIALIZED VIEW niche_leaderboard AS
SELECT 
  nc.id,
  nc.name,
  nc.granularity,
  nc.total_searches_30d,
  nc.existing_recipes_count,
  nc.financial_potential_score,
  nc.saturation_level,
  nc.growth_rate_30d,
  nc.consumer_profile,
  COUNT(DISTINCT no.id) as opportunity_count
FROM niche_clusters nc
LEFT JOIN niche_opportunities no ON no.niche_cluster_id = nc.id
WHERE nc.is_active = true
GROUP BY nc.id
ORDER BY nc.financial_potential_score DESC;

-- Refresh quotidien aprÃ¨s cron clustering
CREATE INDEX idx_niche_leaderboard_score ON niche_leaderboard(financial_potential_score DESC);
```

---

### View : Creator Analytics Summary

```sql
CREATE MATERIALIZED VIEW creator_analytics_summary AS
SELECT 
  cd.creator_id,
  COUNT(DISTINCT cd.user_id) as total_consumers,
  COUNT(DISTINCT cd.user_id) FILTER (WHERE cd.is_recurring) as recurring_consumers,
  COUNT(DISTINCT cd.user_id) FILTER (WHERE cd.is_loyal) as loyal_consumers,
  AVG(cd.completion_rate) as avg_completion_rate,
  
  -- DÃ©mographie dominante
  MODE() WITHIN GROUP (ORDER BY cd.gender) as dominant_gender,
  MODE() WITHIN GROUP (ORDER BY cd.age_range) as dominant_age_range,
  MODE() WITHIN GROUP (ORDER BY cd.fitness_goal) as dominant_goal,
  MODE() WITHIN GROUP (ORDER BY cd.country) as dominant_country,
  
  -- Temporal patterns
  MODE() WITHIN GROUP (ORDER BY cd.preferred_day) as peak_day,
  MODE() WITHIN GROUP (ORDER BY cd.preferred_meal) as peak_meal,
  
  -- Engagement
  SUM(cd.total_consumptions) as total_consumptions,
  SUM(cd.total_likes) as total_likes,
  AVG(cd.avg_rating) as avg_rating

FROM consumer_demographics cd
GROUP BY cd.creator_id;

-- Refresh quotidien
CREATE INDEX idx_analytics_summary_creator ON creator_analytics_summary(creator_id);
```

---

## ðŸš€ Performance Optimizations

### 1. Partitioning `search_queries` par Date

```sql
-- Pour gÃ©rer volume croissant recherches
CREATE TABLE search_queries_y2025m02 PARTITION OF search_queries
  FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE search_queries_y2025m03 PARTITION OF search_queries
  FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- Etc, crÃ©er automatiquement via cron
```

---

### 2. Caching Layer (Redis/Supabase Cache)

**Ã€ cacher** :
- Niche leaderboard (TTL: 1 jour)
- SEO scores frÃ©quents (TTL: 1 heure)
- Creator analytics summary (TTL: 1 jour)

**ImplÃ©mentation** : Edge Functions avec cache headers

---

### 3. Query Optimizations

**Ã‰viter** :
```sql
-- âŒ Scan complet table pour chaque recherche
SELECT * FROM search_queries 
WHERE query_text ILIKE '%attiÃ©kÃ©%';
```

**PrÃ©fÃ©rer** :
```sql
-- âœ… Vector similarity (index ivfflat)
SELECT * FROM search_queries
ORDER BY query_embedding <=> $query_embedding
LIMIT 100;

-- âœ… Full-text search (index GIN)
SELECT * FROM search_queries
WHERE to_tsvector('french', query_text) @@ to_tsquery('french', 'attiÃ©kÃ©');
```

---

## ðŸ“ˆ Monitoring & Alerts

### MÃ©triques DB Ã  Tracker

```sql
-- Volume recherches (croissance)
SELECT DATE(searched_at), COUNT(*) 
FROM search_queries 
GROUP BY DATE(searched_at)
ORDER BY DATE(searched_at) DESC;

-- Usage features Pro
SELECT feature_name, COUNT(*) 
FROM feature_usage 
WHERE created_at > now() - interval '7 days'
GROUP BY feature_name;

-- Performance vectorisation
SELECT 
  COUNT(*) FILTER (WHERE query_embedding IS NULL) as pending,
  COUNT(*) FILTER (WHERE query_embedding IS NOT NULL) as completed
FROM search_queries
WHERE created_at > now() - interval '1 day';
```

---

**Prochaine section** : [04 - Roadmap & ImplÃ©mentation](04-roadmap-implementation.md)
