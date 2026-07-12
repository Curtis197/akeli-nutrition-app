import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_day_recap_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: Scaffold(body: child),
    );

void main() {
  group('MealPlannerDayRecapCard', () {
    testWidgets('shows consumed / target kcal text uncapped', (tester) async {
      await tester.pumpWidget(_wrap(MealPlannerDayRecapCard(
        date: DateTime(2026, 7, 13),
        consumedKcal: 1500,
        targetKcal: 1200,
      )));

      expect(find.text('1500 / 1200 kcal'), findsOneWidget);
    });

    testWidgets('progress bar clamps at 100% when consumed exceeds target', (tester) async {
      await tester.pumpWidget(_wrap(MealPlannerDayRecapCard(
        date: DateTime(2026, 7, 13),
        consumedKcal: 1500,
        targetKcal: 1200,
      )));

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('day-recap-progress')),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('progress bar reflects partial progress under target', (tester) async {
      await tester.pumpWidget(_wrap(MealPlannerDayRecapCard(
        date: DateTime(2026, 7, 13),
        consumedKcal: 600,
        targetKcal: 1200,
      )));

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('day-recap-progress')),
      );
      expect(indicator.value, 0.5);
    });
  });
}
