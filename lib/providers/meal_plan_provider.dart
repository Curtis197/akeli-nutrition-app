import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/logger.dart';
import '../shared/models/meal_plan.dart';
import 'auth_provider.dart';
import 'recipe_provider.dart';

// ---------------------------------------------------------------------------
// Active meal plan — joins entry components with recipe + macro data
// ---------------------------------------------------------------------------

final activeMealPlanProvider =
    FutureProvider.autoDispose<MealPlan?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  appLogger.provider('activeMealPlanProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('activeMealPlanProvider disposed'));
  appLogger.db('BEFORE | table: meal_plan | op: SELECT with joins | userId: ${user.id} | is_active: true');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('meal_plan')
        .select(
          '*, meal_plan_entry(*, meal_ingredient(*), meal_plan_entry_component(*, recipe(id, title, cover_image_url, prep_time_min, cook_time_min, recipe_macro(calories, protein_g, carbs_g, fat_g))))',
        )
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();
    appLogger.db('AFTER | table: meal_plan | rows: ${data == null ? 0 : 1} | userId: ${user.id}');
    if (data == null) {
      appLogger.rls('Zero rows | table: meal_plan | userId: ${user.id} | no active plan or RLS block');
      appLogger.provider('activeMealPlanProvider → data (null)');
      return null;
    }
    appLogger.db('BEFORE | table: recipe_comment | op: SELECT rated recipes | userId: ${user.id}');
    Set<String> ratedRecipeIds;
    try {
      final ratedResult = await client
          .from('recipe_comment')
          .select('recipe_id')
          .eq('user_id', user.id)
          .not('rating', 'is', null);
      ratedRecipeIds = (ratedResult as List)
          .map((r) => r['recipe_id'] as String)
          .toSet();
      appLogger.db('AFTER | table: recipe_comment | rows: ${ratedRecipeIds.length}');
      if (ratedRecipeIds.isEmpty) {
        appLogger.rls('Zero rows | table: recipe_comment | userId: ${user.id} | no ratings or RLS block');
      }
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        appLogger.rls('Permission denied | table: recipe_comment | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        appLogger.db('ERROR | table: recipe_comment | code: ${e.code}', error: e, stackTrace: st);
      }
      appLogger.provider('activeMealPlanProvider → error | ${e.message}');
      rethrow;
    }
    appLogger.provider('activeMealPlanProvider → data | mealPlanId: ${data['id']} | ratedCount: ${ratedRecipeIds.length}');
    return MealPlan.fromJson(data, ratedRecipeIds: ratedRecipeIds);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: meal_plan | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: meal_plan | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('activeMealPlanProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: meal_plan | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('activeMealPlanProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Generate meal plan — Edge Function
// ---------------------------------------------------------------------------

class MealPlanGeneratorNotifier extends AutoDisposeAsyncNotifier<MealPlan?> {
  final _logger = appLogger;

  @override
  Future<MealPlan?> build() async {
    _logger.provider('MealPlanGeneratorNotifier build()');
    ref.onDispose(() => _logger.provider('MealPlanGeneratorNotifier disposed'));
    return null;
  }

  Future<void> generate({int? days, int mealsPerDay = 3}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Default: today through Sunday of the current week (batch runs Sunday night).
    // weekday: 1=Mon … 7=Sun → days remaining inclusive = 8 - weekday.
    final effectiveDays = days ?? (8 - DateTime.now().weekday);

    _logger.userAction('Generate meal plan', metadata: {'days': effectiveDays, 'mealsPerDay': mealsPerDay});
    _logger.edge('generate-meal-plan', 'BEFORE | days: $effectiveDays | mealsPerDay: $mealsPerDay | userId: ${user.id}');
    _logger.provider('MealPlanGeneratorNotifier → loading (generate)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final res = await client.functions.invoke(
          'generate-meal-plan',
          body: {'days': effectiveDays, 'meals_per_day': mealsPerDay},
        );
        _logger.edge('generate-meal-plan', 'AFTER | success | responseType: ${res.data.runtimeType}');

        // Edge function returns Map { meal_plan_id, start_date, days, meals_per_day }.
        String? mealPlanId;
        final responseData = res.data;
        if (responseData is Map<String, dynamic>) {
          mealPlanId = responseData['meal_plan_id'] as String?;
        } else if (responseData is List && responseData.isNotEmpty) {
          // Legacy shape fallback
          final first = responseData.first;
          if (first is Map && first.containsKey('meal_plan_id')) {
            mealPlanId = first['meal_plan_id'] as String?;
          }
        }

        if (mealPlanId == null) {
          _logger.edge('generate-meal-plan', 'ERROR | missing meal_plan_id in response');
          throw StateError('generate-meal-plan: missing meal_plan_id in response');
        }

        _logger.provider('MealPlanGeneratorNotifier → data (generate success) | mealPlanId: $mealPlanId');
        return null;
      } catch (e, st) {
        _logger.edge('generate-meal-plan', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('MealPlanGeneratorNotifier → error | $e');
        rethrow;
      }
    });
    if (state is AsyncData) {
      _logger.provider('MealPlanGeneratorNotifier → invalidating activeMealPlanProvider');
      ref.invalidate(activeMealPlanProvider);
    }
  }
}

