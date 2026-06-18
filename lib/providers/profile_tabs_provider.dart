import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/supabase_client.dart';
import '../core/logger.dart';
import '../shared/models/recipe.dart';

part 'profile_tabs_provider.g.dart';

@riverpod
Future<List<Recipe>> userSavedRecipes(Ref ref, String userId) async {
  appLogger.provider('userSavedRecipesProvider build() | userId: $userId');
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('recipe_save')
      .select('recipe_id')
      .eq('user_id', userId);

  final recipeIds = response.cast<Map<String, dynamic>>().map((e) => e['recipe_id'] as String).toList();

  if (recipeIds.isEmpty) return [];

  final recipesData = await client
      .from('recipe')
      .select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g)')
      .inFilter('id', recipeIds)
      .order('created_at', ascending: false);

  return recipesData.map((e) => Recipe.fromJson(e)).toList();
}

final userLikedRecipesProvider = FutureProvider.autoDispose.family<List<Recipe>, String>((ref, userId) async {
  appLogger.provider('userLikedRecipesProvider build() | userId: $userId');
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('recipe_like')
      .select('recipe_id')
      .eq('user_id', userId);

  final recipeIds = response.cast<Map<String, dynamic>>().map((e) => e['recipe_id'] as String).toList();

  if (recipeIds.isEmpty) return <Recipe>[];

  final recipesData = await client
      .from('recipe')
      .select('*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g)')
      .inFilter('id', recipeIds)
      .order('created_at', ascending: false);

  return recipesData.map((e) => Recipe.fromJson(e)).toList();
});


@riverpod
Future<List<Map<String, dynamic>>> userComments(Ref ref, String userId) async {
  appLogger.provider('userCommentsProvider build() | userId: $userId');
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('recipe_comment')
      .select('*, recipe(title, cover_image_url)')
      .eq('user_id', userId)
      .order('created_at', ascending: false);
      
  return response.cast<Map<String, dynamic>>();
}

@riverpod
Future<List<Map<String, dynamic>>> userGroups(Ref ref, String userId) async {
  appLogger.provider('userGroupsProvider build() | userId: $userId');
  final client = ref.watch(supabaseClientProvider);
  final memberships = await client
      .from('group_member')
      .select('group_id')
      .eq('user_id', userId) as List<dynamic>;

  if (memberships.isEmpty) return [];

  final groupIds = memberships
      .cast<Map<String, dynamic>>()
      .map((m) => m['group_id'] as String)
      .toList();

  final groups = await client
      .from('v_community_group')
      .select('*')
      .inFilter('id', groupIds)
      .order('updated_at', ascending: false) as List<dynamic>;

  return groups.cast<Map<String, dynamic>>();
}
