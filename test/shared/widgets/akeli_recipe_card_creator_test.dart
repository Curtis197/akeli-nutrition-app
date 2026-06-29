import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/widgets/akeli_recipe_card.dart';
import 'package:akeli/providers/creator_provider.dart';
import 'package:akeli/shared/models/creator.dart';

Creator _fakeCreator() => const Creator(
  id: 'c-1',
  userId: 'u-1',
  displayName: 'Amara Diallo',
  avatarUrl: null,
  specialties: [],
  recipeCount: 5,
  fanCount: 2,
  isFanEligible: false,
  isMyFanCreator: false,
  averageRating: 4.2,
);

Widget _wrap(Widget child, {Creator? creator}) {
  return ProviderScope(
    overrides: [
      if (creator != null)
        creatorByIdProvider('c-1').overrideWith(
          (ref) async => creator,
        ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 300,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('AkeliRecipeCard creator row', () {
    testWidgets('shows nothing when creatorId is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AkeliRecipeCard(
          title: 'Mafé',
          rating: 4.0,
          likes: 5,
          comments: 2,
          saves: 1,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Amara Diallo'), findsNothing);
    });

    testWidgets('shows creator name when creatorId is provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const AkeliRecipeCard(
          title: 'Mafé',
          rating: 4.0,
          likes: 5,
          comments: 2,
          saves: 1,
          creatorId: 'c-1',
        ),
        creator: _fakeCreator(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Amara Diallo'), findsOneWidget);
    });
  });
}
