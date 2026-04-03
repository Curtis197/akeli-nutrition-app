import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/recipe.dart';
import '../shared/mock_data.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Feed (personalised recommendations via MockData)
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

  // Simule un délai réseau
  await Future.delayed(const Duration(milliseconds: 800));

  return MockData.recipes;
});

// ---------------------------------------------------------------------------
// Recipe detail
// ---------------------------------------------------------------------------

final recipeDetailProvider =
    FutureProvider.autoDispose.family<Recipe?, String>((ref, id) async {
  // Simule un délai réseau
  await Future.delayed(const Duration(milliseconds: 500));

  try {
    return MockData.recipes.firstWhere((r) => r.id == id);
  } catch (_) {
    return null;
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
}

final searchRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, SearchParams>(
        (ref, params) async {
  if (params.query.length < 2) return [];

  // Simule un délai réseau
  await Future.delayed(const Duration(milliseconds: 600));

  return MockData.recipes
      .where((r) => r.title.toLowerCase().contains(params.query.toLowerCase()))
      .toList();
});

// ---------------------------------------------------------------------------
// Toggle like notifier — Mock version
// ---------------------------------------------------------------------------

class RecipeLikeNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<bool> toggle(String recipeId, bool currentlyLiked) async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 300));
    final newLikedStatus = !currentlyLiked;
    state = AsyncValue.data(newLikedStatus);
    return newLikedStatus;
  }
}

final recipeLikeProvider =
    AsyncNotifierProvider.autoDispose<RecipeLikeNotifier, bool>(
        RecipeLikeNotifier.new);
