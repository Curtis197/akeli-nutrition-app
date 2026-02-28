# 04 - Roadmap & ImplÃ©mentation

---

## ðŸŽ¯ Vue d'Ensemble

La roadmap V1 est structurÃ©e en **5 phases progressives** :

- **Phase 0** : Collecte donnÃ©es (prÃ©-requis, dÃ©marrer ASAP)
- **Phase 1** : Infrastructure fondations
- **Phase 2** : Features Pro Tier
- **Phase 3** : Plateforme Web complÃ¨te
- **Phase 4** : Mobile App update
- **Phase 5** : Testing & Launch

**Principe** : Chaque phase dÃ©livre de la valeur incrÃ©mentale et peut Ãªtre testÃ©e indÃ©pendamment.

---

## ðŸ“… PHASE 0 : Collecte DonnÃ©es (PrÃ©-V1)

### Objectif
Commencer Ã  accumuler donnÃ©es de recherche **AVANT** le launch des features Pro pour avoir insights significatifs dÃ¨s jour 1.

### DurÃ©e RecommandÃ©e
**Minimum 30-60 jours** de collecte pour volume statistiquement utile.

### Pourquoi Critique ?
Sans donnÃ©es historiques :
- SEO Tool retournera "0 recherches" pour la plupart des queries
- Niche Finder sera vide ou basÃ© sur niches prÃ©dÃ©finies manuellement
- Analytics crÃ©ateurs manqueront de profondeur

---

### Actions Phase 0

#### âœ… Backend Setup

**1. Database Schema**
```sql
-- CrÃ©er table search_queries (version minimale)
CREATE TABLE search_queries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id),
  query_text text NOT NULL,
  query_embedding vector(1536),
  searched_at timestamptz DEFAULT now(),
  results_count int DEFAULT 0,
  clicked_recipe_id uuid REFERENCES receipe(id),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_search_queries_date ON search_queries(searched_at DESC);
CREATE INDEX idx_search_queries_text ON search_queries(query_text);
```

**2. Edge Function Basique**
```typescript
// /functions/track-search/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { query, user_id, results_count } = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  // Simple INSERT sans vectorisation (pour l'instant)
  const { data, error } = await supabase
    .from('search_queries')
    .insert({
      query_text: query,
      user_id: user_id,
      results_count: results_count,
      searched_at: new Date().toISOString()
    })
  
  return new Response(
    JSON.stringify({ success: !error }),
    { headers: { "Content-Type": "application/json" } }
  )
})
```

---

#### âœ… Mobile App Update

**Modifier Flutter App : Track Recherches**

```dart
// lib/services/search_service.dart

Future<List<Recipe>> searchRecipes(String query) async {
  // Recherche normale (existante)
  final results = await _supabase
    .from('receipe')
    .select()
    .textSearch('name', query)
    .execute();
  
  // NOUVEAU : Track recherche
  await _trackSearch(query, results.data?.length ?? 0);
  
  return results.data?.map((r) => Recipe.fromJson(r)).toList() ?? [];
}

Future<void> _trackSearch(String query, int resultsCount) async {
  try {
    await _supabase.functions.invoke('track-search', 
      body: {
        'query': query,
        'user_id': _supabase.auth.currentUser?.id,
        'results_count': resultsCount,
      }
    );
  } catch (e) {
    // Silent fail - ne pas bloquer recherche si tracking Ã©choue
    print('Search tracking failed: $e');
  }
}

// Track clic sur recette
Future<void> trackRecipeClick(String searchId, String recipeId) async {
  await _supabase
    .from('search_queries')
    .update({'clicked_recipe_id': recipeId, 'clicked_at': DateTime.now()})
    .eq('id', searchId)
    .execute();
}
```

---

#### âœ… Validation & Monitoring

**Dashboard Simple : Supabase SQL Editor**

```sql
-- Queries trackÃ©es par jour
SELECT 
  DATE(searched_at) as date,
  COUNT(*) as searches,
  COUNT(DISTINCT user_id) as unique_users
FROM search_queries
WHERE searched_at > now() - interval '30 days'
GROUP BY DATE(searched_at)
ORDER BY date DESC;

-- Top 20 recherches
SELECT 
  query_text,
  COUNT(*) as frequency
FROM search_queries
WHERE searched_at > now() - interval '7 days'
GROUP BY query_text
ORDER BY frequency DESC
LIMIT 20;

-- Taux clic (CTR basique)
SELECT 
  COUNT(*) FILTER (WHERE clicked_recipe_id IS NOT NULL)::float / 
  COUNT(*)::float * 100 as ctr_percentage
FROM search_queries
WHERE searched_at > now() - interval '7 days';
```

---

### âœ… CritÃ¨res SuccÃ¨s Phase 0

Avant de passer Phase 1, vÃ©rifier :

