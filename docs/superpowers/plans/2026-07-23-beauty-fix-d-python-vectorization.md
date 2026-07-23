# Beauty Mode Fix — Area D: Python Vectorization Engine

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 11 Area-D findings from `docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md` so the Python vectorization engine correctly computes, refreshes, and tests both nutrition and beauty 50D vectors.
**Architecture:** `python/main.py` (FastAPI endpoints + nightly batch) calls into `python/engine/vectorization.py` (pure vector math over `HAIR_TYPE_SPECTRUM`/`POROSITY_SPECTRUM`/`SKIN_TYPE_SPECTRUM`/`SCALP_TYPE_SPECTRUM` dicts) which reads profile/log/recipe data via `python/engine/database.py` (psycopg2 SQL helpers). Mode (`"nutrition"` vs `"beauty"`) is a plain string threaded through every call — there is no DB column for it, so the nightly batch must derive it per-user from recent activity.
**Tech Stack:** Python, FastAPI, pytest, Supabase/Postgres client (psycopg2)

## Global Constraints
- Repo: c:\Users\DELL LATITUDE 7480\akeli-nutrition-app, branch `sdui`.
- Never use `--no-verify` or skip hooks. Create new commits, do not amend.
- Only touch files listed as "owned" above: `python/engine/vectorization.py`, `python/engine/database.py`, `python/main.py`, `python/tests/test_main.py`, `python/tests/test_vectorization.py`.
- Every behavioral fix must have a pytest test written FIRST (TDD), shown failing, then passing.
- All pytest commands below assume:
  ```bash
  cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app\python"
  ```
  run once per shell before the `python -m pytest ...` commands shown in each step.
- Tasks are numbered in the same order as the findings and MUST be executed in that order — later tasks' "before" code snippets assume all earlier tasks' edits are already applied.

---

### Task 1: Nightly batch must resolve each user's actual mode instead of defaulting to nutrition [Critical]

**Files:**
- Modify: `python/engine/database.py` (insert new function `get_user_last_mode` right after `get_active_users`, currently ending at line 130)
- Modify: `python/main.py:14-27` (import block), `python/main.py:186-194` (nightly-batch user loop)
- Test: `python/tests/test_vectorization.py` (append 3 new tests at end of file, after `test_compute_creator_vector_zero_norm`)
- Test: `python/tests/test_main.py` (modify existing `test_run_nightly_batch` and `test_run_nightly_batch_logs_failure_on_exception`)

**Interfaces:**
- New: `get_user_last_mode(user_id: str) -> str` in `engine/database.py`, returns `"nutrition"` or `"beauty"`.
- Changed call site: `compute_user_vector(user_id, mode=user_mode)` inside `run_nightly_batch()` (was `compute_user_vector(user_id)`).

- [ ] **Step 1: Write the failing tests for `get_user_last_mode` in `test_vectorization.py`**

  Read the current end of the file first to confirm the exact anchor:
  ```bash
  python -m pytest tests/test_vectorization.py --collect-only -q
  ```
  Confirm the last collected test is `test_compute_creator_vector_zero_norm`. Then open `python/tests/test_vectorization.py` and find this exact block (the final lines of the file):
  ```python
  @patch("engine.vectorization.get_creator_recipe_vectors")
  def test_compute_creator_vector_zero_norm(mock_get_vectors):
      """Returns None if centroid is all-zeros (degenerate case)."""
      v = np.zeros(50, dtype=np.float32)
      mock_get_vectors.return_value = [v]

      result = compute_creator_vector("creator_zero")

      assert result is None
  ```
  Append immediately after it (same file, same indentation, nothing in between):
  ```python


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
  ```

  Also update the imports at the very top of the file. Find:
  ```python
  import pytest
  from unittest.mock import patch
  import numpy as np

  from engine.vectorization import compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM
  ```
  Replace with:
  ```python
  import pytest
  from unittest.mock import patch, MagicMock
  from datetime import datetime, timedelta
  import numpy as np

  from engine.vectorization import compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM
  ```

- [ ] **Step 2: Run the new tests — confirm they FAIL**
  ```bash
  python -m pytest tests/test_vectorization.py -k "get_user_last_mode" -v
  ```
  Expected (RED): all 3 tests fail with
  ```
  ImportError: cannot import name 'get_user_last_mode' from 'engine.database'
  ```

- [ ] **Step 3: Implement `get_user_last_mode` in `python/engine/database.py`**

  Find this exact block (current end of `get_active_users`, immediately followed by the Recipe-helpers section comment):
  ```python
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
  ```
  Replace with:
  ```python
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


  def get_user_last_mode(user_id: str) -> str:
      """
      Détermine le dernier mode actif ('nutrition' ou 'beauty') d'un utilisateur.
      Un utilisateur qui n'a jamais complété l'onboarding beauté
      (user_profile.beauty_onboarding_done = false/NULL) est toujours 'nutrition'.
      Sinon, on compare l'horodatage de sa dernière activité beauté
      (MAX(beauty_log.logged_at)) à celui de sa dernière activité nutrition
      (GREATEST des MAX de meal_consumption.consumed_at et daily_nutrition_log.date) —
      le mode le plus récemment actif l'emporte.
      """
      with get_conn() as conn:
          with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
              cur.execute("""
                  SELECT COALESCE(beauty_onboarding_done, false) AS beauty_onboarding_done
                  FROM user_profile
                  WHERE id = %s
              """, (user_id,))
              profile_row = cur.fetchone()
              if not profile_row or not profile_row["beauty_onboarding_done"]:
                  return "nutrition"

              cur.execute("""
                  SELECT
                      (SELECT MAX(logged_at) FROM beauty_log WHERE user_id = %s) AS last_beauty,
                      GREATEST(
                          (SELECT MAX(consumed_at) FROM meal_consumption WHERE user_id = %s),
                          (SELECT MAX(date) FROM daily_nutrition_log WHERE user_id = %s)::timestamptz
                      ) AS last_nutrition
              """, (user_id, user_id, user_id))
              activity_row = cur.fetchone()
              last_beauty = activity_row["last_beauty"] if activity_row else None
              last_nutrition = activity_row["last_nutrition"] if activity_row else None

              if last_beauty is None:
                  return "nutrition"
              if last_nutrition is None:
                  return "beauty"
              return "beauty" if last_beauty > last_nutrition else "nutrition"


  # ---------------------------------------------------------------------------
  # Recipe helpers
  # ---------------------------------------------------------------------------
  ```

