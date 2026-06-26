# Akeli — Synthèse de session
**Date** : Avril 2026  
**Auteur** : Curtis — Fondateur Akeli

---

## 1. Ce qui a été accompli

### 1.1 Infrastructure — Sync Créateur V1 → V0

**Edge Function déployée : `sync-creator-to-v0`**  
Synchronise un créateur de la DB V1 vers la DB V0 lors de son inscription via
le website. Prend un `creator_id` V1, résout le `supabase_auth_id` V0 via email
lookup paginé, et upserte dans V0 avec `v1_creator_id` comme clé d'idempotence.

**Trigger PostgreSQL : `trg_sync_creator_to_v0`**  
Déployé sur la table `creator` V1 — `AFTER INSERT OR UPDATE`. Appelle l'edge
function via `pg_net` de façon asynchrone. Même pattern que `trigger_sync_recipe_to_v0`
déjà en production. Header Authorization aligné sur l'anon key existant.

**État des créateurs :**
- 2 créateurs en V1 (Akeli Kitchen + Curtis — Fondateur Akeli)
- 2 créateurs en V0 avec `v1_creator_id` correctement renseigné
- `supabase_auth_id` null en V0 pour les deux — attendu pour les comptes seed
- Tout nouveau créateur inscrit via le website sera désormais synchronisé automatiquement

---

### 1.2 Documentation — Nouvelles features V1

Trois features conceptualisées, discutées et documentées. Toutes V1.

#### Feature 1 — Batch Cooking
*(Document initial : `V1_BATCH_COOKING_SPEC.md` — remplacé par le Doc Conciliation)*

Un utilisateur peut cuisiner en grande quantité et distribuer les portions sur
plusieurs repas de la semaine. Exclusivité Akeli — reflète la réalité de la
cuisine africaine.

#### Feature 2 — Modular Meal
Un repas est composé de N recettes avec des rôles distincts (`base`, `starch`, `side`).
La consommation est fractionnée : chaque composant génère `1/N` unité de revenu.
Le créateur de la sauce et le créateur du féculent sont rémunérés séparément.

#### Feature 3 — Recettes privées & Combinaisons
Un utilisateur peut créer ses propres recettes (même schéma que créateur) et ses
propres combinaisons sauce + féculent. Trois sources de combinaisons : créateur,
cross-créateur (pré-validé Akeli), utilisateur.

#### Feature 4 — Multi-engine Recommendation (pgvector)
Trois moteurs RPC PostgreSQL selon les préférences utilisateur :
- `recommend_recipes()` — toujours actif
- `recommend_combinations()` — si `modular_meal_enabled`
- `optimize_batch()` — si `batch_cooking_enabled`

Python Railway uniquement pour le calcul nightly des vecteurs.

#### Feature 5 — Feed Generation (pgvector)
Feed 70/20/10 entièrement en RPC pgvector. Python sorti du chemin critique.
Trois fonctions : `generate_feed_personalized`, `generate_feed_exploration`,
`generate_feed_fresh`, assemblées dans l'Edge Function `get-feed`.

---

## 2. Documents produits

| Document | Statut | Remplace |
|----------|--------|---------|
| `V1_BATCH_COOKING_SPEC.md` | ⚠️ Remplacé | — |
| `V1_MODULAR_MEAL_BATCH_CONCILIATION.md` | ✅ Actif | `V1_BATCH_COOKING_SPEC.md` |
| `V1_USER_RECIPES_COMBINATIONS.md` | ✅ Actif | — |
| `V1_RECOMMENDATION_MULTI_ENGINE.md` | ✅ Actif (v2.0) | — |
| `FEED_GENERATION_V2.md` | ✅ Actif | `FEED_GENERATION.md` v1.0 |

---

## 3. Décisions architecturales clés

| Décision | Choix retenu | Raison |
|----------|-------------|--------|
| Batch cooking lié à | `meal_plan_entry_component` | La sauce est en batch, le féculent non — indépendants |
| Consommation | `numeric` (fraction) | 1/N par composant — revenu fractionné par créateur |
| `batch_friendly` | Calculé (`servings > 1`) | Pas de champ redondant, contrôle via les portions |
| Recommandation | RPC pgvector (~3ms) | Pas de Railway sur le chemin critique |
| Feed generation | RPC pgvector (~3ms) | Même principe — Python uniquement pour les vecteurs |
| Moteurs | 3 jobs pgvector + 1 job Python nightly | Simple, cohérent, tout dans Supabase |
| Combinaisons cross-créateur | Pré-calculées par Akeli | Dimension culturelle — pas algorithmic |

---

## 4. Schéma relationnel final — nouvelles tables

```
meal_plan
    └── meal_plan_entry (N)
            └── meal_plan_entry_component (N)
                    ├── recipe_id → recipe
                    ├── role : base | starch | side
                    ├── consumption_weight : 1/N (trigger auto)
                    └── cooking_session_id → cooking_session (optionnel)

cooking_session
    ├── meal_plan_id → meal_plan
    ├── recipe_id → recipe
    ├── total_portions
    └── portions_used (trigger auto)

recipe_combination
    ├── base_recipe_id → recipe
    ├── paired_recipe_id → recipe
    ├── paired_role : starch | side
    ├── source : creator | cross_creator | user
    └── owner_user_id → user_profile (si source = user)

combination_vector
    └── combination_id → recipe_combination
        vector(50) HNSW

user_feed
    ├── user_id, recipe_id, position
    └── segment : personalized | exploration | fresh

meal_consumption (modifié)
    ├── consumption_value : numeric (était boolean)
    └── component_id → meal_plan_entry_component
```

---

## 5. Champs ajoutés sur tables existantes

| Table | Champ | Type | Défaut |
|-------|-------|------|--------|
| `user_profile` | `batch_cooking_enabled` | boolean | false |
| `user_profile` | `modular_meal_enabled` | boolean | false |
| `recipe` | `compatible_starches` | uuid[] | {} |
| `recipe` | `is_private` | boolean | false |
| `recipe` | `owner_user_id` | uuid | null |
| `meal_plan_entry` | ~~`recipe_id`~~ supprimé | — | — |
| `meal_plan_entry` | `cooking_session_id` supprimé | — | — |
| `meal_consumption` | `consumption_value` | numeric(4,3) | 1.0 |
| `meal_consumption` | `component_id` | uuid | null |

---

## 6. À faire — MASTER_INDEX.md

Ajouter et annoter les documents suivants :

```
V1_MODULAR_MEAL_BATCH_CONCILIATION.md  — Meal Planning / Features V1
V1_USER_RECIPES_COMBINATIONS.md        — Meal Planning / Features V1
V1_RECOMMENDATION_MULTI_ENGINE.md      — Recommendation Engine / V1
FEED_GENERATION_V2.md                  — Feed / V1
```

Marquer comme remplacés :
```
V1_BATCH_COOKING_SPEC.md    → remplacé par V1_MODULAR_MEAL_BATCH_CONCILIATION.md
FEED_GENERATION.md          → remplacé par FEED_GENERATION_V2.md
```

---

*Synthèse générée : Avril 2026*
