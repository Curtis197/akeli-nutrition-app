import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/meal_plan.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Active meal plan — joins entry components with recipe + macro data
// ---------------------------------------------------------------------------

final activeMealPlanProvider =
    FutureProvider.autoDispose<MealPlan?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('meal_plan')
      .select(
        '*, meal_plan_entry(*, meal_plan_entry_component(*, recipe(id, title, cover_image_url, recipe_macro(calories, protein_g, carbs_g, fat_g))))',
      )
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
// Shopping list — kept as stub until ingredient data is seeded
// ---------------------------------------------------------------------------

final shoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) async {
  final plan = await ref.watch(activeMealPlanProvider.future);
  if (plan == null) return [];
  return [];
});

// ---------------------------------------------------------------------------
// Log meal consumption — Edge Function
// Logs all components of a meal entry in one call.
// ---------------------------------------------------------------------------

class MealConsumptionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> logConsumption(String mealPlanEntryId) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'log-meal-consumption',
        body: {'meal_plan_entry_id': mealPlanEntryId},
      );
    });
    if (state is AsyncData) ref.invalidate(activeMealPlanProvider);
  }
}

final mealConsumptionProvider =
    AsyncNotifierProvider.autoDispose<MealConsumptionNotifier, void>(
        MealConsumptionNotifier.new);

// ---------------------------------------------------------------------------
// Cooking sessions — for the active meal plan
// ---------------------------------------------------------------------------

final cookingSessionsProvider =
    FutureProvider.autoDispose<List<CookingSession>>((ref) async {
  final plan = await ref.watch(activeMealPlanProvider.future);
  if (plan == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('cooking_session')
      .select('*, recipe(id, title, cover_image_url)')
      .eq('meal_plan_id', plan.id)
      .order('planned_date');

  return data
      .map((e) => CookingSession.fromJson(e))
      .toList();
});

class CookingSessionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> create({
    required String mealPlanId,
    required String recipeId,
    required DateTime plannedDate,
    required int totalPortions,
    String? notes,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.from('cooking_session').insert({
        'user_id': user.id,
        'meal_plan_id': mealPlanId,
        'recipe_id': recipeId,
        'planned_date':
            '${plannedDate.year}-${plannedDate.month.toString().padLeft(2, '0')}-${plannedDate.day.toString().padLeft(2, '0')}',
        'total_portions': totalPortions,
        if (notes != null) 'notes': notes,
      });
    });
    if (state is AsyncData) ref.invalidate(cookingSessionsProvider);
  }
}

final cookingSessionNotifierProvider =
    AsyncNotifierProvider.autoDispose<CookingSessionNotifier, void>(
        CookingSessionNotifier.new);
