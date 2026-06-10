import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_day_row.dart';
import 'package:akeli/shared/models/meal_plan.dart';

MealPlanEntry _makeEntry(DateTime scheduledDate) => MealPlanEntry(
      id: 'e1',
      mealPlanId: 'p1',
      mealType: 'lunch',
      scheduledDate: scheduledDate,
      servings: 1.0,
      isConsumed: false,
      isRated: false,
      isCustomMeal: false,
      ingredients: const [],
      components: const [],
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MealPlannerDayRow — consumed toggle visibility', () {
    testWidgets('toggle is visible for today', (tester) async {
      final today = DateTime.now();
      await tester.pumpWidget(_wrap(MealPlannerDayRow(
        date: today,
        entries: [_makeEntry(today)],
        onConsumedToggle: (_) {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsOneWidget);
    });

    testWidgets('toggle is absent for tomorrow', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.pumpWidget(_wrap(MealPlannerDayRow(
        date: tomorrow,
        entries: [_makeEntry(tomorrow)],
        onConsumedToggle: (_) {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsNothing);
    });

    testWidgets('toggle is visible for yesterday', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(_wrap(MealPlannerDayRow(
        date: yesterday,
        entries: [_makeEntry(yesterday)],
        onConsumedToggle: (_) {},
      )));

      expect(find.byKey(const Key('consumed-toggle')), findsOneWidget);
    });
  });
}
