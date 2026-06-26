# Python Engine Update - Recommendations & Vectorization
**Date & Time:** March 14, 2026 - 08:48:54 AM (+01:00)

## Overview
This document tracks the updates made to the batch vectorization engine located in the `python/` directory of the Akeli Nutrition App project to ensure correct environment launching, dependency resolution, and test coverage.

## Changes Made

### 1. Dependency Resolution
- **File modified:** `python/requirements.txt`
- **Context:** The environment uses Python 3.13, but the engine dependencies had strict pinning to versions of older packages lacking pre-compiled wheel support for Python 3.13. This resulted in underlying build errors during the installation of `fastapi`, `numpy`, `psycopg2-binary`, and `pydantic`.
- **Modifications:** Changed exact versions to allow newer upgrades providing Python 3.13 wheels compatibility:
  - `numpy==1.26.4` ➡️ `numpy>=1.26.4`
  - `psycopg2-binary==2.9.9` ➡️ `psycopg2-binary>=2.9.9`
  - `pydantic==2.7.0` ➡️ `pydantic>=2.7.0`

### 2. Startup Verification
- **Process:** Created a virtual environment (`python/venv`), installed the modified dependencies, and ran `python main.py` using Uvicorn.
- **Outcome:** Successful initialization. FastApi application correctly booted and listened on `0.0.0.0:8000`.

### 3. Test Coverage added
- **Context:** To verify the computation engine's behavior programmatically without hitting live components, testing logic with mocks has been added utilizing `httpx` and `pytest`.
- **Files added:**
  - `python/tests/test_main.py`: Full API coverage on Uvicorn endpoints, returning 200, 401, or 404 respectively. Covered endpoints:
    - `GET /health`
    - `POST /compute-user-vector`
    - `POST /compute-recipe-vector`
    - `POST /nightly-batch`
  - `python/tests/test_vectorization.py`: Tests `engine/vectorization.py` directly by mocking database (`psycopg2`) calls and verifying the properties of the normalized 50D output vector (`np.ndarray` structure sizes and normalizations).
- **Execution:** Successful execution of 12 internal mock test sequences with zero failures.

## Future Recommendations
- Consider upgrading `railway.toml` build commands to incorporate running the test suite dynamically prior to release on push schedules.
