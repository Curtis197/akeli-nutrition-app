import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime, timedelta
import numpy as np
import logging

from engine.vectorization import (
    compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM,
    DIM_HAIR_TEXTURE, DIM_SCALP_TYPE, DIM_POROSITY, DIM_SKIN_TYPE,
    HAIR_TYPE_SPECTRUM, SCALP_TYPE_SPECTRUM, POROSITY_SPECTRUM, SKIN_TYPE_SPECTRUM,
    GOAL_HAIR_GROWTH, GOAL_HAIR_ANTI_BREAKAGE, GOAL_HAIR_MOISTURE, GOAL_HAIR_SHINE,
    GOAL_SKIN_GLOW, GOAL_SKIN_BARRIER, GOAL_SKIN_SEBUM_ACNE,
)


def _expected_normalized(raw: dict) -> np.ndarray:
    """Build the expected user-side 50D vector from {dim_index: raw_value},
    applying the SAME 2x amplification compute_user_vector applies to
    DIM_HAIR_TEXTURE, DIM_POROSITY, DIM_SKIN_TYPE, GOAL_HAIR_GROWTH,
    GOAL_HAIR_ANTI_BREAKAGE, GOAL_HAIR_MOISTURE, GOAL_SKIN_GLOW,
    GOAL_SKIN_BARRIER, GOAL_SKIN_SEBUM_ACNE (vectorization.py "Goal weight
    amplification" block), then L2-normalizing. Uses only the documented
    spectrum constants and known amplification set, not the function under test.
    """
    amplified = {
        DIM_HAIR_TEXTURE, DIM_POROSITY, DIM_SKIN_TYPE,
        GOAL_HAIR_GROWTH, GOAL_HAIR_ANTI_BREAKAGE, GOAL_HAIR_MOISTURE,
        GOAL_SKIN_GLOW, GOAL_SKIN_BARRIER, GOAL_SKIN_SEBUM_ACNE,
    }
    vec = np.zeros(VECTOR_DIM, dtype=np.float64)
    for dim, value in raw.items():
        vec[dim] = value * 2.0 if dim in amplified else value
    norm = np.linalg.norm(vec)
    return vec / norm if norm > 1e-10 else vec


def _expected_normalized_recipe(raw: dict) -> np.ndarray:
    """Build the expected recipe-side 50D vector from {dim_index: raw_value}.
    Recipe vectors have NO amplification step."""
    vec = np.zeros(VECTOR_DIM, dtype=np.float64)
    for dim, value in raw.items():
        vec[dim] = value
    norm = np.linalg.norm(vec)
    return vec / norm if norm > 1e-10 else vec

@patch("engine.vectorization.get_user_health_profile")
def test_compute_user_vector_success(mock_get_profile):
    # Setup mock data for a valid user
    mock_get_profile.return_value = {
        "goals": ["weight_loss", "health"],
        "activity_level": "moderate",
        "weight_kg": 80.0,
        "target_weight_kg": 70.0,
        "cuisine_regions": ["mediterranean", "france"],
        "restrictions": ["vegetarian"]
    }

    # Execute
    vector = compute_user_vector("dummy_user_id")

    # Assert
    assert vector is not None
    assert isinstance(vector, np.ndarray)
    assert len(vector) == VECTOR_DIM

    # Check that magnitude is approximately 1 (L2 normalized)
    assert np.isclose(np.linalg.norm(vector), 1.0)

    # Note: We won't test exact values of every dimension to keep tests robust,
    # but we can check if it at least produces a non-zero vector.
    assert np.any(vector > 0.0)

