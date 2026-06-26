# Generate Meal Plan from Saved Recipes Only

The backend implementation for generating meal plans strictly from saved recipes is now complete!

## Changes Made

### 1. Database Schema & RPCs
- **[NEW] `use_saved_recipes_only` Preference:** Added to the `user_profile` table to track the setting.
- **[NEW] `evaluate_saved_recipe_eligibility` RPC:** A PostgreSQL function that counts a user's saved recipes for Breakfast, Lunch, and Dinner. If any drop below 7, it automatically toggles `use_saved_recipes_only` to `false`.
- **[NEW] Eligibility DB Trigger:** Created `trg_evaluate_saved_recipe_eligibility` on the `recipe_save` table. It fires after every `INSERT` or `DELETE`, proactively evaluating and enforcing the threshold rule.
- **[NEW] `generate_meal_plan_from_saved` RPC:** A dedicated algorithm that bypasses the vector similarity engine and queries recipes strictly by joining the user's `recipe_save` table. It maintains macro density matching and repeat caps.

### 2. Edge Functions
- **[MODIFIED] `generate-meal-plan`:** 
  - Now fetches the user's `use_saved_recipes_only` preference.
  - Acts as the orchestrator: tries `generate_meal_plan_from_saved` if enabled.
  - Includes a fallback mechanism: If the RPC throws `insufficient_saved_recipes`, it toggles the preference off in the database and falls back to the standard vector engine.
- **[MODIFIED] `batch-generate-meal-plans`:** 
  - Updated the background worker loop to apply the exact same orchestration and fallback logic for the Sunday night batch jobs.

> [!TIP]
> The proactive DB trigger means the Edge Function fallback will rarely be needed, acting mostly as a failsafe against race conditions or data anomalies.

## Next Steps

To verify these changes in your live testing environment:
1. Apply the new migration to your database (`supabase db push`).
2. Save at least 7 recipes for breakfast, lunch, and dinner.
3. Manually set your `use_saved_recipes_only` flag to `true` in the database or via your app interface.
4. Generate a meal plan and verify all recommended recipes are from your saved list.
5. Unsave a breakfast recipe (dropping below 7) and verify the DB trigger automatically turns off the preference.
