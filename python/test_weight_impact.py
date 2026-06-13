"""
Test de l'algorithme compute_recipe_weight_impact avec donnees mock.
Aucune connexion DB requise - les fonctions DB sont patchees directement.

Lancer : python test_weight_impact.py
"""

from datetime import date
from unittest.mock import patch
from engine.analytics import compute_recipe_weight_impact

# ------------------------------------------------------------------
# IDs de recettes fictifs
# ------------------------------------------------------------------
THIEBOUDIENNE = "r-thiebou"
BOUILLIE_MIL  = "r-bouillie"
ARACHIDES     = "r-arachides"
SALADE_AVOCAT = "r-salade"
POULET_YASSA  = "r-yassa"
FOUFOU_SAUCE  = "r-foufou"
BISSAP_SALADE = "r-bissap"
OMELETTE      = "r-omelette"
RIZ_SAUCE     = "r-riz-sauce"

RECIPE_NAMES = {
    THIEBOUDIENNE: "Thieboudienne au poisson",
    BOUILLIE_MIL:  "Bouillie de mil",
    ARACHIDES:     "Arachides grillees",
    SALADE_AVOCAT: "Salade avocat-tomate",
    POULET_YASSA:  "Poulet Yassa",
    FOUFOU_SAUCE:  "Foufou + sauce graine",
    BISSAP_SALADE: "Salade de bissap",
    OMELETTE:      "Omelette aux herbes",
    RIZ_SAUCE:     "Riz sauce tomate",
}

MEAL_TYPE_LABELS = {
    "breakfast": "Petit-dejeuner",
    "lunch":     "Dejeuner",
    "dinner":    "Diner",
    "snack":     "Collation",
}


# ------------------------------------------------------------------
# Affichage
# ------------------------------------------------------------------
def print_results(label, results, note=""):
    print("\n" + "-" * 66)
    print("  " + label)
    if note:
        print("  >> " + note)
    print("-" * 66)
    if not results:
        print("  (aucun resultat -- min_samples non atteint ou donnees insuffisantes)")
        return

    # Group by meal_type for display
    by_type = {}
    for r in results:
        mt = r["meal_type"]
        by_type.setdefault(mt, []).append(r)

    for mt, rows in sorted(by_type.items()):
        print(f"\n  [{MEAL_TYPE_LABELS.get(mt, mt).upper()}]")
        for r in rows:
            name  = RECIPE_NAMES.get(r["recipe_id"], r["recipe_id"])
            delta = r["avg_delta_kg"]
            n     = r["sample_count"]
            sign  = "v" if delta < 0 else ("=" if abs(delta) < 0.01 else "^")
            bar   = "#" * min(int(abs(delta) * 20), 20)
            tag   = "PERTE " if delta < 0 else ("STABLE" if abs(delta) < 0.01 else "GAIN  ")
            top   = " <-- TOP" if r == rows[0] else ""
            print(f"    {sign} {tag}  {delta:+.3f} kg  (n={n})  {bar:<20}  {name}{top}")


# ------------------------------------------------------------------
# Scenario 1 - Par type de repas, signal clair
# Petit-dej leger -> perte / dejeuner lourd -> gain / diner mixte
# ------------------------------------------------------------------
def scenario_by_meal_type():
    weight_log = [
        (date(2026, 1,  1), 90.0),
        (date(2026, 1,  8), 89.3),  # -0.7
        (date(2026, 1, 15), 88.9),  # -0.4
        (date(2026, 1, 22), 89.5),  # +0.6
        (date(2026, 1, 29), 90.0),  # +0.5
        (date(2026, 2,  5), 89.2),  # -0.8
        (date(2026, 2, 12), 88.7),  # -0.5
        (date(2026, 2, 19), 89.3),  # +0.6
        (date(2026, 2, 26), 88.5),  # -0.8
    ]
    # Semaines -0.7, -0.4, -0.8, -0.5, -0.8 : bonnes
    # Semaines +0.6, +0.5, +0.6            : mauvaises
    consumed = {
        # Bonnes semaines : bouillie au petit-dej, salade au dej, yassa au diner
        (date(2026, 1,  1), date(2026, 1,  8)): [
            (BOUILLIE_MIL,  "breakfast"),
            (SALADE_AVOCAT, "lunch"),
            (POULET_YASSA,  "dinner"),
        ],
        (date(2026, 1,  8), date(2026, 1, 15)): [
            (BOUILLIE_MIL,  "breakfast"),
            (BISSAP_SALADE, "lunch"),
            (POULET_YASSA,  "dinner"),
        ],
        # Mauvaises semaines : foufou au petit-dej, thiebou au dej, thiebou au diner
        (date(2026, 1, 15), date(2026, 1, 22)): [
            (FOUFOU_SAUCE,  "breakfast"),
            (THIEBOUDIENNE, "lunch"),
            (THIEBOUDIENNE, "dinner"),
        ],
        (date(2026, 1, 22), date(2026, 1, 29)): [
            (FOUFOU_SAUCE,  "breakfast"),
            (THIEBOUDIENNE, "lunch"),
            (RIZ_SAUCE,     "dinner"),
        ],
        (date(2026, 1, 29), date(2026, 2,  5)): [
            (BOUILLIE_MIL,  "breakfast"),
            (SALADE_AVOCAT, "lunch"),
            (POULET_YASSA,  "dinner"),
        ],
        (date(2026, 2,  5), date(2026, 2, 12)): [
            (OMELETTE,      "breakfast"),
            (SALADE_AVOCAT, "lunch"),
            (POULET_YASSA,  "dinner"),
        ],
        (date(2026, 2, 12), date(2026, 2, 19)): [
            (FOUFOU_SAUCE,  "breakfast"),
            (THIEBOUDIENNE, "lunch"),
            (RIZ_SAUCE,     "dinner"),
        ],
        (date(2026, 2, 19), date(2026, 2, 26)): [
            (BOUILLIE_MIL,  "breakfast"),
            (BISSAP_SALADE, "lunch"),
            (POULET_YASSA,  "dinner"),
        ],
    }

    with patch("engine.analytics.get_user_weight_log", lambda uid: weight_log), \
         patch("engine.analytics.get_recipes_consumed_between", lambda uid, d1, d2: consumed.get((d1, d2), [])):
        results = compute_recipe_weight_impact("user-1", min_samples=3)

    print_results(
        "Scenario 1 -- Signal clair par type de repas",
        results,
        "Attendu: bouillie/salade en PERTE, foufou/thiebou en GAIN, yassa en PERTE au diner",
    )