final mealPlanGeneratorProvider =
    AsyncNotifierProvider.autoDispose<MealPlanGeneratorNotifier, MealPlan?>(
        MealPlanGeneratorNotifier.new);

// ---------------------------------------------------------------------------
// Swap Meal Plan Entry
// ---------------------------------------------------------------------------

class MealPlanSwapNotifier extends AutoDisposeAsyncNotifier<void> {
  final _logger = appLogger;

  @override
  FutureOr<void> build() {
    _logger.provider('MealPlanSwapNotifier build()');
    ref.onDispose(() => _logger.provider('MealPlanSwapNotifier disposed'));
  }

  Future<void> swapMeal(String entryId, String newRecipeId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Keep provider alive for the full RPC round-trip even if the calling
    // widget pops and drops the only listener before the response arrives.
    final keepAlive = ref.keepAlive();

    _logger.userAction('Swap meal plan entry', metadata: {'entryId': entryId, 'newRecipeId': newRecipeId});
    _logger.db('BEFORE | rpc: swap_meal_plan_entry | userId: ${user.id} | entryId: $entryId | newRecipeId: $newRecipeId');
    _logger.provider('MealPlanSwapNotifier → loading (swap)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        try {
          await client.rpc(
            'swap_meal_plan_entry',
            params: {'p_entry_id': entryId, 'p_new_recipe_id': newRecipeId},
          );
          _logger.db('AFTER | rpc: swap_meal_plan_entry | success');
          _logger.provider('MealPlanSwapNotifier → data (swap success)');
        } on PostgrestException catch (e, st) {
          _logger.db('ERROR | rpc: swap_meal_plan_entry | code: ${e.code}', error: e, stackTrace: st);
          _logger.provider('MealPlanSwapNotifier → error | $e');
          rethrow;
        } catch (e, st) {
          _logger.db('ERROR | rpc: swap_meal_plan_entry | unexpected: $e', error: e, stackTrace: st);
          _logger.provider('MealPlanSwapNotifier → error | $e');
          rethrow;
        }
      });

      if (state is AsyncData) {
        _logger.provider('MealPlanSwapNotifier → invalidating activeMealPlanProvider and shoppingListProvider');
        ref.invalidate(activeMealPlanProvider);
        ref.invalidate(shoppingListProvider);
      }
    } finally {
      keepAlive.close();
    }
  }
}

final mealPlanSwapProvider =
    AsyncNotifierProvider.autoDispose<MealPlanSwapNotifier, void>(
        MealPlanSwapNotifier.new);

// ---------------------------------------------------------------------------
// Shopping list — kept as stub until ingredient data is seeded
// ---------------------------------------------------------------------------

