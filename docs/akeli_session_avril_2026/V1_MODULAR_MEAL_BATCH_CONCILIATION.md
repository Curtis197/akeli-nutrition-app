# Akeli V1 — Modular Meal & Batch Cooking : Spec Complète et Conciliation

> Ce document remplace et étend `V1_BATCH_COOKING_SPEC.md`.  
> Il couvre les deux features ensemble et leur conciliation au niveau DB et UI.

**Statut** : Prêt pour implémentation V1  
**Date** : Avril 2026  
**Auteur** : Curtis — Fondateur Akeli  
**Dépendances** : `V1_USER_RECIPES_COMBINATIONS.md`, `V1_RECOMMENDATION_MULTI_ENGINE.md`

---

## 1. Concepts

### 1.1 Modular Meal

La cuisine africaine est **compositionnelle** : un repas est composé d'une sauce/base et
d'un féculent interchangeable. La même sauce graine peut être mangée avec du riz, du foutou,
ou de l'attiéké — trois repas nutritionnellement distincts, partageant le même composant base.

Un `meal_plan_entry` n'est plus lié à une seule recette mais à **N composants**, chaque
composant étant une recette indépendante avec son propre créateur et ses propres macros.

**Rôles des composants :**
- `base` — la sauce, le ragoût, le plat principal
- `starch` — le féculent (riz, foutou, attiéké, igname, placali...)
- `side` — l'accompagnement (légumes, salade...)

**Consommation fractionnée :**
Chaque composant génère un `meal_consumption` avec une valeur numérique égale à `1 / N`
(N = nombre de composants du repas). La somme des fractions d'un repas = 1.0.

| Repas | Composants | Fraction chacun |
|-------|-----------|-----------------|
| Ndolé seul | ndolé | 1.0 |
| Ndolé + Foutou | ndolé, foutou | 0.5 / 0.5 |
| Mafé + Riz + Salade | mafé, riz, salade | 0.33 / 0.33 / 0.33 |

### 1.2 Batch Cooking

Une session de cuisson produit N portions d'une recette, distribuées sur plusieurs repas
de la semaine. La session est liée au **composant** concerné — pas au repas entier.

La sauce ndolé peut être en batch (cuisinée une fois pour 5 repas), le féculent est
cuisiné à part à chaque repas. Les deux composants apparaissent dans le même repas
mais ont des cycles de cuisson indépendants.

### 1.3 Conciliation

```
cooking_session (1) ──── meal_plan_entry_component (N)
                              ├── recipe_id
                              ├── role
                              └── consumption_weight

meal_plan_entry (1) ──── meal_plan_entry_component (N)
```

Un composant peut avoir une `cooking_session_id` (batch) ou non (cuisiné à la demande).
Les deux sont indépendants et coexistent naturellement.

---

## 2. Modifications base de données

### 2.1 Modification de `meal_plan_entry`

Suppression du `recipe_id` direct. Tout passe par les composants, même pour un repas
simple (1 composant = weight 1.0).

```sql
ALTER TABLE meal_plan_entry
DROP COLUMN IF EXISTS recipe_id;
```

### 2.2 Nouvelle table : `meal_plan_entry_component`

```sql
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

CREATE INDEX idx_mpec_entry      ON meal_plan_entry_component(meal_plan_entry_id);
CREATE INDEX idx_mpec_recipe     ON meal_plan_entry_component(recipe_id);
CREATE INDEX idx_mpec_session    ON meal_plan_entry_component(cooking_session_id);

ALTER TABLE meal_plan_entry_component ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner via entry" ON meal_plan_entry_component FOR SELECT USING (
  meal_plan_entry_id IN (
    SELECT mpe.id FROM meal_plan_entry mpe
    JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
    WHERE mp.user_id = auth.uid()
  )
);
```

### 2.3 Trigger : recalcul automatique de `consumption_weight`

À chaque INSERT ou DELETE d'un composant, le trigger recalcule `1 / COUNT(composants)`
et met à jour tous les composants du même `meal_plan_entry`.

```sql
CREATE OR REPLACE FUNCTION recalculate_consumption_weight()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  _entry_id uuid;
  _count    int;
  _weight   numeric(4,3);
BEGIN
  -- Determine which entry was affected
  IF TG_OP = 'DELETE' THEN
    _entry_id := OLD.meal_plan_entry_id;
  ELSE
    _entry_id := NEW.meal_plan_entry_id;
  END IF;

  -- Count remaining components for this entry
  SELECT COUNT(*) INTO _count
  FROM meal_plan_entry_component
  WHERE meal_plan_entry_id = _entry_id;

  -- Avoid division by zero
  IF _count = 0 THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  _weight := ROUND((1.0 / _count)::numeric, 3);

  -- Update all components for this entry
  UPDATE meal_plan_entry_component
  SET consumption_weight = _weight
  WHERE meal_plan_entry_id = _entry_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_consumption_weight
AFTER INSERT OR DELETE ON meal_plan_entry_component
FOR EACH ROW EXECUTE FUNCTION recalculate_consumption_weight();
```

### 2.4 Modification de `meal_consumption`

Passage du boolean `is_consumed` à une valeur numérique `consumption_value`.

```sql
ALTER TABLE meal_consumption
ADD COLUMN consumption_value numeric(4,3) NOT NULL DEFAULT 1.0;

-- Migrer les données existantes
UPDATE meal_consumption SET consumption_value = 1.0;

-- Ajouter référence au composant
ALTER TABLE meal_consumption
ADD COLUMN component_id uuid REFERENCES meal_plan_entry_component(id) ON DELETE SET NULL;
```

