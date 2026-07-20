"""
Database helpers — connexion PostgreSQL Supabase via psycopg2
"""

import os
import psycopg2
import psycopg2.extras
from datetime import datetime, timedelta
from typing import Optional
import numpy as np

DATABASE_URL = os.getenv("DATABASE_URL", "")


def get_conn():
    """Retourne une connexion PostgreSQL."""
    return psycopg2.connect(DATABASE_URL)


# ---------------------------------------------------------------------------
# User helpers
# ---------------------------------------------------------------------------

def get_user_health_profile(user_id: str) -> Optional[dict]:
    """Récupère le profil santé de l'utilisateur."""
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("""
                SELECT
                    uhp.sex, uhp.birth_date, uhp.height_cm, uhp.weight_kg,
                    uhp.target_weight_kg, uhp.activity_level,
                    uhp.weight_goal, uhp.muscle_goal, uhp.cooking_time,
                    uhp.hair_type, uhp.porosity, uhp.skin_type, uhp.sensitive_scalp,
                    uhp.beauty_goals, uhp.preferred_actives,
                    ARRAY_AGG(DISTINCT ug.goal_type) FILTER (WHERE ug.goal_type IS NOT NULL) AS goals,
                    ARRAY_AGG(DISTINCT udr.restriction) FILTER (WHERE udr.restriction IS NOT NULL) AS restrictions,
                    ARRAY_AGG(DISTINCT ucp.region) FILTER (WHERE ucp.region IS NOT NULL) AS cuisine_regions
                FROM user_health_profile uhp
                LEFT JOIN user_goal ug ON ug.user_id = uhp.user_id AND ug.is_active = true
                LEFT JOIN user_dietary_restriction udr ON udr.user_id = uhp.user_id
                LEFT JOIN user_cuisine_preference ucp ON ucp.user_id = uhp.user_id
                WHERE uhp.user_id = %s
                GROUP BY uhp.sex, uhp.birth_date, uhp.height_cm, uhp.weight_kg,
                         uhp.target_weight_kg, uhp.activity_level,
                         uhp.weight_goal, uhp.muscle_goal, uhp.cooking_time,
                         uhp.hair_type, uhp.porosity, uhp.skin_type, uhp.sensitive_scalp,
                         uhp.beauty_goals, uhp.preferred_actives
            """, (user_id,))
            row = cur.fetchone()
            return dict(row) if row else None


def get_user_behavior(user_id: str, weeks: int = 4) -> dict:
    """Récupère le comportement des N dernières semaines."""
    since = (datetime.now() - timedelta(weeks=weeks)).date()
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            # Consommations réelles
            cur.execute("""
                SELECT
                    COUNT(*) AS total_consumptions,
                    COUNT(DISTINCT DATE(consumed_at)) AS active_days,
                    AVG(servings) AS avg_servings
                FROM meal_consumption
                WHERE user_id = %s AND consumed_at >= %s
            """, (user_id, since))
            behavior = dict(cur.fetchone() or {})

            # Poids récent
            cur.execute("""
                SELECT weight_kg FROM weight_log
                WHERE user_id = %s ORDER BY logged_at DESC LIMIT 1
            """, (user_id,))
            row = cur.fetchone()
            behavior["current_weight_kg"] = row["weight_kg"] if row else None

            return behavior


def get_active_users(days: int = 7) -> list[str]:
    """Retourne les user_ids actifs dans les N derniers jours."""
    since = (datetime.now() - timedelta(days=days)).isoformat()
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT DISTINCT user_id FROM meal_consumption
                WHERE consumed_at >= %s
                UNION
                SELECT DISTINCT user_id FROM daily_nutrition_log
                WHERE date >= %s::date
            """, (since, since))
            return [row[0] for row in cur.fetchall()]


# ---------------------------------------------------------------------------
# Recipe helpers
# ---------------------------------------------------------------------------

def get_recipe_data(recipe_id: str) -> Optional[dict]:
    """Récupère les données complètes d'une recette publiée."""
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("""
                SELECT
                    r.id, r.difficulty, r.prep_time_min, r.cook_time_min,
                    r.region, r.created_at, r.creator_id,
                    GREATEST(r.servings, 1) AS servings,
                    -- Per-serving macros: divide totals by servings
                    rm.calories  / GREATEST(r.servings, 1) AS calories,
                    rm.protein_g / GREATEST(r.servings, 1) AS protein_g,
                    rm.carbs_g   / GREATEST(r.servings, 1) AS carbs_g,
                    rm.fat_g     / GREATEST(r.servings, 1) AS fat_g,
                    rm.fiber_g   / GREATEST(r.servings, 1) AS fiber_g,
                    c.recipe_count AS creator_recipe_count
                FROM recipe r
                LEFT JOIN recipe_macro rm ON rm.recipe_id = r.id
                LEFT JOIN creator c ON c.id = r.creator_id
                WHERE r.id = %s AND r.is_published = true
            """, (recipe_id,))
            row = cur.fetchone()
            return dict(row) if row else None


