# Allergen Workflow Implementation Walkthrough

The backend and frontend components for the new allergy selection workflow have been fully implemented according to the design specification. Here is a summary of the changes:

## Backend Changes (Supabase)

1. **Schema Modifications & Database Functions:**
   - Created `user_allergy` and `allergen_suggestion` tables.
   - Inserted default allergen dictionary data (14 major EU allergens).
   - Created a GIN index on `recipe.allergen_tags`.
   - Patched `recommend_recipes`, `generate_feed_personalized`, `generate_meal_plan_internal`, and other feed RPCs with a new `user_allergens` CTE to exclude meals where `allergen_tags && (SELECT array_agg(allergen_id) ...)`.

2. **Edge Functions:**
   - Updated the `complete-onboarding` Edge Function to parse user-provided allergies and insert them into the `user_allergy` table for the user.
   - Created the `submit-allergen-suggestion` Edge Function which inserts new unmapped string queries into the `allergen_suggestion` table for admin review.

## Frontend Changes (Flutter)

1. **Data Layer (`Riverpod`):**
   - Created `AllergenModel` representing allergen properties (ID, slug, label).
   - Created `userAllergyProvider` to list user allergies from the `user_allergy` table.
   - Created `searchAllergenProvider` that executes the `search_allergens` RPC query via Supabase to autocompleting queries with a 300ms debounce.

2. **UI Layer:**
   - Implemented `AllergenPickerWidget`, featuring an interactive autocomplete field utilizing the new Riverpod providers and submitting missing suggestions to the backend via Edge Functions.
   - Integrated `AllergenPickerWidget` into the Onboarding process (`onboarding_page.dart`) and the Settings/Preferences panel (`preferences_page.dart`).
   - Ensured UI elements conform to Akeli's 0-warning baseline rule (verified with `flutter analyze`).

## Validation
- `dart run build_runner build --delete-conflicting-outputs` generated Riverpod classes.
- `flutter analyze` ran and confirmed **0 issues**.
