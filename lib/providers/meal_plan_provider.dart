import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/mock_data.dart';
import '../shared/models/meal_plan.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Active meal plan
// ---------------------------------------------------------------------------

final activeMealPlanProvider =
    FutureProvider.autoDispose<MealPlan?>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600)); // Simuler latence
  return MockData.mealPlan;
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
      await Future.delayed(const Duration(seconds: 2)); // Simuler génération
      
      // En mode mockup, on se contente de rafraîchir le plan actif
      // (on pourrait générer de nouvelles entrées aléatoires ici si besoin)
      
      ref.invalidate(activeMealPlanProvider);
      return ref.read(activeMealPlanProvider.future);
    });
  }
}

final mealPlanGeneratorProvider =
    AsyncNotifierProvider.autoDispose<MealPlanGeneratorNotifier, MealPlan?>(
        MealPlanGeneratorNotifier.new);

// ---------------------------------------------------------------------------
// Shopping list (Mocked)
// ---------------------------------------------------------------------------

final shoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) async {
  final plan = await ref.watch(activeMealPlanProvider.future);
  if (plan == null) return [];

  await Future.delayed(const Duration(milliseconds: 700));

  // Mock list d'ingrédients
  return [
    const ShoppingItem(ingredientId: 'i1', name: 'Riz brisé', quantity: 1, unit: 'kg', isChecked: false, category: 'Céréales'),
    const ShoppingItem(ingredientId: 'i2', name: 'Mérou (Thiof)', quantity: 1.5, unit: 'kg', isChecked: false, category: 'Poisson'),
    const ShoppingItem(ingredientId: 'i3', name: 'Concentré de tomate', quantity: 200, unit: 'g', isChecked: true, category: 'Conserves'),
    const ShoppingItem(ingredientId: 'i4', name: 'Feuilles de Ndolé', quantity: 500, unit: 'g', isChecked: false, category: 'Légumes'),
    const ShoppingItem(ingredientId: 'i5', name: 'Arachides blanches', quantity: 300, unit: 'g', isChecked: false, category: 'Épicerie'),
  ];
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
      await Future.delayed(const Duration(seconds: 1));
      
      // Update local mock data (simple mock implementation)
      final index = MockData.mealPlan.entries.indexWhere((m) => m.id == entryId);
      if (index != -1) {
        // Here we just invalidate the provider. 
        // In a real mock we'd update a state or the global MockData object.
      }
      
      ref.invalidate(activeMealPlanProvider);
    });
  }
}

final mealConsumptionProvider =
    AsyncNotifierProvider.autoDispose<MealConsumptionNotifier, void>(
        MealConsumptionNotifier.new);