- [ ] **Volume** : Minimum 5,000 recherches collectÃ©es
- [ ] **DiversitÃ©** : Au moins 500 queries uniques
- [ ] **QualitÃ©** : <5% recherches vides ou invalides
- [ ] **Couverture** : Recherches de 50+ users diffÃ©rents
- [ ] **Tracking clic** : Au moins 20% CTR global

**Si critÃ¨res non atteints** : Continuer Phase 0 + encourager usage app (growth hacking, notifications)

---

## ðŸ—ï¸ PHASE 1 : Infrastructure Fondations

### Objectif
Mettre en place toute l'infrastructure technique nÃ©cessaire aux features Pro sans encore exposer les features aux utilisateurs.

### DurÃ©e EstimÃ©e
**2-4 semaines** (dÃ©pend familiaritÃ© stack)

---

### 1.1 Database Schema Complet

**Actions** :
- [ ] CrÃ©er toutes tables V1 (voir [03-database-schema.md](03-database-schema.md))
  - `user_embeddings`
  - `niche_clusters`
  - `niche_opportunities`
  - `creator_subscriptions`
  - `feature_gates`
  - `consumer_demographics`
- [ ] Modifier tables existantes
  - `recipe_performance_metrics` : colonnes search
  - `receipe` : colonne embedding
- [ ] CrÃ©er indexes optimisÃ©s (vector indexes, composite)
- [ ] Setup RLS policies (sÃ©curitÃ©)

**Tests** :
```sql
-- VÃ©rifier tables crÃ©Ã©es
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('user_embeddings', 'niche_clusters', ...);

-- VÃ©rifier indexes vector (pgvector)
SELECT indexname FROM pg_indexes 
WHERE tablename = 'search_queries' 
  AND indexname LIKE '%embedding%';
```

---

### 1.2 SystÃ¨me Vectorisation

**Edge Function : `vectorize-search`**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from '@supabase/supabase-js'
import OpenAI from 'openai'

const openai = new OpenAI({ apiKey: Deno.env.get('OPENAI_API_KEY') })
const supabase = createClient(...)

serve(async (req) => {
  const { query, user_id } = await req.json()
  
  // 1. Vectoriser query
  const embeddingResponse = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: query,
  })
  const embedding = embeddingResponse.data[0].embedding
  
  // 2. Chercher recettes similaires
  const { data: recipes } = await supabase.rpc('match_recipes', {
    query_embedding: embedding,
    match_threshold: 0.7,
    match_count: 20
  })
  
  // 3. Stocker recherche
  const { data: search } = await supabase
    .from('search_queries')
    .insert({
      query_text: query,
      query_embedding: embedding,
      user_id: user_id,
      results_count: recipes.length
    })
    .select()
    .single()
  
  // 4. Retourner rÃ©sultats
  return new Response(JSON.stringify({
    results: recipes,
    search_id: search.id
  }))
})
```

**SQL Function : `match_recipes`**

```sql
CREATE OR REPLACE FUNCTION match_recipes(
  query_embedding vector(1536),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id uuid,
  name text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.name,
    1 - (r.embedding <=> query_embedding) as similarity
  FROM receipe r
  WHERE r.embedding IS NOT NULL
    AND 1 - (r.embedding <=> query_embedding) > match_threshold
  ORDER BY r.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
```

---

**Edge Function : `vectorize-user`**

```typescript
serve(async (req) => {
  const { user_id } = await req.json()
  
  // 1. AgrÃ©ger comportement user
  const { data: profile } = await supabase.rpc('get_user_behavior_profile', {
    p_user_id: user_id
  })
  
  // 2. GÃ©nÃ©rer prompt descriptif
  const prompt = `User profile summary:
  Gender: ${profile.gender}, Age: ${profile.age_range}
  Fitness goals: ${profile.goals.join(', ')}
  Consumed cuisines: ${profile.cuisines.join(', ')}
  Preferred ingredients: ${profile.ingredients.join(', ')}
  Search patterns: ${profile.search_keywords.join(', ')}
  Cooking time preference: ${profile.avg_cooking_time} minutes
  `
  
  // 3. Vectoriser
  const embeddingResponse = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: prompt
  })
  
  // 4. Upsert
  await supabase
    .from('user_embeddings')
    .upsert({
      user_id: user_id,
      embedding: embeddingResponse.data[0].embedding,
      behavior_summary: profile,
      updated_at: new Date().toISOString()
    })
  
  return new Response(JSON.stringify({ success: true }))
})
```

---

**Cron Job : Vectorisation Quotidienne**

```sql
SELECT cron.schedule(
  'vectorize-active-users',
  '0 2 * * *', -- 2am quotidien
  $$
  SELECT net.http_post(
    url := 'https://[project].supabase.co/functions/v1/vectorize-user',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := json_build_object('user_id', id)::jsonb
  )
  FROM users
  WHERE last_activity_at > now() - interval '7 days'
  $$
);
```

---

### 1.3 Subscription System (Stripe)

**Actions** :
- [ ] CrÃ©er Stripe account (si pas dÃ©jÃ )
- [ ] Configurer Products & Prices :
  - Product "Akeli Pro - Europe" : â‚¬30/mois
  - Product "Akeli Pro - Afrique" : â‚¬12/mois
- [ ] Setup Webhooks Stripe â†’ Supabase
- [ ] ImplÃ©menter Edge Function `stripe-webhook`

**Edge Function : `stripe-webhook`**

```typescript
import Stripe from 'stripe'
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!)

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')!
  const body = await req.text()
  
  let event
  try {
    event = stripe.webhooks.constructEvent(
      body, 
      signature, 
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    )
  } catch (err) {
    return new Response('Webhook signature verification failed', { status: 400 })
  }
  
  // Handle events
  switch (event.type) {
    case 'customer.subscription.created':
    case 'customer.subscription.updated':
      await handleSubscriptionUpdate(event.data.object)
      break
    
    case 'customer.subscription.deleted':
      await handleSubscriptionCancelled(event.data.object)
      break
    
    case 'invoice.payment_succeeded':
      await handlePaymentSuccess(event.data.object)
      break
  }
  
  return new Response(JSON.stringify({ received: true }))
})

