"""
Vectorisation 50D — user_vector et recipe_vector
Ref: V1_VECTORIZATION_MEAL_PLANNER.md + PYTHON_RECOMMENDATION_ENGINE.md

User vector (50D):
  [0:10]  Goals (10D)
  [10:25] Preferences (15D)
  [25:40] Behavior (15D)
  [40:50] Outcomes (10D)

Recipe vector (50D):
  [0:10]  Macros (10D)
  [10:20] Metadata (10D)
  [20:40] Outcomes (20D)
  [40:50] Creator signals (10D)
"""

from __future__ import annotations
from datetime import datetime, date, timedelta
from typing import Optional
import numpy as np

from .database import (
    get_user_health_profile,
    get_user_behavior,
    get_recipe_data,
    get_recipe_consumption_stats,
)

# Dimensions
VECTOR_DIM = 50

# Mappings
ACTIVITY_MAP = {
    "sedentary": 0.1,
    "light": 0.3,
    "moderate": 0.5,
    "active": 0.75,
    "very_active": 1.0,
}

GOAL_MAP = {
    "weight_loss": 0,
    "muscle_gain": 1,
    "maintenance": 2,
    "health": 3,
    "performance": 4,
}

REGION_MAP = {
    "west_africa": 0,
    "central_africa": 1,
    "east_africa": 2,
    "north_africa": 3,
    "south_africa": 4,
    "caribbean": 5,
    "france": 6,
    "mediterranean": 7,
    "middle_east": 8,
    "south_asia": 9,
    "southeast_asia": 10,
    "latin_america": 11,
    "north_america": 12,
}

DIFFICULTY_MAP = {"easy": 0.25, "medium": 0.6, "hard": 1.0}


def _normalize_l2(v: np.ndarray) -> np.ndarray:
    """Normalisation L2 pour cosine similarity."""
    norm = np.linalg.norm(v)
    return v / norm if norm > 1e-10 else v


# ---------------------------------------------------------------------------
# USER VECTOR
# ---------------------------------------------------------------------------

def compute_user_vector(user_id: str) -> Optional[np.ndarray]:
    """
    Construit le vecteur 50D d'un utilisateur.
    Retourne None si le profil est insuffisant.
    """
    profile = get_user_health_profile(user_id)
    if not profile:
        return None

    behavior = get_user_behavior(user_id, weeks=4)

    vector = np.zeros(VECTOR_DIM, dtype=np.float32)

    # ---- [0:10] GOALS (10D) ----
    goals = profile.get("goals") or []
    for goal in goals:
        idx = GOAL_MAP.get(goal)
        if idx is not None:
            vector[idx] = 1.0  # one-hot multi-label

    # Activity level [5]
    vector[5] = ACTIVITY_MAP.get(profile.get("activity_level", "moderate"), 0.5)

    # Goal proximity — progression vers l'objectif [6]
    w_kg = profile.get("weight_kg") or 0
    t_kg = profile.get("target_weight_kg") or w_kg
    if w_kg and t_kg and w_kg != t_kg:
        # Normalise sur une plage de 30kg
        delta = abs(w_kg - t_kg)
        vector[6] = min(1.0, delta / 30.0)

    # Current weight normalisé [7] (60–120kg → 0–1)
    if w_kg:
        vector[7] = min(1.0, max(0.0, (w_kg - 40.0) / 100.0))

    # ---- [10:25] PREFERENCES (15D) ----
    regions = profile.get("cuisine_regions") or []
    for region in regions[:5]:  # max 5 régions
        idx = REGION_MAP.get(region)
        if idx is not None and idx < 13:
            vector[10 + idx] = 1.0  # indices 10..22

    restrictions = profile.get("restrictions") or []
    # Indicateurs diététiques [23]
    if "vegetarian" in restrictions or "vegan" in restrictions:
        vector[23] = 1.0
    if "halal" in restrictions:
        vector[24] = 1.0

    # ---- [25:40] BEHAVIOR (15D) ----
    total_consumptions = behavior.get("total_consumptions") or 0
    active_days = behavior.get("active_days") or 0

    # Fréquence de logging [25] (1 = 1x/j sur 4 semaines)
    vector[25] = min(1.0, active_days / 28.0)

    # Volume de consommation [26]
    vector[26] = min(1.0, total_consumptions / 84.0)  # 3 repas/j × 28j = 84

    # Portion moyenne [27]
    avg_servings = behavior.get("avg_servings") or 1.0
    vector[27] = min(1.0, avg_servings / 2.0)

    # ---- [40:50] OUTCOMES (10D) ----
    current_weight = behavior.get("current_weight_kg") or w_kg
    # Vélocité de poids — tendance [40]
    if w_kg and current_weight and w_kg != current_weight:
        velocity = (current_weight - w_kg) / 4.0  # kg/semaine sur 4 sem
        # Normalise entre -1 et 1 (perte = négatif = bien pour weight_loss)
        vector[40] = max(-1.0, min(1.0, velocity / 2.0))

    # Adhérence globale [41] — proportion de jours actifs
    if active_days > 0:
        vector[41] = min(1.0, active_days / 28.0)

    return _normalize_l2(vector)


