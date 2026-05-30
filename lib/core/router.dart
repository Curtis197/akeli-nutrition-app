import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../features/auth/auth_page.dart';
import '../features/auth/onboarding_page.dart';
import '../features/recipes/feed_page.dart';
import '../features/recipes/recipe_detail_page.dart';
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
import '../features/community/group_chat_page.dart';
import '../features/community/group_detail_page.dart';
import '../features/home/home_page.dart';
import '../features/support/support_page.dart';
import '../features/legal/privacy_policy_page.dart';
import '../features/legal/terms_of_service_page.dart';
import '../features/referral/referral_page.dart';
import '../features/settings/preferences_page.dart';
import '../shared/widgets/main_shell.dart';
import '../features/recipes/domain/entities/recipe_tracking.dart';
import '../features/recipes/creator_detail_page.dart';
import 'logger.dart';

// Routes

abstract class AkeliRoutes {
  static const auth = "/auth";
  static const onboarding = "/onboarding";
  static const home = "/home";
  static const mealPlanner = "/meal-planner";
  static const recipes = "/recipes";
  static const community = "/community";
  static const profile = "/profile";
  static const settings = "/settings";
  static const recipeDetail = "/recipe/:id";
  static const shoppingList = "/shopping-list";
  static const nutrition = "/nutrition";
  static const fanMode = "/fan-mode";
  static const subscription = "/subscription";
  static const aiChat = "/ai-chat";
  static const dietPlan = "/diet-plan";
  static const notifications = "/notifications";
  static const mealDetail = "/meal/:id";
  static const batchCooking = "/batch-cooking";
  static const nutritionPlan = "/nutrition-plan";
  static const groupChat = "/group/:id";
  static const groupDetail = "/group/:id/detail";
  static const support = "/support";
  static const privacyPolicy = "/privacy-policy";
  static const termsOfService = "/terms-of-service";
  static const referral = "/referral";
  static const preferences = "/preferences";
  static const dmChat = '/dm/:conversationId';
  static String dmChatPath(String id) => '/dm/$id';
  static const creatorDetail = '/creators/:creatorId';
  static String creatorDetailPath(String id) => '/creators/$id';

  static String recipeDetailPath(String id) => "/recipe/$id";
  static String mealDetailPath(String id) => "/meal/$id";
  static String groupChatPath(String id) => "/group/$id";
  static String groupDetailPath(String id) => "/group/$id/detail";
}

// RouterNotifier — triggers GoRouter refresh on auth state changes

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
    // Only refresh the router once the profile has settled (data or error),
    // not when it enters the loading state — that prevents the redirect loop
    // where hasProfile=false fires repeatedly while the fetch is in-flight.
    ref.listen(userProfileProvider, (_, next) {
      if (!next.isLoading) notifyListeners();
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

      final isOnAuthPage = state.uri.path == AkeliRoutes.auth;
      final isOnOnboarding = state.uri.path == AkeliRoutes.onboarding;

      appLogger.navigation(
        state.uri.path,
        '',
        reason: 'redirect check | isAuth: $isAuth | hasProfile: ${profile != null}',
      );

      if (!isAuth && !isOnAuthPage) {
        appLogger.navigation(state.uri.path, AkeliRoutes.auth, reason: 'unauthenticated → redirect to auth');
        return AkeliRoutes.auth;
      }
      
      if (isAuth && isOnAuthPage) {
        // If just authenticated, default to home. Once profile loads, we'll redirect to onboarding if needed.
        appLogger.navigation(state.uri.path, AkeliRoutes.home, reason: 'already authenticated → redirect to home');
        return AkeliRoutes.home;
      }

      if (isAuth) {
        if (profile != null) {
          if (!profile.onboardingDone && !isOnOnboarding) {
            final path = state.uri.path;
            if (path == AkeliRoutes.privacyPolicy || path == AkeliRoutes.termsOfService) {
              return null;
            }
            appLogger.navigation(state.uri.path, AkeliRoutes.onboarding, reason: 'onboarding not done → redirect to onboarding');
            return AkeliRoutes.onboarding;
          }
          if (profile.onboardingDone && isOnOnboarding) {
            appLogger.navigation(state.uri.path, AkeliRoutes.home, reason: 'onboarding already done → redirect to home');
            return AkeliRoutes.home;
          }
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: AkeliRoutes.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: AkeliRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AkeliRoutes.recipeDetail,
        builder: (context, state) {
          final recipeId = state.pathParameters['id']!;
          final source = state.extra as TrackingSource? ?? TrackingSource.feed;
          return RecipeDetailPage(recipeId: recipeId, source: source);
        },
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
        path: AkeliRoutes.creatorDetail,
        builder: (context, state) {
          final creatorId = state.pathParameters['creatorId']!;
          return CreatorDetailPage(creatorId: creatorId);
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

