import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../shared/models/ingredient_detail.dart';
import '../shared/models/recipe_usage.dart';
import '../providers/user_profile_provider.dart';

final ingredientDetailProvider =
    FutureProvider.family<IngredientDetail?, String>((ref, ingredientId) async {
  final logger = appLogger;
  logger.provider('ingredientDetailProvider build() | ingredientId: $ingredientId');
  ref.onDispose(() => logger.provider('ingredientDetailProvider disposed | ingredientId: $ingredientId'));

  final profile = await ref.watch(userProfileProvider.future);
  final countryCode = profile?.countryCode ?? 'FR';

  logger.db(
      'BEFORE | table: ingredient | op: SELECT | ingredientId: $ingredientId | country: $countryCode');

  try {
    final data = await Supabase.instance.client
        .from('ingredient')
        .select(
            'id, name_fr, name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, description_fr, description_en, image_url, tags, ingredient_market_price(price_per_100g, currency, country_code)')
        .eq('id', ingredientId)
        .eq('ingredient_market_price.country_code', countryCode)
        .maybeSingle();

    if (data == null) {
      logger.db('AFTER | table: ingredient | rows: 0');
      logger.rls(
          'Zero rows | table: ingredient | ingredientId: $ingredientId | possible RLS block');
      return null;
    }

    logger.db('AFTER | table: ingredient | rows: 1');
    return IngredientDetail.fromJson(data);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: ingredient | ingredientId: $ingredientId',
          error: e,
          stackTrace: st);
      return null;
    } else {
      logger.db(
          'ERROR | table: ingredient | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
      rethrow;
    }
  } catch (e, st) {
    logger.db('ERROR | table: ingredient | unexpected | $e', error: e, stackTrace: st);
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Search / autocomplete ingredients
// ---------------------------------------------------------------------------

final searchIngredientsProvider =
    FutureProvider.family<List<IngredientDetail>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  final client = Supabase.instance.client;
  appLogger.db('BEFORE | table: ingredient | searchIngredients | query: $query');
  
  try {
    final data = await client
        .from('ingredient')
        .select('id, name_fr, name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, description_fr, description_en, image_url, tags')
        .or('name_fr.ilike.%$query%,name.ilike.%$query%')
        .limit(20) as List<dynamic>;

    appLogger.db('AFTER | table: ingredient | searchIngredients | rows: ${data.length}');
    return data.map((e) => IngredientDetail.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e, st) {
    appLogger.db('ERROR | searchIngredients', error: e, stackTrace: st);
    return [];
  }
});

// ---------------------------------------------------------------------------
// Recipes in the current plan that use a given ingredient
// ---------------------------------------------------------------------------

final ingredientRecipesInPlanProvider =
    FutureProvider.family<List<RecipeUsage>, (String mealPlanId, String ingredientId)>(
        (ref, args) async {
  final (mealPlanId, ingredientId) = args;
  final logger = appLogger;
  logger.provider(
      'ingredientRecipesInPlanProvider build() | mealPlanId: $mealPlanId | ingredientId: $ingredientId');
  ref.onDispose(() => logger.provider(
      'ingredientRecipesInPlanProvider disposed | mealPlanId: $mealPlanId | ingredientId: $ingredientId'));

  logger.db(
      'BEFORE rpc | fn: get_ingredient_recipes_in_plan | mealPlanId: $mealPlanId | ingredientId: $ingredientId');

  try {
    final data = await Supabase.instance.client.rpc(
      'get_ingredient_recipes_in_plan',
      params: {
        'p_meal_plan_id': mealPlanId,
        'p_ingredient_id': ingredientId,
      },
    ) as List<dynamic>;

    logger.db('AFTER rpc | fn: get_ingredient_recipes_in_plan | rows: ${data.length}');
    return data.map((e) => RecipeUsage.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e, st) {
    logger.db('ERROR | rpc: get_ingredient_recipes_in_plan | $e', error: e, stackTrace: st);
    return <RecipeUsage>[];
  }
});

