import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/widgets/meal_card.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: Scaffold(body: child),
    );

void main() {
  group('AkeliMealCard planner variant — consumed toggle visibility', () {
    testWidgets('toggle is visible when onConsumedToggle is provided', (tester) async {
      await tester.pumpWidget(_wrap(AkeliMealCard(
        title: 'Thiéboudiène',
        mealType: 'lunch',
        calories: 550,
        isPlanner: true,
        isConsumed: false,
        onConsumedToggle: () {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsOneWidget);
    });

    testWidgets('toggle is absent when onConsumedToggle is null', (tester) async {
      await tester.pumpWidget(_wrap(const AkeliMealCard(
        title: 'Thiéboudiène',
        mealType: 'lunch',
        calories: 550,
        isPlanner: true,
        isConsumed: false,
        onConsumedToggle: null,
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsNothing);
    });

    testWidgets('toggle shows check icon when consumed', (tester) async {
      await tester.pumpWidget(_wrap(AkeliMealCard(
        title: 'Thiéboudiène',
        mealType: 'lunch',
        calories: 550,
        isPlanner: true,
        isConsumed: true,
        onConsumedToggle: () {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
