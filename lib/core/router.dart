import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
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
import '../shared/widgets/main_shell.dart';

// Routes

abstract class AkeliRoutes {
  static const auth = "/auth";
  static const onboarding = "/onboarding";
  static const home = "/home";
  static const mealPlanner = "/meal-planner";
  static const community = "/community";
  static const profile = "/profile";
  static const recipeDetail = "/recipe/:id";
  static const shoppingList = "/shopping-list";
  static const nutrition = "/nutrition";
  static const fanMode = "/fan-mode";
  static const subscription = "/subscription";
  static const aiChat = "/ai-chat";

  static String recipeDetailPath(String id) => "/recipe/$id";
}

// RouterNotifier — triggers GoRouter refresh on auth state changes

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

// Router provider

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AkeliRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isAuth = user != null;
      final isOnAuthPage = state.uri.path == AkeliRoutes.auth;
      final isOnOnboarding = state.uri.path == AkeliRoutes.onboarding;

      if (!isAuth && !isOnAuthPage) return AkeliRoutes.auth;
      if (isAuth && isOnAuthPage) return AkeliRoutes.home;
      if (isAuth && isOnOnboarding) return null;
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
          final id = state.pathParameters["id"]!;
          return RecipeDetailPage(recipeId: id);
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
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AkeliRoutes.home,
            builder: (context, state) => const FeedPage(),
          ),
          GoRoute(
            path: AkeliRoutes.mealPlanner,
            builder: (context, state) => const MealPlannerPage(),
          ),
          GoRoute(
            path: AkeliRoutes.community,
            builder: (context, state) => const CommunityPage(),
          ),
          GoRoute(
            path: AkeliRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text("Page introuvable: ${state.error}")),
    ),
  );
});
