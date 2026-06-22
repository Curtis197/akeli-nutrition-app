# AKELI — Documentation Master Index

> **Document de référence unique pour l'ensemble du projet Akeli.**  
> Toute nouvelle documentation doit être enregistrée ici avant d'être considérée comme active.

> ⚠️ **En cas de contradiction entre deux documents, `V1_ARCHITECTURE_DECISIONS.md` fait autorité.** Il log toutes les décisions d'architecture prises en cours de documentation et supersède les docs sources sur les points listés.

**Dernière mise à jour** : Juin 2026 — ajout fondation copywriting (AKELI_GENESE_PERSONA, AKELI_POSITIONNEMENT_MESSAGING)  
**Auteur** : Curtis — Fondateur Akeli  
**Statut projet** : V0 en production (App Store + Google Play) — V1 en cours de déploiement et préparation marketing  

---

## État du Projet

| Version | Périmètre | Statut |
|---------|-----------|--------|
| V0 — MVP | App Flutter (FlutterFlow) + Website créateur basique | ✅ En production |
| V1 — App | Réécriture native Flutter | 🚀 Déploiement & Tests Externes |
| V1 — Website | Réécriture Next.js — dashboard + création recettes | 🔲 À documenter |
| V2 | Features avancées créateurs + B2B intelligence | 🗓️ Sept 2026 |

---

## 1. Vision & Contexte

Documents fondateurs du projet. À relire en cas de doute stratégique.

| Document | Description | Statut |
|----------|-------------|--------|
| [`Vision_personnel`](01_vision_contexte/Vision_personnel) | Vision personnelle de Curtis — pourquoi Akeli existe, ambitions, principes | ✅ Actif |
| [`AKELI_CONCEPT_INDEX.md`](01_vision_contexte\AKELI_CONCEPT_INDEX.md) | Index des concepts — dictionnaire complet des termes et philosophies du projet | ✅ Actif |
| [`AKELI_GENESE_PERSONA.md`](01_vision_contexte\AKELI_GENESE_PERSONA.md) | Genèse du projet et persona fondatrice (« la fondatrice ») — vérité d'origine et de référence pour toute la copy | ✅ Actif — **Fondateur** |
| [`AKELI_SESSION_FONDATION_MARS2026.md`](01_vision_contexte\AKELI_SESSION_FONDATION_MARS2026.md) | Principes stratégiques fondamentaux — positionnement, permanence vs innovation | ✅ Actif |
| [`AKELI_SESSION_FONDATION_MARS2026.docx`](01_vision_contexte/AKELI_SESSION_FONDATION_MARS2026.docx) | Principes stratégiques fondamentaux (Format Word) | ✅ Actif |
| [`AKELI_ETRE_COLLECTIF_PRINCIPES.docx`](01_vision_contexte/AKELI_ETRE_COLLECTIF_PRINCIPES.docx) | Principes d'appartenance collective | ✅ Actif |
| [`AKELI_CUISINE_ADAPTATION.md`](01_vision_contexte\AKELI_CUISINE_ADAPTATION.md) | Philosophie de l'adaptation culinaire vs la trahison culturelle | ✅ Actif |
| [`AKELI_CUISINE_SYSTEME_VIVANT.md`](01_vision_contexte\AKELI_CUISINE_SYSTEME_VIVANT.md) | La cuisine comme système vivant et évolutif | ✅ Actif |
| [`AKELI_PHILOSOPHIE_REALIGNMENT.md`](01_vision_contexte\AKELI_PHILOSOPHIE_REALIGNMENT.md) | Document fondateur : Le réalignment vs le régime (désynchronisation, objectifs) | ✅ Actif |
| [`AKELI_REALITE_SOCIOLOGIQUE.md`](01_vision_contexte\AKELI_REALITE_SOCIOLOGIQUE.md) | Analyse de la réalité sociologique de la diaspora | ✅ Actif |
| [`AKELI_VISION_UNIVERSELLE.md`](01_vision_contexte\AKELI_VISION_UNIVERSELLE.md) | Vision universelle : combattre la modernité par la modernité | ✅ Actif |

---

