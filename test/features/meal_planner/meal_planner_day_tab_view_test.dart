import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_day_tab_view.dart';
import 'package:akeli/features/meal_planner/widgets/snack_picker_sheet.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/shared/models/meal_plan.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';
import 'package:akeli/shared/widgets/meal_card.dart';

MealPlanEntry _entry({
  required String id,
  required DateTime date,
  bool isConsumed = false,
  double? caloriesComputed,
  String mealType = 'lunch',
}) =>
    MealPlanEntry(
      id: id,
      mealPlanId: 'plan-1',
      mealType: mealType,
      scheduledDate: date,
      servings: 1.0,
      isConsumed: isConsumed,
      isRated: false,
      isCustomMeal: false,
      caloriesComputed: caloriesComputed,
      ingredients: const [],
      components: const [],
    );

Widget _wrap(Widget child, {required List<Override> overrides}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  final day1 = DateTime(2026, 7, 13);
  final day2 = DateTime(2026, 7, 14);

  MealPlan plan() => MealPlan(
        id: 'plan-1',
        userId: 'u-1',
        startDate: day1,
        endDate: day2,
        isActive: true,
        entries: [
          _entry(id: 'e1', date: day1, isConsumed: true, caloriesComputed: 600),
          _entry(id: 'e2', date: day1, isConsumed: false, caloriesComputed: 700),
          _entry(id: 'e3', date: day2, isConsumed: false, caloriesComputed: 500),
        ],
      );

  List<Override> baseOverrides() => [
        activeNutritionPlanProvider.overrideWith((ref) async => NutritionPlan(
              userId: 'u-1',
              calorieGoal: 1200,
              proteinGoalG: 90,
              carbGoalG: 120,
              fatGoalG: 40,
            )),
      ];

  group('MealPlannerDayTabView', () {
    testWidgets('defaults to the first day and recaps only that day', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: baseOverrides(),
      ));
      await tester.pump();

      expect(find.byKey(Key('day-chip-${day1.toIso8601String()}')), findsOneWidget);
      expect(find.byKey(Key('day-chip-${day2.toIso8601String()}')), findsOneWidget);
      expect(find.text('600 / 1200 kcal'), findsOneWidget);
    });

    testWidgets('selecting a day chip updates recap to that day', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: baseOverrides(),
      ));
      await tester.pump();

      await tester.tap(find.byKey(Key('day-chip-${day2.toIso8601String()}')));
      await tester.pump();

      expect(find.text('0 / 1200 kcal'), findsOneWidget);
    });

    testWidgets('recap respects the optimisticConsumptionProvider overlay', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: [
          ...baseOverrides(),
          optimisticConsumptionProvider.overrideWith((ref) => {'e2': true}),
        ],
      ));
      await tester.pump();

      expect(find.text('1300 / 1200 kcal'), findsOneWidget);
    });

    testWidgets('progress bar clamps at 100% when consumed exceeds target', (tester) async {
      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: [
          ...baseOverrides(),
          optimisticConsumptionProvider.overrideWith((ref) => {'e2': true}),
        ],
      ));
      await tester.pump();

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('day-recap-progress')),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('add-snack button opens the snack picker sheet', (tester) async {
      // The planner variant of AkeliMealCard is a fixed 300x300 tile; two
      // entries stacked in the day's Column push the add-snack button past
      // the default 800x600 test surface, so tester.tap() misses it without
      // a taller surface. This mirrors the tester.view.physicalSize pattern
      // already used in test/features/cooking/cooking_mode_page_test.dart.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: plan()),
        overrides: baseOverrides(),
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('day-tab-add-snack')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackPickerSheet), findsOneWidget);
    });

    testWidgets('handles empty entries gracefully without crashing', (tester) async {
      // Create a MealPlan with an empty entries list. This can happen when
      // activeMealPlanProvider returns a non-null plan but the query doesn't
      // use !inner join on meal_plan_entry, defaulting entries to [].
      final emptyPlan = MealPlan(
        id: 'plan-1',
        userId: 'u-1',
        startDate: day1,
        endDate: day2,
        isActive: true,
        entries: const [],
      );

      await tester.pumpWidget(_wrap(
        MealPlannerDayTabView(plan: emptyPlan),
        overrides: baseOverrides(),
      ));
      await tester.pump();

      // The widget should render without throwing StateError: No element.
      // Assert that MealPlannerDayTabView itself still exists in the tree
      // (i.e. it didn't crash), and verify no meal cards are rendered.
      expect(find.byType(MealPlannerDayTabView), findsOneWidget);
      expect(find.byType(AkeliMealCard), findsNothing);
    });
  });
}
