import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch
import os
import numpy as np

from main import app
from engine.vectorization import VECTOR_DIM

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "akeli-recommendation-engine"}

@patch("main.upsert_user_vector")
@patch("main.compute_user_vector")
def test_compute_user_vector_endpoint_success(mock_compute, mock_upsert):
    # Setup mocks
    mock_compute.return_value = np.zeros(VECTOR_DIM, dtype=np.float32)
    
    response = client.post("/compute-user-vector", json={"user_id": "user123"})
    
    assert response.status_code == 200
    assert response.json()["user_id"] == "user123"
    assert response.json()["vector_computed"] is True
    # Ensure our mocks were called
    mock_compute.assert_called_once_with("user123")
    mock_upsert.assert_called_once()

@patch("main.compute_user_vector")
def test_compute_user_vector_endpoint_not_found(mock_compute):
    mock_compute.return_value = None
    
    response = client.post("/compute-user-vector", json={"user_id": "missing_user"})
    
    assert response.status_code == 404
    assert "User not found" in response.json()["detail"]

@patch("main.upsert_recipe_vector")
@patch("main.compute_recipe_vector")
def test_compute_recipe_vector_endpoint_success(mock_compute, mock_upsert):
    mock_compute.return_value = np.zeros(VECTOR_DIM, dtype=np.float32)
    
    response = client.post("/compute-recipe-vector", json={"recipe_id": "recipe123"})
    
    assert response.status_code == 200
    assert response.json()["recipe_id"] == "recipe123"
    mock_compute.assert_called_once_with("recipe123")
    mock_upsert.assert_called_once()

@patch("main.compute_recipe_vector")
def test_compute_recipe_vector_endpoint_not_found(mock_compute):
    mock_compute.return_value = None
    
    response = client.post("/compute-recipe-vector", json={"recipe_id": "missing_recipe"})
    
    assert response.status_code == 404
    assert "Recipe not found" in response.json()["detail"]

def test_nightly_batch_unauthorized():
    response = client.post("/nightly-batch", json={"secret": "wrong_secret"})
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid secret"

@patch("main.run_nightly_batch")
def test_nightly_batch_success(mock_run_batch):
    os.environ["BATCH_SECRET"] = "test_secret"
    
    response = client.post("/nightly-batch", json={"secret": "test_secret"})
    
    assert response.status_code == 200
    assert response.json()["status"] == "batch_started"
    
    # Fastapi TestClient processes background tasks before returning
    mock_run_batch.assert_called_once()

@patch("main.finish_batch_run")
@patch("main.start_batch_run")
@patch("main.upsert_recipe_weight_impact")
@patch("main.compute_recipe_weight_impact")
@patch("main.get_users_with_weight_history")
@patch("main.upsert_creator_vector")
@patch("main.get_creator_recipe_vectors")
@patch("main.compute_creator_vector")
@patch("main.get_all_creators")
@patch("main.upsert_recipe_vector")
@patch("main.compute_recipe_vector")
@patch("main.get_pending_recipes")
@patch("main.upsert_user_vector")
@patch("main.compute_user_vector")
@patch("main.get_active_users")
def test_run_nightly_batch(
    mock_get_users, mock_comp_user, mock_up_user,
    mock_get_recipes, mock_comp_recipe, mock_up_recipe,
    mock_get_creators, mock_comp_creator, mock_get_creator_recipes, mock_up_creator,
    mock_get_weight_users, mock_comp_weight, mock_up_weight,
    mock_start_run, mock_finish_run,
):
    mock_start_run.return_value = "run-123"
    mock_get_users.return_value = ["user1", "user2"]
    mock_comp_user.side_effect = [np.zeros(VECTOR_DIM), None] # Second user fails to generate vector
    
    mock_get_recipes.return_value = ["recipe1"]
    mock_comp_recipe.return_value = np.zeros(VECTOR_DIM)
    
    mock_get_creators.return_value = []
    mock_get_weight_users.return_value = []
    
    from main import run_nightly_batch
    run_nightly_batch()
    
    assert mock_up_user.call_count == 1 # Only one successful vector
    assert mock_up_recipe.call_count == 1 # One successful vector
    mock_start_run.assert_called_once()
    mock_finish_run.assert_called_once_with("run-123", "completed", {
        "user_vectors_updated": 1, "user_vectors_attempted": 2,
        "recipe_vectors_updated": 1, "recipe_vectors_attempted": 1,
        "creator_vectors_updated": 0, "creator_vectors_attempted": 0,
        "weight_impact_updated": 0, "weight_impact_attempted": 0,
    })


@patch("main.finish_batch_run")
@patch("main.start_batch_run")
@patch("main.log_batch_failure")
@patch("main.upsert_recipe_weight_impact")
@patch("main.compute_recipe_weight_impact")
@patch("main.get_users_with_weight_history")
@patch("main.upsert_creator_vector")
@patch("main.get_creator_recipe_vectors")
@patch("main.compute_creator_vector")
@patch("main.get_all_creators")
@patch("main.upsert_recipe_vector")
@patch("main.compute_recipe_vector")
@patch("main.get_pending_recipes")
@patch("main.upsert_user_vector")
@patch("main.compute_user_vector")
@patch("main.get_active_users")
def test_run_nightly_batch_logs_failure_on_exception(
    mock_get_users, mock_comp_user, mock_up_user,
    mock_get_recipes, mock_comp_recipe, mock_up_recipe,
    mock_get_creators, mock_comp_creator, mock_get_creator_recipes, mock_up_creator,
    mock_get_weight_users, mock_comp_weight, mock_up_weight,
    mock_log_failure, mock_start_run, mock_finish_run,
):
    mock_start_run.return_value = "run-456"
    mock_get_users.return_value = ["user1"]
    mock_comp_user.side_effect = Exception("boom")
    mock_get_recipes.return_value = []
    mock_get_creators.return_value = []
    mock_get_weight_users.return_value = []
    
    from main import run_nightly_batch
    run_nightly_batch()
    
    mock_log_failure.assert_called_once_with("run-456", "user_vector", "user1", "boom")
