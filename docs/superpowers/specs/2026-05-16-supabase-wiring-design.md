# Supabase Wiring Design

**Goal:** Replace all mock providers with real Supabase queries, incrementally, one provider file at a time. `flutter analyze` must pass after each step. Local Supabase instance (`http://127.0.0.1:54321`) is used throughout — no remote project touched.

**Constraints:**
- Flutter emulator not available — verification is `flutter analyze` only
- UI screens and router are not modified
- Mock data (MockData class) is removed as each provider is wired
- `_examples/` files are reference-only, not promoted to production

---

## Architecture

**Pattern: `supabaseClientProvider` + direct queries**

One Riverpod `Provider<SupabaseClient>` lives in `lib/core/supabase_client.dart`. Every domain provider reads the client via `ref.watch(supabaseClientProvider)` and calls Supabase queries directly. No repository layer.

```
main.dart
  └─ Supabase.initialize(url, anonKey)        ← called once before runApp()

lib/core/supabase_client.dart
  └─ supabaseClientProvider                   ← Provider<SupabaseClient>

lib/providers/auth_provider.dart
lib/providers/user_profile_provider.dart
lib/providers/recipe_provider.dart
lib/providers/nutrition_provider.dart
lib/providers/meal_plan_provider.dart
lib/providers/fan_mode_provider.dart
  └─ each reads ref.watch(supabaseClientProvider)
```

---

## Phase 0 — Infrastructure

**Files changed:**
- `pubspec.yaml` — add `supabase_flutter: ^2.8.0`
- `lib/core/supabase_client.dart` — new file: local URL + anon key constants, `supabaseClientProvider`
- `lib/main.dart` — call `Supabase.initialize()` before `runApp()`

**Local credentials (hardcoded — local dev only):**
- URL: `http://127.0.0.1:54321`
- Anon key: `sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH`

**Success criterion:** `flutter pub get` succeeds, `flutter analyze` passes with zero issues.

---

## Phase 1 — Auth

**File:** `lib/providers/auth_provider.dart`

**Removed:** `MockUser` class, `StateProvider<MockUser?>` (`authStateProvider`), all mock delays.

**Added:**
- `authStreamProvider` — `StreamProvider<AuthState>` listening to `supabase.auth.onAuthStateChange`. Single source of truth for session state.
- `currentUserProvider` — `Provider<User?>` reading from the stream. Returns `null` when logged out.
- `isAuthenticatedProvider` — `Provider<bool>` — same signature as before, reads real session.
- `AuthNotifier` — replaces mock delays with real calls:
  - `signIn` → `supabase.auth.signInWithPassword(email, password)`
  - `signUp` → `supabase.auth.signUp(email, password)`
  - `signOut` → `supabase.auth.signOut()`
  - `resetPassword` → `supabase.auth.resetPasswordForEmail(email)`
- Error handling: `AuthException` is caught and re-thrown; surfaces as `AsyncError` on the notifier.

**Behavioral change:** App starts logged-out by default. The router guard (`isAuthenticatedProvider`) redirects to login on cold start. Session persists in secure storage after first login.

**Success criterion:** `flutter analyze` passes. No UI files changed.

---

## Phase 2 — User Profile

**File:** `lib/providers/user_profile_provider.dart`

**Supabase surfaces:**
- `user_profile` table — `select`, `update`
- `subscription` table — `select` filtered by `user_id`

**Provider mapping:**
| Provider | Query |
|---|---|
| `userProfileProvider` | `from('user_profile').select().eq('id', userId).single()` |
| `healthProfileProvider` | `from('user_health_profile').select().eq('user_id', userId).maybeSingle()` |
| `UserProfileNotifier.updateProfile` | `from('user_profile').update({...}).eq('id', userId)` |
| `subscriptionProvider` | `from('subscription').select().eq('user_id', userId).maybeSingle()` |
| `isPremiumProvider` | Derived from `subscriptionProvider` — no query |

**Error handling:** Empty profile returns `null`. RLS failure surfaces as `AsyncError`.

**Success criterion:** `flutter analyze` passes.

---

## Phase 3 — Recipes

**File:** `lib/providers/recipe_provider.dart`

**Supabase surfaces:**
- `recipe` table — paginated select with filters
- `get_personalized_feed` RPC — personalized feed
- `toggle-recipe-like` Edge Function

**Provider mapping:**
| Provider | Query |
|---|---|
| `feedProvider` | `rpc('get_personalized_feed', params: {limit, offset, regionId?, difficulty?, maxTimeMin?})` |
| `recipeDetailProvider` | `from('recipe').select().eq('id', id).single()` |
| `searchRecipesProvider` | `from('recipe').select().ilike('title', '%query%').limit(limit)` |
| `RecipeLikeNotifier.toggle` | `functions.invoke('toggle-recipe-like', body: {recipeId, liked})` |

