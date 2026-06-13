"""
Analytics -- Recipe Weight Impact by Meal Type
Pour chaque paire (recette, type de repas) consommee par un utilisateur,
calcule le delta de poids moyen observe lors des periodes ou cette combinaison
a ete consommee.

Algorithme :
  1. Recuperer toutes les entrees weight_log triees ASC.
  2. Pour chaque paire consecutive (date1, w1) -> (date2, w2) :
       delta = w2 - w1
       Trouver toutes les paires (recipe_id, meal_type) consommees dans [date1, date2).
       Ajouter delta a la liste de deltas de chaque paire.
  3. Pour chaque (recipe_id, meal_type) : avg_delta_kg = mean(deltas).
  4. Filtrer : sample_count >= min_samples.
  5. Pour chaque meal_type, la paire avec le plus petit avg_delta_kg est la meilleure.

Retourne toutes les paires qualifiees triees par avg_delta_kg ASC.
Le top par meal_type est la premiere entree de chaque groupe dans ce tri.
"""

from engine.database import get_user_weight_log, get_recipes_consumed_between


def compute_recipe_weight_impact(
    user_id: str,
    min_samples: int = 3,
) -> list[dict]:
    """
    Retourne la liste des (recipe_id, meal_type) avec avg_delta_kg et sample_count.
    Seules les paires avec sample_count >= min_samples sont incluses.
    Trie par avg_delta_kg ASC — le top par meal_type est la premiere entree de chaque groupe.
    """
    weight_log = get_user_weight_log(user_id)

    if len(weight_log) < 2:
        return []

    # (recipe_id, meal_type) -> [delta1, delta2, ...]
    pair_deltas: dict[tuple, list[float]] = {}

    for i in range(len(weight_log) - 1):
        date1, w1 = weight_log[i]
        date2, w2 = weight_log[i + 1]
        delta = round(w2 - w1, 4)

        pairs = get_recipes_consumed_between(user_id, date1, date2)
        for recipe_id, meal_type in pairs:
            key = (recipe_id, meal_type)
            pair_deltas.setdefault(key, []).append(delta)

    results = []
    for (recipe_id, meal_type), deltas in pair_deltas.items():
        if len(deltas) < min_samples:
            continue
        avg_delta = round(sum(deltas) / len(deltas), 4)
        results.append({
            "recipe_id":    recipe_id,
            "meal_type":    meal_type,
            "avg_delta_kg": avg_delta,
            "sample_count": len(deltas),
        })

    results.sort(key=lambda r: r["avg_delta_kg"])
    return results