@patch("engine.vectorization.get_latest_beauty_log")
@patch("engine.vectorization.get_user_health_profile")
def test_compute_beauty_user_vector(mock_get_profile, mock_get_log):
    mock_get_log.return_value = None
    mock_get_profile.return_value = {
        "hair_type": "4C",
        "porosity": "high",
        "skin_type": "dry",
        "beauty_goals": ["growth", "glow"],
        "preferred_actives": ["shea_butter", "aloe_vera"]
    }

    vector = compute_user_vector("beauty_user_id", mode="beauty")

    assert vector is not None
    assert isinstance(vector, np.ndarray)
    assert len(vector) == VECTOR_DIM
    assert np.isclose(np.linalg.norm(vector), 1.0)

    expected = _expected_normalized({
        DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4C"],       # 1.00
        DIM_POROSITY: POROSITY_SPECTRUM["high"],           # 1.00
        DIM_SCALP_TYPE: 0.50,   # no scalp_type in profile -> compute_user_vector's documented default
        DIM_SKIN_TYPE: SKIN_TYPE_SPECTRUM["dry"],          # 0.10
        GOAL_HAIR_GROWTH: 1.0,                               # "growth" in beauty_goals
        GOAL_SKIN_GLOW: 1.0,                                 # "glow" in beauty_goals
    })
    np.testing.assert_allclose(vector, expected, atol=1e-6)

@patch("engine.vectorization.get_user_health_profile")
def test_compute_user_vector_not_found(mock_get_profile):
    # Setup mock to simulate missing user profile
    mock_get_profile.return_value = None

    # Execute
    vector = compute_user_vector("missing_user")

    # Assert
    assert vector is None

@patch("engine.vectorization.get_recipe_consumption_stats")
@patch("engine.vectorization.get_recipe_data")
def test_compute_recipe_vector_success(mock_get_data, mock_get_stats):
    # Setup mock data for a valid recipe
    mock_get_data.return_value = {
        "calories": 400.0,
        "protein_g": 30.0,
        "carbs_g": 40.0,
        "fat_g": 10.0,
        "fiber_g": 8.0,
        "prep_time_min": 15,
        "cook_time_min": 20,
        "difficulty": "medium",
        "region": "mediterranean",
        "created_at": "2024-01-01T12:00:00Z",
        "creator_recipe_count": 5
    }
    mock_get_stats.return_value = {
        "total_consumptions": 100,
        "unique_users": 50,
        "avg_servings": 2.0
    }

    # Execute
    vector = compute_recipe_vector("dummy_recipe_id")

    # Assert
    assert vector is not None
    assert isinstance(vector, np.ndarray)
    assert len(vector) == VECTOR_DIM

    # Check normalization
    assert np.isclose(np.linalg.norm(vector), 1.0)
    assert np.any(vector > 0.0)

@patch("engine.vectorization.get_recipe_consumption_stats")
@patch("engine.vectorization.get_recipe_data")
def test_compute_creator_beauty_recipe_vector(mock_get_data, mock_get_stats):
    mock_get_data.return_value = {
        "mode": "beauty",
        "virtues": ["growth_retention", "anti_breakage"],
        "ingredients": ["shea_butter", "chebe"],
        "ingredient_details": [
            {
                "active_key": "shea_butter",
                "virtue_weights": {"intense_hydration": 0.90, "anti_breakage": 0.85},
                "skin_virtue_weights": {"moisture_barrier": 0.95}
            },
            {
                "active_key": "chebe",
                "virtue_weights": {"growth_retention": 0.95, "anti_breakage": 0.90}
            }
        ],
        "suitable_hair_type": "4",
        "formulation": "heavy_butter"
    }
    mock_get_stats.return_value = {}

    vector = compute_recipe_vector("creator_beauty_remedy_id", mode="beauty")

    assert vector is not None
    assert len(vector) == VECTOR_DIM
    assert np.isclose(np.linalg.norm(vector), 1.0)

    expected = _expected_normalized_recipe({
        DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4"],   # 0.90 for Type 4
        DIM_POROSITY: 1.00,                            # heavy_butter formulation
        DIM_SKIN_TYPE: 0.50,                           # no skin_target -> neutral default
        DIM_SCALP_TYPE: 0.50,                          # no scalp_target -> neutral default
        GOAL_HAIR_GROWTH: 1.0,                          # max(tags 1.0, chebe 0.95)
        GOAL_HAIR_ANTI_BREAKAGE: 1.0,                   # max(tags 1.0, shea 0.85, chebe 0.90)
        GOAL_HAIR_MOISTURE: 0.90,                       # shea_butter intense_hydration
        GOAL_SKIN_BARRIER: 0.95,                        # shea_butter moisture_barrier
    })
    np.testing.assert_allclose(vector, expected, atol=1e-6)

