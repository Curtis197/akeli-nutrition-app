# Akeli Nutrition App — Codebase Guide

> African nutrition & recipes Flutter application. This document covers architecture, pages, providers, models, navigation, and dependencies so you can get up to speed quickly.

---

## Table of Contents

1. [Tech Stack](#1-tech-stack)
2. [Project Structure](#2-project-structure)
3. [Entry Point & Initialization](#3-entry-point--initialization)
4. [Navigation & Routing](#4-navigation--routing)
5. [Pages & Screens](#5-pages--screens)
6. [State Management (Riverpod)](#6-state-management-riverpod)
7. [Shared Widgets](#7-shared-widgets)
8. [Data Models](#8-data-models)
9. [Backend — Supabase](#9-backend--supabase)
10. [Theme & Design Tokens](#10-theme--design-tokens)
11. [Dependencies](#11-dependencies)
12. [Architectural Notes](#12-architectural-notes)

---

## 1. Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod v2.5.1 |
| Navigation | GoRouter v14 |
| Backend | Supabase (Postgres + Auth + Edge Functions) |
| Font | Nunito via google_fonts |
| Charts | fl_chart |
| Image Caching | cached_network_image |
| Code Generation | riverpod_generator + build_runner |

---

## 2. Project Structure

```
akeli-nutrition-app/
├── lib/
│   ├── main.dart                            # App entry point
│   ├── core/
│   │   ├── router.dart                      # GoRouter config & auth guards
│   │   ├── theme.dart                       # Design tokens, colors, typography
│   │   └── supabase_client.dart             # Supabase client helper
│   │
│   ├── features/                            # Feature-sliced modules
│   │   ├── ai_assistant/
│   │   │   └── ai_chat_page.dart
│   │   ├── auth/
│   │   │   ├── auth_page.dart
│   │   │   └── onboarding_page.dart
│   │   ├── community/
│   │   │   ├── community_page.dart
│   │   │   ├── group_chat_page.dart
│   │   │   └── group_detail_page.dart
│   │   ├── diet_plan/
│   │   │   └── diet_plan_page.dart
│   │   ├── fan_mode/
│   │   │   └── fan_mode_page.dart
│   │   ├── home/
│   │   │   └── home_page.dart
│   │   ├── meal_planner/
│   │   │   ├── meal_planner_page.dart
│   │   │   ├── meal_detail_page.dart
│   │   │   └── shopping_list_page.dart
│   │   ├── notifications/
│   │   │   └── notifications_page.dart
│   │   ├── nutrition/
│   │   │   └── nutrition_page.dart
│   │   ├── profile/
│   │   │   └── profile_page.dart
│   │   ├── recipes/                         # Only feature with Clean Architecture
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── recipe_tracking_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── recipe_tracking_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── recipe_tracking.dart
│   │   │   │   └── repositories/
│   │   │   │       └── i_recipe_tracking_repository.dart
│   │   │   ├── presentation/
│   │   │   │   └── providers/
│   │   │   │       └── recipe_tracking_provider.dart
│   │   │   ├── feed_page.dart
│   │   │   └── recipe_detail_page.dart
│   │   ├── subscription/
│   │   │   └── subscription_page.dart
│   │   └── placeholders.dart                # Stub pages (not yet implemented)
│   │
│   ├── providers/                           # Global Riverpod providers
│   │   ├── auth_provider.dart
│   │   ├── fan_mode_provider.dart
│   │   ├── meal_plan_provider.dart
│   │   ├── nutrition_provider.dart
│   │   ├── recipe_provider.dart
│   │   └── user_profile_provider.dart
│   │
│   └── shared/
│       ├── models/                          # Domain models
│       │   ├── creator.dart
│       │   ├── meal_plan.dart
│       │   ├── recipe.dart
│       │   └── user_profile.dart
│       └── widgets/                         # Reusable UI components
│           ├── akeli_recipe_card.dart
│           ├── avatar.dart
│           ├── badge.dart
│           ├── chat_bubble.dart
│           ├── empty_state.dart
│           ├── macro_card.dart
│           ├── main_shell.dart              # Bottom nav shell
│           ├── meal_card.dart
│           ├── notif_card.dart
│           ├── progress_circle.dart
│           ├── recipe_card.dart
│           ├── section_header.dart
│           ├── shopping_row.dart
│           └── tab_bar.dart
│
├── assets/
│   ├── images/
│   └── icons/
└── pubspec.yaml
```

---

## 3. Entry Point & Initialization

**File:** [lib/main.dart](lib/main.dart)

```
main()
  └── Supabase.initialize(url, anonKey)       # Hardcoded in dev
  └── runApp(ProviderScope(child: AkeliApp))  # ProviderScope = Riverpod root

AkeliApp (ConsumerWidget)
  └── watches routerProvider
  └── builds MaterialApp.router
  └── applies light/dark theme (system preference)
  └── sets locale: 'fr' (French default, i18n-ready)
```

> **Note:** Supabase credentials are hardcoded directly in `main.dart` — no `.env` file. The Supabase URL is `https://njzqcftjzskwcpforwzf.supabase.co`.

---

## 4. Navigation & Routing

**File:** [lib/core/router.dart](lib/core/router.dart)

GoRouter is the navigation solution. Routes are defined statically with an auth redirect guard.

### Route Map

```
/auth                        → AuthPage            (public)
/onboarding                  → OnboardingPage       (public)

ShellRoute (MainShell — bottom nav with 4 tabs)
  /home                      → HomePage
  /meal-planner              → MealPlannerPage
  /recipes                   → FeedPage
  /community                 → CommunityPage

/recipe/:id                  → RecipeDetailPage     (modal, no bottom nav)
/meal/:id                    → MealDetailPage        (modal)
/shopping-list               → ShoppingListPage
/nutrition                   → NutritionPage
/fan-mode                    → FanModePage
/subscription                → SubscriptionPage
/ai-chat                     → AiChatPage
/diet-plan                   → DietPlanPage
/profile                     → ProfilePage
/notifications               → NotificationsPage
/group/:id                   → GroupChatPage
/group/:id/detail            → GroupDetailPage
```

### Auth Guard Logic

- **Not authenticated** → redirect to `/auth`
- **On `/auth` when already logged in** → redirect to `/home`

---

## 5. Pages & Screens

### Bottom Tab Pages (inside MainShell)

| Tab | Page | File |
|-----|------|------|
| 1 — Home | Dashboard with recommended recipes, macros summary, quick actions | [lib/features/home/home_page.dart](lib/features/home/home_page.dart) |
| 2 — Meal Planner | Weekly meal plan view | [lib/features/meal_planner/meal_planner_page.dart](lib/features/meal_planner/meal_planner_page.dart) |
| 3 — Recipes | Personalized recipe feed | [lib/features/recipes/feed_page.dart](lib/features/recipes/feed_page.dart) |
| 4 — Community | Groups & social features | [lib/features/community/community_page.dart](lib/features/community/community_page.dart) |

### Auth Pages

| Page | File | Notes |
|------|------|-------|
| AuthPage | [lib/features/auth/auth_page.dart](lib/features/auth/auth_page.dart) | Login + sign-up, magic link |
| OnboardingPage | [lib/features/auth/onboarding_page.dart](lib/features/auth/onboarding_page.dart) | First-time user health profile setup |

### Detail / Push Pages

| Page | File | Notes |
|------|------|-------|
| RecipeDetailPage | [lib/features/recipes/recipe_detail_page.dart](lib/features/recipes/recipe_detail_page.dart) | Full recipe with ingredients & steps, uses `visibility_detector` to track impressions |
| MealDetailPage | [lib/features/meal_planner/meal_detail_page.dart](lib/features/meal_planner/meal_detail_page.dart) | Individual meal in a plan |
| ShoppingListPage | [lib/features/meal_planner/shopping_list_page.dart](lib/features/meal_planner/shopping_list_page.dart) | Aggregated shopping list from active meal plan |
| GroupChatPage | [lib/features/community/group_chat_page.dart](lib/features/community/group_chat_page.dart) | Real-time group messaging |
| GroupDetailPage | [lib/features/community/group_detail_page.dart](lib/features/community/group_detail_page.dart) | Group info & members |

### Feature Pages (accessible from Home / Profile)

| Page | File | Notes |
|------|------|-------|
| NutritionPage | [lib/features/nutrition/nutrition_page.dart](lib/features/nutrition/nutrition_page.dart) | Daily & weekly nutrition charts, weight log |
| ProfilePage | [lib/features/profile/profile_page.dart](lib/features/profile/profile_page.dart) | User settings, health profile, subscription |
| NotificationsPage | [lib/features/notifications/notifications_page.dart](lib/features/notifications/notifications_page.dart) | App notifications list |
| AiChatPage | [lib/features/ai_assistant/ai_chat_page.dart](lib/features/ai_assistant/ai_chat_page.dart) | AI nutrition assistant chat |
| DietPlanPage | [lib/features/diet_plan/diet_plan_page.dart](lib/features/diet_plan/diet_plan_page.dart) | Long-term diet plan view |
| FanModePage | [lib/features/fan_mode/fan_mode_page.dart](lib/features/fan_mode/fan_mode_page.dart) | Subscribe to creator/chef profiles |
| SubscriptionPage | [lib/features/subscription/subscription_page.dart](lib/features/subscription/subscription_page.dart) | Premium plan upsell |

---

## 6. State Management (Riverpod)

All state is managed with **Riverpod v2**. The general rule:

- `StreamProvider` → real-time or auth state
- `FutureProvider.autoDispose` → async data fetched once, auto-cleaned
- `AsyncNotifierProvider` → mutations (write operations)
- `family` modifier → parameterized providers (e.g. recipe by ID)

### auth_provider.dart

[lib/providers/auth_provider.dart](lib/providers/auth_provider.dart)

| Provider | Type | Purpose |
|----------|------|---------|
| `authStateProvider` | StreamProvider | Stream of Supabase auth state changes |
| `currentUserProvider` | Provider | Current authenticated `User` object |
| `isAuthenticatedProvider` | Provider\<bool\> | Computed auth boolean |
| `AuthNotifier` | AsyncNotifierProvider | signUp, signIn, signOut, resetPassword |

### recipe_provider.dart

[lib/providers/recipe_provider.dart](lib/providers/recipe_provider.dart)

| Provider | Type | Purpose |
|----------|------|---------|
| `feedProvider` | FutureProvider | Personalized recipe feed via RPC `recommend_recipes` |
| `searchRecipesProvider` | FutureProvider.family | Full-text search with filters |
| `recipeDetailProvider` | FutureProvider.family | Single recipe with nested ingredients & steps |
| `RecipeLikeNotifier` | AsyncNotifierProvider | Toggle like on a recipe |

### meal_plan_provider.dart

[lib/providers/meal_plan_provider.dart](lib/providers/meal_plan_provider.dart)

| Provider | Type | Purpose |
|----------|------|---------|
| `activeMealPlanProvider` | FutureProvider | Current user's active meal plan |
| `MealPlanGeneratorNotifier` | AsyncNotifierProvider | Call Edge Function `generate-meal-plan` |
| `shoppingListProvider` | FutureProvider | Aggregate shopping list via RPC `generate_shopping_list` |
| `MealConsumptionNotifier` | AsyncNotifierProvider | Call Edge Function `log-meal-consumption` |

### user_profile_provider.dart

[lib/providers/user_profile_provider.dart](lib/providers/user_profile_provider.dart)

| Provider | Type | Purpose |
|----------|------|---------|
| `userProfileProvider` | FutureProvider | User account info from `user_profile` table |
| `healthProfileProvider` | FutureProvider | Health metrics from `user_health_profile` table |
| `UserProfileNotifier` | AsyncNotifierProvider | Update profile or health data |
| `subscriptionProvider` | FutureProvider | Premium subscription record |
| `isPremiumProvider` | Provider\<bool\> | Computed premium flag |

### nutrition_provider.dart

[lib/providers/nutrition_provider.dart](lib/providers/nutrition_provider.dart)

| Provider | Type | Purpose |
|----------|------|---------|
| `todayNutritionProvider` | FutureProvider | Today's nutrition summary |
| `weeklyNutritionProvider` | FutureProvider | Weekly history for charts |
| `weightLogProvider` | FutureProvider | Weight entries |
| `WeightLogNotifier` | AsyncNotifierProvider | Log a new weight entry |

### fan_mode_provider.dart

[lib/providers/fan_mode_provider.dart](lib/providers/fan_mode_provider.dart)

| Provider | Type | Purpose |
|----------|------|---------|
| `myFanSubscriptionProvider` | FutureProvider | User's active fan subscriptions |
| `fanEligibleCreatorsProvider` | FutureProvider | List of creators available for fan mode |
| `creatorProfileProvider` | FutureProvider.family | Public profile of a specific creator |
| `FanModeNotifier` | AsyncNotifierProvider | Call Edge Functions `activate-fan-mode` / `cancel-fan-mode` |

### Recipe Tracking Providers (Clean Architecture)

[lib/features/recipes/presentation/providers/recipe_tracking_provider.dart](lib/features/recipes/presentation/providers/recipe_tracking_provider.dart)

| Provider | Purpose |
|----------|---------|
| `recipeTrackingDatasourceProvider` | Supabase data access layer |
| `recipeTrackingRepositoryProvider` | Repository abstraction |

---

## 7. Shared Widgets

All reusable UI lives in [lib/shared/widgets/](lib/shared/widgets/).

| Widget | File | Usage |
|--------|------|-------|
| `MainShell` | [main_shell.dart](lib/shared/widgets/main_shell.dart) | Persistent bottom nav bar wrapping the 4 tab routes |
| `AkeliRecipeCard` | [akeli_recipe_card.dart](lib/shared/widgets/akeli_recipe_card.dart) | Featured/hero recipe card (large format) |
| `RecipeCard` | [recipe_card.dart](lib/shared/widgets/recipe_card.dart) | Standard recipe card in feed lists |
| `MealCard` | [meal_card.dart](lib/shared/widgets/meal_card.dart) | Meal plan entry card |
| `MacroCard` | [macro_card.dart](lib/shared/widgets/macro_card.dart) | Nutrition macro display (calories, protein, carbs, fat) |
| `ProgressCircle` | [progress_circle.dart](lib/shared/widgets/progress_circle.dart) | Circular progress for nutrition goals |
| `Avatar` | [avatar.dart](lib/shared/widgets/avatar.dart) | User or creator avatar |
| `Badge` | [badge.dart](lib/shared/widgets/badge.dart) | Status / label badges |
| `ChatBubble` | [chat_bubble.dart](lib/shared/widgets/chat_bubble.dart) | Message bubble for community/AI chat |
| `NotifCard` | [notif_card.dart](lib/shared/widgets/notif_card.dart) | Notification list item |
| `ShoppingRow` | [shopping_row.dart](lib/shared/widgets/shopping_row.dart) | Shopping list item with checkbox |
| `SectionHeader` | [section_header.dart](lib/shared/widgets/section_header.dart) | Titled section with optional "see all" action |
| `EmptyState` | [empty_state.dart](lib/shared/widgets/empty_state.dart) | Placeholder for empty lists/states |
| `AkeliTabBar` | [tab_bar.dart](lib/shared/widgets/tab_bar.dart) | Custom tab bar component |

---

## 8. Data Models

All models are in [lib/shared/models/](lib/shared/models/) plus one in the recipes feature.

### Recipe ([recipe.dart](lib/shared/models/recipe.dart))

```
Recipe
  id, title, description, imageUrl
  prepTime, cookTime, servings
  difficulty, region, cuisine
  calories, protein, carbs, fat
  rating, reviewCount
  isLiked
  ingredients: List<RecipeIngredient>
  steps: List<RecipeStep>

RecipeIngredient
  name, quantity, unit

RecipeStep
  stepNumber, instruction, duration
```

### UserProfile ([user_profile.dart](lib/shared/models/user_profile.dart))

```
UserProfile
  id, fullName, username, avatarUrl
  createdAt, updatedAt

HealthProfile
  userId, age, gender, height, weight
  activityLevel, goal
  dietaryPreferences: List<String>
  allergies: List<String>
  targetCalories, targetProtein, targetCarbs, targetFat
```

### MealPlan ([meal_plan.dart](lib/shared/models/meal_plan.dart))

```
MealPlan
  id, userId, name
  startDate, endDate
  isActive
  entries: List<MealPlanEntry>

MealPlanEntry
  id, mealPlanId
  recipeId, recipeName, recipeImageUrl
  dayOfWeek, mealType (breakfast/lunch/dinner/snack)
  servings, isConsumed

ShoppingItem
  ingredient, quantity, unit
  recipeNames: List<String>  // which recipes need it
```

### Creator ([creator.dart](lib/shared/models/creator.dart))

```
Creator
  id, name, bio, avatarUrl
  specialties: List<String>
  followerCount, recipeCount
  isVerified

FanSubscription
  id, userId, creatorId
  startDate, endDate
  isActive
```

### RecipeTracking ([lib/features/recipes/domain/entities/recipe_tracking.dart](lib/features/recipes/domain/entities/recipe_tracking.dart))

```
RecipeImpression
  id, recipeId, userId
  viewedAt

RecipeOpen
  id, recipeId, userId
  openedAt, closedAt, durationSeconds
```

---

## 9. Backend — Supabase

**URL:** `https://njzqcftjzskwcpforwzf.supabase.co`

### Database Tables

| Table | Purpose |
|-------|---------|
| `recipe` | Published recipes |
| `recipe_ingredient` | Ingredients with quantities |
| `recipe_step` | Ordered cooking instructions |
| `recipe_like` | User ↔ recipe likes |
| `recipe_impression` | Lightweight view tracking |
| `recipe_open` | Session tracking with duration |
| `user_profile` | User accounts |
| `user_health_profile` | Health metrics & dietary preferences |
| `meal_plan` | Meal plans per user |
| `meal_plan_entry` | Individual meals inside a plan |
| `daily_nutrition_log` | Per-day nutrition totals |
| `weight_log` | Weight tracking entries |
| `fan_subscription` | Creator fan subscriptions |
| `subscription` | Premium subscriptions |

### RPC Functions (Postgres)

| Function | Called by | Purpose |
|----------|-----------|---------|
| `recommend_recipes(p_user_id, p_limit, p_offset, p_region?, p_difficulty?, p_max_time?)` | `feedProvider` | Personalized recipe recommendations |
| `search_recipes(p_query, p_limit, p_offset, ...)` | `searchRecipesProvider` | Full-text recipe search |
| `generate_shopping_list(p_meal_plan_id)` | `shoppingListProvider` | Aggregate ingredients from a meal plan |
| `search_creators(p_query, p_limit, p_offset)` | `fanEligibleCreatorsProvider` | Creator search |
| `get_creator_public_profile(p_creator_id)` | `creatorProfileProvider` | Public creator profile |

### Edge Functions

| Function | Called by | Purpose |
|----------|-----------|---------|
| `toggle-recipe-like` | `RecipeLikeNotifier` | Like / unlike a recipe |
| `generate-meal-plan` | `MealPlanGeneratorNotifier` | AI-generated weekly meal plan |
| `log-meal-consumption` | `MealConsumptionNotifier` | Mark a meal as consumed |
| `activate-fan-mode` | `FanModeNotifier` | Subscribe to a creator |
| `cancel-fan-mode` | `FanModeNotifier` | Cancel creator subscription |

---

## 10. Theme & Design Tokens

**File:** [lib/core/theme.dart](lib/core/theme.dart)

### Colors

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#3BB78F` (Teal) | Main CTAs, active states |
| Secondary | `#F5A623` (Orange) | Accents, highlights |
| Tertiary | `#8B7FD4` (Violet) | Tags, badges |

### Spacing

| Token | Value |
|-------|-------|
| `xs` | 4px |
| `sm` | 8px |
| `md` | 16px |
| `lg` | 24px |
| `xl` | 32px |
| `xxl` | 48px |

### Border Radius

| Token | Value |
|-------|-------|
| `sm` | 8px |
| `md` | 14px |
| `lg` | 20px |
| `xl` | 28px |
| `pill` | 999px |

### Typography

- **Font:** Nunito (loaded via `google_fonts`)
- **Dark mode:** Full dark theme with inverted palette, enabled automatically via system preference

---

## 11. Dependencies

### pubspec.yaml — Key Packages

**Backend**
```yaml
supabase_flutter: ^2.5.0        # Supabase client (auth, db, edge functions)
```

**State Management**
```yaml
flutter_riverpod: ^2.5.1        # State management
riverpod_annotation: ^2.3.5     # Code generation annotations
```

**Navigation**
```yaml
go_router: ^14.2.7              # Declarative routing with auth guards
```

**UI**
```yaml
google_fonts: ^6.2.1            # Nunito font
shimmer: ^3.0.0                 # Loading skeleton animations
smooth_page_indicator: ^1.1.0   # Carousel dot indicators
percent_indicator: ^4.2.3       # Progress bar / circle
fl_chart: ^0.68.0               # Nutrition charts (line, bar)
cached_network_image: ^3.3.1    # Network image with cache
image_picker: ^1.1.2            # Photo picker for profile
```

**Utilities**
```yaml
intl: ^0.20.0                   # Dates, i18n (locale: fr)
timeago: ^3.6.1                 # "2 hours ago" formatting
logger: ^2.3.0                  # Structured logging
visibility_detector: ^0.4.0     # Recipe impression tracking
cupertino_icons: ^1.0.8         # iOS-style icons
```

**Dev Dependencies**
```yaml
build_runner: ^2.4.11           # Code generation runner
riverpod_generator: ^2.4.3      # Generate Riverpod providers
custom_lint: ^0.7.6             # Riverpod lint rules
riverpod_lint: ^2.6.4           # Riverpod lint rules
```

---

## 12. Architectural Notes

### Feature Structure

Most features follow a simple flat structure:
```
features/my_feature/
  └── my_feature_page.dart
```

The **recipes** feature is the only one with Clean Architecture layers:
```
features/recipes/
  ├── data/        → datasources + repository implementations
  ├── domain/      → entities + repository interfaces
  ├── presentation/→ providers
  ├── feed_page.dart
  └── recipe_detail_page.dart
```

### Impression Tracking

Two-layer recipe tracking is implemented using `visibility_detector`:
1. **Impression** — logged when a recipe card enters the viewport
2. **Session** — logged when a recipe detail page is opened/closed, recording duration

### Supabase Calls Pattern

All Supabase interactions happen inside Riverpod providers. The typical pattern:

```dart
// Read
final data = await supabase.from('recipe').select().eq('id', id).single();

// RPC
final results = await supabase.rpc('recommend_recipes', params: {...});

// Edge Function
final result = await supabase.functions.invoke('toggle-recipe-like', body: {...});
```

### Code Generation

Providers using `@riverpod` annotation require running:
```bash
flutter pub run build_runner build
# or watch mode during development:
flutter pub run build_runner watch
```

### Localization

The app defaults to `fr` (French) locale. The `intl` package and `flutter_localizations` are set up, so adding new languages means adding ARB files and registering delegates.
