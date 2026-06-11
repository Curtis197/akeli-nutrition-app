// lib/providers/creator_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/creator.dart';
import '../shared/models/creator_detail.dart';
import '../shared/models/recipe.dart';
import 'auth_provider.dart';

final _logger = appLogger;

// ---------------------------------------------------------------------------
// Creators list — for the Créateurs tab on the feed page
// ---------------------------------------------------------------------------

final creatorsListProvider = FutureProvider.autoDispose<List<Creator>>((ref) async {
  _logger.provider('creatorsListProvider build()');
  ref.onDispose(() => _logger.provider('creatorsListProvider disposed'));

  final user = ref.watch(currentUserProvider);
  if (user == null) {
    _logger.provider('creatorsListProvider EARLY RETURN | reason: no authenticated user');
    return [];
  }

  final client = ref.watch(supabaseClientProvider);

  try {
    // Step 1: get personalized ordering from RPC (cold start falls back to fan_count)
    _logger.db('BEFORE rpc | fn: generate_creators_personalized | userId: ${user.id}');
    final rpcRows = await client.rpc('generate_creators_personalized', params: {
      'p_user_id': user.id,
      'p_limit': 20,
    }) as List<dynamic>;
    _logger.db('AFTER rpc | fn: generate_creators_personalized | rows: ${rpcRows.length}');

    if (rpcRows.isEmpty) {
      _logger.provider('creatorsListProvider → data | count: 0');
      return [];
    }

    final orderedIds = rpcRows
        .map((r) => (r as Map<String, dynamic>)['creator_id'] as String)
        .toList();

    // Step 2: fetch full creator data for those IDs
    _logger.db('BEFORE | table: creator | op: SELECT IN | ids: ${orderedIds.length}');
    final rows = await client
        .from('creator')
        .select('id, user_id, display_name, profile_image_url, bio, specialties, recipe_count, fan_count, average_rating, heritage_region')
        .inFilter('id', orderedIds) as List<dynamic>;
    _logger.db('AFTER | table: creator | rows: ${rows.length}');

    // Step 3: fetch which creators the user already fans
    Set<String> fanIds = {};
    try {
      _logger.db('BEFORE | table: fan_subscription | op: SELECT IN | userId: ${user.id}');
      final fanRows = await client
          .from('fan_subscription')
          .select('creator_id')
          .inFilter('creator_id', orderedIds)
          .eq('user_id', user.id)
          .eq('status', 'active') as List<dynamic>;
      _logger.db('AFTER | table: fan_subscription | rows: ${fanRows.length}');
      fanIds = fanRows
          .map((r) => (r as Map<String, dynamic>)['creator_id'] as String)
          .toSet();
    } on PostgrestException catch (e, st) {
      _logger.db('ERROR | table: fan_subscription | code: ${e.code} | ${e.message}',
          error: e, stackTrace: st);
      // non-fatal — proceed with empty fan set (filter becomes a no-op)
    }

    // Step 4: re-apply RPC order (IN clause doesn't preserve order)
    final creatorMap = <String, Creator>{};
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final id = row['id'] as String;
      creatorMap[id] = Creator.fromJson({
        ...row,
        'is_my_fan_creator': fanIds.contains(id),
      });
    }

    final list = orderedIds
        .where((id) => creatorMap.containsKey(id))
        .map((id) => creatorMap[id]!)
        .toList();

    if (list.isEmpty) {
      _logger.rls('Zero rows | table: creator | possible RLS block');
    }
    _logger.provider('creatorsListProvider → data | count: ${list.length}');
    return list;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls('Permission denied | rpc: generate_creators_personalized', error: e, stackTrace: st);
    } else {
      _logger.db('ERROR | rpc: generate_creators_personalized | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    _logger.provider('creatorsListProvider → error | ${e.message}');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Single creator by ID — for the creator card on recipe detail page
// ---------------------------------------------------------------------------

final creatorByIdProvider =
    FutureProvider.autoDispose.family<Creator?, String>((ref, creatorId) async {
  _logger.provider('creatorByIdProvider build() | creatorId: $creatorId');
  ref.onDispose(() => _logger.provider('creatorByIdProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  _logger.db('BEFORE | table: creator | op: SELECT | creatorId: $creatorId');

  try {
    final row = await client
        .from('creator')
        .select('id, user_id, display_name, profile_image_url, bio, specialties, recipe_count, fan_count, average_rating, heritage_region')
        .eq('id', creatorId)
        .maybeSingle();

    _logger.db('AFTER | table: creator | rows: ${row == null ? 0 : 1}');

    if (row == null) {
      _logger.rls('Zero rows | table: creator | creatorId: $creatorId | possible RLS block');
      _logger.provider('creatorByIdProvider → data | found: false');
      return null;
    }

    _logger.provider('creatorByIdProvider → data | found: true');
    return Creator.fromJson(row);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls('Permission denied | table: creator | creatorId: $creatorId', error: e, stackTrace: st);
    } else {
      _logger.db('ERROR | table: creator | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    _logger.provider('creatorByIdProvider → error | ${e.message}');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Creator's published recipes — for the recipe grid on creator detail page
// ---------------------------------------------------------------------------

final creatorRecipesProvider =
    FutureProvider.autoDispose.family<List<Recipe>, String>((ref, creatorId) async {
  _logger.provider('creatorRecipesProvider build() | creatorId: $creatorId');
  ref.onDispose(() => _logger.provider('creatorRecipesProvider disposed'));

  final client = ref.watch(supabaseClientProvider);
  _logger.db('BEFORE | table: recipe | op: SELECT | creatorId: $creatorId');

  try {
    final rows = await client
        .from('recipe')
        .select('id, creator_id, title, cover_image_url, region, average_rating, like_count, difficulty, prep_time_min, cook_time_min, servings, is_published, rating_count, created_at')
        .eq('creator_id', creatorId)
        .eq('is_published', true)
        .order('created_at', ascending: false) as List<dynamic>;

    _logger.db('AFTER | table: recipe | rows: ${rows.length}');

    if (rows.isEmpty) {
      _logger.rls('Zero rows | table: recipe | creatorId: $creatorId | possible RLS block');
    }

    final list = rows
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
    _logger.provider('creatorRecipesProvider → data | count: ${list.length}');
    return list;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls('Permission denied | table: recipe | creatorId: $creatorId', error: e, stackTrace: st);
    } else {
      _logger.db('ERROR | table: recipe | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    _logger.provider('creatorRecipesProvider → error | ${e.message}');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Creator detail — aggregate for the detail page
// ---------------------------------------------------------------------------

final creatorDetailProvider =
    FutureProvider.autoDispose.family<CreatorDetail, String>((ref, creatorId) async {
  _logger.provider('creatorDetailProvider build() | creatorId: $creatorId');
  ref.onDispose(() => _logger.provider('creatorDetailProvider disposed'));

  final user = ref.watch(currentUserProvider);
  if (user == null) {
    _logger.provider('creatorDetailProvider EARLY RETURN | reason: no authenticated user');
    throw Exception('Not authenticated');
  }

  final client = ref.watch(supabaseClientProvider);

  _logger.db('[STEP 1] Fetching creator + recipes + fan status in parallel | creatorId: $creatorId');

  late final Creator creator;
  late final List<Recipe> recipes;
  late final bool isFan;

  try {
    final results = await Future.wait(<Future<dynamic>>[
      // creator row
      client
          .from('creator')
          .select('id, user_id, display_name, profile_image_url, bio, specialties, recipe_count, fan_count, average_rating, heritage_region')
          .eq('id', creatorId)
          .single(),
      // creator's published recipes (for totalLikes + recipeIds)
      client
          .from('recipe')
          .select('id, like_count, creator_id, title, cover_image_url, region, average_rating, difficulty, prep_time_min, cook_time_min, servings, is_published, rating_count, created_at, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g)')
          .eq('creator_id', creatorId)
          .eq('is_published', true),
      // active fan subscription
      client
          .from('fan_subscription')
          .select('id, status')
          .eq('creator_id', creatorId)
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1),
    ]);

    final creatorRow = results[0] as Map<String, dynamic>;
    final recipeRows = results[1] as List<dynamic>;
    final fanRows = results[2] as List<dynamic>;

    _logger.db('[STEP 1] Done | recipes: ${recipeRows.length} | isFan: ${fanRows.isNotEmpty}');

    creator = Creator.fromJson(creatorRow);
    recipes = recipeRows.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    isFan = fanRows.isNotEmpty;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls('Permission denied | parallel fetch | creatorId: $creatorId', error: e, stackTrace: st);
    } else {
      _logger.db('ERROR | parallel fetch | creatorId: $creatorId | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    _logger.provider('creatorDetailProvider → error | ${e.message}');
    rethrow;
  }

  final totalLikes = recipes.fold<int>(0, (sum, r) => sum + r.likeCount);
  final recipeIds = recipes.map((r) => r.id).toList();

  int userConsumptionCount = 0;
  if (recipeIds.isNotEmpty) {
    _logger.db('[STEP 2] Querying meal_plan_entry_component | recipeIds: ${recipeIds.length}');
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

      _logger.db('[STEP 2] Done | distinct consumed recipes: $userConsumptionCount');
    } on PostgrestException catch (e, st) {
      _logger.db('ERROR | table: meal_plan_entry_component | ${e.message}', error: e, stackTrace: st);
      // Non-fatal — proceed with 0
    }
  }

  _logger.provider('creatorDetailProvider → data | creatorId: $creatorId');
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
  _logger.db('BEFORE | table: fan_subscription | op: INSERT | creatorId: $creatorId | userId: $userId');
  try {
    await client.from('fan_subscription').insert({
      'creator_id': creatorId,
      'user_id': userId,
      'status': 'active',
    });
    _logger.db('AFTER | table: fan_subscription | op: INSERT | success');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls('Permission denied | table: fan_subscription | creatorId: $creatorId', error: e, stackTrace: st);
    } else {
      _logger.db('ERROR | table: fan_subscription | code: ${e.code} | ${e.message}', error: e, stackTrace: st);
    }
    rethrow;
  }
}
