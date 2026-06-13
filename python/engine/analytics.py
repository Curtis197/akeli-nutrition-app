"""
Analytics — Recipe Weight Impact
Pour chaque recette consommée par un utilisateur, calcule le delta de poids moyen
observé lors des périodes où cette recette a été consommée.

Algorithme :
  1. Récupérer toutes les entrées weight_log triées ASC.
  2. Pour chaque paire consécutive (date1, w1) → (date2, w2) :
       delta = w2 - w1
       Trouver toutes les recettes consommées dans [date1, date2).
       Ajouter delta à la liste de deltas de chaque recette trouvée.
  3. Pour chaque recette : avg_delta_kg = mean(deltas).
  4. Ne retenir que les recettes avec sample_count >= min_samples.

Un avg_delta_kg négatif = recette associée à une perte de poids.
"""

from engine.database import get_user_weight_log, get_recipes_consumed_between


def compute_recipe_weight_impact(
    user_id: str,
    min_samples: int = 3,
) -> list[dict]:
    """
    Retourne la liste des recettes avec leur avg_delta_kg et sample_count.
    Seules les recettes avec sample_count >= min_samples sont incluses.
    Résultat trié par avg_delta_kg ASC (meilleures recettes pour la perte de poids en premier).
    """
    weight_log = get_user_weight_log(user_id)

    if len(weight_log) < 2:
        return []

    # recipe_id -> [delta1, delta2, ...]
    recipe_deltas: dict[str, list[float]] = {}

    for i in range(len(weight_log) - 1):
        date1, w1 = weight_log[i]
        date2, w2 = weight_log[i + 1]
        delta = round(w2 - w1, 4)

        recipes = get_recipes_consumed_between(user_id, date1, date2)
        for recipe_id in recipes:
            recipe_deltas.setdefault(recipe_id, []).append(delta)

    results = []
    for recipe_id, deltas in recipe_deltas.items():
        if len(deltas) < min_samples:
            continue
        avg_delta = round(sum(deltas) / len(deltas), 4)
        results.append({
            "recipe_id":    recipe_id,
            "avg_delta_kg": avg_delta,
            "sample_count": len(deltas),
        })

    results.sort(key=lambda r: r["avg_delta_kg"])
    return results
