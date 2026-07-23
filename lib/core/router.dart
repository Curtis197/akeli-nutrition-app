import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/sdui/widgets/dynamic_layout_page.dart';

import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/mode_provider.dart';
import '../features/auth/auth_page.dart';
import '../features/auth/onboarding_page.dart';
import '../features/auth/reset_password_page.dart';
import '../features/recipes/feed_page.dart';
import '../features/recipes/recipe_detail_page.dart';
import '../features/recipes/saved_recipes_page.dart';
import '../features/meal_planner/meal_planner_page.dart';
import '../features/meal_planner/shopping_list_page.dart';
import '../features/nutrition/nutrition_page.dart';
import '../features/community/community_page.dart';
import '../features/fan_mode/fan_mode_page.dart';
import '../features/subscription/subscription_page.dart';
import '../features/ai_assistant/ai_chat_page.dart';
import '../features/profile/profile_page.dart';
import '../features/settings/settings_page.dart';
import '../features/meal_planner/meal_detail_page.dart';
import '../features/meal_planner/batch_cooking_page.dart';
import '../features/nutrition_plan/nutrition_plan_page.dart';
import '../features/diet_plan/diet_plan_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/settings/notification_settings_page.dart';
import '../features/community/group_chat_page.dart';
import '../features/community/group_detail_page.dart';
import '../features/community/browse_groups_page.dart';
import '../features/home/home_page.dart';
import '../features/support/support_page.dart';
import '../features/legal/privacy_policy_page.dart';
import '../features/legal/terms_of_service_page.dart';
import '../features/referral/referral_page.dart';
import '../features/settings/preferences_page.dart';
import '../features/settings/health_profile_page.dart';
import '../features/settings/account_page.dart';
import '../features/beauty/beauty_onboarding_page.dart';
import '../features/beauty/beauty_analytics_page.dart';
import '../features/settings/meal_schedule_page.dart';
import '../shared/widgets/main_shell.dart';
import '../features/recipes/domain/entities/recipe_tracking.dart';
import '../features/recipes/creator_detail_page.dart';
import '../features/cooking/cooking_mode_page.dart';
import '../features/meal_planner/batch_cooking_detail_page.dart';
import '../shared/models/meal_plan.dart';
import '../shared/models/recipe.dart';
import 'logger.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Routes

abstract class AkeliRoutes {
  static const auth = "/auth";
  static const onboarding = "/onboarding";
  static const beautyOnboarding = "/onboarding/beauty";
  static const home = "/home";
  static const mealPlanner = "/meal-planner";
  static const recipes = "/recipes";
  static const community = "/community";
  static const profile = "/profile";
  static const settings = "/settings";
  static const recipeDetail = "/recipe/:id";
  static const savedRecipes = "/saved-recipes";
  static const shoppingList = "/shopping-list";
  static const nutrition = "/nutrition";
  static const beautyAnalytics = "/beauty-analytics";
  static const fanMode = "/fan-mode";
  static const subscription = "/subscription";
  static const aiChat = "/ai-chat";
  static const dietPlan = "/diet-plan";
  static const notifications = "/notifications";
  static const mealDetail = "/meal/:id";
  static const batchCooking = "/batch-cooking";
  static const batchCookingDetail = "/batch-cooking/:sessionId";
  static String batchCookingDetailPath(String id) => "/batch-cooking/$id";
  static const nutritionPlan = "/nutrition-plan";
  static const groupChat = "/group/:id";
  static const groupDetail = "/group/:id/detail";
  static const browseGroups = "/groups/browse";
  static const support = "/support";
  static const privacyPolicy = "/privacy-policy";
  static const termsOfService = "/terms-of-service";
  static const referral = "/referral";
  static const preferences = "/preferences";
  static const healthProfile = '/health-profile';
  static const notificationSettings = '/notification-settings';
  static const account = '/account';
  static const mealSchedule = '/meal-schedule';
  static const dmChat = '/dm/:conversationId';
  static String dmChatPath(String id) => '/dm/$id';
  static const creatorDetail = '/creators/:creatorId';
  static String creatorDetailPath(String id) => '/creators/$id';
  static const userProfile = '/users/:userId';
  static String userProfilePath(String id) => '/users/$id';