### 2.5 Modification de `cooking_session`

Suppression du lien `meal_plan_entry_id` (remplacé par le lien au niveau composant).

```sql
-- Le lien est maintenant sur meal_plan_entry_component.cooking_session_id
-- cooking_session garde meal_plan_id pour le contexte de la semaine
ALTER TABLE cooking_session
DROP COLUMN IF EXISTS meal_plan_entry_id;
```

### 2.6 Ajout sur `user_profile`

```sql
ALTER TABLE user_profile
ADD COLUMN batch_cooking_enabled  boolean DEFAULT false,
ADD COLUMN modular_meal_enabled   boolean DEFAULT false;
```

### 2.7 Ajout sur `recipe`

```sql
-- Féculents compatibles suggérés par le créateur (recipe_ids)
ALTER TABLE recipe
ADD COLUMN compatible_starches uuid[] DEFAULT '{}';
```

---

## 3. Résumé des tables modifiées

| Table | Changement |
|-------|-----------|
| `meal_plan_entry` | Suppression de `recipe_id` |
| `meal_plan_entry_component` | Nouvelle table centrale |
| `meal_consumption` | Ajout `consumption_value numeric`, `component_id` |
| `cooking_session` | Suppression `meal_plan_entry_id` (lien déplacé sur composant) |
| `user_profile` | Ajout `batch_cooking_enabled`, `modular_meal_enabled` |
| `recipe` | Ajout `compatible_starches uuid[]` |

---

## 4. Logique métier

### 4.1 Création d'un repas simple (comportement par défaut)

1. Créer `meal_plan_entry`
2. Créer 1 `meal_plan_entry_component` avec `role = 'base'`
3. Le trigger calcule `consumption_weight = 1.0`
4. À la consommation : 1 `meal_consumption` avec `consumption_value = 1.0`

### 4.2 Création d'un repas modulaire

1. Créer `meal_plan_entry`
2. Créer N `meal_plan_entry_component` avec leurs rôles
3. Le trigger calcule `consumption_weight = 1/N` pour chaque composant
4. À la consommation : N `meal_consumption` avec `consumption_value = 1/N` chacun

### 4.3 Ajout du batch cooking sur un composant

1. Créer une `cooking_session` liée au `meal_plan_id`
2. Assigner `cooking_session_id` sur le composant concerné (ex: la sauce)
3. Les autres composants du même repas peuvent avoir leur propre session ou `null`

### 4.4 Revenue créateur

Inchangé dans la logique. La valeur monétaire d'une consommation est multipliée par
`consumption_value`. Un repas à deux composants génère deux lignes de revenu à 0.5
unité chacune = 1.0 unité totale par repas.

```
consumption_value 1.0  → 1 unité de revenu
consumption_value 0.5  → 0.5 unité de revenu
consumption_value 0.33 → 0.33 unité de revenu
```

---

## 5. UI Flutter

### 5.1 Meal Planner (vue semaine)

Chaque créneau affiche **un composant au hasard** parmi ceux du repas — priorité au
composant `base`. Visuellement identique à aujourd'hui.

- Si `modular_meal_enabled = true` : badge discret "modulaire" sur la card
- Si `cooking_session_id` présent sur un composant : badge "batch" sur la card

### 5.2 Meal Entry (vue détail repas)

```
┌─────────────────────────────────────┐
│  Total : 650 kcal                   │
│  Protéines: 32g  Glucides: 78g      │
│  Lipides: 18g                       │
├─────────────────────────────────────┤
│  ← [🍲 Ndolé]  [🍚 Riz blanc] →    │
│      base           starch          │
│    [BATCH]                          │
├─────────────────────────────────────┤
│  Marquer comme consommé             │
└─────────────────────────────────────┘
```

- **En priorité** : total nutritionnel additionné de tous les composants
- **Carousel/row** : composants avec image + nom + rôle + badge batch si applicable
- Tap composant → fiche recette individuelle
- Bouton "Marquer comme consommé" → crée N `meal_consumption` en une action

### 5.3 Page Batch Cooking (`meal_planner/batch_cooking`)

```
BatchCookingPage
├── Header : "Batch Cooking — Semaine du [date]"
├── Bouton : "+ Nouvelle session"
└── Liste des cooking_session de la semaine
    └── CookingSessionCard
        ├── Image recette (composant lié)
        ├── Nom de la recette + rôle (base / starch / side)
        ├── Date de cuisson prévue
        ├── Portions : [portions_used] / [total_portions]
        └── Chips des repas couverts
            ex: "Lun. déjeuner · Mer. déjeuner · Ven. dîner"
```

---

## 6. Schéma relationnel complet

```
meal_plan
    └── meal_plan_entry (N)
            └── meal_plan_entry_component (N)
                    ├── recipe_id → recipe
                    ├── role : base | starch | side
                    ├── consumption_weight : 1/N
                    └── cooking_session_id → cooking_session (optionnel)

cooking_session
    ├── meal_plan_id → meal_plan
    ├── recipe_id → recipe
    ├── total_portions
    └── portions_used (trigger auto)

meal_consumption
    ├── user_id
    ├── recipe_id
    ├── component_id → meal_plan_entry_component
    └── consumption_value : numeric (1/N)
```

---

*Document créé : Avril 2026*  
*Auteur : Curtis — Fondateur Akeli*  
*Version : 1.0 — Remplace V1_BATCH_COOKING_SPEC.md*  
*Documents liés : V1_USER_RECIPES_COMBINATIONS.md · V1_RECOMMENDATION_MULTI_ENGINE.md*