@patch("engine.vectorization.get_recipe_consumption_stats")
@patch("engine.vectorization.get_recipe_data")
def test_premade_product_vs_diy_recipe_vectorization(mock_get_recipe, mock_get_stats):
    """Verify premade commercial product uses explicit creator virtues directly without ingredient accumulation."""
    mock_get_recipe.return_value = {
        "mode": "beauty",
        "is_premade_product": True,
        "product_type": "artisanal",
        "virtue_weights": {"growth_retention": 0.95, "shine_softness": 0.85},
        "ingredient_details": [
            # Ingredient has anti_breakage=0.99, but premade product overrides with explicit creator weights
            {"active_key": "chebe", "virtue_weights": {"anti_breakage": 0.99}}
        ]
    }
    mock_get_stats.return_value = {}

    vector = compute_recipe_vector("premade_product_id", mode="beauty")
    assert vector is not None

    expected = _expected_normalized_recipe({
        DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4C"],  # no suitable_hair_type -> defaults to "4C" -> 1.00
        DIM_POROSITY: 0.50,                            # no formulation -> neutral default
        DIM_SKIN_TYPE: 0.50,                           # no skin_target -> neutral default
        DIM_SCALP_TYPE: 0.50,
        GOAL_HAIR_GROWTH: 0.95,                         # explicit creator virtue_weights["growth_retention"]
        GOAL_HAIR_SHINE: 0.85,                          # explicit creator virtue_weights["shine_softness"]
    })
    np.testing.assert_allclose(vector, expected, atol=1e-6)
    assert vector[GOAL_HAIR_ANTI_BREAKAGE] == 0.0  # premade product ignores ingredient_details entirely

@patch("engine.vectorization.get_recipe_consumption_stats")
@patch("engine.vectorization.get_recipe_data")
def test_hybrid_selective_virtue_masking(mock_get_recipe, mock_get_stats):
    """Verify selective virtue masking nullifies un-requested virtues while preserving physical hair/skin dims."""
    mock_get_recipe.return_value = {
        "mode": "beauty",
        "suitable_hair_type": "4C",
        "formulation": "heavy_butter",
        "virtue_weights": {
            "growth_retention": 0.95,
            "shine_softness": 0.90,  # Un-requested virtue
        }
    }
    mock_get_stats.return_value = {}

    # 1. Without active_goals masking: shine_softness (dim 38) is present
    full_vector = compute_recipe_vector("recipe_mask_test", mode="beauty")
    assert full_vector is not None
    expected_full = _expected_normalized_recipe({
        DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4C"],   # 1.00
        DIM_POROSITY: 1.00,                             # heavy_butter
        DIM_SKIN_TYPE: 0.50,                            # no skin_target -> neutral default
        DIM_SCALP_TYPE: 0.50,
        GOAL_HAIR_GROWTH: 0.95,                          # explicit virtue_weights
        GOAL_HAIR_SHINE: 0.90,                           # explicit virtue_weights (un-requested)
    })
    np.testing.assert_allclose(full_vector, expected_full, atol=1e-6)

    # 2. With active_goals = {'growth_retention'}: shine_softness (dim 38) is masked to 0.0
    masked_vector = compute_recipe_vector("recipe_mask_test", mode="beauty", active_goals={"growth_retention"})
    assert masked_vector is not None
    expected_masked = _expected_normalized_recipe({
        DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4C"],
        DIM_POROSITY: 1.00,
        DIM_SKIN_TYPE: 0.50,
        DIM_SCALP_TYPE: 0.50,
        GOAL_HAIR_GROWTH: 0.95,
        # GOAL_HAIR_SHINE omitted entirely -> masked to 0.0
    })
    np.testing.assert_allclose(masked_vector, expected_masked, atol=1e-6)
    assert masked_vector[GOAL_HAIR_SHINE] == 0.0  # SELECTIVELY NULLIFIED

