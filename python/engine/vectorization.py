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
import logging
import numpy as np

from .database import (
    get_user_health_profile,
    get_latest_beauty_log,
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
DIM_HAIR_TEXTURE          = 27  # Spectrum 0.10 (1A) to 1.00 (4C)
DIM_POROSITY              = 28  # Spectrum 0.20 (Low) to 1.00 (High)
DIM_SCALP_TYPE            = 29  # Spectrum 0.10 (Dry) to 1.00 (Flaky)
DIM_SKIN_TYPE             = 30  # Spectrum 0.10 (Dry) to 1.00 (Acne)

# Hair Care Goals & Virtues (31-39)
GOAL_HAIR_GROWTH          = 31  # Length retention & follicle stimulation
GOAL_HAIR_ANTI_BREAKAGE   = 32  # Strengthening & anti-breakage
GOAL_HAIR_MOISTURE        = 33  # Deep hydration & elasticity
GOAL_SCALP_SOOTHING       = 34  # Anti-itch & dandruff relief
GOAL_CURL_DEFINITION      = 35  # Anti-frizz & curl shaping
GOAL_PROTECTIVE_STYLE     = 36  # Braids, locs & edge care
GOAL_HAIR_VOLUME          = 37  # Density & body
GOAL_HAIR_SHINE           = 38  # Cuticle smoothing & luster
GOAL_SCALP_DETOX          = 39  # Clarifying & buildup removal

# Skin Care Goals & Virtues (40-48)
GOAL_SKIN_GLOW            = 40  # Radiance & anti-dullness
GOAL_SKIN_BARRIER         = 41  # Lipid repair & deep moisture
GOAL_SKIN_SEBUM_ACNE      = 42  # Matrifying & blemish control
GOAL_SKIN_SOOTHING        = 43  # Calming reactive skin
GOAL_SKIN_ANTI_DARK_SPOTS = 44  # Hyperpigmentation & even tone
GOAL_SKIN_ANTI_AGING      = 45  # Firming & elasticity
GOAL_SKIN_EXFOLIATION     = 46  # Smooth texture & dead skin removal
GOAL_BODY_NUTRITION       = 47  # Body butter moisture & firming
GOAL_SUN_PROTECTION       = 48  # Antioxidant defense

VIRTUE_TO_DIM_MAP = {
    # Hair Virtues
    "growth_retention": GOAL_HAIR_GROWTH,
    "growth": GOAL_HAIR_GROWTH,
    "anti_breakage": GOAL_HAIR_ANTI_BREAKAGE,
    "intense_hydration": GOAL_HAIR_MOISTURE,
    "moisture": GOAL_HAIR_MOISTURE,
    "scalp_soothing": GOAL_SCALP_SOOTHING,
    "curl_definition": GOAL_CURL_DEFINITION,
    "protective_care": GOAL_PROTECTIVE_STYLE,
    "protective_style": GOAL_PROTECTIVE_STYLE,
    "volume_thickness": GOAL_HAIR_VOLUME,
    "shine_softness": GOAL_HAIR_SHINE,
    "scalp_detox": GOAL_SCALP_DETOX,
    "anti_dandruff": GOAL_SCALP_SOOTHING,

    # Skin Virtues
    "glow_brightening": GOAL_SKIN_GLOW,
    "glow": GOAL_SKIN_GLOW,
    "moisture_barrier": GOAL_SKIN_BARRIER,
    "dry_skin_moisture": GOAL_SKIN_BARRIER,
    "barrier_repair": GOAL_SKIN_BARRIER,
    "sebum_balance": GOAL_SKIN_SEBUM_ACNE,
    "sebum_acne_control": GOAL_SKIN_SEBUM_ACNE,
    "oily_acne_sebum": GOAL_SKIN_SEBUM_ACNE,
    "sensitive_soothing": GOAL_SKIN_SOOTHING,
    "sensitive_skin_soothing": GOAL_SKIN_SOOTHING,
    "anti_dark_spots": GOAL_SKIN_ANTI_DARK_SPOTS,
    "brightening_anti_spots": GOAL_SKIN_ANTI_DARK_SPOTS,
    "anti_aging_elasticity": GOAL_SKIN_ANTI_AGING,
    "anti_aging": GOAL_SKIN_ANTI_AGING,
    "exfoliation_smoothing": GOAL_SKIN_EXFOLIATION,
    "body_nourishing": GOAL_BODY_NUTRITION,
    "antioxidant_defense": GOAL_SUN_PROTECTION,
}

# Continuous Spectrum Encodings (0.0 to 1.0)
HAIR_TYPE_SPECTRUM = {
    "1A": 0.10, "1B": 0.10, "1C": 0.15,
    "2A": 0.25, "2B": 0.30, "2C": 0.40,
    "3A": 0.50, "3B": 0.60, "3C": 0.70,
    "4A": 0.80, "4B": 0.90, "4C": 1.00,
    "1": 0.10, "2": 0.30, "3": 0.60, "4": 0.90,
    "LOCKS": 0.85,
    "TRANSITION": 0.55,
    "PROTECTIVE": 0.85,
}

POROSITY_SPECTRUM = {
    "low": 0.20,
    "medium": 0.50,
    "normal": 0.50,
    "high": 1.00,
}

SKIN_TYPE_SPECTRUM = {
    "dry": 0.10,
    "normal": 0.50,
    "combination": 0.50,
    "oily": 0.90,
    "acne": 1.00,
}

SCALP_TYPE_SPECTRUM = {
    "dry": 0.10,
    "normal": 0.50,
    "oily": 0.90,
    "flaky": 1.00,
    "dandruff": 1.00,
}

# Attribute dims (inherent physical traits) — always amplified 2x; not a "goal" choice.
AMPLIFIED_ATTRIBUTE_DIMS = (DIM_HAIR_TEXTURE, DIM_POROSITY, DIM_SKIN_TYPE)

# Goal/virtue dims amplified 2x — currently 6 of the 18 total goal/virtue dims (31-48).
# Expanding to the other 12 is a product decision, deliberately NOT made here (Finding #7).
AMPLIFIED_GOAL_DIMS = (
    GOAL_HAIR_GROWTH, GOAL_HAIR_ANTI_BREAKAGE, GOAL_HAIR_MOISTURE,
    GOAL_SKIN_GLOW, GOAL_SKIN_BARRIER, GOAL_SKIN_SEBUM_ACNE,
)

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
        # ---- Inherent Attributes (27-30) ----
        hair_type = str(profile.get("hair_type") or "4C").upper()
        if hair_type not in HAIR_TYPE_SPECTRUM:
            logging.getLogger("vectorization").warning(f"User {user_id}: hair_type '{hair_type}' not in HAIR_TYPE_SPECTRUM. Defaulting to 0.90")
            vector[DIM_HAIR_TEXTURE] = 0.90
        else:
            vector[DIM_HAIR_TEXTURE] = HAIR_TYPE_SPECTRUM[hair_type]

        porosity = str(profile.get("porosity") or "medium").lower()
        vector[DIM_POROSITY] = POROSITY_SPECTRUM.get(porosity, 1.0)

        scalp_type = str(profile.get("scalp_type") or "normal").lower()
        vector[DIM_SCALP_TYPE] = SCALP_TYPE_SPECTRUM.get(scalp_type, 0.50)

        skin_type = str(profile.get("skin_type") or "combination").lower()
        vector[DIM_SKIN_TYPE] = SKIN_TYPE_SPECTRUM.get(skin_type, 0.90)

        if profile.get("sensitive_scalp"):
            vector[GOAL_SCALP_SOOTHING] = 1.0

        # ---- User Beauty Goals (31-48) ----
        beauty_goals = set(profile.get("beauty_goals") or [])
        if "growth" in beauty_goals or "growth_retention" in beauty_goals:
            vector[GOAL_HAIR_GROWTH] = 1.0
        if "anti_breakage" in beauty_goals:
            vector[GOAL_HAIR_ANTI_BREAKAGE] = 1.0
        if "moisture" in beauty_goals or "hydration" in beauty_goals:
            vector[GOAL_HAIR_MOISTURE] = 1.0
        if "curl_definition" in beauty_goals:
            vector[GOAL_CURL_DEFINITION] = 1.0
        if "protective_style" in beauty_goals:
            vector[GOAL_PROTECTIVE_STYLE] = 1.0
        if "volume" in beauty_goals:
            vector[GOAL_HAIR_VOLUME] = 1.0

        if "glow" in beauty_goals or "radiance" in beauty_goals:
            vector[GOAL_SKIN_GLOW] = 1.0
        if "anti_dark_spots" in beauty_goals or "brightening" in beauty_goals:
            vector[GOAL_SKIN_ANTI_DARK_SPOTS] = 1.0
        if "sebum_control" in beauty_goals or "acne_control" in beauty_goals:
            vector[GOAL_SKIN_SEBUM_ACNE] = 1.0
        if "barrier_repair" in beauty_goals:
            vector[GOAL_SKIN_BARRIER] = 1.0
        if "anti_aging" in beauty_goals:
            vector[GOAL_SKIN_ANTI_AGING] = 1.0

        # ---- Dynamic Measured Check-in Metrics (from latest beauty_log) ----
        try:
            latest_log = get_latest_beauty_log(user_id)
            if latest_log:
                # Low hair strength (< 5.0) dynamic priority boost for anti-breakage
                strength = latest_log.get("hair_strength_score")
                if strength is not None and float(strength) < 5.0:
                    vector[GOAL_HAIR_ANTI_BREAKAGE] = max(vector[GOAL_HAIR_ANTI_BREAKAGE], 1.0)

                # Low skin hydration (< 5.0) boost for barrier repair
                hydration = latest_log.get("skin_hydration_level")
                if hydration is not None and float(hydration) < 5.0:
                    vector[GOAL_SKIN_BARRIER] = max(vector[GOAL_SKIN_BARRIER], 1.0)

                # High shedding rate boost for growth & anti-breakage
                shedding = str(latest_log.get("hair_shedding_rate") or "").lower()
                if shedding in ("high", "excessive"):
                    vector[GOAL_HAIR_GROWTH] = max(vector[GOAL_HAIR_GROWTH], 1.0)
                    vector[GOAL_HAIR_ANTI_BREAKAGE] = max(vector[GOAL_HAIR_ANTI_BREAKAGE], 1.0)

                # Scalp health score boost
                scalp_health = latest_log.get("scalp_health_score")
                if scalp_health is not None and float(scalp_health) < 5.0:
                    vector[GOAL_SCALP_SOOTHING] = max(vector[GOAL_SCALP_SOOTHING], 1.0)
        except Exception as e:
            logging.warning(
                f"get_latest_beauty_log check-in boost skipped for user_id={user_id}: {e}"
            )

        # Goal weight amplification
        for dim in AMPLIFIED_ATTRIBUTE_DIMS + AMPLIFIED_GOAL_DIMS:
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

def compute_recipe_vector(recipe_id: str, mode: str = "nutrition", active_goals: Optional[set] = None) -> Optional[np.ndarray]:
    recipe = get_recipe_data(recipe_id)
    if not recipe:
        return None

    stats = get_recipe_consumption_stats(recipe_id, days=30)
    vector = np.zeros(VECTOR_DIM, dtype=np.float32)

    if mode == "beauty" or recipe.get("mode") == "beauty":
        # ---- Inherent Attributes (27-30) ----
        suitable_hair = str(recipe.get("suitable_hair_type") or "4C").upper()
        if suitable_hair not in HAIR_TYPE_SPECTRUM:
            logging.getLogger("vectorization").warning(f"Recipe {recipe_id}: suitable_hair_type '{suitable_hair}' not in HAIR_TYPE_SPECTRUM. Defaulting to 0.85")
            vector[DIM_HAIR_TEXTURE] = 0.85
        else:
            vector[DIM_HAIR_TEXTURE] = HAIR_TYPE_SPECTRUM[suitable_hair]

        formulation = str(recipe.get("formulation") or "").lower()
        if formulation == "heavy_butter":
            vector[DIM_POROSITY] = 1.0
        elif formulation == "light_oil":
            vector[DIM_POROSITY] = 0.20
        else:
            vector[DIM_POROSITY] = 0.50

        skin_target = str(recipe.get("skin_target") or "").lower()
        vector[DIM_SKIN_TYPE] = SKIN_TYPE_SPECTRUM.get(skin_target, 0.50)

        scalp_target = str(recipe.get("scalp_target") or "").lower()
        if scalp_target in ("flaky", "dandruff"):
            vector[DIM_SCALP_TYPE] = 1.00
        elif scalp_target == "oily":
            vector[DIM_SCALP_TYPE] = 0.90
        elif scalp_target == "dry":
            vector[DIM_SCALP_TYPE] = 0.10
        else:
            vector[DIM_SCALP_TYPE] = 0.50

        # ---- Remedy Continuous Virtue Weight Vectors (31-48) ----
        is_premade = bool(recipe.get("is_premade_product")) or str(recipe.get("product_type")).lower() in ("artisanal", "industrial")
        recipe_virtue_weights = recipe.get("virtue_weights") or {}

        if is_premade and isinstance(recipe_virtue_weights, dict) and recipe_virtue_weights:
            # 1. ALREADY-MADE PRODUCTS (Artisanal / Industrial): Use creator's explicit intended virtue vector directly
            for virtue_key, weight in recipe_virtue_weights.items():
                dim_idx = VIRTUE_TO_DIM_MAP.get(virtue_key)
                if dim_idx is not None:
                    vector[dim_idx] = float(weight)
        else:
            # 2. DIY / HOMEMADE RECIPES: Compute dynamically from constituent ingredients (plus explicit overrides)
            if isinstance(recipe_virtue_weights, dict):
                for virtue_key, weight in recipe_virtue_weights.items():
                    dim_idx = VIRTUE_TO_DIM_MAP.get(virtue_key)
                    if dim_idx is not None:
                        vector[dim_idx] = max(vector[dim_idx], float(weight))

            virtues = set(recipe.get("virtues") or [])
            tags = set(recipe.get("tags") or []).union(virtues)

            if "growth" in tags or "growth_retention" in tags:
                vector[GOAL_HAIR_GROWTH] = max(vector[GOAL_HAIR_GROWTH], 1.0)
            if "anti_breakage" in tags:
                vector[GOAL_HAIR_ANTI_BREAKAGE] = max(vector[GOAL_HAIR_ANTI_BREAKAGE], 1.0)
            if "intense_hydration" in virtues or "moisture" in tags:
                vector[GOAL_HAIR_MOISTURE] = max(vector[GOAL_HAIR_MOISTURE], 1.0)
                vector[GOAL_SKIN_BARRIER] = max(vector[GOAL_SKIN_BARRIER], 0.8)
            if "scalp_soothing" in virtues:
                vector[GOAL_SCALP_SOOTHING] = max(vector[GOAL_SCALP_SOOTHING], 1.0)
                vector[GOAL_SKIN_SOOTHING] = max(vector[GOAL_SKIN_SOOTHING], 0.9)
            if "curl_definition" in tags:
                vector[GOAL_CURL_DEFINITION] = max(vector[GOAL_CURL_DEFINITION], 1.0)
            if "protective_style" in tags or "protective_care" in tags:
                vector[GOAL_PROTECTIVE_STYLE] = max(vector[GOAL_PROTECTIVE_STYLE], 1.0)
            if "glow" in tags or "glow_brightening" in tags:
                vector[GOAL_SKIN_GLOW] = max(vector[GOAL_SKIN_GLOW], 1.0)
            if "sebum_balance" in virtues:
                vector[GOAL_SKIN_SEBUM_ACNE] = max(vector[GOAL_SKIN_SEBUM_ACNE], 1.0)

            # Dynamically accumulate continuous virtue weight vectors from all constituent ingredients
            ingredient_details = recipe.get("ingredient_details") or []
            for detail in ingredient_details:
                weights = detail.get("virtue_weights") or {}
                if isinstance(weights, dict):
                    for virtue_key, weight in weights.items():
                        dim_idx = VIRTUE_TO_DIM_MAP.get(virtue_key)
                        if dim_idx is not None:
                            vector[dim_idx] = max(vector[dim_idx], float(weight))

                skin_weights = detail.get("skin_virtue_weights") or {}
                if isinstance(skin_weights, dict):
                    for virtue_key, weight in skin_weights.items():
                        dim_idx = VIRTUE_TO_DIM_MAP.get(virtue_key)
                        if dim_idx is not None:
                            vector[dim_idx] = max(vector[dim_idx], float(weight))

        # ---- Hybrid Selective Virtue Masking ----
        # Dims 27-30 (Hair Texture, Porosity, Scalp & Skin Type) are ALWAYS PRESERVED.
        # Dims 31-48 (Virtues/Goals) are masked: zeroed out if NOT in active_goals.
        if active_goals is not None:
            active_dim_indices = set()
            for goal in active_goals:
                dim_idx = VIRTUE_TO_DIM_MAP.get(goal)
                if dim_idx is not None:
                    active_dim_indices.add(dim_idx)

            for goal_dim in range(31, 49):
                if goal_dim not in active_dim_indices:
                    vector[goal_dim] = 0.0

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
