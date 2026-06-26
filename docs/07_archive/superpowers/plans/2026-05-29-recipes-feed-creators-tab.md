# Recipes Feed — Créateurs Tab & Creator Detail Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Créateurs" tab to the recipes feed page, a tappable creator card on the recipe detail page, and a full creator detail page with stats, recipes, and a fan button.

**Architecture:** State-driven tab in `FeedPage` using `AkeliTabBar` + `_tabIndex`. New `creator_provider.dart` handles all creator data fetching. New `creator_detail_page.dart` renders the creator profile with a compound `CreatorDetail` model that aggregates creator info, total likes, and user consumption count.

**Tech Stack:** Flutter, Riverpod (`FutureProvider.autoDispose.family`), Supabase PostgREST, GoRouter, `cached_network_image`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/shared/models/creator_detail.dart` | Create | Aggregate model for detail page |
| `lib/providers/creator_provider.dart` | Create | All creator data providers |
| `lib/shared/widgets/creator_card.dart` | Create | Reusable creator list card |
| `lib/features/recipes/creator_detail_page.dart` | Create | Full creator detail page |
| `lib/core/router.dart` | Modify | Add `/creators/:creatorId` route |
| `lib/features/recipes/feed_page.dart` | Modify | Add tab bar + Créateurs tab body |
| `lib/features/recipes/recipe_detail_page.dart` | Modify | Replace hardcoded creator card |
| `test/features/recipes/creator_detail_test.dart` | Create | Model + provider unit tests |

---

## Task 1: CreatorDetail Aggregate Model

**Files:**
- Create: `lib/shared/models/creator_detail.dart`
- Create: `test/features/recipes/creator_detail_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/recipes/creator_detail_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/creator.dart';
import 'package:akeli/shared/models/creator_detail.dart';

