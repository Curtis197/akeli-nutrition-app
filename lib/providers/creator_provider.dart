// lib/providers/creator_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/creator.dart';
import '../shared/models/creator_detail.dart';
import '../shared/models/recipe.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Creators list — for the Créateurs tab on the feed page
// ---------------------------------------------------------------------------

final creatorsListProvider = FutureProvider.autoDispose<List<Creator>>((ref) async {
  appLogger.provider('creatorsListProvider build()');
  ref.onDispose(() => appLogger.provider('creatorsListProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: creator | op: SELECT | order: recipe_count DESC | limit: 50');

  try {
    final rows = await client
        .from('creator')
        .select('id, user_id, display_name, avatar_url, bio, specialties, recipe_count, fan_count, average_rating, food_region_id')
        .order('recipe_count', ascending: false)
        .limit(50) as List<dynamic>;

    appLogger.db('AFTER | table: creator | rows: ${rows.length}');

    if (rows.isEmpty) {
      appLogger.rls('Zero rows | table: creator | possible RLS block');
    }

    return rows
        .map((e) => Creator.fromJson(e as Map<String, dynamic>))
        .toList();
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: creator', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: creator | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Single creator by ID — for the creator card on recipe detail page
// ---------------------------------------------------------------------------

final creatorByIdProvider =
    FutureProvider.autoDispose.family<Creator?, String>((ref, creatorId) async {
  appLogger.provider('creatorByIdProvider build() | creatorId: $creatorId');
  ref.onDispose(() => appLogger.provider('creatorByIdProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: creator | op: SELECT | creatorId: $creatorId');

  try {
    final row = await client
        .from('creator')
        .select('id, user_id, display_name, avatar_url, bio, specialties, recipe_count, fan_count, average_rating, food_region_id')
        .eq('id', creatorId)
        .maybeSingle();

    appLogger.db('AFTER | table: creator | rows: ${row == null ? 0 : 1}');

    if (row == null) {
      appLogger.rls('Zero rows | table: creator | creatorId: $creatorId | possible RLS block');
      return null;
    }

    return Creator.fromJson(row);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: creator | creatorId: $creatorId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: creator | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Creator's published recipes — for the recipe grid on creator detail page
// ---------------------------------------------------------------------------

final creatorRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, String>((ref, creatorId) async {
  appLogger.provider('creatorRecipesProvider build() | creatorId: $creatorId');
  ref.onDispose(() => appLogger.provider('creatorRecipesProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  appLogger.db('BEFORE | table: recipe | op: SELECT | creatorId: $creatorId');

  try {
    final rows = await client
        .from('recipe')
        .select('id, creator_id, title, cover_image_url, region, calories, average_rating, like_count, difficulty, prep_time_min, cook_time_min, servings, is_published, rating_count, created_at')
        .eq('creator_id', creatorId)
        .eq('is_published', true)
        .order('created_at', ascending: false) as List<dynamic>;

    appLogger.db('AFTER | table: recipe | rows: ${rows.length}');

    if (rows.isEmpty) {
      appLogger.rls('Zero rows | table: recipe | creatorId: $creatorId | possible RLS block');
    }

    return rows
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: recipe | creatorId: $creatorId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: recipe | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Creator detail — aggregate for the detail page
// ---------------------------------------------------------------------------

final creatorDetailProvider =
    FutureProvider.autoDispose.family<CreatorDetail, String>((ref, creatorId) async {
  appLogger.provider('creatorDetailProvider build() | creatorId: $creatorId');
  ref.onDispose(() => appLogger.provider('creatorDetailProvider disposed'));

  final user = ref.watch(currentUserProvider);
  if (user == null) {
    appLogger.provider('creatorDetailProvider EARLY RETURN | reason: no authenticated user');
    throw Exception('Not authenticated');
  }

  final client = ref.watch(supabaseClientProvider);

  appLogger.db('[STEP 1] Fetching creator + recipes + fan status in parallel | creatorId: $creatorId');

  // Run three queries in parallel — typed separately to avoid Future.wait inference issues
  final creatorFuture = client
      .from('creator')
      .select('id, user_id, display_name, avatar_url, bio, specialties, recipe_count, fan_count, average_rating, food_region_id')
      .eq('id', creatorId)
      .single();
  final recipesFuture = client
      .from('recipe')
      .select('id, like_count, creator_id, title, cover_image_url, region, calories, average_rating, difficulty, prep_time_min, cook_time_min, servings, is_published, rating_count, created_at')
      .eq('creator_id', creatorId)
      .eq('is_published', true);
  final fanFuture = client
      .from('fan_subscription')
      .select('id, status')
      .eq('creator_id', creatorId)
      .eq('user_id', user.id)
      .eq('status', 'active')
      .limit(1);

  final creatorRow = await creatorFuture;
  final recipeRows = await recipesFuture as List<dynamic>;
  final fanRows = await fanFuture as List<dynamic>;

  appLogger.db('[STEP 1] Done | recipes: ${recipeRows.length} | isFan: ${fanRows.isNotEmpty}');

  final creator = Creator.fromJson(creatorRow);
  final recipes = recipeRows.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  final isFan = fanRows.isNotEmpty;
  final totalLikes = recipes.fold<int>(0, (sum, r) => sum + r.likeCount);
  final recipeIds = recipes.map((r) => r.id).toList();

  int userConsumptionCount = 0;
  if (recipeIds.isNotEmpty) {
    appLogger.db('[STEP 2] Querying meal_plan_entry_component | recipeIds: ${recipeIds.length}');
    try {
      final consumptionRows = await client
          .from('meal_plan_entry_component')
          .select('recipe_id')
          .inFilter('recipe_id', recipeIds) as List<dynamic>;

      // Distinct recipe IDs consumed
      userConsumptionCount = consumptionRows
          .map((e) => (e as Map<String, dynamic>)['recipe_id'] as String)
          .toSet()
          .length;

      appLogger.db('[STEP 2] Done | distinct consumed recipes: $userConsumptionCount');
    } on PostgrestException catch (e, st) {
      appLogger.db('ERROR | table: meal_plan_entry_component | ${e.message}', error: e, stackTrace: st);
      // Non-fatal — proceed with 0
    }
  }

  return CreatorDetail(
    creator: creator,
    totalLikes: totalLikes,
    userConsumptionCount: userConsumptionCount,
    isFan: isFan,
  );
});

// ---------------------------------------------------------------------------
// Become fan action — standalone function called from CreatorDetailPage
// ---------------------------------------------------------------------------

Future<void> becomeFan(SupabaseClient client, String creatorId, String userId) async {
  appLogger.db('BEFORE | table: fan_subscription | op: INSERT | creatorId: $creatorId | userId: $userId');
  try {
    await client.from('fan_subscription').insert({
      'creator_id': creatorId,
      'user_id': userId,
      'status': 'active',
      'effective_from': DateTime.now().toIso8601String(),
    });
    appLogger.db('AFTER | table: fan_subscription | op: INSERT | success');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: fan_subscription | creatorId: $creatorId', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: fan_subscription | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
}
