# Technical Audit — MVP Codebase

> **Purpose:** Full inventory of technical debt accumulated during FlutterFlow MVP development. This document exists so V1 development starts with a clear picture of what to fix, remove, and avoid repeating.

---

## Summary Scorecard

| Category | Issue Count | Severity |
|----------|-------------|----------|
| Ghost / duplicate code | 12+ instances | High |
| Typos that became API contracts | 10+ | High |
| Test endpoints in production | 2 | High |
| Debug print() statements | 5+ files | Medium |
| Dead function parameters | 3+ | Medium |
| App state anti-patterns | 6 types | Medium |
| Missing test coverage | ~0% | Medium |
| Nav label copy-paste error | 4 labels | Low |

---

## 1. Ghost and Duplicate Code

### Duplicate Components (8+ pairs with `_copy_` suffix)

FlutterFlow creates copies of components when editing, leaving both versions in the codebase. None of the `_copy_` variants should exist in V1.

| Original | Duplicate | Location |
|----------|-----------|----------|
| `daily_recap_widget.dart` | `daily_recap_copy_widget.dart` | `lib/components/` |
| `daily_recap_model.dart` | `daily_recap_copy_model.dart` | `lib/components/` |
| `daily_recapv_view_widget.dart` | _(3rd variant of same concept)_ | `lib/components/` |
| `recipe_filters_widget.dart` | `recipe_filters_copy_widget.dart` | `lib/components/` |
| `recipe_filters_model.dart` | `recipe_filters_copy_model.dart` | `lib/components/` |
| `weekly_int_widget.dart` | `weekly_int_copy_widget.dart` | `lib/components/` |
| `weeklyrecap_widget.dart` | `weeklyrecap_copy_widget.dart` | `lib/components/` |

**V1 action:** Consolidate to a single canonical version of each component. Delete all `_copy_` variants.

---

### Duplicate Edge Function Calls

Three pairs of edge function classes do overlapping work with no clear distinction:

| Pair | File | Lines | Issue |
|------|------|-------|-------|
| `PersonalMealPlanCall` vs `PersonalMealPlanNoMealCall` | `lib/backend/api_requests/api_calls.dart` | 686, 1537 | Nearly identical, different endpoints — purpose unclear |
| `SearchAPrivateConversationCall` vs `SearchAConversationCall` | `lib/backend/api_requests/api_calls.dart` | 68, 911 | Both search conversations — duplication of intent |
| `SearchAGroupByNameCall` vs `SearchAGroupCall` | `lib/backend/api_requests/api_calls.dart` | 130, 188 | Both search groups — different logic, unclear which is canonical |

**V1 action:** Audit which version is actually called in the UI, keep one, delete the other.

---

### Duplicate Custom Functions

`lib/flutter_flow/custom_functions.dart`

| Function | Lines | Issue |
|----------|-------|-------|
| `buildResearchRequest` | 30–66 | Uses `String?` for type/tags/difficulty |
| `buildResearchRequestCopy` | 68–104 | Uses `List<String>?` for same fields |

Both are called across the codebase (27 total usages). The `Copy` version has the correct signature (lists, not single strings) but was never used to replace the original.

**V1 action:** Keep `buildResearchRequestCopy` logic, rename it to `buildResearchRequest`, delete the original. Audit all 27 call sites.

---

## 2. Typos That Became API Contracts

These misspellings exist in class names, method names, and string constants. Because they are used as API identifiers and Supabase table names, they cannot be silently fixed — they require coordinated changes across frontend and backend.

### In `lib/backend/api_requests/api_calls.dart`

| Typo | Correct | Type | Line |
|------|---------|------|------|
| `RecommandedReceipeCall` | `RecommendedRecipeCall` | Class name | ~1177 |
| `ChatNotiificationCall` | `ChatNotificationCall` | Class name | ~1225 |
| `receipes()` | `recipes()` | Method name | ~1152 |
| `receipeIDs()` | `recipeIDs()` | Method name | ~1214 |
| `'recommanded receipe'` | `'recommended recipe'` | String constant | ~1196 |
| `suucess()` | `success()` | Method name | ~378 |
| `descrition()` | `description()` | Method name | ~1503 |

### In `lib/app_state.dart`

| Typo | Correct | Line |
|------|---------|------|
| `cookingTIme` | `cookingTime` | ~248 |
| `dificulty` | `difficulty` | ~254 |
| `TypeAndOr` | `typeAndOr` | ~236 |
| `TagAndOR` | `tagAndOr` | ~242 |

### In Supabase table names (cascades through 81 table files)

The word `receipe` (French-influenced misspelling of "recipe") appears throughout all recipe-related Supabase table names and Dart files:
- `receipe.dart`, `receipe_macro.dart`, `receipe_tags.dart`, `receipe_comments.dart`, etc.
- `recomanded_receipe.dart` (double typo)
- `temporary_receipe.dart`

**V1 action:** Decide whether to fix at DB level (requires migration + frontend update) or keep as-is in DB but normalize naming in Dart. Renaming Supabase tables is a migration — plan carefully.

---

## 3. Test Endpoints in Production

Two edge function endpoints still use `_test` suffixes, indicating they were never promoted to production:

| Call Class | Test Endpoint | File | Line |
|------------|--------------|------|------|
| `MealIngredientsScaleCall` | `receipe_scaling_test` | `api_calls.dart` | ~512 |
| `ShoppingListCall` | `shopping_list_test` | `api_calls.dart` | ~579 |