## 2. Audit MVP — V0

Inventaire complet de ce qui a été construit et de ses limites. Sert de référence pour comprendre ce que V1 corrige.

| Document | Description | Statut |
|----------|-------------|--------|
| [`TECHNICAL_AUDIT.md`](02_audit_mvp_v0\TECHNICAL_AUDIT.md) | Dette technique : composants dupliqués, typos API, code de test en prod, anti-patterns app state | ✅ Actif |
| [`ARCHITECTURE_ANALYSIS.md`](02_audit_mvp_v0\ARCHITECTURE_ANALYSIS.md) | Double backend Firebase + Supabase, catalogue 25 edge functions, inventaire 81 tables | ✅ Actif |
| [`STITCH_DART_AUDIT.md`](02_audit_mvp_v0\STITCH_DART_AUDIT.md) | Correspondance Stitch ↔ Dart — mapping prototypes design vers implémentations Flutter, identification des gaps (Mai 2026) | ✅ Actif |
| [`UI_AUDIT.md`](02_audit_mvp_v0\UI_AUDIT.md) | Ledger de statut UI — tracker global pages/composants, analyse page-centrique alignée sur exports Stitch | ✅ Actif |
| [`PAGE_AUDIT_REPORT.md`](02_audit_mvp_v0\PAGE_AUDIT_REPORT.md) | Rapport audit 68 fichiers Flutter — 11 fichiers avec problèmes identifiés | ✅ Actif |
| [`PRE_PRODUCTION_AUDIT.md`](02_audit_mvp_v0\PRE_PRODUCTION_AUDIT.md) | Audit pré-production complet (Mai 2026) — statut prêt pour tests & déploiement production | ✅ Actif |
| [`PRE_PRODUCTION_CHECKLIST.md`](02_audit_mvp_v0\PRE_PRODUCTION_CHECKLIST.md) | Checklist pré-production — liste de vérification avant release | ✅ Actif |

---

## 3. V1 — Application Flutter

Réécriture complète en Flutter natif via Claude Code. Objectif : base solide, maintenable, scalable.

### 3a. Architecture & Principes

| Document | Description | Statut |
|----------|-------------|--------|
| [`V1_ARCHITECTURE_DECISIONS.md`](03_v1_app_flutter\architecture_principes\V1_ARCHITECTURE_DECISIONS.md) | **Journal des décisions d'architecture** — fait autorité en cas de contradiction. ADR-001 (pgvector vs Python runtime), ADR-002 (suppression Edge Functions query), ADR-003 (feed batch nightly), ADR-004 (onglets Recettes/Créateurs) | ✅ Actif — **Lire en premier** |
| [`V1_ARCHITECTURE_GLOBALE.md`](03_v1_app_flutter\architecture_principes\V1_ARCHITECTURE_GLOBALE.md) | Architecture système complète V1 — 4 couches (Flutter, Supabase, Python Railway, PostgreSQL), flux de données, services externes | ✅ Actif |
| [`SYSTEM_OVERVIEW_V1.md`](03_v1_app_flutter\architecture_principes\SYSTEM_OVERVIEW_V1.md) | Vue d'ensemble executive — différenciateurs, piliers stratégiques, scope V1 vs V2, métriques de succès | ✅ Actif |
| [`V1_CONTRAINTES_FLUTTERFLOW.md`](03_v1_app_flutter\architecture_principes\V1_CONTRAINTES_FLUTTERFLOW.md) | Pourquoi FlutterFlow est abandonné — limitations techniques documentées | ✅ Actif |
| [`V1_OBJECTIFS_IMPLEMENTATION.md`](03_v1_app_flutter\architecture_principes\V1_OBJECTIFS_IMPLEMENTATION.md) | Objectifs V1, métriques de succès, roadmap par feature | ✅ Actif |
| [`ARCHITECTURE_REDESIGN.md`](03_v1_app_flutter\architecture_principes\ARCHITECTURE_REDESIGN.md) | Architecture cible Flutter : state management par slices, structure dossiers, cleanup | ✅ Actif |
| [`FEATURE_SPEC.md`](03_v1_app_flutter\architecture_principes\FEATURE_SPEC.md) | Inventaire feature par feature — ce qu'on garde, coupe, complète ou redesigne | ✅ Actif |
| [`DESIGN_SYSTEM.md`](03_v1_app_flutter\architecture_principes\DESIGN_SYSTEM.md) | Tokens design, typographie, inventaire composants V1 | ✅ Actif |
| [`DESIGN_INVENTORY.md`](03_v1_app_flutter\architecture_principes\DESIGN_INVENTORY.md) | Inventaire migration design — toutes les pages et composants FlutterFlow vs Flutter natif | ✅ Actif |
| [`LOCAL_SETUP_GUIDE.md`](03_v1_app_flutter\architecture_principes\LOCAL_SETUP_GUIDE.md) | Guide setup développement local (Mai 2026) — prêt pour tests locaux | ✅ Actif |
| [`PROJECT_PLAN.md`](03_v1_app_flutter\architecture_principes\PROJECT_PLAN.md) | Master plan complet du projet — index exhaustif composants, tables, fonctions, pages et leurs relations | ✅ Actif |
| [`V1_FLUTTER_RECIPE_TRACKING_IMPLEMENTATION.md`](03_v1_app_flutter\architecture_principes\V1_FLUTTER_RECIPE_TRACKING_IMPLEMENTATION.md) | Implémentation tracking impressions et sessions recette dans Flutter V1 | ✅ Actif |