class ShoppingListNotifier extends AutoDisposeAsyncNotifier<List<ShoppingItem>> {
  final _logger = appLogger;

  @override
  Future<List<ShoppingItem>> build() async {
    _logger.provider('ShoppingListNotifier build()');
    ref.onDispose(() => _logger.provider('ShoppingListNotifier disposed'));

    final plan = await ref.watch(activeMealPlanProvider.future);
    if (plan == null) {
      _logger.provider('ShoppingListNotifier EARLY RETURN | reason: no active meal plan');
      return [];
    }

    final client = ref.watch(supabaseClientProvider);
    _logger.db('BEFORE | table: shopping_list | op: SELECT | mealPlanId: ${plan.id}');
    
    try {
      final existingList = await client
          .from('shopping_list')
          .select('id, shopping_list_item(id, ingredient_id, quantity, unit, is_checked, ingredient(name, name_fr, category))')
          .eq('meal_plan_id', plan.id)
          .maybeSingle();

      List<dynamic> itemsData = [];

      if (existingList != null && existingList['shopping_list_item'] != null) {
         itemsData = existingList['shopping_list_item'] as List<dynamic>;
         _logger.db('AFTER | table: shopping_list | found existing list with ${itemsData.length} items');
      } else {
         _logger.db('Shopping list not found. Calling generate_shopping_list RPC');
         final rpcResult = await client.rpc('generate_shopping_list', params: {'p_meal_plan_id': plan.id}) as List<dynamic>;
         _logger.db('AFTER | rpc: generate_shopping_list | returned ${rpcResult.length} items');
         
         final newList = await client
          .from('shopping_list')
          .select('id, shopping_list_item(id, ingredient_id, quantity, unit, is_checked, ingredient(name, name_fr, category))')
          .eq('meal_plan_id', plan.id)
          .maybeSingle();
         
         if (newList != null && newList['shopping_list_item'] != null) {
           itemsData = newList['shopping_list_item'] as List<dynamic>;
         }
      }

      final items = itemsData.map((e) {
         final ingredient = e['ingredient'] as Map<String, dynamic>?;
         return ShoppingItem(
            id: e['id'] as String,
            ingredientId: e['ingredient_id'] as String?,
            name: (ingredient?['name_fr'] as String?) ?? (ingredient?['name'] as String?) ?? e['custom_name'] as String? ?? 'Unknown',
            quantity: (e['quantity'] as num).toDouble(),
            unit: (e['unit'] as String?) ?? '',
            category: ingredient?['category'] as String?,
            isChecked: (e['is_checked'] as bool?) ?? false,
         );
      }).toList();
      
      items.sort((a, b) {
        final catCmp = (a.category ?? '').compareTo(b.category ?? '');
        if (catCmp != 0) return catCmp;
        return a.name.compareTo(b.name);
      });

      _logger.provider('ShoppingListNotifier → data | items: ${items.length}');
      return items;
    } catch (e, st) {
      _logger.db('ERROR | shopping_list fetch | $e', error: e, stackTrace: st);
      _logger.provider('ShoppingListNotifier → error | $e');
      rethrow;
    }
  }

