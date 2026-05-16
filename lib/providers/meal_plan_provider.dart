import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/meal_plan.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Active meal plan — joins meal_plan_entry
// ---------------------------------------------------------------------------

final activeMealPlanProvider =
    FutureProvider.autoDispose<MealPlan?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('meal_plan')
      .select('*, meal_plan_entry(*)')
      .eq('user_id', user.id)
      .eq('is_active', true)
      .maybeSingle();
  if (data == null) return null;
  return MealPlan.fromJson(data);
});

// ---------------------------------------------------------------------------
// Generate meal plan — Edge Function
// ---------------------------------------------------------------------------

class MealPlanGeneratorNotifier extends AutoDisposeAsyncNotifier<MealPlan?> {
  @override
  Future<MealPlan?> build() async => null;

  Future<void> generate({int days = 7, int mealsPerDay = 3}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'generate-meal-plan',
        body: {'days': days, 'meals_per_day': mealsPerDay},
      );
      return null;
    });
    if (state is AsyncData) {
      ref.invalidate(activeMealPlanProvider);
    }
  }
}

final mealPlanGeneratorProvider =
    AsyncNotifierProvider.autoDispose<MealPlanGeneratorNotifier, MealPlan?>(
        MealPlanGeneratorNotifier.new);

// ---------------------------------------------------------------------------
// Shopping list — kept as mock until ingredient data is seeded
// ---------------------------------------------------------------------------

final shoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) async {
  final plan = await ref.watch(activeMealPlanProvider.future);
  if (plan == null) return [];

  // No ingredient data seeded yet — returns empty list.
  return [];
});

// ---------------------------------------------------------------------------
// Log meal consumption — Edge Function
// ---------------------------------------------------------------------------

class MealConsumptionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> logConsumption(String entryId, String recipeId) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'log-meal-consumption',
        body: {'entry_id': entryId, 'recipe_id': recipeId},
      );
    });
    if (state is AsyncData) ref.invalidate(activeMealPlanProvider);
  }
}

final mealConsumptionProvider =
    AsyncNotifierProvider.autoDispose<MealConsumptionNotifier, void>(
        MealConsumptionNotifier.new);
