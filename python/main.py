"""
AKELI Python Service — Batch Vectorization Engine
Déployé sur Railway. Jamais appelé au runtime (sauf onboarding).
Ref: V1_ARCHITECTURE_DECISIONS.md ADR-001, ADR-003
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
import uvicorn
import os

from engine.vectorization import compute_user_vector, compute_recipe_vector, compute_creator_vector
from engine.analytics import compute_recipe_weight_impact
from engine.database import (
    upsert_user_vector,
    upsert_recipe_vector,
    get_active_users,
    get_pending_recipes,
    get_all_creators,
    get_creator_recipe_vectors,
    upsert_creator_vector,
    upsert_recipe_weight_impact,
    get_users_with_weight_history,
    start_batch_run,
    log_batch_failure,
    finish_batch_run,
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
    mode: str = "nutrition"


class RecipeVectorRequest(BaseModel):
    recipe_id: str
    mode: str = "nutrition"


class CreatorVectorRequest(BaseModel):
    creator_id: str


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
        vector = compute_user_vector(request.user_id, mode=request.mode)
        if vector is None:
            raise HTTPException(status_code=404, detail="User not found or insufficient data")
        upsert_user_vector(request.user_id, vector)
        return {"user_id": request.user_id, "mode": request.mode, "vector_computed": True, "dimensions": len(vector)}
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
        vector = compute_recipe_vector(request.recipe_id, mode=request.mode)
        if vector is None:
            raise HTTPException(status_code=404, detail="Recipe not found or not published")
        upsert_recipe_vector(request.recipe_id, vector)
        return {"recipe_id": request.recipe_id, "mode": request.mode, "vector_computed": True, "dimensions": len(vector)}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---------------------------------------------------------------------------
# Endpoint: compute-creator-vector
# Appelé après la publication d'une recette pour mettre à jour le creator_vector
# ---------------------------------------------------------------------------

@app.post("/compute-creator-vector")
async def api_compute_creator_vector(request: CreatorVectorRequest):
    """
    Calcule et stocke le creator_vector pour un créateur.
    Requiert que les recipe_vectors du créateur soient déjà calculés.
    """
    try:
        vector = compute_creator_vector(request.creator_id)
        if vector is None:
            raise HTTPException(
                status_code=404,
                detail="Creator not found or no published recipe vectors available"
            )
        recipe_vectors = get_creator_recipe_vectors(request.creator_id)
        recipe_count = len(recipe_vectors)
        upsert_creator_vector(request.creator_id, vector, recipe_count)
        return {
            "creator_id": request.creator_id,
            "vector_computed": True,
            "dimensions": len(vector),
            "recipe_count_sampled": recipe_count,
        }
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

    run_id = start_batch_run()
    counts = {
        "user_vectors_updated": 0, "user_vectors_attempted": 0,
        "recipe_vectors_updated": 0, "recipe_vectors_attempted": 0,
        "creator_vectors_updated": 0, "creator_vectors_attempted": 0,
        "weight_impact_updated": 0, "weight_impact_attempted": 0,
    }

    try:
        # --- 1. User vectors ---
        active_users = get_active_users(days=7)
        logger.info(f"[nightly-batch] Processing {len(active_users)} active users")
        counts["user_vectors_attempted"] = len(active_users)

        for user_id in active_users:
            try:
                vector = compute_user_vector(user_id)
                if vector is not None:
                    upsert_user_vector(user_id, vector)
                    counts["user_vectors_updated"] += 1
            except Exception as e:
                logger.error(f"[nightly-batch] User {user_id} failed: {e}")
                log_batch_failure(run_id, "user_vector", user_id, str(e))

        logger.info(f"[nightly-batch] User vectors: {counts['user_vectors_updated']}/{len(active_users)} updated")

        # --- 2. Recipe vectors ---
        pending_recipes = get_pending_recipes()
        logger.info(f"[nightly-batch] Processing {len(pending_recipes)} pending recipes")
        counts["recipe_vectors_attempted"] = len(pending_recipes)

        for recipe_id in pending_recipes:
            try:
                vector = compute_recipe_vector(recipe_id)
                if vector is not None:
                    upsert_recipe_vector(recipe_id, vector)
                    counts["recipe_vectors_updated"] += 1
            except Exception as e:
                logger.error(f"[nightly-batch] Recipe {recipe_id} failed: {e}")
                log_batch_failure(run_id, "recipe_vector", recipe_id, str(e))

        logger.info(f"[nightly-batch] Recipe vectors: {counts['recipe_vectors_updated']}/{len(pending_recipes)} updated")

        # --- 3. Creator vectors ---
        # Must run AFTER recipe vectors — creator vectors are derived from them.
        all_creators = get_all_creators()
        logger.info(f"[nightly-batch] Processing {len(all_creators)} creators")
        counts["creator_vectors_attempted"] = len(all_creators)

        for creator_id in all_creators:
            try:
                vector = compute_creator_vector(creator_id)
                if vector is not None:
                    recipe_count = len(get_creator_recipe_vectors(creator_id))
                    upsert_creator_vector(creator_id, vector, recipe_count)
                    counts["creator_vectors_updated"] += 1
            except Exception as e:
                logger.error(f"[nightly-batch] Creator {creator_id} failed: {e}")
                log_batch_failure(run_id, "creator_vector", creator_id, str(e))

        logger.info(f"[nightly-batch] Creator vectors: {counts['creator_vectors_updated']}/{len(all_creators)} updated")

        # --- 4. Recipe weight impact ---
        # Requires at least 2 weight log entries to form one period.
        users_with_weights = get_users_with_weight_history(min_entries=2)
        logger.info(f"[nightly-batch] Processing weight impact for {len(users_with_weights)} users")
        counts["weight_impact_attempted"] = len(users_with_weights)

        for user_id in users_with_weights:
            try:
                results = compute_recipe_weight_impact(user_id, min_samples=3)
                upsert_recipe_weight_impact(user_id, results)
                counts["weight_impact_updated"] += 1
            except Exception as e:
                logger.error(f"[nightly-batch] Weight impact {user_id} failed: {e}")
                log_batch_failure(run_id, "weight_impact", user_id, str(e))

        logger.info(f"[nightly-batch] Weight impact: {counts['weight_impact_updated']}/{len(users_with_weights)} updated")

        finish_batch_run(run_id, "completed", counts)

    except Exception as e:
        logger.error(f"[nightly-batch] Batch run {run_id} failed catastrophically: {e}")
        finish_batch_run(run_id, "failed", counts)


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