**Risk:** These may point to test Supabase edge functions that could be deleted or unstable.

**V1 action:** Verify if production versions of these endpoints exist. If yes, update to production endpoint. If no, create them.

---

## 4. Dead Function Parameters

Parameters defined in function signatures but never used in the function body:

| Function | Dead Parameter | File | Line |
|----------|---------------|------|------|
| `CustomMealCall` | `imagetest` | `api_calls.dart` | ~393 |
| `ShoppingListCall` | `shoppingListId`, `mealPlanId` | `api_calls.dart` | ~553 |

**V1 action:** Remove dead parameters. If they were intended features, create a ticket to implement them properly.

---

## 5. App State Anti-Patterns

**File:** `lib/app_state.dart` (559 lines)

### 5a. Ungrouped state blob
50+ state variables with no logical grouping. All mixed together: recipe filters, user health params, meal plan state, conversation participants, UI state.

**V1 action:** Split into domain slices — see [ARCHITECTURE_REDESIGN.md](../v1/ARCHITECTURE_REDESIGN.md).

### 5b. Empty persistence implementation
```dart
Future initializePersistedState() async {} // line ~23 — intentionally empty
```
The method name promises persistence but does nothing. Some state should actually be persisted (user filter preferences, locale, etc.).

### 5c. Untyped dynamic fields
Several state fields are typed as `dynamic` or raw `List` with no type parameter:
- `receipeReserchResponse` — dynamic, holds raw API response
- `filter` — untyped List
- `calGte` — String but represents a number

### 5d. Wrong types
- `hasFilters` is a `String` field but semantically should be `bool`

### 5e. Repetitive boilerplate × 15 lists
Every `List` field in app state has 6+ manually written methods:
`addTo`, `removeFrom`, `removeAtIndex`, `updateAtIndex`, `insertAtIndex`, `update`

This pattern is copy-pasted for 15+ list properties. In V1, use a mixin or code generation.

### 5f. Naming convention violations
FlutterFlow generated inconsistent casing: `TypeAndOr`, `TagAndOR`, `cookingTIme`, `dificulty` — none follow Dart's `lowerCamelCase` convention.

---

## 6. Debug Code in Production

`print()` statements should never appear in production Flutter code. They appear in:

| File | Notes |
|------|-------|
| `lib/payment_subscription/payment_subscription_widget.dart` | Debug prints during payment flow |
| `lib/support/support_widget.dart` | Debug prints |
| `lib/referral/referral_widget.dart` | Debug prints |
| `lib/cgu/cgu_widget.dart` | Debug prints |
| `lib/backend/api_requests/api_calls.dart` | List serialization error prints |
| `lib/environment_values.dart` | Error loading environment values |

**V1 action:** Replace all `print()` with `debugPrint()` (at minimum) or adopt a proper logging package (`logger`, `talker`). Remove logs that expose API responses.

---

## 7. Navigation Copy-Paste Error

**File:** `lib/main.dart`

The `BottomNavigationBar` has 4 tabs. All 4 labels are hardcoded as `"Home"`:

```dart
// lines ~218, 229, 239, 249 — all identical
BottomNavigationBarItem(label: 'Home', ...)
BottomNavigationBarItem(label: 'Home', ...)
BottomNavigationBarItem(label: 'Home', ...)
BottomNavigationBarItem(label: 'Home', ...)
```

The actual tabs are: Home, Meal Planner, Recipe Discovery, Community.

**V1 action:** Fix labels. Use i18n keys since the app is multilingual.

---

## 8. Test Coverage

**File:** `test/widget_test.dart`

Only one file exists and it contains the default Flutter counter test — not related to this app at all. There are **zero tests** for any actual feature.

| Test type | Count |
|-----------|-------|
| Unit tests | 0 |
| Widget tests | 0 |
| Integration tests | 0 |
| Meaningful tests total | 0 |

**V1 action:** Establish a testing strategy. At minimum: unit tests for custom functions, API call response parsing, and state management logic. See FEATURE_SPEC.md for V1 priorities.

---

## 9. Miscellaneous Issues

### Unused auth route
`/test` route in GoRouter (`lib/flutter_flow/nav/nav.dart`) — a test page that has no place in production.

### Firebase credentials visibility
`lib/backend/firebase/firebase_config.dart` contains hardcoded Firebase API keys inline in Dart code. While Firebase client keys are considered public, it is bad practice compared to environment-based configuration already used for Supabase.

### Splash screen hardcoded delay
`lib/main.dart` line ~96–99: 1000ms hardcoded delay for splash screen. Should be tied to actual initialization completion.

### Unused stream listener
`lib/main.dart` line ~95: `jwtTokenStream.listen((_) {})` — empty listener with no purpose.

---

## Quick Reference: Files with the Most Issues

| File | Issues |
|------|--------|
| `lib/backend/api_requests/api_calls.dart` | Typos, duplicates, test endpoints, dead params |
| `lib/app_state.dart` | State bloat, anti-patterns, naming violations |
| `lib/flutter_flow/custom_functions.dart` | Duplicate function, inconsistent field naming |
| `lib/main.dart` | Nav labels, hardcoded delays, unused listeners |
| `lib/components/` | 8+ `_copy_` duplicate component files |
