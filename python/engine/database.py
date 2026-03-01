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
                    ARRAY_AGG(DISTINCT ug.goal_type) FILTER (WHERE ug.goal_type IS NOT NULL) AS goals,
                    ARRAY_AGG(DISTINCT udr.restriction) FILTER (WHERE udr.restriction IS NOT NULL) AS restrictions,
                    ARRAY_AGG(DISTINCT ucp.region) FILTER (WHERE ucp.region IS NOT NULL) AS cuisine_regions
                FROM user_health_profile uhp
                LEFT JOIN user_goal ug ON ug.user_id = uhp.user_id AND ug.is_active = true
                LEFT JOIN user_dietary_restriction udr ON udr.user_id = uhp.user_id
                LEFT JOIN user_cuisine_preference ucp ON ucp.user_id = uhp.user_id
                WHERE uhp.user_id = %s
                GROUP BY uhp.sex, uhp.birth_date, uhp.height_cm, uhp.weight_kg,
                         uhp.target_weight_kg, uhp.activity_level
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
                WHERE log_date >= %s::date
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
                    rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g, rm.fiber_g,
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
