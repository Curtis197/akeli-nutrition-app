# Walkthrough: Onboarding & Nutrition Plan Fixes

## What was Accomplished

### 1. Onboarding UI & Navigation Fixes
- **Restored Bottom Navigation Bar:** The `NutritionPlanPage` was missing the `Précédent` and `Suivant` buttons during onboarding. The `_OnboardingBottomBar` is now correctly displayed and integrated into the global page controller.
- **Fixed Step Order:** The `NutritionPlanPage` was previously attempting to calculate the BMR and TDEE *before* the user inputted their target weight and activity level. The steps were re-ordered correctly to: Language → Consent → Profile → Goals → Preferences → Nutrition Plan → Summary.
- **Dynamic Delay Chip:** In the Goals step, the "Délai Estimé" chip and its color now update dynamically based on the slider value ("Intense" for 1-2 months, "Modéré" for 3-5 months, and "Durable" for 6-12 months).

### 2. Data Integrity & State Management
- **Deactivating Old Plans:** Re-running the onboarding or modifying the nutrition plan multiple times was causing a `PostgrestException (duplicate key value)`. The system now explicitly deactivates older plans (`is_active = false`) before creating new ones, maintaining a clean historical record.
- **Dynamic Initial Data:** `NutritionPlanPage` now automatically pulls the correct, real-time onboarding data from the `onboardingProvider` when it loads inside the flow, ensuring precise, personalized macro generation.

### 3. Edge Function JWT Fix (ES256 Error)
- **Resolved 401 Unauthorized:** Addressed the `UNAUTHORIZED_UNSUPPORTED_TOKEN_ALGORITHM` error when saving the final onboarding state by disabling the strict pre-flight JWT verification on the Edge Function. The function still securely authenticates the user via GoTrue's `/auth/v1/user`.

### 4. Clickable Policy Links in Onboarding
- Replaced the simple text checkboxes with `RichText` widgets.
- You can now tap **"Politique de Confidentialité"** and **"Conditions Générales d'Utilisation (CGU)"** directly during onboarding to open their respective pages.

### 5. Precision Steppers for Nutrition Planning
- **Macros:** Replaced the sliders for Protéines, Glucides, and Lipides with `+/-` steppers (`10%`, `11%`, etc.).
- **Meal Distribution:** Replaced the sliders for meal percentages with `+/-` steppers.
- **Why this matters:** Sliders often land on decimals (e.g. `24.6%`) making it very difficult to get the totals to exactly `100%`, which locked the save button. With steppers, you get absolute precision in `1%` increments, making it effortless to balance your meals perfectly.

## Verification Steps
- Please run `supabase stop` and `supabase start` (or restart your Edge Functions) to apply the `config.toml` change.
- Run through the onboarding flow again and observe the accurate calculation of macros, the dynamically updating delay chip, and the successful transition to the home page!