@patch("engine.vectorization.get_latest_beauty_log")
@patch("engine.vectorization.get_user_health_profile")
def test_user_vector_beauty_log_dynamic_metrics(mock_get_profile, mock_get_log):
    """Verify dynamic check-in metrics (low hair strength, high shedding) boost anti-breakage priority."""
    mock_get_profile.return_value = {
        "hair_type": "4C",
        "porosity": "high",
        "skin_type": "dry",
        "beauty_goals": ["growth_retention"]
    }
    mock_get_log.return_value = {
        "hair_strength_score": 3.5,  # Low strength triggers anti-breakage priority
        "hair_shedding_rate": "high"
    }

    vec = compute_user_vector("user_log_test", mode="beauty")
    assert vec is not None

    expected = _expected_normalized({
        DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4C"],
        DIM_POROSITY: POROSITY_SPECTRUM["high"],
        DIM_SCALP_TYPE: 0.50,
        DIM_SKIN_TYPE: SKIN_TYPE_SPECTRUM["dry"],
        GOAL_HAIR_GROWTH: 1.0,          # "growth_retention" in beauty_goals
        GOAL_HAIR_ANTI_BREAKAGE: 1.0,   # boosted: hair_strength_score 3.5 < 5.0
    })
    np.testing.assert_allclose(vec, expected, atol=1e-6)

@patch("engine.vectorization.get_user_health_profile")
@patch("engine.vectorization.get_recipe_consumption_stats")
@patch("engine.vectorization.get_recipe_data")
def test_continuous_hair_type_spectrum_similarity(mock_get_recipe, mock_get_stats, mock_get_user):
    """Verify 3B user (0.60) yields strong continuous similarity with a 4A remedy (0.80)."""
    mock_get_user.return_value = {
        "hair_type": "3B",  # Spectrum 0.60
        "porosity": "high",
        "beauty_goals": ["growth"]
    }
    mock_get_recipe.return_value = {
        "mode": "beauty",
        "suitable_hair_type": "4A",  # Spectrum 0.80
        "virtues": ["growth_retention"],
        "ingredients": ["shea_butter"]
    }
    mock_get_stats.return_value = {}

    user_vec = compute_user_vector("u_3b", mode="beauty")
    recipe_vec = compute_recipe_vector("r_4a", mode="beauty")

    assert user_vec is not None
    assert recipe_vec is not None

    # Calculate cosine similarity (dot product of L2 normalized vectors)
    similarity = float(np.dot(user_vec, recipe_vec))
    assert similarity > 0.40  # Strong positive similarity between 3B and 4A!

@patch("engine.vectorization.get_recipe_data")
def test_compute_recipe_vector_not_found(mock_get_data):
    # Setup mock to simulate missing or unpublished recipe
    mock_get_data.return_value = None

    # Execute
    vector = compute_recipe_vector("missing_recipe")

    # Assert
    assert vector is None


def test_upsert_creator_vector_signature():
    """upsert_creator_vector must accept (creator_id, vector, recipe_count_sampled)."""
    from engine.database import upsert_creator_vector
    import inspect
    sig = inspect.signature(upsert_creator_vector)
    params = list(sig.parameters.keys())
    assert params == ['creator_id', 'vector', 'recipe_count_sampled']


# --- compute_creator_vector ---