**Param classes** (`FeedParams`, `SearchParams`) — unchanged signatures.

**Success criterion:** `flutter analyze` passes.

---

## Phase 4 — Nutrition

**File:** `lib/providers/nutrition_provider.dart`

**Supabase surfaces:**
- `daily_nutrition_log` table
- `weight_log` table

**Provider mapping:**
| Provider | Query |
|---|---|
| `todayNutritionProvider` | `from('daily_nutrition_log').select().eq('user_id', userId).eq('date', todayStr).maybeSingle()` |
| `weeklyNutritionProvider` | `from('daily_nutrition_log').select().eq('user_id', userId).gte('date', weekAgoStr).order('date')` |
| `weightLogProvider` | `from('weight_log').select().eq('user_id', userId).order('logged_at', ascending: false)` |
| `WeightLogNotifier.addEntry` | `from('weight_log').insert({user_id, weight_kg, note?, logged_at})` |

**Note:** `DailyNutrition.fromJson` uses `log_date` key — this must be changed to `date` to match the actual column name (`daily_nutrition_log.date` per the annotation migration fix).

**Success criterion:** `flutter analyze` passes.

---

## Phase 5 — Meal Plan

**File:** `lib/providers/meal_plan_provider.dart`

**Supabase surfaces:**
- `meal_plan` table
- `meal_plan_entry` table (joined)
- `generate-meal-plan` Edge Function
- `log-meal-consumption` Edge Function

**Provider mapping:**
| Provider | Query |
|---|---|
| `activeMealPlanProvider` | `from('meal_plan').select('*, meal_plan_entry(*)').eq('user_id', userId).eq('status', 'active').maybeSingle()` |
| `MealPlanGeneratorNotifier.generate` | `functions.invoke('generate-meal-plan', body: {days, mealsPerDay})` then `ref.invalidate(activeMealPlanProvider)` |
| `MealConsumptionNotifier.logConsumption` | `functions.invoke('log-meal-consumption', body: {entryId, recipeId})` then `ref.invalidate(activeMealPlanProvider)` |
| `shoppingListProvider` | Derived from `activeMealPlanProvider` entries — no direct query yet (mock list kept until ingredient data is seeded) |

**Success criterion:** `flutter analyze` passes.

---

## Phase 6 — Fan Mode

**File:** `lib/providers/fan_mode_provider.dart`

**Supabase surfaces:**
- `fan_subscription` table
- `creator` table
- `activate-fan-mode` Edge Function
- `cancel-fan-mode` Edge Function

**Provider mapping:**
| Provider | Query |
|---|---|
| `myFanSubscriptionProvider` | `from('fan_subscription').select().eq('user_id', userId).maybeSingle()` |
| `fanEligibleCreatorsProvider` | `from('creator').select()` — `is_fan_eligible` column does not exist; return all creators |
| `creatorProfileProvider` | `from('creator').select().eq('id', creatorId).single()` |
| `FanModeNotifier.activate` | `functions.invoke('activate-fan-mode', body: {creatorId})` then `ref.invalidate(myFanSubscriptionProvider)` |
| `FanModeNotifier.cancel` | `functions.invoke('cancel-fan-mode', body: {})` then `ref.invalidate(myFanSubscriptionProvider)` |

**Note:** `creator.is_fan_eligible` does not exist in the schema (confirmed). `fanEligibleCreatorsProvider` returns all creators. The `Creator` model's `isFanEligible` field should be removed or hardcoded to `true`.

**Success criterion:** `flutter analyze` passes.

---

## Error Handling (all phases)

- Mutations use `AsyncValue.guard()` — errors surface as `AsyncError` on the notifier state
- Read providers (`FutureProvider`, `StreamProvider`) propagate errors naturally
- `AuthException` is caught and re-thrown as-is
- `PostgrestException` (RLS failures, missing rows) — not caught; surfaces as `AsyncError`
- Empty results → `null` or `[]`, same as mock behavior
- No retry logic, no offline cache — local dev only

---

## Wiring Order Summary

| Phase | File | Commit message |
|---|---|---|
| 0 | pubspec + supabase_client.dart + main.dart | `feat: add supabase_flutter and initialize local client` |
| 1 | auth_provider.dart | `feat(auth): wire Supabase Auth replacing MockUser` |
| 2 | user_profile_provider.dart | `feat(profile): wire user_profile and subscription tables` |
| 3 | recipe_provider.dart | `feat(recipes): wire recipe feed, detail, search, and like toggle` |
| 4 | nutrition_provider.dart | `feat(nutrition): wire daily nutrition log and weight log` |
| 5 | meal_plan_provider.dart | `feat(meal-plan): wire meal plan tables and Edge Functions` |
| 6 | fan_mode_provider.dart | `feat(fan-mode): wire fan subscription and creator tables` |
