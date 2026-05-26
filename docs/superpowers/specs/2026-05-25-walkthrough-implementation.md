# Akeli Nutrition App: Implementation Walkthrough

## 1. Batch Cooking Calorie Adaptation

The Batch Cooking Calorie Adaptation spec has been fully implemented! The system now automatically identifies recipes repeated across the week, generates a batch cooking session for them, and properly scales their ingredients to match your calorie targets.

### Database Migrations
- Added `scale_factor` to `cooking_session`.
- Created `cooking_session_ingredient` table to store pre-calculated and scaled ingredient quantities.
- Created `create_batch_sessions` RPC:
  - This function automatically groups any recipe that appears 2+ times in the generated plan.
  - It correctly aggregates the `servings` across multiple meals (adjusting for calorie scales) and computes a `scale_factor` against the base recipe servings.
  - It scales every non-optional ingredient and stores it into `cooking_session_ingredient`.
- Updated `generate_shopping_list` RPC:
  - The function now uses a `UNION ALL` query. It aggregates standalone meal plan ingredients and merges them seamlessly with your batch-cooked ingredients, giving you an accurate master shopping list with no duplicated entries!

### Flutter App Integration
- **Models:** Updated `CookingSession` model to hold `scaleFactor` and an array of `CookingSessionIngredient`.
- **Providers:** 
  - `MealPlanGeneratorNotifier` now instantly calls the `create_batch_sessions` RPC right after generating your meal plan.
  - The fetch logic in `cookingSessionsProvider` now pulls down `cooking_session_ingredient(*)` along with the recipe details.
- **UI (`BatchCookingPage`):** 
  - The floating action button for manually creating a session has been removed, as sessions are now fully automated based on your plan.
  - The session card now features a dropdown list of the exact scaled ingredients and portions required for the batch cooking session!

---

## 2. Personal Meal Swap (AI Meal Analysis)

The Personal Meal Swap spec has been fully implemented! Users can now replace standard recipes with their own meals, described via text or a photo, and the app uses Gemini 1.5 Flash via a Supabase Edge Function to analyze the macros.

### Database Migrations
- Created `20260525000008_personal_meal_entry.sql`:
  - Added `is_custom_meal`, `custom_meal_name`, `custom_calories`, `custom_protein_g`, `custom_carbs_g`, and `custom_fat_g` columns to `meal_plan_entry`.
  - Created `swap_meal_plan_entry_custom` RPC: this function replaces a meal entry with a custom one, removing the original `meal_plan_entry_component` records to avoid polluting the shopping list.

### Supabase Edge Function
- Created `supabase/functions/analyze-meal-photo/index.ts`:
  - Connects to the Gemini 1.5 Flash API via `@google/genai`.
  - Analyzes a provided text description or base64 image (or both).
  - Prompts the model to return a structured JSON response containing: `meal_name`, `calories`, `protein_g`, `carbs_g`, `fat_g`, and a `confidence` level (`high`, `medium`, `low`).

### Flutter App Integration
- **Models:** 
  - Updated `MealPlanEntry` to parse `isCustomMeal` and the custom macro columns.
  - Updated getters (`recipeTitle`, `calories`, `proteinG`, etc.) to return the custom values if `isCustomMeal == true`.
- **Providers:** 
  - Created `PersonalMealSwapNotifier` to handle both `analyze` (calls the Edge Function) and `save` (calls the RPC).
- **UI (`MealDetailPage` & `PersonalMealBottomSheet`):**
  - Added a new CTA "Saisir un repas personnel (IA)" in `MealDetailPage`.
  - When a meal is a custom meal, the recipe image is replaced with a placeholder, and a "Repas Personnel" badge is displayed.
  - Created `PersonalMealBottomSheet` UI to allow the user to input a text description or take a photo, analyze it via the Edge Function, view the JSON-mapped results (along with confidence level), and save the custom meal back to the database.

---

## Verification

> [!NOTE]
> **Action Required:**
> 1. Link your Supabase project locally (`supabase link --project-ref <your-ref>`).
> 2. Run `supabase db push` to apply the migrations.
> 3. Set the Gemini API key in Supabase Secrets: `supabase secrets set GEMINI_API_KEY="your-key"`.
> 4. Deploy the Edge Function: `supabase functions deploy analyze-meal-photo`.

Once these backend steps are completed, the full features will be fully functional within the Flutter application!
