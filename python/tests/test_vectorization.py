import pytest
from unittest.mock import patch
import numpy as np

from engine.vectorization import compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM

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

@patch("engine.vectorization.get_user_health_profile")
def test_compute_beauty_user_vector(mock_get_profile):
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
    assert vector[27] > 0.0  # DIM_HAIR_TEXTURE
    assert vector[28] > 0.0  # DIM_POROSITY
    assert vector[30] > 0.0  # DIM_SKIN_TYPE
    assert vector[31] > 0.0  # GOAL_HAIR_GROWTH
    assert vector[40] > 0.0  # GOAL_SKIN_GLOW

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
    assert vector[27] > 0.0  # DIM_HAIR_TEXTURE (0.90 for Type 4)
    assert vector[28] > 0.0  # DIM_POROSITY (1.0 for heavy_butter)
    assert vector[31] > 0.0  # GOAL_HAIR_GROWTH (0.95 from chebe)
    assert vector[32] > 0.0  # GOAL_HAIR_ANTI_BREAKAGE (0.90 from chebe & shea)
    assert vector[41] > 0.0  # GOAL_SKIN_BARRIER (0.95 from dry_skin_moisture / barrier_repair)

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
    assert vector[31] > 0.0  # GOAL_HAIR_GROWTH (0.95 explicit)
    assert vector[38] > 0.0  # GOAL_HAIR_SHINE (0.85 explicit)
    assert vector[32] == 0.0  # GOAL_HAIR_ANTI_BREAKAGE is 0 because premade product uses explicit creator vector

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
    assert full_vector[27] > 0.0  # DIM_HAIR_TEXTURE (preserved)
    assert full_vector[28] > 0.0  # DIM_POROSITY (preserved)
    assert full_vector[31] > 0.0  # GOAL_HAIR_GROWTH (preserved)
    assert full_vector[38] > 0.0  # GOAL_HAIR_SHINE (present)

    # 2. With active_goals = {'growth_retention'}: shine_softness (dim 38) is masked to 0.0
    masked_vector = compute_recipe_vector("recipe_mask_test", mode="beauty", active_goals={"growth_retention"})
    assert masked_vector is not None
    assert masked_vector[27] > 0.0  # DIM_HAIR_TEXTURE (preserved)
    assert masked_vector[28] > 0.0  # DIM_POROSITY (preserved)
    assert masked_vector[31] > 0.0  # GOAL_HAIR_GROWTH (preserved)
    assert masked_vector[38] == 0.0  # GOAL_HAIR_SHINE is SELECTIVELY NULLIFIED to 0.0!

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
