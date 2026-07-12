import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_day_selector.dart';

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
  group('MealPlannerDaySelector', () {
    testWidgets('renders exactly one chip per day, not a fixed 7', (tester) async {
      final days = [
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 14),
        DateTime(2026, 7, 15),
      ];
      await tester.pumpWidget(_wrap(MealPlannerDaySelector(
        days: days,
        selected: days.first,
        onSelect: (_) {},
      )));

      expect(find.byKey(Key('day-chip-${days[0].toIso8601String()}')), findsOneWidget);
      expect(find.byKey(Key('day-chip-${days[1].toIso8601String()}')), findsOneWidget);
      expect(find.byKey(Key('day-chip-${days[2].toIso8601String()}')), findsOneWidget);
      expect(find.byKey(Key('day-chip-${DateTime(2026, 7, 16).toIso8601String()}')), findsNothing);
    });

    testWidgets('renders a single chip when only one day is present', (tester) async {
      final day = DateTime(2026, 7, 13);
      await tester.pumpWidget(_wrap(MealPlannerDaySelector(
        days: [day],
        selected: day,
        onSelect: (_) {},
      )));

      expect(find.byKey(Key('day-chip-${day.toIso8601String()}')), findsOneWidget);
    });

    testWidgets('tapping a chip calls onSelect with that date', (tester) async {
      final days = [DateTime(2026, 7, 13), DateTime(2026, 7, 14)];
      DateTime? selected;
      await tester.pumpWidget(_wrap(MealPlannerDaySelector(
        days: days,
        selected: days.first,
        onSelect: (date) => selected = date,
      )));

      await tester.tap(find.byKey(Key('day-chip-${days[1].toIso8601String()}')));
      await tester.pump();

      expect(selected, days[1]);
    });

    testWidgets('tapping the already-selected chip does not call onSelect', (tester) async {
      final days = [DateTime(2026, 7, 13), DateTime(2026, 7, 14)];
      var callCount = 0;
      await tester.pumpWidget(_wrap(MealPlannerDaySelector(
        days: days,
        selected: days.first,
        onSelect: (_) => callCount++,
      )));

      await tester.tap(find.byKey(Key('day-chip-${days[0].toIso8601String()}')));
      await tester.pump();

      expect(callCount, 0);
    });
  });
}