@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_success(mock_get_vectors):
    """Returns L2-normalized 50D centroid of recipe vectors."""
    # Two recipe vectors with known values
    v1 = np.zeros(50, dtype=np.float32)
    v1[0] = 1.0
    v2 = np.zeros(50, dtype=np.float32)
    v2[0] = 0.5
    v2[1] = 0.5
    mock_get_vectors.return_value = [v1, v2]

    result = compute_creator_vector("creator_abc")

    assert result is not None
    assert isinstance(result, np.ndarray)
    assert len(result) == 50
    # Must be L2-normalized
    assert np.isclose(np.linalg.norm(result), 1.0, atol=1e-6)
    # Centroid before normalization: [0.75, 0.25, 0, ...] → check direction preserved
    assert result[0] > result[1]


@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_no_recipes(mock_get_vectors):
    """Returns None when creator has no recipe vectors."""
    mock_get_vectors.return_value = []

    result = compute_creator_vector("creator_no_recipes")

    assert result is None


@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_single_recipe(mock_get_vectors):
    """Single recipe vector — centroid equals that recipe vector (normalized)."""
    v = np.zeros(50, dtype=np.float32)
    v[10] = 1.0  # only region dim — already normalized (norm=1)
    mock_get_vectors.return_value = [v]

    result = compute_creator_vector("creator_one_recipe")

    assert result is not None
    assert np.isclose(np.linalg.norm(result), 1.0, atol=1e-6)
    assert result[10] == pytest.approx(1.0, abs=1e-5)


@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_zero_norm(mock_get_vectors):
    """Returns None if centroid is all-zeros (degenerate case)."""
    v = np.zeros(50, dtype=np.float32)
    mock_get_vectors.return_value = [v]

    result = compute_creator_vector("creator_zero")

    assert result is None


# ---------------------------------------------------------------------------
# database.py: get_user_last_mode (Finding #1)
# ---------------------------------------------------------------------------

@patch("engine.database.get_conn")
def test_get_user_last_mode_not_onboarded_returns_nutrition(mock_get_conn):
    """A user who never completed beauty onboarding is always 'nutrition'."""
    from engine.database import get_user_last_mode

    mock_cur = MagicMock()
    mock_cur.fetchone.return_value = {"beauty_onboarding_done": False}
    mock_conn = MagicMock()
    mock_conn.__enter__.return_value = mock_conn
    mock_conn.cursor.return_value.__enter__.return_value = mock_cur
    mock_get_conn.return_value = mock_conn

    result = get_user_last_mode("user_never_onboarded")

    assert result == "nutrition"


@patch("engine.database.get_conn")
def test_get_user_last_mode_recent_beauty_activity_returns_beauty(mock_get_conn):
    """Onboarded user whose most recent activity is a beauty_log row -> 'beauty'."""
    from engine.database import get_user_last_mode

    now = datetime(2026, 7, 23, 12, 0, 0)
    mock_cur = MagicMock()
    mock_cur.fetchone.side_effect = [
        {"beauty_onboarding_done": True},
        {"last_beauty": now, "last_nutrition": now - timedelta(days=10)},
    ]
    mock_conn = MagicMock()
    mock_conn.__enter__.return_value = mock_conn
    mock_conn.cursor.return_value.__enter__.return_value = mock_cur
    mock_get_conn.return_value = mock_conn

    result = get_user_last_mode("user_recent_beauty")

    assert result == "beauty"


@patch("engine.database.get_conn")
def test_get_user_last_mode_recent_nutrition_activity_returns_nutrition(mock_get_conn):
    """Onboarded user whose most recent activity is nutrition-side -> 'nutrition'."""
    from engine.database import get_user_last_mode

    now = datetime(2026, 7, 23, 12, 0, 0)
    mock_cur = MagicMock()
    mock_cur.fetchone.side_effect = [
        {"beauty_onboarding_done": True},
        {"last_beauty": now - timedelta(days=10), "last_nutrition": now},
    ]
    mock_conn = MagicMock()
    mock_conn.__enter__.return_value = mock_conn
    mock_conn.cursor.return_value.__enter__.return_value = mock_cur
    mock_get_conn.return_value = mock_conn

    result = get_user_last_mode("user_recent_nutrition")

    assert result == "nutrition"


