"""
Vectorisation 50D — user_vector et recipe_vector
Ref: V1_VECTORIZATION_MEAL_PLANNER.md + PYTHON_RECOMMENDATION_ENGINE.md

Shared semantic space: dimension i means the SAME thing in both vectors.
  User value  = "how much the user wants/prefers this"
  Recipe value = "how much this recipe provides/is this"
  Cosine similarity = genuine preference-property alignment.

Dimensions:
  [0]     Protein intensity    — user: goal-driven desire; recipe: protein ratio
  [1]     Low-calorie          — user: weight_loss goal;   recipe: 1 - cal_density
  [2]     High-fiber / satiety — user: weight_loss goal;   recipe: fiber_density
  [3]     Satiety index        — user: weight_loss goal;   recipe: (prot*4+fiber*2)/cal
  [4]     Carb-rich            — user: muscle_gain goal;   recipe: carb ratio
  [5]     Caloric surplus      — user: muscle_gain goal;   recipe: cal_density
  [6]     Quick meal           — user: 1-activity_level;   recipe: 1 - time_normalized
  [7]     Difficulty match     — user: activity_level;     recipe: difficulty_normalized
  [8]     Recipe freshness     — user: neutral 0.5;        recipe: recency score
  [9]     Popularity           — user: neutral 0.5;        recipe: log-popularity
  [10-22] Cuisine regions (13D one-hot, SAME mapping both vectors)
  [23]    Vegetarian/vegan     — user: flag; recipe: 1 if suitable
  [24]    Halal                — user: flag; recipe: 1 if suitable
  [25]    Creator quality      — user: neutral 0.5;        recipe: creator_experience
  [26]    Fan-eligible creator — user: neutral 0.3;        recipe: 1 if fan_eligible
  [27-49] Reserved (zeros)
"""

from __future__ import annotations
from datetime import datetime
from typing import Optional
import numpy as np

from .database import (
    get_user_health_profile,
    get_recipe_data,
    get_recipe_consumption_stats,
    get_creator_recipe_vectors,   # new
)

VECTOR_DIM = 50

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
    "west_africa":    0,
    "central_africa": 1,
    "east_africa":    2,
    "north_africa":   3,
    "south_africa":   4,
    "caribbean":      5,
    "france":         6,
    "mediterranean":  7,
    "middle_east":    8,
    "south_asia":     9,
    "southeast_asia": 10,
    "latin_america":  11,
    "north_america":  12,
}

DIFFICULTY_MAP = {"easy": 0.25, "medium": 0.6, "hard": 1.0}

# Dim offsets — Nutrition (0-26)
DIM_PROTEIN      = 0
DIM_LOW_CAL      = 1
DIM_FIBER        = 2
DIM_SATIETY      = 3
DIM_CARB         = 4
DIM_CAL_SURPLUS  = 5
DIM_QUICK_MEAL   = 6
DIM_DIFFICULTY   = 7
DIM_FRESHNESS    = 8
DIM_POPULARITY   = 9
DIM_REGIONS      = 10   # 10..22 (13 dims)
DIM_VEGETARIAN   = 23
DIM_HALAL        = 24
DIM_CREATOR_Q    = 25
DIM_FAN_ELIGIBLE = 26

# Dim offsets — Beauty & Care (27-49)
DIM_TYPE4_HAIR       = 27
DIM_HIGH_POROSITY    = 28
DIM_LOW_POROSITY     = 29
DIM_OILY_ACNE_SKIN   = 30
DIM_DRY_SKIN         = 31
DIM_SENSITIVE_SCALP  = 32
DIM_HAIR_GROWTH      = 33
DIM_SKIN_GLOW        = 34
DIM_PROTECTIVE_STYLE = 35
DIM_BEAUTY_ACTIVES   = 36   # 36..44 (9 dims)