def get_recipe_consumption_stats(recipe_id: str, days: int = 30) -> dict:
    """Stats de consommation d'une recette."""
    since = (datetime.now() - timedelta(days=days)).isoformat()
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("""
                SELECT
                    COUNT(*) AS total_consumptions,
                    COUNT(DISTINCT user_id) AS unique_users,
                    AVG(servings) AS avg_servings
                FROM meal_consumption
                WHERE recipe_id = %s AND consumed_at >= %s
            """, (recipe_id, since))
            row = cur.fetchone()
            return dict(row) if row else {}


def get_pending_recipes() -> list[str]:
    """Recettes publiées sans vecteur ou dont le vecteur est périmé."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT r.id FROM recipe r
                LEFT JOIN recipe_vector rv ON rv.recipe_id = r.id
                WHERE r.is_published = true
                  AND (rv.recipe_id IS NULL OR rv.last_computed < r.updated_at)
                LIMIT 500
            """)
            return [row[0] for row in cur.fetchall()]


# ---------------------------------------------------------------------------
# Vector upserts
# ---------------------------------------------------------------------------

def upsert_user_vector(user_id: str, vector: np.ndarray):
    """Stocke ou met à jour le user_vector dans PostgreSQL."""
    vector_list = vector.tolist()
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO user_vector (user_id, vector, last_computed, updated_at)
                VALUES (%s, %s::vector, NOW(), NOW())
                ON CONFLICT (user_id) DO UPDATE SET
                    vector = EXCLUDED.vector,
                    last_computed = NOW(),
                    updated_at = NOW()
            """, (user_id, str(vector_list)))
        conn.commit()


def upsert_recipe_vector(recipe_id: str, vector: np.ndarray):
    """Stocke ou met à jour le recipe_vector dans PostgreSQL."""
    vector_list = vector.tolist()
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO recipe_vector (recipe_id, vector, last_computed)
                VALUES (%s, %s::vector, NOW())
                ON CONFLICT (recipe_id) DO UPDATE SET
                    vector = EXCLUDED.vector,
                    last_computed = NOW()
            """, (recipe_id, str(vector_list)))
        conn.commit()


# ---------------------------------------------------------------------------
# Creator helpers
# ---------------------------------------------------------------------------

def get_all_creators() -> list[str]:
    """Retourne les creator_ids ayant au moins une recette publiée."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT DISTINCT c.id
                FROM creator c
                WHERE c.recipe_count >= 1
            """)
            return [row[0] for row in cur.fetchall()]


def get_creator_recipe_vectors(creator_id: str) -> list[np.ndarray]:
    """
    Retourne les vecteurs de toutes les recettes publiées d'un créateur.
    Retourne une liste vide si aucun recipe_vector n'existe encore pour ce créateur.
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT rv.vector
                FROM recipe_vector rv
                JOIN recipe r ON r.id = rv.recipe_id
                WHERE r.creator_id = %s
                  AND r.is_published = true
            """, (creator_id,))
            rows = cur.fetchall()
            if not rows:
                return []
            # psycopg2 returns pgvector as a string like '[0.1,0.2,...]'
            # Convert each to a float32 numpy array
            result = []
            for row in rows:
                raw = row[0]
                if isinstance(raw, str):
                    nums = [float(x) for x in raw.strip('[]').split(',')]
                    result.append(np.array(nums, dtype=np.float32))
                else:
                    result.append(np.array(raw, dtype=np.float32))
            return result


# ---------------------------------------------------------------------------
# Recipe weight impact helpers
# ---------------------------------------------------------------------------