@patch("engine.database.get_conn")
def test_get_active_users_includes_beauty_logs(mock_get_conn):
    """Users with recent beauty_log entries must be included in active_users."""
    from engine.database import get_active_users

    mock_cur = MagicMock()
    # Mock returning 3 active users
    mock_cur.fetchall.return_value = [("user_meal",), ("user_daily",), ("user_beauty",)]
    mock_conn = MagicMock()
    mock_conn.__enter__.return_value = mock_conn
    mock_conn.cursor.return_value.__enter__.return_value = mock_cur
    mock_get_conn.return_value = mock_conn

    users = get_active_users(days=7)

    assert "user_beauty" in users
    assert len(users) == 3
    
    # Assert query contains beauty_log UNION
    query_called = mock_cur.execute.call_args[0][0].lower()
    assert "beauty_log" in query_called


@patch("engine.vectorization.get_latest_beauty_log")
@patch("engine.vectorization.get_user_health_profile")
def test_compute_user_vector_scalp_type(mock_get_profile, mock_get_log):
    """DIM_SCALP_TYPE must be populated from profile.scalp_type, now a real
    column (user_health_profile.scalp_type, added by
    20260723000000_add_missing_recipe_beauty_targeting_columns.sql and
    persisted by complete_beauty_onboarding) rather than a key no query ever
    produced. The output vector is L2-normalized, so this asserts an exact
    ratio against the known amplified DIM_HAIR_TEXTURE dim rather than an
    absolute value, mirroring test_compute_user_vector_maps_locks_hairtype_end_to_end."""
    mock_get_log.return_value = None
    mock_get_profile.return_value = {
        "hair_type": "4C",
        "porosity": "medium",
        "skin_type": "combination",
        "scalp_type": "flaky",
        "beauty_goals": [],
    }
    vector = compute_user_vector("scalp_user", mode="beauty")
    assert vector is not None
    ratio = float(vector[DIM_HAIR_TEXTURE] / vector[DIM_SCALP_TYPE])
    assert ratio == pytest.approx((HAIR_TYPE_SPECTRUM["4C"] * 2.0) / SCALP_TYPE_SPECTRUM["flaky"], abs=1e-6)


@patch("engine.vectorization.get_recipe_consumption_stats")
@patch("engine.vectorization.get_recipe_data")
def test_compute_recipe_vector_scalp_target(mock_get_recipe, mock_get_stats):
    """DIM_SCALP_TYPE must be populated from recipe.scalp_target, now a real
    column (recipe.scalp_target, added by the same migration) rather than a
    key get_recipe_data() could never produce. compute_recipe_vector does not
    amplify any dims (unlike compute_user_vector), so the ratio against
    DIM_HAIR_TEXTURE needs no *2.0 factor."""
    mock_get_recipe.return_value = {
        "mode": "beauty",
        "suitable_hair_type": "4C",
        "scalp_target": "dry"
    }
    mock_get_stats.return_value = {}

    vector = compute_recipe_vector("scalp_recipe", mode="beauty")
    assert vector is not None
    ratio = float(vector[DIM_HAIR_TEXTURE] / vector[DIM_SCALP_TYPE])
    assert ratio == pytest.approx(HAIR_TYPE_SPECTRUM["4C"] / 0.10, abs=1e-6)  # DIM_SCALP_TYPE: recipe-side "dry" branch == 0.10


def test_hair_type_spectrum_covers_locks_transition_protective():
    """Onboarding dropdown options Locks/Transition/Protective (uppercased by
    both lookup call sites) must have real HAIR_TYPE_SPECTRUM entries, not a
    silent fallback (Finding #4)."""
    assert HAIR_TYPE_SPECTRUM["LOCKS"] == 0.85
    assert HAIR_TYPE_SPECTRUM["TRANSITION"] == 0.55
    assert HAIR_TYPE_SPECTRUM["PROTECTIVE"] == 0.85


