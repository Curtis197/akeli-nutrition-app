import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/locale_provider.dart';
import '../core/supabase_client.dart';
import '../core/logger.dart';
import '../shared/models/recipe.dart';
import 'auth_provider.dart';
import 'mode_provider.dart';
import 'user_profile_provider.dart';

// ---------------------------------------------------------------------------
// Translation helper — applies recipe_translation / recipe_step_translation /
// recipe_ingredient_translation for a given locale (no-op for 'fr').
// ---------------------------------------------------------------------------

Future<List<Recipe>> applyTitleTranslations(
  SupabaseClient client,
  List<Recipe> recipes,
  String locale,
) async {
  if (locale == 'fr' || recipes.isEmpty) return recipes;

  final ids = recipes.map((r) => r.id).toList();
  appLogger.db('BEFORE | table: recipe_translation | op: SELECT | locale: $locale | ids: ${ids.length}');
  try {
    final data = await client
        .from('recipe_translation')
        .select('recipe_id, title')
        .eq('locale', locale)
        .inFilter('recipe_id', ids) as List<dynamic>;
    appLogger.db('AFTER | table: recipe_translation | rows: ${data.length}');

    final transMap = <String, String>{
      for (final t in data.cast<Map<String, dynamic>>())
        t['recipe_id'] as String: t['title'] as String,
    };
    return recipes.map((r) {
      final t = transMap[r.id];
      return t != null ? r.copyWith(title: t) : r;
    }).toList();
  } catch (e, st) {
    appLogger.db('ERROR | table: recipe_translation | $e', error: e, stackTrace: st);
    return recipes;
  }
}

Future<Recipe> _applyDetailTranslations(
  SupabaseClient client,
  Recipe recipe,
  String locale,
) async {
  if (locale == 'fr') return recipe;

  final isUsLocale = locale == 'en-US';
  final textLocale = locale;
  final ingTransLocale = locale;

  // 1. Recipe title + description
  appLogger.db('BEFORE | table: recipe_translation | op: SELECT | locale: $textLocale | recipeId: ${recipe.id}');
  Map<String, dynamic>? rtRow;
  try {
    rtRow = await client
        .from('recipe_translation')
        .select('title, description')
        .eq('recipe_id', recipe.id)
        .eq('locale', textLocale)
        .maybeSingle();
    appLogger.db('AFTER | table: recipe_translation | rows: ${rtRow == null ? 0 : 1}');
  } catch (e, st) {
    appLogger.db('ERROR | table: recipe_translation | $e', error: e, stackTrace: st);
  }

  // 2. Step translations
  final stepIds = recipe.steps.where((s) => s.id.isNotEmpty).map((s) => s.id).toList();
  Map<String, Map<String, dynamic>> stepTrans = {};
  if (stepIds.isNotEmpty) {
    appLogger.db('BEFORE | table: recipe_step_translation | op: SELECT | locale: $textLocale | steps: ${stepIds.length}');
    try {
      final stData = await client
          .from('recipe_step_translation')
          .select('step_id, content, title')
          .eq('locale', textLocale)
          .inFilter('step_id', stepIds) as List<dynamic>;
      appLogger.db('AFTER | table: recipe_step_translation | rows: ${stData.length}');
      stepTrans = {
        for (final s in stData.cast<Map<String, dynamic>>())
          s['step_id'] as String: s,
      };
    } catch (e, st) {
      appLogger.db('ERROR | table: recipe_step_translation | $e', error: e, stackTrace: st);
    }
  }

  // 3. Ingredient section-header & quantity/unit translations
  final ingIds = recipe.ingredients
      .where((i) => (isUsLocale || i.isSectionHeader) && i.id.isNotEmpty)
      .map((i) => i.id)
      .toList();
  Map<String, Map<String, dynamic>> ingTrans = {};
  if (ingIds.isNotEmpty) {
    appLogger.db('BEFORE | table: recipe_ingredient_translation | op: SELECT | locale: $ingTransLocale | rows: ${ingIds.length}');
    try {
      final itData = await client
          .from('recipe_ingredient_translation')
          .select('recipe_ingredient_id, title, quantity, unit')
          .eq('locale', ingTransLocale)
          .inFilter('recipe_ingredient_id', ingIds) as List<dynamic>;
      appLogger.db('AFTER | table: recipe_ingredient_translation | rows: ${itData.length}');
      ingTrans = {
        for (final i in itData.cast<Map<String, dynamic>>())
          i['recipe_ingredient_id'] as String: i,
      };
    } catch (e, st) {
      appLogger.db('ERROR | table: recipe_ingredient_translation | $e', error: e, stackTrace: st);
    }
  }

  // Apply
  final translatedSteps = recipe.steps.map((step) {
    final t = stepTrans[step.id];
    if (t == null) return step;
    return step.copyWith(
      instruction: t['content'] as String? ?? step.instruction,
      sectionTitle: t['title'] as String? ?? step.sectionTitle,
    );
  }).toList();

  final translatedIngredients = recipe.ingredients.map((ing) {
    final t = ingTrans[ing.id];
    RecipeIngredient result = ing;
    if (t != null) {
      if (ing.isSectionHeader) {
        result = ing.copyWith(sectionTitle: t['title'] as String? ?? ing.sectionTitle);
      } else {
        final double? qty = t['quantity'] != null ? (t['quantity'] as num).toDouble() : null;
        final String? unitVal = t['unit'] as String?;
        result = RecipeIngredient(
          id: ing.id,
          ingredientId: ing.ingredientId,
          name: ing.name,
          nameEn: ing.nameEn,
          quantity: qty ?? ing.quantity,
          unit: unitVal ?? ing.unit,
          isOptional: ing.isOptional,
          isSectionHeader: ing.isSectionHeader,
          sectionTitle: ing.sectionTitle,
        );
      }
    }
    // Apply ingredient name translation for regular (non-header) rows
    if (!ing.isSectionHeader && ing.nameEn != null) {
      result = result.copyWith(name: ing.nameEn);
    }
    return result;
  }).toList();

  return recipe.copyWith(
    title: rtRow?['title'] as String? ?? recipe.title,
    description: rtRow?['description'] as String? ?? recipe.description,
    steps: translatedSteps,
    ingredients: translatedIngredients,
  );
}