### 3b. Backend & Base de données

| Document | Description | Statut |
|----------|-------------|--------|
| [`V1_BACKEND_EDGE_FUNCTIONS.md`](03_v1_app_flutter\backend_database\V1_BACKEND_EDGE_FUNCTIONS.md) | Catalogue des 14 Edge Functions Supabase — logique backend uniquement (hors queries). Inclut 8 fonctions SQL PostgreSQL via `.rpc()`. 3 cron jobs, 1 webhook Stripe | ✅ Actif |
| [`V1_DATABASE_SCHEMA.md`](03_v1_app_flutter\backend_database\V1_DATABASE_SCHEMA.md) | Schéma complet PostgreSQL V1 — toutes les tables, RLS policies, indexes, triggers | ✅ Actif |
| [`CREATOR_ANALYTICS_DASHBOARD.md`](03_v1_app_flutter\backend_database\CREATOR_ANALYTICS_DASHBOARD.md) | Dashboard revenus créateurs — modèle économique, métriques, calcul revenue, portfolio analysis | ✅ Actif |
| [`V1_RECIPE_SCHEMA_ADDITIONS.md`](03_v1_app_flutter\backend_database\V1_RECIPE_SCHEMA_ADDITIONS.md) | Ajouts schéma recettes V1 (Mars 2026) — validé, prêt à appliquer en migration | ✅ Actif |

### 3c. Standards de Logging

| Document | Description | Statut |
|----------|-------------|--------|
| [`LOGGING_README.md`](03_v1_app_flutter\logging_standards\LOGGING_README.md) | Principe fondateur : "Log everything, guess nothing" — philosophie et structure du système de logging | ✅ Actif — **Lire avant tout développement Flutter** |
| [`LOGGING_INSTRUCTIONS.md`](03_v1_app_flutter\logging_standards\LOGGING_INSTRUCTIONS.md) | Instructions détaillées de logging — conventions, niveaux, patterns à appliquer | ✅ Actif |
| [`LOGGING_QUICK_REFERENCE.md`](03_v1_app_flutter\logging_standards\LOGGING_QUICK_REFERENCE.md) | Référence rapide logging — cheatsheet des patterns les plus courants | ✅ Actif |

### 3d. Pages — Spécifications (22 pages)