# ------------------------------------------------------------------
# Scenario 2 - Meme recette, roles differents selon le repas
# Riz sauce: PERTE au dejeuner (petit portion), GAIN au diner (grosse portion)
# ------------------------------------------------------------------
def scenario_same_recipe_different_meal():
    weight_log = [
        (date(2026, 3,  1), 80.0),
        (date(2026, 3,  8), 79.5),  # -0.5 : semaine riz-lunch
        (date(2026, 3, 15), 80.3),  # +0.8 : semaine riz-dinner
        (date(2026, 3, 22), 79.7),  # -0.6 : semaine riz-lunch
        (date(2026, 3, 29), 80.4),  # +0.7 : semaine riz-dinner
        (date(2026, 4,  5), 79.8),  # -0.6 : semaine riz-lunch
        (date(2026, 4, 12), 80.5),  # +0.7 : semaine riz-dinner
        (date(2026, 4, 19), 79.9),  # -0.6 : semaine riz-lunch
    ]
    consumed = {
        (date(2026, 3,  1), date(2026, 3,  8)): [(RIZ_SAUCE, "lunch"),  (BOUILLIE_MIL, "breakfast")],
        (date(2026, 3,  8), date(2026, 3, 15)): [(RIZ_SAUCE, "dinner"), (BOUILLIE_MIL, "breakfast")],
        (date(2026, 3, 15), date(2026, 3, 22)): [(RIZ_SAUCE, "lunch"),  (BOUILLIE_MIL, "breakfast")],
        (date(2026, 3, 22), date(2026, 3, 29)): [(RIZ_SAUCE, "dinner"), (BOUILLIE_MIL, "breakfast")],
        (date(2026, 3, 29), date(2026, 4,  5)): [(RIZ_SAUCE, "lunch"),  (BOUILLIE_MIL, "breakfast")],
        (date(2026, 4,  5), date(2026, 4, 12)): [(RIZ_SAUCE, "dinner"), (BOUILLIE_MIL, "breakfast")],
        (date(2026, 4, 12), date(2026, 4, 19)): [(RIZ_SAUCE, "lunch"),  (BOUILLIE_MIL, "breakfast")],
    }

    with patch("engine.analytics.get_user_weight_log", lambda uid: weight_log), \
         patch("engine.analytics.get_recipes_consumed_between", lambda uid, d1, d2: consumed.get((d1, d2), [])):
        results = compute_recipe_weight_impact("user-2", min_samples=3)

    print_results(
        "Scenario 2 -- Meme recette, impact different selon le repas",
        results,
        "Riz sauce au dejeuner -> PERTE. Riz sauce au diner -> GAIN. Separation par meal_type cruciale.",
    )


