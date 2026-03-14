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

@patch("main.upsert_recipe_vector")
@patch("main.compute_recipe_vector")
@patch("main.get_pending_recipes")
@patch("main.upsert_user_vector")
@patch("main.compute_user_vector")
@patch("main.get_active_users")
def test_run_nightly_batch(mock_get_users, mock_comp_user, mock_up_user, mock_get_recipes, mock_comp_recipe, mock_up_recipe):
    mock_get_users.return_value = ["user1", "user2"]
    mock_comp_user.side_effect = [np.zeros(VECTOR_DIM), None] # Second user fails to generate vector
    
    mock_get_recipes.return_value = ["recipe1"]
    mock_comp_recipe.return_value = np.zeros(VECTOR_DIM)
    
    # We call the function directly as it runs synchronously
    from main import run_nightly_batch
    run_nightly_batch()
    
    assert mock_up_user.call_count == 1 # Only one successful vector
    assert mock_up_recipe.call_count == 1 # One successful vector