| Document | Pages couvertes | Statut |
|----------|-----------------|--------|
| [`INDEX.md`](03_v1_app_flutter\pages_specifications\INDEX.md) | Carte de navigation globale, règles communes à toutes les pages | ✅ Actif |
| [`CORE_PAGES.md`](03_v1_app_flutter\pages_specifications\CORE_PAGES.md) | Home, Meal Planner, Meal Detail, Diet Plan, Shopping List | ✅ Actif |
| [`RECIPE_PAGES.md`](03_v1_app_flutter\pages_specifications\RECIPE_PAGES.md) | Recipe Discovery, Recipe Detail | ✅ Actif |
| [`COMMUNITY_PAGES.md`](03_v1_app_flutter\pages_specifications\COMMUNITY_PAGES.md) | Community, Chat, Group, User Profile, Dashboard/Recap | ✅ Actif |
| [`AUTH_PAGES.md`](03_v1_app_flutter\pages_specifications\AUTH_PAGES.md) | Authentication, Inscription (Onboarding), Patient Intake, CGU | ✅ Actif |
| [`SETTINGS_PAGES.md`](03_v1_app_flutter\pages_specifications\SETTINGS_PAGES.md) | Profile Settings, Edit Info, Payment, Notifications, Support, Referral | ✅ Actif |
| [`MISSING_PAGES_COMPLETE.md`](03_v1_app_flutter\pages_specifications\MISSING_PAGES_COMPLETE.md) | 6 pages manquantes implémentées — couverture 100% du design system Digital Editorial | ✅ Actif |
| [`app_texts_for_translation.md`](03_v1_app_flutter\pages_specifications\app_texts_for_translation.md) | Textes de l'application à traduire — référence complète pour i18n | ✅ Actif |
| [`missed_texts_check.md`](03_v1_app_flutter\pages_specifications\missed_texts_check.md) | Vérification des textes manqués lors de la traduction | ✅ Actif |

### 3f. Système de Recommandation — Vectorisation & Intelligence

| Document | Description | Statut |
|----------|-------------|--------|
| [`PYTHON_RECOMMENDATION_ENGINE.md`](03_v1_app_flutter\recommendation_vectorization\PYTHON_RECOMMENDATION_ENGINE.md) | Python Service (Railway) — construction des vecteurs user et recipe uniquement. ⚠️ Les sections cosine similarity et runtime feed/meal_plan sont **obsolètes** — voir `V1_ARCHITECTURE_DECISIONS.md` ADR-001 | ✅ Actif — ⚠️ Lire avec ADR-001 |
| [`FEED_GENERATION.md`](03_v1_app_flutter\recommendation_vectorization\FEED_GENERATION.md) | Algorithme feed scrollable — 70% personnalisé / 20% exploration / 10% fresh, anti-winner-takes-all | ✅ Actif |
| [`OUTCOME_BASED_METRICS.md`](03_v1_app_flutter\recommendation_vectorization\OUTCOME_BASED_METRICS.md) | Métriques outcome — recipe performance, user behavior patterns, weekly momentum, impact vectorisation | ✅ Actif |
| [`RECIPE_ADJUSTMENT_ENGINE.md`](03_v1_app_flutter\recommendation_vectorization\RECIPE_ADJUSTMENT_ENGINE.md) | Ajustement macros recettes en temps réel — recettes paramétriques, logique mathématique, contraintes nutritionnelles | ✅ Actif |
| [`V1_VECTORIZATION_MEAL_PLANNER.md`](03_v1_app_flutter\recommendation_vectorization\V1_VECTORIZATION_MEAL_PLANNER.md) | Structure des 50 dimensions vectorielles (user + recipe) — référence pour la composition des vecteurs uniquement. ⚠️ Les timings (~50-100ms) sont obsolètes — pgvector HNSW = ~3ms. Voir ADR-001 | ✅ Actif — ⚠️ Structure uniquement |
| [`User_Vectorization_and_EGR_Matrix.md`](03_v1_app_flutter\recommendation_vectorization\User_Vectorization_and_EGR_Matrix.md) | Vision V2 — matrice EGR (Enjoyability, Goal, Retention), vectorisation 7 dimensions 1536D | 🗓️ V2 — Vision |
| [`PYTHON_ENGINE_UPDATE_20260314.md`](03_v1_app_flutter\recommendation_vectorization\PYTHON_ENGINE_UPDATE_20260314.md) | Mise à jour engine batch vectorisation Python (Mars 2026) — correctifs environnement, dépendances, couverture tests | ✅ Actif |
| [`algorithm_improvements.md`](03_v1_app_flutter\recommendation_vectorization\algorithm_improvements.md) | Roadmap améliorations algorithmes (Mai 2026) — backlog data science pour recommandation, analytics, meal planning | 🗓️ Backlog technique |
| [`meal_plan_generator_philosophy.md`](03_v1_app_flutter\recommendation_vectorization\meal_plan_generator_philosophy.md) | Philosophie & défis du générateur de meal plans (Mai 2026) — document vivant, décisions de design évolutives | ✅ Actif |
| [`vector_space_reference.md`](03_v1_app_flutter\recommendation_vectorization\vector_space_reference.md) | Référence espace vectoriel 50D partagé — dimensions identiques user_vector et recipe_vector, base de la similarité cosinus | ✅ Actif |