  Future<void> toggleItem(String id, bool isChecked) async {
    final client = ref.read(supabaseClientProvider);
    final plan = await ref.read(activeMealPlanProvider.future);
    if (plan == null) return;

    _logger.userAction('Toggle shopping item', metadata: {'id': id, 'isChecked': isChecked});
    
    final previousState = state.valueOrNull;
    if (previousState != null) {
      state = AsyncData([
        for (final item in previousState)
          if (item.id == id)
            item.copyWith(isChecked: isChecked)
          else
            item
      ]);
    }

    try {
      final listData = await client.from('shopping_list').select('id').eq('meal_plan_id', plan.id).maybeSingle();
      if (listData == null) return;
      
      await client
          .from('shopping_list_item')
          .update({'is_checked': isChecked})
          .eq('shopping_list_id', listData['id'])
          .eq('id', id)
          .select()
          .single();
          
      _logger.db('AFTER | table: shopping_list_item | op: UPDATE is_checked=$isChecked | id: $id');
    } catch (e, st) {
      _logger.db('ERROR | table: shopping_list_item | op: UPDATE | $e', error: e, stackTrace: st);
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }
}

final shoppingListProvider =
    AsyncNotifierProvider.autoDispose<ShoppingListNotifier, List<ShoppingItem>>(
        ShoppingListNotifier.new);

// ---------------------------------------------------------------------------
// Log meal consumption — Edge Function
// Logs all components of a meal entry in one call.
// Returns true on success so MealDetailPage can trigger the rating sheet.
// ---------------------------------------------------------------------------

class MealConsumptionNotifier extends AutoDisposeAsyncNotifier<String?> {
  final _logger = appLogger;

  @override
  FutureOr<String?> build() {
    _logger.provider('MealConsumptionNotifier build()');
    ref.onDispose(() => _logger.provider('MealConsumptionNotifier disposed'));
    return null;
  }

  Future<void> toggleConsumption(String mealPlanEntryId, {required bool isCurrentlyConsumed}) async {
    if (state.isLoading) return;
    final keepAlive = ref.keepAlive();

    _logger.userAction('Toggle meal consumption | isConsumed: $isCurrentlyConsumed',
        metadata: {'mealPlanEntryId': mealPlanEntryId});

    // Phase 1: optimistic write — flip before any async work
    ref.read(optimisticConsumptionProvider.notifier)
        .update((map) => {...map, mealPlanEntryId: !isCurrentlyConsumed});

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();

    try {
      if (isCurrentlyConsumed) {
        _logger.edge('unconsume-meal', 'BEFORE | mealPlanEntryId: $mealPlanEntryId');
        _logger.provider('MealConsumptionNotifier → loading (unconsume)');
        await client.functions.invoke(
          'unconsume-meal',
          body: {'meal_plan_entry_id': mealPlanEntryId},
        );
        _logger.edge('unconsume-meal', 'AFTER | success');
        _logger.provider('MealConsumptionNotifier → data (unconsume $mealPlanEntryId)');
        state = const AsyncData(null);
      } else {
        _logger.edge('log-meal-consumption', 'BEFORE | mealPlanEntryId: $mealPlanEntryId');
        _logger.provider('MealConsumptionNotifier → loading (consume)');
        try {
          await client.functions.invoke(
            'log-meal-consumption',
            body: {'meal_plan_entry_id': mealPlanEntryId},
          );
        } on FunctionException catch (e, st) {
          final details = e.details;
          if (details is Map && details['error'] == 'Meal already consumed') {
            _logger.edge('log-meal-consumption', 'WARNING | Already consumed. Treating as success.');
          } else {
            _logger.edge('log-meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
            rethrow;
          }
        }
        _logger.edge('log-meal-consumption', 'AFTER | success');
        _logger.provider('MealConsumptionNotifier → data (consume $mealPlanEntryId)');
        state = AsyncData(mealPlanEntryId);
      }
      // Success: remove override, DB refetch confirms
      ref.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map}..remove(mealPlanEntryId));
      ref.invalidate(activeMealPlanProvider);
    } catch (e, st) {
      // Revert optimistic override
      ref.read(optimisticConsumptionProvider.notifier)
          .update((map) => {...map, mealPlanEntryId: isCurrentlyConsumed});
      _logger.edge('meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
      _logger.provider('MealConsumptionNotifier → error | $e', error: e, stackTrace: st);
      state = AsyncError(e, st);
      rethrow;
    } finally {
      keepAlive.close();
    }
  }
}

final mealConsumptionProvider =
    AsyncNotifierProvider.autoDispose<MealConsumptionNotifier, String?>(
        MealConsumptionNotifier.new);

// Optimistic overlay — entryId → isConsumed — cleared after server confirms.
final optimisticConsumptionProvider =
    StateProvider<Map<String, bool>>((ref) => {});

// ---------------------------------------------------------------------------
// Cooking sessions — for the active meal plan
// ---------------------------------------------------------------------------

class CookingSessionsNotifier extends AutoDisposeAsyncNotifier<List<CookingSession>> {
  final _logger = appLogger;

