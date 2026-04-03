# Design Migration Inventory: Pages & Components

This document lists all pages and components from the FlutterFlow export and the current consolidated Flutter project.

## 1. Flutterflow Code (`flutterflow_application/akeli`)

**Pages (exported in `index.dart`):**
- `HomePageWidget` (`/home_page/home_page/home_page_widget.dart`)
- `MealPlannerWidget` (`/meal_planner/meal_planner/meal_planner_widget.dart`)
- `MealDetailWidget` (`/meal_planner/meal_detail/meal_detail_widget.dart`)
- `ProfileSettingWidget` (`/profil_management/profile_setting/profile_setting_widget.dart`)
- `NotificationsWidget` (`/profil_management/notifications/notifications_widget.dart`)
- `ForgottenPasswordWidget` (`/user_authentification/forgotten_password/forgotten_password_widget.dart`)
- `CommunityWidget` (`/community/community_widget.dart`)
- `ChatPageWidget` (`/chat_page/chat_page_widget.dart`)
- `GroupPageWidget` (`/group_page/group_page_widget.dart`)
- `InscriptionpageWidget` (`/inscriptionpage/inscriptionpage_widget.dart`)
- `CreateEditProfilWidget` (`/create_edit_profil/create_edit_profil_widget.dart`)
- `EditInfoWidget` (`/edit_info/edit_info_widget.dart`)
- `PaymentSubscriptionWidget` (`/payment_subscription/payment_subscription_widget.dart`)
- `SupportWidget` (`/support/support_widget.dart`)
- `UserprofileWidget` (`/userprofile/userprofile_widget.dart`)
- `DashWidget` (`/dash/dash_widget.dart`)
- `ShoppingListWidget` (`/shopping_list/shopping_list_widget.dart`)
- `TestWidget` (`/test/test_widget.dart`)
- `DietPlanWidget` (`/diet_plan/diet_plan_widget.dart`)
- `ReferralWidget` (`/referral/referral_widget.dart`)
- `RecipeResearchingListWidget` (`/recipe_researching_list/recipe_researching_list_widget.dart`)
- `NotificationSettingWidget` (`/notification_setting/notification_setting_widget.dart`)
- `CguWidget` (`/cgu/cgu_widget.dart`)
- `RgpdWidget` (`/rgpd/rgpd_widget.dart`)
- `ConditionWidget` (`/condition/condition_widget.dart`)
- `ReceipeDetailWidget` (`/receipe_detail/receipe_detail_widget.dart`)
- `AuthentificationWidget` (`/user_authentification/authentification/authentification_widget.dart`)
- `CreatorProfilWidget` (`/creator_profil/creator_profil_widget.dart`)

**Components (`lib/components`):**
- `add_meal_widget.dart`
- `ai_chat_copy_widget.dart`
- `chat_copy2_widget.dart`
- `chat_copy_widget.dart`
- `conversation_message_widget.dart`
- `daily_recap_widget.dart`
- `error_comp_widget.dart`
- `meal_plan_error_widget.dart`
- `notification_chat_widget.dart`
- `notification_demand_widget.dart`
- `notification_widget.dart`
- `ordering_icon_widget.dart`
- `oredering_selector_widget.dart`
- `recipe_filters_widget.dart`
- `tag_and_or_widget.dart`
- `textfield_widget.dart`
- `unpaid_meal_widget.dart`
- `weeklyrecap_copy_widget.dart`
- `weeklyrecap_widget.dart`
- `weekly_int_copy_widget.dart`
- `weekly_int_widget.dart`

---

## 2. Current Flutter Code (`lib`)

**Pages (`lib/features`):**
- **AI Assistant**: `ai_chat_page.dart` (path: `lib/features/ai_assistant/ai_chat_page.dart`)
- **Auth**: `auth_page.dart`, `onboarding_page.dart` (path: `lib/features/auth/`)
- **Community**: `community_page.dart`, `group_chat_page.dart`, `group_detail_page.dart` (path: `lib/features/community/`)
- **Diet Plan**: `diet_plan_page.dart` (path: `lib/features/diet_plan/diet_plan_page.dart`)
- **Fan Mode**: `fan_mode_page.dart` (path: `lib/features/fan_mode/fan_mode_page.dart`)
- **Home**: `home_page.dart` (path: `lib/features/home/home_page.dart`)
- **Meal Planner**: `meal_planner_page.dart`, `meal_detail_page.dart`, `shopping_list_page.dart` (path: `lib/features/meal_planner/`)
- **Notifications**: `notifications_page.dart` (path: `lib/features/notifications/notifications_page.dart`)
- **Nutrition**: `nutrition_page.dart` (path: `lib/features/nutrition/nutrition_page.dart`)
- **Profile**: `profile_page.dart` (path: `lib/features/profile/profile_page.dart`)
- **Recipes**: `feed_page.dart`, `recipe_detail_page.dart` (path: `lib/features/recipes/`)
- **Subscription**: `subscription_page.dart` (path: `lib/features/subscription/subscription_page.dart`)

**Shared Components (`lib/shared/widgets`):**
- `akeli_recipe_card.dart`
- `akeli_weight_stepper.dart`
- `avatar.dart`
- `badge.dart`
- `chat_bubble.dart`
- `empty_state.dart`
- `macro_card.dart`
- `main_shell.dart`
- `meal_card.dart`
- `notif_card.dart`
- `progress_circle.dart`
- `recipe_card.dart`
- `section_header.dart`
- `shopping_row.dart`
- `tab_bar.dart`

**Feature-Specific Components:**
- `lib/features/meal_planner/widgets/meal_planner_day_row.dart`

**Navigation Context:**
- Current app navigation is managed in `lib/core/router.dart` using `go_router`.
- Main Shell (Bottom Nav) includes: Home, Meal Planner, Recipes, Community.

## 3. Audit Progress (Component Migration)

The following groups have been audited and are ready for high-fidelity design generation (Stitch) and native Flutter implementation.

| Audit Group | Status | Consolidated Components |
| :--- | :--- | :--- |
| **Basic UI Atoms** | `Audited` | `Avatar`, `Badge`, `TabBar`, `SectionHeader`, `ProgressCircle` |
| **Messaging & AI** | `Audited` | `AiChatCopy`, `ChatBubble`, `ConversationMessage` |
| **Notifications** | `Audited` | `NotificationDemand`, `NotificationChat`, `Notification` |
| **Nutritional Recap**| `Audited` | `WeeklyInt`, `WeeklyRecap`, `DailyRecap` |
| **Premium & Conversion**| `Audited` | `UnpaidMealWidget`, `SubscriptionPlans` |
| **Interactive Utilities**| `Audited` | `TagAndOr`, `OrderingSelector`, `TextField` |
| **Recipe Discovery** | `Audited` | `RecipeCard`, `RecipeFilters` |
| **Meal Planner Core** | `Audited` | `MealCard`, `AddMealWidget`, `ShoppingRow` |
| **Status & Error** | `Audited` | `ErrorComp`, `MealPlanError`, `EmptyState` |

---

**Next Phase**: Page-Level Audits (e.g., `HomePage`, `AiChatPage`) once component-level implementation begins.