@patch("engine.vectorization.get_latest_beauty_log")
@patch("engine.vectorization.get_user_health_profile")
def test_compute_user_vector_maps_locks_hairtype_end_to_end(mock_get_profile, mock_get_log):
    """'Locks' must actually flow through compute_user_vector into DIM_HAIR_TEXTURE,
    not just exist in the dict."""
    mock_get_log.return_value = None
    mock_get_profile.return_value = {
        "hair_type": "Locks",
        "porosity": "medium",
        "skin_type": "combination",
        "scalp_type": "normal",
        "beauty_goals": [],
    }
    vector = compute_user_vector("user_locks", mode="beauty")
    assert vector is not None
    ratio = float(vector[DIM_HAIR_TEXTURE] / vector[DIM_SCALP_TYPE])
    assert ratio == pytest.approx((HAIR_TYPE_SPECTRUM["LOCKS"] * 2.0) / SCALP_TYPE_SPECTRUM["normal"], abs=1e-6)


@patch("engine.vectorization.get_latest_beauty_log")
@patch("engine.vectorization.get_user_health_profile")
def test_compute_user_vector_logs_warning_on_unknown_hair_type(mock_get_profile, mock_get_log, caplog):
    """An unrecognized hair_type must be logged, not silently miscoded (Finding #4)."""
    mock_get_log.return_value = None
    mock_get_profile.return_value = {
        "hair_type": "totally_unknown_type",
        "porosity": "medium",
        "skin_type": "combination",
        "beauty_goals": [],
    }
    with caplog.at_level(logging.WARNING):
        vector = compute_user_vector("user_unknown_hair", mode="beauty")

    assert vector is not None
    assert any("HAIR_TYPE_SPECTRUM" in record.message for record in caplog.records)


@patch("engine.vectorization.get_recipe_consumption_stats")
@patch("engine.vectorization.get_recipe_data")
def test_compute_recipe_vector_logs_warning_on_unknown_suitable_hair_type(mock_get_data, mock_get_stats, caplog):
    """An unrecognized recipe suitable_hair_type must be logged, not silently miscoded."""
    mock_get_stats.return_value = {}
    mock_get_data.return_value = {"mode": "beauty", "suitable_hair_type": "totally_unknown_type"}
    
    with caplog.at_level(logging.WARNING):
        vector = compute_recipe_vector("recipe_unknown_hair", mode="beauty")

    assert vector is not None
    assert any("HAIR_TYPE_SPECTRUM" in record.message for record in caplog.records)


@patch("engine.vectorization.get_recipe_consumption_stats")
@patch("engine.vectorization.get_recipe_data")
def test_recipe_skin_type_spectrum_distinguishes_oily_from_acne(mock_get_data, mock_get_stats):
    """Recipe-side skin_target must reuse SKIN_TYPE_SPECTRUM (oily=0.90, acne=1.00),
    not collapse both to the same hardcoded 0.90 (Finding #6)."""
    mock_get_stats.return_value = {}
    base_recipe = {"mode": "beauty", "suitable_hair_type": "4C"}

    mock_get_data.return_value = {**base_recipe, "skin_target": "oily"}
    oily_vector = compute_recipe_vector("recipe_oily")

    mock_get_data.return_value = {**base_recipe, "skin_target": "acne"}
    acne_vector = compute_recipe_vector("recipe_acne")

    assert oily_vector is not None and acne_vector is not None
    # DIM_HAIR_TEXTURE raw value is identical (1.00) in both -> the ratio isolates
    # DIM_SKIN_TYPE's raw value, independent of each vector's own norm.
    oily_ratio = float(oily_vector[DIM_SKIN_TYPE] / oily_vector[DIM_HAIR_TEXTURE])
    acne_ratio = float(acne_vector[DIM_SKIN_TYPE] / acne_vector[DIM_HAIR_TEXTURE])
    assert oily_ratio == pytest.approx(SKIN_TYPE_SPECTRUM["oily"] / HAIR_TYPE_SPECTRUM["4C"], abs=1e-6)
    assert acne_ratio == pytest.approx(SKIN_TYPE_SPECTRUM["acne"] / HAIR_TYPE_SPECTRUM["4C"], abs=1e-6)
    assert acne_ratio > oily_ratio  # must NOT collapse to the same value (current bug)