  @override
  Future<List<CookingSession>> build() async {
    _logger.provider('CookingSessionsNotifier build()');
    ref.onDispose(() => _logger.provider('CookingSessionsNotifier disposed'));

    final plan = await ref.watch(activeMealPlanProvider.future);
    if (plan == null) {
      _logger.provider('CookingSessionsNotifier EARLY RETURN | reason: no active meal plan');
      return [];
    }

    _logger.provider('CookingSessionsNotifier | mealPlanId: ${plan.id}');
    _logger.db('BEFORE | table: cooking_session | op: SELECT with recipe join | mealPlanId: ${plan.id}');

    final client = ref.watch(supabaseClientProvider);
    try {
      final data = await client
          .from('cooking_session')
          .select('*, recipe(id, title, cover_image_url), cooking_session_ingredient(*)')
          .eq('meal_plan_id', plan.id)
          .order('planned_date');

      _logger.db('AFTER | table: cooking_session | rows: ${data.length} | mealPlanId: ${plan.id}');
      if (data.isEmpty) {
        _logger.rls('Zero rows | table: cooking_session | mealPlanId: ${plan.id} | possible RLS block');
      }
      _logger.provider('CookingSessionsNotifier → data | sessions: ${data.length}');
      return data.map((e) => CookingSession.fromJson(e)).toList();
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | table: cooking_session | mealPlanId: ${plan.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | table: cooking_session | code: ${e.code}', error: e, stackTrace: st);
      }
      _logger.provider('CookingSessionsNotifier → error | ${e.message}');
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | table: cooking_session | unexpected: $e', error: e, stackTrace: st);
      _logger.provider('CookingSessionsNotifier → error | $e');
      rethrow;
    }
  }


  Future<void> create({
    required String mealPlanId,
    required String recipeId,
    required DateTime plannedDate,
    required int totalPortions,
    String? notes,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Create cooking session', metadata: {'recipeId': recipeId, 'plannedDate': plannedDate.toIso8601String()});
    _logger.db('BEFORE | table: cooking_session | op: INSERT | userId: ${user.id} | recipeId: $recipeId');

    final client = ref.read(supabaseClientProvider);
    
    try {
      await client.from('cooking_session').insert({
        'user_id': user.id,
        'meal_plan_id': mealPlanId,
        'recipe_id': recipeId,
        'planned_date':
            '${plannedDate.year}-${plannedDate.month.toString().padLeft(2, '0')}-${plannedDate.day.toString().padLeft(2, '0')}',
        'total_portions': totalPortions,
        if (notes != null) 'notes': notes,
      });
      _logger.db('AFTER | table: cooking_session | op: INSERT | success');
      ref.invalidateSelf();
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | table: cooking_session | INSERT | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | table: cooking_session | INSERT | code: ${e.code}', error: e, stackTrace: st);
      }
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | table: cooking_session | INSERT | unexpected: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> markCooked(String sessionId, {required bool isCooked}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Mark cooking session cooked', metadata: {'sessionId': sessionId, 'isCooked': isCooked});
    
    // Optimistic UI update
    final previousState = state.valueOrNull;
    if (previousState != null) {
      state = AsyncData([
        for (final session in previousState)
          if (session.id == sessionId)
            session.copyWith(isCooked: isCooked)
          else
            session
      ]);
    }

    _logger.db('BEFORE | table: cooking_session | op: UPDATE is_cooked=$isCooked | sessionId: $sessionId');
    final client = ref.read(supabaseClientProvider);

    try {
      await client
          .from('cooking_session')
          .update({'is_cooked': isCooked})
          .eq('id', sessionId)
          .eq('user_id', user.id);
      _logger.db('AFTER | table: cooking_session | op: UPDATE is_cooked=$isCooked | success');
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | table: cooking_session | UPDATE | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | table: cooking_session | UPDATE | code: ${e.code}', error: e, stackTrace: st);
      }
      // Revert optimistic update
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | table: cooking_session | UPDATE | unexpected: $e', error: e, stackTrace: st);
      // Revert optimistic update
      if (previousState != null) {
        state = AsyncData(previousState);
      }
      rethrow;
    }
  }
}

final cookingSessionsProvider =
    AsyncNotifierProvider.autoDispose<CookingSessionsNotifier, List<CookingSession>>(
        CookingSessionsNotifier.new);

// ---------------------------------------------------------------------------
// Personal Meal Swap
// ---------------------------------------------------------------------------

@immutable
class PersonalMealAnalysisResult {
  final String mealName;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String confidence; // 'high' | 'medium' | 'low'