async function handleSubscriptionUpdate(subscription) {
  const creator_id = subscription.metadata.creator_id
  
  await supabase
    .from('creator_subscriptions')
    .upsert({
      creator_id: creator_id,
      tier: 'pro',
      status: subscription.status,
      stripe_subscription_id: subscription.id,
      stripe_customer_id: subscription.customer,
      current_period_start: new Date(subscription.current_period_start * 1000),
      current_period_end: new Date(subscription.current_period_end * 1000),
      price_eur: subscription.items.data[0].price.unit_amount / 100,
      updated_at: new Date()
    })
}
```

---

### 1.4 Feature Gating

**Edge Function : `check-feature-access`**

```typescript
serve(async (req) => {
  const { creator_id, feature_name } = await req.json()
  
  // 1. Get subscription
  const { data: sub } = await supabase
    .from('creator_subscriptions')
    .select('tier, status')
    .eq('creator_id', creator_id)
    .single()
  
  // 2. Get feature gate
  const { data: gate } = await supabase
    .from('feature_gates')
    .select('required_tier, free_tier_monthly_limit')
    .eq('feature_name', feature_name)
    .single()
  
  // 3. Check access
  if (!sub || sub.tier === 'free') {
    if (!gate.free_tier_monthly_limit) {
      return Response.json({ 
        allowed: false, 
        reason: 'requires_pro' 
      })
    }
    
    // Check usage limit
    const { count } = await supabase
      .from('feature_usage')
      .select('*', { count: 'exact' })
      .eq('creator_id', creator_id)
      .eq('feature_name', feature_name)
      .gte('created_at', startOfMonth())
    
    if (count >= gate.free_tier_monthly_limit) {
      return Response.json({
        allowed: false,
        reason: 'limit_exceeded',
        usage: count,
        limit: gate.free_tier_monthly_limit
      })
    }
  }
  
  return Response.json({ allowed: true, tier: sub?.tier || 'free' })
})
```

---

### âœ… CritÃ¨res SuccÃ¨s Phase 1

- [ ] Toutes tables crÃ©Ã©es et migrÃ©es sans erreur
- [ ] Vectorisation fonctionne (test manuel : vectoriser 10 users)
- [ ] Stripe webhooks reÃ§us et traitÃ©s (test mode)
- [ ] Feature gating bloque correctement free tier
- [ ] Cron jobs s'exÃ©cutent sans erreur

---

## ðŸŽ¨ PHASE 2 : Features Pro Tier

### Objectif
DÃ©velopper les 3 features principales accessibles aux crÃ©ateurs Pro.

### DurÃ©e EstimÃ©e
**4-6 semaines**

---

### 2.1 In-App SEO Tool

**Edge Function : `calculate-seo-score`**

```typescript
serve(async (req) => {
  const { query, creator_id } = await req.json()
  
  // 1. Vectoriser query
  const embedding = await getEmbedding(query)
  
  // 2. Analyser recherches similaires historiques
  const { data: searches } = await supabase.rpc('get_similar_searches', {
    query_embedding: embedding,
    days_back: 30
  })
  
  const search_volume_30d = searches.length
  
  // 3. Compter recettes existantes similaires
  const { data: recipes } = await supabase.rpc('match_recipes', {
    query_embedding: embedding,
    match_threshold: 0.75,
    match_count: 100
  })
  
  const existing_recipes = recipes.length
  const avg_consumption = average(recipes.map(r => r.total_consumptions))
  const avg_rating = average(recipes.map(r => r.avg_rating))
  
  // 4. Calculer tendance
  const { data: searches_prev } = await supabase.rpc('get_similar_searches', {
    query_embedding: embedding,
    days_back: 60,
    days_end: 30
  })
  
  const growth_rate = ((search_volume_30d - searches_prev.length) / searches_prev.length) * 100
  
  // 5. Calculer indice potentiel (formule)
  const demand_score = calculateDemandScore(search_volume_30d)
  const opportunity_score = calculateOpportunityScore(search_volume_30d, existing_recipes)
  const engagement_score = calculateEngagementScore(avg_consumption, avg_rating)
  const trend_score = calculateTrendScore(growth_rate)
  
  const potential_score = Math.round(
    (demand_score * 0.4) +
    (opportunity_score * 0.3) +
    (engagement_score * 0.2) +
    (trend_score * 0.1)
  )
  
  // 6. DÃ©tails exhaustifs
  const detailed_insights = await generateDetailedInsights({
    searches,
    recipes,
    query,
    embedding
  })
  
  return Response.json({
    potential_score,
    search_volume_30d,
    existing_recipes,
    avg_consumption,
    avg_rating,
    growth_rate,
    trend: growth_rate > 10 ? 'growing' : growth_rate < -10 ? 'declining' : 'stable',
    detailed_insights
  })
})
```

**Frontend : Page SEO Tool (Next.js)**

```tsx
// app/seo-tool/page.tsx

