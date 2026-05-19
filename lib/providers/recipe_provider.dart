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
  final int offset;
  final String? regionId;
  final String? difficulty;
  final int? maxTimeMin;

  const FeedParams({
    this.limit = 20,
    this.offset = 0,
    this.regionId,
    this.difficulty,
    this.maxTimeMin,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedParams &&
          limit == other.limit &&
          offset == other.offset &&
          regionId == other.regionId &&
          difficulty == other.difficulty &&
          maxTimeMin == other.maxTimeMin;

  @override
  int get hashCode => Object.hash(limit, offset, regionId, difficulty, maxTimeMin);
}

final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  appLogger.provider('feedProvider build() | userId: ${user?.id ?? "null"} | params: limit=${params.limit} offset=${params.offset}');
  ref.onDispose(() => appLogger.provider('feedProvider disposed | params: limit=${params.limit}'));

  if (user == null) {
    appLogger.provider('feedProvider EARLY RETURN | reason: no authenticated user');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);
  final rpcParams = {
    'p_user_id': user.id,
    'p_limit': params.limit,
    'p_offset': params.offset,
  };

  appLogger.db('BEFORE rpc | fn: get_personalized_feed | userId: ${user.id} | params: $rpcParams');

  try {
    final data = await client.rpc('get_personalized_feed', params: rpcParams) as List<dynamic>;
    appLogger.db('AFTER rpc | fn: get_personalized_feed | rows: ${data.length}');

    if (data.isEmpty) {
      appLogger.rls('Zero rows | rpc: get_personalized_feed | userId: ${user.id} | possible RLS or empty feed');
    }

    final recipes = data.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
    appLogger.provider('feedProvider → data | recipes: ${recipes.length}');
    return recipes;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | rpc: get_personalized_feed | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR rpc | fn: get_personalized_feed | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    appLogger.provider('feedProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR rpc | fn: get_personalized_feed | unexpected: $e', error: e, stackTrace: st);
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
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) {
      appLogger.db('AFTER | table: recipe | rows: 0 | recipeId: $id | not found');
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
  final String orderBy;
  final int limit;
  final int offset;

  const SearchParams({
    required this.query,
    this.regionId,
    this.difficulty,
    this.maxTimeMin,
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
          orderBy == other.orderBy &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(query, regionId, difficulty, maxTimeMin, orderBy, limit, offset);
}

final searchRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, SearchParams>(
        (ref, params) async {
  appLogger.provider('searchRecipesProvider build() | query: "${params.query}" | limit: ${params.limit}');
  ref.onDispose(() => appLogger.provider('searchRecipesProvider disposed | query: "${params.query}"'));

  if (params.query.length < 2) {
    appLogger.provider('searchRecipesProvider EARLY RETURN | reason: query too short (${params.query.length} chars)');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: recipe | op: SELECT ilike | query: "${params.query}" | limit: ${params.limit}');

  try {
    final data = await client
        .from('recipe')
        .select()
        .ilike('title', '%${params.query}%')
        .limit(params.limit) as List<dynamic>;

    appLogger.db('AFTER | table: recipe | rows: ${data.length} | query: "${params.query}"');

    if (data.isEmpty) {
      appLogger.provider('searchRecipesProvider → data (empty) | no results for "${params.query}"');
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
// Toggle like — Edge Function
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
          body: {'recipe_id': recipeId, 'liked': newLiked},
        );
        _logger.edge('toggle-recipe-like', 'AFTER | success | recipeId: $recipeId | liked: $newLiked');
        _logger.provider('RecipeLikeNotifier → data | liked: $newLiked');
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
