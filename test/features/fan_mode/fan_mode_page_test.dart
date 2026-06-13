import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/fan_mode/fan_mode_page.dart';
import 'package:akeli/providers/fan_mode_provider.dart';
import 'package:akeli/shared/models/creator.dart';

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
  const Creator(
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