def test_amplified_goal_dims_is_exactly_six_members():
    """AMPLIFIED_GOAL_DIMS covers 6 of the 18 goal/virtue dims (31-48) by
    design — expanding coverage to the other 12 is a product decision, NOT
    made here (Finding #7)."""
    from engine.vectorization import AMPLIFIED_GOAL_DIMS  # does not exist yet -> ImportError pre-fix

    assert len(AMPLIFIED_GOAL_DIMS) == 6
    assert set(AMPLIFIED_GOAL_DIMS) == {
        GOAL_HAIR_GROWTH, GOAL_HAIR_ANTI_BREAKAGE, GOAL_HAIR_MOISTURE,
        GOAL_SKIN_GLOW, GOAL_SKIN_BARRIER, GOAL_SKIN_SEBUM_ACNE,
    }


@patch("engine.vectorization.get_latest_beauty_log")
@patch("engine.vectorization.get_user_health_profile")
def test_missing_porosity_and_skin_type_fall_back_to_db_neutral_defaults(mock_get_profile, mock_get_log):
    """Missing porosity/skin_type must fall back to the DB's own neutral
    defaults ('medium' / 'combination' per
    supabase/migrations/20260720000003_add_beauty_diagnostic_columns.sql),
    not to spectrum extremes ('high' / 'oily') (Finding #8)."""
    mock_get_log.return_value = None
    mock_get_profile.return_value = {
        "hair_type": "4C",
        # porosity intentionally absent
        # skin_type intentionally absent
        "scalp_type": "normal",
        "beauty_goals": [],
    }

    vector = compute_user_vector("user_missing_fields", mode="beauty")
    assert vector is not None

    # DIM_POROSITY / DIM_SKIN_TYPE (amplified 2x) vs DIM_SCALP_TYPE (not
    # amplified, fixed here at "normal"=0.50) isolates each raw fallback value.
    porosity_ratio = float(vector[DIM_POROSITY] / vector[DIM_SCALP_TYPE])
    assert porosity_ratio == pytest.approx((POROSITY_SPECTRUM["medium"] * 2.0) / SCALP_TYPE_SPECTRUM["normal"], abs=1e-6)

    skin_ratio = float(vector[DIM_SKIN_TYPE] / vector[DIM_SCALP_TYPE])
    assert skin_ratio == pytest.approx((SKIN_TYPE_SPECTRUM["combination"] * 2.0) / SCALP_TYPE_SPECTRUM["normal"], abs=1e-6)


@patch("engine.vectorization.get_latest_beauty_log")
@patch("engine.vectorization.get_user_health_profile")
def test_beauty_log_fetch_failure_is_logged_not_silenced(mock_get_profile, mock_get_log, caplog):
    """A failure fetching the check-in boost must be logged, not silently
    swallowed (Finding #10)."""
    mock_get_profile.return_value = {
        "hair_type": "4C", "porosity": "high", "skin_type": "dry",
        "scalp_type": "normal", "beauty_goals": [],
    }
    mock_get_log.side_effect = Exception("db unreachable")

    with caplog.at_level(logging.WARNING):
        vector = compute_user_vector("user_log_failure", mode="beauty")

    assert vector is not None  # boost failure must not crash vector computation
    assert any("check-in boost skipped" in record.message for record in caplog.records)
