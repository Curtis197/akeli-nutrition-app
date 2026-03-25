import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../shared/models/recipe.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Feed (personalised recommendations via RPC)
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
}

final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final result = await supabase.rpc('recommend_recipes', params: {
    'p_user_id': user.id,
    'p_limit': params.limit,
    'p_offset': params.offset,
    if (params.regionId != null) 'p_region': params.regionId,
    if (params.difficulty != null) 'p_difficulty': params.difficulty,
    if (params.maxTimeMin != null) 'p_max_time': params.maxTimeMin,
  });

  return (result as List<dynamic>)
      .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Recipe detail
// ---------------------------------------------------------------------------

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe?, String>((ref, id) async {
  final user = ref.watch(currentUserProvider);

  final query = supabase.from('recipe').select('''
    *,
    recipe_ingredient (
      ingredient_id,
      quantity,
      unit,
      is_optional,
      ingredient:ingredient_id ( name )
    ),
    recipe_step ( step_number, instruction, duration_min, image_url )
  ''').eq('id', id).eq('is_published', true).maybeSingle();

  final data = await query;
  if (data == null) return null;

  // Flatten ingredient names
  if (data['recipe_ingredient'] is List) {
    for (final ing in data['recipe_ingredient'] as List) {
      ing['ingredient_name'] =
          (ing['ingredient'] as Map<String, dynamic>?)?['name'];
    }
  }

  // Check if liked by current user
  if (user != null) {
    final liked = await supabase
        .from('recipe_like')
        .select('id')
        .eq('recipe_id', id)
        .eq('user_id', user.id)
        .maybeSingle();
    data['is_liked'] = liked != null;
  }

  return Recipe.fromJson(data);
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
}

final searchRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, SearchParams>(
        (ref, params) async {
  if (params.query.length < 2) return [];

  final result = await supabase.rpc('search_recipes', params: {
    'p_query': params.query,
    'p_limit': params.limit,
    'p_offset': params.offset,
    if (params.regionId != null) 'p_region': params.regionId,
    if (params.difficulty != null) 'p_difficulty': params.difficulty,
    if (params.maxTimeMin != null) 'p_max_time': params.maxTimeMin,
    'p_order_by': params.orderBy,
  });

  return (result as List<dynamic>)
      .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Toggle like notifier
// ---------------------------------------------------------------------------

class RecipeLikeNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<bool> toggle(String recipeId, bool currentlyLiked) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final res = await supabase.functions.invoke(
        'toggle-recipe-like',
        body: {'recipe_id': recipeId},
      );
      return (res.data as Map<String, dynamic>)['liked'] as bool;
    });
    state = result;
    return result.valueOrNull ?? currentlyLiked;
  }
}

final recipeLikeProvider =
    AsyncNotifierProvider.autoDispose<RecipeLikeNotifier, bool>(
        RecipeLikeNotifier.new);
