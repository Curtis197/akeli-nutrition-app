import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/logger.dart';
import '../shared/models/recipe.dart';
import 'auth_provider.dart';

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

  const FeedParams({
    this.limit = 20,
    this.excludeIds = const [],
    this.regionId,
    this.difficulty,
    this.maxTimeMin,
    this.minCal,
    this.maxCal,
    this.orderBy,
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
          orderBy == other.orderBy;

  @override
  int get hashCode =>
      Object.hash(limit, excludeIds.length, regionId, difficulty, maxTimeMin, minCal, maxCal, orderBy);
}

final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  appLogger.provider(
      'feedProvider build() | userId: ${user?.id ?? "null"} | region: ${params.regionId} | difficulty: ${params.difficulty} | orderBy: ${params.orderBy}');
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

    appLogger.db(
        'BEFORE | table: recipe | op: SELECT in | ids: ${recipeIds.length}');
    final recipeData = await client
        .from('recipe')
        .select(
            '*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .inFilter('id', recipeIds) as List<dynamic>;
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

    appLogger.provider(
        'feedProvider → data | recipes: ${recipes.length}');
    return recipes;
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
  appLogger.provider('recipeDetailProvider build() | recipeId: $id');
  ref.onDispose(() => appLogger.provider('recipeDetailProvider disposed | recipeId: $id'));

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: recipe | op: SELECT | recipeId: $id');

  try {
    final data = await client
        .from('recipe')
        .select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g), ingredients:recipe_ingredient(id, ingredient_id, ingredient:ingredient_id(name_fr, name), quantity, unit, is_optional, sort_order), steps:recipe_step(step_number, content, image_url, timer_seconds, sort_order, ingredient_ids), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) {
      appLogger.db('AFTER | table: recipe | rows: 0 | recipeId: $id | not found');
      appLogger.rls('Zero rows | table: recipe | recipeId: $id | possible RLS block');
      appLogger.provider('recipeDetailProvider → data (null)');
      return null;
    }

    appLogger.db('AFTER | table: recipe | rows: 1 | recipeId: $id');
    final recipe = Recipe.fromJson(data);
    appLogger.provider('recipeDetailProvider → data | title: ${recipe.title}');
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
          offset == other.offset;

  @override
  int get hashCode => Object.hash(query, regionId, difficulty, maxTimeMin, minCal, maxCal, orderBy, limit, offset);
}

final searchRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, SearchParams>(
        (ref, params) async {
  appLogger.provider(
      'searchRecipesProvider build() | query: "${params.query}" | region: ${params.regionId} | difficulty: ${params.difficulty} | maxTime: ${params.maxTimeMin} | orderBy: ${params.orderBy}');
  ref.onDispose(() => appLogger.provider('searchRecipesProvider disposed | query: "${params.query}"'));

  if (params.query.length < 2) {
    appLogger.provider(
        'searchRecipesProvider EARLY RETURN | reason: query too short (${params.query.length} chars)');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);
  appLogger.db(
      'BEFORE | table: recipe | op: SELECT ilike+filters | query: "${params.query}" | limit: ${params.limit}');

  try {
    var query = client.from('recipe').select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g), recipe_save!left(recipe_id), recipe_like!left(recipe_id)').ilike('title', '%${params.query}%');

    if (params.regionId != null) query = query.eq('region_id', params.regionId!);
    if (params.difficulty != null) query = query.eq('difficulty', params.difficulty!);
    if (params.maxTimeMin != null) query = query.lte('total_time_min', params.maxTimeMin!);
    if (params.minCal != null) query = query.gte('calories', params.minCal!);
    if (params.maxCal != null) query = query.lte('calories', params.maxCal!);

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
    appLogger.provider('searchRecipesProvider → data | recipes: ${recipes.length}');
    return recipes;
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

  final client = ref.watch(supabaseClientProvider);
  const sel = 'id, creator_id, title, cover_image_url, recipe_macro(calories, protein_g, carbs_g, fat_g), like_count, average_rating, is_published, created_at';

  appLogger.db('BEFORE | table: recipe | chatRecipePicker | query: "$query"');
  try {
    final data = query.length >= 2
        ? await client
            .from('recipe')
            .select(sel)
            .eq('is_published', true)
            .ilike('title', '%$query%')
            .limit(30) as List<dynamic>
        : await client
            .from('recipe')
            .select(sel)
            .eq('is_published', true)
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

  appLogger.db('BEFORE | table: recipe | op: SELECT | creator_id: $creatorId');

  try {
    final data = await client
        .from('recipe')
        .select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g), recipe_save!left(recipe_id), recipe_like!left(recipe_id)')
        .eq('creator_id', creatorId)
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
