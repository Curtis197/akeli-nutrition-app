import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
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
}

final feedProvider =
    FutureProvider.autoDispose.family<List<Recipe>, FeedParams>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final data = await client.rpc('get_personalized_feed', params: {
    'p_user_id': user.id,
    'p_limit': params.limit,
    'p_offset': params.offset,
  }) as List<dynamic>;

  return data
      .cast<Map<String, dynamic>>()
      .map(Recipe.fromJson)
      .toList();
});

// ---------------------------------------------------------------------------
// Recipe detail
// ---------------------------------------------------------------------------

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('recipe')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
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

  final client = ref.watch(supabaseClientProvider);
  var query = client
      .from('recipe')
      .select()
      .ilike('title', '%${params.query}%')
      .limit(params.limit);

  final data = await query as List<dynamic>;
  return data
      .cast<Map<String, dynamic>>()
      .map(Recipe.fromJson)
      .toList();
});

// ---------------------------------------------------------------------------
// Toggle like — Edge Function
// ---------------------------------------------------------------------------

class RecipeLikeNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<bool> toggle(String recipeId, bool currentlyLiked) async {
    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    final newLiked = !currentlyLiked;
    state = await AsyncValue.guard(() async {
      await client.functions.invoke(
        'toggle-recipe-like',
        body: {'recipe_id': recipeId, 'liked': newLiked},
      );
      return newLiked;
    });
    return newLiked;
  }
}

final recipeLikeProvider =
    AsyncNotifierProvider.autoDispose<RecipeLikeNotifier, bool>(
        RecipeLikeNotifier.new);