'use client'
import { useState } from 'react'

export default function SEOToolPage() {
  const [query, setQuery] = useState('')
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(false)
  
  async function analyzePotential() {
    setLoading(true)
    const res = await fetch('/api/seo-score', {
      method: 'POST',
      body: JSON.stringify({ query })
    })
    const data = await res.json()
    setResult(data)
    setLoading(false)
  }
  
  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1>In-App SEO Tool</h1>
      
      <div className="my-8">
        <textarea
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Entrez mot-clÃ© ou dÃ©crivez votre idÃ©e de recette..."
          className="w-full p-4 border rounded"
        />
        <button 
          onClick={analyzePotential}
          disabled={loading}
          className="mt-4 px-6 py-3 bg-green-600 text-white rounded"
        >
          {loading ? 'Analyse...' : 'Analyser Potentiel'}
        </button>
      </div>
      
      {result && (
        <div className="bg-white shadow rounded-lg p-6">
          <div className="text-center mb-6">
            <div className="text-6xl font-bold text-green-600">
              {result.potential_score}/100
            </div>
            <div className="text-gray-600">Indice Potentiel</div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <MetricCard 
              label="Volume Recherches"
              value={`${result.search_volume_30d}/mois`}
              trend={result.growth_rate}
            />
            <MetricCard 
              label="Recettes Existantes"
              value={result.existing_recipes}
            />
            <MetricCard 
              label="Consommation Moyenne"
              value={result.avg_consumption}
            />
            <MetricCard 
              label="Note Moyenne"
              value={`${result.avg_rating}â­`}
            />
          </div>
          
          {/* DÃ©tails exhaustifs (collapsible) */}
        </div>
      )}
    </div>
  )
}
```

---

### 2.2 Niche Finder

**Edge Function : `cluster-niches`**

```typescript
// Algorithme clustering conceptuel
serve(async (req) => {
  // 1. Fetch searches uniques 90j
  const { data: searches } = await supabase
    .from('search_queries')
    .select('id, query_text, query_embedding')
    .gte('searched_at', daysAgo(90))
    .not('query_embedding', 'is', null)
  
  // 2. Clustering multi-niveaux (pseudo-code)
  const level1Clusters = kMeansClustering(searches, k=12)
  const level2Clusters = level1Clusters.flatMap(c => kMeansClustering(c, k=4))
  const level3Clusters = level2Clusters.flatMap(c => kMeansClustering(c, k=3))
  
  // 3. Pour chaque cluster, calculer mÃ©triques
  for (const cluster of [...level1Clusters, ...level2Clusters, ...level3Clusters]) {
    const metrics = await calculateClusterMetrics(cluster)
    
    await supabase.from('niche_clusters').insert({
      name: generateClusterName(cluster),
      granularity: cluster.level,
      search_query_ids: cluster.query_ids,
      centroid_embedding: cluster.centroid,
      total_searches_30d: metrics.search_volume,
      existing_recipes_count: metrics.recipe_count,
      financial_potential_score: metrics.revenue_estimate,
      saturation_level: calculateSaturation(metrics),
      growth_rate_30d: metrics.growth_rate,
      consumer_profile: metrics.demographics
    })
    
    // Identifier opportunitÃ©s spÃ©cifiques
    const opportunities = identifyOpportunities(cluster, metrics)
    for (const opp of opportunities) {
      await supabase.from('niche_opportunities').insert(opp)
    }
  }
  
  return Response.json({ clusters_created: allClusters.length })
})
```

**Cron Job : Weekly**

```sql
SELECT cron.schedule(
  'recalculate-niches',
  '0 3 * * 0', -- Dimanche 3am
  $$
  SELECT net.http_post(
    url := 'https://[project].supabase.co/functions/v1/cluster-niches',
    headers := '{"Content-Type": "application/json"}'::jsonb
  )
  $$
);
```

**Frontend : Niche Finder Page**

```tsx
// app/niche-finder/page.tsx

