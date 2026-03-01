# 📚 Akeli — Documentation

> Point d'entrée de la documentation projet.  
> **Pour naviguer dans les docs, commencer par [`MASTER_INDEX.md`](MASTER_INDEX.md).**

**Dernière mise à jour** : Mars 2026  
**Auteur** : Curtis — Fondateur Akeli

---

## 🎯 Le Projet

**Akeli** est la première plateforme de nutrition et meal planning conçue pour la diaspora africaine en Europe. Elle connecte des créateurs de recettes africaines à des utilisateurs cherchant à manger selon leur culture tout en atteignant leurs objectifs nutritionnels.

> *"Nutrition optimization requires not changing who you are."*

---

## 📍 Où en sommes-nous

| Version | Périmètre | Statut |
|---------|-----------|--------|
| **V0 — MVP** | App Flutter (FlutterFlow) + Website créateur basique | ✅ En production — App Store & Google Play |
| **V1 — App** | Réécriture native Flutter via Claude Code | 📝 Documentation en cours |
| **V1 — Website** | Réécriture Next.js — dashboard créateur | 🔲 À documenter |
| **V2** | Features avancées créateurs + B2B intelligence | 🗓️ Sept 2026 |

---

## 🗂️ Naviguer dans la documentation

**→ [`MASTER_INDEX.md`](MASTER_INDEX.md)** — index complet, tous les documents classés par domaine et statut.

**→ [`V1_ARCHITECTURE_DECISIONS.md`](V1_ARCHITECTURE_DECISIONS.md)** — décisions d'architecture (ADR). **Lire en premier en cas de contradiction entre deux docs.**

### Accès rapide par domaine

| Besoin | Document |
|--------|----------|
| Vue d'ensemble du système | [`V1_ARCHITECTURE_GLOBALE.md`](V1_ARCHITECTURE_GLOBALE.md) |
| Backend — Edge Functions & SQL | [`V1_BACKEND_EDGE_FUNCTIONS.md`](V1_BACKEND_EDGE_FUNCTIONS.md) |
| Schéma base de données | [`V1_DATABASE_SCHEMA.md`](V1_DATABASE_SCHEMA.md) |
| Pages UI — navigation globale | [`INDEX.md`](INDEX.md) |
| Mode Fan — logique métier | [`AKELI_MODE_FAN.md`](AKELI_MODE_FAN.md) |
| Modèle économique créateur | [`AKELI_MODELE_CREATEUR.md`](AKELI_MODELE_CREATEUR.md) |
| Assistant IA | [`V1_AI_ASSISTANT_ARCHITECTURE.md`](V1_AI_ASSISTANT_ARCHITECTURE.md) |

---

## 🏗️ Stack technique V1

| Couche | Technologie |
|--------|-------------|
| App mobile | Flutter natif (iOS + Android) |
| Website créateur | Next.js |
| Backend | Supabase (Auth, PostgreSQL, Edge Functions, Storage, Realtime) |
| Vectorisation runtime | pgvector + index HNSW (~3ms pour 2500+ recettes) |
| Construction vecteurs | Python Service sur Railway (batch nightly uniquement) |
| Paiements | Stripe |
| Push notifications | Firebase Cloud Messaging |
| IA assistant | OpenAI GPT-4o-mini |
| Traduction langues africaines | Gemini |

---

## 💡 Conventions documentation

- **Langue** : technique → anglais / vision & business → français
- **Nommage fichiers** : `SCREAMING_SNAKE_CASE.md`
- **Tout nouveau document** doit être indexé dans `MASTER_INDEX.md` avant d'être considéré actif
- **Statuts** : ✅ Actif · 🔲 À documenter · 🗓️ V2 · 🗄️ Archivé

---

*Curtis — Fondateur Akeli*