BEAUTY_ACTIVES_MAP = {
    "shea_butter": 0,  # Karité
    "aloe_vera":   1,  # Aloé Véra
    "chebe":       2,  # Chébé
    "black_seed":  3,  # Nigelle
    "argan":       4,  # Argan
    "ricin":       5,  # Castor / Ricin
    "hibiscus":    6,  # Hibiscus / Karkadé
    "clay":        7,  # Argile
    "jojoba":      8,  # Jojoba
}


def _normalize_l2(v: np.ndarray) -> np.ndarray:
    norm = np.linalg.norm(v)
    return v / norm if norm > 1e-10 else v


# ---------------------------------------------------------------------------
# USER VECTOR
# ---------------------------------------------------------------------------

def _infer_goals_from_profile(profile: dict) -> set:
    """Derive goal types from health metrics when explicit goals are absent."""
    goals = set()
    weight_goal = profile.get("weight_goal")
    muscle_goal = profile.get("muscle_goal")
    if weight_goal == "loss":
        goals.add("weight_loss")
    elif weight_goal == "gain":
        goals.add("muscle_gain")
    elif weight_goal == "maintenance":
        goals.add("maintenance")
    if muscle_goal == "gain":
        goals.add("muscle_gain")
    elif muscle_goal == "loss":
        goals.add("weight_loss")
    elif muscle_goal == "maintenance":
        goals.add("maintenance")
    # Fall back to weight delta when new fields are absent (legacy profiles)
    if not goals:
        weight = profile.get("weight_kg")
        target = profile.get("target_weight_kg")
        if weight is not None and target is not None:
            delta = float(target) - float(weight)
            if delta < -2:
                goals.add("weight_loss")
            elif delta > 2:
                goals.add("muscle_gain")
            else:
                goals.add("maintenance")
    goals.add("health")
    return goals