  const PersonalMealAnalysisResult({
    required this.mealName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
  });

  factory PersonalMealAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PersonalMealAnalysisResult(
      mealName: json['meal_name'] as String,
      calories: (json['calories'] as num).toDouble(),
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
      confidence: json['confidence'] as String,
    );
  }
}

class PersonalMealSwapNotifier extends AutoDisposeAsyncNotifier<PersonalMealAnalysisResult?> {
  final _logger = appLogger;

  @override
  FutureOr<PersonalMealAnalysisResult?> build() {
    _logger.provider('PersonalMealSwapNotifier build()');
    ref.onDispose(() => _logger.provider('PersonalMealSwapNotifier disposed'));
    return null;
  }

  Future<void> analyze({
    String? description,
    String? imageBase64,
    String? mimeType,
  }) async {
    _logger.userAction('Analyze personal meal', metadata: {
      'hasDescription': description != null,
      'hasImage': imageBase64 != null,
    });
    _logger.edge('analyze-meal-photo', 'BEFORE | hasDescription: ${description != null} | hasImage: ${imageBase64 != null} | mimeType: ${mimeType ?? "none"}');
    _logger.provider('PersonalMealSwapNotifier → loading (analyze)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final res = await client.functions.invoke(
          'analyze-meal-photo',
          body: {
            if (description != null) 'description': description,
            if (imageBase64 != null) 'image_base64': imageBase64,
            if (mimeType != null) 'image_mime_type': mimeType,
          },
        );
        _logger.edge('analyze-meal-photo', 'AFTER | success');
        final data = res.data as Map<String, dynamic>;
        _logger.provider('PersonalMealSwapNotifier → data (analyze success)');
        return PersonalMealAnalysisResult.fromJson(data);
      } catch (e, st) {
        _logger.edge('analyze-meal-photo', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('PersonalMealSwapNotifier → error | $e');
        rethrow;
      }
    });
  }

  Future<void> save({
    required String entryId,
    required String mealName,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Save personal meal swap', metadata: {'entryId': entryId, 'mealName': mealName});
    _logger.db('BEFORE | rpc: swap_meal_plan_entry_custom | entryId: $entryId');
    _logger.provider('PersonalMealSwapNotifier → loading (save)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await client.rpc(
          'swap_meal_plan_entry_custom',
          params: {
            'p_entry_id': entryId,
            'p_meal_name': mealName,
            'p_calories': calories,
            'p_protein_g': proteinG,
            'p_carbs_g': carbsG,
            'p_fat_g': fatG,
          },
        );
        _logger.db('AFTER | rpc: swap_meal_plan_entry_custom | success');
        _logger.provider('PersonalMealSwapNotifier → data (save success)');
        return null;
      } on PostgrestException catch (e, st) {
        _logger.db('ERROR | rpc: swap_meal_plan_entry_custom | code: ${e.code}', error: e, stackTrace: st);
        _logger.provider('PersonalMealSwapNotifier → error | $e');
        rethrow;
      } catch (e, st) {
        _logger.db('ERROR | rpc: swap_meal_plan_entry_custom | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('PersonalMealSwapNotifier → error | $e');
        rethrow;
      }
    });

    if (state is AsyncData) {
      _logger.provider('PersonalMealSwapNotifier → invalidating activeMealPlanProvider and shoppingListProvider');
      ref.invalidate(activeMealPlanProvider);
      ref.invalidate(shoppingListProvider);
    }
  }
}

