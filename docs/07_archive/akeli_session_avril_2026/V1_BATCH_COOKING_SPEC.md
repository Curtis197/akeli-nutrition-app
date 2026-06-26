# Akeli V1 — Batch Cooking Feature Spec

> Feature exclusive à Akeli.  
> Modélise la réalité de la cuisine africaine : on cuisine en grande quantité une fois,  
> et on consomme les portions sur plusieurs repas de la semaine.

**Statut** : Prêt pour implémentation V1  
**Date** : Mars 2026  
**Auteur** : Curtis — Fondateur Akeli  
**Scope** : Database · Backend · Flutter UI

---

## 1. Concept

La cuisine africaine repose fréquemment sur le **batch cooking** : un plat est cuisiné en
grande quantité (ex : 6 portions de thiéboudienne le dimanche), puis les portions sont
distribuées sur plusieurs repas de la semaine (déjeuner lundi, déjeuner mercredi, dîner jeudi).

Le modèle V1 actuel (`meal_plan_entry`) traite chaque repas comme une session de cuisson
indépendante — ce qui ne reflète pas ce comportement.

Cette feature introduit le concept de **cooking session** : une session de cuisson produit
N portions d'une recette, distribuées sur plusieurs `meal_plan_entry`. Chaque consommation
d'une portion reste un `meal_consumption` indépendant — le modèle de revenu créateur est
**inchangé**.

---

## 2. Règle batch_friendly

Une recette est considérée **batch friendly** si son nombre de portions (`servings`) est
supérieur à 1. Pas de champ supplémentaire nécessaire — la règle est calculée à la volée.

```sql
-- Règle : batch_friendly = (servings > 1)
-- Utilisé dans l'algorithme de génération du meal plan
```

---

## 3. Modifications base de données

### 3.1 Ajout sur `user_profile`

```sql
ALTER TABLE user_profile
ADD COLUMN batch_cooking_enabled boolean DEFAULT false;
```

Activé par l'utilisateur dans ses paramètres. Quand `true`, l'algorithme de génération
du meal plan favorise les recettes avec `servings > 1` et les groupe sous des sessions
de cuisson.

---

### 3.2 Nouvelle table : `cooking_session`

Représente une session de cuisson unique — une recette cuisinée en une fois pour
plusieurs repas.

```sql
CREATE TABLE cooking_session (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid REFERENCES user_profile(id) ON DELETE CASCADE,
  meal_plan_id      uuid REFERENCES meal_plan(id) ON DELETE CASCADE,
  recipe_id         uuid REFERENCES recipe(id) ON DELETE CASCADE,
  planned_date      date NOT NULL,               -- jour où l'utilisateur prévoit de cuisiner
  total_portions    int NOT NULL,                -- nb de portions cuisinées
  portions_used     int DEFAULT 0,               -- nb de portions assignées à des meal_plan_entry
  notes             text,                        -- note libre de l'utilisateur
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);

CREATE INDEX idx_cooking_session_user     ON cooking_session(user_id);
CREATE INDEX idx_cooking_session_plan     ON cooking_session(meal_plan_id);
CREATE INDEX idx_cooking_session_date     ON cooking_session(planned_date);

ALTER TABLE cooking_session ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner only" ON cooking_session USING (auth.uid() = user_id);
```

---

### 3.3 Modification de `meal_plan_entry`

Ajout d'une clé étrangère optionnelle vers `cooking_session`. `NULL` = repas cuisiné
individuellement (comportement par défaut inchangé).

```sql
ALTER TABLE meal_plan_entry
ADD COLUMN cooking_session_id uuid REFERENCES cooking_session(id) ON DELETE SET NULL;

CREATE INDEX idx_meal_plan_entry_session ON meal_plan_entry(cooking_session_id);
```

---

### 3.4 Trigger : mise à jour de `portions_used`

Maintient automatiquement le compteur `portions_used` sur `cooking_session`.

```sql
CREATE OR REPLACE FUNCTION update_portions_used()
RETURNS TRIGGER AS $$
BEGIN
  -- On insert : incrémenter
  IF TG_OP = 'INSERT' AND NEW.cooking_session_id IS NOT NULL THEN
    UPDATE cooking_session
    SET portions_used = portions_used + 1
    WHERE id = NEW.cooking_session_id;

  -- On delete : décrémenter
  ELSIF TG_OP = 'DELETE' AND OLD.cooking_session_id IS NOT NULL THEN
    UPDATE cooking_session
    SET portions_used = portions_used - 1
    WHERE id = OLD.cooking_session_id;

  -- On update (changement de session)
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.cooking_session_id IS DISTINCT FROM NEW.cooking_session_id THEN
      IF OLD.cooking_session_id IS NOT NULL THEN
        UPDATE cooking_session SET portions_used = portions_used - 1
        WHERE id = OLD.cooking_session_id;
      END IF;
      IF NEW.cooking_session_id IS NOT NULL THEN
        UPDATE cooking_session SET portions_used = portions_used + 1
        WHERE id = NEW.cooking_session_id;
      END IF;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_portions_used
AFTER INSERT OR UPDATE OR DELETE ON meal_plan_entry
FOR EACH ROW EXECUTE FUNCTION update_portions_used();
```