  static String recipeDetailPath(String id) => "/recipe/$id";
  static const recipeCook = '/recipe/:id/cook';
  static String recipeCookPath(String id) => '/recipe/$id/cook';
  static String mealDetailPath(String id) => "/meal/$id";
  static String groupChatPath(String id) => "/group/$id";
  static String groupDetailPath(String id) => "/group/$id/detail";
  static const resetPassword = "/reset-password";
  static const sduiDemo = '/sdui-demo';
}

// ---------------------------------------------------------------------------
// Redirect logic — pure function, unit-testable without Riverpod/Supabase.
// See test/core/router_redirect_test.dart.
//
// Routes that gate on Beauty-mode onboarding regardless of the user's
// currently-selected AppMode (Finding #3 — deep links / bookmarks / browser
// back-forward on the web target must not bypass the gate just because
// currentMode happens to be nutrition).
// ---------------------------------------------------------------------------
const _beautyGatedRoutes = <String>{
  AkeliRoutes.beautyAnalytics,
};

/// Computes the GoRouter redirect target for the current navigation state, or
/// `null` if no redirect is needed.
///
/// Exposed (not private) so it can be unit-tested directly — see
/// test/core/router_redirect_test.dart — without needing to spin up
/// Supabase, Riverpod, or a real GoRouter.
///
/// IMPORTANT — mutual exclusivity: the nutrition-onboarding gate and the
/// beauty-onboarding gate are evaluated as a single if/else-if chain, never
/// as independent sequential ifs. Two independent ifs is what caused
/// Finding #1's infinite redirect loop: a user with onboardingDone == false
/// AND beautyOnboardingDone == false AND currentMode == AppMode.beauty
/// would be bounced from /onboarding -> /onboarding/beauty (by the old
/// third if) and then immediately back from /onboarding/beauty ->
/// /onboarding (by the old first if), forever — go_router's own loop
/// detection turns that into a thrown GoException.
String? computeAkeliRedirect({
  required bool isAuthenticated,
  required bool isRecovery,
  required String currentPath,
  required bool hasProfile,
  required bool onboardingDone,
  required bool beautyOnboardingDone,
  required AppMode currentMode,
}) {
  final isOnAuthPage = currentPath == AkeliRoutes.auth;
  final isOnResetPassword = currentPath == AkeliRoutes.resetPassword;
  final isOnOnboarding = currentPath == AkeliRoutes.onboarding;
  final isOnBeautyOnboarding = currentPath == AkeliRoutes.beautyOnboarding;
  final isOnPrivacyOrTerms =
      currentPath == AkeliRoutes.privacyPolicy || currentPath == AkeliRoutes.termsOfService;
  final isOnBeautyGatedRoute = _beautyGatedRoutes.contains(currentPath);

  if (isRecovery && !isOnResetPassword) {
    return AkeliRoutes.resetPassword;
  }

  if (!isAuthenticated && !isOnAuthPage && !isOnResetPassword) {
    return AkeliRoutes.auth;
  }

  if (isAuthenticated && isOnAuthPage) {
    return AkeliRoutes.home;
  }

  if (isAuthenticated && hasProfile) {
    // Privacy Policy / Terms of Service must always be reachable, regardless
    // of which onboarding stage the user is stuck on.
    if (isOnPrivacyOrTerms) {
      return null;
    }

    // --- Nutrition onboarding gate (always evaluated first) -----------------
    if (!onboardingDone) {
      if (!isOnOnboarding) {
        return AkeliRoutes.onboarding;
      }
      // Already on the nutrition onboarding page — stop here. Do NOT fall
      // through to the beauty gate below; that fall-through is exactly what
      // caused Finding #1's infinite loop.
      return null;
    }

    if (isOnOnboarding) {
      // Nutrition onboarding is done but the user is still viewing that page.
      return AkeliRoutes.home;
    }

    // --- Beauty onboarding gate (only reached once nutrition onboarding is
    // confirmed done) — keyed on EITHER the active mode OR the destination
    // route, so a user can't dodge it by switching currentMode to nutrition
    // and deep-linking straight into a beauty-gated route (Finding #3). ------
    final needsBeautyOnboarding =
        (currentMode == AppMode.beauty || isOnBeautyGatedRoute) && !beautyOnboardingDone;
    if (needsBeautyOnboarding) {
      if (!isOnBeautyOnboarding) {
        return AkeliRoutes.beautyOnboarding;
      }
      return null;
    }

    if (beautyOnboardingDone && isOnBeautyOnboarding) {
      return AkeliRoutes.home;
    }
  }

  return null;
}