def compute_user_vector(user_id: str, mode: str = "nutrition") -> Optional[np.ndarray]:
    profile = get_user_health_profile(user_id)
    if not profile:
        return None

    vector = np.zeros(VECTOR_DIM, dtype=np.float32)

    if mode == "beauty":
        # ---- Beauty Dimensions (27-44) ----
        hair_type = profile.get("hair_type") or "4C"
        if "4" in str(hair_type):
            vector[DIM_TYPE4_HAIR] = 1.0

        porosity = profile.get("porosity")
        if porosity == "high":
            vector[DIM_HIGH_POROSITY] = 1.0
        elif porosity == "low":
            vector[DIM_LOW_POROSITY] = 1.0

        skin_type = profile.get("skin_type")
        if skin_type in ("oily", "acne"):
            vector[DIM_OILY_ACNE_SKIN] = 1.0
        elif skin_type == "dry":
            vector[DIM_DRY_SKIN] = 1.0

        if profile.get("sensitive_scalp"):
            vector[DIM_SENSITIVE_SCALP] = 1.0

        beauty_goals = set(profile.get("beauty_goals") or [])
        if "growth" in beauty_goals or "anti_breakage" in beauty_goals:
            vector[DIM_HAIR_GROWTH] = 1.0
        if "glow" in beauty_goals or "anti_dark_spots" in beauty_goals:
            vector[DIM_SKIN_GLOW] = 1.0
        if "protective_style" in beauty_goals:
            vector[DIM_PROTECTIVE_STYLE] = 1.0

        preferred_actives = profile.get("preferred_actives") or []
        for active in preferred_actives:
            idx = BEAUTY_ACTIVES_MAP.get(active)
            if idx is not None:
                vector[DIM_BEAUTY_ACTIVES + idx] = 1.0

        for dim in (DIM_TYPE4_HAIR, DIM_HIGH_POROSITY, DIM_LOW_POROSITY,
                    DIM_OILY_ACNE_SKIN, DIM_DRY_SKIN, DIM_HAIR_GROWTH, DIM_SKIN_GLOW):
            vector[dim] *= 2.0

        return _normalize_l2(vector)

    explicit_goals = set(g for g in (profile.get("goals") or []) if g)
    goals = explicit_goals if explicit_goals else _infer_goals_from_profile(profile)
    activity = ACTIVITY_MAP.get(profile.get("activity_level", "moderate"), 0.5)

    # ---- Nutritional preferences derived from goals ----
    if "weight_loss" in goals:
        vector[DIM_PROTEIN]     = 1.0   # high protein for satiety/muscle preservation
        vector[DIM_LOW_CAL]     = 1.0   # lower calorie density
        vector[DIM_FIBER]       = 0.8   # fiber for satiety
        vector[DIM_SATIETY]     = 1.0
    if "muscle_gain" in goals:
        vector[DIM_PROTEIN]     = max(vector[DIM_PROTEIN], 1.0)
        vector[DIM_CARB]        = 0.8   # carbs for energy/training
        vector[DIM_CAL_SURPLUS] = 0.7   # caloric surplus needed
    if "maintenance" in goals:
        vector[DIM_PROTEIN]     = max(vector[DIM_PROTEIN], 0.5)
        vector[DIM_LOW_CAL]     = max(vector[DIM_LOW_CAL], 0.5)
    if "health" in goals:
        vector[DIM_FIBER]       = max(vector[DIM_FIBER], 0.7)
        vector[DIM_SATIETY]     = max(vector[DIM_SATIETY], 0.5)
    if "performance" in goals:
        vector[DIM_PROTEIN]     = max(vector[DIM_PROTEIN], 0.8)
        vector[DIM_CARB]        = max(vector[DIM_CARB], 0.7)

    # ---- Time/difficulty preference ----
    cooking_time = profile.get("cooking_time")
    if cooking_time == "quick":
        vector[DIM_QUICK_MEAL] = 0.9
    elif cooking_time == "medium":
        vector[DIM_QUICK_MEAL] = 0.5
    elif cooking_time == "any":
        vector[DIM_QUICK_MEAL] = 0.3
    else:
        # Legacy profiles without cooking_time: derive from activity level
        vector[DIM_QUICK_MEAL] = 1.0 - activity
    vector[DIM_DIFFICULTY]  = activity

    # ---- Neutral signals (user has no strong preference) ----
    vector[DIM_FRESHNESS]   = 0.5
    vector[DIM_POPULARITY]  = 0.5
    vector[DIM_CREATOR_Q]   = 0.5
    vector[DIM_FAN_ELIGIBLE] = 0.3

    # ---- Cuisine regions (one-hot, same mapping as recipe) ----
    regions = profile.get("cuisine_regions") or []
    for region in regions[:5]:
        idx = REGION_MAP.get(region)
        if idx is not None:
            vector[DIM_REGIONS + idx] = 1.0

    # ---- Dietary restrictions ----
    restrictions = profile.get("restrictions") or []
    if "vegetarian" in restrictions or "vegan" in restrictions:
        vector[DIM_VEGETARIAN] = 1.0
    if "halal" in restrictions:
        vector[DIM_HALAL] = 1.0

    # ---- Goal dims carry 2× weight vs preference dims ----
    # After L2 normalization, equal-magnitude dims have equal pull in the dot
    # product. Goals (why you eat) should dominate over preferences (what you
    # like), so we amplify goal-driven dims before normalizing.
    for dim in (DIM_PROTEIN, DIM_LOW_CAL, DIM_FIBER, DIM_SATIETY,
                DIM_CARB, DIM_CAL_SURPLUS):
        vector[dim] *= 2.0

    return _normalize_l2(vector)


# ---------------------------------------------------------------------------
# RECIPE VECTOR
# ---------------------------------------------------------------------------

