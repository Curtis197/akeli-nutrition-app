// lib/providers/_examples/recipe_provider_logged.dart
/**
 * EXAMPLE: Recipe Provider with Comprehensive Logging and RLS Detection
 * 
 * This example demonstrates how to implement comprehensive logging
 * in a Riverpod data provider with RLS violation detection.
 * 
 * You can use this as a template for other data providers.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/logger.dart' show RLSDebugHelper;

/// Recipe model
class Recipe {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String? imageUrl;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByUser;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    this.imageUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByUser = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      creatorId: json['creator_id'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      isLikedByUser: json['is_liked_by_user'] as bool? ?? false,
    );
  }
}

/// Recipe feed provider state
class RecipeFeedState {
  final List<Recipe> recipes;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const RecipeFeedState({
    this.recipes = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  const RecipeFeedState.initial()
      : recipes = const [],
        isLoading = false,
        hasMore = true,
        error = null;

  RecipeFeedState copyWith({
    List<Recipe>? recipes,
    bool isLoading = false,
    bool hasMore = true,
    String? error,
  }) {
    return RecipeFeedState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading,
      hasMore: hasMore,
      error: error,
    );
  }
}

/// Recipe notifier with comprehensive logging
class RecipeFeedNotifier extends AsyncNotifier<RecipeFeedState> {
  final _logger = appLogger;
  static const _pageSize = 20;

  @override
  Future<RecipeFeedState> build() async {
    _logger.provider('RecipeFeedNotifier initialized');
    
    ref.onDispose(() {
      _logger.provider('RecipeFeedNotifier disposed');
    });
    
    // Listen to auth changes and invalidate when user changes
    ref.listen<String?>(currentUserProvider, (previous, next) {
      if (previous != next) {
        _logger.provider('RecipeFeedNotifier detected auth change, invalidating');
        ref.invalidateSelf();
      }
    });
    
    // Load initial data
    return await _fetchRecipes();
  }

  /// Fetch recipes from Supabase with RLS logging
  Future<RecipeFeedState> _fetchRecipes({int offset = 0}) async {
    final userId = ref.read(currentUserProvider)?.id;
    
    _logger.db('Fetching recipes | userId: ${userId ?? "anonymous"} | offset: $offset | limit: $_pageSize');
    
    // RLS debug: Log query context
    RLSDebugHelper.debugQuery(
      'recipe',
      userId,
      filters: {
        'is_published': true,
        'limit': _pageSize,
        'offset': offset,
      },
    );
    
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('recipe')
          .select('''
            id,
            title,
            description,
            creator_id,
            image_url,
            created_at,
            like_count
          ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);
      
      // RLS check: Log result with expectations
      if (response.isEmpty && offset == 0) {
        _logger.rls(
          'Recipe query returned 0 rows for offset 0. Possible RLS policy blocking.',
        );
        _logger.rls(
          'Check RLS policies on "recipe" table for auth_uid() match or creator visibility',
        );
      } else {
        _logger.db(
          'Retrieved ${response.length} recipes | hasMore: ${response.length >= _pageSize}',
        );
      }
      
      final recipes = response.map((json) => Recipe.fromJson(json)).toList();
      
      return RecipeFeedState(
        recipes: recipes,
        hasMore: response.length >= _pageSize,
      );
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        // RLS violation
        _logger.rls(
          'Permission denied on recipe query | userId: $userId | code: ${e.code}',
          error: e,
          stackTrace: st,
        );
      } else {
        _logger.db(
          'Query failed on recipe | code: ${e.code} | message: ${e.message}',
          error: e,
          stackTrace: st,
        );
      }
      rethrow;
    } catch (e, st) {
      _logger.db(
        'Unexpected error fetching recipes: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Load more recipes (pagination)
  Future<void> loadMore() async {
    if (!state.hasValue || !state.value!.hasMore || state.isLoading) {
      _logger.provider('RecipeFeedNotifier loadMore skipped | hasValue: ${state.hasValue} | hasMore: ${state.value?.hasMore} | isLoading: ${state.isLoading}');
      return;
    }
    
    _logger.provider('RecipeFeedNotifier loadMore triggered');
    
    final currentState = state.value!;
    final offset = currentState.recipes.length;
    
    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    
    state = await AsyncValue.guard(() async {
      try {
        final newState = await _fetchRecipes(offset: offset);
        
        return currentState.copyWith(
          recipes: [...currentState.recipes, ...newState.recipes],
          hasMore: newState.hasMore,
          isLoading: false,
        );
      } catch (e, st) {
        _logger.db('Failed to load more recipes: $e', error: e, stackTrace: st);
        return currentState.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    });
  }

  /// Refresh recipes (pull-to-refresh)
  Future<void> refresh() async {
    _logger.provider('RecipeFeedNotifier refresh triggered');
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      try {
        final newState = await _fetchRecipes(offset: 0);
        _logger.provider('RecipeFeedNotifier refresh successful | loaded ${newState.recipes.length} recipes');
        return newState;
      } catch (e, st) {
        _logger.db('Failed to refresh recipes: $e', error: e, stackTrace: st);
        rethrow;
      }
    });
  }

  /// Toggle like on a recipe
  Future<void> toggleLike(String recipeId) async {
    final userId = ref.read(currentUserProvider)?.id;
    
    if (userId == null) {
      _logger.auth('Cannot toggle like: No authenticated user');
      return;
    }
    
    _logger.db('Toggling like on recipe | recipeId: $recipeId | userId: $userId');
    
    // Optimistic update
    final currentState = state.value;
    if (currentState == null) return;
    
    final updatedRecipes = currentState.recipes.map((recipe) {
      if (recipe.id == recipeId) {
        return Recipe(
          id: recipe.id,
          title: recipe.title,
          description: recipe.description,
          creatorId: recipe.creatorId,
          imageUrl: recipe.imageUrl,
          createdAt: recipe.createdAt,
          likeCount: recipe.isLikedByUser
              ? recipe.likeCount - 1
              : recipe.likeCount + 1,
          isLikedByUser: !recipe.isLikedByUser,
        );
      }
      return recipe;
    }).toList();
    
    state = AsyncValue.data(currentState.copyWith(recipes: updatedRecipes));
    
    // Perform actual mutation
    state = await AsyncValue.guard(() async {
      try {
        final supabase = Supabase.instance.client;
        
        RLSDebugHelper.debugQuery('recipe_like', userId, filters: {
          'recipe_id': recipeId,
          'operation': 'INSERT/DELETE',
        });
        
        // Check if already liked
        final existingLike = await supabase
            .from('recipe_like')
            .select('id')
            .eq('recipe_id', recipeId)
            .eq('user_id', userId)
            .maybeSingle();
        
        if (existingLike != null) {
          // Unlike
          _logger.db('Removing like | recipeId: $recipeId');
          
          final {error} = await supabase
              .from('recipe_like')
              .delete()
              .eq('recipe_id', recipeId)
              .eq('user_id', userId);
          
          if (error != null) {
            if (error.code == '42501') {
              _logger.rls('Permission denied on unlike | recipeId: $recipeId');
            } else {
              _logger.db('Unlike failed | recipeId: $recipeId | error: ${error.message}');
            }
            throw error;
          }
          
          _logger.db('Recipe unliked successfully | recipeId: $recipeId');
        } else {
          // Like
          _logger.db('Adding like | recipeId: $recipeId');
          
          final {error} = await supabase
              .from('recipe_like')
              .insert({
                'recipe_id': recipeId,
                'user_id': userId,
              });
          
          if (error != null) {
            if (error.code == '42501') {
              _logger.rls('Permission denied on like | recipeId: $recipeId');
            } else {
              _logger.db('Like failed | recipeId: $recipeId | error: ${error.message}');
            }
            throw error;
          }
          
          _logger.db('Recipe liked successfully | recipeId: $recipeId');
        }
        
        return currentState;
      } catch (e, st) {
        _logger.db(
          'Failed to toggle like on recipe $recipeId: $e',
          error: e,
          stackTrace: st,
        );
        
        // Revert optimistic update on error
        return currentState;
      }
    });
  }
}

/// Provider for recipe feed
final recipeFeedProvider =
    AsyncNotifierProvider<RecipeFeedNotifier, RecipeFeedState>(RecipeFeedNotifier.new);

/// Provider for current user (imported from auth)
final currentUserProvider = Provider<String?>((ref) {
  // This would be imported from auth_provider
  return null;
});