# ------------------------------------------------------------------
# Scenario 3 - Filtre min_samples (n=3) par (recipe, meal_type)
# ------------------------------------------------------------------
def scenario_filter_by_meal_type():
    weight_log = [
        (date(2026, 5,  1), 75.0),
        (date(2026, 5,  8), 74.5),
        (date(2026, 5, 15), 74.2),
        (date(2026, 5, 22), 74.0),
        (date(2026, 5, 29), 74.7),
    ]
    # salade au dej = 4 fois -> retenu
    # salade au petit-dej = 2 fois -> filtre
    consumed = {
        (date(2026, 5,  1), date(2026, 5,  8)): [(SALADE_AVOCAT, "lunch"), (SALADE_AVOCAT, "breakfast")],
        (date(2026, 5,  8), date(2026, 5, 15)): [(SALADE_AVOCAT, "lunch")],
        (date(2026, 5, 15), date(2026, 5, 22)): [(SALADE_AVOCAT, "lunch"), (SALADE_AVOCAT, "breakfast")],
        (date(2026, 5, 22), date(2026, 5, 29)): [(SALADE_AVOCAT, "lunch")],
    }

    with patch("engine.analytics.get_user_weight_log", lambda uid: weight_log), \
         patch("engine.analytics.get_recipes_consumed_between", lambda uid, d1, d2: consumed.get((d1, d2), [])):
        results = compute_recipe_weight_impact("user-3", min_samples=3)

    print_results(
        "Scenario 3 -- Filtre min_samples par (recette, meal_type)",
        results,
        "Salade au dejeuner (n=4) retenu. Salade au petit-dej (n=2) filtre.",
    )


# ------------------------------------------------------------------
# Scenario 4 - Realiste complet : 3 tops distincts par repas
# ------------------------------------------------------------------
def scenario_realistic_top3():
    weight_log = [
        (date(2026, 4,  7), 92.0),
        (date(2026, 4, 14), 91.3),  # -0.7
        (date(2026, 4, 21), 91.8),  # +0.5
        (date(2026, 4, 28), 91.0),  # -0.8
        (date(2026, 5,  5), 90.6),  # -0.4
        (date(2026, 5, 12), 91.2),  # +0.6
        (date(2026, 5, 19), 90.4),  # -0.8
        (date(2026, 5, 26), 90.0),  # -0.4
        (date(2026, 6,  2), 90.7),  # +0.7
        (date(2026, 6,  9), 89.9),  # -0.8
        (date(2026, 6, 13), 89.5),  # -0.4
    ]
    consumed = {
        (date(2026, 4,  7), date(2026, 4, 14)): [
            (BOUILLIE_MIL,  "breakfast"), (SALADE_AVOCAT, "lunch"), (POULET_YASSA, "dinner")],
        (date(2026, 4, 14), date(2026, 4, 21)): [
            (FOUFOU_SAUCE,  "breakfast"), (THIEBOUDIENNE, "lunch"), (RIZ_SAUCE,    "dinner")],
        (date(2026, 4, 21), date(2026, 4, 28)): [
            (OMELETTE,      "breakfast"), (SALADE_AVOCAT, "lunch"), (POULET_YASSA, "dinner")],
        (date(2026, 4, 28), date(2026, 5,  5)): [
            (BOUILLIE_MIL,  "breakfast"), (BISSAP_SALADE, "lunch"), (POULET_YASSA, "dinner")],
        (date(2026, 5,  5), date(2026, 5, 12)): [
            (FOUFOU_SAUCE,  "breakfast"), (THIEBOUDIENNE, "lunch"), (FOUFOU_SAUCE, "dinner")],
        (date(2026, 5, 12), date(2026, 5, 19)): [
            (OMELETTE,      "breakfast"), (SALADE_AVOCAT, "lunch"), (POULET_YASSA, "dinner")],
        (date(2026, 5, 19), date(2026, 5, 26)): [
            (BOUILLIE_MIL,  "breakfast"), (BISSAP_SALADE, "lunch"), (POULET_YASSA, "dinner")],
        (date(2026, 5, 26), date(2026, 6,  2)): [
            (FOUFOU_SAUCE,  "breakfast"), (THIEBOUDIENNE, "lunch"), (RIZ_SAUCE,    "dinner")],
        (date(2026, 6,  2), date(2026, 6,  9)): [
            (BOUILLIE_MIL,  "breakfast"), (SALADE_AVOCAT, "lunch"), (POULET_YASSA, "dinner")],
        (date(2026, 6,  9), date(2026, 6, 13)): [
            (OMELETTE,      "breakfast"), (BISSAP_SALADE, "lunch"), (POULET_YASSA, "dinner")],
    }

    with patch("engine.analytics.get_user_weight_log", lambda uid: weight_log), \
         patch("engine.analytics.get_recipes_consumed_between", lambda uid, d1, d2: consumed.get((d1, d2), [])):
        results = compute_recipe_weight_impact("user-4", min_samples=3)

    print_results(
        "Scenario 4 -- Realiste complet (top 3 par repas)",
        results,
        "Top breakfast: bouillie/omelette. Top lunch: salade/bissap. Top dinner: yassa.",
    )


# ------------------------------------------------------------------
# Runner
# ------------------------------------------------------------------
if __name__ == "__main__":
    print("=" * 66)
    print("  TEST -- compute_recipe_weight_impact par meal_type (donnees mock)")
    print("=" * 66)

    scenario_by_meal_type()
    scenario_same_recipe_different_meal()
    scenario_filter_by_meal_type()
    scenario_realistic_top3()

    print("\n" + "=" * 66)
    print("  Termine.")
    print("=" * 66)