def compute_recipe_vector(recipe_id: str, mode: str = "nutrition") -> Optional[np.ndarray]:
    recipe = get_recipe_data(recipe_id)
    if not recipe:
        return None

    stats = get_recipe_consumption_stats(recipe_id, days=30)
    vector = np.zeros(VECTOR_DIM, dtype=np.float32)

    if mode == "beauty" or recipe.get("mode") == "beauty":
        # ---- Beauty Recipe Dimensions (27-44) ----
        if recipe.get("suitable_hair_type") == "4" or "4" in str(recipe.get("tags") or []):
            vector[DIM_TYPE4_HAIR] = 1.0

        if recipe.get("formulation") == "heavy_butter":
            vector[DIM_HIGH_POROSITY] = 1.0
        elif recipe.get("formulation") == "light_oil":
            vector[DIM_LOW_POROSITY] = 1.0

        if recipe.get("skin_target") in ("oily", "acne"):
            vector[DIM_OILY_ACNE_SKIN] = 1.0
        elif recipe.get("skin_target") == "dry":
            vector[DIM_DRY_SKIN] = 1.0

        if recipe.get("scalp_soothing"):
            vector[DIM_SENSITIVE_SCALP] = 1.0

        virtues = set(recipe.get("virtues") or [])
        tags = set(recipe.get("tags") or []).union(virtues)

        if "growth" in tags or "growth_retention" in tags or "anti_breakage" in tags:
            vector[DIM_HAIR_GROWTH] = max(vector[DIM_HAIR_GROWTH], 1.0)
        if "glow" in tags or "glow_brightening" in tags or "anti_dark_spots" in tags:
            vector[DIM_SKIN_GLOW] = max(vector[DIM_SKIN_GLOW], 1.0)
        if "protective_style" in tags or "protective_care" in tags:
            vector[DIM_PROTECTIVE_STYLE] = max(vector[DIM_PROTECTIVE_STYLE], 1.0)
        if "scalp_soothing" in virtues:
            vector[DIM_SENSITIVE_SCALP] = max(vector[DIM_SENSITIVE_SCALP], 1.0)
        if "sebum_balance" in virtues:
            vector[DIM_OILY_ACNE_SKIN] = max(vector[DIM_OILY_ACNE_SKIN], 1.0)
        if "intense_hydration" in virtues:
            vector[DIM_DRY_SKIN] = max(vector[DIM_DRY_SKIN], 0.8)

        # Accumulate continuous virtue weight vectors from ingredients
        ingredient_details = recipe.get("ingredient_details") or []
        for detail in ingredient_details:
            weights = detail.get("virtue_weights") or {}
            if weights:
                vector[DIM_HAIR_GROWTH] = max(vector[DIM_HAIR_GROWTH], float(weights.get("growth_retention", 0.0)), float(weights.get("anti_breakage", 0.0)))
                vector[DIM_SKIN_GLOW] = max(vector[DIM_SKIN_GLOW], float(weights.get("glow_brightening", 0.0)))
                vector[DIM_PROTECTIVE_STYLE] = max(vector[DIM_PROTECTIVE_STYLE], float(weights.get("protective_care", 0.0)))
                vector[DIM_SENSITIVE_SCALP] = max(vector[DIM_SENSITIVE_SCALP], float(weights.get("scalp_soothing", 0.0)))
                vector[DIM_OILY_ACNE_SKIN] = max(vector[DIM_OILY_ACNE_SKIN], float(weights.get("sebum_balance", 0.0)))
                vector[DIM_DRY_SKIN] = max(vector[DIM_DRY_SKIN], float(weights.get("moisture", 0.0)))

        ingredients = recipe.get("ingredients") or []
        for ing in ingredients:
            ing_code = str(ing).lower()
            for active_key, idx in BEAUTY_ACTIVES_MAP.items():
                if active_key in ing_code:
                    vector[DIM_BEAUTY_ACTIVES + idx] = 1.0

        return _normalize_l2(vector)

    # All values are already per-serving (divided in get_recipe_data query)
    cal   = float(recipe.get("calories")  or 0)
    prot  = float(recipe.get("protein_g") or 0)
    carbs = float(recipe.get("carbs_g")   or 0)
    fiber = float(recipe.get("fiber_g")   or 0)

    # Calorie-based macro percentages (standard nutrition metric):
    # fat=9 kcal/g, protein=carbs=4 kcal/g — gram ratios misrepresent fat contribution
    prot_kcal  = prot  * 4
    carbs_kcal = carbs * 4

    if cal > 0:
        vector[DIM_PROTEIN] = min(1.0, prot_kcal  / cal)   # % calories from protein
        vector[DIM_CARB]    = min(1.0, carbs_kcal / cal)   # % calories from carbs

    # Caloric density cap at 800 kcal/serving (p90 for Akeli recipes is ~420,
    # outliers above 800 are full-meal traditional dishes — cap is intentional)
    cal_density = min(1.0, cal / 800.0)
    vector[DIM_LOW_CAL]     = 1.0 - cal_density
    vector[DIM_CAL_SURPLUS] = cal_density

    # Fiber: currently NULL for all recipes in DB — dimension reserved for future data
    vector[DIM_FIBER] = min(1.0, fiber / 15.0) if fiber > 0 else 0.0

    # Satiety: protein-kcal fraction (fiber term is 0 until data exists)
    if cal > 0:
        vector[DIM_SATIETY] = min(1.0, (prot_kcal + fiber * 2) / cal)

    # ---- Time / difficulty ----
    prep = recipe.get("prep_time_min") or 0
    cook = recipe.get("cook_time_min") or 0
    total_time = prep + cook
    vector[DIM_QUICK_MEAL]  = 1.0 - min(1.0, total_time / 120.0)  # quick = 1.0
    vector[DIM_DIFFICULTY]  = DIFFICULTY_MAP.get(recipe.get("difficulty", "medium"), 0.5)

    # ---- Freshness ----
    created_at = recipe.get("created_at")
    if created_at:
        if isinstance(created_at, str):
            created_at = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
        age_days = (datetime.now(created_at.tzinfo) - created_at).days
        vector[DIM_FRESHNESS] = max(0.0, 1.0 - age_days / 365.0)

    # ---- Popularity ----
    total_consumptions = stats.get("total_consumptions") or 0
    vector[DIM_POPULARITY] = min(1.0, np.log1p(total_consumptions) / np.log1p(1000))

    # ---- Cuisine region (one-hot, same mapping as user) ----
    region_idx = REGION_MAP.get(recipe.get("region", ""), -1)
    if region_idx >= 0:
        vector[DIM_REGIONS + region_idx] = 1.0

    # ---- Creator signals ----
    creator_count = recipe.get("creator_recipe_count") or 0
    vector[DIM_CREATOR_Q]    = min(1.0, creator_count / 100.0)
    vector[DIM_FAN_ELIGIBLE] = 1.0 if creator_count >= 30 else 0.0

    return _normalize_l2(vector)


# ---------------------------------------------------------------------------
# CREATOR VECTOR
# ---------------------------------------------------------------------------

def compute_creator_vector(creator_id: str) -> Optional[np.ndarray]:
    """
    Compute the creator vector as the L2-normalized average of all
    published recipe vectors for this creator.

    Lives in the same 50D semantic space as user_vector and recipe_vector,
    so cosine similarity with user_vector is directly interpretable as
    creator-user alignment.

    Returns None if:
    - no published recipe vectors exist yet for this creator
    - the centroid has zero norm (degenerate case — all recipes all-zero)
    """
    recipe_vectors = get_creator_recipe_vectors(creator_id)
    if not recipe_vectors:
        return None

    # Stack into matrix and compute unweighted mean — shape (50,)
    matrix = np.stack(recipe_vectors, axis=0)                  # (N, 50)
    centroid = np.mean(matrix, axis=0).astype(np.float32)      # (50,)

    norm = np.linalg.norm(centroid)
    if norm <= 1e-10:
        return None

    return (centroid / norm).astype(np.float32)