// ---------------------------------------------------------------------------
// Feed
// ---------------------------------------------------------------------------

class FeedParams {
  final int limit;
  final List<String> excludeIds;
  final String? regionId;
  final String? difficulty;
  final int? maxTimeMin;
  final int? minCal;
  final int? maxCal;
  final String? orderBy; // 'rating' | 'likes' | 'created_at' | null = personalized
  final String? mealType; // filter by meal_types array membership e.g. 'snack'
  final String? mode; // 'nutrition' | 'beauty'

  const FeedParams({
    this.limit = 20,
    this.excludeIds = const [],
    this.regionId,
    this.difficulty,
    this.maxTimeMin,
    this.minCal,
    this.maxCal,
    this.orderBy,
    this.mealType,
    this.mode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedParams &&
          limit == other.limit &&
          excludeIds.length == other.excludeIds.length &&
          regionId == other.regionId &&
          difficulty == other.difficulty &&
          maxTimeMin == other.maxTimeMin &&
          minCal == other.minCal &&
          maxCal == other.maxCal &&
          orderBy == other.orderBy &&
          mealType == other.mealType &&
          mode == other.mode;

  @override
  int get hashCode =>
      Object.hash(limit, excludeIds.length, regionId, difficulty, maxTimeMin, minCal, maxCal, orderBy, mealType, mode);
}

final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  final locale = ref.watch(localeProvider).languageCode;
  final appMode = ref.watch(currentModeProvider);
  final activeMode = params.mode ?? (appMode == AppMode.beauty ? 'beauty' : 'nutrition');

  appLogger.provider(
      'feedProvider build() | userId: ${user?.id ?? "null"} | mode: $activeMode | locale: $locale | region: ${params.regionId} | difficulty: ${params.difficulty} | orderBy: ${params.orderBy} | mealType: ${params.mealType}');
  ref.onDispose(() => appLogger.provider('feedProvider disposed'));

  if (user == null) {
    appLogger.provider('feedProvider EARLY RETURN | reason: no authenticated user');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);

  final rpcParams = {
    'p_user_id': user.id,
    'p_limit': params.limit,
    'p_exclude': params.excludeIds,
    if (params.regionId != null) 'p_region_id': params.regionId,
    if (params.difficulty != null) 'p_difficulty': params.difficulty,
    if (params.maxTimeMin != null) 'p_max_time_min': params.maxTimeMin,
    if (params.minCal != null) 'p_min_cal': params.minCal,
    if (params.maxCal != null) 'p_max_cal': params.maxCal,
    if (params.orderBy != null) 'p_order_by': params.orderBy,
    if (params.mealType != null) 'p_meal_type': params.mealType,
    'p_mode': activeMode,
  };

  appLogger.db(
      'BEFORE rpc | fn: generate_feed_personalized | userId: ${user.id} | params: $rpcParams');

  try {
    final rpcData =
        await client.rpc('generate_feed_personalized', params: rpcParams)
            as List<dynamic>;
    appLogger.db(
        'AFTER rpc | fn: generate_feed_personalized | rows: ${rpcData.length}');

    if (rpcData.isEmpty) {
      appLogger.rls(
          'Zero rows | rpc: generate_feed_personalized | userId: ${user.id} | possible RLS or empty feed');
      return [];
    }

    final recipeIds = rpcData
        .cast<Map<String, dynamic>>()
        .map((e) => e['recipe_id'] as String)
        .toList();

    final profile = await ref.watch(userProfileProvider.future);
    final countryCode = profile?.countryCode ?? 'FR';

    appLogger.db(
        'BEFORE | table: recipe | op: SELECT in | ids: ${recipeIds.length} | country: $countryCode');
    final recipeData = await client
        .from('recipe')
        .select(
            '*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), recipe_market_cost(cost_per_100g, country_code), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .inFilter('id', recipeIds)
        .eq('recipe_market_cost.country_code', countryCode) as List<dynamic>;
    appLogger.db('AFTER | table: recipe | rows: ${recipeData.length}');

    if (recipeData.isEmpty) {
      appLogger.rls(
          'Zero rows | table: recipe | possible RLS block | userId: ${user.id}');
    }

    final recipeMap = {
      for (final r in recipeData.cast<Map<String, dynamic>>())
        r['id'] as String: r
    };
    final recipes = recipeIds
        .where(recipeMap.containsKey)
        .map((id) => Recipe.fromJson(recipeMap[id]!))
        .toList();

    final translated = await applyTitleTranslations(client, recipes, locale);
    appLogger.provider(
        'feedProvider → data | recipes: ${translated.length} | locale: $locale');
    return translated;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls(
          'Permission denied | rpc: generate_feed_personalized | userId: ${user.id}',
          error: e,
          stackTrace: st);
    } else {
      appLogger.db(
          'ERROR rpc | fn: generate_feed_personalized | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
    }
    appLogger.provider('feedProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR rpc | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('feedProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Recipe detail
// ---------------------------------------------------------------------------

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe?, String>((ref, id) async {
  final locale = ref.watch(localeProvider).stringValue;
  appLogger.provider('recipeDetailProvider build() | recipeId: $id | locale: $locale');
  ref.onDispose(() => appLogger.provider('recipeDetailProvider disposed | recipeId: $id'));

  final profile = await ref.watch(userProfileProvider.future);
  final countryCode = profile?.countryCode ?? 'FR';

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: recipe | op: SELECT | recipeId: $id | country: $countryCode');

  try {
    final data = await client
        .from('recipe')
        .select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), recipe_market_cost(cost_per_100g, country_code), ingredients:recipe_ingredient(id, ingredient_id, ingredient:ingredient_id(name_fr, name_en, name), quantity, unit, is_optional, sort_order, is_section_header, title), steps:recipe_step(id, step_number, content, image_url, timer_seconds, sort_order, ingredient_ids, is_section_header, title), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .eq('id', id)
        .eq('recipe_market_cost.country_code', countryCode)
        .maybeSingle();

    if (data == null) {
      appLogger.db('AFTER | table: recipe | rows: 0 | recipeId: $id | not found');
      appLogger.rls('Zero rows | table: recipe | recipeId: $id | possible RLS block');
      appLogger.provider('recipeDetailProvider → data (null)');
      return null;
    }

    appLogger.db('AFTER | table: recipe | rows: 1 | recipeId: $id');
    var recipe = Recipe.fromJson(data);
    recipe = await _applyDetailTranslations(client, recipe, locale);
    appLogger.provider('recipeDetailProvider → data | title: ${recipe.title} | locale: $locale');
    return recipe;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: recipe | recipeId: $id', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: recipe | recipeId: $id | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('recipeDetailProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: recipe | recipeId: $id | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('recipeDetailProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

class SearchParams {
  final String query;
  final String? regionId;
  final String? difficulty;
  final int? maxTimeMin;
  final int? minCal;
  final int? maxCal;
  final String orderBy;
  final int limit;
  final int offset;
  final String? mealType;

  const SearchParams({
    required this.query,
    this.regionId,
    this.difficulty,
    this.maxTimeMin,
    this.minCal,
    this.maxCal,
    this.orderBy = 'relevance',
    this.limit = 20,
    this.offset = 0,
    this.mealType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          query == other.query &&
          regionId == other.regionId &&
          difficulty == other.difficulty &&
          maxTimeMin == other.maxTimeMin &&
          minCal == other.minCal &&
          maxCal == other.maxCal &&
          orderBy == other.orderBy &&
          limit == other.limit &&
          offset == other.offset &&
          mealType == other.mealType;

  @override
  int get hashCode => Object.hash(query, regionId, difficulty, maxTimeMin, minCal, maxCal, orderBy, limit, offset, mealType);
}

final searchRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, SearchParams>(
        (ref, params) async {
  final locale = ref.watch(localeProvider).languageCode;
  appLogger.provider(
      'searchRecipesProvider build() | query: "${params.query}" | locale: $locale | region: ${params.regionId} | difficulty: ${params.difficulty} | maxTime: ${params.maxTimeMin} | orderBy: ${params.orderBy}');
  ref.onDispose(() => appLogger.provider('searchRecipesProvider disposed | query: "${params.query}"'));

  if (params.query.length < 2) {
    appLogger.provider(
        'searchRecipesProvider EARLY RETURN | reason: query too short (${params.query.length} chars)');
    return [];
  }

  final profile = await ref.watch(userProfileProvider.future);
  final countryCode = profile?.countryCode ?? 'FR';

  final client = ref.watch(supabaseClientProvider);
  appLogger.db(
      'BEFORE | table: recipe | op: SELECT ilike+filters | query: "${params.query}" | limit: ${params.limit} | country: $countryCode');

  try {
    var query = client
        .from('recipe')
        .select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), recipe_market_cost(cost_per_100g, country_code), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .ilike('title', '%${params.query}%')
        .eq('recipe_market_cost.country_code', countryCode);

    if (params.regionId != null) query = query.eq('region_id', params.regionId!);
    if (params.difficulty != null) query = query.eq('difficulty', params.difficulty!);
    if (params.maxTimeMin != null) query = query.lte('total_time_min', params.maxTimeMin!);
    if (params.minCal != null) query = query.gte('recipe_macro.calories_per_100g', params.minCal!);
    if (params.maxCal != null) query = query.lte('recipe_macro.calories_per_100g', params.maxCal!);
    if (params.mealType != null) query = query.contains('meal_types', [params.mealType!]);

    final orderColumn = switch (params.orderBy) {
      'rating' => 'average_rating',
      'likes' => 'like_count',
      'created_at' => 'created_at',
      _ => null,
    };

    final limitedQuery = orderColumn != null
        ? query.order(orderColumn, ascending: false).limit(params.limit)
        : query.limit(params.limit);

    final data = await limitedQuery as List<dynamic>;

    appLogger.db('AFTER | table: recipe | rows: ${data.length} | query: "${params.query}"');

    if (data.isEmpty) {
      appLogger.rls(
          'Zero rows | table: recipe | search query: "${params.query}" | possible RLS block or no matches');
      appLogger.provider(
          'searchRecipesProvider → data (empty) | no results for "${params.query}"');
    }

    final recipes = data.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
    final translated = await applyTitleTranslations(client, recipes, locale);
    appLogger.provider('searchRecipesProvider → data | recipes: ${translated.length} | locale: $locale');
    return translated;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: recipe | search query', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: recipe | search | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('searchRecipesProvider → error | ${e.message}');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Chat recipe picker — fetches published recipes for sharing in chat.
// Empty/short query returns popular recipes; longer query searches by title.
// ---------------------------------------------------------------------------

final chatRecipePickerProvider =
    FutureProvider.autoDispose.family<List<Recipe>, String>((ref, query) async {
  appLogger.provider('chatRecipePickerProvider build() | query: "$query"');
  ref.onDispose(() => appLogger.provider('chatRecipePickerProvider disposed'));

  final profile = await ref.watch(userProfileProvider.future);
  final countryCode = profile?.countryCode ?? 'FR';

  final client = ref.watch(supabaseClientProvider);
  const sel = 'id, creator_id, title, cover_image_url, recipe_macro(calories, protein_g, carbs_g, fat_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), recipe_market_cost(cost_per_100g, country_code), like_count, average_rating, is_published, created_at';

  appLogger.db('BEFORE | table: recipe | chatRecipePicker | query: "$query" | country: $countryCode');
  try {
    final data = query.length >= 2
        ? await client
            .from('recipe')
            .select(sel)
            .eq('is_published', true)
            .eq('recipe_market_cost.country_code', countryCode)
            .ilike('title', '%$query%')
            .limit(30) as List<dynamic>
        : await client
            .from('recipe')
            .select(sel)
            .eq('is_published', true)
            .eq('recipe_market_cost.country_code', countryCode)
            .order('like_count', ascending: false)
            .limit(30) as List<dynamic>;

    appLogger.db('AFTER | table: recipe | chatRecipePicker | rows: ${data.length}');
    return data.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
  } on PostgrestException catch (e, st) {
    appLogger.db('ERROR | table: recipe | chatRecipePicker | code: ${e.code}', error: e, stackTrace: st);
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// User recipes (profile page)
// ---------------------------------------------------------------------------

final userRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, String>((ref, userId) async {
  appLogger.provider('userRecipesProvider build() | userId: $userId');
  ref.onDispose(() => appLogger.provider('userRecipesProvider disposed | userId: $userId'));

  if (userId.isEmpty) {
    appLogger.provider('userRecipesProvider EARLY RETURN | reason: empty userId');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);

  // recipe.creator_id references creator.id, not the auth user UUID.
  appLogger.db('BEFORE | table: creator | op: SELECT | user_id: $userId');
  final creatorRow = await client
      .from('creator')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

  if (creatorRow == null) {
    appLogger.rls('Zero rows | table: creator | user_id: $userId | not a creator or RLS block');
    appLogger.provider('userRecipesProvider → data (empty) | no creator profile');
    return [];
  }
  final creatorId = creatorRow['id'] as String;
  appLogger.db('AFTER | table: creator | creatorId: $creatorId');

  final profile = await ref.watch(userProfileProvider.future);
  final countryCode = profile?.countryCode ?? 'FR';

  appLogger.db('BEFORE | table: recipe | op: SELECT | creator_id: $creatorId | country: $countryCode');

  try {
    final data = await client
        .from('recipe')
        .select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), recipe_market_cost(cost_per_100g, country_code), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .eq('creator_id', creatorId)
        .eq('recipe_market_cost.country_code', countryCode)
        .order('created_at', ascending: false)
        .limit(20) as List<dynamic>;

    appLogger.db('AFTER | table: recipe | rows: ${data.length} | creator_id: $creatorId');

    if (data.isEmpty) {
      appLogger.rls('Zero rows | table: recipe | creator_id: $creatorId | possible RLS block or no recipes');
    }

    final recipes = data.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
    appLogger.provider('userRecipesProvider → data | recipes: ${recipes.length}');
    return recipes;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: recipe | creator_id: $userId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: recipe | creator_id: $userId | code: ${e.code} | ${e.message}',
          error: e, stackTrace: st);
    }
    appLogger.provider('userRecipesProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: recipe | creator_id: $userId | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('userRecipesProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Toggle like — Edge Function
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Save (bookmark) — any user, writes to recipe_save
// ---------------------------------------------------------------------------

class RecipeSaveNotifier extends AutoDisposeAsyncNotifier<bool> {
  final _logger = appLogger;

  @override
  Future<bool> build() async {
    _logger.provider('RecipeSaveNotifier build()');
    ref.onDispose(() => _logger.provider('RecipeSaveNotifier disposed'));
    return false;
  }

  Future<bool> toggle(String recipeId, bool currentlySaved) async {
    _logger.userAction('Recipe save toggle', metadata: {'recipeId': recipeId, 'currentlySaved': currentlySaved});
    _logger.provider('RecipeSaveNotifier → loading (toggle)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    final newSaved = !currentlySaved;

    _logger.edge('toggle-recipe-save', 'BEFORE | recipeId: $recipeId | newSaved: $newSaved');

    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'toggle-recipe-save',
          body: {'recipe_id': recipeId},
        );
        _logger.edge('toggle-recipe-save', 'AFTER | success | recipeId: $recipeId | saved: $newSaved');
        _logger.provider('RecipeSaveNotifier → data | saved: $newSaved');

        // Invalidate recipes
        ref.invalidate(recipeDetailProvider(recipeId));
        ref.invalidate(feedProvider);

        return newSaved;
      } catch (e, st) {

        _logger.edge('toggle-recipe-save', 'ERROR | recipeId: $recipeId | $e', error: e, stackTrace: st);
        _logger.provider('RecipeSaveNotifier → error | $e');
        rethrow;
      }
    });
    return state.valueOrNull ?? currentlySaved;
  }
}

final recipeSaveProvider =
    AsyncNotifierProvider.autoDispose<RecipeSaveNotifier, bool>(
        RecipeSaveNotifier.new);

// ---------------------------------------------------------------------------
// Like — only users who have the recipe in their meal plan, writes to recipe_like
// ---------------------------------------------------------------------------

class RecipeLikeNotifier extends AutoDisposeAsyncNotifier<bool> {
  final _logger = appLogger;

  @override
  Future<bool> build() async {
    _logger.provider('RecipeLikeNotifier build()');
    ref.onDispose(() => _logger.provider('RecipeLikeNotifier disposed'));
    return false;
  }

  Future<bool> toggle(String recipeId, bool currentlyLiked) async {
    _logger.userAction('Recipe like toggle', metadata: {'recipeId': recipeId, 'currentlyLiked': currentlyLiked});
    _logger.provider('RecipeLikeNotifier → loading (toggle)');
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    final newLiked = !currentlyLiked;

    _logger.edge('toggle-recipe-like', 'BEFORE | recipeId: $recipeId | newLiked: $newLiked');

    state = await AsyncValue.guard(() async {
      try {
        await client.functions.invoke(
          'toggle-recipe-like',
          body: {'recipe_id': recipeId},
        );
        _logger.edge('toggle-recipe-like', 'AFTER | success | recipeId: $recipeId | liked: $newLiked');
        _logger.provider('RecipeLikeNotifier → data | liked: $newLiked');

        // Invalidate recipes
        ref.invalidate(recipeDetailProvider(recipeId));
        ref.invalidate(feedProvider);

        return newLiked;
      } catch (e, st) {
        _logger.edge('toggle-recipe-like', 'ERROR | recipeId: $recipeId | $e', error: e, stackTrace: st);
        _logger.provider('RecipeLikeNotifier → error | $e');
        rethrow;
      }
    });
    return state.valueOrNull ?? currentlyLiked;
  }
}

final recipeLikeProvider =
    AsyncNotifierProvider.autoDispose<RecipeLikeNotifier, bool>(
        RecipeLikeNotifier.new);

// ---------------------------------------------------------------------------
// Search recipes by ingredient IDs
// ---------------------------------------------------------------------------

final getRecipesByIngredientsProvider =
    FutureProvider.family<List<Recipe>, List<String>>((ref, ingredientIds) async {
  if (ingredientIds.isEmpty) return [];

  final client = ref.watch(supabaseClientProvider);
  final locale = ref.watch(localeProvider).languageCode;
  final profile = await ref.watch(userProfileProvider.future);
  final countryCode = profile?.countryCode ?? 'FR';

  appLogger.db('BEFORE | rpc: get_recipes_by_ingredients | ids: ${ingredientIds.length}');
  
  try {
    final rpcResult = await client.rpc('get_recipes_by_ingredients', params: {
      'p_ingredient_ids': ingredientIds,
    }) as List<dynamic>;

    // Wait! rpcResult is a list of json objects like [{'recipe_id': '...'}]
    final recipeIds = rpcResult.map((e) => e['recipe_id'] as String).toList();
    if (recipeIds.isEmpty) return [];

    appLogger.db('BEFORE | table: recipe | select in getRecipesByIngredients | count: ${recipeIds.length} | country: $countryCode');
    
    final recipeData = await client
        .from('recipe')
        .select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), recipe_market_cost(cost_per_100g, country_code), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .inFilter('id', recipeIds)
        .eq('recipe_market_cost.country_code', countryCode) as List<dynamic>;

    final recipeMap = {
      for (final r in recipeData.cast<Map<String, dynamic>>())
        r['id'] as String: r
    };

    final recipes = recipeIds
        .where(recipeMap.containsKey)
        .map((id) => Recipe.fromJson(recipeMap[id]!))
        .toList();

    return await applyTitleTranslations(client, recipes, locale);
  } catch (e, st) {
    appLogger.db('ERROR | rpc: get_recipes_by_ingredients', error: e, stackTrace: st);
    rethrow;
  }
});