---

## 4. Logique de génération du meal plan

Quand `batch_cooking_enabled = true` sur le profil utilisateur :

1. Lors de la génération du meal plan, filtrer en priorité les recettes avec `servings > 1`
2. Pour chaque recette batch sélectionnée, créer une `cooking_session` avec `total_portions = recipe.servings`
3. Distribuer les portions sur plusieurs `meal_plan_entry` de la semaine, en liant chaque entrée à la même `cooking_session_id`
4. Ne pas dépasser `total_portions` — les portions restantes (`total_portions - portions_used`) restent disponibles

Quand `batch_cooking_enabled = false` : comportement inchangé, `cooking_session_id` reste `NULL` sur toutes les entrées.

---

## 5. Création manuelle d'une session

L'utilisateur peut créer une session de batch cooking manuellement depuis la page
`meal_planner/batch_cooking`, indépendamment de la génération automatique.

**Flux :**
1. L'utilisateur sélectionne une recette (filtrée sur `servings > 1` par défaut, mais pas exclusif)
2. Il choisit le jour de cuisson (`planned_date`)
3. Il choisit le nombre de portions (`total_portions`)
4. La session est créée — il peut ensuite assigner des `meal_plan_entry` existantes à cette session

---

## 6. Flutter — Page Batch Cooking

**Route** : `meal_planner/batch_cooking`  
**Accès** : Sous-page du Meal Planner (bouton ou onglet en haut de la page Meal Planner)

### 6.1 Structure de la page

```
BatchCookingPage
├── Header : "Batch Cooking — Semaine du [date]"
├── Bouton : "+ Nouvelle session"
├── Liste des cooking_session de la semaine active
│   └── CookingSessionCard (×N)
│       ├── Image recette (thumbnail)
│       ├── Nom de la recette
│       ├── Date de cuisson prévue
│       ├── Portions : [portions_used] / [total_portions]
│       ├── Chip par meal_plan_entry liée (ex: "Lun. déjeuner", "Mer. dîner")
│       └── Bouton "Modifier"
└── Empty state si aucune session
```

### 6.2 Données

| Source | Query | Usage |
|--------|-------|-------|
| `cooking_session` | `meal_plan_id = activePlanId` | Liste des sessions |
| `meal_plan_entry` | `cooking_session_id IN (sessionIds)` | Repas couverts par chaque session |
| `recipe` | join sur `cooking_session.recipe_id` | Nom + image |

### 6.3 Interactions

| Action | Résultat |
|--------|----------|
| Tap "+ Nouvelle session" | Bottom sheet : sélection recette + date + portions |
| Tap "Modifier" sur une session | Bottom sheet : édition de la session |
| Tap sur un chip de repas | Navigation vers `meal_plan_entry` correspondante |

---

## 7. Modèle de revenu — inchangé

La création d'une `cooking_session` n'affecte pas le revenu créateur.  
Chaque `meal_consumption` enregistré reste l'unité de facturation, qu'il soit lié ou non
à une session de batch cooking.

```
cooking_session (1) ──── meal_plan_entry (N) ──── meal_consumption (N)
                                                         ↓
                                               creator_revenue_log (N)
```

Une recette cuisinée une fois pour 5 portions = 5 `meal_consumption` potentiels
= 5 unités de revenu.

---

## 8. Paramètres utilisateur

**Page** : Settings → Préférences alimentaires  
**Champ** : Toggle "Cuisiner en grande quantité (batch cooking)"  
**Valeur par défaut** : `false`  
**Effet** : Active la priorisation des recettes batch dans la génération du meal plan

---

## 9. Résumé des changements

| Élément | Type | Description |
|---------|------|-------------|
| `user_profile.batch_cooking_enabled` | ALTER TABLE | Boolean préférence utilisateur |
| `cooking_session` | CREATE TABLE | Nouvelle entité centrale |
| `meal_plan_entry.cooking_session_id` | ALTER TABLE | Lien optionnel vers session |
| `trg_portions_used` | TRIGGER | Maintien auto de `portions_used` |
| `meal_planner/batch_cooking` | Flutter Page | Nouvelle sous-page |
| Settings toggle | Flutter UI | Activation préférence batch |

---

*Document créé : Mars 2026*  
*Auteur : Curtis — Fondateur Akeli*  
*Version : 1.0 — Spec V1*