void main() {
  group('CreatorDetail', () {
    final creator = Creator(
      id: 'c1',
      userId: 'u1',
      displayName: 'Chef Amina',
      specialties: [],
      recipeCount: 5,
      fanCount: 10,
      isFanEligible: false,
      isMyFanCreator: false,
      averageRating: 4.2,
    );

    test('totalLikes and userConsumptionCount are stored correctly', () {
      final detail = CreatorDetail(
        creator: creator,
        totalLikes: 42,
        userConsumptionCount: 3,
        isFan: false,
      );
      expect(detail.totalLikes, 42);
      expect(detail.userConsumptionCount, 3);
      expect(detail.isFan, false);
      expect(detail.creator.displayName, 'Chef Amina');
    });

    test('copyWith isFan updates fan status', () {
      final detail = CreatorDetail(
        creator: creator,
        totalLikes: 42,
        userConsumptionCount: 3,
        isFan: false,
      );
      final updated = detail.copyWith(isFan: true);
      expect(updated.isFan, true);
      expect(updated.totalLikes, 42); // unchanged
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
flutter test test/features/recipes/creator_detail_test.dart
```

Expected: FAIL — `creator_detail.dart` not found.

- [ ] **Step 3: Create the model**

```dart
// lib/shared/models/creator_detail.dart
import 'package:flutter/foundation.dart';
import 'creator.dart';

@immutable
class CreatorDetail {
  final Creator creator;
  final int totalLikes;
  final int userConsumptionCount;
  final bool isFan;

  const CreatorDetail({
    required this.creator,
    required this.totalLikes,
    required this.userConsumptionCount,
    required this.isFan,
  });

  CreatorDetail copyWith({
    Creator? creator,
    int? totalLikes,
    int? userConsumptionCount,
    bool? isFan,
  }) =>
      CreatorDetail(
        creator: creator ?? this.creator,
        totalLikes: totalLikes ?? this.totalLikes,
        userConsumptionCount: userConsumptionCount ?? this.userConsumptionCount,
        isFan: isFan ?? this.isFan,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

```
flutter test test/features/recipes/creator_detail_test.dart
```

Expected: All 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/creator_detail.dart test/features/recipes/creator_detail_test.dart
git commit -m "feat(creators): add CreatorDetail aggregate model"
```

---

## Task 2: Creator Providers

**Files:**
- Create: `lib/providers/creator_provider.dart`

This file defines four providers. Each uses the same logging pattern as `recipe_provider.dart`.

- [ ] **Step 1: Create `creator_provider.dart`**

```dart
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

    return Creator.fromJson(row as Map<String, dynamic>);
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

  final results = await Future.wait([
    // creator row
    client
        .from('creator')
        .select('id, user_id, display_name, avatar_url, bio, specialties, recipe_count, fan_count, average_rating, food_region_id')
        .eq('id', creatorId)
        .single(),
    // creator's published recipes (for totalLikes + recipeIds)
    client
        .from('recipe')
        .select('id, like_count, creator_id, title, cover_image_url, region, calories, average_rating, difficulty, prep_time_min, cook_time_min, servings, is_published, rating_count, created_at')
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
// Become fan action
// ---------------------------------------------------------------------------

final becomeFanProvider =
    FutureProvider.autoDispose.family<void, String>((ref, creatorId) async {
  // Not auto-triggered — call ref.refresh(becomeFanProvider(creatorId)) to trigger.
  // Prefer calling _becomeFan() from the page directly (see creator_detail_page.dart).
});

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
```

- [ ] **Step 2: Verify it compiles**

```
flutter analyze lib/providers/creator_provider.dart
```

Expected: No errors. Fix any import issues if flagged.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/creator_provider.dart
git commit -m "feat(creators): add creator providers (list, byId, recipes, detail)"
```

---

## Task 3: CreatorCard Widget

**Files:**
- Create: `lib/shared/widgets/creator_card.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/shared/widgets/creator_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/models/creator.dart';

class CreatorCard extends StatelessWidget {
  final Creator creator;
  final String? regionName;
  final VoidCallback? onTap;

  const CreatorCard({
    super.key,
    required this.creator,
    this.regionName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appLogger.userAction('CreatorCard tapped', screen: 'CreatorCard',
            metadata: {'creatorId': creator.id});
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AkeliSpacing.md, vertical: AkeliSpacing.xs),
        padding: const EdgeInsets.all(AkeliSpacing.md),
        decoration: BoxDecoration(
          color: AkeliColors.surface,
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          border:
              Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: const [AkeliShadows.sm],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(avatarUrl: creator.avatarUrl, displayName: creator.displayName),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          creator.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (regionName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AkeliColors.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            regionName!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AkeliColors.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (creator.bio != null && creator.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      creator.bio!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AkeliColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${creator.recipeCount} recette${creator.recipeCount != 1 ? 's' : ''}',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AkeliColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AkeliColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;

  const _Avatar({required this.avatarUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: AkeliColors.primaryContainer,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: AkeliColors.onPrimaryContainer),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```
flutter analyze lib/shared/widgets/creator_card.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/creator_card.dart
git commit -m "feat(creators): add CreatorCard widget"
```

---

## Task 4: CreatorDetailPage + Route

**Files:**
- Create: `lib/features/recipes/creator_detail_page.dart`
- Modify: `lib/core/router.dart`

- [ ] **Step 1: Add route constant and GoRoute to router.dart**

In `lib/core/router.dart`, add to `AkeliRoutes`:

```dart
// After line 65 (dmChatPath)
static const creatorDetail = '/creators/:creatorId';
static String creatorDetailPath(String id) => '/creators/$id';
```

Add the import at the top (after existing imports):

```dart
import '../features/recipes/creator_detail_page.dart';
```

Add the `GoRoute` in the `routes` list, before the `ShellRoute` (around line 258):

```dart
GoRoute(
  path: AkeliRoutes.creatorDetail,
  builder: (context, state) {
    final creatorId = state.pathParameters['creatorId']!;
    return CreatorDetailPage(creatorId: creatorId);
  },
),
```

- [ ] **Step 2: Create `creator_detail_page.dart`**

```dart
// lib/features/recipes/creator_detail_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/core/supabase_client.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/auth_provider.dart';
import 'package:akeli/providers/creator_provider.dart';
import 'package:akeli/providers/food_region_provider.dart';
import 'package:akeli/shared/models/creator_detail.dart';
import 'package:akeli/shared/widgets/akeli_recipe_card.dart';
import 'package:akeli/shared/widgets/empty_state.dart';
import 'domain/entities/recipe_tracking.dart';

class CreatorDetailPage extends ConsumerStatefulWidget {
  final String creatorId;

  const CreatorDetailPage({super.key, required this.creatorId});

  @override
  ConsumerState<CreatorDetailPage> createState() => _CreatorDetailPageState();
}

class _CreatorDetailPageState extends ConsumerState<CreatorDetailPage> {
  final _logger = appLogger;
  bool _becomingFan = false;

  @override
  void initState() {
    super.initState();
    _logger.provider('CreatorDetailPage initState() | creatorId: ${widget.creatorId}');
  }

  @override
  void dispose() {
    _logger.provider('CreatorDetailPage disposed');
    super.dispose();
  }

  Future<void> _onBecomeFan(CreatorDetail detail) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Become fan tapped', screen: 'CreatorDetailPage',
        metadata: {'creatorId': widget.creatorId});

    setState(() => _becomingFan = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await becomeFan(client, widget.creatorId, user.id);
      ref.invalidate(creatorDetailProvider(widget.creatorId));
    } catch (e, st) {
      _logger.edge('becomeFan', 'ERROR | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur. Veuillez réessayer.')),
        );
      }
    } finally {
      if (mounted) setState(() => _becomingFan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(creatorDetailProvider(widget.creatorId));
    final recipesAsync = ref.watch(creatorRecipesProvider(widget.creatorId));
    final regionNames = ref.watch(foodRegionNamesProvider).valueOrNull ?? {};

    _logger.provider(
        'CreatorDetailPage build() | detailAsync.isLoading: ${detailAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(creatorDetailProvider(widget.creatorId)),
        ),
        data: (detail) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(detail: detail, regionNames: regionNames)),
            SliverToBoxAdapter(child: _StatsRow(detail: detail)),
            SliverToBoxAdapter(
              child: _FanSection(
                detail: detail,
                becomingFan: _becomingFan,
                onBecomeFan: () => _onBecomeFan(detail),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AkeliSpacing.md, AkeliSpacing.lg, AkeliSpacing.md, AkeliSpacing.sm),
                child: Text(
                  'Recettes',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AkeliColors.onSurface),
                ),
              ),
            ),
            recipesAsync.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(
                child: ErrorState(
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(creatorRecipesProvider(widget.creatorId)),
                ),
              ),
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Aucune recette publiée',
                      subtitle: 'Ce créateur n\'a pas encore publié de recettes.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AkeliSpacing.md,
                      mainAxisSpacing: AkeliSpacing.md,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return AkeliRecipeCard(
                        hasImage: true,
                        title: recipe.title,
                        calories: recipe.calories?.toInt() ?? 0,
                        rating: recipe.averageRating,
                        likes: recipe.likeCount,
                        comments: 0,
                        saves: 0,
                        imageUrl: recipe.thumbnailUrl,
                        region: recipe.regionId != null
                            ? regionNames[recipe.regionId!] ?? recipe.regionId
                            : null,
                        tags: recipe.tagIds.take(2).toList(),
                        onTap: () {
                          _logger.userAction('Recipe tapped from creator page',
                              screen: 'CreatorDetailPage',
                              metadata: {'recipeId': recipe.id});
                          context.push(AkeliRoutes.recipeDetailPath(recipe.id),
                              extra: TrackingSource.feed);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final CreatorDetail detail;
  final Map<String, String> regionNames;

  const _Header({required this.detail, required this.regionNames});

  @override
  Widget build(BuildContext context) {
    final creator = detail.creator;
    final regionName = creator.regionId != null
        ? regionNames[creator.regionId!] ?? creator.regionId
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.lg, vertical: AkeliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LargeAvatar(
                  avatarUrl: creator.avatarUrl,
                  displayName: creator.displayName),
              const SizedBox(width: AkeliSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AkeliColors.onSurface),
                    ),
                    if (regionName != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AkeliColors.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          regionName,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AkeliColors.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (creator.bio != null && creator.bio!.isNotEmpty) ...[
            const SizedBox(height: AkeliSpacing.md),
            Text(
              creator.bio!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AkeliColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;

  const _LargeAvatar({required this.avatarUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: AkeliColors.primaryContainer,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AkeliColors.onPrimaryContainer),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final CreatorDetail detail;

  const _StatsRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    final creator = detail.creator;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatPill(
                icon: Icons.restaurant_menu_rounded,
                label: '${creator.recipeCount} recettes'),
            const SizedBox(width: 8),
            _StatPill(
                icon: Icons.star_rounded,
                label: creator.averageRating.toStringAsFixed(1)),
            const SizedBox(width: 8),
            _StatPill(
                icon: Icons.favorite_rounded,
                label: '${detail.totalLikes} likes'),
            const SizedBox(width: 8),
            _StatPill(
                icon: Icons.check_circle_rounded,
                label: '${detail.userConsumptionCount} cuisinées'),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AkeliColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AkeliColors.onSurface)),
        ],
      ),
    );
  }
}

class _FanSection extends StatelessWidget {
  final CreatorDetail detail;
  final bool becomingFan;
  final VoidCallback onBecomeFan;

  const _FanSection({
    required this.detail,
    required this.becomingFan,
    required this.onBecomeFan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
      child: detail.isFan
          ? Row(
              children: [
                const Icon(Icons.verified_rounded,
                    size: 18, color: AkeliColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Vous êtes fan de ce créateur',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AkeliColors.primary),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: becomingFan ? null : onBecomeFan,
                icon: becomingFan
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.favorite_rounded, size: 18),
                label: Text(becomingFan ? 'En cours...' : 'Devenir fan'),
              ),
            ),
    );
  }
}
```

- [ ] **Step 3: Verify compilation**

```
flutter analyze lib/features/recipes/creator_detail_page.dart lib/core/router.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/recipes/creator_detail_page.dart lib/core/router.dart
git commit -m "feat(creators): add CreatorDetailPage and /creators/:creatorId route"
```

---

## Task 5: Feed Page Tab System

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

Add the `_tabIndex` state variable, wire up `AkeliTabBar`, update `SliverAppBar.bottom` height, and add the Créateurs sliver body.

- [ ] **Step 1: Add imports and state variable**

At the top of `feed_page.dart`, add these imports (after the existing ones):

```dart
import '../../providers/creator_provider.dart';
import '../../providers/food_region_provider.dart';
import '../../shared/widgets/creator_card.dart';
import '../../shared/widgets/tab_bar.dart';
import 'creator_detail_page.dart';
```

Note: `food_region_provider.dart` is already imported. Only add the 4 new ones.

In `_FeedPageState`, add after the existing state variables (after line `String? _orderBy;`):

```dart
int _tabIndex = 0;
```

- [ ] **Step 2: Update `initState` logging**

Replace:
```dart
_logger.provider('FeedPage initState()');
```
With:
```dart
_logger.provider('FeedPage initState() | tabIndex: $_tabIndex');
```

- [ ] **Step 3: Update `SliverAppBar.bottom` to include tab bar**

The current `bottom:` block starts at `bottom: PreferredSize(` with `preferredSize: const Size.fromHeight(104)`.

Replace the entire `bottom:` argument (the `PreferredSize(...)` block) with:

```dart
bottom: PreferredSize(
  preferredSize: Size.fromHeight(_tabIndex == 0 ? 148 : 44),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
        child: AkeliTabBar(
          tabs: const ['Recettes', 'Créateurs'],
          selectedIndex: _tabIndex,
          onTabSelected: (i) {
            _logger.userAction('Feed tab selected', screen: 'FeedPage',
                metadata: {'tabIndex': i.toString()});
            setState(() => _tabIndex = i);
          },
        ),
      ),
      if (_tabIndex == 0) ...[
        // ---- existing search + filter rows go here (unchanged) ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
          child: Row(
            children: [
              // ... (keep the existing SearchBar + filter/sort icon buttons exactly as-is)
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: !_hasActiveFilter
              ? const SizedBox.shrink()
              : ListView(
                  // ... (keep existing active filter chips exactly as-is)
                ),
        ),
        const SizedBox(height: 8),
      ],
    ],
  ),
),
```

**Important:** Do NOT rewrite the inner search bar and filter chip code — move it verbatim inside the `if (_tabIndex == 0)` block. The existing children of the `Column` in the old `bottom:` all move inside that `if` block.

- [ ] **Step 4: Add Créateurs sliver body**

In the `build()` method, the `CustomScrollView.slivers` list currently ends with the `feedAsync.when(...)` sliver. After that sliver (before the closing `],` of `slivers:`), the `feedAsync.when(...)` sliver is already rendered conditionally by the provider — but we need to guard all recipe slivers behind `if (_tabIndex == 0)` and add a Créateurs sliver for tab 1.

Replace the entire `// Content` section (the `feedAsync.when(...)` block):

```dart
// Content
if (_tabIndex == 0)
  feedAsync.when(
    loading: () => const SliverFillRemaining(
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (err, _) => SliverFillRemaining(
      child: ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(feedProvider),
      ),
    ),
    data: (recipes) {
      if (recipes.isEmpty) {
        return SliverFillRemaining(
          child: EmptyState(
            icon: Icons.restaurant_menu_rounded,
            title: isSearching ? 'Aucune recette trouvée' : 'Pas encore de recettes',
            subtitle: isSearching
                ? 'Essayez d\'autres termes de recherche.'
                : 'Explorez et découvrez des recettes africaines.',
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.all(AkeliSpacing.md),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AkeliSpacing.md,
            mainAxisSpacing: AkeliSpacing.md,
            childAspectRatio: 0.68,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return AkeliRecipeCard(
              hasImage: true,
              title: recipe.title,
              calories: recipe.calories?.toInt() ?? 0,
              rating: recipe.averageRating,
              likes: recipe.likeCount,
              comments: 0,
              saves: 0,
              emoji: null,
              region: recipe.regionId != null
                  ? regionNames[recipe.regionId!] ?? recipe.regionId
                  : null,
              tags: recipe.tagIds.take(2).toList(),
              onTap: () {
                _logger.userAction('Recipe card tapped', screen: 'FeedPage',
                    metadata: {'recipeId': recipe.id});
                if (widget.swapEntryId != null) {
                  ref
                      .read(mealPlanSwapProvider.notifier)
                      .swapMeal(widget.swapEntryId!, recipe.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Repas remplacé avec succès'),
                    backgroundColor: AkeliColors.primary,
                  ));
                  context.pop();
                } else {
                  context.push(
                    AkeliRoutes.recipeDetailPath(recipe.id),
                    extra: TrackingSource.feed,
                  );
                }
              },
            );
          },
        ),
      );
    },
  )
else
  _buildCreateursSliver(regionNames),
```

- [ ] **Step 5: Add `_buildCreateursSliver` method**

Add this private method to `_FeedPageState` (before `build()`):

```dart
Widget _buildCreateursSliver(Map<String, String> regionNames) {
  final creatorsAsync = ref.watch(creatorsListProvider);
  _logger.provider('_buildCreateursSliver | creatorsAsync.isLoading: ${creatorsAsync.isLoading}');

  return creatorsAsync.when(
    loading: () => const SliverFillRemaining(
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (err, _) => SliverFillRemaining(
      child: ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(creatorsListProvider),
      ),
    ),
    data: (creators) {
      if (creators.isEmpty) {
        return const SliverFillRemaining(
          child: EmptyState(
            icon: Icons.person_rounded,
            title: 'Aucun créateur disponible',
            subtitle: 'Les créateurs apparaîtront ici.',
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
        sliver: SliverList.builder(
          itemCount: creators.length,
          itemBuilder: (context, index) {
            final creator = creators[index];
            return CreatorCard(
              creator: creator,
              regionName: creator.regionId != null
                  ? regionNames[creator.regionId!] ?? creator.regionId
                  : null,
              onTap: () {
                _logger.userAction('Creator card tapped', screen: 'FeedPage',
                    metadata: {'creatorId': creator.id});
                context.push(AkeliRoutes.creatorDetailPath(creator.id));
              },
            );
          },
        ),
      );
    },
  );
}
```

- [ ] **Step 6: Verify compilation**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat(creators): add Créateurs tab to recipes feed page"
```

---

## Task 6: Replace Hardcoded Creator Card in RecipeDetailPage

**Files:**
- Modify: `lib/features/recipes/recipe_detail_page.dart`

The hardcoded creator block runs from line 592 to 642. Replace it with a real `CreatorCard` that loads data from `creatorByIdProvider`.

- [ ] **Step 1: Add imports to `recipe_detail_page.dart`**

Add after the existing imports:

```dart
import '../../providers/creator_provider.dart';
import '../../shared/widgets/creator_card.dart';
import '../../providers/food_region_provider.dart';
```

- [ ] **Step 2: Replace hardcoded creator block**

Find the `// CREATOR CARD` comment block (lines 592–642) and replace the entire `Padding(...)` widget with:

```dart
// CREATOR CARD
_CreatorCardSection(creatorId: recipe.creatorId),
```

- [ ] **Step 3: Add `_CreatorCardSection` private widget at the bottom of the file**

Add this class at the bottom of `recipe_detail_page.dart`, after the `_RecipeDetailPageState` class:

```dart
class _CreatorCardSection extends ConsumerWidget {
  final String creatorId;

  const _CreatorCardSection({required this.creatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorAsync = ref.watch(creatorByIdProvider(creatorId));
    final regionNames = ref.watch(foodRegionNamesProvider).valueOrNull ?? {};

    return creatorAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (creator) {
        if (creator == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'RECETTE CRÉÉE PAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              CreatorCard(
                creator: creator,
                regionName: creator.regionId != null
                    ? regionNames[creator.regionId!] ?? creator.regionId
                    : null,
                onTap: () {
                  appLogger.userAction('Creator card tapped from recipe detail',
                      screen: 'RecipeDetailPage',
                      metadata: {'creatorId': creatorId});
                  context.push(AkeliRoutes.creatorDetailPath(creatorId));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Verify compilation**

```
flutter analyze lib/features/recipes/recipe_detail_page.dart
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/recipes/recipe_detail_page.dart
git commit -m "feat(creators): replace hardcoded creator card with real data in RecipeDetailPage"
```

---

## Task 7: Manual Testing Checklist

- [ ] **Step 1: Run the app**

```
flutter run
```

- [ ] **Step 2: Test Créateurs tab on feed page**

1. Navigate to the Recettes tab (bottom nav).
2. Confirm "Recettes" and "Créateurs" tabs appear in the app bar.
3. Confirm tab 0 (Recettes) shows search bar, filters, and recipe grid as before.
4. Tap "Créateurs" tab — confirm search bar and filters disappear.
5. Confirm creator cards appear with avatar, name, region chip, bio (2 lines), recipe count.
6. If no creators in DB, confirm the empty state shows correctly.

- [ ] **Step 3: Test creator detail page**

1. Tap a creator card.
2. Confirm navigation to `/creators/:id`.
3. Confirm header: avatar, name, region, bio.
4. Confirm stats row: recipe count, avg rating, total likes, cuisinées count.
5. If not already a fan: confirm "Devenir fan" button is visible.
6. Tap "Devenir fan" — confirm loading state, then "Vous êtes fan de ce créateur" label appears.
7. Confirm recipe grid shows creator's published recipes.
8. Tap a recipe card — confirm navigation to recipe detail.

- [ ] **Step 4: Test creator card on recipe detail**

1. Navigate to any recipe detail page.
2. Scroll to the bottom — confirm real creator data appears (not "Chef Amina").
3. Confirm creator name, avatar, region, recipe count shown.
4. Tap the creator card — confirm navigation to `/creators/:id`.

- [ ] **Step 5: Commit test sign-off**

```bash
git commit --allow-empty -m "test(creators): manual test pass — creators tab, detail page, recipe card"
```