- [ ] **Step 4: Run the new tests — confirm they PASS**
  ```bash
  python -m pytest tests/test_vectorization.py -k "get_user_last_mode" -v
  ```
  Expected (GREEN): `3 passed`

- [ ] **Step 5: Write the failing integration test in `test_main.py`**

  Open `python/tests/test_main.py`. Find the exact existing block (decorators + signature + body of `test_run_nightly_batch`):
  ```python
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
  ```
  Replace with:
  ```python
  @patch("main.get_user_last_mode")
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
      mock_start_run, mock_finish_run, mock_get_last_mode,
  ):
      mock_start_run.return_value = "run-123"
      mock_get_users.return_value = ["user1", "user2"]
      mock_get_last_mode.side_effect = lambda uid: "beauty" if uid == "user1" else "nutrition"
      mock_comp_user.side_effect = [np.zeros(VECTOR_DIM), None] # Second user fails to generate vector
      
      mock_get_recipes.return_value = ["recipe1"]
      mock_comp_recipe.return_value = np.zeros(VECTOR_DIM)
      
      mock_get_creators.return_value = []
      mock_get_weight_users.return_value = []
      
      from main import run_nightly_batch
      run_nightly_batch()
      
      assert mock_up_user.call_count == 1 # Only one successful vector
      assert mock_up_recipe.call_count == 1 # One successful vector
      # Finding #1: each user's mode must be resolved via get_user_last_mode and
      # threaded through to compute_user_vector — nightly batch must not silently
      # default every user to mode="nutrition".
      mock_comp_user.assert_any_call("user1", mode="beauty")
      mock_comp_user.assert_any_call("user2", mode="nutrition")
      mock_start_run.assert_called_once()
      mock_finish_run.assert_called_once_with("run-123", "completed", {
          "user_vectors_updated": 1, "user_vectors_attempted": 2,
          "recipe_vectors_updated": 1, "recipe_vectors_attempted": 1,
          "creator_vectors_updated": 0, "creator_vectors_attempted": 0,
          "weight_impact_updated": 0, "weight_impact_attempted": 0,
      })
  ```

  Now find the exact existing block for `test_run_nightly_batch_logs_failure_on_exception`:
  ```python
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
  ```
  Replace with:
  ```python
  @patch("main.get_user_last_mode")
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
      mock_log_failure, mock_start_run, mock_finish_run, mock_get_last_mode,
  ):
      mock_start_run.return_value = "run-456"
      mock_get_users.return_value = ["user1"]
      mock_get_last_mode.return_value = "nutrition"
      mock_comp_user.side_effect = Exception("boom")
      mock_get_recipes.return_value = []
      mock_get_creators.return_value = []
      mock_get_weight_users.return_value = []
      
      from main import run_nightly_batch
      run_nightly_batch()
      
      mock_log_failure.assert_called_once_with("run-456", "user_vector", "user1", "boom")
  ```

- [ ] **Step 6: Run the modified tests — confirm they FAIL**
  ```bash
  python -m pytest tests/test_main.py -k "test_run_nightly_batch" -v
  ```
  Expected (RED): both tests error with
  ```
  AttributeError: <module 'main' from '...\main.py'> does not have the attribute 'get_user_last_mode'
  ```

- [ ] **Step 7: Implement the fix in `python/main.py`**

  Find:
  ```python
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
  ```
  Replace with:
  ```python
  from engine.database import (
      upsert_user_vector,
      upsert_recipe_vector,
      get_active_users,
      get_user_last_mode,
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
  ```

  Find:
  ```python
          for user_id in active_users:
              try:
                  vector = compute_user_vector(user_id)
                  if vector is not None:
                      upsert_user_vector(user_id, vector)
                      counts["user_vectors_updated"] += 1
              except Exception as e:
                  logger.error(f"[nightly-batch] User {user_id} failed: {e}")
                  log_batch_failure(run_id, "user_vector", user_id, str(e))
  ```
  Replace with:
  ```python
          for user_id in active_users:
              try:
                  user_mode = get_user_last_mode(user_id)
                  vector = compute_user_vector(user_id, mode=user_mode)
                  if vector is not None:
                      upsert_user_vector(user_id, vector)
                      counts["user_vectors_updated"] += 1
              except Exception as e:
                  logger.error(f"[nightly-batch] User {user_id} failed: {e}")
                  log_batch_failure(run_id, "user_vector", user_id, str(e))
  ```

- [ ] **Step 8: Run the modified tests — confirm they PASS**
  ```bash
  python -m pytest tests/test_main.py -v
  ```
  Expected (GREEN): all tests in the file pass, no `FAILED` lines.

---

### Task 2: `get_active_users()` must include pure-beauty users (never queries `beauty_log`) [High]

