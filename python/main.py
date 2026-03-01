"""
AKELI Python Service — Batch Vectorization Engine
Déployé sur Railway. Jamais appelé au runtime (sauf onboarding).
Ref: V1_ARCHITECTURE_DECISIONS.md ADR-001, ADR-003
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
import uvicorn
import os

from engine.vectorization import compute_user_vector, compute_recipe_vector
from engine.database import (
    upsert_user_vector,
    upsert_recipe_vector,
    get_active_users,
    get_pending_recipes,
)

app = FastAPI(
    title="Akeli Recommendation Engine",
    description="Batch vectorization service — not called at runtime except for onboarding",
    version="1.0.0",
)


# ---------------------------------------------------------------------------
# Health check (Railway)
# ---------------------------------------------------------------------------

@app.get("/health")
def health():
    return {"status": "ok", "service": "akeli-recommendation-engine"}


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------

class UserVectorRequest(BaseModel):
    user_id: str


class RecipeVectorRequest(BaseModel):
    recipe_id: str


class NightlyBatchRequest(BaseModel):
    secret: str  # Simple shared secret pour sécuriser le cron


# ---------------------------------------------------------------------------
# Endpoint: compute-user-vector
# Appelé UNE SEULE FOIS après l'onboarding (Edge Function complete-onboarding)
# Tous les recalculs suivants sont via /nightly-batch
# ---------------------------------------------------------------------------

@app.post("/compute-user-vector")
async def api_compute_user_vector(request: UserVectorRequest):
    """
    Calcule et stocke le user_vector pour un utilisateur.
    Exception runtime ADR-001 — appelé uniquement à l'onboarding.
    """
    try:
        vector = compute_user_vector(request.user_id)
        if vector is None:
            raise HTTPException(status_code=404, detail="User not found or insufficient data")
        upsert_user_vector(request.user_id, vector)
        return {"user_id": request.user_id, "vector_computed": True, "dimensions": len(vector)}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---------------------------------------------------------------------------
# Endpoint: compute-recipe-vector
# Appelé lors de la publication d'une recette (optionnel — le batch nightly suffit)
# ---------------------------------------------------------------------------

@app.post("/compute-recipe-vector")
async def api_compute_recipe_vector(request: RecipeVectorRequest):
    """
    Calcule et stocke le recipe_vector pour une recette publiée.
    """
    try:
        vector = compute_recipe_vector(request.recipe_id)
        if vector is None:
            raise HTTPException(status_code=404, detail="Recipe not found or not published")
        upsert_recipe_vector(request.recipe_id, vector)
        return {"recipe_id": request.recipe_id, "vector_computed": True, "dimensions": len(vector)}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---------------------------------------------------------------------------
# Endpoint: nightly-batch
# Déclenché par Railway Cron à 03:00 UTC chaque nuit
# Recalcule user_vectors + recipe_vectors en batch
# ---------------------------------------------------------------------------

@app.post("/nightly-batch")
async def nightly_batch(request: NightlyBatchRequest, background_tasks: BackgroundTasks):
    """
    Batch nightly — recalcule:
    1. user_vector pour les utilisateurs actifs des 7 derniers jours
    2. recipe_vector pour les recettes nouvelles ou modifiées (statut pending)
    """
    expected_secret = os.getenv("BATCH_SECRET", "")
    if not expected_secret or request.secret != expected_secret:
        raise HTTPException(status_code=401, detail="Invalid secret")

    background_tasks.add_task(run_nightly_batch)
    return {"status": "batch_started", "message": "Running in background"}


def run_nightly_batch():
    """Logique du batch nightly — exécutée en background."""
    import logging
    logger = logging.getLogger("nightly_batch")

    # --- 1. User vectors ---
    active_users = get_active_users(days=7)
    logger.info(f"[nightly-batch] Processing {len(active_users)} active users")

    user_success = 0
    for user_id in active_users:
        try:
            vector = compute_user_vector(user_id)
            if vector is not None:
                upsert_user_vector(user_id, vector)
                user_success += 1
        except Exception as e:
            logger.error(f"[nightly-batch] User {user_id} failed: {e}")

    logger.info(f"[nightly-batch] User vectors: {user_success}/{len(active_users)} updated")

    # --- 2. Recipe vectors ---
    pending_recipes = get_pending_recipes()
    logger.info(f"[nightly-batch] Processing {len(pending_recipes)} pending recipes")

    recipe_success = 0
    for recipe_id in pending_recipes:
        try:
            vector = compute_recipe_vector(recipe_id)
            if vector is not None:
                upsert_recipe_vector(recipe_id, vector)
                recipe_success += 1
        except Exception as e:
            logger.error(f"[nightly-batch] Recipe {recipe_id} failed: {e}")

    logger.info(f"[nightly-batch] Recipe vectors: {recipe_success}/{len(pending_recipes)} updated")


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