final personalMealSwapProvider =
    AsyncNotifierProvider.autoDispose<PersonalMealSwapNotifier, PersonalMealAnalysisResult?>(
        PersonalMealSwapNotifier.new);

// ---------------------------------------------------------------------------
// Rate meal consumption — Edge Function
// Writes overall + optional sub-dimension ratings to meal_consumption rows.
// Only callable after the meal has been marked consumed.
// ---------------------------------------------------------------------------

class RatingNotifier extends AutoDisposeAsyncNotifier<void> {
  final _logger = appLogger;

  @override
  FutureOr<void> build() {
    _logger.provider('RatingNotifier build()');
    ref.onDispose(() => _logger.provider('RatingNotifier disposed'));
  }

  Future<void> submitRating(
    String mealPlanEntryId, {
    required int rating,
    int? ratingTaste,
    int? ratingEase,
    int? ratingSatiety,
    String? comment,
  }) async {
    _logger.userAction('Submitting rating (Taste: $ratingTaste, Ease: $ratingEase, Satiety: $ratingSatiety, Comment: ${comment != null})', metadata: {
      'mealPlanEntryId': mealPlanEntryId,
      'rating': rating,
      'ratingTaste': ratingTaste,
      'ratingEase': ratingEase,
      'ratingSatiety': ratingSatiety,
      'hasComment': comment != null,
    });
    _logger.edge('rate-meal-consumption', 'BEFORE | mealPlanEntryId: $mealPlanEntryId | rating: $rating');
    _logger.provider('RatingNotifier → loading');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'rate-meal-consumption',
          body: {
            'meal_plan_entry_id': mealPlanEntryId,
            'rating': rating,
            if (ratingTaste != null) 'rating_taste': ratingTaste,
            if (ratingEase != null) 'rating_ease': ratingEase,
            if (ratingSatiety != null) 'rating_satiety': ratingSatiety,
            if (comment != null) 'comment': comment,
          },
        );
        _logger.edge('rate-meal-consumption', 'AFTER | success');
        _logger.provider('RatingNotifier → data (submitRating success)');

        // Invalidate recipes
        ref.invalidate(feedProvider);

      } catch (e, st) {
        _logger.edge('rate-meal-consumption', 'ERROR | $e', error: e, stackTrace: st);
        _logger.provider('RatingNotifier → error | $e');
        rethrow;
      }
    });

  }
}

final ratingProvider =
    AsyncNotifierProvider.autoDispose<RatingNotifier, void>(RatingNotifier.new);

// ---------------------------------------------------------------------------
// Add snack entry — inserts a new snack meal_plan_entry for a specific date
// ---------------------------------------------------------------------------

class SnackEntryNotifier extends AsyncNotifier<void> {
  final _logger = appLogger;

  @override
  FutureOr<void> build() {
    _logger.provider('SnackEntryNotifier build()');
    ref.onDispose(() => _logger.provider('SnackEntryNotifier disposed'));
  }