**Files:**
- Modify: `python/engine/database.py:118-130` (`get_active_users`)
- Test: `python/tests/test_vectorization.py` (append after Task 1's new tests)

**Interfaces:** `get_active_users(days: int = 7) -> list[str]` — SQL body changes, signature unchanged.

- [ ] **Step 1: Write the failing test**

  Append to the end of `python/tests/test_vectorization.py` (after `test_get_user_last_mode_recent_nutrition_activity_returns_nutrition` added in Task 1):
  ```python


  @patch("engine.database.get_conn")
  def test_get_active_users_unions_beauty_log(mock_get_conn):
      """get_active_users() must also return users active via beauty_log — not
      just meal_consumption/daily_nutrition_log (Finding #2: pure-beauty users
      were never refreshed by the nightly batch)."""
      from engine.database import get_active_users

      mock_cur = MagicMock()
      mock_cur.fetchall.return_value = [("user1",), ("user2",)]
      mock_conn = MagicMock()
      mock_conn.__enter__.return_value = mock_conn
      mock_conn.cursor.return_value.__enter__.return_value = mock_cur
      mock_get_conn.return_value = mock_conn

      result = get_active_users(days=7)

      assert result == ["user1", "user2"]
      executed_sql = mock_cur.execute.call_args[0][0]
      assert "beauty_log" in executed_sql, "get_active_users() SQL must UNION in beauty_log activity"
  ```

- [ ] **Step 2: Run — confirm FAIL**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_get_active_users_unions_beauty_log" -v
  ```
  Expected (RED):
  ```
  AssertionError: get_active_users() SQL must UNION in beauty_log activity
  ```

- [ ] **Step 3: Implement the fix**

  Find:
  ```python
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
  ```
  Replace with:
  ```python
  def get_active_users(days: int = 7) -> list[str]:
      """Retourne les user_ids actifs (nutrition OU beauty) dans les N derniers jours."""
      since = (datetime.now() - timedelta(days=days)).isoformat()
      with get_conn() as conn:
          with conn.cursor() as cur:
              cur.execute("""
                  SELECT DISTINCT user_id FROM meal_consumption
                  WHERE consumed_at >= %s
                  UNION
                  SELECT DISTINCT user_id FROM daily_nutrition_log
                  WHERE date >= %s::date
                  UNION
                  SELECT DISTINCT user_id FROM beauty_log
                  WHERE logged_at >= %s
              """, (since, since, since))
              return [row[0] for row in cur.fetchall()]
  ```

- [ ] **Step 4: Run — confirm PASS**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_get_active_users_unions_beauty_log" -v
  ```
  Expected (GREEN): `1 passed`

---

### Task 3: `DIM_SCALP_TYPE` (29) is never written to any vector [High]

**Files:**
- Modify: `python/engine/vectorization.py:168-181` (spectrum dicts), `python/engine/vectorization.py:238-239` (assignment in `compute_user_vector`)
- Test: `python/tests/test_vectorization.py` (append after Task 2's new test)

**Interfaces:** New module constant `SCALP_TYPE_SPECTRUM: dict[str, float]` in `engine/vectorization.py`. `compute_user_vector` gains one new unconditional assignment `vector[DIM_SCALP_TYPE] = ...`.

- [ ] **Step 1: Write the failing test**

  Update the imports at the top of `python/tests/test_vectorization.py`. Find:
  ```python
  from engine.vectorization import compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM
  ```
  Replace with:
  ```python
  from engine.vectorization import (
      compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM,
      DIM_HAIR_TEXTURE, DIM_SCALP_TYPE, HAIR_TYPE_SPECTRUM,
  )
  ```
  (`DIM_HAIR_TEXTURE`, `DIM_SCALP_TYPE`, `HAIR_TYPE_SPECTRUM` already exist in the current file — this import is safe today. `SCALP_TYPE_SPECTRUM` does not exist yet, so it is imported locally inside the new test below to keep the RED failure scoped to that one test.)

  Append to the end of the file (after `test_get_active_users_unions_beauty_log`):
  ```python


  @patch("engine.vectorization.get_latest_beauty_log")
  @patch("engine.vectorization.get_user_health_profile")
  def test_compute_user_vector_writes_scalp_type_dimension(mock_get_profile, mock_get_log):
      """DIM_SCALP_TYPE (29) must be written from SCALP_TYPE_SPECTRUM — it is
      currently ALWAYS 0.0 because no code path assigns it (Finding #3)."""
      from engine.vectorization import SCALP_TYPE_SPECTRUM  # does not exist yet -> ImportError pre-fix

      mock_get_log.return_value = None
      mock_get_profile.return_value = {
          "hair_type": "4C", "porosity": "high", "skin_type": "dry",
          "scalp_type": "flaky", "beauty_goals": [],
      }

      vector = compute_user_vector("user_scalp_test", mode="beauty")

      assert vector is not None
      assert vector[DIM_SCALP_TYPE] != 0.0
      # DIM_SCALP_TYPE is NOT in the 2x amplification set; DIM_HAIR_TEXTURE IS.
      # Their ratio after L2-normalization equals the ratio of their raw
      # (pre-normalization) values, independent of the vector's norm:
      ratio = float(vector[DIM_SCALP_TYPE] / vector[DIM_HAIR_TEXTURE])
      assert ratio == pytest.approx(SCALP_TYPE_SPECTRUM["flaky"] / (HAIR_TYPE_SPECTRUM["4C"] * 2.0), abs=1e-6)
  ```

- [ ] **Step 2: Run — confirm FAIL**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_compute_user_vector_writes_scalp_type_dimension" -v
  ```
  Expected (RED):
  ```
  ImportError: cannot import name 'SCALP_TYPE_SPECTRUM' from 'engine.vectorization'
  ```

- [ ] **Step 3: Implement the fix in `python/engine/vectorization.py`**

  Find:
  ```python
  POROSITY_SPECTRUM = {
      "low": 0.20,
      "medium": 0.50,
      "normal": 0.50,
      "high": 1.00,
  }

  SKIN_TYPE_SPECTRUM = {
  ```
  Replace with:
  ```python
  POROSITY_SPECTRUM = {
      "low": 0.20,
      "medium": 0.50,
      "normal": 0.50,
      "high": 1.00,
  }

  SCALP_TYPE_SPECTRUM = {
      "dry": 0.10,
      "normal": 0.40,
      "oily": 0.60,
      "flaky": 1.00,
  }

  SKIN_TYPE_SPECTRUM = {
  ```

  Then find (inside `compute_user_vector`, beauty branch):
  ```python
          porosity = str(profile.get("porosity") or "high").lower()
          vector[DIM_POROSITY] = POROSITY_SPECTRUM.get(porosity, 1.0)

          skin_type = str(profile.get("skin_type") or "oily").lower()
          vector[DIM_SKIN_TYPE] = SKIN_TYPE_SPECTRUM.get(skin_type, 0.90)
  ```
  Replace with:
  ```python
          porosity = str(profile.get("porosity") or "high").lower()
          vector[DIM_POROSITY] = POROSITY_SPECTRUM.get(porosity, 1.0)

          vector[DIM_SCALP_TYPE] = SCALP_TYPE_SPECTRUM.get(profile.get("scalp_type"), 0.40)

          skin_type = str(profile.get("skin_type") or "oily").lower()
          vector[DIM_SKIN_TYPE] = SKIN_TYPE_SPECTRUM.get(skin_type, 0.90)
  ```

- [ ] **Step 4: Run — confirm PASS**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_compute_user_vector_writes_scalp_type_dimension" -v
  ```
  Expected (GREEN): `1 passed`

- [ ] **Step 5: Full-file regression check**
  ```bash
  python -m pytest tests/test_vectorization.py -v
  ```
  Expected: no `FAILED` lines (the new nonzero `DIM_SCALP_TYPE` contribution changes vector norms but all existing assertions use `> 0.0` bounds or values unaffected by dim 29 — see Coverage Checklist note under Task 5).

---

### Task 4: 3 of 15 onboarding hair-type options have no `HAIR_TYPE_SPECTRUM` entry, silent fallback [High]

**Files:**
- Modify: `python/engine/vectorization.py:29-32` (imports), `python/engine/vectorization.py:160-166` (`HAIR_TYPE_SPECTRUM`), `python/engine/vectorization.py:235-236` (user-side lookup), `python/engine/vectorization.py:390-391` (recipe-side lookup)
- Test: `python/tests/test_vectorization.py` (append after Task 3's new test)

**Interfaces:** No signature changes. `HAIR_TYPE_SPECTRUM` gains 3 keys. Both lookup call sites change from `.get(x, default)` to an explicit `if x not in DICT: log; default else: DICT[x]` structure.

Confirmed exact onboarding option strings from `lib/features/beauty/beauty_onboarding_page.dart` (DropdownMenuItem values): `'Locks'`, `'Transition'`, `'Protective'`. Both lookup sites call `.upper()` on the value before the dict lookup, so the dict keys must be `"LOCKS"`, `"TRANSITION"`, `"PROTECTIVE"`.

- [ ] **Step 1: Write the failing tests**

  Update the imports. Find:
  ```python
  from engine.vectorization import (
      compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM,
      DIM_HAIR_TEXTURE, DIM_SCALP_TYPE, HAIR_TYPE_SPECTRUM,
  )
  ```
  Replace with:
  ```python
  import logging

  from engine.vectorization import (
      compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM,
      DIM_HAIR_TEXTURE, DIM_SCALP_TYPE, HAIR_TYPE_SPECTRUM, SCALP_TYPE_SPECTRUM,
  )
  ```
  (`SCALP_TYPE_SPECTRUM` now safely exists at module level — Task 3 already implemented it.)

  Append to the end of the file (after `test_compute_user_vector_writes_scalp_type_dimension`):
  ```python


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
          vector = compute_recipe_vector("recipe_unknown_hair")

      assert vector is not None
      assert any("HAIR_TYPE_SPECTRUM" in record.message for record in caplog.records)
  ```

- [ ] **Step 2: Run — confirm FAIL**
  ```bash
  python -m pytest tests/test_vectorization.py -k "hair_type_spectrum or locks_hairtype or unknown_hair_type or unknown_suitable_hair_type" -v
  ```
  Expected (RED): `test_hair_type_spectrum_covers_locks_transition_protective` fails with `KeyError: 'LOCKS'`; `test_compute_user_vector_maps_locks_hairtype_end_to_end` fails with `KeyError: 'LOCKS'`; the two logging tests fail with
  ```
  AssertionError: assert False
   +  where False = any(<generator object ...>)
  ```
  (caplog has zero warning records).

- [ ] **Step 3: Implement the fix in `python/engine/vectorization.py`**

  Add the `logging` import. Find:
  ```python
  from __future__ import annotations
  from datetime import datetime
  from typing import Optional
  import numpy as np
  ```
  Replace with:
  ```python
  from __future__ import annotations
  from datetime import datetime
  from typing import Optional
  import logging
  import numpy as np
  ```

  Extend the spectrum dict. Find:
  ```python
  HAIR_TYPE_SPECTRUM = {
      "1A": 0.10, "1B": 0.10, "1C": 0.15,
      "2A": 0.25, "2B": 0.30, "2C": 0.40,
      "3A": 0.50, "3B": 0.60, "3C": 0.70,
      "4A": 0.80, "4B": 0.90, "4C": 1.00,
      "1": 0.10, "2": 0.30, "3": 0.60, "4": 0.90,
  }
  ```
  Replace with:
  ```python
  HAIR_TYPE_SPECTRUM = {
      "1A": 0.10, "1B": 0.10, "1C": 0.15,
      "2A": 0.25, "2B": 0.30, "2C": 0.40,
      "3A": 0.50, "3B": 0.60, "3C": 0.70,
      "4A": 0.80, "4B": 0.90, "4C": 1.00,
      "1": 0.10, "2": 0.30, "3": 0.60, "4": 0.90,
      # Onboarding dropdown options with no numeric hair-type code (Finding #4):
      "LOCKS": 0.85, "TRANSITION": 0.55, "PROTECTIVE": 0.85,
  }
  ```

  Fix the user-side lookup. Find:
  ```python
          hair_type = str(profile.get("hair_type") or "4C").upper()
          vector[DIM_HAIR_TEXTURE] = HAIR_TYPE_SPECTRUM.get(hair_type, 0.90)
  ```
  Replace with:
  ```python
          hair_type = str(profile.get("hair_type") or "4C").upper()
          if hair_type not in HAIR_TYPE_SPECTRUM:
              logging.warning(
                  f"HAIR_TYPE_SPECTRUM missing entry for hair_type={hair_type!r} "
                  f"(user_id={user_id}) — falling back to 0.90"
              )
              vector[DIM_HAIR_TEXTURE] = 0.90
          else:
              vector[DIM_HAIR_TEXTURE] = HAIR_TYPE_SPECTRUM[hair_type]
  ```

  Fix the recipe-side lookup. Find:
  ```python
          suitable_hair = str(recipe.get("suitable_hair_type") or "4C").upper()
          vector[DIM_HAIR_TEXTURE] = HAIR_TYPE_SPECTRUM.get(suitable_hair, 0.85)
  ```
  Replace with:
  ```python
          suitable_hair = str(recipe.get("suitable_hair_type") or "4C").upper()
          if suitable_hair not in HAIR_TYPE_SPECTRUM:
              logging.warning(
                  f"HAIR_TYPE_SPECTRUM missing entry for suitable_hair_type={suitable_hair!r} "
                  f"(recipe_id={recipe_id}) — falling back to 0.85"
              )
              vector[DIM_HAIR_TEXTURE] = 0.85
          else:
              vector[DIM_HAIR_TEXTURE] = HAIR_TYPE_SPECTRUM[suitable_hair]
  ```

- [ ] **Step 4: Run — confirm PASS**
  ```bash
  python -m pytest tests/test_vectorization.py -k "hair_type_spectrum or locks_hairtype or unknown_hair_type or unknown_suitable_hair_type" -v
  ```
  Expected (GREEN): `4 passed`

- [ ] **Step 5: Full-file regression check**
  ```bash
  python -m pytest tests/test_vectorization.py -v
  ```
  Expected: no `FAILED` lines.

---

### Task 5: Beauty tests assert loose bounds instead of exact spectrum-derived values [Medium]

**Files:**
- Modify: `python/tests/test_vectorization.py` — rewrite `test_compute_beauty_user_vector`, `test_user_vector_beauty_log_dynamic_metrics`, `test_compute_creator_beauty_recipe_vector`, `test_premade_product_vs_diy_recipe_vectorization`, `test_hybrid_selective_virtue_masking` (all pre-existing, no line-number drift risk since all edits use unique `old_string` anchors)

**Interfaces:** None (test-only). Adds two test-local helper functions: `_expected_normalized(raw: dict) -> np.ndarray` (user-side, mirrors the 2x amplification) and `_expected_normalized_recipe(raw: dict) -> np.ndarray` (recipe-side, no amplification).

This task does not touch production code — every test below already passes today on the loose `> 0.0` bound; the point is to replace that bound with the exact value the documented spectrum dicts imply, so a materially wrong weight would be caught. `test_continuous_hair_type_spectrum_similarity` (which asserts `similarity > 0.40`, a derived cosine value, not a raw spectrum lookup) is intentionally left unchanged — it is out of this finding's scope.

- [ ] **Step 1: Add the two test helpers and finish the import block**

  Find:
  ```python
  import logging

  from engine.vectorization import (
      compute_user_vector, compute_recipe_vector, compute_creator_vector, VECTOR_DIM,
      DIM_HAIR_TEXTURE, DIM_SCALP_TYPE, HAIR_TYPE_SPECTRUM, SCALP_TYPE_SPECTRUM,
  )
  ```
  Replace with:
  ```python
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
  ```

- [ ] **Step 2: Rewrite `test_compute_beauty_user_vector`**

  Find:
  ```python
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
  ```
  Replace with:
  ```python
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
          DIM_SCALP_TYPE: 0.40,   # no scalp_type in profile -> compute_user_vector's documented default
          DIM_SKIN_TYPE: SKIN_TYPE_SPECTRUM["dry"],          # 0.10
          GOAL_HAIR_GROWTH: 1.0,                               # "growth" in beauty_goals
          GOAL_SKIN_GLOW: 1.0,                                 # "glow" in beauty_goals
      })
      np.testing.assert_allclose(vector, expected, atol=1e-6)
  ```

- [ ] **Step 3: Rewrite `test_user_vector_beauty_log_dynamic_metrics`**

  Find:
  ```python
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
      assert vec[31] > 0.0  # GOAL_HAIR_GROWTH
      assert vec[32] > 0.0  # GOAL_HAIR_ANTI_BREAKAGE boosted dynamically from beauty log!
  ```
  Replace with:
  ```python
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
          DIM_SCALP_TYPE: 0.40,
          DIM_SKIN_TYPE: SKIN_TYPE_SPECTRUM["dry"],
          GOAL_HAIR_GROWTH: 1.0,          # "growth_retention" in beauty_goals
          GOAL_HAIR_ANTI_BREAKAGE: 1.0,   # boosted: hair_strength_score 3.5 < 5.0
      })
      np.testing.assert_allclose(vec, expected, atol=1e-6)
  ```

- [ ] **Step 4: Rewrite `test_compute_creator_beauty_recipe_vector`**

  Find:
  ```python
      vector = compute_recipe_vector("creator_beauty_remedy_id", mode="beauty")

      assert vector is not None
      assert len(vector) == VECTOR_DIM
      assert np.isclose(np.linalg.norm(vector), 1.0)
      assert vector[27] > 0.0  # DIM_HAIR_TEXTURE (0.90 for Type 4)
      assert vector[28] > 0.0  # DIM_POROSITY (1.0 for heavy_butter)
      assert vector[31] > 0.0  # GOAL_HAIR_GROWTH (0.95 from chebe)
      assert vector[32] > 0.0  # GOAL_HAIR_ANTI_BREAKAGE (0.90 from chebe & shea)
      assert vector[41] > 0.0  # GOAL_SKIN_BARRIER (0.95 from dry_skin_moisture / barrier_repair)
  ```
  Replace with:
  ```python
      vector = compute_recipe_vector("creator_beauty_remedy_id", mode="beauty")

      assert vector is not None
      assert len(vector) == VECTOR_DIM
      assert np.isclose(np.linalg.norm(vector), 1.0)

      expected = _expected_normalized_recipe({
          DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4"],   # 0.90 for Type 4
          DIM_POROSITY: 1.00,                            # heavy_butter formulation
          DIM_SKIN_TYPE: 0.50,                           # no skin_target -> neutral default
          GOAL_HAIR_GROWTH: 1.0,                          # max(tags 1.0, chebe 0.95)
          GOAL_HAIR_ANTI_BREAKAGE: 1.0,                   # max(tags 1.0, shea 0.85, chebe 0.90)
          GOAL_HAIR_MOISTURE: 0.90,                       # shea_butter intense_hydration
          GOAL_SKIN_BARRIER: 0.95,                        # shea_butter moisture_barrier
      })
      np.testing.assert_allclose(vector, expected, atol=1e-6)
  ```

- [ ] **Step 5: Rewrite `test_premade_product_vs_diy_recipe_vectorization`**

  Find:
  ```python
      vector = compute_recipe_vector("premade_product_id", mode="beauty")
      assert vector is not None
      assert vector[31] > 0.0  # GOAL_HAIR_GROWTH (0.95 explicit)
      assert vector[38] > 0.0  # GOAL_HAIR_SHINE (0.85 explicit)
      assert vector[32] == 0.0  # GOAL_HAIR_ANTI_BREAKAGE is 0 because premade product uses explicit creator vector
  ```
  Replace with:
  ```python
      vector = compute_recipe_vector("premade_product_id", mode="beauty")
      assert vector is not None

      expected = _expected_normalized_recipe({
          DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4C"],  # no suitable_hair_type -> defaults to "4C" -> 1.00
          DIM_POROSITY: 0.50,                            # no formulation -> neutral default
          DIM_SKIN_TYPE: 0.50,                           # no skin_target -> neutral default
          GOAL_HAIR_GROWTH: 0.95,                         # explicit creator virtue_weights["growth_retention"]
          GOAL_HAIR_SHINE: 0.85,                          # explicit creator virtue_weights["shine_softness"]
      })
      np.testing.assert_allclose(vector, expected, atol=1e-6)
      assert vector[GOAL_HAIR_ANTI_BREAKAGE] == 0.0  # premade product ignores ingredient_details entirely
  ```

- [ ] **Step 6: Rewrite `test_hybrid_selective_virtue_masking`**

  Find:
  ```python
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
  ```
  Replace with:
  ```python
      # 1. Without active_goals masking: shine_softness (dim 38) is present
      full_vector = compute_recipe_vector("recipe_mask_test", mode="beauty")
      assert full_vector is not None
      expected_full = _expected_normalized_recipe({
          DIM_HAIR_TEXTURE: HAIR_TYPE_SPECTRUM["4C"],   # 1.00
          DIM_POROSITY: 1.00,                             # heavy_butter
          DIM_SKIN_TYPE: 0.50,                            # no skin_target -> neutral default
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
          GOAL_HAIR_GROWTH: 0.95,
          # GOAL_HAIR_SHINE omitted entirely -> masked to 0.0
      })
      np.testing.assert_allclose(masked_vector, expected_masked, atol=1e-6)
      assert masked_vector[GOAL_HAIR_SHINE] == 0.0  # SELECTIVELY NULLIFIED
  ```

- [ ] **Step 7: Run all 5 rewritten tests — confirm they FAIL first**

  Before applying Steps 2-6, run:
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_compute_beauty_user_vector or test_user_vector_beauty_log_dynamic_metrics or test_compute_creator_beauty_recipe_vector or test_premade_product_vs_diy_recipe_vectorization or test_hybrid_selective_virtue_masking" -v
  ```
  Expected (RED, using the OLD loose-bound test bodies but the NEW `_expected_normalized` helper not yet referenced): this step is a checkpoint — apply Step 1 (helpers) first, confirm the file still collects (`5 passed` using old bodies, since helpers are unused yet), THEN apply Steps 2-6 one at a time, re-running the single affected test after each edit to confirm it still passes (it is a like-for-like tightening, not new behavior, so there is no "RED" state here — the reformulated assertion is mathematically equivalent to what the code already produces). Confirm each rewritten test passes individually:
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_compute_beauty_user_vector" -v
  python -m pytest tests/test_vectorization.py -k "test_user_vector_beauty_log_dynamic_metrics" -v
  python -m pytest tests/test_vectorization.py -k "test_compute_creator_beauty_recipe_vector" -v
  python -m pytest tests/test_vectorization.py -k "test_premade_product_vs_diy_recipe_vectorization" -v
  python -m pytest tests/test_vectorization.py -k "test_hybrid_selective_virtue_masking" -v
  ```
  Expected (GREEN) for each: `1 passed`.

  > Note: unlike other tasks, this finding tightens existing correct-passing tests rather than fixing a code defect, so there is no separate red-then-green code change — the "TDD" step here is verifying the exact-value rewrite still agrees with the (unchanged) production math, which is exactly what makes the tightened assertion trustworthy.

- [ ] **Step 8: Full-file regression check**
  ```bash
  python -m pytest tests/test_vectorization.py -v
  ```
  Expected: no `FAILED` lines.

---

### Task 6: Recipe-side skin-type encoding hardcodes `oily`/`acne` to the same 0.90 [Medium]

**Files:**
- Modify: `python/engine/vectorization.py:401-407` (`compute_recipe_vector` skin_target branch)
- Test: `python/tests/test_vectorization.py` (append after Task 5's rewrites)

**Interfaces:** No signature changes.

- [ ] **Step 1: Write the failing test**

  Append to the end of the file:
  ```python


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
  ```

- [ ] **Step 2: Run — confirm FAIL**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_recipe_skin_type_spectrum_distinguishes_oily_from_acne" -v
  ```
  Expected (RED):
  ```
  AssertionError: assert 1.0 == 0.9 ± ... (acne_ratio pytest.approx SKIN_TYPE_SPECTRUM["acne"]/HAIR_TYPE_SPECTRUM["4C"])
  ```
  (both `oily_ratio` and `acne_ratio` currently equal `0.90`, so the `acne_ratio` comparison against `1.00` fails.)

- [ ] **Step 3: Implement the fix**

  Find:
  ```python
          skin_target = str(recipe.get("skin_target") or "").lower()
          if skin_target in ("oily", "acne"):
              vector[DIM_SKIN_TYPE] = 0.90
          elif skin_target == "dry":
              vector[DIM_SKIN_TYPE] = 0.10
          else:
              vector[DIM_SKIN_TYPE] = 0.50
  ```
  Replace with:
  ```python
          skin_target = str(recipe.get("skin_target") or "").lower()
          vector[DIM_SKIN_TYPE] = SKIN_TYPE_SPECTRUM.get(skin_target, 0.50)
  ```

- [ ] **Step 4: Run — confirm PASS**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_recipe_skin_type_spectrum_distinguishes_oily_from_acne" -v
  ```
  Expected (GREEN): `1 passed`

- [ ] **Step 5: Full-file regression check**
  ```bash
  python -m pytest tests/test_vectorization.py -v
  ```
  Expected: no `FAILED` lines (Task 5's Tests D/E/F all have `skin_target` absent, so `.get("", 0.50)` reproduces the exact same `0.50` the old else-branch produced — no regression).

---

### Task 7: 2x goal-weight amplification covers only 6 of 18 goal/virtue dims, undocumented [Medium]

**Files:**
- Modify: `python/engine/vectorization.py:175-181` (insert constants after `SKIN_TYPE_SPECTRUM`), `python/engine/vectorization.py:300-304` (amplification loop)
- Test: `python/tests/test_vectorization.py` (append after Task 6's test)

**Interfaces:** New module constants `AMPLIFIED_ATTRIBUTE_DIMS: tuple[int, ...]` (3 members) and `AMPLIFIED_GOAL_DIMS: tuple[int, ...]` (6 members) in `engine/vectorization.py`. Do NOT expand amplification to the other 12 goal/virtue dims — that is a product decision, flagged in the Coverage Checklist, not made here.

- [ ] **Step 1: Write the failing test**

  Append to the end of the file:
  ```python


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
  ```

- [ ] **Step 2: Run — confirm FAIL**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_amplified_goal_dims_is_exactly_six_members" -v
  ```
  Expected (RED):
  ```
  ImportError: cannot import name 'AMPLIFIED_GOAL_DIMS' from 'engine.vectorization'
  ```

- [ ] **Step 3: Implement the fix**

  Find (current state after Task 3 already inserted `SCALP_TYPE_SPECTRUM` above `SKIN_TYPE_SPECTRUM`):
  ```python
  SKIN_TYPE_SPECTRUM = {
      "dry": 0.10,
      "normal": 0.50,
      "combination": 0.50,
      "oily": 0.90,
      "acne": 1.00,
  }


  def _normalize_l2(v: np.ndarray) -> np.ndarray:
  ```
  Replace with:
  ```python
  SKIN_TYPE_SPECTRUM = {
      "dry": 0.10,
      "normal": 0.50,
      "combination": 0.50,
      "oily": 0.90,
      "acne": 1.00,
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
  ```

  Find:
  ```python
          # Goal weight amplification
          for dim in (DIM_HAIR_TEXTURE, DIM_POROSITY, DIM_SKIN_TYPE,
                      GOAL_HAIR_GROWTH, GOAL_HAIR_ANTI_BREAKAGE, GOAL_HAIR_MOISTURE,
                      GOAL_SKIN_GLOW, GOAL_SKIN_BARRIER, GOAL_SKIN_SEBUM_ACNE):
              vector[dim] *= 2.0
  ```
  Replace with:
  ```python
          # Goal weight amplification
          for dim in AMPLIFIED_ATTRIBUTE_DIMS + AMPLIFIED_GOAL_DIMS:
              vector[dim] *= 2.0
  ```

  This preserves the exact same 9 dims multiplied by 2.0 (identical runtime behavior, zero numeric change) — it only gives the goal-only subset a name and a size assertion.

- [ ] **Step 4: Run — confirm PASS**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_amplified_goal_dims_is_exactly_six_members" -v
  ```
  Expected (GREEN): `1 passed`

- [ ] **Step 5: Full-file regression check**
  ```bash
  python -m pytest tests/test_vectorization.py -v
  ```
  Expected: no `FAILED` lines (behavior-preserving rename — every Task 5 exact-value test still matches).

---

### Task 8: Missing-field fallback defaults skew to spectrum extremes, inconsistent with DB defaults [Low]

**Files:**
- Modify: `python/engine/vectorization.py:238,241` (`compute_user_vector` fallback strings)
- Test: `python/tests/test_vectorization.py` (append after Task 7's test)

**Interfaces:** No signature changes.

Verified against `supabase/migrations/20260720000003_add_beauty_diagnostic_columns.sql`: `porosity VARCHAR(20) DEFAULT 'medium'`, `skin_type VARCHAR(20) DEFAULT 'combination'`. Both `'medium'` and `'combination'` already exist as keys in `POROSITY_SPECTRUM`/`SKIN_TYPE_SPECTRUM` (no dict addition needed).

- [ ] **Step 1: Write the failing test**

  Append to the end of the file:
  ```python


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
      # amplified, fixed here at "normal"=0.40) isolates each raw fallback value.
      porosity_ratio = float(vector[DIM_POROSITY] / vector[DIM_SCALP_TYPE])
      assert porosity_ratio == pytest.approx((POROSITY_SPECTRUM["medium"] * 2.0) / SCALP_TYPE_SPECTRUM["normal"], abs=1e-6)

      skin_ratio = float(vector[DIM_SKIN_TYPE] / vector[DIM_SCALP_TYPE])
      assert skin_ratio == pytest.approx((SKIN_TYPE_SPECTRUM["combination"] * 2.0) / SCALP_TYPE_SPECTRUM["normal"], abs=1e-6)
  ```

- [ ] **Step 2: Run — confirm FAIL**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_missing_porosity_and_skin_type_fall_back_to_db_neutral_defaults" -v
  ```
  Expected (RED): `porosity_ratio` is currently `5.0` (from fallback `"high"`) vs expected `2.5` (from `"medium"`) —
  ```
  AssertionError: assert 5.0 == 2.5 ± ...
  ```

- [ ] **Step 3: Implement the fix**

  Find:
  ```python
          porosity = str(profile.get("porosity") or "high").lower()
  ```
  Replace with:
  ```python
          porosity = str(profile.get("porosity") or "medium").lower()
  ```

  Find:
  ```python
          skin_type = str(profile.get("skin_type") or "oily").lower()
  ```
  Replace with:
  ```python
          skin_type = str(profile.get("skin_type") or "combination").lower()
  ```

- [ ] **Step 4: Run — confirm PASS**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_missing_porosity_and_skin_type_fall_back_to_db_neutral_defaults" -v
  ```
  Expected (GREEN): `1 passed`

- [ ] **Step 5: Full-file regression check**
  ```bash
  python -m pytest tests/test_vectorization.py -v
  ```
  Expected: no `FAILED` lines. (`test_continuous_hair_type_spectrum_similarity`'s profile omits `skin_type` too — verified by hand: with the new `"combination"`=0.50 default its cosine similarity moves from ≈0.927 to ≈0.936, still comfortably above the test's `> 0.40` threshold.)

---

### Task 9: Doc/code mismatch — architecture log claims `1A-1C=0.10`, code has `1C: 0.15` [Low]

**Files:**
- Modify: `docs/BEAUTY_MODE_ARCHITECTURE_LOG.md:34`

**Interfaces:** None (documentation only).

- [ ] **Step 1: Correct the doc line**

  This finding has no test (documentation-only change). Find (line 34):
  ```
    [27]          DIM_HAIR_TEXTURE                               Continuous Spectrum: 1A-1C=0.10 ... 4C=1.00
  ```
  Replace with the full, real `HAIR_TYPE_SPECTRUM` values (including the 3 entries added by Task 4):
  ```
    [27]          DIM_HAIR_TEXTURE                               Continuous Spectrum: 1A=0.10, 1B=0.10, 1C=0.15, 2A=0.25, 2B=0.30, 2C=0.40, 3A=0.50, 3B=0.60, 3C=0.70, 4A=0.80, 4B=0.90, 4C=1.00, Locks=0.85, Transition=0.55, Protective=0.85
  ```

- [ ] **Step 2: Verify**
  ```bash
  grep -n "DIM_HAIR_TEXTURE" "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app\docs\BEAUTY_MODE_ARCHITECTURE_LOG.md"
  ```
  Expected: the printed line 34 now reads the corrected text above, matching `HAIR_TYPE_SPECTRUM` in `python/engine/vectorization.py` exactly.

---

### Task 10: Silent `except Exception: pass` around check-in-boost fetch, no logging [Low]

**Files:**
- Modify: `python/engine/vectorization.py:297-298` (`compute_user_vector` beauty-log try/except)
- Test: `python/tests/test_vectorization.py` (append after Task 8's test)

**Interfaces:** No signature changes.

- [ ] **Step 1: Write the failing test**

  Append to the end of the file:
  ```python


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
  ```

- [ ] **Step 2: Run — confirm FAIL**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_beauty_log_fetch_failure_is_logged_not_silenced" -v
  ```
  Expected (RED):
  ```
  AssertionError: assert False
   +  where False = any(<generator object ...>)
  ```
  (caplog has zero records — the current `except Exception: pass` swallows the failure with no log call.)

- [ ] **Step 3: Implement the fix**

  Find:
  ```python
                  # Scalp health score boost
                  scalp_health = latest_log.get("scalp_health_score")
                  if scalp_health is not None and float(scalp_health) < 5.0:
                      vector[GOAL_SCALP_SOOTHING] = max(vector[GOAL_SCALP_SOOTHING], 1.0)
          except Exception:
              pass
  ```
  Replace with:
  ```python
                  # Scalp health score boost
                  scalp_health = latest_log.get("scalp_health_score")
                  if scalp_health is not None and float(scalp_health) < 5.0:
                      vector[GOAL_SCALP_SOOTHING] = max(vector[GOAL_SCALP_SOOTHING], 1.0)
          except Exception as e:
              logging.warning(
                  f"get_latest_beauty_log check-in boost skipped for user_id={user_id}: {e}"
              )
  ```

- [ ] **Step 4: Run — confirm PASS**
  ```bash
  python -m pytest tests/test_vectorization.py -k "test_beauty_log_fetch_failure_is_logged_not_silenced" -v
  ```
  Expected (GREEN): `1 passed`

- [ ] **Step 5: Full-suite regression check**
  ```bash
  python -m pytest tests/ -v
  ```
  Expected: no `FAILED` lines across both `test_vectorization.py` and `test_main.py`.

---

### Task 11: `test_main.py` never posts `mode: "beauty"` through the actual FastAPI endpoint

**Files:**
- Modify: `python/tests/test_main.py` (append new test at end of file)

**Interfaces:** None — this task adds regression-test coverage only. Reading `api_compute_user_vector` in `python/main.py` confirms it already threads `request.mode` through to `compute_user_vector(request.user_id, mode=request.mode)` correctly (this is the ONBOARDING endpoint, separate from the nightly batch fixed in Task 1). There is no known defect at this endpoint, so — unlike every other task in this plan — this test is expected to PASS on its very first run with no production-code change. It exists to guard against a future regression, per the finding's explicit framing as a coverage gap, not a bug.

- [ ] **Step 1: Add the test**

  Append to the end of `python/tests/test_main.py`:
  ```python


  @patch("main.upsert_user_vector")
  @patch("main.compute_user_vector")
  def test_compute_user_vector_endpoint_beauty_mode(mock_compute, mock_upsert):
      """/compute-user-vector must thread mode="beauty" through to compute_user_vector
      end-to-end via the real FastAPI TestClient (Finding #11 — this path was never
      exercised; only mocked-function unit assertions existed before)."""
      mock_compute.return_value = np.zeros(VECTOR_DIM, dtype=np.float32)

      response = client.post("/compute-user-vector", json={"user_id": "user_beauty_1", "mode": "beauty"})

      assert response.status_code == 200
      assert response.json()["user_id"] == "user_beauty_1"
      assert response.json()["mode"] == "beauty"
      assert response.json()["vector_computed"] is True
      mock_compute.assert_called_once_with("user_beauty_1", mode="beauty")
      mock_upsert.assert_called_once()
  ```

- [ ] **Step 2: Run — confirm it PASSES immediately (no production code change)**
  ```bash
  python -m pytest tests/test_main.py -k "test_compute_user_vector_endpoint_beauty_mode" -v
  ```
  Expected: `1 passed` — this confirms the endpoint already correctly threads `mode` end-to-end; no change to `python/main.py` is needed for this finding.

- [ ] **Step 3: Full-suite regression check**
  ```bash
  python -m pytest tests/ -v
  ```
  Expected: no `FAILED` lines.

---

## Coverage Checklist

| # | Finding | Task | Status |
|---|---------|------|--------|
| 1 | Nightly batch calls `compute_user_vector(user_id)` with no mode, defaulting every user to nutrition | Task 1 | Fixed |
| 2 | `get_active_users()` never queries `beauty_log` — pure-beauty users never refresh | Task 2 | Fixed |
| 3 | `DIM_SCALP_TYPE` (29) defined but never written to any vector | Task 3 | **Partially out of scope** — Python-side write is fixed (`SCALP_TYPE_SPECTRUM` + assignment), but the DB only stores a `sensitive_scalp BOOLEAN`, never a graded `scalp_type` string (confirmed via `supabase/migrations/20260721000016_beauty_onboarding_flag.sql`, which derives `sensitive_scalp := (p_scalp_type = 'sensitive')` and discards the rest of `p_scalp_type`). Storing a real graded value requires a DB schema task (new `scalp_type` column on `user_health_profile` + onboarding UI/RPC change to persist it) that is OUT OF SCOPE for this Python-only plan. Until that lands, `profile.get("scalp_type")` will always be `None` in production and every user's `DIM_SCALP_TYPE` will resolve to the 0.40 default — a real improvement over always-0.0, but not yet user-differentiated. |
| 4 | 3 of 15 hair-type onboarding options have no `HAIR_TYPE_SPECTRUM` entry, silent fallback | Task 4 | Fixed |
| 5 | Beauty tests assert loose `> 0.0` bounds instead of exact spectrum values | Task 5 | Fixed |
| 6 | Recipe-side skin-type hardcodes `oily`/`acne` to the same 0.90 | Task 6 | Fixed |
| 7 | 2x amplification covers only 6 of 18 goal/virtue dims, undocumented | Task 7 | **Partially out of scope** — the 6-member `AMPLIFIED_GOAL_DIMS` constant is named, documented, and tested (`len() == 6`). Expanding amplification to the other 12 goal/virtue dims is a product decision (which goals should out-rank others) and is deliberately NOT made in this plan. |
| 8 | Missing-field fallbacks skew to spectrum extremes vs DB neutral defaults | Task 8 | Fixed |
| 9 | Doc claims `1A-1C=0.10`; code has `1C: 0.15` | Task 9 | Fixed |
| 10 | Silent `except Exception: pass` around check-in-boost fetch | Task 10 | Fixed |
| 11 | `test_main.py` never posts `mode: "beauty"` through the real endpoint | Task 11 | Fixed (coverage-only; no defect found) |

**Discovered but out of scope (not part of the 11 assigned findings):** while implementing Task 2, `get_active_users()`'s existing (untouched) `daily_nutrition_log` clause was found to filter on `WHERE date >= %s::date`, but the actual column is `log_date` (renamed from `date` by `supabase/migrations/20260527000001_sync_daily_nutrition_log_columns.sql`, confirmed via `CREATE TABLE daily_nutrition_log (... log_date date NOT NULL ...)` in `supabase/migrations/20260301000001_initial_schema.sql`). This is a pre-existing, likely-broken SQL reference unrelated to any of the 11 assigned findings. This plan deliberately does NOT fix it (it was not assigned, and fixing it here would be uncontrolled scope expansion) — flagging it here for a separate follow-up task.