export default function NicheFinderPage() {
  const [niches, setNiches] = useState([])
  const [filters, setFilters] = useState({
    granularity: 'all',
    region: 'all'
  })
  
  useEffect(() => {
    fetchNiches()
  }, [filters])
  
  async function fetchNiches() {
    const { data } = await supabase
      .from('niche_clusters')
      .select('*')
      .order('financial_potential_score', { ascending: false })
      .limit(20)
    setNiches(data)
  }
  
  return (
    <div>
      <h1>DÃ©couvrir Niches</h1>
      
      {/* Filtres */}
      <div className="filters">
        <select 
          value={filters.granularity}
          onChange={(e) => setFilters({...filters, granularity: e.target.value})}
        >
          <option value="all">Toutes GranularitÃ©s</option>
          <option value="large">Large</option>
          <option value="medium">Moyen</option>
          <option value="precise">PrÃ©cis</option>
        </select>
      </div>
      
      {/* Feed niches */}
      <div className="niches-feed">
        {niches.map((niche, idx) => (
          <NicheCard key={niche.id} niche={niche} rank={idx + 1} />
        ))}
      </div>
    </div>
  )
}
```

---

### 2.3 Advanced Analytics

**Cron Job : Update Demographics**

```sql
SELECT cron.schedule(
  'update-demographics',
  '0 4 * * *', -- Quotidien 4am
  $$
  INSERT INTO consumer_demographics (
    creator_id, user_id, gender, age_range, country,
    fitness_goal, total_consumptions, completion_rate,
    preferred_day, preferred_meal, total_likes
  )
  SELECT 
    r.creator_id,
    m.user_id,
    u.gender,
    u.age_range,
    u.country,
    ug.goal,
    COUNT(*) as total_consumptions,
    AVG(CASE WHEN m.consumed THEN 1 ELSE 0 END) as completion_rate,
    MODE() WITHIN GROUP (ORDER BY EXTRACT(DOW FROM m.meal_date)) as preferred_day,
    MODE() WITHIN GROUP (ORDER BY m.meal_type) as preferred_meal,
    COUNT(l.id) as total_likes
  FROM meal m
  JOIN receipe r ON r.id = m.receipe_id
  JOIN users u ON u.id = m.user_id
  LEFT JOIN user_goal ug ON ug.user_id = u.id
  LEFT JOIN likes l ON l.recipe_id = r.id AND l.user_id = m.user_id
  WHERE m.meal_date > now() - interval '90 days'
  GROUP BY r.creator_id, m.user_id, u.gender, u.age_range, u.country, ug.goal
  ON CONFLICT (creator_id, user_id) DO UPDATE SET
    total_consumptions = EXCLUDED.total_consumptions,
    completion_rate = EXCLUDED.completion_rate,
    updated_at = now()
  $$
);
```

**Frontend : Analytics Dashboard**

```tsx
// app/analytics/page.tsx

export default function AnalyticsPage() {
  const [analytics, setAnalytics] = useState(null)
  
  useEffect(() => {
    async function fetchAnalytics() {
      // Utiliser materialized view
      const { data } = await supabase
        .from('creator_analytics_summary')
        .select('*')
        .eq('creator_id', currentCreatorId)
        .single()
      
      setAnalytics(data)
    }
    fetchAnalytics()
  }, [])
  
  if (!analytics) return <Loading />
  
  return (
    <div>
      <h1>Mes Consommateurs</h1>
      
      {/* Vue d'ensemble */}
      <StatsGrid>
        <StatCard 
          label="Total Consommateurs"
          value={analytics.total_consumers}
        />
        <StatCard 
          label="RÃ©currents"
          value={`${analytics.recurring_consumers} (${pct}%)`}
        />
        <StatCard 
          label="Loyaux"
          value={analytics.loyal_consumers}
        />
      </StatsGrid>
      
      {/* DÃ©mographie */}
      <Section title="DÃ©mographie">
        <BarChart 
          data={analytics.gender_distribution}
          label="Genre"
        />
        <BarChart 
          data={analytics.age_distribution}
          label="Ã‚ge"
        />
      </Section>
      
      {/* Insights actionnables */}
      <Section title="Insights">
        <InsightCard 
          type="success"
          message="Vos recettes rapides surperforment auprÃ¨s femmes 25-34"
          action="CrÃ©er plus de recettes dans ce style"
        />
      </Section>
    </div>
  )
}
```

---

### âœ… CritÃ¨res SuccÃ¨s Phase 2

- [ ] SEO Tool retourne scores cohÃ©rents (tester 20+ queries)
- [ ] Niche Finder affiche niches pertinentes (validation manuelle top 10)
- [ ] Analytics crÃ©ateurs affichent donnÃ©es rÃ©elles (tester avec 5 crÃ©ateurs beta)
- [ ] Performance acceptable (<3s load time chaque feature)

---

## ðŸŒ PHASE 3 : Plateforme Web V1 ComplÃ¨te

### Objectif
IntÃ©grer toutes les features dans une plateforme web cohÃ©rente avec navigation, design, et subscription flow.

### DurÃ©e EstimÃ©e
**3-4 semaines**

---

### 3.1 Pages Principales

**Architecture Next.js** :

```
/app
  /layout.tsx                  # Layout global
  /(auth)
    /login/page.tsx
    /signup/page.tsx
  /(dashboard)
    /layout.tsx                # Layout crÃ©ateur (sidebar)
    /page.tsx                  # Dashboard home
    /recipes
      /page.tsx                # Liste recettes
      /[id]/edit/page.tsx      # Ã‰dition recette
      /new/page.tsx            # CrÃ©ation recette
    /revenue
      /page.tsx                # Revenue tracking (existant)
    /seo-tool
      /page.tsx                # SEO Tool (Phase 2)
    /niche-finder
      /page.tsx                # Niche Finder (Phase 2)
      /[id]/page.tsx           # DÃ©tail niche
    /analytics
      /page.tsx                # Analytics (Phase 2)
    /settings
      /page.tsx                # ParamÃ¨tres
      /subscription/page.tsx   # Gestion abonnement
