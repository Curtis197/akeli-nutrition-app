import pytest
from unittest.mock import patch
import numpy as np

from engine.vectorization import compute_user_vector, compute_recipe_vector, VECTOR_DIM

@patch("engine.vectorization.get_user_behavior")
@patch("engine.vectorization.get_user_health_profile")
def test_compute_user_vector_success(mock_get_profile, mock_get_behavior):
    # Setup mock data for a valid user
    mock_get_profile.return_value = {
        "goals": ["weight_loss", "health"],
        "activity_level": "moderate",
        "weight_kg": 80.0,
        "target_weight_kg": 70.0,
        "cuisine_regions": ["mediterranean", "france"],
        "restrictions": ["vegetarian"]
    }
    mock_get_behavior.return_value = {
        "total_consumptions": 40,
        "active_days": 20,
        "avg_servings": 1.5,
        "current_weight_kg": 78.0
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
    from engine.vectorization import compute_creator_vector
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
    from engine.vectorization import compute_creator_vector
    mock_get_vectors.return_value = []

    result = compute_creator_vector("creator_no_recipes")

    assert result is None


@patch("engine.vectorization.get_creator_recipe_vectors")
def test_compute_creator_vector_single_recipe(mock_get_vectors):
    """Single recipe vector — centroid equals that recipe vector (normalized)."""
    from engine.vectorization import compute_creator_vector
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
    from engine.vectorization import compute_creator_vector
    v = np.zeros(50, dtype=np.float32)
    mock_get_vectors.return_value = [v]

    result = compute_creator_vector("creator_zero")

    assert result is None