def get_user_weight_log(user_id: str) -> list[tuple]:
    """Retourne [(date, weight_kg), ...] triés ASC pour un utilisateur."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT DATE(logged_at), weight_kg
                FROM weight_log
                WHERE user_id = %s
                ORDER BY logged_at ASC
            """, (user_id,))
            return [(row[0], float(row[1])) for row in cur.fetchall()]


def get_recipes_consumed_between(user_id: str, date_start, date_end) -> list[tuple]:
    """
    Retourne les paires (recipe_id, meal_type) distinctes consommées dans [date_start, date_end).
    Joins meal_plan_entry pour récupérer le meal_type.
    Exclut les consommations sans meal_type connu.
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT DISTINCT mc.recipe_id, mpe.meal_type
                FROM meal_consumption mc
                JOIN meal_plan_entry mpe ON mpe.id = mc.meal_plan_entry_id
                WHERE mc.user_id = %s
                  AND mc.scheduled_date >= %s
                  AND mc.scheduled_date < %s
                  AND mc.recipe_id IS NOT NULL
                  AND mpe.meal_type IS NOT NULL
            """, (user_id, date_start, date_end))
            return [(row[0], row[1]) for row in cur.fetchall()]


def upsert_recipe_weight_impact(user_id: str, results: list[dict]):
    """Remplace les données recipe_weight_impact d'un utilisateur."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "DELETE FROM recipe_weight_impact WHERE user_id = %s",
                (user_id,),
            )
            if results:
                psycopg2.extras.execute_values(
                    cur,
                    """
                    INSERT INTO recipe_weight_impact
                        (user_id, recipe_id, meal_type, avg_delta_kg, sample_count, computed_at)
                    VALUES %s
                    """,
                    [
                        (user_id, r["recipe_id"], r["meal_type"], r["avg_delta_kg"], r["sample_count"])
                        for r in results
                    ],
                    template="(%s, %s, %s, %s, %s, NOW())",
                )
        conn.commit()


def get_users_with_weight_history(min_entries: int = 2) -> list[str]:
    """Retourne les user_ids ayant au moins min_entries entrées dans weight_log."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT user_id
                FROM weight_log
                GROUP BY user_id
                HAVING COUNT(*) >= %s
            """, (min_entries,))
            return [row[0] for row in cur.fetchall()]


def upsert_creator_vector(creator_id: str, vector: np.ndarray, recipe_count_sampled: int):
    """Stocke ou met à jour le creator_vector dans PostgreSQL."""
    vector_list = vector.tolist()
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO creator_vector
                    (creator_id, vector, last_computed, recipe_count_sampled)
                VALUES (%s, %s::vector, NOW(), %s)
                ON CONFLICT (creator_id) DO UPDATE SET
                    vector               = EXCLUDED.vector,
                    last_computed        = NOW(),
                    recipe_count_sampled = EXCLUDED.recipe_count_sampled
            """, (creator_id, str(vector_list), recipe_count_sampled))
        conn.commit()


def start_batch_run() -> str:
    """Crée une nouvelle ligne batch_run_log et retourne son id."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO batch_run_log (started_at, status)
                VALUES (NOW(), 'running')
                RETURNING id
            """)
            run_id = cur.fetchone()[0]
        conn.commit()
    return str(run_id)


def log_batch_failure(run_id: str, phase: str, entity_id: str, error_message: str):
    """Enregistre un échec individuel pendant le batch."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO batch_run_failure (batch_run_id, phase, entity_id, error_message)
                VALUES (%s, %s, %s, %s)
            """, (run_id, phase, entity_id, error_message))
        conn.commit()


def finish_batch_run(run_id: str, status: str, counts: dict):
    """Met à jour la ligne batch_run_log avec les résultats finaux."""
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE batch_run_log SET
                    finished_at = NOW(),
                    status = %s,
                    user_vectors_updated = %s,
                    user_vectors_attempted = %s,
                    recipe_vectors_updated = %s,
                    recipe_vectors_attempted = %s,
                    creator_vectors_updated = %s,
                    creator_vectors_attempted = %s,
                    weight_impact_updated = %s,
                    weight_impact_attempted = %s
                WHERE id = %s
            """, (
                status,
                counts["user_vectors_updated"], counts["user_vectors_attempted"],
                counts["recipe_vectors_updated"], counts["recipe_vectors_attempted"],
                counts["creator_vectors_updated"], counts["creator_vectors_attempted"],
                counts["weight_impact_updated"], counts["weight_impact_attempted"],
                run_id,
            ))
        conn.commit()