```

---

### 3.2 Design System

**Composants RÃ©utilisables** :

```tsx
// components/ui/Card.tsx
export function Card({ children, className }) {
  return (
    <div className={`bg-white shadow rounded-lg p-6 ${className}`}>
      {children}
    </div>
  )
}

// components/ui/StatCard.tsx
export function StatCard({ label, value, trend }) {
  return (
    <Card>
      <div className="text-sm text-gray-600">{label}</div>
      <div className="text-3xl font-bold mt-2">{value}</div>
      {trend && <Trend value={trend} />}
    </Card>
  )
}

// components/ui/ProBadge.tsx
export function ProBadge() {
  return (
    <span className="bg-gradient-to-r from-green-400 to-blue-500 text-white px-3 py-1 rounded-full text-xs font-semibold">
      PRO
    </span>
  )
}
```

**Theme Akeli** :

```tsx
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0fdf4',
          500: '#3BB78F',  // Vert Akeli
          600: '#2d9570',
          700: '#1f7350',
        },
        // Status colors
        success: '#10b981',
        warning: '#f59e0b',
        danger: '#ef4444',
        info: '#3b82f6'
      }
    }
  }
}
```

---

### 3.3 Subscription Flow

**Page Pricing** :

```tsx
// app/pricing/page.tsx

export default function PricingPage() {
  const [region, setRegion] = useState<'europe' | 'africa'>('europe')
  const price = region === 'europe' ? 30 : 12
  
  return (
    <div className="max-w-4xl mx-auto">
      <h1>Devenez CrÃ©ateur Pro</h1>
      
      {/* Toggle rÃ©gion */}
      <RegionSelector value={region} onChange={setRegion} />
      
      <div className="grid md:grid-cols-2 gap-8 mt-12">
        {/* Free Tier */}
        <PricingCard 
          tier="free"
          price="â‚¬0"
          features={[
            "CrÃ©ation recettes illimitÃ©e",
            "Revenue tracking",
            "Analytics basiques",
            "5 recherches SEO/mois"
          ]}
        />
        
        {/* Pro Tier */}
        <PricingCard 
          tier="pro"
          price={`â‚¬${price}`}
          period="/mois"
          highlighted
          features={[
            "Tout du Free, plus :",
            "âœ¨ SEO Tool illimitÃ©",
            "âœ¨ Niche Finder complet",
            "âœ¨ Analytics avancÃ©es",
            "âœ¨ Insights IA",
            "Support prioritaire"
          ]}
          cta={<CheckoutButton region={region} />}
        />
      </div>
    </div>
  )
}
```

**Checkout Flow (Stripe)** :

```tsx
// components/CheckoutButton.tsx

export function CheckoutButton({ region }) {
  async function handleCheckout() {
    const { data } = await fetch('/api/create-checkout-session', {
      method: 'POST',
      body: JSON.stringify({ 
        region,
        creator_id: currentCreator.id
      })
    }).then(r => r.json())
    
    // Redirect to Stripe Checkout
    window.location.href = data.checkout_url
  }
  
  return (
    <button onClick={handleCheckout} className="btn-primary">
      Devenir Pro
    </button>
  )
}
```

**API Route : Create Checkout**

```typescript
// app/api/create-checkout-session/route.ts

import Stripe from 'stripe'
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)