### 3g. Assistant IA In-App

| Document | Description | Statut |
|----------|-------------|--------|
| [`V1_AI_ASSISTANT_SPECS.md`](03_v1_app_flutter\ai_assistant\V1_AI_ASSISTANT_SPECS.md) | Spécifications fonctionnelles de l'assistant — intentions, réponses, UX | ✅ Actif |
| [`V1_AI_ASSISTANT_ARCHITECTURE.md`](03_v1_app_flutter\ai_assistant\V1_AI_ASSISTANT_ARCHITECTURE.md) | Architecture technique — fast path / smart path, 9 modules de données, rate limiting | ✅ Actif |
| [`V1_AI_ASSISTANT_ARCHITECTURE-1.md`](07_archive\V1_AI_ASSISTANT_ARCHITECTURE-1.md) | Doublon exact de `V1_AI_ASSISTANT_ARCHITECTURE.md` — fichiers identiques | 🗄️ Archivé — doublon |
| [`V1_AI_ASSISTANT_IMPLEMENTATION.md`](03_v1_app_flutter\ai_assistant\V1_AI_ASSISTANT_IMPLEMENTATION.md) | Plan d'implémentation — phases, edge functions, tests | ✅ Actif |
| [`Feature_Assistant_Akeli`](03_v1_app_flutter/ai_assistant/Feature_Assistant_Akeli) | Roadmap modulaire features assistant — AI Memory, modules activables indépendamment | ✅ Actif |

### 3h. Walkthroughs & Tests

Comptes-rendus de sessions de test, résultats de validation et walkthroughs fonctionnels du projet Flutter V1.

| Document | Description | Statut |
|----------|-------------|--------|
| [`walkthrough.md`](03_v1_app_flutter\walkthroughs_testing\walkthrough.md) | Walkthrough initial — remédiation des issues invisibles | ✅ Actif |
| [`onboarding_fixes_walkthrough.md`](03_v1_app_flutter\walkthroughs_testing\onboarding_fixes_walkthrough.md) | Walkthrough correctifs onboarding | ✅ Actif |
| [`profile_and_community_walkthrough.md`](03_v1_app_flutter\walkthroughs_testing\profile_and_community_walkthrough.md) | Walkthrough pages profil et communauté | ✅ Actif |
| [`meal_plan_walkthrough.md`](03_v1_app_flutter\walkthroughs_testing\meal_plan_walkthrough.md) | Walkthrough complet meal planning | ✅ Actif |
| [`meal_planning_workflow_test_results.md`](03_v1_app_flutter\walkthroughs_testing\meal_planning_workflow_test_results.md) | Résultats tests du workflow meal planning | ✅ Actif |
| [`backend_evaluation_walkthrough.md`](03_v1_app_flutter\walkthroughs_testing\backend_evaluation_walkthrough.md) | Walkthrough évaluation backend | ✅ Actif |
| [`saved_recipes_feature_walkthrough.md`](03_v1_app_flutter\walkthroughs_testing\saved_recipes_feature_walkthrough.md) | Walkthrough feature recettes sauvegardées | ✅ Actif |
| [`ui_improvements_walkthrough.md`](03_v1_app_flutter\walkthroughs_testing\ui_improvements_walkthrough.md) | Walkthrough améliorations UI | ✅ Actif |

---

## 4. V1 — Website Next.js