# ---------------------------------------------------------------------------
# RECIPE VECTOR
# ---------------------------------------------------------------------------

def compute_recipe_vector(recipe_id: str) -> Optional[np.ndarray]:
    """
    Construit le vecteur 50D d'une recette.
    Retourne None si la recette n'est pas publiée ou données insuffisantes.
    """
    recipe = get_recipe_data(recipe_id)
    if not recipe:
        return None

    stats = get_recipe_consumption_stats(recipe_id, days=30)

    vector = np.zeros(VECTOR_DIM, dtype=np.float32)

    # ---- [0:10] MACROS (10D) ----
    cal = recipe.get("calories") or 0
    prot = recipe.get("protein_g") or 0
    carbs = recipe.get("carbs_g") or 0
    fat = recipe.get("fat_g") or 0
    fiber = recipe.get("fiber_g") or 0
    total_macros = prot + carbs + fat

    # Ratios macros [0, 1, 2]
    if total_macros > 0:
        vector[0] = prot / total_macros
        vector[1] = carbs / total_macros
        vector[2] = fat / total_macros

    # Densité calorique [3] — 0 = légère, 1 = dense (max ~800 kcal/portion)
    vector[3] = min(1.0, cal / 800.0)

    # Densité fibre [4] — 0 = pauvre, 1 = riche (max ~15g)
    vector[4] = min(1.0, fiber / 15.0)

    # Indice de satiété estimé [5] — plus de protéines + fibres = plus satiétant
    if cal > 0:
        satiety = (prot * 4 + fiber * 2) / cal
        vector[5] = min(1.0, satiety)

    # ---- [10:20] METADATA (10D) ----
    prep = recipe.get("prep_time_min") or 0
    cook = recipe.get("cook_time_min") or 0
    total_time = prep + cook

    # Temps total normalisé [10] — max 120 min
    vector[10] = min(1.0, total_time / 120.0)

    # Difficulté [11]
    vector[11] = DIFFICULTY_MAP.get(recipe.get("difficulty", "medium"), 0.5)

    # Région culinaire [12] — one-hot index normalisé
    region_idx = REGION_MAP.get(recipe.get("region", ""), -1)
    if region_idx >= 0:
        vector[12] = (region_idx + 1) / len(REGION_MAP)

    # Âge de la recette [13] — nouvelles recettes = boost
    created_at = recipe.get("created_at")
    if created_at:
        if isinstance(created_at, str):
            created_at = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
        age_days = (datetime.now(created_at.tzinfo) - created_at).days
        # Récente (< 7j) = 1.0, ancienne (> 365j) = 0.0
        vector[13] = max(0.0, 1.0 - age_days / 365.0)

    # ---- [20:40] OUTCOMES (20D) ----
    total_consumptions = stats.get("total_consumptions") or 0
    unique_users = stats.get("unique_users") or 0

    # Popularité (log scale) [20] — max ~1000 consommations
    vector[20] = min(1.0, np.log1p(total_consumptions) / np.log1p(1000))

    # Reach (utilisateurs uniques) [21]
    vector[21] = min(1.0, np.log1p(unique_users) / np.log1p(500))

    # Repeat rate [22] — si beaucoup de consommations par user
    if unique_users > 0:
        repeat_rate = total_consumptions / unique_users
        vector[22] = min(1.0, repeat_rate / 5.0)  # max 5 consommations par user

    # ---- [40:50] CREATOR SIGNALS (10D) ----
    creator_recipe_count = recipe.get("creator_recipe_count") or 0

    # Expérience du créateur [40] — normalisé sur 100 recettes
    vector[40] = min(1.0, creator_recipe_count / 100.0)

    # Éligibilité Fan [41] — booste légèrement les créateurs Fan-eligible
    vector[41] = 1.0 if creator_recipe_count >= 30 else 0.0

    return _normalize_l2(vector)