export async function POST(req: Request) {
  const { region, creator_id } = await req.json()
  
  const price_id = region === 'europe' 
    ? process.env.STRIPE_PRICE_EU 
    : process.env.STRIPE_PRICE_AFRICA
  
  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    line_items: [{ price: price_id, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_URL}/dashboard?success=true`,
    cancel_url: `${process.env.NEXT_PUBLIC_URL}/pricing?cancelled=true`,
    metadata: { creator_id }
  })
  
  return Response.json({ checkout_url: session.url })
}
```

---

### 3.4 Feature Gating Middleware

**Protection Routes Pro** :

```typescript
// middleware.ts

import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createMiddlewareClient({ req, res })
  
  // Routes Pro
  const proRoutes = ['/seo-tool', '/niche-finder', '/analytics']
  const isProRoute = proRoutes.some(route => req.nextUrl.pathname.startsWith(route))
  
  if (isProRoute) {
    const { data: { user } } = await supabase.auth.getUser()
    
    if (!user) {
      return NextResponse.redirect(new URL('/login', req.url))
    }
    
    // Check Pro tier
    const { data: sub } = await supabase
      .from('creator_subscriptions')
      .select('tier, status')
      .eq('creator_id', user.id)
      .single()
    
    if (!sub || sub.tier !== 'pro' || sub.status !== 'active') {
      return NextResponse.redirect(new URL('/pricing', req.url))
    }
  }
  
  return res
}
```

---

### âœ… CritÃ¨res SuccÃ¨s Phase 3

- [ ] Toutes pages navigables et responsive
- [ ] Feature gating fonctionne (test free vs pro)
- [ ] Checkout Stripe complÃ¨te cycle (test mode)
- [ ] Design cohÃ©rent toutes pages
- [ ] Performance Lighthouse >90 (desktop)

---

## ðŸ“± PHASE 4 : Mobile App Update

### Objectif
Synchroniser mobile app avec nouvelles features backend.

### DurÃ©e EstimÃ©e
**1-2 semaines**

---

### Actions

**1. Search Tracking (dÃ©jÃ  fait Phase 0, vÃ©rifier)**

**2. Deep Links vers Web Platform**

```dart
// lib/widgets/pro_banner.dart

class ProFeatureBanner extends StatelessWidget {
  final String feature;
  
  Widget build(context) {
    return Card(
      child: Column(
        children: [
          Text('ðŸ”¥ Feature Pro : $feature'),
          Text('Analysez vos opportunitÃ©s sur la plateforme web'),
          ElevatedButton(
            onPressed: () => _openWebPlatform(),
            child: Text('DÃ©couvrir')
          )
        ]
      )
    );
  }
  
  void _openWebPlatform() {
    final url = 'https://akeli.app/$feature';
    launchUrl(Uri.parse(url));
  }
}
```

**3. Afficher Recettes Trending (from Niches)**

```dart
// lib/screens/discover_screen.dart

class DiscoverScreen extends StatelessWidget {
  Widget build(context) {
    return Column(
      children: [
        // Existant : search, filters
        
        // NOUVEAU : Section trending
        FutureBuilder(
          future: _fetchTrendingRecipes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Loading();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ðŸ”¥ Tendances du Moment', style: heading),
                RecipeCarousel(recipes: snapshot.data),
              ]
            );
          }
        )
      ]
    );
  }
  
  Future<List<Recipe>> _fetchTrendingRecipes() async {
    // Fetch recettes dans top niches
    final { data } = await Supabase.instance.client
      .from('niche_opportunities')
      .select('target_query')
      .order('estimated_monthly_revenue', ascending: false)
      .limit(5);
    
    // Pour chaque opportunitÃ©, fetch best recipe
    // ... (logic)
  }
}
```

---

### âœ… CritÃ¨res SuccÃ¨s Phase 4

- [ ] Search tracking stable (>95% success rate)
- [ ] Deep links fonctionnent iOS + Android
- [ ] Trending section affiche recettes pertinentes
- [ ] Pas de rÃ©gression features existantes

---

## ðŸ§ª PHASE 5 : Testing & Launch

### Objectif
Valider qualitÃ©, corriger bugs, lancer V1 publiquement.

### DurÃ©e EstimÃ©e
**2-3 semaines**

---

### 5.1 Beta Testing

**Recrutement Beta Testers** :
- [ ] 10 crÃ©ateurs actuels (mix free/aspirants pro)
- [ ] 5 nouveaux crÃ©ateurs (fresh perspective)

**Protocole Test** :
1. Onboarding complet (signup â†’ crÃ©ation recette â†’ exploration features)
2. TÃ¢ches guidÃ©es :
   - "Testez 5 idÃ©es recettes avec SEO Tool"
   - "Trouvez votre niche idÃ©ale via Niche Finder"
   - "Consultez vos analytics consommateurs"
3. Feedback form :
   - Bugs rencontrÃ©s
   - Features confuses
   - Suggestions amÃ©lioration
   - NPS (0-10)

**CritÃ¨res Validation** :
- [ ] 0 bugs bloquants (P0)
- [ ] <5 bugs majeurs (P1)
- [ ] NPS moyen >7/10
- [ ] 80%+ testers comprennent value Pro Tier

---

### 5.2 Performance Testing

**Load Testing** :
```bash
# Simuler 100 crÃ©ateurs utilisant SEO Tool simultanÃ©ment
k6 run load-test-seo-tool.js

# VÃ©rifier cron jobs sous charge
# Simuler 1000 users vectorisÃ©s en 1 nuit
```

**Benchmarks Acceptables** :
- SEO Tool : <3s response time (p95)
- Niche Finder page load : <2s
- Analytics dashboard : <1.5s
- Cron vectorisation : <30min pour 1000 users

---

### 5.3 Pricing Validation

**Test RÃ©gional** :
- [ ] VÃ©rifier gÃ©olocalisation correcte (EU vs Afrique)
- [ ] Tester checkout â‚¬30 (EU)
- [ ] Tester checkout â‚¬12 (Afrique)
- [ ] Webhook Stripe bien reÃ§u

**Free Trial** :
- [ ] Activer trial 14 jours
- [ ] Email J+7 : reminder
- [ ] Email J+13 : derniÃ¨re chance
- [ ] Conversion tracking

---

### 5.4 Launch Checklist

**Pre-Launch (J-7)** :
- [ ] Backup complet DB
- [ ] Monitoring setup (Sentry, Datadog, ou Ã©quivalent)
- [ ] Support email ready (support@akeli.app)
- [ ] Documentation crÃ©ateurs (PDF + vidÃ©os)
- [ ] Communication plan :
  - Email annonce crÃ©ateurs existants
  - Post rÃ©seaux sociaux
  - Landing page update

**Launch Day (J-0)** :
- [ ] Enable Pro Tier en production
- [ ] Publier annonce
- [ ] Monitor dashboards (errors, performance)
- [ ] Support rÃ©actif (rÃ©pondre <2h)

**Post-Launch (J+1 Ã  J+7)** :
- [ ] Daily standup : review metrics
- [ ] Fix bugs critiques immÃ©diatement
- [ ] Collecter feedback users
- [ ] ItÃ©rer rapidement (hotfixes)

---

### 5.5 Success Metrics (30 jours post-launch)

**Business** :
- [ ] 20+ crÃ©ateurs Pro subscribed
- [ ] â‚¬600+ MRR (20 crÃ©ateurs Ã— â‚¬30 avg)
- [ ] <5% churn rate

**Produit** :
- [ ] 100+ recherches SEO Tool/jour
- [ ] 500+ vues Niche Finder/semaine
- [ ] 50+ recettes crÃ©Ã©es via insights V1

**Technique** :
- [ ] 99.5%+ uptime
- [ ] <1% error rate
- [ ] 0 security incidents

---

## ðŸ“Š Post-Launch Roadmap (V1.1+)

### Quick Wins (Mois 2-3)

**UX Improvements** :
- [ ] SEO Tool : historique recherches crÃ©ateur
- [ ] Niche Finder : favoris/bookmarks
- [ ] Analytics : export CSV

**Community** :
- [ ] Forum crÃ©ateurs (intÃ©grÃ© plateforme)
- [ ] Success stories showcase
- [ ] Creator leaderboard

---

### Medium Term (Mois 4-6)

**API Publique** :
- [ ] Webhooks notifs (nouvelle consommation, milestone)
- [ ] Endpoints read-only (stats, recettes)
- [ ] Documentation OpenAPI

**Marketplace Programs** :
- [ ] CrÃ©ateurs vendent bundles (ex: "30 jours Keto")
- [ ] Commission Akeli 20%
- [ ] Payment split automatique

---

### Long Term (Mois 7-12)

**Expansion BeautÃ©** :
- [ ] Adapter schema DB (beauty programs)
- [ ] Niches beautÃ©/wellness
- [ ] Cross-sell food â†” beauty

**Geographic Expansion** :
- [ ] UK market
- [ ] Germany market
- [ ] US diaspora market

---

## ðŸ“ Notes Importantes

### FlexibilitÃ© Roadmap

Cette roadmap est **guideline, pas prison**. Ajustements basÃ©s sur :
- Feedback beta testers
- ComplexitÃ© technique dÃ©couverte
- OpportunitÃ©s business Ã©mergentes
- Contraintes temps/budget

### Priorisation Continue

Ã€ chaque phase, se demander :
- **Impact crÃ©ateurs** : Cette feature aide-t-elle vraiment ?
- **Effort technique** : ComplexitÃ© vs valeur ajoutÃ©e ?
- **Revenue impact** : Contribue au business model ?

### Documentation Vivante

Ce document Ã©voluera. Maintenir Ã  jour :
- DÃ©cisions techniques majeures
- Changements scope
- Learnings (ce qui a marchÃ©/ratÃ©)

---

**Fin de la documentation V1** ðŸŽ‰

**PrÃªt Ã  coder ?** Commence par Phase 0 (collecte donnÃ©es) dÃ¨s maintenant !
