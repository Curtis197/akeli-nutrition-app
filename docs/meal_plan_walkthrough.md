# Walkthrough: Filter Meal Plan by Meal Type

## Changes Made
1. Added `meal_types` column to the `recipe` table as a PostgreSQL array `TEXT[]`.
2. Created a migration `20260524000005_seed_meal_types.sql` to automatically classify and map existing recipes to their relevant meal types (breakfast, lunch, dinner, snack).
3. Updated the `generate_meal_plan` RPC function so it matches the `meal_type` of the schedule (e.g., breakfast) against the `meal_types` array of the recipe.
   - Using PostgreSQL array containment operator: `r.meal_types @> ARRAY[v_current_meal_type]`

## What Was Tested
- Reset the local database successfully after fixing local seed constraints.
- Inserted mock recipes covering `breakfast`, `lunch`, and `dinner` into the database.
- Called the REST API `rpc/generate_meal_plan` to simulate generating a 1-day meal plan (3 meals/day).
- Verified that the generated `meal_plan_entry` properly selected recipes whose `meal_types` exactly matched the slot (breakfast, lunch, dinner).

## Validation Results
- The SQL query correctly filters recipes based on `meal_types`.
- **Mock Breakfast** was properly selected for the `breakfast` meal.
- **Mock Lunch** was properly selected for the `lunch` meal.
- **Mock Dinner** was properly selected for the `dinner` meal.

The database logic and schema changes effectively enforce the `meal_type` constraint on the generated meal plan!
