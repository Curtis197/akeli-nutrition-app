# Akeli — Algorithm Improvement Roadmap

**Last updated:** 2026-05-26  
**Purpose:** Living reference for data science techniques applicable to Akeli's recommendation, analytics, and meal planning systems. Not a sprint plan — a research backlog to draw from as the product matures.

---

## Current Baseline

The recommendation pipeline as of V1:

```
Stage 1 — Property match
  cosine_similarity(user_vector[50D], recipe_vector[50D])
  → candidate pool

Stage 2 — Recipe-centric demographic signal
  dot(effectiveness_vector[200D], user_demographic_vector[200D]) / 5
  dot(retention_vector[200D],     user_demographic_vector[200D]) / 5

Stage 3 — User-centric pool signal
  cosine_similarity(recipe_vector[50D], ideal_recipe_vector[50D])
  ideal_recipe_vector = weighted centroid of what worked for top-50 similar users

final_score = base_cosine
            + 0.10 × demographic_effectiveness
            + 0.05 × demographic_retention
            + 0.15 × pool_bonus
```

Trust formula (applied at write time to demographic scores):
```
trust(n, t) = (1 − exp(−n/5)) × exp(−0.02 × weeks_since_last_observation)
```

Everything below improves, extends, or replaces parts of this pipeline.

---

## 1. Beta Distribution — Retention Confidence

**Domain:** Statistics  
**Replaces:** Point estimate retention score + `sample_trust` approximation  
**Effort:** Low — linear algebra adjacent

### Problem

A recipe with 3 reuses out of 3 attempts and one with 30/30 both score `retention = 1.0` today. They are not the same. The first could easily be noise; the second is signal.

### Approach

Model retention as a Bernoulli process. The Beta distribution `Beta(α, β)` is the conjugate prior:

```
α = reuse_count + 1        (successes + prior)
β = non_reuse_count + 1    (failures + prior)

expected_retention = α / (α + β)
lower_bound_95     = Beta.ppf(0.05, α, β)   ← conservative estimate
```

Use `lower_bound_95` as the stored retention score instead of the raw proportion. This automatically dampens scores with few observations without needing a separate trust multiplier.

```
3/3  → lower_bound_95 = 0.44   (not 1.0)
30/30 → lower_bound_95 = 0.90  (justified confidence)
```

### Application

- Replace `retention_raw` in `recipe_demography_score` with Beta lower bound
- Creator dashboard shows confidence interval, not just a point
- Cold start: new recipe inherits Beta params from similar recipes (prior seeding)

---

## 2. Bayesian Updating — Better Cold Start Prior

**Domain:** Bayesian inference  
**Replaces:** `cold_start_trust = 0.4` flat multiplier  
**Effort:** Medium — requires understanding prior/posterior

### Problem

The current cold start inference weights inferred scores at 40% of observed scores regardless of how good the inference is. A recipe with 10 highly similar neighbours should have a stronger prior than one with 1 distant neighbour.

### Approach

Treat the similar-recipe inference as a Bayesian prior. Each real observation updates it:

```
prior_mean     = weighted_avg(similar_recipe_scores)   # from cosine-weighted neighbours
prior_strength = sum(similarities) × avg(neighbour_sample_sizes)

posterior_mean = (prior_strength × prior_mean + n × observed_mean)
                 / (prior_strength + n)
```

As `n` (real observations) grows, the posterior converges to `observed_mean`. At `n=0` it equals the prior. The convergence speed is controlled by `prior_strength` — strong priors (many close neighbours) resist updates longer.

### Application

- `compute_recipe_effectiveness()` uses posterior mean instead of raw average
- Cold start quality varies by recipe — a new Thiéboudienne variant has many close neighbours; a novel fusion recipe has few
- No hard-coded 0.4 multiplier needed

---

## 3. Clustering — Natural User Segments

**Domain:** Unsupervised learning  
**Complements:** Axis bucket system  
**Effort:** Low (K-means is geometrically intuitive given linear algebra background)

### Problem