Réécriture propre en Next.js de la plateforme créateur existante.

**Périmètre V1 :** Dashboard créateur + Interface de création de recettes.  
Les features avancées (analytics, SEO Tool, Pro Tier) sont repoussées en V2.

| Document | Description | Statut |
|----------|-------------|--------|
| *(à créer)* | Architecture Next.js — structure, routing, auth | 🔲 À documenter |
| *(à créer)* | Dashboard créateur — spécifications pages | 🔲 À documenter |
| *(à créer)* | Interface création recettes — spécifications | 🔲 À documenter |

> **Note** : Chaque feature du website V1 fera l'objet d'une conversation dédiée puis d'un document indexé ici.

---

## 5. Business & Marché

Documents de référence stratégique. Consultés lors des décisions produit et expansion.

| Document | Description | Statut |
|----------|-------------|--------|
| [`AKELI_PERSONAS_UTILISATEURS.md`](05_business_marche\AKELI_PERSONAS_UTILISATEURS.md) | Personas détaillés — utilisateurs consommateurs et créateurs | ✅ Actif |
| [`AKELI_MODELE_CREATEUR.md`](05_business_marche\AKELI_MODELE_CREATEUR.md) | Modèle économique créateur — rémunération €1/90 consommations, Mode Fan, logique plateforme | ✅ Actif |
| [`AKELI_POSITIONNEMENT_MESSAGING.md`](05_business_marche\AKELI_POSITIONNEMENT_MESSAGING.md) | Bible copywriting — architecture à deux couches (nous décrire / acte d'achat), accroche « Mangez comme vous êtes », piliers de marque, règles de voix | ✅ Actif |
| [`AKELI_MARCHES_EXPANSION.md`](05_business_marche\AKELI_MARCHES_EXPANSION.md) | Marchés cibles — Europe francophone, anglophone (Nigeria, UK, US, SA) | ✅ Actif |
| [`AKELI_MODE_FAN.md`](05_business_marche\AKELI_MODE_FAN.md) | Mode Fan — allocation directe 1€/mois à un créateur, règle 90/10, blocage technique, historique | ✅ Actif |
| [`Improving_the_Akeli_recipe_platform`](05_business_marche/Improving_the_Akeli_recipe_platform) | Réflexions sur l'amélioration de la plateforme créateur web — contexte et vision | ✅ Actif (référence) |
| [`AKELI_AXES_CONTENU.md`](05_business_marche\akeli_communication\AKELI_AXES_CONTENU.md) | Axes stratégiques de contenu pour les créateurs | ✅ Actif |
| [`AKELI_COMMUNICATION_CREATEUR.md`](05_business_marche\akeli_communication\AKELI_COMMUNICATION_CREATEUR.md) | Communication créateur : proposition fondamentale, pitchs par profil | ✅ Actif |
| [`AKELI_NICHES.md`](05_business_marche\AKELI_NICHES.md) | Documentation et identification des niches de créateurs | ✅ Actif |
| [`AKELI_STRATEGIE_COMMUNAUTE.md`](05_business_marche\AKELI_STRATEGIE_COMMUNAUTE.md) | Stratégie d'engagement et de construction communautaire | ✅ Actif |
| [`AKELI_STRATEGIE_CREATEUR.md`](05_business_marche\AKELI_STRATEGIE_CREATEUR.md) | Stratégie de recrutement et de succès pour les créateurs | ✅ Actif |
| [`SESSION_SYNTHESIS.md`](05_business_marche\SESSION_SYNTHESIS.md) | Synthèse de session stratégique (Avril 2026) — décisions et orientations business | ✅ Actif |
| [`AKELI_COMM_REF08_ETRE_ALIGNE.docx`](05_business_marche/akeli_communication/AKELI_COMM_REF08_ETRE_ALIGNE.docx) | Stratégie communication — Être aligné | ✅ Actif |
| [`AKELI_COMM_REF09_PREUVE_PAR_LES_RESULTATS.docx`](05_business_marche/akeli_communication/AKELI_COMM_REF09_PREUVE_PAR_LES_RESULTATS.docx) | Stratégie communication — Preuve par les résultats | ✅ Actif |
| [`AKELI_COMM_REF10_STRATEGIE_PHASES.docx`](05_business_marche/akeli_communication/AKELI_COMM_REF10_STRATEGIE_PHASES.docx) | Stratégie communication — Stratégie des phases | ✅ Actif |
| [`AKELI_QUIZ_ALIGNEMENT.docx`](05_business_marche/akeli_communication/AKELI_QUIZ_ALIGNEMENT.docx) | Support communication — Quiz d'alignement créateur | ✅ Actif |
| [`AKELI_LIVE_PROTOCOLE.docx`](05_business_marche/akeli_communication/AKELI_LIVE_PROTOCOLE.docx) | Support communication — Protocole Live | ✅ Actif |
| [`AKELI_LIVE_PHASE1_PLAN_FR_EN.md`](05_business_marche\akeli_communication\AKELI_LIVE_PHASE1_PLAN_FR_EN.md) | Plan structuré Live Phase 1 — FR/EN | ✅ Actif |
| [`AKELI_LIVE_PHASE1_PLAN_V2_FR_EN.md`](05_business_marche\akeli_communication\AKELI_LIVE_PHASE1_PLAN_V2_FR_EN.md) | Plan structuré Live Phase 1 (V2) — Zoom Créateurs | ✅ Actif |
| [`AKELI_LIVE_PHASE1_SLIDES_EN.pptx`](05_business_marche/akeli_communication/AKELI_LIVE_PHASE1_SLIDES_EN.pptx) | Slides Live Phase 1 — Anglais | ✅ Actif |
| [`AKELI_LIVE_PHASE1_SLIDES_FR.pptx`](05_business_marche/akeli_communication/AKELI_LIVE_PHASE1_SLIDES_FR.pptx) | Slides Live Phase 1 — Français | ✅ Actif |
| [`AKELI_LIVE_PHASE1_SLIDES_V2_EN.pptx`](05_business_marche/akeli_communication/AKELI_LIVE_PHASE1_SLIDES_V2_EN.pptx) | Slides Live Phase 1 (V2) — Anglais | ✅ Actif |
| [`AKELI_LIVE_PHASE1_SLIDES_V2_FR.pptx`](05_business_marche/akeli_communication/AKELI_LIVE_PHASE1_SLIDES_V2_FR.pptx) | Slides Live Phase 1 (V2) — Français | ✅ Actif |

---

## 6. V2 — En Préparation (Sept 2026)

Features avancées pour créateurs et intelligence B2B. Travail préparatoire en cours — aucun code, concepts et documentation uniquement.

| Document | Description | Statut |
|----------|-------------|--------|
| [`01-vision-architecture.md`](06_v2_preparation\01-vision-architecture.md) | Vision plateforme Pro Tier créateur — Niche Finder, SEO Tool, Analytics avancés. **Périmètre V2 website uniquement** — ne pas utiliser comme référence V1 app | 🗓️ V2 — Documentation antérieure |
| [`02-specifications-fonctionnelles.md`](06_v2_preparation\02-specifications-fonctionnelles.md) | Specs fonctionnelles Pro Tier — Vectorisation recherches, SEO Tool, Niche Finder. **Périmètre V2 website uniquement** | 🗓️ V2 — Documentation antérieure |
| [`03-database-schema.md`](06_v2_preparation\03-database-schema.md) | Schéma base de données Pro Tier V2. **Remplacé par `V1_DATABASE_SCHEMA.md` pour la V1** — ne pas confondre | 🗓️ V2 — Documentation antérieure |
| [`04-roadmap-implementation.md`](06_v2_preparation\04-roadmap-implementation.md) | Roadmap plateforme Pro Tier V2. **Remplacée par `V1_OBJECTIFS_IMPLEMENTATION.md` pour la V1** | 🗓️ V2 — Documentation antérieure |
| [`README.md`](06_v2_preparation\README.md) | Introduction aux docs 01-04 plateforme Pro Tier. Périmètre V2 website | 🗓️ V2 — Documentation antérieure |
| [`AI_AGENT_ARCHITECTURE.md`](06_v2_preparation\AI_AGENT_ARCHITECTURE.md) | Agent IA action-first — nutrition coach qui agit (meal plan, ajustements, substitutions, shopping list, analytics insights) | 🗓️ V2 — En attente |

> **Principe** : Chaque sujet V2 est traité dans une conversation séparée, documenté, puis indexé ici sous la section V2.

---

## 7. Archivé

Documents obsolètes conservés pour mémoire. Ne pas utiliser comme référence.

| Document | Raison | Statut |
|----------|--------|--------|
| `AI_Assistant_n8n___Open_AI_conversation___` | Approche n8n abandonnée — remplacée par edge functions Supabase | 🗄️ Archivé |
| [`V1_AI_ASSISTANT_ARCHITECTURE-1.md`](07_archive\V1_AI_ASSISTANT_ARCHITECTURE-1.md) | Doublon exact de `V1_AI_ASSISTANT_ARCHITECTURE.md` (diff = 0) | 🗄️ Archivé — doublon |
| [`akeli_session_avril_2026/SESSION_SYNTHESIS.md`](07_archive\akeli_session_avril_2026\SESSION_SYNTHESIS.md) | Synthèse session Avril 2026 — concepts explorés puis orientés différemment | 🗄️ Archivé |
| [`akeli_session_avril_2026/FEED_GENERATION_V2.md`](07_archive\akeli_session_avril_2026\FEED_GENERATION_V2.md) | Feed generation V2 (session Avril 2026) | 🗄️ Archivé |
| [`akeli_session_avril_2026/V1_BATCH_COOKING_SPEC.md`](07_archive\akeli_session_avril_2026\V1_BATCH_COOKING_SPEC.md) | Spec batch cooking (session Avril 2026) | 🗄️ Archivé |
| [`akeli_session_avril_2026/V1_MODULAR_MEAL_BATCH_CONCILIATION.md`](07_archive\akeli_session_avril_2026\V1_MODULAR_MEAL_BATCH_CONCILIATION.md) | Conciliation modular meal batch (session Avril 2026) | 🗄️ Archivé |
| [`akeli_session_avril_2026/V1_RECOMMENDATION_MULTI_ENGINE.md`](07_archive\akeli_session_avril_2026\V1_RECOMMENDATION_MULTI_ENGINE.md) | Multi-engine recommendation (session Avril 2026) | 🗄️ Archivé |
| [`akeli_session_avril_2026/V1_USER_RECIPES_COMBINATIONS.md`](07_archive\akeli_session_avril_2026\V1_USER_RECIPES_COMBINATIONS.md) | Combinaisons user-recipes (session Avril 2026) | 🗄️ Archivé |
| `superpowers/specs/` (34 fichiers) | Specs de design pour chaque feature développée Mai–Juin 2026 via workflow Superpowers — de l'onboarding au mode Fan en passant par le meal generator | 🗄️ Archivé — référence historique |
| `superpowers/walkthroughs/` (3 fichiers) | Walkthroughs des features Mai 2026 (feed pagination, group invitation, notification fixes) | 🗄️ Archivé — référence historique |

---

## Conventions de Documentation

**Avant de créer un nouveau document :**
1. Identifier la section où il s'intègre (V1 App / V1 Website / Business / V2)
2. Créer le document avec un nom explicite en `SCREAMING_SNAKE_CASE.md`
3. L'ajouter immédiatement dans ce `MASTER_INDEX.md` avec son statut

**Statuts disponibles :**
- ✅ **Actif** — référence courante, utilisée pour le développement
- 🔲 **À documenter** — prévu, conversation future
- 🗓️ **V2 — En attente** — concept validé, implémentation sept 2026
- 🗄️ **Archivé** — obsolète, conservé pour mémoire

**Langues :**
- Documentation technique → Anglais
- Vision, business, réflexions → Français

---

*Ce document est la source de vérité du projet Akeli pour le statut et l'organisation.*  
*En cas de contradiction entre deux documents sur une décision d'architecture, `V1_ARCHITECTURE_DECISIONS.md` fait autorité.*  
*En cas de contradiction sur les specs, le document le plus récent (voir date en header) fait référence.*