  Future<void> addSnack({
    required String mealPlanId,
    required String recipeId,
    required DateTime scheduledDate,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Add snack entry', metadata: {'mealPlanId': mealPlanId, 'recipeId': recipeId});
    _logger.provider('SnackEntryNotifier → loading (addSnack)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dateStr =
          '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';
      try {
        _logger.db('BEFORE | table: meal_plan_entry | op: INSERT | meal_type: snack | mealPlanId: $mealPlanId | date: $dateStr');
        final entryData = await client
            .from('meal_plan_entry')
            .insert({
              'meal_plan_id': mealPlanId,
              'meal_type': 'snack',
              'scheduled_date': dateStr,
              'servings': 1.0,
              'is_consumed': false,
              'is_custom_meal': false,
            })
            .select('id')
            .single();
        final entryId = entryData['id'] as String;
        _logger.db('AFTER | table: meal_plan_entry | op: INSERT | entryId: $entryId');

        _logger.db('BEFORE | table: meal_plan_entry_component | op: INSERT | role: base | recipeId: $recipeId');
        await client.from('meal_plan_entry_component').insert({
          'meal_plan_entry_id': entryId,
          'recipe_id': recipeId,
          'role': 'base',
          'consumption_weight': 1.0,
        });
        _logger.db('AFTER | table: meal_plan_entry_component | op: INSERT | success');
        _logger.provider('SnackEntryNotifier → data (addSnack success)');
      } on PostgrestException catch (e, st) {
        if (e.code == '42501') {
          _logger.rls('Permission denied | table: meal_plan_entry | INSERT | userId: ${user.id}', error: e, stackTrace: st);
        } else {
          _logger.db('ERROR | table: meal_plan_entry | INSERT | code: ${e.code}', error: e, stackTrace: st);
        }
        _logger.provider('SnackEntryNotifier → error | ${e.message}');
        rethrow;
      } catch (e, st) {
        _logger.db('ERROR | meal_plan_entry INSERT | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('SnackEntryNotifier → error | $e');
        rethrow;
      }
    });

    if (state is AsyncData) {
      _logger.provider('SnackEntryNotifier → invalidating activeMealPlanProvider');
      ref.invalidate(activeMealPlanProvider);
    }
  }

  Future<void> addCustomSnack({
    required String mealPlanId,
    required DateTime scheduledDate,
    required String name,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Add custom snack entry',
        metadata: {'mealPlanId': mealPlanId, 'name': name});
    _logger.provider('SnackEntryNotifier → loading (addCustomSnack)');

    final client = ref.read(supabaseClientProvider);
    final dateStr =
        '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        _logger.db('BEFORE | table: meal_plan_entry | op: INSERT | is_custom_meal: true | date: $dateStr');
        await client.from('meal_plan_entry').insert({
          'meal_plan_id': mealPlanId,
          'meal_type': 'snack',
          'scheduled_date': dateStr,
          'is_custom_meal': true,
          'custom_meal_name': name,
          'custom_calories': calories,
          'custom_protein_g': proteinG,
          'custom_carbs_g': carbsG,
          'custom_fat_g': fatG,
          'servings': 1.0,
          'is_consumed': false,
        });
        _logger.db('AFTER | table: meal_plan_entry | op: INSERT | custom snack success');
        _logger.provider('SnackEntryNotifier → data (addCustomSnack success)');
      } on PostgrestException catch (e, st) {
        if (e.code == '42501') {
          _logger.rls('Permission denied | table: meal_plan_entry | INSERT | userId: ${user.id}',
              error: e, stackTrace: st);
        } else {
          _logger.db('ERROR | table: meal_plan_entry | INSERT custom snack | code: ${e.code}',
              error: e, stackTrace: st);
        }
        _logger.provider('SnackEntryNotifier → error | ${e.message}');
        rethrow;
      } catch (e, st) {
        _logger.db('ERROR | meal_plan_entry INSERT custom snack | unexpected: $e',
            error: e, stackTrace: st);
        _logger.provider('SnackEntryNotifier → error | $e');
        rethrow;
      }
    });

    if (state is AsyncData) {
      _logger.provider('SnackEntryNotifier → invalidating activeMealPlanProvider');
      ref.invalidate(activeMealPlanProvider);
    }
  }
}

final snackEntryProvider =
    AsyncNotifierProvider<SnackEntryNotifier, void>(
        SnackEntryNotifier.new);
