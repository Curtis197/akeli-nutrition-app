import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/meal_plan.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Active meal plan
// ---------------------------------------------------------------------------

final activeMealPlanProvider =
    FutureProvider.autoDispose<MealPlan?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final data = await supabase
      .from('meal_plan')
      .select()
      .eq('user_id', user.id)
      .eq('is_active', true)
      .maybeSingle();

  if (data == null) return null;

  final entries = await supabase
      .from('meal_plan_entry')
      .select('''
        *,
        recipe:recipe_id ( title, thumbnail_url, calories, protein_g, carbs_g, fat_g )
      ''')
      .eq('meal_plan_id', data['id'] as String);

  final entriesData = (entries as List<dynamic>).map((e) {
    final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
    final recipe = map['recipe'] as Map<String, dynamic>?;
    if (recipe != null) {
      map['recipe_title'] = recipe['title'];
      map['recipe_thumbnail'] = recipe['thumbnail_url'];
      map['calories'] = recipe['calories'];
      map['protein_g'] = recipe['protein_g'];
      map['carbs_g'] = recipe['carbs_g'];
      map['fat_g'] = recipe['fat_g'];
    }
    return map;
  }).toList();

  data['entries'] = entriesData;
  return MealPlan.fromJson(data);
});

// ---------------------------------------------------------------------------
// Generate meal plan notifier
// ---------------------------------------------------------------------------

class MealPlanGeneratorNotifier extends AutoDisposeAsyncNotifier<MealPlan?> {
  @override
  Future<MealPlan?> build() async => null;

  Future<void> generate({int days = 7, int mealsPerDay = 3}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await supabase.functions.invoke(
        'generate-meal-plan',
        body: {
          'days': days,
          'meals_per_day': mealsPerDay,
        },
      );

      final raw = res.data as Map<String, dynamic>;
      ref.invalidate(activeMealPlanProvider);

      // Re-fetch the newly created plan
      final data = await supabase
          .from('meal_plan')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      if (data == null) return null;

      final entries = await supabase
          .from('meal_plan_entry')
          .select('''
            *,
            recipe:recipe_id ( title, thumbnail_url, calories, protein_g, carbs_g, fat_g )
          ''')
          .eq('meal_plan_id', data['id'] as String);

      final entriesData = (entries as List<dynamic>).map((e) {
        final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
        final recipe = map['recipe'] as Map<String, dynamic>?;
        if (recipe != null) {
          map['recipe_title'] = recipe['title'];
          map['recipe_thumbnail'] = recipe['thumbnail_url'];
          map['calories'] = recipe['calories'];
          map['protein_g'] = recipe['protein_g'];
          map['carbs_g'] = recipe['carbs_g'];
          map['fat_g'] = recipe['fat_g'];
        }
        return map;
      }).toList();

      data['entries'] = entriesData;
      return MealPlan.fromJson(data);
    });
  }
}

final mealPlanGeneratorProvider =
    AsyncNotifierProvider.autoDispose<MealPlanGeneratorNotifier, MealPlan?>(
        MealPlanGeneratorNotifier.new);

// ---------------------------------------------------------------------------
// Shopping list (via RPC)
// ---------------------------------------------------------------------------

final shoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) async {
  final plan = await ref.watch(activeMealPlanProvider.future);
  if (plan == null) return [];

  final result = await supabase.rpc(
    'generate_shopping_list',
    params: {'p_meal_plan_id': plan.id},
  );

  return (result as List<dynamic>)
      .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Log meal consumption notifier
// ---------------------------------------------------------------------------

class MealConsumptionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> logConsumption(String entryId, String recipeId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.functions.invoke(
        'log-meal-consumption',
        body: {
          'meal_plan_entry_id': entryId,
          'recipe_id': recipeId,
        },
      );
      ref.invalidate(activeMealPlanProvider);
    });
  }
}

final mealConsumptionProvider =
    AsyncNotifierProvider.autoDispose<MealConsumptionNotifier, void>(
        MealConsumptionNotifier.new);
