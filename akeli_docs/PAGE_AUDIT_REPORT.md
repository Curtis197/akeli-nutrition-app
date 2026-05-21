# Page Audit Report

**Files Audited:** 68
**Files with Issues:** 11

## Issues by File

### `features/auth/auth_page.dart`

- Line 139: Hardcoded color detected

### `features/auth/onboarding_page.dart`

- Line 314: Hardcoded color detected
- Line 1015: Hardcoded color detected
- Line 1521: Hardcoded color detected
- Line 60: TODO/FIXME comment: // TODO(wave2): persist onboardingProvider state to Supabase user profile

### `features/journaling/journaling_bottom_sheet.dart`

- Line 73: TODO/FIXME comment: // TODO: Integrate with journaling edge function
- Line 114: TODO/FIXME comment: // TODO: Implement image picker

### `features/meal_planner/meal_planner_page.dart`

- Line 252: Hardcoded color detected

### `features/nutrition/nutrition_page.dart`

- Line 405: Hardcoded color detected
- Line 408: Hardcoded color detected
- Line 429: Hardcoded color detected

### `features/recipes/recipe_detail_page.dart`

- Line 236: Hardcoded color detected
- Line 345: Hardcoded color detected
- Line 381: Hardcoded color detected
- Line 455: Hardcoded color detected
- Line 307: TODO/FIXME comment: // TODO: Implement Add to Calendar

### `features/referral/referral_page.dart`

- Line 53: Hardcoded color detected
- Line 55: Hardcoded color detected
- Line 163: Hardcoded color detected
- Line 171: Hardcoded color detected
- Line 180: Hardcoded color detected
- Missing logger import in substantial widget file
- Line 29: TODO/FIXME comment: // TODO: Integrate with referral edge function

### `features/support/support_page.dart`

- Line 54: TODO/FIXME comment: // TODO: Integrate with support edge function
- Line 286: TODO/FIXME comment: // TODO: Implement image picker

### `shared/widgets/akeli_gradient_button.dart`

- Line 45: Hardcoded color detected

### `shared/widgets/meal_card.dart`

- Line 194: Hardcoded color detected

### `shared/widgets/recipe_card.dart`

- Missing logger import in substantial widget file


## Recommendations

1. Replace all hardcoded colors with `AkeliColors` tokens
2. Add logger imports and usage to all substantial widget files
3. Implement dispose() methods for all controllers
4. Replace print() statements with logger calls
5. Address all TODO/FIXME comments
