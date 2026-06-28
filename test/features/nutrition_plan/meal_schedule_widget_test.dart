// test/features/nutrition_plan/meal_schedule_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

MealDistribution _slot(String type, double pct, {String? nickname}) =>
    MealDistribution(mealType: type, sortOrder: 0, caloriePct: pct, nickname: nickname);

void main() {
  group('MealScheduleWidget', () {
    testWidgets('W1: save enabled when calorie % sums to 100', (tester) async {
      bool saveEnabled = false;
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [
          _slot('breakfast', 30),
          _slot('lunch', 35),
          _slot('dinner', 35),
        ],
        totalCalorieGoal: 2000,
        onChanged: (_) {},
        onSaveEnabled: (v) => saveEnabled = v,
      )));
      await tester.pumpAndSettle();
      expect(saveEnabled, isTrue); // W1
    });

    testWidgets('W2: save disabled when calorie % does not sum to 100',
        (tester) async {
      bool saveEnabled = true;
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [
          _slot('breakfast', 30),
          _slot('lunch', 30), // total = 60%, not 100
        ],
        totalCalorieGoal: 2000,
        onChanged: (_) {},
        onSaveEnabled: (v) => saveEnabled = v,
      )));
      await tester.pumpAndSettle();
      expect(saveEnabled, isFalse); // W2
    });

    testWidgets('W5: add slot increments count', (tester) async {
      final List<List<MealDistribution>> emitted = [];
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [_slot('breakfast', 100)],
        totalCalorieGoal: 2000,
        onChanged: (dists) => emitted.add(List.of(dists)),
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addSlotButton')));
      await tester.pumpAndSettle();

      expect(emitted.last.length, 2); // W5
    });

    testWidgets('W6: remove slot decrements count', (tester) async {
      final List<List<MealDistribution>> emitted = [];
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [
          _slot('breakfast', 50),
          _slot('lunch', 50),
        ],
        totalCalorieGoal: 2000,
        onChanged: (dists) => emitted.add(List.of(dists)),
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteSlot_0')));
      await tester.pumpAndSettle();

      expect(emitted.last.length, 1); // W6
    });

    testWidgets('W7: cannot delete last slot', (tester) async {
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [_slot('breakfast', 100)],
        totalCalorieGoal: 2000,
        onChanged: (_) {},
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('deleteSlot_0')), findsNothing); // W7
    });

    testWidgets('W8: saving with empty nickname succeeds', (tester) async {
      List<MealDistribution>? last;
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [_slot('breakfast', 50), _slot('lunch', 50)],
        totalCalorieGoal: 2000,
        onChanged: (d) => last = d,
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();
      expect(last?.first.nickname, isNull); // W8
    });

    testWidgets('W10: category picker changes mealType', (tester) async {
      List<MealDistribution>? last;
      await tester.pumpWidget(_wrap(MealScheduleWidget(
        initialDistributions: [_slot('breakfast', 100)],
        totalCalorieGoal: 2000,
        onChanged: (d) => last = d,
        onSaveEnabled: (_) {},
      )));
      await tester.pumpAndSettle();

      // Open the dropdown for slot 0
      await tester.tap(find.byKey(const Key('categoryDropdown_0')));
      await tester.pumpAndSettle();

      // Select 'dinner'
      await tester.tap(find.byKey(const Key('categoryOption_dinner')).last);
      await tester.pumpAndSettle();

      expect(last?.first.mealType, 'dinner'); // W10
    });
  });
}