// RouterNotifier — triggers GoRouter refresh on auth state changes

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
    ref.listen(currentModeProvider, (_, __) => notifyListeners());
    // Only refresh the router once the profile has settled (data or error),
    // not when it enters the loading state — that prevents the redirect loop
    // where hasProfile=false fires repeatedly while the fetch is in-flight.
    ref.listen(userProfileProvider, (_, next) {
      if (!next.isLoading) notifyListeners();
    });
    // isAuthenticatedProvider only flips when auth transitions false→true, so
    // a passwordRecovery event that arrives while a session already exists
    // (the normal case for the recovery deep link) would never trigger a
    // router refresh without this — the redirect callback below reads
    // authStreamProvider directly, but nothing was invalidating it. Also
    // refresh on userUpdated so the reset-password redirect clears once the
    // user has actually changed their password.
    ref.listen(authStreamProvider, (_, next) {
      final event = next.valueOrNull?.event;
      if (event == AuthChangeEvent.passwordRecovery || event == AuthChangeEvent.userUpdated) {
        appLogger.navigation('', '', reason: 'authStreamProvider event: $event → router refresh');
        notifyListeners();
      }
    });
  }
}

// Router provider

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AkeliRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isAuth = user != null;
      final profileAsync = ref.read(userProfileProvider);
      final profile = profileAsync.valueOrNull;
      final currentMode = ref.read(currentModeProvider);

      final authState = ref.read(authStreamProvider).valueOrNull;
      final isRecovery = authState?.event == AuthChangeEvent.passwordRecovery;

      appLogger.navigation(
        state.uri.path,
        '',
        reason: 'redirect check | isAuth: $isAuth | hasProfile: ${profile != null}',
      );

      final target = computeAkeliRedirect(
        isAuthenticated: isAuth,
        isRecovery: isRecovery,
        currentPath: state.uri.path,
        hasProfile: profile != null,
        onboardingDone: profile?.onboardingDone ?? false,
        beautyOnboardingDone: profile?.beautyOnboardingDone ?? false,
        currentMode: currentMode,
      );

      if (target != null) {
        appLogger.navigation(state.uri.path, target, reason: 'computeAkeliRedirect');
      }

      return target;
    },
    routes: [
      GoRoute(
        path: AkeliRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AkeliRoutes.beautyOnboarding,
        builder: (context, state) => const BeautyOnboardingPage(),
      ),
      GoRoute(
        path: AkeliRoutes.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: AkeliRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AkeliRoutes.recipeDetail,
        builder: (context, state) {
          final recipeId = state.pathParameters['id']!;
          final source = state.extra as TrackingSource? ?? TrackingSource.feed;
          return RecipeDetailPage(recipeId: recipeId, source: source);
        },
        routes: [
          GoRoute(
            path: 'cook',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              if (extra == null || extra['recipe'] == null) {
                final recipeId = state.pathParameters['id']!;
                appLogger.navigation(
                  '/recipe/$recipeId/cook',
                  '/recipe/$recipeId',
                  reason: 'cook route missing extra — falling back to detail page',
                );
                return RecipeDetailPage(recipeId: recipeId, source: TrackingSource.feed);
              }
              appLogger.userAction(
                'Navigate to cooking mode',
                screen: 'CookingModePage',
                metadata: {'recipeId': state.pathParameters['id']},
              );
              return CookingModePage(
                recipe: extra['recipe'] as Recipe,
                initialStepIndex: (extra['initialStepIndex'] as int?) ?? 0,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AkeliRoutes.savedRecipes,
        builder: (context, state) => const SavedRecipesPage(),
      ),
      GoRoute(
        path: AkeliRoutes.shoppingList,
        builder: (context, state) => const ShoppingListPage(),
      ),
      GoRoute(
        path: AkeliRoutes.nutrition,
        builder: (context, state) => const NutritionPage(),
      ),
      GoRoute(
        path: AkeliRoutes.fanMode,
        builder: (context, state) => const FanModePage(),
      ),
      GoRoute(
        path: AkeliRoutes.subscription,
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(
        path: AkeliRoutes.aiChat,
        builder: (context, state) => const AiChatPage(),
      ),
      GoRoute(
        path: AkeliRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AkeliRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AkeliRoutes.dietPlan,
        builder: (context, state) => const DietPlanPage(),
      ),
      GoRoute(
        path: AkeliRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AkeliRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: AkeliRoutes.account,
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: AkeliRoutes.mealDetail,
        builder: (context, state) {
          final id = state.pathParameters["id"]!;
          return MealDetailPage(mealId: id);
        },
        routes: [
          GoRoute(
            path: 'swap-recipe',
            builder: (context, state) {
              final id = state.pathParameters["id"]!;
              return FeedPage(swapEntryId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AkeliRoutes.batchCooking,
        builder: (context, state) => const BatchCookingPage(),
      ),
      GoRoute(
        path: AkeliRoutes.batchCookingDetail,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final initialSession = extra?['session'] as CookingSession?;
          return BatchCookingDetailPage(
            sessionId: sessionId,
            initialSession: initialSession,
          );
        },
      ),
      GoRoute(
        path: AkeliRoutes.nutritionPlan,
        builder: (context, state) => const NutritionPlanPage(),
      ),
      GoRoute(
        path: AkeliRoutes.groupChat,
        builder: (context, state) {
          final id = state.pathParameters["id"]!;
          return GroupChatPage(groupId: id);
        },
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final id = state.pathParameters["id"]!;
              return GroupDetailPage(groupId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AkeliRoutes.browseGroups,
        builder: (context, state) => const BrowseGroupsPage(),
      ),
      GoRoute(
        path: AkeliRoutes.support,
        builder: (context, state) => const SupportPage(),
      ),
      GoRoute(
        path: AkeliRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AkeliRoutes.termsOfService,
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: AkeliRoutes.referral,
        builder: (context, state) => const ReferralPage(),
      ),
      GoRoute(
        path: AkeliRoutes.preferences,
        builder: (context, state) => const PreferencesPage(),
      ),
      GoRoute(
        path: AkeliRoutes.healthProfile,
        builder: (context, state) => const HealthProfilePage(),
      ),
      GoRoute(
        path: AkeliRoutes.beautyAnalytics,
        builder: (context, state) => const BeautyAnalyticsPage(),
      ),
      GoRoute(
        path: AkeliRoutes.mealSchedule,
        builder: (context, state) => const MealSchedulePage(),
      ),
      GoRoute(
        path: AkeliRoutes.creatorDetail,
        builder: (context, state) {
          final creatorId = state.pathParameters['creatorId']!;
          return CreatorDetailPage(creatorId: creatorId);
        },
      ),
      GoRoute(
        path: AkeliRoutes.userProfile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfilePage(userId: userId);
        },
      ),
      // DM-6 will add conversationId/title params to GroupChatPage
      GoRoute(
        path: AkeliRoutes.dmChat,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final title = state.extra as String? ?? 'Message privé';
          return GroupChatPage(conversationId: conversationId, title: title);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AkeliRoutes.home,
            builder: (context, state) => const HomePage(),
          ),

          GoRoute(
            path: AkeliRoutes.sduiDemo,
            builder: (context, state) => const DynamicLayoutPage(mode: 'nutrition'),
          ),
          GoRoute(
            path: AkeliRoutes.mealPlanner,
            builder: (context, state) => const MealPlannerPage(),
          ),
          GoRoute(
            path: AkeliRoutes.recipes,
            builder: (context, state) => const FeedPage(),
          ),
          GoRoute(
            path: AkeliRoutes.community,
            builder: (context, state) => const CommunityPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text("Page introuvable: ${state.error}")),
    ),
  );
});

