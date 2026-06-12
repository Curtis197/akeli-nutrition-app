# Fan Mode Page Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single `FanModePage` with two purpose-built views — a non-fan view showing consumption ratio by creator, and a fan view showing subscription status, the 90/10 external counter, and a leave button.

**Architecture:** `FanModePage.build()` branches on `myFanSubscriptionProvider` to render either `_NoFanUserView` or `_FanUserView`. Two new providers (`creatorConsumptionProvider`, `fanExternalCounterProvider`) supply the data. The aggregation logic for consumption is extracted as a pure function so it can be unit-tested without Supabase mocks.

**Tech Stack:** Flutter 3, Riverpod (`FutureProvider.autoDispose`), Supabase PostgREST, `flutter_test`, `mocktail`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/shared/models/creator.dart` | Modify | Add `CreatorConsumption` model |
| `lib/providers/fan_mode_provider.dart` | Modify | Add `creatorConsumptionProvider`, `fanExternalCounterProvider`, and pure `aggregateConsumption()` function |
| `lib/features/fan_mode/fan_mode_page.dart` | Rewrite | Branch on subscription state; `_NoFanUserView`, `_FanUserView` widgets |
| `test/shared/models/creator_consumption_test.dart` | Create | Unit tests for `CreatorConsumption.fromAggregated()` |
| `test/providers/fan_mode_aggregation_test.dart` | Create | Unit tests for pure `aggregateConsumption()` function |
| `test/features/fan_mode/fan_mode_page_test.dart` | Create | Widget tests for both views via provider overrides |

---

## Task 1: `CreatorConsumption` model

**Files:**
- Modify: `lib/shared/models/creator.dart`
- Create: `test/shared/models/creator_consumption_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/shared/models/creator_consumption_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/creator.dart';