The 5 demographic axes are defined top-down. Real user behaviour may cluster differently — an unexpected segment like "diaspora women 25–35 in maintenance" that crosses axes but behaves distinctly.

### Approach

Run K-means on `user_vector[50D]` periodically:

```python
from sklearn.cluster import KMeans

vectors = fetch_all_user_vectors()          # N × 50 matrix
kmeans  = KMeans(n_clusters=K, random_state=42)
labels  = kmeans.fit_predict(vectors)
centroids = kmeans.cluster_centers_         # K × 50 matrix
```

Start with K=20. Evaluate using **silhouette score** (measures how well-separated clusters are — ranges [-1, 1], higher is better).

### Applications

- **Validate axis buckets**: do natural clusters align with the demographic axes? If not, axes need revision.
- **Seed ideal_recipe_vector**: use cluster centroid instead of individual user pool — more stable, less noise.
- **Cluster-level analytics**: which clusters are underserved by the current recipe catalogue?
- **Churn prediction**: users drifting away from their cluster centroid may be losing engagement.

---

## 4. Matrix Factorization — Latent Recommendation Layer

**Domain:** Dimensionality reduction / collaborative filtering  
**Complements:** Explicit 50D vectors  
**Effort:** Medium — SVD is linear algebra, but tuning requires practice

### Problem

The explicit 50D vector space encodes what *you think* matters. Latent factors encode what the *data shows* matters — often capturing things not modelled explicitly (seasonal patterns, cultural pairings, texture preferences).

### Approach

Build a user × recipe consumption matrix `M` where `M[u][r] = consumption_pct × goal_aligned_diff`. Apply Singular Value Decomposition:

```python
U, Σ, Vt = svd(M, full_matrices=False)
# U:  N_users  × K  (user latent factors)
# Vt: K × N_recipes  (recipe latent factors)
# K: number of latent dimensions (try 20–50)

predicted_score[u][r] = U[u] · Σ · Vt[:, r]
```

Alternatively use Non-negative Matrix Factorization (NMF) for more interpretable factors (all values ≥ 0).

### Applications

- Latent `pool_bonus` alternative: `U[u] · Vt[:, r]` as a recommendation signal
- Discover latent recipe "archetypes" from `Vt` rows
- Identify latent user "taste profiles" from `U` rows
- Cold start: new recipe's latent vector approximated from its 50D property vector via a learned projection matrix

### Note

Requires a reasonably dense consumption matrix — practical after ~500 active users with completed meal plans.

---

## 5. Markov Chains — Meal Plan Sequencing

**Domain:** Stochastic processes  
**New capability:** Recipe sequence optimisation  
**Effort:** Low — transition matrix is just a normalised matrix

### Problem

The current system scores recipes independently. A good meal plan is also a good *sequence* — nutritional variety, ingredient reuse (batch cooking efficiency), rhythm (heavy meals followed by lighter ones).

### Approach

Build a transition probability matrix `T` where `T[i][j]` = probability that recipe type `j` follows recipe type `i` in successful meal plans (high goal_aligned_diff):

```python
# recipe types = cuisine × calorie_tier × protein_tier (simplified)
T = count_transitions(successful_meal_plans)
T = T / T.sum(axis=1, keepdims=True)   # row-normalise

# at meal plan generation time:
next_recipe_scores *= T[last_recipe_type]   # boost recipes that naturally follow
```

### Applications

- Meal plan auto-generation: Markov chain walk through recipe space
- Batch cooking suggestion: transition to recipes sharing ingredients with yesterday's
- Detect unnatural sequences the user might abandon

---

## 6. Information Theory — Diet Diversity Scoring

**Domain:** Information theory  
**New capability:** Churn prevention signal  
**Effort:** Low — entropy is one formula

### Problem

A user eating the same 3 recipes every week scores well on effectiveness but is a churn risk (boredom) and may develop nutritional gaps. The recommendation system has no diversity pressure.

### Approach

Shannon entropy of a user's recent consumption distribution:

```python
def diet_entropy(recipe_consumptions_last_30d):
    counts = Counter(recipe_consumptions_last_30d)
    total  = sum(counts.values())
    probs  = [c / total for c in counts.values()]
    return -sum(p * log2(p) for p in probs if p > 0)

# max entropy for N distinct recipes = log2(N)
# normalised: entropy / log2(N)  → [0, 1]
```

**Diversity bonus in the RPC:**

```sql
diversity_bonus := CASE
  WHEN recipe already consumed 3+ times in last 30 days THEN -0.10
  WHEN recipe never tried by this user                  THEN +0.05
  ELSE 0
END;
```

### Applications

- Add diversity penalty/bonus to `final_score`
- Alert users whose entropy drops below threshold (engagement risk)
- Creator analytics: which recipes cause low-entropy traps (users eat only this)?

---

## 7. Time Series — Weight Trend Modelling

**Domain:** Time series analysis  
**New capability:** Goal progress prediction  
**Effort:** Medium — requires understanding smoothing and trend decomposition

### Problem

`goal_aligned_diff` currently uses a simple start/end weight difference. A user who lost 2kg then regained 1kg looks different from one with steady -1kg/week, even if the net is the same.

### Approach

Fit a linear trend to the user's weight log within a meal plan period:

```python
from numpy.polynomial import polynomial as P

weeks  = [(date - plan_start).days / 7 for date in weight_log.dates]
weights = weight_log.values
slope, intercept = P.polyfit(weeks, weights, deg=1)
# slope = kg/week trend (negative = losing weight)
```

Use `slope` instead of `(weight_end - weight_start) / plan_weeks`. More robust to noise — a single anomalous weigh-in doesn't distort the signal.

**Exponential smoothing** for user weight display:

```python
smoothed[t] = α × raw[t] + (1 − α) × smoothed[t-1]   # α = 0.3
```

### Applications

- More accurate `goal_aligned_diff` for effectiveness computation
- User-facing weight trend graph (smoothed line vs raw dots)
- Predict when user will reach goal based on current trend → personalised encouragement

---

## 8. Reinforcement Learning Concepts — Long-Term Optimisation

**Domain:** RL / sequential decision making  
**Future capability:** Feed that optimises for lifetime value, not just next click  
**Effort:** High — conceptual leap from supervised/unsupervised

### Problem

All signals so far are retrospective — they score how well past recipes performed. Reinforcement learning frames the recommendation as a sequential decision problem: each recommendation is an *action*, user goal progress is the *reward*, and the system learns a *policy* that maximises long-term reward (sustained goal achievement + retention), not just immediate consumption.

### Approach (conceptual, not V1)

- **State:** user_vector at time t
- **Action:** which recipe to recommend
- **Reward:** `goal_aligned_diff` after the meal plan completes
- **Policy:** learned mapping from state → action that maximises cumulative reward

Contextual bandits (a simpler RL variant) are the practical entry point — treat each recommendation slot as a bandit arm, balance exploration (try new recipes) vs exploitation (recommend proven ones).

### Application

- Exploration bonus: recipes with low sample count get a small boost to accelerate data collection
- This is the formal version of the anti-popularity-bias mechanism already in the design
- Practical implementation: Upper Confidence Bound (UCB) score as an additional signal

---

## Priority Summary

| Technique | Impact | Effort | Depends on | When to tackle |
|---|---|---|---|---|
| Beta distribution (retention) | High | Low | Recipe demography batch live | First improvement post-launch |
| Bayesian cold start prior | High | Medium | Beta distribution | Second iteration |
| Diet entropy / diversity | Medium | Low | Any user consumption data | Post-launch, if churn observed |
| Clustering (K-means) | Medium | Low | 200+ active users | First quarterly analysis |
| Linear trend for weight | Medium | Low | Weight log data | Same sprint as demography batch |
| Matrix factorization | High | Medium | 500+ users, dense matrix | V2 |
| Markov meal sequencing | Medium | Low | Meal plan completion data | Meal planner V2 |
| Contextual bandits / RL | High (long-term) | High | Mature user base | V3+ |
