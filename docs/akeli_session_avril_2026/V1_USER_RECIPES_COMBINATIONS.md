# Akeli V1 — Recettes Privées & Combinaisons

> Recettes privées utilisateur, combinaisons créateur, cross-créateur et utilisateur.
> Complète le modèle modulaire en donnant à l'utilisateur la liberté de composer
> ses propres repas au-delà des suggestions créateurs.

**Statut** : Prêt pour implémentation V1  
**Date** : Avril 2026  
**Auteur** : Curtis — Fondateur Akeli  
**Dépendances** : `V1_MODULAR_MEAL_BATCH_CONCILIATION.md`

---

## 1. Concepts

### 1.1 Recettes privées utilisateur

Un utilisateur peut créer ses propres recettes — non publiées, non visibles par les
autres utilisateurs. Elles sont disponibles dans son meal planner exactement comme une
recette créateur.

**Règles :**
- Même schéma qu'une recette créateur (ingrédients, étapes, macros, image)
- Jamais publiées dans le catalogue public
- Pas de `meal_consumption` générant du revenu créateur (la recette n'a pas de créateur)
- Peuvent être utilisées dans des combinaisons privées

### 1.2 Combinaisons

Une combinaison est une association validée entre une recette `base` et une ou plusieurs
recettes `starch` / `side`. Elle sert de suggestion dans le meal planner modulaire.

**Trois sources de combinaisons :**

| Source | Créateur | Visibilité | Validé par |
|--------|---------|-----------|-----------|
| Créateur | Déclare ses féculents compatibles | Publique | Le créateur |
| Cross-créateur | Sauce créateur A + féculent créateur B | Publique | Akeli (pré-calculé) |
| Utilisateur | Ses propres associations | Privée | L'utilisateur |

---

## 2. Base de données

### 2.1 Recettes privées — modification de `recipe`

```sql
ALTER TABLE recipe
ADD COLUMN is_private     boolean DEFAULT false,
ADD COLUMN owner_user_id  uuid REFERENCES user_profile(id) ON DELETE CASCADE;

-- Index pour récupérer les recettes privées d'un utilisateur
CREATE INDEX idx_recipe_private_owner ON recipe(owner_user_id)
WHERE is_private = true;
```

**RLS :**

```sql
-- Les recettes privées ne sont visibles que par leur propriétaire
DROP POLICY IF EXISTS "public reads published" ON recipe;

CREATE POLICY "public reads published" ON recipe
FOR SELECT USING (
  is_published = true AND is_private = false
);

CREATE POLICY "owner reads private" ON recipe
FOR SELECT USING (
  is_private = true AND owner_user_id = auth.uid()
);

CREATE POLICY "owner writes private" ON recipe
FOR ALL USING (
  is_private = true AND owner_user_id = auth.uid()
);
```

### 2.2 Nouvelle table : `recipe_combination`

Association validée entre une recette base et une recette starch/side.

```sql
CREATE TABLE recipe_combination (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  base_recipe_id  uuid REFERENCES recipe(id) ON DELETE CASCADE,
  paired_recipe_id uuid REFERENCES recipe(id) ON DELETE CASCADE,
  paired_role     text NOT NULL CHECK (paired_role IN ('starch', 'side')),
  source          text NOT NULL CHECK (source IN ('creator', 'cross_creator', 'user')),
  owner_user_id   uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  -- Null pour source = creator ou cross_creator
  -- Renseigné pour source = user
  is_validated    boolean DEFAULT false,
  -- true = validé par Akeli pour cross_creator
  -- true automatiquement pour creator et user
  sort_order      int DEFAULT 0,
  created_at      timestamptz DEFAULT now(),

  UNIQUE (base_recipe_id, paired_recipe_id, source, owner_user_id)
);

CREATE INDEX idx_rc_base       ON recipe_combination(base_recipe_id);
CREATE INDEX idx_rc_paired     ON recipe_combination(paired_recipe_id);
CREATE INDEX idx_rc_owner      ON recipe_combination(owner_user_id);
CREATE INDEX idx_rc_source     ON recipe_combination(source);

ALTER TABLE recipe_combination ENABLE ROW LEVEL SECURITY;

-- Combinaisons publiques (creator + cross_creator validées)
CREATE POLICY "public reads validated" ON recipe_combination
FOR SELECT USING (
  source IN ('creator', 'cross_creator') AND is_validated = true
);

-- Combinaisons privées utilisateur
CREATE POLICY "owner reads user combinations" ON recipe_combination
FOR SELECT USING (
  source = 'user' AND owner_user_id = auth.uid()
);

CREATE POLICY "owner writes user combinations" ON recipe_combination
FOR ALL USING (
  source = 'user' AND owner_user_id = auth.uid()
);
```

---

## 3. Logique des combinaisons

### 3.1 Combinaisons créateur

Le créateur déclare ses féculents compatibles sur la fiche recette via le champ
`compatible_starches uuid[]` (défini dans `V1_MODULAR_MEAL_BATCH_CONCILIATION.md`).

À la publication, un trigger crée automatiquement les entrées dans `recipe_combination`
avec `source = 'creator'` et `is_validated = true`.

```sql
CREATE OR REPLACE FUNCTION sync_creator_combinations()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  _starch_id uuid;
BEGIN
  -- Supprimer les anciennes combinaisons créateur pour cette recette
  DELETE FROM recipe_combination
  WHERE base_recipe_id = NEW.id AND source = 'creator';

  -- Créer les nouvelles combinaisons
  IF NEW.compatible_starches IS NOT NULL THEN
    FOREACH _starch_id IN ARRAY NEW.compatible_starches LOOP
      INSERT INTO recipe_combination (
        base_recipe_id, paired_recipe_id, paired_role,
        source, is_validated
      ) VALUES (
        NEW.id, _starch_id, 'starch', 'creator', true
      )
      ON CONFLICT (base_recipe_id, paired_recipe_id, source, owner_user_id)
      DO NOTHING;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_creator_combinations
AFTER INSERT OR UPDATE OF compatible_starches ON recipe
FOR EACH ROW
WHEN (NEW.is_published = true AND NEW.is_private = false)
EXECUTE FUNCTION sync_creator_combinations();
```

### 3.2 Combinaisons cross-créateur

Calculées en amont par Akeli — pas en temps réel. Critères :
- Même `region` ou `heritage_region`
- Tags communs (ex: "cuisine ivoirienne", "cuisine camerounaise")
- Validation manuelle Akeli (`is_validated = true`)

Insérées directement en DB via script d'administration ou job Python nightly.

### 3.3 Combinaisons utilisateur

L'utilisateur crée ses propres associations depuis :
- La page de détail d'une recette ("Associer un féculent")
- La page de création d'un repas modulaire dans le meal planner

```sql
-- Exemple d'insertion d'une combinaison utilisateur
INSERT INTO recipe_combination (
  base_recipe_id, paired_recipe_id, paired_role,
  source, owner_user_id, is_validated
) VALUES (
  '<sauce_id>', '<starch_id>', 'starch',
  'user', auth.uid(), true
);
```

---

## 4. Recettes privées — UI Flutter

### 4.1 Accès

- Onglet "Mes recettes" dans le profil utilisateur
- Bouton "+ Nouvelle recette" → formulaire identique à la création créateur
- Visible uniquement dans son meal planner (jamais dans le catalogue)

### 4.2 Formulaire de création

Même formulaire que la recette créateur :
- Titre, description, région
- Ingrédients + quantités
- Étapes
- Macros (saisie manuelle ou calcul automatique)
- Image (optionnelle)
- Féculents compatibles (pour combinaisons modulaires)

### 4.3 Dans le Meal Planner

Les recettes privées apparaissent dans le sélecteur de recettes avec un badge 🔒
pour les distinguer des recettes créateur.

---

## 5. Combinaisons — UI Flutter

### 5.1 Suggestion dans le Meal Planner

Quand `modular_meal_enabled = true` et qu'une recette `base` est ajoutée à un créneau,
le meal planner propose automatiquement des féculents compatibles :

**Ordre de priorité des suggestions :**
1. Combinaisons utilisateur (ses préférences passées)
2. Combinaisons créateur (validées par le créateur de la sauce)
3. Combinaisons cross-créateur (validées par Akeli)

### 5.2 Création manuelle d'une combinaison

Depuis la fiche d'une recette `base` :
```
[Recette : Ndolé]
├── Féculents suggérés par le créateur : Foutou, Placali
├── Aussi compatible avec : Riz, Attiéké (cross-créateur)
└── + Ajouter ma propre association
```

---

## 6. Impact sur le revenue model

| Cas | Revenue |
|-----|---------|
| Recette créateur (seule) | consumption_value = 1.0 → revenu plein |
| Recette créateur (modulaire) | consumption_value = 1/N → revenu fractionné |
| Recette privée utilisateur | Aucun revenu créateur |
| Combinaison créateur A + créateur B | 0.5 à A + 0.5 à B |

Les recettes privées ne génèrent aucune ligne dans `creator_revenue_log`.
Le check s'effectue via `recipe.is_private` au moment de l'enregistrement
de la consommation.

---

*Document créé : Avril 2026*  
*Auteur : Curtis — Fondateur Akeli*  
*Version : 1.0*  
*Documents liés : V1_MODULAR_MEAL_BATCH_CONCILIATION.md · V1_RECOMMENDATION_MULTI_ENGINE.md*