void main() {
  group('CreatorConsumption', () {
    test('fromAggregated maps all fields', () {
      final c = CreatorConsumption.fromAggregated(
        creatorId: 'c-1',
        creatorName: 'Amara Diallo',
        avatarUrl: 'https://example.com/avatar.jpg',
        count: 12,
        totalMeals: 20,
      );

      expect(c.creatorId, 'c-1');
      expect(c.creatorName, 'Amara Diallo');
      expect(c.avatarUrl, 'https://example.com/avatar.jpg');
      expect(c.count, 12);
      expect(c.pct, closeTo(0.6, 0.001));
    });

    test('avatarUrl is nullable', () {
      final c = CreatorConsumption.fromAggregated(
        creatorId: 'c-2',
        creatorName: 'Kofi',
        avatarUrl: null,
        count: 5,
        totalMeals: 10,
      );
      expect(c.avatarUrl, isNull);
    });

    test('pct is 0.0 when totalMeals is 0', () {
      final c = CreatorConsumption.fromAggregated(
        creatorId: 'c-3',
        creatorName: 'Fatou',
        avatarUrl: null,
        count: 0,
        totalMeals: 0,
      );
      expect(c.pct, 0.0);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```
flutter test test/shared/models/creator_consumption_test.dart
```
Expected: compilation error — `CreatorConsumption` not defined.

- [ ] **Step 3: Add `CreatorConsumption` to `lib/shared/models/creator.dart`**

Append after the closing `}` of `FanSubscription`:

```dart
@immutable
class CreatorConsumption {
  final String creatorId;
  final String creatorName;
  final String? avatarUrl;
  final int count;
  final double pct;

  const CreatorConsumption({
    required this.creatorId,
    required this.creatorName,
    this.avatarUrl,
    required this.count,
    required this.pct,
  });

  factory CreatorConsumption.fromAggregated({
    required String creatorId,
    required String creatorName,
    String? avatarUrl,
    required int count,
    required int totalMeals,
  }) =>
      CreatorConsumption(
        creatorId: creatorId,
        creatorName: creatorName,
        avatarUrl: avatarUrl,
        count: count,
        pct: totalMeals == 0 ? 0.0 : count / totalMeals,
      );
}
```

- [ ] **Step 4: Run to verify it passes**

```
flutter test test/shared/models/creator_consumption_test.dart
```
Expected: all 3 tests pass.

- [ ] **Step 5: Commit**

```
git add lib/shared/models/creator.dart test/shared/models/creator_consumption_test.dart
git commit -m "feat: add CreatorConsumption model"
```

---

## Task 2: `aggregateConsumption()` pure function + providers

**Files:**
- Modify: `lib/providers/fan_mode_provider.dart`
- Create: `test/providers/fan_mode_aggregation_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/providers/fan_mode_aggregation_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/providers/fan_mode_provider.dart';
import 'package:akeli/shared/models/creator.dart';

void main() {
  group('aggregateConsumption', () {
    final creators = {
      'c-1': Creator(
        id: 'c-1', userId: 'u-1', displayName: 'Amara', avatarUrl: 'https://x.com/a.jpg',
        specialties: [], recipeCount: 40, fanCount: 10,
        isFanEligible: true, isMyFanCreator: false, averageRating: 4.5,
      ),
      'c-2': Creator(
        id: 'c-2', userId: 'u-2', displayName: 'Kofi', avatarUrl: null,
        specialties: [], recipeCount: 35, fanCount: 5,
        isFanEligible: true, isMyFanCreator: false, averageRating: 4.0,
      ),
    };

    test('aggregates rows by creator_id and sorts by count desc', () {
      final rows = [
        {'creator_id': 'c-1'},
        {'creator_id': 'c-2'},
        {'creator_id': 'c-1'},
        {'creator_id': 'c-1'},
      ];

      final result = aggregateConsumption(rows, creators);

      expect(result.length, 2);
      expect(result[0].creatorId, 'c-1');
      expect(result[0].count, 3);
      expect(result[0].pct, closeTo(0.75, 0.001));
      expect(result[1].creatorId, 'c-2');
      expect(result[1].count, 1);
      expect(result[1].pct, closeTo(0.25, 0.001));
    });

    test('returns empty list when rows is empty', () {
      final result = aggregateConsumption([], creators);
      expect(result, isEmpty);
    });

    test('skips rows whose creator_id is not in creatorMap', () {
      final rows = [
        {'creator_id': 'c-1'},
        {'creator_id': 'c-unknown'},
      ];
      final result = aggregateConsumption(rows, creators);
      expect(result.length, 1);
      expect(result[0].creatorId, 'c-1');
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```
flutter test test/providers/fan_mode_aggregation_test.dart
```
Expected: compilation error — `aggregateConsumption` not defined.

- [ ] **Step 3: Add `aggregateConsumption()` and the two new providers to `lib/providers/fan_mode_provider.dart`**

Add this helper function before the `FanModeNotifier` class (around line 130):

```dart
// ---------------------------------------------------------------------------
// Pure aggregation — exported for testability
// ---------------------------------------------------------------------------

String currentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

List<CreatorConsumption> aggregateConsumption(
  List<Map<String, dynamic>> rows,
  Map<String, Creator> creatorMap,
) {
  if (rows.isEmpty) return [];
  final counts = <String, int>{};
  for (final row in rows) {
    final id = row['creator_id'] as String?;
    if (id == null || !creatorMap.containsKey(id)) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final total = counts.values.fold(0, (a, b) => a + b);
  final result = counts.entries.map((e) {
    final c = creatorMap[e.key]!;
    return CreatorConsumption.fromAggregated(
      creatorId: c.id,
      creatorName: c.displayName,
      avatarUrl: c.avatarUrl,
      count: e.value,
      totalMeals: total,
    );
  }).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return result;
}
```

Then add these two providers after `creatorProfileProvider` (around line 127):

```dart
// ---------------------------------------------------------------------------
// Creator consumption ratio — current month, aggregated client-side
// ---------------------------------------------------------------------------

final creatorConsumptionProvider =
    FutureProvider.autoDispose<List<CreatorConsumption>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  appLogger.provider('creatorConsumptionProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('creatorConsumptionProvider disposed'));

  final monthKey = currentMonthKey();
  final client = ref.watch(supabaseClientProvider);

  // Step 1: fetch this month's consumption rows
  appLogger.db('BEFORE | table: meal_consumption | op: SELECT | userId: ${user.id} | month: $monthKey');
  late final List<Map<String, dynamic>> consumptionRows;
  try {
    consumptionRows = await client
        .from('meal_consumption')
        .select('creator_id')
        .eq('user_id', user.id)
        .eq('month_key', monthKey);
    appLogger.db('AFTER | table: meal_consumption | rows: ${consumptionRows.length}');
    if (consumptionRows.isEmpty) {
      appLogger.rls('Zero rows | table: meal_consumption | userId: ${user.id} | month: $monthKey | no meals or RLS');
      appLogger.provider('creatorConsumptionProvider → data (empty)');
      return [];
    }
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: meal_consumption | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: meal_consumption | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('creatorConsumptionProvider → error | ${e.message}');
    rethrow;
  }

  // Step 2: fetch creator details for distinct IDs found in consumption
  final creatorIds = consumptionRows
      .map((r) => r['creator_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  appLogger.db('BEFORE | table: creator | op: SELECT | ids: ${creatorIds.length}');
  late final List<Map<String, dynamic>> creatorRows;
  try {
    creatorRows = await client
        .from('creator')
        .select()
        .inFilter('id', creatorIds);
    appLogger.db('AFTER | table: creator | rows: ${creatorRows.length}');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: creator', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: creator | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('creatorConsumptionProvider → error | ${e.message}');
    rethrow;
  }

  final creatorMap = {for (final r in creatorRows) r['id'] as String: Creator.fromJson(r)};
  final result = aggregateConsumption(consumptionRows, creatorMap);
  appLogger.provider('creatorConsumptionProvider → data | creators: ${result.length}');
  return result;
});

// ---------------------------------------------------------------------------
// Fan external recipe counter — current month (0 if no row yet)
// ---------------------------------------------------------------------------

final fanExternalCounterProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  appLogger.provider('fanExternalCounterProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('fanExternalCounterProvider disposed'));

  final monthKey = currentMonthKey();
  final client = ref.watch(supabaseClientProvider);

  appLogger.db('BEFORE | table: fan_external_recipe_counter | op: SELECT | userId: ${user.id} | month: $monthKey');
  try {
    final data = await client
        .from('fan_external_recipe_counter')
        .select('external_recipe_count')
        .eq('user_id', user.id)
        .eq('month_key', monthKey)
        .maybeSingle();
    final count = (data?['external_recipe_count'] as int?) ?? 0;
    appLogger.db('AFTER | table: fan_external_recipe_counter | count: $count');
    appLogger.provider('fanExternalCounterProvider → data | count: $count');
    return count;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: fan_external_recipe_counter | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: fan_external_recipe_counter | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('fanExternalCounterProvider → error | ${e.message}');
    rethrow;
  }
});
```

- [ ] **Step 4: Run aggregation tests**

```
flutter test test/providers/fan_mode_aggregation_test.dart
```
Expected: all 3 tests pass.

- [ ] **Step 5: Commit**

```
git add lib/providers/fan_mode_provider.dart lib/shared/models/creator.dart test/providers/fan_mode_aggregation_test.dart
git commit -m "feat: add creatorConsumptionProvider and fanExternalCounterProvider"
```

---

## Task 3: Rewrite `fan_mode_page.dart`

**Files:**
- Rewrite: `lib/features/fan_mode/fan_mode_page.dart`
- Create: `test/features/fan_mode/fan_mode_page_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/fan_mode/fan_mode_page_test.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/fan_mode/fan_mode_page.dart';
import 'package:akeli/providers/fan_mode_provider.dart';
import 'package:akeli/shared/models/creator.dart';

// Stub image loading so widget tests don't hit the network
class _FakeCachedNetworkImageProvider extends Fake
    implements CachedNetworkImageProvider {}

FanSubscription _activeSub() => FanSubscription(
      id: 's-1',
      userId: 'u-1',
      creatorId: 'c-1',
      status: 'active',
      effectiveFrom: DateTime(2026, 6, 1),
      createdAt: DateTime(2026, 5, 15),
    );

FanSubscription _pendingSub() => FanSubscription(
      id: 's-2',
      userId: 'u-1',
      creatorId: 'c-1',
      status: 'pending',
      createdAt: DateTime(2026, 6, 10),
    );

final _eligibleCreators = [
  Creator(
    id: 'c-1', userId: 'u-10', displayName: 'Amara Diallo',
    specialties: ['Cuisine ouest-africaine'], recipeCount: 54, fanCount: 38,
    isFanEligible: true, isMyFanCreator: false, averageRating: 4.8,
  ),
];

final _consumption = [
  CreatorConsumption.fromAggregated(
    creatorId: 'c-1', creatorName: 'Amara Diallo',
    avatarUrl: null, count: 12, totalMeals: 15,
  ),
];

Widget _wrap(Widget child, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );

void main() {
  group('FanModePage — no subscription', () {
    late List<Override> overrides;

    setUp(() {
      overrides = [
        myFanSubscriptionProvider.overrideWith((_) async => null),
        fanEligibleCreatorsProvider.overrideWith((_) async => _eligibleCreators),
        creatorConsumptionProvider.overrideWith((_) async => _consumption),
      ];
    });

    testWidgets('shows consumption ratio card', (tester) async {
      await tester.pumpWidget(_wrap(const FanModePage(), overrides));
      await tester.pumpAndSettle();

      expect(find.text('Vos recettes ce mois'), findsOneWidget);
      expect(find.text('Amara Diallo'), findsWidgets);
    });

    testWidgets('shows creator list with Soutenir button', (tester) async {
      await tester.pumpWidget(_wrap(const FanModePage(), overrides));
      await tester.pumpAndSettle();

      expect(find.text('Créateurs à soutenir'), findsOneWidget);
      expect(find.text('Soutenir'), findsOneWidget);
    });

    testWidgets('shows empty state when no consumption', (tester) async {
      final emptyOverrides = [
        myFanSubscriptionProvider.overrideWith((_) async => null),
        fanEligibleCreatorsProvider.overrideWith((_) async => _eligibleCreators),
        creatorConsumptionProvider.overrideWith((_) async => []),
      ];
      await tester.pumpWidget(_wrap(const FanModePage(), emptyOverrides));
      await tester.pumpAndSettle();

      expect(find.text('Aucune recette enregistrée ce mois'), findsOneWidget);
    });
  });

  group('FanModePage — active fan', () {
    late List<Override> overrides;

    setUp(() {
      overrides = [
        myFanSubscriptionProvider.overrideWith((_) async => _activeSub()),
        fanEligibleCreatorsProvider.overrideWith((_) async => _eligibleCreators),
        creatorConsumptionProvider.overrideWith((_) async => _consumption),
        fanExternalCounterProvider.overrideWith((_) async => 3),
        creatorProfileProvider('c-1').overrideWith((_) async => _eligibleCreators.first),
      ];
    });

    testWidgets('shows active status chip', (tester) async {
      await tester.pumpWidget(_wrap(const FanModePage(), overrides));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mode Fan actif'), findsOneWidget);
    });

    testWidgets('shows external counter', (tester) async {
      await tester.pumpWidget(_wrap(const FanModePage(), overrides));
      await tester.pumpAndSettle();

      expect(find.text('Recettes externes ce mois'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('shows Quitter le Mode Fan button', (tester) async {
      await tester.pumpWidget(_wrap(const FanModePage(), overrides));
      await tester.pumpAndSettle();

      expect(find.text('Quitter le Mode Fan'), findsOneWidget);
    });
  });

  group('FanModePage — pending fan', () {
    testWidgets('hides external counter when pending', (tester) async {
      final overrides = [
        myFanSubscriptionProvider.overrideWith((_) async => _pendingSub()),
        fanEligibleCreatorsProvider.overrideWith((_) async => _eligibleCreators),
        creatorConsumptionProvider.overrideWith((_) async => _consumption),
        fanExternalCounterProvider.overrideWith((_) async => 0),
        creatorProfileProvider('c-1').overrideWith((_) async => _eligibleCreators.first),
      ];
      await tester.pumpWidget(_wrap(const FanModePage(), overrides));
      await tester.pumpAndSettle();

      expect(find.text('Recettes externes ce mois'), findsNothing);
      expect(find.textContaining('mois prochain'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```
flutter test test/features/fan_mode/fan_mode_page_test.dart
```
Expected: compilation errors — widgets not yet built.

- [ ] **Step 3: Rewrite `lib/features/fan_mode/fan_mode_page.dart`**

Replace the entire file content:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/fan_mode_provider.dart';
import '../../shared/models/creator.dart';
import '../../shared/widgets/empty_state.dart';

class FanModePage extends ConsumerWidget {
  const FanModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fanSubAsync = ref.watch(myFanSubscriptionProvider);
    appLogger.provider('FanModePage build() | isLoading: ${fanSubAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: const Text('Mode Fan'),
        backgroundColor: AkeliColors.background,
        elevation: 0,
      ),
      body: fanSubAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Center(child: Text('Erreur de chargement')),
        data: (sub) {
          final isFan = sub != null && (sub.isActive || sub.isPending);
          appLogger.provider('FanModePage → isFan: $isFan | status: ${sub?.status}');
          if (isFan) return _FanUserView(sub: sub!);
          return const _NoFanUserView();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View A — Non-fan
// ─────────────────────────────────────────────────────────────────────────────

class _NoFanUserView extends ConsumerWidget {
  const _NoFanUserView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumptionAsync = ref.watch(creatorConsumptionProvider);
    final creatorsAsync = ref.watch(fanEligibleCreatorsProvider);
    appLogger.provider('_NoFanUserView build()');

    return CustomScrollView(
      slivers: [
        // Consumption ratio card
        SliverToBoxAdapter(
          child: consumptionAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (consumption) => _ConsumptionCard(consumption: consumption),
          ),
        ),

        // Creator list
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créateurs à soutenir',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('Votre créateur dominant est mis en avant.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AkeliColors.textSecondary)),
              ],
            ),
          ),
        ),

        creatorsAsync.when(
          loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator())),
          error: (err, _) =>
              SliverToBoxAdapter(child: ErrorState(message: err.toString())),
          data: (creators) {
            if (creators.isEmpty) {
              return const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'Aucun créateur éligible',
                  subtitle:
                      'Les créateurs doivent publier 30 recettes pour être éligibles.',
                ),
              );
            }
            final dominantId = consumptionAsync.valueOrNull?.isNotEmpty == true
                ? consumptionAsync.valueOrNull!.first.creatorId
                : null;
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _EligibleCreatorCard(
                  creator: creators[i],
                  isDominant: creators[i].id == dominantId,
                  onActivate: () => _activateFanMode(context, ref, creators[i]),
                ),
                childCount: creators.length,
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AkeliSpacing.xxl)),
      ],
    );
  }

  Future<void> _activateFanMode(
      BuildContext context, WidgetRef ref, Creator creator) async {
    appLogger.userAction('Activate fan mode button tapped',
        screen: 'FanModePage',
        metadata: {'creatorId': LogHelper.maskUuid(creator.id)});
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activer le Mode Fan'),
        content: Text(
          'Vous allez soutenir ${creator.displayName} avec 1€/mois, '
          'inclus dans votre abonnement Akeli.\n\n'
          'Règle 90/10 : 90% de vos repas devront venir du catalogue de ce créateur '
          '(max 9 recettes externes par mois).\n\n'
          'Actif à partir du 1er du mois prochain.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    appLogger.userAction('Activate fan mode confirmed', screen: 'FanModePage');
    await ref.read(fanModeNotifierProvider.notifier).activate(creator.id);
    final state = ref.read(fanModeNotifierProvider);
    if (!context.mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'activation.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous soutenez maintenant ${creator.displayName} !'),
          backgroundColor: AkeliColors.success,
        ),
      );
    }
  }
}

class _ConsumptionCard extends StatelessWidget {
  final List<CreatorConsumption> consumption;
  const _ConsumptionCard({required this.consumption});

  @override
  Widget build(BuildContext context) {
    final total = consumption.fold(0, (s, c) => s + c.count);
    return Container(
      margin: const EdgeInsets.all(AkeliSpacing.lg),
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos recettes ce mois',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.textSecondary,
                  letterSpacing: 0.7)),
          const SizedBox(height: AkeliSpacing.sm),
          if (consumption.isEmpty)
            Text('Aucune recette enregistrée ce mois',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AkeliColors.textSecondary))
          else ...[
            Container(
              decoration: BoxDecoration(
                color: AkeliColors.background,
                borderRadius: BorderRadius.circular(AkeliRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AkeliSpacing.md, vertical: AkeliSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍽 ', style: TextStyle(fontSize: 13)),
                  Text('$total repas enregistrés',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AkeliColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: AkeliSpacing.md),
            ...consumption.map((c) => _CreatorRatioRow(c: c)),
          ],
        ],
      ),
    );
  }
}

class _CreatorRatioRow extends StatelessWidget {
  final CreatorConsumption c;
  const _CreatorRatioRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final color = _creatorColor(c.creatorId);
    return Padding(
      padding: const EdgeInsets.only(bottom: AkeliSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            backgroundImage: c.avatarUrl != null
                ? CachedNetworkImageProvider(c.avatarUrl!)
                : null,
            child: c.avatarUrl == null
                ? Text(
                    c.creatorName.isNotEmpty
                        ? c.creatorName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: AkeliSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.creatorName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: c.pct,
                    backgroundColor: AkeliColors.background,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AkeliSpacing.sm),
          Text('${(c.pct * 100).round()}%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Color _creatorColor(String id) {
    final colors = [
      const Color(0xFFF472B6),
      const Color(0xFF60A5FA),
      const Color(0xFF4ADE80),
      const Color(0xFFA78BFA),
      const Color(0xFFFBBF24),
    ];
    return colors[id.hashCode % colors.length];
  }
}

class _EligibleCreatorCard extends StatelessWidget {
  final Creator creator;
  final bool isDominant;
  final VoidCallback onActivate;

  const _EligibleCreatorCard({
    required this.creator,
    required this.isDominant,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    appLogger.d('_EligibleCreatorCard build() | creatorId: ${creator.id} | isDominant: $isDominant');
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AkeliSpacing.md, vertical: AkeliSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AkeliSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  AkeliColors.primary.withValues(alpha: 0.1),
              backgroundImage: creator.avatarUrl != null
                  ? CachedNetworkImageProvider(creator.avatarUrl!)
                  : null,
              child: creator.avatarUrl == null
                  ? Text(
                      creator.displayName[0].toUpperCase(),
                      style: const TextStyle(
                          color: AkeliColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: AkeliSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(creator.displayName,
                      style: Theme.of(context).textTheme.titleSmall),
                  if (creator.specialties.isNotEmpty)
                    Text(
                      creator.specialties.join(' • '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AkeliColors.textSecondary),
                    ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.restaurant_menu_rounded,
                        size: 12, color: AkeliColors.textSecondary),
                    const SizedBox(width: 2),
                    Text('${creator.recipeCount} recettes',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AkeliColors.textSecondary)),
                    const SizedBox(width: AkeliSpacing.sm),
                    const Icon(Icons.people_outline_rounded,
                        size: 12, color: AkeliColors.textSecondary),
                    const SizedBox(width: 2),
                    Text('${creator.fanCount} fans',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AkeliColors.textSecondary)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: AkeliSpacing.sm),
            FilledButton(
              onPressed: onActivate,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDominant ? AkeliColors.primary : null,
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Soutenir'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View B — Fan
// ─────────────────────────────────────────────────────────────────────────────

class _FanUserView extends ConsumerWidget {
  final FanSubscription sub;
  const _FanUserView({required this.sub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extCounterAsync = ref.watch(fanExternalCounterProvider);
    final creatorAsync = ref.watch(creatorProfileProvider(sub.creatorId));
    appLogger.provider('_FanUserView build() | status: ${sub.status}');

    final creator = creatorAsync.valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _StatusBanner(sub: sub, creator: creator),
          const SizedBox(height: AkeliSpacing.lg),

          // External counter — active only
          if (sub.isActive)
            extCounterAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (count) => _ExternalCounterCard(count: count),
            ),
          if (sub.isActive) const SizedBox(height: AkeliSpacing.lg),

          // Short explanation
          _FanExplanationCard(sub: sub, creator: creator),
          const SizedBox(height: AkeliSpacing.lg),

          // Leave button
          OutlinedButton(
            onPressed: () => _cancelFanMode(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AkeliColors.error,
              side: const BorderSide(color: AkeliColors.error),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Quitter le Mode Fan'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelFanMode(BuildContext context, WidgetRef ref) async {
    appLogger.userAction('Cancel fan mode button tapped', screen: 'FanModePage');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le Mode Fan'),
        content: const Text(
            'Votre soutien se terminera à la fin du mois en cours.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Garder')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AkeliColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    appLogger.userAction('Cancel fan mode confirmed', screen: 'FanModePage');
    await ref.read(fanModeNotifierProvider.notifier).cancel();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mode Fan annulé.')),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final FanSubscription sub;
  final Creator? creator;
  const _StatusBanner({required this.sub, this.creator});

  @override
  Widget build(BuildContext context) {
    final isPending = sub.isPending;
    final bannerColor =
        isPending ? const Color(0xFFFBBF24) : AkeliColors.primary;

    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: bannerColor.withValues(alpha: 0.15),
            backgroundImage: creator?.avatarUrl != null
                ? CachedNetworkImageProvider(creator!.avatarUrl!)
                : null,
            child: creator?.avatarUrl == null
                ? Text(
                    (creator?.displayName ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                        color: bannerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator?.displayName ?? '…',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (creator?.specialties.isNotEmpty == true)
                  Text(
                    creator!.specialties.first,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AkeliColors.textSecondary),
                  ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AkeliSpacing.sm, vertical: 2),
                  child: Text(
                    isPending
                        ? '⏳ Actif le 1er du mois prochain'
                        : '❤️ Mode Fan actif',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: bannerColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalCounterCard extends StatelessWidget {
  final int count;
  const _ExternalCounterCard({required this.count});

  Color get _color {
    if (count <= 4) return AkeliColors.success;
    if (count <= 7) return const Color(0xFFFBBF24);
    return AkeliColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recettes externes ce mois',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AkeliColors.textSecondary,
                letterSpacing: 0.7),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recettes hors catalogue',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AkeliColors.textSecondary),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _color),
                    ),
                    TextSpan(
                      text: ' / 9',
                      style: TextStyle(
                          fontSize: 14,
                          color: AkeliColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AkeliSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: count / 9,
              backgroundColor: AkeliColors.background,
              valueColor: AlwaysStoppedAnimation(_color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FanExplanationCard extends StatelessWidget {
  final FanSubscription sub;
  final Creator? creator;
  const _FanExplanationCard({required this.sub, this.creator});

  @override
  Widget build(BuildContext context) {
    final name = creator?.displayName ?? 'votre créateur';
    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.lg),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Mode Fan',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AkeliColors.textSecondary,
                letterSpacing: 0.7),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                  fontSize: 13,
                  color: AkeliColors.textSecondary,
                  height: 1.6),
              children: [
                TextSpan(text: 'Vous soutenez '),
                TextSpan(
                    text: name,
                    style: const TextStyle(
                        color: AkeliColors.text,
                        fontWeight: FontWeight.w600)),
                const TextSpan(text: ' avec '),
                const TextSpan(
                    text: '1€/mois garanti',
                    style: TextStyle(
                        color: AkeliColors.text,
                        fontWeight: FontWeight.w600)),
                const TextSpan(
                    text:
                        ', inclus dans votre abonnement.\n\nRègle 90/10 : 90% de vos repas doivent venir du catalogue de ce créateur. Vous pouvez utiliser jusqu\'à '),
                const TextSpan(
                    text: '9 recettes externes',
                    style: TextStyle(
                        color: AkeliColors.text,
                        fontWeight: FontWeight.w600)),
                const TextSpan(text: ' par mois.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run widget tests**

```
flutter test test/features/fan_mode/fan_mode_page_test.dart
```
Expected: all 8 tests pass.

- [ ] **Step 5: Run full test suite to check for regressions**

```
flutter test
```
Expected: all tests pass.

- [ ] **Step 6: Commit**

```
git add lib/features/fan_mode/fan_mode_page.dart test/features/fan_mode/fan_mode_page_test.dart
git commit -m "feat: fan mode page — two-view redesign (non-fan + fan)"
```

---

## Self-Review Checklist

- [x] `CreatorConsumption` model defined before providers that reference it (Task 1 before Task 2)
- [x] `aggregateConsumption()` is `@visibleForTesting`-accessible — it's a top-level function, exported by the library
- [x] `_FanUserView` uses `creatorProfileProvider(sub.creatorId)` — `creatorProfileProvider` is already defined in `fan_mode_provider.dart` (line 93)
- [x] `currentMonthKey()` used in both new providers — defined once, called twice
- [x] Widget tests override all providers watched by the page (including `creatorProfileProvider`)
- [x] "Aucune recette enregistrée ce mois" empty state tested
- [x] Pending fan state tested (counter hidden)
- [x] `_cancelFanMode` in `_FanUserView` mirrors existing dialog pattern exactly
- [x] Logging standard followed: BEFORE/AFTER/ERROR on all DB calls, provider lifecycle logs, zero-row RLS detection
